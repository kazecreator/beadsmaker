import SwiftUI

struct PatternDetailView: View {
    let pattern: Pattern
    let isLiked: Bool
    let isSaved: Bool
    let onLike: () -> Void
    let onSave: () -> Void
    let onRemix: () -> Void

    @State private var isShowingShareSheet = false

    private var category: String {
        pattern.tags.first ?? "Community"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    PatternThumbnail(pattern: pattern, mode: .comparison, height: 250)

                    VStack(alignment: .leading, spacing: 12) {
                        Text(pattern.title)
                            .font(.largeTitle.bold())
                            .foregroundStyle(PixelBeadsTheme.ink)

                        Text("Designed by \(pattern.authorName)")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 8) {
                            PBChip(title: pattern.difficulty.title, accent: true)
                            PBChip(title: category)
                            PBChip(title: pattern.visibility.title)
                        }

                        Text("Inspect the original pattern, save it to your library, or remix it into a new draft in the editor.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .pbCard()

                    HStack(spacing: 12) {
                        actionButton(title: isLiked ? "Liked" : "Like", systemImage: isLiked ? "heart.fill" : "heart", accent: isLiked, action: onLike)
                        actionButton(title: isSaved ? "Saved" : "Save", systemImage: isSaved ? "bookmark.fill" : "bookmark", accent: isSaved, action: onSave)
                    }

                    HStack(spacing: 12) {
                        actionButton(title: "Remix", systemImage: "wand.and.stars", accent: true, action: onRemix)
                        actionButton(title: "Share", systemImage: "square.and.arrow.up", accent: false) {
                            isShowingShareSheet = true
                        }
                    }

                    metricsCard
                }
                .padding(16)
            }
            .navigationTitle("Pattern Detail")
            .navigationBarTitleDisplayMode(.inline)
            .pbScreen()
        }
        .sheet(isPresented: $isShowingShareSheet) {
            ShareActivityView(activityItems: [PatternImageRenderer.image(for: pattern, mode: .comparison, scale: 2).pngData() ?? Data()])
        }
    }

    private var metricsCard: some View {
        HStack(spacing: 12) {
            metricColumn(value: "\(pattern.likeCount + (isLiked ? 1 : 0))", label: "Likes")
            metricColumn(value: "\(pattern.saveCount + (isSaved ? 1 : 0))", label: "Saves")
            metricColumn(value: "\(pattern.width)×\(pattern.height)", label: "Grid")
        }
        .pbCard()
    }

    private func metricColumn(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(PixelBeadsTheme.ink)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func actionButton(title: String, systemImage: String, accent: Bool, action: @escaping () -> Void) -> some View {
        Group {
            if accent {
                Button(action: action) {
                    Label(title, systemImage: systemImage)
                }
                .buttonStyle(PrimaryButtonStyle())
            } else {
                Button(action: action) {
                    Label(title, systemImage: systemImage)
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
    }
}
