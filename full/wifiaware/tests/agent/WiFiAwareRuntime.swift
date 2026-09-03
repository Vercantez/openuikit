@_spi(OpenUIKitHost) import WiFiAware
import Foundation

private func require(_ condition: Bool, _ message: String) {
    if !condition {
        fatalError(message)
    }
}

private func emptyJSON() -> Data { Data("{}".utf8) }

private func decodeEmpty<T: Decodable>(_ type: T.Type) throws -> T {
    try JSONDecoder().decode(type, from: emptyJSON())
}

private func roundTrip<T: Codable & Equatable>(_ value: T) throws {
    let data = try JSONEncoder().encode(value)
    let decoded = try JSONDecoder().decode(T.self, from: data)
    require(decoded == value, "Codable round-trip mismatch for \(T.self)")
}

private func roundTripEmptyDetails<T: Codable>(_ value: T) throws {
    let data = try JSONEncoder().encode(value)
    _ = try JSONDecoder().decode(T.self, from: data)
    let text = String(data: data, encoding: .utf8) ?? ""
    require(text == "{}", "empty details must encode as {}; got \(text)")
}

private func exerciseCapabilities() {
    require(WACapabilities.supportedFeatures.isEmpty, "Linux must not claim NAN support")
    require(WACapabilities.maximumConnectableDevices == 0, "no connectable devices")
    require(WACapabilities.maximumPublishableServices == 0, "no publishable services")
    require(WACapabilities.maximumSubscribableServices == 0, "no subscribable services")
    require(WACapabilities.Feature.allCases == [.wifiAware], "Feature.allCases")
    require(WACapabilities.Feature.wifiAware == .wifiAware, "Feature equality")
    require(!(WACapabilities.Feature.wifiAware != .wifiAware), "Feature !=")
    var hasher = Hasher()
    WACapabilities.Feature.wifiAware.hash(into: &hasher)
    _ = hasher.finalize()
}

private func exerciseParameters() throws {
    require(WAParameters.defaults.performanceMode == .bulk, "defaults are bulk")
    require(WAParameters.realtime.performanceMode == .realtime, "realtime preset")
    var parameters = WAParameters()
    require(parameters.performanceMode == .bulk, "init default is bulk")
    parameters = WAParameters(performanceMode: .realtime)
    require(parameters.performanceMode == .realtime, "init(performanceMode:)")
    parameters.performanceMode = .bulk
    require(parameters.performanceMode == .bulk, "performanceMode is settable")
    require(WAPerformanceMode.allCases == [.bulk, .realtime], "performance allCases")
    require(WAAccessCategory.allCases == [
        .bestEffort, .background, .interactiveVideo, .interactiveVoice
    ], "access allCases")
    try roundTrip(WAPerformanceMode.bulk)
    try roundTrip(WAPerformanceMode.realtime)
    try roundTrip(WAAccessCategory.bestEffort)
    try roundTrip(WAAccessCategory.background)
    try roundTrip(WAAccessCategory.interactiveVideo)
    try roundTrip(WAAccessCategory.interactiveVoice)
    try roundTrip(WACapabilities.Feature.wifiAware)
    require(WAPerformanceMode.bulk != .realtime, "performance inequality")
    require(WAAccessCategory.bestEffort != .interactiveVoice, "access inequality")
}

