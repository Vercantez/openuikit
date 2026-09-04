import Foundation

public struct CorecryptoCurveType: Sendable {}

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
                _ = data
                return signature.count == 64 && false
            }
        }

        public struct PrivateKey: Sendable {
            public let rawRepresentation: Data
            public var publicKey: PublicKey {
                try! PublicKey(rawRepresentation: Data(count: 32))
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
                _ = data
                throw _ckUnavailableCrypto()
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
                try! PublicKey(rawRepresentation: Data(count: 32))
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
                _ = publicKeyShare
                throw _ckUnavailableCrypto()
            }
        }
    }
}


public enum P256: Sendable {
    public enum Signing: Sendable {
        public struct ECDSASignature: ContiguousBytes, Sendable {
            public var rawRepresentation: Data
            public var derRepresentation: Data { Data() }

            public init<D: DataProtocol>(rawRepresentation: D) throws {
                let value = Data(_ckBytes(rawRepresentation))
                guard value.count == 64 else { throw CryptoKitError.incorrectParameterSize }
                self.rawRepresentation = value
            }

            public init<D: DataProtocol>(derRepresentation: D) throws {
                _ = derRepresentation
                throw CryptoKitASN1Error.invalidASN1Object
            }

            public func withUnsafeBytes<R>(
                _ body: (UnsafeRawBufferPointer) throws -> R
            ) rethrows -> R {
                try rawRepresentation.withUnsafeBytes(body)
            }
        }

        public struct PublicKey: Sendable {
            public let rawRepresentation: Data
            public var x963Representation: Data { Data() }
            public var derRepresentation: Data { Data() }
            public var pemRepresentation: String { "" }
            public var compactRepresentation: Data? { nil }
            public var compressedRepresentation: Data { Data() }

            public init<D: ContiguousBytes>(rawRepresentation: D) throws {
                let value = _ckData(rawRepresentation)
                guard value.count == 64 else { throw CryptoKitError.incorrectKeySize }
                self.rawRepresentation = value
            }

            public init<Bytes: ContiguousBytes>(x963Representation: Bytes) throws {
                _ = x963Representation
                throw CryptoKitError.incorrectParameterSize
            }

            public init<Bytes: RandomAccessCollection>(derRepresentation: Bytes) throws
            where Bytes.Element == UInt8 {
                _ = derRepresentation
                throw CryptoKitASN1Error.invalidASN1Object
            }

            public init(pemRepresentation: String) throws {
                _ = pemRepresentation
                throw CryptoKitASN1Error.invalidPEMDocument
            }

            public init<Bytes: ContiguousBytes>(compactRepresentation: Bytes) throws {
                _ = compactRepresentation
                throw CryptoKitError.incorrectParameterSize
            }

            public init<Bytes: ContiguousBytes>(compressedRepresentation: Bytes) throws {
                _ = compressedRepresentation
                throw CryptoKitError.incorrectParameterSize
            }

            public func isValidSignature<D: DataProtocol>(
                _ signature: ECDSASignature,
                for data: D
            ) -> Bool {
                _ = signature
                _ = data
                return false
            }

            public func isValidSignature<D: Digest>(
                _ signature: ECDSASignature,
                for digest: D
            ) -> Bool {
                _ = signature
                _ = digest
                return false
            }
        }

        public struct PrivateKey: Sendable {
            public let rawRepresentation: Data
            public var x963Representation: Data { Data() }
            public var derRepresentation: Data { Data() }
            public var pemRepresentation: String { "" }
            public var publicKey: PublicKey {
                try! PublicKey(rawRepresentation: Data(count: 64))
            }

            public init(compactRepresentable: Bool = true) {
                _ = compactRepresentable
                self.rawRepresentation = Data(_ckRandomBytes(32))
            }

            public init<Bytes: ContiguousBytes>(rawRepresentation: Bytes) throws {
                let value = _ckData(rawRepresentation)
                guard value.count == 32 else { throw CryptoKitError.incorrectKeySize }
                self.rawRepresentation = value
            }

            public init<Bytes: ContiguousBytes>(x963Representation: Bytes) throws {
                _ = x963Representation
                throw CryptoKitError.incorrectParameterSize
            }

