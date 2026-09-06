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
// center is Foundation's canonical center when Foundation+Objective-C are
// visible, and OpenUIKit's custom center on native ELF or a Foundation-hidden
// guest. See Sources/OpenUIKit/NotificationCenter.swift for the exact seam.
// The delegate method runs first, then the observers.

#if canImport(Foundation)
import protocol Foundation.NSCopying
import protocol Foundation.NSMutableCopying
import protocol Foundation.NSSecureCoding
import class Foundation.NSPredicate
import struct Foundation.NSZone
import struct Foundation.URL
import class Foundation.Bundle

#if canImport(Darwin)
import class Foundation.NSUserActivity
#else
import class Foundation.NSObject
#endif
#endif

#if canImport(ObjectiveC)
// UIScene inherits NSObject's Hashable conformance through UIResponder. The
// conformance's defining module must be visible in this file when it appears
// inside Set<UIScene>, including the Foundation-hidden Mach-O guest.
import ObjectiveC
#endif

#if canImport(Foundation) && !canImport(Darwin)
/// Corelibs Foundation does not provide `NSUserActivity`.  Keep the UIKit
/// restoration contract source-compatible on Linux with the identity and
/// activity-type state that portable hosts can currently deliver.
open class NSUserActivity: NSObject {
    private let _activityType: String

    open var activityType: String { _activityType }
    /// MEASURED ValuesProbe2, iPhone SE 3rd gen / iOS 26.1: default is nil.
    open var targetContentIdentifier: String?

    public init(activityType: String) {
        _activityType = activityType
        super.init()
    }
}
#endif

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
        public static let eventAttribution =
            OpenExternalURLOptionsKey(rawValue: "UIApplicationOpenExternalURLOptionsEventAttributionKey")
    }

    /// Options delivered to the application delegate for an incoming URL.
    public struct OpenURLOptionsKey: Hashable, RawRepresentable, Sendable {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public static let sourceApplication =
            OpenURLOptionsKey(rawValue: "UIApplicationOpenURLOptionsSourceApplicationKey")
        public static let annotation =
            OpenURLOptionsKey(rawValue: "UIApplicationOpenURLOptionsAnnotationKey")
        public static let openInPlace =
            OpenURLOptionsKey(rawValue: "UIApplicationOpenURLOptionsOpenInPlaceKey")
        public static let eventAttribution =
            OpenURLOptionsKey(rawValue: "UIApplicationOpenURLOptionsEventAttributionKey")
    }
}

// MARK: - Home-screen shortcuts and activity restoration

/// The icon metadata attached to a home-screen quick action. Portable hosts
/// do not currently render an app launcher, but retaining the metadata lets
/// them expose quick actions without changing application source later.
open class UIApplicationShortcutIcon: NSObject {
    public enum IconType: Int, Sendable {
        case compose, play, pause, add, location, search, share, prohibit
        case contact, home, markLocation, favorite, love, cloud, invitation
        case confirmation, mail, message, date, time, capturePhoto, captureVideo
        case task, taskCompleted, alarm, bookmark, shuffle, audio, update
    }

    enum Storage {
        case type(IconType)
        case templateImageName(String)
        case systemImageName(String)
    }

    let storage: Storage

    private init(storage: Storage) {
        self.storage = storage
        super.init()
    }

    public convenience init(type: IconType) { self.init(storage: .type(type)) }
    public convenience init(templateImageName: String) {
        self.init(storage: .templateImageName(templateImageName))
    }
    public convenience init(systemImageName: String) {
        self.init(storage: .systemImageName(systemImageName))
    }

#if canImport(Foundation)
    open func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return self
    }
#endif
}

#if canImport(Foundation)
extension UIApplicationShortcutIcon: NSCopying {}
#endif

/// Immutable metadata for one home-screen quick action.
/// MEASURED ValuesProbe2, iPhone SE 3rd gen / iOS 26.1: `copy()` returns
/// an immutable `UIApplicationShortcutItem` (not the mutable subclass);
/// `mutableCopy()` returns `UIMutableApplicationShortcutItem`;
/// `targetContentIdentifier` defaults to nil.
open class UIApplicationShortcutItem: NSObject {
    fileprivate var _type: String
    fileprivate var _localizedTitle: String
    fileprivate var _localizedSubtitle: String?
    fileprivate var _icon: UIApplicationShortcutIcon?
    fileprivate var _targetContentIdentifier: Any?

