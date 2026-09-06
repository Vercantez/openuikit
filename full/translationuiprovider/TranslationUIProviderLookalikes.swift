import Foundation

// MARK: - Isolation stand-ins
//
// The isolated host gate compiles TranslationUIProvider with Foundation
// (and toolchain Observation) only. `View` is SwiftUI-owned. `AppExtension`
// is ExtensionFoundation-owned. `AppExtensionScene` and
// `AppExtensionSceneConfiguration` are ExtensionKit-owned. These stand-ins
// exist so TranslationUIProvider-owned signatures type-check. They are not
// Linux ports of those modules and must be deleted when the real modules are
// on the link line.

#if !canImport(SwiftUI)
/// SwiftUI-owned view protocol. Isolation stand-in only.
public protocol View {
    associatedtype Body: View
    var body: Self.Body { get }
}

/// SwiftUI-owned empty view. Isolation stand-in only.
public struct EmptyView: View {
    public init() {}

    public var body: Never {
        fatalError("EmptyView is a leaf View")
    }
}
#endif

#if !canImport(ExtensionFoundation)
/// ExtensionFoundation-owned configuration protocol. Isolation stand-in only.
public protocol AppExtensionConfiguration {}

/// ExtensionFoundation-owned extension protocol. Isolation stand-in only.
public protocol AppExtension {
    associatedtype Configuration: AppExtensionConfiguration
    var configuration: Configuration { get }
}
#endif

#if !canImport(ExtensionKit)
/// ExtensionKit-owned scene protocol. Isolation stand-in only.
public protocol AppExtensionScene {
    associatedtype Body: AppExtensionScene
    var body: Self.Body { get }
}

/// ExtensionKit-owned scene configuration. Isolation stand-in only.
/// Linux stores no XPC accept policy and never talks to `appex`.
public struct AppExtensionSceneConfiguration: AppExtensionConfiguration, Sendable {
    public let hostSceneTypeName: String

    public init<S: AppExtensionScene>(_ scene: S) {
        self.hostSceneTypeName = String(reflecting: type(of: scene))
    }
}
#endif

#if !canImport(SwiftUI) && !canImport(ExtensionKit)
extension Never: View, AppExtensionScene {
    public typealias Body = Never

    public var body: Never {
        fatalError("Never is a leaf View and AppExtensionScene")
    }
}
#elseif !canImport(SwiftUI)
extension Never: View {
    public typealias Body = Never

    public var body: Never {
        fatalError("Never is a leaf View")
    }
}
#elseif !canImport(ExtensionKit)
extension Never: AppExtensionScene {
    public typealias Body = Never

    public var body: Never {
        fatalError("Never is a leaf AppExtensionScene")
    }
}
#endif
