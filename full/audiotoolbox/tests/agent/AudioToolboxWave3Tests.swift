#if canImport(CoreFoundation)
import CoreFoundation
#endif
#if canImport(Glibc)
import Glibc
#endif
import Foundation
import AudioToolbox

private func atW3Expect(_ condition: Bool, _ message: String) {
    if !condition {
        fatalError(message)
    }
}

private func atW3PCMBlob(
    rate: Float64,
    channels: UInt32 = 1,
    bits: UInt32 = 32,
    flags: UInt32 = 9
) -> [UInt8] {
    var blob = [UInt8](repeating: 0, count: 40)
    let bytesPerSample = bits / 8
    blob.withUnsafeMutableBytes { raw in
        let p = raw.baseAddress!
        p.storeBytes(of: rate, toByteOffset: 0, as: Float64.self)
        p.storeBytes(of: UInt32(0x6C70_636D), toByteOffset: 8, as: UInt32.self)
        p.storeBytes(of: flags, toByteOffset: 12, as: UInt32.self)
        p.storeBytes(of: bytesPerSample * channels, toByteOffset: 16, as: UInt32.self)
        p.storeBytes(of: UInt32(1), toByteOffset: 20, as: UInt32.self)
        p.storeBytes(of: bytesPerSample * channels, toByteOffset: 24, as: UInt32.self)
        p.storeBytes(of: channels, toByteOffset: 28, as: UInt32.self)
        p.storeBytes(of: bits, toByteOffset: 32, as: UInt32.self)
    }
    return blob
}

#if canImport(CoreFoundation)
private func atW3FileURL(_ path: String) -> CFURL {
    path.withCString { cstr in
        CFURLCreateFromFileSystemRepresentation(
            kCFAllocatorDefault,
            UnsafeRawPointer(cstr).assumingMemoryBound(to: UInt8.self),
            path.utf8.count,
            false
        )!
    }
}
#endif

private var atW3MixerSamples: [Float] = []
private func atW3MixerCallback(
    _ refCon: UnsafeMutableRawPointer?,
    _ flags: UnsafeMutablePointer<AudioUnitRenderActionFlags>?,
    _ timeStamp: UnsafeRawPointer?,
    _ bus: UInt32,
    _ frames: UInt32,
    _ ioData: UnsafeMutableRawPointer?
) -> Int32 {
    _ = refCon
    _ = timeStamp
    _ = bus
    flags?.pointee.remove(.unitRenderAction_OutputIsSilence)
    guard let ioData else { return kAudioUnitErr_InvalidParameter }
    let stored = ioData.loadUnaligned(fromByteOffset: 16, as: UInt.self)
    guard let dest = UnsafeMutableRawPointer(bitPattern: stored) else {
        return kAudioUnitErr_InvalidParameter
    }
    for index in 0..<Int(frames) {
        let sample: Float = index < atW3MixerSamples.count ? atW3MixerSamples[index] : 0
        dest.storeBytes(of: sample, toByteOffset: index * 4, as: Float.self)
    }
    return 0
}

func testMixerVolumeAffectsMix() {
    var description = AudioComponentDescription(
        componentType: kAudioUnitType_Mixer,
        componentSubType: kAudioUnitSubType_MultiChannelMixer,
        componentManufacturer: kAudioUnitManufacturer_Apple,
        componentFlags: 0,
        componentFlagsMask: 0
    )
    let component = AudioComponentFindNext(nil, &description)
    var mixer: AudioComponentInstance?
    atW3Expect(AudioComponentInstanceNew(component, &mixer) == 0, "mixer")
    let format = atW3PCMBlob(rate: 44100, bits: 32, flags: 9)
    atW3Expect(
        format.withUnsafeBytes { raw in
            AudioUnitSetProperty(
                mixer,
                kAudioUnitProperty_StreamFormat,
                kAudioUnitScope_Output,
                0,
                raw.baseAddress,
                40
            )
        } == 0,
        "format"
    )
    atW3Expect(
        format.withUnsafeBytes { raw in
            AudioUnitSetProperty(
                mixer,
                kAudioUnitProperty_StreamFormat,
                kAudioUnitScope_Input,
                0,
                raw.baseAddress,
                40
            )
        } == 0,
        "input format"
    )
    atW3Expect(AudioUnitInitialize(mixer) == 0, "init")
    atW3Expect(
        AudioUnitSetParameter(
            mixer,
            kMultiChannelMixerParam_Volume,
            kAudioUnitScope_Input,
            0,
            0.5,
            0
        ) == 0,
        "set volume"
    )
    atW3Expect(
        AudioUnitSetParameter(
            mixer,
            kMultiChannelMixerParam_Enable,
            kAudioUnitScope_Input,
            0,
            1,
            0
        ) == 0,
        "enable"
    )
    atW3Expect(
        AudioUnitSetParameter(
            mixer,
            kMultiChannelMixerParam_Pan,
            kAudioUnitScope_Input,
            0,
            0,
            0
        ) == 0,
        "pan"
    )
    var volume: AudioUnitParameterValue = 0
    atW3Expect(
        AudioUnitGetParameter(mixer, kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, 0, &volume) == 0
            && volume == 0.5,
        "get volume"
    )
    var enable: AudioUnitParameterValue = 0
    atW3Expect(
        AudioUnitGetParameter(mixer, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, 0, &enable) == 0
            && enable == 1,
        "get enable"
    )
    var pan: AudioUnitParameterValue = 1
    atW3Expect(
        AudioUnitGetParameter(mixer, kMultiChannelMixerParam_Pan, kAudioUnitScope_Input, 0, &pan) == 0
            && pan == 0,
        "get pan"
    )
    atW3Expect(kMultiChannelMixerParam_PreAveragePower == 1000, "pre avg")
    atW3Expect(kMultiChannelMixerParam_PrePeakHoldLevel == 2000, "pre peak")
    atW3Expect(kMultiChannelMixerParam_PostAveragePower == 3000, "post avg")
    atW3Expect(kMultiChannelMixerParam_PostPeakHoldLevel == 4000, "post peak")
    atW3Expect(kMatrixMixerParam_Volume == 0 && kMatrixMixerParam_Enable == 1, "matrix")
    atW3Expect(kMatrixMixerParam_PreAveragePower == 1000, "mx pre")
    atW3Expect(kMatrixMixerParam_PrePeakHoldLevel == 2000, "mx pre peak")
    atW3Expect(kMatrixMixerParam_PostAveragePower == 3000, "mx post")
    atW3Expect(kMatrixMixerParam_PostPeakHoldLevel == 4000, "mx post peak")
    atW3Expect(kMatrixMixerParam_PreAveragePowerLinear == 5000, "mx pre lin")
    atW3Expect(kMatrixMixerParam_PrePeakHoldLevelLinear == 6000, "mx pre peak lin")
    atW3Expect(kMatrixMixerParam_PostAveragePowerLinear == 7000, "mx post lin")
    atW3Expect(kMatrixMixerParam_PostPeakHoldLevelLinear == 8000, "mx post peak lin")
    atW3Expect(k3DMixerParam_Azimuth == 0 && k3DMixerParam_Elevation == 1, "3d ae")
    atW3Expect(k3DMixerParam_Distance == 2 && k3DMixerParam_Gain == 3, "3d dg")
    atW3Expect(k3DMixerParam_PlaybackRate == 4 && k3DMixerParam_Enable == 5, "3d pe")
    atW3Expect(k3DMixerParam_MinGain == 6 && k3DMixerParam_MaxGain == 7, "3d mm")
    atW3Expect(k3DMixerParam_ReverbBlend == 8 && k3DMixerParam_GlobalReverbGain == 9, "3d rv")
    atW3Expect(k3DMixerParam_OcclusionAttenuation == 10, "3d occ")
    atW3Expect(k3DMixerParam_ObstructionAttenuation == 11, "3d obs")
    atW3Expect(kHALOutputParam_Volume == 14, "hal")
    atW3Expect(kTimePitchParam_Rate == 0 && kTimePitchParam_Pitch == 1 && kTimePitchParam_EffectBlend == 2, "tp")
    atW3Expect(kNewTimePitchParam_Rate == 0 && kNewTimePitchParam_Pitch == 1, "ntp")
    atW3Expect(kNewTimePitchParam_Overlap == 4 && kNewTimePitchParam_EnablePeakLocking == 6, "ntp extra")
    atW3Expect(kVarispeedParam_PlaybackRate == 0 && kVarispeedParam_PlaybackCents == 1, "vari")
    atW3Expect(kAUGroupParameterID_Volume == 7 && kAUGroupParameterID_Pan == 10, "grp vol pan")
    atW3Expect(kAUGroupParameterID_Volume_LSB == 39 && kAUGroupParameterID_Sustain == 64, "grp lsb")
    atW3Expect(kAUGroupParameterID_Sostenuto == 66 && kAUGroupParameterID_AllSoundOff == 120, "grp sost")
    atW3Expect(kAUGroupParameterID_ResetAllControllers == 121 && kAUGroupParameterID_AllNotesOff == 123, "grp all")
    var listSize: UInt32 = 0
    var writable: UInt8 = 1
    atW3Expect(
        AudioUnitGetPropertyInfo(
            mixer,
            kAudioUnitProperty_ParameterList,
            kAudioUnitScope_Global,
            0,
            &listSize,
            &writable
        ) == 0 && listSize == 12 && writable == 0,
        "param list info"
    )
    var ids = [UInt32](repeating: 99, count: 3)
    var size: UInt32 = 12
    atW3Expect(
        ids.withUnsafeMutableBytes { raw in
            AudioUnitGetProperty(
                mixer,
                kAudioUnitProperty_ParameterList,
                kAudioUnitScope_Global,
                0,
                raw.baseAddress,
                &size
            )
        } == 0,
        "param list"
    )
    atW3Expect(ids[0] == kMultiChannelMixerParam_Volume, "list volume")
    atW3Expect(ids[1] == kMultiChannelMixerParam_Enable, "list enable")
    atW3Expect(ids[2] == kMultiChannelMixerParam_Pan, "list pan")
    atW3MixerSamples = [0.5, 1.0]
    var callback = AURenderCallbackStruct(inputProc: atW3MixerCallback, inputProcRefCon: nil)
    atW3Expect(
        withUnsafePointer(to: &callback) { pointer in
            AudioUnitSetProperty(
                mixer,
                kAudioUnitProperty_SetRenderCallback,
                kAudioUnitScope_Input,
                0,
                pointer,
                UInt32(MemoryLayout<AURenderCallbackStruct>.size)
            )
        } == 0,
        "callback"
    )
    var list = [UInt8](repeating: 0, count: 24)
    var samples = [Float](repeating: 0, count: 2)
    list.withUnsafeMutableBytes { raw in
        raw.baseAddress!.storeBytes(of: UInt32(1), toByteOffset: 0, as: UInt32.self)
        raw.baseAddress!.storeBytes(of: UInt32(1), toByteOffset: 8, as: UInt32.self)
        raw.baseAddress!.storeBytes(of: UInt32(8), toByteOffset: 12, as: UInt32.self)
        samples.withUnsafeMutableBytes { pcm in
            raw.baseAddress!.storeBytes(of: UInt(bitPattern: pcm.baseAddress), toByteOffset: 16, as: UInt.self)
            var flags = AudioUnitRenderActionFlags()
            atW3Expect(AudioUnitRender(mixer, &flags, nil, 0, 2, raw.baseAddress) == 0, "render")
        }
    }
    atW3Expect(abs(samples[0] - 0.25) < 0.0001, "0.5 * 0.5")
    atW3Expect(abs(samples[1] - 0.5) < 0.0001, "1.0 * 0.5")
    var notifyCount: Int32 = 0
    atW3Expect(AudioUnitAddRenderNotify(mixer, atW3MixerCallback, &notifyCount) == 0, "add notify")
    atW3Expect(AudioUnitRemoveRenderNotify(mixer, atW3MixerCallback, &notifyCount) == 0, "remove notify")
    _ = AudioComponentInstanceDispose(mixer)
}

