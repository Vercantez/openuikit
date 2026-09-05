import Foundation
#if canImport(AVFoundation)
import AVFoundation
#endif
#if canImport(CoreMedia)
import CoreMedia
#endif

/// Isolated-host audio format used when `AVFoundation` is not on the compiler
/// search path. Apple's `nativeAudioFormat` is `AVAudioFormat` at 16 kHz mono
/// linear PCM ([SFSpeechAudioBufferRecognitionRequest.nativeAudioFormat](https://developer.apple.com/documentation/speech/sfspeechaudiobufferrecognitionrequest/nativeaudioformat)).
public struct SpeechHostAudioFormat: Hashable, Sendable {
    public var sampleRate: Double
    public var channelCount: Int

    public init(sampleRate: Double, channelCount: Int) {
        self.sampleRate = sampleRate
        self.channelCount = channelCount
    }

    public static let speechNative = SpeechHostAudioFormat(sampleRate: 16_000, channelCount: 1)
}

/// Isolated-host PCM buffer. This is not `AVAudioPCMBuffer`; it exists so
/// `append` / `endAudio` semantics can be exercised without redeclaring
/// AVFoundation types.
public struct SpeechHostPCMBuffer: Sendable {
    public var frameLength: Int
    public var format: SpeechHostAudioFormat
    public var data: Data

    public init(
        frameLength: Int,
        format: SpeechHostAudioFormat = .speechNative,
        data: Data = Data()
    ) {
        self.frameLength = frameLength
        self.format = format
        self.data = data
    }
}

/// Isolated-host sample buffer. This is not `CMSampleBuffer`.
public struct SpeechHostSampleBuffer: Sendable {
    public var data: Data
    public var sampleRate: Double

    public init(data: Data, sampleRate: Double = 16_000) {
        self.data = data
        self.sampleRate = sampleRate
    }
}

/// Isolated-host time range used when `CoreMedia` is not on the compiler
/// search path. Apple's attribute value is `CMTimeRange`.
public struct SpeechHostTimeRange: Hashable, Codable, Sendable {
    public var start: TimeInterval
    public var duration: TimeInterval

    public init(start: TimeInterval, duration: TimeInterval) {
        self.start = start
        self.duration = duration
    }

    public var end: TimeInterval { start + duration }

    public func intersects(_ other: SpeechHostTimeRange) -> Bool {
        start < other.end && other.start < end
    }
}

#if canImport(AVFoundation)
public typealias SpeechNativeAudioFormat = AVAudioFormat
#else
public typealias SpeechNativeAudioFormat = SpeechHostAudioFormat
#endif

#if canImport(AVFoundation)
public typealias SpeechPCMBuffer = AVAudioPCMBuffer
#else
public typealias SpeechPCMBuffer = SpeechHostPCMBuffer
#endif

#if canImport(CoreMedia)
public typealias SpeechSampleBuffer = CMSampleBuffer
#else
public typealias SpeechSampleBuffer = SpeechHostSampleBuffer
#endif

#if canImport(CoreMedia)
public typealias SpeechTimeRange = CMTimeRange
#else
public typealias SpeechTimeRange = SpeechHostTimeRange
#endif
