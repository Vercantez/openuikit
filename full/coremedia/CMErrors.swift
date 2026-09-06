import Foundation

// OSStatus integer values from Apple public CoreMedia headers
// (CMBlockBuffer.h -12700..-12708, CMFormatDescription.h -12710/-12711/-12718,
// CMFormatDescriptionBridge.h -12712..-12717/-12719, CMSampleBuffer.h
// -12730..-12744 and DataFailed/Canceled -16750/-16751, CMSync.h
// -12745..-12757, CMBufferQueue.h -12760..-12769, CMSimpleQueue.h
// -12770..-12773, CMMetadata.h -16300..-16315).

public typealias OSStatus = Int32
public typealias FourCharCode = UInt32

public var kCMBlockBufferNoErr: OSStatus { 0 }
public var kCMBlockBufferStructureAllocationFailedErr: OSStatus { -12700 }
public var kCMBlockBufferBlockAllocationFailedErr: OSStatus { -12701 }
public var kCMBlockBufferBadCustomBlockSourceErr: OSStatus { -12702 }
public var kCMBlockBufferBadOffsetParameterErr: OSStatus { -12703 }
public var kCMBlockBufferBadLengthParameterErr: OSStatus { -12704 }
public var kCMBlockBufferBadPointerParameterErr: OSStatus { -12705 }
public var kCMBlockBufferEmptyBBufErr: OSStatus { -12706 }
public var kCMBlockBufferUnallocatedBlockErr: OSStatus { -12707 }
public var kCMBlockBufferInsufficientSpaceErr: OSStatus { -12708 }
public var kCMFormatDescriptionError_InvalidParameter: OSStatus { -12710 }
public var kCMFormatDescriptionError_AllocationFailed: OSStatus { -12711 }
public var kCMFormatDescriptionBridgeError_InvalidParameter: OSStatus { -12712 }
public var kCMFormatDescriptionBridgeError_AllocationFailed: OSStatus { -12713 }
public var kCMFormatDescriptionBridgeError_InvalidSerializedSampleDescription: OSStatus { -12714 }
public var kCMFormatDescriptionBridgeError_InvalidFormatDescription: OSStatus { -12715 }
public var kCMFormatDescriptionBridgeError_IncompatibleFormatDescription: OSStatus { -12716 }
public var kCMFormatDescriptionBridgeError_UnsupportedSampleDescriptionFlavor: OSStatus { -12717 }
public var kCMFormatDescriptionError_ValueNotAvailable: OSStatus { -12718 }
public var kCMFormatDescriptionBridgeError_InvalidSlice: OSStatus { -12719 }
public var kCMSampleBufferError_AllocationFailed: OSStatus { -12730 }
public var kCMSampleBufferError_RequiredParameterMissing: OSStatus { -12731 }
public var kCMSampleBufferError_AlreadyHasDataBuffer: OSStatus { -12732 }
public var kCMSampleBufferError_BufferNotReady: OSStatus { -12733 }
public var kCMSampleBufferError_SampleIndexOutOfRange: OSStatus { -12734 }
public var kCMSampleBufferError_BufferHasNoSampleSizes: OSStatus { -12735 }
public var kCMSampleBufferError_BufferHasNoSampleTimingInfo: OSStatus { -12736 }
public var kCMSampleBufferError_ArrayTooSmall: OSStatus { -12737 }
public var kCMSampleBufferError_InvalidEntryCount: OSStatus { -12738 }
public var kCMSampleBufferError_CannotSubdivide: OSStatus { -12739 }
public var kCMSampleBufferError_SampleTimingInfoInvalid: OSStatus { -12740 }
public var kCMSampleBufferError_InvalidMediaTypeForOperation: OSStatus { -12741 }
public var kCMSampleBufferError_InvalidSampleData: OSStatus { -12742 }
public var kCMSampleBufferError_InvalidMediaFormat: OSStatus { -12743 }
public var kCMSampleBufferError_Invalidated: OSStatus { -12744 }
public var kCMClockError_MissingRequiredParameter: OSStatus { -12745 }
public var kCMClockError_InvalidParameter: OSStatus { -12746 }
public var kCMClockError_AllocationFailed: OSStatus { -12747 }
public var kCMTimebaseError_MissingRequiredParameter: OSStatus { -12748 }
public var kCMTimebaseError_InvalidParameter: OSStatus { -12749 }
public var kCMTimebaseError_AllocationFailed: OSStatus { -12750 }
public var kCMTimebaseError_TimerIntervalTooShort: OSStatus { -12751 }
public var kCMSyncError_MissingRequiredParameter: OSStatus { -12752 }
public var kCMSyncError_InvalidParameter: OSStatus { -12753 }
public var kCMSyncError_AllocationFailed: OSStatus { -12754 }
public var kCMSyncError_RateMustBeNonZero: OSStatus { -12755 }
public var kCMClockError_UnsupportedOperation: OSStatus { -12756 }
public var kCMTimebaseError_ReadOnly: OSStatus { -12757 }
public var kCMBufferQueueError_AllocationFailed: OSStatus { -12760 }
public var kCMBufferQueueError_RequiredParameterMissing: OSStatus { -12761 }
public var kCMBufferQueueError_InvalidCMBufferCallbacksStruct: OSStatus { -12762 }
public var kCMBufferQueueError_EnqueueAfterEndOfData: OSStatus { -12763 }
public var kCMBufferQueueError_QueueIsFull: OSStatus { -12764 }
public var kCMBufferQueueError_BadTriggerDuration: OSStatus { -12765 }
public var kCMBufferQueueError_CannotModifyQueueFromTriggerCallback: OSStatus { -12766 }
public var kCMBufferQueueError_InvalidTriggerCondition: OSStatus { -12767 }
public var kCMBufferQueueError_InvalidTriggerToken: OSStatus { -12768 }
public var kCMBufferQueueError_InvalidBuffer: OSStatus { -12769 }