func testAudioUnitPropertyInfoAndParameterOptions() {
    atW3Expect(AudioUnitParameterOptions.flag_CFNameRelease.rawValue == 1 << 4, "cfname")
    atW3Expect(AudioUnitParameterOptions.flag_OmitFromPresets.rawValue == 1 << 13, "omit")
    atW3Expect(AudioUnitParameterOptions.flag_PlotHistory.rawValue == 1 << 14, "plot")
    atW3Expect(AudioUnitParameterOptions.flag_MeterReadOnly.rawValue == 1 << 15, "meter")
    atW3Expect(AudioUnitParameterOptions.flag_DisplayMask.rawValue == 7 << 16, "mask")
    atW3Expect(AudioUnitParameterOptions.flag_DisplaySquareRoot.rawValue == 1 << 16, "sqrt")
    atW3Expect(AudioUnitParameterOptions.flag_DisplaySquared.rawValue == 2 << 16, "sq")
    atW3Expect(AudioUnitParameterOptions.flag_DisplayCubed.rawValue == 3 << 16, "cubed")
    atW3Expect(AudioUnitParameterOptions.flag_DisplayCubeRoot.rawValue == 4 << 16, "cbrt")
    atW3Expect(AudioUnitParameterOptions.flag_DisplayExponential.rawValue == 5 << 16, "exp")
    atW3Expect(AudioUnitParameterOptions.flag_DisplayLogarithmic.rawValue == 6 << 16, "log")
    atW3Expect(AudioUnitParameterOptions.flag_HasClump.rawValue == 1 << 20, "clump")
    atW3Expect(AudioUnitParameterOptions.flag_HasCFNameString.rawValue == 1 << 21, "cfns")
    atW3Expect(AudioUnitParameterOptions.flag_IsHighResolution.rawValue == 1 << 22, "hires")
    atW3Expect(AudioUnitParameterOptions.flag_NonRealTime.rawValue == 1 << 23, "nrt")
    atW3Expect(AudioUnitParameterOptions.flag_CanRamp.rawValue == 1 << 24, "ramp")
    atW3Expect(AudioUnitParameterOptions.flag_ExpertMode.rawValue == 1 << 25, "expert")
    atW3Expect(AudioUnitParameterOptions.flag_HasName.rawValue == 1 << 26, "name")
    atW3Expect(AudioUnitParameterOptions.flag_IsGlobalMeta.rawValue == 1 << 10, "gmeta")
    atW3Expect(AudioUnitParameterOptions.flag_IsElementMeta.rawValue == 1 << 11, "emeta")
    atW3Expect(AudioUnitParameterOptions.flag_ValuesHaveStrings.rawValue == 1 << 16, "strings")
    atW3Expect(AudioUnitParameterOptions.flag_IsReadable.rawValue == 1 << 30, "read")
    atW3Expect(AudioUnitParameterOptions.flag_IsWritable.rawValue == 1 << 31, "write")
    atW3Expect(AudioUnitParameterUnit.generic.rawValue == 0, "generic")
    atW3Expect(AudioUnitParameterUnit.indexed.rawValue == 1, "indexed")
    atW3Expect(AudioUnitParameterUnit.boolean.rawValue == 2, "bool")
    atW3Expect(AudioUnitParameterUnit.percent.rawValue == 3, "pct")
    atW3Expect(AudioUnitParameterUnit.seconds.rawValue == 4, "sec")
    atW3Expect(AudioUnitParameterUnit.sampleFrames.rawValue == 5, "frames")
    atW3Expect(AudioUnitParameterUnit.phase.rawValue == 6, "phase")
    atW3Expect(AudioUnitParameterUnit.rate.rawValue == 7, "rate")
    atW3Expect(AudioUnitParameterUnit.hertz.rawValue == 8, "hz")
    atW3Expect(AudioUnitParameterUnit.cents.rawValue == 9, "cents")
    atW3Expect(AudioUnitParameterUnit.relativeSemiTones.rawValue == 10, "rst")
    atW3Expect(AudioUnitParameterUnit.midiNoteNumber.rawValue == 11, "midi note")
    atW3Expect(AudioUnitParameterUnit.midiController.rawValue == 12, "midi cc")
    atW3Expect(AudioUnitParameterUnit.decibels.rawValue == 13, "db")
    atW3Expect(AudioUnitParameterUnit.linearGain.rawValue == 14, "gain")
    atW3Expect(AudioUnitParameterUnit.degrees.rawValue == 15, "deg")
    atW3Expect(AudioUnitParameterUnit.equalPowerCrossfade.rawValue == 16, "eqpwr")
    atW3Expect(AudioUnitParameterUnit.mixerFaderCurve1.rawValue == 17, "fader")
    atW3Expect(AudioUnitParameterUnit.pan.rawValue == 18, "pan unit")
    atW3Expect(AudioUnitParameterUnit.meters.rawValue == 19, "meters")
    atW3Expect(AudioUnitParameterUnit.absoluteCents.rawValue == 20, "abs cents")
    atW3Expect(AudioUnitParameterUnit.octaves.rawValue == 21, "oct")
    atW3Expect(AudioUnitParameterUnit.BPM.rawValue == 22, "bpm")
    atW3Expect(AudioUnitParameterUnit.beats.rawValue == 23, "beats")
    atW3Expect(AudioUnitParameterUnit.milliseconds.rawValue == 24, "ms")
    atW3Expect(AudioUnitParameterUnit.ratio.rawValue == 25, "ratio")
    atW3Expect(AudioUnitParameterUnit.customUnit.rawValue == 26, "custom")
    atW3Expect(AudioUnitParameterUnit.midi2Controller.rawValue == 27, "midi2")
    atW3Expect(AudioUnitEventType.parameterValueChange.rawValue == 0, "param change")
    atW3Expect(AudioUnitEventType.beginParameterChangeGesture.rawValue == 1, "begin")
    atW3Expect(AudioUnitEventType.endParameterChangeGesture.rawValue == 2, "end")
    atW3Expect(AudioUnitEventType.propertyChange.rawValue == 3, "prop")
    atW3Expect(AudioUnitRemoteControlEvent.togglePlayPause.rawValue == 1, "playpause")
    atW3Expect(AudioUnitRemoteControlEvent.toggleRecord.rawValue == 2, "record")
    atW3Expect(AudioUnitRemoteControlEvent.rewind.rawValue == 3, "rewind")
    atW3Expect(AudioUnitRenderActionFlags.unitRenderAction_PreRender.rawValue == 1 << 2, "pre")
    atW3Expect(AudioUnitRenderActionFlags.unitRenderAction_PostRender.rawValue == 1 << 3, "post")
    atW3Expect(AudioUnitRenderActionFlags.unitRenderAction_OutputIsSilence.rawValue == 1 << 4, "silence")
    atW3Expect(AudioUnitRenderActionFlags.offlineUnitRenderAction_Preflight.rawValue == 1 << 5, "preflight")
    atW3Expect(AudioUnitRenderActionFlags.offlineUnitRenderAction_Render.rawValue == 1 << 6, "offline render")
    atW3Expect(AudioUnitRenderActionFlags.offlineUnitRenderAction_Complete.rawValue == 1 << 7, "complete")
    atW3Expect(AudioUnitRenderActionFlags.unitRenderAction_PostRenderError.rawValue == 1 << 8, "post err")
    atW3Expect(AudioUnitRenderActionFlags.unitRenderAction_DoNotCheckRenderArgs.rawValue == 1 << 9, "nocheck")
    atW3Expect(AudioQueueProcessingTapFlags.preEffects.rawValue == 1, "pre fx")
    atW3Expect(AudioQueueProcessingTapFlags.postEffects.rawValue == 2, "post fx")
    atW3Expect(AudioQueueProcessingTapFlags.siphon.rawValue == 4, "siphon")
    atW3Expect(AudioQueueProcessingTapFlags.startOfStream.rawValue == 1 << 8, "start")
    atW3Expect(AudioQueueProcessingTapFlags.endOfStream.rawValue == 1 << 9, "end")
}

