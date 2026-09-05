// SwiftUI application lifecycle backed by OpenUIKit's real application,
// scene, window, view-controller, and responder machinery.

#if canImport(Foundation)
import Foundation
#else
#if canImport(FoundationEssentials)
import struct FoundationEssentials.URL
#endif
#if canImport(ObjectiveC)
import ObjectiveC
#endif
#endif
import OpenUIKit
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

@MainActor
public protocol _OpenScene {
    associatedtype Body: _OpenScene

    @_OpenSceneBuilder var body: Body { get }

    /// Underscored implementation hook used by the application host. App
    /// scenes receive the body-based default and do not implement this method.
    func _makeOpenUIKitSceneNode() -> _OpenSceneNode
}

public extension _OpenScene {
    func _makeOpenUIKitSceneNode() -> _OpenSceneNode {
        body._makeOpenUIKitSceneNode()
    }
}

public extension _OpenScene where Body == Never {
    var body: Never {
        fatalError("primitive SwiftUI scenes do not evaluate Never.body")
    }
}

@MainActor
struct _OpenWindowDescriptor {
    let title: String?
    let makeRootViewController: @MainActor () -> UIViewController
}

/// Opaque public carrier required by Scene's public implementation hook. Its
/// representation remains private to the SwiftUI module.
@MainActor
public final class _OpenSceneNode {
    let windows: [_OpenWindowDescriptor]

    init(windows: [_OpenWindowDescriptor]) {
        self.windows = windows
    }
}

extension Never: _OpenScene {
    public func _makeOpenUIKitSceneNode() -> _OpenSceneNode {
        fatalError("Never has no application scene")
    }
}

@MainActor
@resultBuilder
public enum _OpenSceneBuilder {
    public static func buildExpression<Content: _OpenScene>(_ content: Content) -> Content {
        content
    }

    public static func buildBlock() -> _OpenEmptyScene {
        _OpenEmptyScene()
    }

    public static func buildBlock<Content: _OpenScene>(_ content: Content) -> Content {
        content
    }

    public static func buildPartialBlock<Content: _OpenScene>(first: Content) -> Content {
        first
    }

    public static func buildPartialBlock<Accumulated: _OpenScene, Next: _OpenScene>(
        accumulated: Accumulated,
        next: Next
    ) -> _OpenSceneGroup<Accumulated, Next> {
        _OpenSceneGroup(accumulated, next)
    }

    public static func buildOptional<Content: _OpenScene>(
        _ component: Content?
    ) -> Content? {
        component
    }

    public static func buildEither<TrueContent: _OpenScene, FalseContent: _OpenScene>(
        first component: TrueContent
    ) -> _OpenConditionalScene<TrueContent, FalseContent> {
        _OpenConditionalScene(first: component)
    }

    public static func buildEither<TrueContent: _OpenScene, FalseContent: _OpenScene>(
        second component: FalseContent
    ) -> _OpenConditionalScene<TrueContent, FalseContent> {
        _OpenConditionalScene(second: component)
    }

    public static func buildArray<Content: _OpenScene>(
        _ components: [Content]
    ) -> _OpenSceneArray<Content> {
        _OpenSceneArray(components)
    }

    public static func buildLimitedAvailability<Content: _OpenScene>(
        _ component: Content
    ) -> Content {
        component
    }
}

public struct _OpenEmptyScene: _OpenScene {
    public typealias Body = Never

    public init() {}

    public func _makeOpenUIKitSceneNode() -> _OpenSceneNode {
        _OpenSceneNode(windows: [])
    }
}

public struct _OpenSceneGroup<First: _OpenScene, Second: _OpenScene>: _OpenScene {
    public typealias Body = Never

    private let first: First
    private let second: Second

    init(_ first: First, _ second: Second) {
        self.first = first
        self.second = second
    }

    public func _makeOpenUIKitSceneNode() -> _OpenSceneNode {
        _OpenSceneNode(
            windows: first._makeOpenUIKitSceneNode().windows
                + second._makeOpenUIKitSceneNode().windows
        )
    }
}

public struct _OpenConditionalScene<TrueContent: _OpenScene, FalseContent: _OpenScene>:
    _OpenScene
{
    public typealias Body = Never

    private let makeNode: @MainActor () -> _OpenSceneNode

    init(first content: TrueContent) {
        makeNode = content._makeOpenUIKitSceneNode
    }

    init(second content: FalseContent) {
        makeNode = content._makeOpenUIKitSceneNode
    }

    public func _makeOpenUIKitSceneNode() -> _OpenSceneNode {
        makeNode()
    }
}

