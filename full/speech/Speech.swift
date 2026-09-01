@_exported import Foundation
@_exported import CoreMedia
@_exported import AVFoundation

/// Portable Linux starting point for Apple's public `Speech` module.
///
/// Recognition, on-device models, microphone capture, and Apple speech-asset
/// downloads are fail-closed. Request objects, custom language-model *data*,
/// option/preset values, and analyzer wiring are real and deterministic.
///
/// Audio and time types are imported from AVFoundation and CoreMedia so they
/// keep those modules' nominal identity. Isolated builds must stage those
/// modules; the EC2 integrated run builds the real guest dylibs.
enum SpeechPortable {
    static let defaultSampleRate: Double = 16_000
    static let defaultChannelCount: AVAudioChannelCount = 1

    static func defaultAudioFormat() -> AVAudioFormat {
        AVAudioFormat(
            standardFormatWithSampleRate: defaultSampleRate,
            channels: defaultChannelCount
        )
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

    static func failClosedService() -> SFSpeechError {
        failClosedError(
            .internalServiceError,
            reason: "Speech recognition has no on-device or remote service on this host"
        )
    }
}

/// Process-wide model-retention control. Linux never loads Apple speech
/// models, so ending retention is a no-op.
public enum SpeechModels: Sendable {
    public static func endRetention() async {}
}
