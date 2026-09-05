import Foundation
#if canImport(Glibc)
import Glibc
#endif
import Security

private func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else { fatalError(message) }
}

private func isolateKeychain() {
    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent("openuikit-sec-\(UUID().uuidString)", isDirectory: true)
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    dir.path.withCString { _ = setenv("OPENUIKIT_KEYCHAIN_PATH", $0, 1) }
}

private func rsaPrivate() -> SecKey {
    let attrs: [String: Any] = [
        kSecAttrKeyType: kSecAttrKeyTypeRSA,
        kSecAttrKeyClass: kSecAttrKeyClassPrivate,
        kSecAttrKeySizeInBits: 2048,
    ]
    let key = SecKeyCreateWithData(Data(leafRSAPKCS1), attrs as CFDictionary, nil)
    require(key != nil, "rsa private import")
    return key!
}

private func rsaPublic() -> SecKey {
    let attrs: [String: Any] = [
        kSecAttrKeyType: kSecAttrKeyTypeRSA,
        kSecAttrKeyClass: kSecAttrKeyClassPublic,
        kSecAttrKeySizeInBits: 2048,
    ]
    let key = SecKeyCreateWithData(Data(leafRSAPubPKCS1), attrs as CFDictionary, nil)
    require(key != nil, "rsa public import")
    return key!
}

private func ecPrivate() -> SecKey {
    let attrs: [String: Any] = [
        kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
        kSecAttrKeyClass: kSecAttrKeyClassPrivate,
        kSecAttrKeySizeInBits: 256,
    ]
    let key = SecKeyCreateWithData(Data(leafECX963Private), attrs as CFDictionary, nil)
    require(key != nil, "ec private import")
    return key!
}

final class ProbeProtocolOptions: NSObject, OS_sec_protocol_options {}
final class ProbeProtocolMetadata: NSObject, OS_sec_protocol_metadata {}

