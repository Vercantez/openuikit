import Foundation
import VideoToolbox

func vtExpect(_ condition: Bool, _ message: String) {
    guard condition else {
        fatalError("VIDEOTOOLBOX_RUNTIME_FAIL \(message)")
    }
}

func vtExpectStatus(_ status: OSStatus, _ expected: OSStatus, _ message: String) {
    vtExpect(status == expected, "\(message) got \(status) expected \(expected)")
}

final class VTTestBox: @unchecked Sendable {
    var image: OpaquePointer?
    var pts = VTMediaTime.invalid
    var duration = VTMediaTime.invalid
    var count = 0
    var handlerCalled = false
    var visited = 0
}

// --- VideoToolboxErrorTests.swift ---

func testErrorConstantValues() {
    let pairs: [(OSStatus, OSStatus, String)] = [
        (kVTAllocationFailedErr, -12904, "kVTAllocationFailedErr"),
        (kVTColorCorrectionImageRotationFailedErr, -12219, "kVTColorCorrectionImageRotationFailedErr"),
        (kVTColorCorrectionPixelTransferFailedErr, -12212, "kVTColorCorrectionPixelTransferFailedErr"),
        (kVTColorSyncTransformConvertFailedErr, -12919, "kVTColorSyncTransformConvertFailedErr"),
        (kVTCouldNotCreateColorCorrectionDataErr, -12918, "kVTCouldNotCreateColorCorrectionDataErr"),
        (kVTCouldNotCreateInstanceErr, -12907, "kVTCouldNotCreateInstanceErr"),
        (kVTCouldNotFindExtensionErr, -19510, "kVTCouldNotFindExtensionErr"),
        (kVTCouldNotFindTemporalFilterErr, -12217, "kVTCouldNotFindTemporalFilterErr"),
        (kVTCouldNotFindVideoDecoderErr, -12906, "kVTCouldNotFindVideoDecoderErr"),
        (kVTCouldNotFindVideoEncoderErr, -12908, "kVTCouldNotFindVideoEncoderErr"),
        (kVTCouldNotOutputTaggedBufferGroupErr, -17699, "kVTCouldNotOutputTaggedBufferGroupErr"),
        (kVTExtensionConflictErr, -19511, "kVTExtensionConflictErr"),
        (kVTExtensionDisabledErr, -17697, "kVTExtensionDisabledErr"),
        (kVTFormatDescriptionChangeNotSupportedErr, -12916, "kVTFormatDescriptionChangeNotSupportedErr"),
        (kVTFrameSiloInvalidTimeRangeErr, -12216, "kVTFrameSiloInvalidTimeRangeErr"),
        (kVTFrameSiloInvalidTimeStampErr, -12215, "kVTFrameSiloInvalidTimeStampErr"),
        (kVTImageRotationNotSupportedErr, -12914, "kVTImageRotationNotSupportedErr"),
        (kVTInsufficientSourceColorDataErr, -12917, "kVTInsufficientSourceColorDataErr"),
        (kVTInvalidSessionErr, -12903, "kVTInvalidSessionErr"),
        (kVTMultiPassStorageIdentifierMismatchErr, -12913, "kVTMultiPassStorageIdentifierMismatchErr"),
        (kVTMultiPassStorageInvalidErr, -12214, "kVTMultiPassStorageInvalidErr"),
        (kVTParameterErr, -12902, "kVTParameterErr"),
        (kVTPixelRotationNotSupportedErr, -12914, "kVTPixelRotationNotSupportedErr"),
        (kVTPixelTransferNotPermittedErr, -12218, "kVTPixelTransferNotPermittedErr"),
        (kVTPixelTransferNotSupportedErr, -12905, "kVTPixelTransferNotSupportedErr"),
        (kVTPropertyNotSupportedErr, -12900, "kVTPropertyNotSupportedErr"),
        (kVTPropertyReadOnlyErr, -12901, "kVTPropertyReadOnlyErr"),
        (kVTSessionMalfunctionErr, -17691, "kVTSessionMalfunctionErr"),
        (kVTVideoDecoderAuthorizationErr, -12210, "kVTVideoDecoderAuthorizationErr"),
        (kVTVideoDecoderBadDataErr, -12909, "kVTVideoDecoderBadDataErr"),
        (kVTVideoDecoderCallbackMessagingErr, -17695, "kVTVideoDecoderCallbackMessagingErr"),
        (kVTVideoDecoderMalfunctionErr, -12911, "kVTVideoDecoderMalfunctionErr"),
        (kVTVideoDecoderNeedsRosettaErr, -17692, "kVTVideoDecoderNeedsRosettaErr"),
        (kVTVideoDecoderNotAvailableNowErr, -12913, "kVTVideoDecoderNotAvailableNowErr"),
        (kVTVideoDecoderReferenceMissingErr, -17694, "kVTVideoDecoderReferenceMissingErr"),
        (kVTVideoDecoderRemovedErr, -17690, "kVTVideoDecoderRemovedErr"),
        (kVTVideoDecoderUnknownErr, -17696, "kVTVideoDecoderUnknownErr"),
        (kVTVideoDecoderUnsupportedDataFormatErr, -12910, "kVTVideoDecoderUnsupportedDataFormatErr"),
        (kVTVideoEncoderAuthorizationErr, -12211, "kVTVideoEncoderAuthorizationErr"),
        (kVTVideoEncoderAutoWhiteBalanceNotLockedErr, -19512, "kVTVideoEncoderAutoWhiteBalanceNotLockedErr"),
        (kVTVideoEncoderMVHEVCVideoLayerIDsMismatchErr, -17698, "kVTVideoEncoderMVHEVCVideoLayerIDsMismatchErr"),
        (kVTVideoEncoderMalfunctionErr, -12912, "kVTVideoEncoderMalfunctionErr"),
        (kVTVideoEncoderNeedsRosettaErr, -17693, "kVTVideoEncoderNeedsRosettaErr"),
        (kVTVideoEncoderNotAvailableNowErr, -12915, "kVTVideoEncoderNotAvailableNowErr"),
    ]
    vtExpect(pairs.count >= 40, "error table size \(pairs.count)")
    for (value, expected, name) in pairs {
        vtExpect(value == expected, "\(name) got \(value) expected \(expected)")
        vtExpect(value != 0 || name.contains("Ok"), "nonzero \(name)")
    }
    let host = VTHostAllErrorConstants()
    vtExpect(host.count == pairs.count, "host error table")
}

// --- VideoToolboxFlagTests.swift ---

func testOptionSetAndFlagRawValues() {
    let decodeAsync = VTDecodeFrameFlags.enableAsynchronousDecompression
    vtExpect(decodeAsync.rawValue == 1, "decode async rawValue")
    vtExpect(decodeAsync.rawValue == kVTDecodeFrame_EnableAsynchronousDecompression, "kVTDecodeFrame_EnableAsynchronousDecompression")
    vtExpect(VTDecodeFrameFlags.doNotOutputFrame.rawValue == kVTDecodeFrame_DoNotOutputFrame, "kVTDecodeFrame_DoNotOutputFrame")
    vtExpect(VTDecodeFrameFlags.oneXRealTimePlayback.rawValue == kVTDecodeFrame_1xRealTimePlayback, "kVTDecodeFrame_1xRealTimePlayback")
    vtExpect(VTDecodeFrameFlags.enableTemporalProcessing.rawValue == kVTDecodeFrame_EnableTemporalProcessing, "kVTDecodeFrame_EnableTemporalProcessing")
    vtExpect(VTDecodeFrameFlags(rawValue: 3).rawValue == 3, "VTDecodeFrameFlags init(rawValue:)")

    vtExpect(VTDecodeInfoFlags.asynchronous.rawValue == kVTDecodeInfo_Asynchronous, "kVTDecodeInfo_Asynchronous")
    vtExpect(VTDecodeInfoFlags.frameDropped.rawValue == kVTDecodeInfo_FrameDropped, "kVTDecodeInfo_FrameDropped")
    vtExpect(VTDecodeInfoFlags.imageBufferModifiable.rawValue == kVTDecodeInfo_ImageBufferModifiable, "kVTDecodeInfo_ImageBufferModifiable")
    vtExpect(VTDecodeInfoFlags.skippedLeadingFrameDropped.rawValue == kVTDecodeInfo_SkippedLeadingFrameDropped, "kVTDecodeInfo_SkippedLeadingFrameDropped")
    vtExpect(VTDecodeInfoFlags.frameInterrupted.rawValue == kVTDecodeInfo_FrameInterrupted, "kVTDecodeInfo_FrameInterrupted")
    vtExpect(VTDecodeInfoFlags(rawValue: 16).rawValue == 16, "VTDecodeInfoFlags init(rawValue:)")

    vtExpect(VTEncodeInfoFlags.asynchronous.rawValue == kVTEncodeInfo_Asynchronous, "kVTEncodeInfo_Asynchronous")
    vtExpect(VTEncodeInfoFlags.frameDropped.contains(.frameDropped), "VTEncodeInfoFlags.frameDropped")
    vtExpect(VTEncodeInfoFlags.frameDropped.rawValue == kVTEncodeInfo_FrameDropped, "kVTEncodeInfo_FrameDropped")
    vtExpect(VTEncodeInfoFlags(rawValue: 2).rawValue == 2, "VTEncodeInfoFlags init(rawValue:)")

    vtExpect(VTCompressionSessionOptionFlags.beginFinalPass.rawValue == kVTCompressionSessionBeginFinalPass, "kVTCompressionSessionBeginFinalPass")
    vtExpect(VTCompressionSessionOptionFlags(rawValue: 1).rawValue == 1, "VTCompressionSessionOptionFlags init(rawValue:)")
    vtExpect(VTCompressionSessionOptionFlags.beginFinalPass.rawValue == 1, "beginFinalPass rawValue")
}

// --- VideoToolboxKeyTests.swift ---

