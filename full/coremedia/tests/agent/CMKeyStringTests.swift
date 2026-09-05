import CoreFoundation
import CoreMedia
import Foundation

// CFString payloads interned by this port. CMTime.h documents value/timescale/
// epoch/flags; CMTimeRange.h documents start/duration; mapping uses source/
// target. Format-description and sample-attachment keys use the identifier
// suffix (CMKeys.swift), with CoreVideo color aliases "ITU_R_709_2" /
// "IEC_sRGB" / "Apple Log". Pointer identity vs Apple interned constants is
// unobserved (oracle-questions.tsv).

private func cmExpectedCFString(_ expected: String) -> CFString {
    expected.withCString { pointer in
        CFStringCreateWithCString(
            kCFAllocatorDefault,
            pointer,
            CFStringBuiltInEncodings.UTF8.rawValue
        )!
    }
}

private func cmAssertKeyPayload(_ key: CFString, _ expected: String) {
    precondition(CFEqual(key, cmExpectedCFString(expected)))
}

func testCMTimeFamilyDictionaryKeyStrings() {
    // CMTime.h / CMTimeRange.h dictionary key payloads.
    cmAssertKeyPayload(kCMTimeValueKey, "value")
    cmAssertKeyPayload(kCMTimeScaleKey, "timescale")
    cmAssertKeyPayload(kCMTimeEpochKey, "epoch")
    cmAssertKeyPayload(kCMTimeFlagsKey, "flags")
    cmAssertKeyPayload(kCMTimeRangeStartKey, "start")
    cmAssertKeyPayload(kCMTimeRangeDurationKey, "duration")
    cmAssertKeyPayload(kCMTimeMappingSourceKey, "source")
    cmAssertKeyPayload(kCMTimeMappingTargetKey, "target")
}

func testCMFormatDescriptionExtensionKeyStrings() {
    let pairs: [(CFString, String)] = [
        (kCMFormatDescriptionExtension_AlphaChannelMode, "AlphaChannelMode"),
        (kCMFormatDescriptionExtension_AlternativeTransferCharacteristics, "AlternativeTransferCharacteristics"),
        (kCMFormatDescriptionExtension_AmbientViewingEnvironment, "AmbientViewingEnvironment"),
        (kCMFormatDescriptionExtension_AuxiliaryTypeInfo, "AuxiliaryTypeInfo"),
        (kCMFormatDescriptionExtension_BitsPerComponent, "BitsPerComponent"),
        (kCMFormatDescriptionExtension_BytesPerRow, "BytesPerRow"),
        (kCMFormatDescriptionExtension_CameraCalibrationDataLensCollection, "CameraCalibrationDataLensCollection"),
        (kCMFormatDescriptionExtension_ChromaLocationBottomField, "ChromaLocationBottomField"),
        (kCMFormatDescriptionExtension_ChromaLocationTopField, "ChromaLocationTopField"),
        (kCMFormatDescriptionExtension_CleanAperture, "CleanAperture"),
        (kCMFormatDescriptionExtension_ColorPrimaries, "ColorPrimaries"),
        (kCMFormatDescriptionExtension_ContainsAlphaChannel, "ContainsAlphaChannel"),
        (kCMFormatDescriptionExtension_ContentColorVolume, "ContentColorVolume"),
        (kCMFormatDescriptionExtension_ContentLightLevelInfo, "ContentLightLevelInfo"),
        (kCMFormatDescriptionExtension_ConvertedFromExternalSphericalTags, "ConvertedFromExternalSphericalTags"),
        (kCMFormatDescriptionExtension_Depth, "Depth"),
        (kCMFormatDescriptionExtension_FieldCount, "FieldCount"),
        (kCMFormatDescriptionExtension_FieldDetail, "FieldDetail"),
        (kCMFormatDescriptionExtension_FormatName, "FormatName"),
        (kCMFormatDescriptionExtension_FullRangeVideo, "FullRangeVideo"),
        (kCMFormatDescriptionExtension_GammaLevel, "GammaLevel"),
        (kCMFormatDescriptionExtension_HasAdditionalViews, "HasAdditionalViews"),
        (kCMFormatDescriptionExtension_HasLeftStereoEyeView, "HasLeftStereoEyeView"),
        (kCMFormatDescriptionExtension_HasRightStereoEyeView, "HasRightStereoEyeView"),
        (kCMFormatDescriptionExtension_HeroEye, "HeroEye"),
        (kCMFormatDescriptionExtension_HorizontalDisparityAdjustment, "HorizontalDisparityAdjustment"),
        (kCMFormatDescriptionExtension_HorizontalFieldOfView, "HorizontalFieldOfView"),
        (kCMFormatDescriptionExtension_ICCProfile, "ICCProfile"),
        (kCMFormatDescriptionExtension_LogTransferFunction, "LogTransferFunction"),
        (kCMFormatDescriptionExtension_MasteringDisplayColorVolume, "MasteringDisplayColorVolume"),
        (kCMFormatDescriptionExtension_OriginalCompressionSettings, "OriginalCompressionSettings"),
        (kCMFormatDescriptionExtension_PixelAspectRatio, "PixelAspectRatio"),
        (kCMFormatDescriptionExtension_ProjectionKind, "ProjectionKind"),
        (kCMFormatDescriptionExtension_ProtectedContentOriginalFormat, "ProtectedContentOriginalFormat"),
        (kCMFormatDescriptionExtension_RevisionLevel, "RevisionLevel"),
        (kCMFormatDescriptionExtension_SampleDescriptionExtensionAtoms, "SampleDescriptionExtensionAtoms"),
        (kCMFormatDescriptionExtension_SpatialQuality, "SpatialQuality"),
        (kCMFormatDescriptionExtension_StereoCameraBaseline, "StereoCameraBaseline"),
        (kCMFormatDescriptionExtension_TemporalQuality, "TemporalQuality"),
        (kCMFormatDescriptionExtension_TransferFunction, "TransferFunction"),
        (kCMFormatDescriptionExtension_Vendor, "Vendor"),
        (kCMFormatDescriptionExtension_VerbatimISOSampleEntry, "VerbatimISOSampleEntry"),
        (kCMFormatDescriptionExtension_VerbatimImageDescription, "VerbatimImageDescription"),
        (kCMFormatDescriptionExtension_VerbatimSampleDescription, "VerbatimSampleDescription"),
        (kCMFormatDescriptionExtension_Version, "Version"),
        (kCMFormatDescriptionExtension_ViewPackingKind, "ViewPackingKind"),
        (kCMFormatDescriptionExtension_YCbCrMatrix, "YCbCrMatrix"),
    ]
    for (key, expected) in pairs {
        cmAssertKeyPayload(key, expected)
    }
}

