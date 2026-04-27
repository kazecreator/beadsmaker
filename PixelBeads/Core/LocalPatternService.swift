import Foundation

/// JSON-backed PatternService that persists drafts, saved patterns, and published patterns
/// to the app's Application Support directory.
///
/// Explore patterns are still served from MockData until Phase 1 (Supabase integration).
final class LocalPatternService: PatternService {

    // MARK: - Constants

    /// Maximum number of drafts for a free (non-Pro) user.
    static let maxFreeDrafts = 20

    // MARK: - Directories

    private let fm = FileManager.default
    private let storageRootURL: URL

    private var baseURL: URL { storageRootURL }

    private var draftsDir:    URL { baseURL.appendingPathComponent("drafts",    isDirectory: true) }
    private var savedDir:     URL { baseURL.appendingPathComponent("saved",     isDirectory: true) }
    private var publishedDir: URL { baseURL.appendingPathComponent("published", isDirectory: true) }

    // MARK: - Init

    init(baseURL: URL? = nil) {
        self.storageRootURL = baseURL ??
            fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PixelBeads", isDirectory: true)
        for dir in [draftsDir, savedDir, publishedDir] {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }

    // MARK: - PatternService

    func fetchExplorePatterns() -> [Pattern] {
        MockData.explorePatterns.sorted { $0.createdAt > $1.createdAt }
    }

    func fetchLibraryContent(for user: User) -> LibraryContent {
        LibraryContent(
            drafts: load(from: draftsDir),
            saved: load(from: savedDir),
            published: load(from: publishedDir)
        )
    }

    func createBlankPattern(for user: User) -> Pattern {
        MockData.blankPattern(authorName: user.displayName)
    }

    func saveDraft(_ pattern: Pattern, for user: User) -> Pattern {
        guard !isEmptyDraft(pattern) else { return pattern }

        var draft = pattern
        draft.authorName = user.displayName
        draft.status = .draft
        draft.visibility = .private

        // Enforce draft limit for non-Pro users (only for new drafts, not updates)
        let existing = load(from: draftsDir)
        let isExisting = existing.contains { $0.id == draft.id }
        if let duplicate = existing.first(where: {
            $0.id != draft.id && draftContentSignature($0) == draftContentSignature(draft)
        }) {
            return duplicate
        }
        if !user.isPro, !isExisting, existing.count >= Self.maxFreeDrafts {
            return draft // limit reached — return unchanged, do not persist
        }

        write(draft, to: draftsDir)
        return draft
    }

    func publish(_ pattern: Pattern, for user: User) -> Pattern {
        var published = pattern
        published.authorName = user.displayName
        published.status = .final
        published.visibility = .public

        write(published, to: publishedDir)
        delete(id: published.id, from: draftsDir)
        return published
    }

    func savePattern(_ pattern: Pattern, for user: User) {
        var saved = pattern
        saved.saveCount += 1
        write(saved, to: savedDir)
    }

    func removeSavedPattern(id: UUID, for user: User) {
        delete(id: id, from: savedDir)
    }

    func remix(_ pattern: Pattern, for user: User) -> Pattern {
        var remixed = pattern
        remixed.id = UUID()
        remixed.title = L10n.tr("%@ Remix", pattern.title)
        remixed.authorName = user.displayName
        remixed.status = .draft
        remixed.visibility = .private
        remixed.createdAt = .now

        // Enforce draft limit for non-Pro users
        let existing = load(from: draftsDir)
        if !user.isPro, existing.count >= Self.maxFreeDrafts {
            return remixed // limit reached — return remixed pattern but do not persist
        }

        write(remixed, to: draftsDir)
        return remixed
    }

    func avatarEligiblePatterns(for user: User) -> [Pattern] {
        load(from: publishedDir).filter { $0.isSquare && $0.status == .final }
    }

    // MARK: - Draft helpers

    /// Returns the current number of saved drafts.
    func draftCount() -> Int {
        load(from: draftsDir).count
    }

    /// Permanently removes a draft by ID.
    func deleteDraft(id: UUID) {
        delete(id: id, from: draftsDir)
    }

    // MARK: - Private persistence

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private func fileURL(id: UUID, in directory: URL) -> URL {
        directory.appendingPathComponent("\(id.uuidString).json")
    }

    private func load(from directory: URL) -> [Pattern] {
        guard let files = try? fm.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) else { return [] }

        return files
            .filter { $0.pathExtension == "json" }
            .compactMap { url -> Pattern? in
                guard let data = try? Data(contentsOf: url) else { return nil }
                return try? decoder.decode(Pattern.self, from: data)
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private func write(_ pattern: Pattern, to directory: URL) {
        guard let data = try? encoder.encode(pattern) else { return }
        let url = fileURL(id: pattern.id, in: directory)
        try? data.write(to: url, options: .atomic)
    }

    private func delete(id: UUID, from directory: URL) {
        try? fm.removeItem(at: fileURL(id: id, in: directory))
    }

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
