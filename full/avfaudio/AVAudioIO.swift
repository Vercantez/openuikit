import Foundation

public protocol AVAudioPlayerDelegate: NSObjectProtocol {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool)
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: (any Error)?)
    func audioPlayerBeginInterruption(_ player: AVAudioPlayer)
    func audioPlayerEndInterruption(_ player: AVAudioPlayer, withOptions flags: Int)
}

extension AVAudioPlayerDelegate {
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {}
    public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: (any Error)?) {}
    public func audioPlayerBeginInterruption(_ player: AVAudioPlayer) {}
    public func audioPlayerEndInterruption(_ player: AVAudioPlayer, withOptions flags: Int) {}
}

public protocol AVAudioRecorderDelegate: NSObjectProtocol {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool)
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: (any Error)?)
    func audioRecorderBeginInterruption(_ recorder: AVAudioRecorder)
    func audioRecorderEndInterruption(_ recorder: AVAudioRecorder, withOptions flags: Int)
}

extension AVAudioRecorderDelegate {
    public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {}
    public func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: (any Error)?) {}
    public func audioRecorderBeginInterruption(_ recorder: AVAudioRecorder) {}
    public func audioRecorderEndInterruption(_ recorder: AVAudioRecorder, withOptions flags: Int) {}
}

public final class AVAudioFile: NSObject, @unchecked Sendable {
    public let url: URL
    public let fileFormat: AVAudioFormat
    public let processingFormat: AVAudioFormat
    public var framePosition: AVAudioFramePosition = 0
    public private(set) var length: AVAudioFramePosition = 0
    public private(set) var isOpen = true
    private let writable: Bool

    public override init() {
        self.url = URL(fileURLWithPath: "/dev/null")
        self.fileFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        self.processingFormat = self.fileFormat
        self.writable = false
        super.init()
        self.isOpen = false
    }

    public init(forReading fileURL: URL) throws {
        self.url = fileURL
        self.fileFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        self.processingFormat = self.fileFormat
        self.writable = false
        super.init()
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            throw avfaudioHostUnavailableError(
                "Audio file is missing and no Apple decoder is available."
            )
        }
        // Presence is recorded; compressed bytes are not decoded.
        length = 0
    }

    public init(
        forReading fileURL: URL,
        commonFormat format: AVAudioCommonFormat,
        interleaved: Bool
    ) throws {
        self.url = fileURL
        guard
            let processing = AVAudioFormat(
                commonFormat: format,
                sampleRate: 44100,
                channels: 2,
                interleaved: interleaved
            )
        else {
            throw avfaudioHostUnavailableError(
                "No Apple audio codec is installed; compressed encode/decode is fail-closed."
            )
        }
        self.fileFormat = processing
        self.processingFormat = processing
        self.writable = false
        super.init()
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            throw avfaudioHostUnavailableError(
                "Audio file is missing and no Apple decoder is available."
            )
        }
        length = 0
    }

    public init(forWriting fileURL: URL, settings: [String: Any]) throws {
        self.url = fileURL
        guard let format = AVAudioFormat(settings: settings) else {
            throw avfaudioHostUnavailableError(
                "No Apple audio codec is installed; compressed encode/decode is fail-closed."
            )
        }
        self.fileFormat = format
        self.processingFormat = format
        self.writable = true
        super.init()
    }

    public init(
        forWriting fileURL: URL,
        settings: [String: Any],
        commonFormat format: AVAudioCommonFormat,
        interleaved: Bool
    ) throws {
        self.url = fileURL
        let channels = (settings[AVNumberOfChannelsKey] as? NSNumber)?.uint32Value ?? 2
        let rate = (settings[AVSampleRateKey] as? NSNumber)?.doubleValue ?? 44100
        guard
            let processing = AVAudioFormat(
                commonFormat: format,
                sampleRate: rate,
                channels: channels,
                interleaved: interleaved
            )
        else {
            throw avfaudioHostUnavailableError(
                "No Apple audio codec is installed; compressed encode/decode is fail-closed."
            )
        }
        self.fileFormat = processing
        self.processingFormat = processing
        self.writable = true
        super.init()
    }

    public func close() {
        isOpen = false
    }

    public func read(into buffer: AVAudioPCMBuffer) throws {
        try read(into: buffer, frameCount: buffer.frameCapacity)
    }

    public func read(into buffer: AVAudioPCMBuffer, frameCount frames: AVAudioFrameCount) throws {
        guard isOpen, !writable else {
            throw avfaudioHostUnavailableError("No Apple audio decoder is available.")
        }
        buffer.frameLength = 0
        _ = frames
        throw avfaudioHostUnavailableError("No Apple audio decoder is available.")
    }

    public func write(from buffer: AVAudioPCMBuffer) throws {
        guard isOpen, writable else {
            throw avfaudioHostUnavailableError("No Apple audio encoder is available.")
        }
        _ = buffer
        throw avfaudioHostUnavailableError("No Apple audio encoder is available.")
    }
}

