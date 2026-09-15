import AudioToolbox
import Foundation
#if canImport(CoreFoundation)
import CoreFoundation
#endif

private func wave12Expect(_ condition: Bool, _ message: String) {
    if !condition {
        fatalError(message)
    }
}

private final class ATWave12ProbeBox {
    var calls = 0
    var value: AudioUnitParameterValue = -1
    var eventType: UInt32 = 0
}

private func wave12ProbePointer(_ box: ATWave12ProbeBox) -> UnsafeMutableRawPointer {
    Unmanaged.passUnretained(box).toOpaque()
}

private func wave12ProbeBox(_ client: UnsafeMutableRawPointer?) -> ATWave12ProbeBox {
    Unmanaged<ATWave12ProbeBox>.fromOpaque(client!).takeUnretainedValue()
}

func testWave12VersionAndVoiceConstants() {
    wave12Expect(AUDIO_TOOLBOX_VERSION == 1060, "toolbox version")
    wave12Expect(AUDIO_UNIT_VERSION == 1070, "unit version")
    wave12Expect(AU_SUPPORT_INTERAPP_AUDIO == 1, "interapp audio")
    wave12Expect(kAUPresetNumberKey == "preset-number", "preset key")
    wave12Expect(kAUVoiceIOProperty_DuckNonVoiceAudio == 2102, "duck voice")
    wave12Expect(kAUVoiceIOProperty_OtherAudioDuckingConfiguration == 2108, "duck config")
    wave12Expect(kAUVoiceIOProperty_VoiceProcessingQuality == 2103, "voice quality")
    #if canImport(CoreFoundation)
    wave12Expect(
        kAudioComponentInstanceInvalidationNotification as String
            == "com.apple.coreaudio.AudioComponentInstanceInvalidated",
        "invalidation notification"
    )
    wave12Expect(
        kAudioComponentRegistrationsChangedNotification as String
            == "com.apple.coreaudio.AudioComponentRegistrationsChanged",
        "registrations notification"
    )
    #endif
}

func testWave12AudioUnitEventRecords() {
    let param = AudioUnitParameter(
        mAudioUnit: nil,
        mParameterID: 7,
        mScope: kAudioUnitScope_Global,
        mElement: 2
    )
    let argument = AudioUnitEvent.__Unnamed_union_mArgument(parameter: param)
    wave12Expect(argument.parameter.mParameterID == 7, "argument payload")
    let event = AudioUnitEvent(mEventType: .propertyChange, mArgument: argument)
    wave12Expect(event.mEventType == .propertyChange, "event type")
    wave12Expect(event.mArgument.parameter.mElement == 2, "event argument")
    let zero = AudioUnitEvent()
    wave12Expect(zero.mEventType == .parameterValueChange, "zero event type")
    wave12Expect(zero.mArgument.parameter.mParameterID == 0, "zero argument")
}

func testWave12ZeroInitCatalogA() {
    wave12Expect(MIDIRawData().length == 0, "raw data")
    wave12Expect(AUChannelInfo().inChannels == 0, "channel info")
    wave12Expect(MIDIMetaEvent().dataLength == 0, "meta event")
    wave12Expect(ParameterEvent().value == 0, "parameter event")
    wave12Expect(AudioFileMarker().mFramePosition == 0, "file marker")
    wave12Expect(MIDINoteMessage().duration == 0, "note message")
    wave12Expect(AudioFileMarkerList().mNumberMarkers == 0, "marker list")
    wave12Expect(AUDependentParameter().mParameterID == 0, "dependent parameter")
}

func testWave12ZeroInitCatalogB() {
    wave12Expect(AudioFile_SMPTE_Time().mFrames == 0, "smpte time")
    wave12Expect(AudioUnitMeterClipping().peakValueSinceLastCall == 0, "meter clipping")
    wave12Expect(AURenderCallbackStruct().inputProc == nil, "render callback struct")
    wave12Expect(AURecordedParameterEvent().address == 0, "recorded event")
    wave12Expect(AudioComponentDescription().componentType == 0, "component description")
    wave12Expect(AUParameterAutomationEvent().address == 0, "automation event")
    wave12Expect(AUVoiceIOOtherAudioDuckingConfiguration().mEnableAdvancedDucking == 0, "duck config")
    wave12Expect(AUPreset().presetNumber == 0, "preset")
    wave12Expect(AudioUnitParameterUnit(rawValue: 14) != nil, "unit raw value")
    wave12Expect(AudioUnitParameterUnit(rawValue: UInt32.max) == nil, "unit invalid")
}

