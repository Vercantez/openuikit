// A portable NotificationCenter with Foundation-compatible notification
// identity. Owner: app-compat cluster (controls2 + Reminder bridge slice).
//
// TYPE IDENTITY
// -------------
// On a normal package build, Foundation's `Notification` and `OperationQueue`
// are the canonical values and OpenUIKit aliases them. An extension declared
// in a Foundation-only model file is therefore visible to a UIKit-only view
// controller, and there is no second `Notification` for name lookup to find.
//
// A Foundation-hidden Apple guest still needs the same source/API surface.
// That branch retains the small value below and gives it a real
// `_ObjectiveCBridgeable` conformance backed by an NSObject box, so an
// unchanged `@objc func receive(_ note: Notification)` crosses
// `NSObject.perform` with its name, object identity and userInfo intact.
// Native ELF never enables Objective-C interop and uses the value directly.
//
// When Foundation and Objective-C are both visible, `NotificationCenter` is
// Foundation's canonical center too: that is UIKit's native implementation,
// removes the last direct Foundation/UIKit name collision, and gives Apple
// builds the authoritative threading/queue behavior. Native ELF retains the
// strict custom center below because corelibs Foundation has no selector
// registration API and its non-NSObject object filtering differs from UIKit.
// A Foundation-hidden Objective-C guest also uses the custom center, whose
// selector delivery reaches the real runtime through `SelectorDispatch`.
//
// DELIVERY MODEL
// --------------
// The custom portable center posts SYNCHRONOUSLY and is re-entrant-safe:
// `post` snapshots the observer list first, so an observer that adds or
// removes observers does not perturb the notification in flight. Its
// observers are invoked in registration order. Foundation+Objective-C builds
// use Foundation's center and therefore inherit Foundation's delivery model.
//
// There is no run loop and there are no threads in the portable core, so the
// custom center ACCEPTS AND IGNORES the `queue:` argument of
// `addObserver(forName:object:queue:using:)`; its block runs inline on the
// poster's stack. Foundation's native center honors its queue argument. The
// custom behavior is the same "no run loop" limitation that makes the app
// lifecycle host-driven (docs/KNOWN_GAPS.md).
//
// The custom center holds observers WEAKLY for the selector form (UIKit's
// `addObserver(_:selector:name:object:)` holds an unsafe-unretained
// reference; a weak one is strictly safer and never resurrects a dead
// object) and STRONGLY for the block form, whose block Foundation also
// retains until the returned token is removed. Foundation+Objective-C builds
// use Foundation's ownership behavior directly.

#if canImport(Foundation)
import Foundation
#endif
#if canImport(ObjectiveC)
import ObjectiveC
#endif

// MARK: - Notification

#if canImport(Foundation)

/// Foundation's canonical posted-notification value. Keeping the alias in
/// OpenUIKit's namespace makes Foundation-only extensions and UIKit-facing
/// APIs share one declaration rather than two lookalikes.
public typealias Notification = Foundation.Notification

/// Foundation's canonical Objective-C notification carrier.
public typealias NSNotification = Foundation.NSNotification

#else

/// Foundation-hidden posted-notification value.
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

#if canImport(ObjectiveC)

/// Objective-C carrier for the Foundation-hidden notification value.
///
/// The whole Swift value is retained by the box, so nested strings, the
/// sender reference and userInfo values keep their Swift semantics while the
/// outer value crosses an Objective-C method boundary.
public final class _OpenUIKitNotificationBox: NSObject {
    public typealias Name = Notification.Name

    fileprivate let value: Notification

    public var name: Notification.Name { value.name }
    public var object: Any? { value.object }
    public var userInfo: [AnyHashable: Any]? { value.userInfo }

    fileprivate init(_ value: Notification) {
        self.value = value
        super.init()
    }

    public convenience init(name: Notification.Name, object: Any?,
                            userInfo: [AnyHashable: Any]? = nil) {
        self.init(Notification(name: name, object: object, userInfo: userInfo))
    }
}

