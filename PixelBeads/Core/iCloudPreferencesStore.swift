import Foundation

extension Notification.Name {
    static let iCloudPreferencesDidChange = Notification.Name("iCloudPreferencesDidChange")
}

/// Wraps NSUbiquitousKeyValueStore with local UserDefaults fallback for fast reads.
final class iCloudPreferencesStore {
    private let kvs = NSUbiquitousKeyValueStore.default
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        syncFromKVS()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleExternalChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: kvs
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - String

    func string(forKey key: String) -> String? {
        defaults.string(forKey: key) ?? kvs.string(forKey: key)
    }

    func set(_ value: String, forKey key: String) {
        defaults.set(value, forKey: key)
        kvs.set(value, forKey: key)
        kvs.synchronize()
    }

    // MARK: - Data

    func data(forKey key: String) -> Data? {
        defaults.data(forKey: key) ?? kvs.data(forKey: key)
    }

    func set(_ value: Data, forKey key: String) {
        defaults.set(value, forKey: key)
        kvs.set(value, forKey: key)
        kvs.synchronize()
    }

    // MARK: - Array

    func stringArray(forKey key: String) -> [String]? {
        defaults.stringArray(forKey: key) ?? kvs.array(forKey: key) as? [String]
    }

    func set(_ value: [String], forKey key: String) {
        defaults.set(value, forKey: key)
        kvs.set(value, forKey: key)
        kvs.synchronize()
    }

    // MARK: - UUID Set

    func uuidSet(forKey key: String) -> Set<UUID> {
        guard let strings = stringArray(forKey: key) else { return [] }
        return Set(strings.compactMap(UUID.init(uuidString:)))
    }

    func set(_ value: Set<UUID>, forKey key: String) {
        let strings = value.map(\.uuidString)
        set(strings, forKey: key)
    }

    // MARK: - Remove

    func remove(forKey key: String) {
        defaults.removeObject(forKey: key)
        kvs.removeObject(forKey: key)
        kvs.synchronize()
    }

    // MARK: - Private

    private func syncFromKVS() {
        for (key, value) in kvs.dictionaryRepresentation {
            if defaults.object(forKey: key) == nil {
                defaults.set(value, forKey: key)
            }
        }
    }

    @objc private func handleExternalChange() {
        for (key, value) in kvs.dictionaryRepresentation {
            defaults.set(value, forKey: key)
        }
        NotificationCenter.default.post(name: .iCloudPreferencesDidChange, object: nil)
    }
}
