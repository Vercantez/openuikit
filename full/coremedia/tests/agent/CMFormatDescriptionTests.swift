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

private func cmTestFourCC(_ literal: String) -> UInt32 {
    let bytes = Array(literal.utf8)
    return (UInt32(bytes[0]) << 24) | (UInt32(bytes[1]) << 16)
        | (UInt32(bytes[2]) << 8) | UInt32(bytes[3])
}