func testWave12AURenderEventHeadAndEmpty() {
    let empty = AURenderEvent()
    wave12Expect(empty.head.eventType == .parameter, "empty head type")
    wave12Expect(empty.head.eventSampleTime == 0, "empty head time")
    var head = AURenderEventHeader()
    head.eventSampleTime = 99
    head.eventType = .MIDI
    let event = AURenderEvent(head: head)
    wave12Expect(event.head.eventSampleTime == 99, "head time")
    wave12Expect(event.head.eventType == .MIDI, "head type")
}

func testWave12ListenerTypedefs() {
    let eventBox = ATWave12ProbeBox()
    let eventProc: AUEventListenerProc = { client, _, event, hostTime, value in
        let state = wave12ProbeBox(client)
        state.calls += 1
        state.eventType = event.pointee.mEventType.rawValue
        state.value = value
        _ = hostTime
    }
    var event = AudioUnitEvent()
    withUnsafePointer(to: &event) { pointer in
        eventProc(wave12ProbePointer(eventBox), nil, pointer, 123, 0.5)
    }
    wave12Expect(eventBox.calls == 1, "event proc calls")
    wave12Expect(eventBox.eventType == AudioUnitEventType.parameterValueChange.rawValue, "event type")
    wave12Expect(eventBox.value == 0.5, "event value")
    let eventBlock: AUEventListenerBlock = { _, _, _, _ in }
    withUnsafePointer(to: &event) { pointer in
        eventBlock(nil, pointer, 0, 0)
    }
    let paramBox = ATWave12ProbeBox()
    let paramProc: AUParameterListenerProc = { client, _, parameter, value in
        let state = wave12ProbeBox(client)
        state.calls += 1
        state.value = value
        state.eventType = parameter.pointee.mParameterID
    }
    var param = AudioUnitParameter(
        mAudioUnit: nil,
        mParameterID: 11,
        mScope: kAudioUnitScope_Global,
        mElement: 0
    )
    withUnsafePointer(to: &param) { pointer in
        paramProc(wave12ProbePointer(paramBox), nil, pointer, 0.25)
    }
    wave12Expect(paramBox.calls == 1 && paramBox.value == 0.25, "param proc")
    wave12Expect(paramBox.eventType == 11, "param identity")
    let paramBlock: AUParameterListenerBlock = { _, _, _ in }
    withUnsafePointer(to: &param) { pointer in
        paramBlock(nil, pointer, 0)
    }
}

private func wave12MixerUnit() -> AudioUnit? {
    var description = AudioComponentDescription(
        componentType: kAudioUnitType_Mixer,
        componentSubType: kAudioUnitSubType_MultiChannelMixer,
        componentManufacturer: kAudioUnitManufacturer_Apple,
        componentFlags: 0,
        componentFlagsMask: 0
    )
    let component = AudioComponentFindNext(nil, &description)
    var unit: AudioUnit?
    guard AudioComponentInstanceNew(component, &unit) == 0, let found = unit else {
        return nil
    }
    guard AudioUnitInitialize(found) == 0 else {
        return nil
    }
    return found
}

#if canImport(CoreFoundation)
func testWave12AUListenerRuntime() {
    guard let mixer = wave12MixerUnit() else {
        fatalError("mixer")
    }
    defer { _ = AudioComponentInstanceDispose(mixer) }
    let box = ATWave12ProbeBox()
    let proc: AUParameterListenerProc = { client, _, _, value in
        let state = wave12ProbeBox(client)
        state.calls += 1
        state.value = value
    }
    var listener: AUParameterListenerRef?
    let created = AUListenerCreate(proc, wave12ProbePointer(box), nil, nil, 0.05, &listener)
    wave12Expect(created == 0 && listener != nil, "listener created")
    var param = AudioUnitParameter(
        mAudioUnit: mixer,
        mParameterID: kMultiChannelMixerParam_Volume,
        mScope: kAudioUnitScope_Input,
        mElement: 0
    )
    wave12Expect(
        withUnsafePointer(to: &param) { AUListenerAddParameter(listener, nil, $0) } == 0,
        "parameter added"
    )
    wave12Expect(
        withUnsafePointer(to: &param) { AUParameterListenerNotify(nil, nil, $0) } == 0,
        "notify ok"
    )
    wave12Expect(box.calls == 1 && box.value == 1, "notify delivered current volume")
    wave12Expect(
        withUnsafePointer(to: &param) {
            AUParameterSet(nil, nil, $0, 0.75, 0)
        } == 0,
        "parameter set ok"
    )
    wave12Expect(box.calls == 2 && box.value == 0.75, "set notifies")
    wave12Expect(
        withUnsafePointer(to: &param) {
            AUParameterSet(listener, nil, $0, 0.5, 0)
        } == 0,
        "self-sent set ok"
    )
    wave12Expect(box.calls == 2, "sender is not re-notified")
    var stored: AudioUnitParameterValue = 0
    wave12Expect(
        AudioUnitGetParameter(
            mixer,
            kMultiChannelMixerParam_Volume,
            kAudioUnitScope_Input,
            0,
            &stored
        ) == 0 && stored == 0.5,
        "set stored"
    )
    wave12Expect(
        withUnsafePointer(to: &param) { AUListenerRemoveParameter(listener, nil, $0) } == 0,
        "parameter removed"
    )
    wave12Expect(
        withUnsafePointer(to: &param) { AUParameterListenerNotify(nil, nil, $0) } == 0,
        "notify after remove"
    )
    wave12Expect(box.calls == 2, "no delivery after remove")
    wave12Expect(AUListenerDispose(listener) == 0, "listener disposed")
    wave12Expect(AUListenerDispose(listener) != 0, "double dispose fails")
}
#endif