func testCompressionPropertyKeyPayloads() {
    let pairs: [(String, String)] = [
        (kVTCompressionPreset_Balanced, "kVTCompressionPreset_Balanced"),
        (kVTCompressionPreset_HighQuality, "kVTCompressionPreset_HighQuality"),
        (kVTCompressionPreset_HighSpeed, "kVTCompressionPreset_HighSpeed"),
        (kVTCompressionPreset_VideoConferencing, "kVTCompressionPreset_VideoConferencing"),
        (kVTCompressionPropertyCameraCalibrationKey_ExtrinsicOrientationQuaternion, "kVTCompressionPropertyCameraCalibrationKey_ExtrinsicOrientationQuaternion"),
        (kVTCompressionPropertyCameraCalibrationKey_ExtrinsicOriginSource, "kVTCompressionPropertyCameraCalibrationKey_ExtrinsicOriginSource"),
        (kVTCompressionPropertyCameraCalibrationKey_IntrinsicMatrix, "kVTCompressionPropertyCameraCalibrationKey_IntrinsicMatrix"),
        (kVTCompressionPropertyCameraCalibrationKey_IntrinsicMatrixProjectionOffset, "kVTCompressionPropertyCameraCalibrationKey_IntrinsicMatrixProjectionOffset"),
        (kVTCompressionPropertyCameraCalibrationKey_IntrinsicMatrixReferenceDimensions, "kVTCompressionPropertyCameraCalibrationKey_IntrinsicMatrixReferenceDimensions"),
        (kVTCompressionPropertyCameraCalibrationKey_LensAlgorithmKind, "kVTCompressionPropertyCameraCalibrationKey_LensAlgorithmKind"),
        (kVTCompressionPropertyCameraCalibrationKey_LensDistortions, "kVTCompressionPropertyCameraCalibrationKey_LensDistortions"),
        (kVTCompressionPropertyCameraCalibrationKey_LensDomain, "kVTCompressionPropertyCameraCalibrationKey_LensDomain"),
        (kVTCompressionPropertyCameraCalibrationKey_LensFrameAdjustmentsPolynomialX, "kVTCompressionPropertyCameraCalibrationKey_LensFrameAdjustmentsPolynomialX"),
        (kVTCompressionPropertyCameraCalibrationKey_LensFrameAdjustmentsPolynomialY, "kVTCompressionPropertyCameraCalibrationKey_LensFrameAdjustmentsPolynomialY"),
        (kVTCompressionPropertyCameraCalibrationKey_LensIdentifier, "kVTCompressionPropertyCameraCalibrationKey_LensIdentifier"),
        (kVTCompressionPropertyCameraCalibrationKey_LensRole, "kVTCompressionPropertyCameraCalibrationKey_LensRole"),
        (kVTCompressionPropertyCameraCalibrationKey_RadialAngleLimit, "kVTCompressionPropertyCameraCalibrationKey_RadialAngleLimit"),
        (kVTCompressionPropertyKey_AllowFrameReordering, "kVTCompressionPropertyKey_AllowFrameReordering"),
        (kVTCompressionPropertyKey_AllowOpenGOP, "kVTCompressionPropertyKey_AllowOpenGOP"),
        (kVTCompressionPropertyKey_AllowTemporalCompression, "kVTCompressionPropertyKey_AllowTemporalCompression"),
        (kVTCompressionPropertyKey_AlphaChannelMode, "kVTCompressionPropertyKey_AlphaChannelMode"),
        (kVTCompressionPropertyKey_AspectRatio16x9, "kVTCompressionPropertyKey_AspectRatio16x9"),
        (kVTCompressionPropertyKey_AverageBitRate, "kVTCompressionPropertyKey_AverageBitRate"),
        (kVTCompressionPropertyKey_BaseLayerBitRateFraction, "kVTCompressionPropertyKey_BaseLayerBitRateFraction"),
        (kVTCompressionPropertyKey_BaseLayerFrameRate, "kVTCompressionPropertyKey_BaseLayerFrameRate"),
        (kVTCompressionPropertyKey_BaseLayerFrameRateFraction, "kVTCompressionPropertyKey_BaseLayerFrameRateFraction"),
        (kVTCompressionPropertyKey_CalculateMeanSquaredError, "kVTCompressionPropertyKey_CalculateMeanSquaredError"),
        (kVTCompressionPropertyKey_CameraCalibrationDataLensCollection, "kVTCompressionPropertyKey_CameraCalibrationDataLensCollection"),
        (kVTCompressionPropertyKey_CleanAperture, "kVTCompressionPropertyKey_CleanAperture"),
        (kVTCompressionPropertyKey_ColorPrimaries, "kVTCompressionPropertyKey_ColorPrimaries"),
        (kVTCompressionPropertyKey_ConstantBitRate, "kVTCompressionPropertyKey_ConstantBitRate"),
        (kVTCompressionPropertyKey_ContentLightLevelInfo, "kVTCompressionPropertyKey_ContentLightLevelInfo"),
        (kVTCompressionPropertyKey_DataRateLimits, "kVTCompressionPropertyKey_DataRateLimits"),
        (kVTCompressionPropertyKey_Depth, "kVTCompressionPropertyKey_Depth"),
        (kVTCompressionPropertyKey_EnableLTR, "kVTCompressionPropertyKey_EnableLTR"),
        (kVTCompressionPropertyKey_EncoderID, "kVTCompressionPropertyKey_EncoderID"),
        (kVTCompressionPropertyKey_EstimatedAverageBytesPerFrame, "kVTCompressionPropertyKey_EstimatedAverageBytesPerFrame"),
        (kVTCompressionPropertyKey_ExpectedDuration, "kVTCompressionPropertyKey_ExpectedDuration"),
        (kVTCompressionPropertyKey_ExpectedFrameRate, "kVTCompressionPropertyKey_ExpectedFrameRate"),
        (kVTCompressionPropertyKey_FieldCount, "kVTCompressionPropertyKey_FieldCount"),
        (kVTCompressionPropertyKey_FieldDetail, "kVTCompressionPropertyKey_FieldDetail"),
        (kVTCompressionPropertyKey_GammaLevel, "kVTCompressionPropertyKey_GammaLevel"),
        (kVTCompressionPropertyKey_H264EntropyMode, "kVTCompressionPropertyKey_H264EntropyMode"),
        (kVTCompressionPropertyKey_HDRMetadataInsertionMode, "kVTCompressionPropertyKey_HDRMetadataInsertionMode"),
        (kVTCompressionPropertyKey_HasLeftStereoEyeView, "kVTCompressionPropertyKey_HasLeftStereoEyeView"),
        (kVTCompressionPropertyKey_HasRightStereoEyeView, "kVTCompressionPropertyKey_HasRightStereoEyeView"),
        (kVTCompressionPropertyKey_HeroEye, "kVTCompressionPropertyKey_HeroEye"),
        (kVTCompressionPropertyKey_HorizontalDisparityAdjustment, "kVTCompressionPropertyKey_HorizontalDisparityAdjustment"),
        (kVTCompressionPropertyKey_HorizontalFieldOfView, "kVTCompressionPropertyKey_HorizontalFieldOfView"),
        (kVTCompressionPropertyKey_ICCProfile, "kVTCompressionPropertyKey_ICCProfile"),
        (kVTCompressionPropertyKey_MVHEVCLeftAndRightViewIDs, "kVTCompressionPropertyKey_MVHEVCLeftAndRightViewIDs"),
        (kVTCompressionPropertyKey_MVHEVCVideoLayerIDs, "kVTCompressionPropertyKey_MVHEVCVideoLayerIDs"),
        (kVTCompressionPropertyKey_MVHEVCViewIDs, "kVTCompressionPropertyKey_MVHEVCViewIDs"),
        (kVTCompressionPropertyKey_MasteringDisplayColorVolume, "kVTCompressionPropertyKey_MasteringDisplayColorVolume"),
        (kVTCompressionPropertyKey_MaxAllowedFrameQP, "kVTCompressionPropertyKey_MaxAllowedFrameQP"),
        (kVTCompressionPropertyKey_MaxFrameDelayCount, "kVTCompressionPropertyKey_MaxFrameDelayCount"),
        (kVTCompressionPropertyKey_MaxH264SliceBytes, "kVTCompressionPropertyKey_MaxH264SliceBytes"),
        (kVTCompressionPropertyKey_MaxKeyFrameInterval, "kVTCompressionPropertyKey_MaxKeyFrameInterval"),
        (kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration, "kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration"),
        (kVTCompressionPropertyKey_MaximizePowerEfficiency, "kVTCompressionPropertyKey_MaximizePowerEfficiency"),
        (kVTCompressionPropertyKey_MaximumRealTimeFrameRate, "kVTCompressionPropertyKey_MaximumRealTimeFrameRate"),
        (kVTCompressionPropertyKey_MinAllowedFrameQP, "kVTCompressionPropertyKey_MinAllowedFrameQP"),
        (kVTCompressionPropertyKey_MoreFramesAfterEnd, "kVTCompressionPropertyKey_MoreFramesAfterEnd"),
        (kVTCompressionPropertyKey_MoreFramesBeforeStart, "kVTCompressionPropertyKey_MoreFramesBeforeStart"),
        (kVTCompressionPropertyKey_MultiPassStorage, "kVTCompressionPropertyKey_MultiPassStorage"),
        (kVTCompressionPropertyKey_NumberOfPendingFrames, "kVTCompressionPropertyKey_NumberOfPendingFrames"),
        (kVTCompressionPropertyKey_OutputBitDepth, "kVTCompressionPropertyKey_OutputBitDepth"),
        (kVTCompressionPropertyKey_PixelAspectRatio, "kVTCompressionPropertyKey_PixelAspectRatio"),
        (kVTCompressionPropertyKey_PixelBufferPoolIsShared, "kVTCompressionPropertyKey_PixelBufferPoolIsShared"),
        (kVTCompressionPropertyKey_PixelTransferProperties, "kVTCompressionPropertyKey_PixelTransferProperties"),
        (kVTCompressionPropertyKey_PreserveAlphaChannel, "kVTCompressionPropertyKey_PreserveAlphaChannel"),
        (kVTCompressionPropertyKey_PreserveDynamicHDRMetadata, "kVTCompressionPropertyKey_PreserveDynamicHDRMetadata"),
        (kVTCompressionPropertyKey_PrioritizeEncodingSpeedOverQuality, "kVTCompressionPropertyKey_PrioritizeEncodingSpeedOverQuality"),
        (kVTCompressionPropertyKey_ProfileLevel, "kVTCompressionPropertyKey_ProfileLevel"),
        (kVTCompressionPropertyKey_ProgressiveScan, "kVTCompressionPropertyKey_ProgressiveScan"),
        (kVTCompressionPropertyKey_ProjectionKind, "kVTCompressionPropertyKey_ProjectionKind"),
        (kVTCompressionPropertyKey_Quality, "kVTCompressionPropertyKey_Quality"),
        (kVTCompressionPropertyKey_RealTime, "kVTCompressionPropertyKey_RealTime"),
        (kVTCompressionPropertyKey_RecommendedParallelizationLimit, "kVTCompressionPropertyKey_RecommendedParallelizationLimit"),
        (kVTCompressionPropertyKey_RecommendedParallelizedSubdivisionMinimumDuration, "kVTCompressionPropertyKey_RecommendedParallelizedSubdivisionMinimumDuration"),
        (kVTCompressionPropertyKey_RecommendedParallelizedSubdivisionMinimumFrameCount, "kVTCompressionPropertyKey_RecommendedParallelizedSubdivisionMinimumFrameCount"),
        (kVTCompressionPropertyKey_ReferenceBufferCount, "kVTCompressionPropertyKey_ReferenceBufferCount"),
        (kVTCompressionPropertyKey_SourceFrameCount, "kVTCompressionPropertyKey_SourceFrameCount"),
        (kVTCompressionPropertyKey_SpatialAdaptiveQPLevel, "kVTCompressionPropertyKey_SpatialAdaptiveQPLevel"),
        (kVTCompressionPropertyKey_StereoCameraBaseline, "kVTCompressionPropertyKey_StereoCameraBaseline"),
        (kVTCompressionPropertyKey_SuggestedLookAheadFrameCount, "kVTCompressionPropertyKey_SuggestedLookAheadFrameCount"),
        (kVTCompressionPropertyKey_SupportedPresetDictionaries, "kVTCompressionPropertyKey_SupportedPresetDictionaries"),
        (kVTCompressionPropertyKey_SupportsBaseFrameQP, "kVTCompressionPropertyKey_SupportsBaseFrameQP"),
        (kVTCompressionPropertyKey_TargetQualityForAlpha, "kVTCompressionPropertyKey_TargetQualityForAlpha"),
        (kVTCompressionPropertyKey_TransferFunction, "kVTCompressionPropertyKey_TransferFunction"),
        (kVTCompressionPropertyKey_UsingGPURegistryID, "kVTCompressionPropertyKey_UsingGPURegistryID"),
        (kVTCompressionPropertyKey_UsingHardwareAcceleratedVideoEncoder, "kVTCompressionPropertyKey_UsingHardwareAcceleratedVideoEncoder"),
        (kVTCompressionPropertyKey_VBVBufferDuration, "kVTCompressionPropertyKey_VBVBufferDuration"),
        (kVTCompressionPropertyKey_VBVInitialDelayPercentage, "kVTCompressionPropertyKey_VBVInitialDelayPercentage"),
        (kVTCompressionPropertyKey_VBVMaxBitRate, "kVTCompressionPropertyKey_VBVMaxBitRate"),
        (kVTCompressionPropertyKey_VariableBitRate, "kVTCompressionPropertyKey_VariableBitRate"),
        (kVTCompressionPropertyKey_VideoEncoderPixelBufferAttributes, "kVTCompressionPropertyKey_VideoEncoderPixelBufferAttributes"),
        (kVTCompressionPropertyKey_ViewPackingKind, "kVTCompressionPropertyKey_ViewPackingKind"),
        (kVTCompressionPropertyKey_YCbCrMatrix, "kVTCompressionPropertyKey_YCbCrMatrix"),
    ]
    var seen = Set<String>()
    vtExpect(!pairs.isEmpty, "nonempty key table")
    for (value, expected) in pairs {
        vtExpect(value == expected, "payload \(expected)")
        vtExpect(!value.isEmpty, "nonempty \(expected)")
        vtExpect(!seen.contains(value), "unique \(expected)")
        seen.insert(value)
    }
}

