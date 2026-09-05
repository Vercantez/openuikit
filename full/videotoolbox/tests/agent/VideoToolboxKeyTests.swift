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
