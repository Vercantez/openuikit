// ADAPTED(foundation-collision): `import Foundation` dropped. Nothing in this
// file needs it, and Foundation's CGRect/CGSize/CGPoint collide with
// OpenUIKit's own (docs/OBJC_RUNTIME.md measures the same collision).

class OptionAction {
    let label: String
    let secondaryLabel: String?
    let icon: String?
    let action: @MainActor () -> Void
    let selected: Bool
    var destructive = false
    var outline = false
    var onOffAction = false
    var tintIcon: Bool = true
    /// When set, tapping the action presents the returned picker as a submenu
    /// on top of the current one. Choosing an option in the submenu dismisses
    /// both. The closure is evaluated lazily, only when the action is tapped.
    var submenu: (@MainActor () -> OptionsPicker?)?

    @MainActor init(label: String, secondaryLabel: String? = nil, icon: String? = nil, tintIcon: Bool = true, selected: Bool = false, action: @escaping @MainActor () -> Void) {
        self.label = label
        self.secondaryLabel = secondaryLabel
        self.icon = icon
        self.tintIcon = tintIcon
        self.action = action
        self.selected = selected
    }

    @MainActor init(label: String, icon: String, tintIcon: Bool = true, selected: Bool, onOffAction: Bool, action: @escaping @MainActor () -> Void) {
        self.label = label
        self.icon = icon
        self.tintIcon = tintIcon
        self.action = action
        self.onOffAction = onOffAction
        self.selected = selected
        secondaryLabel = nil
    }
}
