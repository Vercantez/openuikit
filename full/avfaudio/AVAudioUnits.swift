import Foundation
#if canImport(AudioToolbox)
import AudioToolbox
#endif
#if canImport(CoreMIDI)
import CoreMIDI
#endif

open class AVAudioUnit: AVAudioNode {
    public var name: String { "AVAudioUnit" }
    public var manufacturerName: String { "" }
    public var version: Int { 0 }
    #if canImport(AudioToolbox)
    public var audioComponentDescription = AudioComponentDescription()
    public var audioUnit: AudioUnit? { nil }
    #endif

    public func loadPreset(at url: URL) throws {
        _ = url
        throw avfaudioHostUnavailableError("Audio unit presets require AudioToolbox hosting.")
    }

    #if canImport(AudioToolbox)
    public class func instantiate(
        with audioComponentDescription: AudioComponentDescription,
        options: AudioComponentInstantiationOptions = []
    ) async throws -> AVAudioUnit {
        _ = audioComponentDescription
        _ = options
        throw avfaudioHostUnavailableError("AUAudioUnit instantiation requires an AudioToolbox host.")
    }
    #endif
}

open class AVAudioUnitEffect: AVAudioUnit {
    public var bypass = false
    public override init() { super.init() }
    #if canImport(AudioToolbox)
    public init(audioComponentDescription: AudioComponentDescription) {
        super.init()
        self.audioComponentDescription = audioComponentDescription
    }
    #endif
}

open class AVAudioUnitTimeEffect: AVAudioUnit {
    public var bypass = false
    public override init() { super.init() }
    #if canImport(AudioToolbox)
    public init(audioComponentDescription: AudioComponentDescription) {
        super.init()
        self.audioComponentDescription = audioComponentDescription
    }
    #endif
}

open class AVAudioUnitGenerator: AVAudioUnit, AVAudioMixing {
    public var bypass = false
    public var volume: Float {
        get { storedVolume }
        set { storedVolume = newValue }
    }
    public var pan: Float {
        get { storedPan }
        set { storedPan = newValue }
    }
    public var renderingAlgorithm: AVAudio3DMixingRenderingAlgorithm = .auto
    public var sourceMode: AVAudio3DMixingSourceMode = .spatializeIfMono
    public var pointSourceInHeadMode: AVAudio3DMixingPointSourceInHeadMode = .mono
    public var rate: Float = 1
    public var reverbBlend: Float = 0
    public var obstruction: Float = 0
    public var occlusion: Float = 0
    public var position: AVAudio3DPoint = AVAudio3DPoint()
    public override init() { super.init() }
    #if canImport(AudioToolbox)
    public init(audioComponentDescription: AudioComponentDescription) {
        super.init()
        self.audioComponentDescription = audioComponentDescription
    }
    #endif
}

open class AVAudioUnitMIDIInstrument: AVAudioUnit {
    public override init() { super.init() }
    #if canImport(AudioToolbox)
    public init(audioComponentDescription: AudioComponentDescription) {
        super.init()
        self.audioComponentDescription = audioComponentDescription
    }
    #endif

    public func startNote(_ note: UInt8, withVelocity velocity: UInt8, onChannel channel: UInt8) {
        _ = (note, velocity, channel)
    }
    public func stopNote(_ note: UInt8, onChannel channel: UInt8) {
        _ = (note, channel)
    }
    public func sendController(_ controller: UInt8, withValue value: UInt8, onChannel channel: UInt8) {
        _ = (controller, value, channel)
    }
    public func sendPitchBend(_ pitchbend: UInt16, onChannel channel: UInt8) {
        _ = (pitchbend, channel)
    }
    public func sendPressure(_ pressure: UInt8, onChannel channel: UInt8) {
        _ = (pressure, channel)
    }
    public func sendPressure(forKey key: UInt8, withValue value: UInt8, onChannel channel: UInt8) {
        _ = (key, value, channel)
    }
    public func sendProgramChange(_ program: UInt8, onChannel channel: UInt8) {
        _ = (program, channel)
    }
    public func sendProgramChange(
        _ program: UInt8,
        bankMSB: UInt8,
        bankLSB: UInt8,
        onChannel channel: UInt8
    ) {
        _ = (program, bankMSB, bankLSB, channel)
    }
    public func sendMIDIEvent(_ event: UInt8, data1: UInt8) {
        _ = (event, data1)
    }
    public func sendMIDIEvent(_ event: UInt8, data1: UInt8, data2: UInt8) {
        _ = (event, data1, data2)
    }
    public func sendMIDISysExEvent(_ midiData: Data) {
        _ = midiData
    }
    #if canImport(CoreMIDI)
    public func send(_ eventList: UnsafePointer<MIDIEventList>) {
        _ = eventList
    }
    #endif
}

