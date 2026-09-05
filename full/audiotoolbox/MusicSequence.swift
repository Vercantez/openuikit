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
#endif
