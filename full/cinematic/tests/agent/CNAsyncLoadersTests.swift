import Foundation
import Cinematic

func testCNAssetInfoAsyncInitThrowsUnsupported() async {
    let asset = AVAsset()
    do {
        _ = try await CNAssetInfo(asset: asset)
        preconditionFailure("CNAssetInfo(asset:) should fail closed")
    } catch let error as CNCinematicError {
        precondition(error.code == .unsupported)
    } catch {
        preconditionFailure("unexpected error type from CNAssetInfo(asset:)")
    }
}

func testCNAssetInfoIsCinematicAsyncFalse() async {
    let result = await CNAssetInfo.isCinematic(asset: AVAsset())
    precondition(result == false)
}

func testCNRenderingSessionAttributesAsyncInitThrowsUnsupported() async {
    let asset = AVAsset()
    do {
        _ = try await CNRenderingSession.Attributes(asset: asset)
        preconditionFailure("CNRenderingSession.Attributes(asset:) should fail closed")
    } catch let error as CNCinematicError {
        precondition(error.code == .unsupported)
    } catch {
        preconditionFailure("unexpected error type from Attributes(asset:)")
    }
}

func testCNAssetSpatialAudioInfoAsyncInitThrowsUnsupported() async {
    let asset = AVAsset()
    do {
        _ = try await CNAssetSpatialAudioInfo(asset: asset)
        preconditionFailure("CNAssetSpatialAudioInfo(asset:) should fail closed")
    } catch let error as CNCinematicError {
        precondition(error.code == .unsupported)
    } catch {
        preconditionFailure("unexpected error type from CNAssetSpatialAudioInfo(asset:)")
    }
}

func testCNAssetSpatialAudioInfoAssetContainsSpatialAudioAsyncFalse() async {
    let result = await CNAssetSpatialAudioInfo.assetContainsSpatialAudio(asset: AVAsset())
    precondition(result == false)
}

func testCNScriptAsyncInitThrowsUnsupported() async {
    let asset = AVAsset()
    do {
        _ = try await CNScript(asset: asset, changes: nil, progress: nil)
        preconditionFailure("CNScript(asset:changes:progress:) should fail closed")
    } catch let error as CNCinematicError {
        precondition(error.code == .unsupported)
    } catch {
        preconditionFailure("unexpected error type from CNScript(asset:changes:progress:)")
    }
}
