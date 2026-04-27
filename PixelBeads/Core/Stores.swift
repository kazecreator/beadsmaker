import Combine
import Foundation

@MainActor
final class AppSessionStore: ObservableObject {
    @Published private(set) var currentUser: User
    @Published var claimError: String?

    private let userService: UserService

    init(userService: UserService) {
        self.userService = userService
        self.currentUser = userService.bootstrapGuestUser()
    }

    func claimHandle(_ handle: String) {
        do {
            currentUser = try userService.claimHandle(handle, for: currentUser)
            claimError = nil
        } catch {
            claimError = error.localizedDescription
        }
    }

    func isHandleAvailable(_ handle: String) -> Bool {
        userService.isHandleAvailable(handle, excluding: currentUser)
    }

    func updateDisplayName(_ displayName: String) {
        currentUser = userService.updateDisplayName(displayName, for: currentUser)
    }

    func updateAvatar(_ avatar: Avatar) {
        currentUser = userService.updateAvatar(avatar, for: currentUser)
    }

    /// Marks the current user as Pro. Called immediately after a successful StoreKit purchase.
    func upgradeToPro() {
        currentUser.isPro = true
    }

    #if DEBUG
    /// Resets user back to a fresh guest state. Debug testing only.
    func debugResetUser() {
        currentUser = userService.bootstrapGuestUser()
    }
    #endif

    /// Links an Apple account to the current user and promotes them from guest.
    /// Called after Apple Sign In completes and the user confirms their display name.
    func linkAppleAccount(appleUserID: String, displayName: String) {
        currentUser.appleUserID = appleUserID
        currentUser.isGuest = false
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            currentUser.displayName = trimmed
        }
    }
}

@MainActor
final class ExploreStore: ObservableObject {
    @Published private(set) var patterns: [Pattern] = []
    @Published private(set) var savedPatternIDs: Set<UUID> = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var bannerMessage: String?
    @Published private(set) var sortMode: ExploreSortMode
    @Published private(set) var filters: ExploreFilters
    @Published private(set) var hasMore = true

    private let exploreService: ExploreService
    private let patternService: PatternService
    private let communityService: CommunityService
    private let preferencesStore: ExplorePreferencesStore
    private var currentPage = 0
    private let pageSize = 20

    init(
        exploreService: ExploreService,
        patternService: PatternService,
        communityService: CommunityService,
        preferencesStore: ExplorePreferencesStore = ExplorePreferencesStore()
    ) {
        self.exploreService = exploreService
        self.patternService = patternService
        self.communityService = communityService
        self.preferencesStore = preferencesStore
        self.sortMode = preferencesStore.loadSortMode()
        self.filters = preferencesStore.loadFilters()
    }

    var hasActiveFilters: Bool {
        !filters.isDefault
    }

    func load(for user: User, deviceID: String, forceRefresh: Bool = false) async {
        isLoading = true
        savedPatternIDs = communityService.savedPatternIDs(deviceID: deviceID)
        currentPage = 0

        do {
            let snapshot = try await exploreService.fetchPatterns(
                sort: sortMode,
                filters: filters,
                page: 0,
                pageSize: pageSize,
                forceRefresh: forceRefresh
            )
            patterns = snapshot.patterns
            hasMore = snapshot.hasMore
            bannerMessage = Self.bannerMessage(for: snapshot.source)
        } catch {
            patterns = patternService.fetchExplorePatterns()
            hasMore = false
            bannerMessage = L10n.tr("Unable to refresh community feed right now.")
        }

        isLoading = false
    }

    func loadMore(for user: User, deviceID: String) async {
        guard hasMore, !isLoadingMore else { return }

        isLoadingMore = true
        currentPage += 1

        do {
            let snapshot = try await exploreService.fetchPatterns(
                sort: sortMode,
                filters: filters,
                page: currentPage,
                pageSize: pageSize,
                forceRefresh: false
            )
            patterns.append(contentsOf: snapshot.patterns)
            hasMore = snapshot.hasMore
        } catch {
            currentPage -= 1
        }

        isLoadingMore = false
    }