public final class AVAudioUnitDelay: AVAudioUnitEffect {
    public var delayTime: TimeInterval = 1
    public var feedback: Float = 50
    public var lowPassCutoff: Float = 15000
    public var wetDryMix: Float = 100
}

public final class AVAudioUnitDistortion: AVAudioUnitEffect {
    public var preGain: Float = -6
    public var wetDryMix: Float = 50
    public func loadFactoryPreset(_ preset: AVAudioUnitDistortionPreset) {
        _ = preset
    }
}

public final class AVAudioUnitEQFilterParameters: NSObject {
    public var filterType: AVAudioUnitEQFilterType = .parametric
    public var frequency: Float = 1000
    public var bandwidth: Float = 1
    public var gain: Float = 0
    public var bypass = false
}

public final class AVAudioUnitEQ: AVAudioUnitEffect {
    public var globalGain: Float = 0
    public private(set) var bands: [AVAudioUnitEQFilterParameters]
    public init(numberOfBands: Int) {
        self.bands = (0..<max(numberOfBands, 1)).map { _ in AVAudioUnitEQFilterParameters() }
        super.init()
    }
}

public final class AVAudioUnitReverb: AVAudioUnitEffect {
    public var wetDryMix: Float = 100
    public func loadFactoryPreset(_ preset: AVAudioUnitReverbPreset) {
        _ = preset
    }
}

public final class AVAudioUnitTimePitch: AVAudioUnitTimeEffect {
    public var rate: Float = 1
    public var pitch: Float = 0
    public var overlap: Float = 8
}

public final class AVAudioUnitVarispeed: AVAudioUnitTimeEffect {
    public var rate: Float = 1
}

public final class AVAudioUnitSampler: AVAudioUnitMIDIInstrument {
    public var masterGain: Float = 0
    public var globalTuning: Float = 0
    public var stereoPan: Float = 0
    public func loadSoundBankInstrument(
        at bankURL: URL,
        program: UInt8,
        bankMSB: UInt8,
        bankLSB: UInt8
    ) throws {
        _ = (bankURL, program, bankMSB, bankLSB)
        throw avfaudioHostUnavailableError("Sampler instruments require an AudioToolbox host.")
    }
    public func loadInstrument(at instrumentURL: URL) throws {
        _ = instrumentURL
        throw avfaudioHostUnavailableError("Sampler instruments require an AudioToolbox host.")
    }
    public func loadAudioFiles(at audioFiles: [URL]) throws {
        _ = audioFiles
        throw avfaudioHostUnavailableError("Sampler instruments require an AudioToolbox host.")
    }
}

public final class AVAudioUnitComponent: NSObject {
    public let name: String
    public let typeName: String
    public let localizedTypeName: String
    public let manufacturerName: String
    public let version: Int
    public let versionString: String
    public let allTagNames: [String]
    public let hasMIDIInput: Bool
    public let hasMIDIOutput: Bool
    public let passesAUVal: Bool
    public let isSandboxSafe: Bool
    public var configurationDictionary: [String: Any] { [:] }
    #if canImport(AudioToolbox)
    public let audioComponentDescription: AudioComponentDescription
    public var audioComponent: AudioComponent? { nil }
    #endif

