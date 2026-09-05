import Foundation

public struct CorecryptoCurveType: Sendable {
    public init() {}
}

public enum Curve25519: Sendable {
    public enum Signing: Sendable {
        public struct PublicKey: Sendable {
            public let rawRepresentation: Data

            public init<D: ContiguousBytes>(rawRepresentation: D) throws {
                let value = _ckData(rawRepresentation)
                guard value.count == 32 else { throw CryptoKitError.incorrectKeySize }
                self.rawRepresentation = value
            }

            public func isValidSignature<S: DataProtocol, D: DataProtocol>(
                _ signature: S,
                for data: D
            ) -> Bool {
                _ed25519Verify(
                    Array(rawRepresentation),
                    _ckBytes(signature),
                    _ckBytes(data)
                )
            }
        }

        public struct PrivateKey: Sendable {
            public let rawRepresentation: Data
            public var publicKey: PublicKey {
                try! PublicKey(rawRepresentation: Data(_ed25519PublicKey(Array(rawRepresentation))))
            }

            public init() {
                self.rawRepresentation = Data(_ckRandomBytes(32))
            }

            public init<D: ContiguousBytes>(rawRepresentation data: D) throws {
                let value = _ckData(data)
                guard value.count == 32 else { throw CryptoKitError.incorrectKeySize }
                self.rawRepresentation = value
            }

            public func signature<D: DataProtocol>(for data: D) throws -> Data {
                Data(_ed25519Sign(Array(rawRepresentation), _ckBytes(data)))
            }
        }
    }

    public enum KeyAgreement: Sendable {
        public struct PublicKey: HPKEDiffieHellmanPublicKey {
            public typealias EphemeralPrivateKey = PrivateKey
            public typealias HPKEEphemeralPrivateKey = PrivateKey
            public let rawRepresentation: Data

            public init<D: ContiguousBytes>(rawRepresentation: D) throws {
                let value = _ckData(rawRepresentation)
                guard value.count == 32 else { throw CryptoKitError.incorrectKeySize }
                self.rawRepresentation = value
            }

            public init<D: ContiguousBytes>(_ serialization: D, kem: HPKE.KEM) throws {
                guard kem == .Curve25519_HKDF_SHA256 else {
                    throw CryptoKitError.incorrectParameterSize
                }
                try self.init(rawRepresentation: serialization)
            }

            public func hpkeRepresentation(kem: HPKE.KEM) throws -> Data {
                guard kem == .Curve25519_HKDF_SHA256 else {
                    throw CryptoKitError.incorrectParameterSize
                }
                return rawRepresentation
            }
        }

        public struct PrivateKey: HPKEDiffieHellmanPrivateKeyGeneration {
            public typealias PublicKey = Curve25519.KeyAgreement.PublicKey
            public let rawRepresentation: Data
            public var publicKey: PublicKey {
                try! PublicKey(rawRepresentation: Data(_x25519PublicKey(Array(rawRepresentation))))
            }

            public init() {
                self.rawRepresentation = Data(_ckRandomBytes(32))
            }

            public init<D: ContiguousBytes>(rawRepresentation: D) throws {
                let value = _ckData(rawRepresentation)
                guard value.count == 32 else { throw CryptoKitError.incorrectKeySize }
                self.rawRepresentation = value
            }

            public func sharedSecretFromKeyAgreement(
                with publicKeyShare: PublicKey
            ) throws -> SharedSecret {
                let secret = _x25519(
                    Array(rawRepresentation),
                    Array(publicKeyShare.rawRepresentation)
                )
                if secret.allSatisfy({ $0 == 0 }) {
                    throw CryptoKitError.invalidParameter
                }
                return SharedSecret(bytes: secret)
            }
        }
    }
}

struct _CKNISTPublic {
    let curve: _NISTCurve
    let point: _NISTPoint

    var rawRepresentation: Data { _ckRawPublic(point, curve) }
    var x963Representation: Data { _ckX963Public(point, curve) }
    var compressedRepresentation: Data { _ckCompressedPublic(point, curve) }
    var compactRepresentation: Data? { _ckCompactPublic(point, curve) }
    var derRepresentation: Data { _ckSPKI(point, curve) }
    var pemRepresentation: String { _ckPEM(derRepresentation, label: "PUBLIC KEY") }

    init(curve: _NISTCurve, point: _NISTPoint) throws {
        guard _nistOnCurve(point, curve) else { throw CryptoKitError.incorrectParameterSize }
        self.curve = curve
        self.point = point
    }

    init<D: ContiguousBytes>(rawRepresentation: D, curve: _NISTCurve) throws {
        try self.init(curve: curve, point: try _ckParseRawPublic(_ckData(rawRepresentation), curve))
    }

    init<Bytes: ContiguousBytes>(x963Representation: Bytes, curve: _NISTCurve) throws {
        try self.init(curve: curve, point: try _ckParseX963Public(_ckData(x963Representation), curve))
    }

