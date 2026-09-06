import CoreFoundation
import CoreMedia
import Foundation

func testCMAudioFormatDescriptionEqualSummaryAndMagicCookie() {
    var first: CMAudioFormatDescription?
    var second: CMAudioFormatDescription?
    precondition(
        CMFormatDescriptionCreate(
            allocator: nil,
            mediaType: kCMMediaType_Audio,
            mediaSubType: kCMAudioCodecType_AAC_LCProtected,
            extensions: nil,
            formatDescriptionOut: &first
        ) == 0
    )
    precondition(
        CMFormatDescriptionCreate(
            allocator: nil,
            mediaType: kCMMediaType_Audio,
            mediaSubType: kCMAudioCodecType_AAC_AudibleProtected,
            extensions: nil,
            formatDescriptionOut: &second
        ) == 0
    )
    var mask: CMAudioFormatDescriptionMask = 0
    precondition(
        CMAudioFormatDescriptionEqual(
            first!,
            otherFormatDescription: first!,
            equalityMask: kCMAudioFormatDescriptionMask_All,
            equalityMaskOut: &mask
        )
    )
    precondition((mask & kCMAudioFormatDescriptionMask_StreamBasicDescription) != 0)
    precondition((mask & kCMAudioFormatDescriptionMask_MagicCookie) != 0)
    precondition(
        !CMAudioFormatDescriptionEqual(
            first!,
            otherFormatDescription: second!,
            equalityMask: kCMAudioFormatDescriptionMask_StreamBasicDescription,
            equalityMaskOut: &mask
        )
    )
    let array = CFArrayCreateMutable(kCFAllocatorDefault, 1, nil)!
    CFArrayAppendValue(array, unsafeBitCast(first!, to: UnsafeRawPointer.self))
    var summary: CMAudioFormatDescription?
    precondition(
        CMAudioFormatDescriptionCreateSummary(
            allocator: nil,
            formatDescriptionArray: array,
            flags: 0,
            formatDescriptionOut: &summary
        ) == 0
    )
    precondition(summary!.mediaType == .audio)
    var cookieSize = 99
    precondition(CMAudioFormatDescriptionGetMagicCookie(first!, sizeOut: &cookieSize) == nil)
    precondition(cookieSize == 0)
    let observed: Int? = first!.withMagicCookie { pointer in
        pointer.map(\.count)
    }
    precondition(observed == nil)
    precondition(
        CMFormatDescription.EqualityMask.magicCookie.rawValue == kCMAudioFormatDescriptionMask_MagicCookie
    )
    precondition(
        CMFormatDescription.EqualityMask.channelLayout.rawValue == kCMAudioFormatDescriptionMask_ChannelLayout
    )
    precondition(
        CMFormatDescription.EqualityMask.streamBasicDescription.rawValue
            == kCMAudioFormatDescriptionMask_StreamBasicDescription
    )
    precondition(
        CMFormatDescription.EqualityMask.extensions.rawValue == kCMAudioFormatDescriptionMask_Extensions
    )
    precondition(CMFormatDescription.EqualityMask.all.rawValue == kCMAudioFormatDescriptionMask_All)
    let constructed = CMFormatDescription.EqualityMask(rawValue: kCMAudioFormatDescriptionMask_MagicCookie)
    precondition(constructed.rawValue == kCMAudioFormatDescriptionMask_MagicCookie)
}

