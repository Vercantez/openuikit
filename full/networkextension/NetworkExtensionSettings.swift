open class NEProxyServer: NSObject, NSCopying, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public let address: String
    public let port: Int
    open var authenticationRequired = false
    open var username: String?
    open var password: String?

    public init(address: String, port: Int) {
        self.address = address
        self.port = port
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard let address = _NEDecodeString(coder, "address") else { return nil }
        self.address = address
        self.port = Int(coder.decodeInt64(forKey: "port"))
        super.init()
        authenticationRequired = coder.decodeBool(forKey: "authenticationRequired")
        username = _NEDecodeString(coder, "username")
        password = _NEDecodeString(coder, "password")
    }

    open func encode(with coder: NSCoder) {
        _NEEncodeString(coder, "address", address)
        _NEEncodeInt64(coder, "port", Int64(port))
        _NEEncodeBool(coder, "authenticationRequired", authenticationRequired)
        _NEEncodeString(coder, "username", username)
        _NEEncodeString(coder, "password", password)
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = NEProxyServer(address: address, port: port)
        copy.authenticationRequired = authenticationRequired
        copy.username = username
        copy.password = password
        return copy
    }
}

open class NEProxySettings: NSObject, NSCopying, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    open var httpEnabled = false
    open var httpsEnabled = false
    open var httpServer: NEProxyServer?
    open var httpsServer: NEProxyServer?
    open var autoProxyConfigurationEnabled = false
    open var exceptionList: [String]?
    open var excludeSimpleHostnames = false
    open var matchDomains: [String]?
    open var proxyAutoConfigurationJavaScript: String?
    open var proxyAutoConfigurationURL: URL?

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        super.init()
        httpEnabled = coder.decodeBool(forKey: "httpEnabled")
        httpsEnabled = coder.decodeBool(forKey: "httpsEnabled")
        httpServer = _NEDecodeObject(NEProxyServer.self, coder, "httpServer")
        httpsServer = _NEDecodeObject(NEProxyServer.self, coder, "httpsServer")
        autoProxyConfigurationEnabled = coder.decodeBool(forKey: "autoProxyConfigurationEnabled")
        exceptionList = _NEDecodeStringArray(coder, "exceptionList")
        excludeSimpleHostnames = coder.decodeBool(forKey: "excludeSimpleHostnames")
        matchDomains = _NEDecodeStringArray(coder, "matchDomains")
        proxyAutoConfigurationJavaScript = _NEDecodeString(coder, "proxyAutoConfigurationJavaScript")
        proxyAutoConfigurationURL = _NEDecodeURL(coder, "proxyAutoConfigurationURL")
    }

    open func encode(with coder: NSCoder) {
        _NEEncodeBool(coder, "httpEnabled", httpEnabled)
        _NEEncodeBool(coder, "httpsEnabled", httpsEnabled)
        _NEEncodeObject(coder, "httpServer", httpServer)
        _NEEncodeObject(coder, "httpsServer", httpsServer)
        _NEEncodeBool(coder, "autoProxyConfigurationEnabled", autoProxyConfigurationEnabled)
        _NEEncodeStringArray(coder, "exceptionList", exceptionList)
        _NEEncodeBool(coder, "excludeSimpleHostnames", excludeSimpleHostnames)
        _NEEncodeStringArray(coder, "matchDomains", matchDomains)
        _NEEncodeString(coder, "proxyAutoConfigurationJavaScript", proxyAutoConfigurationJavaScript)
        _NEEncodeURL(coder, "proxyAutoConfigurationURL", proxyAutoConfigurationURL)
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = NEProxySettings()
        copy.httpEnabled = httpEnabled
        copy.httpsEnabled = httpsEnabled
        copy.httpServer = _NECopiedObject(httpServer)
        copy.httpsServer = _NECopiedObject(httpsServer)
        copy.autoProxyConfigurationEnabled = autoProxyConfigurationEnabled
        copy.exceptionList = exceptionList
        copy.excludeSimpleHostnames = excludeSimpleHostnames
        copy.matchDomains = matchDomains
        copy.proxyAutoConfigurationJavaScript = proxyAutoConfigurationJavaScript
        copy.proxyAutoConfigurationURL = proxyAutoConfigurationURL
        return copy
    }
}

open class NEIPv4Route: NSObject, NSCopying, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public let destinationAddress: String
    public let destinationSubnetMask: String
    open var gatewayAddress: String?

    public init(destinationAddress address: String, subnetMask: String) {
        destinationAddress = address
        destinationSubnetMask = subnetMask
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard
            let destination = _NEDecodeString(coder, "destinationAddress"),
            let mask = _NEDecodeString(coder, "destinationSubnetMask")
        else {
            return nil
        }
        destinationAddress = destination
        destinationSubnetMask = mask
        super.init()
        gatewayAddress = _NEDecodeString(coder, "gatewayAddress")
    }

    open func encode(with coder: NSCoder) {
        _NEEncodeString(coder, "destinationAddress", destinationAddress)
        _NEEncodeString(coder, "destinationSubnetMask", destinationSubnetMask)
        _NEEncodeString(coder, "gatewayAddress", gatewayAddress)
    }

    open class func `default`() -> NEIPv4Route {
        NEIPv4Route(destinationAddress: "0.0.0.0", subnetMask: "0.0.0.0")
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = NEIPv4Route(
            destinationAddress: destinationAddress,
            subnetMask: destinationSubnetMask
        )
        copy.gatewayAddress = gatewayAddress
        return copy
    }
}