            public init<Bytes: RandomAccessCollection>(derRepresentation: Bytes) throws
            where Bytes.Element == UInt8 {
                _ = derRepresentation
                throw CryptoKitASN1Error.invalidASN1Object
            }

            public init(pemRepresentation: String) throws {
                _ = pemRepresentation
                throw CryptoKitASN1Error.invalidPEMDocument
            }

            public func signature<D: DataProtocol>(for data: D) throws -> ECDSASignature {
                _ = data
                throw _ckUnavailableCrypto()
            }

            public func signature<D: Digest>(for digest: D) throws -> ECDSASignature {
                _ = digest
                throw _ckUnavailableCrypto()
            }
        }
    }

    public enum KeyAgreement: Sendable {
        public struct PublicKey: HPKEDiffieHellmanPublicKey {
            public typealias EphemeralPrivateKey = PrivateKey
            public typealias HPKEEphemeralPrivateKey = PrivateKey
            public let rawRepresentation: Data
            public var x963Representation: Data { Data() }
            public var derRepresentation: Data { Data() }
            public var pemRepresentation: String { "" }
            public var compactRepresentation: Data? { nil }
            public var compressedRepresentation: Data { Data() }

            public init<D: ContiguousBytes>(rawRepresentation: D) throws {
                let value = _ckData(rawRepresentation)
                guard value.count == 64 else { throw CryptoKitError.incorrectKeySize }
                self.rawRepresentation = value
            }

            public init<D: ContiguousBytes>(_ serialization: D, kem: HPKE.KEM) throws {
                guard kem == .P256_HKDF_SHA256 else { throw CryptoKitError.incorrectParameterSize }
                try self.init(rawRepresentation: serialization)
            }

            public func hpkeRepresentation(kem: HPKE.KEM) throws -> Data {
                guard kem == .P256_HKDF_SHA256 else { throw CryptoKitError.incorrectParameterSize }
                return rawRepresentation
            }

            public init<Bytes: ContiguousBytes>(x963Representation: Bytes) throws {
                _ = x963Representation
                throw CryptoKitError.incorrectParameterSize
            }

            public init<Bytes: RandomAccessCollection>(derRepresentation: Bytes) throws
            where Bytes.Element == UInt8 {
                _ = derRepresentation
                throw CryptoKitASN1Error.invalidASN1Object
            }

            public init(pemRepresentation: String) throws {
                _ = pemRepresentation
                throw CryptoKitASN1Error.invalidPEMDocument
            }

            public init<Bytes: ContiguousBytes>(compactRepresentation: Bytes) throws {
                _ = compactRepresentation
                throw CryptoKitError.incorrectParameterSize
            }

            public init<Bytes: ContiguousBytes>(compressedRepresentation: Bytes) throws {
                _ = compressedRepresentation
                throw CryptoKitError.incorrectParameterSize
            }
        }

        public struct PrivateKey: HPKEDiffieHellmanPrivateKeyGeneration {
            public typealias PublicKey = P256.KeyAgreement.PublicKey
            public let rawRepresentation: Data
            public var x963Representation: Data { Data() }
            public var derRepresentation: Data { Data() }
            public var pemRepresentation: String { "" }
            public var publicKey: PublicKey {
                try! PublicKey(rawRepresentation: Data(count: 64))
            }

            public init() {
                self.rawRepresentation = Data(_ckRandomBytes(32))
            }

            public init(compactRepresentable: Bool = true) {
                _ = compactRepresentable
                self.rawRepresentation = Data(_ckRandomBytes(32))
            }

            public init<Bytes: ContiguousBytes>(rawRepresentation: Bytes) throws {
                let value = _ckData(rawRepresentation)
                guard value.count == 32 else { throw CryptoKitError.incorrectKeySize }
                self.rawRepresentation = value
            }

            public init<Bytes: ContiguousBytes>(x963Representation: Bytes) throws {
                _ = x963Representation
                throw CryptoKitError.incorrectParameterSize
            }

            public init<Bytes: RandomAccessCollection>(derRepresentation: Bytes) throws
            where Bytes.Element == UInt8 {
                _ = derRepresentation
                throw CryptoKitASN1Error.invalidASN1Object
            }

