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
