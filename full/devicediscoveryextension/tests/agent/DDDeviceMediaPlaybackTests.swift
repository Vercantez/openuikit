import DeviceDiscoveryExtension
import Foundation

func testDDDeviceMediaPlaybackStateRawValues() {
    ddExpect(DDDevice.MediaPlaybackState.noContent.rawValue == 0, "noContent")
    ddExpect(DDDevice.MediaPlaybackState.paused.rawValue == 1, "paused")
    ddExpect(DDDevice.MediaPlaybackState.playing.rawValue == 2, "playing")
}

func testDDDeviceMediaPlaybackStateInitRawValue() {
    ddExpect(DDDevice.MediaPlaybackState(rawValue: 0) == .noContent, "0")
    ddExpect(DDDevice.MediaPlaybackState(rawValue: 2) == .playing, "2")
    ddExpect(DDDevice.MediaPlaybackState(rawValue: 3) == nil, "unknown")
}

func testDDDeviceMediaPlaybackStateInequality() {
    ddExpect(DDDevice.MediaPlaybackState.paused != .playing, "!=")
    ddExpect(!(DDDevice.MediaPlaybackState.noContent != .noContent), "equal inverse")
}

func testDDDeviceMediaPlaybackStateHashable() {
    var hasher = Hasher()
    DDDevice.MediaPlaybackState.playing.hash(into: &hasher)
    _ = hasher.finalize()
    ddExpect(DDDevice.MediaPlaybackState.paused.hashValue == DDDevice.MediaPlaybackState.paused.hashValue, "hashValue")
    ddExpect(DDDevice.MediaPlaybackState.paused.hashValue != DDDevice.MediaPlaybackState.playing.hashValue, "distinct")
}

func testDDDeviceMediaPlaybackStateToString() {
    ddExpect(DDDeviceMediaPlaybackStateToString(.noContent) == "DDDeviceMediaPlaybackStateNoContent", "none")
    ddExpect(DDDeviceMediaPlaybackStateToString(.paused) == "DDDeviceMediaPlaybackStatePaused", "paused")
    ddExpect(DDDeviceMediaPlaybackStateToString(.playing) == "DDDeviceMediaPlaybackStatePlaying", "playing")
}
