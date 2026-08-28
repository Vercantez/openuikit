// Selector target-action without an Objective-C runtime. Owner: controls/event
// module (M12 app-compat).
//
// UIKit dispatches target-action through `objc_msgSend`: `#selector(foo)`
// produces a `SEL`, and the runtime looks the method up by name at call time.
// OpenUIKit has no ObjC runtime, and its classes are not NSObject subclasses,
// so name -> method has to come from somewhere else. It comes from a registry
// the target itself supplies: `SelectorDispatching`.
//
// The *type* of a selector is the one thing that differs per platform, and it
// is the only conditional compilation in this library:
//
//   Darwin   `Selector` IS the platform's real ObjC selector. `#selector(...)`
//            compiles, produces one, and `sel_getName` recovers the name. App
//            source is verbatim UIKit.
//   elsewhere `Selector` is a name-carrying struct of our own. `#selector` and
//            `@objc` do not compile off Darwin at all (see docs/OBJC_RUNTIME.md
//            -- enabling ObjC interop there emits class metadata the shipped
//            libswiftCore cannot read), so the portable spelling of the same
//            thing is `Selector("buttonTapped")`, which also compiles on
//            Darwin. One source, both platforms.
//
// Either way `action.actionName` is the ObjC selector name -- "buttonTapped",
// "valueChanged:", "handlePan:event:" -- and the trailing-colon count is the
// argument count, exactly as in ObjC. Actions accept 0, 1 (sender) or 2
// (sender, event) parameters, UIKit's convention.

#if canImport(ObjectiveC)
import ObjectiveC

/// The platform's real Objective-C selector. `#selector(...)` produces one.
public typealias Selector = ObjectiveC.Selector

extension Selector {
    /// The Objective-C selector name ("buttonTapped", "valueChanged:").
    public var actionName: String { String(cString: sel_getName(self)) }
}
#else

/// Stand-in for Objective-C's `SEL` on platforms with no ObjC runtime: it
/// carries the selector *name*, which is all a source-level dispatch scheme
/// needs. `Selector("buttonTapped")` is the portable spelling of
/// `#selector(buttonTapped)` and compiles on Darwin too.
public struct Selector: Hashable, ExpressibleByStringLiteral,
                        CustomStringConvertible, Sendable {
    /// The Objective-C selector name ("buttonTapped", "valueChanged:").
    public let actionName: String
    public init(_ name: String) { actionName = name }
    public init(stringLiteral value: String) { actionName = value }
    public var description: String { actionName }
}
#endif

extension Selector {
    /// Number of arguments the selector takes, from its trailing colons --
    /// "tapped" = 0, "tapped:" = 1, "tapped:event:" = 2 (ObjC's rule).
    public var actionArity: Int {
        actionName.reduce(0) { $1 == ":" ? $0 + 1 : $0 }
    }

    /// The portable spelling of `#selector(...)`: `Selector.named("tapped")`.
    ///
    /// `Selector("tapped")` means the same thing, but on Darwin the compiler
    /// warns "no method declared with Objective-C selector" for a string
    /// literal, since it cannot see a table it does not own. This spelling
    /// says the same thing without the warning, and compiles everywhere.
    public static func named(_ name: String) -> Selector {
        let indirect = name          // not a literal: no Darwin literal check
        return Selector(indirect)
    }
}

// MARK: - The registry

/// A target that can be reached by selector name.
///
/// UIKit gets this from `objc_msgSend`; we get it from the target. Implement
/// `perform(_:with:)` -- usually by forwarding to an ``ActionTable`` -- and
/// `addTarget(self, action:for:)` works exactly as it does in UIKit.
///
///     final class MyViewController: UIViewController, SelectorDispatching {
///         static let actions: ActionTable<MyViewController> = [
///             .action("buttonTapped", MyViewController.buttonTapped),
///             .action("switchChanged:", MyViewController.switchChanged),
///         ]
///         func perform(_ name: String, with sender: Any?) -> Bool {
///             Self.actions.perform(name, on: self, with: sender)
///         }
///     }
@preconcurrency @MainActor
public protocol SelectorDispatching: AnyObject {
    /// Invoke the method the selector names. Return `false` if unknown --
    /// the caller reports it through ``SelectorDispatch/onUnresolved``.
    func perform(_ selectorName: String, with sender: Any?) -> Bool