func testDocumentedItemKeyStringIdentities() {
    require(kSecAttrAccessGroupToken == "com.apple.token", "token group")
    require(kSecAttrAccessibleAlways == "dk", "dk")
    require(kSecAttrAccessibleAlwaysThisDeviceOnly == "dku", "dku")
    require(kSecAttrApplicationLabel == "klbl", "klbl")
    require(kSecAttrApplicationTag == "atag", "atag")
    require(kSecAttrAuthenticationType == "atyp", "atyp")
    require(kSecAttrAuthenticationTypeDPA == "dpaa", "dpaa")
    require(kSecAttrAuthenticationTypeDefault == "dflt", "dflt")
    require(kSecAttrAuthenticationTypeHTMLForm == "form", "form")
    require(kSecAttrAuthenticationTypeHTTPBasic == "http", "http")
    require(kSecAttrAuthenticationTypeHTTPDigest == "httd", "httd")
    require(kSecAttrAuthenticationTypeMSN == "msna", "msna")
    require(kSecAttrAuthenticationTypeNTLM == "ntlm", "ntlm")
    require(kSecAttrAuthenticationTypeRPA == "rpaa", "rpaa")
    require(kSecAttrCanDecrypt == "decr", "decr")
    require(kSecAttrCanDerive == "drve", "drve")
    require(kSecAttrCanEncrypt == "encr", "encr")
    require(kSecAttrCanSign == "sign", "sign")
    require(kSecAttrCanUnwrap == "unwp", "unwp")
    require(kSecAttrCanVerify == "vrfy", "vrfy")
    require(kSecAttrCanWrap == "wrap", "wrap")
    require(kSecAttrCertificateEncoding == "cenc", "cenc")
    require(kSecAttrCertificateType == "ctyp", "ctyp")
    require(kSecAttrEffectiveKeySize == "esiz", "esiz")
    require(kSecAttrIsExtractable == "extr", "extr")
    require(kSecAttrIsPermanent == "perm", "perm")
    require(kSecAttrIsSensitive == "sens", "sens")
    require(kSecAttrIssuer == "issr", "issr")
    require(kSecAttrKeyClass == "kcls", "kcls")
    require(kSecAttrKeyClassPrivate == "1", "priv")
    require(kSecAttrKeyClassPublic == "0", "pub")
    require(kSecAttrKeyClassSymmetric == "2", "sym")
    require(kSecAttrKeySizeInBits == "bsiz", "bsiz")
    require(kSecAttrKeyType == "type", "kty")
    require(kSecAttrKeyTypeEC == "73", "ec")
    require(kSecAttrKeyTypeECSECPrimeRandom == "73", "ecsec")
    require(kSecAttrKeyTypeRSA == "42", "rsa")
    require(kSecAttrPath == "path", "path")
    require(kSecAttrPersistantReference == "persistref", "persist old")
    require(kSecAttrPersistentReference == "persistref", "persist")
    require(kSecAttrPort == "port", "port")
    require(kSecAttrProtocol == "ptcl", "ptcl")
    require(kSecAttrProtocolAFP == "afp ", "afp")
    require(kSecAttrProtocolAppleTalk == "atlk", "atlk")
    require(kSecAttrProtocolDAAP == "daap", "daap")
    require(kSecAttrProtocolEPPC == "eppc", "eppc")
    require(kSecAttrProtocolFTP == "ftp ", "ftp")
    require(kSecAttrProtocolFTPAccount == "ftpa", "ftpa")
    require(kSecAttrProtocolFTPProxy == "ftpx", "ftpx")
    require(kSecAttrProtocolFTPS == "ftps", "ftps")
    require(kSecAttrProtocolHTTP == "http", "http proto")
    require(kSecAttrProtocolHTTPProxy == "htpx", "htpx")
    require(kSecAttrProtocolHTTPS == "htps", "htps")
    require(kSecAttrProtocolHTTPSProxy == "htsx", "htsx")
    require(kSecAttrProtocolIMAP == "imap", "imap")
    require(kSecAttrProtocolIMAPS == "imps", "imps")
    require(kSecAttrProtocolIPP == "ipp ", "ipp")
    require(kSecAttrProtocolIRC == "irc ", "irc")
    require(kSecAttrProtocolIRCS == "ircs", "ircs")
    require(kSecAttrProtocolLDAP == "ldap", "ldap")
    require(kSecAttrProtocolLDAPS == "ldps", "ldps")
    require(kSecAttrProtocolNNTP == "nntp", "nntp")
    require(kSecAttrProtocolNNTPS == "ntps", "ntps")
    require(kSecAttrProtocolPOP3 == "pop3", "pop3")
    require(kSecAttrProtocolPOP3S == "pops", "pops")
    require(kSecAttrProtocolRTSP == "rtsp", "rtsp")
    require(kSecAttrProtocolRTSPProxy == "rtsx", "rtsx")
    require(kSecAttrProtocolSMB == "smb ", "smb")
    require(kSecAttrProtocolSMTP == "smtp", "smtp")
    require(kSecAttrProtocolSOCKS == "sox ", "sox")
    require(kSecAttrProtocolSSH == "ssh ", "ssh")
    require(kSecAttrProtocolTelnet == "teln", "teln")
    require(kSecAttrProtocolTelnetS == "tels", "tels")
    require(kSecAttrPublicKeyHash == "pkhh", "pkhh")
    require(kSecAttrSecurityDomain == "sdmn", "sdmn")
    require(kSecAttrSerialNumber == "slnr", "slnr")
    require(kSecAttrServer == "srvr", "srvr")
    require(kSecAttrSubject == "subj", "subj")
    require(kSecAttrSubjectKeyID == "skid", "skid")
    require(kSecAttrSyncViewHint == "vwht", "vwht")
    require(kSecAttrTokenID == "tkid", "tkid")
    require(kSecAttrTokenIDSecureEnclave == "com.apple.setoken", "setoken")
    require(kSecImportExportPassphrase == "passphrase", "passphrase")
    require(kSecImportItemCertChain == "chain", "chain")
    require(kSecImportItemIdentity == "identity", "identity")
    require(kSecImportItemKeyID == "keyid", "keyid")
    require(kSecImportItemLabel == "label", "label")
    require(kSecImportItemTrust == "trust", "trust")
    require(kSecImportToMemoryOnly == "toMemoryOnly", "mem")
    require(kSecMatchCaseInsensitive == "m_CaseInsensitive", "mci")
    require(kSecMatchEmailAddressIfPresent == "m_EmailAddressIfPresent", "memail")
    require(kSecMatchHostOrSubdomainOfHost == "m_HostOrSubdomainOfHost", "mhost")
    require(kSecMatchIssuers == "m_Issuers", "miss")
    require(kSecMatchItemList == "m_ItemList", "mil")
    require(kSecMatchPolicy == "m_Policy", "mpol")
    require(kSecMatchSearchList == "m_SearchList", "msl")
    require(kSecMatchSubjectContains == "m_SubjectContains", "msub")
    require(kSecMatchTrustedOnly == "m_TrustedOnly", "mtr")
    require(kSecMatchValidOnDate == "m_ValidOnDate", "mvd")
    require(kSecPolicyAppleCodeSigning == "1.2.840.113635.100.1.16", "codesign")
    require(kSecPolicyAppleEAP == "1.2.840.113635.100.1.9", "eap")
    require(kSecPolicyAppleEAPClient == "1.2.840.113635.100.1.9.2", "eapc")
    require(kSecPolicyAppleEAPServer == "1.2.840.113635.100.1.9.1", "eaps")
    require(kSecPolicyAppleIDValidation == "1.2.840.113635.100.1.18", "idv")
    require(kSecPolicyAppleIPSecClient == "1.2.840.113635.100.1.11.2", "ipsc")
    require(kSecPolicyAppleIPSecServer == "1.2.840.113635.100.1.11.1", "ipss")
    require(kSecPolicyAppleIPsec == "1.2.840.113635.100.1.11", "ips")
    require(kSecPolicyApplePassbookSigning == "1.2.840.113635.100.1.22", "passbook")
    require(kSecPolicyApplePayIssuerEncryption == "1.2.840.113635.100.1.39", "pay")
    require(kSecPolicyAppleRevocation == "1.2.840.113635.100.1.21", "rev")
    require(kSecPolicyAppleSMIME == "1.2.840.113635.100.1.8", "smime")
    require(kSecPolicyAppleSSL == "1.2.840.113635.100.1.3", "ssl")
    require(kSecPolicyAppleSSLClient == "1.2.840.113635.100.1.3.2", "sslc")
    require(kSecPolicyAppleSSLServer == "1.2.840.113635.100.1.3.1", "ssls")
    require(kSecPolicyAppleTimeStamping == "1.2.840.113635.100.1.20", "ts")
    require(kSecPolicyAppleX509Basic == "1.2.840.113635.100.1.2", "x509")
    require(kSecPolicyClient == "SecPolicyClient", "client")
    require(kSecPolicyMacAppStoreReceipt == "1.2.840.113635.100.1.19", "mas")
    require(kSecPolicyName == "SecPolicyName", "pname")
    require(kSecPolicyOid == "SecPolicyOid", "poid")
    require(kSecPolicyRevocationFlags == "SecPolicyRevocationFlags", "pflags")
    require(kSecPolicyTeamIdentifier == "SecPolicyTeamIdentifier", "team")
    require(kSecPrivateKeyAttrs == "private", "priv attrs")
    require(kSecPropertyTypeError == "error", "err")
    require(kSecPropertyTypeTitle == "title", "title")
    require(kSecPublicKeyAttrs == "public", "pub attrs")
    require(kSecReturnRef == "r_Ref", "rref")
    require(kSecTrustCertificateTransparency == "TrustCertificateTransparency", "ct")
    require(kSecTrustCertificateTransparencyWhiteList == "TrustCertificateTransparencyWhiteList", "ctw")
    require(kSecTrustEvaluationDate == "TrustEvaluationDate", "ted")
    require(kSecTrustExtendedValidation == "TrustExtendedValidation", "ev")
    require(kSecTrustOrganizationName == "OrganizationName", "org")
    require(kSecTrustQCStatements == "QCStatements", "qc")
    require(kSecTrustQWACValidation == "QWACValidation", "qwac")
    require(kSecTrustResultValue == "TrustResultValue", "trv")
    require(kSecTrustRevocationChecked == "TrustRevocationChecked", "trc")
    require(kSecTrustRevocationValidUntilDate == "TrustExpirationDate", "exp")
    require(kSecUseAuthenticationContext == "u_AuthCtx", "uac")
    require(kSecUseAuthenticationUI == "u_AuthUI", "uaui")
    require(kSecUseAuthenticationUIAllow == "u_AuthUIA", "allow")
    require(kSecUseAuthenticationUIFail == "u_AuthUIF", "fail")
    require(kSecUseAuthenticationUISkip == "u_AuthUIS", "skip")
    require(kSecUseItemList == "u_ItemList", "uil")
    require(kSecUseNoAuthenticationUI == "u_NoAuthUI", "noauth")
    require(kSecUseOperationPrompt == "u_OpPrompt", "prompt")
    require(kSecValuePersistentRef == "v_PersistentRef", "vpref")
    require(kSecValueRef == "v_Ref", "vref")
}