func testWave12ParameterSetAndFormat() {
    guard let mixer = wave12MixerUnit() else {
        fatalError("mixer")
    }
    defer { _ = AudioComponentInstanceDispose(mixer) }
    var param = AudioUnitParameter(
        mAudioUnit: mixer,
        mParameterID: kMultiChannelMixerParam_Volume,
        mScope: kAudioUnitScope_Input,
        mElement: 1
    )
    wave12Expect(
        withUnsafePointer(to: &param) { AUParameterSet(nil, nil, $0, 0.5, 0) } == 0,
        "anonymous set"
    )
    var bad = AudioUnitParameter(
        mAudioUnit: nil,
        mParameterID: 0,
        mScope: kAudioUnitScope_Global,
        mElement: 0
    )
    wave12Expect(
        withUnsafePointer(to: &bad) { AUParameterSet(nil, nil, $0, 0.5, 0) } != 0,
        "unknown unit fails"
    )
    var text = [CChar](repeating: 0, count: 32)
    let formatted: UnsafeMutablePointer<CChar>? = withUnsafePointer(to: &param) { pointer in
        text.withUnsafeMutableBufferPointer { buffer in
            AUParameterFormatValue(0.75123, pointer, buffer.baseAddress!, 3)
        }
    }
    wave12Expect(formatted != nil, "format returns buffer")
    let rendered = text.withUnsafeBufferPointer { String(cString: $0.baseAddress!) }
    wave12Expect(rendered == "0.75", "oracle format")
    var wide = [CChar](repeating: 0, count: 32)
    withUnsafePointer(to: &param) { pointer in
        wide.withUnsafeMutableBufferPointer { buffer in
            _ = AUParameterFormatValue(-2.5, pointer, buffer.baseAddress!, 4)
        }
    }
    let renderedWide = wide.withUnsafeBufferPointer { String(cString: $0.baseAddress!) }
    wave12Expect(renderedWide == "-2.500", "oracle negative format")
}

#if canImport(CoreFoundation)
func testWave12AUEventListenerRuntime() {
    guard let mixer = wave12MixerUnit() else {
        fatalError("mixer")
    }
    defer { _ = AudioComponentInstanceDispose(mixer) }
    let box = ATWave12ProbeBox()
    let proc: AUEventListenerProc = { client, _, event, _, value in
        let state = wave12ProbeBox(client)
        state.calls += 1
        state.eventType = event.pointee.mEventType.rawValue
        state.value = value
    }
    var listener: AUEventListenerRef?
    let created = AUEventListenerCreate(
        proc,
        wave12ProbePointer(box),
        nil,
        nil,
        0.05,
        0.01,
        &listener
    )
    wave12Expect(created == 0 && listener != nil, "event listener created")
    let param = AudioUnitParameter(
        mAudioUnit: mixer,
        mParameterID: kMultiChannelMixerParam_Volume,
        mScope: kAudioUnitScope_Input,
        mElement: 0
    )
    var event = AudioUnitEvent(
        mEventType: .parameterValueChange,
        mArgument: AudioUnitEvent.__Unnamed_union_mArgument(parameter: param)
    )
    wave12Expect(
        withUnsafePointer(to: &event) { AUEventListenerAddEventType(listener, nil, $0) } == 0,
        "event type added"
    )
    wave12Expect(
        withUnsafePointer(to: &event) { AUEventListenerNotify(nil, nil, $0) } == 0,
        "event notify ok"
    )
    wave12Expect(box.calls == 1, "event delivered")
    wave12Expect(
        box.eventType == AudioUnitEventType.parameterValueChange.rawValue,
        "event type delivered"
    )
    wave12Expect(box.value == 1, "event carries current volume")
    wave12Expect(
        withUnsafePointer(to: &event) { AUEventListenerRemoveEventType(listener, nil, $0) } == 0,
        "event type removed"
    )
    wave12Expect(
        withUnsafePointer(to: &event) { AUEventListenerNotify(nil, nil, $0) } == 0,
        "notify after remove"
    )
    wave12Expect(box.calls == 1, "no event after remove")
    wave12Expect(AUListenerDispose(listener) == 0, "event listener disposed")
}
#endif