public final class AVAudioPlayer: NSObject, @unchecked Sendable {
    public private(set) var url: URL?
    public private(set) var data: Data?
    public let format: AVAudioFormat
    public let settings: [String: Any]
    public let numberOfChannels: Int
    public let duration: TimeInterval
    public var currentTime: TimeInterval = 0
    public var volume: Float = 1
    public var pan: Float = 0
    public var rate: Float = 1
    public var enableRate = false
    public var numberOfLoops = 0
    public var isMeteringEnabled = false
    public private(set) var isPlaying = false
    public var channelAssignments: [AVAudioSessionChannelDescription]?
    public weak var delegate: (any AVAudioPlayerDelegate)?
    public var deviceCurrentTime: TimeInterval {
        ProcessInfo.processInfo.systemUptime
    }

    public init(contentsOf url: URL) throws {
        self.url = url
        self.data = try? Data(contentsOf: url)
        self.format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        self.settings = self.format.settings
        self.numberOfChannels = Int(self.format.channelCount)
        self.duration = 0
        super.init()
    }

    public convenience init(contentsOfURL url: URL) throws {
        try self.init(contentsOf: url)
    }

    public init(contentsOf url: URL, fileTypeHint utiString: String?) throws {
        _ = utiString
        self.url = url
        self.data = try? Data(contentsOf: url)
        self.format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        self.settings = self.format.settings
        self.numberOfChannels = Int(self.format.channelCount)
        self.duration = 0
        super.init()
    }

    public convenience init(contentsOfURL url: URL, fileTypeHint utiString: String?) throws {
        try self.init(contentsOf: url, fileTypeHint: utiString)
    }

    public init(data: Data) throws {
        self.data = data
        self.format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        self.settings = self.format.settings
        self.numberOfChannels = Int(self.format.channelCount)
        self.duration = 0
        super.init()
    }

    public init(data: Data, fileTypeHint utiString: String?) throws {
        _ = utiString
        self.data = data
        self.format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        self.settings = self.format.settings
        self.numberOfChannels = Int(self.format.channelCount)
        self.duration = 0
        super.init()
    }

    public func prepareToPlay() -> Bool { false }

    public func play() -> Bool {
        // Hardware output is fail-closed: the player records intent but does not emit audio.
        isPlaying = false
        return false
    }

    public func play(atTime time: TimeInterval) -> Bool {
        currentTime = time
        return play()
    }

    public func pause() { isPlaying = false }
    public func stop() {
        isPlaying = false
        currentTime = 0
    }

    public func setVolume(_ volume: Float, fadeDuration duration: TimeInterval) {
        _ = duration
        self.volume = volume
    }

    public func updateMeters() {}
    public func averagePower(forChannel channelNumber: Int) -> Float {
        _ = channelNumber
        return -160
    }
    public func peakPower(forChannel channelNumber: Int) -> Float {
        _ = channelNumber
        return -160
    }
}

public final class AVAudioRecorder: NSObject, @unchecked Sendable {
    public let url: URL
    public let format: AVAudioFormat
    public let settings: [String: Any]
    public private(set) var isRecording = false
    public var isMeteringEnabled = false
    public var currentTime: TimeInterval { 0 }
    public var deviceCurrentTime: TimeInterval { ProcessInfo.processInfo.systemUptime }
    public var channelAssignments: [AVAudioSessionChannelDescription]?
    public weak var delegate: (any AVAudioRecorderDelegate)?

