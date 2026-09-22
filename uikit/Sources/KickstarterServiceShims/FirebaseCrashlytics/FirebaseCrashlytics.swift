// Fail-closed stand-in for FirebaseCrashlytics from firebase-ios-sdk 11.15.0
// (fdc352fa). ios-oss calls exactly two members:
//   Crashlytics.crashlytics().record(error:)   — 10 sites (OAuth.swift x4,
//     AppEnvironment.swift x2, PledgeManagerWebViewModel.swift,
//     AppDelegateViewModel.swift, LoginToutViewController.swift x2) plus
//     AppDelegate.swift:503
//   Crashlytics.crashlytics().log(format:arguments:) — AppDelegate.swift:217
// There is no crash-reporting backend: records and logs are dropped, never
// queued for upload. `pendingReports` is not SDK API; it lets a test prove
// that nothing was retained.
import Foundation

public final class Crashlytics {
    private static let shared = Crashlytics()
    private init() {}

    public static func crashlytics() -> Crashlytics { shared }

    /// Dropped (no reporting backend).
    public func record(error: Error, userInfo: [String: Any]? = nil) {}

    /// Dropped (no reporting backend).
    public func log(format: String, arguments: CVaListPointer) {}

    /// Dropped (no reporting backend).
    public func log(_ msg: String) {}

    /// Not SDK API. Always 0: nothing is ever queued for upload.
    public var pendingReports: Int { 0 }
}
