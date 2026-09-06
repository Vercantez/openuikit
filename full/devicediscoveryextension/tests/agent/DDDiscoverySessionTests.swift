import DeviceDiscoveryExtension
import Foundation
@_spi(OpenUIKitHost) import DeviceDiscoveryExtension

func testDDDiscoverySessionInit() {
    let session = DDDiscoverySession()
    ddExpect(session.reportedEvents.isEmpty, "no events yet")
}

func testDDDiscoverySessionReportRetainsEvents() {
    let session = DDDiscoverySession()
    let device = DDDevice(
        displayName: "Peer",
        category: .hifiSpeaker,
        protocolType: UTType("com.example.dial"),
        identifier: "peer-1"
    )
    let found = DDDeviceEvent(eventType: .deviceFound, device: device)
    let changed = DDDeviceEvent(eventType: .deviceChanged, device: device)
    session.report(found)
    session.report(changed)
    ddExpect(session.reportedEvents.count == 2, "two events")
    ddExpect(session.reportedEvents[0].eventType == .deviceFound, "first")
    ddExpect(session.reportedEvents[1].eventType == .deviceChanged, "second")
    ddExpect(session.reportedEvents[0].device === device, "identity")
}
