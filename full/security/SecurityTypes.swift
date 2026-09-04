import Foundation

public typealias SSLCipherSuite = UInt16
public typealias SecTrustCallback = (SecTrust, SecTrustResultType) -> Void
public typealias SecTrustWithErrorCallback = (SecTrust, Bool, CFError?) -> Void

public enum SSLCiphersuiteGroup: Int32, Sendable {
    case `default` = 0
    case compatibility = 1
    case legacy = 2
    case ATS = 3
    case atsCompatibility = 4
}

public enum SSLProtocol: Int32, Sendable {
    case sslProtocolUnknown = 0
    case sslProtocol2 = 1
    case sslProtocol3 = 2
    case sslProtocol3Only = 3
    case tlsProtocol1 = 4
    case tlsProtocol1Only = 5
    case sslProtocolAll = 6
    case tlsProtocol11 = 7
    case tlsProtocol12 = 8
    case dtlsProtocol1 = 9
    case tlsProtocol13 = 10
    case dtlsProtocol12 = 11
    case tlsProtocolMaxSupported = 999
}

public enum tls_ciphersuite_group_t: UInt16, Sendable {
    case `default` = 0
    case compatibility = 1
    case legacy = 2
    case ats = 3
    case ats_compatibility = 4
}

public enum tls_protocol_version_t: UInt16, Sendable {
    case TLSv10 = 0x0301
    case TLSv11 = 0x0302
    case TLSv12 = 0x0303
    case TLSv13 = 0x0304
    case DTLSv12 = 0xFEFD
    case DTLSv10 = 0xFEFF
}

public enum SecKeyOperationType: CFIndex, Sendable {
    case sign = 0
    case verify = 1
    case encrypt = 2
    case decrypt = 3
    case keyExchange = 4
}

public enum SecTrustResultType: UInt32, Sendable {
    case invalid = 0
    case proceed = 1
    case deny = 3
    case unspecified = 4
    case recoverableTrustFailure = 5
    case fatalTrustFailure = 6
    case otherError = 7
}

public struct SecAccessControlCreateFlags: OptionSet, Sendable {
    public let rawValue: CFOptionFlags

    public init(rawValue: CFOptionFlags) {
        self.rawValue = rawValue
    }

    public static let userPresence = SecAccessControlCreateFlags(rawValue: 1 << 0)
    public static let biometryAny = SecAccessControlCreateFlags(rawValue: 1 << 1)
    public static let biometryCurrentSet = SecAccessControlCreateFlags(rawValue: 1 << 3)
    public static let devicePasscode = SecAccessControlCreateFlags(rawValue: 1 << 4)
    public static let companion = SecAccessControlCreateFlags(rawValue: 1 << 5)
    public static let or = SecAccessControlCreateFlags(rawValue: 1 << 14)
    public static let and = SecAccessControlCreateFlags(rawValue: 1 << 15)
    public static let privateKeyUsage = SecAccessControlCreateFlags(rawValue: 1 << 30)
    public static let applicationPassword = SecAccessControlCreateFlags(rawValue: 1 << 31)
    public static let touchIDAny = biometryAny
    public static let touchIDCurrentSet = biometryCurrentSet
}

public struct SecPadding: OptionSet, Sendable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public static let PKCS1 = SecPadding(rawValue: 1)
    public static let OAEP = SecPadding(rawValue: 2)
    public static let sigRaw = SecPadding(rawValue: 0x4000)
    public static let PKCS1MD2 = SecPadding(rawValue: 0x8000)
    public static let PKCS1MD5 = SecPadding(rawValue: 0x8001)
    public static let PKCS1SHA1 = SecPadding(rawValue: 0x8002)
    public static let PKCS1SHA224 = SecPadding(rawValue: 0x8003)
    public static let PKCS1SHA256 = SecPadding(rawValue: 0x8004)
    public static let PKCS1SHA384 = SecPadding(rawValue: 0x8005)
    public static let PKCS1SHA512 = SecPadding(rawValue: 0x8006)
}

