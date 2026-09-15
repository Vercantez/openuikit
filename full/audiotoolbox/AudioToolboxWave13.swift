import Foundation
#if canImport(CoreFoundation)
import CoreFoundation
#endif

// Wave-13 depth pass: offline delegates, music-sequence state, C render/process
// callback types, and the v3 object surface that stays compilable without
// CoreAudioTypes / CoreMIDI / AVFoundation. Hardware, daemon, dispatch-queue,
// MIDI-CI, and async-file behavior stays fail-closed or deferred.

// MARK: - AudioConverter delegates

public func AudioConverterNewSpecific(
    _ inSourceFormat: UnsafeRawPointer?,
    _ inDestinationFormat: UnsafeRawPointer?,
    _ inNumberClassDescriptions: UInt32,
    _ inClassDescriptions: UnsafeRawPointer?,
    _ outAudioConverter: UnsafeMutablePointer<AudioConverterRef?>?
) -> Int32 {
    // The offline engine is the only PCM converter hosted here, so class
    // descriptions cannot select an implementation; the formats still go
    // through the same PCM validation as AudioConverterNew.
    _ = inNumberClassDescriptions
    _ = inClassDescriptions
    return AudioConverterNew(inSourceFormat, inDestinationFormat, outAudioConverter)
}

public typealias AudioConverterInputDataProc = @convention(c) (
    AudioConverterRef,
    UnsafeMutablePointer<UInt32>,
    UnsafeMutablePointer<UnsafeMutableRawPointer>,
    UnsafeMutableRawPointer?
) -> Int32

public typealias AudioConverterComplexInputDataProcRealtimeSafe = (
    AudioConverterRef?,
    UnsafeMutablePointer<UInt32>?,
    UnsafeMutableRawPointer?,
    UnsafeMutableRawPointer?,
    UnsafeMutableRawPointer?
) -> Int32

public func AudioConverterFillComplexBufferRealtimeSafe(
    _ inAudioConverter: AudioConverterRef?,
    _ inInputDataProc: AudioConverterComplexInputDataProcRealtimeSafe?,
    _ inInputDataProcUserData: UnsafeMutableRawPointer?,
    _ ioOutputDataPacketSize: UnsafeMutablePointer<UInt32>?,
    _ outOutputData: UnsafeMutableRawPointer?,
    _ outPacketDescription: UnsafeMutableRawPointer?
) -> Int32 {
    _ = outPacketDescription
    guard let converter = ATRegistry.shared.lookup(
        inAudioConverter,
        as: ATAudioConverterObject.self
    ) else {
        return kAudioConverterErr_UnspecifiedError
    }
    guard let inInputDataProc, let ioOutputDataPacketSize, let outOutputData else {
        return kAudioConverterErr_UnspecifiedError
    }
    let destPackets = Int(ioOutputDataPacketSize.pointee)
    if destPackets <= 0 {
        return 0
    }
    let destFrames = destPackets
    let srcEstimate = atLinearInterpolateFrameCount(
        sourceFrames: max(destFrames, 2),
        sourceRate: converter.dest.mSampleRate,
        destRate: converter.source.mSampleRate
    )
    let sourceFrames = max(srcEstimate, destFrames)
    let sourceByteCount = sourceFrames * converter.source.bytesPerSample
        * converter.source.frameCountChannels
    var sourceStorage = [UInt8](repeating: 0, count: max(sourceByteCount, 1))
    var packetDescSlot: UnsafeMutableRawPointer? = nil
    var providedPackets = UInt32(sourceFrames)
    var abl = [UInt8](repeating: 0, count: 24)
    let status = sourceStorage.withUnsafeMutableBytes { storage in
        abl.withUnsafeMutableBytes { raw in
            raw.baseAddress!.storeBytes(of: UInt32(1), toByteOffset: 0, as: UInt32.self)
            raw.baseAddress!.storeBytes(
                of: converter.source.mChannelsPerFrame,
                toByteOffset: 8,
                as: UInt32.self
            )
            raw.baseAddress!.storeBytes(
                of: UInt32(storage.count),
                toByteOffset: 12,
                as: UInt32.self
            )
            raw.baseAddress!.storeBytes(
                of: UInt(bitPattern: storage.baseAddress),
                toByteOffset: 16,
                as: UInt.self
            )
            return withUnsafeMutablePointer(to: &packetDescSlot) { slot in
                inInputDataProc(
                    inAudioConverter,
                    &providedPackets,
                    raw.baseAddress!,
                    UnsafeMutableRawPointer(slot),
                    inInputDataProcUserData
                )
            }
        }
    }
    if status != 0 {
        ioOutputDataPacketSize.pointee = 0
        return status
    }
    if providedPackets == 0 {
        ioOutputDataPacketSize.pointee = 0
        return 0
    }
    guard let outputList = atLoadBufferList(outOutputData),
          let destBuffer = outputList.buffers.first,
          let destPtr = destBuffer.data
    else {
        return kAudioConverterErr_InvalidOutputSize
    }
    let inputByteCount = min(
        sourceStorage.count,
        Int(providedPackets) * converter.source.bytesPerSample * converter.source.frameCountChannels
    )
    let result = sourceStorage.withUnsafeBytes { src in
        atConvertPCM(
            source: converter.source,
            dest: converter.dest,
            input: src.baseAddress!,
            inputByteCount: inputByteCount,
            output: destPtr,
            outputByteCapacity: Int(destBuffer.dataByteSize),
            channelMap: converter.channelMap.isEmpty ? nil : converter.channelMap
        )
    }
    if result.status != 0 {
        ioOutputDataPacketSize.pointee = 0
        return result.status
    }
    let destWidth = converter.dest.bytesPerSample * converter.dest.frameCountChannels
    ioOutputDataPacketSize.pointee = destWidth == 0 ? 0 : UInt32(result.outputBytes / max(destWidth, 1))
    return 0
}

