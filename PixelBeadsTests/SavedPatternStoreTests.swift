import XCTest
@testable import PixelBeads

final class SavedPatternStoreTests: XCTestCase {
    func testSavedPatternIDsPersistPerDevice() {
        let defaults = UserDefaults(suiteName: #function)!
        defaults.removePersistentDomain(forName: #function)
        let store = SavedPatternStore(defaults: defaults)
        let firstID = UUID()
        let secondID = UUID()

        store.setSavedPatternIDs([firstID], for: "device-a")
        store.setSavedPatternIDs([secondID], for: "device-b")

        XCTAssertEqual(store.savedPatternIDs(for: "device-a"), [firstID])
        XCTAssertEqual(store.savedPatternIDs(for: "device-b"), [secondID])
    }
}