#if canImport(CoreFoundation)
func testWave12ComponentInfoFailClosed() {
    var description = AudioComponentDescription(
        componentType: kAudioUnitType_Mixer,
        componentSubType: kAudioUnitSubType_MultiChannelMixer,
        componentManufacturer: kAudioUnitManufacturer_Apple,
        componentFlags: 0,
        componentFlagsMask: 0
    )
    let component = AudioComponentFindNext(nil, &description)
    wave12Expect(component != nil, "mixer component")
    var info: Unmanaged<CFDictionary>?
    wave12Expect(
        AudioComponentCopyConfigurationInfo(component, &info) != 0 && info == nil,
        "config info fail-closed"
    )
    wave12Expect(
        AudioComponentCopyConfigurationInfo(nil, &info) != 0 && info == nil,
        "config info unknown"
    )
    wave12Expect(AudioComponentGetLastActiveTime(component) == 0, "last active untracked")
    wave12Expect(AudioComponentGetLastActiveTime(nil) == 0, "last active unknown")
    var completed = false
    var completedResult = AudioComponentValidationResult.unknown
    var completedCount = -1
    let status = AudioComponentValidateWithResults(component, nil) { result, dict in
        completed = true
        completedResult = result
        completedCount = CFDictionaryGetCount(dict)
    }
    wave12Expect(status != 0, "validate status fail-closed")
    wave12Expect(completed && completedResult == .failed, "validate completion failed")
    wave12Expect(completedCount == 0, "validate dict empty")
    wave12Expect(
        AudioUnitExtensionCopyComponentList("com.example.never" as CFString) == nil,
        "extension list nil"
    )
    wave12Expect(
        AudioUnitExtensionSetComponentList("com.example.never" as CFString, nil) != 0,
        "extension set fail-closed"
    )
}
#endif

func testWave12CAShowDoesNotThrow() {
    var storage: UInt8 = 0
    withUnsafeMutablePointer(to: &storage) { pointer in
        CAShow(UnsafeMutableRawPointer(pointer))
    }
    CAShow(nil)
}

func testWave12MusicHostTimeAndInfo() {
    var sequence: MusicSequence?
    wave12Expect(NewMusicSequence(&sequence) == 0 && sequence != nil, "sequence")
    defer { _ = DisposeMusicSequence(sequence) }
    var player: MusicPlayer?
    wave12Expect(NewMusicPlayer(&player) == 0 && player != nil, "player")
    defer { _ = DisposeMusicPlayer(player) }
    wave12Expect(MusicPlayerSetSequence(player, sequence) == 0, "attach")
    wave12Expect(MusicPlayerSetTime(player, 4.0) == 0, "set time")
    var host: UInt64 = 0
    wave12Expect(MusicPlayerGetHostTimeForBeats(player, 6.0, &host) == 0, "host for beats")
    wave12Expect(host > 0, "host nonzero")
    var beats: MusicTimeStamp = 0
    wave12Expect(MusicPlayerGetBeatsForHostTime(player, host, &beats) == 0, "beats for host")
    wave12Expect(abs(beats - 6.0) < 0.1, "host round trip")
    wave12Expect(
        MusicPlayerGetHostTimeForBeats(nil, 6.0, &host) != 0,
        "unknown player host fails"
    )
    wave12Expect(
        MusicPlayerGetBeatsForHostTime(nil, host, &beats) != 0,
        "unknown player beats fails"
    )
    wave12Expect(MusicSequenceSetSMPTEResolution(25, 96) == -6304, "oracle smpte encode")
    var fps: Int8 = 0
    var ticks: UInt8 = 0
    MusicSequenceGetSMPTEResolution(-6304, &fps, &ticks)
    wave12Expect(fps == -25 && ticks == 96, "oracle smpte decode")
    #if canImport(CoreFoundation)
    let info = MusicSequenceGetInfoDictionary(sequence)
    wave12Expect(CFDictionaryGetCount(info) == 1, "info count")
    var tempo: Double = 0
    if let raw = CFDictionaryGetValue(info, Unmanaged.passUnretained("tempo" as CFString).toOpaque()) {
        tempo = Unmanaged<NSNumber>.fromOpaque(raw).takeUnretainedValue().doubleValue
    }
    wave12Expect(tempo == 120, "info tempo")
    #endif
}

