public enum NEVPNStatus: Int, Sendable, Hashable {
    case invalid = 0
    case disconnected = 1
    case connecting = 2
    case connected = 3
    case reasserting = 4
    case disconnecting = 5
}

public enum NEProviderStopReason: Int, Sendable, Hashable {
    case none = 0
    case userInitiated = 1
    case providerFailed = 2
    case noNetworkAvailable = 3
    case unrecoverableNetworkChange = 4
    case providerDisabled = 5
    case authenticationCanceled = 6
    case configurationFailed = 7
    case idleTimeout = 8
    case configurationDisabled = 9
    case configurationRemoved = 10
    case superceded = 11
    case userLogout = 12
    case userSwitch = 13
    case connectionFailed = 14
    case sleep = 15
    case appUpdate = 16
    case internalError = 17
}

public enum NEOnDemandRuleAction: Int, Sendable, Hashable {
    case connect = 1
    case disconnect = 2
    case evaluateConnection = 3
    case ignore = 4
}

public enum NEOnDemandRuleInterfaceType: Int, Sendable, Hashable {
    case any = 0
    case wiFi = 2
    case cellular = 3
}

public enum NEEvaluateConnectionRuleAction: Int, Sendable, Hashable {
    case connectIfNeeded = 1
    case neverConnect = 2
}

public enum NEFilterAction: Int, Sendable, Hashable {
    case invalid = 0
    case allow = 1
    case drop = 2
    case remediate = 3
    case filterData = 4
}

public enum NETrafficDirection: Int, Sendable, Hashable {
    case any = 0
    case inbound = 1
    case outbound = 2
}

public enum NETunnelProviderRoutingMethod: Int, Sendable, Hashable {
    case destinationIP = 1
    case sourceApplication = 2
}

public enum NEDNSProtocol: Int, Sendable, Hashable {
    case cleartext = 1
    case TLS = 2
    case HTTPS = 3
}

public enum NEVPNIKEAuthenticationMethod: Int, Sendable, Hashable {
    case none = 0
    case certificate = 1
    case sharedSecret = 2
}

public enum NEVPNIKEv2CertificateType: Int, Sendable, Hashable {
    case RSA = 1
    case ECDSA256 = 2
    case ECDSA384 = 3
    case ECDSA521 = 4
    case ed25519 = 5
    case RSAPSS = 6
}

public enum NEVPNIKEv2DeadPeerDetectionRate: Int, Sendable, Hashable {
    case none = 0
    case low = 1
    case medium = 2
    case high = 3
}

public enum NEVPNIKEv2DiffieHellmanGroup: Int, Sendable, Hashable {
    case groupInvalid = 0
    case group14 = 14
    case group15 = 15
    case group16 = 16
    case group17 = 17
    case group18 = 18
    case group19 = 19
    case group20 = 20
    case group21 = 21
    case group31 = 31
    case group32 = 32
}

public enum NEVPNIKEv2EncryptionAlgorithm: Int, Sendable, Hashable {
    case algorithmAES128 = 3
    case algorithmAES256 = 4
    case algorithmAES128GCM = 5
    case algorithmAES256GCM = 6
    case algorithmChaCha20Poly1305 = 7
}

public enum NEVPNIKEv2IntegrityAlgorithm: Int, Sendable, Hashable {
    case SHA256 = 3
    case SHA384 = 4
    case SHA512 = 5
}

public enum NEVPNIKEv2PostQuantumKeyExchangeMethod: Int, Sendable, Hashable {
    case methodNone = 0
    case method36 = 36
    case method37 = 37
}

public enum NEVPNIKEv2TLSVersion: Int, Sendable, Hashable {
    case versionDefault = 0
    case version1_0 = 1
    case version1_1 = 2
    case version1_2 = 3
}

public enum NWPathStatus: Int, Sendable, Hashable {
    case invalid = 0
    case satisfied = 1
    case unsatisfied = 2
    case satisfiable = 3
}

