import SwiftUI
import SwiftData

struct FavoriteDetailView: View {
    let favorite: CollectedPattern
    let onCreateCopy: (Pattern) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                IronedPatternView(
                    width: favorite.width,
                    height: favorite.height,
                    gridData: favorite.gridData
                )
                .frame(height: 320)
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 12) {
                    Text(favorite.name)
                        .font(.title2.weight(.bold))

                    Text("by \(favorite.author)")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Label("\(favorite.width) × \(favorite.height)", systemImage: "ruler")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
        }
        .navigationTitle("收藏图纸")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 12) {
                Button("取消") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Button("创建副本") {
                    let copy = createCopy()
                    dismiss()
                    onCreateCopy(copy)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(.regularMaterial)
        }
    }

    @discardableResult
    private func createCopy() -> Pattern {
        let copy = Pattern(name: "\(favorite.name) - 副本", width: favorite.width, height: favorite.height)
        copy.gridData = favorite.gridData
        copy.thumbnailData = favorite.thumbnailData
        modelContext.insert(copy)
        try? modelContext.save()
        return copy
    }
}
