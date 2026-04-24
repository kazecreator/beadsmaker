import XCTest
@testable import PixelBeads

final class ExploreCacheStoreTests: XCTestCase {
    func testFreshCacheReturnsPatternsWithinTTL() {
        let baseURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = ExploreCacheStore(baseURL: baseURL, ttl: 600)
        let patterns = [MockData.explorePatterns[0]]

        store.save(patterns, now: .now)

        XCTAssertEqual(store.loadFreshPatterns(now: .now.addingTimeInterval(60))?.count, 1)
    }

    func testExpiredCacheReturnsNilForFreshLoadButKeepsOfflineCopy() {
        let baseURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = ExploreCacheStore(baseURL: baseURL, ttl: 10)
        let patterns = [MockData.explorePatterns[0]]

        store.save(patterns, now: .now)

        XCTAssertNil(store.loadFreshPatterns(now: .now.addingTimeInterval(11)))
        XCTAssertEqual(store.loadPatterns()?.count, 1)
    }
}
