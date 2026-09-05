import Foundation

// MARK: - Isolation stand-ins
//
// The isolated host gate compiles ExtensionKit with Foundation only. Apple's
// `NSXPCConnection` is Foundation-owned but missing from this Linux overlay.
// `UIView` / `UIViewController` are UIKit-owned. `View` / `ViewBuilder` are
// SwiftUI-owned. `AppExtension`, `AppExtensionConfiguration`, and
// `AppExtensionIdentity` are ExtensionFoundation-owned. These stand-ins exist
// so ExtensionKit-owned signatures type-check. They are not Linux ports of
// those modules and must be deleted when the real modules are on the link line.

#if os(Linux)
open class NSXPCConnection: NSObject, @unchecked Sendable {
    public let serviceName: String?

    public override init() {
        self.serviceName = nil
        super.init()
    }

    public init(serviceName: String) {
        self.serviceName = serviceName
        super.init()
    }
}
#endif

#if !canImport(UIKit)
open class UIView: NSObject, @unchecked Sendable {
    public override init() {
        super.init()
    }
}

open class UIViewController: NSObject, @unchecked Sendable {
    public override init() {
        super.init()
    }
}
#endif

#if !canImport(SwiftUI)
public protocol View {
    associatedtype Body: View
    var body: Self.Body { get }
}

public struct EmptyView: View {
    public init() {}

    public var body: Never {
        fatalError("EmptyView is a leaf")
    }
}

@resultBuilder
public enum ViewBuilder {
    public static func buildBlock() -> EmptyView { EmptyView() }

    public static func buildBlock<Content: View>(_ content: Content) -> Content {
        content
    }
}
#endif

#if !canImport(ExtensionFoundation)
public protocol AppExtensionConfiguration {
    func accept(connection: NSXPCConnection) -> Bool
}

public protocol AppExtension {
    associatedtype Configuration: AppExtensionConfiguration
    var configuration: Configuration { get }
}

/// ExtensionFoundation-owned identity stand-in. Not Apple's type.
public struct AppExtensionIdentity: Hashable, Sendable {
    public var bundleIdentifier: String

    public init(bundleIdentifier: String) {
        self.bundleIdentifier = bundleIdentifier
    }
}
#endif
