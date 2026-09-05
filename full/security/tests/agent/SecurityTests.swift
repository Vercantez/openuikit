import Foundation
#if canImport(Glibc)
import Glibc
#endif
import Security

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fatalError(message)
    }
}

func testKeychainAddCopyUpdateDelete() {
    let itemClass = kSecClassGenericPassword
    let account = "wave5-account"
    let service = "wave5-service"
    let initial = Data("first".utf8)
    let changed = Data("second".utf8)
    _ = SecItemDelete([
        kSecClass: itemClass,
        kSecAttrAccount: account,
        kSecAttrService: service,
    ] as CFDictionary)
    let add: [String: Any] = [
        kSecClass: itemClass,
        kSecAttrAccount: account,
        kSecAttrService: service,
        kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock,
        kSecValueData: initial,
    ]
    require(SecItemAdd(add as CFDictionary, nil) == errSecSuccess, "add")
    require(SecItemAdd(add as CFDictionary, nil) == errSecDuplicateItem, "duplicate")
    var copied: CFTypeRef?
    let one: [String: Any] = [
        kSecClass: itemClass,
        kSecAttrAccount: account,
        kSecAttrService: service,
        kSecReturnData: true,
        kSecMatchLimit: kSecMatchLimitOne,
    ]
    require(SecItemCopyMatching(one as CFDictionary, &copied) == errSecSuccess, "copy")
    require((copied as? Data) == initial, "copy bytes")
    require(
        SecItemUpdate(one as CFDictionary, [kSecValueData: changed] as CFDictionary) == errSecSuccess,
        "update"
    )
    copied = nil
    require(SecItemCopyMatching(one as CFDictionary, &copied) == errSecSuccess, "recopy")
    require((copied as? Data) == changed, "updated bytes")
    require(SecItemDelete(one as CFDictionary) == errSecSuccess, "delete")
    copied = nil
    require(
        SecItemCopyMatching(one as CFDictionary, &copied) == errSecItemNotFound,
        "deleted lookup"
    )
}

func testRandomCopyBytes() {
    var random = [UInt8](repeating: 0, count: 32)
    let status = random.withUnsafeMutableBytes {
        SecRandomCopyBytes(kSecRandomDefault, $0.count, $0.baseAddress!)
    }
    require(status == errSecSuccess, "random status")
    require(random.contains(where: { $0 != 0 }), "random bytes")
}

func testErrorMessageString() {
    require(
        (SecCopyErrorMessageString(errSecItemNotFound, nil) as String?)
            == "The item cannot be found.",
        "error message"
    )
    require(
        (SecCopyErrorMessageString(errSecSuccess, nil) as String?) == "No error.",
        "success message"
    )
}

func testKnownItemKeyStringIdentities() {
    precondition(kSecAttrAccessControl == "accc")
    precondition(kSecAttrAccessGroup == "agrp")
    precondition(kSecAttrAccessible == "pdmn")
    precondition(kSecAttrAccessibleAfterFirstUnlock == "ck")
    precondition(kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly == "cku")
    precondition(kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly == "akpu")
    precondition(kSecAttrAccessibleWhenUnlocked == "ak")
    precondition(kSecAttrAccessibleWhenUnlockedThisDeviceOnly == "aku")
    precondition(kSecAttrAccount == "acct")
    precondition(kSecAttrComment == "icmt")
    precondition(kSecAttrCreationDate == "cdat")
    precondition(kSecAttrCreator == "crtr")
    precondition(kSecAttrDescription == "desc")
    precondition(kSecAttrGeneric == "gena")
    precondition(kSecAttrIsInvisible == "invi")
    precondition(kSecAttrIsNegative == "nega")
    precondition(kSecAttrLabel == "labl")
    precondition(kSecAttrModificationDate == "mdat")
    precondition(kSecAttrService == "svce")
    precondition(kSecAttrSynchronizable == "sync")
    precondition(kSecAttrSynchronizableAny == "syna")
    precondition(kSecAttrType == "type")
    precondition(kSecClass == "class")
    precondition(kSecClassCertificate == "cert")
    precondition(kSecClassGenericPassword == "genp")
    precondition(kSecClassIdentity == "idnt")
    precondition(kSecClassInternetPassword == "inet")
    precondition(kSecClassKey == "keys")
    precondition(kSecMatchLimit == "m_Limit")
    precondition(kSecMatchLimitAll == "m_LimitAll")
    precondition(kSecMatchLimitOne == "m_LimitOne")
    precondition(kSecReturnAttributes == "r_Attributes")
    precondition(kSecReturnData == "r_Data")
    precondition(kSecReturnPersistentRef == "r_PersistentRef")
    precondition(kSecReturnRef == "r_Ref")
    precondition(kSecSharedPassword == "spwd")
    precondition(kSecUseDataProtectionKeychain == "nleg")
    precondition(kSecValueData == "v_Data")
}

func testRevocationFlags() {
    require(kSecRevocationOCSPMethod == 1 << 0, "ocsp")
    require(kSecRevocationCRLMethod == 1 << 1, "crl")
    require(kSecRevocationPreferCRL == 1 << 2, "prefer")
    require(kSecRevocationRequirePositiveResponse == 1 << 3, "positive")
    require(kSecRevocationNetworkAccessDisabled == 1 << 4, "network")
    require(
        kSecRevocationUseAnyAvailableMethod == (kSecRevocationOCSPMethod | kSecRevocationCRLMethod),
        "any"
    )
}

func testIPhoneOSMacroIdentities() {
    require(SECURITY_TYPE_UNIFICATION == 1, "unification")
    require(SEC_OS_IPHONE == 1, "iphone")
    require(SEC_OS_OSX == 0, "osx")
    require(SEC_OS_OSX_INCLUDES == false, "osx includes")
}

