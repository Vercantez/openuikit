import Foundation
import Observation

// OpenUIKit Linux starting point for Apple's public ExtensionFoundation module.
// Isolated host compilation imports Foundation only. `NSXPCConnection` is
// Foundation-owned on Darwin but absent from this Linux overlay; `XPCSession`
// and `XPCListener` are XPC-owned. Linux lookalikes exist so public signatures
// type-check. They are not Darwin types and must not be used to claim an Apple
// XPC session succeeded.
//
// Linux never talks to `appex`, `nsxpc`, or an extension catalog. Process
// launch and XPC success are fail-closed. Value types, result builders,
// connection-accept closures, and monitor snapshots are process-local and real.

/// Linux-local fail-closed errors. Apple's ExtensionFoundation NSError domain
/// and codes for process/XPC failure are unobserved; these discriminators are
/// not Darwin codes.
public enum ExtensionFoundationHostError: Error, Equatable, Hashable, Sendable {
    /// `AppExtension.main()` has no extension process to enter.
    case extensionProcessUnavailable
    /// `AppExtensionProcess` cannot launch an appex on Linux.
    case processUnavailable
    /// `makeXPCConnection()` / `makeXPCSession()` cannot open a session.
    case xpcUnavailable
}

extension ExtensionFoundationHostError: CustomNSError {
    public static var errorDomain: String { "ExtensionFoundation.Linux" }

    public var errorCode: Int {
        switch self {
        case .extensionProcessUnavailable: return 1
        case .processUnavailable: return 2
        case .xpcUnavailable: return 3
        }
    }
}

func extensionFoundationString(_ value: StaticString) -> String {
    if value.hasPointerRepresentation {
        return value.withUTF8Buffer { buffer in
            String(decoding: buffer, as: UTF8.self)
        }
    }
    return String(value.unicodeScalar)
}

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

#if !canImport(XPC)
/// XPC-owned session stand-in. Not Apple's type.
public final class XPCSession: @unchecked Sendable {
    public init() {}
}

/// XPC-owned listener stand-in. Not Apple's type.
public final class XPCListener: @unchecked Sendable {
    public init() {}

    public final class IncomingSessionRequest: @unchecked Sendable {
        public init() {}

        public struct Decision: Equatable, Sendable {
            public init() {}
        }
    }
}
#endif

/// An interface you use to declare the content, structure, and behavior of an
/// app extension.
public protocol AppExtension {
    /// A type that manages configuration data for an app extension.
    associatedtype Configuration: AppExtensionConfiguration

    /// The configuration details for this app extension.
    var configuration: Self.Configuration { get }

    /// Initializes the app extension and prepares it to run.
    init()
}

extension AppExtension {
    /// The main entry point for an app extension that does not present UI.
    ///
    /// Darwin calls this when a host launches the extension process. Linux has
    /// no such process and always throws.
    public static func main() throws {
        throw ExtensionFoundationHostError.extensionProcessUnavailable
    }
}

/// An interface you use to configure the XPC connection in your app extension.
public protocol AppExtensionConfiguration: Sendable {
    /// Returns whether the extension accepts an incoming host connection.
    func accept(connection: NSXPCConnection) -> Bool
}

/// A type that contains a custom closure that handles incoming XPC connections.
public struct ConnectionHandler: AppExtensionConfiguration, @unchecked Sendable {
    private let connectionHandler: ((NSXPCConnection) -> Bool)?
    private let sessionHandler:
        ((XPCListener.IncomingSessionRequest) -> XPCListener.IncomingSessionRequest.Decision)?

    /// Initializes the connection handler with a Foundation XPC object closure.
    public init(onConnection connectionHandler: @escaping (NSXPCConnection) -> Bool) {
        self.connectionHandler = connectionHandler
        self.sessionHandler = nil
    }

    /// Initializes the connection handler with an XPC session-request closure.
    public init(
        onSessionRequest requestHandler: @escaping (
            XPCListener.IncomingSessionRequest
        ) -> XPCListener.IncomingSessionRequest.Decision
    ) {
        self.connectionHandler = nil
        self.sessionHandler = requestHandler
    }

    /// Returns whether the stored Foundation-XPC closure accepts `connection`.
    ///
    /// A handler created with `init(onSessionRequest:)` returns `false` here:
    /// that path is a different XPC generation and is not a Foundation
    /// `NSXPCConnection`.
    public func accept(connection: NSXPCConnection) -> Bool {
        connectionHandler?(connection) ?? false
    }

    @_spi(OpenUIKitHost)
    public var host_usesConnectionHandler: Bool {
        connectionHandler != nil
    }

    @_spi(OpenUIKitHost)
    public var host_usesSessionHandler: Bool {
        sessionHandler != nil
    }

    @_spi(OpenUIKitHost)
    public func host_decideSession(
        _ request: XPCListener.IncomingSessionRequest
    ) -> XPCListener.IncomingSessionRequest.Decision? {
        sessionHandler?(request)
    }
}

/// An interface that extension point types adopt.
public protocol ExtensionPointDefining {}