open class NEIPv6Route: NSObject, NSCopying, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public let destinationAddress: String
    public let destinationNetworkPrefixLength: NSNumber
    open var gatewayAddress: String?

    public init(destinationAddress address: String, networkPrefixLength: NSNumber) {
        destinationAddress = address
        destinationNetworkPrefixLength = networkPrefixLength
        super.init()
    }

    public required init?(coder: NSCoder) {
        guard
            let destination = _NEDecodeString(coder, "destinationAddress"),
            let prefix = _NEDecodeObject(NSNumber.self, coder, "destinationNetworkPrefixLength")
        else {
            return nil
        }
        destinationAddress = destination
        destinationNetworkPrefixLength = prefix
        super.init()
        gatewayAddress = _NEDecodeString(coder, "gatewayAddress")
    }

    open func encode(with coder: NSCoder) {
        _NEEncodeString(coder, "destinationAddress", destinationAddress)
        _NEEncodeObject(coder, "destinationNetworkPrefixLength", destinationNetworkPrefixLength)
        _NEEncodeString(coder, "gatewayAddress", gatewayAddress)
    }

    open class func `default`() -> NEIPv6Route {
        NEIPv6Route(destinationAddress: "::", networkPrefixLength: 0)
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = NEIPv6Route(
            destinationAddress: destinationAddress,
            networkPrefixLength: destinationNetworkPrefixLength
        )
        copy.gatewayAddress = gatewayAddress
        return copy
    }
}

open class NEIPv4Settings: NSObject, NSCopying, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public let addresses: [String]
    public let subnetMasks: [String]
    open var includedRoutes: [NEIPv4Route]?
    open var excludedRoutes: [NEIPv4Route]?

    public init(addresses: [String], subnetMasks: [String]) {
        self.addresses = addresses
        self.subnetMasks = subnetMasks
        super.init()
    }

    public required init?(coder: NSCoder) {
        addresses = _NEDecodeStringArray(coder, "addresses") ?? []
        subnetMasks = _NEDecodeStringArray(coder, "subnetMasks") ?? []
        super.init()
        includedRoutes = _NEDecodeTypedArray(
            [NSArray.self, NEIPv4Route.self], coder, "includedRoutes"
        ) as? [NEIPv4Route]
        excludedRoutes = _NEDecodeTypedArray(
            [NSArray.self, NEIPv4Route.self], coder, "excludedRoutes"
        ) as? [NEIPv4Route]
    }

    open func encode(with coder: NSCoder) {
        _NEEncodeStringArray(coder, "addresses", addresses)
        _NEEncodeStringArray(coder, "subnetMasks", subnetMasks)
        if let includedRoutes { coder.encode(includedRoutes as NSArray, forKey: "includedRoutes") }
        if let excludedRoutes { coder.encode(excludedRoutes as NSArray, forKey: "excludedRoutes") }
    }

    func validateForTunnel() throws {
        try _NESettingsValidation.requireMatchingCount(addresses.count, subnetMasks.count)
        guard addresses.allSatisfy(_NESettingsValidation.isIPv4),
            subnetMasks.allSatisfy(_NESettingsValidation.isIPv4)
        else {
            throw _NEHostBoundary.tunnelError(.networkSettingsInvalid)
        }
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = NEIPv4Settings(addresses: addresses, subnetMasks: subnetMasks)
        copy.includedRoutes = _NECopiedArray(includedRoutes)
        copy.excludedRoutes = _NECopiedArray(excludedRoutes)
        return copy
    }
}

open class NEIPv6Settings: NSObject, NSCopying, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public let addresses: [String]
    public let networkPrefixLengths: [NSNumber]
    open var includedRoutes: [NEIPv6Route]?
    open var excludedRoutes: [NEIPv6Route]?

    public init(addresses: [String], networkPrefixLengths: [NSNumber]) {
        self.addresses = addresses
        self.networkPrefixLengths = networkPrefixLengths
        super.init()
    }

    public required init?(coder: NSCoder) {
        let prefixes =
            _NEDecodeTypedArray([NSArray.self, NSNumber.self], coder, "networkPrefixLengths")
            as? [NSNumber] ?? []
        addresses = _NEDecodeStringArray(coder, "addresses") ?? []
        networkPrefixLengths = prefixes
        super.init()
        includedRoutes = _NEDecodeTypedArray(
            [NSArray.self, NEIPv6Route.self], coder, "includedRoutes"
        ) as? [NEIPv6Route]
        excludedRoutes = _NEDecodeTypedArray(
            [NSArray.self, NEIPv6Route.self], coder, "excludedRoutes"
        ) as? [NEIPv6Route]
    }

    open func encode(with coder: NSCoder) {
        _NEEncodeStringArray(coder, "addresses", addresses)
        coder.encode(networkPrefixLengths as NSArray, forKey: "networkPrefixLengths")
        if let includedRoutes { coder.encode(includedRoutes as NSArray, forKey: "includedRoutes") }
        if let excludedRoutes { coder.encode(excludedRoutes as NSArray, forKey: "excludedRoutes") }
    }

    func validateForTunnel() throws {
        try _NESettingsValidation.requireMatchingCount(addresses.count, networkPrefixLengths.count)
        guard addresses.allSatisfy(_NESettingsValidation.isIPv6) else {
            throw _NEHostBoundary.tunnelError(.networkSettingsInvalid)
        }
        for prefix in networkPrefixLengths {
            let value = prefix.intValue
            guard (0...128).contains(value) else {
                throw _NEHostBoundary.tunnelError(.networkSettingsInvalid)
            }
        }
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = NEIPv6Settings(
            addresses: addresses,
            networkPrefixLengths: networkPrefixLengths
        )
        copy.includedRoutes = _NECopiedArray(includedRoutes)
        copy.excludedRoutes = _NECopiedArray(excludedRoutes)
        return copy
    }
}

