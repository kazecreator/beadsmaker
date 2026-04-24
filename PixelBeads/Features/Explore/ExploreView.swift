import SwiftUI

struct ExploreView: View {
    @ObservedObject var sessionStore: AppSessionStore
    @ObservedObject var exploreStore: ExploreStore
    @ObservedObject var createStore: CreateStore
    @ObservedObject var libraryStore: LibraryStore
    @Binding var selectedTab: AppTab

    @State private var selectedPattern: Pattern?
    @State private var isShowingDraftLimitAlert = false
    private let deviceID = DeviceIdentity.deviceID

    var body: some View {
        NavigationStack {
            ZStack {
                PixelBeadsTheme.surface.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        exploreControls

                        if let bannerMessage = exploreStore.bannerMessage {
                            Text(bannerMessage)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(PixelBeadsTheme.ink)
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(PixelBeadsTheme.coral.opacity(0.10))
                                .clipShape(RoundedRectangle(cornerRadius: PixelBeadsTheme.Radius.chip, style: .continuous))
                        }

                        if exploreStore.isLoading && exploreStore.patterns.isEmpty {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 48)
                        }

                        ForEach(exploreStore.patterns) { pattern in
                            ExplorePatternCard(
                                pattern: pattern,
                                isSaved: exploreStore.isSaved(pattern),
                                onOpenDetail: {
                                    selectedPattern = pattern
                                },
                                onCollect: {
                                    Task {
                                        await exploreStore.toggleSave(
                                            pattern,
                                            user: sessionStore.currentUser,
                                            deviceID: deviceID
                                        )
                                        libraryStore.load(for: sessionStore.currentUser)
                                    }
                                },
                                onRemix: {
                                    remix(pattern)
                                }
                            )
                        }

                        if exploreStore.hasMore {
                            loadMoreSection
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("PixelBeads")
            .sheet(item: $selectedPattern) { pattern in
                PatternDetailView(
                    exploreStore: exploreStore,
                    pattern: pattern,
                    onCollect: {
                        Task {
                            await exploreStore.toggleSave(
                                pattern,
                                user: sessionStore.currentUser,
                                deviceID: deviceID
                            )
                            libraryStore.load(for: sessionStore.currentUser)
                        }
                    },
                    onRemix: {
                        remix(pattern)
                        selectedPattern = nil
                    },
                    currentUser: sessionStore.currentUser
                )
                .presentationDetents([.large])
            }
            .refreshable {
                await exploreStore.load(
                    for: sessionStore.currentUser,
                    deviceID: deviceID,
                    forceRefresh: true
                )
            }
        }
        .task(id: sessionStore.currentUser.id) {
            await exploreStore.load(for: sessionStore.currentUser, deviceID: deviceID)
        }
        .alert(L10n.tr("Draft Limit Reached"), isPresented: $isShowingDraftLimitAlert) {
            Button(L10n.tr("OK"), role: .cancel) { }
        } message: {
            Text(L10n.tr("You've reached the 20-draft limit. Delete a draft to make room, or upgrade to Pro for unlimited drafts."))
        }
        .pbScreen()
    }

    private var exploreControls: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(ExploreSortMode.allCases) { mode in
                    Button {
                        Task {
                            await exploreStore.setSortMode(mode, user: sessionStore.currentUser, deviceID: deviceID)
                        }
                    } label: {
                        PBChip(title: mode.title, accent: exploreStore.sortMode == mode)
                    }
                    .buttonStyle(.plain)
                }

                filterMenu(title: exploreStore.filters.theme?.title ?? L10n.tr("Theme"), accent: exploreStore.filters.theme != nil) {
                    Button(L10n.tr("All Themes")) {
                        Task {
                            await exploreStore.updateTheme(nil, user: sessionStore.currentUser, deviceID: deviceID)
                        }
                    }
                    ForEach(PatternTheme.allCases) { theme in
                        Button(theme.title) {
                            Task {
                                await exploreStore.updateTheme(theme, user: sessionStore.currentUser, deviceID: deviceID)
                            }
                        }
                    }
                }

                filterMenu(title: exploreStore.filters.difficulty?.title ?? L10n.tr("Difficulty"), accent: exploreStore.filters.difficulty != nil) {
                    Button(L10n.tr("All Difficulties")) {
                        Task {
                            await exploreStore.updateDifficulty(nil, user: sessionStore.currentUser, deviceID: deviceID)
                        }
                    }
                    ForEach(DifficultyLevel.allCases) { difficulty in
                        Button(difficulty.title) {
                            Task {
                                await exploreStore.updateDifficulty(difficulty, user: sessionStore.currentUser, deviceID: deviceID)
                            }
                        }
                    }
                }

                filterMenu(title: exploreStore.filters.sizeTier?.title ?? L10n.tr("Size"), accent: exploreStore.filters.sizeTier != nil) {
                    Button(L10n.tr("All Sizes")) {
                        Task {
                            await exploreStore.updateSizeTier(nil, user: sessionStore.currentUser, deviceID: deviceID)
                        }
                    }
                    ForEach(PatternSizeTier.allCases) { sizeTier in
                        Button(sizeTier.title) {
                            Task {
                                await exploreStore.updateSizeTier(sizeTier, user: sessionStore.currentUser, deviceID: deviceID)
                            }
                        }
                    }
                }

                if exploreStore.hasActiveFilters {
                    Button {
                        Task {
                            await exploreStore.clearFilters(user: sessionStore.currentUser, deviceID: deviceID)
                        }
                    } label: {
                        PBChip(title: L10n.tr("Clear"))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var loadMoreSection: some View {
        Group {
            if exploreStore.isLoadingMore {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(.vertical, 20)
            } else {
                Button {
                    Task {
                        await exploreStore.loadMore(for: sessionStore.currentUser, deviceID: deviceID)
                    }
                } label: {
                    Text(L10n.tr("Load More"))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(PixelBeadsTheme.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: PixelBeadsTheme.Radius.small, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: PixelBeadsTheme.Radius.small, style: .continuous)
                                .stroke(PixelBeadsTheme.outline, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .padding(.vertical, 10)
            }
        }
    }

    private func filterMenu<Content: View>(title: String, accent: Bool, @ViewBuilder content: () -> Content) -> some View {
        Menu {
            content()
        } label: {
            PBChip(title: title, accent: accent)
        }
    }

    private func remix(_ pattern: Pattern) {
        let ok = createStore.loadTemplate(
            pattern,
            user: sessionStore.currentUser,
            library: libraryStore.content
        )
        if ok {
            libraryStore.load(for: sessionStore.currentUser)
            selectedTab = .create
        } else {
            isShowingDraftLimitAlert = true
        }
    }
}

private struct ExplorePatternCard: View {
    let pattern: Pattern
    let isSaved: Bool
    let onOpenDetail: () -> Void
    let onCollect: () -> Void
    let onRemix: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            PatternThumbnail(pattern: pattern, mode: .bead, height: 150)
                .onTapGesture(perform: onOpenDetail)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(pattern.title)
                        .font(.headline)
                        .foregroundStyle(PixelBeadsTheme.ink)
                    Text(L10n.tr("by %@", pattern.authorName))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        PBChip(title: pattern.difficulty.title, accent: pattern.difficulty == .easy)
                        PBChip(title: pattern.theme.title)
                    }
                }

                Spacer()

                Label("\(pattern.saveCount + (isSaved ? 1 : 0))", systemImage: isSaved ? "heart.fill" : "heart")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isSaved ? PixelBeadsTheme.coral : PixelBeadsTheme.ink)
            }

            HStack(spacing: 10) {
                smallActionButton(
                    title: isSaved ? "Saved" : "Save",
                    systemImage: isSaved ? "heart.fill" : "heart",
                    action: onCollect
                )
                smallActionButton(title: "Remix", systemImage: "wand.and.stars", action: onRemix)
                smallActionButton(title: "Details", systemImage: "chevron.right", action: onOpenDetail)
            }
        }
        .pbCard()
    }

    private func smallActionButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(L10n.tr(title), systemImage: systemImage)
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
        Group {
            if let thumbnailURL = pattern.thumbnailURL {
                AsyncImage(url: thumbnailURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                    default:
                        fallbackThumbnail
                    }
                }
            } else {
                fallbackThumbnail
            }
        }
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

    private var fallbackThumbnail: some View {
        let image = PatternImageRenderer.image(for: pattern, mode: mode)
        return Image(uiImage: image)
            .resizable()
            .interpolation(.none)
            .scaledToFit()
    }
}