func testCMAudioFormatDescriptionEndianBridgeFailClosed() {
    let buffer = CMBlockBuffer(data: Data([0, 1, 2, 3]))
    var desc: CMAudioFormatDescription?
    var outBuffer: CMBlockBuffer?
    let audio = try! CMFormatDescription(
        mediaType: .audio,
        mediaSubType: .mpeg4AAC,
        extensions: nil
    )
    precondition(
        CMAudioFormatDescriptionCopyAsBigEndianSoundDescriptionBlockBuffer(
            allocator: nil,
            audioFormatDescription: audio,
            flavor: nil,
            blockBufferOut: &outBuffer
        ) == kCMFormatDescriptionBridgeError_UnsupportedSampleDescriptionFlavor
    )
    precondition(
        CMAudioFormatDescriptionCreateFromBigEndianSoundDescriptionBlockBuffer(
            allocator: nil,
            bigEndianSoundDescriptionBlockBuffer: buffer,
            flavor: nil,
            formatDescriptionOut: &desc
        ) == kCMFormatDescriptionBridgeError_UnsupportedSampleDescriptionFlavor
    )
    let bytes: [UInt8] = [0, 1, 2, 3]
    precondition(
        bytes.withUnsafeBufferPointer { raw in
            CMAudioFormatDescriptionCreateFromBigEndianSoundDescriptionData(
                allocator: nil,
                bigEndianSoundDescriptionData: raw.baseAddress!,
                size: raw.count,
                flavor: nil,
                formatDescriptionOut: &desc
            )
        } == kCMFormatDescriptionBridgeError_UnsupportedSampleDescriptionFlavor
    )
}

func testCMMPEG2VideoProfileFourCCConstants() {
    func fourCC(_ literal: String) -> Int32 {
        let bytes = Array(literal.utf8)
        return Int32(bitPattern: (UInt32(bytes[0]) << 24) | (UInt32(bytes[1]) << 16)
            | (UInt32(bytes[2]) << 8) | UInt32(bytes[3]))
    }
    precondition(kCMMPEG2VideoProfile_HDV_720p30 == fourCC("hdv1"))
    precondition(kCMMPEG2VideoProfile_HDV_1080i60 == fourCC("hdv2"))
    precondition(kCMMPEG2VideoProfile_HDV_1080i50 == fourCC("hdv3"))
    precondition(kCMMPEG2VideoProfile_HDV_720p24 == fourCC("hdv4"))
    precondition(kCMMPEG2VideoProfile_HDV_720p25 == fourCC("hdv5"))
    precondition(kCMMPEG2VideoProfile_HDV_1080p24 == fourCC("hdv6"))
    precondition(kCMMPEG2VideoProfile_HDV_1080p25 == fourCC("hdv7"))
    precondition(kCMMPEG2VideoProfile_HDV_1080p30 == fourCC("hdv8"))
    precondition(kCMMPEG2VideoProfile_HDV_720p60 == fourCC("hdv9"))
    precondition(kCMMPEG2VideoProfile_HDV_720p50 == fourCC("hdva"))
    precondition(kCMMPEG2VideoProfile_XDCAM_HD_1080i60_VBR35 == fourCC("xdv2"))
    precondition(kCMMPEG2VideoProfile_XDCAM_HD_1080i50_VBR35 == fourCC("xdv3"))
    precondition(kCMMPEG2VideoProfile_XDCAM_HD_1080p24_VBR35 == fourCC("xdv6"))
    precondition(kCMMPEG2VideoProfile_XDCAM_HD_1080p25_VBR35 == fourCC("xdv7"))
    precondition(kCMMPEG2VideoProfile_XDCAM_HD_1080p30_VBR35 == fourCC("xdv8"))
    precondition(kCMMPEG2VideoProfile_XDCAM_EX_720p24_VBR35 == fourCC("xdv4"))
    precondition(kCMMPEG2VideoProfile_XDCAM_EX_720p25_VBR35 == fourCC("xdv5"))
    precondition(kCMMPEG2VideoProfile_XDCAM_EX_720p30_VBR35 == fourCC("xdv1"))
    precondition(kCMMPEG2VideoProfile_XDCAM_EX_720p50_VBR35 == fourCC("xdva"))
    precondition(kCMMPEG2VideoProfile_XDCAM_EX_720p60_VBR35 == fourCC("xdv9"))
    precondition(kCMMPEG2VideoProfile_XDCAM_EX_1080i60_VBR35 == fourCC("xdvb"))
    precondition(kCMMPEG2VideoProfile_XDCAM_EX_1080i50_VBR35 == fourCC("xdvc"))
    precondition(kCMMPEG2VideoProfile_XDCAM_EX_1080p24_VBR35 == fourCC("xdvd"))
    precondition(kCMMPEG2VideoProfile_XDCAM_EX_1080p25_VBR35 == fourCC("xdve"))
    precondition(kCMMPEG2VideoProfile_XDCAM_EX_1080p30_VBR35 == fourCC("xdvf"))
    precondition(kCMMPEG2VideoProfile_XDCAM_HD422_720p50_CBR50 == fourCC("xd5a"))
    precondition(kCMMPEG2VideoProfile_XDCAM_HD422_720p60_CBR50 == fourCC("xd59"))
    precondition(kCMMPEG2VideoProfile_XDCAM_HD422_1080i60_CBR50 == fourCC("xd5b"))
    precondition(kCMMPEG2VideoProfile_XDCAM_HD422_1080i50_CBR50 == fourCC("xd5c"))
    precondition(kCMMPEG2VideoProfile_XDCAM_HD422_1080p24_CBR50 == fourCC("xd5d"))
    precondition(kCMMPEG2VideoProfile_XDCAM_HD422_1080p25_CBR50 == fourCC("xd5e"))
    precondition(kCMMPEG2VideoProfile_XDCAM_HD422_1080p30_CBR50 == fourCC("xd5f"))
    precondition(kCMMPEG2VideoProfile_XDCAM_HD_540p == fourCC("xdhd"))
    precondition(kCMMPEG2VideoProfile_XDCAM_HD422_540p == fourCC("xdh2"))
    precondition(kCMMPEG2VideoProfile_XDCAM_HD422_720p24_CBR50 == fourCC("xd54"))
    precondition(kCMMPEG2VideoProfile_XDCAM_HD422_720p25_CBR50 == fourCC("xd55"))
    precondition(kCMMPEG2VideoProfile_XDCAM_HD422_720p30_CBR50 == fourCC("xd51"))
    precondition(kCMMPEG2VideoProfile_XF == fourCC("xfz1"))
}

