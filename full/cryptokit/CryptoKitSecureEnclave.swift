import Foundation

public enum SecureEnclave: Sendable {
    public static var isAvailable: Bool { false }

    public enum P256: Sendable {
        public enum Signing: Sendable {
            public struct PrivateKey: Sendable {
                public let publicKey: CryptoKit.P256.Signing.PublicKey
                public let dataRepresentation: Data

                public func signature<D: DataProtocol>(
                    for data: D
                ) throws -> CryptoKit.P256.Signing.ECDSASignature {
                    _ = data
                    throw _ckUnavailableCrypto()
                }

                public func signature<D: Digest>(
                    for digest: D
                ) throws -> CryptoKit.P256.Signing.ECDSASignature {
                    _ = digest
                    throw _ckUnavailableCrypto()
                }
            }
        }

        public enum KeyAgreement: Sendable {
            public struct PrivateKey: Sendable {
                public typealias PublicKey = CryptoKit.P256.KeyAgreement.PublicKey
                public let publicKey: CryptoKit.P256.KeyAgreement.PublicKey
                public let dataRepresentation: Data

                public func sharedSecretFromKeyAgreement(
                    with publicKeyShare: CryptoKit.P256.KeyAgreement.PublicKey
                ) throws -> SharedSecret {
                    _ = publicKeyShare
                    throw _ckUnavailableCrypto()
                }
            }
        }
    }

    public enum MLKEM768: Sendable {
        public struct PrivateKey: Sendable {
            public typealias PublicKey = CryptoKit.MLKEM768.PublicKey
            public let publicKey: CryptoKit.MLKEM768.PublicKey
            public let dataRepresentation: Data

            public static func generate() throws -> PrivateKey {
                throw _ckUnavailableCrypto()
            }

            public func decapsulate<D: DataProtocol>(_ encapsulated: D) throws -> SymmetricKey {
                _ = encapsulated
                throw _ckUnavailableCrypto()
            }
        }
    }

    public enum MLKEM1024: Sendable {
        public struct PrivateKey: Sendable {
            public typealias PublicKey = CryptoKit.MLKEM1024.PublicKey
            public let publicKey: CryptoKit.MLKEM1024.PublicKey
            public let dataRepresentation: Data

            public static func generate() throws -> PrivateKey {
                throw _ckUnavailableCrypto()
            }

            public func decapsulate<D: DataProtocol>(_ encapsulated: D) throws -> SymmetricKey {
                _ = encapsulated
                throw _ckUnavailableCrypto()
            }
        }
    }

    public enum MLDSA65: Sendable {
        public struct PrivateKey: Sendable {
            public let publicKey: CryptoKit.MLDSA65.PublicKey
            public let dataRepresentation: Data

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
        public struct PrivateKey: Sendable {
            public let publicKey: CryptoKit.MLDSA87.PublicKey
            public let dataRepresentation: Data

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
}