// Trigger-condition integers from the public CMBufferQueue.h enumeration.
public var kCMBufferQueueTrigger_WhenDurationBecomesLessThan: CMBufferQueueTriggerCondition { 1 }
public var kCMBufferQueueTrigger_WhenDurationBecomesLessThanOrEqualTo: CMBufferQueueTriggerCondition { 2 }
public var kCMBufferQueueTrigger_WhenDurationBecomesGreaterThan: CMBufferQueueTriggerCondition { 3 }
public var kCMBufferQueueTrigger_WhenDurationBecomesGreaterThanOrEqualTo: CMBufferQueueTriggerCondition { 4 }
public var kCMBufferQueueTrigger_WhenMinPresentationTimeStampChanges: CMBufferQueueTriggerCondition { 5 }
public var kCMBufferQueueTrigger_WhenMaxPresentationTimeStampChanges: CMBufferQueueTriggerCondition { 6 }
public var kCMBufferQueueTrigger_WhenDataBecomesReady: CMBufferQueueTriggerCondition { 7 }
public var kCMBufferQueueTrigger_WhenEndOfDataReached: CMBufferQueueTriggerCondition { 8 }
public var kCMBufferQueueTrigger_WhenReset: CMBufferQueueTriggerCondition { 9 }
public var kCMBufferQueueTrigger_WhenBufferCountBecomesLessThan: CMBufferQueueTriggerCondition { 10 }
public var kCMBufferQueueTrigger_WhenBufferCountBecomesGreaterThan: CMBufferQueueTriggerCondition { 11 }
public var kCMBufferQueueTrigger_WhenDurationBecomesGreaterThanOrEqualToAndBufferCountBecomesGreaterThan: CMBufferQueueTriggerCondition { 12 }
public var kCMSimpleQueueError_AllocationFailed: OSStatus { -12770 }
public var kCMSimpleQueueError_RequiredParameterMissing: OSStatus { -12771 }
public var kCMSimpleQueueError_ParameterOutOfRange: OSStatus { -12772 }
public var kCMSimpleQueueError_QueueIsFull: OSStatus { -12773 }
public var kCMSampleBufferError_DataFailed: OSStatus { -16750 }
public var kCMSampleBufferError_DataCanceled: OSStatus { -16751 }
public var kCMMetadataIdentifierError_AllocationFailed: OSStatus { -16300 }
public var kCMMetadataIdentifierError_RequiredParameterMissing: OSStatus { -16301 }
public var kCMMetadataIdentifierError_BadKey: OSStatus { -16302 }
public var kCMMetadataIdentifierError_BadKeyLength: OSStatus { -16303 }
public var kCMMetadataIdentifierError_BadKeyType: OSStatus { -16304 }
public var kCMMetadataIdentifierError_BadNumberKey: OSStatus { -16305 }
public var kCMMetadataIdentifierError_BadKeySpace: OSStatus { -16306 }
public var kCMMetadataIdentifierError_BadIdentifier: OSStatus { -16307 }
public var kCMMetadataIdentifierError_NoKeyValueAvailable: OSStatus { -16308 }
public var kCMMetadataDataTypeRegistryError_AllocationFailed: OSStatus { -16310 }
public var kCMMetadataDataTypeRegistryError_RequiredParameterMissing: OSStatus { -16311 }
public var kCMMetadataDataTypeRegistryError_BadDataTypeIdentifier: OSStatus { -16312 }
public var kCMMetadataDataTypeRegistryError_DataTypeAlreadyRegistered: OSStatus { -16313 }
public var kCMMetadataDataTypeRegistryError_RequiresConformingBaseType: OSStatus { -16314 }
public var kCMMetadataDataTypeRegistryError_MultipleConformingBaseTypes: OSStatus { -16315 }