func testDecompressionPropertyKeyPayloads() {
    let pairs: [(String, String)] = [
        (kVTDecompressionPropertyKey_AllowBitstreamToChangeFrameDimensions, "kVTDecompressionPropertyKey_AllowBitstreamToChangeFrameDimensions"),
        (kVTDecompressionPropertyKey_ContentHasInterframeDependencies, "kVTDecompressionPropertyKey_ContentHasInterframeDependencies"),
        (kVTDecompressionPropertyKey_DecoderProducesRAWOutput, "kVTDecompressionPropertyKey_DecoderProducesRAWOutput"),
        (kVTDecompressionPropertyKey_DeinterlaceMode, "kVTDecompressionPropertyKey_DeinterlaceMode"),
        (kVTDecompressionPropertyKey_FieldMode, "kVTDecompressionPropertyKey_FieldMode"),
        (kVTDecompressionPropertyKey_GeneratePerFrameHDRDisplayMetadata, "kVTDecompressionPropertyKey_GeneratePerFrameHDRDisplayMetadata"),
        (kVTDecompressionPropertyKey_MaxOutputPresentationTimeStampOfFramesBeingDecoded, "kVTDecompressionPropertyKey_MaxOutputPresentationTimeStampOfFramesBeingDecoded"),
        (kVTDecompressionPropertyKey_MaximizePowerEfficiency, "kVTDecompressionPropertyKey_MaximizePowerEfficiency"),
        (kVTDecompressionPropertyKey_MinOutputPresentationTimeStampOfFramesBeingDecoded, "kVTDecompressionPropertyKey_MinOutputPresentationTimeStampOfFramesBeingDecoded"),
        (kVTDecompressionPropertyKey_NumberOfFramesBeingDecoded, "kVTDecompressionPropertyKey_NumberOfFramesBeingDecoded"),
        (kVTDecompressionPropertyKey_OnlyTheseFrames, "kVTDecompressionPropertyKey_OnlyTheseFrames"),
        (kVTDecompressionPropertyKey_OutputPoolRequestedMinimumBufferCount, "kVTDecompressionPropertyKey_OutputPoolRequestedMinimumBufferCount"),
        (kVTDecompressionPropertyKey_PixelBufferPool, "kVTDecompressionPropertyKey_PixelBufferPool"),
        (kVTDecompressionPropertyKey_PixelBufferPoolIsShared, "kVTDecompressionPropertyKey_PixelBufferPoolIsShared"),
        (kVTDecompressionPropertyKey_PixelFormatsWithReducedResolutionSupport, "kVTDecompressionPropertyKey_PixelFormatsWithReducedResolutionSupport"),
        (kVTDecompressionPropertyKey_PixelTransferProperties, "kVTDecompressionPropertyKey_PixelTransferProperties"),
        (kVTDecompressionPropertyKey_PropagatePerFrameHDRDisplayMetadata, "kVTDecompressionPropertyKey_PropagatePerFrameHDRDisplayMetadata"),
        (kVTDecompressionPropertyKey_RealTime, "kVTDecompressionPropertyKey_RealTime"),
        (kVTDecompressionPropertyKey_ReducedCoefficientDecode, "kVTDecompressionPropertyKey_ReducedCoefficientDecode"),
        (kVTDecompressionPropertyKey_ReducedFrameDelivery, "kVTDecompressionPropertyKey_ReducedFrameDelivery"),
        (kVTDecompressionPropertyKey_ReducedResolutionDecode, "kVTDecompressionPropertyKey_ReducedResolutionDecode"),
        (kVTDecompressionPropertyKey_RequestRAWOutput, "kVTDecompressionPropertyKey_RequestRAWOutput"),
        (kVTDecompressionPropertyKey_RequestedMVHEVCVideoLayerIDs, "kVTDecompressionPropertyKey_RequestedMVHEVCVideoLayerIDs"),
        (kVTDecompressionPropertyKey_SuggestedQualityOfServiceTiers, "kVTDecompressionPropertyKey_SuggestedQualityOfServiceTiers"),
        (kVTDecompressionPropertyKey_SupportedPixelFormatsOrderedByPerformance, "kVTDecompressionPropertyKey_SupportedPixelFormatsOrderedByPerformance"),
        (kVTDecompressionPropertyKey_SupportedPixelFormatsOrderedByQuality, "kVTDecompressionPropertyKey_SupportedPixelFormatsOrderedByQuality"),
        (kVTDecompressionPropertyKey_ThreadCount, "kVTDecompressionPropertyKey_ThreadCount"),
        (kVTDecompressionPropertyKey_UsingGPURegistryID, "kVTDecompressionPropertyKey_UsingGPURegistryID"),
        (kVTDecompressionPropertyKey_UsingHardwareAcceleratedVideoDecoder, "kVTDecompressionPropertyKey_UsingHardwareAcceleratedVideoDecoder"),
        (kVTDecompressionProperty_DeinterlaceMode_Temporal, "kVTDecompressionProperty_DeinterlaceMode_Temporal"),
        (kVTDecompressionProperty_DeinterlaceMode_VerticalFilter, "kVTDecompressionProperty_DeinterlaceMode_VerticalFilter"),
        (kVTDecompressionProperty_FieldMode_BothFields, "kVTDecompressionProperty_FieldMode_BothFields"),
        (kVTDecompressionProperty_FieldMode_BottomFieldOnly, "kVTDecompressionProperty_FieldMode_BottomFieldOnly"),
        (kVTDecompressionProperty_FieldMode_DeinterlaceFields, "kVTDecompressionProperty_FieldMode_DeinterlaceFields"),
        (kVTDecompressionProperty_FieldMode_SingleField, "kVTDecompressionProperty_FieldMode_SingleField"),
        (kVTDecompressionProperty_FieldMode_TopFieldOnly, "kVTDecompressionProperty_FieldMode_TopFieldOnly"),
        (kVTDecompressionProperty_OnlyTheseFrames_AllFrames, "kVTDecompressionProperty_OnlyTheseFrames_AllFrames"),
        (kVTDecompressionProperty_OnlyTheseFrames_IFrames, "kVTDecompressionProperty_OnlyTheseFrames_IFrames"),
        (kVTDecompressionProperty_OnlyTheseFrames_KeyFrames, "kVTDecompressionProperty_OnlyTheseFrames_KeyFrames"),
        (kVTDecompressionProperty_OnlyTheseFrames_NonDroppableFrames, "kVTDecompressionProperty_OnlyTheseFrames_NonDroppableFrames"),
        (kVTDecompressionProperty_TemporalLevelLimit, "kVTDecompressionProperty_TemporalLevelLimit"),
        (kVTDecompressionResolutionKey_Height, "kVTDecompressionResolutionKey_Height"),
        (kVTDecompressionResolutionKey_Width, "kVTDecompressionResolutionKey_Width"),
        (kVTVideoDecoderSpecification_EnableHardwareAcceleratedVideoDecoder, "kVTVideoDecoderSpecification_EnableHardwareAcceleratedVideoDecoder"),
        (kVTVideoDecoderSpecification_PreferredDecoderGPURegistryID, "kVTVideoDecoderSpecification_PreferredDecoderGPURegistryID"),
        (kVTVideoDecoderSpecification_RequireHardwareAcceleratedVideoDecoder, "kVTVideoDecoderSpecification_RequireHardwareAcceleratedVideoDecoder"),
        (kVTVideoDecoderSpecification_RequiredDecoderGPURegistryID, "kVTVideoDecoderSpecification_RequiredDecoderGPURegistryID"),
    ]
    var seen = Set<String>()
    vtExpect(!pairs.isEmpty, "nonempty key table")
    for (value, expected) in pairs {
        vtExpect(value == expected, "payload \(expected)")
        vtExpect(!value.isEmpty, "nonempty \(expected)")
        vtExpect(!seen.contains(value), "unique \(expected)")
        seen.insert(value)
    }
}