func testKeychainClassesReturnShapesAndACL() {
    isolateKeychain()
    let account = "inet-\(UUID().uuidString)"
    let add: [String: Any] = [
        kSecClass: kSecClassInternetPassword,
        kSecAttrAccount: account,
        kSecAttrServer: "example.test",
        kSecAttrProtocol: kSecAttrProtocolHTTPS,
        kSecAttrAccessGroup: "group.test",
        kSecUseDataProtectionKeychain: true,
        kSecValueData: Data("secret".utf8),
    ]
    require(SecItemAdd(add as CFDictionary, nil) == errSecSuccess, "inet add")
    var copied: CFTypeRef?
    let attrsQuery: [String: Any] = [
        kSecClass: kSecClassInternetPassword,
        kSecAttrAccount: account,
        kSecReturnAttributes: true,
        kSecReturnData: true,
        kSecMatchLimit: kSecMatchLimitOne,
    ]
    require(SecItemCopyMatching(attrsQuery as CFDictionary, &copied) == errSecSuccess, "inet copy")
    let bag = copied as? [String: Any]
    require(bag?[kSecValueData as String] as? Data == Data("secret".utf8), "inet data")
    require(bag?[kSecAttrServer as String] as? String == "example.test", "server stored")
    require(bag?[kSecAttrAccessGroup as String] as? String == "group.test", "group stored")

    let keyAdd: [String: Any] = [
        kSecClass: kSecClassKey,
        kSecAttrApplicationTag: Data("tag".utf8),
        kSecAttrKeyClass: kSecAttrKeyClassPrivate,
        kSecAttrKeyType: kSecAttrKeyTypeRSA,
        kSecValueData: Data(leafRSAPKCS1),
    ]
    require(SecItemAdd(keyAdd as CFDictionary, nil) == errSecSuccess, "key add")
    copied = nil
    require(
        SecItemCopyMatching(
            [
                kSecClass: kSecClassKey,
                kSecAttrApplicationTag: Data("tag".utf8),
                kSecReturnData: true,
            ] as CFDictionary,
            &copied
        ) == errSecSuccess,
        "key copy"
    )
    require((copied as? Data)?.count == leafRSAPKCS1.count, "key bytes")

    let certAdd: [String: Any] = [
        kSecClass: kSecClassCertificate,
        kSecAttrSerialNumber: Data([0x0a]),
        kSecValueData: Data(leafRSACertDER),
        kSecReturnPersistentRef: true,
    ]
    var pref: CFTypeRef?
    require(SecItemAdd(certAdd as CFDictionary, &pref) == errSecSuccess, "cert add")
    require((pref as? Data)?.count == 16, "persistent ref")

    var error: Unmanaged<CFError>?
    let control = SecAccessControlCreateWithFlags(
        nil,
        kSecAttrAccessibleWhenUnlocked as CFTypeRef,
        [.biometryAny],
        &error
    )
    require(control != nil, "acl")
    let locked: [String: Any] = [
        kSecClass: kSecClassGenericPassword,
        kSecAttrAccount: "bio-\(UUID().uuidString)",
        kSecAttrService: "acl",
        kSecAttrAccessControl: control!,
        kSecValueData: Data("nope".utf8),
    ]
    require(SecItemAdd(locked as CFDictionary, nil) == errSecSuccess, "acl add")
    copied = nil
    require(
        SecItemCopyMatching(
            [
                kSecClass: kSecClassGenericPassword,
                kSecAttrAccount: locked[kSecAttrAccount as String] as! String,
                kSecAttrService: "acl",
                kSecReturnData: true,
            ] as CFDictionary,
            &copied
        ) == errSecAuthFailed,
        "bio fail-closed"
    )

    let path = ProcessInfo.processInfo.environment["OPENUIKIT_KEYCHAIN_PATH"] ?? ""
    require(
        FileManager.default.fileExists(atPath: (path as NSString).appendingPathComponent("store.bin")),
        "encrypted store file"
    )
}