public var kCMAudioFormatDescriptionMask_StreamBasicDescription: CMAudioFormatDescriptionMask { 1 << 0 }
public var kCMAudioFormatDescriptionMask_MagicCookie: CMAudioFormatDescriptionMask { 1 << 1 }
public var kCMAudioFormatDescriptionMask_ChannelLayout: CMAudioFormatDescriptionMask { 1 << 2 }
public var kCMAudioFormatDescriptionMask_Extensions: CMAudioFormatDescriptionMask { 1 << 3 }
public var kCMAudioFormatDescriptionMask_All: CMAudioFormatDescriptionMask { kCMAudioFormatDescriptionMask_StreamBasicDescription | kCMAudioFormatDescriptionMask_MagicCookie | kCMAudioFormatDescriptionMask_ChannelLayout | kCMAudioFormatDescriptionMask_Extensions }

// MPEG-2 profile FourCCs from CMFormatDescription.h char literals.
public var kCMMPEG2VideoProfile_HDV_720p30: Int32 { Int32(bitPattern: cmFourCC("hdv1")) }
public var kCMMPEG2VideoProfile_HDV_1080i60: Int32 { Int32(bitPattern: cmFourCC("hdv2")) }
public var kCMMPEG2VideoProfile_HDV_1080i50: Int32 { Int32(bitPattern: cmFourCC("hdv3")) }
public var kCMMPEG2VideoProfile_HDV_720p24: Int32 { Int32(bitPattern: cmFourCC("hdv4")) }
public var kCMMPEG2VideoProfile_HDV_720p25: Int32 { Int32(bitPattern: cmFourCC("hdv5")) }
public var kCMMPEG2VideoProfile_HDV_1080p24: Int32 { Int32(bitPattern: cmFourCC("hdv6")) }
public var kCMMPEG2VideoProfile_HDV_1080p25: Int32 { Int32(bitPattern: cmFourCC("hdv7")) }
public var kCMMPEG2VideoProfile_HDV_1080p30: Int32 { Int32(bitPattern: cmFourCC("hdv8")) }
public var kCMMPEG2VideoProfile_HDV_720p60: Int32 { Int32(bitPattern: cmFourCC("hdv9")) }
public var kCMMPEG2VideoProfile_HDV_720p50: Int32 { Int32(bitPattern: cmFourCC("hdva")) }
public var kCMMPEG2VideoProfile_XDCAM_HD_1080i60_VBR35: Int32 { Int32(bitPattern: cmFourCC("xdv2")) }
public var kCMMPEG2VideoProfile_XDCAM_HD_1080i50_VBR35: Int32 { Int32(bitPattern: cmFourCC("xdv3")) }
public var kCMMPEG2VideoProfile_XDCAM_HD_1080p24_VBR35: Int32 { Int32(bitPattern: cmFourCC("xdv6")) }
public var kCMMPEG2VideoProfile_XDCAM_HD_1080p25_VBR35: Int32 { Int32(bitPattern: cmFourCC("xdv7")) }
public var kCMMPEG2VideoProfile_XDCAM_HD_1080p30_VBR35: Int32 { Int32(bitPattern: cmFourCC("xdv8")) }
public var kCMMPEG2VideoProfile_XDCAM_EX_720p24_VBR35: Int32 { Int32(bitPattern: cmFourCC("xdv4")) }
public var kCMMPEG2VideoProfile_XDCAM_EX_720p25_VBR35: Int32 { Int32(bitPattern: cmFourCC("xdv5")) }
public var kCMMPEG2VideoProfile_XDCAM_EX_720p30_VBR35: Int32 { Int32(bitPattern: cmFourCC("xdv1")) }
public var kCMMPEG2VideoProfile_XDCAM_EX_720p50_VBR35: Int32 { Int32(bitPattern: cmFourCC("xdva")) }
public var kCMMPEG2VideoProfile_XDCAM_EX_720p60_VBR35: Int32 { Int32(bitPattern: cmFourCC("xdv9")) }
public var kCMMPEG2VideoProfile_XDCAM_EX_1080i60_VBR35: Int32 { Int32(bitPattern: cmFourCC("xdvb")) }
public var kCMMPEG2VideoProfile_XDCAM_EX_1080i50_VBR35: Int32 { Int32(bitPattern: cmFourCC("xdvc")) }
public var kCMMPEG2VideoProfile_XDCAM_EX_1080p24_VBR35: Int32 { Int32(bitPattern: cmFourCC("xdvd")) }
public var kCMMPEG2VideoProfile_XDCAM_EX_1080p25_VBR35: Int32 { Int32(bitPattern: cmFourCC("xdve")) }
public var kCMMPEG2VideoProfile_XDCAM_EX_1080p30_VBR35: Int32 { Int32(bitPattern: cmFourCC("xdvf")) }
public var kCMMPEG2VideoProfile_XDCAM_HD422_720p50_CBR50: Int32 { Int32(bitPattern: cmFourCC("xd5a")) }
public var kCMMPEG2VideoProfile_XDCAM_HD422_720p60_CBR50: Int32 { Int32(bitPattern: cmFourCC("xd59")) }
public var kCMMPEG2VideoProfile_XDCAM_HD422_1080i60_CBR50: Int32 { Int32(bitPattern: cmFourCC("xd5b")) }
public var kCMMPEG2VideoProfile_XDCAM_HD422_1080i50_CBR50: Int32 { Int32(bitPattern: cmFourCC("xd5c")) }
public var kCMMPEG2VideoProfile_XDCAM_HD422_1080p24_CBR50: Int32 { Int32(bitPattern: cmFourCC("xd5d")) }
public var kCMMPEG2VideoProfile_XDCAM_HD422_1080p25_CBR50: Int32 { Int32(bitPattern: cmFourCC("xd5e")) }
public var kCMMPEG2VideoProfile_XDCAM_HD422_1080p30_CBR50: Int32 { Int32(bitPattern: cmFourCC("xd5f")) }
public var kCMMPEG2VideoProfile_XDCAM_HD_540p: Int32 { Int32(bitPattern: cmFourCC("xdhd")) }
public var kCMMPEG2VideoProfile_XDCAM_HD422_540p: Int32 { Int32(bitPattern: cmFourCC("xdh2")) }
public var kCMMPEG2VideoProfile_XDCAM_HD422_720p24_CBR50: Int32 { Int32(bitPattern: cmFourCC("xd54")) }
public var kCMMPEG2VideoProfile_XDCAM_HD422_720p25_CBR50: Int32 { Int32(bitPattern: cmFourCC("xd55")) }
public var kCMMPEG2VideoProfile_XDCAM_HD422_720p30_CBR50: Int32 { Int32(bitPattern: cmFourCC("xd51")) }
public var kCMMPEG2VideoProfile_XF: Int32 { Int32(bitPattern: cmFourCC("xfz1")) }
