import Foundation
import Cinematic

func testCNAssetSpatialAudioInfoIsSupportedFalse() {
    precondition(CNAssetSpatialAudioInfo.isSupported == false)
}

func testCNAssetSpatialAudioInfoCheckIfContainsSpatialAudioFalse() {
    var observed: Bool?
    CNAssetSpatialAudioInfo.checkIfContainsSpatialAudio(asset: AVAsset()) { value in
        observed = value
    }
    precondition(observed == false)
}

func testCNAssetSpatialAudioInfoHostUnparsedDefaults() {
    let info = CNAssetSpatialAudioInfo.host_makeUnparsed(asset: AVAsset())
    precondition(info.defaultRenderingStyle == .cinematic)
    precondition(info.defaultEffectIntensity == 1)
    precondition(info.spatialAudioMixMetadata.isEmpty)
    precondition(info.defaultSpatialAudioTrack.mediaType == "soun")
}

func testCNAssetSpatialAudioInfoWriterSettingsEmpty() {
    let info = CNAssetSpatialAudioInfo.host_makeUnparsed(asset: AVAsset())
    precondition(info.assetWriterInputSettings(for: .stereo).isEmpty)
    precondition(info.assetWriterInputSettings(for: .spatial).isEmpty)
}

func testCNAssetSpatialAudioInfoReaderSettingsEmpty() {
    let info = CNAssetSpatialAudioInfo.host_makeUnparsed(asset: AVAsset())
    precondition(info.assetReaderOutputSettings(for: .stereo).isEmpty)
    precondition(info.assetReaderOutputSettings(for: .spatial).isEmpty)
}

func testCNAssetSpatialAudioInfoAudioMixReturnsObject() {
    let info = CNAssetSpatialAudioInfo.host_makeUnparsed(asset: AVAsset())
    let mix = info.audioMix(effectIntensity: 0.5, renderingStyle: .studio)
    precondition(type(of: mix) == AVAudioMix.self)
}
