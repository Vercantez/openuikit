import CoreFoundation
import CoreMedia
import Foundation

func testMediaTypeFourCCConstants() {
    precondition(kCMMediaType_Video == cmTestFourCC("vide"))
    precondition(kCMMediaType_Audio == cmTestFourCC("soun"))
    precondition(kCMMediaType_Muxed == cmTestFourCC("muxx"))
    precondition(kCMMediaType_Text == cmTestFourCC("text"))
    precondition(kCMMediaType_ClosedCaption == cmTestFourCC("clcp"))
    precondition(kCMMediaType_Subtitle == cmTestFourCC("sbtl"))
    precondition(kCMMediaType_TimeCode == cmTestFourCC("tmcd"))
    precondition(kCMMediaType_Metadata == cmTestFourCC("meta"))
    precondition(kCMMediaType_TaggedBufferGroup == cmTestFourCC("tbgr"))
}

func testVideoCodecFourCCConstants() {
    precondition(kCMVideoCodecType_H264 == cmTestFourCC("avc1"))
    precondition(kCMVideoCodecType_HEVC == cmTestFourCC("hvc1"))
    precondition(kCMVideoCodecType_JPEG == cmTestFourCC("jpeg"))
    precondition(kCMVideoCodecType_AV1 == cmTestFourCC("av01"))
    precondition(kCMVideoCodecType_AppleProRes422 == cmTestFourCC("apcn"))
}

func testPixelFormatConstants() {
    precondition(kCMPixelFormat_32ARGB == 32)
    precondition(kCMPixelFormat_24RGB == 24)
    precondition(kCMPixelFormat_32BGRA == cmTestFourCC("BGRA"))
    precondition(kCMPixelFormat_422YpCbCr8 == cmTestFourCC("2vuy"))
}

func testFormatDescriptionIdentity() {
    let desc = try! CMFormatDescription(
        videoCodecType: .h264,
        width: 1280,
        height: 720,
        extensions: nil
    )
    precondition(desc.mediaType == .video)
    precondition(desc.mediaSubType == .h264)
    precondition(desc.dimensions.width == 1280)
    precondition(desc.dimensions.height == 720)
    precondition(CMFormatDescriptionGetMediaType(desc) == kCMMediaType_Video)
    precondition(CMFormatDescriptionGetMediaSubType(desc) == kCMVideoCodecType_H264)
    let other = try! CMFormatDescription(
        mediaType: .audio,
        mediaSubType: .mpeg4AAC,
        extensions: nil
    )
    precondition(other.mediaType == .audio)
    precondition(!desc.equalTo(other))
    precondition(desc == desc)
    precondition(desc != other)
}

func testFormatDescriptionNegativeDimensionsFailClosed() {
    do {
        _ = try CMFormatDescription(
            videoCodecType: .hevc,
            width: -1,
            height: 10,
            extensions: nil
        )
        preconditionFailure("negative dimensions must fail")
    } catch {
        precondition((error as NSError).code == -12710)
    }
}

func testFormatDescriptionMediaTypeString() {
    let video = CMFormatDescription.MediaType(string: "vide")
    precondition(video == .video)
    precondition(video.description == "vide")
    let h264 = CMFormatDescription.MediaSubType(string: "avc1")
    precondition(h264 == .h264)
}

func testMuxedAndMetadataFormatDescriptions() {
    let muxed = try! CMFormatDescription(
        muxedStreamType: .mpeg2Transport,
        extensions: nil
    )
    precondition(muxed.mediaType == .muxed)
    let meta = try! CMFormatDescription(metadataFormatType: .id3)
    precondition(meta.mediaType == .metadata)
    precondition(meta.mediaSubType == .id3)
}

func testAttachmentModeConstants() {
    precondition(kCMAttachmentMode_ShouldNotPropagate == 0)
    precondition(kCMAttachmentMode_ShouldPropagate == 1)
}