func testCMBlockBufferFlagAndErrorConstants() {
    precondition(kCMBlockBufferAlwaysCopyDataFlag == 1 << 1)
    precondition(kCMBlockBufferDontOptimizeDepthFlag == 1 << 2)
    precondition(kCMBlockBufferPermitEmptyReferenceFlag == 1 << 3)
    precondition(kCMBlockBufferCustomBlockSourceVersion == 1)
    precondition(CMBlockBuffer.Flags.alwaysCopyData.rawValue == kCMBlockBufferAlwaysCopyDataFlag)
    precondition(CMBlockBuffer.Flags.dontOptimizeDepth.rawValue == kCMBlockBufferDontOptimizeDepthFlag)
    precondition(CMBlockBuffer.Flags.permitEmptyReference.rawValue == kCMBlockBufferPermitEmptyReferenceFlag)
    precondition(kCMBlockBufferNoErr == 0)
    precondition(kCMBlockBufferStructureAllocationFailedErr == -12700)
    precondition(kCMBlockBufferBlockAllocationFailedErr == -12701)
    precondition(kCMBlockBufferBadCustomBlockSourceErr == -12702)
    precondition(kCMBlockBufferBadOffsetParameterErr == -12703)
    precondition(kCMBlockBufferBadLengthParameterErr == -12704)
    precondition(kCMBlockBufferBadPointerParameterErr == -12705)
    precondition(kCMBlockBufferEmptyBBufErr == -12706)
    precondition(kCMBlockBufferUnallocatedBlockErr == -12707)
    precondition(kCMBlockBufferInsufficientSpaceErr == -12708)
}

