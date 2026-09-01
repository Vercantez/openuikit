import Foundation

// MARK: - Top-level enumerations (Int / UInt / OSStatus raw values from public iOS 26.1 surface)

public enum AVAudio3DMixingPointSourceInHeadMode: Int, Hashable, Sendable {
    case mono = 0
    case bypass = 1
}

public enum AVAudio3DMixingRenderingAlgorithm: Int, Hashable, Sendable {
    case equalPowerPanning = 0
    case sphericalHead = 1
    case HRTF = 2
    case soundField = 3
    case stereoPassThrough = 5
    case HRTFHQ = 6
    case auto = 7
}

public enum AVAudio3DMixingSourceMode: Int, Hashable, Sendable {
    case spatializeIfMono = 0
    case bypass = 1
    case pointSource = 2
    case ambienceBed = 3
}

public enum AVAudioCommonFormat: UInt, Hashable, Sendable {
    case otherFormat = 0
    case pcmFormatFloat32 = 1
    case pcmFormatFloat64 = 2
    case pcmFormatInt16 = 3
    case pcmFormatInt32 = 4
}

public enum AVAudioContentSource: Int, Hashable, Sendable {
    case unspecified = 0
    case reserved = 1
    case applePassthrough = 2
    case appleCapture_Traditional = 3
    case appleCapture_Spatial = 4
    case appleCapture_Spatial_Enhanced = 5
    case appleMusic_Traditional = 6
    case appleMusic_Spatial = 7
    case appleAV_Traditional_Offline = 8
    case appleAV_Traditional_Live = 9
    case appleAV_Spatial_Offline = 10
    case appleAV_Spatial_Live = 11
    case passthrough = 12
    case capture_Traditional = 13
    case capture_Spatial = 14
    case capture_Spatial_Enhanced = 15
    case music_Traditional = 16
    case music_Spatial = 17
    case av_Traditional_Offline = 18
    case av_Traditional_Live = 19
    case av_Spatial_Offline = 20
    case av_Spatial_Live = 21
}

public enum AVAudioConverterInputStatus: Int, Hashable, Sendable {
    case haveData = 0
    case noDataNow = 1
    case endOfStream = 2
}

public enum AVAudioConverterOutputStatus: Int, Hashable, Sendable {
    case haveData = 0
    case inputRanDry = 1
    case endOfStream = 2
    case error = 3
}

public enum AVAudioConverterPrimeMethod: Int, Hashable, Sendable {
    case pre = 0
    case normal = 1
    case none = 2
}

public enum AVAudioDynamicRangeControlConfiguration: Int, Hashable, Sendable {
    case none = 0
    case music = 1
    case speech = 2
    case movie = 3
    case capture = 4
}

public enum AVAudioEngineManualRenderingError: OSStatus, Error, Hashable, Sendable {
    case invalidMode = -80800
    case initialized = -80801
    case notRunning = -80802
}

public enum AVAudioEngineManualRenderingMode: Int, Hashable, Sendable {
    case offline = 0
    case realtime = 1
}

public enum AVAudioEngineManualRenderingStatus: Int, Hashable, Sendable {
    case error = -1
    case success = 0
    case insufficientDataFromInputNode = 1
    case cannotDoInCurrentContext = 2
}

public enum AVAudioEnvironmentDistanceAttenuationModel: Int, Hashable, Sendable {
    case exponential = 1
    case inverse = 2
    case linear = 3
}

public enum AVAudioEnvironmentOutputType: Int, Hashable, Sendable {
    case auto = 0
    case headphones = 1
    case builtInSpeakers = 2
    case externalSpeakers = 3
}

public enum AVAudioPlayerNodeCompletionCallbackType: Int, Hashable, Sendable {
    case dataConsumed = 0
    case dataRendered = 1
    case dataPlayedBack = 2
}

public enum AVAudioQuality: Int, Hashable, Sendable {
    case min = 0
    case low = 0x20
    case medium = 0x40
    case high = 0x60
    case max = 0x7F
}

