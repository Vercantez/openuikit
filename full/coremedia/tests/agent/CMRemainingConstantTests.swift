import CoreFoundation
import CoreMedia
import Foundation

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

func testCMMetadataBaseDataTypeKeyStrings() {
    let pairs: [(CFString, String)] = [
        (kCMMetadataBaseDataType_AffineTransformF64, "AffineTransformF64"),
        (kCMMetadataBaseDataType_BMP, "BMP"),
        (kCMMetadataBaseDataType_DimensionsF32, "DimensionsF32"),
        (kCMMetadataBaseDataType_ExtendedRasterRectangleValue, "ExtendedRasterRectangleValue"),
        (kCMMetadataBaseDataType_Float32, "Float32"),
        (kCMMetadataBaseDataType_Float64, "Float64"),
        (kCMMetadataBaseDataType_GIF, "GIF"),
        (kCMMetadataBaseDataType_JPEG, "JPEG"),
        (kCMMetadataBaseDataType_JSON, "JSON"),
        (kCMMetadataBaseDataType_PNG, "PNG"),
        (kCMMetadataBaseDataType_PerspectiveTransformF64, "PerspectiveTransformF64"),
        (kCMMetadataBaseDataType_PointF32, "PointF32"),
        (kCMMetadataBaseDataType_PolygonF32, "PolygonF32"),
        (kCMMetadataBaseDataType_PolylineF32, "PolylineF32"),
        (kCMMetadataBaseDataType_RasterRectangleValue, "RasterRectangleValue"),
        (kCMMetadataBaseDataType_RawData, "RawData"),
        (kCMMetadataBaseDataType_RectF32, "RectF32"),
        (kCMMetadataBaseDataType_SInt16, "SInt16"),
        (kCMMetadataBaseDataType_SInt32, "SInt32"),
        (kCMMetadataBaseDataType_SInt64, "SInt64"),
        (kCMMetadataBaseDataType_SInt8, "SInt8"),
        (kCMMetadataBaseDataType_UInt16, "UInt16"),
        (kCMMetadataBaseDataType_UInt32, "UInt32"),
        (kCMMetadataBaseDataType_UInt64, "UInt64"),
        (kCMMetadataBaseDataType_UInt8, "UInt8"),
        (kCMMetadataBaseDataType_UTF16, "UTF16"),
        (kCMMetadataBaseDataType_UTF8, "UTF8"),
    ]
    for (key, expected) in pairs {
        cmAssertKeyPayload(key, expected)
    }
}

func testCMFormatDescriptionRemainingKeyStrings() {
    cmAssertKeyPayload(kCMFormatDescriptionConformsToMPEG2VideoProfile, "kCMFormatDescriptionConformsToMPEG2VideoProfile")
    cmAssertKeyPayload(kCMFormatDescriptionExtensionKey_MetadataKeyTable, "MetadataKeyTable")
    cmAssertKeyPayload(kCMFormatDescriptionHeroEye_Left, "Left")
    cmAssertKeyPayload(kCMFormatDescriptionHeroEye_Right, "Right")
    cmAssertKeyPayload(kCMFormatDescriptionKey_CleanApertureHeightRational, "CleanApertureHeightRational")
    cmAssertKeyPayload(kCMFormatDescriptionKey_CleanApertureHorizontalOffsetRational, "CleanApertureHorizontalOffsetRational")
    cmAssertKeyPayload(kCMFormatDescriptionKey_CleanApertureVerticalOffsetRational, "CleanApertureVerticalOffsetRational")
    cmAssertKeyPayload(kCMFormatDescriptionKey_CleanApertureWidthRational, "CleanApertureWidthRational")
    cmAssertKeyPayload(kCMFormatDescriptionLogTransferFunction_AppleLog, "Apple Log")
    cmAssertKeyPayload(kCMFormatDescriptionProjectionKind_AppleImmersiveVideo, "AppleImmersiveVideo")
    cmAssertKeyPayload(kCMFormatDescriptionProjectionKind_Equirectangular, "Equirectangular")
    cmAssertKeyPayload(kCMFormatDescriptionProjectionKind_HalfEquirectangular, "HalfEquirectangular")
    cmAssertKeyPayload(kCMFormatDescriptionProjectionKind_ParametricImmersive, "ParametricImmersive")
    cmAssertKeyPayload(kCMFormatDescriptionProjectionKind_Rectilinear, "Rectilinear")
    cmAssertKeyPayload(kCMFormatDescriptionVendor_Apple, "Apple")
    cmAssertKeyPayload(kCMFormatDescriptionViewPackingKind_OverUnder, "OverUnder")
    cmAssertKeyPayload(kCMFormatDescriptionViewPackingKind_SideBySide, "SideBySide")
}

