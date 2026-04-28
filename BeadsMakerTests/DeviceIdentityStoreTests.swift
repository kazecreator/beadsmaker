import XCTest
@testable import BeadsMaker

final class DeviceIdentityStoreTests: XCTestCase {
    func testDeviceIdentityReturnsStableValueForSameKeychainEntry() {
        let store = DeviceIdentityStore(
            service: "com.kevinzhang.beadsmaker.tests.\(UUID().uuidString)",
            account: "device-uuid",
            synchronizable: false
        )
        store.reset()

        let first = store.deviceID()
        let second = store.deviceID()

        XCTAssertEqual(first, second)
        XCTAssertFalse(first.isEmpty)

        store.reset()
    }
}
