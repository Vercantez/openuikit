import Foundation

public enum HPKE: Sendable {
    public enum DHKEM: Sendable {}

    public enum KEM: Hashable, CaseIterable, Sendable {
        case P256_HKDF_SHA256
        case P384_HKDF_SHA384
        case P521_HKDF_SHA512
        case Curve25519_HKDF_SHA256
        case XWingMLKEM768X25519
    }

    public enum KDF: Hashable, CaseIterable, Sendable {
        case HKDF_SHA256
        case HKDF_SHA384
        case HKDF_SHA512
        public nonisolated static var allCases: [HPKE.KDF] {
            [.HKDF_SHA256, .HKDF_SHA384, .HKDF_SHA512]
        }
    }

    public enum AEAD: Hashable, CaseIterable, Sendable {
        case AES_GCM_128
        case AES_GCM_256
        case chaChaPoly
        case exportOnly
        public nonisolated static var allCases: [HPKE.AEAD] {
            [.AES_GCM_128, .AES_GCM_256, .chaChaPoly, .exportOnly]
        }
    }

    public enum Errors: Error, Hashable, Sendable {
        case inconsistentCiphersuiteAndKey
        case inconsistentParameters
        case expectedPSK
        case unexpectedPSK
        case inconsistentPSKInputs
        case outOfRangeSequenceNumber
        case exportOnlyMode
        case ciphertextTooShort
    }

    public struct Ciphersuite: Sendable {
        public let kem: KEM
        public let kdf: KDF
        public let aead: AEAD

        public init(kem: KEM, kdf: KDF, aead: AEAD) {
            self.kem = kem
            self.kdf = kdf
            self.aead = aead
        }

        public static let P256_SHA256_AES_GCM_256 = Ciphersuite(
            kem: .P256_HKDF_SHA256, kdf: .HKDF_SHA256, aead: .AES_GCM_256
        )
        public static let P384_SHA384_AES_GCM_256 = Ciphersuite(
            kem: .P384_HKDF_SHA384, kdf: .HKDF_SHA384, aead: .AES_GCM_256
        )
        public static let P521_SHA512_AES_GCM_256 = Ciphersuite(
            kem: .P521_HKDF_SHA512, kdf: .HKDF_SHA512, aead: .AES_GCM_256
        )
        public static let Curve25519_SHA256_ChachaPoly = Ciphersuite(
            kem: .Curve25519_HKDF_SHA256, kdf: .HKDF_SHA256, aead: .chaChaPoly
        )
        public static let XWingMLKEM768X25519_SHA256_AES_GCM_256 = Ciphersuite(
            kem: .XWingMLKEM768X25519, kdf: .HKDF_SHA256, aead: .AES_GCM_256
        )
    }

    struct _Context {
        var key: [UInt8]
        var baseNonce: [UInt8]
        var seq: UInt64
        var exporterSecret: [UInt8]
        var aead: AEAD
        var kdf: KDF
        var suiteID: [UInt8]
        var hashByteCount: Int
    }

    public struct Sender: Sendable {
        public let encapsulatedKey: Data
        var context: _Context

        public init<PK: HPKEDiffieHellmanPublicKey>(
            recipientKey: PK,
            ciphersuite: Ciphersuite,
            info: Data
        ) throws {
            let setup = try _hpkeSetupBaseS(recipientKey: recipientKey, ciphersuite: ciphersuite, info: info)
            encapsulatedKey = setup.0
            context = setup.1
        }

        public init<PK: HPKEKEMPublicKey>(
            recipientKey: PK,
            ciphersuite: Ciphersuite,
            info: Data
        ) throws {
            _ = recipientKey
            _ = ciphersuite
            _ = info
            throw CryptoKitError.incorrectParameterSize
        }

        public init<PK: HPKEDiffieHellmanPublicKey>(
            recipientKey: PK,
            ciphersuite: Ciphersuite,
            info: Data,
            presharedKey psk: SymmetricKey,
            presharedKeyIdentifier pskID: Data
        ) throws {
            let setup = try _hpkeSetupPSKS(
                recipientKey: recipientKey,
                ciphersuite: ciphersuite,
                info: info,
                psk: psk,
                pskID: pskID
            )
            encapsulatedKey = setup.0
            context = setup.1
        }