func testCMSampleBufferConduitDroppedFrameAndLensKeyStrings() {
    cmAssertKeyPayload(kCMSampleBufferConduitNotificationParameter_MaxUpcomingOutputPTS, "MaxUpcomingOutputPTS")
    cmAssertKeyPayload(kCMSampleBufferConduitNotificationParameter_MinUpcomingOutputPTS, "MinUpcomingOutputPTS")
    cmAssertKeyPayload(kCMSampleBufferConduitNotificationParameter_ResumeTag, "ResumeTag")
    cmAssertKeyPayload(
        kCMSampleBufferConduitNotificationParameter_UpcomingOutputPTSRangeMayOverlapQueuedOutputPTSRange,
        "UpcomingOutputPTSRangeMayOverlapQueuedOutputPTSRange"
    )
    cmAssertKeyPayload(kCMSampleBufferConduitNotification_InhibitOutputUntil, "InhibitOutputUntil")
    cmAssertKeyPayload(kCMSampleBufferConduitNotification_ResetOutput, "ResetOutput")
    cmAssertKeyPayload(kCMSampleBufferConduitNotification_UpcomingOutputPTSRangeChanged, "UpcomingOutputPTSRangeChanged")
    cmAssertKeyPayload(kCMSampleBufferConsumerNotification_BufferConsumed, "BufferConsumed")
    cmAssertKeyPayload(kCMSampleBufferDroppedFrameReasonInfo_CameraModeSwitch, "CameraModeSwitch")
    cmAssertKeyPayload(kCMSampleBufferDroppedFrameReason_Discontinuity, "Discontinuity")
    cmAssertKeyPayload(kCMSampleBufferDroppedFrameReason_FrameWasLate, "FrameWasLate")
    cmAssertKeyPayload(kCMSampleBufferDroppedFrameReason_OutOfBuffers, "OutOfBuffers")
    cmAssertKeyPayload(kCMSampleBufferLensStabilizationInfo_Active, "Active")
    cmAssertKeyPayload(kCMSampleBufferLensStabilizationInfo_Off, "Off")
    cmAssertKeyPayload(kCMSampleBufferLensStabilizationInfo_OutOfRange, "OutOfRange")
    cmAssertKeyPayload(kCMSampleBufferLensStabilizationInfo_Unavailable, "Unavailable")
}

