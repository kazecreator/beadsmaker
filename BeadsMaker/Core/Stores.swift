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

    /// Keeps the in-memory guest profile aligned with the verified StoreKit entitlement.
    func setProStatus(_ isPro: Bool) {
        currentUser.isPro = isPro
    }

    #if DEBUG
    func debugResetUser() {
        currentUser = userService.bootstrapGuestUser()
    }

    func debugSetPro(_ isPro: Bool) {
        currentUser.isPro = isPro
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
        userService.persist(currentUser)
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

    var recentlyUsedColors: [String] {
        let counts = currentPattern.pixels
            .compactMap { $0.colorHex }
            .reduce(into: [:]) { dict, hex in
                dict[hex, default: 0] += 1
            }
        return counts
            .sorted { $0.value > $1.value }
            .map { $0.key }
    }

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
        guard user.isPro || library.drafts.count + library.published.count < LocalPatternService.maxFreeDrafts else {
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

    /// Imports a pattern from QR code data, saves it as a draft, and loads it.
    func remixImported(_ pattern: Pattern) {
        currentPattern = pattern
        selectedTool = .brush
        isCanvasLocked = false
        redoStack.removeAll()
        undoStack.removeAll()
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

    /// Marks the current pattern as finished and moves it out of drafts.
    /// Returns `(pattern, isDuplicate)` — if isDuplicate is true the identical finished
    /// work already exists; the returned pattern is that existing copy.
    @discardableResult
    func finalizeLocally(user: User) -> (pattern: Pattern, isDuplicate: Bool) {
        let result = patternService.finalizeLocally(currentPattern, for: user)
        currentPattern = result.pattern
        return result
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
            && library.drafts.count + library.published.count >= LocalPatternService.maxFreeDrafts
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

    /// Resets the editor to a blank canvas without saving the current draft.
    /// Use after finalizing a pattern to start fresh.
    func resetToBlank(user: User) {
        let blank = patternService.createBlankPattern(for: user)
        currentPattern = blank
        selectedColorHex = blank.palette.first ?? "#111111"
        selectedTool = .brush
        isCanvasLocked = false
        undoStack.removeAll()
        redoStack.removeAll()
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
        case .finished: return content.published.filter { $0.visibility == .private }
        case .saved: return content.saved
        case .published: return content.published.filter { $0.visibility == .public }
        }
    }

    /// True when a free user has reached the 20-draft ceiling.
    func isDraftLimitReached(for user: User) -> Bool {
        guard !user.isPro else { return false }
        return content.drafts.count + content.published.count >= LocalPatternService.maxFreeDrafts
    }

    /// Delete a draft or finished work by ID and refresh the content.
    func deleteDraft(id: UUID, for user: User) {
        guard let local = patternService as? LocalPatternService else { return }
        local.deleteDraft(id: id)
        load(for: user)
    }

    func deleteFinished(id: UUID, for user: User) {
        guard let local = patternService as? LocalPatternService else { return }
        local.deleteFinished(id: id)
        load(for: user)
    }

    func renameFinished(id: UUID, title: String, for user: User) {
        guard let local = patternService as? LocalPatternService else { return }
        local.renameFinished(id: id, title: title)
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
        eligiblePatterns = user.isPro ? allWorks.filter { $0.isAvatarEligibleWork } : []
        publishedPatterns = libraryContent.published
        shouldShowDataLossRiskBanner = dataLossRiskBannerPolicy.shouldShow(for: user)
    }

    var allWorks: [Pattern] {
        libraryContent.published
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
