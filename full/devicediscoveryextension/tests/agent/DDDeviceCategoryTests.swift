import DeviceDiscoveryExtension
import Foundation

func testDDDeviceCategoryRawValues() {
    ddExpect(DDDevice.Category.hifiSpeaker.rawValue == 0, "hifiSpeaker")
    ddExpect(DDDevice.Category.hifiSpeakerMultiple.rawValue == 1, "hifiSpeakerMultiple")
    ddExpect(DDDevice.Category.tvWithMediaBox.rawValue == 2, "tvWithMediaBox")
    ddExpect(DDDevice.Category.tv.rawValue == 3, "tv")
    ddExpect(DDDevice.Category.laptopComputer.rawValue == 4, "laptopComputer")
    ddExpect(DDDevice.Category.desktopComputer.rawValue == 5, "desktopComputer")
    ddExpect(DDDevice.Category.accessorySetup.rawValue == 6, "accessorySetup")
}

func testDDDeviceCategoryInitRawValue() {
    ddExpect(DDDevice.Category(rawValue: 0) == .hifiSpeaker, "0")
    ddExpect(DDDevice.Category(rawValue: 6) == .accessorySetup, "6")
    ddExpect(DDDevice.Category(rawValue: 7) == nil, "unknown 7")
    ddExpect(DDDevice.Category(rawValue: -1) == nil, "negative")
}

func testDDDeviceCategoryInequality() {
    ddExpect(DDDevice.Category.tv != .laptopComputer, "!=")
    ddExpect(!(DDDevice.Category.tv != .tv), "equal inverse")
}

func testDDDeviceCategoryHashable() {
    var hasher = Hasher()
    DDDevice.Category.desktopComputer.hash(into: &hasher)
    _ = hasher.finalize()
    ddExpect(DDDevice.Category.tv.hashValue == DDDevice.Category.tv.hashValue, "hashValue")
    ddExpect(DDDevice.Category.tv.hashValue != DDDevice.Category.desktopComputer.hashValue, "distinct")
}

func testDDDeviceCategoryToString() {
    ddExpect(DDDeviceCategoryToString(.hifiSpeaker) == "DDDeviceCategoryHiFiSpeaker", "hifi")
    ddExpect(DDDeviceCategoryToString(.hifiSpeakerMultiple) == "DDDeviceCategoryHiFiSpeakerMultiple", "multi")
    ddExpect(DDDeviceCategoryToString(.tvWithMediaBox) == "DDDeviceCategoryTVWithMediaBox", "box")
    ddExpect(DDDeviceCategoryToString(.tv) == "DDDeviceCategoryTV", "tv")
    ddExpect(DDDeviceCategoryToString(.laptopComputer) == "DDDeviceCategoryLaptopComputer", "laptop")
    ddExpect(DDDeviceCategoryToString(.desktopComputer) == "DDDeviceCategoryDesktopComputer", "desktop")
    ddExpect(DDDeviceCategoryToString(.accessorySetup) == "DDDeviceCategoryAccessorySetup", "accessory")
}
