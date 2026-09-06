#if canImport(CoreFoundation)
import CoreFoundation
#endif
import Foundation

public enum MusicSequenceType: UInt32, Sendable, Hashable {
    case beats = 0x6265_6174
    case seconds = 0x7365_6373
    case samples = 0x7361_6D70
}

public enum MusicSequenceFileTypeID: UInt32, Sendable, Hashable {
    case anyType = 0
    case midiType = 0x6D69_6469
    case iMelodyType = 0x696D_656C
}

public struct MusicSequenceLoadFlags: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let channelsToTracks = MusicSequenceLoadFlags(rawValue: 1 << 0)
    public static let smf_ChannelsToTracks = channelsToTracks
    public static let smf_PreserveTracks: MusicSequenceLoadFlags = []
}

public struct MusicSequenceFileFlags: OptionSet, Sendable, Hashable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let eraseFile = MusicSequenceFileFlags(rawValue: 1)
}

public let kMusicEventType_NULL: UInt32 = 0
public let kMusicEventType_ExtendedNote: UInt32 = 1
public let kMusicEventType_ExtendedTempo: UInt32 = 3
public let kMusicEventType_User: UInt32 = 4
public let kMusicEventType_Meta: UInt32 = 5
public let kMusicEventType_MIDINoteMessage: UInt32 = 6
public let kMusicEventType_MIDIChannelMessage: UInt32 = 7
public let kMusicEventType_MIDIRawData: UInt32 = 8
public let kMusicEventType_Parameter: UInt32 = 9
public let kMusicEventType_AUPreset: UInt32 = 10

@frozen
public struct MIDINoteMessage: Equatable, Hashable, Sendable {
    public var channel: UInt8
    public var note: UInt8
    public var velocity: UInt8
    public var releaseVelocity: UInt8
    public var duration: Float32

    public init() {
        channel = 0
        note = 0
        velocity = 0
        releaseVelocity = 0
        duration = 0
    }

    public init(
        channel: UInt8,
        note: UInt8,
        velocity: UInt8,
        releaseVelocity: UInt8,
        duration: Float32
    ) {
        self.channel = channel
        self.note = note
        self.velocity = velocity
        self.releaseVelocity = releaseVelocity
        self.duration = duration
    }
}

@frozen
public struct MIDIChannelMessage: Equatable, Hashable, Sendable {
    public var status: UInt8
    public var data1: UInt8
    public var data2: UInt8
    public var reserved: UInt8

    public init() {
        status = 0
        data1 = 0
        data2 = 0
        reserved = 0
    }

    public init(status: UInt8, data1: UInt8, data2: UInt8, reserved: UInt8) {
        self.status = status
        self.data1 = data1
        self.data2 = data2
        self.reserved = reserved
    }
}

@frozen
public struct CABarBeatTime: Equatable, Hashable, Sendable {
    public var bar: Int32
    public var beat: UInt16
    public var subbeat: UInt16
    public var subbeatDivisor: UInt16
    public var reserved: UInt16

    public init() {
        bar = 0
        beat = 0
        subbeat = 0
        subbeatDivisor = 0
        reserved = 0
    }

    public init(
        bar: Int32,
        beat: UInt16,
        subbeat: UInt16,
        subbeatDivisor: UInt16,
        reserved: UInt16
    ) {
        self.bar = bar
        self.beat = beat
        self.subbeat = subbeat
        self.subbeatDivisor = subbeatDivisor
        self.reserved = reserved
    }
}

internal struct ATMusicEvent {
    var time: MusicTimeStamp
    var type: MusicEventType
    var payload: Data
}

internal final class ATMusicTrackObject: ATObject {
    unowned var sequence: ATMusicSequenceObject?
    var events: [ATMusicEvent] = []
    let isTempo: Bool
    var mute: UInt32 = 0
    var solo: UInt32 = 0
    var offsetTime: MusicTimeStamp = 0
    var length: MusicTimeStamp = 0
    var timeResolution: UInt16 = 480

    init(sequence: ATMusicSequenceObject, isTempo: Bool) {
        self.sequence = sequence
        self.isTempo = isTempo
    }
}

internal final class ATMusicSequenceObject: ATObject {
    let lock = NSLock()
    var type: MusicSequenceType = .beats
    var tracks: [ATMusicTrackObject] = []
    var tempoTrack: ATMusicTrackObject!
    var tempoHandle: MusicTrack?
    var graph: AUGraph?

    override init() {
        super.init()
        let tempo = ATMusicTrackObject(sequence: self, isTempo: true)
        tempoTrack = tempo
    }
}

internal final class ATMusicEventIteratorObject: ATObject {
    let track: ATMusicTrackObject
    var index: Int = 0
    var snapshot: [ATMusicEvent]
    private var payloadStorage: UnsafeMutableRawPointer?
    private var payloadCapacity = 0

    init(track: ATMusicTrackObject) {
        self.track = track
        self.snapshot = atWithLock(track.sequence?.lock ?? NSLock()) {
            track.events.sorted { $0.time < $1.time }
        }
    }

    deinit {
        payloadStorage?.deallocate()
    }

    func bindPayload(_ data: Data) -> (UnsafeRawPointer?, UInt32) {
        if data.count > payloadCapacity {
            payloadStorage?.deallocate()
            payloadStorage = UnsafeMutableRawPointer.allocate(
                byteCount: max(data.count, 1),
                alignment: MemoryLayout<UInt8>.alignment
            )
            payloadCapacity = max(data.count, 1)
        }
        guard let storage = payloadStorage else { return (nil, 0) }
        if !data.isEmpty {
            data.copyBytes(to: storage.assumingMemoryBound(to: UInt8.self), count: data.count)
        }
        return (UnsafeRawPointer(storage), UInt32(data.count))
    }
}

internal final class ATMusicPlayerObject: ATObject {
    var sequence: ATMusicSequenceObject?
    var time: MusicTimeStamp = 0
    var playing = false
    var rate: Float64 = 1
    var startHost: TimeInterval = 0
    var startStamp: MusicTimeStamp = 0
}

@_cdecl("NewMusicSequence")
public func NewMusicSequence(
    _ outSequence: UnsafeMutablePointer<MusicSequence?>?
) -> Int32 {
    guard let outSequence else { return atParamError }
    let sequence = ATMusicSequenceObject()
    sequence.tempoHandle = ATRegistry.shared.retain(sequence.tempoTrack)
    outSequence.pointee = ATRegistry.shared.retain(sequence)
    return 0
}

@_cdecl("DisposeMusicSequence")
public func DisposeMusicSequence(_ inSequence: MusicSequence?) -> Int32 {
    if let sequence = ATRegistry.shared.lookup(inSequence, as: ATMusicSequenceObject.self) {
        _ = ATRegistry.shared.release(sequence.tempoHandle)
        sequence.tempoHandle = nil
        for track in sequence.tracks {
            _ = ATRegistry.shared.release(OpaquePointer(Unmanaged.passUnretained(track).toOpaque()))
        }
        sequence.tracks.removeAll()
    }
    let status = ATRegistry.shared.release(inSequence)
    return status == atParamError ? 0 : status
}

