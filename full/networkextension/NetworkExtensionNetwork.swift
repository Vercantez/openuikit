#if canImport(Network)
import Network
#endif
#if canImport(Security)
import Security
#endif

open class NWEndpoint: NSObject, NSCopying {
    open func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return NWEndpoint()
    }
}

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

    open override func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return NWHostEndpoint(hostname: hostname, port: port)
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

    open override func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return NWBonjourServiceEndpoint(name: name, type: type, domain: domain)
    }
}

open class NWPath: NSObject {
    public let status: NWPathStatus
    public let isExpensive: Bool
    public let isConstrained: Bool

    @_spi(OpenUIKitHost)
    public init(
        status: NWPathStatus,
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
#if canImport(Security)
    func evaluateTrust(
        for connection: NWTCPConnection,
        peerCertificateChain: [Any],
        completionHandler completion: @escaping (SecTrust) -> Void
    )
    func provideIdentity(
        for connection: NWTCPConnection,
        completionHandler completion: @escaping (SecIdentity, [Any]) -> Void
    )
#endif
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
    private let lock = NSLock()
    private var cancelled = false
    private var pending = [_NEOnceDelivery<(Data?, (any Error)?)>]()
    private var writePending = [_NEOnceDelivery<(any Error)?>]()
    private var _state: NWTCPConnectionState = .disconnected

    public let endpoint: NWEndpoint
    open var state: NWTCPConnectionState {
        lock.lock()
        defer { lock.unlock() }
        return _state
    }

    open var error: (any Error)? {
        _NEHostBoundary.appProxyError(.notConnected)
    }

    open var connectedPath: NWPath? { nil }
    open var hasBetterPath: Bool { false }
    open var localAddress: NWEndpoint? { nil }
    open var remoteAddress: NWEndpoint? { nil }
    open var txtRecord: Data? { nil }
    open var isViable: Bool { false }

    @_spi(OpenUIKitHost)
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

    open func cancel() {
        lock.lock()
        cancelled = true
        _state = .cancelled
        let reads = pending
        pending.removeAll()
        let writes = writePending
        writePending.removeAll()
        lock.unlock()
        let error = _NEHostBoundary.appProxyError(.aborted)
        for item in reads {
            item.schedule((nil, error))
        }
        for item in writes {
            item.schedule(error)
        }
    }

    open func writeClose() {}

    open func readLength(
        _ length: Int,
        completionHandler completion: @escaping (Data?, (any Error)?) -> Void
    ) {
        _ = length
        scheduleRead(completion)
    }

    open func readMinimumLength(
        _ minimum: Int,
        maximumLength maximum: Int,
        completionHandler completion: @escaping (Data?, (any Error)?) -> Void
    ) {
        _ = (minimum, maximum)
        scheduleRead(completion)
    }

    open func write(
        _ data: Data,
        completionHandler completion: @escaping ((any Error)?) -> Void
    ) {
        _ = data
        let delivery = _NEOnceDelivery(completion)
        lock.lock()
        let isCancelled = cancelled
        if !isCancelled {
            writePending.append(delivery)
        }
        lock.unlock()
        NetworkExtensionHostCallback.schedule { [weak self] in
            guard let self else {
                delivery.deliver(_NEHostBoundary.appProxyError(.aborted))
                return
            }
            self.lock.lock()
            let cancelled = self.cancelled
            self.writePending.removeAll { $0 === delivery }
            self.lock.unlock()
            delivery.deliver(
                cancelled
                    ? _NEHostBoundary.appProxyError(.aborted)
                    : _NEHostBoundary.appProxyError(.notConnected)
            )
        }
    }

    private func scheduleRead(
        _ completion: @escaping (Data?, (any Error)?) -> Void
    ) {
        let delivery = _NEOncePair(completion)
        lock.lock()
        let isCancelled = cancelled
        if !isCancelled {
            pending.append(delivery)
        }
        lock.unlock()
        NetworkExtensionHostCallback.schedule { [weak self] in
            guard let self else {
                delivery.deliver((nil, _NEHostBoundary.appProxyError(.aborted)))
                return
            }
            self.lock.lock()
            let cancelled = self.cancelled
            self.pending.removeAll { $0 === delivery }
            self.lock.unlock()
            delivery.deliver(
                (
                    nil,
                    cancelled
                        ? _NEHostBoundary.appProxyError(.aborted)
                        : _NEHostBoundary.appProxyError(.notConnected)
                )
            )
        }
    }
}

open class NWUDPSession: NSObject {
    private let lock = NSLock()
    private var cancelled = false
    private var _state: NWUDPSessionState = .failed
    private var readDelivery: _NEOnceDelivery<([Data]?, (any Error)?)>?

    public let endpoint: NWEndpoint
    open var state: NWUDPSessionState {
        lock.lock()
        defer { lock.unlock() }
        return _state
    }

    open var currentPath: NWPath? { nil }
    open var hasBetterPath: Bool { false }
    open var maximumDatagramLength: Int { 0 }
    open var resolvedEndpoint: NWEndpoint? { nil }
    open var isViable: Bool { false }

    @_spi(OpenUIKitHost)
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

    open func cancel() {
        lock.lock()
        cancelled = true
        _state = .cancelled
        let pending = readDelivery
        readDelivery = nil
        lock.unlock()
        pending?.schedule((nil, _NEHostBoundary.appProxyError(.aborted)))
    }

    open func tryNextResolvedEndpoint() {}

    open func setReadHandler(
        _ handler: @escaping ([Data]?, (any Error)?) -> Void,
        maxDatagrams: Int
    ) {
        _ = maxDatagrams
        let delivery = _NEOncePair(handler)
        lock.lock()
        readDelivery = delivery
        let isCancelled = cancelled
        lock.unlock()
        NetworkExtensionHostCallback.schedule { [weak self] in
            guard let self else {
                delivery.deliver((nil, _NEHostBoundary.appProxyError(.aborted)))
                return
            }
            self.lock.lock()
            let cancelled = self.cancelled
            if self.readDelivery === delivery {
                self.readDelivery = nil
            }
            self.lock.unlock()
            delivery.deliver(
                (
                    nil,
                    cancelled
                        ? _NEHostBoundary.appProxyError(.aborted)
                        : _NEHostBoundary.appProxyError(.notConnected)
                )
            )
        }
        _ = isCancelled
    }

    open func writeDatagram(
        _ datagram: Data,
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _ = datagram
        _NEOnceDelivery(completionHandler).schedule(
            _NEHostBoundary.appProxyError(.notConnected)
        )
    }

    open func writeMultipleDatagrams(
        _ datagramArray: [Data],
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _ = datagramArray
        _NEOnceDelivery(completionHandler).schedule(
            _NEHostBoundary.appProxyError(.notConnected)
        )
    }
}