func testCMFormatDescriptionCreateEqualExtensions() {
    var desc: CMFormatDescription?
    precondition(
        CMFormatDescriptionCreate(
            allocator: nil,
            mediaType: kCMMediaType_Video,
            mediaSubType: kCMVideoCodecType_H264,
            extensions: nil,
            formatDescriptionOut: &desc
        ) == 0
    )
    let created = desc!
    precondition(CMFormatDescriptionGetMediaType(created) == kCMMediaType_Video)
    precondition(CMFormatDescriptionGetMediaSubType(created) == kCMVideoCodecType_H264)
    var video: CMFormatDescription?
    precondition(
        CMVideoFormatDescriptionCreate(
            allocator: nil,
            codecType: kCMVideoCodecType_HEVC,
            width: 1920,
            height: 1080,
            extensions: nil,
            formatDescriptionOut: &video
        ) == 0
    )
    let dims = CMVideoFormatDescriptionGetDimensions(video!)
    precondition(dims.width == 1920)
    precondition(dims.height == 1080)
    precondition(CMFormatDescriptionEqual(created, otherFormatDescription: created))
    precondition(!CMFormatDescriptionEqual(created, otherFormatDescription: video))
    precondition(CMFormatDescription.MediaType.video == .video)
    precondition(CMFormatDescription.MediaSubType.h264 == .h264)
    precondition(CMFormatDescription.MediaSubType.mpeg4AAC.rawValue == cmTestFourCC("aac "))
    precondition(CMFormatDescription.MediaSubType.linearPCM.rawValue == cmTestFourCC("lpcm"))
    precondition(CMFormatDescription.Extensions.Key.formatName.rawValue == "FormatName")
    precondition(CFStringGetLength(kCMFormatDescriptionExtension_FormatName) > 0)
    precondition(CFStringGetLength(kCMFormatDescriptionColorPrimaries_ITU_R_709_2) > 0)
    precondition(kCMFormatDescriptionError_InvalidParameter == -12710)
    precondition(kCMFormatDescriptionError_AllocationFailed == -12711)
    precondition(kCMFormatDescriptionError_ValueNotAvailable == -12718)
    precondition(kCMAudioFormatDescriptionMask_StreamBasicDescription == 1)
    precondition(kCMAudioFormatDescriptionMask_All != 0)
    precondition(kCMMPEG2VideoProfile_HDV_720p30 == Int32(bitPattern: cmTestFourCC("hdv1")))
    precondition(kCMMPEG2VideoProfile_XF == Int32(bitPattern: cmTestFourCC("xfz1")))
    var muxed: CMFormatDescription?
    precondition(
        CMMuxedFormatDescriptionCreate(
            allocator: nil,
            muxType: kCMMuxedStreamType_MPEG2Transport,
            extensions: nil,
            formatDescriptionOut: &muxed
        ) == 0
    )
    precondition(muxed!.mediaType == .muxed)
}

