@_exported import Foundation

/// Linux starting point for Apple's public `Cinematic` module (iOS 17+
/// cinematic video scripts, detections, and rendering). Isolated-host success
/// is not Apple cinematic-asset parsing, Metal rendering, object tracking, or
/// spatial-audio mix success.
///
/// Hardware, Apple video daemons, entitlements, and the Cinematic ML stack are
/// absent on Linux. Asset loaders throw `CNCinematicError.unsupported`. Metal
/// encode and object-tracker APIs fail closed. Value types, error codes,
/// detection-track queries, and in-memory `CNScript` editing are real.
public enum CinematicLinuxBoundary {
    /// Cinematic asset ingest requires AVFoundation cinematic tracks.
    public static let cinematicAssetParsingAvailable = false
    /// `CNRenderingSession.encodeRender` needs Metal shaders Apple has not
    /// published for Linux.
    public static let metalRenderingAvailable = false
    /// `CNObjectTracker` is an Apple ML tracker.
    public static let objectTrackerAvailable = false
    /// Spatial-audio mix metadata is an Apple cinematic-audio service.
    public static let spatialAudioMixAvailable = false
}
