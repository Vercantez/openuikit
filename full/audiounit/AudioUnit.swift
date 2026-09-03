#if canImport(AudioToolbox)
@_exported import AudioToolbox
#endif
#if canImport(CoreAudio)
@_exported import CoreAudio
#endif
#if canImport(CoreAudioTypes)
@_exported import CoreAudioTypes
#endif

/// Linux starting point for Apple's `AudioUnit` compatibility module.
///
/// On iPhoneOS, `AudioUnit.framework` is a thin header re-export of
/// AudioToolbox's Audio Unit C/Objective-C API. The pinned iPhoneOS 26.1 Swift
/// graph records one unique public identifier for this module: the imported C
/// macro `AUDIO_UNIT_VERSION`.
///
/// C host APIs used by the roadmap corpus (`AudioUnitSetParameter`,
/// `AudioComponentDescription`, `kAudioUnitType_*`, and related constants) are
/// owned by AudioToolbox / CoreAudioTypes. This module does not ship lookalike
/// substitutes. When those dependencies are present on the compile path, they
/// are re-exported; otherwise they stay omitted so the isolated gate remains
/// honest.

/// Imported C macro `AUDIO_UNIT_VERSION`, surfaced by the Swift overlay as
/// `var AUDIO_UNIT_VERSION: Int32 { get }`.
///
/// Public header translations of modern AudioToolbox/AudioUnit headers define
/// this as `1070`. Open-source clients treat `AUDIO_UNIT_VERSION < 1060` as the
/// Component Manager-era ABI and `>= 1060` as the Audio Component ABI. The
/// exact iPhoneOS 26.1 integer is queued as an oracle question; this port uses
/// the publicly observed modern value rather than inventing a Linux-only one.
public var AUDIO_UNIT_VERSION: Int32 {
    1070
}
