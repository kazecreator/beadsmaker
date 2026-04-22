import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Query(sort: \CollectedPattern.modifiedAt, order: .reverse) private var favorites: [CollectedPattern]
    @Environment(\.modelContext) private var modelContext

    let searchText: String
    let onCreateCopy: (Pattern) -> Void

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]

    private var filteredFavorites: [CollectedPattern] {
        guard !searchText.isEmpty else { return favorites }

        return favorites.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.author.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        Group {
            if favorites.isEmpty {
                ContentUnavailableView {
                    Label("还没有收藏", systemImage: "heart")
                } description: {
                    Text("还没有收藏，扫码添加")
                }
            } else if filteredFavorites.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(filteredFavorites) { favorite in
                            NavigationLink {
                                FavoriteDetailView(favorite: favorite, onCreateCopy: onCreateCopy)
                            } label: {
                                FavoritePatternCardView(pattern: favorite)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    modelContext.delete(favorite)
                                    try? modelContext.save()
                                } label: {
                                    Label("移出收藏", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(16)
                }
                .refreshable {
                    await FavoriteImportService.refreshAll(favorites: favorites, in: modelContext)
                }
            }
        }
    }
}

private struct FavoritePatternCardView: View {
    let pattern: CollectedPattern

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                Color(.systemFill)

                if let data = pattern.thumbnailData,
                   let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                } else {
                    Image(systemName: "heart.text.square")
                        .font(.system(size: 30))
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(pattern.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                Text(pattern.author)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text("\(pattern.width) × \(pattern.height)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