func testCMSampleBufferAndFormatBridgeErrorConstants() {
    precondition(kCMSampleBufferError_AllocationFailed == -12730)
    precondition(kCMSampleBufferError_RequiredParameterMissing == -12731)
    precondition(kCMSampleBufferError_AlreadyHasDataBuffer == -12732)
    precondition(kCMSampleBufferError_BufferNotReady == -12733)
    precondition(kCMSampleBufferError_SampleIndexOutOfRange == -12734)
    precondition(kCMSampleBufferError_BufferHasNoSampleSizes == -12735)
    precondition(kCMSampleBufferError_BufferHasNoSampleTimingInfo == -12736)
    precondition(kCMSampleBufferError_ArrayTooSmall == -12737)
    precondition(kCMSampleBufferError_InvalidEntryCount == -12738)
    precondition(kCMSampleBufferError_CannotSubdivide == -12739)
    precondition(kCMSampleBufferError_SampleTimingInfoInvalid == -12740)
    precondition(kCMSampleBufferError_InvalidMediaTypeForOperation == -12741)
    precondition(kCMSampleBufferError_InvalidSampleData == -12742)
    precondition(kCMSampleBufferError_InvalidMediaFormat == -12743)
    precondition(kCMSampleBufferError_Invalidated == -12744)
    precondition(kCMSampleBufferError_DataFailed == -16750)
    precondition(kCMSampleBufferError_DataCanceled == -16751)
    precondition(kCMFormatDescriptionError_InvalidParameter == -12710)
    precondition(kCMFormatDescriptionError_AllocationFailed == -12711)
    precondition(kCMFormatDescriptionBridgeError_InvalidParameter == -12712)
    precondition(kCMFormatDescriptionBridgeError_AllocationFailed == -12713)
    precondition(kCMFormatDescriptionBridgeError_InvalidSerializedSampleDescription == -12714)
    precondition(kCMFormatDescriptionBridgeError_InvalidFormatDescription == -12715)
    precondition(kCMFormatDescriptionBridgeError_IncompatibleFormatDescription == -12716)
    precondition(kCMFormatDescriptionBridgeError_UnsupportedSampleDescriptionFlavor == -12717)
    precondition(kCMFormatDescriptionError_ValueNotAvailable == -12718)
    precondition(kCMFormatDescriptionBridgeError_InvalidSlice == -12719)
    precondition(kCMMetadataIdentifierError_AllocationFailed == -16300)
    precondition(kCMMetadataIdentifierError_RequiredParameterMissing == -16301)
    precondition(kCMMetadataIdentifierError_BadKey == -16302)
    precondition(kCMMetadataIdentifierError_BadKeyLength == -16303)
    precondition(kCMMetadataIdentifierError_BadKeyType == -16304)
    precondition(kCMMetadataIdentifierError_BadNumberKey == -16305)
    precondition(kCMMetadataIdentifierError_BadKeySpace == -16306)
    precondition(kCMMetadataIdentifierError_BadIdentifier == -16307)
    precondition(kCMMetadataIdentifierError_NoKeyValueAvailable == -16308)
    precondition(kCMMetadataDataTypeRegistryError_AllocationFailed == -16310)
    precondition(kCMMetadataDataTypeRegistryError_RequiredParameterMissing == -16311)
    precondition(kCMMetadataDataTypeRegistryError_BadDataTypeIdentifier == -16312)
    precondition(kCMMetadataDataTypeRegistryError_DataTypeAlreadyRegistered == -16313)
    precondition(kCMMetadataDataTypeRegistryError_RequiresConformingBaseType == -16314)
    precondition(kCMMetadataDataTypeRegistryError_MultipleConformingBaseTypes == -16315)
}

