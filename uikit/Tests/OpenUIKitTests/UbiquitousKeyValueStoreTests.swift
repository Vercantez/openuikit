import XCTest
import Foundation
@testable import OpenUIKit

final class UbiquitousKeyValueStoreTests: XCTestCase {
    private func freshStore() -> OpenUIKitUbiquitousKeyValueStore {
        let name = "OpenUI.NSUbiquitousKeyValueStore.tests.\(UUID().uuidString)"
        // The portable type always uses the named default suite; isolate by
        // writing through a throwaway store constructed via `init()` then
        // clearing keys we set. Contract: UserDefaults-backed getters match
        // the NSUbiquitousKeyValueStore Swift API (Hackers BookmarksRepository).
        let store = OpenUIKitUbiquitousKeyValueStore()
        _ = name
        return store
    }

    func testStringDataBoolRoundTrip() {
        let store = OpenUIKitUbiquitousKeyValueStore()
        let key = "silent-frameworks.\(UUID().uuidString)"
        store.removeObject(forKey: key)
        store.set("hello", forKey: key)
        XCTAssertEqual(store.string(forKey: key), "hello")
        let payload = Data([1, 2, 3])
        store.set(payload, forKey: key)
        XCTAssertEqual(store.data(forKey: key), payload)
        store.set(true, forKey: key)
        XCTAssertTrue(store.bool(forKey: key))
        store.set(Int64(42), forKey: key)
        XCTAssertEqual(store.longLong(forKey: key), 42)
        XCTAssertTrue(store.synchronize())
        store.removeObject(forKey: key)
        XCTAssertNil(store.object(forKey: key))
    }

    func testDefaultIsSingleton() {
        XCTAssertTrue(
            OpenUIKitUbiquitousKeyValueStore.default
                === OpenUIKitUbiquitousKeyValueStore.default
        )
    }

    func testDidChangeExternallyName() {
        XCTAssertEqual(
            OpenUIKitUbiquitousKeyValueStore.didChangeExternallyNotification.rawValue,
            "NSUbiquitousKeyValueStoreDidChangeExternallyNotification"
        )
    }

#if os(Linux)
    func testLinuxAliasIsThePortableType() {
        XCTAssertTrue(NSUbiquitousKeyValueStore.self == OpenUIKitUbiquitousKeyValueStore.self)
        let store = NSUbiquitousKeyValueStore.default
        store.set("kvs", forKey: "silent-frameworks.linux")
        XCTAssertEqual(store.string(forKey: "silent-frameworks.linux"), "kvs")
        store.removeObject(forKey: "silent-frameworks.linux")
    }
#endif
}
