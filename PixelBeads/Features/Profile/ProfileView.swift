import SwiftUI

struct ProfileView: View {
    @ObservedObject var sessionStore: AppSessionStore
    @ObservedObject var profileStore: ProfileStore
    @EnvironmentObject private var proStatusManager: ProStatusManager
    @EnvironmentObject private var appleSignInManager: AppleSignInManager

    @State private var isShowingAvatarSheet = false
    @State private var isShowingEditNameSheet = false
    @State private var isShowingPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    profileHeader
                    if profileStore.shouldShowDataLossRiskBanner {
                        dataLossRiskBanner
                    }
                    if !sessionStore.currentUser.isPro {
                        upgradeCard
                    }
                    identityCard
                    if sessionStore.currentUser.isPro {
                        appleAccountCard
                    }
                    avatarCard
                    publishedPatternsSection
                }
                .padding(16)
            }
            .navigationTitle(L10n.tr("Profile"))
            .background(PixelBeadsTheme.surface)
            .sheet(isPresented: $isShowingAvatarSheet) {
                AvatarPickerView(sessionStore: sessionStore, profileStore: profileStore)
            }
            .sheet(isPresented: $isShowingEditNameSheet) {
                EditNameView(sessionStore: sessionStore)
            }
            .sheet(isPresented: $isShowingPaywall) {
                PaywallView(sessionStore: sessionStore)
                    .environmentObject(proStatusManager)
                    .environmentObject(appleSignInManager)
            }
        }
        .pbScreen()
    }

    // MARK: - Header

    private var profileHeader: some View {
        HStack(spacing: 16) {
            PBAvatarView(image: avatarImage(for: sessionStore.currentUser.avatar), size: 72)

            VStack(alignment: .leading, spacing: 6) {
                Text(sessionStore.currentUser.displayName)
                    .font(.title2.bold())
                    .foregroundStyle(PixelBeadsTheme.ink)
                Text(sessionStore.currentUser.isPro ? L10n.tr("Pro creator") : L10n.tr("Guest creator"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                PBChip(
                    title: sessionStore.currentUser.isPro ? "Pro" : "Free",
                    accent: sessionStore.currentUser.isPro
                )
            }
            Spacer()
        }
        .pbCard()
    }

    // MARK: - Upgrade CTA (free users only)

    private var upgradeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "crown.fill")
                    .foregroundStyle(PixelBeadsTheme.coral)
                Text(L10n.tr("Unlock Pro"))
                    .font(.headline)
                    .foregroundStyle(PixelBeadsTheme.ink)
            }
            Text(L10n.tr("Publish patterns, get unlimited drafts, and sync via iCloud for just ¥6."))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button {
                isShowingPaywall = true
            } label: {
                Label(L10n.tr("Upgrade to Pro — ¥6"), systemImage: "crown")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .pbCard()
    }

    // MARK: - Apple Account (Pro users only)

    private var appleAccountCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.tr("Account"))
                .font(.headline)
                .foregroundStyle(PixelBeadsTheme.ink)

            HStack(spacing: 10) {
                Image(systemName: "apple.logo")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(PixelBeadsTheme.ink)
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.tr("Signed in with Apple"))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(PixelBeadsTheme.ink)
                    if let appleUserID = sessionStore.currentUser.appleUserID {
                        Text(String(appleUserID.prefix(24)) + "…")
                            .font(.caption2.monospaced())
                            .foregroundStyle(.secondary)
                    } else {
                        Text(L10n.tr("Account linked"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .pbCard()
    }

    // MARK: - Identity

    private var dataLossRiskBanner: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "externaldrive.badge.exclamationmark")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(PixelBeadsTheme.coral)

                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.tr("Protect your drafts"))
                        .font(.headline)
                        .foregroundStyle(PixelBeadsTheme.ink)
                    Text(L10n.tr("Guest drafts stay on this device. If the app is deleted or the device is lost, your local work may be lost too."))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Button {
                    profileStore.dismissDataLossRiskBanner()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .background(PixelBeadsTheme.canvas)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.tr("Dismiss data loss reminder"))
            }
        }
        .pbCard()
    }

    private var identityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.tr("Identity"))
                .font(.headline)

            identityRow(label: L10n.tr("Display Name"), value: sessionStore.currentUser.displayName)

            Button {
                isShowingEditNameSheet = true
            } label: {
                Label(L10n.tr("Edit Name"), systemImage: "pencil")
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .pbCard()
    }

    // MARK: - Avatar

    private var avatarCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.tr("Avatar"))
                .font(.headline)

            Button {
                isShowingAvatarSheet = true
            } label: {
                Label(L10n.tr("Choose Avatar"), systemImage: "square.grid.2x2")
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .pbCard()
    }

    // MARK: - Published Patterns

    private var publishedPatternsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.tr("Published Patterns"))
                .font(.headline)

            if profileStore.publishedPatterns.isEmpty {
                Text(L10n.tr("Publish a pattern from Create or Preview to show it here."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(profileStore.publishedPatterns) { pattern in
                    VStack(alignment: .leading, spacing: 12) {
                        PatternThumbnail(pattern: pattern, mode: .bead, height: 140)
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(pattern.title)
                                    .font(.headline)
                                Text(pattern.theme.title)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            PBChip(title: pattern.difficulty.title, accent: true)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .pbCard()
    }

    // MARK: - Helpers

    private func identityRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body.weight(.medium))
                .foregroundStyle(PixelBeadsTheme.ink)
        }
    }

    private func avatarImage(for avatar: Avatar) -> Image {
        if let presetID = avatar.presetId,
           let preset = MockData.presetAvatars.first(where: { $0.id == presetID }) {
            return Image(systemName: preset.symbol)
        }
        if avatar.patternId != nil {
            return Image(systemName: avatar.renderStyle == .bead ? "circle.grid.3x3.fill" : "square.grid.3x3.fill")
        }
        return Image(systemName: "person.crop.square")
    }
}
