import Foundation

public func SecAccessControlCreateWithFlags(
    _ allocator: CFAllocator?,
    _ protection: CFTypeRef,
    _ flags: SecAccessControlCreateFlags,
    _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?
) -> SecAccessControl? {
    _ = allocator
    let text: String
    if let value = protection as? String {
        text = value
    } else {
        error?.pointee = Unmanaged.passRetained(_securityError(errSecParam, "invalid protection"))
        return nil
    }
    error?.pointee = nil
    return SecAccessControl(protection: text, flags: flags)
}

public func SecAccessControlGetTypeID() -> CFTypeID { _secTypeAccessControl() }

public func SecAddSharedWebCredential(
    _ fqdn: CFString, _ account: CFString, _ password: CFString?,
    _ completionHandler: @escaping (CFError?) -> Void
) {
    _ = fqdn; _ = account; _ = password
    completionHandler(_securityFailClosedError())
}

public func SecCertificateCopyCommonName(
    _ certificate: SecCertificate, _ commonName: UnsafeMutablePointer<CFString?>
) -> OSStatus {
    guard let name = certificate.parsed?.subjectCN else { return errSecItemNotFound }
    commonName.pointee = name as CFString
    return errSecSuccess
}

public func SecCertificateCopyData(_ certificate: SecCertificate) -> CFData {
    certificate.data
}

public func SecCertificateCopyEmailAddresses(
    _ certificate: SecCertificate, _ emailAddresses: UnsafeMutablePointer<CFArray?>
) -> OSStatus {
    emailAddresses.pointee = (certificate.parsed?.emails ?? []) as CFArray
    return errSecSuccess
}

public func SecCertificateCopyKey(_ certificate: SecCertificate) -> SecKey? {
    guard let stored = certificate.parsed?.publicKey else { return nil }
    return _secWrapKey(stored, keyClass: kSecAttrKeyClassPublic)
}

public func SecCertificateCopyNormalizedIssuerSequence(_ certificate: SecCertificate) -> CFData? {
    certificate.parsed.map { Data($0.issuerDER) }
}

public func SecCertificateCopyNormalizedSubjectSequence(_ certificate: SecCertificate) -> CFData? {
    certificate.parsed.map { Data($0.subjectDER) }
}

public func SecCertificateCopyNotValidAfterDate(_ certificate: SecCertificate) -> CFDate? {
    certificate.parsed?.notAfter
}

public func SecCertificateCopyNotValidBeforeDate(_ certificate: SecCertificate) -> CFDate? {
    certificate.parsed?.notBefore
}

public func SecCertificateCopyPublicKey(_ certificate: SecCertificate) -> SecKey? {
    SecCertificateCopyKey(certificate)
}

public func SecCertificateCopySerialNumber(_ certificate: SecCertificate) -> CFData? {
    certificate.parsed.map { Data($0.serial) }
}

public func SecCertificateCopySerialNumberData(
    _ certificate: SecCertificate, _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?
) -> CFData? {
    error?.pointee = nil
    return SecCertificateCopySerialNumber(certificate)
}

public func SecCertificateCopySubjectSummary(_ certificate: SecCertificate) -> CFString? {
    certificate.parsed?.subjectCN.map { $0 as CFString }
}

public func SecCertificateCreateWithData(_ allocator: CFAllocator?, _ data: CFData) -> SecCertificate? {
    _ = allocator
    let bytes = Array(data)
    guard let parsed = _secParseCertificate(bytes) else { return nil }
    return SecCertificate(data: data, parsed: parsed)
}

public func SecCertificateGetTypeID() -> CFTypeID { _secTypeCertificate() }

public func SecCreateSharedWebCredentialPassword() -> CFString? { nil }

public func SecIdentityCopyCertificate(
    _ identityRef: SecIdentity, _ certificateRef: UnsafeMutablePointer<SecCertificate?>
) -> OSStatus {
    certificateRef.pointee = identityRef.certificate
    return errSecSuccess
}

public func SecIdentityCopyPrivateKey(
    _ identityRef: SecIdentity, _ privateKeyRef: UnsafeMutablePointer<SecKey?>
) -> OSStatus {
    privateKeyRef.pointee = identityRef.privateKey
    return errSecSuccess
}

public func SecIdentityCreate(
    _ allocator: CFAllocator?, _ certificate: SecCertificate, _ privateKey: SecKey
) -> SecIdentity? {
    _ = allocator
    return SecIdentity(certificate: certificate, privateKey: privateKey)
}

public func SecIdentityGetTypeID() -> CFTypeID { _secTypeIdentity() }

func _secWrapKey(_ stored: _SecStoredKey, keyClass: CFString) -> SecKey {
    let attrs: [String: Any] = [
        kSecAttrKeyType as String: stored.keyType,
        kSecAttrKeyClass as String: keyClass,
        kSecAttrKeySizeInBits as String: stored.keySize,
    ]
    return SecKey(attributes: attrs, stored: stored)
}

public func SecKeyCopyAttributes(_ key: SecKey) -> CFDictionary? {
    key.attributes as CFDictionary
}

public func SecKeyCopyExternalRepresentation(
    _ key: SecKey, _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?
) -> CFData? {
    switch key.stored {
    case .rsa(let rsa):
        if rsa.isPrivate {
            guard let bytes = rsa.pkcs1Private() else {
                error?.pointee = Unmanaged.passRetained(_securityError(errSecParam, "rsa export"))
                return nil
            }
            error?.pointee = nil
            return Data(bytes)
        }
        error?.pointee = nil
        return Data(rsa.pkcs1Public())
    case .ec(let ec):
        if ec.isPrivate {
            guard let bytes = ec.x963Private() else {
                error?.pointee = Unmanaged.passRetained(_securityError(errSecParam, "ec export"))
                return nil
            }
            error?.pointee = nil
            return Data(bytes)
        }
        error?.pointee = nil
        return Data(ec.x963Public())
    }
}

public func SecKeyCopyKeyExchangeResult(
    _ privateKey: SecKey, _ algorithm: SecKeyAlgorithm, _ publicKey: SecKey,
    _ parameters: CFDictionary, _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?
) -> CFData? {
    _ = parameters
    let name = algorithm.rawValue as String
    let isECDH = name.hasPrefix("ecdhKeyExchange")
    guard isECDH,
          case .ec(let priv) = privateKey.stored,
          case .ec(let pub) = publicKey.stored,
          let secret = _secECDH(privateKey: priv, publicKey: pub) else {
        error?.pointee = Unmanaged.passRetained(_securityError(errSecUnimplemented, "key exchange"))
        return nil
    }
    error?.pointee = nil
    return Data(secret)
}