public func AudioConverterFillComplexBufferWithPacketDependencies(
    _ inAudioConverter: AudioConverterRef?,
    _ inInputDataProc: AudioConverterComplexInputDataProc?,
    _ inInputDataProcUserData: UnsafeMutableRawPointer?,
    _ ioOutputDataPacketSize: UnsafeMutablePointer<UInt32>?,
    _ outOutputData: UnsafeMutableRawPointer?,
    _ outPacketDescriptions: UnsafeMutableRawPointer?,
    _ outPacketDependencies: UnsafeMutableRawPointer?
) -> Int32 {
    // Linear PCM packets carry no dependencies, so the dependency table has
    // nothing to report; conversion itself is the shared PCM engine.
    _ = outPacketDependencies
    return AudioConverterFillComplexBuffer(
        inAudioConverter,
        inInputDataProc,
        inInputDataProcUserData,
        ioOutputDataPacketSize,
        outOutputData,
        outPacketDescriptions
    )
}

// MARK: - AudioFile / AudioQueue delegates

public func AudioFileWritePacketsWithDependencies(
    _ inAudioFile: AudioFileID?,
    _ inUseCache: Bool,
    _ inNumBytes: UInt32,
    _ inPacketDescriptions: UnsafeRawPointer?,
    _ inPacketDependencies: UnsafeRawPointer?,
    _ inStartingPacket: Int64,
    _ ioNumPackets: UnsafeMutablePointer<UInt32>?,
    _ inBuffer: UnsafeRawPointer?
) -> Int32 {
    // Hosted containers hold linear PCM only, where packet dependencies are
    // vacuous; the write itself is the shared packet path.
    _ = inPacketDependencies
    return AudioFileWritePackets(
        inAudioFile,
        inUseCache,
        inNumBytes,
        inPacketDescriptions,
        inStartingPacket,
        ioNumPackets,
        inBuffer
    )
}

public func AudioQueueSetOfflineRenderFormat(
    _ inAQ: AudioQueueRef?,
    _ inFormat: UnsafeRawPointer?,
    _ inLayout: UnsafeRawPointer?
) -> Int32 {
    _ = inLayout
    guard let queue = ATRegistry.shared.lookup(inAQ, as: ATAudioQueueObject.self) else {
        return kAudioQueueErr_InvalidParameter
    }
    guard let inFormat, var format = atLoadASBD(inFormat) else {
        return kAudioQueueErr_InvalidParameter
    }
    if format.mFormatID != 0 && format.mFormatID != atFormatLinearPCM {
        return kAudioQueueErr_CodecNotFound
    }
    if format.mFormatID == atFormatLinearPCM {
        if format.validatePCM() != 0 {
            return kAudioQueueErr_InvalidParameter
        }
        atFillPCMASBD(&format)
    }
    queue.format = format
    return 0
}

// MARK: - Music sequence/player state

