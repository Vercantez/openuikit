// UIResponder — the real base class of the UIKit object graph.
// Owner: lifecycle module (M12, docs/APP_COMPAT.md "App lifecycle /
// environment").
//
// Before M12 the touch entry points and the first-responder bits lived
// ad hoc on UIView. They now live here, and the hierarchy is UIKit's:
//
//   UIResponder
//     ├── UIView ──── UILabel, UIControl (UIButton/UISwitch/UITextField…),
//     │               UIScrollView, UIWindow, …
//     ├── UIViewController ──── UINavigationController, UITabBarController…
//     ├── UIApplication
//     └── UIScene ──── UIWindowScene
//
// THE CHAIN (`next`), exactly as UIKit documents it:
//
//   a view          -> the view controller whose ROOT view it is, if any,
//                      otherwise its superview
//   a view controller -> the controller that PRESENTED it, if it is
//                      presented; otherwise its view's superview (which is
//                      the window when it is a window's root controller)
//   a window        -> its UIWindowScene if it has one, else UIApplication
//   UIApplication   -> its delegate, when the delegate is itself a
//                      UIResponder (the usual `class AppDelegate:
//                      UIResponder, UIApplicationDelegate` shape)
//
// so a button deep inside a pushed screen walks
//   button -> stack -> content -> vc.view -> vc -> nav container -> nav
//   -> window -> application -> app delegate -> nil.
//
// FIRST RESPONDER is stored per UIWindow (`UIWindow.firstResponder`), which
// is where UIKit keeps it too. A responder can only take focus while it has
// a window: for a view that is `view.window`, for a view controller
// `view.window`, for the application its key window. That is what makes
// `becomeFirstResponder()` fail on a detached view, matching UIKit.
//
// TOUCH DELIVERY is unchanged: UIWindow still hit-tests and calls
// touchesBegan/… on the hit view (UIEvent.swift). What changed is the
// DEFAULT implementation — a responder that does not handle a touch now
// forwards it to `next`, like UIKit, instead of swallowing it. Controls,
// table cells and the scroll pipeline all override without calling super,
// so their behavior is untouched.

// UIKit's responder graph is an Objective-C object graph.  Use Foundation's
// NSObject on ordinary native builds (including native ELF Linux, where
// corelibs Foundation supplies its Swift implementation), and the ObjectiveC
// module's root class on the FoundationEssentials-only Mach-O guest path.
// Every supported production build has one of these two providers; failing
// closed keeps a new substrate from silently reverting responders to plain
// Swift classes and breaking `@objc` parameter representability.
#if canImport(Foundation)
import class Foundation.NSObject
#elseif canImport(ObjectiveC)
import class ObjectiveC.NSObject
#else
#error("OpenUIKit requires Foundation.NSObject or ObjectiveC.NSObject")
#endif

// MARK: - Presses (hardware keys / remote)

/// A single hardware-key press. Minimal shape: OpenUIKit has no keyboard
/// HID stack — the host synthesizes presses from its own key events, the
/// same way it synthesizes touches (see `UIWindow.sendKey`, which stays the
/// text-input path and is deliberately NOT routed through presses).
@preconcurrency @MainActor
public final class UIPress {
    public enum Phase: Sendable { case began, changed, ended, cancelled }
    public let phase: Phase
    /// The editing key this press carries, when it maps to one.
    public let key: UIKeyEventKey?
    /// Responder the press was delivered to (UIKit's `responder`).
    public internal(set) weak var responder: UIResponder?
    public let timestamp: TimeInterval

    public init(phase: Phase, key: UIKeyEventKey? = nil,
                responder: UIResponder? = nil, timestamp: TimeInterval = 0) {
        self.phase = phase
        self.key = key
        self.responder = responder
        self.timestamp = timestamp
    }
}

// `nonisolated` for the same reason as UIView's below: identity only, and
// Hashable is a nonisolated protocol (see UIViewCompat.swift).
extension UIPress: Hashable {
    nonisolated public static func == (a: UIPress, b: UIPress) -> Bool { a === b }
    nonisolated public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

/// Event carrying a set of `UIPress`es (UIKit's UIPressesEvent).
@preconcurrency @MainActor
public final class UIPressesEvent {
    public let timestamp: TimeInterval
    public let allPresses: Set<UIPress>
    public init(presses: Set<UIPress>, timestamp: TimeInterval = 0) {
        self.allPresses = presses
        self.timestamp = timestamp
    }
    public func presses(for responder: UIResponder) -> Set<UIPress> {
        allPresses.filter { $0.responder === responder }
    }
}

// MARK: - UIResponder

@preconcurrency @MainActor
open class UIResponder: NSObject {
    public override init() { super.init() }

    /// Called once a nib-loaded object's outlets are all connected.
    ///
    /// UIKit declares this on NSObject (NSNibAwaking) and calls it on every
    /// object an archive produced; a real app's `UITableViewCell` subclass
    /// does most of its setup there (pocket-casts' `SwitchCell.awakeFromNib`
    /// installs the switch as the accessory view). Declared on UIResponder
    /// because that is the widest OpenUIKit base a nib can instantiate — see
    /// UINib.swift for the loader that calls it.
    ///
    /// On an Objective-C platform the method already exists on NSObject (the
    /// `NSNibAwaking` category), so this is an override there and a fresh
    /// declaration everywhere else — either way app source spells it
    /// `override func awakeFromNib()`.
#if canImport(ObjectiveC)
    open override func awakeFromNib() {}
#else
    open func awakeFromNib() {}
#endif

