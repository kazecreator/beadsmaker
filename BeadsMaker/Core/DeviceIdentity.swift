import Foundation
import Security

/// Generates and persists a stable device UUID in the Keychain.
/// With iCloud Keychain enabled, the UUID survives app reinstalls.
enum DeviceIdentity {
    private static let store = DeviceIdentityStore(
        service: "com.kevinzhang.beadsmaker",
        account: "device-uuid",
        synchronizable: true
    )

    static var deviceID: String {
        store.deviceID()
    }
}

struct DeviceIdentityStore {
    let service: String
    let account: String
    let synchronizable: Bool

    func deviceID() -> String {
        if let existing = read() { return existing }
        let new = UUID().uuidString
        save(new)
        return new
    }

    func reset() {
        SecItemDelete(deleteQuery as CFDictionary)
    }

    private func read() -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecAttrSynchronizable: kSecAttrSynchronizableAny
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8)
        else { return nil }
        return string
    }

    private func save(_ value: String) {
        guard let data = value.data(using: .utf8) else { return }
        var query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock
        ]
        if synchronizable {
            // kSecAttrSynchronizable allows the UUID to survive reinstalls via iCloud Keychain.
            query[kSecAttrSynchronizable] = kCFBooleanTrue
        }
        SecItemDelete(deleteQuery as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private var deleteQuery: [CFString: Any] {
        [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecAttrSynchronizable: kSecAttrSynchronizableAny
        ]
    }
}