public struct _OpenSceneArray<Content: _OpenScene>: _OpenScene {
    public typealias Body = Never

    private let components: [Content]

    init(_ components: [Content]) {
        self.components = components
    }

    public func _makeOpenUIKitSceneNode() -> _OpenSceneNode {
        _OpenSceneNode(
            windows: components.flatMap {
                $0._makeOpenUIKitSceneNode().windows
            }
        )
    }
}

extension Optional: _OpenScene where Wrapped: _OpenScene {
    public func _makeOpenUIKitSceneNode() -> _OpenSceneNode {
        switch self {
        case .some(let scene): return scene._makeOpenUIKitSceneNode()
        case .none: return _OpenSceneNode(windows: [])
        }
    }
}

/// A SwiftUI window scene whose root is a real OpenUIKit UIHostingController.
public struct _OpenWindowGroup<Content: _OpenView>: _OpenScene {
    public typealias Body = Never

    private let title: String?
    private let content: Content

    public init(@_OpenViewBuilder content: () -> Content) {
        title = nil
        self.content = content()
    }

    public init(_ title: String, @_OpenViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    public func _makeOpenUIKitSceneNode() -> _OpenSceneNode {
        let content = content
        return _OpenSceneNode(
            windows: [
                _OpenWindowDescriptor(
                    title: title,
                    makeRootViewController: {
                        _OpenUIHostingController(rootView: content)
                    }
                )
            ]
        )
    }
}

@MainActor
private enum _OpenApplicationDelegateAdaptorRegistry {
    static var delegates: [any UIApplicationDelegate] = []

    static func beginApplicationConstruction() {
        delegates.removeAll(keepingCapacity: true)
    }

    static func register(_ delegate: any UIApplicationDelegate) {
        delegates.append(delegate)
    }

    static func consumeApplicationDelegate() -> (any UIApplicationDelegate)? {
        precondition(
            delegates.count <= 1,
            "a SwiftUI App may install at most one UIApplicationDelegateAdaptor"
        )
        defer { delegates.removeAll(keepingCapacity: true) }
        return delegates.first
    }
}

/// Property-wrapper bridge from a SwiftUI App value to OpenUIKit's real
/// UIApplicationDelegate lifecycle. The delegate is created during App
/// initialization, registered before body evaluation, and retained by both
/// the wrapper and UIApplication after launch.
///
/// Linux Swift 6.2.4: Foundation's `NSObject.init()` is not `required`, so a
/// generic class metatype cannot call `DelegateType.init()`. The adaptor is
/// Darwin-only; Focus Settings only needs SwiftUI views / `UIHostingController`
/// on the Linux openrender path.
#if !os(Linux)
@MainActor
@propertyWrapper
public struct _OpenUIApplicationDelegateAdaptor<DelegateType>: _OpenDynamicProperty
    where DelegateType: NSObject, DelegateType: UIApplicationDelegate
{
    private let delegate: DelegateType

    public init(_ delegateType: DelegateType.Type = DelegateType.self) {
        let delegate = delegateType.init()
        self.delegate = delegate
        _OpenApplicationDelegateAdaptorRegistry.register(delegate)
    }

    public var wrappedValue: DelegateType { delegate }
}
#endif

@MainActor
private final class _OpenDefaultApplicationDelegate: UIResponder, UIApplicationDelegate {}

@MainActor
private final class _OpenSwiftUIWindowSceneDelegate: UIResponder, UIWindowSceneDelegate {
    private let descriptor: _OpenWindowDescriptor
    private(set) var rootViewController: UIViewController?
    var window: UIWindow?

    init(descriptor: _OpenWindowDescriptor) {
        self.descriptor = descriptor
        super.init()
    }

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else {
            preconditionFailure("SwiftUI WindowGroup requires a UIWindowScene")
        }
        let controller = descriptor.makeRootViewController()
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = controller
        windowScene.title = descriptor.title
        self.rootViewController = controller
        self.window = window
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        controller.beginAppearanceTransition(true, animated: false)
        controller.endAppearanceTransition()
    }
}

/// Retained result of one SwiftUI application launch. It exposes the concrete
/// OpenUIKit application/scene/window boundary to hosts and runtime tests while
/// retaining the App value and its property wrappers for the process lifetime.
@MainActor
public final class _OpenSwiftUIApplicationSession {
    public let application: UIApplication
    public let scenes: [UIWindowScene]
    public let windows: [UIWindow]
    public let rootViewControllers: [UIViewController]
    public let applicationDelegate: any UIApplicationDelegate

