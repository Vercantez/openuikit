import Foundation
import Dispatch

public let ASAuthorizationErrorDomain = "ASAuthorizationErrorDomain"
public let ASExtensionErrorDomain = "ASExtensionErrorDomain"
public let ASExtensionLocalizedFailureReasonErrorKey =
    "ASExtensionLocalizedFailureReasonErrorKey"
public let ASCredentialIdentityStoreErrorDomain =
    "ASCredentialIdentityStoreErrorDomain"

/// Linux overlay placeholders for Swift `String` constants whose Apple
/// NSString payloads are not in the public inputs. Tests prove the overlay
/// identity, not Apple's string.
public let ASCredentialImportToken = "ASCredentialImportToken"
public let ASCredentialExchangeActivity = "ASCredentialExchangeActivity"
public let ASAuthorizationAppleIDProviderCredentialRevokedNotification =
    Notification.Name("ASAuthorizationAppleIDProviderCredentialRevokedNotification")

@frozen
public struct ASAuthorizationError:
    Foundation._BridgedStoredNSError,
    @unchecked Sendable
{
    public enum Code: Int, Foundation._ErrorCodeProtocol, Sendable {
        public typealias _ErrorType = ASAuthorizationError

        case unknown = 1000
        case canceled = 1001
        case invalidResponse = 1002
        case notHandled = 1003
        case failed = 1004
        case notInteractive = 1005
        case matchedExcludedCredential = 1006
        case credentialImport = 1007
        case credentialExport = 1008
        case preferSignInWithApple = 1009
        case deviceNotConfiguredForPasskeyCreation = 1010
    }

    public let _nsError: NSError

    public init(_nsError: NSError) {
        self._nsError = _nsError
    }

    public static var _nsErrorDomain: String { ASAuthorizationErrorDomain }
    public static var errorDomain: String { ASAuthorizationErrorDomain }

    public static var unknown: Code { .unknown }
    public static var canceled: Code { .canceled }
    public static var invalidResponse: Code { .invalidResponse }
    public static var notHandled: Code { .notHandled }
    public static var failed: Code { .failed }
    public static var notInteractive: Code { .notInteractive }
    public static var matchedExcludedCredential: Code { .matchedExcludedCredential }
    public static var credentialImport: Code { .credentialImport }
    public static var credentialExport: Code { .credentialExport }
    public static var preferSignInWithApple: Code { .preferSignInWithApple }
    public static var deviceNotConfiguredForPasskeyCreation: Code {
        .deviceNotConfiguredForPasskeyCreation
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(_nsError.domain)
        hasher.combine(_nsError.code)
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }
}

@frozen
public struct ASExtensionError:
    Foundation._BridgedStoredNSError,
    @unchecked Sendable
{
    public enum Code: Int, Foundation._ErrorCodeProtocol, Sendable {
        public typealias _ErrorType = ASExtensionError

        case failed = 0
        case userCanceled = 1
        case userInteractionRequired = 100
        case credentialIdentityNotFound = 101
        case matchedExcludedCredential = 102
    }

    public let _nsError: NSError

    public init(_nsError: NSError) {
        self._nsError = _nsError
    }

    public static var _nsErrorDomain: String { ASExtensionErrorDomain }
    public static var errorDomain: String { ASExtensionErrorDomain }

    public static var failed: Code { .failed }
    public static var userCanceled: Code { .userCanceled }
    public static var userInteractionRequired: Code { .userInteractionRequired }
    public static var credentialIdentityNotFound: Code { .credentialIdentityNotFound }
    public static var matchedExcludedCredential: Code { .matchedExcludedCredential }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(_nsError.domain)
        hasher.combine(_nsError.code)
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }
}

@frozen
public struct ASCredentialIdentityStoreError:
    Foundation._BridgedStoredNSError,
    @unchecked Sendable
{
    public enum Code: Int, Foundation._ErrorCodeProtocol, Sendable {
        public typealias _ErrorType = ASCredentialIdentityStoreError

        case internalError = 0
        case storeDisabled = 1
        case storeBusy = 2
    }

    public let _nsError: NSError

    public init(_nsError: NSError) {
        self._nsError = _nsError
    }

    public static var _nsErrorDomain: String { ASCredentialIdentityStoreErrorDomain }
    public static var errorDomain: String { ASCredentialIdentityStoreErrorDomain }

    public static var internalError: Code { .internalError }
    public static var storeDisabled: Code { .storeDisabled }
    public static var storeBusy: Code { .storeBusy }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(_nsError.domain)
        hasher.combine(_nsError.code)
    }

    public var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }
}
