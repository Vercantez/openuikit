import Foundation

/// Actor that would view, manage, or use credentials in the Secure Element.
///
/// Apple's `startSession()` requires a foreground client, the Secure Element
/// credential entitlement, a GDPR sheet, and a user authorization alert.
/// Linux `init()` produces a local object that never holds an SE resource.
/// Every hardware or daemon operation throws `.featureUnavailable`.
public actor CredentialSession: Equatable {
    private var sessionState: State = .invalid

    /// Linux-only designated initializer. Apple's public graph also records
    /// `init()`; this host never attaches an SE session resource.
    public init() {
        sessionState = .invalid
    }

    public static func == (lhs: CredentialSession, rhs: CredentialSession) -> Bool {
        lhs === rhs
    }

    /// Request a session. Linux has no SE daemon or entitlement; always throws.
    public static func startSession() async throws -> CredentialSession {
        throw SecureElementCredentialHostBoundary.unavailable()
    }

    /// Whether this device and user configuration can use the service.
    /// The query itself requires Apple's daemon; this host throws.
    public static var isEligible: Bool {
        get async throws {
            throw SecureElementCredentialHostBoundary.unavailable()
        }
    }

    public var state: State {
        get async { sessionState }
    }

    public var eventStream: AsyncStream<Event> {
        get async {
            AsyncStream { continuation in
                continuation.yield(.sessionInvalidated(reason: .featureUnavailable))
                continuation.finish()
            }
        }
    }

    public var secureElementInfo: SecureElementInfo {
        get async throws {
            throw SecureElementCredentialHostBoundary.unavailable()
        }
    }

    public func invalidate() async throws {
        sessionState = .invalid
        throw SecureElementCredentialHostBoundary.unavailable()
    }

    public func listCredentials() async throws -> [Credential] {
        throw SecureElementCredentialHostBoundary.unavailable()
    }

    public func provisionCredential(configurationUUID: UUID, name: String) async throws -> Credential {
        _ = configurationUUID
        _ = name
        throw SecureElementCredentialHostBoundary.unavailable()
    }

    public func deleteCredential(_ credential: Credential) async throws {
        try rejectUnusableCredential(credential)
        throw SecureElementCredentialHostBoundary.unavailable()
    }

    public func enterWiredMode(using credential: Credential) async throws {
        try rejectUnusableCredential(credential)
        throw SecureElementCredentialHostBoundary.unavailable()
    }

    public func transceive(_ data: Data) async throws -> Data {
        _ = data
        throw SecureElementCredentialHostBoundary.unavailable()
    }

    public func endWiredMode() async throws {
        throw SecureElementCredentialHostBoundary.unavailable()
    }

    public func acquirePresentmentAssertion() async throws -> PresentmentIntentAssertion {
        throw SecureElementCredentialHostBoundary.unavailable()
    }

    /// UIKit overlay API that does not take a scene type, so it is declared
    /// on the Foundation module. Card emulation still requires NFC/SE.
    public func endCardEmulation() async throws {
        throw SecureElementCredentialHostBoundary.unavailable()
    }

    /// SwiftUI overlay: obtain a transaction configuration. Fail closed.
    public nonisolated func configuration() async throws -> CredentialTransaction.Configuration {
        throw SecureElementCredentialHostBoundary.unavailable()
    }

    private func rejectUnusableCredential(_ credential: Credential) throws {
        switch credential.state {
        case .installationPending, .installationFailed:
            throw ErrorCode.invalidCredentialState
        case .installed:
            return
        }
    }

    /// Session lifecycle recorded by the public graph.
    public enum State: Equatable, Sendable {
        case management
        case cardEmulation(credential: Credential)
        case wired(credential: Credential)
        case invalid
    }

    /// Asynchronous events published on `eventStream`.
    public enum Event: Sendable {
        case sessionInvalidated(reason: ErrorCode)
        case credentialFinishedInstalling(credential: Credential)
        case fieldStateChanged(info: NFCFieldInformation)
        case connectivityEvent(ConnectivityEvent)
        case cardEmulationTimeout
        case presentmentIntentAssertionTimeout
    }

    public enum NFCFieldInformation: Equatable, Hashable, Sendable {
        case fieldPresent
        case fieldAbsent
    }

    public struct ConnectivityEvent: Sendable {
        public let instanceApplicationIdentifier: Data
        public let data: Data

        public init(instanceApplicationIdentifier: Data, data: Data) {
            self.instanceApplicationIdentifier = instanceApplicationIdentifier
            self.data = data
        }
    }

    /// Failures for session, provisioning, wired, and presentment APIs.
    ///
    /// The API digester records a Swift enum with these cases in this order
    /// and no `RawRepresentable` witness. Integer NSError codes are unobserved
    /// and are not invented here.
    public enum ErrorCode: Error, LocalizedError, Equatable, Hashable, Sendable {
        case userNotAuthorized
        case accessDenied
        case clientNotInForeground
        case invalidSessionState
        case invalidCredentialState
        case credentialDoesNotExist
        case instanceDoesNotExist
        case sessionInvalidated
        case userCanceledAuthorization
        case userAuthorizationTimedOut
        case commandNotSupported
        case network
        case resourceUnavailable
        case insufficientSpace
        case presentmentIntentAssertionTimeout
        case featureUnavailable
        case ineligible
        case invalidView
        case acquiredResourceRelinquished
        case conditionsNotSatisfied
        case invalidInput
        case internalError

        /// A localized message describing the reason for the failure.
        public var failureReason: String? {
            switch self {
            case .userNotAuthorized:
                return "The user is not authorized for this Secure Element operation."
            case .accessDenied:
                return "Access to the requested Secure Element resource was denied."
            case .clientNotInForeground:
                return "The client is not in the foreground."
            case .invalidSessionState:
                return "The credential session is not in a valid state for this operation."
            case .invalidCredentialState:
                return "The credential is not in a valid state for this operation."
            case .credentialDoesNotExist:
                return "The requested credential does not exist."
            case .instanceDoesNotExist:
                return "The requested credential instance does not exist."
            case .sessionInvalidated:
                return "The credential session has been invalidated."
            case .userCanceledAuthorization:
                return "The user canceled authorization."
            case .userAuthorizationTimedOut:
                return "User authorization timed out."
            case .commandNotSupported:
                return "The Secure Element command is not supported."
            case .network:
                return "A network error prevented the operation."
            case .resourceUnavailable:
                return "A required Secure Element resource is unavailable."
            case .insufficientSpace:
                return "The Secure Element does not have enough space."
            case .presentmentIntentAssertionTimeout:
                return "The presentment intent assertion timed out."
            case .featureUnavailable:
                return "Secure Element Credential is unavailable on this host."
            case .ineligible:
                return "This device or user configuration is not eligible."
            case .invalidView:
                return "The provided view is not valid for presentment."
            case .acquiredResourceRelinquished:
                return "An acquired resource was relinquished."
            case .conditionsNotSatisfied:
                return "The conditions for this operation were not satisfied."
            case .invalidInput:
                return "The input was invalid."
            case .internalError:
                return "An internal Secure Element Credential error occurred."
            }
        }

        public var errorDescription: String? { failureReason }
    }

    /// Options for contactless card emulation. The public graph records only
    /// `Sendable` and `init()`; additional stored fields are unobserved.
    public struct CardEmulationOptions: Sendable {
        public init() {}
    }

    /// A provisioned credential and its installation state.
    public struct Credential: Equatable, Hashable, Sendable {
        public let identifier: UUID
        public let name: String
        public let state: State

        public init(identifier: UUID, name: String, state: State) {
            self.identifier = identifier
            self.name = name
            self.state = state
        }

        public static func == (a: Credential, b: Credential) -> Bool {
            a.identifier == b.identifier && a.name == b.name && a.state == b.state
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(identifier)
            hasher.combine(name)
        }

        public enum State: Equatable, Sendable {
            case installationPending
            case installed(instances: [InstanceInfo])
            case installationFailed
        }

        public struct InstanceInfo: Equatable, Sendable {
            public let instanceAID: Data
            public let packageAID: Data
            public let moduleAID: Data
            public let securityDomainAID: Data
            public let securityDomainKeyInfo: Data
            public let lifeCycleState: Data
            public let instanceType: InstanceType

            public init(
                instanceAID: Data,
                packageAID: Data,
                moduleAID: Data,
                securityDomainAID: Data,
                securityDomainKeyInfo: Data,
                lifeCycleState: Data,
                instanceType: InstanceType
            ) {
                self.instanceAID = instanceAID
                self.packageAID = packageAID
                self.moduleAID = moduleAID
                self.securityDomainAID = securityDomainAID
                self.securityDomainKeyInfo = securityDomainKeyInfo
                self.lifeCycleState = lifeCycleState
                self.instanceType = instanceType
            }

            /// Counter on the security domain. Requires a live SE; fail closed.
            public var securityDomainCounter: Int {
                get async throws {
                    throw SecureElementCredentialHostBoundary.unavailable()
                }
            }

            public enum InstanceType: Equatable, Hashable, Sendable {
                case standalone
                case headApplication
                case groupApplication
            }
        }
    }

    /// Hardware identity of a Secure Element. Codable with property-named keys.
    public struct SecureElementInfo: Codable {
        public let hardwareReleaseVersionInfo: String
        public let secureElementPlatformSigningCertificate: Data

        public init(
            hardwareReleaseVersionInfo: String,
            secureElementPlatformSigningCertificate: Data
        ) {
            self.hardwareReleaseVersionInfo = hardwareReleaseVersionInfo
            self.secureElementPlatformSigningCertificate = secureElementPlatformSigningCertificate
        }
    }

    /// Presentment-intent assertion. Linux never acquires the SE resource.
    public final class PresentmentIntentAssertion {
        private let storedState: State

        /// Linux constructor so fail-closed instance methods can be typed.
        public init(state: State = .invalid) {
            storedState = state
        }

        public var state: State {
            get async { storedState }
        }

        public func relinquish() async throws {
            throw SecureElementCredentialHostBoundary.unavailable()
        }

        public enum State: Equatable, Hashable {
            case active
            case invalid
        }
    }
}

/// Synthesized `Actor` isolation witnesses. Calling them off-actor traps;
/// the sealed runner has no isolation hop, so they stay declared.
enum CredentialSessionIsolationAnchors {
    case assertIsolated
    case assumeIsolated
    case preconditionIsolated
}