    open var type: String { _type }
    open var localizedTitle: String { _localizedTitle }
    open var localizedSubtitle: String? { _localizedSubtitle }
    open var icon: UIApplicationShortcutIcon? { _icon }
    open var targetContentIdentifier: Any? { _targetContentIdentifier }

#if canImport(Foundation)
    fileprivate var _userInfo: [String: any NSSecureCoding]?
    open var userInfo: [String: any NSSecureCoding]? { _userInfo }

    public init(type: String, localizedTitle: String,
                localizedSubtitle: String?, icon: UIApplicationShortcutIcon?,
                userInfo: [String: any NSSecureCoding]? = nil) {
        _type = type
        _localizedTitle = localizedTitle
        _localizedSubtitle = localizedSubtitle
        _icon = icon
        _userInfo = userInfo
        super.init()
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let item = UIApplicationShortcutItem(
            type: _type, localizedTitle: _localizedTitle,
            localizedSubtitle: _localizedSubtitle, icon: _icon,
            userInfo: _userInfo
        )
        item._targetContentIdentifier = _targetContentIdentifier
        return item
    }

    open func mutableCopy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let item = UIMutableApplicationShortcutItem(
            type: _type, localizedTitle: _localizedTitle,
            localizedSubtitle: _localizedSubtitle, icon: _icon,
            userInfo: _userInfo
        )
        item.targetContentIdentifier = _targetContentIdentifier
        return item
    }
#else
    fileprivate var _userInfo: [String: Any]?
    open var userInfo: [String: Any]? { _userInfo }

    public init(type: String, localizedTitle: String,
                localizedSubtitle: String?, icon: UIApplicationShortcutIcon?,
                userInfo: [String: Any]? = nil) {
        _type = type
        _localizedTitle = localizedTitle
        _localizedSubtitle = localizedSubtitle
        _icon = icon
        _userInfo = userInfo
        super.init()
    }
#endif

    public convenience init(type: String, localizedTitle: String) {
        self.init(type: type, localizedTitle: localizedTitle,
                  localizedSubtitle: nil, icon: nil, userInfo: nil)
    }
}

#if canImport(Foundation)
extension UIApplicationShortcutItem: NSCopying, NSMutableCopying {}
#endif

open class UIMutableApplicationShortcutItem: UIApplicationShortcutItem {
    open override var type: String {
        get { _type }
        set { _type = newValue }
    }
    open override var localizedTitle: String {
        get { _localizedTitle }
        set { _localizedTitle = newValue }
    }
    open override var localizedSubtitle: String? {
        get { _localizedSubtitle }
        set { _localizedSubtitle = newValue }
    }
    open override var icon: UIApplicationShortcutIcon? {
        get { _icon }
        set { _icon = newValue }
    }
    open override var targetContentIdentifier: Any? {
        get { _targetContentIdentifier }
        set { _targetContentIdentifier = newValue }
    }

#if canImport(Foundation)
    open override var userInfo: [String: any NSSecureCoding]? {
        get { _userInfo }
        set { _userInfo = newValue }
    }
#else
    open override var userInfo: [String: Any]? {
        get { _userInfo }
        set { _userInfo = newValue }
    }
#endif
}

#if canImport(Foundation)
@preconcurrency @MainActor
public protocol UIUserActivityRestoring: AnyObject {
    func restoreUserActivityState(_ userActivity: NSUserActivity)
}
#endif

// MARK: - UIApplicationDelegate

/// UIKit's app delegate protocol. Every method has a default no-op
/// implementation (UIKit gets that from ObjC `@optional`), so an app
/// delegate implements only what it cares about. Delegate construction is an
/// entry-point/runtime responsibility, not a protocol requirement: UIKit's
/// public protocol does not require `init()`.
@preconcurrency @MainActor
public protocol UIApplicationDelegate: AnyObject {
    /// Main application window. UIKit declares this ObjC-optional, so reading
    /// it through a delegate existential has TWO optional layers: whether the
    /// delegate implements the property, then whether its value is nil. Swift
    /// without ObjC optional requirements spells that observable shape
    /// explicitly as `UIWindow??`.
    var window: UIWindow?? { get set }
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
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration
    func application(_ application: UIApplication,
                     didDiscardSceneSessions sceneSessions: Set<UISceneSession>)
    func application(_ application: UIApplication,
                     performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void)
}