    func setSortMode(_ mode: ExploreSortMode, user: User, deviceID: String) async {
        guard sortMode != mode else { return }
        sortMode = mode
        preferencesStore.saveSortMode(mode)
        await load(for: user, deviceID: deviceID)
    }

    func updateTheme(_ theme: PatternTheme?, user: User, deviceID: String) async {
        filters.theme = theme
        preferencesStore.saveFilters(filters)
        await load(for: user, deviceID: deviceID)
    }

    func updateDifficulty(_ difficulty: DifficultyLevel?, user: User, deviceID: String) async {
        filters.difficulty = difficulty
        preferencesStore.saveFilters(filters)
        await load(for: user, deviceID: deviceID)
    }

    func updateSizeTier(_ sizeTier: PatternSizeTier?, user: User, deviceID: String) async {
        filters.sizeTier = sizeTier
        preferencesStore.saveFilters(filters)
        await load(for: user, deviceID: deviceID)
    }

    func clearFilters(user: User, deviceID: String) async {
        filters = .default
        preferencesStore.saveFilters(filters)
        await load(for: user, deviceID: deviceID)
    }

    func toggleSave(_ pattern: Pattern, user: User, deviceID: String) async {
        let wasSaved = savedPatternIDs.contains(pattern.id)

        do {
            savedPatternIDs = try await communityService.toggleSave(pattern: pattern, deviceID: deviceID)
            if wasSaved {
                patternService.removeSavedPattern(id: pattern.id, for: user)
            } else {
                patternService.savePattern(pattern, for: user)
            }

        } catch {
            bannerMessage = L10n.tr("Unable to sync saves right now.")
        }
    }

    func isSaved(_ pattern: Pattern) -> Bool {
        savedPatternIDs.contains(pattern.id)
    }

    func relatedPatterns(for pattern: Pattern, limit: Int = 6) async -> [Pattern] {
        do {
            return try await exploreService.relatedPatterns(for: pattern, limit: limit)
        } catch {
            return []
        }
    }

    private static func bannerMessage(for source: ExploreFeedSource) -> String? {
        switch source {
        case .remote:
            return nil
        case .cache:
            return L10n.tr("Using cached community patterns.")
        case .localFallback:
            return L10n.tr("Community feed is still using bundled preview data.")
        }
    }
}

@MainActor
final class CreateStore: ObservableObject {
    @Published var currentPattern: Pattern
    @Published var selectedColorHex: String
    @Published var selectedTool: EditorTool = .brush
    @Published var isCanvasLocked = false
    @Published var previewMode: PreviewMode = .bead

    private let patternService: PatternService
    private let exportService: ExportService
    private var undoStack: [Pattern] = []
    private var redoStack: [Pattern] = []
    private var activeStrokeCells: Set<String> = []
    private var hasActiveStroke = false

    init(patternService: PatternService, exportService: ExportService, user: User) {
        self.patternService = patternService
        self.exportService = exportService
        let blank = patternService.createBlankPattern(for: user)
        self.currentPattern = blank
        self.selectedColorHex = blank.palette.first ?? "#111111"
    }

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    func tapCell(x: Int, y: Int) {
        beginStroke()
        applyTool(x: x, y: y)
        endStroke()
    }

    func beginStroke() {
        activeStrokeCells.removeAll()
        hasActiveStroke = false
    }

    func dragCell(x: Int, y: Int) {
        let key = cellKey(x: x, y: y)
        guard !activeStrokeCells.contains(key) else { return }
        activeStrokeCells.insert(key)
        applyTool(x: x, y: y)
    }

    func endStroke() {
        activeStrokeCells.removeAll()
        hasActiveStroke = false
    }

    func publishAndFinalize(user: User) -> Bool {
        finalizeForAvatar()
        return publish(user: user)
    }

    func selectTool(_ tool: EditorTool) {
        if tool == .brush, selectedTool == .brush, !isCanvasLocked {
            isCanvasLocked = true
            return
        }

        isCanvasLocked = false
        selectedTool = tool
    }

