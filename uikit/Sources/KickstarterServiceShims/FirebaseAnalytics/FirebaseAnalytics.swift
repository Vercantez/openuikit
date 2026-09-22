// Fail-closed stand-in for FirebaseAnalytics (GoogleAppMeasurement 11.15.0,
// 45ce435e) — the consent call ios-oss makes through `import Firebase`:
// `Analytics.setConsent([.analyticsStorage: s, .adStorage: s, .adUserData: s,
// .adPersonalization: s])` (Kickstarter-iOS/AppDelegate.swift:456) with
// `ConsentStatus` `.granted` / `.denied`. Nothing is measured or sent; the
// consent map is dropped. `consentSettingsRecorded` is not SDK API — it lets
// a test prove no consent state was retained.
//
// The type is named `Analytics` exactly as in the SDK. AppDelegate also
// imports Segment, whose class is also `Analytics`; the app only ever spells
// Firebase's as an expression (`Analytics.setConsent`) and Segment's with a
// member Firebase's lacks, so overload resolution picks one — the member sets
// here must stay disjoint from Segment's.
import Foundation

public struct ConsentType: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let adStorage = ConsentType(rawValue: "ad_storage")
    public static let analyticsStorage = ConsentType(rawValue: "analytics_storage")
    public static let adUserData = ConsentType(rawValue: "ad_user_data")
    public static let adPersonalization = ConsentType(rawValue: "ad_personalization")
}

public struct ConsentStatus: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let denied = ConsentStatus(rawValue: "denied")
    public static let granted = ConsentStatus(rawValue: "granted")
}

public final class Analytics {
    private init() {}

    /// Dropped: there is no measurement service to receive consent.
    public static func setConsent(_ consentSettings: [ConsentType: ConsentStatus]) {}

    /// Not SDK API. Always 0: `setConsent` retains nothing.
    public static var consentSettingsRecorded: Int { 0 }
}
