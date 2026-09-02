open class NEVPNConnection: NSObject {
    private unowned let _manager: NEVPNManager
    private var lastDisconnectError: (any Error)? = _NEHostBoundary.vpnError(.connectionFailed)

    init(manager: NEVPNManager) {
        _manager = manager
        super.init()
    }

    open var manager: NEVPNManager { _manager }
    open var status: NEVPNStatus { .invalid }
    open var connectedDate: Date? { nil }

    open func startVPNTunnel() throws {
        try startVPNTunnel(options: nil)
    }

    open func startVPNTunnel(options: [String: NSObject]? = nil) throws {
        _ = options
        throw _NEHostBoundary.vpnError(.connectionFailed)
    }

    open func stopVPNTunnel() {}

    open func fetchLastDisconnectError(
        completionHandler handler: @escaping ((any Error)?) -> Void
    ) {
        _NEOnceDelivery(handler).schedule(lastDisconnectError)
    }
}

open class NETunnelProviderSession: NEVPNConnection {
    open func startTunnel(options: [String: Any]? = nil) throws {
        _ = options
        throw _NEHostBoundary.vpnError(.connectionFailed)
    }

    open func stopTunnel() {
        stopVPNTunnel()
    }

    open func sendProviderMessage(
        _ messageData: Data,
        responseHandler: ((Data?) -> Void)? = nil
    ) throws {
        _ = messageData
        throw _NEHostBoundary.vpnError(.configurationInvalid)
    }
}

open class NEVPNManager: NSObject {
    private static let _shared = NEVPNManager()
    private var _connection: NEVPNConnection!

    open class func shared() -> NEVPNManager { _shared }

    public override init() {
        super.init()
        _connection = NEVPNConnection(manager: self)
    }

    fileprivate func installConnection(_ connection: NEVPNConnection) {
        _connection = connection
    }

    open var connection: NEVPNConnection { _connection }
    open var isEnabled = false
    open var localizedDescription: String?
    open var isOnDemandEnabled = false
    open var onDemandRules: [NEOnDemandRule]?
    open var protocolConfiguration: NEVPNProtocol?

    open var `protocol`: NEVPNProtocol? {
        get { protocolConfiguration }
        set { protocolConfiguration = newValue }
    }

    open func loadFromPreferences(
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _NEHostBoundary.complete(
            completionHandler,
            _NEHostBoundary.vpnError(.configurationReadWriteFailed)
        )
    }

    open func saveToPreferences(
        completionHandler: (((any Error)?) -> Void)? = nil
    ) {
        _NEHostBoundary.completeOptional(
            completionHandler,
            _NEHostBoundary.vpnError(.configurationReadWriteFailed)
        )
    }

    open func removeFromPreferences(
        completionHandler: (((any Error)?) -> Void)? = nil
    ) {
        _NEHostBoundary.completeOptional(
            completionHandler,
            _NEHostBoundary.vpnError(.configurationReadWriteFailed)
        )
    }
}

open class NETunnelProviderManager: NEVPNManager {
    public override init() {
        super.init()
        installConnection(NETunnelProviderSession(manager: self))
    }

    open var routingMethod: NETunnelProviderRoutingMethod { .destinationIP }

    open class func loadAllFromPreferences(
        completionHandler: @escaping ([NETunnelProviderManager]?, (any Error)?) -> Void
    ) {
        _NEOnceDelivery { (pair: ([NETunnelProviderManager]?, (any Error)?)) in
            completionHandler(pair.0, pair.1)
        }.schedule((nil, _NEHostBoundary.vpnError(.configurationReadWriteFailed)))
    }

    open func copyAppRules() -> [NEAppRule]? { nil }
}

open class NEAppProxyProviderManager: NETunnelProviderManager {
    open class func loadAllFromPreferences(
        completionHandler: @escaping ([NEAppProxyProviderManager]?, (any Error)?) -> Void
    ) {
        _NEOnceDelivery { (pair: ([NEAppProxyProviderManager]?, (any Error)?)) in
            completionHandler(pair.0, pair.1)
        }.schedule((nil, _NEHostBoundary.vpnError(.configurationReadWriteFailed)))
    }
}

open class NEDNSSettingsManager: NSObject {
    private static let _shared = NEDNSSettingsManager()

    open class func shared() -> NEDNSSettingsManager { _shared }

    open var dnsSettings: NEDNSSettings?
    open var isEnabled: Bool { false }
    open var localizedDescription: String?
    open var onDemandRules: [NEOnDemandRule]?

    open func loadFromPreferences(
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _NEHostBoundary.complete(
            completionHandler,
            _NEHostBoundary.nsError(
                domain: NEDNSSettingsErrorDomain,
                code: NEDNSSettingsManagerError.configurationInvalid.rawValue
            )
        )
    }

