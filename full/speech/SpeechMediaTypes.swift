/// Speech-local stand-ins for CoreMedia / AVFoundation audio types.
///
/// The isolated host gate compiles `Speech` without linking those modules.
/// These types match the public Speech signatures so clients can construct
/// requests and inspect formats. They are not Apple media objects.

public typealias CMTimeValue = Int64
public typealias CMTimeScale = Int32
public typealias AVAudioChannelCount = UInt32
public typealias AVAudioFrameCount = UInt32

public struct CMTime: Hashable, Sendable, Comparable, Codable, CustomStringConvertible {
    public var value: CMTimeValue
    public var timescale: CMTimeScale

    public init(value: CMTimeValue, timescale: CMTimeScale) {
        self.value = value
        self.timescale = timescale
    }

    public init(seconds: Double, preferredTimescale: CMTimeScale) {
        if preferredTimescale <= 0 || seconds.isNaN {
            self.value = 0
            self.timescale = 0
            return
        }
        if seconds.isInfinite {
            self.value = seconds > 0 ? CMTimeValue.max : CMTimeValue.min
            self.timescale = preferredTimescale
            return
        }
        self.value = CMTimeValue((seconds * Double(preferredTimescale)).rounded())
        self.timescale = preferredTimescale
    }

    public static let zero = CMTime(value: 0, timescale: 1)
    public static let invalid = CMTime(value: 0, timescale: 0)

    public var isValid: Bool { timescale > 0 }
    public var isNumeric: Bool { isValid }

    public var seconds: Double {
        guard timescale > 0 else { return .nan }
        return Double(value) / Double(timescale)
    }

    public static func == (lhs: CMTime, rhs: CMTime) -> Bool {
        if !lhs.isValid && !rhs.isValid { return true }
        guard lhs.isValid, rhs.isValid else { return false }
        return lhs.seconds == rhs.seconds
    }

    public static func < (lhs: CMTime, rhs: CMTime) -> Bool {
        lhs.seconds < rhs.seconds
    }

    public var description: String {
        isValid ? "\(seconds)s" : "invalid"
    }
}

public struct CMTimeRange: Hashable, Sendable, Codable, CustomStringConvertible {
    public var start: CMTime
    public var duration: CMTime

    public init(start: CMTime, duration: CMTime) {
        self.start = start
        self.duration = duration
    }

    public static let zero = CMTimeRange(start: .zero, duration: .zero)
    public static let invalid = CMTimeRange(start: .invalid, duration: .invalid)

    public var isValid: Bool { start.isValid && duration.isValid }
    public var end: CMTime {
        guard isValid else { return .invalid }
        let scale = max(start.timescale, duration.timescale)
        return CMTime(seconds: start.seconds + duration.seconds, preferredTimescale: scale)
    }

    public func containsTime(_ time: CMTime) -> Bool {
        guard isValid, time.isValid else { return false }
        return time.seconds >= start.seconds && time.seconds < end.seconds
    }

    public func intersects(_ other: CMTimeRange) -> Bool {
        guard isValid, other.isValid else { return false }
        return start.seconds < other.end.seconds && other.start.seconds < end.seconds
    }

    public var description: String {
        isValid ? "[\(start.seconds)+\(duration.seconds)]" : "invalid"
    }
}

open class AVAudioFormat: NSObject, @unchecked Sendable {
    public let sampleRate: Double
    public let channelCount: AVAudioChannelCount

    public init(sampleRate: Double, channelCount: AVAudioChannelCount) {
        self.sampleRate = sampleRate
        self.channelCount = channelCount
        super.init()
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? AVAudioFormat else { return false }
        return sampleRate == other.sampleRate && channelCount == other.channelCount
    }
}

open class AVAudioPCMBuffer: NSObject, @unchecked Sendable {
    public let format: AVAudioFormat
    public let frameCapacity: AVAudioFrameCount
    public var frameLength: AVAudioFrameCount

    public init(pcmFormat format: AVAudioFormat, frameCapacity: AVAudioFrameCount) {
        self.format = format
        self.frameCapacity = frameCapacity
        self.frameLength = 0
        super.init()
    }
}

open class AVAudioFile: NSObject, @unchecked Sendable {
    public let url: URL
    public let fileFormat: AVAudioFormat

    public init(forReading url: URL) {
        self.url = url
        self.fileFormat = SpeechPortable.defaultAudioFormat()
        super.init()
    }

    public init(url: URL, fileFormat: AVAudioFormat) {
        self.url = url
        self.fileFormat = fileFormat
        super.init()
    }
}

/// Opaque sample-buffer token. Linux Speech does not decode Core Media samples.
open class CMSampleBuffer: NSObject, @unchecked Sendable {
    public override init() {
        super.init()
    }
}
