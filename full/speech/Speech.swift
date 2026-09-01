@_exported import Foundation

/// Portable Linux starting point for Apple's public `Speech` module.
///
/// Recognition, on-device models, microphone capture, and Apple speech-asset
/// downloads are fail-closed. Request objects, custom language-model *data*,
/// option/preset values, and analyzer wiring are real and deterministic.
enum SpeechPortable {
    static let defaultSampleRate: Double = 16_000
    static let defaultChannelCount: AVAudioChannelCount = 1

    static func defaultAudioFormat() -> AVAudioFormat {
        AVAudioFormat(sampleRate: defaultSampleRate, channelCount: defaultChannelCount)
    }

    static func failClosedError(
        _ code: SFSpeechError.Code,
        reason: String
    ) -> SFSpeechError {
        SFSpeechError(
            code,
            userInfo: [NSLocalizedDescriptionKey: reason]
        )
    }
}

/// Process-wide model-retention control. Linux never loads Apple speech
/// models, so ending retention is a no-op.
public enum SpeechModels: Sendable {
    public static func endRetention() async {}
}