@_cdecl("MusicSequenceNewTrack")
public func MusicSequenceNewTrack(
    _ inSequence: MusicSequence?,
    _ outTrack: UnsafeMutablePointer<MusicTrack?>?
) -> Int32 {
    guard let sequence = ATRegistry.shared.lookup(inSequence, as: ATMusicSequenceObject.self) else {
        return atParamError
    }
    guard let outTrack else { return atParamError }
    return atWithLock(sequence.lock) {
        let track = ATMusicTrackObject(sequence: sequence, isTempo: false)
        sequence.tracks.append(track)
        outTrack.pointee = ATRegistry.shared.retain(track)
        return 0
    }
}

@_cdecl("MusicSequenceDisposeTrack")
public func MusicSequenceDisposeTrack(
    _ inSequence: MusicSequence?,
    _ inTrack: MusicTrack?
) -> Int32 {
    guard let sequence = ATRegistry.shared.lookup(inSequence, as: ATMusicSequenceObject.self) else {
        return atParamError
    }
    guard let track = ATRegistry.shared.lookup(inTrack, as: ATMusicTrackObject.self) else {
        return atParamError
    }
    if track.isTempo {
        return atParamError
    }
    return atWithLock(sequence.lock) {
        sequence.tracks.removeAll { $0 === track }
        return ATRegistry.shared.release(inTrack)
    }
}

@_cdecl("MusicSequenceGetTrackCount")
public func MusicSequenceGetTrackCount(
    _ inSequence: MusicSequence?,
    _ outNumberOfTracks: UnsafeMutablePointer<UInt32>?
) -> Int32 {
    guard let sequence = ATRegistry.shared.lookup(inSequence, as: ATMusicSequenceObject.self) else {
        return atParamError
    }
    guard let outNumberOfTracks else { return atParamError }
    return atWithLock(sequence.lock) {
        outNumberOfTracks.pointee = UInt32(sequence.tracks.count)
        return 0
    }
}

@_cdecl("MusicSequenceGetIndTrack")
public func MusicSequenceGetIndTrack(
    _ inSequence: MusicSequence?,
    _ inTrackIndex: UInt32,
    _ outTrack: UnsafeMutablePointer<MusicTrack?>?
) -> Int32 {
    guard let sequence = ATRegistry.shared.lookup(inSequence, as: ATMusicSequenceObject.self) else {
        return atParamError
    }
    guard let outTrack else { return atParamError }
    return atWithLock(sequence.lock) {
        guard Int(inTrackIndex) < sequence.tracks.count else {
            outTrack.pointee = nil
            return atParamError
        }
        let track = sequence.tracks[Int(inTrackIndex)]
        outTrack.pointee = OpaquePointer(Unmanaged.passUnretained(track).toOpaque())
        return 0
    }
}

@_cdecl("MusicSequenceGetTempoTrack")
public func MusicSequenceGetTempoTrack(
    _ inSequence: MusicSequence?,
    _ outTrack: UnsafeMutablePointer<MusicTrack?>?
) -> Int32 {
    guard let sequence = ATRegistry.shared.lookup(inSequence, as: ATMusicSequenceObject.self) else {
        return atParamError
    }
    guard let outTrack else { return atParamError }
    outTrack.pointee = sequence.tempoHandle
    return 0
}

public func MusicSequenceGetSequenceType(
    _ inSequence: MusicSequence?,
    _ outType: UnsafeMutablePointer<MusicSequenceType>?
) -> Int32 {
    guard let sequence = ATRegistry.shared.lookup(inSequence, as: ATMusicSequenceObject.self) else {
        return atParamError
    }
    outType?.pointee = sequence.type
    return 0
}

public func MusicSequenceSetSequenceType(
    _ inSequence: MusicSequence?,
    _ inType: MusicSequenceType
) -> Int32 {
    guard let sequence = ATRegistry.shared.lookup(inSequence, as: ATMusicSequenceObject.self) else {
        return atParamError
    }
    sequence.type = inType
    return 0
}

@_cdecl("MusicTrackGetSequence")
public func MusicTrackGetSequence(
    _ inTrack: MusicTrack?,
    _ outSequence: UnsafeMutablePointer<MusicSequence?>?
) -> Int32 {
    guard let track = ATRegistry.shared.lookup(inTrack, as: ATMusicTrackObject.self) else {
        return atParamError
    }
    guard let sequence = track.sequence else { return atParamError }
    outSequence?.pointee = OpaquePointer(Unmanaged.passUnretained(sequence).toOpaque())
    return 0
}

public func MusicTrackNewMIDINoteEvent(
    _ inTrack: MusicTrack?,
    _ inTimeStamp: MusicTimeStamp,
    _ inMessage: UnsafePointer<MIDINoteMessage>?
) -> Int32 {
    guard let track = ATRegistry.shared.lookup(inTrack, as: ATMusicTrackObject.self) else {
        return atParamError
    }
    guard let inMessage else { return atParamError }
    guard let sequence = track.sequence else { return atParamError }
    var message = inMessage.pointee
    return atWithLock(sequence.lock) {
        let payload = withUnsafeBytes(of: &message) { Data($0) }
        track.events.append(
            ATMusicEvent(time: inTimeStamp, type: kMusicEventType_MIDINoteMessage, payload: payload)
        )
        return 0
    }
}

public func MusicTrackNewMIDIChannelEvent(
    _ inTrack: MusicTrack?,
    _ inTimeStamp: MusicTimeStamp,
    _ inMessage: UnsafePointer<MIDIChannelMessage>?
) -> Int32 {
    guard let track = ATRegistry.shared.lookup(inTrack, as: ATMusicTrackObject.self) else {
        return atParamError
    }
    guard let inMessage else { return atParamError }
    guard let sequence = track.sequence else { return atParamError }
    var message = inMessage.pointee
    return atWithLock(sequence.lock) {
        let payload = withUnsafeBytes(of: &message) { Data($0) }
        track.events.append(
            ATMusicEvent(time: inTimeStamp, type: kMusicEventType_MIDIChannelMessage, payload: payload)
        )
        return 0
    }
}

@_cdecl("MusicTrackNewExtendedTempoEvent")
public func MusicTrackNewExtendedTempoEvent(
    _ inTrack: MusicTrack?,
    _ inTimeStamp: MusicTimeStamp,
    _ inBPM: Float64
) -> Int32 {
    guard let track = ATRegistry.shared.lookup(inTrack, as: ATMusicTrackObject.self) else {
        return atParamError
    }
    guard let sequence = track.sequence else { return atParamError }
    var bpm = inBPM
    return atWithLock(sequence.lock) {
        let payload = withUnsafeBytes(of: &bpm) { Data($0) }
        track.events.append(
            ATMusicEvent(time: inTimeStamp, type: kMusicEventType_ExtendedTempo, payload: payload)
        )
        return 0
    }
}

