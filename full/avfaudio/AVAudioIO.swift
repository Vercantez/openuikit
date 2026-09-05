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

public protocol AVAudioRecorderDelegate: NSObjectProtocol, Sendable {
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
    public var framePosition: AVAudioFramePosition = 0 {
        didSet {
            if framePosition < 0 { framePosition = 0 }
            if framePosition > length { framePosition = length }
        }
    }
    public private(set) var length: AVAudioFramePosition = 0
    public private(set) var isOpen = true
    private let writable: Bool
    private let kind: AVAudioContainerKind
    private var interleaved: Data
    private var flushed = false

    public override init() {
        self.url = URL(fileURLWithPath: "/dev/null")
        self.fileFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        self.processingFormat = self.fileFormat
        self.writable = false
        self.kind = .wav
        self.interleaved = Data()
        super.init()
        self.isOpen = false
    }

    public init(forReading fileURL: URL) throws {
        let data = try Data(contentsOf: fileURL)
        let parsed: AVAudioContainerPCM
        do {
            parsed = try avfaudioParseContainer(data)
        } catch {
            throw avfaudioHostUnavailableError(
                "Audio file is not a supported WAV, CAF, or AIFF PCM container."
            )
        }
        self.url = fileURL
        self.fileFormat = parsed.format
        self.processingFormat = AVAudioFormat(
            standardFormatWithSampleRate: parsed.format.sampleRate,
            channels: parsed.format.channelCount
        ) ?? parsed.format
        self.writable = false
        self.kind = avfaudioContainerKind(url: fileURL, settings: [:])
        self.interleaved = parsed.interleaved
        super.init()
        self.length = parsed.frames
    }

    public init(
        forReading fileURL: URL,
        commonFormat format: AVAudioCommonFormat,
        interleaved: Bool
    ) throws {
        let data = try Data(contentsOf: fileURL)
        let parsed: AVAudioContainerPCM
        do {
            parsed = try avfaudioParseContainer(data)
        } catch {
            throw avfaudioHostUnavailableError(
                "Audio file is not a supported WAV, CAF, or AIFF PCM container."
            )
        }
        guard
            let processing = AVAudioFormat(
                commonFormat: format,
                sampleRate: parsed.format.sampleRate,
                channels: parsed.format.channelCount,
                interleaved: interleaved
            )
        else {
            throw avfaudioHostUnavailableError(
                "No Apple audio codec is installed; compressed encode/decode is fail-closed."
            )
        }
        self.url = fileURL
        self.fileFormat = parsed.format
        self.processingFormat = processing
        self.writable = false
        self.kind = avfaudioContainerKind(url: fileURL, settings: [:])
        self.interleaved = parsed.interleaved
        super.init()
        self.length = parsed.frames
    }

    public init(forWriting fileURL: URL, settings: [String: Any]) throws {
        guard let format = AVAudioFormat(settings: settings), format.commonFormat != .otherFormat else {
            throw avfaudioHostUnavailableError(
                "No Apple audio codec is installed; compressed encode/decode is fail-closed."
            )
        }
        self.url = fileURL
        self.fileFormat = format
        self.processingFormat = AVAudioFormat(
            standardFormatWithSampleRate: format.sampleRate,
            channels: format.channelCount
        ) ?? format
        self.writable = true
        self.kind = avfaudioContainerKind(url: fileURL, settings: settings)
        self.interleaved = Data()
        super.init()
        try avfaudioEncodeContainer(
            AVAudioContainerPCM(format: format, interleaved: Data(), frames: 0),
            kind: kind
        ).write(to: fileURL)
    }

    public init(
        forWriting fileURL: URL,
        settings: [String: Any],
        commonFormat format: AVAudioCommonFormat,
        interleaved: Bool
    ) throws {
        let channels = (settings[AVNumberOfChannelsKey] as? NSNumber)?.uint32Value
            ?? (settings[AVNumberOfChannelsKey] as? AVAudioChannelCount)
            ?? 2
        let rate = (settings[AVSampleRateKey] as? NSNumber)?.doubleValue
            ?? (settings[AVSampleRateKey] as? Double)
            ?? 44100
        guard
            let file = AVAudioFormat(settings: settings), file.commonFormat != .otherFormat,
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
        self.url = fileURL
        self.fileFormat = file
        self.processingFormat = processing
        self.writable = true
        self.kind = avfaudioContainerKind(url: fileURL, settings: settings)
        self.interleaved = Data()
        super.init()
        try avfaudioEncodeContainer(
            AVAudioContainerPCM(format: file, interleaved: Data(), frames: 0),
            kind: kind
        ).write(to: fileURL)
    }

    deinit {
        if writable, isOpen, !flushed {
            try? flush()
        }
    }

    public func close() {
        if writable, isOpen {
            try? flush()
        }
        isOpen = false
    }

    public func read(into buffer: AVAudioPCMBuffer) throws {
        try read(into: buffer, frameCount: buffer.frameCapacity)
    }