public func SecKeyCopyPublicKey(_ key: SecKey) -> SecKey? {
    _secWrapKey(key.stored.publicOnly(), keyClass: kSecAttrKeyClassPublic)
}

private func _secOAEPDigest(_ name: String) -> _SecDigest? {
    if name.hasSuffix("AESGCM") { return nil }
    if name.hasPrefix("rsaEncryptionOAEPSHA512") { return .sha512 }
    if name.hasPrefix("rsaEncryptionOAEPSHA384") { return .sha384 }
    if name.hasPrefix("rsaEncryptionOAEPSHA256") { return .sha256 }
    if name.hasPrefix("rsaEncryptionOAEPSHA224") { return .sha224 }
    if name.hasPrefix("rsaEncryptionOAEPSHA1") { return .sha1 }
    return .sha256
}

public func SecKeyCreateDecryptedData(
    _ key: SecKey, _ algorithm: SecKeyAlgorithm, _ ciphertext: CFData,
    _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?
) -> CFData? {
    let name = algorithm.rawValue as String
    if name.hasPrefix("ecies") {
        error?.pointee = Unmanaged.passRetained(_securityError(errSecUnimplemented, "ECIES fail-closed"))
        return nil
    }
    guard case .rsa(let rsa) = key.stored else {
        error?.pointee = Unmanaged.passRetained(_securityError(errSecParam, "not RSA"))
        return nil
    }
    let bytes = Array(ciphertext)
    let plain: [UInt8]?
    if name == (SecKeyAlgorithm.rsaEncryptionPKCS1.rawValue as String) {
        plain = _secRSAESPKCS1Decrypt(key: rsa, ciphertext: bytes)
    } else if name == (SecKeyAlgorithm.rsaEncryptionRaw.rawValue as String) {
        plain = rsa.crypt(bytes, privateExponent: true)
    } else if name.hasPrefix("rsaEncryptionOAEP") {
        guard let digest = _secOAEPDigest(name) else {
            error?.pointee = Unmanaged.passRetained(_securityError(errSecUnimplemented, "RSA OAEP+AES-GCM"))
            return nil
        }
        plain = _secRSAOAEPDecrypt(key: rsa, ciphertext: bytes, digest: digest)
    } else {
        error?.pointee = Unmanaged.passRetained(_securityError(errSecParam, "algorithm"))
        return nil
    }
    guard let plain else {
        error?.pointee = Unmanaged.passRetained(_securityError(errSecAuthFailed, "decrypt"))
        return nil
    }
    error?.pointee = nil
    return Data(plain)
}

public func SecKeyCreateEncryptedData(
    _ key: SecKey, _ algorithm: SecKeyAlgorithm, _ plaintext: CFData,
    _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?
) -> CFData? {
    let name = algorithm.rawValue as String
    if name.hasPrefix("ecies") {
        error?.pointee = Unmanaged.passRetained(_securityError(errSecUnimplemented, "ECIES fail-closed"))
        return nil
    }
    guard case .rsa(let rsa) = key.stored else {
        error?.pointee = Unmanaged.passRetained(_securityError(errSecParam, "not RSA"))
        return nil
    }
    let bytes = Array(plaintext)
    let cipher: [UInt8]?
    if name == (SecKeyAlgorithm.rsaEncryptionPKCS1.rawValue as String) {
        cipher = _secRSAESPKCS1Encrypt(key: rsa, plaintext: bytes)
    } else if name == (SecKeyAlgorithm.rsaEncryptionRaw.rawValue as String) {
        cipher = rsa.crypt(bytes, privateExponent: false)
    } else if name.hasPrefix("rsaEncryptionOAEP") {
        guard let digest = _secOAEPDigest(name) else {
            error?.pointee = Unmanaged.passRetained(_securityError(errSecUnimplemented, "RSA OAEP+AES-GCM"))
            return nil
        }
        cipher = _secRSAOAEPEncrypt(key: rsa, plaintext: bytes, digest: digest)
    } else {
        error?.pointee = Unmanaged.passRetained(_securityError(errSecParam, "algorithm"))
        return nil
    }
    guard let cipher else {
        error?.pointee = Unmanaged.passRetained(_securityError(errSecParam, "encrypt"))
        return nil
    }
    error?.pointee = nil
    return Data(cipher)
}

public func SecKeyCreateRandomKey(
    _ parameters: CFDictionary, _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?
) -> SecKey? {
    let dict = parameters
    let type = (dict[kSecAttrKeyType as String] as? String) ?? (kSecAttrKeyTypeRSA as String)
    let bits = _secInt(dict[kSecAttrKeySizeInBits as String]) ?? (type == (kSecAttrKeyTypeRSA as String) ? 2048 : 256)
    let stored: _SecStoredKey
    if type == (kSecAttrKeyTypeRSA as String) || type == "42" {
        guard let rsa = _SecRSAKey.generate(bits: bits) else {
            error?.pointee = Unmanaged.passRetained(_securityError(errSecParam, "rsa generate"))
            return nil
        }
        stored = .rsa(rsa)
    } else {
        guard let curve = _secCurve(forBits: bits) else {
            error?.pointee = Unmanaged.passRetained(_securityError(errSecParam, "ec size"))
            return nil
        }
        stored = .ec(_SecECKey.generate(curve: curve))
    }
    error?.pointee = nil
    var attrs = dict
    attrs[kSecAttrKeyClass as String] = kSecAttrKeyClassPrivate
    attrs[kSecAttrKeySizeInBits as String] = stored.keySize
    attrs[kSecAttrKeyType as String] = stored.keyType
    return SecKey(attributes: attrs, stored: stored)
}

