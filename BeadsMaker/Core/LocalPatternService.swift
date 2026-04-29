import Foundation

/// JSON-backed PatternService that persists drafts, saved patterns, and published patterns.
/// Uses a pluggable PatternStorage backend — local Application Support by default,
/// or an iCloud ubiquity container for Pro users.
final class LocalPatternService: PatternService {

    // MARK: - Constants

    /// Maximum number of drafts for a free (non-Pro) user.
    static let maxFreeDrafts = 20

    // MARK: - Storage

    private var storage: PatternStorage

    private var draftsDir:    URL { storage.baseURL().appendingPathComponent("drafts",    isDirectory: true) }
    private var savedDir:     URL { storage.baseURL().appendingPathComponent("saved",     isDirectory: true) }
    private var publishedDir: URL { storage.baseURL().appendingPathComponent("published", isDirectory: true) }

    // MARK: - Init

    /// Creates a service with a specific storage backend.
    init(storage: PatternStorage) {
        self.storage = storage
        for dir in [draftsDir, savedDir, publishedDir] {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }

    /// Backward-compatible init using local Application Support storage.
    convenience init(baseURL: URL? = nil) {
        self.init(storage: LocalPatternStorage(root: baseURL))
    }

    // MARK: - Storage migration

    /// Migrates all existing patterns from the current storage to a new backend.
    func migrateToiCloud(storage iCloudStorage: PatternStorage) async {
        let drafts = storage.loadPatterns(from: draftsDir)
        let saved = storage.loadPatterns(from: savedDir)
        let published = storage.loadPatterns(from: publishedDir)

        self.storage = iCloudStorage
        for dir in [draftsDir, savedDir, publishedDir] {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }

        for pattern in drafts { storage.writePattern(pattern, to: draftsDir) }
        for pattern in saved { storage.writePattern(pattern, to: savedDir) }
        for pattern in published { storage.writePattern(pattern, to: publishedDir) }
    }

    func switchToiCloud(storage iCloudStorage: PatternStorage) async {
        self.storage = iCloudStorage
        for dir in [draftsDir, savedDir, publishedDir] {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }

    /// Returns the current storage backend type.
    var isUsingiCloud: Bool { storage is iCloudPatternStorage }

    // MARK: - PatternService

    func fetchLibraryContent(for user: User) -> LibraryContent {
        LibraryContent(
            drafts: storage.loadPatterns(from: draftsDir),
            saved: storage.loadPatterns(from: savedDir),
            published: storage.loadPatterns(from: publishedDir)
        )
    }

    func createBlankPattern(for user: User) -> Pattern {
        MockData.blankPattern(authorName: user.displayName)
    }

    private func freeTierCount() -> Int {
        storage.patternCount(in: draftsDir) + storage.patternCount(in: publishedDir)
    }

    func saveDraft(_ pattern: Pattern, for user: User) -> Pattern {
        guard !isEmptyDraft(pattern) else { return pattern }

        var draft = pattern
        draft.authorName = user.displayName
        draft.status = .draft
        draft.visibility = .private

        let existing = storage.loadPatterns(from: draftsDir)
        let isExisting = existing.contains { $0.id == draft.id }
        if let duplicate = existing.first(where: {
            $0.id != draft.id && draftContentSignature($0) == draftContentSignature(draft)
        }) {
            return duplicate
        }
        if !user.isPro, !isExisting, freeTierCount() >= Self.maxFreeDrafts {
            return draft
        }

        storage.writePattern(draft, to: draftsDir)
        return draft
    }

    func finalizeLocally(_ pattern: Pattern, for user: User) -> (pattern: Pattern, isDuplicate: Bool) {
        let existing = storage.loadPatterns(from: publishedDir)
        if let duplicate = existing.first(where: {
            $0.id != pattern.id && draftContentSignature($0) == draftContentSignature(pattern)
        }) {
            return (duplicate, true)
        }
        var finished = pattern
        finished.authorName = user.displayName
        finished.status = .final
        finished.visibility = .private

        storage.writePattern(finished, to: publishedDir)
        storage.deletePattern(id: finished.id, from: draftsDir)
        return (finished, false)
    }

    func publish(_ pattern: Pattern, for user: User) -> Pattern {
        var published = pattern
        published.authorName = user.displayName
        published.status = .final
        published.visibility = .public

        storage.writePattern(published, to: publishedDir)
        storage.deletePattern(id: published.id, from: draftsDir)
        return published
    }

    func savePattern(_ pattern: Pattern, for user: User) {
        var saved = pattern
        saved.saveCount += 1
        storage.writePattern(saved, to: savedDir)
    }

    func removeSavedPattern(id: UUID, for user: User) {
        storage.deletePattern(id: id, from: savedDir)
    }

    func remix(_ pattern: Pattern, for user: User) -> Pattern {
        var remixed = pattern
        remixed.id = UUID()
        remixed.title = L10n.tr("%@ Remix", pattern.title)
        remixed.authorName = user.displayName
        remixed.status = .draft
        remixed.visibility = .private
        remixed.createdAt = .now

        if !user.isPro, freeTierCount() >= Self.maxFreeDrafts {
            return remixed
        }

        storage.writePattern(remixed, to: draftsDir)
        return remixed
    }

    func avatarEligiblePatterns(for user: User) -> [Pattern] {
        storage.loadPatterns(from: publishedDir).filter { $0.isSquare && $0.status == .final }
    }

    // MARK: - Draft helpers

    func draftCount() -> Int {
        storage.patternCount(in: draftsDir)
    }

    func deleteDraft(id: UUID) {
        storage.deletePattern(id: id, from: draftsDir)
    }

    func deleteFinished(id: UUID) {
        storage.deletePattern(id: id, from: publishedDir)
    }

    func renameFinished(id: UUID, title: String) {
        var patterns = storage.loadPatterns(from: publishedDir)
        guard let idx = patterns.firstIndex(where: { $0.id == id }) else { return }
        patterns[idx].title = title
        storage.writePattern(patterns[idx], to: publishedDir)
    }

    // MARK: - Private helpers

    private func isEmptyDraft(_ pattern: Pattern) -> Bool {
        pattern.pixels.allSatisfy { $0.colorHex == nil }
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