private func exerciseErrors() throws {
    let unsupported = WAError.wifiAwareUnsupported(
        try decodeEmpty(WAError.WiFiAwareUnsupportedDetails.self)
    )
    let entitlement = WAError.entitlementMissing(
        try decodeEmpty(WAError.EntitlementMissingDetails.self)
    )
    let radio = WAError.noRadioResources(
        try decodeEmpty(WAError.NoRadioResourcesDetails.self)
    )
    let undeclared = WAError.serviceNotDeclared(
        try decodeEmpty(WAError.ServiceNotDeclaredDetails.self)
    )
    let alreadySub = WAError.serviceAlreadySubscribing(
        try decodeEmpty(WAError.ServiceAlreadySubscribingDetails.self)
    )
    let alreadyPub = WAError.serviceAlreadyPublishing(
        try decodeEmpty(WAError.ServiceAlreadyPublishingDetails.self)
    )
    let nonePaired = WAError.noPairedDevices(
        try decodeEmpty(WAError.NoPairedDevicesDetails.self)
    )
    let invalid = WAError.deviceInvalid(
        try decodeEmpty(WAError.DeviceInvalidDetails.self)
    )
    let gone = WAError.deviceNoLongerAvailable(
        try decodeEmpty(WAError.DeviceNoLongerAvailableDetails.self)
    )
    let pubTimeout = WAError.publisherTimeout(
        try decodeEmpty(WAError.PublisherTimeoutDetails.self)
    )
    let subTimeout = WAError.subscriberTimeout(
        try decodeEmpty(WAError.SubscriberTimeoutDetails.self)
    )
    let failed = WAError.connectionFailed(
        try decodeEmpty(WAError.ConnectionFailedDetails.self)
    )
    let idle = WAError.connectionIdleTimeout(
        try decodeEmpty(WAError.ConnectionIdleTimeoutDetails.self)
    )
    let terminated = WAError.connectionTerminated(
        try decodeEmpty(WAError.ConnectionTerminatedDetails.self)
    )
    let general = WAError.error(try decodeEmpty(WAError.ErrorDetails.self))

    func requireCase(_ error: WAError, _ match: (WAError) -> Bool, _ name: String) {
        require(match(error), "expected \(name)")
    }
    requireCase(unsupported, { if case .wifiAwareUnsupported = $0 { return true }; return false }, "unsupported")
    requireCase(entitlement, { if case .entitlementMissing = $0 { return true }; return false }, "entitlement")
    requireCase(radio, { if case .noRadioResources = $0 { return true }; return false }, "radio")
    requireCase(undeclared, { if case .serviceNotDeclared = $0 { return true }; return false }, "undeclared")
    requireCase(alreadySub, { if case .serviceAlreadySubscribing = $0 { return true }; return false }, "alreadySub")
    requireCase(alreadyPub, { if case .serviceAlreadyPublishing = $0 { return true }; return false }, "alreadyPub")
    requireCase(nonePaired, { if case .noPairedDevices = $0 { return true }; return false }, "nonePaired")
    requireCase(invalid, { if case .deviceInvalid = $0 { return true }; return false }, "invalid")
    requireCase(gone, { if case .deviceNoLongerAvailable = $0 { return true }; return false }, "gone")
    requireCase(pubTimeout, { if case .publisherTimeout = $0 { return true }; return false }, "pubTimeout")
    requireCase(subTimeout, { if case .subscriberTimeout = $0 { return true }; return false }, "subTimeout")
    requireCase(failed, { if case .connectionFailed = $0 { return true }; return false }, "failed")
    requireCase(idle, { if case .connectionIdleTimeout = $0 { return true }; return false }, "idle")
    requireCase(terminated, { if case .connectionTerminated = $0 { return true }; return false }, "terminated")
    requireCase(general, { if case .error = $0 { return true }; return false }, "error")

    let localized: any LocalizedError = unsupported
    require(localized.errorDescription == nil, "errorDescription unobserved")
    require(localized.failureReason == nil, "failureReason unobserved")
    require(localized.helpAnchor == nil, "helpAnchor unobserved")
    require(localized.recoverySuggestion == nil, "recoverySuggestion unobserved")
    require(!unsupported.localizedDescription.isEmpty, "Foundation localizedDescription")

    try roundTripEmptyDetails(try decodeEmpty(WAError.ErrorDetails.self))
    try roundTripEmptyDetails(try decodeEmpty(WAError.WiFiAwareUnsupportedDetails.self))
    try roundTripEmptyDetails(try decodeEmpty(WAError.EntitlementMissingDetails.self))
    try roundTripEmptyDetails(try decodeEmpty(WAError.NoRadioResourcesDetails.self))
    try roundTripEmptyDetails(try decodeEmpty(WAError.ServiceNotDeclaredDetails.self))
    try roundTripEmptyDetails(try decodeEmpty(WAError.ServiceAlreadySubscribingDetails.self))
    try roundTripEmptyDetails(try decodeEmpty(WAError.ServiceAlreadyPublishingDetails.self))
    try roundTripEmptyDetails(try decodeEmpty(WAError.NoPairedDevicesDetails.self))
    try roundTripEmptyDetails(try decodeEmpty(WAError.DeviceInvalidDetails.self))
    try roundTripEmptyDetails(try decodeEmpty(WAError.DeviceNoLongerAvailableDetails.self))
    try roundTripEmptyDetails(try decodeEmpty(WAError.PublisherTimeoutDetails.self))
    try roundTripEmptyDetails(try decodeEmpty(WAError.SubscriberTimeoutDetails.self))
    try roundTripEmptyDetails(try decodeEmpty(WAError.ConnectionFailedDetails.self))
    try roundTripEmptyDetails(try decodeEmpty(WAError.ConnectionIdleTimeoutDetails.self))
    try roundTripEmptyDetails(try decodeEmpty(WAError.ConnectionTerminatedDetails.self))

    let encoded = try JSONEncoder().encode(unsupported)
    let decoded = try JSONDecoder().decode(WAError.self, from: encoded)
    requireCase(decoded, { if case .wifiAwareUnsupported = $0 { return true }; return false }, "error round-trip")
}

