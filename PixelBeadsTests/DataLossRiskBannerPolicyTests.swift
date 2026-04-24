import XCTest
@testable import PixelBeads

final class DataLossRiskBannerPolicyTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "DataLossRiskBannerPolicyTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        if let suiteName {
            UserDefaults().removePersistentDomain(forName: suiteName)
        }
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testBannerShowsForFreeUserWithoutDismissalHistory() {
        let policy = DataLossRiskBannerPolicy(defaults: defaults, now: { Date(timeIntervalSince1970: 10_000) })

        XCTAssertTrue(policy.shouldShow(for: MockData.guestUser))
    }

    func testBannerWaitsThirtyDaysAfterDismissal() {
        let firstNow = Date(timeIntervalSince1970: 1_000_000)
        var policy = DataLossRiskBannerPolicy(defaults: defaults, now: { firstNow })
        policy.markDismissed()

        policy = DataLossRiskBannerPolicy(defaults: defaults, now: {
            firstNow.addingTimeInterval(DataLossRiskBannerPolicy.reminderInterval - 60)
        })
        XCTAssertFalse(policy.shouldShow(for: MockData.guestUser))

        policy = DataLossRiskBannerPolicy(defaults: defaults, now: {
            firstNow.addingTimeInterval(DataLossRiskBannerPolicy.reminderInterval + 60)
        })
        XCTAssertTrue(policy.shouldShow(for: MockData.guestUser))
    }

    func testBannerStaysHiddenForProUsers() {
        let proUser = User(
            id: MockData.guestUser.id,
            displayName: "Pro",
            avatar: MockData.guestUser.avatar,
            isGuest: false,
            isClaimed: false,
            isPro: true
        )
        let policy = DataLossRiskBannerPolicy(defaults: defaults, now: Date.init)

        XCTAssertFalse(policy.shouldShow(for: proUser))
    }
}