public struct SecKeyAlgorithm: RawRepresentable, Hashable, Sendable {
    public let rawValue: CFString

    public init(rawValue: CFString) {
        self.rawValue = rawValue
    }
}

public struct SecKeyKeyExchangeParameter: RawRepresentable, Hashable, Sendable {
    public let rawValue: CFString

    public init(rawValue: CFString) {
        self.rawValue = rawValue
    }

    public static let requestedSize = SecKeyKeyExchangeParameter(rawValue: "requestedSize")
    public static let sharedInfo = SecKeyKeyExchangeParameter(rawValue: "sharedInfo")
}

public protocol OS_sec_object: NSObjectProtocol {}
public protocol OS_sec_certificate: NSObjectProtocol {}
public protocol OS_sec_identity: NSObjectProtocol {}
public protocol OS_sec_trust: NSObjectProtocol {}
public protocol OS_sec_protocol_metadata: NSObjectProtocol {}
public protocol OS_sec_protocol_options: NSObjectProtocol {}

public typealias sec_object_t = any OS_sec_object
public typealias sec_certificate_t = any OS_sec_certificate
public typealias sec_identity_t = any OS_sec_identity
public typealias sec_trust_t = any OS_sec_trust
public typealias sec_protocol_metadata_t = any OS_sec_protocol_metadata
public typealias sec_protocol_options_t = any OS_sec_protocol_options
public typealias sec_protocol_challenge_complete_t = (sec_identity_t?) -> Void
public typealias sec_protocol_challenge_t = (sec_protocol_metadata_t, @escaping sec_protocol_challenge_complete_t) -> Void
public typealias sec_protocol_key_update_complete_t = () -> Void
public typealias sec_protocol_key_update_t = (sec_protocol_metadata_t, @escaping sec_protocol_key_update_complete_t) -> Void
public typealias sec_protocol_verify_complete_t = (Bool) -> Void
public typealias sec_protocol_verify_t = (sec_protocol_metadata_t, sec_trust_t, @escaping sec_protocol_verify_complete_t) -> Void

public final class SecAccessControl: Hashable, @unchecked Sendable {
    let _id = ObjectIdentifier(NSObject())
    init() {}
    public static func == (left: SecAccessControl, right: SecAccessControl) -> Bool { left === right }
    public static func != (left: SecAccessControl, right: SecAccessControl) -> Bool { left !== right }
    public func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(self)) }
    public var hashValue: Int { ObjectIdentifier(self).hashValue }
}

public final class SecCertificate: Hashable, @unchecked Sendable {
    let data: Data
    init(data: Data) { self.data = data }
    public static func == (left: SecCertificate, right: SecCertificate) -> Bool { left === right }
    public static func != (left: SecCertificate, right: SecCertificate) -> Bool { left !== right }
    public func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(self)) }
    public var hashValue: Int { ObjectIdentifier(self).hashValue }
}

public final class SecIdentity: Hashable, @unchecked Sendable {
    let certificate: SecCertificate
    let privateKey: SecKey
    init(certificate: SecCertificate, privateKey: SecKey) {
        self.certificate = certificate
        self.privateKey = privateKey
    }
    public static func == (left: SecIdentity, right: SecIdentity) -> Bool { left === right }
    public static func != (left: SecIdentity, right: SecIdentity) -> Bool { left !== right }
    public func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(self)) }
    public var hashValue: Int { ObjectIdentifier(self).hashValue }
}

public final class SecKey: Hashable, @unchecked Sendable {
    let attributes: [String: Any]
    let material: Data
    init(attributes: [String: Any], material: Data) {
        self.attributes = attributes
        self.material = material
    }
    public static func == (left: SecKey, right: SecKey) -> Bool { left === right }
    public static func != (left: SecKey, right: SecKey) -> Bool { left !== right }
    public func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(self)) }
    public var hashValue: Int { ObjectIdentifier(self).hashValue }
}

