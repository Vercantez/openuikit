@_spi(OpenUIKitHost) import WiFiAware
import Foundation

private func waExpect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testCapabilitiesFailClosed() {
    waExpect(WACapabilities.supportedFeatures.isEmpty, "Linux has no NAN radio")
    waExpect(WACapabilities.maximumConnectableDevices == 0, "no connectable devices")
    waExpect(WACapabilities.maximumPublishableServices == 0, "no publishable services")
    waExpect(WACapabilities.maximumSubscribableServices == 0, "no subscribable services")
    let _: WACapabilities.Type = WACapabilities.self
}

func testFeatureCases() {
    let cases = WACapabilities.Feature.allCases
    waExpect(cases == [.wifiAware], "Feature.allCases")
    let _: WACapabilities.Feature.AllCases = cases
    waExpect(WACapabilities.Feature.wifiAware == .wifiAware, "Feature ==")
    waExpect(!(WACapabilities.Feature.wifiAware != .wifiAware), "Feature !=")
    var hasher = Hasher()
    WACapabilities.Feature.wifiAware.hash(into: &hasher)
    _ = hasher.finalize()
    let hashed = WACapabilities.Feature.wifiAware.hashValue
    waExpect(hashed == WACapabilities.Feature.wifiAware.hashValue, "Feature.hashValue stable")
    let data = try! JSONEncoder().encode(WACapabilities.Feature.wifiAware)
    let decoded = try! JSONDecoder().decode(WACapabilities.Feature.self, from: data)
    waExpect(decoded == .wifiAware, "Feature Codable")
}