public typealias MusicSequenceUserCallback = (
    UnsafeMutableRawPointer?,
    MusicSequence?,
    MusicTrack?,
    MusicTimeStamp,
    UnsafePointer<MusicEventUserData>?,
    MusicTimeStamp,
    MusicTimeStamp
) -> Void

public func MusicSequenceSetUserCallback(
    _ inSequence: MusicSequence?,
    _ inCallback: MusicSequenceUserCallback?,
    _ inClientData: UnsafeMutableRawPointer?
) -> Int32 {
    guard let sequence = ATRegistry.shared.lookup(
        inSequence,
        as: ATMusicSequenceObject.self
    ) else {
        return kAudioToolboxErr_NoSequence
    }
    return atWithLock(sequence.lock) {
        sequence.userCallback = inCallback
        sequence.userCallbackData = inClientData
        return 0
    }
}

// macOS probe: SetSMPTEResolution(25, 96) == -6304 and
// GetSMPTEResolution(-6304) decodes to (fps: -25, ticks: 96); i.e. the setter
// stores the negated frame rate (SMPTE convention) as (fps << 8) | ticks.
public func MusicSequenceSetSMPTEResolution(_ fps: Int8, _ ticks: UInt8) -> Int16 {
    let negated = 0 &- fps
    return (Int16(negated) << 8) | Int16(ticks)
}

public func MusicSequenceGetSMPTEResolution(
    _ inRes: Int16,
    _ fps: UnsafeMutablePointer<Int8>?,
    _ ticks: UnsafeMutablePointer<UInt8>?
) {
    fps?.pointee = Int8(truncatingIfNeeded: inRes >> 8)
    ticks?.pointee = UInt8(truncatingIfNeeded: inRes & 0xFF)
}

#if canImport(CoreFoundation)
public func MusicSequenceGetInfoDictionary(_ inSequence: MusicSequence?) -> CFDictionary {
    guard let sequence = ATRegistry.shared.lookup(
        inSequence,
        as: ATMusicSequenceObject.self
    ) else {
        return [:] as CFDictionary
    }
    // macOS probe: a fresh Apple sequence reports {tempo = 120}. The offline
    // tempo map defaults to 120 BPM, so the info dictionary carries it.
    let tempo = atSequenceTempo(sequence)
    return ["tempo": tempo] as CFDictionary
}
#endif

public func MusicPlayerGetHostTimeForBeats(
    _ inPlayer: MusicPlayer?,
    _ inBeats: MusicTimeStamp,
    _ outHostTime: UnsafeMutablePointer<UInt64>?
) -> Int32 {
    guard let player = ATRegistry.shared.lookup(inPlayer, as: ATMusicPlayerObject.self) else {
        return atParamError
    }
    guard let outHostTime else {
        return atParamError
    }
    var beats = player.time
    if player.playing {
        let elapsed = Date().timeIntervalSince1970 - player.startHost
        let bpm = atSequenceTempo(player.sequence) * player.rate
        beats = player.startStamp + elapsed * (bpm / 60.0)
    }
    let bpm = atSequenceTempo(player.sequence) * player.rate
    let safeBeatsPerSecond = bpm > 0 ? bpm / 60.0 : 2.0
    let now = atWave12HostNanoseconds()
    let deltaSeconds = (inBeats - beats) / safeBeatsPerSecond
    let deltaNanos = Int64((deltaSeconds * 1_000_000_000).rounded())
    let nowSigned: Int64 = now >= UInt64(Int64.max) ? Int64.max : Int64(now)
    let (target, overflow) = nowSigned.addingReportingOverflow(deltaNanos)
    if overflow {
        outHostTime.pointee = deltaNanos >= 0 ? UInt64.max : 0
    } else {
        outHostTime.pointee = target <= 0 ? 0 : UInt64(target)
    }
    return 0
}

