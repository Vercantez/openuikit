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

func testPublisherDevicesFactories() {
    let device = sampleDevice()
    let all = WAPublisherListener.Devices.allPairedDevices
    let user = WAPublisherListener.Devices.userSpecifiedDevices
    waExpect(all.hostKind == "allPaired", "publisher allPaired")
    waExpect(user.hostKind == "userSpecified", "publisher userSpecified")
    let selectedSeq = WAPublisherListener.Devices.selected([device])
    waExpect(selectedSeq.hostKind == "selected", "publisher selected sequence")
    waExpect(selectedSeq.hostSelectedCount == 1, "publisher selected count")
    let selectedDict = WAPublisherListener.Devices.selected([device.id: device])
    waExpect(selectedDict.hostSelectedCount == 1, "publisher selected dict")
    let predicate = #Predicate<WAPairedDevice> { $0.id == 1 }
    let matching = WAPublisherListener.Devices.matching(predicate)
    waExpect(matching.hostKind == "matching", "publisher matching")
    let _: WAPublisherListener.Devices = all
}

func testPublisherActionAndDatapath() {
    let service = samplePublishable()
    waExpect(
        WAPublisherListener.DatapathParameters.defaults.hostPerformanceMode == .bulk,
        "datapath defaults"
    )
    waExpect(
        WAPublisherListener.DatapathParameters.realtime.hostPerformanceMode == .realtime,
        "datapath realtime"
    )
    let action = WAPublisherListener.Action.connecting(
        to: service,
        from: .allPairedDevices,
        datapath: .defaults
    )
    waExpect(action.hostService == service, "publisher action service")
    waExpect(action.hostDevices.hostKind == "allPaired", "publisher action devices")
    waExpect(action.hostDatapath?.hostPerformanceMode == .bulk, "publisher action datapath")
    let _: WAPublisherListener.Action = action
    let _: WAPublisherListener.DatapathParameters = .defaults
}

func testPublisherIsApplicationServiceFailClosed() {
    let action = WAPublisherListener.Action.connecting(
        to: samplePublishable(),
        from: .allPairedDevices,
        datapath: nil
    )
    let listener = WAPublisherListener(hostAction: action)
    waExpect(!listener.isApplicationService, "Linux never publishes")
    let _: WAPublisherListener = listener
}