@_cdecl("MusicTrackClear")
public func MusicTrackClear(
    _ inTrack: MusicTrack?,
    _ inStartTime: MusicTimeStamp,
    _ inEndTime: MusicTimeStamp
) -> Int32 {
    guard let track = ATRegistry.shared.lookup(inTrack, as: ATMusicTrackObject.self) else {
        return atParamError
    }
    guard let sequence = track.sequence else { return atParamError }
    return atWithLock(sequence.lock) {
        track.events.removeAll { event in
            event.time >= inStartTime && event.time < inEndTime
        }
        return 0
    }
}

@_cdecl("NewMusicEventIterator")
public func NewMusicEventIterator(
    _ inTrack: MusicTrack?,
    _ outIterator: UnsafeMutablePointer<MusicEventIterator?>?
) -> Int32 {
    guard let track = ATRegistry.shared.lookup(inTrack, as: ATMusicTrackObject.self) else {
        return atParamError
    }
    guard let outIterator else { return atParamError }
    let iterator = ATMusicEventIteratorObject(track: track)
    outIterator.pointee = ATRegistry.shared.retain(iterator)
    return 0
}

@_cdecl("DisposeMusicEventIterator")
public func DisposeMusicEventIterator(_ inIterator: MusicEventIterator?) -> Int32 {
    let status = ATRegistry.shared.release(inIterator)
    return status == atParamError ? 0 : status
}

@_cdecl("MusicEventIteratorHasCurrentEvent")
public func MusicEventIteratorHasCurrentEvent(
    _ inIterator: MusicEventIterator?,
    _ outHasCurEvent: UnsafeMutablePointer<UInt8>?
) -> Int32 {
    guard let iterator = ATRegistry.shared.lookup(inIterator, as: ATMusicEventIteratorObject.self) else {
        return atParamError
    }
    outHasCurEvent?.pointee = iterator.index < iterator.snapshot.count ? 1 : 0
    return 0
}

@_cdecl("MusicEventIteratorHasNextEvent")
public func MusicEventIteratorHasNextEvent(
    _ inIterator: MusicEventIterator?,
    _ outHasNextEvent: UnsafeMutablePointer<UInt8>?
) -> Int32 {
    guard let iterator = ATRegistry.shared.lookup(inIterator, as: ATMusicEventIteratorObject.self) else {
        return atParamError
    }
    outHasNextEvent?.pointee = (iterator.index + 1) < iterator.snapshot.count ? 1 : 0
    return 0
}

@_cdecl("MusicEventIteratorHasPreviousEvent")
public func MusicEventIteratorHasPreviousEvent(
    _ inIterator: MusicEventIterator?,
    _ outHasPrevEvent: UnsafeMutablePointer<UInt8>?
) -> Int32 {
    guard let iterator = ATRegistry.shared.lookup(inIterator, as: ATMusicEventIteratorObject.self) else {
        return atParamError
    }
    outHasPrevEvent?.pointee = iterator.index > 0 ? 1 : 0
    return 0
}

@_cdecl("MusicEventIteratorNextEvent")
public func MusicEventIteratorNextEvent(_ inIterator: MusicEventIterator?) -> Int32 {
    guard let iterator = ATRegistry.shared.lookup(inIterator, as: ATMusicEventIteratorObject.self) else {
        return atParamError
    }
    guard iterator.index < iterator.snapshot.count else { return atParamError }
    iterator.index += 1
    return 0
}

@_cdecl("MusicEventIteratorPreviousEvent")
public func MusicEventIteratorPreviousEvent(_ inIterator: MusicEventIterator?) -> Int32 {
    guard let iterator = ATRegistry.shared.lookup(inIterator, as: ATMusicEventIteratorObject.self) else {
        return atParamError
    }
    guard iterator.index > 0 else { return atParamError }
    iterator.index -= 1
    return 0
}

@_cdecl("MusicEventIteratorSeek")
public func MusicEventIteratorSeek(
    _ inIterator: MusicEventIterator?,
    _ inTimeStamp: MusicTimeStamp
) -> Int32 {
    guard let iterator = ATRegistry.shared.lookup(inIterator, as: ATMusicEventIteratorObject.self) else {
        return atParamError
    }
    iterator.index = iterator.snapshot.firstIndex { $0.time >= inTimeStamp } ?? iterator.snapshot.count
    return 0
}

@_cdecl("MusicEventIteratorGetEventInfo")
public func MusicEventIteratorGetEventInfo(
    _ inIterator: MusicEventIterator?,
    _ outTimeStamp: UnsafeMutablePointer<MusicTimeStamp>?,
    _ outEventType: UnsafeMutablePointer<MusicEventType>?,
    _ outEventData: UnsafeMutablePointer<UnsafeRawPointer?>?,
    _ outEventDataSize: UnsafeMutablePointer<UInt32>?
) -> Int32 {
    guard let iterator = ATRegistry.shared.lookup(inIterator, as: ATMusicEventIteratorObject.self) else {
        return atParamError
    }
    guard iterator.index < iterator.snapshot.count else { return atParamError }
    let event = iterator.snapshot[iterator.index]
    let bound = iterator.bindPayload(event.payload)
    outTimeStamp?.pointee = event.time
    outEventType?.pointee = event.type
    outEventData?.pointee = bound.0
    outEventDataSize?.pointee = bound.1
    return 0
}

@_cdecl("MusicEventIteratorDeleteEvent")
public func MusicEventIteratorDeleteEvent(_ inIterator: MusicEventIterator?) -> Int32 {
    guard let iterator = ATRegistry.shared.lookup(inIterator, as: ATMusicEventIteratorObject.self) else {
        return atParamError
    }
    guard iterator.index < iterator.snapshot.count else { return atParamError }
    guard let sequence = iterator.track.sequence else { return atParamError }
    let event = iterator.snapshot[iterator.index]
    return atWithLock(sequence.lock) {
        if let idx = iterator.track.events.firstIndex(where: {
            $0.time == event.time && $0.type == event.type && $0.payload == event.payload
        }) {
            iterator.track.events.remove(at: idx)
        }
        iterator.snapshot.remove(at: iterator.index)
        return 0
    }
}

@_cdecl("NewMusicPlayer")
public func NewMusicPlayer(_ outPlayer: UnsafeMutablePointer<MusicPlayer?>?) -> Int32 {
    guard let outPlayer else { return atParamError }
    outPlayer.pointee = ATRegistry.shared.retain(ATMusicPlayerObject())
    return 0
}

@_cdecl("DisposeMusicPlayer")
public func DisposeMusicPlayer(_ inPlayer: MusicPlayer?) -> Int32 {
    let status = ATRegistry.shared.release(inPlayer)
    return status == atParamError ? 0 : status
}

@_cdecl("MusicPlayerSetSequence")
public func MusicPlayerSetSequence(
    _ inPlayer: MusicPlayer?,
    _ inSequence: MusicSequence?
) -> Int32 {
    guard let player = ATRegistry.shared.lookup(inPlayer, as: ATMusicPlayerObject.self) else {
        return atParamError
    }
    if let inSequence {
        guard let sequence = ATRegistry.shared.lookup(inSequence, as: ATMusicSequenceObject.self) else {
            return atParamError
        }
        player.sequence = sequence
    } else {
        player.sequence = nil
    }
    return 0
}

