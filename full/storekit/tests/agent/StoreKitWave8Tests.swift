import Foundation
import StoreKit

private func expectWave8(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testStoreDownloaderExtensionProtocol() {
    struct Wave8Downloader: StoreDownloaderExtension {}
    func acceptsDownloader(_ value: some StoreDownloaderExtension) -> Bool {
        _ = value
        return true
    }
    expectWave8(acceptsDownloader(Wave8Downloader()), "StoreDownloaderExtension conformance")
    expectWave8(
        Wave8Downloader() is any StoreDownloaderExtension,
        "StoreDownloaderExtension existential"
    )
    _ = Wave8Downloader.self
}

func testSubscriptionUnitFormatStyleInequality() {
    let first = Product.SubscriptionPeriod.Unit.FormatStyle()
    let second = Product.SubscriptionPeriod.Unit.FormatStyle()
    expectWave8(!(first != second), "unit FormatStyle values are all equal")
    expectWave8(first == second, "unit FormatStyle equality")
}
