import Foundation

/// Cinematic track layout parsed from an `AVAsset`. Linux cannot parse Apple
/// cinematic sample data; `init(asset:)` throws `.unsupported`. Isolated-host
/// construction stores caller-provided placeholders and never claims a
/// successful cinematic parse.
public class CNAssetInfo: @unchecked Sendable {
    public let asset: AVAsset
    public var allCinematicTracks: [AVAssetTrack] { storedAllTracks }
    public var cinematicVideoTrack: AVAssetTrack { storedVideo }
    public var cinematicDisparityTrack: AVAssetTrack { storedDisparity }
    public var cinematicMetadataTrack: AVAssetTrack { storedMetadata }
    public var frameTimingTrack: AVAssetTrack { storedTiming }
    public var timeRange: CMTimeRange { storedTimeRange }
    public var naturalSize: CGSize { storedNaturalSize }
    public var preferredSize: CGSize { storedPreferredSize }
    public var preferredTransform: CGAffineTransform { storedTransform }
    public var videoCompositionTracks: [AVAssetTrack] { storedCompositionTracks }
    public var videoCompositionTrackIDs: [CMPersistentTrackID] { storedCompositionIDs }
    public var sampleDataTrackIDs: [CMPersistentTrackID] { storedSampleIDs }

    private let storedAllTracks: [AVAssetTrack]
    private let storedVideo: AVAssetTrack
    private let storedDisparity: AVAssetTrack
    private let storedMetadata: AVAssetTrack
    private let storedTiming: AVAssetTrack
    private let storedTimeRange: CMTimeRange
    private let storedNaturalSize: CGSize
    private let storedPreferredSize: CGSize
    private let storedTransform: CGAffineTransform
    private let storedCompositionTracks: [AVAssetTrack]
    private let storedCompositionIDs: [CMPersistentTrackID]
    private let storedSampleIDs: [CMPersistentTrackID]

    init(
        asset: AVAsset,
        allCinematicTracks: [AVAssetTrack],
        cinematicVideoTrack: AVAssetTrack,
        cinematicDisparityTrack: AVAssetTrack,
        cinematicMetadataTrack: AVAssetTrack,
        frameTimingTrack: AVAssetTrack,
        timeRange: CMTimeRange,
        naturalSize: CGSize,
        preferredSize: CGSize,
        preferredTransform: CGAffineTransform,
        videoCompositionTracks: [AVAssetTrack],
        videoCompositionTrackIDs: [CMPersistentTrackID],
        sampleDataTrackIDs: [CMPersistentTrackID]
    ) {
        self.asset = asset
        self.storedAllTracks = allCinematicTracks
        self.storedVideo = cinematicVideoTrack
        self.storedDisparity = cinematicDisparityTrack
        self.storedMetadata = cinematicMetadataTrack
        self.storedTiming = frameTimingTrack
        self.storedTimeRange = timeRange
        self.storedNaturalSize = naturalSize
        self.storedPreferredSize = preferredSize
        self.storedTransform = preferredTransform
        self.storedCompositionTracks = videoCompositionTracks
        self.storedCompositionIDs = videoCompositionTrackIDs
        self.storedSampleIDs = sampleDataTrackIDs
    }

    public init(asset: AVAsset) async throws {
        throw CNCinematicError(.unsupported)
    }

    public class func isCinematic(asset: AVAsset) async -> Bool {
        _ = asset
        return false
    }

    /// Isolated-host placeholder. Properties are zeros/empty tracks, not a
    /// parsed cinematic movie.
    public static func host_makeUnparsed(asset: AVAsset) -> CNAssetInfo {
        let video = AVAssetTrack(trackID: 1, mediaType: "vide")
        let disparity = AVAssetTrack(trackID: 2, mediaType: "auxv")
        let metadata = AVAssetTrack(trackID: 3, mediaType: "meta")
        return CNAssetInfo(
            asset: asset,
            allCinematicTracks: [video, disparity, metadata],
            cinematicVideoTrack: video,
            cinematicDisparityTrack: disparity,
            cinematicMetadataTrack: metadata,
            frameTimingTrack: video,
            timeRange: .zero,
            naturalSize: .zero,
            preferredSize: .zero,
            preferredTransform: .identity,
            videoCompositionTracks: [video],
            videoCompositionTrackIDs: [1],
            sampleDataTrackIDs: [2]
        )
    }
}

/// Composition-side cinematic track set. Inserting Apple cinematic time
/// ranges requires AVFoundation composition plumbing that Linux does not have.
public class CNCompositionInfo: CNAssetInfo, @unchecked Sendable {
    public func insertTimeRange(
        _ timeRange: CMTimeRange,
        of cinematicAssetInfo: CNAssetInfo,
        at startTime: CMTime
    ) throws {
        _ = timeRange
        _ = cinematicAssetInfo
        _ = startTime
        throw CNCinematicError(.unsupported)
    }
}

extension AVMutableComposition {
    /// Linux returns a host placeholder composition info and does not add
    /// cinematic tracks to the mutable composition.
    public func addTracks(
        for cinematicAssetInfo: CNAssetInfo,
        preferredStartingTrackID: CMPersistentTrackID
    ) -> CNCompositionInfo {
        _ = cinematicAssetInfo
        _ = preferredStartingTrackID
        let video = AVAssetTrack(trackID: preferredStartingTrackID, mediaType: "vide")
        let disparity = AVAssetTrack(
            trackID: preferredStartingTrackID &+ 1,
            mediaType: "auxv"
        )
        let metadata = AVAssetTrack(
            trackID: preferredStartingTrackID &+ 2,
            mediaType: "meta"
        )
        return CNCompositionInfo(
            asset: self,
            allCinematicTracks: [video, disparity, metadata],
            cinematicVideoTrack: video,
            cinematicDisparityTrack: disparity,
            cinematicMetadataTrack: metadata,
            frameTimingTrack: video,
            timeRange: .zero,
            naturalSize: .zero,
            preferredSize: .zero,
            preferredTransform: .identity,
            videoCompositionTracks: [video],
            videoCompositionTrackIDs: [preferredStartingTrackID],
            sampleDataTrackIDs: [preferredStartingTrackID &+ 1]
        )
    }
}
