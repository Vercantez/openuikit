import Foundation
import Cinematic

func testCNAssetInfoHostUnparsedStoresAsset() {
    let asset = AVAsset(url: URL(fileURLWithPath: "/tmp/host.cinematic.mov"))
    let info = CNAssetInfo.host_makeUnparsed(asset: asset)
    precondition(info.asset === asset)
}

func testCNAssetInfoHostUnparsedTrackLayout() {
    let info = CNAssetInfo.host_makeUnparsed(asset: AVAsset())
    precondition(info.allCinematicTracks.count == 3)
    precondition(info.cinematicVideoTrack.trackID == 1)
    precondition(info.cinematicDisparityTrack.trackID == 2)
    precondition(info.cinematicMetadataTrack.trackID == 3)
    precondition(info.frameTimingTrack.trackID == 1)
    precondition(info.videoCompositionTracks.count == 1)
    precondition(info.videoCompositionTrackIDs == [1])
    precondition(info.sampleDataTrackIDs == [2])
}

func testCNAssetInfoHostUnparsedGeometryIsZero() {
    let info = CNAssetInfo.host_makeUnparsed(asset: AVAsset())
    precondition(info.naturalSize == .zero)
    precondition(info.preferredSize == .zero)
    precondition(info.preferredTransform == .identity)
    precondition(info.timeRange == .zero)
}

func testAVMutableCompositionAddTracksReturnsCompositionInfo() {
    let composition = AVMutableComposition()
    let source = CNAssetInfo.host_makeUnparsed(asset: AVAsset())
    let added = composition.addTracks(for: source, preferredStartingTrackID: 20)
    precondition(added.cinematicVideoTrack.trackID == 20)
    precondition(added.cinematicDisparityTrack.trackID == 21)
    precondition(added.cinematicMetadataTrack.trackID == 22)
    precondition(added.videoCompositionTrackIDs == [20])
}

func testCNCompositionInfoInsertTimeRangeThrowsUnsupported() {
    let composition = AVMutableComposition()
    let source = CNAssetInfo.host_makeUnparsed(asset: AVAsset())
    let added = composition.addTracks(for: source, preferredStartingTrackID: 1)
    do {
        try added.insertTimeRange(
            CMTimeRange(start: .zero, duration: CMTime(seconds: 1, preferredTimescale: 600)),
            of: source,
            at: .zero
        )
        preconditionFailure("insertTimeRange should fail closed")
    } catch let error as CNCinematicError {
        precondition(error.code == .unsupported)
        precondition(error.errorCode == 5)
    } catch {
        preconditionFailure("unexpected error type")
    }
}
