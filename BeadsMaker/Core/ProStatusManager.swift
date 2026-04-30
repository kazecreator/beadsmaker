import Foundation
import Security
import StoreKit

// MARK: - Keychain helper (Pro status, device-local)

private enum ProKeychain {
    private static let service = "com.kevinzhang.beadsmaker"
    private static let account = "pro-status"

    static func read() -> Bool {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return false }
        return data.first == 1
    }

    static func write(_ value: Bool) {
        let data = Data([value ? 1 : 0])
        let deleteQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        SecItemAdd([
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock
        ] as CFDictionary, nil)
    }
}

// MARK: - Purchase result

enum PurchaseResult {
    case success
    case userCancelled
    case pending
    case failed(String)
}

// MARK: - ProStatusManager

@MainActor
final class ProStatusManager: ObservableObject {
    static let productID = "com.beadsmaker.pro"
    private static let productLoadTimeout: Duration = .seconds(8)
    private static let purchaseTimeout: Duration = .seconds(45)

    /// Reflects the current Pro entitlement (Keychain-backed, survives reinstalls).
    @Published private(set) var isPro: Bool

    /// The StoreKit product once loaded.
    @Published private(set) var product: Product?

    /// True while a purchase is in-flight.
    @Published private(set) var purchaseInProgress = false

    /// True while a restore is in-flight.
    @Published private(set) var restoreInProgress = false

    /// Non-nil when the last purchase or restore attempt produced a user-visible error.
    @Published var errorMessage: String?

    /// True when StoreKit product loading failed (network issue, misconfiguration, etc.).
    @Published private(set) var productLoadFailed = false

    private var transactionUpdatesTask: Task<Void, Never>?

    init() {
        #if DEBUG
        self.isPro = ProKeychain.read()
        #else
        self.isPro = false
        #endif
        transactionUpdatesTask = Task { [weak self] in
            await self?.listenForTransactionUpdates()
        }
        Task { await loadProductAndVerify() }
    }

    deinit {
        transactionUpdatesTask?.cancel()
    }

    // MARK: - Purchase

    /// Initiates a StoreKit 2 purchase flow.
    /// Returns the result; the caller is responsible for the post-purchase UX.
    func purchase() async -> PurchaseResult {
        #if DEBUG
        // Xcode 26 beta: StoreKit local testing is broken on real devices.
        // When product is nil in debug builds, simulate a successful purchase so the
        // downstream flow (Apple Sign In → ConfirmNameView → Supabase) can be regression-tested.
        if product == nil {
            applyPro()
            return .success
        }
        #endif

        guard let product else {
            let message = L10n.tr("Product not available. Please try again later.")
            errorMessage = message
            productLoadFailed = true
            return .failed(message)
        }
        purchaseInProgress = true
        errorMessage = nil
        defer { purchaseInProgress = false }

        do {
            let result = try await purchaseResult(for: product)
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                applyPro()
                await transaction.finish()
                return .success

            case .userCancelled:
                return .userCancelled

            case .pending:
                return .pending

            @unknown default:
                let message = L10n.tr("Unknown purchase result.")
                errorMessage = message
                return .failed(message)
            }
        } catch ProStatusError.purchaseTimedOut {
            let message = L10n.tr("Purchase is taking longer than expected. Please try again.")
            errorMessage = message
            return .failed(message)
        } catch {
            let message = error.localizedDescription
            errorMessage = message
            return .failed(message)
        }
    }

    // MARK: - Restore

    /// Syncs App Store receipts and re-unlocks Pro if a previous purchase is found.
    func restorePurchases() async {
        restoreInProgress = true
        errorMessage = nil
        defer { restoreInProgress = false }

        do {
            try await AppStore.sync()
            await checkEntitlements()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Entitlement verification

    /// Re-checks current entitlements from StoreKit; updates `isPro` if a valid transaction exists.
    /// Called on cold start (background) so the Keychain stays in sync.
    func checkEntitlements() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.productID,
               transaction.revocationDate == nil {
                applyPro()
                return
            }
        }
        clearPro()
    }

    // MARK: - Helpers

    func retryLoadProduct() async {
        productLoadFailed = false
        await loadProductAndVerify()
    }

    private func loadProductAndVerify() async {
        do {
            let products = try await loadProductsWithTimeout()
            if let product = products.first {
                self.product = product
                productLoadFailed = false
                errorMessage = nil
            } else {
                self.product = nil
                productLoadFailed = true
                errorMessage = L10n.tr("No in-app purchase products are available right now.")
            }
            print("[ProStatusManager] Loaded \(products.count) product(s). product=\(String(describing: products.first?.id))")
        } catch ProStatusError.productLoadTimedOut {
            print("[ProStatusManager] Product load TIMED OUT")
            product = nil
            productLoadFailed = true
            errorMessage = L10n.tr("Product information is taking longer than expected. Please try again.")
        } catch {
            print("[ProStatusManager] Product load FAILED: \(error)")
            product = nil
            productLoadFailed = true
        }
        await checkEntitlements()
    }

    #if DEBUG
    func debugResetPro() {
        isPro = false
        product = nil
        ProKeychain.write(false)
        Task { await loadProductAndVerify() }
    }

    func debugTogglePro() -> Bool {
        let newValue = !isPro
        isPro = newValue
        ProKeychain.write(newValue)
        return newValue
    }
    #endif

    private func applyPro() {
        isPro = true
        ProKeychain.write(true)
    }

    private func clearPro() {
        isPro = false
        ProKeychain.write(false)
    }

    private func loadProductsWithTimeout() async throws -> [Product] {
        try await withThrowingTaskGroup(of: [Product].self) { group in
            group.addTask {
                try await Product.products(for: [Self.productID])
            }
            group.addTask {
                try await Task.sleep(for: Self.productLoadTimeout)
                throw ProStatusError.productLoadTimedOut
            }

            guard let products = try await group.next() else {
                throw ProStatusError.productLoadTimedOut
            }
            group.cancelAll()
            return products
        }
    }

    private func purchaseResult(for product: Product) async throws -> Product.PurchaseResult {
        try await withThrowingTaskGroup(of: Product.PurchaseResult.self) { group in
            group.addTask {
                try await product.purchase()
            }
            group.addTask {
                try await Task.sleep(for: Self.purchaseTimeout)
                throw ProStatusError.purchaseTimedOut
            }

            guard let result = try await group.next() else {
                throw ProStatusError.purchaseTimedOut
            }
            group.cancelAll()
            return result
        }
    }

    private func listenForTransactionUpdates() async {
        for await result in Transaction.updates {
            do {
                let transaction = try checkVerified(result)
                guard transaction.productID == Self.productID else { continue }
                if transaction.revocationDate == nil {
                    applyPro()
                }
                await transaction.finish()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw ProStatusError.failedVerification
        case .verified(let value):
            return value
        }
    }
}

// MARK: - Errors

enum ProStatusError: LocalizedError {
    case failedVerification
    case productLoadTimedOut
    case purchaseTimedOut

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return L10n.tr("Transaction verification failed.")
        case .productLoadTimedOut:
            return L10n.tr("Product information is taking longer than expected. Please try again.")
        case .purchaseTimedOut:
            return L10n.tr("Purchase is taking longer than expected. Please try again.")
        }
    }
}
