import DeviceDiscoveryExtension
import Foundation
@_spi(OpenUIKitHost) import DeviceDiscoveryExtension

private final class RecordingDiscoveryExtension: DDDiscoveryExtension {
    var startCount = 0
    var stopCount = 0
    var received: [DDDeviceEvent] = []

    func startDiscovery(session: DDDiscoverySession) {
        startCount += 1
        _ = session
        // Fail-closed: do not invent devices or call report.
    }

    func stopDiscovery(session: DDDiscoverySession) {
        stopCount += 1
        _ = session
    }

    func didReceiveEvent(_ event: DDDeviceEvent) {
        received.append(event)
    }
}

private final class DefaultingDiscoveryExtension: DDDiscoveryExtension {
    func startDiscovery(session: DDDiscoverySession) {
        _ = session
    }

    func stopDiscovery(session: DDDiscoverySession) {
        _ = session
    }
}

func testDDDiscoveryExtensionStartDiscoveryDoesNotInventDevices() {
    let ext = RecordingDiscoveryExtension()
    let session = DDDiscoverySession()
    ext.startDiscovery(session: session)
    ddExpect(ext.startCount == 1, "started once")
    ddExpect(session.reportedEvents.isEmpty, "no invented devices")
}

func testDDDiscoveryExtensionStopDiscovery() {
    let ext = RecordingDiscoveryExtension()
    let session = DDDiscoverySession()
    ext.startDiscovery(session: session)
    ext.stopDiscovery(session: session)
    ddExpect(ext.stopCount == 1, "stopped")
    ddExpect(ext.startCount == 1, "start retained")
}

func testDDDiscoveryExtensionDidReceiveEventRequirement() {
    let ext = RecordingDiscoveryExtension()
    let device = DDDevice(
        displayName: "X",
        category: .tv,
        protocolType: UTType("public.item"),
        identifier: "x"
    )
    let event = DDDeviceEvent(eventType: .deviceLost, device: device)
    ext.didReceiveEvent(event)
    ddExpect(ext.received.count == 1, "recorded")
    ddExpect(ext.received[0].eventType == .deviceLost, "type")
}

func testDDDiscoveryExtensionDidReceiveEventDefault() {
    let ext = DefaultingDiscoveryExtension()
    let device = DDDevice(
        displayName: "Y",
        category: .tv,
        protocolType: UTType("public.item"),
        identifier: "y"
    )
    ext.didReceiveEvent(DDDeviceEvent(eventType: .unknown, device: device))
}

func testDDDiscoveryExtensionConfigurationInit() {
    let ext = DefaultingDiscoveryExtension()
    let configuration = DDDiscoveryExtensionConfiguration(discoveryExtension: ext)
    ddExpect(configuration.discoveryExtension === ext, "same extension")
}

func testDDDiscoveryExtensionDefaultConfiguration() {
    let ext = DefaultingDiscoveryExtension()
    let configuration = ext.configuration
    ddExpect(configuration.discoveryExtension === ext, "wraps self")
}

func testDDDiscoveryExtensionConfigurationAcceptFailsClosed() {
    let ext = DefaultingDiscoveryExtension()
    let configuration = DDDiscoveryExtensionConfiguration(discoveryExtension: ext)
    let connection = NSXPCConnection(serviceName: "com.apple.DeviceDiscovery")
    let asProtocol: any DDDiscoveryExtensionConfigurationProtocol = configuration
    ddExpect(asProtocol.accept(connection: connection) == false, "protocol fail-closed")
    ddExpect(connection.serviceName == "com.apple.DeviceDiscovery", "name stored")
}
