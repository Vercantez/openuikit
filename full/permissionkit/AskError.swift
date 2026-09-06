import Foundation

/// Fail-closed errors for Communication Limits prompts. Linux has no
/// Screen Time / Communication Limits daemon, so `ask` throws
/// `communicationLimitsNotEnabled` rather than inventing a grant.
public enum AskError: Error, LocalizedError, @unchecked Sendable {
    case unknown
    case invalidQuestion
    case contactSyncNotSetup
    case communicationLimitsNotEnabled
    case systemError(underlyingError: any Error)

    public var errorDescription: String? {
        switch self {
        case .unknown:
            return "An unknown PermissionKit error occurred."
        case .invalidQuestion:
            return "The permission question is invalid."
        case .contactSyncNotSetup:
            return "Contact sync is not set up."
        case .communicationLimitsNotEnabled:
            return "Communication Limits are not enabled on this host."
        case .systemError(let underlyingError):
            return underlyingError.localizedDescription
        }
    }
}