    /// Two-argument form (`action:forEvent:`). Defaults to dropping the event.
    func perform(_ selectorName: String, with sender: Any?, event: UIEvent?) -> Bool
}

extension SelectorDispatching {
    public func perform(_ selectorName: String, with sender: Any?,
                        event: UIEvent?) -> Bool {
        perform(selectorName, with: sender)
    }
}

/// One name -> method binding. Built with ``action(_:_:)``, whose overloads
/// accept unapplied method references of UIKit's three action shapes.
public struct ActionEntry<Owner: AnyObject> {
    let name: String
    let body: (Owner, Any?, UIEvent?) -> Void

    /// `func buttonTapped()` -- selector "buttonTapped".
    public static func action(_ name: String,
                              _ method: @escaping (Owner) -> () -> Void) -> ActionEntry {
        ActionEntry(name: name) { owner, _, _ in method(owner)() }
    }

    /// `func switchChanged(_ sender: UISwitch)` -- selector "switchChanged:".
    /// The sender is cast to `Sender`; a mismatch is a no-op, as in UIKit.
    public static func action<Sender>(
        _ name: String,
        _ method: @escaping (Owner) -> (Sender) -> Void
    ) -> ActionEntry {
        ActionEntry(name: name) { owner, sender, _ in
            guard let s = sender as? Sender else { return }
            method(owner)(s)
        }
    }

    /// `func tapped(_ sender: UIControl, _ event: UIEvent?)` -- "tapped:event:".
    public static func action<Sender>(
        _ name: String,
        _ method: @escaping (Owner) -> (Sender, UIEvent?) -> Void
    ) -> ActionEntry {
        ActionEntry(name: name) { owner, sender, event in
            guard let s = sender as? Sender else { return }
            method(owner)(s, event)
        }
    }
}

/// The name -> method table a ``SelectorDispatching`` target dispatches
/// through. Written as an array literal of ``ActionEntry``.
public struct ActionTable<Owner: AnyObject>: ExpressibleByArrayLiteral {
    private let entries: [String: (Owner, Any?, UIEvent?) -> Void]

    public init(_ entries: [ActionEntry<Owner>]) {
        var map: [String: (Owner, Any?, UIEvent?) -> Void] = [:]
        for e in entries { map[e.name] = e.body }
        self.entries = map
    }

    public init(arrayLiteral elements: ActionEntry<Owner>...) {
        self.init(elements)
    }

    /// Every selector name this table answers to.
    public var selectorNames: [String] { entries.keys.sorted() }

    @discardableResult
    public func perform(_ name: String, on owner: Owner, with sender: Any?,
                        event: UIEvent? = nil) -> Bool {
        guard let body = entries[name] else { return false }
        body(owner, sender, event)
        return true
    }
}

// MARK: - Delivery

/// Sends a selector to a target, and reports the ones that go nowhere.
///
/// UIKit throws `unrecognized selector sent to instance` at runtime; we have
/// no runtime to throw it from, so a miss is silent by default (matching
/// UIKit's behaviour for a nil target) and observable through
/// ``onUnresolved`` -- which the test suite and `openhost` install.
@preconcurrency @MainActor
public enum SelectorDispatch {
    /// Called with (target, selector name) whenever a send finds no method.
    /// `nil` target means the weak target had already deallocated.
    public static var onUnresolved: ((AnyObject?, String) -> Void)?

    @discardableResult
    public static func send(_ action: Selector, to target: AnyObject?,
                            sender: Any?, event: UIEvent? = nil) -> Bool {
        guard let target else { return false }
        if trySend(action, to: target, sender: sender, event: event) { return true }
        onUnresolved?(target, action.actionName)
        return false
    }

    /// Like ``send(_:to:sender:event:)`` but SILENT on a miss. Used where a
    /// miss is expected and meaningful rather than a bug — walking the
    /// responder chain for a nil-targeted action (UIMenu.swift), where every
    /// responder but one is supposed to say no.
    @discardableResult
    public static func trySend(_ action: Selector, to target: AnyObject?,
                               sender: Any?, event: UIEvent? = nil) -> Bool {
        guard let dispatcher = target as? SelectorDispatching else { return false }
        return dispatcher.perform(action.actionName, with: sender, event: event)
    }
}