        public init<SK: HPKEDiffieHellmanPrivateKey>(
            recipientKey: SK.PublicKey,
            ciphersuite: Ciphersuite,
            info: Data,
            authenticatedBy authenticationKey: SK
        ) throws {
            let setup = try _hpkeSetupAuthS(
                recipientKey: recipientKey,
                ciphersuite: ciphersuite,
                info: info,
                authenticationKey: authenticationKey
            )
            encapsulatedKey = setup.0
            context = setup.1
        }

        public init<SK: HPKEDiffieHellmanPrivateKey>(
            recipientKey: SK.PublicKey,
            ciphersuite: Ciphersuite,
            info: Data,
            authenticatedBy authenticationKey: SK,
            presharedKey psk: SymmetricKey,
            presharedKeyIdentifier pskID: Data
        ) throws {
            let setup = try _hpkeSetupAuthPSKS(
                recipientKey: recipientKey,
                ciphersuite: ciphersuite,
                info: info,
                authenticationKey: authenticationKey,
                psk: psk,
                pskID: pskID
            )
            encapsulatedKey = setup.0
            context = setup.1
        }

        public mutating func seal<M: DataProtocol>(_ msg: M) throws -> Data {
            try seal(msg, authenticating: Data())
        }

        public mutating func seal<M: DataProtocol, AD: DataProtocol>(
            _ msg: M,
            authenticating aad: AD
        ) throws -> Data {
            try _hpkeSeal(&context, plaintext: _ckBytes(msg), aad: _ckBytes(aad))
        }

        public func exportSecret<Context: DataProtocol>(
            context: Context,
            outputByteCount: Int
        ) throws -> SymmetricKey {
            try _hpkeExport(self.context, exporterContext: _ckBytes(context), length: outputByteCount)
        }
    }

    public struct Recipient: Sendable {
        var context: _Context

        public init<SK: HPKEDiffieHellmanPrivateKey>(
            privateKey: SK,
            ciphersuite: Ciphersuite,
            info: Data,
            encapsulatedKey: Data
        ) throws {
            context = try _hpkeSetupBaseR(
                privateKey: privateKey,
                ciphersuite: ciphersuite,
                info: info,
                encapsulatedKey: encapsulatedKey
            )
        }

        public init<SK: HPKEKEMPrivateKey>(
            privateKey: SK,
            ciphersuite: Ciphersuite,
            info: Data,
            encapsulatedKey: Data
        ) throws {
            _ = privateKey
            _ = ciphersuite
            _ = info
            _ = encapsulatedKey
            throw CryptoKitError.incorrectParameterSize
        }

        public init<SK: HPKEDiffieHellmanPrivateKey>(
            privateKey: SK,
            ciphersuite: Ciphersuite,
            info: Data,
            encapsulatedKey: Data,
            presharedKey psk: SymmetricKey,
            presharedKeyIdentifier pskID: Data
        ) throws {
            context = try _hpkeSetupPSKR(
                privateKey: privateKey,
                ciphersuite: ciphersuite,
                info: info,
                encapsulatedKey: encapsulatedKey,
                psk: psk,
                pskID: pskID
            )
        }

        public init<SK: HPKEDiffieHellmanPrivateKey>(
            privateKey: SK,
            ciphersuite: Ciphersuite,
            info: Data,
            encapsulatedKey: Data,
            authenticatedBy authenticationKey: SK.PublicKey
        ) throws {
            context = try _hpkeSetupAuthR(
                privateKey: privateKey,
                ciphersuite: ciphersuite,
                info: info,
                encapsulatedKey: encapsulatedKey,
                authenticationKey: authenticationKey
            )
        }

        public init<SK: HPKEDiffieHellmanPrivateKey>(
            privateKey: SK,
            ciphersuite: Ciphersuite,
            info: Data,
            encapsulatedKey: Data,
            authenticatedBy authenticationKey: SK.PublicKey,
            presharedKey psk: SymmetricKey,
            presharedKeyIdentifier pskID: Data
        ) throws {
            context = try _hpkeSetupAuthPSKR(
                privateKey: privateKey,
                ciphersuite: ciphersuite,
                info: info,
                encapsulatedKey: encapsulatedKey,
                authenticationKey: authenticationKey,
                psk: psk,
                pskID: pskID
            )
        }

        public mutating func open<C: DataProtocol>(_ ciphertext: C) throws -> Data {
            try open(ciphertext, authenticating: Data())
        }

