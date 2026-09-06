import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import MarketplaceKit

func marketplaceKitJSONRoundTrip<T: Codable>(_ value: T) -> T {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    let data = try! encoder.encode(value)
    return try! decoder.decode(T.self, from: data)
}

struct MarketplaceKitProbeExtension: MarketplaceExtension {}

struct MarketplaceKitProbeAppExtension: MarketplaceAppExtension {}

final class MarketplaceKitProbeSceneDelegate: MarketplaceSceneDelegate {
    var lastOption: MarketplaceDisplayOption?
    var lastScene: UIWindowScene?

    func scene(_ scene: UIWindowScene, askedToDisplay option: MarketplaceDisplayOption) {
        lastScene = scene
        lastOption = option
    }
}

func testMarketplaceKitSupportHelpersExist() {
    _ = MarketplaceKitProbeExtension()
    _ = MarketplaceKitProbeSceneDelegate()
}