open class NEDNSSettings: NSObject, NSCopying, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public let servers: [String]
    open var allowFailover = false
    open var domainName: String?
    open var matchDomains: [String]?
    open var matchDomainsNoSearch = false
    open var searchDomains: [String]?

    public init(servers: [String]) {
        self.servers = servers
        super.init()
    }

    public required init?(coder: NSCoder) {
        servers = _NEDecodeStringArray(coder, "servers") ?? []
        super.init()
        decodeDNS(from: coder)
    }

    func decodeDNS(from coder: NSCoder) {
        allowFailover = coder.decodeBool(forKey: "allowFailover")
        domainName = _NEDecodeString(coder, "domainName")
        matchDomains = _NEDecodeStringArray(coder, "matchDomains")
        matchDomainsNoSearch = coder.decodeBool(forKey: "matchDomainsNoSearch")
        searchDomains = _NEDecodeStringArray(coder, "searchDomains")
    }

    open var dnsProtocol: NEDNSProtocol { .cleartext }

    func populateDNSCopy(_ copy: NEDNSSettings) {
        copy.allowFailover = allowFailover
        copy.domainName = domainName
        copy.matchDomains = matchDomains
        copy.matchDomainsNoSearch = matchDomainsNoSearch
        copy.searchDomains = searchDomains
    }

    open func encode(with coder: NSCoder) {
        _NEEncodeString(coder, _NEPortableArchive.kindKey, "cleartext")
        _NEEncodeStringArray(coder, "servers", servers)
        _NEEncodeBool(coder, "allowFailover", allowFailover)
        _NEEncodeString(coder, "domainName", domainName)
        _NEEncodeStringArray(coder, "matchDomains", matchDomains)
        _NEEncodeBool(coder, "matchDomainsNoSearch", matchDomainsNoSearch)
        _NEEncodeStringArray(coder, "searchDomains", searchDomains)
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = NEDNSSettings(servers: servers)
        populateDNSCopy(copy)
        return copy
    }
}

open class NEDNSOverHTTPSSettings: NEDNSSettings {
    open var identityReference: Data?
    open var serverURL: URL?

    open override var dnsProtocol: NEDNSProtocol { .HTTPS }

    public override init(servers: [String]) {
        super.init(servers: servers)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        identityReference = _NEDecodeData(coder, "identityReference")
        serverURL = _NEDecodeURL(coder, "serverURL")
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        _NEEncodeString(coder, _NEPortableArchive.kindKey, "https")
        _NEEncodeData(coder, "identityReference", identityReference)
        _NEEncodeURL(coder, "serverURL", serverURL)
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = NEDNSOverHTTPSSettings(servers: servers)
        populateDNSCopy(copy)
        copy.identityReference = identityReference
        copy.serverURL = serverURL
        return copy
    }
}

open class NEDNSOverTLSSettings: NEDNSSettings {
    open var identityReference: Data?
    open var serverName: String?

    open override var dnsProtocol: NEDNSProtocol { .TLS }

    public override init(servers: [String]) {
        super.init(servers: servers)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        identityReference = _NEDecodeData(coder, "identityReference")
        serverName = _NEDecodeString(coder, "serverName")
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        _NEEncodeString(coder, _NEPortableArchive.kindKey, "tls")
        _NEEncodeData(coder, "identityReference", identityReference)
        _NEEncodeString(coder, "serverName", serverName)
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = NEDNSOverTLSSettings(servers: servers)
        populateDNSCopy(copy)
        copy.identityReference = identityReference
        copy.serverName = serverName
        return copy
    }
}

open class NEOnDemandRule: NSObject, NSCopying, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    open var dnsSearchDomainMatch: [String]?
    open var dnsServerAddressMatch: [String]?
    open var ssidMatch: [String]?
    open var interfaceTypeMatch: NEOnDemandRuleInterfaceType = .any
    open var probeURL: URL?

    open var action: NEOnDemandRuleAction { .ignore }

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        super.init()
        decodeOnDemand(from: coder)
    }

    func decodeOnDemand(from coder: NSCoder) {
        dnsSearchDomainMatch = _NEDecodeStringArray(coder, "dnsSearchDomainMatch")
        dnsServerAddressMatch = _NEDecodeStringArray(coder, "dnsServerAddressMatch")
        ssidMatch = _NEDecodeStringArray(coder, "ssidMatch")
        interfaceTypeMatch =
            NEOnDemandRuleInterfaceType(rawValue: Int(coder.decodeInt64(forKey: "interfaceTypeMatch")))
            ?? .any
        probeURL = _NEDecodeURL(coder, "probeURL")
    }

    func populateOnDemandCopy(_ copy: NEOnDemandRule) {
        copy.dnsSearchDomainMatch = dnsSearchDomainMatch
        copy.dnsServerAddressMatch = dnsServerAddressMatch
        copy.ssidMatch = ssidMatch
        copy.interfaceTypeMatch = interfaceTypeMatch
        copy.probeURL = probeURL
    }

    open func encode(with coder: NSCoder) {
        _NEEncodeStringArray(coder, "dnsSearchDomainMatch", dnsSearchDomainMatch)
        _NEEncodeStringArray(coder, "dnsServerAddressMatch", dnsServerAddressMatch)
        _NEEncodeStringArray(coder, "ssidMatch", ssidMatch)
        _NEEncodeInt64(coder, "interfaceTypeMatch", Int64(interfaceTypeMatch.rawValue))
        _NEEncodeURL(coder, "probeURL", probeURL)
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = NEOnDemandRule()
        populateOnDemandCopy(copy)
        return copy
    }
}