func testCMMetadataIdentifierRemainingKeyStrings() {
    cmAssertKeyPayload(kCMMetadataIdentifier_QuickTimeMetadataDirection_Facing, "Facing")
    cmAssertKeyPayload(
        kCMMetadataIdentifier_QuickTimeMetadataDisplayMaskRectangleMono,
        "QuickTimeMetadataDisplayMaskRectangleMono"
    )
    cmAssertKeyPayload(
        kCMMetadataIdentifier_QuickTimeMetadataDisplayMaskRectangleStereoLeft,
        "QuickTimeMetadataDisplayMaskRectangleStereoLeft"
    )
    cmAssertKeyPayload(
        kCMMetadataIdentifier_QuickTimeMetadataDisplayMaskRectangleStereoRight,
        "QuickTimeMetadataDisplayMaskRectangleStereoRight"
    )
    cmAssertKeyPayload(
        kCMMetadataIdentifier_QuickTimeMetadataLivePhotoStillImageTransform,
        "QuickTimeMetadataLivePhotoStillImageTransform"
    )
    cmAssertKeyPayload(
        kCMMetadataIdentifier_QuickTimeMetadataLivePhotoStillImageTransformReferenceDimensions,
        "QuickTimeMetadataLivePhotoStillImageTransformReferenceDimensions"
    )
    cmAssertKeyPayload(
        kCMMetadataIdentifier_QuickTimeMetadataPreferredAffineTransform,
        "QuickTimeMetadataPreferredAffineTransform"
    )
    cmAssertKeyPayload(
        kCMMetadataIdentifier_QuickTimeMetadataPresentationImmersiveMedia,
        "QuickTimeMetadataPresentationImmersiveMedia"
    )
    cmAssertKeyPayload(kCMMetadataIdentifier_QuickTimeMetadataSceneIlluminance, "QuickTimeMetadataSceneIlluminance")
    cmAssertKeyPayload(kCMMetadataIdentifier_QuickTimeMetadataSegmentIdentifier, "QuickTimeMetadataSegmentIdentifier")
    cmAssertKeyPayload(kCMMetadataIdentifier_QuickTimeMetadataSpatialAudioMix, "QuickTimeMetadataSpatialAudioMix")
    cmAssertKeyPayload(kCMMetadataIdentifier_QuickTimeMetadataVideoOrientation, "QuickTimeMetadataVideoOrientation")
}

func testCMTextFormatDescriptionRemainingKeyStrings() {
    cmAssertKeyPayload(kCMTextFormatDescriptionColor_Alpha, "Alpha")
    cmAssertKeyPayload(kCMTextFormatDescriptionColor_Blue, "Blue")
    cmAssertKeyPayload(kCMTextFormatDescriptionColor_Green, "Green")
    cmAssertKeyPayload(kCMTextFormatDescriptionColor_Red, "Red")
    cmAssertKeyPayload(kCMTextFormatDescriptionExtension_BackgroundColor, "BackgroundColor")
    cmAssertKeyPayload(kCMTextFormatDescriptionExtension_FontTable, "FontTable")
    cmAssertKeyPayload(kCMTextFormatDescriptionExtension_TextJustification, "TextJustification")
    cmAssertKeyPayload(kCMTextFormatDescriptionStyle_Ascent, "Ascent")
    cmAssertKeyPayload(kCMTextFormatDescriptionStyle_EndChar, "EndChar")
    cmAssertKeyPayload(kCMTextFormatDescriptionStyle_ForegroundColor, "ForegroundColor")
    cmAssertKeyPayload(kCMTextFormatDescriptionStyle_Height, "Height")
    cmAssertKeyPayload(kCMTextFormatDescriptionStyle_StartChar, "StartChar")
}

func testRemainingPixelFormatConstants() {
    func fourCC(_ literal: String) -> UInt32 {
        let bytes = Array(literal.utf8)
        return (UInt32(bytes[0]) << 24) | (UInt32(bytes[1]) << 16) | (UInt32(bytes[2]) << 8) | UInt32(bytes[3])
    }
    precondition(kCMPixelFormat_16BE555 == 16)
    precondition(kCMPixelFormat_16BE565 == fourCC("B565"))
    precondition(kCMPixelFormat_16LE555 == fourCC("L555"))
    precondition(kCMPixelFormat_16LE5551 == fourCC("5551"))
    precondition(kCMPixelFormat_16LE565 == fourCC("L565"))
    precondition(kCMPixelFormat_422YpCbCr10 == fourCC("v210"))
    precondition(kCMPixelFormat_422YpCbCr16 == fourCC("v216"))
    precondition(kCMPixelFormat_422YpCbCr8_yuvs == fourCC("yuvs"))
    precondition(kCMPixelFormat_4444YpCbCrA8 == fourCC("v408"))
    precondition(kCMPixelFormat_444YpCbCr10 == fourCC("v410"))
    precondition(kCMPixelFormat_444YpCbCr8 == fourCC("v308"))
    precondition(kCMPixelFormat_8IndexedGray_WhiteIsZero == 40)
}

