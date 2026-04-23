import SwiftUI

struct ProfileView: View {
    @ObservedObject var sessionStore: AppSessionStore
    @ObservedObject var profileStore: ProfileStore

    @State private var isShowingAvatarSheet = false
    @State private var isShowingClaimHandleSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    profileHeader
                    guestPromptCard
                    identityCard
                    avatarCard
                    publishedPatternsSection
                    rulesCard
                }
                .padding(16)
            }
            .navigationTitle("Profile")
            .background(PixelBeadsTheme.surface)
            .sheet(isPresented: $isShowingAvatarSheet) {
                AvatarPickerView(sessionStore: sessionStore, profileStore: profileStore)
            }
            .sheet(isPresented: $isShowingClaimHandleSheet) {
                ClaimHandleView(sessionStore: sessionStore)
            }
        }
        .pbScreen()
    }

    private var profileHeader: some View {
        HStack(spacing: 16) {
            PBAvatarView(image: avatarImage(for: sessionStore.currentUser.avatar), size: 72)

            VStack(alignment: .leading, spacing: 6) {
                Text(sessionStore.currentUser.displayName)
                    .font(.title2.bold())
                Text(sessionStore.currentUser.publicHandle.map { "@\($0)" } ?? "Guest creator")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    PBChip(title: sessionStore.currentUser.isGuest ? "Guest" : "Claimed", accent: true)
                    PBChip(title: sessionStore.currentUser.avatar.renderStyle.title)
                }
            }
            Spacer()
        }
        .pbCard()
    }

    @ViewBuilder
    private var guestPromptCard: some View {
        if sessionStore.currentUser.isGuest {
            VStack(alignment: .leading, spacing: 12) {
                Text("Claim your handle when you’re ready")
                    .font(.headline)
                Text("Guest mode keeps browsing, drafting, exporting, and avatar selection open. Claim a unique handle to publish publicly.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button {
                    isShowingClaimHandleSheet = true
                } label: {
                    Label("Claim Handle", systemImage: "at")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .pbCard()
        }
    }

    private var identityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Identity")
                .font(.headline)

            identityRow(title: "Display Name", value: sessionStore.currentUser.displayName)
            identityRow(title: "Public Handle", value: sessionStore.currentUser.publicHandle.map { "@\($0)" } ?? "Not claimed yet")

            Button {
                isShowingClaimHandleSheet = true
            } label: {
                Label(sessionStore.currentUser.isClaimed ? "Edit Profile" : "Claim Handle", systemImage: sessionStore.currentUser.isClaimed ? "person.crop.circle.badge.checkmark" : "at")
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .pbCard()
    }

    private var avatarCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Avatar")
                .font(.headline)

            Text("Pick from bead-style presets or published square patterns, then render in pixel or bead style.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                isShowingAvatarSheet = true
            } label: {
                Label("Choose Avatar", systemImage: "square.grid.2x2")
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .pbCard()
    }

    private var publishedPatternsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Published Patterns")
                .font(.headline)

            if profileStore.publishedPatterns.isEmpty {
                Text("Publish a pattern from Create or Preview to show it here.")
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
                                Text(pattern.tags.first ?? "Community")
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

    private var rulesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Guest-first rules")
                .font(.headline)
            Text("Browse, create, save drafts, export, and use preset avatars without logging in.")
                .font(.subheadline)
            Text("Publishing unlocks after you claim a unique public handle.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .pbCard()
    }

    private func identityRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
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
