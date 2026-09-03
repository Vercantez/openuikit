import CryptoKit
import Foundation

private func ckHex<S: Sequence>(_ bytes: S) -> String where S.Element == UInt8 {
    bytes.map { String(format: "%02x", $0) }.joined()
}

private func ckData(_ hex: String) -> Data {
    precondition(hex.count.isMultiple(of: 2))
    var bytes = [UInt8]()
    bytes.reserveCapacity(hex.count / 2)
    var index = hex.startIndex
    while index < hex.endIndex {
        let next = hex.index(index, offsetBy: 2)
        let byte = UInt8(hex[index..<next], radix: 16)
        precondition(byte != nil)
        bytes.append(byte!)
        index = next
    }
    return Data(bytes)
}

private func ckExpectError<T>(_ body: () throws -> T) -> Error {
    do {
        _ = try body()
        preconditionFailure("expected a fail-closed error")
    } catch {
        return error
    }
}

func testSHA256Vectors() {
    let empty = Data()
    let abc = Data("abc".utf8)
    precondition(
        ckHex(SHA256.hash(data: empty))
            == "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
    )
    precondition(
        ckHex(SHA256.hash(data: abc))
            == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
    )
    precondition(SHA256.byteCount == 32)
    precondition(SHA256.blockByteCount == 64)
    precondition(SHA256Digest.byteCount == 32)
    var streaming = SHA256()
    streaming.update(data: Data("a".utf8))
    Data("bc".utf8).withUnsafeBytes { streaming.update(bufferPointer: $0) }
    let digest = streaming.finalize()
    precondition(digest == SHA256.hash(data: abc))
    precondition(digest.description == ckHex(digest))
    precondition(Array(digest).count == 32)
}

func testSHA384Vectors() {
    let empty = Data()
    let abc = Data("abc".utf8)
    precondition(
        ckHex(SHA384.hash(data: empty))
            == "38b060a751ac96384cd9327eb1b1e36a21fdb71114be07434c0cc7bf63f6e1da"
            + "274edebfe76f65fbd51ad2f14898b95b"
    )
    precondition(
        ckHex(SHA384.hash(data: abc))
            == "cb00753f45a35e8bb5a03d699ac65007272c32ab0eded1631a8b605a43ff5bed"
            + "8086072ba1e7cc2358baeca134c825a7"
    )
    precondition(SHA384.byteCount == 48)
    precondition(SHA384Digest.byteCount == 48)
}

func testSHA512Vectors() {
    let empty = Data()
    let abc = Data("abc".utf8)
    precondition(
        ckHex(SHA512.hash(data: empty))
            == "cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce"
            + "47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e"
    )
    precondition(
        ckHex(SHA512.hash(data: abc))
            == "ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a"
            + "2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f"
    )
    precondition(SHA512.byteCount == 64)
    precondition(SHA512Digest.byteCount == 64)
}

func testSHA3Vectors() {
    let empty = Data()
    let abc = Data("abc".utf8)
    precondition(
        ckHex(SHA3_256.hash(data: empty))
            == "a7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f8434a"
    )
    precondition(
        ckHex(SHA3_256.hash(data: abc))
            == "3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532"
    )
    precondition(
        ckHex(SHA3_384.hash(data: empty))
            == "0c63a75b845e4f7d01107d852e4c2485c51a50aaaa94fc61995e71bbee983a2a"
            + "c3713831264adb47fb6bd1e058d5f004"
    )
    precondition(
        ckHex(SHA3_384.hash(data: abc))
            == "ec01498288516fc926459f58e2c6ad8df9b473cb0fc08c2596da7cf0e49be4b2"
            + "98d88cea927ac7f539f1edf228376d25"
    )
    precondition(
        ckHex(SHA3_512.hash(data: empty))
            == "a69f73cca23a9ac5c8b567dc185a756e97c982164fe25859e0d1dcc1475c80a6"
            + "15b2123af1f5f94c11e3e9402c3ac558f500199d95b6d3e301758586281dcd26"
    )
    precondition(
        ckHex(SHA3_512.hash(data: abc))
            == "b751850b1a57168a5693cd924b6b096e08f621827444f70d884f5d0240d2712e"
            + "10e116e9192af3c91a7ec57647e3934057340b4cf408d5a56592f8274eec53f0"
    )
    precondition(SHA3_256Digest.byteCount == 32)
    precondition(SHA3_384Digest.byteCount == 48)
    precondition(SHA3_512Digest.byteCount == 64)
}

