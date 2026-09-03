import Foundation

public enum KEM: Sendable {
    public enum Errors: Error, Hashable, Sendable {
        case invalidSeed
        case publicKeyMismatchDuringInitialization
    }

    public struct EncapsulationResult: Sendable {
        public let sharedSecret: SymmetricKey
        public let encapsulated: Data

        public init(sharedSecret: SymmetricKey, encapsulated: Data) {
            self.sharedSecret = sharedSecret
            self.encapsulated = encapsulated
        }
    }
}

private func _ckRejectSeed<D: DataProtocol>(_ seed: D, expected: Int) throws -> Data {
    let value = Data(_ckBytes(seed))
    guard value.count == expected else { throw KEM.Errors.invalidSeed }
    return value
}

public enum MLKEM768: Sendable {
    public struct PublicKey: KEMPublicKey {
        public let rawRepresentation: Data
        public init<D: DataProtocol>(rawRepresentation: D) throws {
            self.rawRepresentation = Data(_ckBytes(rawRepresentation))
        }
        public func encapsulate() throws -> KEM.EncapsulationResult {
            throw _ckUnavailableCrypto()
        }
    }

    public struct PrivateKey: KEMPrivateKey {
        public typealias PublicKey = MLKEM768.PublicKey
        public let seedRepresentation: Data
        public var integrityCheckedRepresentation: Data { seedRepresentation }
        public var publicKey: PublicKey { try! PublicKey(rawRepresentation: Data()) }

        public init() throws { throw _ckUnavailableCrypto() }
        public static func generate() throws -> PrivateKey { throw _ckUnavailableCrypto() }

        public init<D: DataProtocol>(seedRepresentation seed: D, publicKey: PublicKey?) throws {
            if publicKey != nil { throw KEM.Errors.publicKeyMismatchDuringInitialization }
            seedRepresentation = try _ckRejectSeed(seed, expected: 64)
        }

        public init<D: DataProtocol>(integrityCheckedRepresentation representation: D) throws {
            seedRepresentation = try _ckRejectSeed(representation, expected: 64)
        }

        public func decapsulate<D: DataProtocol>(_ encapsulated: D) throws -> SymmetricKey {
            try decapsulate(Data(_ckBytes(encapsulated)))
        }

        public func decapsulate(_ encapsulated: Data) throws -> SymmetricKey {
            _ = encapsulated
            throw _ckUnavailableCrypto()
        }
    }
}

public enum MLKEM1024: Sendable {
    public struct PublicKey: KEMPublicKey {
        public let rawRepresentation: Data
        public init<D: DataProtocol>(rawRepresentation: D) throws {
            self.rawRepresentation = Data(_ckBytes(rawRepresentation))
        }
        public func encapsulate() throws -> KEM.EncapsulationResult {
            throw _ckUnavailableCrypto()
        }
    }

    public struct PrivateKey: KEMPrivateKey {
        public typealias PublicKey = MLKEM1024.PublicKey
        public let seedRepresentation: Data
        public var integrityCheckedRepresentation: Data { seedRepresentation }
        public var publicKey: PublicKey { try! PublicKey(rawRepresentation: Data()) }

        public init() throws { throw _ckUnavailableCrypto() }
        public static func generate() throws -> PrivateKey { throw _ckUnavailableCrypto() }

        public init<D: DataProtocol>(seedRepresentation seed: D, publicKey: PublicKey?) throws {
            if publicKey != nil { throw KEM.Errors.publicKeyMismatchDuringInitialization }
            seedRepresentation = try _ckRejectSeed(seed, expected: 64)
        }

        public init<D: DataProtocol>(integrityCheckedRepresentation representation: D) throws {
            seedRepresentation = try _ckRejectSeed(representation, expected: 64)
        }

        public func decapsulate<D: DataProtocol>(_ encapsulated: D) throws -> SymmetricKey {
            try decapsulate(Data(_ckBytes(encapsulated)))
        }

        public func decapsulate(_ encapsulated: Data) throws -> SymmetricKey {
            _ = encapsulated
            throw _ckUnavailableCrypto()
        }
    }
}

public enum XWingMLKEM768X25519: Sendable {
    public struct PublicKey: HPKEKEMPublicKey {
        public typealias EphemeralPrivateKey = PrivateKey
        public typealias HPKEEphemeralPrivateKey = PrivateKey
        public let rawRepresentation: Data

        public init<D: ContiguousBytes>(rawRepresentation: D) throws {
            self.rawRepresentation = _ckData(rawRepresentation)
        }

        public init<D: ContiguousBytes>(_ serialization: D, kem: HPKE.KEM) throws {
            guard kem == .XWingMLKEM768X25519 else { throw CryptoKitError.incorrectParameterSize }
            try self.init(rawRepresentation: serialization)
        }

