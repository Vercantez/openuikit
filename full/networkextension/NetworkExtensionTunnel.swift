#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif
#if canImport(Network)
import Network
#endif

open class NEFlowMetaData: NSObject, NSCopying {
    public let sourceAppSigningIdentifier: String
    public let sourceAppUniqueIdentifier: Data

    @_spi(OpenUIKitHost)
    public init(sourceAppSigningIdentifier: String, sourceAppUniqueIdentifier: Data) {
        self.sourceAppSigningIdentifier = sourceAppSigningIdentifier
        self.sourceAppUniqueIdentifier = sourceAppUniqueIdentifier
        super.init()
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return NEFlowMetaData(
            sourceAppSigningIdentifier: sourceAppSigningIdentifier,
            sourceAppUniqueIdentifier: sourceAppUniqueIdentifier
        )
    }
}

open class NEPacket: NSObject, NSCopying {
    public let data: Data
    public let protocolFamily: sa_family_t
    open var metadata: NEFlowMetaData? { nil }

    public init(data: Data, protocolFamily: sa_family_t) {
        self.data = data
        self.protocolFamily = protocolFamily
        super.init()
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return NEPacket(data: data, protocolFamily: protocolFamily)
    }
}

open class NEPacketTunnelFlow: NSObject {
    open func readPacketObjects(completionHandler: @escaping ([NEPacket]) -> Void) {
        _NEOnceDelivery(completionHandler).schedule([])
    }

    open func readPackets(completionHandler: @escaping ([Data], [NSNumber]) -> Void) {
        _NEOnceDelivery { (pair: ([Data], [NSNumber])) in
            completionHandler(pair.0, pair.1)
        }.schedule(([], []))
    }

    open func writePacketObjects(_ packets: [NEPacket]) -> Bool {
        _ = packets
        return false
    }

    open func writePackets(_ packets: [Data], withProtocols protocols: [NSNumber]) -> Bool {
        _ = (packets, protocols)
        return false
    }
}

open class NEProvider: NSObject {
    open var defaultPath: NWPath? {
        NWPath(status: .unsatisfied)
    }

    open func createTCPConnection(
        to remoteEndpoint: NWEndpoint,
        enableTLS: Bool,
        tlsParameters TLSParameters: NWTLSParameters?,
        delegate: Any?
    ) -> NWTCPConnection {
        _ = (enableTLS, TLSParameters, delegate)
        return NWTCPConnection(endpoint: remoteEndpoint)
    }

    open func createUDPSession(
        to remoteEndpoint: NWEndpoint,
        from localEndpoint: NWHostEndpoint?
    ) -> NWUDPSession {
        _ = localEndpoint
        return NWUDPSession(endpoint: remoteEndpoint)
    }

    open func displayMessage(
        _ message: String,
        completionHandler: @escaping (Bool) -> Void
    ) {
        _ = message
        _NEOnceDelivery(completionHandler).schedule(false)
    }

    open func sleep(completionHandler: @escaping () -> Void) {
        _NEOnceDelivery { (_: Void) in
            completionHandler()
        }.schedule(())
    }

    open func wake() {}
}

open class NETunnelProvider: NEProvider {
    open var appRules: [NEAppRule]? { nil }
    open var protocolConfiguration: NEVPNProtocol { NEVPNProtocol() }
    open var reasserting = false
    open var routingMethod: NETunnelProviderRoutingMethod { .destinationIP }

    open func handleAppMessage(_ messageData: Data) async -> Data? {
        _ = messageData
        return nil
    }

    open func setTunnelNetworkSettings(
        _ tunnelNetworkSettings: NETunnelNetworkSettings?
    ) async throws {
        if let tunnelNetworkSettings {
            try tunnelNetworkSettings.validateForTunnel()
        }
        throw _NEHostBoundary.tunnelError(.networkSettingsFailed)
    }
}

open class NEPacketTunnelProvider: NETunnelProvider {
    private let _packetFlow = NEPacketTunnelFlow()

    open var packetFlow: NEPacketTunnelFlow { _packetFlow }

#if canImport(Network)
    open var virtualInterface: Network.NWInterface? { nil }
#endif

    open func startTunnel(options: [String: NSObject]? = nil) async throws {
        _ = options
        throw _NEHostBoundary.vpnError(.connectionFailed)
    }

    open func stopTunnel(with reason: NEProviderStopReason) async {
        _ = reason
    }

    open func cancelTunnelWithError(_ error: (any Error)?) {
        _ = error
    }

    open func createTCPConnectionThroughTunnel(
        to remoteEndpoint: NWEndpoint,
        enableTLS: Bool,
        tlsParameters TLSParameters: NWTLSParameters?,
        delegate: Any?
    ) -> NWTCPConnection {
        createTCPConnection(
            to: remoteEndpoint,
            enableTLS: enableTLS,
            tlsParameters: TLSParameters,
            delegate: delegate
        )
    }

    open func createUDPSessionThroughTunnel(
        to remoteEndpoint: NWEndpoint,
        from localEndpoint: NWHostEndpoint?
    ) -> NWUDPSession {
        createUDPSession(to: remoteEndpoint, from: localEndpoint)
    }
}