    /// UIKit's `UIAccessibilityAction` hook (declared on NSObject there).
    /// Storage-only accessibility means nothing calls it — see
    /// docs/REAL_APP_TEST.md blocker 10 — but a real cell overrides it
    /// (pocket-casts' `SwitchCell` returns its locked state), so the
    /// declaration has to exist for that source to compile.
    open func accessibilityActivate() -> Bool { false }

    /// Accessibility attributes (storage only — see UIViewCompat.swift for
    /// the accessors and for why nothing consults them).
    var _accessibility = AccessibilityState()
    private var _inputAssistantItemStorage: UITextInputAssistantItem?

    /// Stable keyboard-shortcut-bar configuration for this responder.
    /// OpenUIKit hosts do not draw that bar; the object and its mutations are
    /// nevertheless observable with UIKit's lifetime semantics.
    open var inputAssistantItem: UITextInputAssistantItem {
        if let item = _inputAssistantItemStorage { return item }
        let item = UITextInputAssistantItem()
        _inputAssistantItemStorage = item
        return item
    }

    // MARK: The chain

    /// The next responder, or nil at the end of the chain. Overridden by
    /// UIView / UIViewController / UIWindow / UIApplication (see the file
    /// header for the exact rules).
    open var next: UIResponder? { nil }

    /// This responder followed by every responder after it, in chain order.
    /// Not UIKit API (UIKit makes you walk `next`); provided because the
    /// walk is needed by `sendAction` and is the natural thing to assert in
    /// a test. Cycle-guarded, so a malformed hierarchy cannot hang a host.
    public var _responderChain: [UIResponder] {
        var chain: [UIResponder] = []
        var r: UIResponder? = self
        while let cur = r {
            if chain.contains(where: { $0 === cur }) { break }
            chain.append(cur)
            r = cur.next
        }
        return chain
    }

    // MARK: First responder

    /// The window this responder takes first-responder status in, or nil if
    /// it is not currently attached to one. UIView returns its `window`,
    /// UIViewController its view's window, UIApplication its key window.
    var _firstResponderWindow: UIWindow? { nil }

    /// Whether this responder can take focus. Default false, like UIKit;
    /// UITextField/UITextView override.
    open var canBecomeFirstResponder: Bool { false }

    /// Whether this responder will give focus up. Default true, like UIKit.
    open var canResignFirstResponder: Bool { true }

    public var isFirstResponder: Bool {
        _firstResponderWindow?.firstResponder === self
    }

    /// Take first-responder status. UIKit semantics: fails when
    /// `canBecomeFirstResponder` is false, when the responder is not in a
    /// window, or when the current first responder refuses to resign. The
    /// previous first responder resigns first.
    @discardableResult
    open func becomeFirstResponder() -> Bool {
        guard canBecomeFirstResponder, let w = _firstResponderWindow else {
            return false
        }
        if w.firstResponder === self { return true }
        if let cur = w.firstResponder {
            guard cur.canResignFirstResponder else { return false }
            _ = cur.resignFirstResponder()
        }
        w.firstResponder = self
        return true
    }

    /// Give up first-responder status. Returns true (UIKit's default).
    @discardableResult
    open func resignFirstResponder() -> Bool {
        if let w = _firstResponderWindow, w.firstResponder === self {
            w.firstResponder = nil
        }
        return true
    }

    // MARK: Standard editing actions

    /// Default standard-edit action. Text editors override this; ordinary
    /// responders ignore it, matching UIKit's responder-chain surface.
    open func selectAll(_ sender: Any?) {}

    // MARK: Touch entry points

    /// UIKit's default: forward the touches to the next responder. A
    /// responder that handles a phase overrides WITHOUT calling super
    /// (UIControl, UITableViewCell, …) so the touch stops there.
    open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        next?.touchesBegan(touches, with: event)
    }
    open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        next?.touchesMoved(touches, with: event)
    }
    open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        next?.touchesEnded(touches, with: event)
    }
    open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        next?.touchesCancelled(touches, with: event)
    }

    // MARK: Key commands (M13 — see UIMenu.swift for the routing)

    /// UIKit's `keyCommands`: the key commands this responder contributes
    /// while it is in the responder chain. Default nil, like UIKit. The
    /// window walks the chain collecting these in
    /// `UIWindow.performKeyCommand(input:modifierFlags:)`.
    open var keyCommands: [UIKeyCommand]? { nil }

    // MARK: Press entry points

    open func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        next?.pressesBegan(presses, with: event)
    }
    open func pressesChanged(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        next?.pressesChanged(presses, with: event)
    }
    open func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        next?.pressesEnded(presses, with: event)
    }
    open func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        next?.pressesCancelled(presses, with: event)
    }
}