func testProfileLevelKeyPayloads() {
    let pairs: [(String, String)] = [
        (kVTProfileLevel_H263_Profile0_Level10, "kVTProfileLevel_H263_Profile0_Level10"),
        (kVTProfileLevel_H263_Profile0_Level45, "kVTProfileLevel_H263_Profile0_Level45"),
        (kVTProfileLevel_H263_Profile3_Level45, "kVTProfileLevel_H263_Profile3_Level45"),
        (kVTProfileLevel_H264_Baseline_1_3, "kVTProfileLevel_H264_Baseline_1_3"),
        (kVTProfileLevel_H264_Baseline_3_0, "kVTProfileLevel_H264_Baseline_3_0"),
        (kVTProfileLevel_H264_Baseline_3_1, "kVTProfileLevel_H264_Baseline_3_1"),
        (kVTProfileLevel_H264_Baseline_3_2, "kVTProfileLevel_H264_Baseline_3_2"),
        (kVTProfileLevel_H264_Baseline_4_0, "kVTProfileLevel_H264_Baseline_4_0"),
        (kVTProfileLevel_H264_Baseline_4_1, "kVTProfileLevel_H264_Baseline_4_1"),
        (kVTProfileLevel_H264_Baseline_4_2, "kVTProfileLevel_H264_Baseline_4_2"),
        (kVTProfileLevel_H264_Baseline_5_0, "kVTProfileLevel_H264_Baseline_5_0"),
        (kVTProfileLevel_H264_Baseline_5_1, "kVTProfileLevel_H264_Baseline_5_1"),
        (kVTProfileLevel_H264_Baseline_5_2, "kVTProfileLevel_H264_Baseline_5_2"),
        (kVTProfileLevel_H264_Baseline_AutoLevel, "kVTProfileLevel_H264_Baseline_AutoLevel"),
        (kVTProfileLevel_H264_ConstrainedBaseline_AutoLevel, "kVTProfileLevel_H264_ConstrainedBaseline_AutoLevel"),
        (kVTProfileLevel_H264_ConstrainedHigh_AutoLevel, "kVTProfileLevel_H264_ConstrainedHigh_AutoLevel"),
        (kVTProfileLevel_H264_Extended_5_0, "kVTProfileLevel_H264_Extended_5_0"),
        (kVTProfileLevel_H264_Extended_AutoLevel, "kVTProfileLevel_H264_Extended_AutoLevel"),
        (kVTProfileLevel_H264_High_3_0, "kVTProfileLevel_H264_High_3_0"),
        (kVTProfileLevel_H264_High_3_1, "kVTProfileLevel_H264_High_3_1"),
        (kVTProfileLevel_H264_High_3_2, "kVTProfileLevel_H264_High_3_2"),
        (kVTProfileLevel_H264_High_4_0, "kVTProfileLevel_H264_High_4_0"),
        (kVTProfileLevel_H264_High_4_1, "kVTProfileLevel_H264_High_4_1"),
        (kVTProfileLevel_H264_High_4_2, "kVTProfileLevel_H264_High_4_2"),
        (kVTProfileLevel_H264_High_5_0, "kVTProfileLevel_H264_High_5_0"),
        (kVTProfileLevel_H264_High_5_1, "kVTProfileLevel_H264_High_5_1"),
        (kVTProfileLevel_H264_High_5_2, "kVTProfileLevel_H264_High_5_2"),
        (kVTProfileLevel_H264_High_AutoLevel, "kVTProfileLevel_H264_High_AutoLevel"),
        (kVTProfileLevel_H264_Main_3_0, "kVTProfileLevel_H264_Main_3_0"),
        (kVTProfileLevel_H264_Main_3_1, "kVTProfileLevel_H264_Main_3_1"),
        (kVTProfileLevel_H264_Main_3_2, "kVTProfileLevel_H264_Main_3_2"),
        (kVTProfileLevel_H264_Main_4_0, "kVTProfileLevel_H264_Main_4_0"),
        (kVTProfileLevel_H264_Main_4_1, "kVTProfileLevel_H264_Main_4_1"),
        (kVTProfileLevel_H264_Main_4_2, "kVTProfileLevel_H264_Main_4_2"),
        (kVTProfileLevel_H264_Main_5_0, "kVTProfileLevel_H264_Main_5_0"),
        (kVTProfileLevel_H264_Main_5_1, "kVTProfileLevel_H264_Main_5_1"),
        (kVTProfileLevel_H264_Main_5_2, "kVTProfileLevel_H264_Main_5_2"),
        (kVTProfileLevel_H264_Main_AutoLevel, "kVTProfileLevel_H264_Main_AutoLevel"),
        (kVTProfileLevel_HEVC_Main10_AutoLevel, "kVTProfileLevel_HEVC_Main10_AutoLevel"),
        (kVTProfileLevel_HEVC_Main42210_AutoLevel, "kVTProfileLevel_HEVC_Main42210_AutoLevel"),
        (kVTProfileLevel_HEVC_Main_AutoLevel, "kVTProfileLevel_HEVC_Main_AutoLevel"),
        (kVTProfileLevel_HEVC_Monochrome10_AutoLevel, "kVTProfileLevel_HEVC_Monochrome10_AutoLevel"),
        (kVTProfileLevel_HEVC_Monochrome_AutoLevel, "kVTProfileLevel_HEVC_Monochrome_AutoLevel"),
        (kVTProfileLevel_MP4V_AdvancedSimple_L0, "kVTProfileLevel_MP4V_AdvancedSimple_L0"),
        (kVTProfileLevel_MP4V_AdvancedSimple_L1, "kVTProfileLevel_MP4V_AdvancedSimple_L1"),
        (kVTProfileLevel_MP4V_AdvancedSimple_L2, "kVTProfileLevel_MP4V_AdvancedSimple_L2"),
        (kVTProfileLevel_MP4V_AdvancedSimple_L3, "kVTProfileLevel_MP4V_AdvancedSimple_L3"),
        (kVTProfileLevel_MP4V_AdvancedSimple_L4, "kVTProfileLevel_MP4V_AdvancedSimple_L4"),
        (kVTProfileLevel_MP4V_Main_L2, "kVTProfileLevel_MP4V_Main_L2"),
        (kVTProfileLevel_MP4V_Main_L3, "kVTProfileLevel_MP4V_Main_L3"),
        (kVTProfileLevel_MP4V_Main_L4, "kVTProfileLevel_MP4V_Main_L4"),
        (kVTProfileLevel_MP4V_Simple_L0, "kVTProfileLevel_MP4V_Simple_L0"),
        (kVTProfileLevel_MP4V_Simple_L1, "kVTProfileLevel_MP4V_Simple_L1"),
        (kVTProfileLevel_MP4V_Simple_L2, "kVTProfileLevel_MP4V_Simple_L2"),
        (kVTProfileLevel_MP4V_Simple_L3, "kVTProfileLevel_MP4V_Simple_L3"),
    ]
    var seen = Set<String>()
    vtExpect(!pairs.isEmpty, "nonempty key table")
    for (value, expected) in pairs {
        vtExpect(value == expected, "payload \(expected)")
        vtExpect(!value.isEmpty, "nonempty \(expected)")
        vtExpect(!seen.contains(value), "unique \(expected)")
        seen.insert(value)
    }
}

func testPixelTransferAndRotationKeyPayloads() {
    let pairs: [(String, String)] = [
        (kVTDownsamplingMode_Average, "kVTDownsamplingMode_Average"),
        (kVTDownsamplingMode_Decimate, "kVTDownsamplingMode_Decimate"),
        (kVTPixelRotationPropertyKey_FlipHorizontalOrientation, "kVTPixelRotationPropertyKey_FlipHorizontalOrientation"),
        (kVTPixelRotationPropertyKey_FlipVerticalOrientation, "kVTPixelRotationPropertyKey_FlipVerticalOrientation"),
        (kVTPixelRotationPropertyKey_Rotation, "kVTPixelRotationPropertyKey_Rotation"),
        (kVTPixelTransferPropertyKey_DestinationCleanAperture, "kVTPixelTransferPropertyKey_DestinationCleanAperture"),
        (kVTPixelTransferPropertyKey_DestinationColorPrimaries, "kVTPixelTransferPropertyKey_DestinationColorPrimaries"),
        (kVTPixelTransferPropertyKey_DestinationICCProfile, "kVTPixelTransferPropertyKey_DestinationICCProfile"),
        (kVTPixelTransferPropertyKey_DestinationPixelAspectRatio, "kVTPixelTransferPropertyKey_DestinationPixelAspectRatio"),
        (kVTPixelTransferPropertyKey_DestinationTransferFunction, "kVTPixelTransferPropertyKey_DestinationTransferFunction"),
        (kVTPixelTransferPropertyKey_DestinationYCbCrMatrix, "kVTPixelTransferPropertyKey_DestinationYCbCrMatrix"),
        (kVTPixelTransferPropertyKey_DownsamplingMode, "kVTPixelTransferPropertyKey_DownsamplingMode"),
        (kVTPixelTransferPropertyKey_RealTime, "kVTPixelTransferPropertyKey_RealTime"),
        (kVTPixelTransferPropertyKey_ScalingMode, "kVTPixelTransferPropertyKey_ScalingMode"),
        (kVTRotation_0, "kVTRotation_0"),
        (kVTRotation_180, "kVTRotation_180"),
        (kVTRotation_CCW90, "kVTRotation_CCW90"),
        (kVTRotation_CW90, "kVTRotation_CW90"),
        (kVTScalingMode_CropSourceToCleanAperture, "kVTScalingMode_CropSourceToCleanAperture"),
        (kVTScalingMode_Letterbox, "kVTScalingMode_Letterbox"),
        (kVTScalingMode_Normal, "kVTScalingMode_Normal"),
        (kVTScalingMode_Trim, "kVTScalingMode_Trim"),
    ]
    var seen = Set<String>()
    vtExpect(!pairs.isEmpty, "nonempty key table")
    for (value, expected) in pairs {
        vtExpect(value == expected, "payload \(expected)")
        vtExpect(!value.isEmpty, "nonempty \(expected)")
        vtExpect(!seen.contains(value), "unique \(expected)")
        seen.insert(value)
    }
}

func testRAWProcessorKeyPayloads() {
    let pairs: [(String, String)] = [
        (kVTRAWProcessingParameterListElement_Description, "kVTRAWProcessingParameterListElement_Description"),
        (kVTRAWProcessingParameterListElement_Label, "kVTRAWProcessingParameterListElement_Label"),
        (kVTRAWProcessingParameterListElement_ListElementID, "kVTRAWProcessingParameterListElement_ListElementID"),
        (kVTRAWProcessingParameterValueType_Boolean, "kVTRAWProcessingParameterValueType_Boolean"),
        (kVTRAWProcessingParameterValueType_Float, "kVTRAWProcessingParameterValueType_Float"),
        (kVTRAWProcessingParameterValueType_Integer, "kVTRAWProcessingParameterValueType_Integer"),
        (kVTRAWProcessingParameterValueType_List, "kVTRAWProcessingParameterValueType_List"),
        (kVTRAWProcessingParameterValueType_SubGroup, "kVTRAWProcessingParameterValueType_SubGroup"),
        (kVTRAWProcessingParameter_CameraValue, "kVTRAWProcessingParameter_CameraValue"),
        (kVTRAWProcessingParameter_CurrentValue, "kVTRAWProcessingParameter_CurrentValue"),
        (kVTRAWProcessingParameter_Description, "kVTRAWProcessingParameter_Description"),
        (kVTRAWProcessingParameter_Enabled, "kVTRAWProcessingParameter_Enabled"),
        (kVTRAWProcessingParameter_InitialValue, "kVTRAWProcessingParameter_InitialValue"),
        (kVTRAWProcessingParameter_Key, "kVTRAWProcessingParameter_Key"),
        (kVTRAWProcessingParameter_ListArray, "kVTRAWProcessingParameter_ListArray"),
        (kVTRAWProcessingParameter_MaximumValue, "kVTRAWProcessingParameter_MaximumValue"),
        (kVTRAWProcessingParameter_MinimumValue, "kVTRAWProcessingParameter_MinimumValue"),
        (kVTRAWProcessingParameter_Name, "kVTRAWProcessingParameter_Name"),
        (kVTRAWProcessingParameter_NeutralValue, "kVTRAWProcessingParameter_NeutralValue"),
        (kVTRAWProcessingParameter_SubGroup, "kVTRAWProcessingParameter_SubGroup"),
        (kVTRAWProcessingParameter_ValueType, "kVTRAWProcessingParameter_ValueType"),
        (kVTRAWProcessingPropertyKey_MetadataForSidecarFile, "kVTRAWProcessingPropertyKey_MetadataForSidecarFile"),
        (kVTRAWProcessingPropertyKey_MetalDeviceRegistryID, "kVTRAWProcessingPropertyKey_MetalDeviceRegistryID"),
        (kVTRAWProcessingPropertyKey_OutputColorAttachments, "kVTRAWProcessingPropertyKey_OutputColorAttachments"),
    ]
    var seen = Set<String>()
    vtExpect(!pairs.isEmpty, "nonempty key table")
    for (value, expected) in pairs {
        vtExpect(value == expected, "payload \(expected)")
        vtExpect(!value.isEmpty, "nonempty \(expected)")
        vtExpect(!seen.contains(value), "unique \(expected)")
        seen.insert(value)
    }
}

