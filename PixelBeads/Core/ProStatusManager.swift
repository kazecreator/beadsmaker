import Foundation
import Security
import StoreKit

// MARK: - Keychain helper (Pro status, device-local)

private enum ProKeychain {
    private static let service = "com.kevinzhang.pixelbeads"
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
    static let productID = "com.pixelbeads.pro"

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

    init() {
        self.isPro = ProKeychain.read()
        Task { await loadProductAndVerify() }
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
            await applyPro()
            return .success
        }
        #endif

        guard let product else {
            return .failed(L10n.tr("Product not available. Check your internet connection."))
        }
        purchaseInProgress = true
        errorMessage = nil
        defer { purchaseInProgress = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await applyPro()
                await transaction.finish()
                return .success

            case .userCancelled:
                return .userCancelled

            case .pending:
                return .pending

            @unknown default:
                return .failed(L10n.tr("Unknown purchase result."))
            }
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
                await applyPro()
                return
            }
        }
    }

    // MARK: - Helpers

    private func loadProductAndVerify() async {
        do {
            let products = try await Product.products(for: [Self.productID])
            self.product = products.first
            print("[ProStatusManager] Loaded \(products.count) product(s). product=\(String(describing: products.first?.id))")
        } catch {
            print("[ProStatusManager] Product load FAILED: \(error)")
            // Product load failure is non-fatal; purchase button is disabled.
        }
        await checkEntitlements()
    }

    #if DEBUG
    /// Clears Pro status from Keychain and memory. Debug testing only.
    func debugResetPro() {
        isPro = false
        product = nil
        ProKeychain.write(false)
        Task { await loadProductAndVerify() }
    }
    #endif

    private func applyPro() async {
        isPro = true
        ProKeychain.write(true)
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

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return L10n.tr("Transaction verification failed.")
        }
    }
}