    private let appValue: Any
    private let sceneDelegates: [_OpenSwiftUIWindowSceneDelegate]

    fileprivate init(
        application: UIApplication,
        appValue: Any,
        applicationDelegate: any UIApplicationDelegate,
        scenes: [UIWindowScene],
        sceneDelegates: [_OpenSwiftUIWindowSceneDelegate]
    ) {
        self.application = application
        self.appValue = appValue
        self.applicationDelegate = applicationDelegate
        self.scenes = scenes
        self.sceneDelegates = sceneDelegates
        windows = sceneDelegates.compactMap(\.window)
        rootViewControllers = sceneDelegates.compactMap(\.rootViewController)
    }

    /// Delivers an incoming universal/custom-scheme URL to the active
    /// handlers rooted in this application session. Platform hosts invoke
    /// this after their native URL registration accepts the event.
    @discardableResult
    public func openURL(_ url: URL) -> Bool {
        rootViewControllers.reduce(false) { delivered, controller in
            guard let view = controller.viewIfLoaded else { return delivered }
            return _openDeliverURL(url, in: view) || delivered
        }
    }
}

@MainActor
enum _OpenSwiftUIApplicationLifecycle {
    private static var retainedSession: _OpenSwiftUIApplicationSession?

    @discardableResult
    static func launch<Application: _OpenApp>(
        _ applicationType: Application.Type,
        preparePackagedResources: Bool
    ) -> _OpenSwiftUIApplicationSession {
        if preparePackagedResources {
            guard let resources = Bundle.main.resourcePath, !resources.isEmpty else {
                preconditionFailure("SwiftUI application bundle has no resource directory")
            }
            OpenUIKitRuntime.configureApplicationBundleResources(at: resources)
        }

        _OpenApplicationDelegateAdaptorRegistry.beginApplicationConstruction()
        let appValue = applicationType.init()
        let delegate = _OpenApplicationDelegateAdaptorRegistry
            .consumeApplicationDelegate() ?? _OpenDefaultApplicationDelegate()
        let application = UIApplicationMain(delegate: delegate)
        let node = appValue.body._makeOpenUIKitSceneNode()
        precondition(
            !node.windows.isEmpty,
            "a SwiftUI App must produce at least one WindowGroup"
        )

        var scenes: [UIWindowScene] = []
        var sceneDelegates: [_OpenSwiftUIWindowSceneDelegate] = []
        for (index, descriptor) in node.windows.enumerated() {
            let sceneDelegate = _OpenSwiftUIWindowSceneDelegate(descriptor: descriptor)
            let session = UISceneSession(
                persistentIdentifier: "SwiftUI.WindowGroup.\(index)",
                role: .windowApplication
            )
            let scene = application._hostConnectWindowScene(
                delegate: sceneDelegate,
                session: session,
                options: UIScene.ConnectionOptions()
            )
            scenes.append(scene)
            sceneDelegates.append(sceneDelegate)
        }
        application._hostDidBecomeActive()

        let result = _OpenSwiftUIApplicationSession(
            application: application,
            appValue: appValue,
            applicationDelegate: delegate,
            scenes: scenes,
            sceneDelegates: sceneDelegates
        )
        retainedSession = result
        return result
    }

    /// Enter the production frame loop for an already launched SwiftUI App.
    /// A normal application does not return. `OPENUIKIT_HOST_TURNS` is the
    /// sole automation boundary and must be a positive decimal integer.
    static func runApplicationHost(_ session: _OpenSwiftUIApplicationSession) {
        let turnLimit = _applicationHostTurnLimit(
            getenv("OPENUIKIT_HOST_TURNS").map { String(cString: $0) }
        )
        let result = _runApplicationHost(
            application: session.application,
            windows: session.windows,
            boundedTurnCount: turnLimit,
            now: _applicationHostMonotonicSeconds,
            waitUntil: _applicationHostSleep
        )
        guard let turnLimit else {
            preconditionFailure("unbounded SwiftUI application host loop returned")
        }
        precondition(
            result.turns == turnLimit,
            "bounded SwiftUI application host returned before its requested turn count"
        )
        print("PORTABLE_UIKIT_HOST_LOOP_OK turns=\(result.turns) paced=true")
    }