func testCMPublicConstantsAndOverlay() {
    precondition(CFStringGetLength(kCMTimeValueKey) > 0)
    precondition(CFStringGetLength(kCMFormatDescriptionExtension_FormatName) > 0)
    precondition(CFStringGetLength(kCMSampleAttachmentKey_NotSync) > 0)
    precondition(CFStringGetLength(kCMMetadataKeySpace_QuickTimeMetadata) > 0)
    precondition(kCMTimeZero == .zero)
    precondition(kCMTimeInvalid == .invalid)
    precondition(kCMTimeRangeZero.isEmpty)
    precondition(kCMBlockBufferNoErr == 0)
    precondition(kCMFormatDescriptionError_InvalidParameter == -12710)
    precondition(kCMSampleBufferError_Invalidated == -12744)
    precondition(kCMClockError_UnsupportedOperation == -12756)
    precondition(kCMTextDisplayFlag_scrollIn == 0x0000_0020)
    precondition(kCMTextJustification_left_top == 0)
    let field = CMFormatDescription.Extensions.Value.FieldDetail.temporalTopFirst
    precondition(CFEqual(field.rawValue, kCMFormatDescriptionFieldDetail_TemporalTopFirst))
    precondition(
        CMFormatDescription.Extensions.Value.YCbCrMatrix.itu_R_709_2.rawValue
            as CFString === kCMFormatDescriptionYCbCrMatrix_ITU_R_709_2
            || CFEqual(
                CMFormatDescription.Extensions.Value.YCbCrMatrix.itu_R_709_2.rawValue,
                kCMFormatDescriptionYCbCrMatrix_ITU_R_709_2
            )
    )
    precondition(
        CMFormatDescription.EqualityMask.all.contains(.streamBasicDescription)
    )
    precondition(CMFormatDescription.TimeCode.Flag.dropFrame.rawValue == 1)
    precondition(
        CFEqual(
            CMSampleBuffer.AttachmentKey.forceKeyFrame.rawValue,
            kCMSampleBufferAttachmentKey_ForceKeyFrame
        )
    )
    precondition(
        CMFormatDescription.Extensions.Value.MPEG2VideoProfile.hdv_720p30.rawValue
            == UInt32(bitPattern: kCMMPEG2VideoProfile_HDV_720p30)
    )
    let buffer = CMBlockBuffer(data: Data([1, 2, 3, 4]))
    var scratch = [CChar](repeating: 0, count: 4)
    var returned: UnsafeMutablePointer<CChar>?
    scratch.withUnsafeMutableBufferPointer { pointer in
        precondition(
            CMBlockBufferAccessDataBytes(
                buffer,
                atOffset: 0,
                length: 4,
                temporaryBlock: pointer.baseAddress!,
                returnedPointerOut: &returned
            ) == 0
        )
    }
    precondition(returned != nil)
    var desc: CMFormatDescription?
    precondition(
        CMFormatDescriptionCreate(
            allocator: nil,
            mediaType: kCMMediaType_Video,
            mediaSubType: kCMVideoCodecType_H264,
            extensions: nil,
            formatDescriptionOut: &desc
        ) == 0
    )
    var copied: CMBlockBuffer?
    precondition(
        CMVideoFormatDescriptionCopyAsBigEndianImageDescriptionBlockBuffer(
            allocator: nil,
            videoFormatDescription: desc!,
            stringEncoding: CFStringBuiltInEncodings.UTF8.rawValue,
            flavor: nil,
            blockBufferOut: &copied
        ) == kCMFormatDescriptionBridgeError_UnsupportedSampleDescriptionFlavor
    )
    precondition(CMVideoFormatDescriptionGetPresentationDimensions(desc!, usePixelAspectRatio: true, useCleanAperture: true).width == 0)
}

func testCMMetadataIdentifierBasics() {
    var identifier: CFString?
    let key = cmMakeCFStringForTest("com.apple.quicktime.location.ISO6709")
    let space = kCMMetadataKeySpace_QuickTimeMetadata
    precondition(
        CMMetadataCreateIdentifierForKeyAndKeySpace(
            allocator: nil,
            key: key,
            keySpace: space,
            identifierOut: &identifier
        ) == 0
    )
    precondition(identifier != nil)
    var keyOut: CFTypeRef?
    precondition(
        CMMetadataCreateKeyFromIdentifier(allocator: nil, identifier: identifier!, keyOut: &keyOut) == 0
    )
    var spaceOut: CFString?
    precondition(
        CMMetadataCreateKeySpaceFromIdentifier(
            allocator: nil,
            identifier: identifier!,
            keySpaceOut: &spaceOut
        ) == 0
    )
    precondition(kCMMetadataIdentifierError_BadKey == -16302)
    precondition(kCMMetadataDataTypeRegistryError_AllocationFailed == -16310)
    precondition(CFStringGetLength(kCMMetadataKeySpace_ID3) > 0)
    precondition(CFStringGetLength(kCMMetadataBaseDataType_UTF8) > 0)
    var meta: CMMetadataFormatDescription?
    precondition(
        CMMetadataFormatDescriptionCreateWithKeys(
            allocator: nil,
            metadataType: kCMMetadataFormatType_Boxed,
            keys: nil,
            formatDescriptionOut: &meta
        ) == 0
    )
    precondition(meta!.mediaType == .metadata)
}

private func cmMakeCFStringForTest(_ string: String) -> CFString {
    string.withCString { pointer in
        CFStringCreateWithCString(
            kCFAllocatorDefault,
            pointer,
            CFStringBuiltInEncodings.UTF8.rawValue
        )!
    }
}

private func cmTestFourCC(_ literal: String) -> UInt32 {
    let bytes = Array(literal.utf8)
    return (UInt32(bytes[0]) << 24) | (UInt32(bytes[1]) << 16)
        | (UInt32(bytes[2]) << 8) | UInt32(bytes[3])
}