    public func read(into buffer: AVAudioPCMBuffer, frameCount frames: AVAudioFrameCount) throws {
        guard isOpen, !writable else {
            throw avfaudioHostUnavailableError("AVAudioFile is not open for reading.")
        }
        let remaining = max(length - framePosition, 0)
        let want = min(Int(frames), Int(remaining), Int(buffer.frameCapacity))
        guard
            let fileBuffer = AVAudioPCMBuffer(
                pcmFormat: fileFormat,
                frameCapacity: AVAudioFrameCount(max(want, 1))
            )
        else {
            throw avfaudioHostUnavailableError("Unable to allocate a file-format PCM buffer.")
        }
        let copied = avfaudioFillPCMBuffer(
            fileBuffer,
            fromInterleaved: interleaved,
            format: fileFormat,
            startFrame: Int(framePosition),
            frameCount: want
        )
        fileBuffer.frameLength = copied
        if copied == 0 {
            buffer.frameLength = 0
            return
        }
        if buffer.format.commonFormat == fileBuffer.format.commonFormat
            && buffer.format.sampleRate == fileBuffer.format.sampleRate
            && buffer.format.channelCount == fileBuffer.format.channelCount
        {
            _ = avfaudioConvertPCM(from: fileBuffer, to: buffer, channelMap: [], downmix: false)
        } else {
            _ = avfaudioConvertPCM(from: fileBuffer, to: buffer, channelMap: [], downmix: false)
        }
        framePosition += AVAudioFramePosition(copied)
    }

    public func write(from buffer: AVAudioPCMBuffer) throws {
        guard isOpen, writable else {
            throw avfaudioHostUnavailableError("AVAudioFile is not open for writing.")
        }
        guard
            let fileBuffer = AVAudioPCMBuffer(
                pcmFormat: fileFormat,
                frameCapacity: max(buffer.frameLength, 1)
            )
        else {
            throw avfaudioHostUnavailableError("Unable to allocate a file-format PCM buffer.")
        }
        _ = avfaudioConvertPCM(from: buffer, to: fileBuffer, channelMap: [], downmix: false)
        let chunk = avfaudioPCMBufferToInterleaved(fileBuffer)
        let frameSize = max(fileFormat.bytesPerSample * Int(fileFormat.channelCount), 1)
        let start = Int(framePosition) * frameSize
        if start > interleaved.count {
            interleaved.append(Data(count: start - interleaved.count))
        }
        if start == interleaved.count {
            interleaved.append(chunk)
        } else {
            let end = start + chunk.count
            if end > interleaved.count {
                interleaved.append(Data(count: end - interleaved.count))
            }
            interleaved.replaceSubrange(start..<end, with: chunk)
        }
        let next = framePosition + AVAudioFramePosition(fileBuffer.frameLength)
        length = max(length, next)
        framePosition = next
        try flush()
    }

    private func flush() throws {
        let encoded = try avfaudioEncodeContainer(
            AVAudioContainerPCM(format: fileFormat, interleaved: interleaved, frames: length),
            kind: kind
        )
        try encoded.write(to: url)
        flushed = true
    }
}

public final class AVAudioPlayer: NSObject {
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

    public convenience init(contentsOf url: URL) throws {
        try self.init(contentsOf: url, fileTypeHint: nil)
    }

    public convenience init(contentsOfURL url: URL) throws {
        try self.init(contentsOf: url)
    }

    public convenience init(contentsOf url: URL, fileTypeHint utiString: String?) throws {
        let data = try Data(contentsOf: url)
        try self.init(waveData: data, url: url, fileTypeHint: utiString)
    }

    public convenience init(contentsOfURL url: URL, fileTypeHint utiString: String?) throws {
        try self.init(contentsOf: url, fileTypeHint: utiString)
    }

    public convenience init(data: Data) throws {
        try self.init(data: data, fileTypeHint: nil)
    }

    public convenience init(data: Data, fileTypeHint utiString: String?) throws {
        try self.init(waveData: data, url: nil, fileTypeHint: utiString)
    }

    private init(waveData data: Data, url: URL?, fileTypeHint: String?) throws {
        _ = fileTypeHint
        guard !data.isEmpty else {
            throw avfaudioHostUnavailableError("AVAudioPlayer refuses empty audio data.")
        }
        guard let parsed = avfaudioParseLinearPCMWAVE(data) else {
            throw avfaudioHostUnavailableError(
                "AVAudioPlayer has no decoder for this payload; only 16-bit linear PCM WAVE is accepted."
            )
        }
        guard
            let format = AVAudioFormat(
                commonFormat: .pcmFormatInt16,
                sampleRate: parsed.sampleRate,
                channels: parsed.channels,
                interleaved: true
            )
        else {
            throw avfaudioHostUnavailableError("WAVE format is not representable as AVAudioFormat.")
        }
        self.url = url
        self.data = data
        self.format = format
        self.settings = format.settings
        self.numberOfChannels = Int(format.channelCount)
        self.duration = parsed.duration
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
        guard inputFormat.commonFormat != .otherFormat,
              outputFormat.commonFormat != .otherFormat
        else {
            throw avfaudioHostUnavailableError(
                "AVAudioConverter refuses compressed codecs without an AudioToolbox host."
            )
        }
        guard inputBuffer.format.commonFormat == inputFormat.commonFormat,
              outputBuffer.format.commonFormat == outputFormat.commonFormat
        else {
            throw avfaudioHostUnavailableError(
                "AVAudioConverter buffer formats must match the converter formats."
            )
        }
        let map = channelMap.map { $0.intValue }
        _ = avfaudioConvertPCM(
            from: inputBuffer,
            to: outputBuffer,
            channelMap: map,
            downmix: downmix
        )
    }

