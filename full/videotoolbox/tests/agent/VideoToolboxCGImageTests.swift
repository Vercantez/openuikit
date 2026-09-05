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

func testCreateCGImageFromPixelBuffer() {
    var sourceBGRA: OpaquePointer?
    vtExpectStatus(
        VTHostCreatePixelBuffer(width: 4, height: 4, pixelFormat: kVTPixelFormat_32BGRA, pixelBufferOut: &sourceBGRA),
        0,
        "source"
    )
    vtExpectStatus(VTHostFillPixelBuffer(sourceBGRA, red: 10, green: 20, blue: 30, alpha: 255), 0, "fill")

    var image: OpaquePointer?
    vtExpectStatus(VTCreateCGImageFromCVPixelBuffer(pixelBuffer: nil, imageOut: &image), kVTParameterErr, "VTCreateCGImageFromCVPixelBuffer nil")
    var image2: OpaquePointer?
    vtExpectStatus(VTCreateCGImageFromCVPixelBuffer(pixelBuffer: sourceBGRA, imageOut: &image2), 0, "VTCreateCGImageFromCVPixelBuffer")
    vtExpect(VTHostCGImageGetWidth(image2) == 4, "cg width")
    vtExpect(VTHostCGImageGetHeight(image2) == 4, "cg height")
    vtExpect(VTHostCGImageGetByte(image2, offset: 0) == 10, "cg red")
    vtExpect(VTHostCGImageGetByte(image2, offset: 1) == 20, "cg green")
    vtExpect(VTHostCGImageGetByte(image2, offset: 2) == 30, "cg blue")
    let fakeBuffer = OpaquePointer(bitPattern: 0x11)!
    var image3: OpaquePointer?
    vtExpectStatus(
        VTCreateCGImageFromCVPixelBuffer(pixelBuffer: fakeBuffer, imageOut: &image3),
        kVTParameterErr,
        "cgimage unknown pointer"
    )
}
