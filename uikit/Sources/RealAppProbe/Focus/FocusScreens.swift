// Harness, not app source: the Firefox Focus row(s) of RealAppScreen's
// table and their builder. Compiled into RealAppProbe on every route
// (SwiftPM and the guest builder's Focus/ glob).

import OpenUIKit
import Foundation
import Onboarding
#if canImport(Blockzilla)
import Blockzilla
#endif

extension RealAppScreen {
    /// Copy SearchPlugins / disconnect-*.json / WebView JS next to the
    /// executable before any variant touches Bundle.main. MEASURED try3:
    /// a copy after the first Bundle.main resource access was invisible
    /// to path(forResource:ofType:).
    public static func installFocusBundleResourcesIfNeeded() {
        #if canImport(Blockzilla)
        FocusBrowserLaunch.installBundleResources()
        #endif
    }

    static let focusScreenTable: [Screen] = [
        // Firefox Focus Settings. Captured on the iPhone 16 @3x
        // (scripts/realapp_probe_sim.sh); the Pocket Casts rows stay.
        Screen(name: "realapp_focus_settings_light", variant: .focusSettings,
               theme: .light, style: .light, contentSizeCategory: .large,
               presentsSheet: false),
    ]

    /// Home is last in `RealAppScreen.screens` (after Hackers and Ledger)
    /// so a guest scale-2 iOS-cut miss cannot drop the screens before it.
    /// MEASURED arm64 verify 399c3d76:
    /// `GUEST_REALAPP_SCREENS=12` then
    /// `OPENUIKIT_IOS_INK_MISS: I|system-semibold|18|light|F0.0|83`
    /// (`glyph_ink_ios.json` has no system-semibold|18; the 3x table does).
    static let focusHomeTable: [Screen] = [
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
        // RealApp.swift / openhost already pointed imageSearchPaths at the
        // absolute assets argv. A relative defaultAssetsDirectory only works
        // when cwd is uikit/; guest machorun cwd is build/full (attempt 11
        // storage nibs; this home would miss img_focus_wordmark the same way).
        if OpenUIKitRuntime.imageSearchPaths.isEmpty {
            configureAssets(directory: defaultAssetsDirectory)
        }
        let home = HomeViewController(tipManager: TipManager())
        home.onboardingEventsHandler = HarnessOnboardingEventsHandler()
        home.view.backgroundColor = .systemBackground
        return home
    }

    /// The real AppDelegate launch is the fifteenth screen on routes that
    /// compile Blockzilla (Darwin and the Linux-hosted Mach-O guest).
    static let focusBrowserTable: [Screen] = {
        #if canImport(Blockzilla)
        return [
            Screen(name: "realapp_focus_browser_light", variant: .focusBrowser,
                   theme: .light, style: .light, contentSizeCategory: .large,
                   presentsSheet: false),
        ]
        #else
        return []
        #endif
    }()

    public static func makeFocusBrowserScreen() -> UIViewController {
        #if canImport(Blockzilla)
        if OpenUIKitRuntime.imageSearchPaths.isEmpty {
            configureAssets(directory: defaultAssetsDirectory)
        }
        return FocusBrowserLaunch.makeRoot()
        #else
        return makeFocusHomeScreen()
        #endif
    }
}
