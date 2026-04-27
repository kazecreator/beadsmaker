import Foundation
import Photos
import UIKit

protocol UserService {
    func bootstrapGuestUser() -> User
    func isHandleAvailable(_ handle: String, excluding user: User) -> Bool
    func claimHandle(_ handle: String, for user: User) throws -> User
    func updateAvatar(_ avatar: Avatar, for user: User) -> User
    func updateDisplayName(_ displayName: String, for user: User) -> User
    func persist(_ user: User)
}

protocol PatternService {
    func fetchLibraryContent(for user: User) -> LibraryContent
    func createBlankPattern(for user: User) -> Pattern
    func saveDraft(_ pattern: Pattern, for user: User) -> Pattern
    func finalizeLocally(_ pattern: Pattern, for user: User) -> (pattern: Pattern, isDuplicate: Bool)
    func publish(_ pattern: Pattern, for user: User) -> Pattern
    func savePattern(_ pattern: Pattern, for user: User)
    func removeSavedPattern(id: UUID, for user: User)
    func remix(_ pattern: Pattern, for user: User) -> Pattern
    func avatarEligiblePatterns(for user: User) -> [Pattern]
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
        case .handleTaken: return L10n.tr("That handle is already taken.")
        case .handleTooShort: return L10n.tr("Handle must be at least 3 characters.")
        }
    }
}

final class MockUserService: UserService {
    private var claimedHandles: Set<String> = ["pixelmia", "alexbeads", "junmakes"]
    private let defaults: UserDefaults
    private let icloud: iCloudPreferencesStore?
    private let userKey = "PB_persisted_user"
    private let icloudUserKey = "sync.user-profile"

    init(defaults: UserDefaults = .standard, icloud: iCloudPreferencesStore? = nil) {
        self.defaults = defaults
        self.icloud = icloud
    }

    func bootstrapGuestUser() -> User {
        // Check iCloud first for profile from another device
        if let icloud, let data = icloud.data(forKey: icloudUserKey),
           let saved = try? JSONDecoder().decode(User.self, from: data) {
            // Seed local defaults
            defaults.set(data, forKey: userKey)
            return saved
        }
        if let data = defaults.data(forKey: userKey),
           let saved = try? JSONDecoder().decode(User.self, from: data) {
            return saved
        }
        return MockData.guestUser
    }

    func persist(_ user: User) {
        if let data = try? JSONEncoder().encode(user) {
            defaults.set(data, forKey: userKey)
            icloud?.set(data, forKey: icloudUserKey)
        }
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
        persist(updated)
        return updated
    }

    func updateAvatar(_ avatar: Avatar, for user: User) -> User {
        var updated = user
        updated.avatar = avatar
        persist(updated)
        return updated
    }

    func updateDisplayName(_ displayName: String, for user: User) -> User {
        var updated = user
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.displayName = trimmed.isEmpty ? user.displayName : trimmed
        persist(updated)
        return updated
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

enum PhotoLibrarySaver {
    static func saveFinishedPNG(pattern: Pattern, completion: @escaping (PhotoSaveStatus) -> Void) {
        saveImage(PatternImageRenderer.finishedImage(for: pattern, cellSize: 22, scale: 3), completion: completion)
    }

    static func saveImage(_ image: UIImage, completion: @escaping (PhotoSaveStatus) -> Void) {
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        } completionHandler: { success, error in
            DispatchQueue.main.async {
                if success {
                    completion(.saved)
                } else {
                    completion(.failed(error?.localizedDescription ?? L10n.tr("Please allow PixelBeads to add images to Photos.")))
                }
            }
        }
    }
}
