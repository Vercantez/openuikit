@_exported import Foundation

#if canImport(Contacts)
import Contacts
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif

/// Linux starting point for Apple's public `ContactsUI` module.
///
/// Isolated host compilation has Foundation only. `Contacts`, `UIKit`, and
/// `SwiftUI` APIs compile exclusively when those modules are importable.
/// Linux has no address book, contact-picker UI, or limited-access grant
/// sheet: every path that would reveal or persist contact records stays
/// fail-closed.

/// Linux host-test control. Hidden from ordinary `import ContactsUI` clients
/// and not part of Apple's public ContactsUI surface.
@_spi(OpenUIKitHost)
@MainActor
public enum ContactsUIHostControl {
    /// Delivers `contactPickerDidCancel` through the existential delegate.
    /// Never fabricates a selected `CNContact`.
    public static func reportPickerCancel(_ picker: CNContactPickerViewController) {
        picker.delegate?.contactPickerDidCancel(picker)
    }

    /// Records a fail-closed editor completion. When Contacts is absent the
    /// Darwin `didCompleteWith` callback is not invoked (it needs `CNContact?`).
    /// When Contacts is present, the callback runs with `nil` (no saved contact).
    public static func reportViewControllerCompletion(
        _ viewController: CNContactViewController
    ) {
        viewController.linuxCompletedWithoutSaving = true
        #if canImport(Contacts)
        viewController.delegate?.contactViewController(viewController, didCompleteWith: nil)
        #endif
    }

    /// Invokes the access-button approval callback with an empty identifier
    /// list. Linux has no limited-access authorization, matching the public
    /// overlay note that the handler receives an empty result without it.
    @discardableResult
    public static func invokeAccessApproval(_ button: ContactAccessButton) -> [String] {
        button.invokeFailClosedApproval()
    }

    public static func highlightedPropertyKey(
        _ viewController: CNContactViewController
    ) -> String? {
        viewController.linuxHighlightedPropertyKey
    }

    public static func highlightedPropertyIdentifier(
        _ viewController: CNContactViewController
    ) -> String? {
        viewController.linuxHighlightedPropertyIdentifier
    }

    public static func linuxModifierTags(_ button: ContactAccessButton) -> [String] {
        button.linuxModifiers
    }
}
