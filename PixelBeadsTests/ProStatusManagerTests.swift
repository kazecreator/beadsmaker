import XCTest
@testable import PixelBeads

@MainActor
final class ProStatusManagerTests: XCTestCase {

    // MARK: - AppSessionStore upgrade methods

    func testUpgradeToProSetsIsPro() {
        let store = AppSessionStore(userService: MockUserService())
        XCTAssertFalse(store.currentUser.isPro, "Guest should start as non-Pro")

        store.upgradeToPro()

        XCTAssertTrue(store.currentUser.isPro, "upgradeToPro should set isPro = true")
    }

    func testLinkAppleAccountUpdatesFields() {
        let store = AppSessionStore(userService: MockUserService())
        XCTAssertTrue(store.currentUser.isGuest, "Should start as guest")
        XCTAssertNil(store.currentUser.appleUserID, "appleUserID should start nil")

        store.linkAppleAccount(appleUserID: "apple-abc123", displayName: "Pixel Maker")

        XCTAssertEqual(store.currentUser.appleUserID, "apple-abc123")
        XCTAssertEqual(store.currentUser.displayName, "Pixel Maker")
        XCTAssertFalse(store.currentUser.isGuest, "linkAppleAccount should promote out of guest")
    }

    func testLinkAppleAccountKeepsExistingNameWhenGivenEmpty() {
        let store = AppSessionStore(userService: MockUserService())
        let originalName = store.currentUser.displayName

        store.linkAppleAccount(appleUserID: "apple-abc123", displayName: "   ")

        XCTAssertEqual(store.currentUser.displayName, originalName,
                       "Whitespace-only display name should not overwrite existing name")
    }

    // MARK: - User model: appleUserID field

    func testUserEncodesAndDecodesWithAppleUserID() throws {
        var user = MockData.guestUser
        user.appleUserID = "test-apple-user-id-xyz"

        let data = try JSONEncoder().encode(user)
        let decoded = try JSONDecoder().decode(User.self, from: data)

        XCTAssertEqual(decoded.appleUserID, "test-apple-user-id-xyz")
    }

    func testUserWithNilAppleUserIDRoundTrips() throws {
        var user = MockData.guestUser
        user.appleUserID = nil

        let data = try JSONEncoder().encode(user)
        let decoded = try JSONDecoder().decode(User.self, from: data)

        XCTAssertNil(decoded.appleUserID)
    }

    // MARK: - PurchaseResult enum coverage

    func testPurchaseResultCasesAreReachable() {
        let results: [PurchaseResult] = [.success, .userCancelled, .pending, .failed("test error")]
        for result in results {
            switch result {
            case .success: break
            case .userCancelled: break
            case .pending: break
            case .failed(let msg):
                XCTAssertFalse(msg.isEmpty)
            }
        }
    }
}