public func MusicPlayerGetBeatsForHostTime(
    _ inPlayer: MusicPlayer?,
    _ inHostTime: UInt64,
    _ outBeats: UnsafeMutablePointer<MusicTimeStamp>?
) -> Int32 {
    guard let player = ATRegistry.shared.lookup(inPlayer, as: ATMusicPlayerObject.self) else {
        return atParamError
    }
    guard let outBeats else {
        return atParamError
    }
    var beats = player.time
    if player.playing {
        let elapsed = Date().timeIntervalSince1970 - player.startHost
        let bpm = atSequenceTempo(player.sequence) * player.rate
        beats = player.startStamp + elapsed * (bpm / 60.0)
    }
    let bpm = atSequenceTempo(player.sequence) * player.rate
    let safeBeatsPerSecond = bpm > 0 ? bpm / 60.0 : 2.0
    let now = atWave12HostNanoseconds()
    let hostSigned: Float64 = inHostTime >= UInt64(Int64.max)
        ? Float64(Int64.max) : Float64(Int64(inHostTime))
    let nowSigned: Float64 = now >= UInt64(Int64.max)
        ? Float64(Int64.max) : Float64(Int64(now))
    outBeats.pointee = beats + ((hostSigned - nowSigned) / 1_000_000_000) * safeBeatsPerSecond
    return 0
}

public func MusicTrackGetDestNode(
    _ inTrack: MusicTrack?,
    _ outNode: UnsafeMutablePointer<AUNode>?
) -> Int32 {
    guard let track = ATRegistry.shared.lookup(inTrack, as: ATMusicTrackObject.self) else {
        return kAudioToolboxErr_TrackNotFound
    }
    guard let outNode else {
        return atParamError
    }
    guard let sequence = track.sequence else {
        return kAudioToolboxErr_TrackNotFound
    }
    return atWithLock(sequence.lock) {
        guard track.hasDestNode else {
            return atParamError
        }
        outNode.pointee = track.destNode
        return 0
    }
}

public func MusicTrackSetDestNode(_ inTrack: MusicTrack?, _ inNode: AUNode) -> Int32 {
    guard let track = ATRegistry.shared.lookup(inTrack, as: ATMusicTrackObject.self) else {
        return kAudioToolboxErr_TrackNotFound
    }
    guard let sequence = track.sequence else {
        return kAudioToolboxErr_TrackNotFound
    }
    return atWithLock(sequence.lock) {
        track.destNode = inNode
        track.hasDestNode = true
        return 0
    }
}

public func MusicTrackNewExtendedNoteEvent(
    _ inTrack: MusicTrack?,
    _ inTimeStamp: MusicTimeStamp,
    _ inInfo: UnsafePointer<ExtendedNoteOnEvent>?
) -> Int32 {
    guard let track = ATRegistry.shared.lookup(inTrack, as: ATMusicTrackObject.self) else {
        return atParamError
    }
    guard let inInfo else {
        return atParamError
    }
    guard let sequence = track.sequence else {
        return atParamError
    }
    let payload = Data(bytes: inInfo, count: MemoryLayout<ExtendedNoteOnEvent>.size)
    return atWithLock(sequence.lock) {
        track.events.append(
            ATMusicEvent(time: inTimeStamp, type: kMusicEventType_ExtendedNote, payload: payload)
        )
        return 0
    }
}

public func MusicTrackNewUserEvent(
    _ inTrack: MusicTrack?,
    _ inTimeStamp: MusicTimeStamp,
    _ inUserData: UnsafePointer<MusicEventUserData>?
) -> Int32 {
    guard let track = ATRegistry.shared.lookup(inTrack, as: ATMusicTrackObject.self) else {
        return atParamError
    }
    guard let inUserData else {
        return atParamError
    }
    guard let sequence = track.sequence else {
        return atParamError
    }
    let header = inUserData.pointee
    let size = MemoryLayout<UInt32>.size + max(Int(header.length), 1)
    let payload = Data(bytes: inUserData, count: size)
    return atWithLock(sequence.lock) {
        track.events.append(
            ATMusicEvent(time: inTimeStamp, type: kMusicEventType_User, payload: payload)
        )
        return 0
    }
}

// MARK: - C render/process/output callback types (raw-pointer overlays)

// Dependency-owned AudioBufferList / AudioTimeStamp / AudioStreamPacketDescription
// stay out of the isolated compile; the overlays below use the same raw-pointer
// convention as the hosted AudioUnitRender / AURenderCallback entry points.

// Plain Swift closure: the render-action flags / render-callback payloads are
// Swift-native option types, which Swift 6 does not admit in `@convention(c)`.
public typealias AudioUnitRenderProc = (
    UnsafeMutableRawPointer?,
    UnsafeMutablePointer<AudioUnitRenderActionFlags>?,
    UnsafeRawPointer?,
    UInt32,
    UInt32,
    UnsafeMutableRawPointer?
) -> Int32

