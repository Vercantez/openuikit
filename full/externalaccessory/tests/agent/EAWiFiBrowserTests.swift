@_spi(OpenUIKitHost) import ExternalAccessory
import Foundation

final class EAWiFiBrowserProbe: NSObject, EAWiFiUnconfiguredAccessoryBrowserDelegate {
    var states: [EAWiFiUnconfiguredAccessoryBrowserState] = []
    var found: [Set<EAWiFiUnconfiguredAccessory>] = []
    var removed: [Set<EAWiFiUnconfiguredAccessory>] = []
    var finished: [(EAWiFiUnconfiguredAccessory, EAWiFiUnconfiguredAccessoryConfigurationStatus)] = []

    func accessoryBrowser(
        _ browser: EAWiFiUnconfiguredAccessoryBrowser,
        didUpdate state: EAWiFiUnconfiguredAccessoryBrowserState
    ) {
        _ = browser
        states.append(state)
    }

    func accessoryBrowser(
        _ browser: EAWiFiUnconfiguredAccessoryBrowser,
        didFindUnconfiguredAccessories accessories: Set<EAWiFiUnconfiguredAccessory>
    ) {
        _ = browser
        found.append(accessories)
    }

    func accessoryBrowser(
        _ browser: EAWiFiUnconfiguredAccessoryBrowser,
        didRemoveUnconfiguredAccessories accessories: Set<EAWiFiUnconfiguredAccessory>
    ) {
        _ = browser
        removed.append(accessories)
    }

    func accessoryBrowser(
        _ browser: EAWiFiUnconfiguredAccessoryBrowser,
        didFinishConfiguringAccessory accessory: EAWiFiUnconfiguredAccessory,
        with status: EAWiFiUnconfiguredAccessoryConfigurationStatus
    ) {
        _ = browser
        finished.append((accessory, status))
    }
}

func testEAWiFiUnconfiguredAccessoryEmptyProperties() {
    let accessory = EAWiFiUnconfiguredAccessory()
    precondition(accessory.name.isEmpty)
    precondition(accessory.manufacturer.isEmpty)
    precondition(accessory.model.isEmpty)
    precondition(accessory.ssid.isEmpty)
    precondition(accessory.macAddress.isEmpty)
    precondition(accessory.properties.isEmpty)
}

func testEAWiFiUnconfiguredAccessoryHostProperties() {
    let accessory = EAWiFiUnconfiguredAccessory(
        hostName: "Lamp",
        manufacturer: "Acme",
        model: "L2",
        ssid: "LampNet",
        macAddress: "00:11:22:33:44:55",
        properties: [.propertySupportsHomeKit]
    )
    precondition(accessory.name == "Lamp")
    precondition(accessory.manufacturer == "Acme")
    precondition(accessory.model == "L2")
    precondition(accessory.ssid == "LampNet")
    precondition(accessory.macAddress == "00:11:22:33:44:55")
    precondition(accessory.properties.contains(.propertySupportsHomeKit))
}

func testEAWiFiUnconfiguredAccessoryBrowserInit() {
    let probe = EAWiFiBrowserProbe()
    let queue = DispatchQueue(label: "ea.wifi.tests")
    let browser = EAWiFiUnconfiguredAccessoryBrowser(delegate: probe, queue: queue)
    precondition(browser.delegate === probe)
    precondition(browser.hostQueue === queue)
    precondition(browser.unconfiguredAccessories.isEmpty)
    precondition(probe.states.isEmpty)
}

func testEAWiFiUnconfiguredAccessoryBrowserSearchFailClosed() {
    let probe = EAWiFiBrowserProbe()
    let browser = EAWiFiUnconfiguredAccessoryBrowser(delegate: probe, queue: nil)
    browser.startSearchingForUnconfiguredAccessories(matching: nil)
    precondition(probe.states == [.wiFiUnavailable])
    precondition(probe.found.isEmpty)
    precondition(browser.unconfiguredAccessories.isEmpty)
    precondition(!browser.hostIsSearching)
}

func testEAWiFiUnconfiguredAccessoryBrowserStop() {
    let probe = EAWiFiBrowserProbe()
    let browser = EAWiFiUnconfiguredAccessoryBrowser(delegate: probe, queue: nil)
    browser.stopSearchingForUnconfiguredAccessories()
    precondition(probe.states == [.stopped])
}

func testEAWiFiUnconfiguredAccessoryBrowserConfigureFailClosed() {
    let probe = EAWiFiBrowserProbe()
    let browser = EAWiFiUnconfiguredAccessoryBrowser(delegate: probe, queue: nil)
    let accessory = EAWiFiUnconfiguredAccessory(
        hostName: "Speaker",
        manufacturer: "Acme",
        model: "S1",
        ssid: "SpeakerNet",
        macAddress: "aa:bb:cc:dd:ee:ff",
        properties: [.propertySupportsAirPlay]
    )
    browser.configureAccessory(accessory, withConfigurationUIOn: NSObject())
    precondition(probe.finished.count == 1)
    precondition(probe.finished[0].0 === accessory)
    precondition(probe.finished[0].1 == .failed)
}

func testEAWiFiUnconfiguredAccessoryBrowserDelegateAssignment() {
    let first = EAWiFiBrowserProbe()
    let second = EAWiFiBrowserProbe()
    let browser = EAWiFiUnconfiguredAccessoryBrowser(delegate: first, queue: nil)
    browser.delegate = second
    precondition(browser.delegate === second)
    browser.startSearchingForUnconfiguredAccessories(matching: NSPredicate(value: true))
    precondition(first.states.isEmpty)
    precondition(second.states == [.wiFiUnavailable])
}
