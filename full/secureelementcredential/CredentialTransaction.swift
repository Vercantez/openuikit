import Foundation

/// SwiftUI overlay transaction object used to perform wired and contactless
/// exchanges. On Apple, success transitions the session into card-emulation
/// or wired state after user authorization. Linux has no SE, NFC, or
/// presentment UI, so every perform API throws `.featureUnavailable`.
public class CredentialTransaction {
    /// Linux constructor. Apple's graph records no public designated init.
    public init() {}

    public func performCardEmulationTransactionWithCurrentCredential(
        options: CardEmulationOptions = .init()
    ) async throws {
        _ = options
        throw SecureElementCredentialHostBoundary.unavailable()
    }

    public func performTransaction(
        using credential: Credential,
        options: CardEmulationOptions = .init()
    ) async throws {
        _ = credential
        _ = options
        throw SecureElementCredentialHostBoundary.unavailable()
    }

    public func performTransactionInWiredMode(
        using credential: Credential,
        instanceAID: Data
    ) async throws {
        _ = credential
        _ = instanceAID
        throw SecureElementCredentialHostBoundary.unavailable()
    }

    /// Configuration for an upcoming transaction. Identity-equal only.
    public class Configuration: Equatable {
        /// Linux constructor. Apple's graph records no public designated init.
        public init() {}

        public func invalidate() async throws {
            throw SecureElementCredentialHostBoundary.unavailable()
        }

        public static func == (lhs: Configuration, rhs: Configuration) -> Bool {
            lhs === rhs
        }
    }
}

/// UIKit overlay window-scene event delivered when a credential session
/// window is presented or a reader is detected. The payload itself does not
/// require UIKit; scene delivery remains unavailable on Linux.
public enum CredentialSessionWindowSceneEvent: Codable, Equatable, Hashable, Sendable {
    case presentation
    case readerDetected

    public var description: String {
        switch self {
        case .presentation:
            return "presentation"
        case .readerDetected:
            return "readerDetected"
        }
    }
}