open class NEOnDemandRuleConnect: NEOnDemandRule {
    open override var action: NEOnDemandRuleAction { .connect }

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        super.init()
        decodeOnDemand(from: coder)
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = NEOnDemandRuleConnect()
        populateOnDemandCopy(copy)
        return copy
    }
}

open class NEOnDemandRuleDisconnect: NEOnDemandRule {
    open override var action: NEOnDemandRuleAction { .disconnect }

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        super.init()
        decodeOnDemand(from: coder)
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = NEOnDemandRuleDisconnect()
        populateOnDemandCopy(copy)
        return copy
    }
}

open class NEOnDemandRuleIgnore: NEOnDemandRule {
    open override var action: NEOnDemandRuleAction { .ignore }

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        super.init()
        decodeOnDemand(from: coder)
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = NEOnDemandRuleIgnore()
        populateOnDemandCopy(copy)
        return copy
    }
}

open class NEOnDemandRuleEvaluateConnection: NEOnDemandRule {
    open var connectionRules: [NEEvaluateConnectionRule]?
    open override var action: NEOnDemandRuleAction { .evaluateConnection }

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        super.init()
        decodeOnDemand(from: coder)
        connectionRules = _NEDecodeTypedArray(
            [NSArray.self, NEEvaluateConnectionRule.self], coder, "connectionRules"
        ) as? [NEEvaluateConnectionRule]
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        if let connectionRules {
            coder.encode(connectionRules as NSArray, forKey: "connectionRules")
        }
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = NEOnDemandRuleEvaluateConnection()
        populateOnDemandCopy(copy)
        copy.connectionRules = _NECopiedArray(connectionRules)
        return copy
    }
}

open class NEEvaluateConnectionRule: NSObject, NSCopying, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public let matchDomains: [String]
    public let action: NEEvaluateConnectionRuleAction
    open var probeURL: URL?
    open var useDNSServers: [String]?

    public init(matchDomains domains: [String], andAction action: NEEvaluateConnectionRuleAction) {
        matchDomains = domains
        self.action = action
        super.init()
    }

    public required init?(coder: NSCoder) {
        let decodedAction =
            NEEvaluateConnectionRuleAction(rawValue: Int(coder.decodeInt64(forKey: "action")))
            ?? .connectIfNeeded
        matchDomains = _NEDecodeStringArray(coder, "matchDomains") ?? []
        action = decodedAction
        super.init()
        probeURL = _NEDecodeURL(coder, "probeURL")
        useDNSServers = _NEDecodeStringArray(coder, "useDNSServers")
    }

    open func encode(with coder: NSCoder) {
        _NEEncodeStringArray(coder, "matchDomains", matchDomains)
        _NEEncodeInt64(coder, "action", Int64(action.rawValue))
        _NEEncodeURL(coder, "probeURL", probeURL)
        _NEEncodeStringArray(coder, "useDNSServers", useDNSServers)
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = NEEvaluateConnectionRule(matchDomains: matchDomains, andAction: action)
        copy.probeURL = probeURL
        copy.useDNSServers = useDNSServers
        return copy
    }
}

open class NEAppRule: NSObject, NSCopying, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public let matchSigningIdentifier: String
    open var matchDomains: [Any]?
    open var matchPath: String?

    public init(signingIdentifier: String) {
        matchSigningIdentifier = signingIdentifier
        super.init()
    }

    public required init?(coder: NSCoder) {
        matchSigningIdentifier = _NEDecodeString(coder, "matchSigningIdentifier") ?? ""
        super.init()
        matchPath = _NEDecodeString(coder, "matchPath")
        matchDomains = _NEDecodeStringArray(coder, "matchDomains")
    }

    open func encode(with coder: NSCoder) {
        _NEEncodeString(coder, "matchSigningIdentifier", matchSigningIdentifier)
        _NEEncodeString(coder, "matchPath", matchPath)
        if let matchDomains {
            let strings = matchDomains.compactMap { $0 as? String }
            _NEEncodeStringArray(coder, "matchDomains", strings)
        }
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = NEAppRule(signingIdentifier: matchSigningIdentifier)
        copy.matchDomains = matchDomains
        copy.matchPath = matchPath
        return copy
    }
}