public final class SecPolicy: Hashable, @unchecked Sendable {
    let identifier: String
    let properties: [String: Any]
    init(identifier: String, properties: [String: Any] = [:]) {
        self.identifier = identifier
        self.properties = properties
    }
    public static func == (left: SecPolicy, right: SecPolicy) -> Bool { left === right }
    public static func != (left: SecPolicy, right: SecPolicy) -> Bool { left !== right }
    public func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(self)) }
    public var hashValue: Int { ObjectIdentifier(self).hashValue }
}

public final class SecTrust: Hashable, @unchecked Sendable {
    var certificates: [SecCertificate]
    var policies: [SecPolicy]
    var anchors: [SecCertificate] = []
    var anchorsOnly = false
    var networkFetchAllowed = false
    var verifyDate: Date?
    var exceptions: Data?
    var ocsp: CFTypeRef?
    var scts: CFArray?
    var lastResult: SecTrustResultType = .invalid
    init(certificates: [SecCertificate], policies: [SecPolicy]) {
        self.certificates = certificates
        self.policies = policies
    }
    public static func == (left: SecTrust, right: SecTrust) -> Bool { left === right }
    public static func != (left: SecTrust, right: SecTrust) -> Bool { left !== right }
    public func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(self)) }
    public var hashValue: Int { ObjectIdentifier(self).hashValue }
}

final class _OSSecObject: NSObject, OS_sec_object {}
final class _OSSecCertificate: NSObject, OS_sec_certificate {
    let certificate: SecCertificate
    init(certificate: SecCertificate) { self.certificate = certificate }
}
final class _OSSecIdentity: NSObject, OS_sec_identity {
    let identity: SecIdentity
    let certificates: [SecCertificate]
    init(identity: SecIdentity, certificates: [SecCertificate] = []) {
        self.identity = identity
        self.certificates = certificates
    }
}
final class _OSSecTrust: NSObject, OS_sec_trust {
    let trust: SecTrust
    init(trust: SecTrust) { self.trust = trust }
}
final class _OSSecProtocolMetadata: NSObject, OS_sec_protocol_metadata {}
final class _OSSecProtocolOptions: NSObject, OS_sec_protocol_options {
    var minVersion: tls_protocol_version_t = .TLSv12
    var maxVersion: tls_protocol_version_t = .TLSv13
    var minSSL: SSLProtocol = .tlsProtocol12
    var maxSSL: SSLProtocol = .tlsProtocol13
    var peerAuth = false
    var falseStart = false
    var fallback = false
    var ocsp = false
    var renegotiation = false
    var resumption = false
    var sct = false
    var tickets = false
    var serverName: String?
    var identity: sec_identity_t?
    var ciphers: [UInt16] = []
}

private let _typeSecAccessControl: CFTypeID = 0x53414331
private let _typeSecCertificate: CFTypeID = 0x53434532
private let _typeSecIdentity: CFTypeID = 0x53494433
private let _typeSecKey: CFTypeID = 0x534B5934
private let _typeSecPolicy: CFTypeID = 0x53504F35
private let _typeSecTrust: CFTypeID = 0x53545236

func _secTypeAccessControl() -> CFTypeID { _typeSecAccessControl }
func _secTypeCertificate() -> CFTypeID { _typeSecCertificate }
func _secTypeIdentity() -> CFTypeID { _typeSecIdentity }
func _secTypeKey() -> CFTypeID { _typeSecKey }
func _secTypePolicy() -> CFTypeID { _typeSecPolicy }
func _secTypeTrust() -> CFTypeID { _typeSecTrust }
import Foundation