func testEncoderListAndSpecificationKeyPayloads() {
    let pairs: [(String, String)] = [
        (kVTVideoEncoderListOption_IncludeStandardDefinitionDVEncoders, "kVTVideoEncoderListOption_IncludeStandardDefinitionDVEncoders"),
        (kVTVideoEncoderList_CodecName, "kVTVideoEncoderList_CodecName"),
        (kVTVideoEncoderList_CodecType, "kVTVideoEncoderList_CodecType"),
        (kVTVideoEncoderList_DisplayName, "kVTVideoEncoderList_DisplayName"),
        (kVTVideoEncoderList_EncoderID, "kVTVideoEncoderList_EncoderID"),
        (kVTVideoEncoderList_EncoderName, "kVTVideoEncoderList_EncoderName"),
        (kVTVideoEncoderList_GPURegistryID, "kVTVideoEncoderList_GPURegistryID"),
        (kVTVideoEncoderList_InstanceLimit, "kVTVideoEncoderList_InstanceLimit"),
        (kVTVideoEncoderList_IsHardwareAccelerated, "kVTVideoEncoderList_IsHardwareAccelerated"),
        (kVTVideoEncoderList_PerformanceRating, "kVTVideoEncoderList_PerformanceRating"),
        (kVTVideoEncoderList_QualityRating, "kVTVideoEncoderList_QualityRating"),
        (kVTVideoEncoderList_SupportedSelectionProperties, "kVTVideoEncoderList_SupportedSelectionProperties"),
        (kVTVideoEncoderList_SupportsFrameReordering, "kVTVideoEncoderList_SupportsFrameReordering"),
        (kVTVideoEncoderSpecification_EnableHardwareAcceleratedVideoEncoder, "kVTVideoEncoderSpecification_EnableHardwareAcceleratedVideoEncoder"),
        (kVTVideoEncoderSpecification_EnableLowLatencyRateControl, "kVTVideoEncoderSpecification_EnableLowLatencyRateControl"),
        (kVTVideoEncoderSpecification_EncoderID, "kVTVideoEncoderSpecification_EncoderID"),
        (kVTVideoEncoderSpecification_PreferredEncoderGPURegistryID, "kVTVideoEncoderSpecification_PreferredEncoderGPURegistryID"),
        (kVTVideoEncoderSpecification_RequireHardwareAcceleratedVideoEncoder, "kVTVideoEncoderSpecification_RequireHardwareAcceleratedVideoEncoder"),
        (kVTVideoEncoderSpecification_RequiredEncoderGPURegistryID, "kVTVideoEncoderSpecification_RequiredEncoderGPURegistryID"),
    ]
    var seen = Set<String>()
    vtExpect(!pairs.isEmpty, "nonempty key table")
    for (value, expected) in pairs {
        vtExpect(value == expected, "payload \(expected)")
        vtExpect(!value.isEmpty, "nonempty \(expected)")
        vtExpect(!seen.contains(value), "unique \(expected)")
        seen.insert(value)
    }
}

func testRemainingPropertyKeyPayloads() {
    let pairs: [(String, String)] = [
        (kVTAlphaChannelMode_PremultipliedAlpha, "kVTAlphaChannelMode_PremultipliedAlpha"),
        (kVTAlphaChannelMode_StraightAlpha, "kVTAlphaChannelMode_StraightAlpha"),
        (kVTCameraCalibrationExtrinsicOriginSource_StereoCameraSystemBaseline, "kVTCameraCalibrationExtrinsicOriginSource_StereoCameraSystemBaseline"),
        (kVTCameraCalibrationLensAlgorithmKind_ParametricLens, "kVTCameraCalibrationLensAlgorithmKind_ParametricLens"),
        (kVTCameraCalibrationLensDomain_Color, "kVTCameraCalibrationLensDomain_Color"),
        (kVTCameraCalibrationLensRole_Left, "kVTCameraCalibrationLensRole_Left"),
        (kVTCameraCalibrationLensRole_Mono, "kVTCameraCalibrationLensRole_Mono"),
        (kVTCameraCalibrationLensRole_Right, "kVTCameraCalibrationLensRole_Right"),
        (kVTDecodeFrameOptionKey_ContentAnalyzerCropRectangle, "kVTDecodeFrameOptionKey_ContentAnalyzerCropRectangle"),
        (kVTDecodeFrameOptionKey_ContentAnalyzerRotation, "kVTDecodeFrameOptionKey_ContentAnalyzerRotation"),
        (kVTEncodeFrameOptionKey_AcknowledgedLTRTokens, "kVTEncodeFrameOptionKey_AcknowledgedLTRTokens"),
        (kVTEncodeFrameOptionKey_BaseFrameQP, "kVTEncodeFrameOptionKey_BaseFrameQP"),
        (kVTEncodeFrameOptionKey_ForceKeyFrame, "kVTEncodeFrameOptionKey_ForceKeyFrame"),
        (kVTEncodeFrameOptionKey_ForceLTRRefresh, "kVTEncodeFrameOptionKey_ForceLTRRefresh"),
        (kVTExtensionProperties_CodecNameKey, "kVTExtensionProperties_CodecNameKey"),
        (kVTExtensionProperties_ContainingBundleNameKey, "kVTExtensionProperties_ContainingBundleNameKey"),
        (kVTExtensionProperties_ContainingBundleURLKey, "kVTExtensionProperties_ContainingBundleURLKey"),
        (kVTExtensionProperties_ExtensionIdentifierKey, "kVTExtensionProperties_ExtensionIdentifierKey"),
        (kVTExtensionProperties_ExtensionNameKey, "kVTExtensionProperties_ExtensionNameKey"),
        (kVTExtensionProperties_ExtensionURLKey, "kVTExtensionProperties_ExtensionURLKey"),
        (kVTH264EntropyMode_CABAC, "kVTH264EntropyMode_CABAC"),
        (kVTH264EntropyMode_CAVLC, "kVTH264EntropyMode_CAVLC"),
        (kVTHDRMetadataInsertionMode_Auto, "kVTHDRMetadataInsertionMode_Auto"),
        (kVTHDRMetadataInsertionMode_None, "kVTHDRMetadataInsertionMode_None"),
        (kVTHDRMetadataInsertionMode_RequestSDRRangePreservation, "kVTHDRMetadataInsertionMode_RequestSDRRangePreservation"),
        (kVTHDRPerFrameMetadataGenerationHDRFormatType_DolbyVision, "kVTHDRPerFrameMetadataGenerationHDRFormatType_DolbyVision"),
        (kVTHDRPerFrameMetadataGenerationOptionsKey_HDRFormats, "kVTHDRPerFrameMetadataGenerationOptionsKey_HDRFormats"),
        (kVTHeroEye_Left, "kVTHeroEye_Left"),
        (kVTHeroEye_Right, "kVTHeroEye_Right"),
        (kVTMotionEstimationSessionCreationOption_Label, "kVTMotionEstimationSessionCreationOption_Label"),
        (kVTMotionEstimationSessionCreationOption_MotionVectorSize, "kVTMotionEstimationSessionCreationOption_MotionVectorSize"),
        (kVTMotionEstimationSessionCreationOption_UseMultiPassSearch, "kVTMotionEstimationSessionCreationOption_UseMultiPassSearch"),
        (kVTMultiPassStorageCreationOption_DoNotDelete, "kVTMultiPassStorageCreationOption_DoNotDelete"),
        (kVTProjectionKind_Equirectangular, "kVTProjectionKind_Equirectangular"),
        (kVTProjectionKind_HalfEquirectangular, "kVTProjectionKind_HalfEquirectangular"),
        (kVTProjectionKind_ParametricImmersive, "kVTProjectionKind_ParametricImmersive"),
        (kVTProjectionKind_Rectilinear, "kVTProjectionKind_Rectilinear"),
        (kVTPropertyDocumentationKey, "kVTPropertyDocumentationKey"),
        (kVTPropertyReadWriteStatusKey, "kVTPropertyReadWriteStatusKey"),
        (kVTPropertyReadWriteStatus_ReadOnly, "kVTPropertyReadWriteStatus_ReadOnly"),
        (kVTPropertyReadWriteStatus_ReadWrite, "kVTPropertyReadWriteStatus_ReadWrite"),
        (kVTPropertyShouldBeSerializedKey, "kVTPropertyShouldBeSerializedKey"),
        (kVTPropertySupportedValueListKey, "kVTPropertySupportedValueListKey"),
        (kVTPropertySupportedValueMaximumKey, "kVTPropertySupportedValueMaximumKey"),
        (kVTPropertySupportedValueMinimumKey, "kVTPropertySupportedValueMinimumKey"),
        (kVTPropertyTypeKey, "kVTPropertyTypeKey"),
        (kVTPropertyType_Boolean, "kVTPropertyType_Boolean"),
        (kVTPropertyType_Enumeration, "kVTPropertyType_Enumeration"),
        (kVTPropertyType_Number, "kVTPropertyType_Number"),
        (kVTSampleAttachmentKey_QualityMetrics, "kVTSampleAttachmentKey_QualityMetrics"),
        (kVTSampleAttachmentKey_RequireLTRAcknowledgementToken, "kVTSampleAttachmentKey_RequireLTRAcknowledgementToken"),
        (kVTSampleAttachmentQualityMetricsKey_ChromaBlueMeanSquaredError, "kVTSampleAttachmentQualityMetricsKey_ChromaBlueMeanSquaredError"),
        (kVTSampleAttachmentQualityMetricsKey_ChromaRedMeanSquaredError, "kVTSampleAttachmentQualityMetricsKey_ChromaRedMeanSquaredError"),
        (kVTSampleAttachmentQualityMetricsKey_LumaMeanSquaredError, "kVTSampleAttachmentQualityMetricsKey_LumaMeanSquaredError"),
        (kVTViewPackingKind_OverUnder, "kVTViewPackingKind_OverUnder"),
        (kVTViewPackingKind_SideBySide, "kVTViewPackingKind_SideBySide"),
    ]
    var seen = Set<String>()
    vtExpect(!pairs.isEmpty, "nonempty key table")
    for (value, expected) in pairs {
        vtExpect(value == expected, "payload \(expected)")
        vtExpect(!value.isEmpty, "nonempty \(expected)")
        vtExpect(!seen.contains(value), "unique \(expected)")
        seen.insert(value)
    }
}

// --- VideoToolboxTypealiasTests.swift ---

func testSessionRefTypealiases() {
    vtExpect(MemoryLayout<VTSessionRef>.size == MemoryLayout<OpaquePointer>.size, "VTSessionRef")
    vtExpect(MemoryLayout<VTFrameSiloRef>.size == MemoryLayout<OpaquePointer>.size, "VTFrameSiloRef")
    vtExpect(MemoryLayout<VTMultiPassStorageRef>.size == MemoryLayout<OpaquePointer>.size, "VTMultiPassStorageRef")
    vtExpect(MemoryLayout<VTCompressionSessionRef>.size == MemoryLayout<OpaquePointer>.size, "VTCompressionSessionRef")
    vtExpect(MemoryLayout<VTDecompressionSessionRef>.size == MemoryLayout<OpaquePointer>.size, "VTDecompressionSessionRef")
    vtExpect(MemoryLayout<VTPixelRotationSessionRef>.size == MemoryLayout<OpaquePointer>.size, "VTPixelRotationSessionRef")
    vtExpect(MemoryLayout<VTPixelTransferSessionRef>.size == MemoryLayout<OpaquePointer>.size, "VTPixelTransferSessionRef")
    vtExpect(MemoryLayout<VTRAWProcessingSessionRef>.size == MemoryLayout<OpaquePointer>.size, "VTRAWProcessingSessionRef")
    vtExpect(MemoryLayout<VTMotionEstimationSessionRef>.size == MemoryLayout<OpaquePointer>.size, "VTMotionEstimationSessionRef")
    vtExpect(MemoryLayout<VTHDRPerFrameMetadataGenerationSessionRef>.size == MemoryLayout<OpaquePointer>.size, "VTHDRPerFrameMetadataGenerationSessionRef")
    vtExpect(MemoryLayout<OSStatus>.size == MemoryLayout<Int32>.size, "OSStatus")
    _ = VTSessionRef.self
    _ = VTFrameSiloRef.self
    _ = VTMultiPassStorageRef.self
    _ = VTCompressionSessionRef.self
    _ = VTDecompressionSessionRef.self
    _ = VTPixelRotationSessionRef.self
    _ = VTPixelTransferSessionRef.self
    _ = VTRAWProcessingSessionRef.self
    _ = VTMotionEstimationSessionRef.self
    _ = VTHDRPerFrameMetadataGenerationSessionRef.self
    _ = OSStatus.self
}