@_cdecl("MusicPlayerGetSequence")
public func MusicPlayerGetSequence(
    _ inPlayer: MusicPlayer?,
    _ outSequence: UnsafeMutablePointer<MusicSequence?>?
) -> Int32 {
    guard let player = ATRegistry.shared.lookup(inPlayer, as: ATMusicPlayerObject.self) else {
        return atParamError
    }
    if let sequence = player.sequence {
        outSequence?.pointee = OpaquePointer(Unmanaged.passUnretained(sequence).toOpaque())
    } else {
        outSequence?.pointee = nil
    }
    return 0
}

@_cdecl("MusicPlayerStart")
public func MusicPlayerStart(_ inPlayer: MusicPlayer?) -> Int32 {
    guard let player = ATRegistry.shared.lookup(inPlayer, as: ATMusicPlayerObject.self) else {
        return atParamError
    }
    player.playing = true
    player.startHost = Date().timeIntervalSince1970
    player.startStamp = player.time
    return 0
}

@_cdecl("MusicPlayerStop")
public func MusicPlayerStop(_ inPlayer: MusicPlayer?) -> Int32 {
    guard let player = ATRegistry.shared.lookup(inPlayer, as: ATMusicPlayerObject.self) else {
        return atParamError
    }
    player.playing = false
    return 0
}

@_cdecl("MusicPlayerSetTime")
public func MusicPlayerSetTime(
    _ inPlayer: MusicPlayer?,
    _ inTime: MusicTimeStamp
) -> Int32 {
    guard let player = ATRegistry.shared.lookup(inPlayer, as: ATMusicPlayerObject.self) else {
        return atParamError
    }
    player.time = inTime
    return 0
}

@_cdecl("MusicPlayerGetTime")
public func MusicPlayerGetTime(
    _ inPlayer: MusicPlayer?,
    _ outTime: UnsafeMutablePointer<MusicTimeStamp>?
) -> Int32 {
    guard let player = ATRegistry.shared.lookup(inPlayer, as: ATMusicPlayerObject.self) else {
        return atParamError
    }
    if player.playing {
        let elapsed = Date().timeIntervalSince1970 - player.startHost
        let bpm = atSequenceTempo(player.sequence) * player.rate
        let beatsPerSecond = bpm / 60.0
        player.time = player.startStamp + elapsed * beatsPerSecond
    }
    outTime?.pointee = player.time
    return 0
}

@_cdecl("MusicPlayerIsPlaying")
public func MusicPlayerIsPlaying(
    _ inPlayer: MusicPlayer?,
    _ outIsPlaying: UnsafeMutablePointer<UInt8>?
) -> Int32 {
    guard let player = ATRegistry.shared.lookup(inPlayer, as: ATMusicPlayerObject.self) else {
        return atParamError
    }
    outIsPlaying?.pointee = player.playing ? 1 : 0
    return 0
}

@_cdecl("MusicPlayerSetPlayRateScalar")
public func MusicPlayerSetPlayRateScalar(
    _ inPlayer: MusicPlayer?,
    _ inScaleRate: Float64
) -> Int32 {
    guard let player = ATRegistry.shared.lookup(inPlayer, as: ATMusicPlayerObject.self) else {
        return atParamError
    }
    player.rate = inScaleRate
    return 0
}

@_cdecl("MusicPlayerGetPlayRateScalar")
public func MusicPlayerGetPlayRateScalar(
    _ inPlayer: MusicPlayer?,
    _ outScaleRate: UnsafeMutablePointer<Float64>?
) -> Int32 {
    guard let player = ATRegistry.shared.lookup(inPlayer, as: ATMusicPlayerObject.self) else {
        return atParamError
    }
    outScaleRate?.pointee = player.rate
    return 0
}

#if canImport(CoreFoundation)
public func MusicSequenceFileLoadData(
    _ inSequence: MusicSequence?,
    _ inData: CFData?,
    _ inFileTypeHint: MusicSequenceFileTypeID,
    _ inFlags: MusicSequenceLoadFlags
) -> Int32 {
    _ = inFlags
    guard let sequence = ATRegistry.shared.lookup(inSequence, as: ATMusicSequenceObject.self) else {
        return atParamError
    }
    guard let inData else { return atParamError }
    let length = CFDataGetLength(inData)
    if length <= 0 {
        return kAudioFileInvalidFileError
    }
    if inFileTypeHint != .midiType && inFileTypeHint != .anyType {
        return kAudioFileUnsupportedFileTypeError
    }
    let bytes = [UInt8](UnsafeBufferPointer(start: CFDataGetBytePtr(inData), count: length))
    return atLoadSMF(sequence: sequence, bytes: bytes)
}

internal func atSequenceTempo(_ sequence: ATMusicSequenceObject?) -> Float64 {
    guard let sequence else { return 120 }
    if let tempoEvent = sequence.tempoTrack.events.first(where: { $0.type == kMusicEventType_ExtendedTempo }),
       tempoEvent.payload.count >= 8
    {
        return tempoEvent.payload.withUnsafeBytes { $0.loadUnaligned(as: Float64.self) }
    }
    return 120
}

internal func atLoadSMF(sequence: ATMusicSequenceObject, bytes: [UInt8]) -> Int32 {
    guard bytes.count >= 14,
          bytes[0] == 0x4D, bytes[1] == 0x54, bytes[2] == 0x68, bytes[3] == 0x64
    else {
        return kAudioFileUnsupportedFileTypeError
    }
    func be32(_ i: Int) -> UInt32 {
        (UInt32(bytes[i]) << 24) | (UInt32(bytes[i + 1]) << 16) | (UInt32(bytes[i + 2]) << 8) | UInt32(bytes[i + 3])
    }
    func be16(_ i: Int) -> UInt16 {
        (UInt16(bytes[i]) << 8) | UInt16(bytes[i + 1])
    }
    let headerLen = be32(4)
    if headerLen < 6 { return kAudioFileInvalidFileError }
    let format = be16(8)
    let ntrks = Int(be16(10))
    let division = be16(12)
    _ = format
    let ticksPerBeat = Float64(division & 0x7FFF)
    if ticksPerBeat <= 0 { return kAudioFileInvalidFileError }
    var offset = 8 + Int(headerLen)
    var trackIndex = 0
    while offset + 8 <= bytes.count && trackIndex < ntrks {
        if bytes[offset] != 0x4D || bytes[offset + 1] != 0x54
            || bytes[offset + 2] != 0x72 || bytes[offset + 3] != 0x6B
        {
            return kAudioFileInvalidFileError
        }
        let chunkLen = Int(be32(offset + 4))
        let start = offset + 8
        let end = min(start + chunkLen, bytes.count)
        let status = atParseSMFTrack(
            sequence: sequence,
            bytes: bytes,
            start: start,
            end: end,
            ticksPerBeat: ticksPerBeat,
            isFirst: false
        )
        if status != 0 { return status }
        offset = start + chunkLen
        trackIndex += 1
    }
    _ = format
    return 0
}

