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

private func sampleSubscribable() -> WASubscribableService {
    try! JSONDecoder().decode(
        WASubscribableService.self,
        from: Data(#"{"name":"_demo-sub._tcp"}"#.utf8)
    )
}

func testSubscriberDevicesFactories() {
    let device = sampleDevice()
    let all = WASubscriberBrowser.Devices.allPairedDevices
    let user = WASubscriberBrowser.Devices.userSpecifiedDevices
    waExpect(all.hostKind == "allPaired", "subscriber allPaired")
    waExpect(user.hostKind == "userSpecified", "subscriber userSpecified")
    waExpect(
        WASubscriberBrowser.Devices.selected([device]).hostSelectedCount == 1,
        "sub selected seq"
    )
    waExpect(
        WASubscriberBrowser.Devices.selected([device.id: device]).hostSelectedCount == 1,
        "sub selected dict"
    )
    let predicate = #Predicate<WAPairedDevice> { $0.id == 1 }
    waExpect(
        WASubscriberBrowser.Devices.matching(predicate).hostKind == "matching",
        "sub matching"
    )
    let _: WASubscriberBrowser.Devices = all
}

func testSubscriberActionConnecting() {
    let service = sampleSubscribable()
    let action = WASubscriberBrowser.Action.connecting(
        to: .allPairedDevices,
        from: service
    )
    waExpect(action.hostService == service, "subscriber action service")
    waExpect(action.hostDevices.hostKind == "allPaired", "subscriber action devices")
    let _: WASubscriberBrowser.Action = action
}

func testSubscriberEndpointAlias() {
    let action = WASubscriberBrowser.Action.connecting(
        to: .userSpecifiedDevices,
        from: sampleSubscribable()
    )
    let browser = WASubscriberBrowser(hostAction: action)
    let _: WASubscriberBrowser = browser
    let _: WASubscriberBrowser.Endpoint.Type = WAEndpoint.self
}