// --- VideoToolboxCompressionTests.swift ---

func testCompressionSessionFailClosed() {
    var compression: OpaquePointer?
    let compressionStatus = VTCompressionSessionCreate(
        width: 1280,
        height: 720,
        codecType: kVTVideoCodecType_H264,
        sessionOut: &compression
    )
    vtExpectStatus(compressionStatus, kVTCouldNotFindVideoEncoderErr, "VTCompressionSessionCreate h264")
    vtExpect(compression == nil, "compression session nil")

    var jpegEncoder: OpaquePointer?
    vtExpectStatus(
        VTCompressionSessionCreate(
            width: 64,
            height: 64,
            codecType: kVTVideoCodecType_JPEG,
            sessionOut: &jpegEncoder
        ),
        kVTCouldNotFindVideoEncoderErr,
        "VTCompressionSessionCreate jpeg"
    )

    var hevc: OpaquePointer?
    vtExpectStatus(
        VTCompressionSessionCreate(width: 1920, height: 1080, codecType: kVTVideoCodecType_HEVC, sessionOut: &hevc),
        kVTCouldNotFindVideoEncoderErr,
        "VTCompressionSessionCreate hevc"
    )

    var badSize: OpaquePointer?
    vtExpectStatus(
        VTCompressionSessionCreate(width: 0, height: 720, codecType: kVTVideoCodecType_H264, sessionOut: &badSize),
        kVTParameterErr,
        "VTCompressionSessionCreate parameter"
    )

    vtExpectStatus(VTCompressionSessionEncodeFrame(nil), kVTInvalidSessionErr, "VTCompressionSessionEncodeFrame nil")
    vtExpectStatus(VTCompressionSessionCompleteFrames(nil), kVTInvalidSessionErr, "VTCompressionSessionCompleteFrames nil")
    vtExpectStatus(VTCompressionSessionPrepareToEncodeFrames(nil), kVTInvalidSessionErr, "VTCompressionSessionPrepareToEncodeFrames nil")
    vtExpect(VTCompressionSessionGetPixelBufferPool(nil) == nil, "VTCompressionSessionGetPixelBufferPool nil")
    vtExpectStatus(VTCompressionSessionBeginPass(nil, flags: []), kVTInvalidSessionErr, "VTCompressionSessionBeginPass nil")
    var further = true
    vtExpectStatus(VTCompressionSessionEndPass(nil, furtherPassesRequestedOut: &further), kVTInvalidSessionErr, "VTCompressionSessionEndPass nil")
    vtExpect(!further, "further false")
    vtExpectStatus(VTCompressionSessionGetTimeRangesForNextPass(nil), kVTInvalidSessionErr, "VTCompressionSessionGetTimeRangesForNextPass nil")
    vtExpectStatus(VTCompressionSessionEncodeMultiImageFrame(nil), kVTInvalidSessionErr, "VTCompressionSessionEncodeMultiImageFrame")
    vtExpectStatus(VTCompressionSessionEncodeMultiImageFrameWithOutputHandler(nil), kVTInvalidSessionErr, "VTCompressionSessionEncodeMultiImageFrameWithOutputHandler")
    VTCompressionSessionInvalidate(nil)
}

// --- VideoToolboxDecompressionTests.swift ---

func testUncompressedPassthroughDecoder() {
    var missingFormat: OpaquePointer?
    vtExpectStatus(
        VTDecompressionSessionCreate(sessionOut: &missingFormat),
        kVTParameterErr,
        "VTDecompressionSessionCreate needs format"
    )

    var sourceBGRA: OpaquePointer?
    vtExpectStatus(
        VTHostCreatePixelBuffer(width: 4, height: 4, pixelFormat: kVTPixelFormat_32BGRA, pixelBufferOut: &sourceBGRA),
        0,
        "source bgra"
    )
    vtExpectStatus(VTHostFillPixelBuffer(sourceBGRA, red: 10, green: 20, blue: 30, alpha: 255), 0, "fill source")

    let bgraFormat = VTVideoFormatDescription(codecType: kVTPixelFormat_32BGRA, width: 4, height: 4)
    let box = VTTestBox()
    var decoder: OpaquePointer?
    vtExpectStatus(
        VTDecompressionSessionCreate(
            formatDescription: bgraFormat,
            destinationPixelFormat: kVTPixelFormat_32BGRA,
            outputCallback: { status, info, image, pts, duration, _ in
                vtExpect(status == 0, "callback status")
                vtExpect(info.contains(.imageBufferModifiable), "modifiable flag")
                box.image = image
                box.pts = pts
                box.duration = duration
                box.count += 1
            },
            sessionOut: &decoder
        ),
        0,
        "VTDecompressionSessionCreate bgra"
    )
    vtExpect(decoder != nil, "decoder session")

    let pts = VTMediaTime(value: 1001, timescale: 30)
    let duration = VTMediaTime(value: 1, timescale: 30)
    var sample: OpaquePointer?
    vtExpectStatus(
        VTHostCreateSampleBuffer(
            format: bgraFormat,
            pixelBuffer: sourceBGRA,
            presentationTimeStamp: pts,
            duration: duration,
            sampleBufferOut: &sample
        ),
        0,
        "sample"
    )

    vtExpectStatus(VTDecompressionSessionDecodeFrame(nil), kVTInvalidSessionErr, "VTDecompressionSessionDecodeFrame nil")
    var infoFlags = VTDecodeInfoFlags(rawValue: 0)
    vtExpectStatus(
        VTDecompressionSessionDecodeFrame(
            decoder,
            sampleBuffer: sample,
            decodeFlags: [],
            sourceFrameRefCon: nil,
            infoFlagsOut: &infoFlags
        ),
        0,
        "VTDecompressionSessionDecodeFrame passthrough"
    )
    vtExpect(box.count == 1, "sync callback")
    vtExpect(box.pts == pts, "pts forwarded")
    vtExpect(box.duration == duration, "duration forwarded")
    vtExpect(box.image != nil, "decoded image")
    vtExpect(VTHostPixelBufferGetByte(box.image, x: 1, y: 1, channel: 0) == 10, "passthrough red")
    vtExpect(VTHostPixelBufferGetByte(box.image, x: 1, y: 1, channel: 2) == 30, "passthrough blue")

    vtExpect(!VTDecompressionSessionCanAcceptFormatDescription(decoder), "VTDecompressionSessionCanAcceptFormatDescription nil format")
    vtExpect(
        VTDecompressionSessionCanAcceptFormatDescription(decoder, formatDescription: bgraFormat),
        "accept same"
    )
    vtExpect(
        !VTDecompressionSessionCanAcceptFormatDescription(
            decoder,
            formatDescription: VTVideoFormatDescription(codecType: kVTPixelFormat_32BGRA, width: 8, height: 4)
        ),
        "reject size change"
    )
    vtExpectStatus(
        VTSessionSetProperty(decoder, key: kVTDecompressionPropertyKey_AllowBitstreamToChangeFrameDimensions, value: "true"),
        0,
        "allow size change"
    )
    vtExpect(
        VTDecompressionSessionCanAcceptFormatDescription(
            decoder,
            formatDescription: VTVideoFormatDescription(codecType: kVTPixelFormat_32BGRA, width: 8, height: 4)
        ),
        "accept size change after property"
    )

    var black: OpaquePointer?
    vtExpectStatus(VTDecompressionSessionCopyBlackPixelBuffer(decoder, pixelBufferOut: &black), 0, "VTDecompressionSessionCopyBlackPixelBuffer")
    vtExpect(VTHostPixelBufferGetByte(black, x: 0, y: 0, channel: 0) == 0, "black r")
    vtExpectStatus(VTDecompressionSessionFinishDelayedFrames(decoder), 0, "VTDecompressionSessionFinishDelayedFrames")
    vtExpectStatus(VTDecompressionSessionWaitForAsynchronousFrames(decoder), 0, "VTDecompressionSessionWaitForAsynchronousFrames idle")

    var dropInfo = VTDecodeInfoFlags(rawValue: 0)
    vtExpectStatus(
        VTDecompressionSessionDecodeFrame(
            decoder,
            sampleBuffer: sample,
            decodeFlags: .doNotOutputFrame,
            sourceFrameRefCon: nil,
            infoFlagsOut: &dropInfo
        ),
        0,
        "drop"
    )
    vtExpect(dropInfo.contains(.frameDropped), "dropped flag")
    vtExpect(box.count == 1, "no extra callback")

    var asyncInfo = VTDecodeInfoFlags(rawValue: 0)
    vtExpectStatus(
        VTDecompressionSessionDecodeFrame(
            decoder,
            sampleBuffer: sample,
            decodeFlags: .enableAsynchronousDecompression,
            sourceFrameRefCon: nil,
            infoFlagsOut: &asyncInfo
        ),
        0,
        "async decode"
    )
    vtExpect(asyncInfo.contains(.asynchronous), "async info")
    vtExpectStatus(VTDecompressionSessionWaitForAsynchronousFrames(decoder), 0, "wait async")
    vtExpect(box.count == 2, "async callback delivered")

    vtExpectStatus(VTDecompressionSessionDecodeFrameWithOutputHandler(nil), kVTInvalidSessionErr, "VTDecompressionSessionDecodeFrameWithOutputHandler nil")
    var handlerInfo = VTDecodeInfoFlags(rawValue: 0)
    vtExpectStatus(
        VTDecompressionSessionDecodeFrameWithOutputHandler(
            decoder,
            sampleBuffer: sample,
            decodeFlags: [],
            infoFlagsOut: &handlerInfo,
            outputHandler: { status, _, image, _, _, _ in
                vtExpect(status == 0, "handler status")
                vtExpect(image != nil, "handler image")
                box.handlerCalled = true
            }
        ),
        0,
        "VTDecompressionSessionDecodeFrameWithOutputHandler"
    )
    vtExpect(box.handlerCalled, "handler called")

    VTDecompressionSessionInvalidate(decoder)
    vtExpectStatus(VTDecompressionSessionFinishDelayedFrames(decoder), kVTInvalidSessionErr, "invalid after VTDecompressionSessionInvalidate")
}