extension SecKeyAlgorithm {
    public static let ecdhKeyExchangeCofactor = SecKeyAlgorithm(rawValue: "ecdhKeyExchangeCofactor")
    public static let ecdhKeyExchangeCofactorX963SHA1 = SecKeyAlgorithm(rawValue: "ecdhKeyExchangeCofactorX963SHA1")
    public static let ecdhKeyExchangeCofactorX963SHA224 = SecKeyAlgorithm(rawValue: "ecdhKeyExchangeCofactorX963SHA224")
    public static let ecdhKeyExchangeCofactorX963SHA256 = SecKeyAlgorithm(rawValue: "ecdhKeyExchangeCofactorX963SHA256")
    public static let ecdhKeyExchangeCofactorX963SHA384 = SecKeyAlgorithm(rawValue: "ecdhKeyExchangeCofactorX963SHA384")
    public static let ecdhKeyExchangeCofactorX963SHA512 = SecKeyAlgorithm(rawValue: "ecdhKeyExchangeCofactorX963SHA512")
    public static let ecdhKeyExchangeStandard = SecKeyAlgorithm(rawValue: "ecdhKeyExchangeStandard")
    public static let ecdhKeyExchangeStandardX963SHA1 = SecKeyAlgorithm(rawValue: "ecdhKeyExchangeStandardX963SHA1")
    public static let ecdhKeyExchangeStandardX963SHA224 = SecKeyAlgorithm(rawValue: "ecdhKeyExchangeStandardX963SHA224")
    public static let ecdhKeyExchangeStandardX963SHA256 = SecKeyAlgorithm(rawValue: "ecdhKeyExchangeStandardX963SHA256")
    public static let ecdhKeyExchangeStandardX963SHA384 = SecKeyAlgorithm(rawValue: "ecdhKeyExchangeStandardX963SHA384")
    public static let ecdhKeyExchangeStandardX963SHA512 = SecKeyAlgorithm(rawValue: "ecdhKeyExchangeStandardX963SHA512")
    public static let ecdsaSignatureDigestRFC4754 = SecKeyAlgorithm(rawValue: "ecdsaSignatureDigestRFC4754")
    public static let ecdsaSignatureDigestRFC4754SHA1 = SecKeyAlgorithm(rawValue: "ecdsaSignatureDigestRFC4754SHA1")
    public static let ecdsaSignatureDigestRFC4754SHA224 = SecKeyAlgorithm(rawValue: "ecdsaSignatureDigestRFC4754SHA224")
    public static let ecdsaSignatureDigestRFC4754SHA256 = SecKeyAlgorithm(rawValue: "ecdsaSignatureDigestRFC4754SHA256")
    public static let ecdsaSignatureDigestRFC4754SHA384 = SecKeyAlgorithm(rawValue: "ecdsaSignatureDigestRFC4754SHA384")
    public static let ecdsaSignatureDigestRFC4754SHA512 = SecKeyAlgorithm(rawValue: "ecdsaSignatureDigestRFC4754SHA512")
    public static let ecdsaSignatureDigestX962 = SecKeyAlgorithm(rawValue: "ecdsaSignatureDigestX962")
    public static let ecdsaSignatureDigestX962SHA1 = SecKeyAlgorithm(rawValue: "ecdsaSignatureDigestX962SHA1")
    public static let ecdsaSignatureDigestX962SHA224 = SecKeyAlgorithm(rawValue: "ecdsaSignatureDigestX962SHA224")
    public static let ecdsaSignatureDigestX962SHA256 = SecKeyAlgorithm(rawValue: "ecdsaSignatureDigestX962SHA256")
    public static let ecdsaSignatureDigestX962SHA384 = SecKeyAlgorithm(rawValue: "ecdsaSignatureDigestX962SHA384")
    public static let ecdsaSignatureDigestX962SHA512 = SecKeyAlgorithm(rawValue: "ecdsaSignatureDigestX962SHA512")
    public static let ecdsaSignatureMessageRFC4754SHA1 = SecKeyAlgorithm(rawValue: "ecdsaSignatureMessageRFC4754SHA1")
    public static let ecdsaSignatureMessageRFC4754SHA224 = SecKeyAlgorithm(rawValue: "ecdsaSignatureMessageRFC4754SHA224")
    public static let ecdsaSignatureMessageRFC4754SHA256 = SecKeyAlgorithm(rawValue: "ecdsaSignatureMessageRFC4754SHA256")
    public static let ecdsaSignatureMessageRFC4754SHA384 = SecKeyAlgorithm(rawValue: "ecdsaSignatureMessageRFC4754SHA384")
    public static let ecdsaSignatureMessageRFC4754SHA512 = SecKeyAlgorithm(rawValue: "ecdsaSignatureMessageRFC4754SHA512")
    public static let ecdsaSignatureMessageX962SHA1 = SecKeyAlgorithm(rawValue: "ecdsaSignatureMessageX962SHA1")
    public static let ecdsaSignatureMessageX962SHA224 = SecKeyAlgorithm(rawValue: "ecdsaSignatureMessageX962SHA224")
    public static let ecdsaSignatureMessageX962SHA256 = SecKeyAlgorithm(rawValue: "ecdsaSignatureMessageX962SHA256")
    public static let ecdsaSignatureMessageX962SHA384 = SecKeyAlgorithm(rawValue: "ecdsaSignatureMessageX962SHA384")
    public static let ecdsaSignatureMessageX962SHA512 = SecKeyAlgorithm(rawValue: "ecdsaSignatureMessageX962SHA512")
    public static let ecdsaSignatureRFC4754 = SecKeyAlgorithm(rawValue: "ecdsaSignatureRFC4754")
    public static let eciesEncryptionCofactorVariableIVX963SHA224AESGCM = SecKeyAlgorithm(rawValue: "eciesEncryptionCofactorVariableIVX963SHA224AESGCM")
    public static let eciesEncryptionCofactorVariableIVX963SHA256AESGCM = SecKeyAlgorithm(rawValue: "eciesEncryptionCofactorVariableIVX963SHA256AESGCM")
    public static let eciesEncryptionCofactorVariableIVX963SHA384AESGCM = SecKeyAlgorithm(rawValue: "eciesEncryptionCofactorVariableIVX963SHA384AESGCM")
    public static let eciesEncryptionCofactorVariableIVX963SHA512AESGCM = SecKeyAlgorithm(rawValue: "eciesEncryptionCofactorVariableIVX963SHA512AESGCM")
    public static let eciesEncryptionCofactorX963SHA1AESGCM = SecKeyAlgorithm(rawValue: "eciesEncryptionCofactorX963SHA1AESGCM")
    public static let eciesEncryptionCofactorX963SHA224AESGCM = SecKeyAlgorithm(rawValue: "eciesEncryptionCofactorX963SHA224AESGCM")
    public static let eciesEncryptionCofactorX963SHA256AESGCM = SecKeyAlgorithm(rawValue: "eciesEncryptionCofactorX963SHA256AESGCM")
    public static let eciesEncryptionCofactorX963SHA384AESGCM = SecKeyAlgorithm(rawValue: "eciesEncryptionCofactorX963SHA384AESGCM")
    public static let eciesEncryptionCofactorX963SHA512AESGCM = SecKeyAlgorithm(rawValue: "eciesEncryptionCofactorX963SHA512AESGCM")
    public static let eciesEncryptionStandardVariableIVX963SHA224AESGCM = SecKeyAlgorithm(rawValue: "eciesEncryptionStandardVariableIVX963SHA224AESGCM")
    public static let eciesEncryptionStandardVariableIVX963SHA256AESGCM = SecKeyAlgorithm(rawValue: "eciesEncryptionStandardVariableIVX963SHA256AESGCM")
    public static let eciesEncryptionStandardVariableIVX963SHA384AESGCM = SecKeyAlgorithm(rawValue: "eciesEncryptionStandardVariableIVX963SHA384AESGCM")
    public static let eciesEncryptionStandardVariableIVX963SHA512AESGCM = SecKeyAlgorithm(rawValue: "eciesEncryptionStandardVariableIVX963SHA512AESGCM")
    public static let eciesEncryptionStandardX963SHA1AESGCM = SecKeyAlgorithm(rawValue: "eciesEncryptionStandardX963SHA1AESGCM")
    public static let eciesEncryptionStandardX963SHA224AESGCM = SecKeyAlgorithm(rawValue: "eciesEncryptionStandardX963SHA224AESGCM")
    public static let eciesEncryptionStandardX963SHA256AESGCM = SecKeyAlgorithm(rawValue: "eciesEncryptionStandardX963SHA256AESGCM")
    public static let eciesEncryptionStandardX963SHA384AESGCM = SecKeyAlgorithm(rawValue: "eciesEncryptionStandardX963SHA384AESGCM")
    public static let eciesEncryptionStandardX963SHA512AESGCM = SecKeyAlgorithm(rawValue: "eciesEncryptionStandardX963SHA512AESGCM")
    public static let rsaEncryptionOAEPSHA1 = SecKeyAlgorithm(rawValue: "rsaEncryptionOAEPSHA1")
    public static let rsaEncryptionOAEPSHA1AESGCM = SecKeyAlgorithm(rawValue: "rsaEncryptionOAEPSHA1AESGCM")
    public static let rsaEncryptionOAEPSHA224 = SecKeyAlgorithm(rawValue: "rsaEncryptionOAEPSHA224")
    public static let rsaEncryptionOAEPSHA224AESGCM = SecKeyAlgorithm(rawValue: "rsaEncryptionOAEPSHA224AESGCM")
    public static let rsaEncryptionOAEPSHA256 = SecKeyAlgorithm(rawValue: "rsaEncryptionOAEPSHA256")
    public static let rsaEncryptionOAEPSHA256AESGCM = SecKeyAlgorithm(rawValue: "rsaEncryptionOAEPSHA256AESGCM")
    public static let rsaEncryptionOAEPSHA384 = SecKeyAlgorithm(rawValue: "rsaEncryptionOAEPSHA384")
    public static let rsaEncryptionOAEPSHA384AESGCM = SecKeyAlgorithm(rawValue: "rsaEncryptionOAEPSHA384AESGCM")
    public static let rsaEncryptionOAEPSHA512 = SecKeyAlgorithm(rawValue: "rsaEncryptionOAEPSHA512")
    public static let rsaEncryptionOAEPSHA512AESGCM = SecKeyAlgorithm(rawValue: "rsaEncryptionOAEPSHA512AESGCM")
    public static let rsaEncryptionPKCS1 = SecKeyAlgorithm(rawValue: "rsaEncryptionPKCS1")
    public static let rsaEncryptionRaw = SecKeyAlgorithm(rawValue: "rsaEncryptionRaw")
    public static let rsaSignatureDigestPKCS1v15Raw = SecKeyAlgorithm(rawValue: "rsaSignatureDigestPKCS1v15Raw")
    public static let rsaSignatureDigestPKCS1v15SHA1 = SecKeyAlgorithm(rawValue: "rsaSignatureDigestPKCS1v15SHA1")
    public static let rsaSignatureDigestPKCS1v15SHA224 = SecKeyAlgorithm(rawValue: "rsaSignatureDigestPKCS1v15SHA224")
    public static let rsaSignatureDigestPKCS1v15SHA256 = SecKeyAlgorithm(rawValue: "rsaSignatureDigestPKCS1v15SHA256")
    public static let rsaSignatureDigestPKCS1v15SHA384 = SecKeyAlgorithm(rawValue: "rsaSignatureDigestPKCS1v15SHA384")
    public static let rsaSignatureDigestPKCS1v15SHA512 = SecKeyAlgorithm(rawValue: "rsaSignatureDigestPKCS1v15SHA512")
    public static let rsaSignatureDigestPSSSHA1 = SecKeyAlgorithm(rawValue: "rsaSignatureDigestPSSSHA1")
    public static let rsaSignatureDigestPSSSHA224 = SecKeyAlgorithm(rawValue: "rsaSignatureDigestPSSSHA224")
    public static let rsaSignatureDigestPSSSHA256 = SecKeyAlgorithm(rawValue: "rsaSignatureDigestPSSSHA256")
    public static let rsaSignatureDigestPSSSHA384 = SecKeyAlgorithm(rawValue: "rsaSignatureDigestPSSSHA384")
    public static let rsaSignatureDigestPSSSHA512 = SecKeyAlgorithm(rawValue: "rsaSignatureDigestPSSSHA512")
    public static let rsaSignatureMessagePKCS1v15SHA1 = SecKeyAlgorithm(rawValue: "rsaSignatureMessagePKCS1v15SHA1")
    public static let rsaSignatureMessagePKCS1v15SHA224 = SecKeyAlgorithm(rawValue: "rsaSignatureMessagePKCS1v15SHA224")
    public static let rsaSignatureMessagePKCS1v15SHA256 = SecKeyAlgorithm(rawValue: "rsaSignatureMessagePKCS1v15SHA256")
    public static let rsaSignatureMessagePKCS1v15SHA384 = SecKeyAlgorithm(rawValue: "rsaSignatureMessagePKCS1v15SHA384")
    public static let rsaSignatureMessagePKCS1v15SHA512 = SecKeyAlgorithm(rawValue: "rsaSignatureMessagePKCS1v15SHA512")
    public static let rsaSignatureMessagePSSSHA1 = SecKeyAlgorithm(rawValue: "rsaSignatureMessagePSSSHA1")
    public static let rsaSignatureMessagePSSSHA224 = SecKeyAlgorithm(rawValue: "rsaSignatureMessagePSSSHA224")
    public static let rsaSignatureMessagePSSSHA256 = SecKeyAlgorithm(rawValue: "rsaSignatureMessagePSSSHA256")
    public static let rsaSignatureMessagePSSSHA384 = SecKeyAlgorithm(rawValue: "rsaSignatureMessagePSSSHA384")
    public static let rsaSignatureMessagePSSSHA512 = SecKeyAlgorithm(rawValue: "rsaSignatureMessagePSSSHA512")
    public static let rsaSignatureRaw = SecKeyAlgorithm(rawValue: "rsaSignatureRaw")
}