func testCMFormatDescriptionColorMatrixKeyStrings() {
    let pairs: [(CFString, String)] = [
        (kCMFormatDescriptionChromaLocation_Bottom, "Bottom"),
        (kCMFormatDescriptionChromaLocation_BottomLeft, "BottomLeft"),
        (kCMFormatDescriptionChromaLocation_Center, "Center"),
        (kCMFormatDescriptionChromaLocation_DV420, "DV420"),
        (kCMFormatDescriptionChromaLocation_Left, "Left"),
        (kCMFormatDescriptionChromaLocation_Top, "Top"),
        (kCMFormatDescriptionChromaLocation_TopLeft, "TopLeft"),
        (kCMFormatDescriptionColorPrimaries_DCI_P3, "DCI_P3"),
        (kCMFormatDescriptionColorPrimaries_EBU_3213, "EBU_3213"),
        (kCMFormatDescriptionColorPrimaries_ITU_R_2020, "ITU_R_2020"),
        (kCMFormatDescriptionColorPrimaries_ITU_R_709_2, "ITU_R_709_2"),
        (kCMFormatDescriptionColorPrimaries_P22, "P22"),
        (kCMFormatDescriptionColorPrimaries_P3_D65, "P3_D65"),
        (kCMFormatDescriptionColorPrimaries_SMPTE_C, "SMPTE_C"),
        (kCMFormatDescriptionFieldDetail_SpatialFirstLineEarly, "SpatialFirstLineEarly"),
        (kCMFormatDescriptionFieldDetail_SpatialFirstLineLate, "SpatialFirstLineLate"),
        (kCMFormatDescriptionFieldDetail_TemporalBottomFirst, "TemporalBottomFirst"),
        (kCMFormatDescriptionFieldDetail_TemporalTopFirst, "TemporalTopFirst"),
        (kCMFormatDescriptionTransferFunction_ITU_R_2020, "ITU_R_2020"),
        (kCMFormatDescriptionTransferFunction_ITU_R_2100_HLG, "ITU_R_2100_HLG"),
        (kCMFormatDescriptionTransferFunction_ITU_R_709_2, "ITU_R_709_2"),
        (kCMFormatDescriptionTransferFunction_Linear, "Linear"),
        (kCMFormatDescriptionTransferFunction_SMPTE_240M_1995, "SMPTE_240M_1995"),
        (kCMFormatDescriptionTransferFunction_SMPTE_ST_2084_PQ, "SMPTE_ST_2084_PQ"),
        (kCMFormatDescriptionTransferFunction_SMPTE_ST_428_1, "SMPTE_ST_428_1"),
        (kCMFormatDescriptionTransferFunction_UseGamma, "UseGamma"),
        (kCMFormatDescriptionTransferFunction_sRGB, "IEC_sRGB"),
        (kCMFormatDescriptionYCbCrMatrix_ITU_R_2020, "ITU_R_2020"),
        (kCMFormatDescriptionYCbCrMatrix_ITU_R_601_4, "ITU_R_601_4"),
        (kCMFormatDescriptionYCbCrMatrix_ITU_R_709_2, "ITU_R_709_2"),
        (kCMFormatDescriptionYCbCrMatrix_SMPTE_240M_1995, "SMPTE_240M_1995"),
    ]
    for (key, expected) in pairs {
        cmAssertKeyPayload(key, expected)
    }
}

