@_exported import CoreMedia
@_exported import Foundation

/// Isolated-only AVFoundation audio surface used when the real guest
/// AVFoundation module is not on the compiler search path.
///
/// These types live in module `AVFoundation`, never in `Speech`. They exist
/// so Speech can import AVFoundation with the correct nominal identity.
/// The EC2 integrated run must build the real guest AVFoundation instead.

public typealias AVAudioChannelCount = UInt32
public typealias AVAudioFrameCount = UInt32

open class AVAudioFormat: NSObject, @unchecked Sendable {
    public let sampleRate: Double
    public let channelCount: AVAudioChannelCount

    public init(standardFormatWithSampleRate sampleRate: Double, channels: AVAudioChannelCount) {
        self.sampleRate = sampleRate
        self.channelCount = channels
        super.init()
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? AVAudioFormat else { return false }
        return sampleRate == other.sampleRate && channelCount == other.channelCount
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(sampleRate)
        hasher.combine(channelCount)
        return hasher.finalize()
    }
}

open class AVAudioPCMBuffer: NSObject, @unchecked Sendable {
    public let format: AVAudioFormat
    public let frameCapacity: AVAudioFrameCount
    public var frameLength: AVAudioFrameCount

    public init?(pcmFormat format: AVAudioFormat, frameCapacity: AVAudioFrameCount) {
        self.format = format
        self.frameCapacity = frameCapacity
        self.frameLength = 0
        super.init()
    }
}

open class AVAudioFile: NSObject, @unchecked Sendable {
    public let url: URL
    public let processingFormat: AVAudioFormat

    public init(forReading url: URL) throws {
        self.url = url
        self.processingFormat = AVAudioFormat(
            standardFormatWithSampleRate: 16_000,
            channels: 1
        )
        super.init()
    }
}
