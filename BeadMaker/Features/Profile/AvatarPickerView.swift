import SwiftUI
import SwiftData

struct AvatarPickerView: View {
    var profile: UserProfile
    @Query(sort: \Pattern.modifiedAt, order: .reverse) private var patterns: [Pattern]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPresetId: Int?
    @State private var selectedPatternIndex: Int?

    private let columns = [GridItem(.adaptive(minimum: 72), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    presetSection
                    if !patterns.isEmpty { patternSection }
                }
                .padding()
            }
            .navigationTitle("选择头像")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("确定") { applyAndDismiss() }
                        .bold()
                        .disabled(selectedPresetId == nil && selectedPatternIndex == nil)
                }
            }
        }
        .onAppear { loadCurrent() }
    }

    // MARK: - Sections

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("预设像素头像", systemImage: "sparkles").font(.headline)
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(PixelAvatarLibrary.avatars) { avatar in
                    avatarCell(
                        image: avatar.render(pixelSize: 8),
                        label: avatar.name,
                        isSelected: selectedPresetId == avatar.id && selectedPatternIndex == nil
                    ) {
                        selectedPresetId = avatar.id
                        selectedPatternIndex = nil
                    }
                }
            }
        }
    }

    private var patternSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("我的拼豆图纸", systemImage: "photo.on.rectangle").font(.headline)
            Text("选择一张图纸作为头像").font(.caption).foregroundStyle(.secondary)
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Array(patterns.enumerated()), id: \.offset) { idx, pattern in
                    if let data = pattern.thumbnailData, let img = UIImage(data: data) {
                        avatarCell(
                            image: img,
                            label: pattern.name,
                            isSelected: selectedPatternIndex == idx && selectedPresetId == nil
                        ) {
                            selectedPatternIndex = idx
                            selectedPresetId = nil
                        }
                    }
                }
            }
        }
    }

    // MARK: - Cell

    @ViewBuilder
    private func avatarCell(image: UIImage, label: String, isSelected: Bool, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.25),
                                    lineWidth: isSelected ? 3 : 1)
                    )
                    .shadow(color: isSelected ? Color.accentColor.opacity(0.35) : .clear, radius: 5)
                    .scaleEffect(isSelected ? 1.08 : 1.0)
                    .animation(.spring(duration: 0.2), value: isSelected)

                Text(label)
                    .font(.caption2)
                    .lineLimit(1)
                    .foregroundStyle(.primary)
                    .frame(width: 60)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Logic

    private func loadCurrent() {
        if profile.isPreset {
            selectedPresetId = profile.presetAvatarIndex
        } else {
            // pattern avatar: leave unselected (thumbnail data already applied)
        }
    }

    private func applyAndDismiss() {
        if let presetId = selectedPresetId {
            profile.avatarType = "preset"
            profile.presetAvatarIndex = presetId
            profile.customAvatarData = nil
        } else if let idx = selectedPatternIndex, idx < patterns.count {
            profile.avatarType = "pattern"
            profile.customAvatarData = patterns[idx].thumbnailData
        }
        try? modelContext.save()
        dismiss()
    }
}