    init<Bytes: RandomAccessCollection>(derRepresentation: Bytes, curve: _NISTCurve) throws
    where Bytes.Element == UInt8 {
        try self.init(curve: curve, point: try _ckParseSPKI(Data(derRepresentation), curve))
    }

    init(pemRepresentation: String, curve: _NISTCurve) throws {
        let der = try _ckParsePEM(pemRepresentation, expectedLabel: "PUBLIC KEY")
        try self.init(curve: curve, point: try _ckParseSPKI(der, curve))
    }

    init<Bytes: ContiguousBytes>(compactRepresentation: Bytes, curve: _NISTCurve) throws {
        try self.init(curve: curve, point: try _ckParseCompactPublic(_ckData(compactRepresentation), curve))
    }

    init<Bytes: ContiguousBytes>(compressedRepresentation: Bytes, curve: _NISTCurve) throws {
        try self.init(curve: curve, point: try _ckParseCompressedPublic(_ckData(compressedRepresentation), curve))
    }
}

struct _CKNISTPrivate {
    let curve: _NISTCurve
    let scalar: _CKNat

    var publicPoint: _NISTPoint { _nistPublicPoint(scalar, curve) }
    var rawRepresentation: Data { _ckCoordBytes(scalar, length: curve.coordinateByteCount) }
    var x963Representation: Data { _ckX963Private(scalar, publicPoint, curve) }
    var derRepresentation: Data { _ckPKCS8(scalar, publicPoint, curve) }
    var pemRepresentation: String { _ckPEM(derRepresentation, label: "PRIVATE KEY") }

    init(curve: _NISTCurve, scalar: _CKNat) throws {
        guard _nistIsValidScalar(scalar, curve) else { throw CryptoKitError.incorrectParameterSize }
        self.curve = curve
        self.scalar = scalar
    }

    init(curve: _NISTCurve, compactRepresentable: Bool) {
        self.curve = curve
        while true {
            let candidate = _nistRandomScalar(curve)
            let point = _nistPublicPoint(candidate, curve)
            if !compactRepresentable || _ckCompactPublic(point, curve) != nil {
                self.scalar = candidate
                return
            }
        }
    }

    init<Bytes: ContiguousBytes>(rawRepresentation: Bytes, curve: _NISTCurve) throws {
        try self.init(curve: curve, scalar: try _ckParsePrivateScalar(_ckData(rawRepresentation), curve))
    }

    init<Bytes: ContiguousBytes>(x963Representation: Bytes, curve: _NISTCurve) throws {
        let parsed = try _ckParseX963Private(_ckData(x963Representation), curve)
        try self.init(curve: curve, scalar: parsed.0)
    }

    init<Bytes: RandomAccessCollection>(derRepresentation: Bytes, curve: _NISTCurve) throws
    where Bytes.Element == UInt8 {
        try self.init(curve: curve, scalar: try _ckParsePKCS8(Data(derRepresentation), curve))
    }

    init(pemRepresentation: String, curve: _NISTCurve) throws {
        let der = try _ckParsePEM(pemRepresentation, expectedLabel: "PRIVATE KEY")
        try self.init(curve: curve, scalar: try _ckParsePKCS8(der, curve))
    }
}

private func _ckECDSASignature(raw: Data, curve: _NISTCurve) throws -> (r: _CKNat, s: _CKNat) {
    try _ckParseRawSignature(raw, coordinateByteCount: curve.coordinateByteCount)
}

public enum P256: Sendable {
    public enum Signing: Sendable {
        public struct ECDSASignature: ContiguousBytes, Sendable {
            public var rawRepresentation: Data
            public var derRepresentation: Data {
                let pair = try! _ckParseRawSignature(rawRepresentation, coordinateByteCount: 32)
                return _ckDERSignature(r: pair.r, s: pair.s)
            }

            public init<D: DataProtocol>(rawRepresentation: D) throws {
                let value = Data(_ckBytes(rawRepresentation))
                _ = try _ckParseRawSignature(value, coordinateByteCount: 32)
                self.rawRepresentation = value
            }

            public init<D: DataProtocol>(derRepresentation: D) throws {
                let pair = try _ckParseDERSignature(Data(_ckBytes(derRepresentation)), coordinateByteCount: 32)
                self.rawRepresentation = _ckRawSignature(r: pair.r, s: pair.s, coordinateByteCount: 32)
            }

            public func withUnsafeBytes<R>(
                _ body: (UnsafeRawBufferPointer) throws -> R
            ) rethrows -> R {
                try rawRepresentation.withUnsafeBytes(body)
            }
        }

        public struct PublicKey: Sendable {
            fileprivate let storage: _CKNISTPublic
            public var rawRepresentation: Data { storage.rawRepresentation }
            public var x963Representation: Data { storage.x963Representation }
            public var derRepresentation: Data { storage.derRepresentation }
            public var pemRepresentation: String { storage.pemRepresentation }
            public var compactRepresentation: Data? { storage.compactRepresentation }
            public var compressedRepresentation: Data { storage.compressedRepresentation }

