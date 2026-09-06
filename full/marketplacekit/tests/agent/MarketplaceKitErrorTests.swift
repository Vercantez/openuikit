import Foundation
import MarketplaceKit

func testMarketplaceKitErrorCases() {
    let cases: [MarketplaceKitError] = [
        .unknown,
        .missingCapabilities(["metal", "arm64"]),
        .unsupportedPlatform,
        .minimumPlatformVersionNotSatisfied("18.0"),
        .installationRestricted,
        .installationOfMarketplaceDenied,
        .ratingRestricted,
        .insufficientStorageSpace(Measurement(value: 512, unit: UnitInformationStorage.bytes)),
        .noSupportedVariant,
        .appNotInstalled,
        .invalidManifest,
        .networkError,
        .invalidAlternativeDistributionPackageURL,
        .invalidAlternativeDistributionPackageSignature,
        .featureUnavailable,
        .cancelled,
        .mismatchedInstallType,
        .oauthTokenError,
        .invalidLicense,
        .invalidURL,
        .missingInstallVerificationToken,
        .ageRatingExceptionNotNeeded,
        .missingAgeRatingExceptionRequest,
    ]
    precondition(cases.count == 23)
    for error in cases {
        precondition(!error.description.isEmpty)
        precondition(!error.localizedDescription.isEmpty)
        let decoded = marketplaceKitJSONRoundTrip(error)
        precondition(decoded.description == error.description)
    }
}

func testMarketplaceKitErrorAssociatedValues() {
    switch MarketplaceKitError.missingCapabilities(["gpu"]) {
    case .missingCapabilities(let names):
        precondition(names == ["gpu"])
    default:
        preconditionFailure("missingCapabilities associated value")
    }
    switch MarketplaceKitError.minimumPlatformVersionNotSatisfied("17.4") {
    case .minimumPlatformVersionNotSatisfied(let version):
        precondition(version == "17.4")
    default:
        preconditionFailure("minimumPlatformVersionNotSatisfied associated value")
    }
    switch MarketplaceKitError.insufficientStorageSpace(
        Measurement(value: 2, unit: UnitInformationStorage.kilobytes)
    ) {
    case .insufficientStorageSpace(let amount):
        precondition(amount.converted(to: .bytes).value == 2000)
    default:
        preconditionFailure("insufficientStorageSpace associated value")
    }
}

func testMarketplaceKitErrorDescriptions() {
    precondition(
        MarketplaceKitError.unsupportedPlatform.description
            == "The requested install does not run on this device's platform."
    )
    precondition(
        MarketplaceKitError.featureUnavailable.description
            == "The requested feature is unavailable."
    )
    precondition(
        MarketplaceKitError.cancelled.description == "The operation was cancelled."
    )
    precondition(
        MarketplaceKitError.invalidURL.description
            == "A URL required by the operation is invalid."
    )
}
