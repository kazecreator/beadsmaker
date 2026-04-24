import XCTest
@testable import PixelBeads

final class ExplorePreferencesStoreTests: XCTestCase {
    func testSortModePersists() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let store = ExplorePreferencesStore(defaults: defaults)

        store.saveSortMode(.allTime)

        XCTAssertEqual(store.loadSortMode(), .allTime)
    }

    func testFiltersPersist() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let store = ExplorePreferencesStore(defaults: defaults)
        let filters = ExploreFilters(theme: .animals, difficulty: .medium, sizeTier: .large)

        store.saveFilters(filters)

        XCTAssertEqual(store.loadFilters(), filters)
    }
}