public func SecKeyCreateSignature(
    _ key: SecKey, _ algorithm: SecKeyAlgorithm, _ dataToSign: CFData,
    _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?
) -> CFData? {
    let name = algorithm.rawValue as String
    let bytes = Array(dataToSign)
    switch key.stored {
    case .rsa(let rsa):
        let sig: [UInt8]?
        if name.hasPrefix("rsaSignatureMessagePSS") || name.hasPrefix("rsaSignatureDigestPSS") {
            let digest = _secDigest(fromAlgorithm: name)
            let hash = name.hasPrefix("rsaSignatureDigest") ? bytes : digest.hash(bytes)
            sig = _secRSAPSSSign(key: rsa, messageHash: hash, digest: digest)
        } else if name == (SecKeyAlgorithm.rsaSignatureRaw.rawValue as String)
                    || name == (SecKeyAlgorithm.rsaSignatureDigestPKCS1v15Raw.rawValue as String) {
            sig = _secRSAPKCS1Sign(key: rsa, digestInfo: bytes)
        } else {
            let digest = _secDigest(fromAlgorithm: name)
            let hash = name.hasPrefix("rsaSignatureDigest") ? bytes : digest.hash(bytes)
            sig = _secRSAPKCS1Sign(key: rsa, digestInfo: digest.digestInfoPrefix + hash)
        }
        guard let sig else {
            error?.pointee = Unmanaged.passRetained(_securityError(errSecParam, "sign"))
            return nil
        }
        error?.pointee = nil
        return Data(sig)
    case .ec(let ec):
        let digest = _secDigest(fromAlgorithm: name)
        let alreadyHashed = name.hasPrefix("ecdsaSignatureDigest")
            || name == (SecKeyAlgorithm.ecdsaSignatureRFC4754.rawValue as String)
        let hash = alreadyHashed ? bytes : digest.hash(bytes)
        let der = !name.hasPrefix("ecdsaSignatureMessageRFC4754")
            && !name.hasPrefix("ecdsaSignatureDigestRFC4754")
            && name != (SecKeyAlgorithm.ecdsaSignatureRFC4754.rawValue as String)
        guard let sig = _secECDSASign(key: ec, hash: hash, der: der) else {
            error?.pointee = Unmanaged.passRetained(_securityError(errSecParam, "ecdsa"))
            return nil
        }
        error?.pointee = nil
        return Data(sig)
    }
}

func _secDigest(fromAlgorithm name: String) -> _SecDigest {
    if name.hasSuffix("SHA512") { return .sha512 }
    if name.hasSuffix("SHA384") { return .sha384 }
    if name.hasSuffix("SHA224") { return .sha224 }
    if name.hasSuffix("SHA1") { return .sha1 }
    return .sha256
}

public func SecKeyCreateWithData(
    _ keyData: CFData, _ attributes: CFDictionary, _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?
) -> SecKey? {
    let dict = attributes
    let type = (dict[kSecAttrKeyType as String] as? String) ?? ""
    let keyClass = (dict[kSecAttrKeyClass as String] as? String) ?? (kSecAttrKeyClassPrivate as String)
    let wantPrivate = keyClass != (kSecAttrKeyClassPublic as String)
    let bytes = Array(keyData)
    let bits = _secInt(dict[kSecAttrKeySizeInBits as String])
    let stored: _SecStoredKey?
    if type == (kSecAttrKeyTypeRSA as String) || type == "42" || type.isEmpty && _SecRSAKey.parsePKCS1(bytes) != nil {
        stored = _SecRSAKey.parsePKCS1(bytes).map { .rsa($0) }
    } else {
        let curve = bits.flatMap(_secCurve(forBits:))
            ?? _secCurve(forX963: bytes.count)
            ?? _secCurveP256()
        stored = _SecECKey.parseX963(bytes, curve: curve, wantPrivate: wantPrivate).map { .ec($0) }
    }
    guard let stored else {
        error?.pointee = Unmanaged.passRetained(_securityError(errSecParam, "key data"))
        return nil
    }
    error?.pointee = nil
    var attrs = dict
    attrs[kSecAttrKeyType as String] = stored.keyType
    attrs[kSecAttrKeyClass as String] = keyClass
    attrs[kSecAttrKeySizeInBits as String] = stored.keySize
    return SecKey(attributes: attrs, stored: stored)
}

public func SecKeyDecrypt(
    _ key: SecKey, _ padding: SecPadding, _ cipherText: UnsafePointer<UInt8>, _ cipherTextLen: Int,
    _ plainText: UnsafeMutablePointer<UInt8>, _ plainTextLen: UnsafeMutablePointer<Int>
) -> OSStatus {
    let data = Data(bytes: cipherText, count: cipherTextLen)
    let algorithm: SecKeyAlgorithm = padding.contains(.OAEP) ? .rsaEncryptionOAEPSHA1 : .rsaEncryptionPKCS1
    guard let plain = SecKeyCreateDecryptedData(key, algorithm, data, nil) else { return errSecParam }
    let count = min(plain.count, plainTextLen.pointee)
    plain.copyBytes(to: plainText, count: count)
    plainTextLen.pointee = count
    return errSecSuccess
}

public func SecKeyEncrypt(
    _ key: SecKey, _ padding: SecPadding, _ plainText: UnsafePointer<UInt8>, _ plainTextLen: Int,
    _ cipherText: UnsafeMutablePointer<UInt8>, _ cipherTextLen: UnsafeMutablePointer<Int>
) -> OSStatus {
    let data = Data(bytes: plainText, count: plainTextLen)
    let algorithm: SecKeyAlgorithm = padding.contains(.OAEP) ? .rsaEncryptionOAEPSHA1 : .rsaEncryptionPKCS1
    guard let cipher = SecKeyCreateEncryptedData(key, algorithm, data, nil) else { return errSecParam }
    let count = min(cipher.count, cipherTextLen.pointee)
    cipher.copyBytes(to: cipherText, count: count)
    cipherTextLen.pointee = count
    return errSecSuccess
}

public func SecKeyGeneratePair(
    _ parameters: CFDictionary,
    _ publicKey: UnsafeMutablePointer<SecKey?>?,
    _ privateKey: UnsafeMutablePointer<SecKey?>?
) -> OSStatus {
    guard let priv = SecKeyCreateRandomKey(parameters, nil) else { return errSecParam }
    privateKey?.pointee = priv
    publicKey?.pointee = SecKeyCopyPublicKey(priv)
    return errSecSuccess
}

public func SecKeyGetBlockSize(_ key: SecKey) -> Int {
    switch key.stored {
    case .rsa(let rsa): return rsa.modulusBytes
    case .ec(let ec): return ec.curve.size
    }
}

public func SecKeyGetTypeID() -> CFTypeID { _secTypeKey() }