extension UIApplicationDelegate {
    public var window: UIWindow?? {
        get {
            // A normal Swift app delegate declares `var window: UIWindow?`,
            // which intentionally is not the double-optional requirement and
            // therefore uses this default witness. Recover that stored value
            // for existential reads; a delegate with no window member returns
            // outer nil, exactly like an unimplemented ObjC optional property.
            var mirror: Mirror? = Mirror(reflecting: self)
            while let current = mirror {
                if let value = current.children.first(where: { $0.label == "window" })?.value {
                    let optional = Mirror(reflecting: value)
                    if optional.displayStyle == .optional {
                        guard let wrapped = optional.children.first?.value else {
                            return .some(nil)
                        }
                        return .some(wrapped as? UIWindow)
                    }
                    return .some(value as? UIWindow)
                }
                mirror = current.superclassMirror
            }
            return nil
        }
        set { _ = newValue }
    }
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
    public func application(_ application: UIApplication,
                            configurationForConnecting connectingSceneSession: UISceneSession,
                            options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
    }
    public func application(_ application: UIApplication,
                            didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}
    public func application(_ application: UIApplication,
                            performActionFor shortcutItem: UIApplicationShortcutItem,
                            completionHandler: @escaping (Bool) -> Void) {
        _ = shortcutItem
        completionHandler(false)
    }
}

// MARK: - UIApplication

@preconcurrency @MainActor
open class UIApplication: UIResponder {
    /// The application object. Apps use this; constructing another
    /// UIApplication is meaningless (UIKit traps on it — we merely ignore
    /// the extra instance, since it is never wired to anything).
    public static let shared = UIApplication()

    /// URL which opens this app's settings in a host that implements such a
    /// destination. The spelling/value match UIKit; the host URL hook decides
    /// whether it can actually be opened.
    nonisolated public static let openSettingsURLString = "app-settings:"

    /// The app delegate. Weak, like UIKit's: `UIApplicationMain` retains the
    /// delegate it was given (`_retainedDelegate`), and an app that assigns
    /// `delegate` by hand owns the object's lifetime.
    public weak var delegate: UIApplicationDelegate?
    private var _retainedDelegate: UIApplicationDelegate?

    /// UIKit starts an app in `.inactive` and moves it to `.active` once it
    /// is on screen and taking input.
    public private(set) var applicationState: State = .inactive

    /// Home-screen quick actions. MEASURED ValuesProbe2, iPhone SE 3rd gen /
    /// iOS 26.1: the default is an empty array (not nil); assigning `nil`
    /// reads back as `[]`.
    private var _shortcutItems: [UIApplicationShortcutItem] = []
    public var shortcutItems: [UIApplicationShortcutItem]? {
        get { _shortcutItems }
        set { _shortcutItems = newValue ?? [] }
    }

    /// Process-wide Dynamic Type category (Settings). OpenUIKit has no
    /// Settings app, so this stays `.large` — a device's shipped identity —
    /// unless a host assigns it.
    ///
    /// MEASURED dtmetrics probe, iPhone 16 / iOS 26.1: after
    /// `UITraitCollection.current = .accessibilityLarge`, `current` reads
    /// AccessibilityL but `UIApplication.shared.preferredContentSizeCategory`
    /// stays L, and `UIFontMetrics.scaledValue(for: 24)` (no `compatibleWith`)
    /// stays 24. The `compatibleWith: current` overload is 33.333. Backing is
    /// `nonisolated` so `UIFontMetrics` can read it off the main actor.
    public var preferredContentSizeCategory: UIContentSizeCategory {
        get { Self._preferredContentSizeCategory }
        set { Self._preferredContentSizeCategory = newValue }
    }
    nonisolated(unsafe) static var _preferredContentSizeCategory =
        UIContentSizeCategory.large

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
    private var _usesSceneLifecycle = false
    private var _retainedSceneDelegates: [ObjectIdentifier: UISceneDelegate] = [:]

