import Foundation

/// Errors reported by MarketplaceKit.
///
/// Case list and associated-value shapes match the Xcode 26.1 symbol graph and
/// API digester (ordered children). `description` strings follow the public
/// Apple documentation comments in the pinned graph. Linux Codable keys are
/// local (`linuxCase` plus associated payloads); Darwin archive layout is
/// unobserved.
public enum MarketplaceKitError: Error, Sendable, Codable, CustomStringConvertible {
    /// Failure due to an unknown error.
    case unknown
    /// The requested install requires capabilities not available on this device.
    case missingCapabilities([String])
    /// The requested install does not run on this device's platform.
    case unsupportedPlatform
    /// The requested install requires a minimum platform version greater than this device.
    case minimumPlatformVersionNotSatisfied(String)
    /// Installations are restricted on this device.
    case installationRestricted
    /// Installations of marketplaces are denied on this device.
    case installationOfMarketplaceDenied
    /// The requested install is rating-restricted on this device.
    case ratingRestricted
    /// The device does not have enough storage for the requested install.
    case insufficientStorageSpace(Measurement<UnitInformationStorage>)
    /// No supported variant of the requested install is available.
    case noSupportedVariant
    /// The referenced app is not installed.
    case appNotInstalled
    /// The alternative distribution manifest is invalid.
    case invalidManifest
    /// A network error prevented the operation.
    case networkError
    /// The alternative distribution package URL is invalid.
    case invalidAlternativeDistributionPackageURL
    /// The alternative distribution package signature is invalid.
    case invalidAlternativeDistributionPackageSignature
    /// The requested feature is unavailable.
    case featureUnavailable
    /// The operation was cancelled.
    case cancelled
    /// The install type does not match the requested operation.
    case mismatchedInstallType
    /// An OAuth token error prevented the operation.
    case oauthTokenError
    /// The app license is invalid.
    case invalidLicense
    /// A URL required by the operation is invalid.
    case invalidURL
    /// An install verification token is required and was not supplied.
    case missingInstallVerificationToken
    /// An age-rating exception is not needed for this request.
    case ageRatingExceptionNotNeeded
    /// An age-rating exception request is required and was not supplied.
    case missingAgeRatingExceptionRequest

    public var description: String {
        switch self {
        case .unknown:
            return "Failure due to an unknown error."
        case .missingCapabilities(let capabilities):
            return "The requested install requires capabilities not available on this device: \(capabilities.joined(separator: ","))."
        case .unsupportedPlatform:
            return "The requested install does not run on this device's platform."
        case .minimumPlatformVersionNotSatisfied(let version):
            return "The requested install requires a minimum platform version that is greater than this device (\(version))."
        case .installationRestricted:
            return "Installations are restricted on this device."
        case .installationOfMarketplaceDenied:
            return "Installations of marketplaces are denied on this device."
        case .ratingRestricted:
            return "The requested install is rating-restricted on this device."
        case .insufficientStorageSpace(let amount):
            return "Insufficient storage space: \(amount)."
        case .noSupportedVariant:
            return "No supported variant of the requested install is available."
        case .appNotInstalled:
            return "The referenced app is not installed."
        case .invalidManifest:
            return "The alternative distribution manifest is invalid."
        case .networkError:
            return "A network error prevented the operation."
        case .invalidAlternativeDistributionPackageURL:
            return "The alternative distribution package URL is invalid."
        case .invalidAlternativeDistributionPackageSignature:
            return "The alternative distribution package signature is invalid."
        case .featureUnavailable:
            return "The requested feature is unavailable."
        case .cancelled:
            return "The operation was cancelled."
        case .mismatchedInstallType:
            return "The install type does not match the requested operation."
        case .oauthTokenError:
            return "An OAuth token error prevented the operation."
        case .invalidLicense:
            return "The app license is invalid."
        case .invalidURL:
            return "A URL required by the operation is invalid."
        case .missingInstallVerificationToken:
            return "An install verification token is required and was not supplied."
        case .ageRatingExceptionNotNeeded:
            return "An age-rating exception is not needed for this request."
        case .missingAgeRatingExceptionRequest:
            return "An age-rating exception request is required and was not supplied."
        }
    }