    public func convert(
        to outputBuffer: AVAudioBuffer,
        error outError: UnsafeMutablePointer<NSError?>?,
        withInputFrom inputBlock: @escaping AVAudioConverterInputBlock
    ) -> AVAudioConverterOutputStatus {
        guard let pcmOut = outputBuffer as? AVAudioPCMBuffer else {
            outError?.pointee = avfaudioHostUnavailableError(
                "AVAudioConverter requires an AudioToolbox codec host for compressed buffers."
            )
            return .error
        }
        guard inputFormat.commonFormat != .otherFormat,
              outputFormat.commonFormat != .otherFormat
        else {
            outError?.pointee = avfaudioHostUnavailableError(
                "AVAudioConverter refuses compressed codecs without an AudioToolbox host."
            )
            return .error
        }
        var status = AVAudioConverterInputStatus.haveData
        guard let supplied = inputBlock(AVAudioPacketCount(pcmOut.frameCapacity), &status) else {
            pcmOut.frameLength = 0
            if status == .endOfStream {
                return .endOfStream
            }
            return .inputRanDry
        }
        guard let pcmIn = supplied as? AVAudioPCMBuffer else {
            outError?.pointee = avfaudioHostUnavailableError(
                "AVAudioConverter requires an AudioToolbox codec host for compressed buffers."
            )
            return .error
        }
        do {
            try convert(to: pcmOut, from: pcmIn)
            if status == .endOfStream {
                return .endOfStream
            }
            return .haveData
        } catch {
            outError?.pointee = error as NSError
            return .error
        }
    }
}

struct AVFAudioLinearPCMWAVE {
    var sampleRate: Double
    var channels: AVAudioChannelCount
    var duration: TimeInterval
}

func avfaudioParseLinearPCMWAVE(_ data: Data) -> AVFAudioLinearPCMWAVE? {
    guard data.count >= 44 else { return nil }
    func ascii(_ offset: Int) -> String {
        String(decoding: data[offset..<(offset + 4)], as: UTF8.self)
    }
    func u16(_ offset: Int) -> UInt16 {
        UInt16(data[offset]) | (UInt16(data[offset + 1]) << 8)
    }
    func u32(_ offset: Int) -> UInt32 {
        UInt32(data[offset])
            | (UInt32(data[offset + 1]) << 8)
            | (UInt32(data[offset + 2]) << 16)
            | (UInt32(data[offset + 3]) << 24)
    }
    guard ascii(0) == "RIFF", ascii(8) == "WAVE" else { return nil }

    var offset = 12
    var audioFormat: UInt16?
    var channels: UInt16?
    var sampleRate: UInt32?
    var bits: UInt16?
    var payloadBytes: Int?
    while offset + 8 <= data.count {
        let chunkID = ascii(offset)
        let chunkSize = Int(u32(offset + 4))
        let body = offset + 8
        guard chunkSize >= 0, body <= data.count else { return nil }
        let next = body + chunkSize + (chunkSize & 1)
        if chunkID == "fmt " {
            guard chunkSize >= 16, body + 16 <= data.count else { return nil }
            audioFormat = u16(body)
            channels = u16(body + 2)
            sampleRate = u32(body + 4)
            bits = u16(body + 14)
        } else if chunkID == "data" {
            guard body + chunkSize <= data.count else { return nil }
            payloadBytes = chunkSize
        }
        guard next > offset else { return nil }
        offset = next
    }

    guard
        audioFormat == 1,
        bits == 16,
        let channelCount = channels,
        channelCount == 1 || channelCount == 2,
        let rate = sampleRate,
        rate == 8000 || rate == 16000 || rate == 22050 || rate == 44100 || rate == 48000,
        let bytes = payloadBytes
    else {
        return nil
    }
    let frameSize = Int(channelCount) * 2
    guard frameSize > 0, bytes >= frameSize, bytes % frameSize == 0 else { return nil }
    let frames = bytes / frameSize
    return AVFAudioLinearPCMWAVE(
        sampleRate: Double(rate),
        channels: AVAudioChannelCount(channelCount),
        duration: TimeInterval(frames) / TimeInterval(rate)
    )
}
