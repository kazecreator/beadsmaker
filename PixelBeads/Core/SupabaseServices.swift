import Foundation
import Supabase

struct SupabaseExploreService: ExploreService {
    private let client: SupabaseClient
    private let config: SupabaseClientConfig
    private let cacheStore: ExploreCacheStore

    init(config: SupabaseClientConfig, cacheStore: ExploreCacheStore = ExploreCacheStore()) {
        self.client = SupabaseClient(supabaseURL: config.url, supabaseKey: config.anonKey)
        self.config = config
        self.cacheStore = cacheStore
    }

    // MARK: - fetchPatterns

    func fetchPatterns(
        sort: ExploreSortMode,
        filters: ExploreFilters,
        page: Int,
        pageSize: Int,
        forceRefresh: Bool
    ) async throws -> ExploreFeedSnapshot {
        // Serve from cache on page 0 when the cache is fresh and no refresh is forced.
        if page == 0, !forceRefresh, let cached = cacheStore.loadFreshPatterns() {
            let result = Self.clientPage(cached, filters: filters, sort: sort, page: 0, pageSize: pageSize)
            return ExploreFeedSnapshot(patterns: result.patterns, source: .cache, hasMore: result.hasMore)
        }

        do {
            let (patterns, hasMore) = try await fetchServerPage(
                sort: sort, filters: filters, page: page, pageSize: pageSize
            )
            // Refresh the offline cache whenever we successfully fetch page 0 of
            // the unfiltered feed — this is the most useful fallback for offline use.
            if page == 0, filters.isDefault {
                cacheStore.save(patterns)
            }
            return ExploreFeedSnapshot(patterns: patterns, source: .remote, hasMore: hasMore)
        } catch {
            // Network unavailable: fall back to whatever is in cache.
            if let cached = cacheStore.loadPatterns() {
                let result = Self.clientPage(cached, filters: filters, sort: sort, page: page, pageSize: pageSize)
                return ExploreFeedSnapshot(patterns: result.patterns, source: .cache, hasMore: result.hasMore)
            }
            throw error
        }
    }

    // MARK: - relatedPatterns

    func relatedPatterns(for pattern: Pattern, limit: Int) async throws -> [Pattern] {
        // Try cache first (avoids an extra round-trip on the detail screen).
        let basePatterns: [Pattern]
        if let cached = cacheStore.loadFreshPatterns() ?? cacheStore.loadPatterns() {
            basePatterns = cached
        } else {
            // Cache cold — fetch a small batch from the server.
            let (remote, _) = try await fetchServerPage(sort: .allTime, filters: .default, page: 0, pageSize: 50)
            basePatterns = remote
        }
        return Array(
            basePatterns
                .filter { $0.authorName == pattern.authorName && $0.id != pattern.id }
                .sorted { $0.saveCount > $1.saveCount }
                .prefix(limit)
        )
    }

    // MARK: - Server-side paginated fetch

    /// Fetches one page from the `patterns_explore` view with server-side
    /// filtering, sorting, and range. Requests `pageSize + 1` rows so we can
    /// determine `hasMore` without a separate COUNT query.
    private func fetchServerPage(
        sort: ExploreSortMode,
        filters: ExploreFilters,
        page: Int,
        pageSize: Int
    ) async throws -> (patterns: [Pattern], hasMore: Bool) {
        var query = client
            .from("patterns_explore")
            .select()

        // Server-side filters (only applied when a value is set)
        if let theme = filters.theme {
            query = query.eq("theme", value: theme.rawValue)
        }
        if let difficulty = filters.difficulty {
            query = query.eq("difficulty", value: difficulty.rawValue)
        }
        if let sizeTier = filters.sizeTier {
            query = query.eq("size_tier", value: sizeTier.rawValue)
        }

        // Server-side sort
        let primarySort = sort == .weekly ? "week_save_count" : "save_count"
        let from = page * pageSize

        let rows: [SupabasePatternRow] = try await query
            .order(primarySort, ascending: false)
            .order("created_at", ascending: false)
            .range(from: from, to: from + pageSize)  // one extra to probe hasMore
            .execute()
            .value

        let hasMore = rows.count > pageSize
        let patterns = rows.prefix(pageSize).map { $0.makePattern(storageBaseURL: config.url) }
        return (Array(patterns), hasMore)
    }

    // MARK: - Client-side page (cache path)

