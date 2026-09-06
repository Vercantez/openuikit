import Foundation

public enum RestrictedSandboxRevision: Equatable, Hashable, Comparable, CaseIterable, Sendable {
    case revision1
    case revision2

    public static func < (lhs: RestrictedSandboxRevision, rhs: RestrictedSandboxRevision) -> Bool {
        lhs.rank < rhs.rank
    }

    private var rank: Int {
        switch self {
        case .revision1: return 1
        case .revision2: return 2
        }
    }
}

public protocol RestrictedSandboxAppliable {
    func applyRestrictedSandbox(revision: RestrictedSandboxRevision)
}

extension RestrictedSandboxAppliable {
    public func applyRestrictedSandbox(revision: RestrictedSandboxRevision) {
        _ = revision
    }
}

extension RestrictedSandboxAppliable where Self: WebContentExtension {
    public func applyRestrictedSandbox(revision: RestrictedSandboxRevision) {
        _ = revision
    }
}

public protocol BEExtensionProcess: NSObjectProtocol {
    func invalidate()
    func makeLibXPCConnectionError() throws -> xpc_connection_t
}

public enum ProcessCapability: Equatable {
    case background
    case foreground
    case suspended
    case mediaPlaybackAndCapture(environment: MediaEnvironment)

    public struct Grant {
        private final class State {
            var valid = true
        }

        private let state: State

        public var isValid: Bool { state.valid }

        public func invalidate() {
            state.valid = false
        }

        public static func host_makeValid() -> Grant {
            Grant(state: State())
        }

        private init(state: State) {
            self.state = state
        }
    }
}

public final class BEProcessCapability: NSObject, @unchecked Sendable {
    public enum Kind: Equatable {
        case background
        case foreground
        case suspended
        case mediaPlaybackAndCapture
    }

    public let kind: Kind

    private init(kind: Kind) {
        self.kind = kind
        super.init()
    }

    public static func background() -> BEProcessCapability {
        BEProcessCapability(kind: .background)
    }

    public static func foreground() -> BEProcessCapability {
        BEProcessCapability(kind: .foreground)
    }

    public static func suspended() -> BEProcessCapability {
        BEProcessCapability(kind: .suspended)
    }

    public static func mediaPlaybackAndCapture(
        environment: BEMediaEnvironment
    ) -> BEProcessCapability {
        _ = environment
        return BEProcessCapability(kind: .mediaPlaybackAndCapture)
    }

    public func request() throws -> ProcessCapability.Grant {
        throw BrowserEngineKitHostError.processUnavailable
    }
}

public struct WebContentProcess {
    public private(set) var isInvalidated = false

    public static func host_makeUnavailable() -> WebContentProcess {
        WebContentProcess()
    }

    public init(bundleIdentifier: String? = nil, onInterruption: @escaping () -> Void) async throws {
        _ = bundleIdentifier
        _ = onInterruption
        throw BrowserEngineKitHostError.processUnavailable
    }

    private init() {}

    public mutating func invalidate() {
        isInvalidated = true
    }

    public func makeLibXPCConnection() throws -> xpc_connection_t {
        throw BrowserEngineKitHostError.xpcUnavailable
    }

    public func grantCapability(_ capability: ProcessCapability) throws -> ProcessCapability.Grant {
        _ = capability
        throw BrowserEngineKitHostError.processUnavailable
    }

    public func grantCapability(
        _ capability: ProcessCapability,
        invalidationHandler: @escaping () -> Void
    ) throws -> ProcessCapability.Grant {
        _ = capability
        _ = invalidationHandler
        throw BrowserEngineKitHostError.processUnavailable
    }

    public func createVisibilityPropagationInteraction() -> any UIInteraction {
        BEHostInteraction()
    }
}

public struct NetworkingProcess {
    public private(set) var isInvalidated = false

    public static func host_makeUnavailable() -> NetworkingProcess {
        NetworkingProcess()
    }

    public init(bundleIdentifier: String? = nil, onInterruption: @escaping () -> Void) async throws {
        _ = bundleIdentifier
        _ = onInterruption
        throw BrowserEngineKitHostError.processUnavailable
    }

    private init() {}

    public mutating func invalidate() {
        isInvalidated = true
    }

    public func makeLibXPCConnection() throws -> xpc_connection_t {
        throw BrowserEngineKitHostError.xpcUnavailable
    }

    public func grantCapability(_ capability: ProcessCapability) throws -> ProcessCapability.Grant {
        _ = capability
        throw BrowserEngineKitHostError.processUnavailable
    }

    public func grantCapability(
        _ capability: ProcessCapability,
        invalidationHandler: @escaping () -> Void
    ) throws -> ProcessCapability.Grant {
        _ = capability
        _ = invalidationHandler
        throw BrowserEngineKitHostError.processUnavailable
    }
}

public struct RenderingProcess {
    public private(set) var isInvalidated = false

    public static func host_makeUnavailable() -> RenderingProcess {
        RenderingProcess()
    }

    public init(bundleIdentifier: String? = nil, onInterruption: @escaping () -> Void) async throws {
        _ = bundleIdentifier
        _ = onInterruption
        throw BrowserEngineKitHostError.processUnavailable
    }

    private init() {}

    public mutating func invalidate() {
        isInvalidated = true
    }

    public func makeLibXPCConnection() throws -> xpc_connection_t {
        throw BrowserEngineKitHostError.xpcUnavailable
    }

    public func grantCapability(_ capability: ProcessCapability) throws -> ProcessCapability.Grant {
        _ = capability
        throw BrowserEngineKitHostError.processUnavailable
    }

    public func grantCapability(
        _ capability: ProcessCapability,
        invalidationHandler: @escaping () -> Void
    ) throws -> ProcessCapability.Grant {
        _ = capability
        _ = invalidationHandler
        throw BrowserEngineKitHostError.processUnavailable
    }

    public func createVisibilityPropagationInteraction() -> any UIInteraction {
        BEHostInteraction()
    }
}

public struct RenderingExtensionConfiguration: Sendable {
    public init() {}

    /// Linux has no extension process. Always returns `false`.
    public func accept(connection: NSXPCConnection) -> Bool {
        _ = connection
        return false
    }
}

public struct NetworkingExtensionConfiguration: Sendable {
    public init() {}

    public func accept(connection: NSXPCConnection) -> Bool {
        _ = connection
        return false
    }
}

public struct WebContentExtensionConfiguration: Sendable {
    public init() {}

    public func accept(connection: NSXPCConnection) -> Bool {
        _ = connection
        return false
    }
}

public protocol RenderingExtension: RestrictedSandboxAppliable, AppExtension
where Configuration == RenderingExtensionConfiguration {
    func handle(xpcConnection: xpc_connection_t)
}

extension RenderingExtension {
    public var configuration: RenderingExtensionConfiguration {
        RenderingExtensionConfiguration()
    }
}

public protocol NetworkingExtension: RestrictedSandboxAppliable, AppExtension
where Configuration == NetworkingExtensionConfiguration {
    func handle(xpcConnection: xpc_connection_t)
}

extension NetworkingExtension {
    public var configuration: NetworkingExtensionConfiguration {
        NetworkingExtensionConfiguration()
    }
}

public protocol WebContentExtension: RestrictedSandboxAppliable, AppExtension
where Configuration == WebContentExtensionConfiguration {
    func handle(xpcConnection: xpc_connection_t)
}

extension WebContentExtension {
    public var configuration: WebContentExtensionConfiguration {
        WebContentExtensionConfiguration()
    }
}