func testMusicSequenceBeatsSecondsAndTrackEdit() {
    var sequence: MusicSequence?
    atW3Expect(NewMusicSequence(&sequence) == 0, "seq")
    var tempo: MusicTrack?
    atW3Expect(MusicSequenceGetTempoTrack(sequence, &tempo) == 0, "tempo")
    atW3Expect(MusicTrackNewExtendedTempoEvent(tempo, 0, 120) == 0, "120 bpm")
    var beats: MusicTimeStamp = 0
    atW3Expect(MusicSequenceGetBeatsForSeconds(sequence, 1, &beats) == 0, "beats")
    atW3Expect(abs(beats - 2) < 0.0001, "1s = 2 beats at 120")
    var seconds: Float64 = 0
    atW3Expect(MusicSequenceGetSecondsForBeats(sequence, 2, &seconds) == 0, "seconds")
    atW3Expect(abs(seconds - 1) < 0.0001, "2 beats = 1s")
    var barBeat = CABarBeatTime()
    atW3Expect(MusicSequenceBeatsToBarBeatTime(sequence, 5.5, 480, &barBeat) == 0, "barbeat")
    atW3Expect(barBeat.bar == 1, "bar 1")
    atW3Expect(barBeat.beat == 2, "beat 2")
    atW3Expect(barBeat.subbeatDivisor == 480, "divisor")
    var reconstructed: MusicTimeStamp = 0
    atW3Expect(MusicSequenceBarBeatTimeToBeats(sequence, &barBeat, &reconstructed) == 0, "to beats")
    atW3Expect(abs(reconstructed - 5.5) < 0.01, "round trip barbeat")
    var trackA: MusicTrack?
    var trackB: MusicTrack?
    atW3Expect(MusicSequenceNewTrack(sequence, &trackA) == 0, "a")
    atW3Expect(MusicSequenceNewTrack(sequence, &trackB) == 0, "b")
    var index: UInt32 = 99
    atW3Expect(MusicSequenceGetTrackIndex(sequence, trackB, &index) == 0 && index == 1, "index")
    var note = MIDINoteMessage(channel: 0, note: 60, velocity: 80, releaseVelocity: 0, duration: 0.5)
    atW3Expect(MusicTrackNewMIDINoteEvent(trackA, 0, &note) == 0, "note 0")
    note.note = 64
    atW3Expect(MusicTrackNewMIDINoteEvent(trackA, 1, &note) == 0, "note 1")
    atW3Expect(MusicTrackCopyInsert(trackA, 0, 2, trackB, 0) == 0, "copy insert")
    atW3Expect(MusicTrackMerge(trackA, 0, 1, trackB, 4) == 0, "merge")
    atW3Expect(MusicTrackMoveEvents(trackB, 0, 10, 0.25) == 0, "move")
    atW3Expect(MusicTrackCut(trackA, 0, 1) == 0, "cut")
    var mute: UInt32 = 1
    atW3Expect(MusicTrackSetProperty(trackA, kSequenceTrackProperty_MuteStatus, &mute, 4) == 0, "mute set")
    mute = 0
    var propSize: UInt32 = 4
    atW3Expect(MusicTrackGetProperty(trackA, kSequenceTrackProperty_MuteStatus, &mute, &propSize) == 0, "mute get")
    atW3Expect(mute == 1, "muted")
    var solo: UInt32 = 1
    atW3Expect(MusicTrackSetProperty(trackA, kSequenceTrackProperty_SoloStatus, &solo, 4) == 0, "solo")
    solo = 0
    atW3Expect(MusicTrackGetProperty(trackA, kSequenceTrackProperty_SoloStatus, &solo, &propSize) == 0 && solo == 1, "solo get")
    var offset: MusicTimeStamp = 1.5
    atW3Expect(MusicTrackSetProperty(trackA, kSequenceTrackProperty_OffsetTime, &offset, 8) == 0, "offset")
    offset = 0
    propSize = 8
    atW3Expect(MusicTrackGetProperty(trackA, kSequenceTrackProperty_OffsetTime, &offset, &propSize) == 0, "offset get")
    atW3Expect(abs(offset - 1.5) < 0.0001, "offset value")
    var length: MusicTimeStamp = 8
    atW3Expect(MusicTrackSetProperty(trackA, kSequenceTrackProperty_TrackLength, &length, 8) == 0, "length")
    length = 0
    atW3Expect(MusicTrackGetProperty(trackA, kSequenceTrackProperty_TrackLength, &length, &propSize) == 0 && length == 8, "length get")
    var resolution: UInt16 = 240
    atW3Expect(MusicTrackSetProperty(trackA, kSequenceTrackProperty_TimeResolution, &resolution, 2) == 0, "res")
    resolution = 0
    propSize = 2
    atW3Expect(MusicTrackGetProperty(trackA, kSequenceTrackProperty_TimeResolution, &resolution, &propSize) == 0 && resolution == 240, "res get")
    atW3Expect(kSequenceTrackProperty_LoopInfo == 0, "loop info")
    atW3Expect(kSequenceTrackProperty_AutomatedParameters == 4, "automated")
    var iterator: MusicEventIterator?
    atW3Expect(NewMusicEventIterator(trackB, &iterator) == 0, "iter")
    atW3Expect(MusicEventIteratorSetEventTime(iterator, 3.0) == 0, "set time")
    atW3Expect(DisposeMusicEventIterator(iterator) == 0, "dispose iter")
    var player: MusicPlayer?
    atW3Expect(NewMusicPlayer(&player) == 0, "player")
    atW3Expect(MusicPlayerSetSequence(player, sequence) == 0, "set seq")
    atW3Expect(MusicPlayerPreroll(player) == 0, "preroll")
    atW3Expect(kAudioToolboxErr_InvalidSequenceType == -10846, "invalid seq")
    atW3Expect(kAudioToolboxErr_TrackIndexError == -10859, "track index")
    atW3Expect(kAudioToolboxErr_TrackNotFound == -10858, "track not found")
    atW3Expect(kAudioToolboxErr_EndOfTrack == -10857, "end")
    atW3Expect(kAudioToolboxErr_StartOfTrack == -10856, "start")
    atW3Expect(kAudioToolboxErr_IllegalTrackDestination == -10855, "illegal dest")
    atW3Expect(kAudioToolboxErr_NoSequence == -10854, "no seq")
    atW3Expect(kAudioToolboxErr_InvalidEventType == -10853, "event")
    atW3Expect(kAudioToolboxErr_InvalidPlayerState == -10852, "player")
    atW3Expect(kAudioToolboxErr_CannotDoInCurrentContext == -10863, "context")
    atW3Expect(kAudioToolboxError_NoTrackDestination == -66720, "no dest")
    atW3Expect(DisposeMusicPlayer(player) == 0, "player")
    atW3Expect(DisposeMusicSequence(sequence) == 0, "seq")
}