    func toggleCanvasLock() {
        selectedTool = .brush
        isCanvasLocked.toggle()
    }

    private func applyTool(x: Int, y: Int) {
        guard !isCanvasLocked else { return }

        switch selectedTool {
        case .eyedropper:
            if let picked = currentPattern.pixels.first(where: { $0.x == x && $0.y == y })?.colorHex {
                selectedColorHex = picked
            }
        case .brush, .eraser:
            if !hasActiveStroke {
                pushUndoState()
                hasActiveStroke = true
            }
            if let index = currentPattern.pixels.firstIndex(where: { $0.x == x && $0.y == y }) {
                if selectedTool == .eraser {
                    currentPattern.pixels.remove(at: index)
                } else {
                    currentPattern.pixels[index].colorHex = selectedColorHex
                }
            } else if selectedTool == .brush {
                currentPattern.pixels.append(PatternPixel(x: x, y: y, colorHex: selectedColorHex))
            }
        }
    }

    /// Loads a remix of the given pattern as the current draft.
    /// Returns false if the free draft limit would be exceeded.
    @discardableResult
    func loadTemplate(_ pattern: Pattern, user: User, library: LibraryContent) -> Bool {
        guard user.isPro || library.drafts.count < LocalPatternService.maxFreeDrafts else {
            return false
        }
        var remix = patternService.remix(pattern, for: user)
        remix.palette = Array(Set(remix.palette + MockData.defaultPalette)).sorted()
        currentPattern = remix
        selectedTool = .brush
        isCanvasLocked = false
        redoStack.removeAll()
        undoStack.removeAll()
        return true
    }

    func updateTitle(_ title: String) {
        currentPattern.title = title
    }

    func undo() {
        guard let previous = undoStack.popLast() else { return }
        redoStack.append(currentPattern)
        currentPattern = previous
    }

    func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(currentPattern)
        currentPattern = next
    }

    @discardableResult
    func saveDraft(user: User) -> Bool {
        guard shouldPersistDraft(currentPattern) else { return false }
        currentPattern = patternService.saveDraft(currentPattern, for: user)
        return true
    }

    /// Creates a new blank draft, saving the current one first.
    /// Returns false if the free draft limit (20) would be exceeded.
    @discardableResult
    func startNewDraft(user: User, library: LibraryContent) -> Bool {
        let shouldSaveCurrentDraft = shouldPersistDraft(currentPattern)
        let isNew = !library.drafts.contains { $0.id == currentPattern.id }
        let isDuplicate = library.drafts.contains {
            $0.id != currentPattern.id && draftContentSignature($0) == draftContentSignature(currentPattern)
        }
        let wouldExceedLimit = !user.isPro
            && shouldSaveCurrentDraft
            && isNew
            && !isDuplicate
            && library.drafts.count >= LocalPatternService.maxFreeDrafts
        guard !wouldExceedLimit else { return false }

        // Auto-save current work before switching
        if shouldSaveCurrentDraft {
            _ = patternService.saveDraft(currentPattern, for: user)
        }

        let blank = patternService.createBlankPattern(for: user)
        currentPattern = blank
        selectedColorHex = blank.palette.first ?? "#111111"
        selectedTool = .brush
        isCanvasLocked = false
        undoStack.removeAll()
        redoStack.removeAll()
        return true
    }

    func publish(user: User) -> Bool {
        guard user.isPro else { return false }
        currentPattern = patternService.publish(currentPattern, for: user)
        return true
    }

    func exportArtifact(option: ExportOption) -> ExportArtifact {
        exportService.export(pattern: currentPattern, option: option)
    }

    func finalizeForAvatar() {
        currentPattern.status = .final
    }

    func resizeCanvas(width: Int, height: Int) {
        pushUndoState()
        currentPattern.width = width
        currentPattern.height = height
        currentPattern.pixels.removeAll { $0.x >= width || $0.y >= height }
    }

    func loadForEditing(_ pattern: Pattern) {
        undoStack.removeAll()
        redoStack.removeAll()
        currentPattern = pattern
        selectedColorHex = pattern.palette.first ?? "#111111"
        isCanvasLocked = false
        selectedTool = .brush
    }

    func clearCanvas() {
        pushUndoState()
        currentPattern.pixels.removeAll()
    }

    private func pushUndoState() {
        undoStack.append(currentPattern)
        redoStack.removeAll()
    }

    private func cellKey(x: Int, y: Int) -> String {
        "\(x)-\(y)"
    }

    private func shouldPersistDraft(_ pattern: Pattern) -> Bool {
        pattern.pixels.contains { $0.colorHex != nil }
    }

    private func draftContentSignature(_ pattern: Pattern) -> String {
        let pixels = pattern.pixels
            .compactMap { pixel -> String? in
                guard let colorHex = pixel.colorHex else { return nil }
                return "\(pixel.x),\(pixel.y),\(colorHex.uppercased())"
            }
            .sorted()
            .joined(separator: "|")
        return "\(pattern.width)x\(pattern.height):\(pixels)"
    }
}