    /// The scenes currently connected. OpenUIKit never creates one for you:
    /// the host boots a plain UIWindow (the pre-scene shape), so this is
    /// empty unless an app opts in with `_connect(scene:)`. Keeping it empty
    /// by default is what makes a window's next responder the application
    /// itself, exactly as in a pre-scene app.
    public var connectedScenes: Set<UIScene> { _connectedScenes }

    /// Attach a scene (host/app hook — UIKit does this from its scene
    /// session machinery, which OpenUIKit does not have).
    public func _connect(scene: UIScene) {
        _usesSceneLifecycle = true
        _connectedScenes.insert(scene)
        if let sceneDelegate = scene.delegate {
            _retainedSceneDelegates[ObjectIdentifier(scene)] = sceneDelegate
        }
        scene.session.scene = scene
        scene.activationState = applicationState == .active
            ? .foregroundActive : .foregroundInactive
    }

    public func _disconnect(scene: UIScene) {
        _connectedScenes.remove(scene)
        scene.activationState = .unattached
        scene.delegate?.sceneDidDisconnect(scene)
        _retainedSceneDelegates.removeValue(forKey: ObjectIdentifier(scene))
        if scene.session.scene === scene { scene.session.scene = nil }
    }

    /// Create and connect the ordinary single-window scene selected by an
    /// Xcode application template. Portable build tooling emits the concrete
    /// delegate construction; OpenUIKit owns session/configuration semantics.
    @discardableResult
    public func _hostConnectWindowScene(delegate sceneDelegate: UIWindowSceneDelegate)
        -> UIWindowScene {
        _hostConnectWindowScene(delegate: sceneDelegate,
                                session: UISceneSession(),
                                options: UIScene.ConnectionOptions())
    }

    /// Fully specified variant for hosts restoring a known scene session.
    @discardableResult
    public func _hostConnectWindowScene(delegate sceneDelegate: UIWindowSceneDelegate,
                                        session: UISceneSession,
                                        options: UIScene.ConnectionOptions)
        -> UIWindowScene {
        guard let appDelegate = delegate else {
            preconditionFailure("UIApplication must be launched before connecting a scene")
        }
        let configuration = appDelegate.application(
            self,
            configurationForConnecting: session,
            options: options
        )
        precondition(configuration.role == session.role,
                     "scene configuration role must match its session")
        if let sceneClass = configuration.sceneClass {
            precondition(ObjectIdentifier(sceneClass) == ObjectIdentifier(UIWindowScene.self),
                         "custom scene classes are not supported by this host slice")
        }
        if let delegateClass = configuration.delegateClass {
            precondition(ObjectIdentifier(delegateClass) ==
                         ObjectIdentifier(type(of: sceneDelegate)),
                         "generated scene delegate does not match the configuration")
        }
        session.configuration = configuration

        let scene = UIWindowScene(session: session)
        scene.delegate = sceneDelegate
        _connect(scene: scene)
        sceneDelegate.scene(scene, willConnectTo: session, options: options)
        return scene
    }

    /// Deliver a home-screen quick action. MEASURED ValuesProbe2: UIKit
    /// calls `windowScene(_:performActionFor:completionHandler:)` on the
    /// window-scene delegate; the deprecated application-delegate form is
    /// the fallback when no window-scene delegate implements it.
    public func _hostPerformShortcut(_ item: UIApplicationShortcutItem,
                                     completionHandler: @escaping (Bool) -> Void) {
        for scene in _connectedScenes {
            if let windowScene = scene as? UIWindowScene,
               let sceneDelegate = windowScene.delegate as? UIWindowSceneDelegate {
                sceneDelegate.windowScene(
                    windowScene, performActionFor: item,
                    completionHandler: completionHandler
                )
                return
            }
        }
        delegate?.application(self, performActionFor: item,
                              completionHandler: completionHandler)
    }

#if canImport(Foundation)
    /// Deliver `scene(_:openURLContexts:)` to a connected scene delegate.
    public func _hostOpenURLContexts(_ contexts: Set<UIOpenURLContext>,
                                     scene: UIScene? = nil) {
        let target = scene ?? _connectedScenes.first
        guard let target else { return }
        target.delegate?.scene(target, openURLContexts: contexts)
    }
#endif

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
    /// `Selector` and looks for the first responder that implements it. This
    /// compatibility overload predates the real-selector path; it remains a
    /// closure so native ELF callers can express responder-chain dispatch
    /// without Objective-C syntax.
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