    open func saveToPreferences(
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _NEHostBoundary.complete(
            completionHandler,
            _NEHostBoundary.nsError(
                domain: NEDNSSettingsErrorDomain,
                code: NEDNSSettingsManagerError.configurationInvalid.rawValue
            )
        )
    }

    open func removeFromPreferences(
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _NEHostBoundary.complete(
            completionHandler,
            _NEHostBoundary.nsError(
                domain: NEDNSSettingsErrorDomain,
                code: NEDNSSettingsManagerError.configurationCannotBeRemoved.rawValue
            )
        )
    }
}

open class NEDNSProxyManager: NSObject {
    private static let _shared = NEDNSProxyManager()

    open class func shared() -> NEDNSProxyManager { _shared }

    open var isEnabled = false
    open var localizedDescription: String?
    open var providerProtocol: NEDNSProxyProviderProtocol?

    open func loadFromPreferences(
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _NEHostBoundary.complete(
            completionHandler,
            _NEHostBoundary.nsError(
                domain: NEDNSProxyErrorDomain,
                code: NEDNSProxyManagerError.configurationInvalid.rawValue
            )
        )
    }

    open func saveToPreferences(
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _NEHostBoundary.complete(
            completionHandler,
            _NEHostBoundary.nsError(
                domain: NEDNSProxyErrorDomain,
                code: NEDNSProxyManagerError.configurationInvalid.rawValue
            )
        )
    }

    open func removeFromPreferences(
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _NEHostBoundary.complete(
            completionHandler,
            _NEHostBoundary.nsError(
                domain: NEDNSProxyErrorDomain,
                code: NEDNSProxyManagerError.configurationCannotBeRemoved.rawValue
            )
        )
    }
}

open class NERelay: NSObject, NSCopying {
    open var http2RelayURL: URL?
    open var http3RelayURL: URL?
    open var additionalHTTPHeaderFields: [String: String] = [:]
    open var dnsOverHTTPSURL: URL?
    open var identityData: Data?
    open var identityDataPassword: String?
    open var rawPublicKeys: [Data]?
    open var syntheticDNSAnswerIPv4Prefix: String?
    open var syntheticDNSAnswerIPv6Prefix: String?

    open func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = NERelay()
        copy.http2RelayURL = http2RelayURL
        copy.http3RelayURL = http3RelayURL
        copy.additionalHTTPHeaderFields = additionalHTTPHeaderFields
        copy.dnsOverHTTPSURL = dnsOverHTTPSURL
        copy.identityData = identityData
        copy.identityDataPassword = identityDataPassword
        copy.rawPublicKeys = rawPublicKeys
        copy.syntheticDNSAnswerIPv4Prefix = syntheticDNSAnswerIPv4Prefix
        copy.syntheticDNSAnswerIPv6Prefix = syntheticDNSAnswerIPv6Prefix
        return copy
    }
}

open class NERelayManager: NSObject {
    private static let _shared = NERelayManager()

    open class func shared() -> NERelayManager { _shared }

    open var isUIToggleEnabled = false
    open var isDNSFailoverAllowed = false
    open var isEnabled = false
    open var excludedDomains: [String]?
    open var excludedFQDNs: [String]?
    open var localizedDescription: String?
    open var matchDomains: [String]?
    open var matchFQDNs: [String]?
    open var onDemandRules: [NEOnDemandRule]?
    open var relays: [NERelay]?

    open class func loadAllManagersFromPreferences(
        completionHandler: @escaping ([NERelayManager], (any Error)?) -> Void
    ) {
        _NEOnceDelivery { (pair: ([NERelayManager], (any Error)?)) in
            completionHandler(pair.0, pair.1)
        }.schedule(
            (
                [],
                _NEHostBoundary.nsError(
                    domain: NERelayErrorDomain,
                    code: NERelayManagerError.configurationInvalid.rawValue
                )
            )
        )
    }

    open func loadFromPreferences(
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _NEHostBoundary.complete(
            completionHandler,
            _NEHostBoundary.nsError(
                domain: NERelayErrorDomain,
                code: NERelayManagerError.configurationInvalid.rawValue
            )
        )
    }

    open func saveToPreferences(
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _NEHostBoundary.complete(
            completionHandler,
            _NEHostBoundary.nsError(
                domain: NERelayErrorDomain,
                code: NERelayManagerError.configurationInvalid.rawValue
            )
        )
    }

    open func removeFromPreferences(
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _NEHostBoundary.complete(
            completionHandler,
            _NEHostBoundary.nsError(
                domain: NERelayErrorDomain,
                code: NERelayManagerError.configurationCannotBeRemoved.rawValue
            )
        )
    }

    open func getLastClientErrors(
        _ seconds: TimeInterval,
        completionHandler: @escaping ([any Error]?) -> Void
    ) {
        _ = seconds
        _NEOnceDelivery(completionHandler).schedule(nil)
    }
}
