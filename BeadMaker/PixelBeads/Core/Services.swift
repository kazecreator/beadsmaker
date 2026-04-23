import Foundation
import UIKit

protocol UserService {
    func bootstrapGuestUser() -> User
    func isHandleAvailable(_ handle: String, excluding user: User) -> Bool
    func claimHandle(_ handle: String, for user: User) throws -> User
    func updateAvatar(_ avatar: Avatar, for user: User) -> User
    func updateDisplayName(_ displayName: String, for user: User) -> User
}

protocol PatternService {
    func fetchExplorePatterns() -> [Pattern]
    func fetchLibraryContent(for user: User) -> LibraryContent
    func createBlankPattern(for user: User) -> Pattern
    func saveDraft(_ pattern: Pattern, for user: User) -> Pattern
    func publish(_ pattern: Pattern, for user: User) -> Pattern
    func savePattern(_ pattern: Pattern, for user: User)
    func remix(_ pattern: Pattern, for user: User) -> Pattern
    func avatarEligiblePatterns(for user: User) -> [Pattern]
}

protocol CommunityService {
    func likedPatternIDs(for user: User) -> Set<UUID>
    func savedPatternIDs(for user: User) -> Set<UUID>
    func toggleLike(patternID: UUID, for user: User) -> Set<UUID>
    func toggleSave(pattern: Pattern, for user: User) -> Set<UUID>
}

protocol AvatarService {
    func presetAvatars() -> [Avatar]
    func makePatternAvatar(from pattern: Pattern, style: AvatarRenderStyle) -> Avatar?
}

protocol ExportService {
    func export(pattern: Pattern, option: ExportOption) -> ExportArtifact
}

enum UserServiceError: LocalizedError {
    case handleTaken
    case handleTooShort

    var errorDescription: String? {
        switch self {
        case .handleTaken: return "That handle is already taken in mock data."
        case .handleTooShort: return "Handle must be at least 3 characters."
        }
    }
}

final class MockUserService: UserService {
    private var claimedHandles: Set<String> = ["pixelmia", "alexbeads", "junmakes"]

    func bootstrapGuestUser() -> User {
        MockData.guestUser
    }

    func isHandleAvailable(_ handle: String, excluding user: User) -> Bool {
        let normalized = handle.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalized.count >= 3 else {
            return false
        }
        if normalized == user.publicHandle {
            return true
        }
        return !claimedHandles.contains(normalized)
    }

    func claimHandle(_ handle: String, for user: User) throws -> User {
        let normalized = handle.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalized.count >= 3 else {
            throw UserServiceError.handleTooShort
        }
        guard !claimedHandles.contains(normalized) else {
            throw UserServiceError.handleTaken
        }

        if let existingHandle = user.publicHandle, existingHandle != normalized {
            claimedHandles.remove(existingHandle)
        }
        claimedHandles.insert(normalized)
        var updated = user
        updated.publicHandle = normalized
        updated.isGuest = false
        updated.isClaimed = true
        return updated
    }

    func updateAvatar(_ avatar: Avatar, for user: User) -> User {
        var updated = user
        updated.avatar = avatar
        return updated
    }

    func updateDisplayName(_ displayName: String, for user: User) -> User {
        var updated = user
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.displayName = trimmed.isEmpty ? user.displayName : trimmed
        return updated
    }
}

final class MockPatternService: PatternService {
    private var explorePatterns: [Pattern]
    private var draftsByUser: [UUID: [Pattern]]
    private var savedByUser: [UUID: [Pattern]]
    private var publishedByUser: [UUID: [Pattern]]

    init() {
        self.explorePatterns = MockData.explorePatterns
        self.draftsByUser = [MockData.guestUser.id: [MockData.blankPattern()]]
        self.savedByUser = [MockData.guestUser.id: [MockData.explorePatterns[0]]]
        self.publishedByUser = [MockData.guestUser.id: []]
    }

    func fetchExplorePatterns() -> [Pattern] {
        explorePatterns.sorted { $0.createdAt > $1.createdAt }
    }

