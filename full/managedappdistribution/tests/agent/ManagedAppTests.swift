import Foundation
@_spi(OpenUIKitHost) import ManagedAppDistribution

private func sampleApp(id: String = "com.example.app", name: String = "Example") -> ManagedApp {
    ManagedApp(
        id: id,
        name: name,
        platform: .iOS,
        fileSize: Measurement(value: 12, unit: UnitInformationStorage.megabytes),
        metadataLanguage: Locale.Language(identifier: "en"),
        subtitle: "Subtitle",
        seller: "Example Seller",
        genres: ["Productivity"],
        description: "A managed app",
        languages: [Locale.Language(identifier: "en"), Locale.Language(identifier: "es")],
        requirements: "Requires iOS 17.2",
        version: "1.2.3",
        releaseDate: Date(timeIntervalSince1970: 1_700_000_000),
        releaseNotes: "Bug fixes",
        contentRating: "4+",
        developerWebsite: URL(string: "https://example.invalid"),
        privacyPolicy: URL(string: "https://example.invalid/privacy"),
        licenseAgreement: URL(string: "https://example.invalid/license"),
        copyright: "Copyright Example"
    )
}

func testManagedAppStoresMetadata() {
    let app = sampleApp()
    precondition(app.name == "Example")
    precondition(app.subtitle == "Subtitle")
    precondition(app.seller == "Example Seller")
    precondition(app.genres == ["Productivity"])
    precondition(app.description == "A managed app")
    precondition(app.requirements == "Requires iOS 17.2")
    precondition(app.version == "1.2.3")
    precondition(app.releaseNotes == "Bug fixes")
    precondition(app.contentRating == "4+")
    precondition(app.copyright == "Copyright Example")
}

func testManagedAppIdentifiable() {
    let app = sampleApp(id: "com.example.ident")
    precondition(app.id == "com.example.ident")
    let typed: ManagedApp.ID = app.id
    precondition(typed == "com.example.ident")
}

func testManagedAppEquality() {
    let a = sampleApp()
    let b = sampleApp()
    let c = sampleApp(id: "com.example.other")
    precondition(a == b)
    precondition(a != c)
}

func testManagedAppHash() {
    let a = sampleApp()
    let b = sampleApp()
    precondition(a.hashValue == b.hashValue)
    var hasher = Hasher()
    a.hash(into: &hasher)
    _ = hasher.finalize()
}

func testManagedAppInequalityOperator() {
    let a = sampleApp(id: "a")
    let b = sampleApp(id: "b")
    precondition(a != b)
    precondition(!(a != sampleApp(id: "a")))
}

func testManagedAppPlatformProperty() {
    let app = sampleApp()
    precondition(app.platform == Platform.iOS)
    precondition(app.platform.description == "iOS")
}

func testManagedAppFileSize() {
    let app = sampleApp()
    precondition(app.fileSize?.value == 12)
    precondition(app.fileSize?.unit == UnitInformationStorage.megabytes)
}

func testManagedAppURLs() {
    let app = sampleApp()
    precondition(app.developerWebsite?.absoluteString == "https://example.invalid")
    precondition(app.privacyPolicy?.absoluteString == "https://example.invalid/privacy")
    precondition(app.licenseAgreement?.absoluteString == "https://example.invalid/license")
}

func testManagedAppLanguages() {
    let app = sampleApp()
    precondition(app.languages.count == 2)
    precondition(app.metadataLanguage != nil)
}

func testManagedAppReleaseDate() {
    let app = sampleApp()
    precondition(app.releaseDate == Date(timeIntervalSince1970: 1_700_000_000))
}

func testManagedAppIconURLFailClosed() {
    let app = sampleApp()
    precondition(app.iconURL(fitting: CGSize(width: 64, height: 64)) == nil)
}

func testManagedAppIconURLHostInstall() {
    var app = sampleApp()
    let url = URL(string: "https://example.invalid/icon.png")!
    let size = CGSize(width: 120, height: 120)
    app._installIconURL(url, fitting: size)
    precondition(app.iconURL(fitting: size) == url)
    precondition(app.iconURL(fitting: CGSize(width: 64, height: 64)) == nil)
}

func testManagedAppScreenshotURLsFailClosed() {
    let app = sampleApp()
    precondition(app.screenshotURLs(fitting: CGSize(width: 320, height: 568)).isEmpty)
}

func testManagedAppScreenshotURLsHostInstall() {
    var app = sampleApp()
    let urls = [URL(string: "https://example.invalid/s1.png")!]
    let size = CGSize(width: 320, height: 568)
    app._installScreenshotURLs(urls, fitting: size)
    precondition(app.screenshotURLs(fitting: size) == urls)
    precondition(app.screenshotURLs(fitting: CGSize(width: 1, height: 1)).isEmpty)
}
