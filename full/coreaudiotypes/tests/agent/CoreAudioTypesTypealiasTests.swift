import CoreAudioTypes

private func require(_ condition: Bool, _ message: String) {
    if !condition {
        fatalError("COREAUDIOTYPES_TEST_FAIL: \(message)")
    }
}

private func requireEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String) {
    require(actual == expected, "\(message): \(actual) != \(expected)")
}

func testTypealiases() {
    requireEqual(MemoryLayout<AudioChannelLabel>.size, 4, "AudioChannelLabel")
    requireEqual(MemoryLayout<AudioChannelLayoutTag>.size, 4, "AudioChannelLayoutTag")
    requireEqual(MemoryLayout<AudioFormatID>.size, 4, "AudioFormatID")
    requireEqual(MemoryLayout<AudioFormatFlags>.size, 4, "AudioFormatFlags")
    requireEqual(MemoryLayout<AudioSampleType>.size, 2, "AudioSampleType")
    requireEqual(MemoryLayout<AudioUnitSampleType>.size, 4, "AudioUnitSampleType")
    requireEqual(MemoryLayout<AudioSessionID>.size, 4, "AudioSessionID")
    requireEqual(MemoryLayout<AVAudioInteger>.size, MemoryLayout<Int>.size, "AVAudioInteger")
    requireEqual(MemoryLayout<AVAudioUInteger>.size, MemoryLayout<UInt>.size, "AVAudioUInteger")
    let label: AudioChannelLabel = kAudioChannelLabel_Left
    let tag: AudioChannelLayoutTag = kAudioChannelLayoutTag_Stereo
    let format: AudioFormatID = kAudioFormatLinearPCM
    let flags: AudioFormatFlags = kAudioFormatFlagIsPacked
    let sample: AudioSampleType = -1
    let unitSample: AudioUnitSampleType = 1
    let session: AudioSessionID = 7
    let avInt: AVAudioInteger = -50
    let avUInt: AVAudioUInteger = 4
    requireEqual(label, 1, "label value")
    requireEqual(tag, kAudioChannelLayoutTag_Stereo, "tag value")
    requireEqual(format, kAudioFormatLinearPCM, "format value")
    requireEqual(flags, 8, "flags value")
    requireEqual(sample, -1, "sample value")
    requireEqual(unitSample, 1, "unit sample value")
    requireEqual(session, 7, "session value")
    requireEqual(avInt, -50, "AVAudioInteger value")
    requireEqual(avUInt, 4, "AVAudioUInteger value")
}