    public init(url: URL, format: AVAudioFormat) throws {
        self.url = url
        self.format = format
        self.settings = format.settings
        super.init()
    }

    public convenience init(URL url: URL, format: AVAudioFormat) throws {
        try self.init(url: url, format: format)
    }

    public init(url: URL, settings: [String: Any]) throws {
        guard let format = AVAudioFormat(settings: settings) else {
            throw avfaudioHostUnavailableError(
                "No Apple audio codec is installed; compressed encode/decode is fail-closed."
            )
        }
        self.url = url
        self.format = format
        self.settings = settings
        super.init()
    }

    public convenience init(URL url: URL, settings: [String: Any]) throws {
        try self.init(url: url, settings: settings)
    }

    public func prepareToRecord() -> Bool { false }

    public func record() -> Bool {
        isRecording = false
        return false
    }

    public func record(forDuration duration: TimeInterval) -> Bool {
        _ = duration
        return record()
    }

    public func record(atTime time: TimeInterval) -> Bool {
        _ = time
        return record()
    }

    public func record(atTime time: TimeInterval, forDuration duration: TimeInterval) -> Bool {
        _ = time
        _ = duration
        return record()
    }

    public func pause() { isRecording = false }
    public func stop() { isRecording = false }
    public func deleteRecording() -> Bool {
        try? FileManager.default.removeItem(at: url)
        return true
    }
    public func updateMeters() {}
    public func averagePower(forChannel channelNumber: Int) -> Float {
        _ = channelNumber
        return -160
    }
    public func peakPower(forChannel channelNumber: Int) -> Float {
        _ = channelNumber
        return -160
    }
}

public final class AVAudioConverter: NSObject, @unchecked Sendable {
    public let inputFormat: AVAudioFormat
    public let outputFormat: AVAudioFormat
    public var bitRate = 0
    public var bitRateStrategy: String?
    public var sampleRateConverterQuality = AVAudioQuality.max.rawValue
    public var sampleRateConverterAlgorithm: String?
    public var channelMap: [NSNumber] = []
    public var dither = false
    public var downmix = false
    public var primeMethod = AVAudioConverterPrimeMethod.normal
    public var primeInfo = AVAudioConverterPrimeInfo()
    public var magicCookie: Data?
    public var contentSource = AVAudioContentSource.unspecified
    public var dynamicRangeControlConfiguration = AVAudioDynamicRangeControlConfiguration.none
    public var audioSyncPacketFrequency = 0
    public var applicableEncodeBitRates: [NSNumber]? { nil }
    public var applicableEncodeSampleRates: [NSNumber]? { nil }
    public var availableEncodeBitRates: [NSNumber]? { nil }
    public var availableEncodeSampleRates: [NSNumber]? { nil }
    public var availableEncodeChannelLayoutTags: [NSNumber]? { nil }
    public var maximumOutputPacketSize: Int { 0 }

    public init?(from fromFormat: AVAudioFormat, to toFormat: AVAudioFormat) {
        self.inputFormat = fromFormat
        self.outputFormat = toFormat
        super.init()
    }

    public convenience init?(fromFormat: AVAudioFormat, toFormat: AVAudioFormat) {
        self.init(from: fromFormat, to: toFormat)
    }

    public func reset() {}

    public func convert(to outputBuffer: AVAudioPCMBuffer, from inputBuffer: AVAudioPCMBuffer) throws {
        _ = outputBuffer
        _ = inputBuffer
        throw avfaudioHostUnavailableError(
            "AVAudioConverter requires an AudioToolbox codec host."
        )
    }

    public func convert(
        to outputBuffer: AVAudioBuffer,
        error outError: UnsafeMutablePointer<NSError?>?,
        withInputFrom inputBlock: @escaping AVAudioConverterInputBlock
    ) -> AVAudioConverterOutputStatus {
        var status = AVAudioConverterInputStatus.noDataNow
        _ = inputBlock(0, &status)
        _ = outputBuffer
        outError?.pointee = avfaudioHostUnavailableError(
            "AVAudioConverter requires an AudioToolbox codec host."
        )
        return .error
    }
}
