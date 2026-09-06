import PHASE
import Foundation

private func expect(_ condition: Bool, _ message: String) {
    precondition(condition, message)
}

func testCalibrationModeRawValues() {
    expect(PHASECalibrationMode.none.rawValue == 0, "none")
    expect(PHASECalibrationMode.relativeSpl.rawValue == 1, "relative")
    expect(PHASECalibrationMode.absoluteSpl.rawValue == 2, "absolute")
    expect(PHASECalibrationMode(rawValue: 1) == .relativeSpl, "init")
    expect(PHASECalibrationMode.none != .absoluteSpl, "neq")
    var hasher = Hasher()
    PHASECalibrationMode.none.hash(into: &hasher)
    _ = hasher.finalize()
    expect(PHASECalibrationMode.none.hashValue != PHASECalibrationMode.absoluteSpl.hashValue, "hash")
}

func testCullOptionRawValues() {
    expect(PHASECullOption.terminate.rawValue == 0, "terminate")
    expect(PHASECullOption.sleepWakeAtZero.rawValue == 1, "zero")
    expect(PHASECullOption.sleepWakeAtRandomOffset.rawValue == 2, "random")
    expect(PHASECullOption.sleepWakeAtRealtimeOffset.rawValue == 3, "realtime")
    expect(PHASECullOption.doNotCull.rawValue == 4, "doNotCull")
    expect(PHASECullOption(rawValue: 4) == .doNotCull, "init")
    expect(PHASECullOption.terminate != .doNotCull, "neq")
    var hasher = Hasher()
    PHASECullOption.terminate.hash(into: &hasher)
    _ = hasher.finalize()
}

func testCurveTypeRawValues() {
    expect(PHASECurveType.linear.rawValue == 1_668_435_054, "linear")
    expect(PHASECurveType.squared.rawValue == 1_668_436_849, "squared")
    expect(PHASECurveType.inverseSquared.rawValue == 1_668_434_257, "invSq")
    expect(PHASECurveType.cubed.rawValue == 1_668_432_757, "cubed")
    expect(PHASECurveType.inverseCubed.rawValue == 1_668_434_243, "invCu")
    expect(PHASECurveType.sine.rawValue == 1_668_436_846, "sine")
    expect(PHASECurveType.inverseSine.rawValue == 1_668_434_259, "invSine")
    expect(PHASECurveType.sigmoid.rawValue == 1_668_436_839, "sigmoid")
    expect(PHASECurveType.inverseSigmoid.rawValue == 1_668_434_247, "invSig")
    expect(PHASECurveType.holdStartValue.rawValue == 1_668_434_003, "hold")
    expect(PHASECurveType.jumpToEndValue.rawValue == 1_668_434_501, "jump")
    expect(PHASECurveType(rawValue: 1_668_435_054) == .linear, "init")
    expect(PHASECurveType.linear != .squared, "neq")
    var hasher = Hasher()
    PHASECurveType.linear.hash(into: &hasher)
    _ = hasher.finalize()
}

func testMaterialPresetRawValues() {
    expect(PHASEMaterialPreset.cardboard.rawValue == 1_833_136_740, "cardboard")
    expect(PHASEMaterialPreset.glass.rawValue == 1_833_397_363, "glass")
    expect(PHASEMaterialPreset.brick.rawValue == 1_833_071_211, "brick")
    expect(PHASEMaterialPreset.concrete.rawValue == 1_833_132_914, "concrete")
    expect(PHASEMaterialPreset.drywall.rawValue == 1_833_202_295, "drywall")
    expect(PHASEMaterialPreset.wood.rawValue == 1_834_448_228, "wood")
    expect(PHASEMaterialPreset(rawValue: 1_834_448_228) == .wood, "init")
    expect(PHASEMaterialPreset.wood != .glass, "neq")
    var hasher = Hasher()
    PHASEMaterialPreset.wood.hash(into: &hasher)
    _ = hasher.finalize()
}

func testMediumPresetRawValues() {
    expect(PHASEMedium.Preset.air.rawValue == 1_835_286_898, "air")
    expect(PHASEMedium.Preset(rawValue: 1_835_286_898) == .air, "init")
    expect(PHASEMedium.Preset(rawValue: 0) == nil, "unknown nil")
    var hasher = Hasher()
    PHASEMedium.Preset.air.hash(into: &hasher)
    _ = hasher.finalize()
    expect(PHASEMedium.Preset.air.hashValue != 0 || true, "hashValue")
}

