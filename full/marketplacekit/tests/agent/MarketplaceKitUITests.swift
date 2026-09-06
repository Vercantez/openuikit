import Foundation
import MarketplaceKit

func testMarketplaceKitURIScheme() {
    precondition(MarketplaceKitURIScheme == "marketplace-kit")
    let url = URL(string: "\(MarketplaceKitURIScheme)://install?account=a")!
    precondition(url.scheme == MarketplaceKitURIScheme)
    precondition(url.host == "install")
}

func testActionButtonImagePlacementRawValues() {
    precondition(ActionButton.ButtonImagePlacement.top.rawValue == 0)
    precondition(ActionButton.ButtonImagePlacement.leading.rawValue == 1)
    precondition(ActionButton.ButtonImagePlacement.bottom.rawValue == 2)
    precondition(ActionButton.ButtonImagePlacement.trailing.rawValue == 3)
    precondition(ActionButton.ButtonImagePlacement(rawValue: 0) == .top)
    precondition(ActionButton.ButtonImagePlacement(rawValue: 1) == .leading)
    precondition(ActionButton.ButtonImagePlacement(rawValue: 2) == .bottom)
    precondition(ActionButton.ButtonImagePlacement(rawValue: 3) == .trailing)
    precondition(ActionButton.ButtonImagePlacement(rawValue: 4) == nil)
    precondition(ActionButton.ButtonImagePlacement.top != .bottom)
    var hasher = Hasher()
    ActionButton.ButtonImagePlacement.leading.hash(into: &hasher)
    _ = hasher.finalize()
    precondition(
        ActionButton.ButtonImagePlacement.top.hashValue
            == ActionButton.ButtonImagePlacement(rawValue: 0)!.hashValue
    )
    let raw: ActionButton.ButtonImagePlacement.RawValue = ActionButton.ButtonImagePlacement.trailing.rawValue
    precondition(raw == 3)
}

func testActionButtonStoresActionAndStyle() {
    let metadata = InstallMetadata(
        account: "acct",
        appleItemID: 10,
        alternativeDistributionPackage: URL(string: "https://cdn.example.invalid/p")!,
        isUpdate: false
    )
    let configuration = InstallConfiguration(install: metadata) { .cancel }
    let button = ActionButton(action: .install(configuration))
    switch button.action {
    case .install(let stored):
        precondition(stored.install.appleItemID == 10)
    default:
        preconditionFailure("install action")
    }
    precondition(button.label == "")
    button.label = "GET"
    precondition(button.label == "GET")
    precondition(button.imageName == nil)
    button.imageName = "download"
    precondition(button.imageName == "download")
    precondition(button.imagePlacement == .leading)
    button.imagePlacement = .trailing
    precondition(button.imagePlacement == .trailing)
    precondition(button.size == .zero)
    button.size = CGSize(width: 120, height: 36)
    precondition(button.size.width == 120)
    precondition(button.size.height == 36)
    precondition(button.fontSize == 0)
    button.fontSize = 15
    precondition(button.fontSize == 15)
    precondition(button.cornerRadius == 0)
    button.cornerRadius = 8
    precondition(button.cornerRadius == 8)
    precondition(button.borderWidth == 0)
    button.borderWidth = 1
    precondition(button.borderWidth == 1)
    button.borderColor = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
    precondition(button.borderColor.red == 1)
    button.isEnabled = false
    precondition(!button.isEnabled)
    button.isHighlighted = true
    precondition(button.isHighlighted)
    button.backgroundColor = UIColor.clear
    precondition(button.backgroundColor?.alpha == 0)
    button.tintColor = UIColor.black
    precondition(button.tintColor.red == 0)
}

func testActionButtonLaunchDeleteBatchCases() {
    let launch = ActionButton(action: .launch(44))
    switch launch.action {
    case .launch(let item):
        precondition(item == 44)
    default:
        preconditionFailure("launch")
    }
    let delete = ActionButton(action: .delete(45))
    switch delete.action {
    case .delete(let item):
        precondition(item == 45)
    default:
        preconditionFailure("delete")
    }
    let metadata = InstallMetadata(
        account: "a",
        appleItemID: 1,
        alternativeDistributionPackage: URL(string: "https://cdn.example.invalid/x")!,
        isUpdate: true,
        appShareURL: URL(string: "https://example.invalid/s"),
        requestAgeException: true
    )
    let batch = BatchInstallConfiguration(installs: [metadata]) { .cancel }
    let button = ActionButton(action: .batchInstall(batch))
    switch button.action {
    case .batchInstall(let stored):
        precondition(stored.installs.count == 1)
        precondition(stored.installs[0].isUpdate)
        precondition(stored.installs[0].requestAgeException)
        let confirm = stored.confirmInstall
        _ = confirm
    default:
        preconditionFailure("batchInstall")
    }
}

