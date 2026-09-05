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