func testWave12MusicDestinationsAndEvents() {
    var sequence: MusicSequence?
    wave12Expect(NewMusicSequence(&sequence) == 0 && sequence != nil, "sequence")
    defer { _ = DisposeMusicSequence(sequence) }
    var track: MusicTrack?
    wave12Expect(MusicSequenceNewTrack(sequence, &track) == 0 && track != nil, "track")
    let callback: MusicSequenceUserCallback = { _, _, _, _, _, _, _ in }
    wave12Expect(MusicSequenceSetUserCallback(sequence, callback, nil) == 0, "user callback")
    wave12Expect(MusicSequenceSetUserCallback(nil, callback, nil) != 0, "user callback unknown")
    wave12Expect(MusicTrackSetDestNode(track, 42) == 0, "set dest node")
    var node: AUNode = 0
    wave12Expect(MusicTrackGetDestNode(track, &node) == 0 && node == 42, "get dest node")
    wave12Expect(MusicTrackGetDestNode(nil, &node) != 0, "dest node unknown")
    var bare: MusicTrack?
    wave12Expect(MusicSequenceNewTrack(sequence, &bare) == 0 && bare != nil, "bare track")
    wave12Expect(MusicTrackGetDestNode(bare, &node) != 0, "dest node unset")
    var note = ExtendedNoteOnEvent()
    note.duration = 1.5
    wave12Expect(
        withUnsafePointer(to: &note) { MusicTrackNewExtendedNoteEvent(track, 3.0, $0) } == 0,
        "extended note"
    )
    var userData = MusicEventUserData(length: 1, data: 0x7f)
    wave12Expect(
        withUnsafePointer(to: &userData) { MusicTrackNewUserEvent(track, 4.0, $0) } == 0,
        "user event"
    )
    var iterator: MusicEventIterator?
    wave12Expect(NewMusicEventIterator(track, &iterator) == 0, "iterator")
    var hasEvent: UInt8 = 0
    wave12Expect(
        MusicEventIteratorHasCurrentEvent(iterator, &hasEvent) == 0 && hasEvent != 0,
        "has event"
    )
    wave12Expect(DisposeMusicEventIterator(iterator) == 0, "dispose iterator")
}

func testWave12ConverterSpecificAndRealtime() {
    let inputProc: AudioConverterInputDataProc = { _, count, _, _ in
        count.pointee = 4
        return 1
    }
    var packets: UInt32 = 0
    let ioStorage = UnsafeMutableRawPointer.allocate(byteCount: 8, alignment: 8)
    defer { ioStorage.deallocate() }
    var slot: UnsafeMutableRawPointer = ioStorage
    let status = withUnsafeMutablePointer(to: &packets) { count in
        withUnsafeMutablePointer(to: &slot) { storage in
            inputProc(OpaquePointer(bitPattern: 0x7000)!, count, storage, nil)
        }
    }
    wave12Expect(status == 1 && packets == 4, "input proc passthrough")
    let safeProc: AudioConverterComplexInputDataProcRealtimeSafe = { _, _, _, _, _ in 0 }
    wave12Expect(
        safeProc(nil, nil, nil, nil, nil) == 0,
        "realtime safe proc invoked"
    )
    wave12Expect(
        AudioConverterNewSpecific(nil, nil, 0, nil, nil) != 0,
        "specific nil formats fail"
    )
    wave12Expect(
        AudioConverterFillComplexBufferRealtimeSafe(nil, safeProc, nil, nil, nil, nil) != 0,
        "realtime safe unknown converter fails"
    )
    var empty: UInt32 = 0
    wave12Expect(
        AudioConverterFillComplexBufferWithPacketDependencies(nil, nil, nil, &empty, nil, nil, nil)
            != 0,
        "packet dependency unknown converter fails"
    )
}

func testWave12FileAndQueueDelegates() {
    var packets: UInt32 = 0
    wave12Expect(
        AudioFileWritePacketsWithDependencies(nil, false, 0, nil, nil, 0, &packets, nil) != 0,
        "dependency write unknown fails"
    )
    wave12Expect(AudioQueueSetOfflineRenderFormat(nil, nil, nil) != 0, "offline format unknown")
}

