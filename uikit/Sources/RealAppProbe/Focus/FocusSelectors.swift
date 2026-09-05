// Harness, not app source: the selector table for Firefox Focus's
// SettingsViewController. Under Focus/ so the guest builder's top-level
// glob does not compile it (see RealAppScreen.focusScreens).

import OpenUIKit

// mozilla-mobile/focus-ios SettingsViewController at a2832521. Selector
// names from Tools/objcshim/selector_oracle.swift: zero-arg is the base
// name; `toggleSwitched(_:)` is `toggleSwitched:`; first-arg label
// `gestureRecognizer:` is not a preposition so Swift inserts `With`.
extension SettingsViewController: SelectorDispatching {
    static let actions: ActionTable<SettingsViewController> = [
        .action("dismissSettings", SettingsViewController.dismissSettings),
        .action("toggleSwitched:", SettingsViewController.toggleSwitched),
        .action("applicationDidBecomeActive",
                SettingsViewController.applicationDidBecomeActive),
        .action("tappedLearnMoreFooterWithGestureRecognizer:",
                SettingsViewController.tappedLearnMoreFooter),
        .action("tappedLearnMoreSearchSuggestionsFooterWithGestureRecognizer:",
                SettingsViewController.tappedLearnMoreSearchSuggestionsFooter),
        .action("tappedLearnMoreStudiesWithGestureRecognizer:",
                SettingsViewController.tappedLearnMoreStudies),
    ]
    func perform(_ name: String, with sender: Any?) -> Bool {
        Self.actions.perform(name, on: self, with: sender)
    }
}

extension HomeViewController: SelectorDispatching {
    static let actions: ActionTable<HomeViewController> = [
        .action("rotated", HomeViewController.rotated),
    ]
    func perform(_ name: String, with sender: Any?) -> Bool {
        Self.actions.perform(name, on: self, with: sender)
    }
}