internal func atParseSMFTrack(
    sequence: ATMusicSequenceObject,
    bytes: [UInt8],
    start: Int,
    end: Int,
    ticksPerBeat: Float64,
    isFirst: Bool
) -> Int32 {
    var i = start
    var tick: UInt32 = 0
    var running: UInt8 = 0
    let track: ATMusicTrackObject
    if isFirst {
        track = sequence.tempoTrack
    } else {
        let created = ATMusicTrackObject(sequence: sequence, isTempo: false)
        sequence.tracks.append(created)
        _ = ATRegistry.shared.retain(created)
        track = created
    }
    func readVLQ() -> UInt32? {
        var value: UInt32 = 0
        while i < end {
            let b = bytes[i]
            i += 1
            value = (value << 7) | UInt32(b & 0x7F)
            if b & 0x80 == 0 { return value }
            if value > 0x0FFF_FFFF { return nil }
        }
        return nil
    }
    while i < end {
        guard let delta = readVLQ() else { break }
        tick += delta
        if i >= end { break }
        var statusByte = bytes[i]
        if statusByte < 0x80 {
            statusByte = running
        } else {
            i += 1
            running = statusByte
        }
        let time = Float64(tick) / ticksPerBeat
        if statusByte == 0xFF {
            if i >= end { break }
            let meta = bytes[i]
            i += 1
            guard let len = readVLQ() else { break }
            let payloadStart = i
            i = min(i + Int(len), end)
            if meta == 0x51 && len >= 3 {
                let us = (UInt32(bytes[payloadStart]) << 16)
                    | (UInt32(bytes[payloadStart + 1]) << 8)
                    | UInt32(bytes[payloadStart + 2])
                var bpm = 60_000_000.0 / Float64(max(us, 1))
                let payload = withUnsafeBytes(of: &bpm) { Data($0) }
                sequence.tempoTrack.events.append(
                    ATMusicEvent(time: time, type: kMusicEventType_ExtendedTempo, payload: payload)
                )
            }
            continue
        }
        if statusByte >= 0x80 && statusByte < 0xF0 {
            let command = statusByte & 0xF0
            let channel = statusByte & 0x0F
            if command == 0x90 || command == 0x80 {
                if i + 1 >= end { break }
                let note = bytes[i]
                let vel = bytes[i + 1]
                i += 2
                var message = MIDINoteMessage(
                    channel: channel,
                    note: note,
                    velocity: command == 0x80 ? 0 : vel,
                    releaseVelocity: 0,
                    duration: command == 0x80 ? 0 : 0.5
                )
                let payload = withUnsafeBytes(of: &message) { Data($0) }
                track.events.append(
                    ATMusicEvent(time: time, type: kMusicEventType_MIDINoteMessage, payload: payload)
                )
            } else {
                let dataBytes = (command == 0xC0 || command == 0xD0) ? 1 : 2
                if i + dataBytes > end { break }
                var message = MIDIChannelMessage(
                    status: statusByte,
                    data1: bytes[i],
                    data2: dataBytes == 2 ? bytes[i + 1] : 0,
                    reserved: 0
                )
                i += dataBytes
                let payload = withUnsafeBytes(of: &message) { Data($0) }
                track.events.append(
                    ATMusicEvent(time: time, type: kMusicEventType_MIDIChannelMessage, payload: payload)
                )
            }
        } else if statusByte == 0xF0 || statusByte == 0xF7 {
            guard let len = readVLQ() else { break }
            i = min(i + Int(len), end)
        }
    }
    return 0
}

public func MusicSequenceFileLoad(
    _ inSequence: MusicSequence?,
    _ inFileRef: CFURL?,
    _ inFileTypeHint: MusicSequenceFileTypeID,
    _ inFlags: MusicSequenceLoadFlags
) -> Int32 {
    guard let inFileRef else { return atParamError }
    guard let path = atPathFromCFURL(inFileRef) else { return kAudioFileInvalidFileError }
    guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
        return kAudioFileFileNotFoundError
    }
    let cf = data.withUnsafeBytes { buffer in
        CFDataCreate(kCFAllocatorDefault, buffer.bindMemory(to: UInt8.self).baseAddress, data.count)!
    }
    return MusicSequenceFileLoadData(inSequence, cf, inFileTypeHint, inFlags)
}

public func MusicSequenceFileCreateData(
    _ inSequence: MusicSequence?,
    _ inFileType: MusicSequenceFileTypeID,
    _ inFlags: MusicSequenceFileFlags,
    _ inResolution: Int16,
    _ outData: UnsafeMutablePointer<Unmanaged<CFData>?>?
) -> Int32 {
    _ = inFlags
    outData?.pointee = nil
    guard let sequence = ATRegistry.shared.lookup(inSequence, as: ATMusicSequenceObject.self) else {
        return kAudioToolboxErr_NoSequence
    }
    if inFileType != .midiType && inFileType != .anyType {
        return kAudioToolboxErr_InvalidSequenceType
    }
    let resolution = inResolution == 0 ? Int16(480) : inResolution
    let bytes = atEncodeSMF(sequence: sequence, ticksPerBeat: UInt16(max(resolution, 1)))
    let cf = bytes.withUnsafeBytes { buffer in
        CFDataCreate(kCFAllocatorDefault, buffer.bindMemory(to: UInt8.self).baseAddress, bytes.count)!
    }
    outData?.pointee = Unmanaged.passRetained(cf)
    return 0
}

public func MusicSequenceFileCreate(
    _ inSequence: MusicSequence?,
    _ inFileRef: CFURL?,
    _ inFileType: MusicSequenceFileTypeID,
    _ inFlags: MusicSequenceFileFlags,
    _ inResolution: Int16
) -> Int32 {
    guard let inFileRef else { return atParamError }
    guard let path = atPathFromCFURL(inFileRef) else { return kAudioFileInvalidFileError }
    var data: Unmanaged<CFData>?
    let status = MusicSequenceFileCreateData(inSequence, inFileType, inFlags, inResolution, &data)
    guard status == 0, let retained = data else { return status }
    let cf = retained.takeRetainedValue()
    let length = CFDataGetLength(cf)
    let bytes = Data(bytes: CFDataGetBytePtr(cf), count: length)
    do {
        try bytes.write(to: URL(fileURLWithPath: path), options: inFlags.contains(.eraseFile) ? .atomic : .atomic)
    } catch {
        return kAudioFileUnspecifiedError
    }
    return 0
}
#endif

@_cdecl("MusicSequenceGetBeatsForSeconds")
public func MusicSequenceGetBeatsForSeconds(
    _ inSequence: MusicSequence?,
    _ inSeconds: Float64,
    _ outBeats: UnsafeMutablePointer<MusicTimeStamp>?
) -> Int32 {
    guard let sequence = ATRegistry.shared.lookup(inSequence, as: ATMusicSequenceObject.self) else {
        return kAudioToolboxErr_NoSequence
    }
    let bpm = atSequenceTempo(sequence)
    outBeats?.pointee = inSeconds * (bpm / 60.0)
    return 0
}