func testInstallMetadataInits() {
    let package = URL(string: "https://cdn.example.invalid/pkg")!
    let short = InstallMetadata(
        account: "acct",
        appleItemID: 3,
        alternativeDistributionPackage: package,
        isUpdate: false
    )
    precondition(short.account == "acct")
    precondition(short.appleItemID == 3)
    precondition(short.alternativeDistributionPackage == package)
    precondition(!short.isUpdate)
    precondition(short.appShareURL == nil)
    precondition(!short.requestAgeException)
    var full = InstallMetadata(
        account: "acct2",
        appleItemID: 4,
        alternativeDistributionPackage: package,
        isUpdate: true,
        appShareURL: URL(string: "https://example.invalid/share"),
        requestAgeException: false
    )
    precondition(full.isUpdate)
    precondition(full.appShareURL?.host == "example.invalid")
    precondition(!full.requestAgeException)
    full.requestAgeException = true
    full.appShareURL = nil
    precondition(full.requestAgeException)
    precondition(full.appShareURL == nil)
}

func testInstallConfigurationStoresClosure() {
    let metadata = InstallMetadata(
        account: "a",
        appleItemID: 9,
        alternativeDistributionPackage: URL(string: "https://cdn.example.invalid/z")!,
        isUpdate: false
    )
    let configuration = InstallConfiguration(install: metadata) {
        .confirmed(installVerificationToken: "tok", authenticationContext: nil)
    }
    precondition(configuration.install.appleItemID == 9)
    let stored = configuration.confirmInstall
    _ = stored
}

func testInstallConfirmationResultCases() {
    switch InstallConfirmationResult.cancel {
    case .cancel:
        break
    default:
        preconditionFailure("cancel")
    }
    let context = LAContext()
    switch InstallConfirmationResult.confirmed(
        installVerificationToken: "ivt",
        authenticationContext: context
    ) {
    case .confirmed(let token, let stored):
        precondition(token == "ivt")
        precondition(stored === context)
    default:
        preconditionFailure("confirmed")
    }
}

func testBatchInstallConfirmationEquality() {
    precondition(BatchInstallConfirmationResult.cancel == .cancel)
    let left = BatchInstallConfirmationResult.confirmed(
        installVerificationTokens: [1: "a", 2: "b"],
        authenticationContext: nil
    )
    let right = BatchInstallConfirmationResult.confirmed(
        installVerificationTokens: [1: "a", 2: "b"],
        authenticationContext: nil
    )
    precondition(left == right)
    precondition(left != .cancel)
    let different = BatchInstallConfirmationResult.confirmed(
        installVerificationTokens: [1: "z"],
        authenticationContext: nil
    )
    precondition(left != different)
}

func testMarketplaceDisplayOptionCodable() {
    let product = MarketplaceDisplayOption.productPage(appleItemID: 12, appleVersionID: 3)
    let search = MarketplaceDisplayOption.searchResults(query: "maps")
    let auth = MarketplaceDisplayOption.authentication(account: "user")
    switch product {
    case .productPage(let item, let version):
        precondition(item == 12)
        precondition(version == 3)
    default:
        preconditionFailure("productPage")
    }
    switch search {
    case .searchResults(let query):
        precondition(query == "maps")
    default:
        preconditionFailure("searchResults")
    }
    switch auth {
    case .authentication(let account):
        precondition(account == "user")
    default:
        preconditionFailure("authentication")
    }
    let decodedProduct = marketplaceKitJSONRoundTrip(product)
    precondition(decodedProduct == product)
    let decodedSearch = marketplaceKitJSONRoundTrip(search)
    precondition(decodedSearch == search)
    let decodedAuth = marketplaceKitJSONRoundTrip(auth)
    precondition(decodedAuth == auth)
}

func testMarketplaceSceneDelegateAskedToDisplay() {
    let delegate = MarketplaceKitProbeSceneDelegate()
    let scene = UIWindowScene()
    let option = MarketplaceDisplayOption.searchResults(query: "news")
    delegate.scene(scene, askedToDisplay: option)
    precondition(delegate.lastScene === scene)
    precondition(delegate.lastOption == option)
}

func testUISceneConnectionOptionsHaveNoDisplayOption() {
    let options = UIScene.ConnectionOptions()
    precondition(options.marketplaceDisplayOption == nil)
}
