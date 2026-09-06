import Foundation
import MarketplaceKit

// Isolated host-gate success against toolchain Foundation is not integrated
// guest-Foundation success. This probe is for a future clean EC2 run that
// builds guest Foundation first, then MarketplaceKit with that `-I` / `-L`.
// The host gate does not compile this file.

func marketplaceKitDependencyIdentityProbe() {
    let data = Data("marketplace-kit".utf8)
    let url = URL(string: "https://cdn.example.invalid/package")!
    let measurement = Measurement(value: Double(data.count), unit: UnitInformationStorage.bytes)
    precondition(type(of: data) == Data.self)
    precondition(type(of: url) == URL.self)
    precondition(type(of: measurement) == Measurement<UnitInformationStorage>.self)
    precondition(!String(reflecting: type(of: data)).hasPrefix("MarketplaceKit."))
    precondition(!String(reflecting: type(of: url)).hasPrefix("MarketplaceKit."))

    let version = AppVersion(appleItemID: 1, appleVersionID: UInt64(data.count))
    precondition(version.appleItemID == 1)

    var request = AppLibrary.InstallationRequest(
        alternativeDistributionPackageURL: url,
        account: String(data: data, encoding: .utf8) ?? "",
        installVerificationToken: "probe"
    )
    request.appShareURL = url
    precondition(request.alternativeDistributionPackageURL == url)
    precondition(request.appShareURL == url)

    let error = MarketplaceKitError.insufficientStorageSpace(measurement)
    precondition(!error.description.isEmpty)
}

#if MARKETPLACEKIT_IDENTITY_MAIN
marketplaceKitDependencyIdentityProbe()
print("MARKETPLACEKIT_DEPENDENCY_IDENTITY_OK")
#endif
