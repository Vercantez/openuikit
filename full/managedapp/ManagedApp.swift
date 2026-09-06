import Foundation

#if canImport(Security)
import Security
#else
/// Isolated-host stand-in for `Security.SecIdentity`. Compiles out when the
/// real Security module is on the link line.
public struct SecIdentity: Equatable, Hashable, Sendable {}

/// Isolated-host stand-in for `Security.SecCertificate`. Compiles out when the
/// real Security module is on the link line.
public struct SecCertificate: Equatable, Hashable, Sendable {}
#endif

/// Errors that functions in the ManagedApp framework can throw.
public enum ManagedAppError: Error, LocalizedError, Hashable, Sendable {
    /// An error that indicates a failure finding an identifier.
    case invalidIdentifier
    /// An error that indicates a failure requesting a secret from the asset server.
    case serverError
    /// An error that indicates a failure at the system level.
    case internalError

    public var errorDescription: String? {
        switch self {
        case .invalidIdentifier:
            return "An error that indicates a failure finding an identifier."
        case .serverError:
            return "An error that indicates a failure requesting a secret from the asset server."
        case .internalError:
            return "An error that indicates a failure at the system level."
        }
    }
}

/// A code for an error that occurs during configuration decoding.
///
/// The system reserves some codes for its use only. Reserved codes are equal to
/// or greater than `firstReserved`. Codes less than `firstReserved` are
/// app-specific.
///
/// Integer values below are the Linux starting-point mapping: reserved codes
/// occupy `1000...` in API-digester declaration order after the threshold.
/// Apple's exact integers are unobserved and recorded in `oracle-questions.tsv`.
public struct ManagedAppConfigurationDecodingErrorCode: RawRepresentable, Hashable, Codable, Sendable {
    public typealias RawValue = Int

    public let rawValue: Int

    public init?(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// An error code for the start of the range of reserved error codes.
    public static let firstReserved: Int = 1000
    /// A reserved error that indicates the decoder threw an unknown custom error.
    public static let generic: Int = 1000
    /// An error code that indicates the decoder encountered corrupt data.
    public static let dataCorrupted: Int = 1001
    /// An error code that indicates the decoder encountered an unknown coding key.
    public static let keyNotFound: Int = 1002
    /// An error code that indicates the decoder encountered a type mismatch.
    public static let typeMismatch: Int = 1003
    /// An error code that indicates a coding key yields no value.
    public static let valueNotFound: Int = 1004
    /// An error code that indicates the decoder timed out.
    public static let timeout: Int = 1005
}

/// A protocol for an error that describes an issue with decoding the configuration.
public protocol ManagedAppConfigurationDecodingError: Error, Codable, Sendable {
    /// An app-specific error code that identifies a configuration issue.
    var code: ManagedAppConfigurationDecodingErrorCode { get set }
    /// A human-readable message that describes the configuration issue.
    var message: String { get set }
}

/// One-shot async sequence used by Linux providers: yields `snapshot` once, then
/// finishes. Apple's sequences stay open for MDM updates; Linux has no daemon.
struct ManagedAppSnapshotSequence<Element>: AsyncSequence {
    let snapshot: Element

    struct Iterator: AsyncIteratorProtocol {
        var remaining: Element?

        mutating func next() async -> Element? {
            let value = remaining
            remaining = nil
            return value
        }
    }

    func makeAsyncIterator() -> Iterator {
        Iterator(remaining: snapshot)
    }
}

/// A class that provides passwords that an MDM admin provisions for a managed app or extension.
public final class ManagedAppPasswordsProvider: Sendable {
    public init() {}

    /// Yields an empty identifier array: Linux has no MDM password store.
    public var identifiers: some AsyncSequence<[String], Never> {
        get async {
            ManagedAppSnapshotSequence(snapshot: [String]())
        }
    }

    /// Throws `invalidIdentifier` because no passwords are provisioned.
    public func password(withIdentifier identifier: String) async throws(ManagedAppError) -> String {
        _ = identifier
        throw .invalidIdentifier
    }
}

/// A class that provides identities that an MDM admin provisions for a managed app or extension.
public final class ManagedAppIdentitiesProvider: Sendable {
    public init() {}

    public var identifiers: some AsyncSequence<[String], Never> {
        get async {
            ManagedAppSnapshotSequence(snapshot: [String]())
        }
    }

    public func identity(withIdentifier identifier: String) async throws(ManagedAppError) -> SecIdentity {
        _ = identifier
        throw .invalidIdentifier
    }
}

/// A class that provides certificates that an MDM admin provisions for a managed app or extension.
public final class ManagedAppCertificatesProvider: Sendable {
    public init() {}

    public var identifiers: some AsyncSequence<[String], Never> {
        get async {
            ManagedAppSnapshotSequence(snapshot: [String]())
        }
    }

    public func certificate(withIdentifier identifier: String) async throws(ManagedAppError) -> SecCertificate {
        _ = identifier
        throw .invalidIdentifier
    }
}

/// A class that provides configurations that an MDM admin provisions for a managed app or extension.
public final class ManagedAppConfigurationProvider: Sendable {
    public init() {}

    /// Yields `nil` immediately: Linux has no MDM configuration plist.
    public func configurations<Configuration: Decodable>(
        _ t: Configuration.Type
    ) async -> some AsyncSequence<Configuration?, Never> {
        _ = t
        return ManagedAppSnapshotSequence<Configuration?>(snapshot: nil)
    }
}