func testSecKeyRSAImportSignEncrypt() {
    let priv = rsaPrivate()
    let pub = rsaPublic()
    require(SecKeyGetBlockSize(priv) == 256, "rsa 2048 block")
    require(SecKeyIsAlgorithmSupported(priv, .sign, .rsaSignatureMessagePKCS1v15SHA256), "rsa sign")
    require(!SecKeyIsAlgorithmSupported(priv, .sign, .ecdsaSignatureMessageX962SHA256), "not ecdsa")
    require(!SecKeyIsAlgorithmSupported(priv, .encrypt, .rsaEncryptionOAEPSHA256AESGCM), "oaep+aes fail")
    let message = Data(messageBytes)
    require(
        SecKeyVerifySignature(pub, .rsaSignatureMessagePKCS1v15SHA256, message, Data(messageRSAPKCS1Sig), nil),
        "openssl pkcs1 verify"
    )
    require(
        SecKeyVerifySignature(pub, .rsaSignatureMessagePSSSHA256, message, Data(messageRSAPSSSig), nil),
        "openssl pss verify"
    )
    let signature = SecKeyCreateSignature(priv, .rsaSignatureMessagePKCS1v15SHA256, message, nil)
    require(signature != nil, "sign")
    require(SecKeyVerifySignature(pub, .rsaSignatureMessagePKCS1v15SHA256, message, signature!, nil), "round trip")
    let copiedPub = SecKeyCopyPublicKey(priv)
    require(copiedPub != nil, "copy public")
    let attrs = SecKeyCopyAttributes(priv)
    require(attrs?[kSecAttrKeyType] as? String == kSecAttrKeyTypeRSA, "type attr")
    let external = SecKeyCopyExternalRepresentation(priv, nil)
    require(external != nil, "external")
    let reimported = SecKeyCreateWithData(
        external!,
        [
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass: kSecAttrKeyClassPrivate,
        ] as CFDictionary,
        nil
    )
    require(reimported != nil, "reimport")
    let cipher = SecKeyCreateEncryptedData(pub, .rsaEncryptionPKCS1, Data(smallPlain), nil)
    require(cipher != nil, "encrypt")
    let plain = SecKeyCreateDecryptedData(priv, .rsaEncryptionPKCS1, cipher!, nil)
    require(plain as Data? == Data(smallPlain), "decrypt")
    let known = SecKeyCreateDecryptedData(priv, .rsaEncryptionPKCS1, Data(smallRSAPKCS1), nil)
    require(known as Data? == Data(smallPlain), "openssl decrypt")
    require(SecKeyCreateEncryptedData(pub, .eciesEncryptionStandardX963SHA256AESGCM, Data(smallPlain), nil) == nil, "ecies nil")
    require(SecKeyCreateDecryptedData(priv, .eciesEncryptionStandardX963SHA256AESGCM, Data(smallPlain), nil) == nil, "ecies dec nil")
    let oaep = SecKeyCreateEncryptedData(pub, .rsaEncryptionOAEPSHA256, Data(smallPlain), nil)
    require(oaep != nil, "oaep")
    require(SecKeyCreateDecryptedData(priv, .rsaEncryptionOAEPSHA256, oaep!, nil) as Data? == Data(smallPlain), "oaep round")
    var cipherLen = 256
    var cipherBuf = [UInt8](repeating: 0, count: 256)
    let encStatus = Data(smallPlain).withUnsafeBytes { raw in
        cipherBuf.withUnsafeMutableBufferPointer { out in
            SecKeyEncrypt(pub, .PKCS1, raw.bindMemory(to: UInt8.self).baseAddress!, raw.count, out.baseAddress!, &cipherLen)
        }
    }
    require(encStatus == errSecSuccess, "SecKeyEncrypt")
    var plainLen = 256
    var plainBuf = [UInt8](repeating: 0, count: 256)
    let decStatus = cipherBuf.withUnsafeBufferPointer { raw in
        plainBuf.withUnsafeMutableBufferPointer { out in
            SecKeyDecrypt(priv, .PKCS1, raw.baseAddress!, cipherLen, out.baseAddress!, &plainLen)
        }
    }
    require(decStatus == errSecSuccess, "SecKeyDecrypt")
    require(Array(plainBuf.prefix(plainLen)) == smallPlain, "raw encrypt")
    let rsa4096 = SecKeyCreateWithData(
        Data(rsa4096PKCS1),
        [
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass: kSecAttrKeyClassPrivate,
        ] as CFDictionary,
        nil
    )
    require(rsa4096 != nil, "rsa4096 import")
    require(SecKeyGetBlockSize(rsa4096!) == 512, "4096 block")
}