            public init(pemRepresentation: String) throws {
                _ = pemRepresentation
                throw CryptoKitASN1Error.invalidPEMDocument
            }

            public func sharedSecretFromKeyAgreement(
                with publicKeyShare: PublicKey
            ) throws -> SharedSecret {
                _ = publicKeyShare
                throw _ckUnavailableCrypto()
            }
        }
    }
}

public enum P384: Sendable {
    public enum Signing: Sendable {
        public struct ECDSASignature: ContiguousBytes, Sendable {
            public var rawRepresentation: Data
            public var derRepresentation: Data { Data() }

            public init<D: DataProtocol>(rawRepresentation: D) throws {
                let value = Data(_ckBytes(rawRepresentation))
                guard value.count == 96 else { throw CryptoKitError.incorrectParameterSize }
                self.rawRepresentation = value
            }

            public init<D: DataProtocol>(derRepresentation: D) throws {
                _ = derRepresentation
                throw CryptoKitASN1Error.invalidASN1Object
            }

            public func withUnsafeBytes<R>(
                _ body: (UnsafeRawBufferPointer) throws -> R
            ) rethrows -> R {
                try rawRepresentation.withUnsafeBytes(body)
            }
        }

        public struct PublicKey: Sendable {
            public let rawRepresentation: Data
            public var x963Representation: Data { Data() }
            public var derRepresentation: Data { Data() }
            public var pemRepresentation: String { "" }
            public var compactRepresentation: Data? { nil }
            public var compressedRepresentation: Data { Data() }

            public init<D: ContiguousBytes>(rawRepresentation: D) throws {
                let value = _ckData(rawRepresentation)
                guard value.count == 96 else { throw CryptoKitError.incorrectKeySize }
                self.rawRepresentation = value
            }

            public init<Bytes: ContiguousBytes>(x963Representation: Bytes) throws {
                _ = x963Representation
                throw CryptoKitError.incorrectParameterSize
            }

            public init<Bytes: RandomAccessCollection>(derRepresentation: Bytes) throws
            where Bytes.Element == UInt8 {
                _ = derRepresentation
                throw CryptoKitASN1Error.invalidASN1Object
            }

            public init(pemRepresentation: String) throws {
                _ = pemRepresentation
                throw CryptoKitASN1Error.invalidPEMDocument
            }

            public init<Bytes: ContiguousBytes>(compactRepresentation: Bytes) throws {
                _ = compactRepresentation
                throw CryptoKitError.incorrectParameterSize
            }

            public init<Bytes: ContiguousBytes>(compressedRepresentation: Bytes) throws {
                _ = compressedRepresentation
                throw CryptoKitError.incorrectParameterSize
            }

            public func isValidSignature<D: DataProtocol>(
                _ signature: ECDSASignature,
                for data: D
            ) -> Bool {
                _ = signature
                _ = data
                return false
            }

            public func isValidSignature<D: Digest>(
                _ signature: ECDSASignature,
                for digest: D
            ) -> Bool {
                _ = signature
                _ = digest
                return false
            }
        }

        public struct PrivateKey: Sendable {
            public let rawRepresentation: Data
            public var x963Representation: Data { Data() }
            public var derRepresentation: Data { Data() }
            public var pemRepresentation: String { "" }
            public var publicKey: PublicKey {
                try! PublicKey(rawRepresentation: Data(count: 96))
            }

            public init(compactRepresentable: Bool = true) {
                _ = compactRepresentable
                self.rawRepresentation = Data(_ckRandomBytes(48))
            }

            public init<Bytes: ContiguousBytes>(rawRepresentation: Bytes) throws {
                let value = _ckData(rawRepresentation)
                guard value.count == 48 else { throw CryptoKitError.incorrectKeySize }
                self.rawRepresentation = value
            }

            public init<Bytes: ContiguousBytes>(x963Representation: Bytes) throws {
                _ = x963Representation
                throw CryptoKitError.incorrectParameterSize
            }

            public init<Bytes: RandomAccessCollection>(derRepresentation: Bytes) throws
            where Bytes.Element == UInt8 {
                _ = derRepresentation
                throw CryptoKitASN1Error.invalidASN1Object
            }

