@_exported import Foundation

// Isolated-host stand-ins for UIKit, SwiftUI, and Network types named by the
// public DeviceDiscoveryUI surface. The sealed host gate compiles this module
// alone. When a real module is on the link line, these blocks compile out.
// They are not a Linux UIKit, SwiftUI, or Network port.

#if !canImport(UIKit)

open class UIResponder: NSObject {
    public override init() {
        super.init()
    }
}

open class UIViewController: UIResponder {
    public override init() {
        super.init()
    }

    open func viewDidLoad() {}
}

#endif

#if !canImport(SwiftUI)

public protocol View {
    associatedtype Body: View
    var body: Body { get }
}

@resultBuilder
public enum ViewBuilder {
    public static func buildBlock() -> EmptyView {
        EmptyView()
    }

    public static func buildBlock<Content: View>(_ content: Content) -> Content {
        content
    }

    public static func buildExpression<Content: View>(_ content: Content) -> Content {
        content
    }
}

public struct EmptyView: View {
    public init() {}
    public var body: Never { preconditionFailure("EmptyView has no body") }
}

extension Never: View {
    public var body: Never { preconditionFailure("Never has no body") }
}

#endif

#if !canImport(Network)

/// Isolated-host existential for Apple's `Network.ListenerProvider`.
/// Not a Network port; present so pairing APIs type-check without that module.
public protocol ListenerProvider {}

/// Isolated-host protocol for Apple's `Network.BrowserProvider`.
public protocol BrowserProvider {
    associatedtype Endpoint
}

/// Isolated-host shell of `Network.NWBrowser` covering only the `Descriptor`
/// cases DeviceDiscoveryUI takes as arguments.
public enum NWBrowser {
    public enum Descriptor: Hashable, Sendable {
        case bonjour(type: String, domain: String?)
        case bonjourWithTXTRecord(type: String, domain: String?)
        case applicationService(name: String)
    }
}

/// Isolated-host shell of `Network.NWParameters`. Construction does not start
/// a path, browser, or listener.
public final class NWParameters {
    public init() {}
}

/// Isolated-host shell of `Network.NWEndpoint`. Linux never produces a
/// selected peer; this type exists so `endpoint` can be declared.
public enum NWEndpoint: Hashable, Sendable {
    case hostPort(host: String, port: UInt16)
}

#endif