            public init<D: ContiguousBytes>(rawRepresentation: D) throws {
                storage = try _CKNISTPublic(rawRepresentation: rawRepresentation, curve: .p256)
            }

            public init<Bytes: ContiguousBytes>(x963Representation: Bytes) throws {
                storage = try _CKNISTPublic(x963Representation: x963Representation, curve: .p256)
            }

            public init<Bytes: RandomAccessCollection>(derRepresentation: Bytes) throws
            where Bytes.Element == UInt8 {
                storage = try _CKNISTPublic(derRepresentation: derRepresentation, curve: .p256)
            }

            public init(pemRepresentation: String) throws {
                storage = try _CKNISTPublic(pemRepresentation: pemRepresentation, curve: .p256)
            }

            public init<Bytes: ContiguousBytes>(compactRepresentation: Bytes) throws {
                storage = try _CKNISTPublic(compactRepresentation: compactRepresentation, curve: .p256)
            }

            public init<Bytes: ContiguousBytes>(compressedRepresentation: Bytes) throws {
                storage = try _CKNISTPublic(compressedRepresentation: compressedRepresentation, curve: .p256)
            }

            init(storage: _CKNISTPublic) { self.storage = storage }

            public func isValidSignature<D: DataProtocol>(
                _ signature: ECDSASignature,
                for data: D
            ) -> Bool {
                isValidSignature(signature, digestBytes: Array(SHA256.hash(data: Data(_ckBytes(data)))))
            }

            public func isValidSignature<D: Digest>(
                _ signature: ECDSASignature,
                for digest: D
            ) -> Bool {
                isValidSignature(signature, digestBytes: Array(digest))
            }

            private func isValidSignature(_ signature: ECDSASignature, digestBytes: [UInt8]) -> Bool {
                guard let pair = try? _ckECDSASignature(raw: signature.rawRepresentation, curve: .p256) else {
                    return false
                }
                return _ecdsaVerify(
                    .p256,
                    publicPoint: storage.point,
                    digest: digestBytes,
                    r: pair.r,
                    s: pair.s
                )
            }
        }

        public struct PrivateKey: Sendable {
            fileprivate let storage: _CKNISTPrivate
            public var rawRepresentation: Data { storage.rawRepresentation }
            public var x963Representation: Data { storage.x963Representation }
            public var derRepresentation: Data { storage.derRepresentation }
            public var pemRepresentation: String { storage.pemRepresentation }
            public var publicKey: PublicKey {
                PublicKey(storage: try! _CKNISTPublic(curve: .p256, point: storage.publicPoint))
            }

            public init(compactRepresentable: Bool = true) {
                storage = _CKNISTPrivate(curve: .p256, compactRepresentable: compactRepresentable)
            }

            public init<Bytes: ContiguousBytes>(rawRepresentation: Bytes) throws {
                storage = try _CKNISTPrivate(rawRepresentation: rawRepresentation, curve: .p256)
            }

            public init<Bytes: ContiguousBytes>(x963Representation: Bytes) throws {
                storage = try _CKNISTPrivate(x963Representation: x963Representation, curve: .p256)
            }

            public init<Bytes: RandomAccessCollection>(derRepresentation: Bytes) throws
            where Bytes.Element == UInt8 {
                storage = try _CKNISTPrivate(derRepresentation: derRepresentation, curve: .p256)
            }

            public init(pemRepresentation: String) throws {
                storage = try _CKNISTPrivate(pemRepresentation: pemRepresentation, curve: .p256)
            }

            public func signature<D: DataProtocol>(for data: D) throws -> ECDSASignature {
                try signature(digestBytes: Array(SHA256.hash(data: Data(_ckBytes(data)))))
            }

            public func signature<D: Digest>(for digest: D) throws -> ECDSASignature {
                try signature(digestBytes: Array(digest))
            }

            private func signature(digestBytes: [UInt8]) throws -> ECDSASignature {
                let pair = _ecdsaSign(.p256, scalar: storage.scalar, digest: digestBytes)
                return try ECDSASignature(
                    rawRepresentation: _ckRawSignature(r: pair.r, s: pair.s, coordinateByteCount: 32)
                )
            }
        }
    }

    public enum KeyAgreement: Sendable {
        public struct PublicKey: HPKEDiffieHellmanPublicKey {
            public typealias EphemeralPrivateKey = PrivateKey
            public typealias HPKEEphemeralPrivateKey = PrivateKey
            fileprivate let storage: _CKNISTPublic
            public var rawRepresentation: Data { storage.rawRepresentation }
            public var x963Representation: Data { storage.x963Representation }
            public var derRepresentation: Data { storage.derRepresentation }
            public var pemRepresentation: String { storage.pemRepresentation }
            public var compactRepresentation: Data? { storage.compactRepresentation }
            public var compressedRepresentation: Data { storage.compressedRepresentation }

