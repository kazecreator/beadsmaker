import Foundation

struct ExplorePreferencesStore {
    private let defaults: UserDefaults
    private let sortKey = "explore.sort-mode"
    private let filtersKey = "explore.filters"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadSortMode() -> ExploreSortMode {
        guard let rawValue = defaults.string(forKey: sortKey),
              let mode = ExploreSortMode(rawValue: rawValue)
        else { return .weekly }
        return mode
    }

    func saveSortMode(_ mode: ExploreSortMode) {
        defaults.set(mode.rawValue, forKey: sortKey)
    }

    func loadFilters() -> ExploreFilters {
        guard let data = defaults.data(forKey: filtersKey),
              let filters = try? JSONDecoder().decode(ExploreFilters.self, from: data)
        else { return .default }
        return filters
    }

    func saveFilters(_ filters: ExploreFilters) {
        guard let data = try? JSONEncoder().encode(filters) else { return }
        defaults.set(data, forKey: filtersKey)
    }
}

struct SavedPatternStore {
    private let defaults: UserDefaults
    private let keyPrefix = "explore.saved-pattern-ids"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func savedPatternIDs(for deviceID: String) -> Set<UUID> {
        let key = storageKey(for: deviceID)
        let rawValues = defaults.stringArray(forKey: key) ?? []
        return Set(rawValues.compactMap(UUID.init(uuidString:)))
    }

    func setSavedPatternIDs(_ ids: Set<UUID>, for deviceID: String) {
        defaults.set(ids.map(\.uuidString).sorted(), forKey: storageKey(for: deviceID))
    }

    private func storageKey(for deviceID: String) -> String {
        "\(keyPrefix).\(deviceID)"
    }
}

struct ExploreCacheStore {
    private struct CacheEnvelope: Codable {
        let fetchedAt: Date
        let patterns: [Pattern]
    }

    private let fileManager = FileManager.default
    private let fileURL: URL
    private let ttl: TimeInterval

    init(baseURL: URL? = nil, ttl: TimeInterval = 600) {
        let root = baseURL ??
            fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PixelBeads", isDirectory: true)
        self.fileURL = root.appendingPathComponent("explore-cache.json")
        self.ttl = ttl
        try? fileManager.createDirectory(at: root, withIntermediateDirectories: true)
    }

    func loadFreshPatterns(now: Date = .now) -> [Pattern]? {
        guard let envelope = loadEnvelope(), now.timeIntervalSince(envelope.fetchedAt) <= ttl else {
            return nil
        }
        return envelope.patterns
    }

    func loadPatterns() -> [Pattern]? {
        loadEnvelope()?.patterns
    }

    func save(_ patterns: [Pattern], now: Date = .now) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(CacheEnvelope(fetchedAt: now, patterns: patterns)) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    private func loadEnvelope() -> CacheEnvelope? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? decoder.decode(CacheEnvelope.self, from: data)
    }
}
