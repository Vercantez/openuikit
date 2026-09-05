// HARNESS CODE — the selector dispatch tables the vendored app source cannot
// supply for itself.
//
// docs/OBJC_RUNTIME.md item 1: native ELF has no Objective-C interoperability,
// so even NSObject-backed OpenUIKit targets must publish a name -> method
// table there. Real UIKit needs none of this. It is two lines plus one line
// per action, and it is the single largest per-file source cost the real-app
// harness measured — counted as such in docs/REAL_APP_TEST.md.
//
// It lives OUTSIDE Vendored/ so the vendored files stay a clean diff against
// the app's own source.

import OpenUIKit

extension SimpleActionView: SelectorDispatching {
    static let actions: ActionTable<SimpleActionView> = [
        .action("switchToggled:", SimpleActionView.switchToggled),
        .action("actionTapped", SimpleActionView.actionTapped),
    ]
    func perform(_ name: String, with sender: Any?) -> Bool {
        Self.actions.perform(name, on: self, with: sender)
    }
}

// The themeable base classes each observe Constants.Notifications.themeChanged
// by selector. Nothing in the harness posts it — one frame, one theme — but the
// observer is registered in their initialisers, so the name has to resolve.
extension ThemeableView: SelectorDispatching {
    static let actions: ActionTable<ThemeableView> = [
        .action("themeDidChange", ThemeableView.themeDidChange),
    ]
    func perform(_ name: String, with sender: Any?) -> Bool {
        Self.actions.perform(name, on: self, with: sender)
    }
}

extension ThemeableLabel: SelectorDispatching {
    static let actions: ActionTable<ThemeableLabel> = [
        .action("themeDidChange", ThemeableLabel.themeDidChange),
    ]
    func perform(_ name: String, with sender: Any?) -> Bool {
        Self.actions.perform(name, on: self, with: sender)
    }
}

extension ThemeableTable: SelectorDispatching {
    static let actions: ActionTable<ThemeableTable> = [
        .action("themeDidChange", ThemeableTable.themeDidChange),
    ]
    func perform(_ name: String, with sender: Any?) -> Bool {
        Self.actions.perform(name, on: self, with: sender)
    }
}

extension ThemeableCell: SelectorDispatching {
    static let actions: ActionTable<ThemeableCell> = [
        .action("themeDidChange", ThemeableCell.themeDidChange),
    ]
    func perform(_ name: String, with sender: Any?) -> Bool {
        Self.actions.perform(name, on: self, with: sender)
    }
}

extension StorageAndDataUseViewController: SelectorDispatching {
    static let actions: ActionTable<StorageAndDataUseViewController> = [
        .action("warnWhenNotOnWifiToggled:",
                StorageAndDataUseViewController.warnWhenNotOnWifiToggled),
    ]
    func perform(_ name: String, with sender: Any?) -> Bool {
        Self.actions.perform(name, on: self, with: sender)
    }
}

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