            public init<D: ContiguousBytes>(rawRepresentation: D) throws {
                storage = try _CKNISTPublic(rawRepresentation: rawRepresentation, curve: .p256)
            }

            public init<D: ContiguousBytes>(_ serialization: D, kem: HPKE.KEM) throws {
                guard kem == .P256_HKDF_SHA256 else { throw CryptoKitError.incorrectParameterSize }
                let data = _ckData(serialization)
                if data.count == 65 {
                    storage = try _CKNISTPublic(x963Representation: data, curve: .p256)
                } else {
                    storage = try _CKNISTPublic(rawRepresentation: data, curve: .p256)
                }
            }

            public func hpkeRepresentation(kem: HPKE.KEM) throws -> Data {
                guard kem == .P256_HKDF_SHA256 else { throw CryptoKitError.incorrectParameterSize }
                return x963Representation
            }

            public init<Bytes: ContiguousBytes>(x963Representation: Bytes) throws {
                storage = try _CKNISTPublic(x963Representation: x963Representation, curve: .p256)
            }

            public init<Bytes: RandomAccessCollection>(derRepresentation: Bytes) throws
            where Bytes.Element == UInt8 {
                storage = try _CKNISTPublic(derRepresentation: derRepresentation, curve: .p256)
            }

            public init(pemRepresentation: String) throws {
                storage = try _CKNISTPublic(pemRepresentation: pemRepresentation, curve: .p256)
            }

            public init<Bytes: ContiguousBytes>(compactRepresentation: Bytes) throws {
                storage = try _CKNISTPublic(compactRepresentation: compactRepresentation, curve: .p256)
            }

            public init<Bytes: ContiguousBytes>(compressedRepresentation: Bytes) throws {
                storage = try _CKNISTPublic(compressedRepresentation: compressedRepresentation, curve: .p256)
            }

            init(storage: _CKNISTPublic) { self.storage = storage }
        }

        public struct PrivateKey: HPKEDiffieHellmanPrivateKeyGeneration {
            public typealias PublicKey = P256.KeyAgreement.PublicKey
            fileprivate let storage: _CKNISTPrivate
            public var rawRepresentation: Data { storage.rawRepresentation }
            public var x963Representation: Data { storage.x963Representation }
            public var derRepresentation: Data { storage.derRepresentation }
            public var pemRepresentation: String { storage.pemRepresentation }
            public var publicKey: PublicKey {
                PublicKey(storage: try! _CKNISTPublic(curve: .p256, point: storage.publicPoint))
            }

            public init() {
                storage = _CKNISTPrivate(curve: .p256, compactRepresentable: true)
            }

            public init(compactRepresentable: Bool = true) {
                storage = _CKNISTPrivate(curve: .p256, compactRepresentable: compactRepresentable)
            }

            public init<Bytes: ContiguousBytes>(rawRepresentation: Bytes) throws {
                storage = try _CKNISTPrivate(rawRepresentation: rawRepresentation, curve: .p256)
            }

            public init<Bytes: ContiguousBytes>(x963Representation: Bytes) throws {
                storage = try _CKNISTPrivate(x963Representation: x963Representation, curve: .p256)
            }

            public init<Bytes: RandomAccessCollection>(derRepresentation: Bytes) throws
            where Bytes.Element == UInt8 {
                storage = try _CKNISTPrivate(derRepresentation: derRepresentation, curve: .p256)
            }

            public init(pemRepresentation: String) throws {
                storage = try _CKNISTPrivate(pemRepresentation: pemRepresentation, curve: .p256)
            }

            public func sharedSecretFromKeyAgreement(
                with publicKeyShare: PublicKey
            ) throws -> SharedSecret {
                let point = _nistScale(publicKeyShare.storage.point, storage.scalar, .p256)
                guard !point.infinity else { throw CryptoKitError.invalidParameter }
                return SharedSecret(bytes: Array(_ckCoordBytes(point.x, length: 32)))
            }
        }
    }
}

public enum P384: Sendable {
    public enum Signing: Sendable {
        public struct ECDSASignature: ContiguousBytes, Sendable {
            public var rawRepresentation: Data
            public var derRepresentation: Data {
                let pair = try! _ckParseRawSignature(rawRepresentation, coordinateByteCount: 48)
                return _ckDERSignature(r: pair.r, s: pair.s)
            }

            public init<D: DataProtocol>(rawRepresentation: D) throws {
                let value = Data(_ckBytes(rawRepresentation))
                _ = try _ckParseRawSignature(value, coordinateByteCount: 48)
                self.rawRepresentation = value
            }

            public init<D: DataProtocol>(derRepresentation: D) throws {
                let pair = try _ckParseDERSignature(Data(_ckBytes(derRepresentation)), coordinateByteCount: 48)
                self.rawRepresentation = _ckRawSignature(r: pair.r, s: pair.s, coordinateByteCount: 48)
            }