func testWave12AudioUnitProcTypedefs() {
    let render: AudioUnitRenderProc = { _, _, _, _, _, _ in -50 }
    wave12Expect(render(nil, nil, nil, 0, 0, nil) == -50, "render proc")
    let process: AudioUnitProcessProc = { _, _, _, _, _ in -51 }
    wave12Expect(process(nil, nil, nil, 0, nil) == -51, "process proc")
    let multiple: AudioUnitProcessMultipleProc = { _, _, _, _, _, _, _, _ in -52 }
    wave12Expect(multiple(nil, nil, nil, 0, 0, nil, 0, nil) == -52, "process multiple")
    let complex: AudioUnitComplexRenderProc = { _, _, _, _, _, _, _, _, _, _ in -53 }
    wave12Expect(complex(nil, nil, nil, 0, 0, nil, nil, nil, nil, nil) == -53, "complex render")
    let initialize: AudioUnitInitializeProc = { _ in 0 }
    var ioStorage: UInt8 = 0
    wave12Expect(
        withUnsafeMutablePointer(to: &ioStorage) { initialize(UnsafeMutableRawPointer($0)) } == 0,
        "initialize proc"
    )
    let uninitialize: AudioUnitUninitializeProc = { _ in 0 }
    wave12Expect(
        withUnsafeMutablePointer(to: &ioStorage) { uninitialize(UnsafeMutableRawPointer($0)) } == 0,
        "uninitialize proc"
    )
    let reset: AudioUnitResetProc = { _, _, _ in 0 }
    wave12Expect(
        withUnsafeMutablePointer(to: &ioStorage) { reset(UnsafeMutableRawPointer($0), 1, 2) } == 0,
        "reset proc"
    )
    let getParameter: AudioUnitGetParameterProc = { _, _, _, _, value in
        value.pointee = 0.5
        return 0
    }
    var parameter: AudioUnitParameterValue = 0
    wave12Expect(
        withUnsafeMutablePointer(to: &ioStorage) { storage in
            withUnsafeMutablePointer(to: &parameter) { slot in
                getParameter(UnsafeMutableRawPointer(storage), 7, 1, 0, slot)
            }
        } == 0 && parameter == 0.5,
        "get parameter proc"
    )
    let setParameter: AudioUnitSetParameterProc = { _, _, _, _, _, _ in 0 }
    wave12Expect(
        withUnsafeMutablePointer(to: &ioStorage) {
            setParameter(UnsafeMutableRawPointer($0), 7, 1, 0, 0.5, 0)
        } == 0,
        "set parameter proc"
    )
    let getProperty: AudioUnitGetPropertyProc = { _, _, _, _, _, size in
        size.pointee = 8
        return 0
    }
    var size: UInt32 = 0
    wave12Expect(
        withUnsafeMutablePointer(to: &ioStorage) { storage in
            withUnsafeMutablePointer(to: &size) { slot in
                getProperty(
                    UnsafeMutableRawPointer(storage),
                    9,
                    1,
                    0,
                    UnsafeMutableRawPointer(storage),
                    slot
                )
            }
        } == 0 && size == 8,
        "get property proc"
    )
    let setProperty: AudioUnitSetPropertyProc = { _, _, _, _, _, _ in 0 }
    wave12Expect(
        withUnsafeMutablePointer(to: &ioStorage) {
            setProperty(
                UnsafeMutableRawPointer($0),
                9,
                1,
                0,
                UnsafeRawPointer($0),
                4
            )
        } == 0,
        "set property proc"
    )
    let getPropertyInfo: AudioUnitGetPropertyInfoProc = { _, _, _, _, size, writable in
        size?.pointee = 4
        writable?.pointee = 1
        return 0
    }
    var infoSize: UInt32 = 0
    var writable: UInt8 = 0
    wave12Expect(
        withUnsafeMutablePointer(to: &ioStorage) { storage in
            withUnsafeMutablePointer(to: &infoSize) { sizeSlot in
                withUnsafeMutablePointer(to: &writable) { writableSlot in
                    getPropertyInfo(
                        UnsafeMutableRawPointer(storage),
                        9,
                        1,
                        0,
                        sizeSlot,
                        writableSlot
                    )
                }
            }
        } == 0 && infoSize == 4 && writable == 1,
        "get property info proc"
    )
}

func testWave12AnchoredProcTypedefs() {
    let addProperty: AudioUnitAddPropertyListenerProc = { _, _, _, _ in -50 }
    var ioStorage: UInt8 = 0
    wave12Expect(
        withUnsafeMutablePointer(to: &ioStorage) {
            addProperty(UnsafeMutableRawPointer($0), 3, { _, _, _, _, _ in }, nil)
        } == -50,
        "add property listener proc"
    )
    let removeProperty: AudioUnitRemovePropertyListenerProc = { _, _, _ in -51 }
    wave12Expect(
        withUnsafeMutablePointer(to: &ioStorage) {
            removeProperty(UnsafeMutableRawPointer($0), 3, { _, _, _, _, _ in })
        } == -51,
        "remove property listener proc"
    )
    let removeWithData: AudioUnitRemovePropertyListenerWithUserDataProc = { _, _, _, _ in -52 }
    wave12Expect(
        withUnsafeMutablePointer(to: &ioStorage) {
            removeWithData(UnsafeMutableRawPointer($0), 3, { _, _, _, _, _ in }, nil)
        } == -52,
        "remove property listener with data proc"
    )
}