open class NETunnelNetworkSettings: NSObject, NSCopying, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public let tunnelRemoteAddress: String
    open var dnsSettings: NEDNSSettings?
    open var proxySettings: NEProxySettings?

    public init(tunnelRemoteAddress address: String) {
        tunnelRemoteAddress = address
        super.init()
    }

    public required init?(coder: NSCoder) {
        tunnelRemoteAddress = _NEDecodeString(coder, "tunnelRemoteAddress") ?? ""
        super.init()
        decodeTunnel(from: coder)
    }

    func decodeTunnel(from coder: NSCoder) {
        dnsSettings = _NEDecodeTypedArray(
            [
                NEDNSSettings.self,
                NEDNSOverHTTPSSettings.self,
                NEDNSOverTLSSettings.self,
            ],
            coder,
            "dnsSettings"
        ) as? NEDNSSettings
        proxySettings = _NEDecodeObject(NEProxySettings.self, coder, "proxySettings")
    }

    func populateTunnelCopy(_ copy: NETunnelNetworkSettings) {
        copy.dnsSettings = _NECopiedObject(dnsSettings)
        copy.proxySettings = _NECopiedObject(proxySettings)
    }

    open func encode(with coder: NSCoder) {
        _NEEncodeString(coder, "tunnelRemoteAddress", tunnelRemoteAddress)
        _NEEncodeObject(coder, "dnsSettings", dnsSettings)
        _NEEncodeObject(coder, "proxySettings", proxySettings)
    }

    func validateForTunnel() throws {
        guard !tunnelRemoteAddress.isEmpty else {
            throw _NEHostBoundary.tunnelError(.networkSettingsInvalid)
        }
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = NETunnelNetworkSettings(tunnelRemoteAddress: tunnelRemoteAddress)
        populateTunnelCopy(copy)
        return copy
    }
}

open class NEPacketTunnelNetworkSettings: NETunnelNetworkSettings {
    open var ipv4Settings: NEIPv4Settings?
    open var ipv6Settings: NEIPv6Settings?
    open var mtu: NSNumber?
    open var tunnelOverheadBytes: NSNumber?

    public override init(tunnelRemoteAddress address: String) {
        super.init(tunnelRemoteAddress: address)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        ipv4Settings = _NEDecodeObject(NEIPv4Settings.self, coder, "ipv4Settings")
        ipv6Settings = _NEDecodeObject(NEIPv6Settings.self, coder, "ipv6Settings")
        mtu = _NEDecodeObject(NSNumber.self, coder, "mtu")
        tunnelOverheadBytes = _NEDecodeObject(NSNumber.self, coder, "tunnelOverheadBytes")
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        _NEEncodeObject(coder, "ipv4Settings", ipv4Settings)
        _NEEncodeObject(coder, "ipv6Settings", ipv6Settings)
        _NEEncodeObject(coder, "mtu", mtu)
        _NEEncodeObject(coder, "tunnelOverheadBytes", tunnelOverheadBytes)
    }

    override func validateForTunnel() throws {
        try super.validateForTunnel()
        try ipv4Settings?.validateForTunnel()
        try ipv6Settings?.validateForTunnel()
        if let mtu, mtu.intValue <= 0 {
            throw _NEHostBoundary.tunnelError(.networkSettingsInvalid)
        }
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: tunnelRemoteAddress)
        populateTunnelCopy(copy)
        copy.ipv4Settings = _NECopiedObject(ipv4Settings)
        copy.ipv6Settings = _NECopiedObject(ipv6Settings)
        copy.mtu = mtu
        copy.tunnelOverheadBytes = tunnelOverheadBytes
        return copy
    }
}

open class NEVPNProtocol: NSObject, NSCopying, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    open var disconnectOnSleep = false
    open var enforceRoutes = false
    open var excludeAPNs = true
    open var excludeCellularServices = true
    open var excludeDeviceCommunication = true
    open var excludeLocalNetworks = true
    open var identityData: Data?
    open var identityDataPassword: String?
    open var identityReference: Data?
    open var includeAllNetworks = false
    open var passwordReference: Data?
    open var proxySettings: NEProxySettings?
    open var serverAddress: String?
    open var sliceUUID: String?
    open var username: String?

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        super.init()
        decodeVPNProtocol(from: coder)
    }

    func decodeVPNProtocol(from coder: NSCoder) {
        disconnectOnSleep = coder.decodeBool(forKey: "disconnectOnSleep")
        enforceRoutes = coder.decodeBool(forKey: "enforceRoutes")
        excludeAPNs = coder.decodeBool(forKey: "excludeAPNs")
        excludeCellularServices = coder.decodeBool(forKey: "excludeCellularServices")
        excludeDeviceCommunication = coder.decodeBool(forKey: "excludeDeviceCommunication")
        excludeLocalNetworks = coder.decodeBool(forKey: "excludeLocalNetworks")
        identityData = _NEDecodeData(coder, "identityData")
        identityDataPassword = _NEDecodeString(coder, "identityDataPassword")
        identityReference = _NEDecodeData(coder, "identityReference")
        includeAllNetworks = coder.decodeBool(forKey: "includeAllNetworks")
        passwordReference = _NEDecodeData(coder, "passwordReference")
        proxySettings = _NEDecodeObject(NEProxySettings.self, coder, "proxySettings")
        serverAddress = _NEDecodeString(coder, "serverAddress")
        sliceUUID = _NEDecodeString(coder, "sliceUUID")
        username = _NEDecodeString(coder, "username")
    }

    func populateVPNProtocolCopy(_ copy: NEVPNProtocol) {
        copy.disconnectOnSleep = disconnectOnSleep
        copy.enforceRoutes = enforceRoutes
        copy.excludeAPNs = excludeAPNs
        copy.excludeCellularServices = excludeCellularServices
        copy.excludeDeviceCommunication = excludeDeviceCommunication
        copy.excludeLocalNetworks = excludeLocalNetworks
        copy.identityData = identityData
        copy.identityDataPassword = identityDataPassword
        copy.identityReference = identityReference
        copy.includeAllNetworks = includeAllNetworks
        copy.passwordReference = passwordReference
        copy.proxySettings = _NECopiedObject(proxySettings)
        copy.serverAddress = serverAddress
        copy.sliceUUID = sliceUUID
        copy.username = username
    }

    open func encode(with coder: NSCoder) {
        _NEEncodeBool(coder, "disconnectOnSleep", disconnectOnSleep)
        _NEEncodeBool(coder, "enforceRoutes", enforceRoutes)
        _NEEncodeBool(coder, "excludeAPNs", excludeAPNs)
        _NEEncodeBool(coder, "excludeCellularServices", excludeCellularServices)
        _NEEncodeBool(coder, "excludeDeviceCommunication", excludeDeviceCommunication)
        _NEEncodeBool(coder, "excludeLocalNetworks", excludeLocalNetworks)
        _NEEncodeData(coder, "identityData", identityData)
        _NEEncodeString(coder, "identityDataPassword", identityDataPassword)
        _NEEncodeData(coder, "identityReference", identityReference)
        _NEEncodeBool(coder, "includeAllNetworks", includeAllNetworks)
        _NEEncodeData(coder, "passwordReference", passwordReference)
        _NEEncodeObject(coder, "proxySettings", proxySettings)
        _NEEncodeString(coder, "serverAddress", serverAddress)
        _NEEncodeString(coder, "sliceUUID", sliceUUID)
        _NEEncodeString(coder, "username", username)
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = NEVPNProtocol()
        populateVPNProtocolCopy(copy)
        return copy
    }
}

