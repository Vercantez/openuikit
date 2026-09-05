import Foundation

/// Music Haptics requires the Apple Music / Core Haptics track service.
/// Linux exposes the types and keeps the manager inactive.
public struct MAMusicHaptics: Sendable, Equatable {
    public init() {}

    public static var enabledStatusDidChangeNotification: Notification.Name {
        Notification.Name("MAMusicHapticsEnabledStatusDidChangeNotification")
    }
}

final class _MAMusicHapticsObserverToken: NSObject, NSCopying {
    func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return self
    }
}

open class MAMusicHapticsManager: NSObject {
    public static let shared = MAMusicHapticsManager()

    public static let activeStatusDidChangeNotification = NSNotification.Name(
        "MAMusicHapticsManagerActiveStatusDidChangeNotification"
    )

    private let lock = NSLock()
    private var observers: [ObjectIdentifier: (String, Bool) -> Void] = [:]

    public override init() {
        super.init()
    }

    public var isActive: Bool { false }

    public func addStatusObserver(
        _ statusHandler: @escaping (String, Bool) -> Void
    ) -> (any NSCopying)? {
        let token = _MAMusicHapticsObserverToken()
        lock.lock()
        observers[ObjectIdentifier(token)] = statusHandler
        lock.unlock()
        return token
    }

    public func removeStatusObserver(_ registrationToken: any NSCopying) {
        let object = registrationToken as AnyObject
        lock.lock()
        observers.removeValue(forKey: ObjectIdentifier(object))
        lock.unlock()
    }

    public func checkHapticTrackAvailabilityForMedia(
        matchingCode internationalStandardRecordingCode: String,
        completionHandler: ((Bool) -> Void)? = nil
    ) {
        _ = internationalStandardRecordingCode
        completionHandler?(false)
    }
}
