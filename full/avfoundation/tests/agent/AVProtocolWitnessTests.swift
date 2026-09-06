import Foundation
import AVFoundation

private func avAssertHashablePair<T: Hashable>(_ a: T, _ b: T) {
    precondition(a == a)
    precondition(a != b)
    precondition(a.hashValue == a.hashValue)
    var hasher = Hasher()
    a.hash(into: &hasher)
    b.hash(into: &hasher)
    _ = hasher.finalize()
}

private func avAssertIntEnumHash<T: Hashable & RawRepresentable>(_ type: T.Type) where T.RawValue == Int {
    var found: [T] = []
    for raw in [-11800, -11801, -11820, -11834, 0, 1, 2, 3, 4] {
        if let value = T(rawValue: raw), !found.contains(where: { $0 == value }) {
            found.append(value)
        }
        if found.count == 2 { break }
    }
    precondition(found.count == 2, "\(type) needs two distinct cases")
    avAssertHashablePair(found[0], found[1])
}

private func avAssertStringNewtypeHash<T: Hashable & RawRepresentable>(_ type: T.Type) where T.RawValue == String {
    avAssertHashablePair(T(rawValue: "alpha"), T(rawValue: "beta"))
}

private func avAssertOptionSetAlgebra<T: OptionSet>(_ member: T, extra: T) where T.Element == T, T.RawValue: FixedWidthInteger {
    var set = T()
    precondition(set.isEmpty)
    let inserted = set.insert(member)
    precondition(inserted.inserted)
    precondition(set.contains(member))
    _ = set.update(with: member)
    let removed = set.remove(member)
    precondition(removed != nil)
    set = T([member])
    precondition(!set.isDisjoint(with: set))
    precondition(set.isSubset(of: set))
    precondition(set.isSuperset(of: T()))
    precondition(!set.isStrictSubset(of: set))
    precondition(!set.isStrictSuperset(of: set))
    precondition(set.union(extra).contains(member))
    _ = set.intersection(member)
    _ = set.symmetricDifference(extra)
    _ = set.subtracting(T())
    var mutating = T([member])
    mutating.formUnion(extra)
    mutating.formIntersection(member)
    mutating.formSymmetricDifference(extra)
    mutating.subtract(T())
    _ = T(CollectionOfOne(member))
    precondition(member != extra || extra == member)
}