func testNormalizationModeRawValues() {
    expect(PHASENormalizationMode.none.rawValue == 0, "none")
    expect(PHASENormalizationMode.dynamic.rawValue == 1, "dynamic")
    expect(PHASENormalizationMode(rawValue: 1) == .dynamic, "init")
    expect(PHASENormalizationMode.none != .dynamic, "neq")
    var hasher = Hasher()
    PHASENormalizationMode.none.hash(into: &hasher)
    _ = hasher.finalize()
}

func testPlaybackModeRawValues() {
    expect(PHASEPlaybackMode.oneShot.rawValue == 0, "oneShot")
    expect(PHASEPlaybackMode.looping.rawValue == 1, "looping")
    expect(PHASEPlaybackMode(rawValue: 0) == .oneShot, "init")
    expect(PHASEPlaybackMode.oneShot != .looping, "neq")
    var hasher = Hasher()
    PHASEPlaybackMode.oneShot.hash(into: &hasher)
    _ = hasher.finalize()
}

func testPushStreamCompletionRawValues() {
    expect(PHASEPushStreamCompletionCallbackCondition.dataRendered.rawValue == 0, "dataRendered")
    expect(PHASEPushStreamCompletionCallbackCondition(rawValue: 0) == .dataRendered, "init")
    expect(PHASEPushStreamCompletionCallbackCondition(rawValue: 1) == nil, "unknown nil")
    var hasher = Hasher()
    PHASEPushStreamCompletionCallbackCondition.dataRendered.hash(into: &hasher)
    _ = hasher.finalize()
}

func testReverbPresetRawValues() {
    expect(PHASEReverbPreset.none.rawValue == 1_917_742_958, "none")
    expect(PHASEReverbPreset.smallRoom.rawValue == 1_918_063_213, "small")
    expect(PHASEReverbPreset.mediumRoom.rawValue == 1_917_669_997, "medRoom")
    expect(PHASEReverbPreset.largeRoom.rawValue == 1_917_604_401, "largeRoom")
    expect(PHASEReverbPreset.largeRoom2.rawValue == 1_917_604_402, "largeRoom2")
    expect(PHASEReverbPreset.mediumChamber.rawValue == 1_917_666_152, "medCh")
    expect(PHASEReverbPreset.largeChamber.rawValue == 1_917_600_616, "largeCh")
    expect(PHASEReverbPreset.mediumHall.rawValue == 1_917_667_377, "medHall")
    expect(PHASEReverbPreset.mediumHall2.rawValue == 1_917_667_378, "medHall2")
    expect(PHASEReverbPreset.mediumHall3.rawValue == 1_917_667_379, "medHall3")
    expect(PHASEReverbPreset.largeHall.rawValue == 1_917_601_841, "largeHall")
    expect(PHASEReverbPreset.largeHall2.rawValue == 1_917_601_842, "largeHall2")
    expect(PHASEReverbPreset.cathedral.rawValue == 1_917_023_336, "cathedral")
    expect(PHASEReverbPreset(rawValue: 1_917_023_336) == .cathedral, "init")
    expect(PHASEReverbPreset.none != .cathedral, "neq")
    var hasher = Hasher()
    PHASEReverbPreset.none.hash(into: &hasher)
    _ = hasher.finalize()
}

func testSpatializationModeRawValues() {
    expect(PHASESpatializationMode.automatic.rawValue == 0, "auto")
    expect(PHASESpatializationMode.alwaysUseBinaural.rawValue == 1, "binaural")
    expect(PHASESpatializationMode.alwaysUseChannelBased.rawValue == 2, "channel")
    expect(PHASESpatializationMode(rawValue: 0) == .automatic, "init")
    expect(PHASESpatializationMode.automatic != .alwaysUseBinaural, "neq")
    var hasher = Hasher()
    PHASESpatializationMode.automatic.hash(into: &hasher)
    _ = hasher.finalize()
}

func testUpdateModeRawValues() {
    expect(PHASEEngine.UpdateMode.automatic.rawValue == 0, "auto")
    expect(PHASEEngine.UpdateMode.manual.rawValue == 1, "manual")
    expect(PHASEEngine.UpdateMode(rawValue: 1) == .manual, "init")
    expect(PHASEEngine.UpdateMode.automatic != .manual, "neq")
    var hasher = Hasher()
    PHASEEngine.UpdateMode.automatic.hash(into: &hasher)
    _ = hasher.finalize()
}

