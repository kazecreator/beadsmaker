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

    func updateAvatar(_ avatar: Avatar) {
        currentUser = userService.updateAvatar(avatar, for: currentUser)
    }
}

@MainActor
final class ExploreStore: ObservableObject {
    @Published private(set) var patterns: [Pattern] = []
    @Published private(set) var likedPatternIDs: Set<UUID> = []
    @Published private(set) var savedPatternIDs: Set<UUID> = []

    private let patternService: PatternService
    private let communityService: CommunityService

    init(patternService: PatternService, communityService: CommunityService) {
        self.patternService = patternService
        self.communityService = communityService
    }

    func load(for user: User) {
        patterns = patternService.fetchExplorePatterns()
        likedPatternIDs = communityService.likedPatternIDs(for: user)
        savedPatternIDs = communityService.savedPatternIDs(for: user)
    }

    func toggleLike(_ pattern: Pattern, user: User) {
        likedPatternIDs = communityService.toggleLike(patternID: pattern.id, for: user)
    }

    func toggleSave(_ pattern: Pattern, user: User) {
        savedPatternIDs = communityService.toggleSave(pattern: pattern, for: user)
    }
}

@MainActor
final class CreateStore: ObservableObject {
    @Published var currentPattern: Pattern
    @Published var selectedColorHex: String
    @Published var selectedTool: EditorTool = .brush
    @Published var previewMode: PreviewMode = .bead

    private let patternService: PatternService
    private let exportService: ExportService
    private var undoStack: [Pattern] = []
    private var redoStack: [Pattern] = []

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
        switch selectedTool {
        case .eyedropper:
            if let picked = currentPattern.pixels.first(where: { $0.x == x && $0.y == y })?.colorHex {
                selectedColorHex = picked
            }
        case .brush, .eraser:
            pushUndoState()
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

    func loadTemplate(_ pattern: Pattern, user: User) {
        var remix = patternService.remix(pattern, for: user)
        remix.palette = Array(Set(remix.palette + MockData.defaultPalette)).sorted()
        currentPattern = remix
        selectedTool = .brush
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

    func saveDraft(user: User) {
        currentPattern = patternService.saveDraft(currentPattern, for: user)
    }

    func publish(user: User) -> Bool {
        guard !user.isGuest || user.isClaimed else {
            return false
        }
        currentPattern = patternService.publish(currentPattern, for: user)
        return true
    }

    func exportArtifact(option: ExportOption) -> ExportArtifact {
        exportService.export(pattern: currentPattern, option: option)
    }

    func finalizeForAvatar() {
        currentPattern.status = .final
    }

    private func pushUndoState() {
        undoStack.append(currentPattern)
        redoStack.removeAll()
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
}

@MainActor
final class ProfileStore: ObservableObject {
    @Published private(set) var presetAvatars: [Avatar] = []
    @Published private(set) var eligiblePatterns: [Pattern] = []
    @Published var selectedRenderStyle: AvatarRenderStyle = .bead

    private let avatarService: AvatarService
    private let patternService: PatternService

    init(avatarService: AvatarService, patternService: PatternService) {
        self.avatarService = avatarService
        self.patternService = patternService
    }

    func load(for user: User) {
        presetAvatars = avatarService.presetAvatars()
        eligiblePatterns = patternService.avatarEligiblePatterns(for: user)
    }

    func makePatternAvatar(from pattern: Pattern) -> Avatar? {
        avatarService.makePatternAvatar(from: pattern, style: selectedRenderStyle)
    }
}