            public func withUnsafeBytes<R>(
                _ body: (UnsafeRawBufferPointer) throws -> R
            ) rethrows -> R {
                try rawRepresentation.withUnsafeBytes(body)
            }
        }

        public struct PublicKey: Sendable {
            fileprivate let storage: _CKNISTPublic
            public var rawRepresentation: Data { storage.rawRepresentation }
            public var x963Representation: Data { storage.x963Representation }
            public var derRepresentation: Data { storage.derRepresentation }
            public var pemRepresentation: String { storage.pemRepresentation }
            public var compactRepresentation: Data? { storage.compactRepresentation }
            public var compressedRepresentation: Data { storage.compressedRepresentation }

            public init<D: ContiguousBytes>(rawRepresentation: D) throws {
                storage = try _CKNISTPublic(rawRepresentation: rawRepresentation, curve: .p384)
            }

            public init<Bytes: ContiguousBytes>(x963Representation: Bytes) throws {
                storage = try _CKNISTPublic(x963Representation: x963Representation, curve: .p384)
            }

            public init<Bytes: RandomAccessCollection>(derRepresentation: Bytes) throws
            where Bytes.Element == UInt8 {
                storage = try _CKNISTPublic(derRepresentation: derRepresentation, curve: .p384)
            }

            public init(pemRepresentation: String) throws {
                storage = try _CKNISTPublic(pemRepresentation: pemRepresentation, curve: .p384)
            }

            public init<Bytes: ContiguousBytes>(compactRepresentation: Bytes) throws {
                storage = try _CKNISTPublic(compactRepresentation: compactRepresentation, curve: .p384)
            }

            public init<Bytes: ContiguousBytes>(compressedRepresentation: Bytes) throws {
                storage = try _CKNISTPublic(compressedRepresentation: compressedRepresentation, curve: .p384)
            }

            init(storage: _CKNISTPublic) { self.storage = storage }

            public func isValidSignature<D: DataProtocol>(
                _ signature: ECDSASignature,
                for data: D
            ) -> Bool {
                isValidSignature(signature, digestBytes: Array(SHA384.hash(data: Data(_ckBytes(data)))))
            }

            public func isValidSignature<D: Digest>(
                _ signature: ECDSASignature,
                for digest: D
            ) -> Bool {
                isValidSignature(signature, digestBytes: Array(digest))
            }

            private func isValidSignature(_ signature: ECDSASignature, digestBytes: [UInt8]) -> Bool {
                guard let pair = try? _ckECDSASignature(raw: signature.rawRepresentation, curve: .p384) else {
                    return false
                }
                return _ecdsaVerify(
                    .p384,
                    publicPoint: storage.point,
                    digest: digestBytes,
                    r: pair.r,
                    s: pair.s
                )
            }
        }

        public struct PrivateKey: Sendable {
            fileprivate let storage: _CKNISTPrivate
            public var rawRepresentation: Data { storage.rawRepresentation }
            public var x963Representation: Data { storage.x963Representation }
            public var derRepresentation: Data { storage.derRepresentation }
            public var pemRepresentation: String { storage.pemRepresentation }
            public var publicKey: PublicKey {
                PublicKey(storage: try! _CKNISTPublic(curve: .p384, point: storage.publicPoint))
            }

            public init(compactRepresentable: Bool = true) {
                storage = _CKNISTPrivate(curve: .p384, compactRepresentable: compactRepresentable)
            }

            public init<Bytes: ContiguousBytes>(rawRepresentation: Bytes) throws {
                storage = try _CKNISTPrivate(rawRepresentation: rawRepresentation, curve: .p384)
            }

            public init<Bytes: ContiguousBytes>(x963Representation: Bytes) throws {
                storage = try _CKNISTPrivate(x963Representation: x963Representation, curve: .p384)
            }

            public init<Bytes: RandomAccessCollection>(derRepresentation: Bytes) throws
            where Bytes.Element == UInt8 {
                storage = try _CKNISTPrivate(derRepresentation: derRepresentation, curve: .p384)
            }

            public init(pemRepresentation: String) throws {
                storage = try _CKNISTPrivate(pemRepresentation: pemRepresentation, curve: .p384)
            }

            public func signature<D: DataProtocol>(for data: D) throws -> ECDSASignature {
                try signature(digestBytes: Array(SHA384.hash(data: Data(_ckBytes(data)))))
            }

            public func signature<D: Digest>(for digest: D) throws -> ECDSASignature {
                try signature(digestBytes: Array(digest))
            }

            private func signature(digestBytes: [UInt8]) throws -> ECDSASignature {
                let pair = _ecdsaSign(.p384, scalar: storage.scalar, digest: digestBytes)
                return try ECDSASignature(
                    rawRepresentation: _ckRawSignature(r: pair.r, s: pair.s, coordinateByteCount: 48)
                )
            }
        }
    }