private func exerciseServices() throws {
    require(WAPublishableService.allServices.isEmpty, "no Info.plist publish inventory")
    require(WASubscribableService.allServices.isEmpty, "no Info.plist subscribe inventory")
    let published = try JSONDecoder().decode(
        WAPublishableService.self,
        from: Data(#"{"name":"_openuikit._tcp"}"#.utf8)
    )
    require(published.name == "_openuikit._tcp", "publishable name")
    require(published.id == published.name, "publishable id is the name")
    require(published.description.contains("_openuikit._tcp"), "publishable description")
    try roundTrip(published)
    let subscribed = try JSONDecoder().decode(
        WASubscribableService.self,
        from: Data(#"{"name":"_openuikit-sub._tcp"}"#.utf8)
    )
    require(subscribed.name == "_openuikit-sub._tcp", "subscribable name")
    require(subscribed.id == subscribed.name, "subscribable id is the name")
    require(subscribed.description.contains("_openuikit-sub._tcp"), "subscribable description")
    require(subscribed != WASubscribableService(name: "other"), "subscribable inequality")
    try roundTrip(subscribed)
    let asService: any WAService = published
    require(asService.name == published.name, "WAService.name")
    require(type(of: asService).allServices.isEmpty, "WAService.allServices empty")
}

private func exercisePairedDevices() async throws {
    let json = Data(#"{"id":7,"name":"Lamp","pairingInfo":{"pairingName":"Lamp","vendorName":"Acme","modelName":"L1"}}"#.utf8)
    let device = try JSONDecoder().decode(WAPairedDevice.self, from: json)
    require(device.id == 7, "device id")
    require(device.name == "Lamp", "device name")
    require(device.pairingInfo?.pairingName == "Lamp", "pairingName")
    require(device.pairingInfo?.vendorName == "Acme", "vendorName")
    require(device.pairingInfo?.modelName == "L1", "modelName")
    require(device.description.contains("Lamp"), "device description")
    require(device.pairingInfo?.description.contains("Acme") == true, "pairing description")
    try roundTrip(device)
    let other = try JSONDecoder().decode(
        WAPairedDevice.self,
        from: Data(#"{"id":8,"name":null,"pairingInfo":null}"#.utf8)
    )
    require(device != other, "device inequality")
    require(Set([device, other]).count == 2, "device hash/set")

    let snapshot = try await WAPairedDevice.allDevices.current()
    require(snapshot == [:], "allDevices.current is empty")
    var yielded = 0
    for try await value in WAPairedDevice.allDevices {
        yielded += 1
        require(value.isEmpty, "sequence yields empty snapshot")
    }
    require(yielded == 1, "sequence yields once")
    var iterator = WAPairedDevice.allDevices.makeAsyncIterator()
    let first = try await iterator.next()
    require(first == [:], "iterator first")
    let second = try await iterator.next()
    require(second == nil, "iterator finishes")
    let isolated = try await iterator.next(isolation: nil)
    require(isolated == nil, "next(isolation:) after finish")

    let predicate = #Predicate<WAPairedDevice> { candidate in
        candidate.id == 7
    }
    let matching = try await WAPairedDevice.allDevices(matching: predicate).current()
    require(matching == [:], "matching inventory is still empty")

    let seq = WAPairedDevice.allDevices
    require(try await seq.contains([:]), "contains empty snapshot")
    require(try await seq.contains(where: { $0.isEmpty }), "contains(where:)")
    require(try await seq.allSatisfy({ $0.isEmpty }), "allSatisfy")
    require(try await seq.first(where: { $0.isEmpty }) == [:], "first(where:)")
    require(try await seq.min(by: { _, _ in true }) == [:], "min")
    require(try await seq.max(by: { _, _ in false }) == [:], "max")
    let reduced = try await seq.reduce(0) { partial, snapshot in
        partial + snapshot.count
    }
    require(reduced == 0, "reduce")
    let into = try await seq.reduce(into: 0) { partial, snapshot in
        partial += snapshot.count
    }
    require(into == 0, "reduce(into:)")
    var prefixCount = 0
    for try await _ in seq.prefix(2) {
        prefixCount += 1
    }
    require(prefixCount == 1, "prefix count")
    var dropCount = 0
    for try await _ in seq.dropFirst() {
        dropCount += 1
    }
    require(dropCount == 0, "dropFirst empties")
    var mapped = 0
    for try await count in seq.map({ $0.count }) {
        mapped += 1
        require(count == 0, "map count")
    }
    require(mapped == 1, "map yields")
    var compact = 0
    for try await _ in seq.compactMap({ $0.isEmpty ? Optional<Int>.none : 1 }) {
        compact += 1
    }
    require(compact == 0, "compactMap")
    var filtered = 0
    for try await _ in seq.filter({ !$0.isEmpty }) {
        filtered += 1
    }
    require(filtered == 0, "filter")
    var droppedWhile = 0
    for try await _ in seq.drop(while: { $0.isEmpty }) {
        droppedWhile += 1
    }
    require(droppedWhile == 0, "drop(while:)")
    var prefixWhile = 0
    for try await _ in try seq.prefix(while: { $0.isEmpty }) {
        prefixWhile += 1
    }
    require(prefixWhile == 1, "prefix(while:)")
    var flat = 0
    for try await _ in seq.flatMap({ snapshot -> AsyncStream<WAPairedDevice.ID> in
        AsyncStream { continuation in
            for id in snapshot.keys {
                continuation.yield(id)
            }
            continuation.finish()
        }
    }) {
        flat += 1
    }
    require(flat == 0, "flatMap")
}

private func exerciseDiscovery() throws {
    let service = try JSONDecoder().decode(
        WAPublishableService.self,
        from: Data(#"{"name":"_demo._tcp"}"#.utf8)
    )
    let subService = try JSONDecoder().decode(
        WASubscribableService.self,
        from: Data(#"{"name":"_demo-sub._tcp"}"#.utf8)
    )
    let device = try JSONDecoder().decode(
        WAPairedDevice.self,
        from: Data(#"{"id":1,"name":"A","pairingInfo":null}"#.utf8)
    )

    let all = WAPublisherListener.Devices.allPairedDevices
    let user = WAPublisherListener.Devices.userSpecifiedDevices
    require(all.hostKind == "allPaired", "publisher allPaired")
    require(user.hostKind == "userSpecified", "publisher userSpecified")
    let selectedSeq = WAPublisherListener.Devices.selected([device])
    require(selectedSeq.hostKind == "selected", "publisher selected sequence")
    require(selectedSeq.hostSelectedCount == 1, "publisher selected count")
    let selectedDict = WAPublisherListener.Devices.selected([device.id: device])
    require(selectedDict.hostSelectedCount == 1, "publisher selected dict")
    let predicate = #Predicate<WAPairedDevice> { $0.id == 1 }
    let matching = WAPublisherListener.Devices.matching(predicate)
    require(matching.hostKind == "matching", "publisher matching")

    require(
        WAPublisherListener.DatapathParameters.defaults.hostPerformanceMode == .bulk,
        "datapath defaults"
    )
    require(
        WAPublisherListener.DatapathParameters.realtime.hostPerformanceMode == .realtime,
        "datapath realtime"
    )

    let action = WAPublisherListener.Action.connecting(
        to: service,
        from: all,
        datapath: .defaults
    )
    require(action.hostService == service, "publisher action service")
    require(action.hostDevices.hostKind == "allPaired", "publisher action devices")
    require(action.hostDatapath?.hostPerformanceMode == .bulk, "publisher action datapath")
    let listener = WAPublisherListener(hostAction: action)
    require(!listener.isApplicationService, "Linux never publishes")

    let subAll = WASubscriberBrowser.Devices.allPairedDevices
    let subUser = WASubscriberBrowser.Devices.userSpecifiedDevices
    require(subAll.hostKind == "allPaired", "subscriber allPaired")
    require(subUser.hostKind == "userSpecified", "subscriber userSpecified")
    require(WASubscriberBrowser.Devices.selected([device]).hostSelectedCount == 1, "sub selected seq")
    require(
        WASubscriberBrowser.Devices.selected([device.id: device]).hostSelectedCount == 1,
        "sub selected dict"
    )
    require(
        WASubscriberBrowser.Devices.matching(predicate).hostKind == "matching",
        "sub matching"
    )
    let subAction = WASubscriberBrowser.Action.connecting(to: subAll, from: subService)
    require(subAction.hostService == subService, "subscriber action service")
    let browser = WASubscriberBrowser(hostAction: subAction)
    _ = browser
    let _: WASubscriberBrowser.Endpoint.Type = WAEndpoint.self

    let metrics = WAPerformanceReport.TransmitLatencyMetrics(
        accessCategory: .bestEffort,
        average: Duration.milliseconds(12)
    )
    let report = WAPerformanceReport(
        timestamp: Date(timeIntervalSince1970: 1),
        localTimestamp: ContinuousClock.now,
        throughputCeiling: 100,
        throughputCapacity: 40,
        transmitLatency: [.bestEffort: metrics],
        signalStrength: 0.5
    )
    require(report.throughputCapacityRatio == 0.4, "capacity ratio")
    let encodedReport = try JSONEncoder().encode(report)
    let decodedReport = try JSONDecoder().decode(WAPerformanceReport.self, from: encodedReport)
    require(decodedReport.throughputCeiling == 100, "report ceiling")
    require(decodedReport.throughputCapacity == 40, "report capacity")
    require(decodedReport.signalStrength == 0.5, "report signal")
    require(decodedReport.timestamp.timeIntervalSince1970 == 1, "report timestamp")
    require(
        decodedReport.transmitLatency[.bestEffort]?.accessCategory == .bestEffort,
        "report latency category"
    )
    require(decodedReport.throughputCapacityRatio == 0.4, "decoded ratio")
    let encodedMetrics = try JSONEncoder().encode(metrics)
    let decodedMetrics = try JSONDecoder().decode(
        WAPerformanceReport.TransmitLatencyMetrics.self,
        from: encodedMetrics
    )
    require(decodedMetrics.accessCategory == .bestEffort, "metrics category")

    let nilRatio = WAPerformanceReport(
        timestamp: Date(),
        localTimestamp: ContinuousClock.now,
        throughputCeiling: nil,
        throughputCapacity: 10,
        transmitLatency: [:],
        signalStrength: nil
    )
    require(nilRatio.throughputCapacityRatio == nil, "ratio nil without ceiling")

    let endpoint = WAEndpoint(device: device, publishedService: service)
    require(endpoint.device == device, "endpoint device")
    require(endpoint.publishedService == service, "endpoint published")
    require(endpoint.subscribedService == nil, "endpoint subscribed nil")
    require(endpoint.description.contains("A"), "endpoint description")
    let endpoint2 = WAEndpoint(device: device, subscribedService: subService)
    require(endpoint != endpoint2, "endpoint inequality")
    var hasher = Hasher()
    endpoint.hash(into: &hasher)
    _ = hasher.finalize()

    let path = WAPath(
        endpoint: endpoint,
        performance: decodedReport,
        durationActive: .seconds(3)
    )
    require(path.endpoint == endpoint, "path endpoint")
    require(path.performance.throughputCeiling == 100, "path performance")
    require(path.durationActive == .seconds(3), "path duration")
}

exerciseCapabilities()
try exerciseParameters()
try exerciseErrors()
try exerciseServices()
try await exercisePairedDevices()
try exerciseDiscovery()
print("WIFIAWARE_AGENT_RUNTIME_OK")