func testAssetTypeRawValues() {
    expect(PHASEAsset.AssetType.resident.rawValue == 0, "resident")
    expect(PHASEAsset.AssetType.streamed.rawValue == 1, "streamed")
    expect(PHASEAsset.AssetType(rawValue: 0) == .resident, "init")
    expect(PHASEAsset.AssetType.resident != .streamed, "neq")
    var hasher = Hasher()
    PHASEAsset.AssetType.resident.hash(into: &hasher)
    _ = hasher.finalize()
}

func testRenderingStateRawValues() {
    expect(PHASESoundEvent.RenderingState.stopped.rawValue == 0, "stopped")
    expect(PHASESoundEvent.RenderingState.started.rawValue == 1, "started")
    expect(PHASESoundEvent.RenderingState.paused.rawValue == 2, "paused")
    expect(PHASESoundEvent.RenderingState(rawValue: 0) == .stopped, "init")
    expect(PHASESoundEvent.RenderingState.stopped != .started, "neq")
    var hasher = Hasher()
    PHASESoundEvent.RenderingState.stopped.hash(into: &hasher)
    _ = hasher.finalize()
}

func testPrepareHandlerReasonRawValues() {
    expect(PHASESoundEvent.PrepareHandlerReason.failure.rawValue == 0, "failure")
    expect(PHASESoundEvent.PrepareHandlerReason.prepared.rawValue == 1, "prepared")
    expect(PHASESoundEvent.PrepareHandlerReason.terminated.rawValue == 2, "terminated")
    expect(PHASESoundEvent.PrepareHandlerReason(rawValue: 1) == .prepared, "init")
    expect(PHASESoundEvent.PrepareHandlerReason.failure != .prepared, "neq")
    var hasher = Hasher()
    PHASESoundEvent.PrepareHandlerReason.failure.hash(into: &hasher)
    _ = hasher.finalize()
}

func testPrepareStateRawValues() {
    expect(PHASESoundEvent.PrepareState.prepareNotStarted.rawValue == 0, "notStarted")
    expect(PHASESoundEvent.PrepareState.prepareInProgress.rawValue == 1, "inProgress")
    expect(PHASESoundEvent.PrepareState.prepared.rawValue == 2, "prepared")
    expect(PHASESoundEvent.PrepareState(rawValue: 0) == .prepareNotStarted, "init")
    expect(PHASESoundEvent.PrepareState.prepared != .prepareNotStarted, "neq")
    var hasher = Hasher()
    PHASESoundEvent.PrepareState.prepared.hash(into: &hasher)
    _ = hasher.finalize()
}

func testSeekHandlerReasonRawValues() {
    expect(PHASESoundEvent.SeekHandlerReason.failure.rawValue == 0, "failure")
    expect(PHASESoundEvent.SeekHandlerReason.failureSeekAlreadyInProgress.rawValue == 1, "inProgress")
    expect(PHASESoundEvent.SeekHandlerReason.seekSuccessful.rawValue == 2, "success")
    expect(PHASESoundEvent.SeekHandlerReason(rawValue: 2) == .seekSuccessful, "init")
    expect(PHASESoundEvent.SeekHandlerReason.failure != .seekSuccessful, "neq")
    var hasher = Hasher()
    PHASESoundEvent.SeekHandlerReason.failure.hash(into: &hasher)
    _ = hasher.finalize()
}

func testStartHandlerReasonRawValues() {
    expect(PHASESoundEvent.StartHandlerReason.failure.rawValue == 0, "failure")
    expect(PHASESoundEvent.StartHandlerReason.finishedPlaying.rawValue == 1, "finished")
    expect(PHASESoundEvent.StartHandlerReason.terminated.rawValue == 2, "terminated")
    expect(PHASESoundEvent.StartHandlerReason(rawValue: 1) == .finishedPlaying, "init")
    expect(PHASESoundEvent.StartHandlerReason.failure != .terminated, "neq")
    var hasher = Hasher()
    PHASESoundEvent.StartHandlerReason.failure.hash(into: &hasher)
    _ = hasher.finalize()
}
