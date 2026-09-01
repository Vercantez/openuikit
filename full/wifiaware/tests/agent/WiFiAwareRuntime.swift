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

    static func run() async throws {
        try testCapabilities()
        try testParameters()
        try testAccessAndPerformanceEnums()
        try testErrors()
        try testPairedDevices()
        try await testDeviceSequenceFailClosed()
        try testServices()
        try testPublisherAndSubscriberConfiguration()
        try testEndpointPathAndPerformance()
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
        precondition(WiFiAwareAvailability.isSupported == false)
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
        precondition(
            WAPerformanceMode.allCases == [.bulk, .realtime]
        )
        precondition(
            Set(WAAccessCategory.allCases)
                == [
                    .bestEffort, .background, .interactiveVideo, .interactiveVoice
                ]
        )
        precondition(WAPerformanceMode.bulk != .realtime)
        precondition(WAAccessCategory.bestEffort != .interactiveVoice)
        let mode = try JSONDecoder().decode(
            WAPerformanceMode.self,
            from: try JSONEncoder().encode(WAPerformanceMode.realtime)
        )
        precondition(mode == .realtime)
        let category = try JSONDecoder().decode(
            WAAccessCategory.self,
            from: try JSONEncoder().encode(WAAccessCategory.background)
        )
        precondition(category == .background)
        _ = WAPerformanceMode.bulk.hashValue
        _ = WAAccessCategory.interactiveVideo.hashValue
    }

    static func testErrors() throws {
        let cases: [WAError] = [
            .error(.init()),
            .wifiAwareUnsupported(.init()),
            .entitlementMissing(.init()),
            .noRadioResources(.init()),
            .serviceNotDeclared(.init()),
            .serviceAlreadySubscribing(.init()),
            .serviceAlreadyPublishing(.init()),
            .noPairedDevices(.init()),
            .deviceInvalid(.init()),
            .deviceNoLongerAvailable(.init()),
            .publisherTimeout(.init()),
            .subscriberTimeout(.init()),
            .connectionFailed(.init()),
            .connectionIdleTimeout(.init()),
            .connectionTerminated(.init()),
        ]
        for error in cases {
            precondition(error.errorDescription != nil)
            precondition(error.failureReason == error.errorDescription)
            _ = error.recoverySuggestion
            _ = error.helpAnchor
            _ = error.localizedDescription
            let data = try JSONEncoder().encode(error)
            let decoded = try JSONDecoder().decode(WAError.self, from: data)
            precondition(decoded.errorDescription == error.errorDescription)
        }
        let unsupported = WAError.wifiAwareUnsupported(.init())
        precondition(unsupported.recoverySuggestion != nil)
        if case .wifiAwareUnsupported = unsupported {
        } else {
            preconditionFailure("expected wifiAwareUnsupported")
        }
    }

    static func testPairedDevices() throws {
        let info = WAPairedDevice.PairingInfo(
            pairingName: "Pad",
            vendorName: "Acme",
            modelName: "Pad1"
        )
        precondition(info.pairingName == "Pad")
        precondition(info.vendorName == "Acme")
        precondition(info.modelName == "Pad1")
        precondition(info.description.contains("Pad"))
        let copy = WAPairedDevice.PairingInfo(
            pairingName: "Pad", vendorName: "Acme", modelName: "Pad1"
        )
        precondition(info == copy)
        precondition(info.hashValue == copy.hashValue)
        let encodedInfo = try JSONEncoder().encode(info)
        let decodedInfo = try JSONDecoder().decode(
            WAPairedDevice.PairingInfo.self, from: encodedInfo
        )
        precondition(decodedInfo == info)

        let device = WAPairedDevice(id: 7, name: "Kitchen", pairingInfo: info)
        precondition(device.id == 7)
        precondition(device.name == "Kitchen")
        precondition(device.pairingInfo == info)
        precondition(device.description.contains("Kitchen"))
        let other = WAPairedDevice(id: 8, name: nil, pairingInfo: nil)
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
        let published = WAPublishableService(name: "example-service")
        let subscribed = WASubscribableService(name: "example-service")
        precondition(published.id == "example-service")
        precondition(subscribed.id == "example-service")
        precondition(published.name == subscribed.name)
        precondition(published.description.contains("example-service"))
        precondition(subscribed.description.contains("example-service"))
        precondition(published == WAPublishableService(name: "example-service"))
        precondition(subscribed != WASubscribableService(name: "other"))
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
        let service = WAPublishableService(name: "xfer")
        let device = WAPairedDevice(id: 1, name: "Peer", pairingInfo: nil)
        let selected = WAPublisherListener.Devices.selected([device])
        let fromDictionary = WAPublisherListener.Devices.selected([device.id: device])
        _ = fromDictionary
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

        let subscribeService = WASubscribableService(name: "xfer")
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

    static func testEndpointPathAndPerformance() throws {
        let device = WAPairedDevice(id: 42, name: "Lamp", pairingInfo: nil)
        let published = WAPublishableService(name: "lamp")
        let subscribed = WASubscribableService(name: "lamp")
        let endpoint = WAEndpoint(
            device: device,
            publishedService: published,
            subscribedService: subscribed
        )
        precondition(endpoint.device == device)
        precondition(endpoint.publishedService == published)
        precondition(endpoint.subscribedService == subscribed)
        precondition(endpoint.description.contains("Lamp"))
        let other = WAEndpoint(device: device)
        precondition(endpoint != other)
        _ = endpoint.hashValue

        let metrics = WAPerformanceReport.TransmitLatencyMetrics(
            accessCategory: .bestEffort,
            average: .milliseconds(12)
        )
        precondition(metrics.accessCategory == .bestEffort)
        let report = WAPerformanceReport(
            timestamp: Date(timeIntervalSince1970: 1),
            localTimestamp: ContinuousClock.now,
            throughputCeiling: 100,
            throughputCapacity: 40,
            transmitLatency: [.bestEffort: metrics],
            signalStrength: -50
        )
        precondition(report.throughputCapacityRatio == 0.4)
        precondition(report.signalStrength == -50)
        let missingRatio = WAPerformanceReport(
            timestamp: Date(timeIntervalSince1970: 1),
            localTimestamp: ContinuousClock.now,
            throughputCeiling: nil,
            throughputCapacity: 40,
            transmitLatency: [:],
            signalStrength: nil
        )
        precondition(missingRatio.throughputCapacityRatio == nil)
        let encoded = try JSONEncoder().encode(report)
        let decoded = try JSONDecoder().decode(WAPerformanceReport.self, from: encoded)
        precondition(decoded.throughputCeiling == 100)
        precondition(decoded.throughputCapacity == 40)
        precondition(decoded.transmitLatency[.bestEffort]?.accessCategory == .bestEffort)

        let path = WAPath(
            endpoint: endpoint,
            performance: report,
            durationActive: .seconds(3)
        )
        precondition(path.endpoint == endpoint)
        precondition(path.durationActive == .seconds(3))
        precondition(path.performance.throughputCapacity == 40)
    }

    static func testAsyncSequenceSurface() throws {
        let sequence = WAPairedDevice.allDevices
        _ = sequence.map { $0.count }
        _ = sequence.map { snapshot in snapshot.count }
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
