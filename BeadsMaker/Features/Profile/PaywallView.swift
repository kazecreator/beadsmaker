import SwiftUI

/// Paywall shown when a guest user hits the draft limit.
/// Handles StoreKit purchase and only links an account when backend features are enabled.
struct PaywallView: View {
    @ObservedObject var sessionStore: AppSessionStore
    @EnvironmentObject private var proStatusManager: ProStatusManager
    @EnvironmentObject private var appleSignInManager: AppleSignInManager
    @Environment(\.dismiss) private var dismiss

    /// Completion handler — called after the user finishes the sign-in flow.
    var onUpgradeComplete: (() -> Void)?

    @State private var signInResult: AppleSignInResult?
    @State private var isShowingConfirmName = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    heroSection
                    featuresCard
                    pricingCard
                    ctaCard

                    if let message = proStatusManager.errorMessage {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(BeadsMakerTheme.ink)
                            .padding(.horizontal, 4)
                    }
                }
                .padding(16)
            }
            .navigationTitle(L10n.tr("Pro Feature"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.tr("Not Now")) { dismiss() }
                        .foregroundStyle(.secondary)
                }
            }
            .pbScreen()
        }
        .sheet(isPresented: $isShowingConfirmName) {
            if let result = signInResult {
                ConfirmNameView(
                    sessionStore: sessionStore,
                    appleSignInResult: result
                ) {
                    onUpgradeComplete?()
                    dismiss()
                }
                .environmentObject(appleSignInManager)
            }
        }
    }

    // MARK: - Sections

    private var heroSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "crown.fill")
                .font(.system(size: 44))
                .foregroundStyle(BeadsMakerTheme.ink)
                .padding(.top, 8)
            Text(L10n.tr("Become a Pro Creator"))
                .font(.title2.bold())
                .foregroundStyle(BeadsMakerTheme.ink)
                .multilineTextAlignment(.center)
            Text(L10n.tr("One-time purchase. No subscription."))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .pbCard()
    }

    private var featuresCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.tr("What you get"))
                .font(.headline)
                .foregroundStyle(BeadsMakerTheme.ink)

            if AppFeatureFlags.communityEnabled {
                featureRow(icon: "globe", title: L10n.tr("Publish patterns"),
                           detail: L10n.tr("Share your pixel art with the community"))
            }
            featureRow(icon: "doc.on.doc", title: L10n.tr("Unlimited drafts"),
                       detail: L10n.tr("No more 20-draft ceiling"))
        }
        .pbCard()
    }

    private var pricingCard: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.tr("BeadsMaker Pro"))
                    .font(.headline)
                    .foregroundStyle(BeadsMakerTheme.ink)
                Text(L10n.tr("One-time purchase, yours forever"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let product = proStatusManager.product {
                Text(product.displayPrice)
                    .font(.title3.bold())
                    .foregroundStyle(BeadsMakerTheme.ink)
            } else {
                ProgressView()
                    .tint(BeadsMakerTheme.ink)
            }
        }
        .pbCard()
    }

    @ViewBuilder
    private var ctaCard: some View {
        switch proStatusManager.productLoadState {
        case .loading:
            VStack(spacing: 12) {
                Button {
                    // no-op: still loading
                } label: {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(true)

                restoreButton
            }
            .pbCard()

        case .loaded:
            VStack(spacing: 12) {
                Button {
                    Task { await handlePurchase() }
                } label: {
                    if proStatusManager.purchaseInProgress {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Label(L10n.tr("Upgrade to Pro"), systemImage: "crown")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(proStatusManager.purchaseInProgress)

                restoreButton
            }
            .pbCard()

        case .unavailable:
            VStack(spacing: 12) {
                VStack(spacing: 12) {
                    Image(systemName: "clock.badge.questionmark")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text(L10n.tr("Pro features are coming soon"))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(BeadsMakerTheme.ink)
                    Text(L10n.tr("We're finalizing the Pro purchase with the App Store. Check back shortly."))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(16)

                restoreButton
            }
            .pbCard()

        case .error:
            VStack(spacing: 12) {
                VStack(spacing: 12) {
                    Image(systemName: "wifi.slash")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text(L10n.tr("Unable to load product"))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(BeadsMakerTheme.ink)
                    Text(L10n.tr("Check your internet connection and try again."))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button {
                        Task { await proStatusManager.retryLoadProduct() }
                    } label: {
                        Label(L10n.tr("Retry"), systemImage: "arrow.clockwise")
                            .font(.subheadline.weight(.medium))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(BeadsMakerTheme.ink)
                }
                .frame(maxWidth: .infinity)
                .padding(16)

                restoreButton
            }
            .pbCard()
        }
    }

    private var restoreButton: some View {
        Button {
            Task { await handleRestore() }
        } label: {
            if proStatusManager.restoreInProgress {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                Text(L10n.tr("Restore Purchase"))
            }
        }
        .buttonStyle(SecondaryButtonStyle())
        .disabled(proStatusManager.restoreInProgress)
    }

    // MARK: - Actions

    private func handlePurchase() async {
        let result = await proStatusManager.purchase()
        switch result {
        case .success:
            // Immediately reflect Pro status in the session.
            sessionStore.upgradeToPro()
            await finishUpgrade()

        case .pending:
            // Family sharing / Ask to Buy — dismiss and wait for transaction update.
            dismiss()

        case .userCancelled, .failed:
            // Error message already set on proStatusManager; leave the sheet open.
            break
        }
    }

    private func handleRestore() async {
        await proStatusManager.restorePurchases()
        if proStatusManager.isPro {
            sessionStore.upgradeToPro()
            await finishUpgrade()
        }
    }

    private func finishUpgrade() async {
        if AppFeatureFlags.backendEnabled {
            await triggerAppleSignIn()
        } else {
            onUpgradeComplete?()
            dismiss()
        }
    }

    private func triggerAppleSignIn() async {
        print("[PaywallView] triggerAppleSignIn called")
        #if DEBUG
        // Sign in with Apple requires a paid Apple Developer account.
        // In debug builds, skip the real flow and go directly to ConfirmNameView.
        let mockResult = AppleSignInResult(appleUserID: "debug-apple-user-\(UUID().uuidString)", displayName: nil, email: nil)
        signInResult = mockResult
        isShowingConfirmName = true
        #else
        do {
            let result = try await appleSignInManager.signIn()
            print("[PaywallView] signIn succeeded: \(result.appleUserID)")
            signInResult = result
            isShowingConfirmName = true
        } catch is AppleSignInError {
            print("[PaywallView] signIn threw AppleSignInError — dismissing")
            // Cancelled or failed Apple Sign In: Pro status is already set — just dismiss.
            onUpgradeComplete?()
            dismiss()
        } catch {
            print("[PaywallView] signIn threw unknown error: \(error)")
            // Unexpected error: still dismiss since purchase succeeded.
            onUpgradeComplete?()
            dismiss()
        }
        #endif
    }

    // MARK: - Helpers

    private func featureRow(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(BeadsMakerTheme.ink)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(BeadsMakerTheme.ink)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
