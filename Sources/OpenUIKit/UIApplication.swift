// UIApplication + UIApplicationDelegate + a minimal scene layer.
// Owner: lifecycle module (M12, docs/APP_COMPAT.md "App lifecycle /
// environment", the #2 item on the punch list at 543 uses).
//
// WHAT IS DIFFERENT FROM UIKIT, AND WHY
//
// UIKit's `UIApplicationMain` never returns: it creates the application
// object, installs the delegate, and spins a run loop that owns the process
// forever. OpenUIKit has NO RUN LOOP and reads NO WALL CLOCK — that is the
// portability rule the whole library is built on (docs/ARCHITECTURE.md
// "Hard rules"), and it is why events, animations and scroll physics are
// all driven by host-supplied timestamps.
//
// So the entry point here does the LAUNCH SEQUENCE and returns, leaving the
// host to own the loop:
//
//     let app = UIApplicationMain(delegate: MyAppDelegate())
//     ...                       // -> application(_:didFinishLaunching…)
//     app._hostDidBecomeActive() // after the first frame is on screen
//     while running { ... }      // the host's loop drives window.tick(…)
//     app._hostWillTerminate()   // on quit
//
// The five underscore-prefixed `_host…` methods are the whole lifecycle
// driver. They are NOT UIKit API (hence the underscore); UIKit fires the
// same callbacks from its run loop's response to system events, and a
// portable core has no system to hear from. Everything an app sees —
// `applicationState`, the delegate callbacks, their ORDER — is UIKit's.
//
// Each transition also POSTS the UIKit notification for it
// (`UIApplication.didBecomeActiveNotification` and friends) on
// `NotificationCenter.default` with `UIApplication.shared` as the object, so
// an app that observes instead of implementing the delegate is heard. The
// center is OpenUIKit's own portable one and SHADOWS Foundation's — see
// Sources/OpenUIKit/NotificationCenter.swift for the full tradeoff. The
// delegate method runs first, then the observers.

// MARK: - Application state

extension UIApplication {
    /// UIKit's `UIApplication.State`.
    public enum State: Int, Sendable {
        case active = 0
        case inactive = 1
        case background = 2
    }

    /// Keys in the launch-options dictionary. OpenUIKit never populates it
    /// (nothing launches an app here but the host); the type exists so app
    /// delegates written against UIKit compile unchanged.
    public struct LaunchOptionsKey: Hashable, RawRepresentable, Sendable {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public static let url = LaunchOptionsKey(rawValue: "UIApplicationLaunchOptionsURLKey")
        public static let sourceApplication =
            LaunchOptionsKey(rawValue: "UIApplicationLaunchOptionsSourceApplicationKey")
        public static let remoteNotification =
            LaunchOptionsKey(rawValue: "UIApplicationLaunchOptionsRemoteNotificationKey")
        public static let localNotification =
            LaunchOptionsKey(rawValue: "UIApplicationLaunchOptionsLocalNotificationKey")
    }

    /// Options for `open(_:options:completionHandler:)`.
    public struct OpenExternalURLOptionsKey: Hashable, RawRepresentable, Sendable {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public static let universalLinksOnly =
            OpenExternalURLOptionsKey(rawValue: "universalLinksOnly")
    }
}

// MARK: - UIApplicationDelegate