    public enum KeyAgreement: Sendable {
        public struct PublicKey: HPKEPublicKeySerialization {
            public typealias EphemeralPrivateKey = PrivateKey
            fileprivate let storage: _CKNISTPublic
            public var rawRepresentation: Data { storage.rawRepresentation }
            public var x963Representation: Data { storage.x963Representation }
            public var derRepresentation: Data { storage.derRepresentation }
            public var pemRepresentation: String { storage.pemRepresentation }
            public var compactRepresentation: Data? { storage.compactRepresentation }
            public var compressedRepresentation: Data { storage.compressedRepresentation }

            public init<D: ContiguousBytes>(rawRepresentation: D) throws {
                storage = try _CKNISTPublic(rawRepresentation: rawRepresentation, curve: .p384)
            }

            public init<D: ContiguousBytes>(_ serialization: D, kem: HPKE.KEM) throws {
                guard kem == .P384_HKDF_SHA384 else { throw CryptoKitError.incorrectParameterSize }
                let data = _ckData(serialization)
                if data.count == 97 {
                    storage = try _CKNISTPublic(x963Representation: data, curve: .p384)
                } else {
                    storage = try _CKNISTPublic(rawRepresentation: data, curve: .p384)
                }
            }

            public func hpkeRepresentation(kem: HPKE.KEM) throws -> Data {
                guard kem == .P384_HKDF_SHA384 else { throw CryptoKitError.incorrectParameterSize }
                return x963Representation
            }

            public init<Bytes: ContiguousBytes>(x963Representation: Bytes) throws {
                storage = try _CKNISTPublic(x963Representation: x963Representation, curve: .p384)
            }

            public init<Bytes: RandomAccessCollection>(derRepresentation: Bytes) throws
            where Bytes.Element == UInt8 {
                storage = try _CKNISTPublic(derRepresentation: derRepresentation, curve: .p384)
            }

            public init(pemRepresentation: String) throws {
                storage = try _CKNISTPublic(pemRepresentation: pemRepresentation, curve: .p384)
            }

            public init<Bytes: ContiguousBytes>(compactRepresentation: Bytes) throws {
                storage = try _CKNISTPublic(compactRepresentation: compactRepresentation, curve: .p384)
            }

            public init<Bytes: ContiguousBytes>(compressedRepresentation: Bytes) throws {
                storage = try _CKNISTPublic(compressedRepresentation: compressedRepresentation, curve: .p384)
            }

            init(storage: _CKNISTPublic) { self.storage = storage }
        }

        public struct PrivateKey: DiffieHellmanKeyAgreement {
            public typealias PublicKey = P384.KeyAgreement.PublicKey
            fileprivate let storage: _CKNISTPrivate
            public var rawRepresentation: Data { storage.rawRepresentation }
            public var x963Representation: Data { storage.x963Representation }
            public var derRepresentation: Data { storage.derRepresentation }
            public var pemRepresentation: String { storage.pemRepresentation }
            public var publicKey: PublicKey {
                PublicKey(storage: try! _CKNISTPublic(curve: .p384, point: storage.publicPoint))
            }

            public init() {
                storage = _CKNISTPrivate(curve: .p384, compactRepresentable: true)
            }

            public init(compactRepresentable: Bool = true) {
                storage = _CKNISTPrivate(curve: .p384, compactRepresentable: compactRepresentable)
            }

            public init<Bytes: ContiguousBytes>(rawRepresentation: Bytes) throws {
                storage = try _CKNISTPrivate(rawRepresentation: rawRepresentation, curve: .p384)
            }

            public init<Bytes: ContiguousBytes>(x963Representation: Bytes) throws {
                storage = try _CKNISTPrivate(x963Representation: x963Representation, curve: .p384)
            }

            public init<Bytes: RandomAccessCollection>(derRepresentation: Bytes) throws
            where Bytes.Element == UInt8 {
                storage = try _CKNISTPrivate(derRepresentation: derRepresentation, curve: .p384)
            }

            public init(pemRepresentation: String) throws {
                storage = try _CKNISTPrivate(pemRepresentation: pemRepresentation, curve: .p384)
            }

            public func sharedSecretFromKeyAgreement(
                with publicKeyShare: PublicKey
            ) throws -> SharedSecret {
                let point = _nistScale(publicKeyShare.storage.point, storage.scalar, .p384)
                guard !point.infinity else { throw CryptoKitError.invalidParameter }
                return SharedSecret(bytes: Array(_ckCoordBytes(point.x, length: 48)))
            }
        }
    }
}

public enum P521: Sendable {
    public enum Signing: Sendable {
        public struct ECDSASignature: ContiguousBytes, Sendable {
            public var rawRepresentation: Data
            public var derRepresentation: Data {
                let pair = try! _ckParseRawSignature(rawRepresentation, coordinateByteCount: 66)
                return _ckDERSignature(r: pair.r, s: pair.s)
            }

            public init<D: DataProtocol>(rawRepresentation: D) throws {
                let value = Data(_ckBytes(rawRepresentation))
                _ = try _ckParseRawSignature(value, coordinateByteCount: 66)
                self.rawRepresentation = value
            }

