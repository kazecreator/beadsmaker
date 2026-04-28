import SwiftUI

struct AvatarPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var proStatusManager: ProStatusManager
    @EnvironmentObject private var appleSignInManager: AppleSignInManager

    @ObservedObject var sessionStore: AppSessionStore
    @ObservedObject var profileStore: ProfileStore

    @State private var draftAvatar: Avatar?
    @State private var displayName = ""
    @State private var isShowingPaywall = false
    @FocusState private var isNameFocused: Bool

    private let maxDisplayNameLength = 24

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    nameEditor
                    presetGrid
                    patternSection
                }
                .padding(16)
            }
            .navigationTitle(L10n.tr("Edit Profile"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.tr("Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.tr("Save Profile")) {
                        guard var selected = draftAvatar else { return }
                        selected.renderStyle = .bead
                        sessionStore.updateDisplayName(trimmedDisplayName)
                        sessionStore.updateAvatar(selected)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear {
                draftAvatar = sessionStore.currentUser.avatar
                displayName = sessionStore.currentUser.displayName
                profileStore.selectedRenderStyle = .bead
            }
            .onChange(of: displayName) { _, newValue in
                if newValue.count > maxDisplayNameLength {
                    displayName = String(newValue.prefix(maxDisplayNameLength))
                }
            }
            .pbScreen()
        }
        .sheet(isPresented: $isShowingPaywall) {
            PaywallView(sessionStore: sessionStore)
                .environmentObject(proStatusManager)
                .environmentObject(appleSignInManager)
        }
    }

    private var nameEditor: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(L10n.tr("Display Name"))
                    .font(.headline)
                    .foregroundStyle(BeadsMakerTheme.ink)

                Spacer()

                Text("\(displayName.count)/\(maxDisplayNameLength)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                TextField(L10n.tr("Pixel Maker"), text: $displayName)
                    .textInputAutocapitalization(.words)
                    .textContentType(.name)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .focused($isNameFocused)
                    .onSubmit {
                        isNameFocused = false
                    }

                if !displayName.isEmpty {
                    Button {
                        displayName = ""
                        isNameFocused = true
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L10n.tr("Clear"))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(BeadsMakerTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: BeadsMakerTheme.Radius.button, style: .continuous))

            if AppFeatureFlags.communityEnabled {
                Text(L10n.tr("Displays on published patterns"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .pbCard()
    }

    private var presetGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.tr("Preset Avatars"))
                .font(.headline)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
                ForEach(MockData.presetAvatars, id: \.id) { preset in
                    let avatar = Avatar(type: .preset, presetId: preset.id, patternId: nil, renderStyle: .bead)
                    Button {
                        draftAvatar = avatar
                    } label: {
                        VStack(spacing: 10) {
                            presetAvatarTile(for: preset.pattern)
                            Text(preset.title)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(BeadsMakerTheme.ink)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: BeadsMakerTheme.Radius.card, style: .continuous)
                                .stroke(isSelected(avatar) ? BeadsMakerTheme.ink : BeadsMakerTheme.outline, lineWidth: isSelected(avatar) ? 2 : 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: BeadsMakerTheme.Radius.card, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .pbCard()
    }

    private var patternSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.tr("Pattern-Based Avatar"))
                .font(.headline)

            if !sessionStore.currentUser.isPro {
                VStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .font(.title2)
                        .foregroundStyle(BeadsMakerTheme.ink)
                    Text(L10n.tr("Pattern avatars are a Pro feature."))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button {
                        isShowingPaywall = true
                    } label: {
                        Label(L10n.tr("Upgrade to Pro"), systemImage: "crown")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .frame(maxWidth: .infinity)
            } else if profileStore.eligiblePatterns.isEmpty {
                Text(L10n.tr("Create a square work to use it as your avatar."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(profileStore.eligiblePatterns) { pattern in
                    let avatar = Avatar(type: .pattern, presetId: nil, patternId: pattern.id, renderStyle: .bead)
                    Button {
                        draftAvatar = avatar
                    } label: {
                        HStack(spacing: 14) {
                            Image(uiImage: PatternImageRenderer.finishedImage(for: pattern, cellSize: 12, scale: 2))
                                .resizable()
                                .interpolation(.none)
                                .scaledToFit()
                                .frame(width: 84, height: 84)
                                .background(BeadsMakerTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: BeadsMakerTheme.Radius.small, style: .continuous))

                            VStack(alignment: .leading, spacing: 6) {
                                Text(pattern.title)
                                    .font(.headline)
                                    .foregroundStyle(BeadsMakerTheme.ink)
                                Text(L10n.tr("Square work"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: isSelected(avatar) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(isSelected(avatar) ? BeadsMakerTheme.ink : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .pbCard()
    }

    private func presetAvatarTile(for pattern: Pattern) -> some View {
        Image(uiImage: PatternImageRenderer.finishedImage(for: pattern, cellSize: 10, scale: 2))
            .resizable()
            .interpolation(.none)
            .scaledToFit()
            .frame(width: 56, height: 56)
            .padding(4)
            .background(BeadsMakerTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: BeadsMakerTheme.Radius.card, style: .continuous))
    }

    private var trimmedDisplayName: String {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        draftAvatar != nil && !trimmedDisplayName.isEmpty
    }

    private func isSelected(_ avatar: Avatar) -> Bool {
        guard let draftAvatar else { return false }
        return draftAvatar.type == avatar.type && draftAvatar.presetId == avatar.presetId && draftAvatar.patternId == avatar.patternId
    }
}