    public init(name: String = "", typeName: String = "") {
        self.name = name
        self.typeName = typeName
        self.localizedTypeName = typeName
        self.manufacturerName = ""
        self.version = 0
        self.versionString = "0"
        self.allTagNames = []
        self.hasMIDIInput = false
        self.hasMIDIOutput = false
        self.passesAUVal = false
        self.isSandboxSafe = true
        #if canImport(AudioToolbox)
        self.audioComponentDescription = AudioComponentDescription()
        #endif
        super.init()
    }
}

public final class AVAudioUnitComponentManager: NSObject {
    public static let registrationsChangedNotification = NSNotification.Name(
        "AVAudioUnitComponentManagerRegistrationsChangedNotification"
    )
    private static let instance = AVAudioUnitComponentManager()
    public class func shared() -> AVAudioUnitComponentManager { instance }
    public var tagNames: [String] { [] }
    public var standardLocalizedTagNames: [String] { [] }

    #if canImport(AudioToolbox)
    public func components(matching desc: AudioComponentDescription) -> [AVAudioUnitComponent] {
        _ = desc
        return []
    }
    #endif
    public func components(matching predicate: NSPredicate) -> [AVAudioUnitComponent] {
        _ = predicate
        return []
    }
    public func components(
        passingTest testHandler: @escaping (AVAudioUnitComponent, UnsafeMutablePointer<ObjCBool>) -> Bool
    ) -> [AVAudioUnitComponent] {
        _ = testHandler
        return []
    }
}

open class AVMusicEvent: NSObject {}

public final class AVAUPresetEvent: AVMusicEvent {
    public var scope: UInt32
    public var element: UInt32
    public let presetDictionary: [AnyHashable: Any]
    public init(scope: UInt32, element: UInt32, dictionary presetDictionary: [AnyHashable: Any]) {
        self.scope = scope
        self.element = element
        self.presetDictionary = presetDictionary
        super.init()
    }
}

public final class AVExtendedNoteOnEvent: AVMusicEvent {
    public var midiNote: Float
    public var velocity: Float
    public var instrumentID: UInt32
    public var groupID: UInt32
    public var duration: AVMusicTimeStamp
    public init(
        midiNote: Float,
        velocity: Float,
        instrumentID: UInt32,
        groupID: UInt32,
        duration: AVMusicTimeStamp
    ) {
        self.midiNote = midiNote
        self.velocity = velocity
        self.instrumentID = instrumentID
        self.groupID = groupID
        self.duration = duration
        super.init()
    }
}

public final class AVExtendedTempoEvent: AVMusicEvent {
    public var tempo: Double
    public init(tempo: Double) {
        self.tempo = tempo
        super.init()
    }
}

open class AVMIDIChannelEvent: AVMusicEvent {
    public var channel: UInt32
    public init(channel: UInt32) {
        self.channel = channel
        super.init()
    }
}

public final class AVMIDIChannelPressureEvent: AVMIDIChannelEvent {
    public var pressure: UInt32
    public init(channel: UInt32, pressure: UInt32) {
        self.pressure = pressure
        super.init(channel: channel)
    }
}

public final class AVMIDIControlChangeEvent: AVMIDIChannelEvent {
    public enum MessageType: Int, Hashable, Sendable {
        case bankSelect = 0
        case modWheel = 1
        case breath = 2
        case foot = 4
        case portamentoTime = 5
        case dataEntry = 6
        case volume = 7
        case balance = 8
        case pan = 10
        case expression = 11
        case sustain = 64
        case portamento = 65
        case sostenuto = 66
        case soft = 67
        case legatoPedal = 68
        case hold2Pedal = 69
        case filterResonance = 71
        case releaseTime = 72
        case attackTime = 73
        case brightness = 74
        case decayTime = 75
        case vibratoRate = 76
        case vibratoDepth = 77
        case vibratoDelay = 78
        case reverbLevel = 91
        case chorusLevel = 93
        case RPN_LSB = 100
        case RPN_MSB = 101
        case allSoundOff = 120
        case resetAllControllers = 121
        case allNotesOff = 123
        case omniModeOff = 124
        case omniModeOn = 125
        case monoModeOn = 126
        case monoModeOff = 127
    }