// Plain Swift closure: the render-action flags / render-callback payloads are
// Swift-native option types, which Swift 6 does not admit in `@convention(c)`.
public typealias AudioUnitProcessProc = (
    UnsafeMutableRawPointer?,
    UnsafeMutablePointer<AudioUnitRenderActionFlags>?,
    UnsafeRawPointer?,
    UInt32,
    UnsafeMutableRawPointer?
) -> Int32

// Plain Swift closure: the render-action flags / render-callback payloads are
// Swift-native option types, which Swift 6 does not admit in `@convention(c)`.
public typealias AudioUnitProcessMultipleProc = (
    UnsafeMutableRawPointer?,
    UnsafeMutablePointer<AudioUnitRenderActionFlags>?,
    UnsafeRawPointer?,
    UInt32,
    UInt32,
    UnsafeMutableRawPointer?,
    UInt32,
    UnsafeMutableRawPointer?
) -> Int32

// Plain Swift closure: the render-action flags / render-callback payloads are
// Swift-native option types, which Swift 6 does not admit in `@convention(c)`.
public typealias AudioUnitComplexRenderProc = (
    UnsafeMutableRawPointer?,
    UnsafeMutablePointer<AudioUnitRenderActionFlags>?,
    UnsafeRawPointer?,
    UInt32,
    UInt32,
    UnsafeMutablePointer<UInt32>?,
    UnsafeMutableRawPointer?,
    UnsafeMutableRawPointer?,
    UnsafeMutableRawPointer?,
    UnsafeMutablePointer<UInt32>?
) -> Int32

public typealias AudioUnitInitializeProc = @convention(c) (UnsafeMutableRawPointer) -> Int32

public typealias AudioUnitUninitializeProc = @convention(c) (UnsafeMutableRawPointer) -> Int32

public typealias AudioUnitResetProc = @convention(c) (
    UnsafeMutableRawPointer,
    AudioUnitScope,
    AudioUnitElement
) -> Int32

public typealias AudioUnitGetParameterProc = @convention(c) (
    UnsafeMutableRawPointer,
    AudioUnitParameterID,
    AudioUnitScope,
    AudioUnitElement,
    UnsafeMutablePointer<AudioUnitParameterValue>
) -> Int32

public typealias AudioUnitSetParameterProc = @convention(c) (
    UnsafeMutableRawPointer,
    AudioUnitParameterID,
    AudioUnitScope,
    AudioUnitElement,
    AudioUnitParameterValue,
    UInt32
) -> Int32

public typealias AudioUnitGetPropertyProc = @convention(c) (
    UnsafeMutableRawPointer,
    AudioUnitPropertyID,
    AudioUnitScope,
    AudioUnitElement,
    UnsafeMutableRawPointer,
    UnsafeMutablePointer<UInt32>
) -> Int32

public typealias AudioUnitSetPropertyProc = @convention(c) (
    UnsafeMutableRawPointer,
    AudioUnitPropertyID,
    AudioUnitScope,
    AudioUnitElement,
    UnsafeRawPointer,
    UInt32
) -> Int32

public typealias AudioUnitGetPropertyInfoProc = @convention(c) (
    UnsafeMutableRawPointer,
    AudioUnitPropertyID,
    AudioUnitScope,
    AudioUnitElement,
    UnsafeMutablePointer<UInt32>?,
    // C `Boolean` arrives as a byte on the isolated compile; the hosted
    // Wave-9 overlays use the same UInt8 spelling.
    UnsafeMutablePointer<UInt8>?
) -> Int32

// Plain Swift closure: the render-action flags / render-callback payloads are
// Swift-native option types, which Swift 6 does not admit in `@convention(c)`.
public typealias AudioUnitAddRenderNotifyProc = (
    UnsafeMutableRawPointer,
    AURenderCallback,
    UnsafeMutableRawPointer?
) -> Int32

// Plain Swift closure: the render-action flags / render-callback payloads are
// Swift-native option types, which Swift 6 does not admit in `@convention(c)`.
public typealias AudioUnitRemoveRenderNotifyProc = (
    UnsafeMutableRawPointer,
    AURenderCallback,
    UnsafeMutableRawPointer?
) -> Int32

public typealias AudioOutputUnitStartProc = @convention(c) (UnsafeMutableRawPointer) -> Int32

public typealias AudioOutputUnitStopProc = @convention(c) (UnsafeMutableRawPointer) -> Int32

