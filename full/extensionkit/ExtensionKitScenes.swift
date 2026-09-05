import Foundation

/// Internal primitive harvest used by scene composition and `accept(connection:)`.
protocol _ExtensionKitPrimitiveSource {
    func _extensionKitPrimitives() -> [PrimitiveAppExtensionScene]
}

func _collectPrimitives<S: AppExtensionScene>(_ scene: S) -> [PrimitiveAppExtensionScene] {
    if let source = scene as? any _ExtensionKitPrimitiveSource {
        return source._extensionKitPrimitives()
    }
    return _collectPrimitives(scene.body)
}

/// An interface you use to provide a specific scene from your app extension’s UI.
@MainActor
@preconcurrency
public protocol AppExtensionScene {
    associatedtype Body: AppExtensionScene
    @MainActor @preconcurrency var body: Self.Body { get }
}

/// Composed scene returned by multi-argument `AppExtensionSceneBuilder.buildBlock`.
struct _ComposedAppExtensionScene: AppExtensionScene, _ExtensionKitPrimitiveSource {
    typealias Body = Never
    var primitives: [PrimitiveAppExtensionScene]

    var body: Never {
        fatalError("_ComposedAppExtensionScene is a composition; body is uninhabited")
    }

    func _extensionKitPrimitives() -> [PrimitiveAppExtensionScene] {
        primitives
    }
}

/// A type you use to deliver the contents of your app-extension-based UI.
@MainActor
@preconcurrency
public struct PrimitiveAppExtensionScene: AppExtensionScene, Sendable {
    public typealias Body = Never

    final class _Storage: @unchecked Sendable {
        let id: String
        let onConnection: @Sendable (NSXPCConnection) -> Bool
        let renderContent: @Sendable () -> Void

        init(
            id: String,
            onConnection: @escaping @Sendable (NSXPCConnection) -> Bool,
            renderContent: @escaping @Sendable () -> Void
        ) {
            self.id = id
            self.onConnection = onConnection
            self.renderContent = renderContent
        }
    }

    let storage: _Storage

    /// Initializes the primitive app extension scene with the specified ID and
    /// closure for the content.
    ///
    /// `onConnection` defaults to `{ _ in false }` as declared by the pinned
    /// public surface. Linux never opens a real XPC session; the closure is
    /// invoked only when a caller passes a connection into
    /// `AppExtensionSceneConfiguration.accept(connection:)`.
    @MainActor
    @preconcurrency
    public init<Content: View>(
        id: String,
        @ViewBuilder content: @escaping () -> Content,
        onConnection: @escaping (NSXPCConnection) -> Bool = { _ in false }
    ) {
        let render = content
        self.storage = _Storage(
            id: id,
            onConnection: { connection in onConnection(connection) },
            renderContent: { _ = render() }
        )
    }

    @MainActor
    @preconcurrency
    public var body: Never {
        fatalError("PrimitiveAppExtensionScene is a leaf AppExtensionScene")
    }

    /// A string that provides information about the scene.
    ///
    /// Apple's exact format is unobserved. Linux includes the scene identifier.
    @MainActor
    @preconcurrency
    public var debugDescription: String {
        "PrimitiveAppExtensionScene(id: \(storage.id))"
    }

    @_spi(OpenUIKitHost)
    public var host_sceneID: String { storage.id }

    @_spi(OpenUIKitHost)
    public func host_renderContent() {
        storage.renderContent()
    }
}

extension PrimitiveAppExtensionScene: @MainActor CustomDebugStringConvertible {}

extension PrimitiveAppExtensionScene: _ExtensionKitPrimitiveSource {
    func _extensionKitPrimitives() -> [PrimitiveAppExtensionScene] {
        [self]
    }
}

/// A custom parameter attribute that constructs extension scenes from closures.
@MainActor
@preconcurrency
@resultBuilder
public struct AppExtensionSceneBuilder: Sendable {
    /// Passes through a single extension scene unmodified.
    @MainActor
    @preconcurrency
    public static func buildBlock<Content: AppExtensionScene>(
        _ content: Content
    ) -> some AppExtensionScene {
        content
    }

    /// Builds an extension scene by combining two scenes.
    @MainActor
    @preconcurrency
    public static func buildBlock<C0: AppExtensionScene, C1: AppExtensionScene>(
        _ c0: C0,
        _ c1: C1
    ) -> some AppExtensionScene {
        _ComposedAppExtensionScene(primitives: _collectPrimitives(c0) + _collectPrimitives(c1))
    }