open class NEVPNIKEv2SecurityAssociationParameters: NSObject, NSCopying, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    open var diffieHellmanGroup: NEVPNIKEv2DiffieHellmanGroup = .group14
    open var encryptionAlgorithm: NEVPNIKEv2EncryptionAlgorithm = .algorithmAES256
    open var integrityAlgorithm: NEVPNIKEv2IntegrityAlgorithm = .SHA256
    open var lifetimeMinutes: Int32 = 1440
    open var postQuantumKeyExchangeMethods: [NEVPNIKEv2PostQuantumKeyExchangeMethod] = []

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        super.init()
        diffieHellmanGroup =
            NEVPNIKEv2DiffieHellmanGroup(rawValue: Int(coder.decodeInt64(forKey: "diffieHellmanGroup")))
            ?? .group14
        encryptionAlgorithm =
            NEVPNIKEv2EncryptionAlgorithm(
                rawValue: Int(coder.decodeInt64(forKey: "encryptionAlgorithm"))
            )
            ?? .algorithmAES256
        integrityAlgorithm =
            NEVPNIKEv2IntegrityAlgorithm(rawValue: Int(coder.decodeInt64(forKey: "integrityAlgorithm")))
            ?? .SHA256
        lifetimeMinutes = coder.decodeInt32(forKey: "lifetimeMinutes")
        if let values = _NEDecodeTypedArray(
            [NSArray.self, NSNumber.self], coder, "pqke"
        ) as? [NSNumber] {
            postQuantumKeyExchangeMethods = values.compactMap {
                NEVPNIKEv2PostQuantumKeyExchangeMethod(rawValue: $0.intValue)
            }
        }
    }

    open func encode(with coder: NSCoder) {
        _NEEncodeInt64(coder, "diffieHellmanGroup", Int64(diffieHellmanGroup.rawValue))
        _NEEncodeInt64(coder, "encryptionAlgorithm", Int64(encryptionAlgorithm.rawValue))
        _NEEncodeInt64(coder, "integrityAlgorithm", Int64(integrityAlgorithm.rawValue))
        coder.encode(lifetimeMinutes, forKey: "lifetimeMinutes")
        coder.encode(
            postQuantumKeyExchangeMethods.map { NSNumber(value: $0.rawValue) } as NSArray,
            forKey: "pqke"
        )
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = NEVPNIKEv2SecurityAssociationParameters()
        populate(onto: copy)
        return copy
    }

    func populate(onto copy: NEVPNIKEv2SecurityAssociationParameters) {
        copy.diffieHellmanGroup = diffieHellmanGroup
        copy.encryptionAlgorithm = encryptionAlgorithm
        copy.integrityAlgorithm = integrityAlgorithm
        copy.lifetimeMinutes = lifetimeMinutes
        copy.postQuantumKeyExchangeMethods = postQuantumKeyExchangeMethods
    }
}

open class NEVPNIKEv2PPKConfiguration: NSObject, NSCopying, NSSecureCoding {
    public static var supportsSecureCoding: Bool { true }

    public let identifier: String
    public let keychainReference: Data
    open var isMandatory = true

    public init(identifier: String, keychainReference: Data) {
        self.identifier = identifier
        self.keychainReference = keychainReference
        super.init()
    }

    public required init?(coder: NSCoder) {
        identifier = _NEDecodeString(coder, "identifier") ?? ""
        keychainReference = _NEDecodeData(coder, "keychainReference") ?? Data()
        super.init()
        isMandatory = coder.decodeBool(forKey: "isMandatory")
    }