    /// Applies filter, sort, and page to a locally cached flat array.
    /// Used when serving from cache (offline / stale) so the user still
    /// gets sensible results.
    private static func clientPage(
        _ patterns: [Pattern],
        filters: ExploreFilters,
        sort: ExploreSortMode,
        page: Int,
        pageSize: Int
    ) -> (patterns: [Pattern], hasMore: Bool) {
        let filtered = patterns.filter { p in
            (filters.theme.map { p.theme == $0 } ?? true) &&
            (filters.difficulty.map { p.difficulty == $0 } ?? true) &&
            (filters.sizeTier.map { p.sizeTier == $0 } ?? true)
        }
        let sorted = filtered.sorted { lhs, rhs in
            switch sort {
            case .weekly:
                let l = lhs.weekSaveCount ?? 0, r = rhs.weekSaveCount ?? 0
                return l != r ? l > r : lhs.createdAt > rhs.createdAt
            case .allTime:
                return lhs.saveCount != rhs.saveCount
                    ? lhs.saveCount > rhs.saveCount
                    : lhs.createdAt > rhs.createdAt
            }
        }
        let start = page * pageSize
        let end = min(start + pageSize, sorted.count)
        let slice = start < sorted.count ? Array(sorted[start..<end]) : []
        return (slice, end < sorted.count)
    }
}

// MARK: - SupabaseCommunityService

final class SupabaseCommunityService: CommunityService {
    private let client: SupabaseClient
    private let savedPatternStore: SavedPatternStore

    init(config: SupabaseClientConfig, savedPatternStore: SavedPatternStore = SavedPatternStore()) {
        self.client = SupabaseClient(supabaseURL: config.url, supabaseKey: config.anonKey)
        self.savedPatternStore = savedPatternStore
    }

    func savedPatternIDs(deviceID: String) -> Set<UUID> {
        savedPatternStore.savedPatternIDs(for: deviceID)
    }

    func toggleSave(pattern: Pattern, deviceID: String) async throws -> Set<UUID> {
        var savedIDs = savedPatternStore.savedPatternIDs(for: deviceID)
        if savedIDs.contains(pattern.id) {
            try await client
                .from("saves")
                .delete()
                .eq("pattern_id", value: pattern.id.uuidString.lowercased())
                .eq("device_id", value: deviceID)
                .execute()
            savedIDs.remove(pattern.id)
        } else {
            do {
                try await client
                    .from("saves")
                    .insert([
                        "pattern_id": pattern.id.uuidString.lowercased(),
                        "device_id": deviceID
                    ])
                    .execute()
            } catch {
                if !Self.isDuplicateSave(error) {
                    throw error
                }
            }
            savedIDs.insert(pattern.id)
        }

        savedPatternStore.setSavedPatternIDs(savedIDs, for: deviceID)
        return savedIDs
    }

    private static func isDuplicateSave(_ error: Error) -> Bool {
        let message = error.localizedDescription.lowercased()
        return message.contains("duplicate") || message.contains("409")
    }
}

// MARK: - Row decoders

private struct SupabasePatternRow: Decodable {
    let id: UUID
    let title: String
    let authorName: String
    let width: Int
    let height: Int
    let pixels: [PatternPixel]
    let palette: [String]
    let difficulty: String
    let theme: String
    let saveCount: Int
    let weekSaveCount: Int          // provided by patterns_explore view
    let createdAt: Date
    let publishedAt: Date?
    let thumbnailPath: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case authorName = "author_name"
        case width
        case height
        case pixels
        case palette
        case difficulty
        case theme
        case saveCount = "save_count"
        case weekSaveCount = "week_save_count"
        case createdAt = "created_at"
        case publishedAt = "published_at"
        case thumbnailPath = "thumbnail_path"
    }

    func makePattern(storageBaseURL: URL) -> Pattern {
        Pattern(
            id: id,
            title: title.isEmpty ? L10n.tr("Untitled Draft") : title,
            authorName: authorName.isEmpty ? L10n.tr("Guest Maker") : authorName,
            width: width,
            height: height,
            pixels: pixels,
            palette: palette,
            status: .final,
            visibility: .public,
            difficulty: DifficultyLevel(rawValue: difficulty) ?? .easy,
            tags: [],
            likeCount: 0,
            saveCount: saveCount,
            weekSaveCount: weekSaveCount,
            isRemixable: true,
            createdAt: publishedAt ?? createdAt,
            theme: PatternTheme(rawValue: theme) ?? .other,
            thumbnailURL: Self.thumbnailURL(for: thumbnailPath, storageBaseURL: storageBaseURL)
        )
    }

    private static func thumbnailURL(for path: String?, storageBaseURL: URL) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        return storageBaseURL
            .appendingPathComponent("storage")
            .appendingPathComponent("v1")
            .appendingPathComponent("object")
            .appendingPathComponent("public")
            .appendingPathComponent("pattern-thumbnails")
            .appendingPathComponent(path)
    }
}

private struct SupabaseSaveRow: Decodable {
    let patternID: UUID

    enum CodingKeys: String, CodingKey {
        case patternID = "pattern_id"
    }
}
