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

    public struct Sender: Sendable {
        public let encapsulatedKey: Data

        public init<PK: HPKEDiffieHellmanPublicKey>(
            recipientKey: PK,
            ciphersuite: Ciphersuite,
            info: Data
        ) throws {
            _ = recipientKey
            _ = ciphersuite
            _ = info
            throw CryptoKitError.incorrectParameterSize
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
            _ = recipientKey
            _ = ciphersuite
            _ = info
            _ = psk
            _ = pskID
            throw HPKE.Errors.expectedPSK
        }

        public init<SK: HPKEDiffieHellmanPrivateKey>(
            recipientKey: SK.PublicKey,
            ciphersuite: Ciphersuite,
            info: Data,
            authenticatedBy authenticationKey: SK
        ) throws {
            _ = recipientKey
            _ = ciphersuite
            _ = info
            _ = authenticationKey
            throw CryptoKitError.incorrectParameterSize
        }

        public init<SK: HPKEDiffieHellmanPrivateKey>(
            recipientKey: SK.PublicKey,
            ciphersuite: Ciphersuite,
            info: Data,
            authenticatedBy authenticationKey: SK,
            presharedKey psk: SymmetricKey,
            presharedKeyIdentifier pskID: Data
        ) throws {
            _ = recipientKey
            _ = ciphersuite
            _ = info
            _ = authenticationKey
            _ = psk
            _ = pskID
            throw HPKE.Errors.inconsistentPSKInputs
        }

        public mutating func seal<M: DataProtocol>(_ msg: M) throws -> Data {
            try seal(msg, authenticating: Data())
        }

        public mutating func seal<M: DataProtocol, AD: DataProtocol>(
            _ msg: M,
            authenticating aad: AD
        ) throws -> Data {
            _ = msg
            _ = aad
            throw HPKE.Errors.exportOnlyMode
        }

        public func exportSecret<Context: DataProtocol>(
            context: Context,
            outputByteCount: Int
        ) throws -> SymmetricKey {
            _ = context
            _ = outputByteCount
            throw CryptoKitError.incorrectParameterSize
        }
    }

    public struct Recipient: Sendable {
        public init<SK: HPKEDiffieHellmanPrivateKey>(
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
            _ = privateKey
            _ = ciphersuite
            _ = info
            _ = encapsulatedKey
            _ = psk
            _ = pskID
            throw HPKE.Errors.expectedPSK
        }

        public init<SK: HPKEDiffieHellmanPrivateKey>(
            privateKey: SK,
            ciphersuite: Ciphersuite,
            info: Data,
            encapsulatedKey: Data,
            authenticatedBy authenticationKey: SK.PublicKey
        ) throws {
            _ = privateKey
            _ = ciphersuite
            _ = info
            _ = encapsulatedKey
            _ = authenticationKey
            throw CryptoKitError.incorrectParameterSize
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
            _ = privateKey
            _ = ciphersuite
            _ = info
            _ = encapsulatedKey
            _ = authenticationKey
            _ = psk
            _ = pskID
            throw HPKE.Errors.inconsistentPSKInputs
        }

        public mutating func open<C: DataProtocol>(_ ciphertext: C) throws -> Data {
            try open(ciphertext, authenticating: Data())
        }

        public mutating func open<C: DataProtocol, AD: DataProtocol>(
            _ ciphertext: C,
            authenticating aad: AD
        ) throws -> Data {
            _ = ciphertext
            _ = aad
            throw HPKE.Errors.ciphertextTooShort
        }

        public func exportSecret<Context: DataProtocol>(
            context: Context,
            outputByteCount: Int
        ) throws -> SymmetricKey {
            _ = context
            _ = outputByteCount
            throw CryptoKitError.incorrectParameterSize
        }
    }
}