func testMusicSequenceSMFWriteAndAUGraph() {
#if canImport(CoreFoundation)
    var sequence: MusicSequence?
    atW3Expect(NewMusicSequence(&sequence) == 0, "seq")
    var track: MusicTrack?
    atW3Expect(MusicSequenceNewTrack(sequence, &track) == 0, "track")
    var tempo: MusicTrack?
    atW3Expect(MusicSequenceGetTempoTrack(sequence, &tempo) == 0, "tempo")
    atW3Expect(MusicTrackNewExtendedTempoEvent(tempo, 0, 120) == 0, "tempo event")
    var note = MIDINoteMessage(channel: 1, note: 64, velocity: 90, releaseVelocity: 0, duration: 0.25)
    atW3Expect(MusicTrackNewMIDINoteEvent(track, 0, &note) == 0, "note")
    var data: Unmanaged<CFData>?
    atW3Expect(
        MusicSequenceFileCreateData(sequence, .midiType, [], 480, &data) == 0,
        "create data"
    )
    atW3Expect(data != nil, "bytes")
    let cf = data!.takeRetainedValue()
    atW3Expect(CFDataGetLength(cf) > 14, "smf size")
    var reloaded: MusicSequence?
    atW3Expect(NewMusicSequence(&reloaded) == 0, "reload seq")
    atW3Expect(MusicSequenceFileLoadData(reloaded, cf, .midiType, []) == 0, "reload")
    var count: UInt32 = 0
    atW3Expect(MusicSequenceGetTrackCount(reloaded, &count) == 0 && count >= 1, "tracks")
    let path = FileManager.default.temporaryDirectory
        .appendingPathComponent("openuikit-at-smf-\(UUID().uuidString).mid")
    defer { try? FileManager.default.removeItem(at: path) }
    atW3Expect(
        MusicSequenceFileCreate(sequence, atW3FileURL(path.path), .midiType, .eraseFile, 480) == 0,
        "create file"
    )
    var graph: AUGraph?
    atW3Expect(NewAUGraph(&graph) == 0, "graph")
    atW3Expect(MusicSequenceSetAUGraph(sequence, graph) == 0, "set graph")
    var stored: AUGraph?
    atW3Expect(MusicSequenceGetAUGraph(sequence, &stored) == 0 && stored == graph, "get graph")
    atW3Expect(DisposeAUGraph(graph) == 0, "graph")
    atW3Expect(DisposeMusicSequence(reloaded) == 0, "reload")
    atW3Expect(DisposeMusicSequence(sequence) == 0, "seq")
#endif
}

func testAudioFileOptimizeReadPacketDataAndGlobalInfo() {
#if canImport(CoreFoundation)
    let path = FileManager.default.temporaryDirectory
        .appendingPathComponent("openuikit-at-opt-\(UUID().uuidString).wav")
    defer { try? FileManager.default.removeItem(at: path) }
    let format = atW3PCMBlob(rate: 8000, bits: 16, flags: 12)
    var file: AudioFileID?
    format.withUnsafeBytes { raw in
        _ = AudioFileCreateWithURL(atW3FileURL(path.path), kAudioFileWAVEType, raw.baseAddress, [], &file)
    }
    var packets: UInt32 = 4
    let samples: [Int16] = [10, 20, 30, 40]
    samples.withUnsafeBytes { raw in
        _ = AudioFileWritePackets(file, false, 8, nil, 0, &packets, raw.baseAddress)
    }
    var deferFlag: UInt32 = 1
    atW3Expect(
        AudioFileSetProperty(file, kAudioFilePropertyDeferSizeUpdates, 4, &deferFlag) == 0,
        "defer"
    )
    atW3Expect(AudioFileOptimize(file) == 0, "optimize")
    var readPackets: UInt32 = 4
    var bytes: UInt32 = 0
    var out = [Int16](repeating: 0, count: 4)
    atW3Expect(
        out.withUnsafeMutableBytes { raw in
            AudioFileReadPacketData(file, false, &bytes, nil, 0, &readPackets, raw.baseAddress)
        } == 0,
        "read packet data"
    )
    atW3Expect(out == samples, "sample exact")
    atW3Expect(AudioFileClose(file) == 0, "close")
    var typeSize: UInt32 = 0
    atW3Expect(
        AudioFileGetGlobalInfoSize(kAudioFileGlobalInfo_ReadableTypes, 0, nil, &typeSize) == 0
            && typeSize == 12,
        "readable size"
    )
    var writableSize: UInt32 = 0
    atW3Expect(
        AudioFileGetGlobalInfoSize(kAudioFileGlobalInfo_WritableTypes, 0, nil, &writableSize) == 0
            && writableSize == 12,
        "writable size"
    )
    var types = [UInt32](repeating: 0, count: 3)
    var io = typeSize
    atW3Expect(
        types.withUnsafeMutableBytes { raw in
            AudioFileGetGlobalInfo(kAudioFileGlobalInfo_ReadableTypes, 0, nil, &io, raw.baseAddress)
        } == 0,
        "readable"
    )
    atW3Expect(types.contains(kAudioFileWAVEType), "wave")
    atW3Expect(types.contains(kAudioFileAIFFType), "aiff")
    atW3Expect(types.contains(kAudioFileCAFType), "caf")
    io = 12
    atW3Expect(
        types.withUnsafeMutableBytes { raw in
            AudioFileGetGlobalInfo(kAudioFileGlobalInfo_WritableTypes, 0, nil, &io, raw.baseAddress)
        } == 0,
        "writable"
    )
    var formatID: UInt32 = 0
    io = 4
    var wave = kAudioFileWAVEType
    atW3Expect(
        withUnsafeMutablePointer(to: &wave) { specifier in
            withUnsafeMutableBytes(of: &formatID) { raw in
                AudioFileGetGlobalInfo(
                    kAudioFileGlobalInfo_AvailableFormatIDs,
                    4,
                    specifier,
                    &io,
                    raw.baseAddress
                )
            }
        } == 0 && formatID == 0x6C70_636D,
        "lpcm"
    )
    atW3Expect(kAudioFileGlobalInfo_FileTypeName == atFourCCProbe("ftnm"), "ftnm")
    atW3Expect(kAudioFileGlobalInfo_AvailableStreamDescriptionsForFormat == atFourCCProbe("sdid"), "sdid")
    atW3Expect(kAudioFileGlobalInfo_AllExtensions == atFourCCProbe("alxt"), "alxt")
    atW3Expect(kAudioFileGlobalInfo_AllHFSTypeCodes == atFourCCProbe("ahfs"), "ahfs")
    atW3Expect(kAudioFileGlobalInfo_AllUTIs == atFourCCProbe("auti"), "auti")
    atW3Expect(kAudioFileGlobalInfo_AllMIMETypes == atFourCCProbe("amim"), "amim")
    atW3Expect(kAudioFileGlobalInfo_ExtensionsForType == atFourCCProbe("fext"), "fext")
    atW3Expect(kAudioFileGlobalInfo_HFSTypeCodesForType == atFourCCProbe("fhfs"), "fhfs")
    atW3Expect(kAudioFileGlobalInfo_UTIsForType == atFourCCProbe("futi"), "futi")
    atW3Expect(kAudioFileGlobalInfo_MIMETypesForType == atFourCCProbe("fmim"), "fmim")
    atW3Expect(kAudioFileGlobalInfo_TypesForMIMEType == atFourCCProbe("tmim"), "tmim")
    atW3Expect(kAudioFileGlobalInfo_TypesForUTI == atFourCCProbe("tuti"), "tuti")
    atW3Expect(kAudioFileGlobalInfo_TypesForHFSTypeCode == atFourCCProbe("thfs"), "thfs")
    atW3Expect(kAudioFileGlobalInfo_TypesForExtension == atFourCCProbe("text"), "text")
#endif
}