@MainActor
final class LibraryStore: ObservableObject {
    @Published var selectedSegment: LibrarySegment = .drafts
    @Published private(set) var content = LibraryContent(drafts: [], saved: [], published: [])

    private let patternService: PatternService

    init(patternService: PatternService) {
        self.patternService = patternService
    }

    func load(for user: User) {
        content = patternService.fetchLibraryContent(for: user)
    }

    var displayedPatterns: [Pattern] {
        switch selectedSegment {
        case .drafts: return content.drafts
        case .saved: return content.saved
        case .published: return content.published
        }
    }

    /// True when a free user has reached the 20-draft ceiling.
    func isDraftLimitReached(for user: User) -> Bool {
        guard !user.isPro else { return false }
        return content.drafts.count >= LocalPatternService.maxFreeDrafts
    }

    /// Delete a draft by ID and refresh the content.
    func deleteDraft(id: UUID, for user: User) {
        guard let local = patternService as? LocalPatternService else { return }
        local.deleteDraft(id: id)
        load(for: user)
    }
}

@MainActor
final class ProfileStore: ObservableObject {
    @Published private(set) var presetAvatars: [Avatar] = []
    @Published private(set) var eligiblePatterns: [Pattern] = []
    @Published private(set) var publishedPatterns: [Pattern] = []
    @Published private(set) var libraryContent = LibraryContent(drafts: [], saved: [], published: [])
    @Published private(set) var shouldShowDataLossRiskBanner = false
    @Published var selectedRenderStyle: AvatarRenderStyle = .bead

    private let avatarService: AvatarService
    private let patternService: PatternService
    private let dataLossRiskBannerPolicy: DataLossRiskBannerPolicy

    init(
        avatarService: AvatarService,
        patternService: PatternService,
        dataLossRiskBannerPolicy: DataLossRiskBannerPolicy = DataLossRiskBannerPolicy()
    ) {
        self.avatarService = avatarService
        self.patternService = patternService
        self.dataLossRiskBannerPolicy = dataLossRiskBannerPolicy
    }

    func load(for user: User) {
        presetAvatars = avatarService.presetAvatars()
        libraryContent = patternService.fetchLibraryContent(for: user)
        eligiblePatterns = allWorks.filter { $0.isAvatarEligibleWork }
        publishedPatterns = libraryContent.published
        shouldShowDataLossRiskBanner = dataLossRiskBannerPolicy.shouldShow(for: user)
    }

    var allWorks: [Pattern] {
        var seenIDs = Set<UUID>()
        return (libraryContent.drafts + libraryContent.saved + libraryContent.published).filter { pattern in
            guard !seenIDs.contains(pattern.id) else { return false }
            seenIDs.insert(pattern.id)
            return true
        }
    }

    func makePatternAvatar(from pattern: Pattern) -> Avatar? {
        guard pattern.isAvatarEligibleWork else { return nil }
        return Avatar(type: .pattern, presetId: nil, patternId: pattern.id, renderStyle: .bead)
    }

    func dismissDataLossRiskBanner() {
        dataLossRiskBannerPolicy.markDismissed()
        shouldShowDataLossRiskBanner = false
    }
}
