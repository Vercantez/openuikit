import Foundation

// Isolated-host stand-ins for types owned by UniformTypeIdentifiers, Network,
// ExtensionFoundation, and Darwin Foundation (NSXPCConnection). The sealed
// host gate compiles this module with Foundation only. When a real module is
// on the link line these blocks compile out. They are not Linux ports of
// those frameworks.

#if !canImport(UniformTypeIdentifiers)

/// Isolated-host shell of `UniformTypeIdentifiers.UTType`. Identifier storage
/// only; this is not a UTI database.
public struct UTType: Equatable, Hashable, Sendable {
    public var identifier: String

    public init(_ identifier: String) {
        self.identifier = identifier
    }
}

#endif

#if !canImport(Network)

/// Isolated-host shell of `Network.NWEndpoint`. Construction does not open a
/// path, browser, or connection.
public enum NWEndpoint: Hashable, Sendable {
    case hostPort(host: String, port: UInt16)
}

/// Isolated-host shell of `Network.NWTXTRecord`. Bytes are retained locally
/// and never advertised on the wire.
public struct NWTXTRecord: Equatable, Hashable, Sendable {
    public var data: Data

    public init(_ data: Data = Data()) {
        self.data = data
    }
}

#endif

#if os(Linux)

/// Darwin `Foundation.NSXPCConnection` is missing from this Linux overlay.
/// The type exists so `accept(connection:)` type-checks. It does not listen.
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

#if !canImport(ExtensionFoundation)

/// Isolated-host shell of `ExtensionFoundation.AppExtensionConfiguration`.
public protocol AppExtensionConfiguration {
    func accept(connection: NSXPCConnection) -> Bool
}

/// Isolated-host shell of `ExtensionFoundation.AppExtension`.
public protocol AppExtension {
    associatedtype Configuration: AppExtensionConfiguration
    var configuration: Configuration { get }
}

#endif