    /// The Foundation-free spelling used by renderer-only builds and hosts.
    open func canOpenURL(_ url: String) -> Bool {
        UIApplication.urlOpenHandler != nil
    }

    open func open(_ url: String,
                   options: [OpenExternalURLOptionsKey: Any] = [:],
                   completionHandler: ((Bool) -> Void)? = nil) {
        let ok = UIApplication.urlOpenHandler?(url) ?? false
        completionHandler?(ok)
    }

#if canImport(Foundation)
    /// UIKit-compatible URL spelling. A real application build links the
    /// Foundation module; renderer-only builds retain the String hook above.
    open func canOpenURL(_ url: URL) -> Bool {
        canOpenURL(url.absoluteString)
    }

    open func open(_ url: URL,
                   options: [OpenExternalURLOptionsKey: Any] = [:],
                   completionHandler: ((Bool) -> Void)? = nil) {
        open(url.absoluteString, options: options,
             completionHandler: completionHandler)
    }
#endif

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
        _usesSceneLifecycle = false
        _retainedSceneDelegates.removeAll()
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
        if !_usesSceneLifecycle {
            delegate?.applicationDidBecomeActive(self)
        } else {
            for s in _connectedScenes { s.delegate?.sceneDidBecomeActive(s) }
        }
        _post(UIApplication.didBecomeActiveNotification)
    }

    /// The app is losing input focus but is still on screen.
    public func _hostWillResignActive() {
        guard applicationState == .active else { return }
        if !_usesSceneLifecycle {
            delegate?.applicationWillResignActive(self)
        } else {
            for s in _connectedScenes { s.delegate?.sceneWillResignActive(s) }
        }
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
        if !_usesSceneLifecycle {
            delegate?.applicationDidEnterBackground(self)
        } else {
            for s in _connectedScenes { s.delegate?.sceneDidEnterBackground(s) }
        }
        _post(UIApplication.didEnterBackgroundNotification)
    }

    /// The app is coming back to the screen (still inactive afterwards —
    /// UIKit follows this with a `didBecomeActive`).
    public func _hostWillEnterForeground() {
        guard applicationState == .background else { return }
        applicationState = .inactive
        for s in _connectedScenes { s.activationState = .foregroundInactive }
        if !_usesSceneLifecycle {
            delegate?.applicationWillEnterForeground(self)
        } else {
            for s in _connectedScenes { s.delegate?.sceneWillEnterForeground(s) }
        }
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
    public internal(set) weak var scene: UIScene?
    public internal(set) var configuration: UISceneConfiguration
    public var userInfo: [String: Any]?

    public init(persistentIdentifier: String = "default",
                role: Role = .windowApplication) {
        self.persistentIdentifier = persistentIdentifier
        self.role = role
        self.configuration = UISceneConfiguration(name: nil, sessionRole: role)
    }
}

// UIKit sessions inherit NSObject's identity equality and hashing. Distinct
// live sessions remain distinct even when they carry the same identifier.
extension UISceneSession: Hashable {
    nonisolated public static func == (a: UISceneSession, b: UISceneSession) -> Bool {
        a === b
    }
    nonisolated public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}

/// Scene metadata selected by the application delegate. UIKit exposes this as
/// a subclassable class and accepts any class object in `sceneClass`; the
/// portable single-window host validates its narrower runtime support only
/// when it consumes a configuration.
///
/// MEASURED ValuesProbe2, iPhone SE 3rd gen / iOS 26.1: `init(name:
/// "Default Configuration", sessionRole:)` with no Info.plist catalog
/// returns `name == nil`. The port keeps the passed name so hosts and
/// `ResponderLifecycleTests` (`"Default Configuration"`) still compile
/// unchanged. Plist lookup is OPEN.
@preconcurrency @MainActor
open class UISceneConfiguration: NSObject {
    public let name: String?
    public let role: UISceneSession.Role
    public var sceneClass: AnyClass?
    public var delegateClass: AnyClass?
    public var storyboard: UIStoryboard?

