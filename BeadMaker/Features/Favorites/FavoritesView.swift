import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Query(sort: \CollectedPattern.modifiedAt, order: .reverse) private var favorites: [CollectedPattern]
    @Environment(\.modelContext) private var modelContext

    let searchText: String
    let onSelectFavorite: (CollectedPattern) -> Void
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
                            Button {
                                onSelectFavorite(favorite)
                            } label: {
                                FavoritePatternCardView(pattern: favorite)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button {
                                    let copy = duplicate(favorite)
                                    onCreateCopy(copy)
                                } label: {
                                    Label("生成副本", systemImage: "doc.on.doc")
                                }

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
        PatternCardView(
            name: pattern.name,
            width: pattern.width,
            height: pattern.height,
            thumbnailData: pattern.thumbnailData,
            isCollected: true,
            subtitle: pattern.author,
            badgeText: "收藏"
        )
    }
}

private extension FavoritesView {
    func duplicate(_ favorite: CollectedPattern) -> Pattern {
        let copy = Pattern(name: "\(favorite.name) 副本", width: favorite.width, height: favorite.height)
        copy.gridData = favorite.gridData
        copy.thumbnailData = PatternRenderer.thumbnail(pattern: copy).pngData()
        modelContext.insert(copy)
        try? modelContext.save()
        return copy
    }
}
