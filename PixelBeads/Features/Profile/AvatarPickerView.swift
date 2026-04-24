import SwiftUI

struct AvatarPickerView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var sessionStore: AppSessionStore
    @ObservedObject var profileStore: ProfileStore

    @State private var draftAvatar: Avatar?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    stylePicker
                    presetGrid
                    patternSection
                }
                .padding(16)
            }
            .navigationTitle(L10n.tr("Choose Avatar"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L10n.tr("Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.tr("Done")) {
                        guard var selected = draftAvatar else { return }
                        selected.renderStyle = profileStore.selectedRenderStyle
                        sessionStore.updateAvatar(selected)
                        dismiss()
                    }
                    .disabled(draftAvatar == nil)
                }
            }
            .onAppear {
                draftAvatar = sessionStore.currentUser.avatar
                profileStore.selectedRenderStyle = sessionStore.currentUser.avatar.renderStyle
            }
            .pbScreen()
        }
    }

    private var stylePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.tr("Render Style"))
                .font(.headline)

            Picker("Render Style", selection: $profileStore.selectedRenderStyle) {
                ForEach(AvatarRenderStyle.allCases) { style in
                    Text(style.title).tag(style)
                }
            }
            .pickerStyle(.segmented)
        }
        .pbCard()
    }

    private var presetGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.tr("Preset Avatars"))
                .font(.headline)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
                ForEach(MockData.presetAvatars, id: \.id) { preset in
                    let avatar = Avatar(type: .preset, presetId: preset.id, patternId: nil, renderStyle: profileStore.selectedRenderStyle)
                    Button {
                        draftAvatar = avatar
                    } label: {
                        VStack(spacing: 10) {
                            avatarTile(symbol: preset.symbol)
                            Text(preset.title)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(PixelBeadsTheme.ink)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: PixelBeadsTheme.Radius.card, style: .continuous)
                                .stroke(isSelected(avatar) ? PixelBeadsTheme.coral : PixelBeadsTheme.outline, lineWidth: isSelected(avatar) ? 2 : 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: PixelBeadsTheme.Radius.card, style: .continuous))
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

            if profileStore.eligiblePatterns.isEmpty {
                Text(L10n.tr("Publish a square final pattern to unlock pattern-based avatars."))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(profileStore.eligiblePatterns) { pattern in
                    let avatar = Avatar(type: .pattern, presetId: nil, patternId: pattern.id, renderStyle: profileStore.selectedRenderStyle)
                    Button {
                        draftAvatar = avatar
                    } label: {
                        HStack(spacing: 14) {
                            PatternThumbnail(pattern: pattern, mode: profileStore.selectedRenderStyle == .bead ? .bead : .pixel, height: 84)
                                .frame(width: 84)

                            VStack(alignment: .leading, spacing: 6) {
                                Text(pattern.title)
                                    .font(.headline)
                                    .foregroundStyle(PixelBeadsTheme.ink)
                                Text(L10n.tr("Published square pattern"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: isSelected(avatar) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(isSelected(avatar) ? PixelBeadsTheme.coral : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .pbCard()
    }

    private func avatarTile(symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 28, weight: .semibold))
            .foregroundStyle(profileStore.selectedRenderStyle == .bead ? PixelBeadsTheme.coral : PixelBeadsTheme.ink)
            .frame(width: 56, height: 56)
            .background(profileStore.selectedRenderStyle == .bead ? PixelBeadsTheme.coral.opacity(0.12) : PixelBeadsTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: PixelBeadsTheme.Radius.card, style: .continuous))
    }

    private func isSelected(_ avatar: Avatar) -> Bool {
        guard let draftAvatar else { return false }
        return draftAvatar.type == avatar.type && draftAvatar.presetId == avatar.presetId && draftAvatar.patternId == avatar.patternId
    }
}