private func atFourCCProbe(_ s: String) -> UInt32 {
    let chars = Array(s.utf8)
    return (UInt32(chars[0]) << 24) | (UInt32(chars[1]) << 16) | (UInt32(chars[2]) << 8) | UInt32(chars[3])
}

func testAudioQueueParameterPrimeAndTime() {
    let format = atW3PCMBlob(rate: 8000, bits: 16, flags: 12)
    var queue: AudioQueueRef?
    atW3Expect(
        format.withUnsafeBytes { raw in
            AudioQueueNewOutput(raw.baseAddress, nil, nil, nil, nil, 0, &queue)
        } == 0,
        "queue"
    )
    atW3Expect(AudioQueueSetParameter(queue, kAudioQueueParam_Volume, 0.5) == 0, "set vol")
    var volume: AudioQueueParameterValue = 0
    atW3Expect(AudioQueueGetParameter(queue, kAudioQueueParam_Volume, &volume) == 0 && volume == 0.5, "get vol")
    atW3Expect(AudioQueueSetParameter(queue, kAudioQueueParam_Pan, -0.25) == 0, "pan")
    var pan: AudioQueueParameterValue = 0
    atW3Expect(AudioQueueGetParameter(queue, kAudioQueueParam_Pan, &pan) == 0 && pan == -0.25, "get pan")
    atW3Expect(AudioQueueSetParameter(queue, kAudioQueueParam_PlayRate, 1.5) == 0, "rate")
    var rate: AudioQueueParameterValue = 0
    atW3Expect(AudioQueueGetParameter(queue, kAudioQueueParam_PlayRate, &rate) == 0 && rate == 1.5, "get rate")
    atW3Expect(AudioQueueSetParameter(queue, kAudioQueueParam_Pitch, 2) == 0, "pitch")
    var pitch: AudioQueueParameterValue = 0
    atW3Expect(AudioQueueGetParameter(queue, kAudioQueueParam_Pitch, &pitch) == 0 && pitch == 2, "get pitch")
    atW3Expect(AudioQueueSetParameter(queue, kAudioQueueParam_VolumeRampTime, 0.1) == 0, "ramp")
    var ramp: AudioQueueParameterValue = 0
    atW3Expect(AudioQueueGetParameter(queue, kAudioQueueParam_VolumeRampTime, &ramp) == 0 && ramp == 0.1, "get ramp")
    var prepared: UInt32 = 0
    atW3Expect(AudioQueuePrime(queue, 256, &prepared) == 0 && prepared == 256, "prime")
    var buffer: AudioQueueBufferRef?
    atW3Expect(AudioQueueAllocateBuffer(queue, 8, &buffer) == 0, "alloc")
    buffer!.pointee.mAudioDataByteSize = 8
    let src: [Int16] = [1000, 2000, 3000, 4000]
    src.withUnsafeBytes { raw in
        memcpy(buffer!.pointee.mAudioData, raw.baseAddress, 8)
    }
    atW3Expect(AudioQueueEnqueueBuffer(queue, buffer, 0, nil) == 0, "enqueue")
    atW3Expect(AudioQueueStart(queue, nil) == 0, "start")
    var stamp = [UInt8](repeating: 0, count: 64)
    var disc: UInt8 = 1
    atW3Expect(
        stamp.withUnsafeMutableBytes { raw in
            AudioQueueGetCurrentTime(queue, nil, raw.baseAddress, &disc)
        } == 0 && disc == 0,
        "time"
    )
    let sampleTime = stamp.withUnsafeBytes { $0.loadUnaligned(as: Float64.self) }
    atW3Expect(sampleTime >= 4, "sample time advanced")
    var tap: AudioQueueProcessingTapRef?
    var maxFrames: UInt32 = 1
    atW3Expect(
        AudioQueueProcessingTapNew(queue, nil, nil, [.preEffects], &maxFrames, nil, &tap)
            == kAudioQueueErr_TooManyTaps,
        "tap fail-closed"
    )
    atW3Expect(AudioQueueProcessingTapDispose(nil) == kAudioQueueErr_InvalidTapContext, "tap dispose")
    var tapTime: Float64 = 1
    var tapFrames: UInt32 = 1
    atW3Expect(
        AudioQueueProcessingTapGetQueueTime(nil, &tapTime, &tapFrames) == kAudioQueueErr_InvalidTapContext
            && tapTime == 0 && tapFrames == 0,
        "tap time"
    )
    var tapFlags = AudioQueueProcessingTapFlags.preEffects
    var produced: UInt32 = 9
    atW3Expect(
        AudioQueueProcessingTapGetSourceAudio(nil, 4, nil, &tapFlags, &produced, nil)
            == kAudioQueueErr_InvalidTapContext && produced == 0 && tapFlags.rawValue == 0,
        "tap source"
    )
    var timeline: AudioQueueTimelineRef?
    atW3Expect(AudioQueueCreateTimeline(queue, &timeline) == kAudioQueueErr_InvalidParameter, "timeline")
    atW3Expect(AudioQueueDisposeTimeline(queue, timeline) == 0, "dispose timeline")
    atW3Expect(AudioQueueDispose(queue, true) == 0, "dispose")
}