func testCMFormatDescriptionCameraCalibrationKeyStrings() {
    func payload(_ key: CFString, _ expected: String) {
        let other = expected.withCString { pointer in
            CFStringCreateWithCString(
                kCFAllocatorDefault,
                pointer,
                CFStringBuiltInEncodings.UTF8.rawValue
            )!
        }
        precondition(CFEqual(key, other))
    }
    payload(kCMFormatDescriptionAlphaChannelMode_PremultipliedAlpha, "PremultipliedAlpha")
    payload(kCMFormatDescriptionAlphaChannelMode_StraightAlpha, "StraightAlpha")
    payload(
        kCMFormatDescriptionCameraCalibrationExtrinsicOriginSource_StereoCameraSystemBaseline,
        "StereoCameraSystemBaseline"
    )
    payload(kCMFormatDescriptionCameraCalibrationLensAlgorithmKind_ParametricLens, "ParametricLens")
    payload(kCMFormatDescriptionCameraCalibrationLensDomain_Color, "Color")
    payload(kCMFormatDescriptionCameraCalibrationLensRole_Left, "Left")
    payload(kCMFormatDescriptionCameraCalibrationLensRole_Mono, "Mono")
    payload(kCMFormatDescriptionCameraCalibrationLensRole_Right, "Right")
    payload(
        kCMFormatDescriptionCameraCalibration_ExtrinsicOrientationQuaternion,
        "ExtrinsicOrientationQuaternion"
    )
    payload(kCMFormatDescriptionCameraCalibration_ExtrinsicOriginSource, "ExtrinsicOriginSource")
    payload(kCMFormatDescriptionCameraCalibration_IntrinsicMatrix, "IntrinsicMatrix")
    payload(
        kCMFormatDescriptionCameraCalibration_IntrinsicMatrixProjectionOffset,
        "IntrinsicMatrixProjectionOffset"
    )
    payload(
        kCMFormatDescriptionCameraCalibration_IntrinsicMatrixReferenceDimensions,
        "IntrinsicMatrixReferenceDimensions"
    )
    payload(kCMFormatDescriptionCameraCalibration_LensAlgorithmKind, "LensAlgorithmKind")
    payload(kCMFormatDescriptionCameraCalibration_LensDistortions, "LensDistortions")
    payload(kCMFormatDescriptionCameraCalibration_LensDomain, "LensDomain")
    payload(
        kCMFormatDescriptionCameraCalibration_LensFrameAdjustmentsPolynomialX,
        "LensFrameAdjustmentsPolynomialX"
    )
    payload(
        kCMFormatDescriptionCameraCalibration_LensFrameAdjustmentsPolynomialY,
        "LensFrameAdjustmentsPolynomialY"
    )
    payload(kCMFormatDescriptionCameraCalibration_LensIdentifier, "LensIdentifier")
    payload(kCMFormatDescriptionCameraCalibration_LensRole, "LensRole")
    payload(kCMFormatDescriptionCameraCalibration_RadialAngleLimit, "RadialAngleLimit")
}

func testCMBlockBufferCustomAllocatorCopiesAndFrees() {
    final class AllocatorBox: @unchecked Sendable {
        var allocated = false
        var freed = false
    }
    let box = AllocatorBox()
    var source = CMBlockBufferCustomBlockSource(
        version: kCMBlockBufferCustomBlockSourceVersion,
        AllocateBlock: { _, length in
            box.allocated = true
            let pointer = UnsafeMutableRawPointer.allocate(byteCount: length, alignment: 1)
            pointer.initializeMemory(as: UInt8.self, repeating: 7, count: length)
            return pointer
        },
        FreeBlock: { _, pointer, _ in
            box.freed = true
            pointer.deallocate()
        },
        refCon: nil
    )
    var buffer: CMBlockBuffer?
    precondition(
        withUnsafePointer(to: &source) { pointer in
            CMBlockBufferCreateWithMemoryBlock(
                allocator: nil,
                memoryBlock: nil,
                blockLength: 4,
                blockAllocator: nil,
                customBlockSource: pointer,
                offsetToData: 0,
                dataLength: 4,
                flags: kCMBlockBufferAlwaysCopyDataFlag,
                blockBufferOut: &buffer
            )
        } == 0
    )
    precondition(box.allocated)
    precondition(box.freed)
    precondition(CMBlockBufferGetDataLength(buffer!) == 4)
    var dest = [UInt8](repeating: 0, count: 4)
    dest.withUnsafeMutableBytes { raw in
        precondition(
            CMBlockBufferCopyDataBytes(buffer!, atOffset: 0, dataLength: 4, destination: raw.baseAddress!)
                == 0
        )
    }
    precondition(dest == [7, 7, 7, 7])
}