public enum AVAudioUnitDistortionPreset: Int, Hashable, Sendable {
    case drumsBitBrush = 0
    case drumsBufferBeats = 1
    case drumsLoFi = 2
    case multiBrokenSpeaker = 3
    case multiCellphoneConcert = 4
    case multiDecimated1 = 5
    case multiDecimated2 = 6
    case multiDecimated3 = 7
    case multiDecimated4 = 8
    case multiDistortedFunk = 9
    case multiDistortedCubed = 10
    case multiDistortedSquared = 11
    case multiEcho1 = 12
    case multiEcho2 = 13
    case multiEchoTight1 = 14
    case multiEchoTight2 = 15
    case multiEverythingIsBroken = 16
    case speechAlienChatter = 17
    case speechCosmicInterference = 18
    case speechGoldenPi = 19
    case speechRadioTower = 20
    case speechWaves = 21
}

public enum AVAudioUnitEQFilterType: Int, Hashable, Sendable {
    case parametric = 0
    case lowPass = 1
    case highPass = 2
    case lowShelf = 3
    case highShelf = 4
    case bandPass = 5
    case bandStop = 6
    case resonantLowPass = 7
    case resonantHighPass = 8
    case resonantLowShelf = 9
    case resonantHighShelf = 10
}

public enum AVAudioUnitReverbPreset: Int, Hashable, Sendable {
    case smallRoom = 0
    case mediumRoom = 1
    case largeRoom = 2
    case mediumHall = 3
    case largeHall = 4
    case plate = 5
    case mediumChamber = 6
    case largeChamber = 7
    case cathedral = 8
    case largeRoom2 = 9
    case mediumHall2 = 10
    case mediumHall3 = 11
    case largeHall2 = 12
}

public enum AVAudioVoiceProcessingSpeechActivityEvent: Int, Hashable, Sendable {
    case started = 0
    case ended = 1
}

public enum AVMusicTrackLoopCount: Int, Hashable, Sendable {
    case forever = -1
}

public enum AVSpeechBoundary: Int, Hashable, Sendable {
    case immediate = 0
    case word = 1
}

public enum AVSpeechSynthesisVoiceGender: Int, Hashable, Sendable {
    case unspecified = 0
    case male = 1
    case female = 2
}

public enum AVSpeechSynthesisVoiceQuality: Int, Hashable, Sendable {
    case `default` = 1
    case enhanced = 2
    case premium = 3
}

public struct AVAudioPlayerNodeBufferOptions: OptionSet, Hashable, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let loops = AVAudioPlayerNodeBufferOptions(rawValue: 1 << 0)
    public static let interrupts = AVAudioPlayerNodeBufferOptions(rawValue: 1 << 1)
    public static let interruptsAtLoop = AVAudioPlayerNodeBufferOptions(rawValue: 1 << 2)
}

public struct AVAudioSessionActivationOptions: OptionSet, Hashable, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
}

public struct AVMusicSequenceLoadOptions: OptionSet, Hashable, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let smf_ChannelsToTracks = AVMusicSequenceLoadOptions(rawValue: 1 << 0)
}

public struct AVAudioConverterPrimeInfo: Hashable, Sendable {
    public var leadingFrames: AVAudioFrameCount
    public var trailingFrames: AVAudioFrameCount
    public init() {
        self.leadingFrames = 0
        self.trailingFrames = 0
    }
    public init(leadingFrames: AVAudioFrameCount, trailingFrames: AVAudioFrameCount) {
        self.leadingFrames = leadingFrames
        self.trailingFrames = trailingFrames
    }
}

public struct AVAudioVoiceProcessingOtherAudioDuckingConfiguration: Sendable {
    public enum Level: Int, Hashable, Sendable {
        case `default` = 0
        case min = 1
        case mid = 2
        case max = 3
    }
    public var enableAdvancedDucking: ObjCBool
    public var duckingLevel: Level
    public init() {
        self.enableAdvancedDucking = false
        self.duckingLevel = .default
    }
    public init(enableAdvancedDucking: ObjCBool, duckingLevel: Level) {
        self.enableAdvancedDucking = enableAdvancedDucking
        self.duckingLevel = duckingLevel
    }
}
