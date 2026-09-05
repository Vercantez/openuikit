@_exported import Foundation

/// Linux starting implementation of Apple's public `ShazamKit` module.
///
/// This host has no Shazam matching service, microphone capture, Apple Music
/// catalog, or media-library daemon. Value types, custom-catalog bookkeeping,
/// and fail-closed error codes are real. Audio ingest, Apple catalog matches,
/// remote `SHMediaItem` fetch, and library sync never invent success.
///
/// `AVAudioPCMBuffer`, `AVAudioTime`, `AVAsset`, `Song`, and `UTType` live in
/// other modules that this seed does not depend on. Those symbols stay
/// deferred until a future integration build imports the real modules.
public enum ShazamKitModuleInfo {
    public static let linuxStartingPoint = true
}