public func SecKeyIsAlgorithmSupported(
    _ key: SecKey, _ operation: SecKeyOperationType, _ algorithm: SecKeyAlgorithm
) -> Bool {
    let name = algorithm.rawValue as String
    switch key.stored {
    case .rsa:
        if name.hasPrefix("ecies") || name.hasPrefix("ecdsa") || name.hasPrefix("ecdh") { return false }
        if name.hasSuffix("AESGCM") { return false }
        return true
    case .ec:
        if name.hasPrefix("rsa") { return false }
        if name.hasPrefix("ecies") { return false }
        if operation == .encrypt || operation == .decrypt { return false }
        return true
    }
}

public func SecKeyRawSign(
    _ key: SecKey, _ padding: SecPadding, _ dataToSign: UnsafePointer<UInt8>, _ dataToSignLen: Int,
    _ sig: UnsafeMutablePointer<UInt8>, _ sigLen: UnsafeMutablePointer<Int>
) -> OSStatus {
    _ = padding
    let data = Data(bytes: dataToSign, count: dataToSignLen)
    guard let signature = SecKeyCreateSignature(key, .rsaSignatureRaw, data, nil) else { return errSecParam }
    let count = min(signature.count, sigLen.pointee)
    signature.copyBytes(to: sig, count: count)
    sigLen.pointee = count
    return errSecSuccess
}

public func SecKeyRawVerify(
    _ key: SecKey, _ padding: SecPadding, _ signedData: UnsafePointer<UInt8>, _ signedDataLen: Int,
    _ sig: UnsafePointer<UInt8>, _ sigLen: Int
) -> OSStatus {
    _ = padding
    let data = Data(bytes: signedData, count: signedDataLen)
    let signature = Data(bytes: sig, count: sigLen)
    return SecKeyVerifySignature(key, .rsaSignatureRaw, data, signature, nil) ? errSecSuccess : errSecAuthFailed
}

public func SecKeyVerifySignature(
    _ key: SecKey, _ algorithm: SecKeyAlgorithm, _ signedData: CFData, _ signature: CFData,
    _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?
) -> Bool {
    let name = algorithm.rawValue as String
    let bytes = Array(signedData)
    let sig = Array(signature)
    switch key.stored {
    case .rsa(let rsa):
        let ok: Bool
        if name.hasPrefix("rsaSignatureMessagePSS") || name.hasPrefix("rsaSignatureDigestPSS") {
            let digest = _secDigest(fromAlgorithm: name)
            let hash = name.hasPrefix("rsaSignatureDigest") ? bytes : digest.hash(bytes)
            ok = _secRSAPSSVerify(key: rsa, messageHash: hash, signature: sig, digest: digest)
        } else if name == (SecKeyAlgorithm.rsaSignatureRaw.rawValue as String)
                    || name == (SecKeyAlgorithm.rsaSignatureDigestPKCS1v15Raw.rawValue as String) {
            ok = _secRSAPKCS1Verify(key: rsa, digestInfo: bytes, signature: sig)
        } else {
            let digest = _secDigest(fromAlgorithm: name)
            let hash = name.hasPrefix("rsaSignatureDigest") ? bytes : digest.hash(bytes)
            ok = _secRSAPKCS1Verify(key: rsa, digestInfo: digest.digestInfoPrefix + hash, signature: sig)
        }
        if !ok { error?.pointee = Unmanaged.passRetained(_securityError(errSecAuthFailed, "verify")) }
        else { error?.pointee = nil }
        return ok
    case .ec(let ec):
        let digest = _secDigest(fromAlgorithm: name)
        let hash = name.hasPrefix("ecdsaSignatureDigest") || name == (SecKeyAlgorithm.ecdsaSignatureRFC4754.rawValue as String)
            ? bytes : digest.hash(bytes)
        let ok = _secECDSAVerify(key: ec, hash: hash, signature: sig)
        if !ok { error?.pointee = Unmanaged.passRetained(_securityError(errSecAuthFailed, "verify")) }
        else { error?.pointee = nil }
        return ok
    }
}

public func SecPKCS12Import(
    _ pkcs12_data: CFData, _ options: CFDictionary, _ items: UnsafeMutablePointer<CFArray?>
) -> OSStatus {
    let password = (options[kSecImportExportPassphrase as String] as? String) ?? ""
    guard let parsed = _secPKCS12Import(Array(pkcs12_data), password: password) else {
        items.pointee = nil
        return errSecAuthFailed
    }
    var out: [[String: Any]] = []
    if let identity = parsed.identity,
       let cert = SecCertificateCreateWithData(nil, Data(identity.cert.der)) {
        let key = _secWrapKey(identity.key, keyClass: kSecAttrKeyClassPrivate)
        let wrapped = SecIdentity(certificate: cert, privateKey: key)
        var entry: [String: Any] = [kSecImportItemIdentity as String: wrapped]
        entry[kSecImportItemCertChain as String] = parsed.certs.compactMap {
            SecCertificateCreateWithData(nil, Data($0.der))
        }
        out.append(entry)
    } else {
        for cert in parsed.certs {
            if let object = SecCertificateCreateWithData(nil, Data(cert.der)) {
                out.append([kSecImportItemCertChain as String: [object]])
            }
        }
    }
    items.pointee = out as CFArray
    return errSecSuccess
}

public func SecPolicyCopyProperties(_ policyRef: SecPolicy) -> CFDictionary? {
    var props = policyRef.properties
    props[kSecPolicyOid as String] = policyRef.identifier
    if let host = policyRef.hostname { props[kSecPolicyName as String] = host }
    if policyRef.revocationFlags != 0 {
        props[kSecPolicyRevocationFlags as String] = Int(policyRef.revocationFlags)
    }
    return props as CFDictionary
}

public func SecPolicyCreateBasicX509() -> SecPolicy {
    SecPolicy(identifier: kSecPolicyAppleX509Basic as String)
}

public func SecPolicyCreateRevocation(_ revocationFlags: CFOptionFlags) -> SecPolicy? {
    let policy = SecPolicy(identifier: kSecPolicyAppleRevocation as String)
    policy.revocationFlags = revocationFlags
    return policy
}