func testSecKeyECGenerateSignExchange() {
    let priv = ecPrivate()
    let pub = SecKeyCopyPublicKey(priv)
    require(pub != nil, "ec pub")
    require(SecKeyGetBlockSize(priv) == 32, "p256 size")
    let message = Data(messageBytes)
    require(
        SecKeyVerifySignature(pub!, .ecdsaSignatureMessageX962SHA256, message, Data(messageECSig), nil),
        "openssl ecdsa"
    )
    let signature = SecKeyCreateSignature(priv, .ecdsaSignatureMessageX962SHA256, message, nil)
    require(signature != nil, "ecdsa sign")
    require(SecKeyVerifySignature(pub!, .ecdsaSignatureMessageX962SHA256, message, signature!, nil), "ecdsa round")
    require(!SecKeyIsAlgorithmSupported(priv, .encrypt, .rsaEncryptionPKCS1), "ec no rsa")
    require(!SecKeyIsAlgorithmSupported(priv, .encrypt, .eciesEncryptionStandardX963SHA256AESGCM), "ecies unsupported")
    let generated = SecKeyCreateRandomKey(
        [
            kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits: 256,
        ] as CFDictionary,
        nil
    )
    require(generated != nil, "p256 generate")
    var pubOut: SecKey?
    var privOut: SecKey?
    require(
        SecKeyGeneratePair(
            [kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom, kSecAttrKeySizeInBits: 384] as CFDictionary,
            &pubOut,
            &privOut
        ) == errSecSuccess,
        "p384 pair"
    )
    require(pubOut != nil && privOut != nil, "pair out")
    let p521 = SecKeyCreateRandomKey(
        [kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom, kSecAttrKeySizeInBits: 521] as CFDictionary,
        nil
    )
    require(p521 != nil, "p521")
    let other = SecKeyCreateRandomKey(
        [kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom, kSecAttrKeySizeInBits: 256] as CFDictionary,
        nil
    )
    let secret = SecKeyCopyKeyExchangeResult(
        generated!,
        .ecdhKeyExchangeStandard,
        SecKeyCopyPublicKey(other!)!,
        [:] as CFDictionary,
        nil
    )
    require(secret != nil && (secret as Data?)?.count == 32, "ecdh")
    let x963 = SecKeyCopyExternalRepresentation(priv, nil)
    require((x963 as Data?)?.count == 97, "x963 private 04||X||Y||K")
    let x963Pub = SecKeyCopyExternalRepresentation(pub!, nil)
    require((x963Pub as Data?)?.count == 65, "x963 public")
}

func testSecCertificateParseAndIdentity() {
    let cert = SecCertificateCreateWithData(nil, Data(leafRSACertDER))
    require(cert != nil, "leaf")
    var cn: CFString?
    require(SecCertificateCopyCommonName(cert!, &cn) == errSecSuccess, "cn")
    require(cn as String? == "leaf.example.test", "cn value")
    var emails: CFArray?
    require(SecCertificateCopyEmailAddresses(cert!, &emails) == errSecSuccess, "emails")
    require(SecCertificateCopyNormalizedSubjectSequence(cert!) != nil, "subject")
    require(SecCertificateCopyNormalizedIssuerSequence(cert!) != nil, "issuer")
    require(SecCertificateCopyNotValidBeforeDate(cert!) != nil, "nb")
    require(SecCertificateCopyNotValidAfterDate(cert!) != nil, "na")
    require(SecCertificateCopySerialNumber(cert!) != nil, "serial")
    require(SecCertificateCopySerialNumberData(cert!, nil) != nil, "serial data")
    require(SecCertificateCopyPublicKey(cert!) != nil, "pubkey")
    require(SecCertificateGetTypeID() == SecCertificateGetTypeID(), "typeid")
    require(SecAccessControlGetTypeID() != 0, "acl type")
    require(SecIdentityGetTypeID() != 0, "id type")
    let identity = SecIdentityCreate(nil, cert!, rsaPrivate())
    require(identity != nil, "identity")
    var copiedCert: SecCertificate?
    var copiedKey: SecKey?
    require(SecIdentityCopyCertificate(identity!, &copiedCert) == errSecSuccess, "id cert")
    require(SecIdentityCopyPrivateKey(identity!, &copiedKey) == errSecSuccess, "id key")
}

