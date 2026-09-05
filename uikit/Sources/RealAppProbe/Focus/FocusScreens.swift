// Harness, not app source: the Firefox Focus row(s) of RealAppScreen's
// table and their builder. Lives under Focus/ so the guest builder's
// top-level glob (full/scripts/build_full.sh) does not compile it — see
// RealAppScreen.focusScreens.

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
}