    open func encode(with coder: NSCoder) {
        _NEEncodeString(coder, "identifier", identifier)
        _NEEncodeData(coder, "keychainReference", keychainReference)
        _NEEncodeBool(coder, "isMandatory", isMandatory)
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = NEVPNIKEv2PPKConfiguration(
            identifier: identifier,
            keychainReference: keychainReference
        )
        copy.isMandatory = isMandatory
        return copy
    }
}

open class NEVPNProtocolIPSec: NEVPNProtocol {
    open var authenticationMethod: NEVPNIKEAuthenticationMethod = .none
    open var localIdentifier: String?
    open var remoteIdentifier: String?
    open var sharedSecretReference: Data?
    open var useExtendedAuthentication = false

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        super.init()
        decodeVPNProtocol(from: coder)
        decodeIPSec(from: coder)
    }

    func decodeIPSec(from coder: NSCoder) {
        authenticationMethod =
            NEVPNIKEAuthenticationMethod(
                rawValue: Int(coder.decodeInt64(forKey: "authenticationMethod"))
            )
            ?? .none
        localIdentifier = _NEDecodeString(coder, "localIdentifier")
        remoteIdentifier = _NEDecodeString(coder, "remoteIdentifier")
        sharedSecretReference = _NEDecodeData(coder, "sharedSecretReference")
        useExtendedAuthentication = coder.decodeBool(forKey: "useExtendedAuthentication")
    }

    func populateIPSecCopy(_ copy: NEVPNProtocolIPSec) {
        populateVPNProtocolCopy(copy)
        copy.authenticationMethod = authenticationMethod
        copy.localIdentifier = localIdentifier
        copy.remoteIdentifier = remoteIdentifier
        copy.sharedSecretReference = sharedSecretReference
        copy.useExtendedAuthentication = useExtendedAuthentication
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        _NEEncodeInt64(coder, "authenticationMethod", Int64(authenticationMethod.rawValue))
        _NEEncodeString(coder, "localIdentifier", localIdentifier)
        _NEEncodeString(coder, "remoteIdentifier", remoteIdentifier)
        _NEEncodeData(coder, "sharedSecretReference", sharedSecretReference)
        _NEEncodeBool(coder, "useExtendedAuthentication", useExtendedAuthentication)
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = NEVPNProtocolIPSec()
        populateIPSecCopy(copy)
        return copy
    }
}

open class NEVPNProtocolIKEv2: NEVPNProtocolIPSec {
    private let _ike = NEVPNIKEv2SecurityAssociationParameters()
    private let _child = NEVPNIKEv2SecurityAssociationParameters()

