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
                        subtitle: "Browse creator-made bead patterns, then remix or save without logging in."
                    )

                    guestHighlightCard

                    ForEach(exploreStore.patterns) { pattern in
                        Button {
                            selectedPattern = pattern
                        } label: {
                            ExplorePatternCard(
                                pattern: pattern,
                                isLiked: exploreStore.likedPatternIDs.contains(pattern.id),
                                isSaved: exploreStore.savedPatternIDs.contains(pattern.id)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .background(PixelBeadsTheme.surface)
            .navigationTitle("PixelBeads")
            .sheet(item: $selectedPattern) { pattern in
                PatternDetailSheet(
                    pattern: pattern,
                    isLiked: exploreStore.likedPatternIDs.contains(pattern.id),
                    isSaved: exploreStore.savedPatternIDs.contains(pattern.id),
                    onLike: {
                        exploreStore.toggleLike(pattern, user: sessionStore.currentUser)
                    },
                    onSave: {
                        exploreStore.toggleSave(pattern, user: sessionStore.currentUser)
                        libraryStore.load(for: sessionStore.currentUser)
                    },
                    onUseTemplate: {
                        createStore.loadTemplate(pattern, user: sessionStore.currentUser)
                        selectedTab = .create
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
                PBChip(title: "Export in 1 tap")
                Spacer()
            }

            Text("Make patterns first. Claim a handle only when you’re ready to publish.")
                .font(.headline)
                .foregroundStyle(PixelBeadsTheme.ink)

            Text("No progress bars, no forced onboarding — just browse, remix, and export.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .pbCard()
    }
}

private struct ExplorePatternCard: View {
    let pattern: Pattern
    let isLiked: Bool
    let isSaved: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            PatternThumbnail(pattern: pattern, mode: .bead, height: 150)

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
                        ForEach(pattern.tags.prefix(2), id: \.self) { tag in
                            PBChip(title: tag)
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    Label("\(pattern.likeCount)", systemImage: isLiked ? "heart.fill" : "heart")
                    Label("\(pattern.saveCount)", systemImage: isSaved ? "bookmark.fill" : "bookmark")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(PixelBeadsTheme.ink)
            }
        }
        .pbCard()
    }
}

private struct PatternDetailSheet: View {
    let pattern: Pattern
    let isLiked: Bool
    let isSaved: Bool
    let onLike: () -> Void
    let onSave: () -> Void
    let onUseTemplate: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    PatternThumbnail(pattern: pattern, mode: .comparison, height: 220)

                    VStack(alignment: .leading, spacing: 12) {
                        Text(pattern.title)
                            .font(.largeTitle.bold())
                        Text("Designed by \(pattern.authorName)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 8) {
                            PBChip(title: pattern.difficulty.title, accent: true)
                            ForEach(pattern.tags, id: \.self) { tag in
                                PBChip(title: tag)
                            }
                        }

                        Text("Use this pattern as a template, inspect it in bead view, or save it to your local library.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .pbCard()

                    HStack(spacing: 12) {
                        Button(action: onLike) {
                            Label(isLiked ? "Liked" : "Like", systemImage: isLiked ? "heart.fill" : "heart")
                        }
                        .buttonStyle(SecondaryButtonStyle())

                        Button(action: onSave) {
                            Label(isSaved ? "Saved" : "Save", systemImage: isSaved ? "bookmark.fill" : "bookmark")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }

                    Button(action: onUseTemplate) {
                        Label("Use Template", systemImage: "wand.and.stars")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(16)
            }
            .navigationTitle("Pattern Detail")
            .navigationBarTitleDisplayMode(.inline)
            .pbScreen()
        }
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