@_cdecl("MusicSequenceGetSecondsForBeats")
public func MusicSequenceGetSecondsForBeats(
    _ inSequence: MusicSequence?,
    _ inBeats: MusicTimeStamp,
    _ outSeconds: UnsafeMutablePointer<Float64>?
) -> Int32 {
    guard let sequence = ATRegistry.shared.lookup(inSequence, as: ATMusicSequenceObject.self) else {
        return kAudioToolboxErr_NoSequence
    }
    let bpm = atSequenceTempo(sequence)
    outSeconds?.pointee = inBeats * 60.0 / max(bpm, 1)
    return 0
}

public func MusicSequenceGetTrackIndex(
    _ inSequence: MusicSequence?,
    _ inTrack: MusicTrack?,
    _ outTrackIndex: UnsafeMutablePointer<UInt32>?
) -> Int32 {
    guard let sequence = ATRegistry.shared.lookup(inSequence, as: ATMusicSequenceObject.self) else {
        return kAudioToolboxErr_NoSequence
    }
    guard let track = ATRegistry.shared.lookup(inTrack, as: ATMusicTrackObject.self) else {
        return kAudioToolboxErr_TrackNotFound
    }
    return atWithLock(sequence.lock) {
        if let index = sequence.tracks.firstIndex(where: { $0 === track }) {
            outTrackIndex?.pointee = UInt32(index)
            return 0
        }
        return kAudioToolboxErr_TrackNotFound
    }
}

public func MusicSequenceSetAUGraph(
    _ inSequence: MusicSequence?,
    _ inGraph: AUGraph?
) -> Int32 {
    guard let sequence = ATRegistry.shared.lookup(inSequence, as: ATMusicSequenceObject.self) else {
        return kAudioToolboxErr_NoSequence
    }
    if let inGraph {
        guard ATRegistry.shared.lookup(inGraph, as: ATAUGraphObject.self) != nil else {
            return kAUGraphErr_InvalidAudioUnit
        }
    }
    sequence.graph = inGraph
    return 0
}

public func MusicSequenceGetAUGraph(
    _ inSequence: MusicSequence?,
    _ outGraph: UnsafeMutablePointer<AUGraph?>?
) -> Int32 {
    guard let sequence = ATRegistry.shared.lookup(inSequence, as: ATMusicSequenceObject.self) else {
        return kAudioToolboxErr_NoSequence
    }
    outGraph?.pointee = sequence.graph
    return 0
}

public func MusicSequenceBeatsToBarBeatTime(
    _ inSequence: MusicSequence?,
    _ inBeats: MusicTimeStamp,
    _ inSubbeatDivisor: UInt32,
    _ outBarBeatTime: UnsafeMutablePointer<CABarBeatTime>?
) -> Int32 {
    guard ATRegistry.shared.lookup(inSequence, as: ATMusicSequenceObject.self) != nil else {
        return kAudioToolboxErr_NoSequence
    }
    let divisor = max(inSubbeatDivisor, 1)
    let beatsPerBar: Float64 = 4
    let bar = Int32(floor(inBeats / beatsPerBar))
    let beatInBar = inBeats - Float64(bar) * beatsPerBar
    let beat = UInt16(floor(beatInBar)) + 1
    let fraction = beatInBar - floor(beatInBar)
    var time = CABarBeatTime()
    time.bar = bar
    time.beat = beat
    time.subbeat = UInt16(fraction * Float64(divisor))
    time.subbeatDivisor = UInt16(divisor)
    outBarBeatTime?.pointee = time
    return 0
}

public func MusicSequenceBarBeatTimeToBeats(
    _ inSequence: MusicSequence?,
    _ inBarBeatTime: UnsafePointer<CABarBeatTime>?,
    _ outBeats: UnsafeMutablePointer<MusicTimeStamp>?
) -> Int32 {
    guard ATRegistry.shared.lookup(inSequence, as: ATMusicSequenceObject.self) != nil else {
        return kAudioToolboxErr_NoSequence
    }
    guard let inBarBeatTime else { return atParamError }
    let time = inBarBeatTime.pointee
    let divisor = max(Float64(time.subbeatDivisor), 1)
    let beats = Float64(time.bar) * 4.0 + Float64(max(Int(time.beat), 1) - 1) + Float64(time.subbeat) / divisor
    outBeats?.pointee = beats
    return 0
}

public func MusicTrackCopyInsert(
    _ inSourceTrack: MusicTrack?,
    _ inSourceStartTime: MusicTimeStamp,
    _ inSourceEndTime: MusicTimeStamp,
    _ inDestTrack: MusicTrack?,
    _ inDestInsertTime: MusicTimeStamp
) -> Int32 {
    guard let source = ATRegistry.shared.lookup(inSourceTrack, as: ATMusicTrackObject.self),
          let dest = ATRegistry.shared.lookup(inDestTrack, as: ATMusicTrackObject.self),
          let sequence = dest.sequence
    else {
        return kAudioToolboxErr_TrackNotFound
    }
    return atWithLock(sequence.lock) {
        let copied = source.events.filter { $0.time >= inSourceStartTime && $0.time < inSourceEndTime }
        let span = inSourceEndTime - inSourceStartTime
        for index in dest.events.indices {
            if dest.events[index].time >= inDestInsertTime {
                dest.events[index].time += span
            }
        }
        for event in copied {
            var moved = event
            moved.time = inDestInsertTime + (event.time - inSourceStartTime)
            dest.events.append(moved)
        }
        return 0
    }
}

public func MusicTrackCut(
    _ inTrack: MusicTrack?,
    _ inStartTime: MusicTimeStamp,
    _ inEndTime: MusicTimeStamp
) -> Int32 {
    guard let track = ATRegistry.shared.lookup(inTrack, as: ATMusicTrackObject.self),
          let sequence = track.sequence
    else {
        return kAudioToolboxErr_TrackNotFound
    }
    return atWithLock(sequence.lock) {
        let span = inEndTime - inStartTime
        track.events.removeAll { $0.time >= inStartTime && $0.time < inEndTime }
        for index in track.events.indices {
            if track.events[index].time >= inEndTime {
                track.events[index].time -= span
            }
        }
        return 0
    }
}

public func MusicTrackMerge(
    _ inSourceTrack: MusicTrack?,
    _ inSourceStartTime: MusicTimeStamp,
    _ inSourceEndTime: MusicTimeStamp,
    _ inDestTrack: MusicTrack?,
    _ inDestInsertTime: MusicTimeStamp
) -> Int32 {
    guard let source = ATRegistry.shared.lookup(inSourceTrack, as: ATMusicTrackObject.self),
          let dest = ATRegistry.shared.lookup(inDestTrack, as: ATMusicTrackObject.self),
          let sequence = dest.sequence
    else {
        return kAudioToolboxErr_TrackNotFound
    }
    return atWithLock(sequence.lock) {
        let copied = source.events.filter { $0.time >= inSourceStartTime && $0.time < inSourceEndTime }
        for event in copied {
            var moved = event
            moved.time = inDestInsertTime + (event.time - inSourceStartTime)
            dest.events.append(moved)
        }
        return 0
    }
}

