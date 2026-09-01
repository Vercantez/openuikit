open class NEPrivateLTENetwork: NSObject {
    open var mobileCountryCode = ""
    open var mobileNetworkCode = ""
    open var trackingAreaCode: String?
}

open class NEHotspotEAPSettings: NSObject {
    public enum TLSVersion: Int, Sendable, Hashable {
        case version1_0 = 0
        case version1_1 = 1
        case version1_2 = 2
    }

    public enum EAPType: Int, Sendable, Hashable {
        case EAPTLS = 13
        case EAPTTLS = 21
        case EAPPEAP = 25
        case EAPFAST = 43
    }

    public enum TTLSInnerAuthenticationType: Int, Sendable, Hashable {
        case eapttlsInnerAuthenticationPAP = 0
        case eapttlsInnerAuthenticationCHAP = 1
        case eapttlsInnerAuthenticationMSCHAP = 2
        case eapttlsInnerAuthenticationMSCHAPv2 = 3
        case eapttlsInnerAuthenticationEAP = 4
    }

    open var outerIdentity = ""
    open var password = ""
    open var preferredTLSVersion: TLSVersion = .version1_2
    open var supportedEAPTypes: [NSNumber] = []
    open var isTLSClientCertificateRequired = false
    open var trustedServerNames: [String] = []
    open var ttlsInnerAuthenticationType: TTLSInnerAuthenticationType =
        .eapttlsInnerAuthenticationMSCHAPv2
    open var username = ""

    open func setTrustedServerCertificates(_ certificates: [Any]) -> Bool {
        _ = certificates
        return false
    }
}

open class NEHotspotHS20Settings: NSObject {
    public let domainName: String
    open var isRoamingEnabled: Bool
    open var mccAndMNCs: [String] = []
    open var naiRealmNames: [String] = []
    open var roamingConsortiumOIs: [String] = []

    public init(domainName: String, roamingEnabled: Bool) {
        self.domainName = domainName
        isRoamingEnabled = roamingEnabled
        super.init()
    }
}

open class NEHotspotConfiguration: NSObject {
    public let ssid: String
    public let ssidPrefix: String
    open var hidden = false
    open var joinOnce = false
    open var lifeTimeInDays: NSNumber = 1

    public init(ssid SSID: String) {
        ssid = SSID
        ssidPrefix = ""
        super.init()
    }

    public init(SSID: String) {
        ssid = SSID
        ssidPrefix = ""
        super.init()
    }

    public init(ssid SSID: String, passphrase: String, isWEP: Bool) {
        _ = (passphrase, isWEP)
        ssid = SSID
        ssidPrefix = ""
        super.init()
    }

    public init(SSID: String, passphrase: String, isWEP: Bool) {
        _ = (passphrase, isWEP)
        ssid = SSID
        ssidPrefix = ""
        super.init()
    }

    public init(ssid SSID: String, eapSettings: NEHotspotEAPSettings) {
        _ = eapSettings
        ssid = SSID
        ssidPrefix = ""
        super.init()
    }

    public init(SSID: String, eapSettings: NEHotspotEAPSettings) {
        _ = eapSettings
        ssid = SSID
        ssidPrefix = ""
        super.init()
    }

    public init(ssidPrefix SSIDPrefix: String) {
        ssid = ""
        ssidPrefix = SSIDPrefix
        super.init()
    }

    public init(SSIDPrefix: String) {
        ssid = ""
        ssidPrefix = SSIDPrefix
        super.init()
    }

    public init(ssidPrefix SSIDPrefix: String, passphrase: String, isWEP: Bool) {
        _ = (passphrase, isWEP)
        ssid = ""
        ssidPrefix = SSIDPrefix
        super.init()
    }

    public init(SSIDPrefix: String, passphrase: String, isWEP: Bool) {
        _ = (passphrase, isWEP)
        ssid = ""
        ssidPrefix = SSIDPrefix
        super.init()
    }

    public init(hs20Settings: NEHotspotHS20Settings, eapSettings: NEHotspotEAPSettings) {
        _ = eapSettings
        ssid = ""
        ssidPrefix = ""
        super.init()
        _ = hs20Settings
    }

    public init(HS20Settings hs20Settings: NEHotspotHS20Settings, eapSettings: NEHotspotEAPSettings) {
        _ = eapSettings
        ssid = ""
        ssidPrefix = ""
        super.init()
        _ = hs20Settings
    }
}

open class NEHotspotNetwork: NSObject {
    public let ssid: String
    public let bssid: String