/// UIKit's app delegate protocol. Every method has a default no-op
/// implementation (UIKit gets that from ObjC `@optional`), so an app
/// delegate implements only what it cares about. Delegate construction is an
/// entry-point/runtime responsibility, not a protocol requirement: UIKit's
/// public protocol does not require `init()`.
@preconcurrency @MainActor
public protocol UIApplicationDelegate: AnyObject {
    func application(_ application: UIApplication,
                     willFinishLaunchingWithOptions
                     launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions
                     launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
    func applicationDidBecomeActive(_ application: UIApplication)
    func applicationWillResignActive(_ application: UIApplication)
    func applicationDidEnterBackground(_ application: UIApplication)
    func applicationWillEnterForeground(_ application: UIApplication)
    func applicationWillTerminate(_ application: UIApplication)
}

extension UIApplicationDelegate {
    public func application(_ application: UIApplication,
                            willFinishLaunchingWithOptions
                            launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool { true }
    public func application(_ application: UIApplication,
                            didFinishLaunchingWithOptions
                            launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool { true }
    public func applicationDidBecomeActive(_ application: UIApplication) {}
    public func applicationWillResignActive(_ application: UIApplication) {}
    public func applicationDidEnterBackground(_ application: UIApplication) {}
    public func applicationWillEnterForeground(_ application: UIApplication) {}
    public func applicationWillTerminate(_ application: UIApplication) {}
}

// MARK: - UIApplication

@preconcurrency @MainActor
open class UIApplication: UIResponder {
    /// The application object. Apps use this; constructing another
    /// UIApplication is meaningless (UIKit traps on it — we merely ignore
    /// the extra instance, since it is never wired to anything).
    public static let shared = UIApplication()

    /// The app delegate. Weak, like UIKit's: `UIApplicationMain` retains the
    /// delegate it was given (`_retainedDelegate`), and an app that assigns
    /// `delegate` by hand owns the object's lifetime.
    public weak var delegate: UIApplicationDelegate?
    private var _retainedDelegate: UIApplicationDelegate?

    /// UIKit starts an app in `.inactive` and moves it to `.active` once it
    /// is on screen and taking input.
    public private(set) var applicationState: State = .inactive

    /// True between `_hostWillTerminate()` and process exit.
    public private(set) var isTerminating = false

    // MARK: Windows

    @MainActor
    private final class WeakWindow {
        weak var window: UIWindow?
        init(_ w: UIWindow) { window = w }
    }
    private var _windows: [WeakWindow] = []
    private weak var _keyWindow: UIWindow?

    /// Every live window, in creation order. (UIKit lists only VISIBLE
    /// windows; OpenUIKit has no window-server visibility, so a window
    /// counts from the moment it exists.) Deprecated in UIKit, still used
    /// pervasively by real apps — hence present.
    public var windows: [UIWindow] {
        _windows.compactMap { $0.window }
    }

    /// The key window — the one the app routes keyboard/first-responder work
    /// to. Set by `UIWindow.makeKey()` / `makeKeyAndVisible()`; defaults to
    /// the first window created.
    public var keyWindow: UIWindow? {
        _keyWindow ?? windows.first
    }

    func _register(window: UIWindow) {
        _windows.removeAll { $0.window == nil }
        guard !_windows.contains(where: { $0.window === window }) else { return }
        _windows.append(WeakWindow(window))
    }

    func _makeKey(window: UIWindow) {
        _register(window: window)
        _keyWindow = window
    }

    // MARK: Scenes

    private var _connectedScenes: Set<UIScene> = []

    /// The scenes currently connected. OpenUIKit never creates one for you:
    /// the host boots a plain UIWindow (the pre-scene shape), so this is
    /// empty unless an app opts in with `_connect(scene:)`. Keeping it empty
    /// by default is what makes a window's next responder the application
    /// itself, exactly as in a pre-scene app.
    public var connectedScenes: Set<UIScene> { _connectedScenes }

    /// Attach a scene (host/app hook — UIKit does this from its scene
    /// session machinery, which OpenUIKit does not have).
    public func _connect(scene: UIScene) {
        _connectedScenes.insert(scene)
        scene.activationState = applicationState == .active
            ? .foregroundActive : .foregroundInactive
    }

    public func _disconnect(scene: UIScene) {
        _connectedScenes.remove(scene)
        scene.activationState = .unattached
    }

    // MARK: Responder chain

    /// The application is the end of the chain unless its delegate is
    /// itself a responder — the usual `class AppDelegate: UIResponder,
    /// UIApplicationDelegate` shape, where UIKit forwards to it.
    open override var next: UIResponder? { delegate as? UIResponder }

    override var _firstResponderWindow: UIWindow? { keyWindow }

    // MARK: Event dispatch

    /// Route an event to the key window. UIKit's `sendEvent` is the funnel
    /// every touch passes through; OpenUIKit's hosts call
    /// `UIWindow.sendTouch` directly (it is the one that owns hit-testing
    /// and the touch lifetime), so this is the compatibility spelling for
    /// app code that synthesizes events.
    open func sendEvent(_ event: UIEvent) {
        keyWindow?.sendEvent(event)
    }

    /// Selector-free analog of UIKit's
    /// `sendAction(_:to:from:for:)`. UIKit identifies the action with a
    /// `Selector` and looks for the first responder that implements it;
    /// portable Swift has no selectors, so the action is a CLOSURE that
    /// returns whether it handled the responder it was given.
    ///
    /// With a `target`, the action is sent straight to it. With `target`
    /// nil, the action walks the responder chain starting at the key
    /// window's first responder (falling back to `sender`, then the key
    /// window) and stops at the first responder that returns true — the
    /// same "nil-targeted action" semantics UIKit gives you.
    @discardableResult
    open func sendAction(_ action: (UIResponder) -> Bool,
                         to target: UIResponder?,
                         from sender: Any?,
                         for event: UIEvent?) -> Bool {
        if let target { return action(target) }
        let start = keyWindow?.firstResponder ?? (sender as? UIResponder) ?? keyWindow
        guard let start else { return false }
        for responder in start._responderChain {
            if action(responder) { return true }
        }
        return false
    }

    // MARK: Opening URLs

    /// HOST HOOK: OpenUIKit cannot open a URL — there is no OS to hand it
    /// to, and the library may be running on Linux with no browser. A host
    /// that can (openhost could shell out; a wasm host could call
    /// `window.open`) installs a handler here; without one, `open` reports
    /// failure and `canOpenURL` returns false, which is exactly what UIKit
    /// does for a scheme nothing claims.
    public static var urlOpenHandler: ((String) -> Bool)?

    /// URLs are plain strings: `URL` is a Foundation type and the library
    /// may not import Foundation. A host or app on Foundation passes
    /// `url.absoluteString`.
    open func canOpenURL(_ url: String) -> Bool {
        UIApplication.urlOpenHandler != nil
    }

    open func open(_ url: String,
                   options: [OpenExternalURLOptionsKey: Any] = [:],
                   completionHandler: ((Bool) -> Void)? = nil) {
        let ok = UIApplication.urlOpenHandler?(url) ?? false
        completionHandler?(ok)
    }

    // MARK: Launch + lifecycle (host-driven)

    /// Run the launch sequence: install the delegate, then
    /// `willFinishLaunching` -> `didFinishLaunching`. Leaves the app in
    /// `.inactive`; the host calls `_hostDidBecomeActive()` once the first
    /// frame is up. Returns the delegate's `didFinishLaunching` verdict.
    @discardableResult
    public func _hostLaunch(delegate: UIApplicationDelegate,
                            launchOptions: [LaunchOptionsKey: Any]? = nil) -> Bool {
        _retainedDelegate = delegate
        self.delegate = delegate
        isTerminating = false
        applicationState = .inactive
        _ = delegate.application(self, willFinishLaunchingWithOptions: launchOptions)
        let ok = delegate.application(self, didFinishLaunchingWithOptions: launchOptions)
        _post(UIApplication.didFinishLaunchingNotification)
        return ok
    }

    /// Posts a lifecycle notification with `self` as the object. UIKit posts
    /// each of these alongside the delegate callback; the delegate runs
    /// first here (its hook is a direct call, not an observer registration —
    /// see Sources/OpenUIKit/NotificationCenter.swift).
    private func _post(_ name: Notification.Name) {
        NotificationCenter.default.post(name: name, object: self)
    }

    /// The app is on screen and taking input. No-op if already active, like
    /// UIKit (which never sends a redundant transition).
    public func _hostDidBecomeActive() {
        guard applicationState != .active else { return }
        applicationState = .active
        for s in _connectedScenes { s.activationState = .foregroundActive }
        delegate?.applicationDidBecomeActive(self)
        for s in _connectedScenes { s.delegate?.sceneDidBecomeActive(s) }
        _post(UIApplication.didBecomeActiveNotification)
    }

    /// The app is losing input focus but is still on screen.
    public func _hostWillResignActive() {
        guard applicationState == .active else { return }
        for s in _connectedScenes { s.delegate?.sceneWillResignActive(s) }
        delegate?.applicationWillResignActive(self)
        applicationState = .inactive
        for s in _connectedScenes { s.activationState = .foregroundInactive }
        _post(UIApplication.willResignActiveNotification)
    }

    /// The app left the screen. UIKit always resigns active first; so do we,
    /// so a host that calls only this still produces the documented order.
    public func _hostDidEnterBackground() {
        if applicationState == .active { _hostWillResignActive() }
        guard applicationState != .background else { return }
        applicationState = .background
        for s in _connectedScenes { s.activationState = .background }
        delegate?.applicationDidEnterBackground(self)
        for s in _connectedScenes { s.delegate?.sceneDidEnterBackground(s) }
        _post(UIApplication.didEnterBackgroundNotification)
    }

    /// The app is coming back to the screen (still inactive afterwards —
    /// UIKit follows this with a `didBecomeActive`).
    public func _hostWillEnterForeground() {
        guard applicationState == .background else { return }
        applicationState = .inactive
        for s in _connectedScenes { s.activationState = .foregroundInactive }
        delegate?.applicationWillEnterForeground(self)
        for s in _connectedScenes { s.delegate?.sceneWillEnterForeground(s) }
        _post(UIApplication.willEnterForegroundNotification)
    }

    /// The process is about to exit. Fires exactly once.
    public func _hostWillTerminate() {
        guard !isTerminating else { return }
        isTerminating = true
        delegate?.applicationWillTerminate(self)
        _post(UIApplication.willTerminateNotification)
    }
}

/// UIKit's `UIApplicationMain`, adapted to a library with no run loop: it
/// performs the launch sequence and RETURNS the application object (see the
/// file header). The host then runs its own loop and drives the remaining
/// lifecycle with `app._hostDidBecomeActive()` / `_hostWillTerminate()`.
@discardableResult
@preconcurrency @MainActor
public func UIApplicationMain(delegate: UIApplicationDelegate,
                              launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil)
    -> UIApplication {
    let app = UIApplication.shared
    app._hostLaunch(delegate: delegate, launchOptions: launchOptions)
    return app
}

// MARK: - Scenes (minimal)

public enum UISceneActivationState: Int, Sendable {
    case unattached = -1
    case foregroundActive = 0
    case foregroundInactive = 1
    case background = 2
}

/// A scene session. OpenUIKit has no state restoration and no session
/// persistence: the identifier is whatever the creator supplies and the
/// role is carried for app code that switches on it.
@preconcurrency @MainActor
public final class UISceneSession {
    public struct Role: Hashable, RawRepresentable, Sendable {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public static let windowApplication = Role(rawValue: "UIWindowSceneSessionRoleApplication")
        public static let windowExternalDisplay =
            Role(rawValue: "UIWindowSceneSessionRoleExternalDisplayNonInteractive")
    }
    public let persistentIdentifier: String
    public let role: Role
    public var userInfo: [String: Any]?

    public init(persistentIdentifier: String = "default",
                role: Role = .windowApplication) {
        self.persistentIdentifier = persistentIdentifier
        self.role = role
    }
}

/// Options passed to `scene(_:willConnectTo:options:)`. Empty here — there
/// is no launch surface to describe.
@preconcurrency @MainActor
public final class UISceneConnectionOptions {
    public init() {}
}

@preconcurrency @MainActor
public protocol UISceneDelegate: AnyObject {
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UISceneConnectionOptions)
    func sceneDidDisconnect(_ scene: UIScene)
    func sceneDidBecomeActive(_ scene: UIScene)
    func sceneWillResignActive(_ scene: UIScene)
    func sceneWillEnterForeground(_ scene: UIScene)
    func sceneDidEnterBackground(_ scene: UIScene)
}

extension UISceneDelegate {
    public func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
                      options connectionOptions: UISceneConnectionOptions) {}
    public func sceneDidDisconnect(_ scene: UIScene) {}
    public func sceneDidBecomeActive(_ scene: UIScene) {}
    public func sceneWillResignActive(_ scene: UIScene) {}
    public func sceneWillEnterForeground(_ scene: UIScene) {}
    public func sceneDidEnterBackground(_ scene: UIScene) {}
}

@preconcurrency @MainActor
public protocol UIWindowSceneDelegate: UISceneDelegate {
    var window: UIWindow? { get set }
}

/// A scene. Minimal by design: OpenUIKit's hosts boot a plain UIWindow, and
/// scenes exist so scene-shaped app code (`class SceneDelegate: UIResponder,
/// UIWindowSceneDelegate`) compiles and receives its callbacks.
@preconcurrency @MainActor
open class UIScene: UIResponder {
    public let session: UISceneSession
    public weak var delegate: UISceneDelegate?
    public internal(set) var activationState: UISceneActivationState = .unattached
    public var title: String?