    /// Builds an extension scene by combining three scenes.
    @MainActor
    @preconcurrency
    public static func buildBlock<C0: AppExtensionScene, C1: AppExtensionScene, C2: AppExtensionScene>(
        _ c0: C0,
        _ c1: C1,
        _ c2: C2
    ) -> some AppExtensionScene {
        _ComposedAppExtensionScene(
            primitives: _collectPrimitives(c0) + _collectPrimitives(c1) + _collectPrimitives(c2)
        )
    }

    @MainActor
    @preconcurrency
    public static func buildBlock<
        C0: AppExtensionScene, C1: AppExtensionScene, C2: AppExtensionScene, C3: AppExtensionScene
    >(
        _ c0: C0,
        _ c1: C1,
        _ c2: C2,
        _ c3: C3
    ) -> some AppExtensionScene {
        _ComposedAppExtensionScene(
            primitives: _collectPrimitives(c0) + _collectPrimitives(c1)
                + _collectPrimitives(c2) + _collectPrimitives(c3)
        )
    }

    @MainActor
    @preconcurrency
    public static func buildBlock<
        C0: AppExtensionScene, C1: AppExtensionScene, C2: AppExtensionScene, C3: AppExtensionScene,
        C4: AppExtensionScene
    >(
        _ c0: C0,
        _ c1: C1,
        _ c2: C2,
        _ c3: C3,
        _ c4: C4
    ) -> some AppExtensionScene {
        _ComposedAppExtensionScene(
            primitives: _collectPrimitives(c0) + _collectPrimitives(c1)
                + _collectPrimitives(c2) + _collectPrimitives(c3) + _collectPrimitives(c4)
        )
    }

    @MainActor
    @preconcurrency
    public static func buildBlock<
        C0: AppExtensionScene, C1: AppExtensionScene, C2: AppExtensionScene, C3: AppExtensionScene,
        C4: AppExtensionScene, C5: AppExtensionScene
    >(
        _ c0: C0,
        _ c1: C1,
        _ c2: C2,
        _ c3: C3,
        _ c4: C4,
        _ c5: C5
    ) -> some AppExtensionScene {
        _ComposedAppExtensionScene(
            primitives: _collectPrimitives(c0) + _collectPrimitives(c1)
                + _collectPrimitives(c2) + _collectPrimitives(c3)
                + _collectPrimitives(c4) + _collectPrimitives(c5)
        )
    }

    @MainActor
    @preconcurrency
    public static func buildBlock<
        C0: AppExtensionScene, C1: AppExtensionScene, C2: AppExtensionScene, C3: AppExtensionScene,
        C4: AppExtensionScene, C5: AppExtensionScene, C6: AppExtensionScene
    >(
        _ c0: C0,
        _ c1: C1,
        _ c2: C2,
        _ c3: C3,
        _ c4: C4,
        _ c5: C5,
        _ c6: C6
    ) -> some AppExtensionScene {
        _ComposedAppExtensionScene(
            primitives: _collectPrimitives(c0) + _collectPrimitives(c1)
                + _collectPrimitives(c2) + _collectPrimitives(c3)
                + _collectPrimitives(c4) + _collectPrimitives(c5) + _collectPrimitives(c6)
        )
    }

    @MainActor
    @preconcurrency
    public static func buildBlock<
        C0: AppExtensionScene, C1: AppExtensionScene, C2: AppExtensionScene, C3: AppExtensionScene,
        C4: AppExtensionScene, C5: AppExtensionScene, C6: AppExtensionScene, C7: AppExtensionScene
    >(
        _ c0: C0,
        _ c1: C1,
        _ c2: C2,
        _ c3: C3,
        _ c4: C4,
        _ c5: C5,
        _ c6: C6,
        _ c7: C7
    ) -> some AppExtensionScene {
        _ComposedAppExtensionScene(
            primitives: _collectPrimitives(c0) + _collectPrimitives(c1)
                + _collectPrimitives(c2) + _collectPrimitives(c3)
                + _collectPrimitives(c4) + _collectPrimitives(c5)
                + _collectPrimitives(c6) + _collectPrimitives(c7)
        )
    }

    @MainActor
    @preconcurrency
    public static func buildBlock<
        C0: AppExtensionScene, C1: AppExtensionScene, C2: AppExtensionScene, C3: AppExtensionScene,
        C4: AppExtensionScene, C5: AppExtensionScene, C6: AppExtensionScene, C7: AppExtensionScene,
        C8: AppExtensionScene
    >(
        _ c0: C0,
        _ c1: C1,
        _ c2: C2,
        _ c3: C3,
        _ c4: C4,
        _ c5: C5,
        _ c6: C6,
        _ c7: C7,
        _ c8: C8
    ) -> some AppExtensionScene {
        _ComposedAppExtensionScene(
            primitives: _collectPrimitives(c0) + _collectPrimitives(c1)
                + _collectPrimitives(c2) + _collectPrimitives(c3)
                + _collectPrimitives(c4) + _collectPrimitives(c5)
                + _collectPrimitives(c6) + _collectPrimitives(c7) + _collectPrimitives(c8)
        )
    }

