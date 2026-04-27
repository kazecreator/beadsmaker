import SwiftUI

struct LibraryView: View {
    @ObservedObject var libraryStore: LibraryStore
    @ObservedObject var createStore: CreateStore
    @ObservedObject var sessionStore: AppSessionStore
    @Binding var selectedTab: AppTab

    @State private var draftToDelete: Pattern?
    @State private var isShowingDraftLimitAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if AppFeatureFlags.communityEnabled {
                        Picker(L10n.tr("Library"), selection: $libraryStore.selectedSegment) {
                            ForEach(LibrarySegment.allCases) { segment in
                                Text(segment.title).tag(segment)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    if libraryStore.displayedPatterns.isEmpty {
                        emptyState
                    } else {
                        ForEach(libraryStore.displayedPatterns) { pattern in
                            NavigationLink {
                                referenceView(for: pattern)
                            } label: {
                                patternCard(pattern)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                if libraryStore.selectedSegment == .drafts {
                                    Button(role: .destructive) {
                                        draftToDelete = pattern
                                    } label: {
                                        Label(L10n.tr("Delete Draft"), systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
            .navigationTitle(L10n.tr("Library"))
            .background(PixelBeadsTheme.surface)
        }
        .alert(L10n.tr("Draft Limit Reached"), isPresented: $isShowingDraftLimitAlert) {
            Button(L10n.tr("OK"), role: .cancel) { }
        } message: {
            Text(L10n.tr("You've reached the 20-draft limit. Delete a draft to make room, or upgrade to Pro for unlimited drafts."))
        }
        .alert(L10n.tr("Delete Draft?"), isPresented: Binding(
            get: { draftToDelete != nil },
            set: { if !$0 { draftToDelete = nil } }
        )) {
            Button(L10n.tr("Delete"), role: .destructive) {
                if let pattern = draftToDelete {
                    libraryStore.deleteDraft(id: pattern.id, for: sessionStore.currentUser)
                }
                draftToDelete = nil
            }
            Button(L10n.tr("Cancel"), role: .cancel) {
                draftToDelete = nil
            }
        } message: {
            Text(L10n.tr("This will permanently remove this draft."))
        }
        .pbScreen()
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
                mode: libraryStore.selectedSegment == .published ? .bead : pattern.status == .final ? .bead : .pixel,
                height: 170
            )
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(pattern.title)
                        .font(.headline)
                        .foregroundStyle(PixelBeadsTheme.ink)
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
            Text(AppFeatureFlags.communityEnabled
                ? L10n.tr("Saved patterns, drafts, and published work appear here automatically.")
                : L10n.tr("Drafts appear here automatically."))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .pbCard()
    }
}
