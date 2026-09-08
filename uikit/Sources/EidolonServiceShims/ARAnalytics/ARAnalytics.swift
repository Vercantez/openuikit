import Foundation

// ARAnalytics 5.0.1, 888744016bb4f53ad5b652819406645bd21f80c7:
// ARAnalytics.h:51,126,129,202,203,212 and ARAnalytics.m:821,822,831.
// These are the three selectors and three constant values Eidolon calls.
public let ARHockeyAppLiveID = "ARHockeyAppLiveID"
public let ARHockeyAppBetaID = "ARHockeyAppBetaID"
public let ARSegmentioWriteKey = "ARSegmentioWriteKey"

/// Service-unavailable adapter. No providers, keys, identities, or events are
/// retained, and no analytics/crash-report/network operation is started.
public final class ARAnalytics: NSObject {
    public static var isEnabled: Bool { false }

    public static func setup(withAnalytics analyticsDictionary: [AnyHashable: Any]!) {
        unavailable()
    }

    public static func event(_ event: String!) {
        unavailable()
    }

    public static func event(_ event: String!, withProperties properties: [AnyHashable: Any]!) {
        unavailable()
    }

    private static let lock = NSLock()
    private static var didReportUnavailable = false
    private static func unavailable() {
        lock.lock()
        defer { lock.unlock() }
        guard !didReportUnavailable else { return }
        didReportUnavailable = true
        print("OpenUIKit Eidolon: analytics and crash reporting are unavailable")
    }
}
