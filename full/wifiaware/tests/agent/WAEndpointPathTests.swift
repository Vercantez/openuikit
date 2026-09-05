@_spi(OpenUIKitHost) import WiFiAware
import Foundation

private func waExpect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

private func sampleDevice() -> WAPairedDevice {
    try! JSONDecoder().decode(
        WAPairedDevice.self,
        from: Data(#"{"id":1,"name":"A","pairingInfo":null}"#.utf8)
    )
}

private func samplePublishable() -> WAPublishableService {
    try! JSONDecoder().decode(
        WAPublishableService.self,
        from: Data(#"{"name":"_demo._tcp"}"#.utf8)
    )
}

private func sampleSubscribable() -> WASubscribableService {
    try! JSONDecoder().decode(
        WASubscribableService.self,
        from: Data(#"{"name":"_demo-sub._tcp"}"#.utf8)
    )
}

func testEndpointSPIIdentity() {
    let device = sampleDevice()
    let service = samplePublishable()
    let endpoint = WAEndpoint(device: device, publishedService: service)
    waExpect(endpoint.device == device, "endpoint device")
    waExpect(endpoint.publishedService == service, "endpoint published")
    waExpect(endpoint.subscribedService == nil, "endpoint subscribed nil")
    waExpect(endpoint.description.contains("A"), "endpoint description")
    let endpoint2 = WAEndpoint(device: device, subscribedService: sampleSubscribable())
    waExpect(endpoint == endpoint, "endpoint ==")
    waExpect(endpoint != endpoint2, "endpoint !=")
    var hasher = Hasher()
    endpoint.hash(into: &hasher)
    _ = hasher.finalize()
    _ = endpoint.hashValue
    let _: WAEndpoint = endpoint
}

func testPathSPIIdentity() {
    let endpoint = WAEndpoint(device: sampleDevice(), publishedService: samplePublishable())
    let report = WAPerformanceReport(
        timestamp: Date(timeIntervalSince1970: 1),
        localTimestamp: ContinuousClock.now,
        throughputCeiling: 100,
        throughputCapacity: 40,
        transmitLatency: [:],
        signalStrength: nil
    )
    let path = WAPath(
        endpoint: endpoint,
        performance: report,
        durationActive: .seconds(3)
    )
    waExpect(path.endpoint == endpoint, "path endpoint")
    waExpect(path.performance.throughputCeiling == 100, "path performance")
    waExpect(path.durationActive == .seconds(3), "path duration")
    let _: WAPath = path
}