    public let messageType: MessageType
    public let value: UInt32
    public init(channel: UInt32, messageType: MessageType, value: UInt32) {
        self.messageType = messageType
        self.value = value
        super.init(channel: channel)
    }
}

public final class AVMIDIMetaEvent: AVMusicEvent {
    public enum EventType: Int, Hashable, Sendable {
        case sequenceNumber = 0
        case text = 1
        case copyright = 2
        case trackName = 3
        case instrument = 4
        case lyric = 5
        case marker = 6
        case cuePoint = 7
        case midiChannel = 32
        case midiPort = 33
        case endOfTrack = 47
        case tempo = 81
        case smpteOffset = 84
        case timeSignature = 88
        case keySignature = 89
        case proprietaryEvent = 127
    }

    public let type: EventType
    public let data: Data
    public init(type: EventType, data: Data) {
        self.type = type
        self.data = data
        super.init()
    }
}

public final class AVMIDINoteEvent: AVMusicEvent {
    public var channel: UInt32
    public var key: UInt32
    public var velocity: UInt32
    public var duration: AVMusicTimeStamp
    public init(channel: UInt32, key keyNum: UInt32, velocity: UInt32, duration: AVMusicTimeStamp) {
        self.channel = channel
        self.key = keyNum
        self.velocity = velocity
        self.duration = duration
        super.init()
    }
}

public final class AVMIDIPitchBendEvent: AVMIDIChannelEvent {
    public var value: UInt32
    public init(channel: UInt32, value: UInt32) {
        self.value = value
        super.init(channel: channel)
    }
}

public final class AVMIDIPolyPressureEvent: AVMIDIChannelEvent {
    public var key: UInt32
    public var pressure: UInt32
    public init(channel: UInt32, key: UInt32, pressure: UInt32) {
        self.key = key
        self.pressure = pressure
        super.init(channel: channel)
    }
}

public final class AVMIDIProgramChangeEvent: AVMIDIChannelEvent {
    public var programNumber: UInt32
    public init(channel: UInt32, programNumber: UInt32) {
        self.programNumber = programNumber
        super.init(channel: channel)
    }
}

public final class AVMIDISysexEvent: AVMusicEvent {
    public let data: Data
    public var sizeInBytes: UInt32 { UInt32(data.count) }
    public init(data: Data) {
        self.data = data
        super.init()
    }
}

public final class AVMusicUserEvent: AVMusicEvent {
    public let data: Data
    public var sizeInBytes: UInt32 { UInt32(data.count) }
    public init(data: Data) {
        self.data = data
        super.init()
    }
}

public final class AVParameterEvent: AVMusicEvent {
    public var parameterID: UInt32
    public var scope: UInt32
    public var element: UInt32
    public var value: Float
    public init(parameterID: UInt32, scope: UInt32, element: UInt32, value: Float) {
        self.parameterID = parameterID
        self.scope = scope
        self.element = element
        self.value = value
        super.init()
    }
}

public final class AVMusicTrack: NSObject {
    public var destinationAudioUnit: AVAudioUnit?
    #if canImport(CoreMIDI)
    public var destinationMIDIEndpoint: MIDIEndpointRef?
    #endif
    public var lengthInBeats: AVMusicTimeStamp = 0
    public var lengthInSeconds: TimeInterval = 0
    public var loopRange = AVBeatRange()
    public var isLoopingEnabled = false
    public var isMuted = false
    public var isSoloed = false
    public var numberOfLoops = 0
    public var offsetTime: AVMusicTimeStamp = 0
    public var timeResolution: Int { 480 }
    public var usesAutomatedParameters = false
    private var events: [(AVMusicTimeStamp, AVMusicEvent)] = []