func testCMSampleBufferAudioBufferListAlignmentFlag() {
    precondition(kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment == 1)
    precondition(
        CMSampleBuffer.Flags.audioBufferListAssure16ByteAlignment.contains(
            CMSampleBuffer.Flags(rawValue: kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment)
        )
    )
}

func testCMRemainingMediaFormatTypeFourCCs() {
    func fourCC(_ literal: String) -> UInt32 {
        let bytes = Array(literal.utf8)
        return (UInt32(bytes[0]) << 24) | (UInt32(bytes[1]) << 16) | (UInt32(bytes[2]) << 8) | UInt32(bytes[3])
    }
    precondition(kCMClosedCaptionFormatType_ATSC == fourCC("atcc"))
    precondition(kCMClosedCaptionFormatType_CEA608 == fourCC("c608"))
    precondition(kCMClosedCaptionFormatType_CEA708 == fourCC("c708"))
    precondition(kCMMetadataFormatType_EMSG == fourCC("emsg"))
    precondition(kCMMetadataFormatType_ICY == fourCC("icy "))
    precondition(kCMMetadataFormatType_ID3 == fourCC("id3 "))
    precondition(kCMMuxedStreamType_DV == fourCC("dv  "))
    precondition(kCMMuxedStreamType_EmbeddedDeviceScreenRecording == fourCC("isr "))
    precondition(kCMMuxedStreamType_MPEG1System == fourCC("mp1s"))
    precondition(kCMMuxedStreamType_MPEG2Program == fourCC("mp2p"))
    precondition(kCMSubtitleFormatType_3GText == fourCC("tx3g"))
    precondition(kCMSubtitleFormatType_WebVTT == fourCC("wvtt"))
    precondition(kCMTextFormatType_3GText == fourCC("tx3g"))
    precondition(kCMTimeCodeFormatType_Counter32 == fourCC("cn32"))
    precondition(kCMTimeCodeFormatType_Counter64 == fourCC("cn64"))
    precondition(kCMTimeCodeFormatType_TimeCode64 == fourCC("tc64"))
}

func testCMTimeCodeFlagConstants() {
    precondition(kCMTimeCodeFlag_DropFrame == 1)
    precondition(kCMTimeCodeFlag_24HourMax == 2)
    precondition(kCMTimeCodeFlag_NegTimesOK == 4)
    precondition(CMFormatDescription.TimeCode.Flag.dropFrame.rawValue == kCMTimeCodeFlag_DropFrame)
    precondition(CMFormatDescription.TimeCode.Flag.twentyFourHourMax.rawValue == kCMTimeCodeFlag_24HourMax)
    precondition(CMFormatDescription.TimeCode.Flag.negTimesOK.rawValue == kCMTimeCodeFlag_NegTimesOK)
}

func testCMSyncRemainingErrorConstants() {
    precondition(kCMSyncError_MissingRequiredParameter == -12752)
    precondition(kCMSyncError_InvalidParameter == -12753)
    precondition(kCMSyncError_AllocationFailed == -12754)
    precondition(CMClock.Error.missingRequiredParameter.code == Int(kCMSyncError_MissingRequiredParameter))
    precondition(CMClock.Error.invalidParameter.code == Int(kCMSyncError_InvalidParameter))
    precondition(CMClock.Error.allocationFailed.code == Int(kCMSyncError_AllocationFailed))
}

