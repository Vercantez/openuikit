import Foundation
import MarketplaceKit

func testAppleItemIDAlias() {
    let item: AppleItemID = 1_234_567_890
    precondition(item == UInt64(1_234_567_890))
    let version: AppleVersionID = 99
    precondition(version == UInt64(99))
}

func testAppVersionInitAndDescription() {
    let version = AppVersion(appleItemID: 42, appleVersionID: 7)
    precondition(version.appleItemID == 42)
    precondition(version.appleVersionID == 7)
    precondition(version.description == "42:7")
    precondition(String(describing: version) == "42:7")
}

func testAutomaticUpdateStoresFields() {
    let package = URL(string: "https://cdn.example.invalid/app.pkg")!
    var update = AutomaticUpdate(
        appleItemID: 100,
        alternativeDistributionPackage: package,
        account: "user-1",
        installVerificationToken: "token-1"
    )
    precondition(update.appleItemID == 100)
    precondition(update.alternativeDistributionPackage == package)
    precondition(update.account == "user-1")
    precondition(update.installVerificationToken == "token-1")
    precondition(update.appShareURL == nil)
    let share = URL(string: "https://example.invalid/share")!
    update.appShareURL = share
    precondition(update.appShareURL == share)
}

func testTransactionReportingTokenType() {
    let token = TransactionReporting.TokenType.coreTechnology
    precondition(token.rawValue == "coreTechnology")
    let custom = TransactionReporting.TokenType(rawValue: "custom.token")
    precondition(custom.rawValue == "custom.token")
    precondition(custom != token)
    let alias: TransactionReporting.TokenType.RawValue = token.rawValue
    precondition(alias == "coreTechnology")
}