        public mutating func open<C: DataProtocol, AD: DataProtocol>(
            _ ciphertext: C,
            authenticating aad: AD
        ) throws -> Data {
            try _hpkeOpen(&context, ciphertext: _ckBytes(ciphertext), aad: _ckBytes(aad))
        }

        public func exportSecret<Context: DataProtocol>(
            context: Context,
            outputByteCount: Int
        ) throws -> SymmetricKey {
            try _hpkeExport(self.context, exporterContext: _ckBytes(context), length: outputByteCount)
        }
    }
}

private func _hpkeI2OSP(_ value: Int, _ length: Int) -> [UInt8] {
    var bytes = [UInt8](repeating: 0, count: length)
    var remaining = value
    for index in stride(from: length - 1, through: 0, by: -1) {
        bytes[index] = UInt8(remaining & 0xff)
        remaining >>= 8
    }
    return bytes
}

private func _hpkeKEMID(_ kem: HPKE.KEM) throws -> UInt16 {
    switch kem {
    case .P256_HKDF_SHA256: return 0x0010
    case .P384_HKDF_SHA384: return 0x0011
    case .P521_HKDF_SHA512: return 0x0012
    case .Curve25519_HKDF_SHA256: return 0x0020
    case .XWingMLKEM768X25519: throw CryptoKitError.incorrectParameterSize
    }
}

private func _hpkeKDFID(_ kdf: HPKE.KDF) -> UInt16 {
    switch kdf {
    case .HKDF_SHA256: return 0x0001
    case .HKDF_SHA384: return 0x0002
    case .HKDF_SHA512: return 0x0003
    }
}

private func _hpkeAEADID(_ aead: HPKE.AEAD) -> UInt16 {
    switch aead {
    case .AES_GCM_128: return 0x0001
    case .AES_GCM_256: return 0x0002
    case .chaChaPoly: return 0x0003
    case .exportOnly: return 0xffff
    }
}

private func _hpkeNh(_ kdf: HPKE.KDF) -> Int {
    switch kdf {
    case .HKDF_SHA256: return 32
    case .HKDF_SHA384: return 48
    case .HKDF_SHA512: return 64
    }
}

private func _hpkeNkNn(_ aead: HPKE.AEAD) -> (Int, Int) {
    switch aead {
    case .AES_GCM_128: return (16, 12)
    case .AES_GCM_256: return (32, 12)
    case .chaChaPoly: return (32, 12)
    case .exportOnly: return (0, 0)
    }
}

private func _hpkeNsecret(_ kem: HPKE.KEM) throws -> Int {
    switch kem {
    case .P256_HKDF_SHA256, .Curve25519_HKDF_SHA256: return 32
    case .P384_HKDF_SHA384: return 48
    case .P521_HKDF_SHA512: return 64
    case .XWingMLKEM768X25519: throw CryptoKitError.incorrectParameterSize
    }
}

private func _hpkeSuiteID(_ ciphersuite: HPKE.Ciphersuite) throws -> [UInt8] {
    let kem = try _hpkeKEMID(ciphersuite.kem)
    return Array("HPKE".utf8) + _hpkeI2OSP(Int(kem), 2)
        + _hpkeI2OSP(Int(_hpkeKDFID(ciphersuite.kdf)), 2)
        + _hpkeI2OSP(Int(_hpkeAEADID(ciphersuite.aead)), 2)
}

private func _hpkeKEMSuiteID(_ kem: HPKE.KEM) throws -> [UInt8] {
    Array("KEM".utf8) + _hpkeI2OSP(Int(try _hpkeKEMID(kem)), 2)
}

private func _hpkeLabeledExtract(
    kdf: HPKE.KDF,
    suiteID: [UInt8],
    salt: [UInt8],
    label: String,
    ikm: [UInt8]
) -> [UInt8] {
    let labeled = Array("HPKE-v1".utf8) + suiteID + Array(label.utf8) + ikm
    switch kdf {
    case .HKDF_SHA256:
        return Array(HKDF<SHA256>.extract(inputKeyMaterial: SymmetricKey(rawBytes: labeled), salt: Data(salt)))
    case .HKDF_SHA384:
        return Array(HKDF<SHA384>.extract(inputKeyMaterial: SymmetricKey(rawBytes: labeled), salt: Data(salt)))
    case .HKDF_SHA512:
        return Array(HKDF<SHA512>.extract(inputKeyMaterial: SymmetricKey(rawBytes: labeled), salt: Data(salt)))
    }
}