    private enum CodingKeys: String, CodingKey {
        case linuxCase
        case capabilities
        case version
        case bytes
    }

    private var linuxCaseName: String {
        switch self {
        case .unknown: return "unknown"
        case .missingCapabilities: return "missingCapabilities"
        case .unsupportedPlatform: return "unsupportedPlatform"
        case .minimumPlatformVersionNotSatisfied: return "minimumPlatformVersionNotSatisfied"
        case .installationRestricted: return "installationRestricted"
        case .installationOfMarketplaceDenied: return "installationOfMarketplaceDenied"
        case .ratingRestricted: return "ratingRestricted"
        case .insufficientStorageSpace: return "insufficientStorageSpace"
        case .noSupportedVariant: return "noSupportedVariant"
        case .appNotInstalled: return "appNotInstalled"
        case .invalidManifest: return "invalidManifest"
        case .networkError: return "networkError"
        case .invalidAlternativeDistributionPackageURL: return "invalidAlternativeDistributionPackageURL"
        case .invalidAlternativeDistributionPackageSignature: return "invalidAlternativeDistributionPackageSignature"
        case .featureUnavailable: return "featureUnavailable"
        case .cancelled: return "cancelled"
        case .mismatchedInstallType: return "mismatchedInstallType"
        case .oauthTokenError: return "oauthTokenError"
        case .invalidLicense: return "invalidLicense"
        case .invalidURL: return "invalidURL"
        case .missingInstallVerificationToken: return "missingInstallVerificationToken"
        case .ageRatingExceptionNotNeeded: return "ageRatingExceptionNotNeeded"
        case .missingAgeRatingExceptionRequest: return "missingAgeRatingExceptionRequest"
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(linuxCaseName, forKey: .linuxCase)
        switch self {
        case .missingCapabilities(let capabilities):
            try container.encode(capabilities, forKey: .capabilities)
        case .minimumPlatformVersionNotSatisfied(let version):
            try container.encode(version, forKey: .version)
        case .insufficientStorageSpace(let amount):
            let bytes = amount.converted(to: .bytes).value
            try container.encode(bytes, forKey: .bytes)
        default:
            break
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(String.self, forKey: .linuxCase)
        switch name {
        case "unknown":
            self = .unknown
        case "missingCapabilities":
            self = .missingCapabilities(try container.decode([String].self, forKey: .capabilities))
        case "unsupportedPlatform":
            self = .unsupportedPlatform
        case "minimumPlatformVersionNotSatisfied":
            self = .minimumPlatformVersionNotSatisfied(try container.decode(String.self, forKey: .version))
        case "installationRestricted":
            self = .installationRestricted
        case "installationOfMarketplaceDenied":
            self = .installationOfMarketplaceDenied
        case "ratingRestricted":
            self = .ratingRestricted
        case "insufficientStorageSpace":
            let bytes = try container.decode(Double.self, forKey: .bytes)
            self = .insufficientStorageSpace(Measurement(value: bytes, unit: .bytes))
        case "noSupportedVariant":
            self = .noSupportedVariant
        case "appNotInstalled":
            self = .appNotInstalled
        case "invalidManifest":
            self = .invalidManifest
        case "networkError":
            self = .networkError
        case "invalidAlternativeDistributionPackageURL":
            self = .invalidAlternativeDistributionPackageURL
        case "invalidAlternativeDistributionPackageSignature":
            self = .invalidAlternativeDistributionPackageSignature
        case "featureUnavailable":
            self = .featureUnavailable
        case "cancelled":
            self = .cancelled
        case "mismatchedInstallType":
            self = .mismatchedInstallType
        case "oauthTokenError":
            self = .oauthTokenError
        case "invalidLicense":
            self = .invalidLicense
        case "invalidURL":
            self = .invalidURL
        case "missingInstallVerificationToken":
            self = .missingInstallVerificationToken
        case "ageRatingExceptionNotNeeded":
            self = .ageRatingExceptionNotNeeded
        case "missingAgeRatingExceptionRequest":
            self = .missingAgeRatingExceptionRequest
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .linuxCase,
                in: container,
                debugDescription: "Unknown MarketplaceKitError Linux case \(name)"
            )
        }
    }
}