    open var ikeSecurityAssociationParameters: NEVPNIKEv2SecurityAssociationParameters { _ike }
    open var childSecurityAssociationParameters: NEVPNIKEv2SecurityAssociationParameters { _child }
    open var allowPostQuantumKeyExchangeFallback = false
    open var certificateType: NEVPNIKEv2CertificateType = .RSA
    open var deadPeerDetectionRate: NEVPNIKEv2DeadPeerDetectionRate = .medium
    open var disableMOBIKE = false
    open var disableRedirect = false
    open var enableFallback = false
    open var enablePFS = false
    open var enableRevocationCheck = false
    open var maximumTLSVersion: NEVPNIKEv2TLSVersion = .versionDefault
    open var minimumTLSVersion: NEVPNIKEv2TLSVersion = .versionDefault
    open var mtu: Int = 1280
    open var ppkConfiguration: NEVPNIKEv2PPKConfiguration?
    open var serverCertificateCommonName: String?
    open var serverCertificateIssuerCommonName: String?
    open var strictRevocationCheck = false
    open var useConfigurationAttributeInternalIPSubnet = false

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        super.init()
        decodeVPNProtocol(from: coder)
        decodeIPSec(from: coder)
        if let ike = _NEDecodeObject(
            NEVPNIKEv2SecurityAssociationParameters.self, coder, "ike"
        ) {
            ike.populate(onto: _ike)
        }
        if let child = _NEDecodeObject(
            NEVPNIKEv2SecurityAssociationParameters.self, coder, "child"
        ) {
            child.populate(onto: _child)
        }
        allowPostQuantumKeyExchangeFallback = coder.decodeBool(
            forKey: "allowPostQuantumKeyExchangeFallback"
        )
        certificateType =
            NEVPNIKEv2CertificateType(rawValue: Int(coder.decodeInt64(forKey: "certificateType")))
            ?? .RSA
        deadPeerDetectionRate =
            NEVPNIKEv2DeadPeerDetectionRate(
                rawValue: Int(coder.decodeInt64(forKey: "deadPeerDetectionRate"))
            )
            ?? .medium
        disableMOBIKE = coder.decodeBool(forKey: "disableMOBIKE")
        disableRedirect = coder.decodeBool(forKey: "disableRedirect")
        enableFallback = coder.decodeBool(forKey: "enableFallback")
        enablePFS = coder.decodeBool(forKey: "enablePFS")
        enableRevocationCheck = coder.decodeBool(forKey: "enableRevocationCheck")
        maximumTLSVersion =
            NEVPNIKEv2TLSVersion(rawValue: Int(coder.decodeInt64(forKey: "maximumTLSVersion")))
            ?? .versionDefault
        minimumTLSVersion =
            NEVPNIKEv2TLSVersion(rawValue: Int(coder.decodeInt64(forKey: "minimumTLSVersion")))
            ?? .versionDefault
        mtu = Int(coder.decodeInt64(forKey: "mtu"))
        ppkConfiguration = _NEDecodeObject(NEVPNIKEv2PPKConfiguration.self, coder, "ppkConfiguration")
        serverCertificateCommonName = _NEDecodeString(coder, "serverCertificateCommonName")
        serverCertificateIssuerCommonName = _NEDecodeString(
            coder, "serverCertificateIssuerCommonName"
        )
        strictRevocationCheck = coder.decodeBool(forKey: "strictRevocationCheck")
        useConfigurationAttributeInternalIPSubnet = coder.decodeBool(
            forKey: "useConfigurationAttributeInternalIPSubnet"
        )
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        _NEEncodeObject(coder, "ike", ikeSecurityAssociationParameters)
        _NEEncodeObject(coder, "child", childSecurityAssociationParameters)
        _NEEncodeBool(
            coder, "allowPostQuantumKeyExchangeFallback", allowPostQuantumKeyExchangeFallback
        )
        _NEEncodeInt64(coder, "certificateType", Int64(certificateType.rawValue))
        _NEEncodeInt64(coder, "deadPeerDetectionRate", Int64(deadPeerDetectionRate.rawValue))
        _NEEncodeBool(coder, "disableMOBIKE", disableMOBIKE)
        _NEEncodeBool(coder, "disableRedirect", disableRedirect)
        _NEEncodeBool(coder, "enableFallback", enableFallback)
        _NEEncodeBool(coder, "enablePFS", enablePFS)
        _NEEncodeBool(coder, "enableRevocationCheck", enableRevocationCheck)
        _NEEncodeInt64(coder, "maximumTLSVersion", Int64(maximumTLSVersion.rawValue))
        _NEEncodeInt64(coder, "minimumTLSVersion", Int64(minimumTLSVersion.rawValue))
        _NEEncodeInt64(coder, "mtu", Int64(mtu))
        _NEEncodeObject(coder, "ppkConfiguration", ppkConfiguration)
        _NEEncodeString(coder, "serverCertificateCommonName", serverCertificateCommonName)
        _NEEncodeString(
            coder, "serverCertificateIssuerCommonName", serverCertificateIssuerCommonName
        )
        _NEEncodeBool(coder, "strictRevocationCheck", strictRevocationCheck)
        _NEEncodeBool(
            coder,
            "useConfigurationAttributeInternalIPSubnet",
            useConfigurationAttributeInternalIPSubnet
        )
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = NEVPNProtocolIKEv2()
        populateIPSecCopy(copy)
        ikeSecurityAssociationParameters.populate(onto: copy._ike)
        childSecurityAssociationParameters.populate(onto: copy._child)
        copy.allowPostQuantumKeyExchangeFallback = allowPostQuantumKeyExchangeFallback
        copy.certificateType = certificateType
        copy.deadPeerDetectionRate = deadPeerDetectionRate
        copy.disableMOBIKE = disableMOBIKE
        copy.disableRedirect = disableRedirect
        copy.enableFallback = enableFallback
        copy.enablePFS = enablePFS
        copy.enableRevocationCheck = enableRevocationCheck
        copy.maximumTLSVersion = maximumTLSVersion
        copy.minimumTLSVersion = minimumTLSVersion
        copy.mtu = mtu
        copy.ppkConfiguration = _NECopiedObject(ppkConfiguration)
        copy.serverCertificateCommonName = serverCertificateCommonName
        copy.serverCertificateIssuerCommonName = serverCertificateIssuerCommonName
        copy.strictRevocationCheck = strictRevocationCheck
        copy.useConfigurationAttributeInternalIPSubnet =
            useConfigurationAttributeInternalIPSubnet
        return copy
    }
}

open class NETunnelProviderProtocol: NEVPNProtocol {
    open var providerBundleIdentifier: String?
    open var providerConfiguration: [String: Any]?

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        super.init()
        decodeVPNProtocol(from: coder)
        providerBundleIdentifier = _NEDecodeString(coder, "providerBundleIdentifier")
        providerConfiguration = _NEDecodePlistDictionary(coder, "providerConfiguration")
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        _NEEncodeString(coder, "providerBundleIdentifier", providerBundleIdentifier)
        _NEEncodePlistDictionary(coder, "providerConfiguration", providerConfiguration)
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = NETunnelProviderProtocol()
        populateVPNProtocolCopy(copy)
        copy.providerBundleIdentifier = providerBundleIdentifier
        copy.providerConfiguration = _NECopiedDictionary(providerConfiguration)
        return copy
    }
}

open class NEDNSProxyProviderProtocol: NEVPNProtocol {
    open var providerBundleIdentifier: String?
    open var providerConfiguration: [String: Any]?

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        super.init()
        decodeVPNProtocol(from: coder)
        providerBundleIdentifier = _NEDecodeString(coder, "providerBundleIdentifier")
        providerConfiguration = _NEDecodePlistDictionary(coder, "providerConfiguration")
    }

    open override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        _NEEncodeString(coder, "providerBundleIdentifier", providerBundleIdentifier)
        _NEEncodePlistDictionary(coder, "providerConfiguration", providerConfiguration)
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = NEDNSProxyProviderProtocol()
        populateVPNProtocolCopy(copy)
        copy.providerBundleIdentifier = providerBundleIdentifier
        copy.providerConfiguration = _NECopiedDictionary(providerConfiguration)
        return copy
    }
}