import Foundation

public enum tls_ciphersuite_t: UInt16, Sendable {
    case AES_128_GCM_SHA256 = 4865
    case AES_256_GCM_SHA384 = 4866
    case CHACHA20_POLY1305_SHA256 = 4867
    case ECDHE_ECDSA_WITH_3DES_EDE_CBC_SHA = 49160
    case ECDHE_ECDSA_WITH_AES_128_CBC_SHA = 49161
    case ECDHE_ECDSA_WITH_AES_128_CBC_SHA256 = 49187
    case ECDHE_ECDSA_WITH_AES_128_GCM_SHA256 = 49195
    case ECDHE_ECDSA_WITH_AES_256_CBC_SHA = 49162
    case ECDHE_ECDSA_WITH_AES_256_CBC_SHA384 = 49188
    case ECDHE_ECDSA_WITH_AES_256_GCM_SHA384 = 49196
    case ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256 = 52393
    case ECDHE_RSA_WITH_3DES_EDE_CBC_SHA = 49170
    case ECDHE_RSA_WITH_AES_128_CBC_SHA = 49171
    case ECDHE_RSA_WITH_AES_128_CBC_SHA256 = 49191
    case ECDHE_RSA_WITH_AES_128_GCM_SHA256 = 49199
    case ECDHE_RSA_WITH_AES_256_CBC_SHA = 49172
    case ECDHE_RSA_WITH_AES_256_CBC_SHA384 = 49192
    case ECDHE_RSA_WITH_AES_256_GCM_SHA384 = 49200
    case ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256 = 52392
    case RSA_WITH_3DES_EDE_CBC_SHA = 10
    case RSA_WITH_AES_128_CBC_SHA = 47
    case RSA_WITH_AES_128_CBC_SHA256 = 60
    case RSA_WITH_AES_128_GCM_SHA256 = 156
    case RSA_WITH_AES_256_CBC_SHA = 53
    case RSA_WITH_AES_256_CBC_SHA256 = 61
    case RSA_WITH_AES_256_GCM_SHA384 = 157
}
