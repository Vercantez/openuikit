import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import MarketplaceKit

func testMarketplaceAppExtensionAsyncDefaults() async {
    let probe = MarketplaceKitProbeAppExtension()
    let request = URLRequest(url: URL(string: "https://api.example.invalid/headers")!)
    let headers = await probe.additionalHeaders(for: request, account: "acct")
    precondition(headers.isEmpty)
    let versions = await probe.availableAppVersions(forAppleItemIDs: [1, 2])
    precondition(versions.isEmpty)
    let url = URL(string: "https://api.example.invalid/v1")!
    let ok = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: nil)!
    let missing = HTTPURLResponse(url: url, statusCode: 404, httpVersion: "HTTP/1.1", headerFields: nil)!
    let okFailed = await probe.requestFailed(response: ok)
    let missingFailed = await probe.requestFailed(response: missing)
    precondition(okFailed == false)
    precondition(missingFailed == true)
}

func testMarketplaceAppExtensionAutomaticUpdatesThrows() async {
    let probe = MarketplaceKitProbeAppExtension()
    let installed = [AppVersion(appleItemID: 1, appleVersionID: 2)]
    do {
        _ = try await probe.automaticUpdates(for: installed)
        preconditionFailure("automaticUpdates should throw")
    } catch let error as MarketplaceKitError {
        precondition(error.description == MarketplaceKitError.featureUnavailable.description)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}

func testMarketplaceExtensionAutomaticUpdatesThrows() async {
    let probe = MarketplaceKitProbeExtension()
    let installed = [AppVersion(appleItemID: 3, appleVersionID: 4)]
    do {
        _ = try await probe.automaticUpdates(for: installed)
        preconditionFailure("automaticUpdates should throw")
    } catch let error as MarketplaceKitError {
        precondition(error.description == MarketplaceKitError.featureUnavailable.description)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}

func testAppLibraryInstallRequestsFailClosed() async {
    let library = AppLibrary.current
    let package = URL(string: "https://cdn.example.invalid/pkg")!
    let badScheme = URL(string: "ftp://cdn.example.invalid/pkg")!
    let request = AppLibrary.InstallationRequest(
        alternativeDistributionPackageURL: package,
        account: "acct",
        installVerificationToken: "tok"
    )
    do {
        try await library.requestAppInstallation(for: package, account: "acct", installVerificationToken: "tok")
        preconditionFailure("requestAppInstallation should throw")
    } catch let error as MarketplaceKitError {
        precondition(error.description == MarketplaceKitError.unsupportedPlatform.description)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
    do {
        try await library.requestAppInstallation(for: badScheme, account: "acct", installVerificationToken: "tok")
        preconditionFailure("requestAppInstallation should throw")
    } catch let error as MarketplaceKitError {
        precondition(error.description == MarketplaceKitError.invalidURL.description)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
    do {
        try await library.requestAppInstallation(request)
        preconditionFailure("requestAppInstallation should throw")
    } catch let error as MarketplaceKitError {
        precondition(error.description == MarketplaceKitError.unsupportedPlatform.description)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
    do {
        try await library.requestAppInstallationFromBrowser(for: package, referrer: package)
        preconditionFailure("requestAppInstallationFromBrowser should throw")
    } catch is MarketplaceKitError {
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
    do {
        try await library.requestAppUpdate(for: package, account: "acct", installVerificationToken: "tok")
        preconditionFailure("requestAppUpdate should throw")
    } catch let error as MarketplaceKitError {
        precondition(error.description == MarketplaceKitError.unsupportedPlatform.description)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
    do {
        try await library.requestAppUpdate(request)
        preconditionFailure("requestAppUpdate should throw")
    } catch let error as MarketplaceKitError {
        precondition(error.description == MarketplaceKitError.unsupportedPlatform.description)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}

func testAppLibraryAgeSheetLicenseAndExceptionRequests() async {
    let library = AppLibrary.current
    let app = library.app(forAppleItemID: 4242)
    do {
        try await app.presentAgeExceptionApproveInPersonSheet()
        preconditionFailure("presentAgeExceptionApproveInPersonSheet should throw")
    } catch let error as MarketplaceKitError {
        precondition(error.description == MarketplaceKitError.featureUnavailable.description)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
    do {
        try await library.requestLicenseRenewal(appleItemIDs: [4242])
        preconditionFailure("requestLicenseRenewal should throw")
    } catch let error as MarketplaceKitError {
        precondition(error.description == MarketplaceKitError.invalidLicense.description)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
    do {
        let requests = try await library.currentAgeExceptionRequests()
        precondition(requests.isEmpty)
    } catch {
        preconditionFailure("currentAgeExceptionRequests should not throw: \(error)")
    }
}

func testAppLibraryTerritoryAndAuthentication() async {
    let library = AppLibrary.current
    let previous = await library.searchTerritory
    await library.setSearchTerritory("US")
    let stored = await library.searchTerritory
    precondition(stored == "US")
    await library.setSearchTerritory(previous)
    let restored = await library.searchTerritory
    precondition(restored == previous)
    await library.didAuthenticate(account: "acct")
}

func testAppDistributorCurrentThrows() async {
    do {
        _ = try await AppDistributor.current
        preconditionFailure("AppDistributor.current should throw")
    } catch let error as MarketplaceKitError {
        precondition(error.description == MarketplaceKitError.unsupportedPlatform.description)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}

func testTransactionReportingTokenThrows() async {
    do {
        _ = try await TransactionReporting.token(for: .coreTechnology)
        preconditionFailure("TransactionReporting.token should throw")
    } catch let error as MarketplaceKitError {
        precondition(error.description == MarketplaceKitError.featureUnavailable.description)
    } catch {
        preconditionFailure("unexpected error \(error)")
    }
}
