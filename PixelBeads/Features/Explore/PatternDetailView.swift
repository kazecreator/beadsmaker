import SwiftUI

struct PatternDetailView: View {
    @ObservedObject var exploreStore: ExploreStore
    let pattern: Pattern
    let onCollect: () -> Void
    let onRemix: () -> Void
    let currentUser: User
    /// false when pushed via navigationDestination from another PatternDetailView.
    /// The parent's NavigationStack is reused — no nested stack is created.
    var isRoot: Bool = true

    @State private var relatedPatterns: [Pattern] = []
    @State private var isLoadingRelated = false
    @State private var isShowingShareSheet = false
    @State private var pushedPattern: Pattern?
    private let deviceID = DeviceIdentity.deviceID

    private var isSaved: Bool {
        exploreStore.isSaved(pattern)
    }

    private var category: String {
        pattern.tags.first ?? "Community"
    }

    var body: some View {
        if isRoot {
            NavigationStack {
                detailContent
            }
            .sheet(isPresented: $isShowingShareSheet) { shareSheet }
        } else {
            detailContent
                .sheet(isPresented: $isShowingShareSheet) { shareSheet }
        }
    }

    // MARK: - Main content (shared between root and pushed)

    @ViewBuilder
    private var detailContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PatternThumbnail(pattern: pattern, mode: .comparison, height: 250)

                VStack(alignment: .leading, spacing: 12) {
                    Text(pattern.title)
                        .font(.largeTitle.bold())
                        .foregroundStyle(PixelBeadsTheme.ink)

                    Text(L10n.tr("Designed by %@", pattern.authorName))
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        PBChip(title: pattern.difficulty.title, accent: true)
                        PBChip(title: pattern.theme.title)
                        PBChip(title: pattern.visibility.title)
                    }

                    Text(L10n.tr("Inspect the original pattern, save it to your library, or remix it into a new draft in the editor."))
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .pbCard()

                HStack(spacing: 12) {
                    actionButton(
                        title: isSaved ? "Saved" : "Save",
                        systemImage: isSaved ? "heart.fill" : "heart",
                        accent: isSaved,
                        action: onCollect
                    )
                    actionButton(title: "Remix", systemImage: "wand.and.stars", accent: true, action: onRemix)
                }

                HStack(spacing: 12) {
                    actionButton(title: "Share", systemImage: "square.and.arrow.up", accent: false) {
                        isShowingShareSheet = true
                    }
                }

                metricsCard

                if !relatedPatterns.isEmpty {
                    authorOtherWorksSection
                } else if isLoadingRelated {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .padding(.vertical, 20)
                }
            }
            .padding(16)
        }
        .navigationTitle(pattern.title.isEmpty ? L10n.tr("Pattern Detail") : pattern.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $pushedPattern) { related in
            PatternDetailView(
                exploreStore: exploreStore,
                pattern: related,
                onCollect: {
                    Task {
                        await exploreStore.toggleSave(related, user: currentUser, deviceID: deviceID)
                    }
                },
                onRemix: {
                    // Dismiss the full sheet (handled by ExploreView), which also unwinds the nav stack
                    onRemix()
                },
                currentUser: currentUser,
                isRoot: false
            )
        }
        .pbScreen()
        .task(id: pattern.id) {
            await loadRelatedPatterns()
        }
    }

    // MARK: - Author's other works

    private var authorOtherWorksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.tr("More by %@", pattern.authorName))
                .font(.headline)
                .foregroundStyle(PixelBeadsTheme.ink)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(relatedPatterns) { relatedPattern in
                        RelatedPatternCard(
                            pattern: relatedPattern,
                            isSaved: exploreStore.isSaved(relatedPattern),
                            onTap: {
                                pushedPattern = relatedPattern
                            },
                            onCollect: {
                                Task {
                                    await exploreStore.toggleSave(
                                        relatedPattern,
                                        user: currentUser,
                                        deviceID: deviceID
                                    )
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 2)
                .padding(.bottom, 4)
            }
        }
        .pbCard()
    }

    private func loadRelatedPatterns() async {
        isLoadingRelated = true
        relatedPatterns = await exploreStore.relatedPatterns(for: pattern, limit: 6)
        isLoadingRelated = false
    }

    // MARK: - Share sheet content

    private var shareSheet: some View {
        ShareActivityView(activityItems: [
            PatternImageRenderer.image(for: pattern, mode: .comparison, scale: 2).pngData() ?? Data()
        ])
    }

    private var metricsCard: some View {
        HStack(spacing: 12) {
            metricColumn(value: "\(pattern.saveCount + (isSaved ? 1 : 0))", label: "Saves")
            metricColumn(value: "\(pattern.width)×\(pattern.height)", label: "Grid")
            metricColumn(value: pattern.difficulty.title, label: "Difficulty")
        }
        .pbCard()
    }

    private func metricColumn(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(PixelBeadsTheme.ink)
            Text(L10n.tr(label))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func actionButton(title: String, systemImage: String, accent: Bool, action: @escaping () -> Void) -> some View {
        Group {
            if accent {
                Button(action: action) {
                    Label(L10n.tr(title), systemImage: systemImage)
                }
                .buttonStyle(PrimaryButtonStyle())
            } else {
                Button(action: action) {
                    Label(L10n.tr(title), systemImage: systemImage)
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
    }
}

private struct RelatedPatternCard: View {
    let pattern: Pattern
    let isSaved: Bool
    let onTap: () -> Void
    let onCollect: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                PatternThumbnail(pattern: pattern, mode: .bead, height: 100)
                    .frame(width: 140)

                Text(pattern.title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(PixelBeadsTheme.ink)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Button(action: onCollect) {
                        Image(systemName: isSaved ? "heart.fill" : "heart")
                            .font(.caption)
                            .foregroundStyle(isSaved ? PixelBeadsTheme.coral : PixelBeadsTheme.ink)
                    }
                    .buttonStyle(.plain)

                    Text("\(pattern.saveCount + (isSaved ? 1 : 0))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 140)
        }
        .buttonStyle(.plain)
    }
}
