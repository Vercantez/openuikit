// A portable NotificationCenter. Owner: app-compat cluster (controls2).
//
// WHY THIS TYPE IS HERE AND NOT IMPORTED
// --------------------------------------
// `NotificationCenter`, `Notification` and `Notification.Name` are Foundation
// types. `Sources/OpenUIKit` imports no Foundation at all — that is the
// property that makes the library build and behave identically on Linux
// (docs/PORTABILITY.md) — so a UIKit reimplementation that wants to post
// `UIApplication.didBecomeActiveNotification` has to declare the whole family
// itself. It does, and it SHADOWS Foundation's types EXACTLY the way
// `NSAttributedString` already does (docs/KNOWN_GAPS.md, "Attributed text"):
//
//   * An app or test that imports BOTH OpenUIKit and Foundation sees two
//     types named `NotificationCenter` / `Notification` and the compiler
//     reports `'Notification' is ambiguous for type lookup in this context`.
//     The fix is a file-scope disambiguation,
//     `private typealias Notification = OpenUIKit.Notification`, the same
//     pattern the repo uses for `CGRect` and `NSAttributedString`.
//   * There is NO bridging. A Foundation `Notification` cannot be posted to
//     this center and an observer registered here never hears Foundation's
//     `NotificationCenter.default`. Adding a bridge would require the library
//     to import Foundation.
//   * `object` and `userInfo` values are `Any`, like Foundation's.
//
// DELIVERY MODEL
// --------------
// Posting is SYNCHRONOUS and re-entrant-safe: `post` snapshots the observer
// list first, so an observer that adds or removes observers does not perturb
// the notification in flight (Foundation guarantees the same). Observers are
// invoked in registration order.
//
// There is no run loop and there are no threads in the portable core, so the
// `queue:` argument of `addObserver(forName:object:queue:using:)` is ACCEPTED
// AND IGNORED — the block runs inline on the poster's stack. `OperationQueue`
// below exists only so that argument compiles; it is not an execution
// context. This is the same "no run loop" limitation that makes the app
// lifecycle host-driven (docs/KNOWN_GAPS.md).
//
// Observers are held WEAKLY for the selector form (UIKit's
// `addObserver(_:selector:name:object:)` holds an unsafe-unretained
// reference; a weak one is strictly safer and never resurrects a dead
// object) and STRONGLY for the block form, whose block Foundation also
// retains until the returned token is removed.

// MARK: - Notification

/// A posted notification. Foundation's `Notification` is a struct with the
/// same three members and the same semantics.
public struct Notification {
    /// A notification's identity. Two names are equal iff their raw strings
    /// are.
    public struct Name: Hashable, RawRepresentable, ExpressibleByStringLiteral,
                        CustomStringConvertible, Sendable {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public init(_ rawValue: String) { self.rawValue = rawValue }
        public init(stringLiteral value: String) { self.rawValue = value }
        public var description: String { rawValue }
    }

    public var name: Name
    /// The poster. Observers registered with a non-nil `object` hear only
    /// notifications whose `object` is IDENTICAL (`===`) to it.
    public var object: Any?
    public var userInfo: [AnyHashable: Any]?

    public init(name: Name, object: Any? = nil,
                userInfo: [AnyHashable: Any]? = nil) {
        self.name = name
        self.object = object
        self.userInfo = userInfo
    }
}

// MARK: - OperationQueue (argument-compatibility shim)

/// Present ONLY so `addObserver(forName:object:queue:using:)` compiles with
/// app source that passes `.main`. It schedules nothing: the portable core
/// has no run loop and no threads, and every notification is delivered
/// inline. See the file header.
public final class OperationQueue {
    public static let main = OperationQueue(name: "main")
    public static var current: OperationQueue? { main }
    public var name: String?
    public init(name: String? = nil) { self.name = name }
}

/// The opaque token `addObserver(forName:object:queue:using:)` returns.
///
/// Foundation types that return value `any NSObjectProtocol`. Portable Swift
/// has no `NSObject` and no ObjC protocol to conform to, and NAMING a class
/// `NSObjectProtocol` would collide with the real protocol on Darwin (where
/// `import ObjectiveC` already vends it) — so the token is its own type.
/// A caller porting from Foundation changes the declared type of the stored
/// observer from `NSObjectProtocol?` to `NotificationToken?` and nothing
/// else. Keep the token: dropping it does NOT unregister the block.
public final class NotificationToken {
    fileprivate init() {}
}