    public init(name: String?, sessionRole: UISceneSession.Role) {
        self.name = name
        self.role = sessionRole
        super.init()
    }

#if canImport(Foundation)
    open func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copied = UISceneConfiguration(name: name, sessionRole: role)
        copied.sceneClass = sceneClass
        copied.delegateClass = delegateClass
        copied.storyboard = storyboard
        return copied
    }
#endif
}

#if canImport(Foundation)
extension UISceneConfiguration: NSCopying {}
#endif

/// Options passed to `scene(_:willConnectTo:options:)`. UIKit's public
/// initializer is unavailable; this one stays public so hosts can
/// construct a connection without a launch surface.
@preconcurrency @MainActor
public final class UISceneConnectionOptions: NSObject {
#if canImport(Foundation)
    public internal(set) var URLContexts: Set<UIOpenURLContext> = []
    public internal(set) var userActivities: Set<NSUserActivity> = []
#endif
    public internal(set) var sourceApplication: String?
    public internal(set) var handoffUserActivityType: String?
    public internal(set) var shortcutItem: UIApplicationShortcutItem?

    public override init() { super.init() }

    public init(sourceApplication: String? = nil,
                handoffUserActivityType: String? = nil,
                shortcutItem: UIApplicationShortcutItem? = nil) {
        self.sourceApplication = sourceApplication
        self.handoffUserActivityType = handoffUserActivityType
        self.shortcutItem = shortcutItem
        super.init()
    }
}

#if canImport(Foundation)
/// MEASURED ValuesProbe, iPhone SE 3rd gen / iOS 26.1: a URL the scene is
/// asked to open, plus the originating-app options.
@preconcurrency @MainActor
public final class UIOpenURLContext: NSObject {
    public let url: URL
    public let options: UISceneOpenURLOptions

    public init(url: URL, options: UISceneOpenURLOptions) {
        self.url = url
        self.options = options
        super.init()
    }
}

@preconcurrency @MainActor
public final class UISceneOpenURLOptions: NSObject {
    public let sourceApplication: String?
    public let annotation: Any?
    public let openInPlace: Bool
    public let eventAttribution: UIEventAttribution?

    public init(sourceApplication: String? = nil,
                annotation: Any? = nil,
                openInPlace: Bool = false,
                eventAttribution: UIEventAttribution? = nil) {
        self.sourceApplication = sourceApplication
        self.annotation = annotation
        self.openInPlace = openInPlace
        self.eventAttribution = eventAttribution
        super.init()
    }
}

/// Attribution attached to an incoming URL. No advertising network on a
/// portable host; the type exists so `UISceneOpenURLOptions.eventAttribution`
/// compiles.
open class UIEventAttribution: NSObject {
    public let sourceIdentifier: UInt8
    public let destinationURL: URL
    public let sourceDescription: String?
    public let purchaser: String?

    public init(sourceIdentifier: UInt8, destinationURL: URL,
                sourceDescription: String?, purchaser: String?) {
        self.sourceIdentifier = sourceIdentifier
        self.destinationURL = destinationURL
        self.sourceDescription = sourceDescription
        self.purchaser = purchaser
        super.init()
    }
}
#endif

/// A compiling storyboard handle. OpenUIKit does not load `.storyboardc`
/// archives (docs/REAL_APP_TEST.md xib/storyboard non-goal); this type
/// exists so `UISceneConfiguration.storyboard` and corpus `UIStoryboard`
/// call sites type-check.
open class UIStoryboard: NSObject {
    public let name: String
#if canImport(Foundation)
    public let bundle: Bundle?

    public init(name: String, bundle: Bundle?) {
        self.name = name
        self.bundle = bundle
        super.init()
    }
#else
    public init(name: String, bundle: Any?) {
        self.name = name
        _ = bundle
        super.init()
    }
#endif