    public func addEvent(_ event: AVMusicEvent, at beat: AVMusicTimeStamp) {
        events.append((beat, event))
    }
    public func clearEvents(in range: AVBeatRange) {
        events.removeAll { $0.0 >= range.start && $0.0 < range.start + range.length }
    }
    public func cutEvents(in range: AVBeatRange) { clearEvents(in: range) }
    public func moveEvents(in range: AVBeatRange, by beatAmount: AVMusicTimeStamp) {
        events = events.map { stamp, event in
            if stamp >= range.start && stamp < range.start + range.length {
                return (stamp + beatAmount, event)
            }
            return (stamp, event)
        }
    }
    public func copyEvents(
        in range: AVBeatRange,
        from sourceTrack: AVMusicTrack,
        insertAt insertStartBeat: AVMusicTimeStamp
    ) {
        for (stamp, event) in sourceTrack.events
        where stamp >= range.start && stamp < range.start + range.length {
            addEvent(event, at: insertStartBeat + (stamp - range.start))
        }
    }
    public func copyAndMergeEvents(
        in range: AVBeatRange,
        from sourceTrack: AVMusicTrack,
        mergeAt mergeStartBeat: AVMusicTimeStamp
    ) {
        copyEvents(in: range, from: sourceTrack, insertAt: mergeStartBeat)
    }
    public func enumerateEvents(
        in range: AVBeatRange,
        using block: AVMusicEventEnumerationBlock
    ) {
        var stop = ObjCBool(false)
        for (stamp, event) in events
        where stamp >= range.start && stamp < range.start + range.length {
            var mutable = stamp
            block(event, &mutable, &stop)
            if stop.boolValue { break }
        }
    }
}

public final class AVAudioSequencer: NSObject {
    public struct InfoDictionaryKey: RawRepresentable, Hashable, Sendable {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public static let album = InfoDictionaryKey(rawValue: "album")
        public static let approximateDurationInSeconds = InfoDictionaryKey(rawValue: "approximateDurationInSeconds")
        public static let artist = InfoDictionaryKey(rawValue: "artist")
        public static let channelLayout = InfoDictionaryKey(rawValue: "channelLayout")
        public static let comments = InfoDictionaryKey(rawValue: "comments")
        public static let composer = InfoDictionaryKey(rawValue: "composer")
        public static let copyright = InfoDictionaryKey(rawValue: "copyright")
        public static let encodingApplication = InfoDictionaryKey(rawValue: "encodingApplication")
        public static let genre = InfoDictionaryKey(rawValue: "genre")
        public static let ISRC = InfoDictionaryKey(rawValue: "ISRC")
        public static let keySignature = InfoDictionaryKey(rawValue: "keySignature")
        public static let lyricist = InfoDictionaryKey(rawValue: "lyricist")
        public static let nominalBitRate = InfoDictionaryKey(rawValue: "nominalBitRate")
        public static let recordedDate = InfoDictionaryKey(rawValue: "recordedDate")
        public static let sourceBitDepth = InfoDictionaryKey(rawValue: "sourceBitDepth")
        public static let sourceEncoder = InfoDictionaryKey(rawValue: "sourceEncoder")
        public static let subTitle = InfoDictionaryKey(rawValue: "subTitle")
        public static let tempo = InfoDictionaryKey(rawValue: "tempo")
        public static let timeSignature = InfoDictionaryKey(rawValue: "timeSignature")
        public static let title = InfoDictionaryKey(rawValue: "title")
        public static let trackNumber = InfoDictionaryKey(rawValue: "trackNumber")
        public static let year = InfoDictionaryKey(rawValue: "year")
    }

    public private(set) var tracks: [AVMusicTrack] = []
    public let tempoTrack = AVMusicTrack()
    public var currentPositionInBeats: TimeInterval = 0
    public var currentPositionInSeconds: TimeInterval = 0
    public var rate: Float = 1
    public private(set) var isPlaying = false
    public var userInfo: [String: Any] { [:] }
    private weak var engine: AVAudioEngine?

    public override init() { super.init() }
    public init(audioEngine engine: AVAudioEngine) {
        self.engine = engine
        super.init()
    }

