import Foundation

/// Spatial-audio sidecar for cinematic assets. Linux reports
/// `isSupported == false` and never claims Apple mix metadata.
public class CNAssetSpatialAudioInfo: @unchecked Sendable {
    public static var isSupported: Bool { false }

    public var defaultSpatialAudioTrack: AVAssetTrack { storedTrack }
    public var spatialAudioMixMetadata: Data { storedMetadata }
    public var defaultRenderingStyle: CNSpatialAudioRenderingStyle { storedStyle }
    public var defaultEffectIntensity: Float32 { storedIntensity }

    private let storedTrack: AVAssetTrack
    private let storedMetadata: Data
    private let storedStyle: CNSpatialAudioRenderingStyle
    private let storedIntensity: Float32

    init(
        track: AVAssetTrack,
        metadata: Data,
        style: CNSpatialAudioRenderingStyle,
        intensity: Float32
    ) {
        self.storedTrack = track
        self.storedMetadata = metadata
        self.storedStyle = style
        self.storedIntensity = intensity
    }

    public init(asset: AVAsset) async throws {
        throw CNCinematicError(.unsupported)
    }

    public class func assetContainsSpatialAudio(asset: AVAsset) async -> Bool {
        _ = asset
        return false
    }

    public class func checkIfContainsSpatialAudio(
        asset: AVAsset,
        completionHandler: @escaping (Bool) -> Void
    ) {
        _ = asset
        completionHandler(false)
    }

    /// Isolated-host placeholder. Metadata is empty; intensity `1` is a Linux
    /// identity default, not an Apple-observed cinematic mix.
    public static func host_makeUnparsed(asset: AVAsset) -> CNAssetSpatialAudioInfo {
        _ = asset
        return CNAssetSpatialAudioInfo(
            track: AVAssetTrack(trackID: 4, mediaType: "soun"),
            metadata: Data(),
            style: .cinematic,
            intensity: 1
        )
    }

    public func assetWriterInputSettings(
        for contentType: CNSpatialAudioContentType
    ) -> Dictionary<String, Any> {
        _ = contentType
        return [:]
    }

    public func assetReaderOutputSettings(
        for contentType: CNSpatialAudioContentType
    ) -> Dictionary<String, Any> {
        _ = contentType
        return [:]
    }

    public func audioMix(
        effectIntensity: Float32,
        renderingStyle: CNSpatialAudioRenderingStyle
    ) -> AVAudioMix {
        _ = effectIntensity
        _ = renderingStyle
        return AVAudioMix()
    }
}