            public init(pemRepresentation: String) throws {
                _ = pemRepresentation
                throw CryptoKitASN1Error.invalidPEMDocument
            }

            public func signature<D: DataProtocol>(for data: D) throws -> ECDSASignature {
                _ = data
                throw _ckUnavailableCrypto()
            }

            public func signature<D: Digest>(for digest: D) throws -> ECDSASignature {
                _ = digest
                throw _ckUnavailableCrypto()
            }
        }
    }

    public enum KeyAgreement: Sendable {
        public struct PublicKey: HPKEPublicKeySerialization {
            public typealias EphemeralPrivateKey = PrivateKey
            public let rawRepresentation: Data
            public var x963Representation: Data { Data() }
            public var derRepresentation: Data { Data() }
            public var pemRepresentation: String { "" }
            public var compactRepresentation: Data? { nil }
            public var compressedRepresentation: Data { Data() }

            public init<D: ContiguousBytes>(rawRepresentation: D) throws {
                let value = _ckData(rawRepresentation)
                guard value.count == 96 else { throw CryptoKitError.incorrectKeySize }
                self.rawRepresentation = value
            }

            public init<D: ContiguousBytes>(_ serialization: D, kem: HPKE.KEM) throws {
                guard kem == .P384_HKDF_SHA384 else { throw CryptoKitError.incorrectParameterSize }
                try self.init(rawRepresentation: serialization)
            }

            public func hpkeRepresentation(kem: HPKE.KEM) throws -> Data {
                guard kem == .P384_HKDF_SHA384 else { throw CryptoKitError.incorrectParameterSize }
                return rawRepresentation
            }

            public init<Bytes: ContiguousBytes>(x963Representation: Bytes) throws {
                _ = x963Representation
                throw CryptoKitError.incorrectParameterSize
            }

            public init<Bytes: RandomAccessCollection>(derRepresentation: Bytes) throws
            where Bytes.Element == UInt8 {
                _ = derRepresentation
                throw CryptoKitASN1Error.invalidASN1Object
            }

            public init(pemRepresentation: String) throws {
                _ = pemRepresentation
                throw CryptoKitASN1Error.invalidPEMDocument
            }

            public init<Bytes: ContiguousBytes>(compactRepresentation: Bytes) throws {
                _ = compactRepresentation
                throw CryptoKitError.incorrectParameterSize
            }

            public init<Bytes: ContiguousBytes>(compressedRepresentation: Bytes) throws {
                _ = compressedRepresentation
                throw CryptoKitError.incorrectParameterSize
            }
        }

        public struct PrivateKey: DiffieHellmanKeyAgreement {
            public typealias PublicKey = P384.KeyAgreement.PublicKey
            public let rawRepresentation: Data
            public var x963Representation: Data { Data() }
            public var derRepresentation: Data { Data() }
            public var pemRepresentation: String { "" }
            public var publicKey: PublicKey {
                try! PublicKey(rawRepresentation: Data(count: 96))
            }

            public init() {
                self.rawRepresentation = Data(_ckRandomBytes(48))
            }

            public init(compactRepresentable: Bool = true) {
                _ = compactRepresentable
                self.rawRepresentation = Data(_ckRandomBytes(48))
            }

            public init<Bytes: ContiguousBytes>(rawRepresentation: Bytes) throws {
                let value = _ckData(rawRepresentation)
                guard value.count == 48 else { throw CryptoKitError.incorrectKeySize }
                self.rawRepresentation = value
            }

            public init<Bytes: ContiguousBytes>(x963Representation: Bytes) throws {
                _ = x963Representation
                throw CryptoKitError.incorrectParameterSize
            }

            public init<Bytes: RandomAccessCollection>(derRepresentation: Bytes) throws
            where Bytes.Element == UInt8 {
                _ = derRepresentation
                throw CryptoKitASN1Error.invalidASN1Object
            }

            public init(pemRepresentation: String) throws {
                _ = pemRepresentation
                throw CryptoKitASN1Error.invalidPEMDocument
            }

