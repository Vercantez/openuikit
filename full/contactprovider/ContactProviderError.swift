import Foundation

/// Errors thrown by the Contact Provider framework.
///
/// Case order matches the pinned Xcode 26.1 API digester children. `errorCode`
/// uses that declaration-order discriminator (0...10). Darwin `NSError` codes
/// are unobserved; see `oracle-questions.tsv`.
public enum ContactProviderError: Error, Equatable, Hashable, Sendable {
    /// The framework couldn't discover the app's extension.
    case extensionNotFound
    /// Limit of items has been reached.
    case itemsLimitReached
    /// The extension is unable to enumerate.
    case cannotEnumerate
    /// The page expired and is no longer valid.
    case pageExpired
    /// The change anchor expired and is no longer valid.
    case changeAnchorExpired
    /// The extension can't run because the feature isn't available.
    case featureNotAvailable
    /// The person using the app denied the action.
    case deniedByUser
    /// The extension enumeration timed out.
    case enumerationTimeout
    /// The app invalidated the extension while it was enumerating.
    case extensionInvalidated
    /// The extension invalidate operation timed out.
    case extensionInvalidateTimeout
    /// The domain has not been registered.
    case domainNotRegistered
}

extension ContactProviderError: CustomNSError {
    public static var errorDomain: String {
        ContactProviderLinux.errorDomain
    }

    public var errorCode: Int {
        switch self {
        case .extensionNotFound: return 0
        case .itemsLimitReached: return 1
        case .cannotEnumerate: return 2
        case .pageExpired: return 3
        case .changeAnchorExpired: return 4
        case .featureNotAvailable: return 5
        case .deniedByUser: return 6
        case .enumerationTimeout: return 7
        case .extensionInvalidated: return 8
        case .extensionInvalidateTimeout: return 9
        case .domainNotRegistered: return 10
        }
    }

    public var errorUserInfo: [String: Any] {
        var info: [String: Any] = [:]
        if let description = errorDescription {
            info[NSLocalizedDescriptionKey] = description
        }
        if let reason = failureReason {
            info[NSLocalizedFailureReasonErrorKey] = reason
        }
        return info
    }
}

extension ContactProviderError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .extensionNotFound:
            return "The framework couldn't discover the app's extension."
        case .itemsLimitReached:
            return "Limit of items has been reached."
        case .cannotEnumerate:
            return "The extension is unable to enumerate."
        case .pageExpired:
            return "The page expired and is no longer valid."
        case .changeAnchorExpired:
            return "The change anchor expired and is no longer valid."
        case .featureNotAvailable:
            return "The extension can't run because the feature isn't available."
        case .deniedByUser:
            return "The person using the app denied the action."
        case .enumerationTimeout:
            return "The extension enumeration timed out."
        case .extensionInvalidated:
            return "The app invalidated the extension while it was enumerating content or changes."
        case .extensionInvalidateTimeout:
            return "The extension invalidate operation timed out."
        case .domainNotRegistered:
            return "The domain has not been registered."
        }
    }

    public var failureReason: String? {
        errorDescription
    }
}