public func SecPolicyCreateSSL(_ server: Bool, _ hostname: CFString?) -> SecPolicy {
    let oid = server ? (kSecPolicyAppleSSLServer as String) : (kSecPolicyAppleSSLClient as String)
    var properties: [String: Any] = [kSecPolicyOid as String: oid]
    if let hostname { properties[kSecPolicyName as String] = hostname }
    let policy = SecPolicy(identifier: oid, properties: properties)
    policy.server = server
    policy.hostname = hostname
    return policy
}

public func SecPolicyCreateWithProperties(
    _ policyIdentifier: CFTypeRef, _ properties: CFDictionary?
) -> SecPolicy? {
    guard let oid = policyIdentifier as? String else { return nil }
    var props = properties ?? [:]
    props[kSecPolicyOid as String] = oid
    let policy = SecPolicy(identifier: oid, properties: props)
    policy.hostname = props[kSecPolicyName as String] as? String
    if let flags = _secInt(props[kSecPolicyRevocationFlags as String]) {
        policy.revocationFlags = CFOptionFlags(flags)
    }
    return policy
}

public func SecPolicyGetTypeID() -> CFTypeID { _secTypePolicy() }

public func SecRequestSharedWebCredential(
    _ fqdn: CFString?, _ account: CFString?,
    _ completionHandler: @escaping (CFArray?, CFError?) -> Void
) {
    _ = fqdn; _ = account
    completionHandler(nil, _securityFailClosedError())
}

func _secCertificates(from value: CFTypeRef) -> [SecCertificate] {
    if let cert = value as? SecCertificate { return [cert] }
    if let array = value as? [SecCertificate] { return array }
    if let array = value as? [Any] { return array.compactMap { $0 as? SecCertificate } }
    if let data = value as? Data, let cert = SecCertificateCreateWithData(nil, data) { return [cert] }
    return []
}

func _secPolicies(from value: CFTypeRef?) -> [SecPolicy] {
    guard let value else { return [SecPolicyCreateBasicX509()] }
    if let policy = value as? SecPolicy { return [policy] }
    if let array = value as? [SecPolicy] { return array }
    if let array = value as? [Any] { return array.compactMap { $0 as? SecPolicy } }
    return [SecPolicyCreateBasicX509()]
}

public func SecTrustCopyCertificateChain(_ trust: SecTrust) -> CFArray? {
    let chain = trust.builtChain.isEmpty ? trust.certificates : trust.builtChain
    return chain as CFArray
}

public func SecTrustCopyCustomAnchorCertificates(
    _ trust: SecTrust, _ anchors: UnsafeMutablePointer<CFArray?>
) -> OSStatus {
    anchors.pointee = trust.anchors as CFArray
    return errSecSuccess
}

public func SecTrustCopyExceptions(_ trust: SecTrust) -> CFData? { trust.exceptions }

public func SecTrustCopyKey(_ trust: SecTrust) -> SecKey? {
    trust.certificates.first.flatMap(SecCertificateCopyKey)
}

public func SecTrustCopyPolicies(
    _ trust: SecTrust, _ policies: UnsafeMutablePointer<CFArray?>
) -> OSStatus {
    policies.pointee = trust.policies as CFArray
    return errSecSuccess
}

public func SecTrustCopyProperties(_ trust: SecTrust) -> CFArray? {
    [[kSecPropertyTypeTitle as String: "Trust result", kSecTrustResultValue as String: Int(trust.lastResult.rawValue)]]
}

public func SecTrustCopyPublicKey(_ trust: SecTrust) -> SecKey? { SecTrustCopyKey(trust) }

public func SecTrustCopyResult(_ trust: SecTrust) -> CFDictionary? {
    [
        kSecTrustResultValue as String: Int(trust.lastResult.rawValue),
        kSecTrustEvaluationDate as String: trust.verifyDate ?? Date(),
        kSecTrustRevocationChecked as String: false,
    ] as CFDictionary
}

public func SecTrustCreateWithCertificates(
    _ certificates: CFTypeRef, _ policies: CFTypeRef?, _ trust: UnsafeMutablePointer<SecTrust?>
) -> OSStatus {
    let certs = _secCertificates(from: certificates)
    let pols = _secPolicies(from: policies)
    trust.pointee = SecTrust(certificates: certs, policies: pols)
    return errSecSuccess
}

func _secEvaluate(_ trust: SecTrust) -> (SecTrustResultType, NSError?) {
    let now = trust.verifyDate ?? Date()
    var remaining = trust.certificates
    var chain: [SecCertificate] = []
    if let leaf = remaining.first { chain.append(leaf); remaining.removeFirst() }
    else {
        trust.lastResult = .invalid
        trust.evaluated = true
        return (.invalid, _securityError(errSecParam, "empty certificates"))
    }
    func issuerOf(_ cert: SecCertificate) -> SecCertificate? {
        guard let parsed = cert.parsed else { return nil }
        let pool = trust.anchors + remaining + trust.certificates
        for candidate in pool {
            guard let other = candidate.parsed else { continue }
            if other.subjectDER == parsed.issuerDER { return candidate }
        }
        return nil
    }
    while let next = issuerOf(chain[chain.count - 1]) {
        if chain.contains(where: { $0 === next }) { break }
        chain.append(next)
        if trust.anchors.contains(where: { $0 === next }) { break }
        if next.parsed?.subjectDER == next.parsed?.issuerDER { break }
    }
    trust.builtChain = chain
    let dateOK = chain.allSatisfy { cert in
        guard let parsed = cert.parsed else { return false }
        return now >= parsed.notBefore && now <= parsed.notAfter
    }
    var signaturesOK = true
    if chain.count >= 2 {
        for index in 0..<(chain.count - 1) {
            guard let signed = chain[index].parsed, let issuerKey = chain[index + 1].parsed?.publicKey else {
                signaturesOK = false
                break
            }
            if !_secVerifyCertSignature(signed: signed, issuerKey: issuerKey) { signaturesOK = false; break }
        }
    } else if let leaf = chain.first?.parsed, let key = leaf.publicKey {
        signaturesOK = _secVerifyCertSignature(signed: leaf, issuerKey: key)
    }
    var anchored = false
    if let last = chain.last {
        if trust.anchors.contains(where: { $0 === last }) {
            anchored = true
        } else if let lastParsed = last.parsed {
            anchored = trust.anchors.contains { $0.parsed?.subjectDER == lastParsed.subjectDER }
        }
        if trust.anchors.isEmpty && !trust.anchorsOnly {
            anchored = last.parsed?.subjectDER == last.parsed?.issuerDER
        }
    }
    var hostnameOK = true
    for policy in trust.policies {
        if let host = policy.hostname, policy.identifier == (kSecPolicyAppleSSLServer as String)
            || policy.identifier == (kSecPolicyAppleSSL as String)
            || policy.identifier == (kSecPolicyAppleSSLClient as String) {
            if let parsed = chain.first?.parsed {
                hostnameOK = _secMatchHostname(host, cert: parsed)
            }
        }
        if policy.revocationFlags & kSecRevocationRequirePositiveResponse != 0 {
            trust.lastResult = .recoverableTrustFailure
            trust.evaluated = true
            let err = _securityError(errSecUnimplemented, "revocation fail-closed")
            trust.lastError = err
            return (.recoverableTrustFailure, err)
        }
    }
    if dateOK && signaturesOK && anchored && hostnameOK {
        trust.lastResult = trust.anchors.isEmpty ? .unspecified : .proceed
        trust.evaluated = true
        trust.lastError = nil
        return (trust.lastResult, nil)
    }
    trust.lastResult = .recoverableTrustFailure
    trust.evaluated = true
    let err = _securityError(errSecAuthFailed, "trust evaluation failed")
    trust.lastError = err
    return (.recoverableTrustFailure, err)
}

