// SwiftUI application lifecycle backed by OpenUIKit's real application,
// scene, window, view-controller, and responder machinery.

#if canImport(Foundation)
import Foundation
#elseif canImport(ObjectiveC)
import ObjectiveC
#endif
import OpenUIKit

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
}

@MainActor
public protocol _OpenApp {
    associatedtype Body: _OpenScene

    init()

    @_OpenSceneBuilder var body: Body { get }
}

public extension _OpenApp {
    static func main() {
        _OpenSwiftUIApplicationLifecycle.launch(
            Self.self,
            preparePackagedResources: true
        )
    }
}

public typealias App = _OpenApp
public typealias Scene = _OpenScene
public typealias SceneBuilder = _OpenSceneBuilder
public typealias WindowGroup<Content> = _OpenWindowGroup<Content> where Content: _OpenView
public typealias UIApplicationDelegateAdaptor<DelegateType> =
    _OpenUIApplicationDelegateAdaptor<DelegateType>
    where DelegateType: NSObject, DelegateType: UIApplicationDelegate
