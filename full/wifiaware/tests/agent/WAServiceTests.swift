@_spi(OpenUIKitHost) import WiFiAware
import Foundation

private func waExpect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testPublishableService() {
    waExpect(WAPublishableService.allServices.isEmpty, "no Info.plist publish inventory")
    let published = try! JSONDecoder().decode(
        WAPublishableService.self,
        from: Data(#"{"name":"_openuikit._tcp"}"#.utf8)
    )
    waExpect(published.name == "_openuikit._tcp", "publishable name")
    let id: WAPublishableService.ID = published.id
    waExpect(id == published.name, "publishable id is the name")
    waExpect(published.description.contains("_openuikit._tcp"), "publishable description")
    waExpect(published == published, "publishable ==")
    waExpect(published != WAPublishableService(name: "other"), "publishable !=")
    var hasher = Hasher()
    published.hash(into: &hasher)
    _ = hasher.finalize()
    _ = published.hashValue
    let encoded = try! JSONEncoder().encode(published)
    let decoded = try! JSONDecoder().decode(WAPublishableService.self, from: encoded)
    waExpect(decoded == published, "publishable Codable")
}

func testSubscribableService() {
    waExpect(WASubscribableService.allServices.isEmpty, "no Info.plist subscribe inventory")
    let subscribed = try! JSONDecoder().decode(
        WASubscribableService.self,
        from: Data(#"{"name":"_openuikit-sub._tcp"}"#.utf8)
    )
    waExpect(subscribed.name == "_openuikit-sub._tcp", "subscribable name")
    let id: WASubscribableService.ID = subscribed.id
    waExpect(id == subscribed.name, "subscribable id is the name")
    waExpect(subscribed.description.contains("_openuikit-sub._tcp"), "subscribable description")
    waExpect(subscribed == subscribed, "subscribable ==")
    waExpect(subscribed != WASubscribableService(name: "other"), "subscribable !=")
    var hasher = Hasher()
    subscribed.hash(into: &hasher)
    _ = hasher.finalize()
    _ = subscribed.hashValue
    let encoded = try! JSONEncoder().encode(subscribed)
    let decoded = try! JSONDecoder().decode(WASubscribableService.self, from: encoded)
    waExpect(decoded == subscribed, "subscribable Codable")
}

func testWAServiceProtocol() {
    let published = WAPublishableService(name: "_svc._tcp")
    let asService: any WAService = published
    waExpect(asService.name == published.name, "WAService.name")
    waExpect(type(of: asService).allServices.isEmpty, "WAService.allServices empty")
}