    @MainActor
    @preconcurrency
    public static func buildBlock<
        C0: AppExtensionScene, C1: AppExtensionScene, C2: AppExtensionScene, C3: AppExtensionScene,
        C4: AppExtensionScene, C5: AppExtensionScene, C6: AppExtensionScene, C7: AppExtensionScene,
        C8: AppExtensionScene, C9: AppExtensionScene
    >(
        _ c0: C0,
        _ c1: C1,
        _ c2: C2,
        _ c3: C3,
        _ c4: C4,
        _ c5: C5,
        _ c6: C6,
        _ c7: C7,
        _ c8: C8,
        _ c9: C9
    ) -> some AppExtensionScene {
        _ComposedAppExtensionScene(
            primitives: _collectPrimitives(c0) + _collectPrimitives(c1)
                + _collectPrimitives(c2) + _collectPrimitives(c3)
                + _collectPrimitives(c4) + _collectPrimitives(c5)
                + _collectPrimitives(c6) + _collectPrimitives(c7)
                + _collectPrimitives(c8) + _collectPrimitives(c9)
        )
    }
}

/// An object you use to configure an app extension that provides a custom UI.
@MainActor
@preconcurrency
public struct AppExtensionSceneConfiguration: AppExtensionConfiguration, Sendable {
    final class _Storage: @unchecked Sendable {
        let primitives: [PrimitiveAppExtensionScene]
        let nestedAccept: (@Sendable (NSXPCConnection) -> Bool)?

        init(
            primitives: [PrimitiveAppExtensionScene],
            nestedAccept: (@Sendable (NSXPCConnection) -> Bool)?
        ) {
            self.primitives = primitives
            self.nestedAccept = nestedAccept
        }
    }

    let storage: _Storage

    /// Creates a scene configuration from a closure.
    @MainActor
    @preconcurrency
    public init<Content: AppExtensionScene>(
        _ content: @autoclosure @escaping @MainActor () -> Content
    ) {
        self.storage = _Storage(
            primitives: _collectPrimitives(content()),
            nestedAccept: nil
        )
    }

    /// Creates a scene configuration object from a closure and extension configuration.
    ///
    /// The optional nested configuration manages global IPC. Linux requires that
    /// nested `accept` return `true` (when present) and that at least one scene
    /// `onConnection` return `true`. Darwin's composition is unobserved.
    @MainActor
    @preconcurrency
    public init<Content: AppExtensionScene, Configuration: AppExtensionConfiguration>(
        _ content: @autoclosure @escaping @MainActor () -> Content,
        configuration: Configuration? = nil
    ) {
        let nested: (@Sendable (NSXPCConnection) -> Bool)?
        if let configuration {
            nested = { connection in configuration.accept(connection: connection) }
        } else {
            nested = nil
        }
        self.storage = _Storage(
            primitives: _collectPrimitives(content()),
            nestedAccept: nested
        )
    }

    /// A closure the framework calls when a host tries to connect to this extension.
    ///
    /// Default `onConnection` returns `false`, so a freshly built configuration
    /// rejects. Linux never claims an Apple XPC session succeeded.
    public nonisolated func accept(connection: NSXPCConnection) -> Bool {
        if let nestedAccept = storage.nestedAccept, !nestedAccept(connection) {
            return false
        }
        return storage.primitives.contains { primitive in
            primitive.storage.onConnection(connection)
        }
    }

    @_spi(OpenUIKitHost)
    public var host_sceneIDs: [String] {
        storage.primitives.map(\.storage.id)
    }
}

extension Array: AppExtensionScene where Element: AppExtensionScene {
    public typealias Body = Never

    @MainActor
    @preconcurrency
    public var body: Never {
        fatalError("Array AppExtensionScene is a composition; body is uninhabited")
    }
}

extension Array: _ExtensionKitPrimitiveSource where Element: AppExtensionScene {
    func _extensionKitPrimitives() -> [PrimitiveAppExtensionScene] {
        reduce(into: []) { result, element in
            result.append(contentsOf: _collectPrimitives(element))
        }
    }
}

extension Never: AppExtensionScene {
    @MainActor
    @preconcurrency
    public var body: Never {
        fatalError("Never has no AppExtensionScene body")
    }
}

#if !canImport(SwiftUI)
extension Never: View {
    public typealias Body = Never
}
#endif

extension Never: _ExtensionKitPrimitiveSource {
    func _extensionKitPrimitives() -> [PrimitiveAppExtensionScene] {
        []
    }
}