func testInsecureHashVectors() {
    let empty = Data()
    let abc = Data("abc".utf8)
    precondition(ckHex(Insecure.MD5.hash(data: empty)) == "d41d8cd98f00b204e9800998ecf8427e")
    precondition(ckHex(Insecure.MD5.hash(data: abc)) == "900150983cd24fb0d6963f7d28e17f72")
    precondition(ckHex(Insecure.SHA1.hash(data: empty)) == "da39a3ee5e6b4b0d3255bfef95601890afd80709")
    precondition(ckHex(Insecure.SHA1.hash(data: abc)) == "a9993e364706816aba3e25717850c26c9cd0d89d")
    precondition(Insecure.MD5Digest.byteCount == 16)
    precondition(Insecure.SHA1Digest.byteCount == 20)
    precondition(Insecure.MD5.byteCount == 16)
    precondition(Insecure.SHA1.byteCount == 20)
}

func testHMACSHA256RFC4231() {
    let key = SymmetricKey(data: ckData("0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b"))
    let mac = HMAC<SHA256>.authenticationCode(for: Data("Hi There".utf8), using: key)
    precondition(
        ckHex(mac)
            == "b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7"
    )
    precondition(mac.byteCount == 32)
    precondition(
        HMAC<SHA256>.isValidAuthenticationCode(
            mac,
            authenticating: Data("Hi There".utf8),
            using: key
        )
    )
    precondition(
        !HMAC<SHA256>.isValidAuthenticationCode(
            mac,
            authenticating: Data("Hi there".utf8),
            using: key
        )
    )
    Data("Hi There".utf8).withUnsafeBytes { pointer in
        precondition(
            HMAC<SHA256>.isValidAuthenticationCode(mac, authenticating: pointer, using: key)
        )
    }
    var streaming = HMAC<SHA256>(key: key)
    streaming.update(data: Data("Hi ".utf8))
    streaming.update(data: Data("There".utf8))
    precondition(streaming.finalize() == mac)
}

func testHKDFSHA256RFC5869() {
    let ikm = SymmetricKey(data: ckData("0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b"))
    let salt = ckData("000102030405060708090a0b0c")
    let info = ckData("f0f1f2f3f4f5f6f7f8f9")
    let okm = HKDF<SHA256>.deriveKey(
        inputKeyMaterial: ikm,
        salt: salt,
        info: info,
        outputByteCount: 42
    )
    precondition(okm.bitCount == 42 * 8)
    precondition(
        ckHex(okm.withUnsafeBytes { Data($0) })
            == "3cb25f25faacd57a90434f64d0362f2a2d2d0a90cf1a5a4c5db02d56ecc4c5bf"
            + "34007208d5b887185865"
    )
    let extracted = HKDF<SHA256>.extract(inputKeyMaterial: ikm, salt: Optional(salt))
    let expanded = HKDF<SHA256>.expand(
        pseudoRandomKey: extracted,
        info: Optional(info),
        outputByteCount: 42
    )
    precondition(expanded == okm)
    _ = HKDF<SHA256>.deriveKey(inputKeyMaterial: ikm, outputByteCount: 16)
    _ = HKDF<SHA256>.deriveKey(inputKeyMaterial: ikm, info: info, outputByteCount: 16)
    _ = HKDF<SHA256>.deriveKey(inputKeyMaterial: ikm, salt: salt, outputByteCount: 16)
}

func testSymmetricKeySizes() {
    precondition(SymmetricKeySize.bits128.bitCount == 128)
    precondition(SymmetricKeySize.bits192.bitCount == 192)
    precondition(SymmetricKeySize.bits256.bitCount == 256)
    let sized = SymmetricKey(size: .bits256)
    precondition(sized.bitCount == 256)
    let copied = SymmetricKey(data: sized)
    precondition(copied == sized)
    let other = SymmetricKey(size: .bits128)
    precondition(other.bitCount == 128)
    precondition(other != sized)
}