func testCMSampleAttachmentKeyStrings() {
    let pairs: [(CFString, String)] = [
        (kCMSampleAttachmentKey_AudioIndependentSampleDecoderRefreshCount, "AudioIndependentSampleDecoderRefreshCount"),
        (kCMSampleAttachmentKey_CryptorSubsampleAuxiliaryData, "CryptorSubsampleAuxiliaryData"),
        (kCMSampleAttachmentKey_DependsOnOthers, "DependsOnOthers"),
        (kCMSampleAttachmentKey_DisplayImmediately, "DisplayImmediately"),
        (kCMSampleAttachmentKey_DoNotDisplay, "DoNotDisplay"),
        (kCMSampleAttachmentKey_EarlierDisplayTimesAllowed, "EarlierDisplayTimesAllowed"),
        (kCMSampleAttachmentKey_HDR10PlusPerFrameData, "HDR10PlusPerFrameData"),
        (kCMSampleAttachmentKey_HEVCStepwiseTemporalSubLayerAccess, "HEVCStepwiseTemporalSubLayerAccess"),
        (kCMSampleAttachmentKey_HEVCSyncSampleNALUnitType, "HEVCSyncSampleNALUnitType"),
        (kCMSampleAttachmentKey_HEVCTemporalLevelInfo, "HEVCTemporalLevelInfo"),
        (kCMSampleAttachmentKey_HEVCTemporalSubLayerAccess, "HEVCTemporalSubLayerAccess"),
        (kCMSampleAttachmentKey_HasRedundantCoding, "HasRedundantCoding"),
        (kCMSampleAttachmentKey_IsDependedOnByOthers, "IsDependedOnByOthers"),
        (kCMSampleAttachmentKey_NotSync, "NotSync"),
        (kCMSampleAttachmentKey_PartialSync, "PartialSync"),
        (kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, "CameraIntrinsicMatrix"),
        (kCMSampleBufferAttachmentKey_DisplayEmptyMediaImmediately, "DisplayEmptyMediaImmediately"),
        (kCMSampleBufferAttachmentKey_DrainAfterDecoding, "DrainAfterDecoding"),
        (kCMSampleBufferAttachmentKey_DroppedFrameReason, "DroppedFrameReason"),
        (kCMSampleBufferAttachmentKey_DroppedFrameReasonInfo, "DroppedFrameReasonInfo"),
        (kCMSampleBufferAttachmentKey_EmptyMedia, "EmptyMedia"),
        (kCMSampleBufferAttachmentKey_EndsPreviousSampleDuration, "EndsPreviousSampleDuration"),
        (kCMSampleBufferAttachmentKey_FillDiscontinuitiesWithSilence, "FillDiscontinuitiesWithSilence"),
        (kCMSampleBufferAttachmentKey_ForceKeyFrame, "ForceKeyFrame"),
        (kCMSampleBufferAttachmentKey_GradualDecoderRefresh, "GradualDecoderRefresh"),
        (kCMSampleBufferAttachmentKey_PermanentEmptyMedia, "PermanentEmptyMedia"),
        (kCMSampleBufferAttachmentKey_PostNotificationWhenConsumed, "PostNotificationWhenConsumed"),
        (kCMSampleBufferAttachmentKey_ResetDecoderBeforeDecoding, "ResetDecoderBeforeDecoding"),
        (kCMSampleBufferAttachmentKey_ResumeOutput, "ResumeOutput"),
        (kCMSampleBufferAttachmentKey_Reverse, "Reverse"),
        (kCMSampleBufferAttachmentKey_SampleReferenceByteOffset, "SampleReferenceByteOffset"),
        (kCMSampleBufferAttachmentKey_SampleReferenceURL, "SampleReferenceURL"),
        (kCMSampleBufferAttachmentKey_SpeedMultiplier, "SpeedMultiplier"),
        (kCMSampleBufferAttachmentKey_StillImageLensStabilizationInfo, "StillImageLensStabilizationInfo"),
        (kCMSampleBufferAttachmentKey_TransitionID, "TransitionID"),
        (kCMSampleBufferAttachmentKey_TrimDurationAtEnd, "TrimDurationAtEnd"),
        (kCMSampleBufferAttachmentKey_TrimDurationAtStart, "TrimDurationAtStart"),
    ]
    for (key, expected) in pairs {
        cmAssertKeyPayload(key, expected)
    }
}

func testCMMetadataKeySpaceStrings() {
    let pairs: [(CFString, String)] = [
        (kCMMetadataKeySpace_HLSDateRange, "HLSDateRange"),
        (kCMMetadataKeySpace_ID3, "ID3"),
        (kCMMetadataKeySpace_ISOUserData, "ISOUserData"),
        (kCMMetadataKeySpace_Icy, "Icy"),
        (kCMMetadataKeySpace_QuickTimeMetadata, "QuickTimeMetadata"),
        (kCMMetadataKeySpace_QuickTimeUserData, "QuickTimeUserData"),
        (kCMMetadataKeySpace_iTunes, "iTunes"),
    ]
    for (key, expected) in pairs {
        cmAssertKeyPayload(key, expected)
    }
}
