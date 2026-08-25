// DemoApp entry point. Owner: demo app (M7.5).
//
// The M7.5 "real UIKit feel" demo (docs/APP_FEEL.md): a Settings-style
// multi-screen app written as ordinary UIKit code — UIViewController
// subclasses, addTarget actions, UIView.animate — against OpenUIKit.
// Hosted by `openhost --app demo`, which boots a UIApplication-lite around
// the navigation controller this factory returns.

import OpenUIKit

public enum DemoApp {
    /// The demo's default window size in points (iPhone-ish portrait).
    public static let windowSize = CGSize(width: 390, height: 780)

    /// Build the app's root: a UINavigationController on the Settings root.
    public static func makeRootViewController() -> UINavigationController {
        UINavigationController(rootViewController: SettingsRootViewController())
    }
}