func testWave12OutputAndQueueBlocks() {
    let start: AudioOutputUnitStartProc = { _ in 0 }
    let stop: AudioOutputUnitStopProc = { _ in 0 }
    var ioStorage: UInt8 = 0
    wave12Expect(
        withUnsafeMutablePointer(to: &ioStorage) { start(UnsafeMutableRawPointer($0)) } == 0,
        "start proc"
    )
    wave12Expect(
        withUnsafeMutablePointer(to: &ioStorage) { stop(UnsafeMutableRawPointer($0)) } == 0,
        "stop proc"
    )
    let queue = OpaquePointer(bitPattern: 0x6000)!
    let block: AudioQueueOutputCallbackBlock = { callbackQueue, _ in
        wave12Expect(callbackQueue == queue, "output block queue")
    }
    let storage = UnsafeMutableRawPointer.allocate(byteCount: 1, alignment: 1)
    defer { storage.deallocate() }
    var buffer = AudioQueueBuffer(
        mAudioDataBytesCapacity: 1,
        mAudioData: storage,
        mAudioDataByteSize: 0,
        mUserData: nil,
        mPacketDescriptionCapacity: 0,
        mPacketDescriptions: nil,
        mPacketDescriptionCount: 0
    )
    withUnsafeMutablePointer(to: &buffer) { pointer in
        block(queue, pointer)
    }
    let inputBlock: AudioQueueInputCallbackBlock = { _, callbackQueue, _, _, count, _ in
        wave12Expect(callbackQueue == queue && count == 2, "input block")
    }
    withUnsafeMutablePointer(to: &buffer) { pointer in
        inputBlock(nil, queue, pointer, nil, 2, nil)
    }
    var flags = AudioQueueProcessingTapFlags()
    var packetCount: UInt32 = 3
    let tap: AudioQueueProcessingTapCallback = { _, _, frames, _, tapFlags, count, _ in
        tapFlags?.pointee = .siphon
        count?.pointee = 0
        wave12Expect(frames == 64, "tap frames")
    }
    let tapRef = OpaquePointer(bitPattern: 0x6001)!
    withUnsafeMutablePointer(to: &flags) { flagsSlot in
        withUnsafeMutablePointer(to: &packetCount) { countSlot in
            tap(nil, tapRef, 64, nil, flagsSlot, countSlot, nil)
        }
    }
    wave12Expect(flags == .siphon && packetCount == 0, "tap outputs")
}

func testWave12HostBlocksAndAliases() {
    let context: AUHostMusicalContextBlock = { tempo, _, _, _, _, _ in
        tempo?.pointee = 120
        return true
    }
    var tempo: Double = 0
    wave12Expect(
        withUnsafeMutablePointer(to: &tempo) {
            context($0, nil, nil, nil, nil, nil)
        } && tempo == 120,
        "musical context"
    )
    let transport: AUHostTransportStateBlock = { state, _, _, _ in
        state?.pointee = []
        return false
    }
    var state = AUHostTransportStateFlags(rawValue: 7)
    wave12Expect(
        withUnsafeMutablePointer(to: &state) { transport($0, nil, nil, nil) } == false
            && state == [],
        "transport state"
    )
    let midiBytes: [UInt8] = [0x90, 0x40, 0x7F]
    let midiOut: AUMIDIOutputEventBlock = { sampleTime, cable, length, bytes in
        wave12Expect(sampleTime == 11 && cable == 3 && length == 3, "midi out header")
        wave12Expect(bytes[0] == 0x90, "midi out payload")
        return 0
    }
    wave12Expect(
        midiBytes.withUnsafeBufferPointer { midiOut(11, 3, $0.count, $0.baseAddress!) } == 0,
        "midi out"
    )
    let scheduleMIDI: AUScheduleMIDIEventBlock = { _, _, _, _ in }
    midiBytes.withUnsafeBufferPointer { scheduleMIDI(5, 0, $0.count, $0.baseAddress!) }
    let scheduleParam: AUScheduleParameterBlock = { sampleTime, frames, address, value in
        wave12Expect(sampleTime == 6 && frames == 128 && address == 9 && value == 0.5, "schedule param")
    }
    scheduleParam(6, 128, 9, 0.5)
    let host: CallHostBlock = { message in message }
    wave12Expect(host(["k": 1])["k"] as? Int == 1, "call host echo")
    let cookie = AudioCodecMagicCookieInfo(mMagicCookieSize: 9, mMagicCookie: nil)
    let aliased: MagicCookieInfo = cookie
    wave12Expect(aliased.mMagicCookieSize == 9, "magic cookie alias")
    let channel: MIDIChannelNumber = 15
    wave12Expect(channel == 15, "midi channel")
    let remote: AudioUnitRemoteControlEventListener = { event in
        wave12Expect(event == .rewind, "remote event")
    }
    remote(.rewind)
    let speech: AUVoiceIOMutedSpeechActivityEventListener = { event in
        wave12Expect(event == .hasEnded, "speech event")
    }
    speech(.hasEnded)
}