// MARK: - NotificationCenter

public final class NotificationCenter {
    /// The process-wide center. UIKit posts every notification it owns here.
    public static let `default` = NotificationCenter()

    public init() {}

    private struct Registration {
        let id: Int
        let name: Notification.Name?
        /// nil = "any sender"; otherwise the sender must be identical.
        weak var object: AnyObject?
        let hadObject: Bool
        /// Block form: the block, retained. Selector form: nil.
        let block: ((Notification) -> Void)?
        /// Selector form: the observer (weak) and the selector.
        weak var observer: AnyObject?
        let isWeakObserver: Bool
        let selectorName: String?
        /// Block form only: the token identifying this registration.
        let token: NotificationToken?
    }

    private var registrations: [Registration] = []
    private var nextID = 0

    // MARK: Registering

    /// Foundation's block form. The returned token is the ONLY handle that
    /// removes the observation — the block is retained until then.
    ///
    /// `queue` is accepted and ignored (file header): the block runs inline
    /// on the poster's stack.
    @discardableResult
    public func addObserver(forName name: Notification.Name?,
                            object obj: Any?,
                            queue: OperationQueue?,
                            using block: @escaping (Notification) -> Void) -> NotificationToken {
        _ = queue
        let token = NotificationToken()
        nextID += 1
        registrations.append(Registration(
            id: nextID, name: name, object: obj as AnyObject?,
            hadObject: obj != nil, block: block, observer: nil,
            isWeakObserver: false, selectorName: nil, token: token))
        return token
    }

    /// Foundation's selector form, dispatched through OpenUIKit's portable
    /// selector mechanism (docs/OBJC_RUNTIME.md): `observer` must conform to
    /// ``SelectorDispatching`` and answer to `selector`'s name, exactly as
    /// for `UIControl.addTarget(_:action:for:)`. The selector takes one
    /// argument — the ``Notification`` — so its name ends in a colon
    /// (`Selector.named("keyboardWillShow:")`).
    ///
    /// The observer is held weakly; a deallocated one is skipped and its
    /// registration reaped on the next post.
    public func addObserver(_ observer: AnyObject,
                            selector: Selector,
                            name: Notification.Name?,
                            object obj: Any?) {
        nextID += 1
        registrations.append(Registration(
            id: nextID, name: name, object: obj as AnyObject?,
            hadObject: obj != nil, block: nil, observer: observer,
            isWeakObserver: true, selectorName: selector.actionName, token: nil))
    }

    // MARK: Removing

    /// Removes every registration made by `observer` — both the token
    /// returned by the block form and an object registered by selector.
    public func removeObserver(_ observer: Any) {
        removeObserver(observer, name: nil, object: nil)
    }

    /// Removes the registrations of `observer` that match `name` and
    /// `object`. A nil `name`/`object` means "any", as in Foundation.
    public func removeObserver(_ observer: Any, name: Notification.Name?,
                               object obj: Any?) {
        let target = observer as AnyObject
        let objObject = obj as AnyObject?
        registrations.removeAll { reg in
            let isThisObserver: Bool
            if let token = reg.token { isThisObserver = token === target }
            else { isThisObserver = reg.observer === target }
            guard isThisObserver else { return false }
            if let name, reg.name != name { return false }
            if let objObject, reg.object !== objObject { return false }
            return true
        }
    }

    // MARK: Posting

    public func post(_ notification: Notification) {
        // Snapshot first: an observer may add or remove observers.
        let snapshot = registrations
        var reap = false
        for reg in snapshot {
            if let n = reg.name, n != notification.name { continue }
            if reg.hadObject {
                guard let want = reg.object else { reap = true; continue }
                guard let got = notification.object as AnyObject?,
                      got === want else { continue }
            }
            if let block = reg.block {
                block(notification)
            } else if let selectorName = reg.selectorName {
                guard let observer = reg.observer else { reap = true; continue }
                // `NotificationCenter` stays nonisolated, like Foundation's —
                // posting is not a UI operation. The selector OBSERVER is,
                // though: `SelectorDispatching` is `@MainActor` because every
                // conformer is a view or a view controller. OpenUIKit is
                // single-threaded and every `post` reaches here from the main
                // thread; `assumeIsolated` asserts that (traps off-main)
                // instead of hiding it behind `nonisolated(unsafe)`.
                MainActor.assumeIsolated {
                    guard let dispatcher = observer as? SelectorDispatching else {
                        SelectorDispatch.onUnresolved?(observer, selectorName)
                        return
                    }
                    if !dispatcher.perform(selectorName, with: notification) {
                        SelectorDispatch.onUnresolved?(observer, selectorName)
                    }
                }
            }
        }
        if reap {
            registrations.removeAll { $0.isWeakObserver && $0.observer == nil }
            registrations.removeAll { $0.hadObject && $0.object == nil }
        }
    }