func testCMHEVCTemporalLevelInfoKeyStrings() {
    cmAssertKeyPayload(kCMHEVCTemporalLevelInfoKey_ConstraintIndicatorFlags, "ConstraintIndicatorFlags")
    cmAssertKeyPayload(kCMHEVCTemporalLevelInfoKey_LevelIndex, "LevelIndex")
    cmAssertKeyPayload(kCMHEVCTemporalLevelInfoKey_ProfileCompatibilityFlags, "ProfileCompatibilityFlags")
    cmAssertKeyPayload(kCMHEVCTemporalLevelInfoKey_ProfileIndex, "ProfileIndex")
    cmAssertKeyPayload(kCMHEVCTemporalLevelInfoKey_ProfileSpace, "ProfileSpace")
    cmAssertKeyPayload(kCMHEVCTemporalLevelInfoKey_TemporalLevel, "TemporalLevel")
    cmAssertKeyPayload(kCMHEVCTemporalLevelInfoKey_TierFlag, "TierFlag")
}

func testCMMetadataFormatDescriptionRemainingKeyStrings() {
    cmAssertKeyPayload(kCMMetadataDataType_QuickTimeMetadataDirection, "QuickTimeMetadataDirection")
    cmAssertKeyPayload(kCMMetadataDataType_QuickTimeMetadataLocation_ISO6709, "ISO6709")
    cmAssertKeyPayload(kCMMetadataDataType_QuickTimeMetadataMilliLux, "QuickTimeMetadataMilliLux")
    cmAssertKeyPayload(kCMMetadataDataType_QuickTimeMetadataUUID, "QuickTimeMetadataUUID")
    cmAssertKeyPayload(kCMMetadataFormatDescriptionKey_ConformingDataTypes, "ConformingDataTypes")
    cmAssertKeyPayload(kCMMetadataFormatDescriptionKey_DataTypeNamespace, "DataTypeNamespace")
    cmAssertKeyPayload(kCMMetadataFormatDescriptionKey_LanguageTag, "LanguageTag")
    cmAssertKeyPayload(kCMMetadataFormatDescriptionKey_SetupData, "SetupData")
    cmAssertKeyPayload(kCMMetadataFormatDescriptionKey_StructuralDependency, "StructuralDependency")
    cmAssertKeyPayload(kCMMetadataFormatDescriptionMetadataSpecificationKey_DataType, "DataType")
    cmAssertKeyPayload(kCMMetadataFormatDescriptionMetadataSpecificationKey_ExtendedLanguageTag, "ExtendedLanguageTag")
    cmAssertKeyPayload(kCMMetadataFormatDescriptionMetadataSpecificationKey_SetupData, "SetupData")
    cmAssertKeyPayload(
        kCMMetadataFormatDescriptionMetadataSpecificationKey_StructuralDependency,
        "StructuralDependency"
    )
    cmAssertKeyPayload(
        kCMMetadataFormatDescription_StructuralDependencyKey_DependencyIsInvalidFlag,
        "DependencyIsInvalidFlag"
    )
}

func testCMTimeCodeFormatDescriptionRemainingKeyStrings() {
    cmAssertKeyPayload(kCMTimeCodeFormatDescriptionExtension_SourceReferenceName, "SourceReferenceName")
    cmAssertKeyPayload(kCMTimeCodeFormatDescriptionKey_LangCode, "LangCode")
    cmAssertKeyPayload(kCMTimeCodeFormatDescriptionKey_Value, "Value")
}

func testCMTimebaseNotificationRemainingKeyStrings() {
    cmAssertKeyPayload(kCMTimebaseNotificationKey_EventTime, "EventTime")
    cmAssertKeyPayload(kCMTimebaseNotification_EffectiveRateChanged, "EffectiveRateChanged")
    cmAssertKeyPayload(kCMTimebaseNotification_TimeJumped, "TimeJumped")
    precondition(CFEqual(CMTimebase.NotificationKey.eventTime.rawValue, kCMTimebaseNotificationKey_EventTime))
}