func testSecPKCS12AndTrustEvaluate() {
    var items: CFArray?
    let status = SecPKCS12Import(
        Data(leafRSA_P12),
        [kSecImportExportPassphrase: kPKCS12Passphrase] as CFDictionary,
        &items
    )
    require(status == errSecSuccess, "p12")
    let first = (items as? [[String: Any]])?.first
    require(first?[kSecImportItemIdentity as String] is SecIdentity, "p12 identity")

    let leaf = SecCertificateCreateWithData(nil, Data(leafRSACertDER))!
    let ca = SecCertificateCreateWithData(nil, Data(caCertDER))!
    let ssl = SecPolicyCreateSSL(true, "leaf.example.test")
    var trust: SecTrust?
    require(SecTrustCreateWithCertificates([leaf] as CFArray, ssl, &trust) == errSecSuccess, "trust")
    require(SecTrustSetAnchorCertificates(trust!, [ca] as CFArray) == errSecSuccess, "anchors")
    require(SecTrustSetAnchorCertificatesOnly(trust!, true) == errSecSuccess, "anchors only")
    require(SecTrustSetVerifyDate(trust!, Date(timeIntervalSince1970: 1_790_400_000)) == errSecSuccess, "date inside validity")
    require(SecTrustSetPolicies(trust!, ssl) == errSecSuccess, "set policy")
    require(SecTrustSetNetworkFetchAllowed(trust!, false) == errSecSuccess, "fetch")
    require(SecTrustSetOCSPResponse(trust!, nil) == errSecSuccess, "ocsp")
    require(SecTrustSetSignedCertificateTimestamps(trust!, nil) == errSecSuccess, "sct")
    require(SecTrustSetExceptions(trust!, nil), "exceptions")
    var allow = DarwinBoolean(true)
    require(SecTrustGetNetworkFetchAllowed(trust!, &allow) == errSecSuccess, "get fetch")
    require(allow.boolValue == false, "fetch off")
    var result = SecTrustResultType.invalid
    require(SecTrustEvaluate(trust!, &result) == errSecSuccess, "eval")
    require(result == .proceed, "proceed")
    var err: CFError?
    require(SecTrustEvaluateWithError(trust!, &err), "eval error")
    var stored = SecTrustResultType.invalid
    require(SecTrustGetTrustResult(trust!, &stored) == errSecSuccess, "get result")
    require(stored == .proceed, "stored proceed")
    require(SecTrustGetCertificateCount(trust!) >= 1, "count")
    require(SecTrustGetCertificateAtIndex(trust!, 0) != nil, "index")
    require(SecTrustCopyCertificateChain(trust!) != nil, "chain")
    require(SecTrustCopyKey(trust!) != nil, "key")
    require(SecTrustCopyPublicKey(trust!) != nil, "pubkey")
    require(SecTrustCopyResult(trust!) != nil, "copy result")
    require(SecTrustCopyProperties(trust!) != nil, "props")
    var policies: CFArray?
    require(SecTrustCopyPolicies(trust!, &policies) == errSecSuccess, "copy pol")
    var anchors: CFArray?
    require(SecTrustCopyCustomAnchorCertificates(trust!, &anchors) == errSecSuccess, "copy anchors")
    _ = SecTrustCopyExceptions(trust!)
    _ = SecTrustGetVerifyTime(trust!)
    require(SecTrustGetTypeID() != 0, "trust type")

    let wildcard = SecPolicyCreateSSL(true, "www.example.test")
    var wildTrust: SecTrust?
    require(SecTrustCreateWithCertificates([leaf] as CFArray, wildcard, &wildTrust) == errSecSuccess, "wild")
    require(SecTrustSetAnchorCertificates(wildTrust!, [ca] as CFArray) == errSecSuccess, "wild anchors")
    require(SecTrustEvaluateWithError(wildTrust!, nil), "wildcard RFC 6125")

    let badHost = SecPolicyCreateSSL(true, "not-the-leaf.test")
    var badTrust: SecTrust?
    require(SecTrustCreateWithCertificates([leaf] as CFArray, badHost, &badTrust) == errSecSuccess, "bad host")
    require(SecTrustSetAnchorCertificates(badTrust!, [ca] as CFArray) == errSecSuccess, "bad anchors")
    require(SecTrustEvaluateWithError(badTrust!, nil) == false, "hostname mismatch")

    let basic = SecPolicyCreateBasicX509()
    let props = SecPolicyCopyProperties(basic)
    require(props?[kSecPolicyOid] as? String == kSecPolicyAppleX509Basic, "basic oid")
    let revocation = SecPolicyCreateRevocation(kSecRevocationRequirePositiveResponse)
    require(revocation != nil, "revocation policy")
    var revTrust: SecTrust?
    require(SecTrustCreateWithCertificates([leaf] as CFArray, revocation, &revTrust) == errSecSuccess, "rev trust")
    require(SecTrustSetAnchorCertificates(revTrust!, [ca] as CFArray) == errSecSuccess, "rev anchors")
    require(SecTrustEvaluateWithError(revTrust!, nil) == false, "revocation fail-closed")
    let custom = SecPolicyCreateWithProperties(kSecPolicyAppleSSLServer as CFTypeRef, [kSecPolicyName: "leaf.example.test"] as CFDictionary)
    require(custom != nil, "with properties")
    require(SecPolicyGetTypeID() != 0, "policy type")

    var asyncResult = SecTrustResultType.invalid
    require(
        SecTrustEvaluateAsync(trust!, dispatch_queue_s()) { _, value in
            asyncResult = value
        } == errSecSuccess,
        "async"
    )
    require(asyncResult == .proceed, "async callback")
    var asyncOK = false
    require(
        SecTrustEvaluateAsyncWithError(trust!, dispatch_queue_s()) { _, ok, _ in
            asyncOK = ok
        } == errSecSuccess,
        "async err"
    )
    require(asyncOK, "async err callback")
}