            public init<D: DataProtocol>(derRepresentation: D) throws {
                let pair = try _ckParseDERSignature(Data(_ckBytes(derRepresentation)), coordinateByteCount: 66)
                self.rawRepresentation = _ckRawSignature(r: pair.r, s: pair.s, coordinateByteCount: 66)
            }

            public func withUnsafeBytes<R>(
                _ body: (UnsafeRawBufferPointer) throws -> R
            ) rethrows -> R {
                try rawRepresentation.withUnsafeBytes(body)
            }
        }

        public struct PublicKey: Sendable {
            fileprivate let storage: _CKNISTPublic
            public var rawRepresentation: Data { storage.rawRepresentation }
            public var x963Representation: Data { storage.x963Representation }
            public var derRepresentation: Data { storage.derRepresentation }
            public var pemRepresentation: String { storage.pemRepresentation }
            public var compactRepresentation: Data? { storage.compactRepresentation }
            public var compressedRepresentation: Data { storage.compressedRepresentation }

            public init<D: ContiguousBytes>(rawRepresentation: D) throws {
                storage = try _CKNISTPublic(rawRepresentation: rawRepresentation, curve: .p521)
            }

            public init<Bytes: ContiguousBytes>(x963Representation: Bytes) throws {
                storage = try _CKNISTPublic(x963Representation: x963Representation, curve: .p521)
            }

            public init<Bytes: RandomAccessCollection>(derRepresentation: Bytes) throws
            where Bytes.Element == UInt8 {
                storage = try _CKNISTPublic(derRepresentation: derRepresentation, curve: .p521)
            }

            public init(pemRepresentation: String) throws {
                storage = try _CKNISTPublic(pemRepresentation: pemRepresentation, curve: .p521)
            }

            public init<Bytes: ContiguousBytes>(compactRepresentation: Bytes) throws {
                storage = try _CKNISTPublic(compactRepresentation: compactRepresentation, curve: .p521)
            }

            public init<Bytes: ContiguousBytes>(compressedRepresentation: Bytes) throws {
                storage = try _CKNISTPublic(compressedRepresentation: compressedRepresentation, curve: .p521)
            }

            init(storage: _CKNISTPublic) { self.storage = storage }

            public func isValidSignature<D: DataProtocol>(
                _ signature: ECDSASignature,
                for data: D
            ) -> Bool {
                isValidSignature(signature, digestBytes: Array(SHA512.hash(data: Data(_ckBytes(data)))))
            }

            public func isValidSignature<D: Digest>(
                _ signature: ECDSASignature,
                for digest: D
            ) -> Bool {
                isValidSignature(signature, digestBytes: Array(digest))
            }

            private func isValidSignature(_ signature: ECDSASignature, digestBytes: [UInt8]) -> Bool {
                guard let pair = try? _ckECDSASignature(raw: signature.rawRepresentation, curve: .p521) else {
                    return false
                }
                return _ecdsaVerify(
                    .p521,
                    publicPoint: storage.point,
                    digest: digestBytes,
                    r: pair.r,
                    s: pair.s
                )
            }
        }

        public struct PrivateKey: Sendable {
            fileprivate let storage: _CKNISTPrivate
            public var rawRepresentation: Data { storage.rawRepresentation }
            public var x963Representation: Data { storage.x963Representation }
            public var derRepresentation: Data { storage.derRepresentation }
            public var pemRepresentation: String { storage.pemRepresentation }
            public var publicKey: PublicKey {
                PublicKey(storage: try! _CKNISTPublic(curve: .p521, point: storage.publicPoint))
            }

            public init(compactRepresentable: Bool = true) {
                storage = _CKNISTPrivate(curve: .p521, compactRepresentable: compactRepresentable)
            }

            public init<Bytes: ContiguousBytes>(rawRepresentation: Bytes) throws {
                storage = try _CKNISTPrivate(rawRepresentation: rawRepresentation, curve: .p521)
            }

            public init<Bytes: ContiguousBytes>(x963Representation: Bytes) throws {
                storage = try _CKNISTPrivate(x963Representation: x963Representation, curve: .p521)
            }

            public init<Bytes: RandomAccessCollection>(derRepresentation: Bytes) throws
            where Bytes.Element == UInt8 {
                storage = try _CKNISTPrivate(derRepresentation: derRepresentation, curve: .p521)
            }

            public init(pemRepresentation: String) throws {
                storage = try _CKNISTPrivate(pemRepresentation: pemRepresentation, curve: .p521)
            }

            public func signature<D: DataProtocol>(for data: D) throws -> ECDSASignature {
                try signature(digestBytes: Array(SHA512.hash(data: Data(_ckBytes(data)))))
            }

            public func signature<D: Digest>(for digest: D) throws -> ECDSASignature {
                try signature(digestBytes: Array(digest))
            }