func testAudioCodecConstantsAndFailClosed() {
    atW3Expect(kAppleSoftwareAudioCodecManufacturer == atFourCCProbe("appl"), "sw")
    atW3Expect(kAppleHardwareAudioCodecManufacturer == atFourCCProbe("aphw"), "hw")
    atW3Expect(kAudioCodecPropertyInputBufferSize == atFourCCProbe("tbuf"), "tbuf")
    atW3Expect(kAudioCodecPropertyPacketFrameSize == atFourCCProbe("pakf"), "pakf")
    atW3Expect(kAudioCodecPropertyHasVariablePacketByteSizes == atFourCCProbe("vpk?"), "vpk")
    atW3Expect(kAudioCodecPropertyEmploysDependentPackets == atFourCCProbe("dpk?"), "dpk")
    atW3Expect(kAudioCodecPropertyMaximumPacketByteSize == atFourCCProbe("pakb"), "pakb")
    atW3Expect(kAudioCodecPropertyPacketSizeLimitForVBR == atFourCCProbe("pakl"), "pakl")
    atW3Expect(kAudioCodecPropertyCurrentInputFormat == atFourCCProbe("ifmt"), "ifmt")
    atW3Expect(kAudioCodecPropertyCurrentOutputFormat == atFourCCProbe("ofmt"), "ofmt")
    atW3Expect(kAudioCodecPropertyMagicCookie == atFourCCProbe("kuki"), "kuki")
    atW3Expect(kAudioCodecPropertyUsedInputBufferSize == atFourCCProbe("ubuf"), "ubuf")
    atW3Expect(kAudioCodecPropertyIsInitialized == atFourCCProbe("init"), "init")
    atW3Expect(kAudioCodecPropertyCurrentTargetBitRate == atFourCCProbe("brat"), "brat")
    atW3Expect(kAudioCodecPropertyCurrentInputSampleRate == atFourCCProbe("cisr"), "cisr")
    atW3Expect(kAudioCodecPropertyCurrentOutputSampleRate == atFourCCProbe("cosr"), "cosr")
    atW3Expect(kAudioCodecPropertyQualitySetting == atFourCCProbe("srcq"), "srcq")
    atW3Expect(kAudioCodecPropertyApplicableBitRateRange == atFourCCProbe("brta"), "brta")
    atW3Expect(kAudioCodecPropertyRecommendedBitRateRange == atFourCCProbe("brtr"), "brtr")
    atW3Expect(kAudioCodecPropertyApplicableInputSampleRates == atFourCCProbe("isra"), "isra")
    atW3Expect(kAudioCodecPropertyApplicableOutputSampleRates == atFourCCProbe("osra"), "osra")
    atW3Expect(kAudioCodecPropertyPaddedZeros == atFourCCProbe("pad0"), "pad0")
    atW3Expect(kAudioCodecPropertyPrimeMethod == atFourCCProbe("prmm"), "prmm")
    atW3Expect(kAudioCodecPropertyPrimeInfo == atFourCCProbe("prim"), "prim")
    atW3Expect(kAudioCodecPropertyCurrentInputChannelLayout == atFourCCProbe("icl "), "icl")
    atW3Expect(kAudioCodecPropertyCurrentOutputChannelLayout == atFourCCProbe("ocl "), "ocl")
    atW3Expect(kAudioCodecPropertySettings == atFourCCProbe("acs "), "acs")
    atW3Expect(kAudioCodecPropertyFormatList == atFourCCProbe("acfl"), "acfl")
    atW3Expect(kAudioCodecPropertyBitRateControlMode == atFourCCProbe("acbf"), "acbf")
    atW3Expect(kAudioCodecPropertySoundQualityForVBR == atFourCCProbe("vbrq"), "vbrq")
    atW3Expect(kAudioCodecPropertyBitRateForVBR == atFourCCProbe("vbrb"), "vbrb")
    atW3Expect(kAudioCodecPropertyDelayMode == atFourCCProbe("dmod"), "dmod")
    atW3Expect(kAudioCodecPropertyAdjustLocalQuality == atFourCCProbe("^qal"), "qal")
    atW3Expect(kAudioCodecPropertyDynamicRangeControlMode == atFourCCProbe("mdrc"), "mdrc")
    atW3Expect(kAudioCodecPropertyAdjustCompressionProfile == atFourCCProbe("^pro"), "pro")
    atW3Expect(kAudioCodecPropertyProgramTargetLevelConstant == atFourCCProbe("ptlc"), "ptlc")
    atW3Expect(kAudioCodecPropertyAdjustTargetLevelConstant == atFourCCProbe("^tlc"), "tlc")
    atW3Expect(kAudioCodecPropertyProgramTargetLevel == atFourCCProbe("pptl"), "pptl")
    atW3Expect(kAudioCodecPropertyAdjustTargetLevel == atFourCCProbe("^ptl"), "ptl")
    atW3Expect(kAudioCodecPropertyDynamicRangeControlConfiguration == atFourCCProbe("cdrc"), "cdrc")
    atW3Expect(kAudioCodecPropertyContentSource == atFourCCProbe("csrc"), "csrc")
    atW3Expect(kAudioCodecPropertyASPFrequency == atFourCCProbe("aspf"), "aspf")
    atW3Expect(kAudioCodecNoError == 0, "noerr")
    atW3Expect(kAudioCodecQuality_Max == 0x7F, "qmax")
    atW3Expect(kAudioCodecQuality_High == 0x60, "qhigh")
    atW3Expect(kAudioCodecQuality_Medium == 0x40, "qmed")
    atW3Expect(kAudioCodecQuality_Low == 0x20, "qlow")
    atW3Expect(kAudioCodecQuality_Min == 0, "qmin")
    atW3Expect(kAudioCodecPropertyNameCFString == atFourCCProbe("lnam"), "lnam")
    atW3Expect(kAudioCodecPropertyManufacturerCFString == atFourCCProbe("lmak"), "lmak")
    atW3Expect(kAudioCodecPropertyFormatCFString == atFourCCProbe("lfor"), "lfor")
    atW3Expect(kAudioCodecUnspecifiedError == atSignedFourCCProbe("what"), "what")
    atW3Expect(kAudioCodecUnknownPropertyError == atSignedFourCCProbe("who?"), "who")
    atW3Expect(kAudioCodecBadPropertySizeError == atSignedFourCCProbe("!siz"), "siz")
    atW3Expect(kAudioCodecIllegalOperationError == atSignedFourCCProbe("nope"), "nope")
    atW3Expect(kAudioCodecUnsupportedFormatError == atSignedFourCCProbe("fmt?"), "fmt")
    atW3Expect(kAudioCodecStateError == atSignedFourCCProbe("!stt"), "stt")
    atW3Expect(kAudioCodecNotEnoughBufferSpaceError == atSignedFourCCProbe("!buf"), "buf")
    atW3Expect(kAudioCodecBadDataError == atSignedFourCCProbe("!dat"), "dat")
    atW3Expect(kAudioCodecBitRateControlMode_Constant == 0, "cbr mode")
    atW3Expect(kAudioCodecBitRateControlMode_LongTermAverage == 1, "lta")
    atW3Expect(kAudioCodecBitRateControlMode_VariableConstrained == 2, "vbrc")
    atW3Expect(kAudioCodecBitRateControlMode_Variable == 3, "vbr")
    atW3Expect(kAudioCodecBitRateFormat_CBR == 0, "cbr fmt")
    atW3Expect(kAudioCodecBitRateFormat_ABR == 1, "abr")
    atW3Expect(kAudioCodecBitRateFormat_VBR == 2, "vbr fmt")
    atW3Expect(kAudioCodecDelayMode_Compatibility == 0, "compat")
    atW3Expect(kAudioCodecDelayMode_Minimum == 1, "min delay")
    atW3Expect(kAudioCodecDelayMode_Optimal == 2, "opt delay")
    atW3Expect(kAudioCodecPrimeMethod_Pre == 0, "pre")
    atW3Expect(kAudioCodecPrimeMethod_Normal == 1, "normal")
    atW3Expect(kAudioCodecPrimeMethod_None == 2, "none")
    atW3Expect(kAudioCodecOutputPrecedenceNone == 0, "prec none")
    atW3Expect(kAudioCodecOutputPrecedenceBitRate == 1, "prec br")
    atW3Expect(kAudioCodecOutputPrecedenceSampleRate == 2, "prec sr")
    atW3Expect(kAudioCodecProduceOutputPacketFailure == 1, "fail")
    atW3Expect(kAudioCodecProduceOutputPacketSuccess == 2, "ok")
    atW3Expect(kAudioCodecProduceOutputPacketSuccessHasMore == 3, "more")
    atW3Expect(kAudioCodecProduceOutputPacketNeedsMoreInputData == 4, "need")
    atW3Expect(kAudioCodecProduceOutputPacketAtEOF == 5, "eof")
    atW3Expect(kAudioCodecProduceOutputPacketSuccessConcealed == 6, "concealed")
    atW3Expect(kAudioCodecGetPropertyInfoSelect == 1, "sel info")
    atW3Expect(kAudioCodecGetPropertySelect == 2, "sel get")
    atW3Expect(kAudioCodecSetPropertySelect == 3, "sel set")
    atW3Expect(kAudioCodecInitializeSelect == 4, "sel init")
    atW3Expect(kAudioCodecUninitializeSelect == 5, "sel uninit")
    atW3Expect(kAudioCodecAppendInputDataSelect == 6, "sel append")
    atW3Expect(kAudioCodecProduceOutputDataSelect == 7, "sel produce")
    atW3Expect(kAudioCodecResetSelect == 8, "sel reset")
    atW3Expect(kAudioCodecAppendInputBufferListSelect == 9, "sel abl")
    atW3Expect(kAudioCodecProduceOutputBufferListSelect == 10, "sel obl")
    atW3Expect(kAudioCodecDynamicRangeControlConfiguration_None == 0, "drc none")
    atW3Expect(kAudioCodecDynamicRangeControlConfiguration_Music == 1, "drc music")
    atW3Expect(kAudioCodecDynamicRangeControlConfiguration_Speech == 2, "drc speech")
    atW3Expect(kAudioCodecDynamicRangeControlConfiguration_Movie == 3, "drc movie")
    atW3Expect(kAudioCodecDynamicRangeControlConfiguration_Capture == 4, "drc capture")
    atW3Expect(kAudioCodecContentSource_Unspecified == -1, "unspec")
    atW3Expect(kAudioCodecContentSource_Reserved == 0, "reserved")
    atW3Expect(kAudioCodecContentSource_AppleCapture_Traditional == 1, "act")
    atW3Expect(kAudioCodecContentSource_AppleCapture_Spatial == 2, "acs")
    atW3Expect(kAudioCodecContentSource_AppleCapture_Spatial_Enhanced == 3, "acse")
    atW3Expect(kAudioCodecContentSource_AppleMusic_Traditional == 4, "amt")
    atW3Expect(kAudioCodecContentSource_AppleMusic_Spatial == 5, "ams")
    atW3Expect(kAudioCodecContentSource_AppleAV_Traditional_Offline == 6, "avto")
    atW3Expect(kAudioCodecContentSource_AppleAV_Spatial_Offline == 7, "avso")
    atW3Expect(kAudioCodecContentSource_AppleAV_Traditional_Live == 8, "avtl")
    atW3Expect(kAudioCodecContentSource_AppleAV_Spatial_Live == 9, "avsl")
    atW3Expect(kAudioCodecContentSource_ApplePassthrough == 10, "ap")
    atW3Expect(kAudioCodecContentSource_Capture_Traditional == 33, "ct")
    atW3Expect(kAudioCodecContentSource_Capture_Spatial == 34, "cs")
    atW3Expect(kAudioCodecContentSource_Capture_Spatial_Enhanced == 35, "cse")
    atW3Expect(kAudioCodecContentSource_Music_Traditional == 36, "mt")
    atW3Expect(kAudioCodecContentSource_Music_Spatial == 37, "ms")
    atW3Expect(kAudioCodecContentSource_AV_Traditional_Offline == 38, "avto2")
    atW3Expect(kAudioCodecContentSource_AV_Spatial_Offline == 39, "avso2")
    atW3Expect(kAudioCodecContentSource_AV_Traditional_Live == 40, "avtl2")
    atW3Expect(kAudioCodecContentSource_AV_Spatial_Live == 41, "avsl2")
    atW3Expect(kAudioCodecContentSource_Passthrough == 42, "pt")
    atW3Expect(AudioCodecInitialize(nil, nil, nil, nil, 0) == kAudioCodecUnsupportedFormatError, "init")
    atW3Expect(AudioCodecUninitialize(nil) == kAudioCodecStateError, "uninit")
    atW3Expect(AudioCodecReset(nil) == kAudioCodecStateError, "reset")
    var size: UInt32 = 0
    var writable: UInt8 = 1
    atW3Expect(
        AudioCodecGetPropertyInfo(nil, kAudioCodecPropertyInputBufferSize, &size, &writable)
            == kAudioCodecUnknownPropertyError,
        "info"
    )
    atW3Expect(
        AudioCodecGetProperty(nil, kAudioCodecPropertyMagicCookie, &size, nil) == kAudioCodecUnknownPropertyError,
        "get"
    )
    atW3Expect(
        AudioCodecSetProperty(nil, kAudioCodecPropertyQualitySetting, 0, nil) == kAudioCodecIllegalOperationError,
        "set"
    )
    var consumed: UInt32 = 1
    atW3Expect(AudioCodecAppendInputData(nil, nil, &consumed, nil, nil) == kAudioCodecStateError, "append")
    var status: UInt32 = 0
    atW3Expect(
        AudioCodecProduceOutputPackets(nil, nil, &size, nil, nil, &status) == kAudioCodecStateError
            && status == kAudioCodecProduceOutputPacketFailure,
        "produce"
    )
    atW3Expect(AudioCodecAppendInputBufferList(nil, nil, nil, nil, &consumed) == kAudioCodecStateError, "abl")
    atW3Expect(
        AudioCodecProduceOutputBufferList(nil, nil, &size, nil, &status) == kAudioCodecStateError,
        "obl"
    )
    let prime = AudioCodecPrimeInfo(leadingFrames: 1, trailingFrames: 2)
    atW3Expect(prime.leadingFrames == 1 && prime.trailingFrames == 2, "prime fields")
    let emptyPrime = AudioCodecPrimeInfo()
    atW3Expect(emptyPrime.leadingFrames == 0, "empty prime")
    let cookie = AudioCodecMagicCookieInfo(mMagicCookieSize: 4, mMagicCookie: nil)
    atW3Expect(cookie.mMagicCookieSize == 4 && cookie.mMagicCookie == nil, "cookie")
    let emptyCookie = AudioCodecMagicCookieInfo()
    atW3Expect(emptyCookie.mMagicCookieSize == 0, "empty cookie")
}

