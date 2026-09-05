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
