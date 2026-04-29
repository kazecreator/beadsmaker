import SwiftUI

struct LibraryView: View {
    @ObservedObject var libraryStore: LibraryStore
    @ObservedObject var createStore: CreateStore
    @ObservedObject var sessionStore: AppSessionStore
    @Binding var selectedTab: AppTab

    @State private var draftToDelete: Pattern?
    @State private var isShowingDraftLimitAlert = false
    @State private var sharePattern: Pattern?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    segmentPicker

                    if libraryStore.displayedPatterns.isEmpty {
                        emptyState
                    } else {
                        patternList
                    }
                }
                .padding(16)
            }
            .navigationTitle(L10n.tr("Library"))
            .background(BeadsMakerTheme.surface)
        }
        .alert(L10n.tr("Draft Limit Reached"), isPresented: $isShowingDraftLimitAlert) {
            Button(L10n.tr("OK"), role: .cancel) { }
        } message: {
            Text(L10n.tr("You've reached the 20-draft limit. Delete a draft to make room, or upgrade to Pro for unlimited drafts."))
        }
        .alert(
            libraryStore.selectedSegment == .finished
                ? L10n.tr("Delete Finished Work?")
                : L10n.tr("Delete Draft?"),
            isPresented: Binding(
                get: { draftToDelete != nil },
                set: { if !$0 { draftToDelete = nil } }
            )
        ) {
            Button(L10n.tr("Delete"), role: .destructive) {
                if let pattern = draftToDelete {
                    if libraryStore.selectedSegment == .finished {
                        libraryStore.deleteFinished(id: pattern.id, for: sessionStore.currentUser)
                    } else {
                        libraryStore.deleteDraft(id: pattern.id, for: sessionStore.currentUser)
                    }
                }
                draftToDelete = nil
            }
            Button(L10n.tr("Cancel"), role: .cancel) {
                draftToDelete = nil
            }
        } message: {
            Text(
                libraryStore.selectedSegment == .finished
                    ? L10n.tr("This will permanently remove this finished work.")
                    : L10n.tr("This will permanently remove this draft.")
            )
        }
        .sheet(isPresented: Binding(
            get: { sharePattern != nil },
            set: { if !$0 { sharePattern = nil } }
        )) {
            if let pattern = sharePattern {
                PublishShareSheet(
                    pattern: pattern,
                    displayName: sessionStore.currentUser.displayName,
                    avatarPattern: avatarPatternForShare(),
                    onDone: {
                        libraryStore.selectedSegment = .finished
                    }
                )
            }
        }
        .pbScreen()
    }

    // MARK: - Subviews

    private var segmentPicker: some View {
        Picker(L10n.tr("Library"), selection: $libraryStore.selectedSegment) {
            ForEach(LibrarySegment.allCases) { segment in
                Text(segment.title).tag(segment)
            }
        }
        .pickerStyle(.segmented)
    }

    private var patternList: some View {
        ForEach(libraryStore.displayedPatterns) { pattern in
            if libraryStore.selectedSegment == .drafts {
                Button {
                    createStore.loadForEditing(pattern)
                    selectedTab = .create
                } label: {
                    patternCard(pattern)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button(role: .destructive) {
                        draftToDelete = pattern
                    } label: {
                        Label(L10n.tr("Delete Draft"), systemImage: "trash")
                            .foregroundStyle(BeadsMakerTheme.destructive)
                    }
                    .tint(BeadsMakerTheme.destructive)
                }
            } else {
                NavigationLink {
                    referenceView(for: pattern)
                } label: {
                    patternCard(pattern)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    if libraryStore.selectedSegment == .finished {
                        Button(role: .destructive) {
                            draftToDelete = pattern
                        } label: {
                            Label(L10n.tr("Delete Finished Work"), systemImage: "trash")
                                .foregroundStyle(BeadsMakerTheme.destructive)
                        }
                        .tint(BeadsMakerTheme.destructive)
                    }
                }
            }
        }
    }

    private func avatarPatternForShare() -> Pattern? {
        let avatar = sessionStore.currentUser.avatar
        if let presetID = avatar.presetId,
           let preset = MockData.presetAvatars.first(where: { $0.id == presetID }) {
            return preset.pattern
        }
        if let patternID = avatar.patternId,
           let pattern = libraryStore.content.published.first(where: { $0.id == patternID }) {
            return pattern
        }
        return nil
    }

    // MARK: - Helpers

    @ViewBuilder
    private func referenceView(for pattern: Pattern) -> some View {
        switch libraryStore.selectedSegment {
        case .drafts:
            DraftReferenceView(
                pattern: pattern,
                createStore: createStore,
                selectedTab: $selectedTab,
                actionTitle: "Edit",
                onAction: {
                    createStore.loadForEditing(pattern)
                    selectedTab = .create
                }
            )
        case .finished:
            DraftReferenceView(
                pattern: pattern,
                createStore: createStore,
                selectedTab: $selectedTab,
                actionTitle: "Create Copy",
                onAction: {
                    let ok = createStore.loadTemplate(
                        pattern,
                        user: sessionStore.currentUser,
                        library: libraryStore.content
                    )
                    if ok {
                        selectedTab = .create
                    } else {
                        isShowingDraftLimitAlert = true
                    }
                },
                onShare: { sharePattern = pattern },
                onRename: { newTitle in
                    libraryStore.renameFinished(id: pattern.id, title: newTitle, for: sessionStore.currentUser)
                }
            )
        case .saved:
            DraftReferenceView(
                pattern: pattern,
                createStore: createStore,
                selectedTab: $selectedTab,
                actionTitle: "Create Copy",
                onAction: {
                    let ok = createStore.loadTemplate(
                        pattern,
                        user: sessionStore.currentUser,
                        library: libraryStore.content
                    )
                    if ok {
                        selectedTab = .create
                    } else {
                        isShowingDraftLimitAlert = true
                    }
                }
            )
        case .published:
            DraftReferenceView(
                pattern: pattern,
                createStore: createStore,
                selectedTab: $selectedTab
            )
        }
    }

    private func patternCard(_ pattern: Pattern) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            PatternThumbnail(
                pattern: pattern,
                mode: libraryStore.selectedSegment == .finished ? .pixel : .bead,
                height: 170
            )
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(pattern.title)
                        .font(.headline)
                        .foregroundStyle(BeadsMakerTheme.ink)
                    Text(cardSubtitle(for: pattern))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                PBChip(title: pattern.status.title, accent: pattern.status == .final)
            }
        }
        .pbCard()
    }

    private func cardSubtitle(for pattern: Pattern) -> String {
        switch libraryStore.selectedSegment {
        case .drafts:
            return L10n.tr(pattern.status == .draft ? "Local draft" : "Ready for export")
        case .finished:
            return L10n.tr("Finished")
        case .saved:
            return L10n.tr("by %@", pattern.authorName)
        case .published:
            return L10n.tr("Published")
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.tr("Nothing here yet"))
                .font(.headline)
            Text(emptyStateMessage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .pbCard()
    }

    private var emptyStateMessage: String {
        switch libraryStore.selectedSegment {
        case .drafts:
            return AppFeatureFlags.communityEnabled
                ? L10n.tr("Saved patterns, drafts, and published work appear here automatically.")
                : L10n.tr("Drafts appear here automatically.")
        case .finished:
            return L10n.tr("Finished works appear here after you finalize a draft.")
        case .saved:
            return L10n.tr("Saved patterns, drafts, and published work appear here automatically.")
        case .published:
            return L10n.tr("Saved patterns, drafts, and published work appear here automatically.")
        }
    }
}
