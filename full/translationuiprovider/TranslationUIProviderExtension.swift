import Foundation

/// A protocol that creates a translation UI provider extension.
///
/// Darwin is `@MainActor` and inherits ExtensionFoundation `AppExtension`.
/// Linux omits `@MainActor` so the sealed runner can construct conforming
/// types. `configuration` never launches an `appex` process.
public protocol TranslationUIProviderExtension: AppExtension
where Configuration == AppExtensionSceneConfiguration {
    associatedtype Body: TranslationUIProviderExtensionScene
    var body: Self.Body { get }
}

extension TranslationUIProviderExtension {
    /// A read-only, computed configuration for the translation UI provider
    /// extension.
    ///
    /// Darwin returns ExtensionKit `AppExtensionSceneConfiguration`. Linux
    /// vends an isolation `AppExtensionSceneConfiguration`. It does not
    /// register an ExtensionKit scene with a host.
    public var configuration: AppExtensionSceneConfiguration {
        AppExtensionSceneConfiguration(body)
    }
}

/// The AppExtensionScene protocol to which this extension's scenes conform.
public protocol TranslationUIProviderExtensionScene: AppExtensionScene {}

/// Process-local leaf scene returned by `TranslationUIProviderSelectedTextScene.body`.
/// Does not present translation UI.
public struct TranslationUIProviderHostExtensionScene: TranslationUIProviderExtensionScene,
    Sendable
{
    public typealias Body = Never

    public init() {}

    public var body: Never {
        fatalError("TranslationUIProviderHostExtensionScene is a leaf AppExtensionScene")
    }
}

/// The specific AppExtensionScene that this extension provides.
///
/// Linux stores the content closure. The closure is not rendered by SwiftUI
/// or ExtensionKit. The host supplies `TranslationUIProviderContext` when
/// asking Linux to invoke the closure; Darwin delivers that context over XPC.
public struct TranslationUIProviderSelectedTextScene<Content: View>: TranslationUIProviderExtensionScene,
    @unchecked Sendable
{
    public typealias Body = TranslationUIProviderHostExtensionScene

    private let content: (any TranslationUIProviderContext) -> Content

    /// Creates the selected-text scene with a content builder.
    ///
    /// Darwin: the system supplies the context when the extension UI loads.
    /// Linux stores the closure and does not invent a host context.
    public init(content: @escaping (any TranslationUIProviderContext) -> Content) {
        self.content = content
    }

    /// The content and behavior of the scene’s interface.
    ///
    /// Linux returns a leaf host scene that does not present a sheet.
    public var body: TranslationUIProviderHostExtensionScene {
        TranslationUIProviderHostExtensionScene()
    }

    @_spi(OpenUIKitHost)
    public func hostRenderContent(context: any TranslationUIProviderContext) -> Content {
        content(context)
    }
}

/// Configuration for extensions that conform to the
/// ``TranslationUIProviderExtension`` protocol.
///
/// Darwin is `@MainActor` and talks to ExtensionFoundation. Linux stores the
/// extension's type name and never accepts an XPC connection.
public struct TranslationProviderUIExtensionConfiguration: AppExtensionConfiguration, Sendable {
    @_spi(OpenUIKitHost)
    public let hostExtensionTypeName: String

    /// Creates a default configuration for the given extension.
    ///
    /// - Parameter appExtension: An instance of the extension that conforms
    ///   to the ``TranslationUIProviderExtension`` protocol.
    public init(_ appExtension: any TranslationUIProviderExtension) {
        self.hostExtensionTypeName = String(reflecting: type(of: appExtension))
    }

    /// Darwin's TBD exports `accept(connection:)`. Linux never accepts a
    /// connection; there is no `NSXPCConnection` on this isolated host.
    @_spi(OpenUIKitHost)
    public func hostAcceptConnection() -> Bool {
        false
    }
}