            public func sharedSecretFromKeyAgreement(
                with publicKeyShare: PublicKey
            ) throws -> SharedSecret {
                _ = publicKeyShare
                throw _ckUnavailableCrypto()
            }
        }
    }
}

public enum P521: Sendable {
    public enum Signing: Sendable {
        public struct ECDSASignature: ContiguousBytes, Sendable {
            public var rawRepresentation: Data
            public var derRepresentation: Data { Data() }

            public init<D: DataProtocol>(rawRepresentation: D) throws {
                let value = Data(_ckBytes(rawRepresentation))
                guard value.count == 132 else { throw CryptoKitError.incorrectParameterSize }
                self.rawRepresentation = value
            }

            public init<D: DataProtocol>(derRepresentation: D) throws {
                _ = derRepresentation
                throw CryptoKitASN1Error.invalidASN1Object
            }

            public func withUnsafeBytes<R>(
                _ body: (UnsafeRawBufferPointer) throws -> R
            ) rethrows -> R {
                try rawRepresentation.withUnsafeBytes(body)
            }
        }

        public struct PublicKey: Sendable {
            public let rawRepresentation: Data
            public var x963Representation: Data { Data() }
            public var derRepresentation: Data { Data() }
            public var pemRepresentation: String { "" }
            public var compactRepresentation: Data? { nil }
            public var compressedRepresentation: Data { Data() }

            public init<D: ContiguousBytes>(rawRepresentation: D) throws {
                let value = _ckData(rawRepresentation)
                guard value.count == 132 else { throw CryptoKitError.incorrectKeySize }
                self.rawRepresentation = value
            }

            public init<Bytes: ContiguousBytes>(x963Representation: Bytes) throws {
                _ = x963Representation
                throw CryptoKitError.incorrectParameterSize
            }

            public init<Bytes: RandomAccessCollection>(derRepresentation: Bytes) throws
            where Bytes.Element == UInt8 {
                _ = derRepresentation
                throw CryptoKitASN1Error.invalidASN1Object
            }

            public init(pemRepresentation: String) throws {
                _ = pemRepresentation
                throw CryptoKitASN1Error.invalidPEMDocument
            }

            public init<Bytes: ContiguousBytes>(compactRepresentation: Bytes) throws {
                _ = compactRepresentation
                throw CryptoKitError.incorrectParameterSize
            }

            public init<Bytes: ContiguousBytes>(compressedRepresentation: Bytes) throws {
                _ = compressedRepresentation
                throw CryptoKitError.incorrectParameterSize
            }

            public func isValidSignature<D: DataProtocol>(
                _ signature: ECDSASignature,
                for data: D
            ) -> Bool {
                _ = signature
                _ = data
                return false
            }

            public func isValidSignature<D: Digest>(
                _ signature: ECDSASignature,
                for digest: D
            ) -> Bool {
                _ = signature
                _ = digest
                return false
            }
        }

        public struct PrivateKey: Sendable {
            public let rawRepresentation: Data
            public var x963Representation: Data { Data() }
            public var derRepresentation: Data { Data() }
            public var pemRepresentation: String { "" }
            public var publicKey: PublicKey {
                try! PublicKey(rawRepresentation: Data(count: 132))
            }

            public init(compactRepresentable: Bool = true) {
                _ = compactRepresentable
                self.rawRepresentation = Data(_ckRandomBytes(66))
            }

            public init<Bytes: ContiguousBytes>(rawRepresentation: Bytes) throws {
                let value = _ckData(rawRepresentation)
                guard value.count == 66 else { throw CryptoKitError.incorrectKeySize }
                self.rawRepresentation = value
            }

            public init<Bytes: ContiguousBytes>(x963Representation: Bytes) throws {
                _ = x963Representation
                throw CryptoKitError.incorrectParameterSize
            }

            public init<Bytes: RandomAccessCollection>(derRepresentation: Bytes) throws
            where Bytes.Element == UInt8 {
                _ = derRepresentation
                throw CryptoKitASN1Error.invalidASN1Object
            }

            public init(pemRepresentation: String) throws {
                _ = pemRepresentation
                throw CryptoKitASN1Error.invalidPEMDocument
            }

