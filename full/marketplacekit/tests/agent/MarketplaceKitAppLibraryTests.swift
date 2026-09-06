import Foundation
import MarketplaceKit

func testAppLibrarySingletonAndEmptyState() {
    let library = AppLibrary.current
    precondition(library === AppLibrary.current)
    precondition(!library.isLoading)
    precondition(library.maximumAllowedAgeRating == 0)
    precondition(library.installedApps.isEmpty)
    precondition(library.installingApps.isEmpty)
}

func testAppLibraryAppIdentity() {
    let library = AppLibrary.current
    let first = library.app(forAppleItemID: 555)
    let again = library.app(forAppleItemID: 555)
    let other = library.app(forAppleItemID: 556)
    precondition(first === again)
    precondition(first.id == 555)
    precondition(first == again)
    precondition(first != other)
    precondition(first.hashValue == again.hashValue)
    var hasher = Hasher()
    first.hash(into: &hasher)
    var hasher2 = Hasher()
    again.hash(into: &hasher2)
    precondition(hasher.finalize() == hasher2.finalize())
    let id: AppLibrary.App.ID = first.id
    precondition(id == 555)
    precondition(!first.isInstalled)
    precondition(!first.isInstalling)
    precondition(!first.isUpdating)
    precondition(first.installedMetadata == nil)
    precondition(first.installation == nil)
    precondition(first.installationError == nil)
}

func testAppLibraryAppMetadataEquality() {
    let meta = AppLibrary.App.Metadata(
        appleVersionID: 9,
        version: "9.0",
        shortVersion: "9.0",
        account: "acct"
    )
    let same = AppLibrary.App.Metadata(
        appleVersionID: 9,
        version: "9.0",
        shortVersion: "9.0",
        account: "acct"
    )
    let different = AppLibrary.App.Metadata(
        appleVersionID: 8,
        version: "8.0",
        shortVersion: "8.0",
        account: nil
    )
    precondition(meta == same)
    precondition(meta != different)
    precondition(meta.appleVersionID == 9)
    precondition(meta.version == "9.0")
    precondition(meta.shortVersion == "9.0")
    precondition(meta.account == "acct")
}

func testAppLibraryInstallationProgress() {
    let progress = Progress(totalUnitCount: 100)
    progress.completedUnitCount = 25
    let installation = AppLibrary.App.Installation(progress: progress)
    precondition(installation.progress.totalUnitCount == 100)
    precondition(installation.progress.completedUnitCount == 25)
    let app = AppLibrary.current.app(forAppleItemID: 777)
    app.installation = installation
    app.installationError = .networkError
    precondition(app.isInstalling)
    precondition(!app.isUpdating)
    precondition(app.installationError?.description == MarketplaceKitError.networkError.description)
    app.installedMetadata = AppLibrary.App.Metadata(
        appleVersionID: 1,
        version: "1",
        shortVersion: "1.0",
        account: nil
    )
    precondition(app.isInstalled)
    precondition(app.isUpdating)
}

func testAppLibraryInstalledAppsMutation() {
    let library = AppLibrary.current
    let previousInstalled = library.installedApps
    let previousInstalling = library.installingApps
    let app = library.app(forAppleItemID: 1)
    library.installedApps = [app]
    precondition(library.installedApps.contains(app))
    library.installingApps = [app]
    precondition(library.installingApps.count == 1)
    library.installedApps = previousInstalled
    library.installingApps = previousInstalling
}

func testAppLibraryInstallationRequest() {
    let url = URL(string: "https://cdn.example.invalid/pkg")!
    var request = AppLibrary.InstallationRequest(
        alternativeDistributionPackageURL: url,
        account: "acct",
        installVerificationToken: "tok"
    )
    precondition(request.alternativeDistributionPackageURL == url)
    precondition(request.account == "acct")
    precondition(request.installVerificationToken == "tok")
    precondition(request.appShareURL == nil)
    let share = URL(string: "https://example.invalid/app")!
    request.appShareURL = share
    precondition(request.appShareURL == share)
}