func testRawRepresentableEnumHashableSynthesis() {
    avAssertIntEnumHash(AVAssetExportSession.Status.self)
    avAssertIntEnumHash(AVAssetImageGenerator.Result.self)
    avAssertIntEnumHash(AVAssetReader.Status.self)
    avAssertIntEnumHash(AVAssetSegmentType.self)
    avAssertIntEnumHash(AVAssetWriter.Status.self)
    avAssertIntEnumHash(AVAuthorizationStatus.self)
    avAssertIntEnumHash(AVCaption.Animation.self)
    avAssertIntEnumHash(AVCaptionConversionValidator.Status.self)
    avAssertIntEnumHash(AVCaption.FontStyle.self)
    avAssertIntEnumHash(AVCaption.FontWeight.self)
    avAssertIntEnumHash(AVCaptionRegion.DisplayAlignment.self)
    avAssertIntEnumHash(AVCaptionRegion.Scroll.self)
    avAssertIntEnumHash(AVCaptionRegion.WritingMode.self)
    avAssertIntEnumHash(AVCaptionRubyAlignment.self)
    avAssertIntEnumHash(AVCaptionRubyPosition.self)
    avAssertIntEnumHash(AVCaption.TextAlignment.self)
    avAssertIntEnumHash(AVCaption.TextCombine.self)
    avAssertIntEnumHash(AVCaptionUnitsType.self)
    avAssertIntEnumHash(AVCaptureDevice.AutoFocusRangeRestriction.self)
    avAssertIntEnumHash(AVCaptureDevice.Format.AutoFocusSystem.self)
    avAssertIntEnumHash(AVCaptureCameraLensSmudgeDetectionStatus.self)
    avAssertIntEnumHash(AVCaptureDevice.CenterStageControlMode.self)
    avAssertIntEnumHash(AVCaptureDevice.CinematicVideoFocusMode.self)
    avAssertIntEnumHash(AVCaptureColorSpace.self)
    avAssertIntEnumHash(AVCaptureDevice.Position.self)
    avAssertIntEnumHash(AVCaptureDevice.ExposureMode.self)
    avAssertIntEnumHash(AVCaptureDevice.FlashMode.self)
    avAssertIntEnumHash(AVCaptureDevice.FocusMode.self)
    avAssertIntEnumHash(AVCaptureDevice.LensStabilizationStatus.self)
    avAssertIntEnumHash(AVCaptureDevice.MicrophoneMode.self)
    avAssertIntEnumHash(AVCaptureMultichannelAudioMode.self)
    avAssertIntEnumHash(AVCaptureOutput.DataDroppedReason.self)
    avAssertIntEnumHash(AVCapturePhotoOutput.CaptureReadiness.self)
    avAssertIntEnumHash(AVCapturePhotoOutput.QualityPrioritization.self)
    avAssertIntEnumHash(AVCaptureDevice.PrimaryConstituentDeviceSwitchingBehavior.self)
    avAssertIntEnumHash(AVCaptureSession.InterruptionReason.self)
    avAssertIntEnumHash(AVCaptureDevice.SystemUserInterface.self)
    avAssertIntEnumHash(AVCaptureTimecodeGenerator.SynchronizationStatus.self)
    avAssertIntEnumHash(AVCaptureTimecode.SourceType.self)
    avAssertIntEnumHash(AVCaptureDevice.TorchMode.self)
    avAssertIntEnumHash(AVCaptureVideoOrientation.self)
    avAssertIntEnumHash(AVCaptureVideoStabilizationMode.self)
    avAssertIntEnumHash(AVCaptureDevice.WhiteBalanceMode.self)
    avAssertIntEnumHash(AVContentKeyRequest.Status.self)
    avAssertIntEnumHash(AVDepthData.Accuracy.self)
    avAssertIntEnumHash(AVDepthData.Quality.self)
    avAssertIntEnumHash(AVError.Code.self)
    avAssertIntEnumHash(AVExternalContentProtectionStatus.self)
    avAssertIntEnumHash(AVExternalSyncDeviceStatus.self)
    avAssertIntEnumHash(AVKeyValueStatus.self)
    avAssertIntEnumHash(AVPlayer.ActionAtItemEnd.self)
    avAssertIntEnumHash(AVPlayerAudiovisualBackgroundPlaybackPolicy.self)
    avAssertIntEnumHash(AVPlayerInterstitialEventAssetListResponseStatus.self)
    avAssertIntEnumHash(AVPlayerInterstitialEvent.SkippableEventState.self)
    avAssertIntEnumHash(AVPlayerInterstitialEvent.TimelineOccupancy.self)
    avAssertIntEnumHash(AVPlayerItemSegment.SegmentType.self)
    avAssertIntEnumHash(AVPlayerItem.Status.self)
    avAssertIntEnumHash(AVPlayerLooper.ItemOrdering.self)
    avAssertIntEnumHash(AVPlayerLooper.Status.self)
    avAssertIntEnumHash(AVPlayer.NetworkResourcePriority.self)
    avAssertIntEnumHash(AVPlayer.Status.self)
    avAssertIntEnumHash(AVPlayer.TimeControlStatus.self)
    avAssertIntEnumHash(AVQueuedSampleBufferRenderingStatus.self)
    avAssertIntEnumHash(AVSampleBufferRequest.Direction.self)
    avAssertIntEnumHash(AVSampleBufferRequest.Mode.self)
}

func testOptionSetAlgebraSynthesis() {
    avAssertOptionSetAlgebra(
        AVAssetReferenceRestrictions.forbidRemoteReferenceToLocal,
        extra: .forbidAll
    )
    avAssertOptionSetAlgebra(
        AVAssetTrackGroupOutputHandling.preserveAlternateTracks,
        extra: AVAssetTrackGroupOutputHandling(rawValue: 1 << 1)
    )
    avAssertOptionSetAlgebra(
        AVAudioSpatializationFormats.monoAndStereo,
        extra: .multichannel
    )
    avAssertOptionSetAlgebra(
        AVCaption.Decoration.underline,
        extra: .overline
    )
    avAssertOptionSetAlgebra(
        AVCaptureDevice.PrimaryConstituentDeviceRestrictedSwitchingBehaviorConditions.videoZoomChanged,
        extra: .focusModeChanged
    )
    avAssertOptionSetAlgebra(
        AVCaptureDevice.SystemPressureState.Factors.systemTemperature,
        extra: .peakPower
    )
    avAssertOptionSetAlgebra(
        AVDelegatingPlaybackCoordinatorRateChangeOptions.playImmediately,
        extra: AVDelegatingPlaybackCoordinatorRateChangeOptions(rawValue: 1 << 1)
    )
    avAssertOptionSetAlgebra(
        AVDelegatingPlaybackCoordinatorSeekOptions.resumeImmediately,
        extra: AVDelegatingPlaybackCoordinatorSeekOptions(rawValue: 1 << 1)
    )
    avAssertOptionSetAlgebra(
        AVMovieWritingOptions.addMovieHeaderToDestination,
        extra: .truncateDestinationToMovieHeaderOnly
    )
    avAssertOptionSetAlgebra(AVPlayer.HDRMode.hlg, extra: .hdr10)
    avAssertOptionSetAlgebra(
        AVPlayerInterstitialEvent.Restrictions.constrainsSeekingForwardInPrimaryContent,
        extra: .requiresPlaybackAtPreferredRateForAdvancement
    )
    avAssertOptionSetAlgebra(
        AVVariantPreferences.scalabilityToLosslessAudio,
        extra: AVVariantPreferences(rawValue: 1 << 1)
    )
}