            public func signature<D: DataProtocol>(for data: D) throws -> ECDSASignature {
                _ = data
                throw _ckUnavailableCrypto()
            }

            public func signature<D: Digest>(for digest: D) throws -> ECDSASignature {
                _ = digest
                throw _ckUnavailableCrypto()
            }
        }
    }

    public enum KeyAgreement: Sendable {
        public struct PublicKey: HPKEDiffieHellmanPublicKey {
            public typealias EphemeralPrivateKey = PrivateKey
            public typealias HPKEEphemeralPrivateKey = PrivateKey
            public let rawRepresentation: Data
            public var x963Representation: Data { Data() }
            public var derRepresentation: Data { Data() }
            public var pemRepresentation: String { "" }
            public var compactRepresentation: Data? { nil }
            public var compressedRepresentation: Data { Data() }

            public init<D: ContiguousBytes>(rawRepresentation: D) throws {
                let value = _ckData(rawRepresentation)
                guard value.count == 132 else { throw CryptoKitError.incorrectKeySize }
                self.rawRepresentation = value
            }

            public init<D: ContiguousBytes>(_ serialization: D, kem: HPKE.KEM) throws {
                guard kem == .P521_HKDF_SHA512 else { throw CryptoKitError.incorrectParameterSize }
                try self.init(rawRepresentation: serialization)
            }

            public func hpkeRepresentation(kem: HPKE.KEM) throws -> Data {
                guard kem == .P521_HKDF_SHA512 else { throw CryptoKitError.incorrectParameterSize }
                return rawRepresentation
            }

            public init<Bytes: ContiguousBytes>(x963Representation: Bytes) throws {
                _ = x963Representation
                throw CryptoKitError.incorrectParameterSize
            }

            public init<Bytes: RandomAccessCollection>(derRepresentation: Bytes) throws
            where Bytes.Element == UInt8 {
                _ = derRepresentation
                throw CryptoKitASN1Error.invalidASN1Object
            }

            public init(pemRepresentation: String) throws {
                _ = pemRepresentation
                throw CryptoKitASN1Error.invalidPEMDocument
            }

            public init<Bytes: ContiguousBytes>(compactRepresentation: Bytes) throws {
                _ = compactRepresentation
                throw CryptoKitError.incorrectParameterSize
            }

            public init<Bytes: ContiguousBytes>(compressedRepresentation: Bytes) throws {
                _ = compressedRepresentation
                throw CryptoKitError.incorrectParameterSize
            }
        }

        public struct PrivateKey: HPKEDiffieHellmanPrivateKeyGeneration {
            public typealias PublicKey = P521.KeyAgreement.PublicKey
            public let rawRepresentation: Data
            public var x963Representation: Data { Data() }
            public var derRepresentation: Data { Data() }
            public var pemRepresentation: String { "" }
            public var publicKey: PublicKey {
                try! PublicKey(rawRepresentation: Data(count: 132))
            }

            public init() {
                self.rawRepresentation = Data(_ckRandomBytes(66))
            }

            public init(compactRepresentable: Bool = true) {
                _ = compactRepresentable
                self.rawRepresentation = Data(_ckRandomBytes(66))
            }

            public init<Bytes: ContiguousBytes>(rawRepresentation: Bytes) throws {
                let value = _ckData(rawRepresentation)
                guard value.count == 66 else { throw CryptoKitError.incorrectKeySize }
                self.rawRepresentation = value
            }

            public init<Bytes: ContiguousBytes>(x963Representation: Bytes) throws {
                _ = x963Representation
                throw CryptoKitError.incorrectParameterSize
            }

            public init<Bytes: RandomAccessCollection>(derRepresentation: Bytes) throws
            where Bytes.Element == UInt8 {
                _ = derRepresentation
                throw CryptoKitASN1Error.invalidASN1Object
            }

            public init(pemRepresentation: String) throws {
                _ = pemRepresentation
                throw CryptoKitASN1Error.invalidPEMDocument
            }

            public func sharedSecretFromKeyAgreement(
                with publicKeyShare: PublicKey
            ) throws -> SharedSecret {
                _ = publicKeyShare
                throw _ckUnavailableCrypto()
            }
        }
    }
}