func testDecompressionFailClosedAndStubs() {
    var h264Decoder: OpaquePointer?
    let h264Format = VTVideoFormatDescription(codecType: kVTVideoCodecType_H264, width: 1280, height: 720)
    vtExpectStatus(
        VTDecompressionSessionCreate(formatDescription: h264Format, outputCallback: nil, sessionOut: &h264Decoder),
        kVTCouldNotFindVideoDecoderErr,
        "h264 decoder missing"
    )
    vtExpect(h264Decoder == nil, "h264 decoder nil")

    var hevcDecoder: OpaquePointer?
    vtExpectStatus(
        VTDecompressionSessionCreate(
            formatDescription: VTVideoFormatDescription(codecType: kVTVideoCodecType_HEVC, width: 64, height: 64),
            outputCallback: nil,
            sessionOut: &hevcDecoder
        ),
        kVTCouldNotFindVideoDecoderErr,
        "hevc decoder missing"
    )

    var jpegDecoder: OpaquePointer?
    vtExpectStatus(
        VTDecompressionSessionCreate(
            formatDescription: VTVideoFormatDescription(codecType: kVTVideoCodecType_JPEG, width: 64, height: 64),
            outputCallback: nil,
            sessionOut: &jpegDecoder
        ),
        kVTCouldNotFindVideoDecoderErr,
        "jpeg decoder unreachable"
    )

    vtExpectStatus(
        VTDecompressionSessionDecodeFrameWithMultiImageCapableOutputHandler(nil),
        kVTInvalidSessionErr,
        "VTDecompressionSessionDecodeFrameWithMultiImageCapableOutputHandler"
    )
    vtExpectStatus(VTDecompressionSessionDecodeFrameWithOptions(nil), kVTInvalidSessionErr, "VTDecompressionSessionDecodeFrameWithOptions")
    vtExpectStatus(
        VTDecompressionSessionDecodeFrameWithOptionsAndOutputHandler(nil),
        kVTInvalidSessionErr,
        "VTDecompressionSessionDecodeFrameWithOptionsAndOutputHandler"
    )

    let bgraFormat = VTVideoFormatDescription(codecType: kVTPixelFormat_32BGRA, width: 4, height: 4)
    var decoder: OpaquePointer?
    vtExpectStatus(
        VTDecompressionSessionCreate(formatDescription: bgraFormat, outputCallback: nil, sessionOut: &decoder),
        0,
        "stub decoder"
    )
    vtExpectStatus(VTDecompressionSessionSetMultiImageCallback(decoder), kVTPropertyNotSupportedErr, "VTDecompressionSessionSetMultiImageCallback")
    VTDecompressionSessionInvalidate(decoder)
}

// --- VideoToolboxSessionPropertyTests.swift ---

func testSessionPropertyRoundTrip() {
    var transfer: OpaquePointer?
    vtExpectStatus(VTPixelTransferSessionCreate(sessionOut: &transfer), 0, "property fixture")
    vtExpectStatus(
        VTSessionSetProperty(transfer, key: kVTPixelTransferPropertyKey_ScalingMode, value: kVTScalingMode_Trim),
        0,
        "VTSessionSetProperty"
    )
    var copied: String?
    vtExpectStatus(
        VTSessionCopyProperty(transfer, key: kVTPixelTransferPropertyKey_ScalingMode, valueOut: &copied),
        0,
        "VTSessionCopyProperty"
    )
    vtExpect(copied == kVTScalingMode_Trim, "copied scaling mode")
    vtExpectStatus(
        VTSessionSetProperty(transfer, key: kVTPixelTransferPropertyKey_ScalingMode, value: "not-a-mode"),
        kVTParameterErr,
        "bad scaling"
    )
    vtExpectStatus(
        VTSessionSetProperties(transfer, properties: [kVTPixelTransferPropertyKey_ScalingMode: kVTScalingMode_Normal]),
        0,
        "VTSessionSetProperties"
    )
    copied = nil
    vtExpectStatus(
        VTSessionCopyProperty(transfer, key: kVTPixelTransferPropertyKey_ScalingMode, valueOut: &copied),
        0,
        "copy after set properties"
    )
    vtExpect(copied == kVTScalingMode_Normal, "set properties value")

    var dump: [String: String] = [:]
    vtExpectStatus(VTSessionCopySerializableProperties(transfer, propertiesOut: &dump), 0, "VTSessionCopySerializableProperties")
    vtExpect(dump[kVTPixelTransferPropertyKey_ScalingMode] == kVTScalingMode_Normal, "serializable dump")
    var catalog: [String: String] = [:]
    vtExpectStatus(VTSessionCopySupportedPropertyDictionary(transfer, propertiesOut: &catalog), 0, "VTSessionCopySupportedPropertyDictionary")
    vtExpect(catalog[kVTPixelTransferPropertyKey_ScalingMode]?.contains(kVTPropertyType_Enumeration) == true, "enum type")
    vtExpectStatus(
        VTSessionSetProperty(transfer, key: "not-a-real-key", value: "x"),
        kVTPropertyNotSupportedErr,
        "unknown key"
    )
    vtExpectStatus(VTSessionSetProperty(nil, key: kVTPixelTransferPropertyKey_ScalingMode, value: kVTScalingMode_Trim), kVTInvalidSessionErr, "nil session")
    VTPixelTransferSessionInvalidate(transfer)

    var decoder: OpaquePointer?
    let format = VTVideoFormatDescription(codecType: kVTPixelFormat_32BGRA, width: 4, height: 4)
    vtExpectStatus(
        VTDecompressionSessionCreate(formatDescription: format, outputCallback: nil, sessionOut: &decoder),
        0,
        "decomp property fixture"
    )
    vtExpectStatus(VTSessionSetProperty(decoder, key: kVTDecompressionPropertyKey_ThreadCount, value: "4"), 0, "set threads")
    copied = nil
    vtExpectStatus(VTSessionCopyProperty(decoder, key: kVTDecompressionPropertyKey_ThreadCount, valueOut: &copied), 0, "copy threads")
    vtExpect(copied == "4", "thread value")
    vtExpectStatus(VTSessionSetProperty(decoder, key: kVTDecompressionPropertyKey_ThreadCount, value: "0"), kVTParameterErr, "thread range")
    vtExpectStatus(
        VTSessionSetProperty(decoder, key: kVTDecompressionPropertyKey_UsingHardwareAcceleratedVideoDecoder, value: "true"),
        kVTPropertyReadOnlyErr,
        "hw decoder readonly"
    )
    VTDecompressionSessionInvalidate(decoder)
}

// --- VideoToolboxPixelTransferTests.swift ---

func testPixelTransferConversion() {
    var sourceBGRA: OpaquePointer?
    vtExpectStatus(
        VTHostCreatePixelBuffer(width: 4, height: 4, pixelFormat: kVTPixelFormat_32BGRA, pixelBufferOut: &sourceBGRA),
        0,
        "source"
    )
    vtExpectStatus(VTHostFillPixelBuffer(sourceBGRA, red: 10, green: 20, blue: 30, alpha: 255), 0, "fill")

    var transfer: OpaquePointer?
    vtExpectStatus(VTPixelTransferSessionCreate(sessionOut: &transfer), 0, "VTPixelTransferSessionCreate")
    vtExpect(transfer != nil, "pixel transfer session")
    vtExpectStatus(
        VTSessionSetProperty(transfer, key: kVTPixelTransferPropertyKey_ScalingMode, value: kVTScalingMode_Trim),
        0,
        "set scaling"
    )

    var destRGBA: OpaquePointer?
    vtExpectStatus(
        VTHostCreatePixelBuffer(width: 4, height: 4, pixelFormat: kVTPixelFormat_32RGBA, pixelBufferOut: &destRGBA),
        0,
        "dest rgba"
    )
    vtExpectStatus(VTPixelTransferSessionTransferImage(transfer, source: sourceBGRA, destination: destRGBA), 0, "VTPixelTransferSessionTransferImage")
    vtExpect(VTHostPixelBufferGetByte(destRGBA, x: 0, y: 0, channel: 0) == 10, "rgba red after convert")
    vtExpect(VTHostPixelBufferGetByte(destRGBA, x: 0, y: 0, channel: 2) == 30, "rgba blue after convert")

    var destSmall: OpaquePointer?
    vtExpectStatus(
        VTHostCreatePixelBuffer(width: 2, height: 2, pixelFormat: kVTPixelFormat_32BGRA, pixelBufferOut: &destSmall),
        0,
        "dest small"
    )
    vtExpectStatus(
        VTSessionSetProperty(transfer, key: kVTPixelTransferPropertyKey_ScalingMode, value: kVTScalingMode_Normal),
        0,
        "normal scale"
    )
    vtExpectStatus(VTPixelTransferSessionTransferImage(transfer, source: sourceBGRA, destination: destSmall), 0, "scale")
    vtExpect(VTHostPixelBufferGetWidth(destSmall) == 2, "scaled width")

    var letterbox: OpaquePointer?
    vtExpectStatus(
        VTHostCreatePixelBuffer(width: 8, height: 4, pixelFormat: kVTPixelFormat_32BGRA, pixelBufferOut: &letterbox),
        0,
        "letterbox dest"
    )
    vtExpectStatus(
        VTSessionSetProperty(transfer, key: kVTPixelTransferPropertyKey_ScalingMode, value: kVTScalingMode_Letterbox),
        0,
        "letterbox mode"
    )
    vtExpectStatus(VTPixelTransferSessionTransferImage(transfer, source: sourceBGRA, destination: letterbox), 0, "letterbox")
    vtExpect(VTHostPixelBufferGetByte(letterbox, x: 0, y: 0, channel: 0) == 0, "letterbox pad")

    vtExpectStatus(
        VTPixelTransferSessionTransferImage(transfer, source: nil, destination: nil),
        kVTPixelTransferNotSupportedErr,
        "xfer missing buffers"
    )
    vtExpect(VTPixelTransferSessionGetTypeID() == 0, "VTPixelTransferSessionGetTypeID")
    VTPixelTransferSessionInvalidate(transfer)
    vtExpectStatus(
        VTSessionSetProperty(transfer, key: kVTPixelTransferPropertyKey_ScalingMode, value: kVTScalingMode_Trim),
        kVTInvalidSessionErr,
        "invalid after invalidate"
    )
}

// --- VideoToolboxPixelRotationTests.swift ---

func testPixelRotationSession() {
    var sourceBGRA: OpaquePointer?
    vtExpectStatus(
        VTHostCreatePixelBuffer(width: 4, height: 4, pixelFormat: kVTPixelFormat_32BGRA, pixelBufferOut: &sourceBGRA),
        0,
        "source"
    )
    vtExpectStatus(VTHostFillPixelBuffer(sourceBGRA, red: 10, green: 20, blue: 30, alpha: 255), 0, "fill")

    var rotation: OpaquePointer?
    vtExpectStatus(VTPixelRotationSessionCreate(sessionOut: &rotation), 0, "VTPixelRotationSessionCreate")
    vtExpectStatus(
        VTSessionSetProperty(rotation, key: kVTPixelRotationPropertyKey_Rotation, value: kVTRotation_CW90),
        0,
        "set rot"
    )
    var rotated: OpaquePointer?
    vtExpectStatus(
        VTHostCreatePixelBuffer(width: 4, height: 4, pixelFormat: kVTPixelFormat_32BGRA, pixelBufferOut: &rotated),
        0,
        "rot dest square"
    )
    vtExpectStatus(VTPixelRotationSessionRotateImage(rotation, source: sourceBGRA, destination: rotated), 0, "VTPixelRotationSessionRotateImage")
    vtExpectStatus(
        VTPixelRotationSessionRotateImage(rotation, source: nil, destination: nil),
        kVTPixelRotationNotSupportedErr,
        "rotate missing"
    )
    vtExpect(VTPixelRotationSessionGetTypeID() == 0, "VTPixelRotationSessionGetTypeID")
    VTPixelRotationSessionInvalidate(rotation)
}

// --- VideoToolboxCGImageTests.swift ---