    public func createAndAppendTrack() -> AVMusicTrack {
        let track = AVMusicTrack()
        tracks.append(track)
        return track
    }
    public func removeTrack(_ track: AVMusicTrack) -> Bool {
        let before = tracks.count
        tracks.removeAll { $0 === track }
        return tracks.count < before
    }
    public func prepareToPlay() {}
    public func start() throws {
        throw avfaudioHostUnavailableError(
            "AVAudioSequencer.start requires an AudioToolbox MusicSequence host."
        )
    }
    public func stop() { isPlaying = false }
    public func reverseEvents() {}
    public func setUserCallback(_ userCallback: AVAudioSequencerUserCallback?) {
        _ = userCallback
    }
    public func load(from data: Data, options: AVMusicSequenceLoadOptions = []) throws {
        _ = data
        _ = options
        throw avfaudioHostUnavailableError("Sampler instruments require an AudioToolbox host.")
    }
    public func load(from fileURL: URL, options: AVMusicSequenceLoadOptions = []) throws {
        _ = fileURL
        _ = options
        throw avfaudioHostUnavailableError("Sampler instruments require an AudioToolbox host.")
    }
    public func write(to fileURL: URL, smpteResolution resolution: Int, replaceExisting replace: Bool) throws {
        _ = (fileURL, resolution, replace)
        throw avfaudioHostUnavailableError("Sampler instruments require an AudioToolbox host.")
    }
    public func data(
        withSMPTEResolution SMPTEResolution: Int,
        error outError: UnsafeMutablePointer<NSError?>?
    ) -> Data {
        _ = SMPTEResolution
        outError?.pointee = avfaudioHostUnavailableError(
            "MusicSequence export requires an AudioToolbox host."
        )
        return Data()
    }
    public func beats(forSeconds seconds: TimeInterval) -> AVMusicTimeStamp {
        _ = seconds
        return 0
    }
    public func seconds(forBeats beats: AVMusicTimeStamp) -> TimeInterval {
        _ = beats
        return 0
    }
    public func beats(
        forHostTime inHostTime: UInt64,
        error outError: UnsafeMutablePointer<NSError?>?
    ) -> AVMusicTimeStamp {
        _ = inHostTime
        outError?.pointee = avfaudioHostUnavailableError(
            "Host-time mapping requires an AudioToolbox MusicSequence tempo map."
        )
        return 0
    }
    public func hostTime(
        forBeats inBeats: AVMusicTimeStamp,
        error outError: UnsafeMutablePointer<NSError?>?
    ) -> UInt64 {
        _ = inBeats
        outError?.pointee = avfaudioHostUnavailableError(
            "Host-time mapping requires an AudioToolbox MusicSequence tempo map."
        )
        return 0
    }
}

public final class AVMIDIPlayer: NSObject {
    public var currentPosition: TimeInterval = 0
    public let duration: TimeInterval
    public var rate: Float = 1
    public private(set) var isPlaying = false

    public init(contentsOf inURL: URL, soundBankURL bankURL: URL?) throws {
        _ = inURL
        _ = bankURL
        throw avfaudioHostUnavailableError("AVMIDIPlayer requires an AudioToolbox/CoreMIDI host.")
    }
    public convenience init(contentsOfURL inURL: URL, soundBankURL bankURL: URL?) throws {
        try self.init(contentsOf: inURL, soundBankURL: bankURL)
    }
    public init(data: Data, soundBankURL bankURL: URL?) throws {
        _ = data
        _ = bankURL
        throw avfaudioHostUnavailableError("AVMIDIPlayer requires an AudioToolbox/CoreMIDI host.")
    }
    public func prepareToPlay() {}
    public func play(_ completionHandler: AVMIDIPlayerCompletionHandler? = nil) {
        isPlaying = false
        guard let completionHandler else { return }
        AVFAudioCallbackDelivery.deliverExactlyOnce {
            completionHandler()
        }
    }
    public func stop() { isPlaying = false }
}