    public init(session: UISceneSession) {
        self.session = session
        super.init()
    }

    /// Spelled as a second initializer rather than a defaulted parameter:
    /// default argument expressions are evaluated in the CALLER's isolation,
    /// so `= UISceneSession()` would be a call to a main-actor initializer
    /// from wherever the caller happens to be. This overload keeps the
    /// convenience without the isolation hole.
    public convenience override init() {
        self.init(session: UISceneSession())
    }

    /// A scene's next responder is the application (UIKit).
    open override var next: UIResponder? { UIApplication.shared }
}

// `nonisolated`: identity only, and Hashable is a nonisolated protocol
// (see the note in UIViewCompat.swift).
extension UIScene: Hashable {
    nonisolated public static func == (a: UIScene, b: UIScene) -> Bool { a === b }
    nonisolated public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

@preconcurrency @MainActor
open class UIWindowScene: UIScene {
    /// Single-display: always `UIScreen.main`.
    public var screen: UIScreen { .main }

    /// Windows attached to this scene (set through `UIWindow.windowScene`).
    public var windows: [UIWindow] {
        UIApplication.shared.windows.filter { $0.windowScene === self }
    }

    public var keyWindow: UIWindow? {
        let k = UIApplication.shared.keyWindow
        return k?.windowScene === self ? k : windows.first
    }
}