public func MusicTrackMoveEvents(
    _ inTrack: MusicTrack?,
    _ inStartTime: MusicTimeStamp,
    _ inEndTime: MusicTimeStamp,
    _ inMoveTime: MusicTimeStamp
) -> Int32 {
    guard let track = ATRegistry.shared.lookup(inTrack, as: ATMusicTrackObject.self),
          let sequence = track.sequence
    else {
        return kAudioToolboxErr_TrackNotFound
    }
    return atWithLock(sequence.lock) {
        for index in track.events.indices {
            if track.events[index].time >= inStartTime && track.events[index].time < inEndTime {
                track.events[index].time += inMoveTime
            }
        }
        return 0
    }
}

public func MusicTrackGetProperty(
    _ inTrack: MusicTrack?,
    _ inPropertyID: UInt32,
    _ outData: UnsafeMutableRawPointer?,
    _ ioDataSize: UnsafeMutablePointer<UInt32>?
) -> Int32 {
    guard let track = ATRegistry.shared.lookup(inTrack, as: ATMusicTrackObject.self) else {
        return kAudioToolboxErr_TrackNotFound
    }
    switch inPropertyID {
    case kSequenceTrackProperty_MuteStatus:
        ioDataSize?.pointee = 4
        outData?.storeBytes(of: track.mute, as: UInt32.self)
    case kSequenceTrackProperty_SoloStatus:
        ioDataSize?.pointee = 4
        outData?.storeBytes(of: track.solo, as: UInt32.self)
    case kSequenceTrackProperty_OffsetTime:
        ioDataSize?.pointee = 8
        outData?.storeBytes(of: track.offsetTime, as: MusicTimeStamp.self)
    case kSequenceTrackProperty_TrackLength:
        ioDataSize?.pointee = 8
        let length = track.length > 0 ? track.length : (track.events.map(\.time).max() ?? 0)
        outData?.storeBytes(of: length, as: MusicTimeStamp.self)
    case kSequenceTrackProperty_TimeResolution:
        ioDataSize?.pointee = 2
        outData?.storeBytes(of: track.timeResolution, as: UInt16.self)
    default:
        return kAudioToolboxErr_InvalidEventType
    }
    return 0
}

public func MusicTrackSetProperty(
    _ inTrack: MusicTrack?,
    _ inPropertyID: UInt32,
    _ inData: UnsafeRawPointer?,
    _ inDataSize: UInt32
) -> Int32 {
    guard let track = ATRegistry.shared.lookup(inTrack, as: ATMusicTrackObject.self) else {
        return kAudioToolboxErr_TrackNotFound
    }
    guard let inData else { return atParamError }
    switch inPropertyID {
    case kSequenceTrackProperty_MuteStatus:
        guard inDataSize >= 4 else { return atParamError }
        track.mute = inData.loadUnaligned(as: UInt32.self)
    case kSequenceTrackProperty_SoloStatus:
        guard inDataSize >= 4 else { return atParamError }
        track.solo = inData.loadUnaligned(as: UInt32.self)
    case kSequenceTrackProperty_OffsetTime:
        guard inDataSize >= 8 else { return atParamError }
        track.offsetTime = inData.loadUnaligned(as: MusicTimeStamp.self)
    case kSequenceTrackProperty_TrackLength:
        guard inDataSize >= 8 else { return atParamError }
        track.length = inData.loadUnaligned(as: MusicTimeStamp.self)
    case kSequenceTrackProperty_TimeResolution:
        guard inDataSize >= 2 else { return atParamError }
        track.timeResolution = inData.loadUnaligned(as: UInt16.self)
    default:
        return kAudioToolboxErr_InvalidEventType
    }
    return 0
}

@_cdecl("MusicEventIteratorSetEventTime")
public func MusicEventIteratorSetEventTime(
    _ inIterator: MusicEventIterator?,
    _ inTimeStamp: MusicTimeStamp
) -> Int32 {
    guard let iterator = ATRegistry.shared.lookup(inIterator, as: ATMusicEventIteratorObject.self) else {
        return atParamError
    }
    guard iterator.index < iterator.snapshot.count else { return kAudioToolboxErr_EndOfTrack }
    guard let sequence = iterator.track.sequence else { return kAudioToolboxErr_NoSequence }
    let event = iterator.snapshot[iterator.index]
    return atWithLock(sequence.lock) {
        if let idx = iterator.track.events.firstIndex(where: {
            $0.time == event.time && $0.type == event.type && $0.payload == event.payload
        }) {
            iterator.track.events[idx].time = inTimeStamp
        }
        iterator.snapshot[iterator.index].time = inTimeStamp
        return 0
    }
}

public func MusicEventIteratorSetEventInfo(
    _ inIterator: MusicEventIterator?,
    _ inEventType: MusicEventType,
    _ inEventData: UnsafeRawPointer?
) -> Int32 {
    guard let iterator = ATRegistry.shared.lookup(inIterator, as: ATMusicEventIteratorObject.self) else {
        return atParamError
    }
    guard iterator.index < iterator.snapshot.count else { return kAudioToolboxErr_EndOfTrack }
    guard let inEventData else { return atParamError }
    guard let sequence = iterator.track.sequence else { return kAudioToolboxErr_NoSequence }
    let size = atMusicEventPayloadSize(inEventType, inEventData)
    let payload = Data(bytes: inEventData, count: size)
    let event = iterator.snapshot[iterator.index]
    return atWithLock(sequence.lock) {
        if let idx = iterator.track.events.firstIndex(where: {
            $0.time == event.time && $0.type == event.type && $0.payload == event.payload
        }) {
            iterator.track.events[idx].type = inEventType
            iterator.track.events[idx].payload = payload
        }
        iterator.snapshot[iterator.index].type = inEventType
        iterator.snapshot[iterator.index].payload = payload
        return 0
    }
}

private func atMusicEventPayloadSize(_ type: MusicEventType, _ pointer: UnsafeRawPointer) -> Int {
    switch type {
    case kMusicEventType_MIDINoteMessage:
        return MemoryLayout<MIDINoteMessage>.size
    case kMusicEventType_MIDIChannelMessage:
        return MemoryLayout<MIDIChannelMessage>.size
    case kMusicEventType_ExtendedTempo:
        return MemoryLayout<Float64>.size
    case kMusicEventType_Parameter:
        return MemoryLayout<ParameterEvent>.size
    case kMusicEventType_MIDIRawData:
        let length = Int(pointer.loadUnaligned(as: UInt32.self))
        return MemoryLayout<UInt32>.size + max(length, 1)
    case kMusicEventType_Meta:
        let header = MemoryLayout<UInt32>.size + MemoryLayout<UInt32>.size
        let length = Int(pointer.loadUnaligned(fromByteOffset: 4, as: UInt32.self))
        return header + max(length, 1)
    default:
        return 8
    }
}

