@_exported import Foundation

#if canImport(AVFAudio)
import AVFAudio
#endif
#if canImport(ModelIO)
import ModelIO
#endif
#if canImport(CoreAudio)
import CoreAudio
#endif

/// Linux starting implementation of Apple's public `PHASE` module.
///
/// Enums, option sets, error codes, envelopes, object graphs, mixer/node
/// definitions, and in-process group/engine bookkeeping are real. Apple's
/// spatial-audio renderer, head tracker, audio decoder, and PHASE daemon are
/// absent: engine start, sound-event prepare/start, and sound-asset decode
/// fail closed with the documented `PHASEError` / `PHASESoundEventError` /
/// `PHASEAssetError` codes instead of inventing audible success.

/// Linux fallback spelling of the exported `PHASEErrorDomain` symbol.
/// The Apple CFString payload is unobserved; see `oracle-questions.tsv`.
public let PHASEErrorDomain = "PHASEErrorDomain"

/// Linux fallback spelling of the exported `PHASEAssetErrorDomain` symbol.
public let PHASEAssetErrorDomain = "PHASEAssetErrorDomain"

/// Linux fallback spelling of the exported `PHASESoundEventErrorDomain` symbol.
public let PHASESoundEventErrorDomain = "PHASESoundEventErrorDomain"

func phaseLinuxReason(_ detail: String) -> [String: Any] {
    [
        NSLocalizedDescriptionKey:
            "PHASE has no Apple spatial renderer, audio decoder, or daemon on this Linux host: \(detail)"
    ]
}

func phaseGeneratedIdentifier() -> String {
    UUID().uuidString
}

#if canImport(AVFAudio) && canImport(CoreAudio)
public typealias PHASEPullStreamRenderHandler = (
    UnsafeMutablePointer<ObjCBool>,
    UnsafePointer<AudioTimeStamp>,
    AVAudioFrameCount,
    UnsafeMutablePointer<AudioBufferList>
) -> OSStatus
#endif
