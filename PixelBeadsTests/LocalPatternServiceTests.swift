import XCTest
@testable import PixelBeads

final class LocalPatternServiceTests: XCTestCase {
    private var tempRootURL: URL!

    override func setUp() {
        super.setUp()
        tempRootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("PixelBeadsTests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: tempRootURL, withIntermediateDirectories: true)
    }

    override func tearDown() {
        if let tempRootURL {
            try? FileManager.default.removeItem(at: tempRootURL)
        }
        super.tearDown()
    }

    func testSavedDraftPersistsAcrossServiceInstances() {
        let service = LocalPatternService(baseURL: tempRootURL)
        let user = MockData.guestUser
        var pattern = service.createBlankPattern(for: user)
        pattern.title = "Persistence Test"
        pattern.pixels = [PatternPixel(x: 1, y: 2, colorHex: "#111111")]

        _ = service.saveDraft(pattern, for: user)

        let reloaded = LocalPatternService(baseURL: tempRootURL)
        let drafts = reloaded.fetchLibraryContent(for: user).drafts

        XCTAssertEqual(drafts.count, 1)
        XCTAssertEqual(drafts.first?.title, "Persistence Test")
        XCTAssertEqual(drafts.first?.pixels.count, 1)
    }

    func testFreeUserDraftLimitStopsAtTwentyDrafts() {
        let service = LocalPatternService(baseURL: tempRootURL)
        let user = MockData.guestUser

        for index in 0...20 {
            var pattern = service.createBlankPattern(for: user)
            pattern.id = UUID()
            pattern.title = "Draft \(index)"
            pattern.pixels = [PatternPixel(x: index, y: 0, colorHex: "#111111")]
            _ = service.saveDraft(pattern, for: user)
        }

        let drafts = service.fetchLibraryContent(for: user).drafts
        XCTAssertEqual(drafts.count, LocalPatternService.maxFreeDrafts)
    }

    func testDeleteDraftRemovesPersistedDraft() {
        let service = LocalPatternService(baseURL: tempRootURL)
        let user = MockData.guestUser
        var pattern = service.createBlankPattern(for: user)
        pattern.title = "Delete Me"
        let saved = service.saveDraft(pattern, for: user)

        service.deleteDraft(id: saved.id)

        let drafts = service.fetchLibraryContent(for: user).drafts
        XCTAssertTrue(drafts.isEmpty)
    }
}
