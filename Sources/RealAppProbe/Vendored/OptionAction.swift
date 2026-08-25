// M15: this file's `import Foundation` is BACK — unmodified app source. It was
// the one adaptation on the "foundation-collision" line of the M14 ledger, and
// OpenUIKit's geometry types are Foundation's own now, so there is nothing to
// collide (docs/APP_COMPAT.md "M15").
import Foundation

class OptionAction {
    let label: String
    let secondaryLabel: String?
    let icon: String?
    // ADAPTED(main-actor) x4 in this file: real UIKit annotates UIView and
    // UIViewController `@MainActor`, so an app's `@MainActor` closures can be
    // called straight from a touch handler. OpenUIKit's classes carry no
    // global-actor isolation, so those calls are a concurrency error. The
    // annotation is dropped; the library is single-threaded either way.
    let action: () -> Void
    let selected: Bool
    var destructive = false
    var outline = false
    var onOffAction = false
    var tintIcon: Bool = true
    /// When set, tapping the action presents the returned picker as a submenu
    /// on top of the current one. Choosing an option in the submenu dismisses
    /// both. The closure is evaluated lazily, only when the action is tapped.
    var submenu: (() -> OptionsPicker?)?

    init(label: String, secondaryLabel: String? = nil, icon: String? = nil, tintIcon: Bool = true, selected: Bool = false, action: @escaping () -> Void) {
        self.label = label
        self.secondaryLabel = secondaryLabel
        self.icon = icon
        self.tintIcon = tintIcon
        self.action = action
        self.selected = selected
    }

    init(label: String, icon: String, tintIcon: Bool = true, selected: Bool, onOffAction: Bool, action: @escaping () -> Void) {
        self.label = label
        self.icon = icon
        self.tintIcon = tintIcon
        self.action = action
        self.onOffAction = onOffAction
        self.selected = selected
        secondaryLabel = nil
    }
}