    public init(ssid: String = "", bssid: String = "") {
        self.ssid = ssid
        self.bssid = bssid
        super.init()
    }

    open var didAutoJoin: Bool { false }
    open var isChosenHelper: Bool { false }
    open var didJustJoin: Bool { false }
    open var isSecure: Bool { false }
    open var securityType: NEHotspotNetworkSecurityType { .unknown }
    open var signalStrength: Double { 0 }

    open class func fetchCurrent(completionHandler: @escaping (NEHotspotNetwork?) -> Void) {
        completionHandler(nil)
    }

    open func setConfidence(_ confidence: NEHotspotHelperConfidence) {
        _ = confidence
    }

    open func setPassword(_ password: String) {
        _ = password
    }
}

open class NEHotspotHelperResponse: NSObject {
    open func deliver() {}

    open func setNetwork(_ network: NEHotspotNetwork) {
        _ = network
    }

    open func setNetworkList(_ networkList: [NEHotspotNetwork]) {
        _ = networkList
    }
}

open class NEHotspotHelperCommand: NSObject {
    open var commandType: NEHotspotHelperCommandType { .none }
    open var network: NEHotspotNetwork? { nil }
    open var networkList: [NEHotspotNetwork]? { nil }

    open func createResponse(_ result: NEHotspotHelperResult) -> NEHotspotHelperResponse {
        _ = result
        return NEHotspotHelperResponse()
    }

    open func createTCPConnection(_ endpoint: NWEndpoint) -> NWTCPConnection {
        NWTCPConnection(endpoint: endpoint)
    }

    open func createUDPSession(_ endpoint: NWEndpoint) -> NWUDPSession {
        NWUDPSession(endpoint: endpoint)
    }
}

public typealias NEHotspotHelperHandler = (NEHotspotHelperCommand) -> Void

open class NEHotspotHelper: NSObject {
    open class func logoff(_ network: NEHotspotNetwork) -> Bool {
        _ = network
        return false
    }

    open class func register(
        options: [String: NSObject]? = nil,
        queue: DispatchQueue,
        handler: @escaping NEHotspotHelperHandler
    ) -> Bool {
        _ = (options, queue, handler)
        return false
    }

    open class func supportedNetworkInterfaces() -> [Any]? { nil }
}

open class NEHotspotConfigurationManager: NSObject {
    private static let _shared = NEHotspotConfigurationManager()
    open class var shared: NEHotspotConfigurationManager { _shared }

    open func apply(_ configuration: NEHotspotConfiguration) async throws {
        _ = configuration
        throw NEHotspotConfigurationError.internal
    }

    open func configuredSSIDs() async -> [String] { [] }

    open func removeConfiguration(forHS20DomainName domainName: String) {
        _ = domainName
    }

    open func removeConfiguration(forSSID SSID: String) {
        _ = SSID
    }
}

public final class NEHotspotManager: NSObject {
    public enum Error: Swift.Error, Hashable, Sendable, LocalizedError {
        case internalError
        case configurationInvalid
        case configurationNotLoaded

        public var errorDescription: String? { _NEHostBoundary.description }
    }

    private static let _shared = NEHotspotManager()
    public static var shared: NEHotspotManager { _shared }

    public var safariDomains: [String] = []
    public var evaluatedSSIDs: [String] = []
    public var evaluationProviderBundleIdentifier: String?
    public var authenticationProviderBundleIdentifier: String?
    public var isEnabled = false

    public func saveToPreferences() async throws {
        throw Error.configurationInvalid
    }

    public func loadFromPreferences() async throws {
        throw Error.configurationNotLoaded
    }

    public func removeFromPreferences() async throws {
        throw Error.configurationInvalid
    }
}

@MainActor
public class NEHotspotEvaluationProviderConfiguration: NEAppExtensionConfiguration {}

@MainActor
public class NEHotspotAuthenticationProviderConfiguration: NEAppExtensionConfiguration {}

public protocol NEHotspotEvaluationProvider {
    var localizedDisplayName: String { get }
    func handleCommand(_ command: NEHotspotHelperCommand) async -> NEHotspotHelperResponse
    func start() async -> Bool
    func stop(reason: NEProviderStopReason) async
}

public protocol NEHotspotAuthenticationProvider {
    func handleCommand(_ command: NEHotspotHelperCommand) async -> NEHotspotHelperResponse
    func start() async -> Bool
    func stop(reason: NEProviderStopReason) async
}