private func _hpkeLabeledExpand(
    kdf: HPKE.KDF,
    suiteID: [UInt8],
    prk: [UInt8],
    label: String,
    info: [UInt8],
    length: Int
) -> [UInt8] {
    let labeled = _hpkeI2OSP(length, 2) + Array("HPKE-v1".utf8) + suiteID + Array(label.utf8) + info
    let key: SymmetricKey
    switch kdf {
    case .HKDF_SHA256:
        key = HKDF<SHA256>.expand(pseudoRandomKey: SymmetricKey(rawBytes: prk), info: Data(labeled), outputByteCount: length)
    case .HKDF_SHA384:
        key = HKDF<SHA384>.expand(pseudoRandomKey: SymmetricKey(rawBytes: prk), info: Data(labeled), outputByteCount: length)
    case .HKDF_SHA512:
        key = HKDF<SHA512>.expand(pseudoRandomKey: SymmetricKey(rawBytes: prk), info: Data(labeled), outputByteCount: length)
    }
    return Array(_ckData(key))
}

private func _hpkeExtractAndExpand(kem: HPKE.KEM, kdf: HPKE.KDF, dh: [UInt8], kemContext: [UInt8]) throws -> [UInt8] {
    let suiteID = try _hpkeKEMSuiteID(kem)
    let eae = _hpkeLabeledExtract(kdf: kdf, suiteID: suiteID, salt: [], label: "eae_prk", ikm: dh)
    return _hpkeLabeledExpand(
        kdf: kdf,
        suiteID: suiteID,
        prk: eae,
        label: "shared_secret",
        info: kemContext,
        length: try _hpkeNsecret(kem)
    )
}

private func _hpkeKeySchedule(
    ciphersuite: HPKE.Ciphersuite,
    mode: UInt8,
    sharedSecret: [UInt8],
    info: Data,
    psk: [UInt8],
    pskID: [UInt8]
) throws -> HPKE._Context {
    if ciphersuite.kem == .XWingMLKEM768X25519 {
        throw CryptoKitError.incorrectParameterSize
    }
    let suiteID = try _hpkeSuiteID(ciphersuite)
    let kdf = ciphersuite.kdf
    let pskIDHash = _hpkeLabeledExtract(kdf: kdf, suiteID: suiteID, salt: [], label: "psk_id_hash", ikm: pskID)
    let infoHash = _hpkeLabeledExtract(kdf: kdf, suiteID: suiteID, salt: [], label: "info_hash", ikm: Array(info))
    let keyScheduleContext = [mode] + pskIDHash + infoHash
    let secret = _hpkeLabeledExtract(kdf: kdf, suiteID: suiteID, salt: sharedSecret, label: "secret", ikm: psk)
    let (nk, nn) = _hpkeNkNn(ciphersuite.aead)
    let key = nk == 0 ? [] : _hpkeLabeledExpand(kdf: kdf, suiteID: suiteID, prk: secret, label: "key", info: keyScheduleContext, length: nk)
    let baseNonce = nn == 0 ? [] : _hpkeLabeledExpand(kdf: kdf, suiteID: suiteID, prk: secret, label: "base_nonce", info: keyScheduleContext, length: nn)
    let exporter = _hpkeLabeledExpand(kdf: kdf, suiteID: suiteID, prk: secret, label: "exp", info: keyScheduleContext, length: _hpkeNh(kdf))
    return HPKE._Context(
        key: key,
        baseNonce: baseNonce,
        seq: 0,
        exporterSecret: exporter,
        aead: ciphersuite.aead,
        kdf: kdf,
        suiteID: suiteID,
        hashByteCount: _hpkeNh(kdf)
    )
}

private func _hpkeDHKEMEncap<PK: HPKEDiffieHellmanPublicKey>(
    recipientKey: PK,
    ciphersuite: HPKE.Ciphersuite
) throws -> (secret: [UInt8], enc: Data) {
    let skE = PK.EphemeralPrivateKey()
    let dh = try skE.sharedSecretFromKeyAgreement(with: recipientKey)
    let enc = try skE.publicKey.hpkeRepresentation(kem: ciphersuite.kem)
    let pkRm = try recipientKey.hpkeRepresentation(kem: ciphersuite.kem)
    let secret = try _hpkeExtractAndExpand(
        kem: ciphersuite.kem,
        kdf: try _hpkeKEMKDF(ciphersuite.kem),
        dh: dh.bytes,
        kemContext: Array(enc) + Array(pkRm)
    )
    return (secret, enc)
}