func testSecProtocolAndObjectWrappers() {
    let cert = SecCertificateCreateWithData(nil, Data(leafRSACertDER))!
    let identity = SecIdentityCreate(nil, cert, rsaPrivate())!
    let wrappedCert = sec_certificate_create(cert)
    require(wrappedCert != nil, "sec cert")
    _ = sec_certificate_copy_ref(wrappedCert!).takeUnretainedValue()
    let wrappedId = sec_identity_create(identity)
    require(wrappedId != nil, "sec id")
    require(sec_identity_copy_ref(wrappedId!) != nil, "id ref")
    require(sec_identity_create_with_certificates(identity, [cert] as CFArray) != nil, "id+certs")
    var seen = 0
    require(sec_identity_access_certificates(wrappedId!) { _ in seen += 1 }, "access certs")
    require(seen >= 1, "handler")
    require(sec_identity_copy_certificates_ref(wrappedId!) != nil, "certs ref")
    var trust: SecTrust?
    require(SecTrustCreateWithCertificates([cert] as CFArray, SecPolicyCreateBasicX509(), &trust) == errSecSuccess, "t")
    let wrappedTrust = sec_trust_create(trust!)
    require(wrappedTrust != nil, "sec trust")
    _ = sec_trust_copy_ref(wrappedTrust!).takeUnretainedValue()
    let options = ProbeProtocolOptions()
    let metadata = ProbeProtocolMetadata()
    sec_protocol_options_add_tls_ciphersuite(options, 0)
    sec_protocol_options_add_tls_ciphersuite_group(options, .ATS)
    sec_protocol_options_append_tls_ciphersuite(options, .AES_128_GCM_SHA256)
    sec_protocol_options_append_tls_ciphersuite_group(options, .ats)
    "h2".withCString { sec_protocol_options_add_tls_application_protocol(options, $0) }
    sec_protocol_options_set_local_identity(options, wrappedId!)
    sec_protocol_options_set_max_tls_protocol_version(options, .TLSv13)
    sec_protocol_options_set_min_tls_protocol_version(options, .TLSv12)
    sec_protocol_options_set_peer_authentication_required(options, true)
    sec_protocol_options_set_tls_false_start_enabled(options, false)
    sec_protocol_options_set_tls_is_fallback_attempt(options, false)
    sec_protocol_options_set_tls_max_version(options, .tlsProtocol13)
    sec_protocol_options_set_tls_min_version(options, .tlsProtocol12)
    sec_protocol_options_set_tls_ocsp_enabled(options, false)
    sec_protocol_options_set_tls_renegotiation_enabled(options, false)
    sec_protocol_options_set_tls_resumption_enabled(options, true)
    sec_protocol_options_set_tls_sct_enabled(options, false)
    "leaf.example.test".withCString { sec_protocol_options_set_tls_server_name(options, $0) }
    sec_protocol_options_set_tls_tickets_enabled(options, false)
    require(sec_protocol_options_are_equal(options, options), "opt eq")
    require(
        sec_protocol_options_get_default_max_tls_protocol_version() == .TLSv13,
        "max tls"
    )
    require(
        sec_protocol_options_get_default_min_tls_protocol_version() == .TLSv12,
        "min tls"
    )
    require(
        sec_protocol_options_get_default_max_dtls_protocol_version() == .DTLSv12,
        "max dtls"
    )
    require(
        sec_protocol_options_get_default_min_dtls_protocol_version() == .DTLSv12,
        "min dtls"
    )
    require(!sec_protocol_metadata_get_early_data_accepted(metadata), "0rtt")
    _ = sec_protocol_metadata_get_negotiated_ciphersuite(metadata)
    _ = sec_protocol_metadata_get_negotiated_protocol(metadata)
    _ = sec_protocol_metadata_get_negotiated_protocol_version(metadata)
    _ = sec_protocol_metadata_get_negotiated_tls_ciphersuite(metadata)
    _ = sec_protocol_metadata_get_negotiated_tls_protocol_version(metadata)
    _ = sec_protocol_metadata_get_server_name(metadata)
    _ = sec_protocol_metadata_copy_negotiated_protocol(metadata)
    _ = sec_protocol_metadata_copy_server_name(metadata)
    require(sec_protocol_metadata_peers_are_equal(metadata, metadata), "peers")
    require(sec_protocol_metadata_challenge_parameters_are_equal(metadata, metadata), "chal")
    require(!sec_protocol_metadata_access_peer_certificate_chain(metadata) { _ in }, "chain")
    require(!sec_protocol_metadata_access_supported_signature_algorithms(metadata) { _ in }, "algs")
    require(!sec_protocol_metadata_access_distinguished_names(metadata) { _ in }, "dn")
    require(!sec_protocol_metadata_access_ocsp_response(metadata) { _ in }, "ocsp")
    require(!sec_protocol_metadata_access_pre_shared_keys(metadata) { _, _ in }, "psk")
    require(sec_protocol_metadata_copy_peer_public_key(metadata) == nil, "peer key")
    "".withCString { ptr in
        require(sec_protocol_metadata_create_secret(metadata, 0, ptr, 0) == nil, "secret")
        var zero: UInt8 = 0
        withUnsafePointer(to: &zero) { bytes in
            require(
                sec_protocol_metadata_create_secret_with_context(metadata, 0, ptr, 0, bytes, 0) == nil,
                "secret ctx"
            )
        }
    }
    let psk = Data("psk".utf8)
    sec_protocol_options_add_pre_shared_key(options, psk, psk)
    sec_protocol_options_set_tls_pre_shared_key_identity_hint(options, psk)
    sec_protocol_options_set_tls_diffie_hellman_parameters(options, psk)
    sec_protocol_options_set_challenge_block(options, { _, complete in complete(nil) }, dispatch_queue_s())
    sec_protocol_options_set_key_update_block(options, { _, complete in complete() }, dispatch_queue_s())
    sec_protocol_options_set_verify_block(options, { _, _, complete in complete(false) }, dispatch_queue_s())
    sec_protocol_options_set_pre_shared_key_selection_block(
        options,
        { _, _, complete in complete(nil) },
        dispatch_queue_s()
    )
    var dummy = 0
    withUnsafeMutablePointer(to: &dummy) { ptr in
        let raw = UnsafeMutableRawPointer(ptr)
        _ = sec_retain(raw)
        sec_release(raw)
    }
    var webDone = false
    SecAddSharedWebCredential("example.test" as CFString, "acct" as CFString, nil) { _ in webDone = true }
    require(webDone, "web cred callback")
    require(SecCreateSharedWebCredentialPassword() == nil, "web pw")
    var reqDone = false
    SecRequestSharedWebCredential(nil, nil) { _, _ in reqDone = true }
    require(reqDone, "web request")
}