func testWave12AUAudioUnitCompletionAndChannel() {
    let good = AudioComponentDescription(
        componentType: kAudioUnitType_Mixer,
        componentSubType: kAudioUnitSubType_MultiChannelMixer,
        componentManufacturer: kAudioUnitManufacturer_Apple,
        componentFlags: 0,
        componentFlagsMask: 0
    )
    var madeUnit: AUAudioUnit?
    var madeError: (any Error)?
    AUAudioUnit.instantiate(with: good, options: []) { unit, error in
        madeUnit = unit
        madeError = error
    }
    wave12Expect(madeUnit != nil && madeError == nil, "completion success")
    let bad = AudioComponentDescription(
        componentType: kAudioUnitType_Output,
        componentSubType: kAudioUnitSubType_RemoteIO,
        componentManufacturer: kAudioUnitManufacturer_Apple,
        componentFlags: 0,
        componentFlagsMask: 0
    )
    var failedUnit: AUAudioUnit?
    var failedError: (any Error)?
    AUAudioUnit.instantiate(with: bad, options: []) { unit, error in
        failedUnit = unit
        failedError = error
    }
    wave12Expect(failedUnit == nil && failedError != nil, "completion failure")
    guard let unit = madeUnit else {
        fatalError("unit")
    }
    let channel = unit.messageChannel(for: "wave12")
    let echo: CallHostBlock = { message in message }
    channel.callHostBlock = echo
    wave12Expect(channel.callAudioUnit(["ping": 7])["ping"] as? Int == 7, "channel echo")
    channel.callHostBlock = nil
    wave12Expect(channel.callAudioUnit(["ping": 7]).isEmpty, "channel empty")
}

func testWave12AUAudioUnitBlockProperties() {
    let description = AudioComponentDescription(
        componentType: kAudioUnitType_Mixer,
        componentSubType: kAudioUnitSubType_MultiChannelMixer,
        componentManufacturer: kAudioUnitManufacturer_Apple,
        componentFlags: 0,
        componentFlagsMask: 0
    )
    guard let unit = try? AUAudioUnit(componentDescription: description, options: []) else {
        fatalError("unit")
    }
    let parameter = AUParameterTree.createParameter(
        withIdentifier: "wave12",
        name: "Wave12",
        address: 77,
        min: 0,
        max: 1,
        unit: .generic,
        unitName: nil,
        valueStrings: nil,
        dependentParameters: nil
    )
    unit.parameterTree.children.append(parameter)
    unit.scheduleParameterBlock(10, 64, 77, 0.75)
    wave12Expect(parameter.value == 0.75, "scheduled parameter applied")
    unit.scheduleParameterBlock(10, 64, 78, 0.25)
    wave12Expect(parameter.value == 0.75, "unknown address ignored")
    wave12Expect(unit.scheduleMIDIEventBlock == nil, "midi schedule nil")
    var contextTempo: Double = 0
    unit.musicalContextBlock = { tempo, _, _, _, _, _ in
        tempo?.pointee = 122
        contextTempo = tempo?.pointee ?? 0
        return true
    }
    var tempo: Double = 0
    let contextFired = withUnsafeMutablePointer(to: &tempo) { pointer in
        unit.musicalContextBlock?(pointer, nil, nil, nil, nil, nil) ?? false
    }
    wave12Expect(contextFired && contextTempo == 122, "musical context stored")
    unit.transportStateBlock = { _, _, _, _ in false }
    wave12Expect(unit.transportStateBlock != nil, "transport stored")
    unit.transportStateBlock = nil
    wave12Expect(unit.transportStateBlock == nil, "transport cleared")
    var midiStatus: Int32 = -1
    unit.midiOutputEventBlock = { _, _, _, _ in
        midiStatus = 0
        return 0
    }
    let midiBytes: [UInt8] = [0x80, 0x40, 0x00]
    midiBytes.withUnsafeBufferPointer {
        _ = unit.midiOutputEventBlock?(4, 0, $0.count, $0.baseAddress!)
    }
    wave12Expect(midiStatus == 0, "midi output stored")
}
