open class NEProxyServer: NSObject, NSCopying {
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

    open func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = NEProxyServer(address: address, port: port)
        copy.authenticationRequired = authenticationRequired
        copy.username = username
        copy.password = password
        return copy
    }
}

open class NEProxySettings: NSObject, NSCopying {
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

open class NEIPv4Route: NSObject, NSCopying {
    public let destinationAddress: String
    public let destinationSubnetMask: String
    open var gatewayAddress: String?

    public init(destinationAddress address: String, subnetMask: String) {
        destinationAddress = address
        destinationSubnetMask = subnetMask
        super.init()
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

open class NEIPv6Route: NSObject, NSCopying {
    public let destinationAddress: String
    public let destinationNetworkPrefixLength: NSNumber
    open var gatewayAddress: String?

    public init(destinationAddress address: String, networkPrefixLength: NSNumber) {
        destinationAddress = address
        destinationNetworkPrefixLength = networkPrefixLength
        super.init()
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

open class NEIPv4Settings: NSObject, NSCopying {
    public let addresses: [String]
    public let subnetMasks: [String]
    open var includedRoutes: [NEIPv4Route]?
    open var excludedRoutes: [NEIPv4Route]?

    public init(addresses: [String], subnetMasks: [String]) {
        self.addresses = addresses
        self.subnetMasks = subnetMasks
        super.init()
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = NEIPv4Settings(addresses: addresses, subnetMasks: subnetMasks)
        copy.includedRoutes = _NECopiedArray(includedRoutes)
        copy.excludedRoutes = _NECopiedArray(excludedRoutes)
        return copy
    }
}

open class NEIPv6Settings: NSObject, NSCopying {
    public let addresses: [String]
    public let networkPrefixLengths: [NSNumber]
    open var includedRoutes: [NEIPv6Route]?
    open var excludedRoutes: [NEIPv6Route]?

    public init(addresses: [String], networkPrefixLengths: [NSNumber]) {
        self.addresses = addresses
        self.networkPrefixLengths = networkPrefixLengths
        super.init()
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

open class NEDNSSettings: NSObject, NSCopying {
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

    open var dnsProtocol: NEDNSProtocol { .cleartext }

    func populateDNSCopy(_ copy: NEDNSSettings) {
        copy.allowFailover = allowFailover
        copy.domainName = domainName
        copy.matchDomains = matchDomains
        copy.matchDomainsNoSearch = matchDomainsNoSearch
        copy.searchDomains = searchDomains
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

    open override func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = NEDNSOverTLSSettings(servers: servers)
        populateDNSCopy(copy)
        copy.identityReference = identityReference
        copy.serverName = serverName
        return copy
    }
}

open class NEOnDemandRule: NSObject, NSCopying {
    open var dnsSearchDomainMatch: [String]?
    open var dnsServerAddressMatch: [String]?
    open var ssidMatch: [String]?
    open var interfaceTypeMatch: NEOnDemandRuleInterfaceType = .any
    open var probeURL: URL?

    open var action: NEOnDemandRuleAction { .ignore }

    func populateOnDemandCopy(_ copy: NEOnDemandRule) {
        copy.dnsSearchDomainMatch = dnsSearchDomainMatch
        copy.dnsServerAddressMatch = dnsServerAddressMatch
        copy.ssidMatch = ssidMatch
        copy.interfaceTypeMatch = interfaceTypeMatch
        copy.probeURL = probeURL
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

    open override func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = NEOnDemandRuleConnect()
        populateOnDemandCopy(copy)
        return copy
    }
}

open class NEOnDemandRuleDisconnect: NEOnDemandRule {
    open override var action: NEOnDemandRuleAction { .disconnect }

    open override func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = NEOnDemandRuleDisconnect()
        populateOnDemandCopy(copy)
        return copy
    }
}

open class NEOnDemandRuleIgnore: NEOnDemandRule {
    open override var action: NEOnDemandRuleAction { .ignore }

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

    open override func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = NEOnDemandRuleEvaluateConnection()
        populateOnDemandCopy(copy)
        copy.connectionRules = _NECopiedArray(connectionRules)
        return copy
    }
}

open class NEEvaluateConnectionRule: NSObject, NSCopying {
    public let matchDomains: [String]
    public let action: NEEvaluateConnectionRuleAction
    open var probeURL: URL?
    open var useDNSServers: [String]?

    public init(matchDomains domains: [String], andAction action: NEEvaluateConnectionRuleAction) {
        matchDomains = domains
        self.action = action
        super.init()
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = NEEvaluateConnectionRule(matchDomains: matchDomains, andAction: action)
        copy.probeURL = probeURL
        copy.useDNSServers = useDNSServers
        return copy
    }
}

open class NEAppRule: NSObject, NSCopying {
    public let matchSigningIdentifier: String
    open var matchDomains: [Any]?
    open var matchPath: String?

    public init(signingIdentifier: String) {
        matchSigningIdentifier = signingIdentifier
        super.init()
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = NEAppRule(signingIdentifier: matchSigningIdentifier)
        copy.matchDomains = matchDomains
        copy.matchPath = matchPath
        return copy
    }
}

open class NETunnelNetworkSettings: NSObject, NSCopying {
    public let tunnelRemoteAddress: String
    open var dnsSettings: NEDNSSettings?
    open var proxySettings: NEProxySettings?

    public init(tunnelRemoteAddress address: String) {
        tunnelRemoteAddress = address
        super.init()
    }

    func populateTunnelCopy(_ copy: NETunnelNetworkSettings) {
        copy.dnsSettings = _NECopiedObject(dnsSettings)
        copy.proxySettings = _NECopiedObject(proxySettings)
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

open class NEVPNProtocol: NSObject, NSCopying {
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

    open func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = NEVPNProtocol()
        populateVPNProtocolCopy(copy)
        return copy
    }
}

open class NEVPNIKEv2SecurityAssociationParameters: NSObject, NSCopying {
    open var diffieHellmanGroup: NEVPNIKEv2DiffieHellmanGroup = .group14
    open var encryptionAlgorithm: NEVPNIKEv2EncryptionAlgorithm = .algorithmAES256
    open var integrityAlgorithm: NEVPNIKEv2IntegrityAlgorithm = .SHA256
    open var lifetimeMinutes: Int32 = 1440
    open var postQuantumKeyExchangeMethods: [NEVPNIKEv2PostQuantumKeyExchangeMethod] = []

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

open class NEVPNIKEv2PPKConfiguration: NSObject, NSCopying {
    public let identifier: String
    public let keychainReference: Data
    open var isMandatory = true

    public init(identifier: String, keychainReference: Data) {
        self.identifier = identifier
        self.keychainReference = keychainReference
        super.init()
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

    func populateIPSecCopy(_ copy: NEVPNProtocolIPSec) {
        populateVPNProtocolCopy(copy)
        copy.authenticationMethod = authenticationMethod
        copy.localIdentifier = localIdentifier
        copy.remoteIdentifier = remoteIdentifier
        copy.sharedSecretReference = sharedSecretReference
        copy.useExtendedAuthentication = useExtendedAuthentication
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

    open override func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        let copy = NEDNSProxyProviderProtocol()
        populateVPNProtocolCopy(copy)
        copy.providerBundleIdentifier = providerBundleIdentifier
        copy.providerConfiguration = _NECopiedDictionary(providerConfiguration)
        return copy
    }
}