private func _hpkeDHKEMDecap<SK: HPKEDiffieHellmanPrivateKey>(
    privateKey: SK,
    encapsulatedKey: Data,
    ciphersuite: HPKE.Ciphersuite
) throws -> [UInt8] {
    let pkE = try SK.PublicKey(encapsulatedKey, kem: ciphersuite.kem)
    let dh = try privateKey.sharedSecretFromKeyAgreement(with: pkE)
    let pkRm = try privateKey.publicKey.hpkeRepresentation(kem: ciphersuite.kem)
    return try _hpkeExtractAndExpand(
        kem: ciphersuite.kem,
        kdf: try _hpkeKEMKDF(ciphersuite.kem),
        dh: dh.bytes,
        kemContext: Array(encapsulatedKey) + Array(pkRm)
    )
}

private func _hpkeSetupBaseS<PK: HPKEDiffieHellmanPublicKey>(
    recipientKey: PK,
    ciphersuite: HPKE.Ciphersuite,
    info: Data
) throws -> (Data, HPKE._Context) {
    let (secret, enc) = try _hpkeDHKEMEncap(recipientKey: recipientKey, ciphersuite: ciphersuite)
    let context = try _hpkeKeySchedule(
        ciphersuite: ciphersuite, mode: 0, sharedSecret: secret, info: info, psk: [], pskID: []
    )
    return (enc, context)
}

private func _hpkeSetupBaseR<SK: HPKEDiffieHellmanPrivateKey>(
    privateKey: SK,
    ciphersuite: HPKE.Ciphersuite,
    info: Data,
    encapsulatedKey: Data
) throws -> HPKE._Context {
    let secret = try _hpkeDHKEMDecap(privateKey: privateKey, encapsulatedKey: encapsulatedKey, ciphersuite: ciphersuite)
    return try _hpkeKeySchedule(
        ciphersuite: ciphersuite, mode: 0, sharedSecret: secret, info: info, psk: [], pskID: []
    )
}

private func _hpkeSetupPSKS<PK: HPKEDiffieHellmanPublicKey>(
    recipientKey: PK,
    ciphersuite: HPKE.Ciphersuite,
    info: Data,
    psk: SymmetricKey,
    pskID: Data
) throws -> (Data, HPKE._Context) {
    let (secret, enc) = try _hpkeDHKEMEncap(recipientKey: recipientKey, ciphersuite: ciphersuite)
    let context = try _hpkeKeySchedule(
        ciphersuite: ciphersuite,
        mode: 1,
        sharedSecret: secret,
        info: info,
        psk: Array(_ckData(psk)),
        pskID: Array(pskID)
    )
    return (enc, context)
}

private func _hpkeSetupPSKR<SK: HPKEDiffieHellmanPrivateKey>(
    privateKey: SK,
    ciphersuite: HPKE.Ciphersuite,
    info: Data,
    encapsulatedKey: Data,
    psk: SymmetricKey,
    pskID: Data
) throws -> HPKE._Context {
    let secret = try _hpkeDHKEMDecap(privateKey: privateKey, encapsulatedKey: encapsulatedKey, ciphersuite: ciphersuite)
    return try _hpkeKeySchedule(
        ciphersuite: ciphersuite,
        mode: 1,
        sharedSecret: secret,
        info: info,
        psk: Array(_ckData(psk)),
        pskID: Array(pskID)
    )
}

private func _hpkeAuthDH<SK: HPKEDiffieHellmanPrivateKey>(
    skE: SK.PublicKey.EphemeralPrivateKey,
    skS: SK,
    pkR: SK.PublicKey,
    pkS: SK.PublicKey,
    ciphersuite: HPKE.Ciphersuite
) throws -> [UInt8] {
    let dh1 = try skE.sharedSecretFromKeyAgreement(with: pkR)
    let dh2 = try skS.sharedSecretFromKeyAgreement(with: pkR)
    let enc = try skE.publicKey.hpkeRepresentation(kem: ciphersuite.kem)
    let pkRm = try pkR.hpkeRepresentation(kem: ciphersuite.kem)
    let pkSm = try pkS.hpkeRepresentation(kem: ciphersuite.kem)
    return try _hpkeExtractAndExpand(
        kem: ciphersuite.kem,
        kdf: try _hpkeKEMKDF(ciphersuite.kem),
        dh: dh1.bytes + dh2.bytes,
        kemContext: Array(enc) + Array(pkRm) + Array(pkSm)
    )
}