open class NEAppProxyFlow: NSObject {
    private let _metaData: NEFlowMetaData

    public override init() {
        _metaData = NEFlowMetaData(
            sourceAppSigningIdentifier: "",
            sourceAppUniqueIdentifier: Data()
        )
        super.init()
    }

    open var isBound: Bool { false }
    open var metaData: NEFlowMetaData { _metaData }
    open var remoteHostname: String? { nil }

#if canImport(Network)
    open var interface: Network.NWInterface?
    open func setMetadata(on parameters: Network.NWParameters) {
        _ = parameters
    }
#endif

    open func closeReadWithError(_ error: (any Error)?) {
        _ = error
    }

    open func closeWriteWithError(_ error: (any Error)?) {
        _ = error
    }

    open func open(withLocalEndpoint localEndpoint: NWHostEndpoint?) async throws {
        _ = localEndpoint
        throw _NEHostBoundary.appProxyError(.notConnected)
    }

    open func open(
        withLocalFlowEndpoint localEndpoint: NWEndpoint?,
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _ = localEndpoint
        _NEOnceDelivery(completionHandler).schedule(
            _NEHostBoundary.appProxyError(.notConnected)
        )
    }

    open func open(withLocalFlowEndpoint localEndpoint: NWEndpoint?) async throws {
        _ = localEndpoint
        throw _NEHostBoundary.appProxyError(.notConnected)
    }
}

open class NEAppProxyTCPFlow: NEAppProxyFlow {
    open var remoteEndpoint: NWEndpoint {
        NWHostEndpoint(hostname: "", port: "0")
    }

    open var remoteFlowEndpoint: NWEndpoint { remoteEndpoint }

    open func readData(completionHandler: @escaping (Data?, (any Error)?) -> Void) {
        _NEOncePair(completionHandler).schedule(
            (nil, _NEHostBoundary.appProxyError(.notConnected))
        )
    }

    open func write(_ data: Data) async throws {
        _ = data
        throw _NEHostBoundary.appProxyError(.notConnected)
    }
}

open class NEAppProxyUDPFlow: NEAppProxyFlow {
    open var localEndpoint: NWEndpoint? { nil }
    open var localFlowEndpoint: NWEndpoint? { localEndpoint }

    open func readDatagrams() async -> ([(Data, NWEndpoint)]?, (any Error)?) {
        (nil, _NEHostBoundary.appProxyError(.notConnected))
    }

    open func writeDatagrams(_ array: [(Data, NWEndpoint)]) async throws {
        _ = array
        throw _NEHostBoundary.appProxyError(.notConnected)
    }

    open func writeDatagrams(
        _ array: [(Data, NWEndpoint)],
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _ = array
        _NEOnceDelivery(completionHandler).schedule(
            _NEHostBoundary.appProxyError(.notConnected)
        )
    }

    open func writeDatagrams(
        _ datagrams: [Data],
        sentBy remoteEndpoints: [NWEndpoint]
    ) async throws {
        _ = (datagrams, remoteEndpoints)
        throw _NEHostBoundary.appProxyError(.notConnected)
    }
}

public protocol NEAppProxyUDPFlowHandling {
    func handleNewUDPFlow(
        _ flow: NEAppProxyUDPFlow,
        initialRemoteFlowEndpoint remoteEndpoint: NWEndpoint
    ) -> Bool
}

open class NEAppProxyProvider: NETunnelProvider {
    open func startProxy(options: [String: Any]? = nil) async throws {
        _ = options
        throw _NEHostBoundary.vpnError(.connectionFailed)
    }

    open func stopProxy(with reason: NEProviderStopReason) async {
        _ = reason
    }

    open func cancelProxyWithError(_ error: (any Error)?) {
        _ = error
    }

    open func handleNewFlow(_ flow: NEAppProxyFlow) -> Bool {
        _ = flow
        return false
    }

    open func handleNewUDPFlow(
        _ flow: NEAppProxyUDPFlow,
        initialRemoteEndpoint remoteEndpoint: NWEndpoint
    ) -> Bool {
        _ = (flow, remoteEndpoint)
        return false
    }
}

open class NEDNSProxyProvider: NEProvider {
    open var systemDNSSettings: [NEDNSSettings]? { nil }

    open func startProxy(options: [String: Any]? = nil) async throws {
        _ = options
        throw _NEHostBoundary.nsError(
            domain: NEDNSProxyErrorDomain,
            code: NEDNSProxyManagerError.configurationInvalid.rawValue
        )
    }

    open func stopProxy(with reason: NEProviderStopReason) async {
        _ = reason
    }

    open func cancelProxyWithError(_ error: (any Error)?) {
        _ = error
    }

    open func handleNewFlow(_ flow: NEAppProxyFlow) -> Bool {
        _ = flow
        return false
    }

    open func handleNewUDPFlow(
        _ flow: NEAppProxyUDPFlow,
        initialRemoteEndpoint remoteEndpoint: NWEndpoint
    ) -> Bool {
        _ = (flow, remoteEndpoint)
        return false
    }
}