            private func signature(digestBytes: [UInt8]) throws -> ECDSASignature {
                let pair = _ecdsaSign(.p521, scalar: storage.scalar, digest: digestBytes)
                return try ECDSASignature(
                    rawRepresentation: _ckRawSignature(r: pair.r, s: pair.s, coordinateByteCount: 66)
                )
            }
        }
    }

    public enum KeyAgreement: Sendable {
        public struct PublicKey: HPKEDiffieHellmanPublicKey {
            public typealias EphemeralPrivateKey = PrivateKey
            public typealias HPKEEphemeralPrivateKey = PrivateKey
            fileprivate let storage: _CKNISTPublic
            public var rawRepresentation: Data { storage.rawRepresentation }
            public var x963Representation: Data { storage.x963Representation }
            public var derRepresentation: Data { storage.derRepresentation }
            public var pemRepresentation: String { storage.pemRepresentation }
            public var compactRepresentation: Data? { storage.compactRepresentation }
            public var compressedRepresentation: Data { storage.compressedRepresentation }

            public init<D: ContiguousBytes>(rawRepresentation: D) throws {
                storage = try _CKNISTPublic(rawRepresentation: rawRepresentation, curve: .p521)
            }

            public init<D: ContiguousBytes>(_ serialization: D, kem: HPKE.KEM) throws {
                guard kem == .P521_HKDF_SHA512 else { throw CryptoKitError.incorrectParameterSize }
                let data = _ckData(serialization)
                if data.count == 133 {
                    storage = try _CKNISTPublic(x963Representation: data, curve: .p521)
                } else {
                    storage = try _CKNISTPublic(rawRepresentation: data, curve: .p521)
                }
            }

            public func hpkeRepresentation(kem: HPKE.KEM) throws -> Data {
                guard kem == .P521_HKDF_SHA512 else { throw CryptoKitError.incorrectParameterSize }
                return x963Representation
            }

            public init<Bytes: ContiguousBytes>(x963Representation: Bytes) throws {
                storage = try _CKNISTPublic(x963Representation: x963Representation, curve: .p521)
            }

            public init<Bytes: RandomAccessCollection>(derRepresentation: Bytes) throws
            where Bytes.Element == UInt8 {
                storage = try _CKNISTPublic(derRepresentation: derRepresentation, curve: .p521)
            }

            public init(pemRepresentation: String) throws {
                storage = try _CKNISTPublic(pemRepresentation: pemRepresentation, curve: .p521)
            }

            public init<Bytes: ContiguousBytes>(compactRepresentation: Bytes) throws {
                storage = try _CKNISTPublic(compactRepresentation: compactRepresentation, curve: .p521)
            }

            public init<Bytes: ContiguousBytes>(compressedRepresentation: Bytes) throws {
                storage = try _CKNISTPublic(compressedRepresentation: compressedRepresentation, curve: .p521)
            }

            init(storage: _CKNISTPublic) { self.storage = storage }
        }

        public struct PrivateKey: HPKEDiffieHellmanPrivateKeyGeneration {
            public typealias PublicKey = P521.KeyAgreement.PublicKey
            fileprivate let storage: _CKNISTPrivate
            public var rawRepresentation: Data { storage.rawRepresentation }
            public var x963Representation: Data { storage.x963Representation }
            public var derRepresentation: Data { storage.derRepresentation }
            public var pemRepresentation: String { storage.pemRepresentation }
            public var publicKey: PublicKey {
                PublicKey(storage: try! _CKNISTPublic(curve: .p521, point: storage.publicPoint))
            }

            public init() {
                storage = _CKNISTPrivate(curve: .p521, compactRepresentable: true)
            }

            public init(compactRepresentable: Bool = true) {
                storage = _CKNISTPrivate(curve: .p521, compactRepresentable: compactRepresentable)
            }

            public init<Bytes: ContiguousBytes>(rawRepresentation: Bytes) throws {
                storage = try _CKNISTPrivate(rawRepresentation: rawRepresentation, curve: .p521)
            }

            public init<Bytes: ContiguousBytes>(x963Representation: Bytes) throws {
                storage = try _CKNISTPrivate(x963Representation: x963Representation, curve: .p521)
            }

            public init<Bytes: RandomAccessCollection>(derRepresentation: Bytes) throws
            where Bytes.Element == UInt8 {
                storage = try _CKNISTPrivate(derRepresentation: derRepresentation, curve: .p521)
            }

            public init(pemRepresentation: String) throws {
                storage = try _CKNISTPrivate(pemRepresentation: pemRepresentation, curve: .p521)
            }

            public func sharedSecretFromKeyAgreement(
                with publicKeyShare: PublicKey
            ) throws -> SharedSecret {
                let point = _nistScale(publicKeyShare.storage.point, storage.scalar, .p521)
                guard !point.infinity else { throw CryptoKitError.invalidParameter }
                return SharedSecret(bytes: Array(_ckCoordBytes(point.x, length: 66)))
            }
        }
    }
}