private func atSignedFourCCProbe(_ s: String) -> Int32 {
    Int32(bitPattern: atFourCCProbe(s))
}

func testMusicDeviceMIDIFailClosed() {
    var description = AudioComponentDescription(
        componentType: kAudioUnitType_Generator,
        componentSubType: kAudioUnitSubType_ScheduledSoundPlayer,
        componentManufacturer: kAudioUnitManufacturer_Apple,
        componentFlags: 0,
        componentFlagsMask: 0
    )
    let component = AudioComponentFindNext(nil, &description)
    var unit: AudioComponentInstance?
    atW3Expect(AudioComponentInstanceNew(component, &unit) == 0, "unit")
    atW3Expect(
        MusicDeviceMIDIEvent(unit, 0x90, 60, 80, 0) == kAudioUnitErr_CannotDoInCurrentContext,
        "midi"
    )
    atW3Expect(MusicDeviceSysEx(unit, nil, 0) == kAudioUnitErr_CannotDoInCurrentContext, "sysex")
    var noteID: NoteInstanceID = 1
    var params = MusicDeviceNoteParams(argCount: 2, mPitch: 60, mVelocity: 80, mControls: 0)
    atW3Expect(
        MusicDeviceStartNote(unit, 0, 0, &noteID, 0, &params) == kAudioUnitErr_CannotDoInCurrentContext,
        "start"
    )
    atW3Expect(noteID == 0, "cleared")
    atW3Expect(MusicDeviceStopNote(unit, 0, 1, 0) == kAudioUnitErr_CannotDoInCurrentContext, "stop")
    atW3Expect(MemoryLayout<MusicDeviceStdNoteParams>.size == 12, "std layout")
    let std = MusicDeviceStdNoteParams(argCount: 2, mPitch: 61, mVelocity: 70)
    atW3Expect(std.argCount == 2 && std.mPitch == 61 && std.mVelocity == 70, "std")
    atW3Expect(params.mPitch == 60 && params.mVelocity == 80 && params.mControls == 0, "note params")
    let emptyParams = MusicDeviceNoteParams()
    atW3Expect(emptyParams.argCount == 2, "empty note")
    let emptyStd = MusicDeviceStdNoteParams()
    atW3Expect(emptyStd.mPitch == 60, "empty std")
    atW3Expect(kMusicDeviceProperty_InstrumentCount == 1000, "inst count")
    atW3Expect(kMusicDeviceProperty_InstrumentName == 1001, "inst name")
    atW3Expect(kMusicDeviceProperty_InstrumentNumber == 1004, "inst num")
    atW3Expect(kMusicDeviceProperty_BankName == 1007, "bank")
    atW3Expect(kMusicDeviceProperty_SoundBankURL == 1100, "url")
    atW3Expect(kMusicDeviceRange == 0x0100, "range")
    atW3Expect(kMusicDeviceMIDIEventSelect == 0x0101, "midi sel")
    atW3Expect(kMusicDeviceSysExSelect == 0x0102, "sysex sel")
    atW3Expect(kMusicDevicePrepareInstrumentSelect == 0x0103, "prep")
    atW3Expect(kMusicDeviceReleaseInstrumentSelect == 0x0104, "rel")
    atW3Expect(kMusicDeviceStartNoteSelect == 0x0105, "start sel")
    atW3Expect(kMusicDeviceStopNoteSelect == 0x0106, "stop sel")
    atW3Expect(kMusicDeviceMIDIEventListSelect == 0x0107, "list sel")
    atW3Expect(kMusicNoteEvent_UseGroupInstrument == 0xFFFF_FFFF, "group inst")
    atW3Expect(kMusicNoteEvent_Unused == 0x00FF_FFFF, "unused")
    _ = AudioComponentInstanceDispose(unit)
}