func testCreateCGImageFromPixelBuffer() {
    var sourceBGRA: OpaquePointer?
    vtExpectStatus(
        VTHostCreatePixelBuffer(width: 4, height: 4, pixelFormat: kVTPixelFormat_32BGRA, pixelBufferOut: &sourceBGRA),
        0,
        "source"
    )
    vtExpectStatus(VTHostFillPixelBuffer(sourceBGRA, red: 10, green: 20, blue: 30, alpha: 255), 0, "fill")

    var image: OpaquePointer?
    vtExpectStatus(VTCreateCGImageFromCVPixelBuffer(pixelBuffer: nil, imageOut: &image), kVTParameterErr, "VTCreateCGImageFromCVPixelBuffer nil")
    var image2: OpaquePointer?
    vtExpectStatus(VTCreateCGImageFromCVPixelBuffer(pixelBuffer: sourceBGRA, imageOut: &image2), 0, "VTCreateCGImageFromCVPixelBuffer")
    vtExpect(VTHostCGImageGetWidth(image2) == 4, "cg width")
    vtExpect(VTHostCGImageGetHeight(image2) == 4, "cg height")
    vtExpect(VTHostCGImageGetByte(image2, offset: 0) == 10, "cg red")
    vtExpect(VTHostCGImageGetByte(image2, offset: 1) == 20, "cg green")
    vtExpect(VTHostCGImageGetByte(image2, offset: 2) == 30, "cg blue")
    let fakeBuffer = OpaquePointer(bitPattern: 0x00FF_FFFF)!
    var image3: OpaquePointer?
    vtExpectStatus(
        VTCreateCGImageFromCVPixelBuffer(pixelBuffer: fakeBuffer, imageOut: &image3),
        kVTParameterErr,
        "cgimage unknown pointer"
    )
}

// --- VideoToolboxSiloTests.swift ---

func testFrameSiloSamplePass() {
    var sourceBGRA: OpaquePointer?
    vtExpectStatus(
        VTHostCreatePixelBuffer(width: 4, height: 4, pixelFormat: kVTPixelFormat_32BGRA, pixelBufferOut: &sourceBGRA),
        0,
        "source"
    )
    let bgraFormat = VTVideoFormatDescription(codecType: kVTPixelFormat_32BGRA, width: 4, height: 4)
    var sample: OpaquePointer?
    vtExpectStatus(
        VTHostCreateSampleBuffer(
            format: bgraFormat,
            pixelBuffer: sourceBGRA,
            presentationTimeStamp: VTMediaTime(value: 1, timescale: 1),
            duration: VTMediaTime.zero,
            sampleBufferOut: &sample
        ),
        0,
        "sample"
    )
    var sample2: OpaquePointer?
    vtExpectStatus(
        VTHostCreateSampleBuffer(
            format: bgraFormat,
            pixelBuffer: sourceBGRA,
            presentationTimeStamp: VTMediaTime(value: 2, timescale: 1),
            duration: VTMediaTime.zero,
            sampleBufferOut: &sample2
        ),
        0,
        "sample2"
    )

    var silo: OpaquePointer?
    vtExpectStatus(VTFrameSiloCreate(siloOut: &silo), 0, "VTFrameSiloCreate")
    vtExpect(silo != nil, "silo session")
    vtExpectStatus(VTFrameSiloAddSampleBuffer(silo, sampleBuffer: sample), 0, "VTFrameSiloAddSampleBuffer")
    vtExpectStatus(VTFrameSiloAddSampleBuffer(silo, sampleBuffer: sample2), 0, "add sample2")
    vtExpectStatus(VTFrameSiloSetTimeRangesForNextPass(silo), 0, "VTFrameSiloSetTimeRangesForNextPass")
    var progress = -1.0
    vtExpectStatus(VTFrameSiloGetProgressOfCurrentPass(silo, progressOut: &progress), 0, "VTFrameSiloGetProgressOfCurrentPass")
    let box = VTTestBox()
    vtExpectStatus(
        VTFrameSiloCallFunctionForEachSampleBuffer(silo) { pointer in
            box.visited += 1
            vtExpect(VTHostSampleBufferGetPresentationTimeStamp(pointer).isValid, "silo pts")
            return 0
        },
        0,
        "VTFrameSiloCallFunctionForEachSampleBuffer"
    )
    vtExpect(box.visited == 2, "visited \(box.visited)")
    vtExpectStatus(VTFrameSiloGetProgressOfCurrentPass(silo, progressOut: &progress), 0, "progress after")
    vtExpect(progress == 1, "complete pass")
    vtExpectStatus(VTFrameSiloCallFunctionForEachSampleBuffer(nil), kVTInvalidSessionErr, "foreach nil")
}

func testMultiPassStorageCreateAndClose() {
    var storage: OpaquePointer?
    vtExpectStatus(VTMultiPassStorageCreate(storageOut: &storage), 0, "VTMultiPassStorageCreate")
    vtExpectStatus(VTMultiPassStorageClose(storage), 0, "VTMultiPassStorageClose")
    vtExpectStatus(VTMultiPassStorageClose(nil), kVTInvalidSessionErr, "multipass nil")
}

// --- VideoToolboxFailClosedTests.swift ---

func testRAWProcessingSessionFailClosed() {
    var raw: OpaquePointer?
    vtExpectStatus(VTRAWProcessingSessionCreate(sessionOut: &raw), kVTCouldNotFindExtensionErr, "VTRAWProcessingSessionCreate")
    VTRAWProcessingSessionInvalidate(raw)
    vtExpect(VTRAWProcessingSessionGetTypeID() == 0, "VTRAWProcessingSessionGetTypeID")
    vtExpectStatus(VTRAWProcessingSessionCompleteFrames(nil), kVTInvalidSessionErr, "VTRAWProcessingSessionCompleteFrames")
    vtExpectStatus(VTRAWProcessingSessionProcessFrame(nil), kVTInvalidSessionErr, "VTRAWProcessingSessionProcessFrame")
    var rawParams: [String: String] = ["a": "b"]
    vtExpectStatus(VTRAWProcessingSessionCopyProcessingParameters(nil, parametersOut: &rawParams), kVTInvalidSessionErr, "VTRAWProcessingSessionCopyProcessingParameters")
    vtExpectStatus(VTRAWProcessingSessionSetProcessingParameters(nil, parameters: ["k": "v"]), kVTInvalidSessionErr, "VTRAWProcessingSessionSetProcessingParameters")
    vtExpectStatus(VTRAWProcessingSessionSetParameterChangedHandler(nil), kVTInvalidSessionErr, "VTRAWProcessingSessionSetParameterChangedHandler")
    vtExpectStatus(VTRAWProcessingSessionSetParameterChangedHander(nil), kVTInvalidSessionErr, "VTRAWProcessingSessionSetParameterChangedHander")
}

func testMotionEstimationSessionFailClosed() {
    var motion: OpaquePointer?
    vtExpectStatus(VTMotionEstimationSessionCreate(sessionOut: &motion), kVTCouldNotFindTemporalFilterErr, "VTMotionEstimationSessionCreate")
    VTMotionEstimationSessionInvalidate(motion)
    vtExpect(VTMotionEstimationSessionGetTypeID() == 0, "VTMotionEstimationSessionGetTypeID")
}

func testHDRMetadataSessionFailClosed() {
    var hdr: OpaquePointer?
    vtExpectStatus(
        VTHDRPerFrameMetadataGenerationSessionCreate(framesPerSecond: 24, sessionOut: &hdr),
        kVTAllocationFailedErr,
        "VTHDRPerFrameMetadataGenerationSessionCreate"
    )
    vtExpectStatus(
        VTHDRPerFrameMetadataGenerationSessionCreate(framesPerSecond: 0, sessionOut: &hdr),
        kVTParameterErr,
        "hdr fps"
    )
    VTHDRPerFrameMetadataGenerationSessionInvalidate(hdr)
    vtExpect(VTHDRPerFrameMetadataGenerationSessionGetTypeID() == 0, "VTHDRPerFrameMetadataGenerationSessionGetTypeID")
}

func testHardwareAndEncoderDiscovery() {
    vtExpect(VTIsHardwareDecodeSupported(kVTVideoCodecType_H264) == false, "VTIsHardwareDecodeSupported h264")
    vtExpect(VTIsHardwareDecodeSupported(kVTPixelFormat_32BGRA) == false, "VTIsHardwareDecodeSupported bgra")
    vtExpect(VTIsStereoMVHEVCDecodeSupported() == false, "VTIsStereoMVHEVCDecodeSupported")
    vtExpect(VTIsStereoMVHEVCEncodeSupported() == false, "VTIsStereoMVHEVCEncodeSupported")

    var encoders: [String] = ["sentinel"]
    vtExpectStatus(VTCopyVideoEncoderList(&encoders), 0, "VTCopyVideoEncoderList")
    vtExpect(encoders.isEmpty, "encoder list empty")

    var encoderID: String?
    var encoderProps: [String: String] = ["x": "y"]
    vtExpectStatus(
        VTCopySupportedPropertyDictionaryForEncoder(
            width: 64,
            height: 64,
            codecType: kVTVideoCodecType_H264,
            encoderIdentifierOut: &encoderID,
            propertiesOut: &encoderProps
        ),
        kVTCouldNotFindVideoEncoderErr,
        "VTCopySupportedPropertyDictionaryForEncoder"
    )
    vtExpect(encoderID == nil, "encoder id nil")
    vtExpect(encoderProps.isEmpty, "encoder props empty")
}

func testProfessionalWorkflowRegistration() {
    VTRegisterProfessionalVideoWorkflowVideoDecoders()
    VTRegisterProfessionalVideoWorkflowVideoEncoders()
    VTRegisterSupplementalVideoDecoderIfAvailable(kVTVideoCodecType_H264)
}

func testExtensionPropertyQueries() {
    var extProps: [String: String] = ["x": "y"]
    vtExpectStatus(VTCopyVideoDecoderExtensionProperties(&extProps), kVTCouldNotFindExtensionErr, "VTCopyVideoDecoderExtensionProperties")
    vtExpect(extProps.isEmpty, "decoder ext empty")
    vtExpectStatus(VTCopyRAWProcessorExtensionProperties(&extProps), kVTCouldNotFindExtensionErr, "VTCopyRAWProcessorExtensionProperties")
}

func videotoolboxRunAllAgentTests() {
    testErrorConstantValues()
    testOptionSetAndFlagRawValues()
    testCompressionPropertyKeyPayloads()
    testDecompressionPropertyKeyPayloads()
    testProfileLevelKeyPayloads()
    testPixelTransferAndRotationKeyPayloads()
    testRAWProcessorKeyPayloads()
    testEncoderListAndSpecificationKeyPayloads()
    testRemainingPropertyKeyPayloads()
    testSessionRefTypealiases()
    testCompressionSessionFailClosed()
    testUncompressedPassthroughDecoder()
    testDecompressionFailClosedAndStubs()
    testSessionPropertyRoundTrip()
    testPixelTransferConversion()
    testPixelRotationSession()
    testCreateCGImageFromPixelBuffer()
    testFrameSiloSamplePass()
    testMultiPassStorageCreateAndClose()
    testRAWProcessingSessionFailClosed()
    testMotionEstimationSessionFailClosed()
    testHDRMetadataSessionFailClosed()
    testHardwareAndEncoderDiscovery()
    testProfessionalWorkflowRegistration()
    testExtensionPropertyQueries()
}

videotoolboxRunAllAgentTests()
print("VIDEOTOOLBOX_AGENT_RUNTIME_OK")
