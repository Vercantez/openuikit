// A durable, property-list-compatible NSUbiquitousKeyValueStore for
// Linux-hosted Mach-O guests.
//
// Apple backs this API with iCloud.  A Linux host has no iCloud KVS daemon or
// account identity to delegate to, so this implementation deliberately uses a
// private UserDefaults suite as its durable local replica.  The public storage
// and conversion semantics remain useful to unchanged applications, while the
// absence of cross-device synchronization stays explicit: this class never
// manufactures didChangeExternally notifications for local writes.

import FoundationEssentials
import OpenUIKit

#if canImport(ObjectiveC)
import class ObjectiveC.NSObject
#else
#error("NSUbiquitousKeyValueStore requires the ObjectiveC NSObject substrate")
#endif

public final class NSUbiquitousKeyValueStore: NSObject, @unchecked Sendable {
    private static let _default = NSUbiquitousKeyValueStore(
        defaults: UserDefaults(suiteName: "OpenUI.NSUbiquitousKeyValueStore")!
    )

    private let _defaults: UserDefaults

    public static var `default`: NSUbiquitousKeyValueStore { _default }

    /// The notification Apple posts when a cloud replica changes underneath
    /// the process.  Local writes do not post this notification.
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
        case let value as UInt: return Int64(clamping: value)
        case let value as Int64: return value
        case let value as UInt64: return Int64(clamping: value)
        case let value as Double: return Int64(value)
        case let value as Float: return Int64(value)
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
        let reloaded = _defaults._reloadExternalChanges()
        guard reloaded.success else { return false }
        if !reloaded.changedKeys.isEmpty {
            NotificationCenter.default.post(
                name: Self.didChangeExternallyNotification,
                object: self,
                userInfo: [
                    Self.changeReasonKey: NSUbiquitousKeyValueStoreServerChange,
                    Self.changedKeysKey: reloaded.changedKeys,
                ]
            )
        }
        return _defaults.synchronize()
    }
}

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