func testCAFRemainingStructFields() {
    atW3Expect(CAFFormatFlags.linearPCMFormatFlagIsFloat.rawValue == 1, "float")
    atW3Expect(CAFRegionFlags.loopEnable.rawValue == 1, "loop")
    atW3Expect(CAFRegionFlags.playForward.rawValue == 2, "fwd")
    atW3Expect(CAFRegionFlags.playBackward.rawValue == 4, "back")
    let data = CAFDataChunk(mEditCount: 3, mData: 7)
    atW3Expect(data.mEditCount == 3 && data.mData == 7, "data chunk")
    let emptyData = CAFDataChunk()
    atW3Expect(emptyData.mEditCount == 0, "empty data")
    let list = CAFAudioFormatListItem(
        mFormat: CAFAudioDescription(),
        mChannelLayoutTag: 1
    )
    atW3Expect(list.mChannelLayoutTag == 1, "list tag")
    atW3Expect(list.mFormat.mChannelsPerFrame == 0, "list format")
    let emptyList = CAFAudioFormatListItem()
    atW3Expect(emptyList.mChannelLayoutTag == 0, "empty list")
    let uuid = CAF_UUID_ChunkHeader()
    atW3Expect(uuid.mUUID.0 == 0 && uuid.mHeader.mChunkSize == 0, "uuid")
    let uuid2 = CAF_UUID_ChunkHeader(
        mHeader: CAFChunkHeader(mChunkType: 1, mChunkSize: 2),
        mUUID: (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 10, 12, 13, 14, 15, 16)
    )
    atW3Expect(uuid2.mHeader.mChunkType == 1 && uuid2.mUUID.0 == 1, "uuid init")
    let marker = CAFMarker(mType: kCAFMarkerType_Index, mFramePosition: 8, mMarkerID: 3, mSMPTETime: CAF_SMPTE_Time(), mChannel: 1)
    atW3Expect(marker.mType == kCAFMarkerType_Index && marker.mFramePosition == 8, "marker")
    atW3Expect(marker.mMarkerID == 3 && marker.mChannel == 1, "marker ids")
    let emptyMarker = CAFMarker()
    atW3Expect(emptyMarker.mType == kCAFMarkerType_Generic, "empty marker")
    let chunk = CAFMarkerChunk(mSMPTE_TimeType: kCAF_SMPTE_TimeType24, mNumberMarkers: 1, mMarkers: marker)
    atW3Expect(chunk.mNumberMarkers == 1 && chunk.mSMPTE_TimeType == kCAF_SMPTE_TimeType24, "marker chunk")
    let emptyChunk = CAFMarkerChunk()
    atW3Expect(emptyChunk.mNumberMarkers == 0, "empty marker chunk")
    let region = CAFRegion(mRegionID: 9, mFlags: [.loopEnable, .playForward], mNumberMarkers: 1, mMarkers: marker)
    atW3Expect(region.mRegionID == 9 && region.mFlags.contains(.loopEnable), "region")
    let regionChunk = CAFRegionChunk(mSMPTE_TimeType: 0, mNumberRegions: 1, mRegions: region)
    atW3Expect(regionChunk.mNumberRegions == 1 && regionChunk.mRegions.mRegionID == 9, "region chunk")
    let inst = CAFInstrumentChunk(
        mBaseNote: 48,
        mMIDILowNote: 1,
        mMIDIHighNote: 80,
        mMIDILowVelocity: 10,
        mMIDIHighVelocity: 120,
        mdBGain: -3,
        mStartRegionID: 1,
        mSustainRegionID: 2,
        mReleaseRegionID: 3,
        mInstrumentID: 4
    )
    atW3Expect(inst.mBaseNote == 48 && inst.mInstrumentID == 4, "inst")
    atW3Expect(inst.mMIDILowNote == 1 && inst.mdBGain == -3, "inst fields")
    let packets = CAFPacketTableHeader(mNumberPackets: 10, mNumberValidFrames: 20, mPrimingFrames: 1, mRemainderFrames: 2)
    atW3Expect(packets.mNumberPackets == 10 && packets.mRemainderFrames == 2, "pakt")
    let emptyPackets = CAFPacketTableHeader()
    atW3Expect(emptyPackets.mNumberPackets == 0 && emptyPackets.mPrimingFrames == 0, "empty pakt")
    let peak = CAFPositionPeak(mValue: 0.5, mFrameNumber: 99)
    atW3Expect(peak.mValue == 0.5 && peak.mFrameNumber == 99, "peak")
    let peakChunk = CAFPeakChunk(mEditCount: 2, mPeaks: peak)
    atW3Expect(peakChunk.mEditCount == 2 && peakChunk.mPeaks.mFrameNumber == 99, "peak chunk")
    let ovw = CAFOverviewSample(mMinValue: -4, mMaxValue: 5)
    atW3Expect(ovw.mMinValue == -4 && ovw.mMaxValue == 5, "ovw sample")
    let ovwChunk = CAFOverviewChunk(mEditCount: 1, mNumFramesPerOVWSample: 256, mData: ovw)
    atW3Expect(ovwChunk.mNumFramesPerOVWSample == 256 && ovwChunk.mData.mMaxValue == 5, "ovw")
    let sid = CAFStringID(mStringID: 7, mStringStartByteOffset: 12)
    atW3Expect(sid.mStringID == 7 && sid.mStringStartByteOffset == 12, "string id")
    let strings = CAFStrings(mNumEntries: 2, mStringsIDs: sid)
    atW3Expect(strings.mNumEntries == 2 && strings.mStringsIDs.mStringID == 7, "strings")
    let info = CAFInfoStrings(mNumEntries: 4)
    atW3Expect(info.mNumEntries == 4, "info")
    let emptyInfo = CAFInfoStrings()
    atW3Expect(emptyInfo.mNumEntries == 0, "empty info")
    let umid = CAFUMIDChunk(mBytes: (
        1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2
    ))
    atW3Expect(umid.mBytes.0 == 1 && umid.mBytes.31 == 2, "umid")
    let emptyUmid = CAFUMIDChunk()
    atW3Expect(emptyUmid.mBytes.0 == 0, "empty umid")
    atW3Expect(CAFStrings().mNumEntries == 0, "empty strings")
    atW3Expect(CAFStringID().mStringID == 0, "empty string id")
    atW3Expect(CAFPeakChunk().mEditCount == 0, "empty peak chunk")
    atW3Expect(CAFRegionChunk().mNumberRegions == 0, "empty region chunk")
    atW3Expect(CAFPositionPeak().mFrameNumber == 0, "empty peak")
    atW3Expect(CAFOverviewChunk().mNumFramesPerOVWSample == 0, "empty ovw")
    atW3Expect(CAFOverviewSample().mMaxValue == 0, "empty ovw sample")
    atW3Expect(CAFInstrumentChunk().mBaseNote == 60, "empty inst")
    atW3Expect(CAFRegion().mRegionID == 0, "empty region")
    atW3Expect(CAFFormatFlags(rawValue: 1) == .linearPCMFormatFlagIsFloat, "float raw")
    atW3Expect(CAFRegionFlags(rawValue: 1) == .loopEnable, "loop raw")
    atW3Expect(MemoryLayout<CAFMarker>.size >= 24, "marker layout")
    atW3Expect(MemoryLayout<CAFInstrumentChunk>.size >= 28, "inst layout")
    atW3Expect(MemoryLayout<CAFPacketTableHeader>.size == 24, "pakt layout")
    atW3Expect(MemoryLayout<CAFPositionPeak>.size == 16 || MemoryLayout<CAFPositionPeak>.size == 12, "peak layout")
}