func testAESGCMNISTEmptyPlaintext() {
    let key = SymmetricKey(data: Data(count: 16))
    let nonce = try! AES.GCM.Nonce(data: Data(count: 12))
    let box = try! AES.GCM.seal(Data(), using: key, nonce: nonce)
    precondition(ckHex(box.tag) == "58e2fccefa7e3061367f1d57a4e7455a")
    precondition(box.ciphertext.isEmpty)
    let opened = try! AES.GCM.open(box, using: key)
    precondition(opened.isEmpty)
    let aad = Data("aad".utf8)
    let boxedAAD = try! AES.GCM.seal(Data("pt".utf8), using: key, nonce: nonce, authenticating: aad)
    let openedAAD = try! AES.GCM.open(boxedAAD, using: key, authenticating: aad)
    precondition(openedAAD == Data("pt".utf8))
    let reconstructed = try! AES.GCM.SealedBox(
        nonce: boxedAAD.nonce,
        ciphertext: boxedAAD.ciphertext,
        tag: boxedAAD.tag
    )
    precondition(try! AES.GCM.open(reconstructed, using: key, authenticating: aad) == Data("pt".utf8))
    let combined = try! AES.GCM.SealedBox(combined: boxedAAD.combined!)
    precondition(combined.nonce.withUnsafeBytes { Data($0) } == nonce.withUnsafeBytes { Data($0) })
}

func testChaChaPolyRFC8439() {
    let key = SymmetricKey(
        data: ckData(
            "808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9f"
        )
    )
    let nonce = try! ChaChaPoly.Nonce(data: ckData("070000004041424344454647"))
    let aad = ckData("50515253c0c1c2c3c4c5c6c7")
    let plaintext = ckData(
        "4c616469657320616e642047656e746c656d656e206f662074686520636c6173"
            + "73206f66202739393a204966204920636f756c64206f6666657220796f75206f"
            + "6e6c79206f6e652074697020666f7220746865206675747572652c2073756e73"
            + "637265656e20776f756c642062652069742e"
    )
    let box = try! ChaChaPoly.seal(plaintext, using: key, nonce: nonce, authenticating: aad)
    precondition(
        ckHex(box.ciphertext)
            == "d31a8d34648e60db7b86afbc53ef7ec2a4aded51296e08fea9e2b5a736ee62d6"
            + "3dbea45e8ca9671282fafb69da92728b1a71de0a9e060b2905d6a5b67ecd3b36"
            + "92ddbd7f2d778b8c9803aee328091b58fab324e4fad675945585808b4831d7bc"
            + "3ff4def08e4b7a9de576d26586cec64b6116"
    )
    precondition(ckHex(box.tag) == "1ae10b594f09e26a7e902ecbd0600691")
    precondition(try! ChaChaPoly.open(box, using: key, authenticating: aad) == plaintext)
    let noAAD = try! ChaChaPoly.seal(plaintext, using: key, nonce: nonce)
    precondition(try! ChaChaPoly.open(noAAD, using: key) == plaintext)
    let randomNonce = ChaChaPoly.Nonce()
    precondition(Array(randomNonce).count == 12)
    precondition(randomNonce.count == 12)
    let rebuilt = try! ChaChaPoly.SealedBox(combined: box.combined)
    precondition(try! ChaChaPoly.open(rebuilt, using: key, authenticating: aad) == plaintext)
}

func testAESKeyWrapRoundTripShape() {
    let kek = SymmetricKey(size: .bits128)
    let key = SymmetricKey(size: .bits128)
    let wrapped = try! AES.KeyWrap.wrap(key, using: kek)
    precondition(wrapped.count == 24)
    let error = ckExpectError { try AES.KeyWrap.unwrap(wrapped, using: kek) }
    guard case CryptoKitError.unwrapFailure = error else {
        preconditionFailure("unwrap must fail closed until AES decrypt exists")
    }
}