func testEnumRawValues() {
    require(SSLProtocol.tlsProtocol12.rawValue == 8, "tls12")
    require(SSLProtocol.tlsProtocol13.rawValue == 10, "tls13")
    require(SSLProtocol.tlsProtocolMaxSupported.rawValue == 999, "max")
    require(tls_protocol_version_t.TLSv12.rawValue == 0x0303, "wire tls12")
    require(tls_protocol_version_t.TLSv13.rawValue == 0x0304, "wire tls13")
    require(tls_protocol_version_t.DTLSv10.rawValue == 0xFEFF, "dtls10")
    require(SecTrustResultType.invalid.rawValue == 0, "invalid")
    require(SecTrustResultType.proceed.rawValue == 1, "proceed")
    require(SecTrustResultType.deny.rawValue == 3, "deny")
    require(SecKeyOperationType.sign.rawValue == 0, "sign")
    require(SecKeyOperationType.keyExchange.rawValue == 4, "kex")
    require(SSLCiphersuiteGroup.ATS.rawValue == 3, "ats")
    require(tls_ciphersuite_group_t.ats.rawValue == 3, "ats group")
    require(tls_ciphersuite_t.AES_128_GCM_SHA256.rawValue == 0x1301, "tls13 aes")
    require(tls_ciphersuite_t.RSA_WITH_AES_128_CBC_SHA.rawValue == 0x002F, "rsa aes")
    require(SSLProtocol(rawValue: 8) == .tlsProtocol12, "failable init")
    require(SSLProtocol(rawValue: 12345) == nil, "unknown raw")
}

func testOptionSets() {
    let flags: SecAccessControlCreateFlags = [.userPresence, .biometryAny]
    require(flags.contains(.userPresence), "contains")
    require(flags.contains(.biometryAny), "bio")
    require(SecAccessControlCreateFlags.touchIDAny == .biometryAny, "touch alias")
    require(!SecAccessControlCreateFlags().contains(.devicePasscode), "empty")
    require(SecPadding.PKCS1.rawValue == 1, "pkcs1")
    require(SecPadding.OAEP.rawValue == 2, "oaep")
    require((SecPadding.PKCS1.union(.OAEP)).contains(.OAEP), "union")
    require(SecAccessControlCreateFlags.applicationPassword.rawValue == 1 << 31, "app password")
}

func testKeyAlgorithmIdentities() {
    require(SecKeyAlgorithm.rsaEncryptionPKCS1.rawValue == "rsaEncryptionPKCS1", "rsa pkcs1")
    require(
        SecKeyAlgorithm.ecdsaSignatureMessageX962SHA256.rawValue
            == "ecdsaSignatureMessageX962SHA256",
        "ecdsa"
    )
    require(SecKeyKeyExchangeParameter.requestedSize.rawValue == "requestedSize", "size")
    require(SecKeyAlgorithm.rsaEncryptionPKCS1 != .rsaEncryptionRaw, "neq")
}

func testCFLikeTypeIdentities() {
    require(SecCertificateGetTypeID() == SecCertificateGetTypeID(), "cert type")
    require(SecPolicyGetTypeID() != SecTrustGetTypeID(), "distinct types")
    require(SecKeyGetTypeID() != 0, "key type")
    let cert = SecCertificateCreateWithData(nil, Data(leafRSACertDER))
    require(cert != nil, "create cert")
    let policy = SecPolicyCreateBasicX509()
    require(SecPolicyGetTypeID() != 0, "policy type")
    _ = policy
}

func testHashableAndEquatable() {
    let left = SecPolicyCreateSSL(true, "example.test")
    let right = SecPolicyCreateSSL(true, "example.test")
    require(left != right, "distinct instances")
    require(left == left, "identity")
    require(left.hashValue == left.hashValue, "hash")
    require(SSLProtocol.tlsProtocol12 == .tlsProtocol12, "enum eq")
    require(SSLProtocol.tlsProtocol12 != .tlsProtocol13, "enum neq")
    var hasher = Hasher()
    SSLProtocol.tlsProtocol12.hash(into: &hasher)
    _ = hasher.finalize()
}

func testPolicyAndTrustFailClosed() {
    let policy = SecPolicyCreateSSL(true, "example.test")
    var trust: SecTrust?
    let status = SecTrustCreateWithCertificates(Data() as CFTypeRef, policy, &trust)
    require(status == errSecSuccess, "trust object is constructible")
    require(trust != nil, "trust out-param")
    var result = SecTrustResultType.proceed
    require(SecTrustEvaluate(trust!, &result) == errSecSuccess, "evaluate")
    require(result == .invalid, "invalid result")
    var error: CFError?
    require(SecTrustEvaluateWithError(trust!, &error) == false, "evaluate with error")
}

func testCertificateCreateWithData() {
    require(SecCertificateCreateWithData(nil, Data([0x30, 0x82])) == nil, "invalid DER")
    let cert = SecCertificateCreateWithData(nil, Data(leafRSACertDER))
    require(cert != nil, "created")
    require(SecCertificateCopyData(cert!) == Data(leafRSACertDER), "copy data")
    require(SecCertificateCopyKey(cert!) != nil, "spki key")
    require(SecCertificateCopySubjectSummary(cert!) as String? == "leaf.example.test", "cn")
}

func testAccessControlFailClosed() {
    var error: Unmanaged<CFError>?
    let control = SecAccessControlCreateWithFlags(
        nil,
        kSecAttrAccessibleWhenUnlocked as CFTypeRef,
        [.userPresence],
        &error
    )
    require(control != nil, "access control object is constructible")
    require(error == nil, "no CFError on construct")
}
