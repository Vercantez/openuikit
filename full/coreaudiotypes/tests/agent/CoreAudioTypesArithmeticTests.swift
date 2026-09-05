import CoreAudioTypes

private func require(_ condition: Bool, _ message: String) {
    if !condition {
        fatalError("COREAUDIOTYPES_TEST_FAIL: \(message)")
    }
}

private func requireEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String) {
    require(actual == expected, "\(message): \(actual) != \(expected)")
}

func testGetNumberOfChannels() {
    requireEqual(
        AudioChannelLayoutTag_GetNumberOfChannels(kAudioChannelLayoutTag_Mono),
        1,
        "mono"
    )
    requireEqual(
        AudioChannelLayoutTag_GetNumberOfChannels(kAudioChannelLayoutTag_Stereo),
        2,
        "stereo"
    )
    requireEqual(
        AudioChannelLayoutTag_GetNumberOfChannels(kAudioChannelLayoutTag_UseChannelDescriptions),
        0,
        "use descriptions"
    )
    requireEqual(
        AudioChannelLayoutTag_GetNumberOfChannels(kAudioChannelLayoutTag_UseChannelBitmap),
        0,
        "use bitmap"
    )
    let packed: AudioChannelLayoutTag = (200 << 16) | 12
    requireEqual(AudioChannelLayoutTag_GetNumberOfChannels(packed), 12, "packed 12")
    requireEqual(AudioChannelLayoutTag_GetNumberOfChannels(0xFFFF), 0xFFFF, "low 16 mask")
    requireEqual(AudioChannelLayoutTag_GetNumberOfChannels(0x0001_0000), 0, "high bits ignored")
}