    static func _runApplicationHost(
        application: UIApplication,
        windows: [UIWindow],
        boundedTurnCount: Int?,
        frameInterval: Double = 1.0 / 60.0,
        now: () -> Double,
        waitUntil: (Double) -> Void
    ) -> _OpenSwiftUIApplicationHostResult {
        precondition(!windows.isEmpty, "SwiftUI application host requires a UIWindow")
        precondition(
            application.applicationState == .active,
            "SwiftUI application host requires an active UIApplication"
        )
        precondition(
            Set(windows.map(ObjectIdentifier.init)).count == windows.count,
            "SwiftUI application host received a duplicate UIWindow"
        )
        precondition(
            windows.allSatisfy { window in
                !window.isHidden
                    && window.windowScene?.activationState == .foregroundActive
            },
            "SwiftUI application host requires visible windows in active UIWindowScenes"
        )
        if let boundedTurnCount {
            precondition(
                boundedTurnCount > 0,
                "bounded SwiftUI application host turn count must be positive"
            )
        }
        precondition(
            frameInterval.isFinite && frameInterval > 0,
            "SwiftUI application host frame interval must be finite and positive"
        )
        print("PORTABLE_UIKIT_HOST_ACTIVE windows=\(windows.count)")

        let start = now()
        precondition(start.isFinite, "SwiftUI application host clock is not finite")
        var previous = start
        var turns = 0
        var windowTicks = 0
        while true {
            let sample = now()
            precondition(
                sample.isFinite && sample >= previous,
                "SwiftUI application host clock must be finite and monotonic"
            )
            previous = sample
            let elapsed = sample - start
            OpenUIKitRuntime.animationTime = elapsed
            for window in windows {
                window.tick(timestamp: elapsed)
                windowTicks += 1
            }
            turns += 1

            if let boundedTurnCount, turns >= boundedTurnCount {
                let minimumElapsed = frameInterval
                    * Double(Swift.max(0, boundedTurnCount - 1)) * 0.8
                precondition(
                    elapsed >= minimumElapsed,
                    "bounded SwiftUI application host did not use the paced clock"
                )
                application._hostWillTerminate()
                return _OpenSwiftUIApplicationHostResult(
                    elapsed: elapsed,
                    turns: turns,
                    windowTicks: windowTicks
                )
            }
            waitUntil(start + elapsed + frameInterval)
        }
    }

    static func _applicationHostTurnLimit(_ value: String?) -> Int? {
        guard let value else { return nil }
        guard let count = Int(value), count > 0 else {
            preconditionFailure("OPENUIKIT_HOST_TURNS must be a positive integer")
        }
        return count
    }

    private static func _applicationHostMonotonicSeconds() -> Double {
        var value = timespec()
        guard clock_gettime(CLOCK_MONOTONIC, &value) == 0 else {
            preconditionFailure("SwiftUI application host could not read CLOCK_MONOTONIC")
        }
        return Double(value.tv_sec) + Double(value.tv_nsec) * 1e-9
    }

    private static func _applicationHostSleep(until deadline: Double) {
        let delay = deadline - _applicationHostMonotonicSeconds()
        guard delay > 0 else { return }
        var request = timespec(
            tv_sec: Int(delay),
            tv_nsec: Int((delay - Double(Int(delay))) * 1e9)
        )
        var remainder = timespec()
        while nanosleep(&request, &remainder) != 0 {
            request = remainder
        }
    }
}

struct _OpenSwiftUIApplicationHostResult: Equatable {
    let elapsed: Double
    let turns: Int
    let windowTicks: Int
}

@MainActor
public protocol _OpenApp {
    associatedtype Body: _OpenScene

    init()

    @_OpenSceneBuilder var body: Body { get }
}

public extension _OpenApp {
    static func main() {
        let session = _OpenSwiftUIApplicationLifecycle.launch(
            Self.self,
            preparePackagedResources: true
        )
        _OpenSwiftUIApplicationLifecycle.runApplicationHost(session)
    }
}

public typealias App = _OpenApp
public typealias Scene = _OpenScene
public typealias SceneBuilder = _OpenSceneBuilder
public typealias WindowGroup<Content> = _OpenWindowGroup<Content> where Content: _OpenView
#if !os(Linux)
public typealias UIApplicationDelegateAdaptor<DelegateType> =
    _OpenUIApplicationDelegateAdaptor<DelegateType>
    where DelegateType: NSObject, DelegateType: UIApplicationDelegate
#endif