private func _hpkeKEMKDF(_ kem: HPKE.KEM) throws -> HPKE.KDF {
    switch kem {
    case .P256_HKDF_SHA256, .Curve25519_HKDF_SHA256: return .HKDF_SHA256
    case .P384_HKDF_SHA384: return .HKDF_SHA384
    case .P521_HKDF_SHA512: return .HKDF_SHA512
    case .XWingMLKEM768X25519: throw CryptoKitError.incorrectParameterSize
    }
}

private func _hpkeSetupAuthS<SK: HPKEDiffieHellmanPrivateKey>(
    recipientKey: SK.PublicKey,
    ciphersuite: HPKE.Ciphersuite,
    info: Data,
    authenticationKey: SK
) throws -> (Data, HPKE._Context) {
    let skE = SK.PublicKey.EphemeralPrivateKey()
    let secret = try _hpkeAuthDH(
        skE: skE,
        skS: authenticationKey,
        pkR: recipientKey,
        pkS: authenticationKey.publicKey,
        ciphersuite: ciphersuite
    )
    let enc = try skE.publicKey.hpkeRepresentation(kem: ciphersuite.kem)
    let context = try _hpkeKeySchedule(
        ciphersuite: ciphersuite, mode: 2, sharedSecret: secret, info: info, psk: [], pskID: []
    )
    return (enc, context)
}

private func _hpkeSetupAuthR<SK: HPKEDiffieHellmanPrivateKey>(
    privateKey: SK,
    ciphersuite: HPKE.Ciphersuite,
    info: Data,
    encapsulatedKey: Data,
    authenticationKey: SK.PublicKey
) throws -> HPKE._Context {
    let pkE = try SK.PublicKey(encapsulatedKey, kem: ciphersuite.kem)
    let dh1 = try privateKey.sharedSecretFromKeyAgreement(with: pkE)
    let dh2 = try privateKey.sharedSecretFromKeyAgreement(with: authenticationKey)
    let pkRm = try privateKey.publicKey.hpkeRepresentation(kem: ciphersuite.kem)
    let pkSm = try authenticationKey.hpkeRepresentation(kem: ciphersuite.kem)
    let secret = try _hpkeExtractAndExpand(
        kem: ciphersuite.kem,
        kdf: try _hpkeKEMKDF(ciphersuite.kem),
        dh: dh1.bytes + dh2.bytes,
        kemContext: Array(encapsulatedKey) + Array(pkRm) + Array(pkSm)
    )
    return try _hpkeKeySchedule(
        ciphersuite: ciphersuite, mode: 2, sharedSecret: secret, info: info, psk: [], pskID: []
    )
}

private func _hpkeSetupAuthPSKS<SK: HPKEDiffieHellmanPrivateKey>(
    recipientKey: SK.PublicKey,
    ciphersuite: HPKE.Ciphersuite,
    info: Data,
    authenticationKey: SK,
    psk: SymmetricKey,
    pskID: Data
) throws -> (Data, HPKE._Context) {
    let skE = SK.PublicKey.EphemeralPrivateKey()
    let secret = try _hpkeAuthDH(
        skE: skE,
        skS: authenticationKey,
        pkR: recipientKey,
        pkS: authenticationKey.publicKey,
        ciphersuite: ciphersuite
    )
    let enc = try skE.publicKey.hpkeRepresentation(kem: ciphersuite.kem)
    let context = try _hpkeKeySchedule(
        ciphersuite: ciphersuite,
        mode: 3,
        sharedSecret: secret,
        info: info,
        psk: Array(_ckData(psk)),
        pskID: Array(pskID)
    )
    return (enc, context)
}