    public func post(name: Notification.Name, object: Any? = nil,
                     userInfo: [AnyHashable: Any]? = nil) {
        post(Notification(name: name, object: object, userInfo: userInfo))
    }

    /// Number of live registrations. Not Foundation API — the test suite and
    /// leak checks use it.
    public var _observerCount: Int { registrations.count }
}

// MARK: - The notification names UIKit declares

extension UIApplication {
    // App lifecycle. Every one of these is POSTED by the corresponding
    // `_host…` transition, with `UIApplication.shared` as the object, right
    // after the matching delegate method returns. (UIKit's own ordering is
    // delegate-then-observers for the same reason: its delegate hook is not
    // an observer registration.)
    public static let didFinishLaunchingNotification =
        Notification.Name("UIApplicationDidFinishLaunchingNotification")
    public static let didBecomeActiveNotification =
        Notification.Name("UIApplicationDidBecomeActiveNotification")
    public static let willResignActiveNotification =
        Notification.Name("UIApplicationWillResignActiveNotification")
    public static let didEnterBackgroundNotification =
        Notification.Name("UIApplicationDidEnterBackgroundNotification")
    public static let willEnterForegroundNotification =
        Notification.Name("UIApplicationWillEnterForegroundNotification")
    public static let willTerminateNotification =
        Notification.Name("UIApplicationWillTerminateNotification")

    /// Declared for source compatibility; NOTHING posts these — the portable
    /// core has no memory-pressure signal, no significant-time-change clock
    /// and no status-bar animation.
    public static let didReceiveMemoryWarningNotification =
        Notification.Name("UIApplicationDidReceiveMemoryWarningNotification")
    public static let significantTimeChangeNotification =
        Notification.Name("UIApplicationSignificantTimeChangeNotification")
}

extension UIDevice {
    /// Declared for source compatibility. There is no device to interrogate
    /// (docs/KNOWN_GAPS.md, "App lifecycle"), so nothing posts it.
    public static let orientationDidChangeNotification =
        Notification.Name("UIDeviceOrientationDidChangeNotification")
    public static let batteryLevelDidChangeNotification =
        Notification.Name("UIDeviceBatteryLevelDidChangeNotification")
}

extension UIResponder {
    // Keyboard notifications. OpenUIKit has no system keyboard (text input is
    // driven by the host's key events, M8), so nothing posts these either —
    // they exist because observing them is how apps avoid the keyboard, and
    // that code must COMPILE even when the keyboard never appears. A host
    // that draws its own keyboard can post them with the userInfo keys below.
    public static let keyboardWillShowNotification =
        Notification.Name("UIKeyboardWillShowNotification")
    public static let keyboardDidShowNotification =
        Notification.Name("UIKeyboardDidShowNotification")
    public static let keyboardWillHideNotification =
        Notification.Name("UIKeyboardWillHideNotification")
    public static let keyboardDidHideNotification =
        Notification.Name("UIKeyboardDidHideNotification")
    public static let keyboardWillChangeFrameNotification =
        Notification.Name("UIKeyboardWillChangeFrameNotification")
    public static let keyboardDidChangeFrameNotification =
        Notification.Name("UIKeyboardDidChangeFrameNotification")

    public static let keyboardFrameBeginUserInfoKey = "UIKeyboardFrameBeginUserInfoKey"
    public static let keyboardFrameEndUserInfoKey = "UIKeyboardFrameEndUserInfoKey"
    public static let keyboardAnimationDurationUserInfoKey =
        "UIKeyboardAnimationDurationUserInfoKey"
    public static let keyboardAnimationCurveUserInfoKey =
        "UIKeyboardAnimationCurveUserInfoKey"
    public static let keyboardIsLocalUserInfoKey = "UIKeyboardIsLocalUserInfoKey"
}
