open class NEProxyServer: NSObject {
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
}

open class NEProxySettings: NSObject {
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
}

open class NEIPv4Route: NSObject {
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
}

open class NEIPv6Route: NSObject {
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
}

open class NEIPv4Settings: NSObject {
    public let addresses: [String]
    public let subnetMasks: [String]
    open var includedRoutes: [NEIPv4Route]?
    open var excludedRoutes: [NEIPv4Route]?

    public init(addresses: [String], subnetMasks: [String]) {
        self.addresses = addresses
        self.subnetMasks = subnetMasks
        super.init()
    }
}

open class NEIPv6Settings: NSObject {
    public let addresses: [String]
    public let networkPrefixLengths: [NSNumber]
    open var includedRoutes: [NEIPv6Route]?
    open var excludedRoutes: [NEIPv6Route]?

    public init(addresses: [String], networkPrefixLengths: [NSNumber]) {
        self.addresses = addresses
        self.networkPrefixLengths = networkPrefixLengths
        super.init()
    }
}

open class NEDNSSettings: NSObject {
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
}

open class NEDNSOverHTTPSSettings: NEDNSSettings {
    open var identityReference: Data?
    open var serverURL: URL?

    open override var dnsProtocol: NEDNSProtocol { .HTTPS }
}

open class NEDNSOverTLSSettings: NEDNSSettings {
    open var identityReference: Data?
    open var serverName: String?

    open override var dnsProtocol: NEDNSProtocol { .TLS }
}

open class NEOnDemandRule: NSObject {
    open var dnsSearchDomainMatch: [String]?
    open var dnsServerAddressMatch: [String]?
    open var ssidMatch: [String]?
    open var interfaceTypeMatch: NEOnDemandRuleInterfaceType = .any
    open var probeURL: URL?

    open var action: NEOnDemandRuleAction { .ignore }
}

open class NEOnDemandRuleConnect: NEOnDemandRule {
    open override var action: NEOnDemandRuleAction { .connect }
}

open class NEOnDemandRuleDisconnect: NEOnDemandRule {
    open override var action: NEOnDemandRuleAction { .disconnect }
}

open class NEOnDemandRuleIgnore: NEOnDemandRule {
    open override var action: NEOnDemandRuleAction { .ignore }
}

open class NEOnDemandRuleEvaluateConnection: NEOnDemandRule {
    open var connectionRules: [NEEvaluateConnectionRule]?
    open override var action: NEOnDemandRuleAction { .evaluateConnection }
}

open class NEEvaluateConnectionRule: NSObject {
    public let matchDomains: [String]
    public let action: NEEvaluateConnectionRuleAction
    open var probeURL: URL?
    open var useDNSServers: [String]?

    public init(matchDomains domains: [String], andAction action: NEEvaluateConnectionRuleAction) {
        matchDomains = domains
        self.action = action
        super.init()
    }
}

open class NEAppRule: NSObject {
    public let matchSigningIdentifier: String
    open var matchDomains: [Any]?
    open var matchPath: String?

    public init(signingIdentifier: String) {
        matchSigningIdentifier = signingIdentifier
        super.init()
    }
}

open class NETunnelNetworkSettings: NSObject {
    public let tunnelRemoteAddress: String
    open var dnsSettings: NEDNSSettings?
    open var proxySettings: NEProxySettings?

    public init(tunnelRemoteAddress address: String) {
        tunnelRemoteAddress = address
        super.init()
    }
}

open class NEPacketTunnelNetworkSettings: NETunnelNetworkSettings {
    open var ipv4Settings: NEIPv4Settings?
    open var ipv6Settings: NEIPv6Settings?
    open var mtu: NSNumber?
    open var tunnelOverheadBytes: NSNumber?
}

open class NEVPNProtocol: NSObject {
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
}

open class NEVPNIKEv2SecurityAssociationParameters: NSObject {
    open var diffieHellmanGroup: NEVPNIKEv2DiffieHellmanGroup = .group14
    open var encryptionAlgorithm: NEVPNIKEv2EncryptionAlgorithm = .algorithmAES256
    open var integrityAlgorithm: NEVPNIKEv2IntegrityAlgorithm = .SHA256
    open var lifetimeMinutes: Int32 = 1440
    open var postQuantumKeyExchangeMethods: [NEVPNIKEv2PostQuantumKeyExchangeMethod] = []
}

open class NEVPNIKEv2PPKConfiguration: NSObject {
    public let identifier: String
    public let keychainReference: Data
    open var isMandatory = true

    public init(identifier: String, keychainReference: Data) {
        self.identifier = identifier
        self.keychainReference = keychainReference
        super.init()
    }
}

open class NEVPNProtocolIPSec: NEVPNProtocol {
    open var authenticationMethod: NEVPNIKEAuthenticationMethod = .none
    open var localIdentifier: String?
    open var remoteIdentifier: String?
    open var sharedSecretReference: Data?
    open var useExtendedAuthentication = false
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
}

open class NETunnelProviderProtocol: NEVPNProtocol {
    open var providerBundleIdentifier: String?
    open var providerConfiguration: [String: Any]?
}

open class NEDNSProxyProviderProtocol: NEVPNProtocol {
    open var providerBundleIdentifier: String?
    open var providerConfiguration: [String: Any]?
}