    func fetchLibraryContent(for user: User) -> LibraryContent {
        LibraryContent(
            drafts: draftsByUser[user.id, default: []],
            saved: savedByUser[user.id, default: []],
            published: publishedByUser[user.id, default: []]
        )
    }

    func createBlankPattern(for user: User) -> Pattern {
        MockData.blankPattern(authorName: user.displayName)
    }

    func saveDraft(_ pattern: Pattern, for user: User) -> Pattern {
        var draft = pattern
        draft.authorName = user.displayName
        draft.status = .draft
        draft.visibility = .private
        upsert(&draftsByUser[user.id, default: []], pattern: draft)
        return draft
    }

    func publish(_ pattern: Pattern, for user: User) -> Pattern {
        var published = pattern
        published.authorName = user.displayName
        published.status = .final
        published.visibility = .public
        upsert(&publishedByUser[user.id, default: []], pattern: published)
        upsert(&explorePatterns, pattern: published)
        draftsByUser[user.id, default: []].removeAll { $0.id == pattern.id }
        return published
    }

    func savePattern(_ pattern: Pattern, for user: User) {
        var saved = pattern
        saved.saveCount += 1
        upsert(&savedByUser[user.id, default: []], pattern: saved)
    }

    func remix(_ pattern: Pattern, for user: User) -> Pattern {
        var remix = pattern
        remix.id = UUID()
        remix.title = "\(pattern.title) Remix"
        remix.authorName = user.displayName
        remix.status = .draft
        remix.visibility = .private
        remix.createdAt = .now
        upsert(&draftsByUser[user.id, default: []], pattern: remix)
        return remix
    }

    func avatarEligiblePatterns(for user: User) -> [Pattern] {
        let library = fetchLibraryContent(for: user)
        return library.published
            .filter { $0.isSquare && $0.status == .final }
    }

    private func upsert(_ patterns: inout [Pattern], pattern: Pattern) {
        if let index = patterns.firstIndex(where: { $0.id == pattern.id }) {
            patterns[index] = pattern
        } else {
            patterns.insert(pattern, at: 0)
        }
    }
}

final class MockCommunityService: CommunityService {
    private let patternService: PatternService
    private var likesByUser: [UUID: Set<UUID>] = [:]
    private var savesByUser: [UUID: Set<UUID>] = [:]

    init(patternService: PatternService) {
        self.patternService = patternService
    }

    func likedPatternIDs(for user: User) -> Set<UUID> {
        likesByUser[user.id, default: []]
    }

    func savedPatternIDs(for user: User) -> Set<UUID> {
        savesByUser[user.id, default: Set(patternService.fetchLibraryContent(for: user).saved.map(\.id))]
    }

    func toggleLike(patternID: UUID, for user: User) -> Set<UUID> {
        var likes = likesByUser[user.id, default: []]
        if likes.contains(patternID) {
            likes.remove(patternID)
        } else {
            likes.insert(patternID)
        }
        likesByUser[user.id] = likes
        return likes
    }

    func toggleSave(pattern: Pattern, for user: User) -> Set<UUID> {
        var saves = savesByUser[user.id, default: []]
        if saves.contains(pattern.id) {
            saves.remove(pattern.id)
        } else {
            saves.insert(pattern.id)
            patternService.savePattern(pattern, for: user)
        }
        savesByUser[user.id] = saves
        return saves
    }
}

final class MockAvatarService: AvatarService {
    func presetAvatars() -> [Avatar] {
        MockData.presetAvatarIDs.map {
            Avatar(type: .preset, presetId: $0, patternId: nil, renderStyle: .bead)
        }
    }

    func makePatternAvatar(from pattern: Pattern, style: AvatarRenderStyle) -> Avatar? {
        guard pattern.isSquare, pattern.status == .final else {
            return nil
        }
        return Avatar(type: .pattern, presetId: nil, patternId: pattern.id, renderStyle: style)
    }
}

final class MockExportService: ExportService {
    func export(pattern: Pattern, option: ExportOption) -> ExportArtifact {
        let image = PatternImageRenderer.image(for: pattern, mode: option.mode, scale: 2)
        return ExportArtifact(option: option, imageData: image.pngData() ?? Data(), previewPattern: pattern)
    }
}
