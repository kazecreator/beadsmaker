import SwiftUI

struct ProInfoView: View {
    @ObservedObject var sessionStore: AppSessionStore
    @EnvironmentObject private var proStatusManager: ProStatusManager
    @EnvironmentObject private var appleSignInManager: AppleSignInManager
    @Environment(\.dismiss) private var dismiss

    private var isPro: Bool { sessionStore.currentUser.isPro }

    @State private var isShowingPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if isPro {
                        thankYouSection
                    } else {
                        heroSection
                        featuresSection
                        subscribeSection
                    }
                }
                .padding(16)
            }
            .navigationTitle(L10n.tr("BeadsMaker Pro"))
            .navigationBarTitleDisplayMode(.inline)
            .background(BeadsMakerTheme.surface)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.tr("Done")) { dismiss() }
                }
            }
        }
        .presentationDetents([.fraction(0.82), .large])
        .sheet(isPresented: $isShowingPaywall) {
            PaywallView(sessionStore: sessionStore)
                .environmentObject(proStatusManager)
                .environmentObject(appleSignInManager)
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(BeadsMakerTheme.ink.opacity(0.06))
                    .frame(width: 80, height: 80)
                Image(systemName: "crown.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(BeadsMakerTheme.ink)
            }

            VStack(spacing: 6) {
                Text(L10n.tr("Unlock the Full Studio"))
                    .font(.title2.bold())
                    .foregroundStyle(BeadsMakerTheme.ink)
                Text(L10n.tr("One-time purchase. No subscription."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .pbCard()
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.tr("What you get"))
                .font(.headline)
                .foregroundStyle(BeadsMakerTheme.ink)

            VStack(spacing: 0) {
                featureRow(icon: "doc.on.doc.fill", title: L10n.tr("Unlimited drafts"),
                           detail: L10n.tr("No more 20-draft ceiling"))
                Divider().padding(.leading, 52)
                featureRow(icon: "icloud.fill", title: L10n.tr("iCloud sync across devices"),
                           detail: L10n.tr("Your patterns, drafts, and preferences stay in sync on every device"))
                Divider().padding(.leading, 52)
                featureRow(icon: "square.grid.3x3.fill", title: L10n.tr("Pattern-based avatars"),
                           detail: L10n.tr("Turn any square finished work into your profile avatar"))
            }
        }
        .pbCard()
    }

    // MARK: - Subscribe

    private var subscribeSection: some View {
        VStack(spacing: 16) {
            if let product = proStatusManager.product {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.tr("BeadsMaker Pro"))
                            .font(.headline)
                            .foregroundStyle(BeadsMakerTheme.ink)
                        Text(L10n.tr("One-time purchase, yours forever"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(product.displayPrice)
                        .font(.title3.bold())
                        .foregroundStyle(BeadsMakerTheme.ink)
                }
                .padding(16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: BeadsMakerTheme.Radius.card, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: BeadsMakerTheme.Radius.card, style: .continuous)
                        .stroke(BeadsMakerTheme.outline, lineWidth: 1)
                )
            }

            Button {
                isShowingPaywall = true
            } label: {
                Label(L10n.tr("Upgrade to Pro"), systemImage: "crown")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())

            Button {
                Task { await proStatusManager.restorePurchases() }
            } label: {
                Text(L10n.tr("Restore Purchase"))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(BeadsMakerTheme.ink)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Thank you (Pro)

    private var thankYouSection: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(BeadsMakerTheme.ink.opacity(0.06))
                        .frame(width: 80, height: 80)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(BeadsMakerTheme.ink)
                }

                VStack(spacing: 6) {
                    Text(L10n.tr("You're a Pro Creator"))
                        .font(.title2.bold())
                        .foregroundStyle(BeadsMakerTheme.ink)
                    Text(L10n.tr("Thank you for supporting BeadsMaker. You have unlimited drafts, iCloud sync, and full access to every feature."))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .pbCard()

            VStack(alignment: .leading, spacing: 16) {
                Text(L10n.tr("What you get"))
                    .font(.headline)
                    .foregroundStyle(BeadsMakerTheme.ink)

                VStack(spacing: 0) {
                    featureRow(icon: "doc.on.doc.fill", title: L10n.tr("Unlimited drafts"),
                               detail: L10n.tr("Create as many patterns as you like"))
                    Divider().padding(.leading, 52)
                    featureRow(icon: "icloud.fill", title: L10n.tr("iCloud sync"),
                               detail: L10n.tr("Seamlessly synced across all your devices"))
                    Divider().padding(.leading, 52)
                    featureRow(icon: "square.grid.3x3.fill", title: L10n.tr("Pattern-based avatars"),
                               detail: L10n.tr("Any square finished work becomes a custom avatar"))
                }
            }
            .pbCard()
        }
    }

    // MARK: - Helpers

    private func featureRow(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(BeadsMakerTheme.ink.opacity(0.06))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(BeadsMakerTheme.ink)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(BeadsMakerTheme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(.vertical, 12)
    }
}