func testNewtypeWrapperHashableSynthesis() {
    avAssertStringNewtypeHash(AVAssetDownloadedAssetEvictionPriority.self)
    avAssertStringNewtypeHash(AVAssetImageGenerator.ApertureMode.self)
    avAssertStringNewtypeHash(AVAssetImageGenerator.DynamicRangePolicy.self)
    avAssertStringNewtypeHash(AVAssetPlaybackConfigurationOption.self)
    avAssertStringNewtypeHash(AVAssetWriterInput.MediaDataLocation.self)
    avAssertStringNewtypeHash(AVAudioTimePitchAlgorithm.self)
    avAssertStringNewtypeHash(AVCaptionConversionAdjustment.AdjustmentType.self)
    avAssertStringNewtypeHash(AVCaptionConversionWarning.WarningType.self)
    avAssertStringNewtypeHash(AVCaptionSettingsKey.self)
    avAssertStringNewtypeHash(AVCaptureDevice.AspectRatio.self)
    avAssertStringNewtypeHash(AVCaptureDevice.DeviceType.self)
    avAssertStringNewtypeHash(AVCaptureReactionType.self)
    avAssertStringNewtypeHash(AVCaptureSceneMonitoringStatus.self)
    avAssertStringNewtypeHash(AVCaptureSession.Preset.self)
    avAssertStringNewtypeHash(AVCaptureDevice.SystemPressureState.Level.self)
    avAssertStringNewtypeHash(AVContentKeyRequest.RetryReason.self)
    avAssertStringNewtypeHash(AVContentKeySessionServerPlaybackContextOption.self)
    avAssertStringNewtypeHash(AVContentKeySystem.self)
    avAssertStringNewtypeHash(AVCoordinatedPlaybackSuspension.Reason.self)
    avAssertStringNewtypeHash(AVFileType.self)
    avAssertStringNewtypeHash(AVFileTypeProfile.self)
    avAssertStringNewtypeHash(AVLayerVideoGravity.self)
    avAssertStringNewtypeHash(AVMediaCharacteristic.self)
    avAssertStringNewtypeHash(AVMediaType.self)
    avAssertStringNewtypeHash(AVMetadataExtraAttributeKey.self)
    avAssertStringNewtypeHash(AVMetadataFormat.self)
    avAssertStringNewtypeHash(AVMetadataIdentifier.self)
    avAssertStringNewtypeHash(AVMetadataKey.self)
    avAssertStringNewtypeHash(AVMetadataKeySpace.self)
    avAssertStringNewtypeHash(AVMetadataObject.ObjectType.self)
    avAssertStringNewtypeHash(AVOutputSettingsPreset.self)
    avAssertStringNewtypeHash(AVPlayerIntegratedTimelineSnapshotsOutOfSyncReason.self)
    avAssertStringNewtypeHash(AVPlayerInterstitialEvent.Cue.self)
    avAssertStringNewtypeHash(AVPlayerItemLegibleOutput.TextStylingResolution.self)
    avAssertStringNewtypeHash(AVPlayer.RateDidChangeReason.self)
    avAssertStringNewtypeHash(AVPlayer.WaitingReason.self)
    avAssertStringNewtypeHash(AVSemanticSegmentationMatte.MatteType.self)
    avAssertStringNewtypeHash(AVSpatialCaptureDiscomfortReason.self)
    avAssertStringNewtypeHash(AVAssetTrack.AssociationType.self)
    avAssertStringNewtypeHash(AVVideoApertureMode.self)
    avAssertStringNewtypeHash(AVVideoCodecType.self)
    avAssertStringNewtypeHash(AVVideoComposition.PerFrameHDRDisplayMetadataPolicy.self)
    avAssertStringNewtypeHash(AVVideoRange.self)
}
