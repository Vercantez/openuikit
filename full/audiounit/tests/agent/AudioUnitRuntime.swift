@_spi(AudioUnitLinux) import AudioUnit

func expectEqual<T: Equatable>(_ actual: T, _ expected: T, _ label: String) {
    if actual != expected {
        fatalError("\(label): expected \(expected), got \(actual)")
    }
}

func expectTrue(_ value: Bool, _ label: String) {
    if !value {
        fatalError("\(label): expected true")
    }
}

func expectFalse(_ value: Bool, _ label: String) {
    if value {
        fatalError("\(label): expected false")
    }
}

func expectThrows(_ work: () throws -> Void, _ label: String) -> AudioUnitLinuxHostError {
    do {
        try work()
        fatalError("\(label): expected throw")
    } catch let error as AudioUnitLinuxHostError {
        return error
    } catch {
        fatalError("\(label): unexpected error \(error)")
    }
}

// MARK: - AUDIO_UNIT_VERSION (pinned public surface)

expectEqual(AUDIO_UNIT_VERSION, Int32(1070), "AUDIO_UNIT_VERSION value")
expectTrue(AUDIO_UNIT_VERSION >= AudioUnitLinuxHost.audioComponentAPIFloor, "Audio Component-era floor")
expectEqual(AUDIO_UNIT_VERSION, AUDIO_UNIT_VERSION, "AUDIO_UNIT_VERSION is stable")

let version: Int32 = AUDIO_UNIT_VERSION
expectEqual(version, 1070, "AUDIO_UNIT_VERSION binds as Int32")
expectTrue(version > 0, "AUDIO_UNIT_VERSION is a positive header constant")

// MARK: - Linux host SPI is fail-closed

expectFalse(AudioUnitLinuxHost.pluginHostingAvailable, "plugin hosting")
expectFalse(AudioUnitLinuxHost.realtimeRenderAvailable, "realtime render")
expectFalse(AudioUnitLinuxHost.appleSystemUnitsAvailable, "Apple system units")
expectEqual(AudioUnitLinuxHost.audioComponentAPIFloor, Int32(1060), "1060 Component Manager threshold")

let pluginError = expectThrows({
    try AudioUnitLinuxHost.requirePluginHosting()
}, "requirePluginHosting")
expectEqual(pluginError, .pluginHostingUnavailable, "plugin hosting error")

let realtimeError = expectThrows({
    try AudioUnitLinuxHost.requireRealtimeRender()
}, "requireRealtimeRender")
expectEqual(realtimeError, .realtimeRenderUnavailable, "realtime render error")

// Pocket Casts EffectsPlayer constructs Apple AU subtypes by four-character
// code. Those named constants belong to AudioToolbox; Linux must not instantiate
// them. 'hpas' is the public HighPassFilter subtype fourcc.
let highPassFourCC = UInt32(0x68706173)
let unitError = expectThrows({
    try AudioUnitLinuxHost.instantiateAppleSystemUnit(subtypeFourCC: highPassFourCC)
}, "instantiateAppleSystemUnit")
expectEqual(
    unitError,
    .appleSystemUnitUnavailable(subtypeFourCC: highPassFourCC),
    "Apple system unit error"
)

print("AUDIOUNIT_AGENT_RUNTIME_OK")
