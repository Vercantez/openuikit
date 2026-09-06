import DeviceDiscoveryExtension
import Foundation

func testDDDeviceEventTypeRawValues() {
    ddExpect(DDDeviceEvent.EventType.unknown.rawValue == 0, "unknown")
    ddExpect(DDDeviceEvent.EventType.deviceFound.rawValue == 40, "found")
    ddExpect(DDDeviceEvent.EventType.deviceLost.rawValue == 41, "lost")
    ddExpect(DDDeviceEvent.EventType.deviceChanged.rawValue == 42, "changed")
}

func testDDDeviceEventTypeInitRawValue() {
    ddExpect(DDDeviceEvent.EventType(rawValue: 0) == .unknown, "0")
    ddExpect(DDDeviceEvent.EventType(rawValue: 40) == .deviceFound, "40")
    ddExpect(DDDeviceEvent.EventType(rawValue: 41) == .deviceLost, "41")
    ddExpect(DDDeviceEvent.EventType(rawValue: 42) == .deviceChanged, "42")
    ddExpect(DDDeviceEvent.EventType(rawValue: 1) == nil, "gap")
}

func testDDDeviceEventTypeInequality() {
    ddExpect(DDDeviceEvent.EventType.deviceFound != .deviceLost, "!=")
    ddExpect(!(DDDeviceEvent.EventType.unknown != .unknown), "equal inverse")
}

func testDDDeviceEventTypeHashable() {
    var hasher = Hasher()
    DDDeviceEvent.EventType.deviceChanged.hash(into: &hasher)
    _ = hasher.finalize()
    ddExpect(
        DDDeviceEvent.EventType.deviceFound.hashValue == DDDeviceEvent.EventType.deviceFound.hashValue,
        "hashValue"
    )
    ddExpect(
        DDDeviceEvent.EventType.deviceFound.hashValue != DDDeviceEvent.EventType.deviceLost.hashValue,
        "distinct"
    )
}

func testDDEventTypeToString() {
    ddExpect(DDEventTypeToString(.unknown) == "DDEventTypeUnknown", "unknown")
    ddExpect(DDEventTypeToString(.deviceFound) == "DDEventTypeDeviceFound", "found")
    ddExpect(DDEventTypeToString(.deviceLost) == "DDEventTypeDeviceLost", "lost")
    ddExpect(DDEventTypeToString(.deviceChanged) == "DDEventTypeDeviceChanged", "changed")
}

func testDDDeviceEventInit() {
    let device = DDDevice(
        displayName: "Box",
        category: .tvWithMediaBox,
        protocolType: UTType("com.example.dial"),
        identifier: "box-1"
    )
    let event = DDDeviceEvent(eventType: .deviceFound, device: device)
    ddExpect(event.eventType == .deviceFound, "type")
    ddExpect(event.device === device, "same device identity")
}

func testDDDeviceEventDeviceProperty() {
    let device = DDDevice(
        displayName: "A",
        category: .desktopComputer,
        protocolType: UTType("public.item"),
        identifier: "a"
    )
    let event = DDDeviceEvent(eventType: .deviceChanged, device: device)
    ddExpect(event.device.identifier == "a", "identifier through event")
    device.displayName = "B"
    ddExpect(event.device.displayName == "B", "shared mutation")
}

func testDDDeviceEventEventTypeProperty() {
    let device = DDDevice(
        displayName: "A",
        category: .hifiSpeaker,
        protocolType: UTType("public.item"),
        identifier: "a"
    )
    let lost = DDDeviceEvent(eventType: .deviceLost, device: device)
    ddExpect(lost.eventType == .deviceLost, "lost")
}
