open class NWEndpoint: NSObject {}

open class NWHostEndpoint: NWEndpoint {
    public let hostname: String
    public let port: String

    public convenience init(hostname: String, port: String) {
        self.init(storedHostname: hostname, storedPort: port)
    }

    init(storedHostname: String, storedPort: String) {
        hostname = storedHostname
        port = storedPort
        super.init()
    }
}

open class NWBonjourServiceEndpoint: NWEndpoint {
    public let name: String
    public let type: String
    public let domain: String

    public convenience init(name: String, type: String, domain: String) {
        self.init(storedName: name, storedType: type, storedDomain: domain)
    }

    init(storedName: String, storedType: String, storedDomain: String) {
        name = storedName
        type = storedType
        domain = storedDomain
        super.init()
    }
}

open class NWPath: NSObject {
    public let status: NWPathStatus
    public let isExpensive: Bool
    public let isConstrained: Bool

    public init(
        status: NWPathStatus = .unsatisfied,
        isExpensive: Bool = false,
        isConstrained: Bool = false
    ) {
        self.status = status
        self.isExpensive = isExpensive
        self.isConstrained = isConstrained
        super.init()
    }

    open func isEqual(to path: NWPath) -> Bool {
        status == path.status
            && isExpensive == path.isExpensive
            && isConstrained == path.isConstrained
    }
}

open class NWTLSParameters: NSObject {
    open var sslCipherSuites: Set<NSNumber>?
    open var tlsSessionID: Data?
    open var maximumSSLProtocolVersion: Int = 0
    open var minimumSSLProtocolVersion: Int = 0
}

public protocol NWTCPConnectionAuthenticationDelegate: NSObjectProtocol {
    func shouldEvaluateTrust(for connection: NWTCPConnection) -> Bool
    func shouldProvideIdentity(for connection: NWTCPConnection) -> Bool
}

extension NWTCPConnectionAuthenticationDelegate {
    public func shouldEvaluateTrust(for connection: NWTCPConnection) -> Bool {
        _ = connection
        return false
    }

    public func shouldProvideIdentity(for connection: NWTCPConnection) -> Bool {
        _ = connection
        return false
    }
}

open class NWTCPConnection: NSObject {
    public let endpoint: NWEndpoint
    open var state: NWTCPConnectionState { .disconnected }
    open var error: (any Error)? {
        _NEHostBoundary.nsError(domain: NEAppProxyErrorDomain, code: NEAppProxyFlowError.notConnected.rawValue)
    }
    open var connectedPath: NWPath? { nil }
    open var hasBetterPath: Bool { false }
    open var localAddress: NWEndpoint? { nil }
    open var remoteAddress: NWEndpoint? { nil }
    open var txtRecord: Data? { nil }
    open var isViable: Bool { false }

    public init(endpoint: NWEndpoint) {
        self.endpoint = endpoint
        super.init()
    }

    public convenience init(upgradeFor connection: NWTCPConnection) {
        self.init(endpoint: connection.endpoint)
    }

    public convenience init(upgradeForConnection connection: NWTCPConnection) {
        self.init(upgradeFor: connection)
    }

    open func cancel() {}

    open func writeClose() {}

    open func readLength(
        _ length: Int,
        completionHandler completion: @escaping (Data?, (any Error)?) -> Void
    ) {
        _ = length
        completion(nil, _NEHostBoundary.appProxyError(.notConnected))
    }

    open func readMinimumLength(
        _ minimum: Int,
        maximumLength maximum: Int,
        completionHandler completion: @escaping (Data?, (any Error)?) -> Void
    ) {
        _ = (minimum, maximum)
        completion(nil, _NEHostBoundary.appProxyError(.notConnected))
    }

    open func write(
        _ data: Data,
        completionHandler completion: @escaping ((any Error)?) -> Void
    ) {
        _ = data
        completion(_NEHostBoundary.appProxyError(.notConnected))
    }
}

open class NWUDPSession: NSObject {
    public let endpoint: NWEndpoint
    open var state: NWUDPSessionState { .failed }
    open var currentPath: NWPath? { nil }
    open var hasBetterPath: Bool { false }
    open var maximumDatagramLength: Int { 0 }
    open var resolvedEndpoint: NWEndpoint? { nil }
    open var isViable: Bool { false }

    public init(endpoint: NWEndpoint) {
        self.endpoint = endpoint
        super.init()
    }

    public convenience init(upgradeFor session: NWUDPSession) {
        self.init(endpoint: session.endpoint)
    }

    public convenience init(upgradeForSession session: NWUDPSession) {
        self.init(upgradeFor: session)
    }

    open func cancel() {}

    open func tryNextResolvedEndpoint() {}

    open func setReadHandler(
        _ handler: @escaping ([Data]?, (any Error)?) -> Void,
        maxDatagrams: Int
    ) {
        _ = maxDatagrams
        handler(nil, _NEHostBoundary.appProxyError(.notConnected))
    }

    open func writeDatagram(
        _ datagram: Data,
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _ = datagram
        completionHandler(_NEHostBoundary.appProxyError(.notConnected))
    }

    open func writeMultipleDatagrams(
        _ datagramArray: [Data],
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _ = datagramArray
        completionHandler(_NEHostBoundary.appProxyError(.notConnected))
    }
}