public typealias AudioUnitRemoteControlEventListener = (AudioUnitRemoteControlEvent) -> Void

// MARK: - Queue / host / message blocks and scalar aliases

public typealias AudioQueueOutputCallbackBlock = (
    AudioQueueRef?,
    AudioQueueBufferRef?
) -> Void

public typealias AudioQueueInputCallbackBlock = (
    UnsafeMutableRawPointer?,
    AudioQueueRef?,
    AudioQueueBufferRef?,
    UnsafeRawPointer?,
    UInt32,
    UnsafeMutableRawPointer?
) -> Void

public typealias AudioQueueProcessingTapCallback = (
    UnsafeMutableRawPointer?,
    AudioQueueProcessingTapRef?,
    UInt32,
    UnsafeRawPointer?,
    UnsafeMutablePointer<AudioQueueProcessingTapFlags>?,
    UnsafeMutablePointer<UInt32>?,
    UnsafeMutableRawPointer?
) -> Void

public typealias AUHostMusicalContextBlock = (
    UnsafeMutablePointer<Double>?,
    UnsafeMutablePointer<Double>?,
    UnsafeMutablePointer<Int>?,
    UnsafeMutablePointer<Double>?,
    UnsafeMutablePointer<Int>?,
    UnsafeMutablePointer<Double>?
) -> Bool

public typealias AUHostTransportStateBlock = (
    UnsafeMutablePointer<AUHostTransportStateFlags>?,
    UnsafeMutablePointer<Double>?,
    UnsafeMutablePointer<Double>?,
    UnsafeMutablePointer<Double>?
) -> Bool

public typealias AUMIDIOutputEventBlock = (
    AUEventSampleTime,
    UInt8,
    Int,
    UnsafePointer<UInt8>
) -> Int32

public typealias AUScheduleMIDIEventBlock = (
    AUEventSampleTime,
    UInt8,
    Int,
    UnsafePointer<UInt8>
) -> Void

public typealias AUScheduleParameterBlock = (
    AUEventSampleTime,
    AUAudioFrameCount,
    AUParameterAddress,
    AUValue
) -> Void

public typealias CallHostBlock = ([AnyHashable: Any]) -> [AnyHashable: Any]

public typealias MIDIChannelNumber = UInt8

public typealias MagicCookieInfo = AudioCodecMagicCookieInfo

public typealias AUVoiceIOMutedSpeechActivityEventListener = (AUVoiceIOSpeechActivityEvent) -> Void

// MARK: - AUMessageChannel and v3 object surface

public protocol AUMessageChannel: AnyObject {
    func callAudioUnit(_ message: [AnyHashable: Any]) -> [AnyHashable: Any]
    var callHostBlock: CallHostBlock? { get set }
}

internal final class ATWave12MessageChannel: AUMessageChannel {
    var callHostBlock: CallHostBlock?

    func callAudioUnit(_ message: [AnyHashable: Any]) -> [AnyHashable: Any] {
        callHostBlock?(message) ?? [:]
    }
}

public extension AUAudioUnit {
    // The async/Swift-concurrency instantiate overload already exists on the
    // class; this completion-handler spelling invokes its completion
    // synchronously because no plug-in load happens offline.
    class func instantiate(
        with componentDescription: AudioComponentDescription,
        options: AudioComponentInstantiationOptions = [],
        completionHandler: @escaping (AUAudioUnit?, (any Error)?) -> Void
    ) {
        do {
            completionHandler(
                try AUAudioUnit(componentDescription: componentDescription, options: options),
                nil
            )
        } catch {
            completionHandler(nil, error)
        }
    }

    func messageChannel(for channelName: String) -> any AUMessageChannel {
        _ = channelName
        return ATWave12MessageChannel()
    }

    // Offline schedule blocks apply immediate values onto the hosted parameter
    // tree; MIDI scheduling has no transport, so that block stays nil.
    var scheduleParameterBlock: AUScheduleParameterBlock {
        { [weak self] _, _, address, value in
            self?.applyWave12ScheduledParameter(address: address, value: value)
        }
    }

    var scheduleMIDIEventBlock: AUScheduleMIDIEventBlock? {
        nil
    }

    internal func applyWave12ScheduledParameter(address: AUParameterAddress, value: AUValue) {
        if let parameter = parameterTree.allParameters.first(where: { $0.address == address }) {
            parameter.setValue(value, originator: nil)
        }
    }
}