public enum NWTCPConnectionState: Int, Sendable, Hashable {
    case invalid = 0
    case connecting = 1
    case waiting = 2
    case connected = 3
    case disconnected = 4
    case cancelled = 5
}

public enum NWUDPSessionState: Int, Sendable, Hashable {
    case invalid = 0
    case waiting = 1
    case preparing = 2
    case ready = 3
    case failed = 4
    case cancelled = 5
}

public enum NEFilterManagerError: Int, Sendable, Hashable, Error {
    case configurationInvalid = 1
    case configurationDisabled = 2
    case configurationStale = 3
    case configurationCannotBeRemoved = 4
    case configurationPermissionDenied = 5
    case configurationInternalError = 6
}

public enum NEDNSProxyManagerError: Int, Sendable, Hashable, Error {
    case configurationInvalid = 1
    case configurationDisabled = 2
    case configurationStale = 3
    case configurationCannotBeRemoved = 4
}

public enum NEDNSSettingsManagerError: Int, Sendable, Hashable, Error {
    case configurationInvalid = 1
    case configurationDisabled = 2
    case configurationStale = 3
    case configurationCannotBeRemoved = 4
}

public enum NERelayManagerError: Int, Sendable, Hashable, Error {
    case configurationInvalid = 1
    case configurationDisabled = 2
    case configurationStale = 3
    case configurationCannotBeRemoved = 4
}

public enum NERelayManagerClientError: Int, Sendable, Hashable, Error {
    case none = 0
    case dnsFailed = 1
    case serverUnreachable = 2
    case serverDisconnected = 3
    case certificateInvalid = 4
    case certificateExpired = 5
    case certificateMissing = 6
    case serverCertificateInvalid = 7
    case serverCertificateExpired = 8
    case other = 9
}

public enum NEVPNConnectionError: Int, Sendable, Hashable, Error {
    case overslept = 1
    case noNetworkAvailable = 2
    case unrecoverableNetworkChange = 3
    case configurationFailed = 4
    case serverAddressResolutionFailed = 5
    case serverNotResponding = 6
    case serverDead = 7
    case authenticationFailed = 8
    case clientCertificateInvalid = 9
    case clientCertificateNotYetValid = 10
    case clientCertificateExpired = 11
    case pluginFailed = 12
    case configurationNotFound = 13
    case pluginDisabled = 14
    case negotiationFailed = 15
    case serverDisconnected = 16
    case serverCertificateInvalid = 17
    case serverCertificateNotYetValid = 18
    case serverCertificateExpired = 19
}

public enum NEHotspotConfigurationError: Int, Sendable, Hashable, Error {
    case unknown = 0
    case invalid = 1
    case invalidSSID = 2
    case invalidWPAPassphrase = 3
    case invalidWEPPassphrase = 4
    case invalidEAPSettings = 5
    case invalidHS20Settings = 6
    case invalidHS20DomainName = 7
    case userDenied = 8
    case `internal` = 9
    case pending = 10
    case systemConfiguration = 11
    case alreadyAssociated = 12
    case applicationIsNotInForeground = 13
    case invalidSSIDPrefix = 14
    case userUnauthorized = 15
    case joinOnceNotSupported = 16
    case systemDenied = 17
}

public enum NEHotspotHelperCommandType: Int, Sendable, Hashable {
    case none = 0
    case filterScanList = 1
    case evaluate = 2
    case authenticate = 3
    case presentUI = 4
    case maintain = 5
    case logoff = 6
}

public enum NEHotspotHelperConfidence: Int, Sendable, Hashable {
    case none = 0
    case low = 1
    case high = 2
}

public enum NEHotspotHelperResult: Int, Sendable, Hashable {
    case success = 0
    case failure = 1
    case commandNotRecognized = 3
    case authenticationRequired = 4
    case temporaryFailure = 6
}

public enum NEHotspotNetworkSecurityType: Int, Sendable, Hashable {
    case unknown = 0
    case open = 1
    case WEP = 2
    case personal = 3
    case enterprise = 4
}
