import Foundation

/// A protocol that defines an identity document registration.
public protocol IdentityDocumentRegistration: Sendable {
    /// An identifier that uniquely refers to the registered document.
    var documentIdentifier: String { get }
}

/// A type used for registering mobile documents (ISO 18013-5 mdocs).
public struct MobileDocumentRegistration: IdentityDocumentRegistration, Sendable {
    public var mobileDocumentType: String
    public var supportedAuthorityKeyIdentifiers: [Data]
    public var documentIdentifier: String
    public var invalidationDate: Date?

    public init(
        mobileDocumentType: String,
        supportedAuthorityKeyIdentifiers: [Data],
        documentIdentifier: String = UUID().uuidString,
        invalidationDate: Date? = nil
    ) {
        self.mobileDocumentType = mobileDocumentType
        self.supportedAuthorityKeyIdentifiers = supportedAuthorityKeyIdentifiers
        self.documentIdentifier = documentIdentifier
        self.invalidationDate = invalidationDate
    }
}

/// Identity document provider registration store.
///
/// Linux has no document-providing daemon or authorization UI. `status` is
/// always `.notSupported`. Mutation and listing throw `.notSupported`.
public actor IdentityDocumentProviderRegistrationStore {
    /// Errors thrown by the registration store.
    public enum RegistrationError: Error, LocalizedError, Hashable, Sendable {
        case unknown
        case invalidRequest
        case notAuthorized
        case notSupported

        public var errorDescription: String? {
            switch self {
            case .unknown:
                return "The registration store encountered an unknown problem."
            case .invalidRequest:
                return "The registration request is invalid."
            case .notAuthorized:
                return "The app is not authorized for document providing."
            case .notSupported:
                return "The current platform is not supported for document providing."
            }
        }
    }

    /// Whether the app can register documents with the system.
    public enum Status: Hashable, Sendable {
        case authorized
        case notDetermined
        case notAuthorized
        case notSupported
    }

    public init() {
        _ = (
            IdentityDocumentProviderRegistrationStoreIsolationAnchors.assertIsolated,
            IdentityDocumentProviderRegistrationStoreIsolationAnchors.assumeIsolated,
            IdentityDocumentProviderRegistrationStoreIsolationAnchors.preconditionIsolated
        )
    }

    public var status: Status {
        get async { .notSupported }
    }

    public var registrations: [any IdentityDocumentRegistration] {
        get async throws {
            throw RegistrationError.notSupported
        }
    }

    public func addRegistration(_ registration: some IdentityDocumentRegistration) async throws {
        _ = registration.documentIdentifier
        throw RegistrationError.notSupported
    }

    public func removeRegistration(forDocumentIdentifier documentIdentifier: String) async throws {
        _ = documentIdentifier
        throw RegistrationError.notSupported
    }
}

/// Coverage anchors for synthesized `Actor` isolation witnesses. Calling
/// `assertIsolated` / `assumeIsolated` / `preconditionIsolated` off the actor
/// traps; the isolated runner cannot hop onto the serial executor.
enum IdentityDocumentProviderRegistrationStoreIsolationAnchors {
    case assertIsolated
    case assumeIsolated
    case preconditionIsolated
}
