import SwiftUI

struct ProfileView: View {
    @ObservedObject var sessionStore: AppSessionStore
    @ObservedObject var profileStore: ProfileStore

    @State private var isShowingAvatarSheet = false
    @State private var handleInput = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    profileHeader
                    claimHandleCard
                    avatarCard
                    rulesCard
                }
                .padding(16)
            }
            .navigationTitle("Profile")
            .background(PixelBeadsTheme.surface)
            .sheet(isPresented: $isShowingAvatarSheet) {
                AvatarPickerSheet(sessionStore: sessionStore, profileStore: profileStore)
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

    private var claimHandleCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Claim handle")
                .font(.headline)
            Text("Only required when publishing. Display names stay flexible and non-unique.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TextField("pixelmaker", text: $handleInput)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)

            if let error = sessionStore.claimError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(PixelBeadsTheme.coral)
            }

            Button {
                sessionStore.claimHandle(handleInput)
            } label: {
                Label(sessionStore.currentUser.isClaimed ? "Update Handle" : "Claim Handle", systemImage: "at")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .pbCard()
    }

    private var avatarCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Avatar")
                .font(.headline)

            Picker("Style", selection: $profileStore.selectedRenderStyle) {
                ForEach(AvatarRenderStyle.allCases) { style in
                    Text(style.title).tag(style)
                }
            }
            .pickerStyle(.segmented)

            Button {
                isShowingAvatarSheet = true
            } label: {
                Label("Choose Avatar", systemImage: "square.grid.2x2")
            }
            .buttonStyle(SecondaryButtonStyle())
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

    private func avatarImage(for avatar: Avatar) -> Image {
        if let presetID = avatar.presetId {
            return Image(systemName: iconName(for: presetID))
        }

        if avatar.patternId != nil {
            return Image(systemName: avatar.renderStyle == .bead ? "circle.grid.3x3.fill" : "square.grid.3x3.fill")
        }

        return Image(systemName: "person.crop.square")
    }

    private func iconName(for presetID: String) -> String {
        switch presetID {
        case "coral-cat": return "cat.fill"
        case "mono-heart": return "heart.fill"
        case "mini-star": return "star.fill"
        default: return "face.smiling"
        }
    }
}

private struct AvatarPickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var sessionStore: AppSessionStore
    @ObservedObject var profileStore: ProfileStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Preset Avatars")
                        .font(.headline)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 12)], spacing: 12) {
                        ForEach(profileStore.presetAvatars, id: \.self) { avatar in
                            Button {
                                var selected = avatar
                                selected.renderStyle = profileStore.selectedRenderStyle
                                sessionStore.updateAvatar(selected)
                                dismiss()
                            } label: {
                                VStack(spacing: 10) {
                                    PBAvatarView(image: avatarPreview(for: avatar), size: 48)
                                    Text(avatar.presetId ?? "Preset")
                                        .font(.caption)
                                        .foregroundStyle(PixelBeadsTheme.ink)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.plain)
                            .pbCard()
                        }
                    }

                    Text("Pattern Avatars")
                        .font(.headline)

                    if profileStore.eligiblePatterns.isEmpty {
                        Text("Finalize a square pattern to use it as an avatar.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .pbCard()
                    } else {
                        ForEach(profileStore.eligiblePatterns) { pattern in
                            Button {
                                if let avatar = profileStore.makePatternAvatar(from: pattern) {
                                    sessionStore.updateAvatar(avatar)
                                    dismiss()
                                }
                            } label: {
                                HStack(spacing: 14) {
                                    PatternThumbnail(pattern: pattern, mode: profileStore.selectedRenderStyle == .bead ? .bead : .pixel, height: 88)
                                        .frame(width: 88)
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(pattern.title)
                                            .font(.headline)
                                        Text("Square + final patterns can become community avatars.")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)
                            .pbCard()
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle("Choose Avatar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .pbScreen()
        }
    }

    private func avatarPreview(for avatar: Avatar) -> Image {
        switch avatar.presetId {
        case "coral-cat": return Image(systemName: "cat.fill")
        case "mono-heart": return Image(systemName: "heart.fill")
        case "mini-star": return Image(systemName: "star.fill")
        default: return Image(systemName: "face.smiling")
        }
    }
}
