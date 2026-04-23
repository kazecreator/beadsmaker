import SwiftUI

struct ExploreView: View {
    @ObservedObject var sessionStore: AppSessionStore
    @ObservedObject var exploreStore: ExploreStore
    @ObservedObject var createStore: CreateStore
    @ObservedObject var libraryStore: LibraryStore
    @Binding var selectedTab: AppTab

    @State private var selectedPattern: Pattern?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    PBSectionHeader(
                        title: "Explore",
                        subtitle: "Browse creator-made bead patterns, then like, save, or remix them into your own drafts."
                    )

                    guestHighlightCard

                    ForEach(exploreStore.patterns) { pattern in
                        ExplorePatternCard(
                            pattern: pattern,
                            isLiked: exploreStore.isLiked(pattern),
                            isSaved: exploreStore.isSaved(pattern),
                            onOpenDetail: {
                                selectedPattern = pattern
                            },
                            onLike: {
                                exploreStore.toggleLike(pattern, user: sessionStore.currentUser)
                            },
                            onSave: {
                                exploreStore.toggleSave(pattern, user: sessionStore.currentUser)
                                libraryStore.load(for: sessionStore.currentUser)
                            },
                            onRemix: {
                                remix(pattern)
                            }
                        )
                    }
                }
                .padding(16)
            }
            .background(PixelBeadsTheme.surface)
            .navigationTitle("PixelBeads")
            .sheet(item: $selectedPattern) { pattern in
                PatternDetailView(
                    pattern: pattern,
                    isLiked: exploreStore.isLiked(pattern),
                    isSaved: exploreStore.isSaved(pattern),
                    onLike: {
                        exploreStore.toggleLike(pattern, user: sessionStore.currentUser)
                    },
                    onSave: {
                        exploreStore.toggleSave(pattern, user: sessionStore.currentUser)
                        libraryStore.load(for: sessionStore.currentUser)
                    },
                    onRemix: {
                        remix(pattern)
                        selectedPattern = nil
                    }
                )
                .presentationDetents([.large])
            }
        }
        .pbScreen()
    }

    private var guestHighlightCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                PBChip(title: sessionStore.currentUser.isGuest ? "Guest-first" : "Claimed Handle", accent: true)
                PBChip(title: "Remix ready")
                Spacer()
            }

            Text("Make patterns first. Claim a handle only when you’re ready to publish.")
                .font(.headline)
                .foregroundStyle(PixelBeadsTheme.ink)

            Text("Like, save, and remix without leaving the feed. Community supports creation — not the other way around.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .pbCard()
    }

    private func remix(_ pattern: Pattern) {
        createStore.loadTemplate(pattern, user: sessionStore.currentUser)
        libraryStore.load(for: sessionStore.currentUser)
        selectedTab = .create
    }
}

private struct ExplorePatternCard: View {
    let pattern: Pattern
    let isLiked: Bool
    let isSaved: Bool
    let onOpenDetail: () -> Void
    let onLike: () -> Void
    let onSave: () -> Void
    let onRemix: () -> Void

    private var displayLikeCount: Int { pattern.likeCount + (isLiked ? 1 : 0) }
    private var displaySaveCount: Int { pattern.saveCount + (isSaved ? 1 : 0) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            PatternThumbnail(pattern: pattern, mode: .bead, height: 150)
                .onTapGesture(perform: onOpenDetail)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(pattern.title)
                        .font(.headline)
                        .foregroundStyle(PixelBeadsTheme.ink)
                    Text("by \(pattern.authorName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        PBChip(title: pattern.difficulty.title, accent: pattern.difficulty == .easy)
                        PBChip(title: pattern.tags.first ?? "Community")
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    Label("\(displayLikeCount)", systemImage: isLiked ? "heart.fill" : "heart")
                    Label("\(displaySaveCount)", systemImage: isSaved ? "bookmark.fill" : "bookmark")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(PixelBeadsTheme.ink)
            }

            HStack(spacing: 10) {
                smallActionButton(title: isLiked ? "Liked" : "Like", systemImage: isLiked ? "heart.fill" : "heart", action: onLike)
                smallActionButton(title: isSaved ? "Saved" : "Save", systemImage: isSaved ? "bookmark.fill" : "bookmark", action: onSave)
                smallActionButton(title: "Remix", systemImage: "wand.and.stars", action: onRemix)
                smallActionButton(title: "Details", systemImage: "chevron.right", action: onOpenDetail)
            }
        }
        .pbCard()
    }

    private func smallActionButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(PixelBeadsTheme.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: PixelBeadsTheme.Radius.small, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: PixelBeadsTheme.Radius.small, style: .continuous)
                        .stroke(PixelBeadsTheme.outline, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct PatternThumbnail: View {
    let pattern: Pattern
    let mode: PreviewMode
    var height: CGFloat

    var body: some View {
        let image = PatternImageRenderer.image(for: pattern, mode: mode)
        Image(uiImage: image)
            .resizable()
            .interpolation(.none)
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .padding(12)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: PixelBeadsTheme.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: PixelBeadsTheme.Radius.card, style: .continuous)
                    .stroke(PixelBeadsTheme.outline, lineWidth: 1)
            )
    }
}
