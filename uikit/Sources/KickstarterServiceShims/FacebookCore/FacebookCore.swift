// Fail-closed stand-in for FacebookCore / FBSDKCoreKit from facebook-ios-sdk
// 12.3.2 (e14f3499). Surface = what ios-oss touches:
//   Library/FacebookSDK.swift:12-25  Settings.shared.isEventDataUsageLimited /
//     .appID, ApplicationDelegate.shared.application(_:didFinishLaunching
//     WithOptions:) and application(_:open:options:)
//   Library/UIAlertController.swift:262-264  ErrorLocalizedTitleKey /
//     ErrorLocalizedDescriptionKey (reached through `import FacebookLogin`)
//
// There is no Facebook SDK session on OpenUIKit: settings are stored locally
// (they are plain properties in the SDK too) but nothing is sent; the
// launch hook starts nothing; `application(_:open:options:)` reports the URL
// as NOT handled, so the app's own deep-link path runs
// (Kickstarter-iOS/AppDelegate.swift:329).
import Foundation
import UIKit

public let ErrorLocalizedTitleKey = "com.facebook.sdk:FBSDKErrorLocalizedTitleKey"
public let ErrorLocalizedDescriptionKey = "com.facebook.sdk:FBSDKErrorLocalizedDescriptionKey"

public final class Settings {
    public static let shared = Settings()
    private init() {}

    public var appID: String?
    public var isEventDataUsageLimited = false
}

public final class ApplicationDelegate {
    public static let shared = ApplicationDelegate()
    private init() {}

    /// Starts no SDK session; returns false.
    @discardableResult
    public func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        false
    }

    /// Never handles a URL: there is no Facebook login flow to return to.
    @discardableResult
    public func application(
        _ application: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        false
    }
}

public final class AccessToken {
    public let tokenString: String
    init(tokenString: String) { self.tokenString = tokenString }

    /// No token is ever current.
    public static var current: AccessToken? { nil }
}