func testCryptoKitErrorSurface() {
    let cases: [CryptoKitError] = [
        .incorrectKeySize,
        .incorrectParameterSize,
        .authenticationFailure,
        .underlyingCoreCryptoError(error: -1),
        .wrapFailure,
        .unwrapFailure,
        .invalidParameter,
    ]
    for item in cases {
        precondition(item == item)
        precondition(item != .incorrectKeySize || item == .incorrectKeySize)
        var hasher = Hasher()
        item.hash(into: &hasher)
        _ = item.hashValue
    }
    precondition(CryptoKitError.incorrectKeySize != .unwrapFailure)
    let asn1: [CryptoKitASN1Error] = [
        .invalidFieldIdentifier,
        .unexpectedFieldType,
        .invalidObjectIdentifier,
        .invalidASN1Object,
        .invalidASN1IntegerEncoding,
        .invalidPEMDocument,
        .truncatedASN1Field,
        .unsupportedFieldLength,
    ]
    for item in asn1 {
        precondition(item == item)
        var hasher = Hasher()
        item.hash(into: &hasher)
        _ = item.hashValue
    }
    let _: CryptoKitMetaError = CryptoKitError.invalidParameter
}

func testCurve25519FailClosed() {
    let tooShort = ckExpectError {
        try Curve25519.Signing.PublicKey(rawRepresentation: Data(count: 31))
    }
    guard case CryptoKitError.incorrectKeySize = tooShort else {
        preconditionFailure("short Ed25519 public key must throw incorrectKeySize")
    }
    let publicKey = try! Curve25519.Signing.PublicKey(rawRepresentation: Data(count: 32))
    precondition(publicKey.rawRepresentation.count == 32)
    precondition(!publicKey.isValidSignature(Data(count: 64), for: Data("abc".utf8)))
    let privateKey = try! Curve25519.Signing.PrivateKey(rawRepresentation: Data(count: 32))
    let signError = ckExpectError { try privateKey.signature(for: Data("abc".utf8)) }
    guard case CryptoKitError.underlyingCoreCryptoError = signError else {
        preconditionFailure("Ed25519 signing must fail closed")
    }
    let generated = Curve25519.Signing.PrivateKey()
    precondition(generated.rawRepresentation.count == 32)
    let kaPrivate = Curve25519.KeyAgreement.PrivateKey()
    let kaPublic = try! Curve25519.KeyAgreement.PublicKey(rawRepresentation: Data(count: 32))
    let kaError = ckExpectError {
        try kaPrivate.sharedSecretFromKeyAgreement(with: kaPublic)
    }
    guard case CryptoKitError.underlyingCoreCryptoError = kaError else {
        preconditionFailure("X25519 key agreement must fail closed")
    }
    _ = try! kaPublic.hpkeRepresentation(kem: .Curve25519_HKDF_SHA256)
}

func testNISTCurvesFailClosed() {
    let p256 = try! P256.Signing.PublicKey(rawRepresentation: Data(count: 64))
    precondition(p256.rawRepresentation.count == 64)
    precondition(p256.pemRepresentation.isEmpty)
    precondition(p256.compactRepresentation == nil)
    let pemError = ckExpectError { try P256.Signing.PublicKey(pemRepresentation: "not-pem") }
    guard case CryptoKitASN1Error.invalidPEMDocument = pemError else {
        preconditionFailure("PEM init must throw invalidPEMDocument")
    }
    let signature = try! P256.Signing.ECDSASignature(rawRepresentation: Data(count: 64))
    precondition(!p256.isValidSignature(signature, for: Data("abc".utf8)))
    let privateKey = P256.Signing.PrivateKey()
    let signError = ckExpectError { try privateKey.signature(for: Data("abc".utf8)) }
    guard case CryptoKitError.underlyingCoreCryptoError = signError else {
        preconditionFailure("P256 signing must fail closed")
    }
    let p384 = try! P384.KeyAgreement.PublicKey(rawRepresentation: Data(count: 96))
    precondition(p384.rawRepresentation.count == 96)
    let p521 = try! P521.Signing.PublicKey(rawRepresentation: Data(count: 132))
    precondition(p521.rawRepresentation.count == 132)
}