private func _hpkeSetupAuthPSKR<SK: HPKEDiffieHellmanPrivateKey>(
    privateKey: SK,
    ciphersuite: HPKE.Ciphersuite,
    info: Data,
    encapsulatedKey: Data,
    authenticationKey: SK.PublicKey,
    psk: SymmetricKey,
    pskID: Data
) throws -> HPKE._Context {
    let pkE = try SK.PublicKey(encapsulatedKey, kem: ciphersuite.kem)
    let dh1 = try privateKey.sharedSecretFromKeyAgreement(with: pkE)
    let dh2 = try privateKey.sharedSecretFromKeyAgreement(with: authenticationKey)
    let pkRm = try privateKey.publicKey.hpkeRepresentation(kem: ciphersuite.kem)
    let pkSm = try authenticationKey.hpkeRepresentation(kem: ciphersuite.kem)
    let secret = try _hpkeExtractAndExpand(
        kem: ciphersuite.kem,
        kdf: try _hpkeKEMKDF(ciphersuite.kem),
        dh: dh1.bytes + dh2.bytes,
        kemContext: Array(encapsulatedKey) + Array(pkRm) + Array(pkSm)
    )
    return try _hpkeKeySchedule(
        ciphersuite: ciphersuite,
        mode: 3,
        sharedSecret: secret,
        info: info,
        psk: Array(_ckData(psk)),
        pskID: Array(pskID)
    )
}

private func _hpkeNonce(_ context: HPKE._Context) throws -> [UInt8] {
    guard context.baseNonce.count == 12 else { throw HPKE.Errors.exportOnlyMode }
    var nonce = context.baseNonce
    var seq = context.seq
    for index in stride(from: 11, through: 4, by: -1) {
        nonce[index] ^= UInt8(seq & 0xff)
        seq >>= 8
    }
    return nonce
}

private func _hpkeSeal(_ context: inout HPKE._Context, plaintext: [UInt8], aad: [UInt8]) throws -> Data {
    if context.aead == .exportOnly { throw HPKE.Errors.exportOnlyMode }
    let nonce = try _hpkeNonce(context)
    let key = SymmetricKey(rawBytes: context.key)
    let combined: Data
    switch context.aead {
    case .AES_GCM_128, .AES_GCM_256:
        let box = try AES.GCM.seal(
            Data(plaintext),
            using: key,
            nonce: AES.GCM.Nonce(data: Data(nonce)),
            authenticating: Data(aad)
        )
        combined = box.ciphertext + box.tag
    case .chaChaPoly:
        let box = try ChaChaPoly.seal(
            Data(plaintext),
            using: key,
            nonce: ChaChaPoly.Nonce(data: Data(nonce)),
            authenticating: Data(aad)
        )
        combined = box.ciphertext + box.tag
    case .exportOnly:
        throw HPKE.Errors.exportOnlyMode
    }
    context.seq += 1
    return combined
}

private func _hpkeOpen(_ context: inout HPKE._Context, ciphertext: [UInt8], aad: [UInt8]) throws -> Data {
    if context.aead == .exportOnly { throw HPKE.Errors.exportOnlyMode }
    guard ciphertext.count >= 16 else { throw HPKE.Errors.ciphertextTooShort }
    let nonce = try _hpkeNonce(context)
    let key = SymmetricKey(rawBytes: context.key)
    let ct = Data(ciphertext.dropLast(16))
    let tag = Data(ciphertext.suffix(16))
    let opened: Data
    switch context.aead {
    case .AES_GCM_128, .AES_GCM_256:
        let box = try AES.GCM.SealedBox(nonce: AES.GCM.Nonce(data: Data(nonce)), ciphertext: ct, tag: tag)
        opened = try AES.GCM.open(box, using: key, authenticating: Data(aad))
    case .chaChaPoly:
        let box = try ChaChaPoly.SealedBox(nonce: ChaChaPoly.Nonce(data: Data(nonce)), ciphertext: ct, tag: tag)
        opened = try ChaChaPoly.open(box, using: key, authenticating: Data(aad))
    case .exportOnly:
        throw HPKE.Errors.exportOnlyMode
    }
    context.seq += 1
    return opened
}

private func _hpkeExport(_ context: HPKE._Context, exporterContext: [UInt8], length: Int) throws -> SymmetricKey {
    guard length > 0 else { throw CryptoKitError.incorrectParameterSize }
    let bytes = _hpkeLabeledExpand(
        kdf: context.kdf,
        suiteID: context.suiteID,
        prk: context.exporterSecret,
        label: "sec",
        info: exporterContext,
        length: length
    )
    return SymmetricKey(rawBytes: bytes)
}
