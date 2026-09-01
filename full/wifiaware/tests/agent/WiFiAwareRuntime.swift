import Foundation
import Dispatch
import WiFiAware

do {
    try WiFiAwareRuntime.runBlocking {
        try await WiFiAwareRuntime.run()
    }
    print("WIFIAWARE_AGENT_RUNTIME_OK")
} catch {
    fputs("WIFIAWARE_AGENT_RUNTIME_FAILED: \(error)\n", stderr)
    exit(1)
}

private enum WiFiAwareRuntime {
    final class Box: @unchecked Sendable {
        var result: Result<Void, Error> = .success(())
    }

    static func runBlocking(_ body: @escaping @Sendable () async throws -> Void) throws {
        let box = Box()
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            do {
                try await body()
                box.result = .success(())
            } catch {
                box.result = .failure(error)
            }
            semaphore.signal()
        }
        semaphore.wait()
        try box.result.get()
    }

    static func decode<T: Decodable>(_ json: String) throws -> T {
        try JSONDecoder().decode(T.self, from: Data(json.utf8))
    }

    static func errorJSON(_ caseName: String) -> String {
        "{\"\(caseName)\":{\"_0\":{}}}"
    }

    static func run() async throws {
        try testCapabilities()
        try testParameters()
        try testAccessAndPerformanceEnums()
        try testErrors()
        try testPairedDevices()
        try await testDeviceSequenceFailClosed()
        try testServices()
        try testPublisherAndSubscriberConfiguration()
        try testPerformanceReportCodable()
        try testAsyncSequenceSurface()
    }

    static func testCapabilities() throws {
        precondition(WACapabilities.supportedFeatures.isEmpty)
        precondition(!WACapabilities.supportedFeatures.contains(.wifiAware))
        precondition(WACapabilities.maximumConnectableDevices == 0)
        precondition(WACapabilities.maximumPublishableServices == 0)
        precondition(WACapabilities.maximumSubscribableServices == 0)
        precondition(WACapabilities.Feature.allCases == [.wifiAware])
        let encoded = try JSONEncoder().encode(WACapabilities.Feature.wifiAware)
        let decoded = try JSONDecoder().decode(WACapabilities.Feature.self, from: encoded)
        precondition(decoded == .wifiAware)
        precondition(WACapabilities.Feature.wifiAware == WACapabilities.Feature.allCases[0])
        _ = WACapabilities.Feature.wifiAware.hashValue
        let fromDecoder: WACapabilities.Feature = try decode("{\"wifiAware\":{}}")
        precondition(fromDecoder == .wifiAware)
    }

    static func testParameters() throws {
        precondition(WAParameters.defaults.performanceMode == .bulk)
        precondition(WAParameters.realtime.performanceMode == .realtime)
        var parameters = WAParameters()
        precondition(parameters.performanceMode == .bulk)
        parameters.performanceMode = .realtime
        precondition(parameters.performanceMode == .realtime)
        let explicit = WAParameters(performanceMode: .bulk)
        precondition(explicit.performanceMode == .bulk)
    }

    static func testAccessAndPerformanceEnums() throws {
        precondition(WAPerformanceMode.allCases == [.bulk, .realtime])
        precondition(
            Set(WAAccessCategory.allCases)
                == [
                    .bestEffort, .background, .interactiveVideo, .interactiveVoice
                ]
        )
        precondition(WAPerformanceMode.bulk != .realtime)
        precondition(WAAccessCategory.bestEffort != .interactiveVoice)
        let mode: WAPerformanceMode = try decode("{\"realtime\":{}}")
        precondition(mode == .realtime)
        let category: WAAccessCategory = try decode("{\"background\":{}}")
        precondition(category == .background)
        _ = WAPerformanceMode.bulk.hashValue
        _ = WAAccessCategory.interactiveVideo.hashValue
        let encodedMode = try JSONEncoder().encode(WAPerformanceMode.realtime)
        let decodedMode = try JSONDecoder().decode(WAPerformanceMode.self, from: encodedMode)
        precondition(decodedMode == .realtime)
    }

    static func testErrors() throws {
        let caseNames = [
            "error",
            "wifiAwareUnsupported",
            "entitlementMissing",
            "noRadioResources",
            "serviceNotDeclared",
            "serviceAlreadySubscribing",
            "serviceAlreadyPublishing",
            "noPairedDevices",
            "deviceInvalid",
            "deviceNoLongerAvailable",
            "publisherTimeout",
            "subscriberTimeout",
            "connectionFailed",
            "connectionIdleTimeout",
            "connectionTerminated",
        ]
        var decodedCases: [WAError] = []
        for name in caseNames {
            let error: WAError = try decode(errorJSON(name))
            precondition(error.errorDescription != nil)
            precondition(error.failureReason == error.errorDescription)
            _ = error.recoverySuggestion
            _ = error.helpAnchor
            _ = error.localizedDescription
            let data = try JSONEncoder().encode(error)
            let roundTrip = try JSONDecoder().decode(WAError.self, from: data)
            precondition(roundTrip.errorDescription == error.errorDescription)
            decodedCases.append(error)
        }
        let unsupported: WAError = try decode(errorJSON("wifiAwareUnsupported"))
        precondition(unsupported.recoverySuggestion != nil)
        if case .wifiAwareUnsupported = unsupported {
        } else {
            preconditionFailure("expected wifiAwareUnsupported")
        }
        let details: WAError.WiFiAwareUnsupportedDetails = try decode("{}")
        _ = details
        precondition(decodedCases.count == caseNames.count)
    }

    static func testPairedDevices() throws {
        let info: WAPairedDevice.PairingInfo = try decode(
            """
            {"pairingName":"Pad","vendorName":"Acme","modelName":"Pad1"}
            """
        )
        precondition(info.pairingName == "Pad")
        precondition(info.vendorName == "Acme")
        precondition(info.modelName == "Pad1")
        precondition(info.description.contains("Pad"))
        let copy: WAPairedDevice.PairingInfo = try decode(
            """
            {"pairingName":"Pad","vendorName":"Acme","modelName":"Pad1"}
            """
        )
        precondition(info == copy)
        precondition(info.hashValue == copy.hashValue)
        let encodedInfo = try JSONEncoder().encode(info)
        let decodedInfo = try JSONDecoder().decode(
            WAPairedDevice.PairingInfo.self, from: encodedInfo
        )
        precondition(decodedInfo == info)

        let device: WAPairedDevice = try decode(
            """
            {"id":7,"name":"Kitchen","pairingInfo":{"pairingName":"Pad","vendorName":"Acme","modelName":"Pad1"}}
            """
        )
        precondition(device.id == 7)
        precondition(device.name == "Kitchen")
        precondition(device.pairingInfo == info)
        precondition(device.description.contains("Kitchen"))
        let other: WAPairedDevice = try decode(
            """
            {"id":8,"name":null,"pairingInfo":null}
            """
        )
        precondition(device != other)
        precondition(other.description.contains("unnamed"))
        let encodedDevice = try JSONEncoder().encode(device)
        let decodedDevice = try JSONDecoder().decode(WAPairedDevice.self, from: encodedDevice)
        precondition(decodedDevice == device)
        _ = device.hashValue
    }

    static func testDeviceSequenceFailClosed() async throws {
        do {
            _ = try await WAPairedDevice.allDevices.current()
            preconditionFailure("allDevices.current() must not succeed")
        } catch let error as WAError {
            if case .wifiAwareUnsupported = error {
            } else {
                preconditionFailure("expected wifiAwareUnsupported, got \(error)")
            }
        }

        let matching = #Predicate<WAPairedDevice> { device in
            device.name == "Kitchen"
        }
        do {
            _ = try await WAPairedDevice.allDevices(matching: matching).current()
            preconditionFailure("matching allDevices.current() must not succeed")
        } catch let error as WAError {
            if case .wifiAwareUnsupported = error {
            } else {
                preconditionFailure("expected wifiAwareUnsupported, got \(error)")
            }
        }

        let iterator = WAPairedDevice.allDevices.makeAsyncIterator()
        do {
            _ = try await iterator.next()
            preconditionFailure("device iterator must not succeed")
        } catch let error as WAError {
            if case .wifiAwareUnsupported = error {
            } else {
                preconditionFailure("expected wifiAwareUnsupported, got \(error)")
            }
        }
    }

    static func testServices() throws {
        precondition(WAPublishableService.allServices.isEmpty)
        precondition(WASubscribableService.allServices.isEmpty)
        let published: WAPublishableService = try decode("{\"name\":\"example-service\"}")
        let subscribed: WASubscribableService = try decode("{\"name\":\"example-service\"}")
        precondition(published.id == "example-service")
        precondition(subscribed.id == "example-service")
        precondition(published.name == subscribed.name)
        precondition(published.description.contains("example-service"))
        precondition(subscribed.description.contains("example-service"))
        let publishedCopy: WAPublishableService = try decode("{\"name\":\"example-service\"}")
        precondition(published == publishedCopy)
        let other: WASubscribableService = try decode("{\"name\":\"other\"}")
        precondition(subscribed != other)
        _ = published.hashValue
        _ = subscribed.hashValue
        let encodedPublished = try JSONEncoder().encode(published)
        let decodedPublished = try JSONDecoder().decode(
            WAPublishableService.self, from: encodedPublished
        )
        precondition(decodedPublished == published)
        let encodedSubscribed = try JSONEncoder().encode(subscribed)
        let decodedSubscribed = try JSONDecoder().decode(
            WASubscribableService.self, from: encodedSubscribed
        )
        precondition(decodedSubscribed == subscribed)
    }

    static func testPublisherAndSubscriberConfiguration() throws {
        let service: WAPublishableService = try decode("{\"name\":\"xfer\"}")
        let device: WAPairedDevice = try decode(
            """
            {"id":1,"name":"Peer","pairingInfo":null}
            """
        )
        let selected = WAPublisherListener.Devices.selected([device])
        let fromDictionary = WAPublisherListener.Devices.selected([device.id: device])
        _ = fromDictionary
        let emptySelected = WAPublisherListener.Devices.selected([] as [WAPairedDevice])
        _ = emptySelected
        let matching = WAPublisherListener.Devices.matching(
            #Predicate<WAPairedDevice> { $0.id == 1 }
        )
        _ = matching
        _ = WAPublisherListener.Devices.allPairedDevices
        _ = WAPublisherListener.Devices.userSpecifiedDevices
        let action = WAPublisherListener.Action.connecting(
            to: service,
            from: selected,
            datapath: .realtime
        )
        let listener = WAPublisherListener.wifiAware(action, active: .seconds(5))
        precondition(listener.isApplicationService)
        let defaultListener = WAPublisherListener.wifiAware(
            .connecting(to: service, from: .allPairedDevices)
        )
        precondition(defaultListener.isApplicationService)
        _ = WAPublisherListener.DatapathParameters.defaults
        _ = WAPublisherListener.DatapathParameters.realtime

        let subscribeService: WASubscribableService = try decode("{\"name\":\"xfer\"}")
        let browserDevices = WASubscriberBrowser.Devices.selected([device])
        _ = WASubscriberBrowser.Devices.selected([device.id: device])
        _ = WASubscriberBrowser.Devices.matching(
            #Predicate<WAPairedDevice> { $0.name == "Peer" }
        )
        _ = WASubscriberBrowser.Devices.allPairedDevices
        _ = WASubscriberBrowser.Devices.userSpecifiedDevices
        let browser = WASubscriberBrowser.wifiAware(
            .connecting(to: browserDevices, from: subscribeService)
        )
        _ = browser
        let typed: WASubscriberBrowser.Endpoint? = nil
        _ = typed
    }

    static func testPerformanceReportCodable() throws {
        let metrics: WAPerformanceReport.TransmitLatencyMetrics = try decode(
            """
            {"accessCategory":{"bestEffort":{}},"average":[0,12000000000000000]}
            """
        )
        precondition(metrics.accessCategory == .bestEffort)
        precondition(metrics.average != nil)

        let encoder = JSONEncoder()
        func embed<T: Encodable>(_ value: T) throws -> Any {
            try JSONSerialization.jsonObject(
                with: try encoder.encode(value),
                options: [.fragmentsAllowed]
            )
        }
        var object: [String: Any] = [
            "timestamp": try embed(Date(timeIntervalSince1970: 1)),
            "localTimestamp": try embed(ContinuousClock.now),
            "throughputCeiling": 100.0,
            "throughputCapacity": 40.0,
            "signalStrength": -50.0,
        ]
        let encodedMetrics = try encoder.encode(metrics)
        let metricsObject = try JSONSerialization.jsonObject(with: encodedMetrics)
        object["transmitLatency"] = [
            try embed(WAAccessCategory.bestEffort),
            metricsObject,
        ]
        let data = try JSONSerialization.data(withJSONObject: object)
        let report = try JSONDecoder().decode(WAPerformanceReport.self, from: data)
        precondition(report.throughputCeiling == 100)
        precondition(report.throughputCapacity == 40)
        precondition(report.signalStrength == -50)
        precondition(report.throughputCapacityRatio == 0.4)
        precondition(report.transmitLatency[.bestEffort]?.accessCategory == .bestEffort)
        let encoded = try JSONEncoder().encode(report)
        let decoded = try JSONDecoder().decode(WAPerformanceReport.self, from: encoded)
        precondition(decoded.throughputCapacityRatio == 0.4)

        var missingObject = object
        missingObject.removeValue(forKey: "throughputCeiling")
        missingObject["throughputCapacity"] = 40.0
        missingObject["transmitLatency"] = [] as [Any]
        missingObject.removeValue(forKey: "signalStrength")
        let missingData = try JSONSerialization.data(withJSONObject: missingObject)
        let missing = try JSONDecoder().decode(WAPerformanceReport.self, from: missingData)
        precondition(missing.throughputCapacityRatio == nil)
    }

    static func testAsyncSequenceSurface() throws {
        let sequence = WAPairedDevice.allDevices
        _ = sequence.map { $0.count }
        _ = sequence.compactMap { $0.keys.first }
        _ = sequence.filter { !$0.isEmpty }
        _ = sequence.dropFirst()
        _ = sequence.dropFirst(1)
        _ = sequence.prefix(1)
        _ = try sequence.prefix { !$0.isEmpty }
        _ = sequence.drop { $0.isEmpty }
        _ = sequence.flatMap { _ in WAPairedDevice.allDevices }
    }
}
