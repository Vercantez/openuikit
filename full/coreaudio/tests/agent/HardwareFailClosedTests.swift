import CoreAudio
import Foundation

func testAudioObjectHasPropertyIsFalse() {
    var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDevices)
    coreAudioExpect(!CoreAudioHardware.isAvailable, "HAL unavailable")
    coreAudioExpect(
        AudioObjectHasProperty(kAudioObjectSystemObject, &address) == false,
        "AudioObjectHasProperty is false"
    )
    coreAudioExpect(AudioObjectExists(kAudioObjectSystemObject) == false, "AudioObjectExists is false")
    coreAudioExpect(kAudioObjectUnknown == 0, "unknown object id")
}

func testAudioObjectPropertyQueriesFailClosed() {
    var address = AudioObjectPropertyAddress(
        mSelector: kAudioHardwarePropertyDefaultOutputDevice,
        mScope: kAudioObjectPropertyScopeOutput,
        mElement: kAudioObjectPropertyElementMain
    )
    var settable = DarwinBoolean(true)
    coreAudioExpect(
        AudioObjectIsPropertySettable(kAudioObjectSystemObject, &address, &settable)
            == kAudioHardwareUnsupportedOperationError,
        "settable status"
    )
    coreAudioExpect(settable.boolValue == false, "settable out-parameter")

    var dataSize: UInt32 = 99
    coreAudioExpect(
        AudioObjectGetPropertyDataSize(kAudioObjectSystemObject, &address, 0, nil, &dataSize)
            == kAudioHardwareUnsupportedOperationError,
        "get size status"
    )
    coreAudioExpect(dataSize == 0, "get size does not invent a payload")

    var dummy: UInt32 = 0xFFFF_FFFF
    var ioSize: UInt32 = 4
    coreAudioExpect(
        AudioObjectGetPropertyData(kAudioObjectSystemObject, &address, 0, nil, &ioSize, &dummy)
            == kAudioHardwareUnsupportedOperationError,
        "get data status"
    )
    coreAudioExpect(ioSize == 0, "get data does not invent a size")
    coreAudioExpect(
        AudioObjectSetPropertyData(kAudioObjectSystemObject, &address, 0, nil, 4, &dummy)
            == kAudioHardwareUnsupportedOperationError,
        "set data status"
    )
}

func testAudioObjectListenersFailClosed() {
    var address = AudioObjectPropertyAddress(mSelector: kAudioHardwarePropertyDefaultInputDevice)
    let listener: AudioObjectPropertyListenerProc = { _, _, _, _ in kAudio_NoError }
    coreAudioExpect(
        AudioObjectAddPropertyListener(kAudioObjectSystemObject, &address, listener, nil)
            == kAudioHardwareUnsupportedOperationError,
        "add listener"
    )
    coreAudioExpect(
        AudioObjectRemovePropertyListener(kAudioObjectSystemObject, &address, listener, nil)
            == kAudioHardwareUnsupportedOperationError,
        "remove listener"
    )
}

func testHardwareErrorFourCCValues() {
    let rows: [(OSStatus, UInt32)] = [
        (kAudio_NoError, 0),
        (kAudioHardwareNoError, 0),
        (kAudioHardwareUnspecifiedError, 0x77686174), // 'what'
        (kAudioHardwareUnsupportedOperationError, 0x756E6F70), // 'unop'
        (kAudioHardwareUnknownPropertyError, 0x77686F3F), // 'who?'
        (kAudioHardwareNotRunningError, 0x73746F70), // 'stop'
        (kAudioHardwareIllegalOperationError, 0x6E6F7065), // 'nope'
    ]
    for (status, fourCC) in rows {
        coreAudioExpect(status == OSStatus(bitPattern: fourCC), "FourCC \(fourCC)")
    }
    coreAudioExpect(kAudioObjectPropertyScopeGlobal == 0x676C6F62, "glob")
    coreAudioExpect(kAudioObjectPropertyScopeInput == 0x696E7074, "inpt")
    coreAudioExpect(kAudioObjectPropertyScopeOutput == 0x6F757470, "outp")
    coreAudioExpect(kAudioHardwarePropertyDevices == 0x64657623, "dev#")
}

func testHostTimeIsNanosecondsOnLinux() {
    let hostTime = AudioGetCurrentHostTime()
    coreAudioExpect(AudioConvertHostTimeToNanos(hostTime) == hostTime, "host time is nanoseconds")
    coreAudioExpect(AudioConvertNanosToHostTime(hostTime) == hostTime, "nanos conversion identity")
    coreAudioExpect(AudioGetHostClockFrequency() == 1_000_000_000, "1 GHz Linux clock")
    coreAudioExpect(AudioGetHostClockMinimumTimeDelta() == 1, "minimum delta")
    let later = AudioGetCurrentHostTime()
    coreAudioExpect(later >= hostTime, "host time is monotonic")
}
