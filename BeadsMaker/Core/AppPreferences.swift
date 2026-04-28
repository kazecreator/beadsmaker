import Foundation

struct DataLossRiskBannerPolicy {
    static let reminderInterval: TimeInterval = 30 * 24 * 60 * 60
    static let storageKey = "profile.dataLossRiskBanner.lastDismissedAt"

    let defaults: UserDefaults
    let now: () -> Date

    init(defaults: UserDefaults = .standard, now: @escaping () -> Date = Date.init) {
        self.defaults = defaults
        self.now = now
    }

    func shouldShow(for user: User) -> Bool {
        guard !user.isPro else { return false }
        guard let lastDismissedAt = defaults.object(forKey: Self.storageKey) as? Date else {
            return true
        }
        return now().timeIntervalSince(lastDismissedAt) >= Self.reminderInterval
    }

    func markDismissed() {
        defaults.set(now(), forKey: Self.storageKey)
    }
}
