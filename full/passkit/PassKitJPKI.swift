import Foundation

/// Japanese Individual Number Card (JPKI) pass contents. Certificate
/// extraction, PIN/biometric authentication, and signatures are Apple /
/// card-hardware operations: they throw `JPKIPassContents.Error` on this host.

public struct JPKIPassContents {
    public protocol Identity {
        associatedtype IdentityType: JPKIPassContents.Identity
        func certificate(
            using request: JPKIPassContents.AuthenticationRequest<IdentityType>
        ) async throws -> JPKIPassContents.Certificate<IdentityType>
        var authenticationTriesRemaining: Int { get async throws }
        func signature(
            for data: Data,
            using request: JPKIPassContents.AuthenticationRequest<IdentityType>
        ) async throws -> JPKIPassContents.Signature<IdentityType>
        func signature(
            for data: [Data],
            using request: JPKIPassContents.AuthenticationRequest<IdentityType>
        ) async throws -> [JPKIPassContents.Signature<IdentityType>]
    }

    public struct Certificate<IdentityType: JPKIPassContents.Identity>: Sendable {
        public let data: Data
    }

    public struct Signature<IdentityType: JPKIPassContents.Identity>: Sendable {
        public let certificate: Certificate<IdentityType>
        public let signatureData: Data
    }

    public struct AuthenticationRequest<IdentityType: JPKIPassContents.Identity>: Sendable {
        public init(type: JPKIPassContents.UserIdentity.AuthenticationType) {
            _ = type
        }
        public init(type: JPKIPassContents.SigningIdentity.AuthenticationType) {
            _ = type
        }
    }

    public enum Error: Swift.Error, Sendable {
        case unknownError
        case invalidInput
        case appNotForeground
        case biometricUnavailable
        case resourceNotAvailable
        case userAuthenticationFailed(remainingRetryAttempts: Int)
        case incorrectUserAuthentication
        case biometricAuthenticationFailed(laError: LAError)

        public var localizedDescription: String {
            "JPKIPassContents.Error"
        }
    }

    public struct UserIdentity: Identity, Sendable {
        public typealias IdentityType = JPKIPassContents.UserIdentity

        public init() {}

        public enum AuthenticationType: Sendable {
            case systemBiometric
            case pin(String)
        }

        public var authenticationTriesRemaining: Int {
            get async throws { throw Error.resourceNotAvailable }
        }

        public func certificate(
            using request: AuthenticationRequest<UserIdentity>
        ) async throws -> Certificate<UserIdentity> {
            _ = request
            throw Error.resourceNotAvailable
        }

        public func changePIN(from oldValue: String, to newValue: String) async throws {
            _ = (oldValue, newValue)
            throw Error.resourceNotAvailable
        }

        public func signature(
            for data: Data,
            using request: AuthenticationRequest<UserIdentity>
        ) async throws -> Signature<UserIdentity> {
            _ = (data, request)
            throw Error.resourceNotAvailable
        }

        public func signature(
            for data: [Data],
            using request: AuthenticationRequest<UserIdentity>
        ) async throws -> [Signature<UserIdentity>] {
            _ = (data, request)
            throw Error.resourceNotAvailable
        }
    }

    public struct SigningIdentity: Identity, Sendable {
        public typealias IdentityType = JPKIPassContents.SigningIdentity

        public init() {}

        public enum AuthenticationType: Sendable {
            case password(String)
        }

        public var authenticationTriesRemaining: Int {
            get async throws { throw Error.resourceNotAvailable }
        }

        public func certificate(
            using request: AuthenticationRequest<SigningIdentity>
        ) async throws -> Certificate<SigningIdentity> {
            _ = request
            throw Error.resourceNotAvailable
        }

        public func changePassword(from oldValue: String, to newValue: String) async throws {
            _ = (oldValue, newValue)
            throw Error.resourceNotAvailable
        }

        public func signature(
            for data: Data,
            using request: AuthenticationRequest<SigningIdentity>
        ) async throws -> Signature<SigningIdentity> {
            _ = (data, request)
            throw Error.resourceNotAvailable
        }

        public func signature(
            for data: [Data],
            using request: AuthenticationRequest<SigningIdentity>
        ) async throws -> [Signature<SigningIdentity>] {
            _ = (data, request)
            throw Error.resourceNotAvailable
        }
    }

    public let userIdentity: UserIdentity?
    public let signingIdentity: SigningIdentity?

    public init(_ pass: PKPass) async throws {
        _ = pass
        throw Error.resourceNotAvailable
    }
}

enum _JPKIPassContentsMarker {}

#if !canImport(LocalAuthentication)
public struct LAError: Error, Hashable, Sendable {
    public var code: Int
    public init(_ code: Int = 0) { self.code = code }
}
#endif
