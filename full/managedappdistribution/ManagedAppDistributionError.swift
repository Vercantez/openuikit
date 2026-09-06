import Foundation

/// Codes that identify errors in Managed App Distribution.
///
/// Case order follows the Xcode 26.1 API digester children:
/// `unrecoverableError`, `networkError`, `deviceNotManaged`,
/// `unsupportedPlatform`, `licenseNotFound`, `appNotManaged`.
/// Description strings are the graph documentation comments.
/// Linux Codable keys are local (`linuxCase`); Darwin archive layout is
/// unobserved.
public enum ManagedAppDistributionError: Error, Sendable, Hashable, Codable, CustomStringConvertible, LocalizedError, RecoverableError {
    /// An error that is unspecified and unrecoverable.
    case unrecoverableError
    /// An error that indicates a network issue.
    case networkError
    /// An error that indicates this device isn't managed.
    case deviceNotManaged
    /// An error that indicates the platform is unsupported.
    case unsupportedPlatform
    /// An error that indicates that a license wasn't found for requested app.
    case licenseNotFound
    /// An error that indicates that the calling app is not managed
    case appNotManaged

    private var linuxCase: String {
        switch self {
        case .unrecoverableError: return "unrecoverableError"
        case .networkError: return "networkError"
        case .deviceNotManaged: return "deviceNotManaged"
        case .unsupportedPlatform: return "unsupportedPlatform"
        case .licenseNotFound: return "licenseNotFound"
        case .appNotManaged: return "appNotManaged"
        }
    }

    /// A localized description of the error.
    public var description: String {
        switch self {
        case .unrecoverableError:
            return "An error that is unspecified and unrecoverable."
        case .networkError:
            return "An error that indicates a network issue."
        case .deviceNotManaged:
            return "An error that indicates this device isn't managed."
        case .unsupportedPlatform:
            return "An error that indicates the platform is unsupported."
        case .licenseNotFound:
            return "An error that indicates that a license wasn't found for requested app."
        case .appNotManaged:
            return "An error that indicates that the calling app is not managed"
        }
    }

    /// A brief description of the error.
    ///
    /// This appears in the title of an alert.
    public var errorDescription: String? { description }

    /// A detailed description of the error.
    ///
    /// This appears in the body of an alert.
    public var failureReason: String? { description }

    /// A suggestion for recovering from the error.
    public var recoverySuggestion: String? { nil }

    /// A link to help documentation.
    ///
    /// This property is for macOS.
    public var helpAnchor: String? { nil }

    /// A set of possible recovery options to present.
    public var recoveryOptions: [String] { [] }

    /// A set of localized error strings.
    public var localizedStringResource: LocalizedStringResource {
        LocalizedStringResource(description)
    }

    /// Attempt to recover from this error when someone selects the option at the given index.
    ///
    /// Linux has no MDM recovery UI. Always returns `false`.
    public func attemptRecovery(optionIndex: Int) -> Bool {
        _ = optionIndex
        return false
    }

    /// Attempt to recover from this error when someone selects the option at the given index.
    public func attemptRecovery(optionIndex: Int, resultHandler handler: @escaping (Bool) -> Void) {
        handler(attemptRecovery(optionIndex: optionIndex))
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(String.self, forKey: .linuxCase)
        switch name {
        case "unrecoverableError": self = .unrecoverableError
        case "networkError": self = .networkError
        case "deviceNotManaged": self = .deviceNotManaged
        case "unsupportedPlatform": self = .unsupportedPlatform
        case "licenseNotFound": self = .licenseNotFound
        case "appNotManaged": self = .appNotManaged
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .linuxCase,
                in: container,
                debugDescription: "unknown ManagedAppDistributionError case"
            )
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(linuxCase, forKey: .linuxCase)
    }

    private enum CodingKeys: String, CodingKey {
        case linuxCase
    }
}