public func SecTrustEvaluate(_ trust: SecTrust, _ result: UnsafeMutablePointer<SecTrustResultType>) -> OSStatus {
    let (status, _) = _secEvaluate(trust)
    result.pointee = status
    return errSecSuccess
}

public func SecTrustEvaluateWithError(_ trust: SecTrust, _ error: UnsafeMutablePointer<CFError?>?) -> Bool {
    let (status, err) = _secEvaluate(trust)
    let ok = status == .proceed || status == .unspecified
    if !ok { error?.pointee = err }
    else { error?.pointee = nil }
    return ok
}

public func SecTrustEvaluateAsync(
    _ trust: SecTrust, _ queue: dispatch_queue_t?, _ result: @escaping SecTrustCallback
) -> OSStatus {
    _ = queue
    var value = SecTrustResultType.invalid
    let status = SecTrustEvaluate(trust, &value)
    result(trust, value)
    return status
}

public func SecTrustEvaluateAsyncWithError(
    _ trust: SecTrust, _ queue: dispatch_queue_t, _ result: @escaping SecTrustWithErrorCallback
) -> OSStatus {
    _ = queue
    var err: CFError?
    let ok = SecTrustEvaluateWithError(trust, &err)
    result(trust, ok, err)
    return errSecSuccess
}

public func SecTrustGetCertificateAtIndex(_ trust: SecTrust, _ ix: CFIndex) -> SecCertificate? {
    let chain = trust.builtChain.isEmpty ? trust.certificates : trust.builtChain
    guard ix >= 0, ix < chain.count else { return nil }
    return chain[ix]
}

public func SecTrustGetCertificateCount(_ trust: SecTrust) -> CFIndex {
    (trust.builtChain.isEmpty ? trust.certificates : trust.builtChain).count
}

public func SecTrustGetNetworkFetchAllowed(
    _ trust: SecTrust, _ allowFetch: UnsafeMutablePointer<DarwinBoolean>
) -> OSStatus {
    allowFetch.pointee = DarwinBoolean(trust.networkFetchAllowed)
    return errSecSuccess
}

public func SecTrustGetTrustResult(
    _ trust: SecTrust, _ result: UnsafeMutablePointer<SecTrustResultType>
) -> OSStatus {
    result.pointee = trust.lastResult
    return errSecSuccess
}

public func SecTrustGetTypeID() -> CFTypeID { _secTypeTrust() }

public func SecTrustGetVerifyTime(_ trust: SecTrust) -> CFAbsoluteTime {
    (trust.verifyDate ?? Date()).timeIntervalSinceReferenceDate
}

public func SecTrustSetAnchorCertificates(_ trust: SecTrust, _ anchorCertificates: CFArray?) -> OSStatus {
    if let array = anchorCertificates {
        trust.anchors = array.compactMap { $0 as? SecCertificate }
    } else {
        trust.anchors = []
    }
    return errSecSuccess
}

public func SecTrustSetAnchorCertificatesOnly(_ trust: SecTrust, _ anchorCertificatesOnly: Bool) -> OSStatus {
    trust.anchorsOnly = anchorCertificatesOnly
    return errSecSuccess
}

public func SecTrustSetExceptions(_ trust: SecTrust, _ exceptions: CFData?) -> Bool {
    trust.exceptions = exceptions
    return true
}

public func SecTrustSetNetworkFetchAllowed(_ trust: SecTrust, _ allowFetch: Bool) -> OSStatus {
    trust.networkFetchAllowed = allowFetch
    return errSecSuccess
}

public func SecTrustSetOCSPResponse(_ trust: SecTrust, _ responseData: CFTypeRef?) -> OSStatus {
    trust.ocsp = responseData
    return errSecSuccess
}

public func SecTrustSetPolicies(_ trust: SecTrust, _ policies: CFTypeRef) -> OSStatus {
    trust.policies = _secPolicies(from: policies)
    return errSecSuccess
}

public func SecTrustSetSignedCertificateTimestamps(_ trust: SecTrust, _ sctArray: CFArray?) -> OSStatus {
    trust.scts = sctArray
    return errSecSuccess
}

public func SecTrustSetVerifyDate(_ trust: SecTrust, _ verifyDate: CFDate) -> OSStatus {
    trust.verifyDate = verifyDate
    return errSecSuccess
}

public func sec_certificate_copy_ref(_ certificate: sec_certificate_t) -> Unmanaged<SecCertificate> {
    (certificate as? _OSSecCertificate).map { Unmanaged.passUnretained($0.certificate) }
        ?? Unmanaged.passUnretained(SecCertificate(data: Data(), parsed: nil))
}

public func sec_certificate_create(_ certificate: SecCertificate) -> sec_certificate_t? {
    _OSSecCertificate(certificate: certificate)
}

public func sec_identity_access_certificates(
    _ identity: sec_identity_t, _ handler: @escaping (sec_certificate_t) -> Void
) -> Bool {
    guard let wrapped = identity as? _OSSecIdentity else { return false }
    handler(_OSSecCertificate(certificate: wrapped.identity.certificate))
    for cert in wrapped.certificates { handler(_OSSecCertificate(certificate: cert)) }
    return true
}

