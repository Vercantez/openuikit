// NSUbiquitousKeyValueStore backed by UserDefaults.
//
// Apple backs this API with iCloud. Linux corelibs-Foundation has no
// NSUbiquitousKeyValueStore. The portable class uses a private UserDefaults
// suite as a local replica and never manufactures didChangeExternally
// notifications for local writes (Apple only posts those for cloud replicas).
//
// On Darwin the name NSUbiquitousKeyValueStore is Foundation's; apps keep
// Apple's type. The portable implementation is always testable as
// OpenUIKitUbiquitousKeyValueStore.

import Foundation

public final class OpenUIKitUbiquitousKeyValueStore: NSObject, @unchecked Sendable {
    private static let _default = OpenUIKitUbiquitousKeyValueStore(
        defaults: UserDefaults(suiteName: "OpenUI.NSUbiquitousKeyValueStore")!
    )

    private let _defaults: UserDefaults

    public static var `default`: OpenUIKitUbiquitousKeyValueStore { _default }

    public static let didChangeExternallyNotification = Notification.Name(
        "NSUbiquitousKeyValueStoreDidChangeExternallyNotification"
    )
    public static let changeReasonKey = "NSUbiquitousKeyValueStoreChangeReasonKey"
    public static let changedKeysKey = "NSUbiquitousKeyValueStoreChangedKeysKey"

    public override convenience init() {
        self.init(defaults: UserDefaults(suiteName: "OpenUI.NSUbiquitousKeyValueStore")!)
    }

    private init(defaults: UserDefaults) {
        _defaults = defaults
        super.init()
    }

    public func object(forKey aKey: String) -> Any? {
        _defaults.object(forKey: aKey)
    }

    public func set(_ anObject: Any?, forKey aKey: String) {
        _defaults.set(anObject, forKey: aKey)
    }

    public func removeObject(forKey aKey: String) {
        _defaults.removeObject(forKey: aKey)
    }

    public func string(forKey aKey: String) -> String? {
        _defaults.string(forKey: aKey)
    }

    public func array(forKey aKey: String) -> [Any]? {
        _defaults.array(forKey: aKey)
    }

    public func dictionary(forKey aKey: String) -> [String: Any]? {
        _defaults.dictionary(forKey: aKey)
    }

    public func data(forKey aKey: String) -> Data? {
        _defaults.data(forKey: aKey)
    }

    public func longLong(forKey aKey: String) -> Int64 {
        switch object(forKey: aKey) {
        case let value as Bool: return value ? 1 : 0
        case let value as Int: return Int64(clamping: value)
        case let value as Int64: return value
        case let value as Double: return Int64(value)
        case let value as String: return Int64(value) ?? 0
        default: return 0
        }
    }

    public func double(forKey aKey: String) -> Double {
        _defaults.double(forKey: aKey)
    }

    public func bool(forKey aKey: String) -> Bool {
        _defaults.bool(forKey: aKey)
    }

    public func set(_ aString: String?, forKey aKey: String) {
        set(aString as Any?, forKey: aKey)
    }

    public func set(_ aData: Data?, forKey aKey: String) {
        set(aData as Any?, forKey: aKey)
    }

    public func set(_ anArray: [Any]?, forKey aKey: String) {
        set(anArray as Any?, forKey: aKey)
    }

    public func set(_ aDictionary: [String: Any]?, forKey aKey: String) {
        set(aDictionary as Any?, forKey: aKey)
    }

    public func set(_ value: Int64, forKey aKey: String) {
        set(value as Any, forKey: aKey)
    }

    public func set(_ value: Double, forKey aKey: String) {
        set(value as Any, forKey: aKey)
    }

    public func set(_ value: Bool, forKey aKey: String) {
        set(value as Any, forKey: aKey)
    }

    public var dictionaryRepresentation: [String: Any] {
        _defaults.dictionaryRepresentation()
    }

    @discardableResult
    public func synchronize() -> Bool {
        _defaults.synchronize()
    }
}

#if os(Linux)
public typealias NSUbiquitousKeyValueStore = OpenUIKitUbiquitousKeyValueStore
public let NSUbiquitousKeyValueStoreDidChangeExternallyNotification =
    NSUbiquitousKeyValueStore.didChangeExternallyNotification
public let NSUbiquitousKeyValueStoreChangeReasonKey =
    NSUbiquitousKeyValueStore.changeReasonKey
public let NSUbiquitousKeyValueStoreChangedKeysKey =
    NSUbiquitousKeyValueStore.changedKeysKey
public let NSUbiquitousKeyValueStoreServerChange = 0
public let NSUbiquitousKeyValueStoreInitialSyncChange = 1
public let NSUbiquitousKeyValueStoreQuotaViolationChange = 2
public let NSUbiquitousKeyValueStoreAccountChange = 3
#endif