public func MusicTrackNewMetaEvent(
    _ inTrack: MusicTrack?,
    _ inTimeStamp: MusicTimeStamp,
    _ inMetaEvent: UnsafePointer<MIDIMetaEvent>?
) -> Int32 {
    guard let track = ATRegistry.shared.lookup(inTrack, as: ATMusicTrackObject.self) else {
        return atParamError
    }
    guard let inMetaEvent else { return atParamError }
    guard let sequence = track.sequence else { return atParamError }
    let size = atMusicEventPayloadSize(kMusicEventType_Meta, UnsafeRawPointer(inMetaEvent))
    let payload = Data(bytes: inMetaEvent, count: size)
    return atWithLock(sequence.lock) {
        track.events.append(ATMusicEvent(time: inTimeStamp, type: kMusicEventType_Meta, payload: payload))
        return 0
    }
}

public func MusicTrackNewMIDIRawDataEvent(
    _ inTrack: MusicTrack?,
    _ inTimeStamp: MusicTimeStamp,
    _ inRawData: UnsafePointer<MIDIRawData>?
) -> Int32 {
    guard let track = ATRegistry.shared.lookup(inTrack, as: ATMusicTrackObject.self) else {
        return atParamError
    }
    guard let inRawData else { return atParamError }
    guard let sequence = track.sequence else { return atParamError }
    let size = atMusicEventPayloadSize(kMusicEventType_MIDIRawData, UnsafeRawPointer(inRawData))
    let payload = Data(bytes: inRawData, count: size)
    return atWithLock(sequence.lock) {
        track.events.append(ATMusicEvent(time: inTimeStamp, type: kMusicEventType_MIDIRawData, payload: payload))
        return 0
    }
}

public func MusicTrackNewParameterEvent(
    _ inTrack: MusicTrack?,
    _ inTimeStamp: MusicTimeStamp,
    _ inInfo: UnsafePointer<ParameterEvent>?
) -> Int32 {
    guard let track = ATRegistry.shared.lookup(inTrack, as: ATMusicTrackObject.self) else {
        return atParamError
    }
    guard let inInfo else { return atParamError }
    guard let sequence = track.sequence else { return atParamError }
    var info = inInfo.pointee
    return atWithLock(sequence.lock) {
        let payload = withUnsafeBytes(of: &info) { Data($0) }
        track.events.append(ATMusicEvent(time: inTimeStamp, type: kMusicEventType_Parameter, payload: payload))
        return 0
    }
}

@_cdecl("MusicSequenceReverse")
public func MusicSequenceReverse(_ inSequence: MusicSequence?) -> Int32 {
    guard let sequence = ATRegistry.shared.lookup(inSequence, as: ATMusicSequenceObject.self) else {
        return kAudioToolboxErr_NoSequence
    }
    return atWithLock(sequence.lock) {
        var tracks = sequence.tracks
        tracks.append(sequence.tempoTrack)
        let end = tracks.flatMap(\.events).map(\.time).max() ?? 0
        for track in tracks {
            for index in track.events.indices {
                track.events[index].time = end - track.events[index].time
            }
        }
        return 0
    }
}

@_cdecl("MusicPlayerPreroll")
public func MusicPlayerPreroll(_ inPlayer: MusicPlayer?) -> Int32 {
    guard ATRegistry.shared.lookup(inPlayer, as: ATMusicPlayerObject.self) != nil else {
        return kAudioToolboxErr_InvalidPlayerState
    }
    return 0
}

internal func atEncodeSMF(sequence: ATMusicSequenceObject, ticksPerBeat: UInt16) -> [UInt8] {
    func vlq(_ value: UInt32) -> [UInt8] {
        var buffer: [UInt8] = []
        var remaining = value
        buffer.append(UInt8(remaining & 0x7F))
        remaining >>= 7
        while remaining > 0 {
            buffer.append(UInt8((remaining & 0x7F) | 0x80))
            remaining >>= 7
        }
        return buffer.reversed()
    }
    func be16(_ value: UInt16) -> [UInt8] {
        [UInt8((value >> 8) & 0xFF), UInt8(value & 0xFF)]
    }
    func be32(_ value: UInt32) -> [UInt8] {
        [
            UInt8((value >> 24) & 0xFF),
            UInt8((value >> 16) & 0xFF),
            UInt8((value >> 8) & 0xFF),
            UInt8(value & 0xFF),
        ]
    }
    func encodeTrack(_ events: [ATMusicEvent], extraTempo: Bool) -> [UInt8] {
        var payload: [UInt8] = []
        var lastTick: UInt32 = 0
        let ordered = events.sorted { $0.time < $1.time }
        for event in ordered {
            let tick = UInt32(max(event.time, 0) * Float64(ticksPerBeat))
            payload.append(contentsOf: vlq(tick >= lastTick ? tick - lastTick : 0))
            lastTick = tick
            if event.type == kMusicEventType_ExtendedTempo, event.payload.count >= 8 {
                let bpm = event.payload.withUnsafeBytes { $0.loadUnaligned(as: Float64.self) }
                let us = UInt32((60_000_000.0 / max(bpm, 1)).rounded())
                payload.append(contentsOf: [0xFF, 0x51, 0x03, UInt8((us >> 16) & 0xFF), UInt8((us >> 8) & 0xFF), UInt8(us & 0xFF)])
            } else if event.type == kMusicEventType_MIDINoteMessage, event.payload.count >= MemoryLayout<MIDINoteMessage>.size {
                let message = event.payload.withUnsafeBytes { $0.loadUnaligned(as: MIDINoteMessage.self) }
                payload.append(0x90 | (message.channel & 0x0F))
                payload.append(message.note)
                payload.append(message.velocity)
            } else if event.type == kMusicEventType_MIDIChannelMessage, event.payload.count >= MemoryLayout<MIDIChannelMessage>.size {
                let message = event.payload.withUnsafeBytes { $0.loadUnaligned(as: MIDIChannelMessage.self) }
                payload.append(message.status)
                payload.append(message.data1)
                payload.append(message.data2)
            } else {
                payload.append(contentsOf: [0xFF, 0x01, 0x00])
            }
            _ = extraTempo
        }
        payload.append(contentsOf: vlq(0))
        payload.append(contentsOf: [0xFF, 0x2F, 0x00])
        var chunk: [UInt8] = [0x4D, 0x54, 0x72, 0x6B]
        chunk.append(contentsOf: be32(UInt32(payload.count)))
        chunk.append(contentsOf: payload)
        return chunk
    }
    let format: UInt16 = sequence.tracks.count > 1 ? 1 : 0
    var ntrks = UInt16(sequence.tracks.count)
    if !sequence.tempoTrack.events.isEmpty {
        ntrks += 1
    }
    var bytes: [UInt8] = [0x4D, 0x54, 0x68, 0x64]
    bytes.append(contentsOf: be32(6))
    bytes.append(contentsOf: be16(format))
    bytes.append(contentsOf: be16(max(ntrks, 1)))
    bytes.append(contentsOf: be16(ticksPerBeat))
    if !sequence.tempoTrack.events.isEmpty {
        bytes.append(contentsOf: encodeTrack(sequence.tempoTrack.events, extraTempo: true))
    }
    if sequence.tracks.isEmpty && sequence.tempoTrack.events.isEmpty {
        bytes.append(contentsOf: encodeTrack([], extraTempo: false))
    }
    for track in sequence.tracks {
        bytes.append(contentsOf: encodeTrack(track.events, extraTempo: false))
    }
    return bytes
}