func testHPKEFailClosed() {
    precondition(HPKE.KEM.allCases.contains(.P256_HKDF_SHA256))
    precondition(HPKE.KDF.allCases.contains(.HKDF_SHA256))
    precondition(HPKE.AEAD.allCases.contains(.chaChaPoly))
    let suite = HPKE.Ciphersuite.Curve25519_SHA256_ChachaPoly
    precondition(suite.kem == .Curve25519_HKDF_SHA256)
    precondition(suite.kdf == .HKDF_SHA256)
    precondition(suite.aead == .chaChaPoly)
    _ = HPKE.Ciphersuite.P256_SHA256_AES_GCM_256
    _ = HPKE.Ciphersuite.P384_SHA384_AES_GCM_256
    _ = HPKE.Ciphersuite.P521_SHA512_AES_GCM_256
    _ = HPKE.Ciphersuite.XWingMLKEM768X25519_SHA256_AES_GCM_256
    let recipient = try! Curve25519.KeyAgreement.PublicKey(rawRepresentation: Data(count: 32))
    let senderError = ckExpectError {
        try HPKE.Sender(recipientKey: recipient, ciphersuite: suite, info: Data())
    }
    guard case CryptoKitError.incorrectParameterSize = senderError else {
        preconditionFailure("HPKE sender must fail closed without a native KEM")
    }
    let hpkeErrors: [HPKE.Errors] = [
        .inconsistentCiphersuiteAndKey,
        .inconsistentParameters,
        .expectedPSK,
        .unexpectedPSK,
        .inconsistentPSKInputs,
        .outOfRangeSequenceNumber,
        .exportOnlyMode,
        .ciphertextTooShort,
    ]
    for item in hpkeErrors {
        precondition(item == item)
    }
}

func testPostQuantumFailClosed() {
    let generateError = ckExpectError { try MLKEM768.PrivateKey.generate() }
    guard case CryptoKitError.underlyingCoreCryptoError = generateError else {
        preconditionFailure("ML-KEM generate must fail closed")
    }
    let seed = Data(count: 64)
    let privateKey = try! MLKEM768.PrivateKey(seedRepresentation: seed, publicKey: nil)
    let decapError = ckExpectError { try privateKey.decapsulate(Data()) }
    guard case CryptoKitError.underlyingCoreCryptoError = decapError else {
        preconditionFailure("ML-KEM decapsulate must fail closed")
    }
    let mismatch = ckExpectError {
        try MLKEM768.PrivateKey(
            seedRepresentation: seed,
            publicKey: MLKEM768.PublicKey(rawRepresentation: Data())
        )
    }
    guard case KEM.Errors.publicKeyMismatchDuringInitialization = mismatch else {
        preconditionFailure("supplied public key must be rejected")
    }
    let xwingError = ckExpectError { try XWingMLKEM768X25519.PrivateKey() }
    guard case CryptoKitError.underlyingCoreCryptoError = xwingError else {
        preconditionFailure("X-Wing generate must fail closed")
    }
    let mldsa = try! MLDSA65.PublicKey(rawRepresentation: Data())
    precondition(!mldsa.isValidSignature(Data(), for: Data("abc".utf8)))
    _ = KEM.EncapsulationResult(sharedSecret: SymmetricKey(size: .bits256), encapsulated: Data())
    _ = KEM.Errors.invalidSeed
}

func testSecureEnclaveUnavailable() {
    precondition(SecureEnclave.isAvailable == false)
}

func testDigestSequenceAndEquality() {
    let digest = SHA256.hash(data: Data("abc".utf8))
    var collected = [UInt8]()
    for byte in digest {
        collected.append(byte)
    }
    precondition(collected.count == 32)
    precondition(digest == digest)
    precondition(digest == Data(collected))
    let mac = HMAC<SHA256>.authenticationCode(
        for: Data("abc".utf8),
        using: SymmetricKey(size: .bits256)
    )
    precondition(Array(mac).count == 32)
    let nonce = try! AES.GCM.Nonce(data: Data(count: 12))
    precondition(Array(nonce).count == 12)
}