        public func hpkeRepresentation(kem: HPKE.KEM) throws -> Data {
            guard kem == .XWingMLKEM768X25519 else { throw CryptoKitError.incorrectParameterSize }
            return rawRepresentation
        }

        public func encapsulate() throws -> KEM.EncapsulationResult {
            throw _ckUnavailableCrypto()
        }
    }

    public struct PrivateKey: HPKEKEMPrivateKeyGeneration {
        public typealias PublicKey = XWingMLKEM768X25519.PublicKey
        public let seedRepresentation: Data
        public var integrityCheckedRepresentation: Data { seedRepresentation }
        public var publicKey: PublicKey { try! PublicKey(rawRepresentation: Data()) }

        public init() throws { throw _ckUnavailableCrypto() }
        public static func generate() throws -> PrivateKey { throw _ckUnavailableCrypto() }

        public init<D: DataProtocol>(seedRepresentation seed: D, publicKey: PublicKey?) throws {
            if publicKey != nil { throw KEM.Errors.publicKeyMismatchDuringInitialization }
            seedRepresentation = try _ckRejectSeed(seed, expected: 32)
        }

        public init<D: DataProtocol>(integrityCheckedRepresentation representation: D) throws {
            seedRepresentation = try _ckRejectSeed(representation, expected: 32)
        }

        public func decapsulate(_ encapsulated: Data) throws -> SymmetricKey {
            _ = encapsulated
            throw _ckUnavailableCrypto()
        }
    }
}

public enum MLDSA65: Sendable {
    public struct PublicKey: Sendable {
        public let rawRepresentation: Data
        public init<D: DataProtocol>(rawRepresentation: D) throws {
            self.rawRepresentation = Data(_ckBytes(rawRepresentation))
        }
        public func isValidSignature<S: DataProtocol, D: DataProtocol>(
            _ signature: S,
            for data: D
        ) -> Bool {
            _ = signature
            _ = data
            return false
        }
        public func isValidSignature<S: DataProtocol, D: DataProtocol, C: DataProtocol>(
            _ signature: S,
            for data: D,
            context: C
        ) -> Bool {
            _ = signature
            _ = data
            _ = context
            return false
        }
    }

    public struct PrivateKey: Sendable {
        public let seedRepresentation: Data
        public var integrityCheckedRepresentation: Data { seedRepresentation }
        public var publicKey: PublicKey { try! PublicKey(rawRepresentation: Data()) }

        public init() throws { throw _ckUnavailableCrypto() }

        public init<D: DataProtocol>(seedRepresentation seed: D, publicKey: PublicKey?) throws {
            _ = publicKey
            seedRepresentation = Data(_ckBytes(seed))
        }

        public init<D: DataProtocol>(integrityCheckedRepresentation representation: D) throws {
            seedRepresentation = Data(_ckBytes(representation))
        }

        public func signature<D: DataProtocol>(for data: D) throws -> Data {
            _ = data
            throw _ckUnavailableCrypto()
        }

        public func signature<D: DataProtocol, C: DataProtocol>(
            for data: D,
            context: C
        ) throws -> Data {
            _ = data
            _ = context
            throw _ckUnavailableCrypto()
        }
    }
}

public enum MLDSA87: Sendable {
    public struct PublicKey: Sendable {
        public let rawRepresentation: Data
        public init<D: DataProtocol>(rawRepresentation: D) throws {
            self.rawRepresentation = Data(_ckBytes(rawRepresentation))
        }
        public func isValidSignature<S: DataProtocol, D: DataProtocol>(
            _ signature: S,
            for data: D
        ) -> Bool {
            _ = signature
            _ = data
            return false
        }
        public func isValidSignature<S: DataProtocol, D: DataProtocol, C: DataProtocol>(
            _ signature: S,
            for data: D,
            context: C
        ) -> Bool {
            _ = signature
            _ = data
            _ = context
            return false
        }
    }

    public struct PrivateKey: Sendable {
        public let seedRepresentation: Data
        public var integrityCheckedRepresentation: Data { seedRepresentation }
        public var publicKey: PublicKey { try! PublicKey(rawRepresentation: Data()) }

        public init() throws { throw _ckUnavailableCrypto() }

        public init<D: DataProtocol>(seedRepresentation seed: D, publicKey: PublicKey?) throws {
            _ = publicKey
            seedRepresentation = Data(_ckBytes(seed))
        }

        public init<D: DataProtocol>(integrityCheckedRepresentation representation: D) throws {
            seedRepresentation = Data(_ckBytes(representation))
        }

        public func signature<D: DataProtocol>(for data: D) throws -> Data {
            _ = data
            throw _ckUnavailableCrypto()
        }

        public func signature<D: DataProtocol, C: DataProtocol>(
            for data: D,
            context: C
        ) throws -> Data {
            _ = data
            _ = context
            throw _ckUnavailableCrypto()
        }
    }
}