func testTypealiasAndCallbackIdentities() {
    let _: SSLCipherSuite = 0
    let _: SecRandomRef? = kSecRandomDefault
    let _: SecTrustCallback = { _, _ in }
    let _: SecTrustWithErrorCallback = { _, _, _ in }
    let _: sec_certificate_t? = nil
    let _: sec_identity_t? = nil
    let _: sec_object_t? = nil
    let _: sec_trust_t? = nil
    let _: sec_protocol_metadata_t? = nil
    let _: sec_protocol_options_t? = nil
    let _: sec_protocol_challenge_complete_t = { _ in }
    let _: sec_protocol_challenge_t = { _, complete in complete(nil) }
    let _: sec_protocol_key_update_complete_t = {}
    let _: sec_protocol_key_update_t = { _, complete in complete() }
    let _: sec_protocol_verify_complete_t = { _ in }
    let _: sec_protocol_verify_t = { _, _, complete in complete(false) }
    let _: sec_protocol_pre_shared_key_selection_complete_t = { _ in }
    let _: sec_protocol_pre_shared_key_selection_t = { _, _, complete in complete(nil) }
    let queue = dispatch_queue_s()
    require(queue === queue, "queue identity")
    let _: dispatch_data_t = Data()
    require(SecKeyGetTypeID() != SecPolicyGetTypeID(), "distinct")
}

func testSecKeyRawSignVerify() {
    let priv = rsaPrivate()
    let digestInfo = [UInt8](repeating: 0x11, count: 32)
    var sigLen = 256
    var sig = [UInt8](repeating: 0, count: 256)
    let signStatus = digestInfo.withUnsafeBufferPointer { raw in
        sig.withUnsafeMutableBufferPointer { out in
            var length = 256
            let status = SecKeyRawSign(priv, .sigRaw, raw.baseAddress!, raw.count, out.baseAddress!, &length)
            sigLen = length
            return status
        }
    }
    require(signStatus == errSecSuccess, "raw sign")
    let verify = digestInfo.withUnsafeBufferPointer { dataPtr in
        sig.withUnsafeBufferPointer { sigPtr in
            SecKeyRawVerify(priv, .sigRaw, dataPtr.baseAddress!, dataPtr.count, sigPtr.baseAddress!, sigLen)
        }
    }
    require(verify == errSecSuccess, "raw verify")
}