public func sec_identity_copy_certificates_ref(_ identity: sec_identity_t) -> Unmanaged<NSArray>? {
    guard let wrapped = identity as? _OSSecIdentity else { return nil }
    var certs: [SecCertificate] = [wrapped.identity.certificate]
    certs.append(contentsOf: wrapped.certificates)
    return Unmanaged.passRetained(certs as NSArray)
}

public func sec_identity_copy_ref(_ identity: sec_identity_t) -> Unmanaged<SecIdentity>? {
    (identity as? _OSSecIdentity).map { Unmanaged.passUnretained($0.identity) }
}

public func sec_identity_create(_ identity: SecIdentity) -> sec_identity_t? {
    _OSSecIdentity(identity: identity)
}

public func sec_identity_create_with_certificates(_ identity: SecIdentity, _ certificates: CFArray) -> sec_identity_t? {
    let extra = certificates.compactMap { $0 as? SecCertificate }
    return _OSSecIdentity(identity: identity, certificates: extra)
}

public func sec_protocol_metadata_access_distinguished_names(
    _ metadata: sec_protocol_metadata_t, _ handler: @escaping (dispatch_data_t) -> Void
) -> Bool {
    _ = metadata; _ = handler
    return false
}

public func sec_protocol_metadata_access_ocsp_response(
    _ metadata: sec_protocol_metadata_t, _ handler: @escaping (dispatch_data_t) -> Void
) -> Bool {
    _ = metadata; _ = handler
    return false
}

public func sec_protocol_metadata_access_peer_certificate_chain(
    _ metadata: sec_protocol_metadata_t, _ handler: @escaping (sec_certificate_t) -> Void
) -> Bool {
    _ = metadata; _ = handler
    return false
}

public func sec_protocol_metadata_access_pre_shared_keys(
    _ metadata: sec_protocol_metadata_t, _ handler: @escaping (dispatch_data_t, dispatch_data_t) -> Void
) -> Bool {
    _ = metadata; _ = handler
    return false
}

public func sec_protocol_metadata_access_supported_signature_algorithms(
    _ metadata: sec_protocol_metadata_t, _ handler: @escaping (UInt16) -> Void
) -> Bool {
    _ = metadata; _ = handler
    return false
}

public func sec_protocol_metadata_challenge_parameters_are_equal(
    _ metadataA: sec_protocol_metadata_t, _ metadataB: sec_protocol_metadata_t
) -> Bool {
    metadataA === metadataB
}

public func sec_protocol_metadata_copy_negotiated_protocol(_ metadata: sec_protocol_metadata_t) -> UnsafePointer<CChar>? {
    _ = metadata
    return nil
}

public func sec_protocol_metadata_copy_peer_public_key(_ metadata: sec_protocol_metadata_t) -> dispatch_data_t? {
    _ = metadata
    return nil
}

public func sec_protocol_metadata_copy_server_name(_ metadata: sec_protocol_metadata_t) -> UnsafePointer<CChar>? {
    _ = metadata
    return nil
}

public func sec_protocol_metadata_create_secret(
    _ metadata: sec_protocol_metadata_t, _ label_len: Int, _ label: UnsafePointer<CChar>, _ exporter_length: Int
) -> dispatch_data_t? {
    _ = metadata; _ = label_len; _ = label; _ = exporter_length
    return nil
}

public func sec_protocol_metadata_create_secret_with_context(
    _ metadata: sec_protocol_metadata_t, _ label_len: Int, _ label: UnsafePointer<CChar>,
    _ context_len: Int, _ context: UnsafePointer<UInt8>, _ exporter_length: Int
) -> dispatch_data_t? {
    _ = metadata; _ = label_len; _ = label; _ = context_len; _ = context; _ = exporter_length
    return nil
}

public func sec_protocol_metadata_get_early_data_accepted(_ metadata: sec_protocol_metadata_t) -> Bool {
    _ = metadata
    return false
}

public func sec_protocol_metadata_get_negotiated_ciphersuite(_ metadata: sec_protocol_metadata_t) -> SSLCipherSuite {
    _ = metadata
    return 0
}

public func sec_protocol_metadata_get_negotiated_protocol(_ metadata: sec_protocol_metadata_t) -> UnsafePointer<CChar>? {
    _ = metadata
    return nil
}

public func sec_protocol_metadata_get_negotiated_protocol_version(_ metadata: sec_protocol_metadata_t) -> SSLProtocol {
    _ = metadata
    return .sslProtocolUnknown
}

public func sec_protocol_metadata_get_negotiated_tls_ciphersuite(_ metadata: sec_protocol_metadata_t) -> tls_ciphersuite_t {
    _ = metadata
    return .RSA_WITH_AES_128_GCM_SHA256
}

public func sec_protocol_metadata_get_negotiated_tls_protocol_version(_ metadata: sec_protocol_metadata_t) -> tls_protocol_version_t {
    _ = metadata
    return .TLSv12
}

public func sec_protocol_metadata_get_server_name(_ metadata: sec_protocol_metadata_t) -> UnsafePointer<CChar>? {
    _ = metadata
    return nil
}

public func sec_protocol_metadata_peers_are_equal(
    _ metadataA: sec_protocol_metadata_t, _ metadataB: sec_protocol_metadata_t
) -> Bool {
    metadataA === metadataB
}

public func sec_protocol_options_add_pre_shared_key(
    _ options: sec_protocol_options_t, _ psk: dispatch_data_t, _ psk_identity: dispatch_data_t
) {
    _ = options; _ = psk; _ = psk_identity
}

public func sec_protocol_options_add_tls_application_protocol(
    _ options: sec_protocol_options_t, _ application_protocol: UnsafePointer<CChar>
) {
    _ = options; _ = application_protocol
}

public func sec_protocol_options_add_tls_ciphersuite(_ options: sec_protocol_options_t, _ ciphersuite: SSLCipherSuite) {
    (options as? _OSSecProtocolOptions)?.ciphers.append(ciphersuite)
}

public func sec_protocol_options_add_tls_ciphersuite_group(
    _ options: sec_protocol_options_t, _ group: SSLCiphersuiteGroup
) {
    _ = options; _ = group
}

