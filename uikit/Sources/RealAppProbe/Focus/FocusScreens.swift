// Harness, not app source: the Firefox Focus row(s) of RealAppScreen's
// table and their builder. Compiled into RealAppProbe on every route
// (SwiftPM and the guest builder's Focus/ glob).

import OpenUIKit
import Foundation
import Onboarding

extension RealAppScreen {
    static let focusScreenTable: [Screen] = [
        // Firefox Focus Settings. Captured on the iPhone 16 @3x
        // (scripts/realapp_probe_sim.sh); the Pocket Casts rows stay.
        Screen(name: "realapp_focus_settings_light", variant: .focusSettings,
               theme: .light, style: .light, contentSizeCategory: .large,
               presentsSheet: false),
        // Firefox Focus browser home (HomeViewController as the window
        // root). Captured on the iPhone 16 @3x; BrowserViewController's
        // WKWebView / SnapKit URL bar is a listed blocker, so this is the
        // home overlay the app installs at launch (wordmark + tips).
        Screen(name: "realapp_focus_home_light", variant: .focusHome,
               theme: .light, style: .light, contentSizeCategory: .large,
               presentsSheet: false),
    ]

    /// Focus presents Settings inside a UINavigationController
    /// (BrowserViewController.showSettings). The capture is that nav+table
    /// as the window root so viewDidLoad's `navigationController!` holds.
    static func makeFocusSettingsScreen() -> UIViewController {
        let settings = SettingsViewController(
            searchEngineManager: SearchEngineManager(),
            authenticationManager: AuthenticationManager(),
            onboardingEventsHandler: HarnessOnboardingEventsHandler(),
            themeManager: ThemeManager(),
            dismissScreenCompletion: {},
            shouldScrollToSiri: false
        )
        return UINavigationController(rootViewController: settings)
    }

    /// HomeViewController is the overlay BrowserViewController.createHomeView
    /// installs at launch (mozilla-mobile/focus-ios a2832521). The window
    /// root is the home controller itself so the wordmark / tips layout is
    /// the first screen without WKWebView.
    public static func makeFocusHomeScreen() -> UIViewController {
        configureAssets(directory: defaultAssetsDirectory)
        let home = HomeViewController(tipManager: TipManager())
        home.onboardingEventsHandler = HarnessOnboardingEventsHandler()
        home.view.backgroundColor = .systemBackground
        return home
    }
}
