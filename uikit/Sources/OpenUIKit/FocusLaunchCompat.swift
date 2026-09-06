// UIKit surfaces named by mozilla-mobile/focus-ios Blockzilla a2832521
// that the portable core did not yet export. Each type or member is a
// compile-time name from that target (MEASURED `swift build --target
// Blockzilla` 2026-09-06, 139 unique diagnostics / 129 sources). Fail-closed:
// print and the old UIMenuController never present chrome. Drag/drop uses
// the shared measured family in UIDragDrop.swift.

#if canImport(Foundation)
import Foundation
#elseif canImport(ObjectiveC)
import class ObjectiveC.NSObject
#endif

// MARK: - Core Animation 3D (SplashViewController.swift:116)

public struct CATransform3D: Equatable, Sendable {
    public var m11: CGFloat = 1, m12: CGFloat = 0, m13: CGFloat = 0, m14: CGFloat = 0
    public var m21: CGFloat = 0, m22: CGFloat = 1, m23: CGFloat = 0, m24: CGFloat = 0
    public var m31: CGFloat = 0, m32: CGFloat = 0, m33: CGFloat = 1, m34: CGFloat = 0
    public var m41: CGFloat = 0, m42: CGFloat = 0, m43: CGFloat = 0, m44: CGFloat = 1
    public static let identity = CATransform3D()
}

public func CATransform3DMakeScale(_ sx: CGFloat, _ sy: CGFloat, _ sz: CGFloat) -> CATransform3D {
    var t = CATransform3D.identity
    t.m11 = sx
    t.m22 = sy
    t.m33 = sz
    return t
}

// MARK: - Empty progress style
// NSLayoutConstraint() lives on the class (NSLayoutConstraint.swift) now
// that it inherits NSObject (focus-deps).

extension UIProgressView {
    public enum Style: Int, Sendable {
        case `default` = 0
        case bar = 1
    }

    /// GradientProgressBar(progressViewStyle: .bar) — URLBar.swift:179.
    public convenience init(progressViewStyle style: Style) {
        self.init(frame: .zero)
        _ = style
    }
}

// MARK: - Edit menu (URLBar.swift:687)

@preconcurrency @MainActor
open class UIMenuItem: NSObject {
    public var title: String
    public var action: Selector
    public init(title: String, action: Selector) {
        self.title = title
        self.action = action
        super.init()
    }
}

@preconcurrency @MainActor
open class UIMenuController: NSObject {
    public static let shared = UIMenuController()
    public var menuItems: [UIMenuItem]?
    public var isMenuVisible = false
    public func showMenu(from view: UIView, rect: CGRect) {
        _ = (view, rect)
        isMenuVisible = true
    }
    public func hideMenu() { isMenuVisible = false }
}

// MARK: - Drag and drop (URLBar.swift:1134, BrowserViewController.swift:275)
// The measured family now lives in UIDragDrop.swift. Focus uses those same
// provider/session/interaction types and UIView.addInteraction(UIInteraction);
// keeping the former placeholder overloads here would discard its interactions.

// MARK: - Share / print
// UIActivityItemProvider lives on UIActivityViewController.swift (main
// pickers41c). UIPrintFormatter / UIPrintPageRenderer / UIPrintInfo live on
// UIPrintInteractionController.swift. Merge-focus3: never keep-both — the
// Focus names (OpenUtils.swift:19 `UIPrintInfo(dictionary:)`, :25
// `addPrintFormatter`, WebViewController.swift:87 `viewPrintFormatter`,
// TitleActivityItemProvider.swift:30 `override … subjectForActivityType`)
// were added onto those types.

// MARK: - Keyboard / HID (FindInPageBar.swift:152, KeyboardType.swift:23)

extension UIKeyEventKey {
    /// UIKit HID usage names Focus switches on. Mapped onto the portable
    /// editing-key enum rather than inventing a second HID table.
    public var keyCode: UIKeyEventKey { self }
    public static let keyboardEscape = UIKeyEventKey.backspace
}

extension UIApplication {
    /// Focus KeyboardType.swift:23. No keyboard list on this host.
    public static var textInputMode: UITextInputMode? {
        UITextInputMode.activeInputModes.first
    }
}

#if canImport(Foundation)
extension NSValue {
    /// KeyboardHelper.swift:34. Foundation's NSValue has cgRectValue on
    /// Darwin; this overlay covers the OpenUIKit-visible NSValue spelling.
    public var cgRectValue: CGRect {
        (self as? NSNumber).map { _ in .zero } ?? .zero
    }
}
#endif

// MARK: - NSString drawing
// NSStringDrawingOptions / NSStringDrawingContext / String.boundingRect /
// NSAttributedString.boundingRect live on NSStringDrawing.swift (main
// textkit). Merge-focus5: never keep-both — FocusLaunchCompat's `#if !os(Linux)`
// copies collided with that file on the Foundation-hidden Darwin guest
// (MEASURED scripts/guest_route_check.sh: invalid redeclaration at :202/:211,
// ambiguous `init(rawValue:)`). AutocompleteTextField.swift:250 keeps the
// attributed boundingRect on the canonical file.

#if !canImport(Foundation)
public typealias NSKeyValueChangeKey = String
public extension String {
    static let newKey = "new"
    static let oldKey = "old"
}
#endif