public func sec_protocol_options_append_tls_ciphersuite(
    _ options: sec_protocol_options_t, _ ciphersuite: tls_ciphersuite_t
) {
    (options as? _OSSecProtocolOptions)?.ciphers.append(ciphersuite.rawValue)
}

public func sec_protocol_options_append_tls_ciphersuite_group(
    _ options: sec_protocol_options_t, _ group: tls_ciphersuite_group_t
) {
    _ = options; _ = group
}

public func sec_protocol_options_are_equal(
    _ optionsA: sec_protocol_options_t, _ optionsB: sec_protocol_options_t
) -> Bool {
    optionsA === optionsB
}

public func sec_protocol_options_get_default_max_dtls_protocol_version() -> tls_protocol_version_t { .DTLSv12 }
public func sec_protocol_options_get_default_max_tls_protocol_version() -> tls_protocol_version_t { .TLSv13 }
public func sec_protocol_options_get_default_min_dtls_protocol_version() -> tls_protocol_version_t { .DTLSv12 }
public func sec_protocol_options_get_default_min_tls_protocol_version() -> tls_protocol_version_t { .TLSv12 }

public func sec_protocol_options_set_challenge_block(
    _ options: sec_protocol_options_t, _ challenge_block: @escaping sec_protocol_challenge_t,
    _ challenge_queue: dispatch_queue_t
) {
    _ = options; _ = challenge_block; _ = challenge_queue
}

public func sec_protocol_options_set_key_update_block(
    _ options: sec_protocol_options_t, _ key_update_block: @escaping sec_protocol_key_update_t,
    _ key_update_queue: dispatch_queue_t
) {
    _ = options; _ = key_update_block; _ = key_update_queue
}

public func sec_protocol_options_set_local_identity(_ options: sec_protocol_options_t, _ identity: sec_identity_t) {
    (options as? _OSSecProtocolOptions)?.identity = identity
}

public func sec_protocol_options_set_max_tls_protocol_version(
    _ options: sec_protocol_options_t, _ version: tls_protocol_version_t
) {
    (options as? _OSSecProtocolOptions)?.maxVersion = version
}

public func sec_protocol_options_set_min_tls_protocol_version(
    _ options: sec_protocol_options_t, _ version: tls_protocol_version_t
) {
    (options as? _OSSecProtocolOptions)?.minVersion = version
}

public func sec_protocol_options_set_peer_authentication_required(
    _ options: sec_protocol_options_t, _ peer_authentication_required: Bool
) {
    (options as? _OSSecProtocolOptions)?.peerAuth = peer_authentication_required
}

public func sec_protocol_options_set_pre_shared_key_selection_block(
    _ options: sec_protocol_options_t,
    _ psk_selection_block: @escaping sec_protocol_pre_shared_key_selection_t,
    _ psk_selection_queue: dispatch_queue_t
) {
    _ = options; _ = psk_selection_block; _ = psk_selection_queue
}

public func sec_protocol_options_set_tls_diffie_hellman_parameters(
    _ options: sec_protocol_options_t, _ params: dispatch_data_t
) {
    _ = options; _ = params
}

public func sec_protocol_options_set_tls_false_start_enabled(
    _ options: sec_protocol_options_t, _ false_start_enabled: Bool
) {
    (options as? _OSSecProtocolOptions)?.falseStart = false_start_enabled
}

public func sec_protocol_options_set_tls_is_fallback_attempt(
    _ options: sec_protocol_options_t, _ is_fallback_attempt: Bool
) {
    (options as? _OSSecProtocolOptions)?.fallback = is_fallback_attempt
}

public func sec_protocol_options_set_tls_max_version(_ options: sec_protocol_options_t, _ version: SSLProtocol) {
    (options as? _OSSecProtocolOptions)?.maxSSL = version
}

public func sec_protocol_options_set_tls_min_version(_ options: sec_protocol_options_t, _ version: SSLProtocol) {
    (options as? _OSSecProtocolOptions)?.minSSL = version
}

public func sec_protocol_options_set_tls_ocsp_enabled(_ options: sec_protocol_options_t, _ ocsp_enabled: Bool) {
    (options as? _OSSecProtocolOptions)?.ocsp = ocsp_enabled
}

public func sec_protocol_options_set_tls_pre_shared_key_identity_hint(
    _ options: sec_protocol_options_t, _ psk_identity_hint: dispatch_data_t
) {
    _ = options; _ = psk_identity_hint
}

public func sec_protocol_options_set_tls_renegotiation_enabled(
    _ options: sec_protocol_options_t, _ renegotiation_enabled: Bool
) {
    (options as? _OSSecProtocolOptions)?.renegotiation = renegotiation_enabled
}

public func sec_protocol_options_set_tls_resumption_enabled(
    _ options: sec_protocol_options_t, _ resumption_enabled: Bool
) {
    (options as? _OSSecProtocolOptions)?.resumption = resumption_enabled
}

public func sec_protocol_options_set_tls_sct_enabled(_ options: sec_protocol_options_t, _ sct_enabled: Bool) {
    (options as? _OSSecProtocolOptions)?.sct = sct_enabled
}

public func sec_protocol_options_set_tls_server_name(
    _ options: sec_protocol_options_t, _ server_name: UnsafePointer<CChar>
) {
    (options as? _OSSecProtocolOptions)?.serverName = String(cString: server_name)
}

public func sec_protocol_options_set_tls_tickets_enabled(
    _ options: sec_protocol_options_t, _ tickets_enabled: Bool
) {
    (options as? _OSSecProtocolOptions)?.tickets = tickets_enabled
}

public func sec_protocol_options_set_verify_block(
    _ options: sec_protocol_options_t, _ verify_block: @escaping sec_protocol_verify_t,
    _ verify_block_queue: dispatch_queue_t
) {
    _ = options; _ = verify_block; _ = verify_block_queue
}

public func sec_release(_ obj: UnsafeMutableRawPointer!) { _ = obj }

public func sec_retain(_ obj: UnsafeMutableRawPointer!) -> UnsafeMutableRawPointer! { obj }

public func sec_trust_copy_ref(_ trust: sec_trust_t) -> Unmanaged<SecTrust> {
    (trust as? _OSSecTrust).map { Unmanaged.passUnretained($0.trust) }
        ?? Unmanaged.passUnretained(SecTrust(certificates: [], policies: []))
}

public func sec_trust_create(_ trust: SecTrust) -> sec_trust_t? {
    _OSSecTrust(trust: trust)
}