/// Foundation-hidden counterpart of Foundation.NSNotification. It is the
/// same NSObject box used by Notification's Objective-C bridge:
/// NSNotification handlers share one box, while Notification-typed thunks
/// unbridge that same box to a value.
public typealias NSNotification = _OpenUIKitNotificationBox

extension Notification: _ObjectiveCBridgeable {
    public typealias _ObjectiveCType = NSNotification

    public func _bridgeToObjectiveC() -> _OpenUIKitNotificationBox {
        _OpenUIKitNotificationBox(self)
    }

    public static func _forceBridgeFromObjectiveC(
        _ source: _OpenUIKitNotificationBox,
        result: inout Notification?
    ) {
        result = source.value
    }

    public static func _conditionallyBridgeFromObjectiveC(
        _ source: _OpenUIKitNotificationBox,
        result: inout Notification?
    ) -> Bool {
        result = source.value
        return true
    }

    public static func _unconditionallyBridgeFromObjectiveC(
        _ source: _OpenUIKitNotificationBox?
    ) -> Notification {
        source?.value ?? Notification(name: .init(""))
    }
}

#endif
#endif

// MARK: - OperationQueue (argument-compatibility shim)

#if canImport(Foundation)

/// Foundation's canonical queue identity. The native Foundation center honors
/// it; OpenUIKit's native-ELF center accepts it but deliberately delivers
/// inline.
public typealias OperationQueue = Foundation.OperationQueue

#else

/// Foundation-hidden argument-compatibility shim. It schedules nothing: the
/// portable core has no run loop and every notification is delivered inline.
public final class OperationQueue {
    public static let main = OperationQueue(name: "main")
    public static var current: OperationQueue? { main }
    public var name: String?
    public init(name: String? = nil) { self.name = name }
}

#endif

#if canImport(Foundation) && canImport(ObjectiveC)

/// Native Foundation's block-observer token identity.
public typealias NotificationToken = any ObjectiveC.NSObjectProtocol

#elseif canImport(Foundation)

/// Native-ELF block-observer token. Corelibs Foundation has no selector-form
/// center API, so OpenUIKit retains its custom token identity; NSObject
/// inheritance still lets unchanged storage spell `any NSObjectProtocol`.
public final class NotificationToken: Foundation.NSObject {
    fileprivate override init() { super.init() }
}

#elseif canImport(ObjectiveC)

/// Foundation-hidden block-observer token. NSObject inheritance preserves
/// Foundation's source shape: the returned value assigns to
/// `any NSObjectProtocol` even though the custom center owns its identity.
public final class NotificationToken: NSObject {
    fileprivate override init() { super.init() }
}

#else

/// Opaque token for the rare build with neither an NSObject provider nor
/// Objective-C. Keep it: dropping the value does not unregister the block.
public final class NotificationToken {
    fileprivate init() {}
}

#endif

// MARK: - NotificationCenter

#if canImport(Foundation) && canImport(ObjectiveC)

/// Foundation's canonical notification center on native Apple builds.
public typealias NotificationCenter = Foundation.NotificationCenter

#else

/// Strict portable center for native ELF and Foundation-hidden guests.
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

    /// Foundation's selector form, dispatched through OpenUIKit's central
    /// selector mechanism (docs/OBJC_RUNTIME.md). On Objective-C-capable
    /// targets a matching NSObject method is invoked from runtime metadata;
    /// native ELF and non-NSObject targets use the same portable registry
    /// fallback as `UIControl.addTarget(_:action:for:)`. The conventional
    /// selector takes one ``Notification`` argument and ends in a colon.
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
#if !canImport(Foundation) && canImport(ObjectiveC)
        // Bridge once per post. Native Foundation gives every selector
        // observer the same NSNotification carrier; one shared box preserves
        // that identity for both Notification- and NSNotification-typed
        // Objective-C thunks. Block observers still receive the Swift value.
        let selectorSender: Any = notification._bridgeToObjectiveC()
#else
        let selectorSender: Any = notification
#endif
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
                    _ = SelectorDispatch.send(
                        Selector.named(selectorName),
                        to: observer,
                        sender: selectorSender
                    )
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

#endif

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
