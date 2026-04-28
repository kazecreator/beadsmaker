import SwiftUI
import StoreKit

struct ProfileView: View {
    @ObservedObject var sessionStore: AppSessionStore
    @ObservedObject var profileStore: ProfileStore
    @EnvironmentObject private var proStatusManager: ProStatusManager
    @EnvironmentObject private var appleSignInManager: AppleSignInManager
    @EnvironmentObject private var syncManager: iCloudSyncManager

    @State private var isShowingEditProfileSheet = false
    @State private var isShowingPrivacyPolicy = false
    @State private var isShowingProInfo = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    profileHeader
                    if profileStore.shouldShowDataLossRiskBanner {
                        dataLossRiskBanner
                    }
                    worksSection
                    legalSection
                }
                .padding(16)
            }
            .navigationTitle(L10n.tr("Profile"))
            .background(BeadsMakerTheme.surface)
            .sheet(isPresented: $isShowingEditProfileSheet) {
                AvatarPickerView(sessionStore: sessionStore, profileStore: profileStore)
            }
            .sheet(isPresented: $isShowingPrivacyPolicy) {
                PrivacyPolicyView()
            }
            .sheet(isPresented: $isShowingProInfo) {
                ProInfoView(sessionStore: sessionStore)
                    .environmentObject(proStatusManager)
                    .environmentObject(appleSignInManager)
            }
        }
        .pbScreen()
    }

    // MARK: - Header

    private var profileHeader: some View {
        HStack(alignment: .top, spacing: 16) {
            avatarPreview(for: sessionStore.currentUser.avatar, size: 72)

            VStack(alignment: .leading, spacing: 8) {
                Text(sessionStore.currentUser.displayName)
                    .font(.title2.bold())
                    .foregroundStyle(BeadsMakerTheme.ink)
                    .lineLimit(1)

                accountStatusLabel

                statusActions
            }

            Spacer()

            Button {
                isShowingEditProfileSheet = true
            } label: {
                Image(systemName: "pencil")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(BeadsMakerTheme.ink)
                    .frame(width: 34, height: 34)
                    .background(BeadsMakerTheme.surface)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.tr("Edit Profile"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .pbCard()
    }

    private var statusActions: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) {
                statusChips
                upgradeButton
            }

            VStack(alignment: .leading, spacing: 8) {
                statusChips
                upgradeButton
            }
        }
    }

    private var statusChips: some View {
        HStack(spacing: 8) {
            PBChip(
                title: sessionStore.currentUser.isPro ? L10n.tr("Pro") : L10n.tr("Free"),
                accent: sessionStore.currentUser.isPro
            )

            if sessionStore.currentUser.appleUserID != nil {
                PBChip(title: L10n.tr("Account linked"), accent: true)
            }

        }
    }

    @ViewBuilder
    private var upgradeButton: some View {
        if !sessionStore.currentUser.isPro {
            Button {
                isShowingProInfo = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "crown")
                    Text(L10n.tr("Upgrade to Pro"))
                        .lineLimit(1)
                    if let price = proStatusManager.product?.displayPrice {
                        Text(price)
                            .lineLimit(1)
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(BeadsMakerTheme.ink)
                .clipShape(RoundedRectangle(cornerRadius: BeadsMakerTheme.Radius.chip, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Identity

    private var dataLossRiskBanner: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "externaldrive.badge.exclamationmark")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(BeadsMakerTheme.ink)

                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.tr("Protect your drafts"))
                        .font(.headline)
                        .foregroundStyle(BeadsMakerTheme.ink)
                    Text(L10n.tr("Guest drafts stay on this device. If the app is deleted or the device is lost, your local work may be lost too."))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                if sessionStore.currentUser.isPro {
                    Button {
                        profileStore.dismissDataLossRiskBanner()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                            .padding(8)
                            .background(BeadsMakerTheme.canvas)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L10n.tr("Dismiss data loss reminder"))
                } else {
                    Button {
                        isShowingProInfo = true
                    } label: {
                        Text(L10n.tr("Upgrade"))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(BeadsMakerTheme.ink)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .pbCard()
    }

    // MARK: - Works

    private var worksSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(L10n.tr("My Works"))
                    .font(.headline)
                Spacer()
                if !profileStore.allWorks.isEmpty {
                    Text("\(profileStore.allWorks.count)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }

            if profileStore.allWorks.isEmpty {
                Text(L10n.tr("Drafts, saved patterns, and finished work appear here automatically."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3),
                    spacing: 20
                ) {
                    ForEach(profileStore.allWorks) { pattern in
                        stickerCell(for: pattern)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .pbCard()
    }

    // MARK: - Legal

    private var legalSection: some View {
        VStack(spacing: 0) {
            Button {
                isShowingProInfo = true
            } label: {
                legalRow(title: L10n.tr("BeadsMaker Pro"), systemImage: "crown")
            }

            Divider()
                .padding(.leading, 48)

            syncRow

            Divider()
                .padding(.leading, 48)

            Button {
                isShowingPrivacyPolicy = true
            } label: {
                legalRow(title: L10n.tr("Privacy Policy"), systemImage: "hand.raised")
            }

            Divider()
                .padding(.leading, 48)

            Link(destination: URL(string: "mailto:kazecreator@gmail.com")!) {
                legalRow(title: L10n.tr("Feedback"), systemImage: "envelope")
            }

            Divider()
                .padding(.leading, 48)

            Button {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    SKStoreReviewController.requestReview(in: windowScene)
                }
            } label: {
                legalRow(title: L10n.tr("Rate Us"), systemImage: "star")
            }
        }
        .pbCard()
    }

    private func legalRow(title: String, systemImage: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(BeadsMakerTheme.ink)
                .frame(width: 36, height: 36)
                .background(BeadsMakerTheme.canvas)
                .clipShape(Circle())

            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(BeadsMakerTheme.ink)

            Spacer()

            Image(systemName: "arrow.up.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    // MARK: - Sync

    private var syncRow: some View {
        HStack(spacing: 12) {
            Image(systemName: syncIconName)
                .font(.body.weight(.semibold))
                .foregroundStyle(syncIconColor)
                .frame(width: 36, height: 36)
                .background(BeadsMakerTheme.canvas)
                .clipShape(Circle())

            Text(L10n.tr("iCloud Sync"))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(BeadsMakerTheme.ink)

            Spacer()

            Toggle("", isOn: syncBinding)
                .labelsHidden()
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private var syncBinding: Binding<Bool> {
        Binding(
            get: {
                if case .syncing = syncManager.syncStatus { return true }
                if case .upToDate = syncManager.syncStatus { return true }
                return false
            },
            set: { wantsOn in
                if wantsOn {
                    guard sessionStore.currentUser.isPro else {
                        isShowingProInfo = true
                        return
                    }
                    syncManager.startSync()
                } else {
                    syncManager.stopSync()
                }
            }
        )
    }

    private var syncIconName: String {
        switch syncManager.syncStatus {
        case .unavailable, .notPro: return "icloud.slash"
        case .syncing:              return "icloud.and.arrow.down"
        case .upToDate:             return "checkmark.icloud"
        case .error:                return "xmark.icloud"
        }
    }

    private var syncIconColor: Color {
        switch syncManager.syncStatus {
        case .upToDate: return .green
        case .syncing:  return .blue
        case .error:    return .red
        default:        return BeadsMakerTheme.ink
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private var accountStatusLabel: some View {
        if sessionStore.currentUser.appleUserID != nil {
            Text(L10n.tr("Signed in with Apple"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        } else if !sessionStore.currentUser.isPro {
            Text(L10n.tr("Guest creator"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
    }

    @ViewBuilder
    private func avatarPreview(for avatar: Avatar, size: CGFloat) -> some View {
        if let presetID = avatar.presetId,
           let preset = MockData.presetAvatars.first(where: { $0.id == presetID }) {
            finishedAvatarPreview(for: preset.pattern, size: size)
        } else if avatar.type == .pattern, !sessionStore.currentUser.isPro {
            PBAvatarView(image: Image(systemName: "person.crop.square"), size: size)
        } else if let patternID = avatar.patternId,
                  let pattern = profileStore.allWorks.first(where: { $0.id == patternID })
                    ?? profileStore.eligiblePatterns.first(where: { $0.id == patternID }) {
            finishedAvatarPreview(for: pattern, size: size)
        } else {
            PBAvatarView(image: Image(systemName: "person.crop.square"), size: size)
        }
    }

    private func finishedAvatarPreview(for pattern: Pattern, size: CGFloat) -> some View {
        Image(uiImage: PatternImageRenderer.finishedImage(for: pattern, cellSize: 16, scale: 2))
            .resizable()
            .interpolation(.none)
            .scaledToFit()
            .frame(width: size, height: size)
            .padding(8)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: BeadsMakerTheme.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: BeadsMakerTheme.Radius.card, style: .continuous)
                    .stroke(BeadsMakerTheme.outline, lineWidth: 1)
            )
    }

    private func stickerCell(for pattern: Pattern) -> some View {
        VStack(spacing: 6) {
            Image(uiImage: PatternImageRenderer.finishedImage(for: pattern, cellSize: 16, scale: 2))
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(minHeight: 64)
                .shadow(color: .black.opacity(0.10), radius: 4, y: 3)

            Text(pattern.title.isEmpty ? L10n.tr("Untitled") : pattern.title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}