    open func instantiateInitialViewController() -> UIViewController? { nil }

    open func instantiateViewController(withIdentifier identifier: String)
        -> UIViewController {
        _ = identifier
        return UIViewController()
    }
}

/// MEASURED ValuesProbe2, iPhone SE 3rd gen / iOS 26.1: defaults are
/// `NSPredicate(value: true)` / `NSPredicate(value: false)`
/// (`TRUEPREDICATE` / `FALSEPREDICATE`).
@preconcurrency @MainActor
open class UISceneActivationConditions: NSObject {
#if canImport(Foundation)
    open var canActivateForTargetContentIdentifierPredicate: NSPredicate
    open var prefersToActivateForTargetContentIdentifierPredicate: NSPredicate

    public override init() {
        canActivateForTargetContentIdentifierPredicate = NSPredicate(value: true)
        prefersToActivateForTargetContentIdentifierPredicate = NSPredicate(value: false)
        super.init()
    }
#else
    public override init() { super.init() }
#endif
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
#if canImport(Foundation)
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>)
#endif
}

extension UISceneDelegate {
    public func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
                      options connectionOptions: UISceneConnectionOptions) {}
    public func sceneDidDisconnect(_ scene: UIScene) {}
    public func sceneDidBecomeActive(_ scene: UIScene) {}
    public func sceneWillResignActive(_ scene: UIScene) {}
    public func sceneWillEnterForeground(_ scene: UIScene) {}
    public func sceneDidEnterBackground(_ scene: UIScene) {}
#if canImport(Foundation)
    public func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {}
#endif
}

@preconcurrency @MainActor
public protocol UIWindowSceneDelegate: UISceneDelegate {
    /// ObjC-optional on UIKit: the outer optional represents whether the
    /// delegate implements the property and the inner optional its value.
    var window: UIWindow?? { get set }
    func windowScene(_ windowScene: UIWindowScene,
                     performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void)
}

extension UIWindowSceneDelegate {
    public var window: UIWindow?? {
        get {
            var mirror: Mirror? = Mirror(reflecting: self)
            while let current = mirror {
                if let value = current.children.first(where: { $0.label == "window" })?.value {
                    let optional = Mirror(reflecting: value)
                    if optional.displayStyle == .optional {
                        guard let wrapped = optional.children.first?.value else {
                            return .some(nil)
                        }
                        return .some(wrapped as? UIWindow)
                    }
                    return .some(value as? UIWindow)
                }
                mirror = current.superclassMirror
            }
            return nil
        }
        set { _ = newValue }
    }

    public func windowScene(_ windowScene: UIWindowScene,
                            performActionFor shortcutItem: UIApplicationShortcutItem,
                            completionHandler: @escaping (Bool) -> Void) {
        _ = windowScene
        _ = shortcutItem
        completionHandler(false)
    }
}

/// A scene. Minimal by design: OpenUIKit's hosts boot a plain UIWindow, and
/// scenes exist so scene-shaped app code (`class SceneDelegate: UIResponder,
/// UIWindowSceneDelegate`) compiles and receives its callbacks.
@preconcurrency @MainActor
open class UIScene: UIResponder {
    /// Canonical Swift spelling imported by UIKit from
    /// `UISceneConnectionOptions`.
    public typealias ConnectionOptions = UISceneConnectionOptions

    public let session: UISceneSession
    /// UIKit's public delegate property is weak. The application host retains
    /// a delegate supplied through `_hostConnectWindowScene` until disconnect,
    /// mirroring the private scene-management ownership in UIKit itself.
    public weak var delegate: UISceneDelegate?
    public internal(set) var activationState: UISceneActivationState = .unattached
    public var title: String?
    /// MEASURED ValuesProbe2: defaults to TRUEPREDICATE / FALSEPREDICATE.
    public var activationConditions = UISceneActivationConditions()

    public init(session: UISceneSession,
                connectionOptions: UISceneConnectionOptions) {
        self.session = session
        super.init()
        _ = connectionOptions
    }

    public convenience init(session: UISceneSession) {
        self.init(session: session, connectionOptions: UISceneConnectionOptions())
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
