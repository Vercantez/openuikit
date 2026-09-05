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

func testPixelRotationSession() {
    var sourceBGRA: OpaquePointer?
    vtExpectStatus(
        VTHostCreatePixelBuffer(width: 4, height: 4, pixelFormat: kVTPixelFormat_32BGRA, pixelBufferOut: &sourceBGRA),
        0,
        "source"
    )
    vtExpectStatus(VTHostFillPixelBuffer(sourceBGRA, red: 10, green: 20, blue: 30, alpha: 255), 0, "fill")

    var rotation: OpaquePointer?
    vtExpectStatus(VTPixelRotationSessionCreate(sessionOut: &rotation), 0, "VTPixelRotationSessionCreate")
    vtExpectStatus(
        VTSessionSetProperty(rotation, key: kVTPixelRotationPropertyKey_Rotation, value: kVTRotation_CW90),
        0,
        "set rot"
    )
    var rotated: OpaquePointer?
    vtExpectStatus(
        VTHostCreatePixelBuffer(width: 4, height: 4, pixelFormat: kVTPixelFormat_32BGRA, pixelBufferOut: &rotated),
        0,
        "rot dest square"
    )
    vtExpectStatus(VTPixelRotationSessionRotateImage(rotation, source: sourceBGRA, destination: rotated), 0, "VTPixelRotationSessionRotateImage")
    vtExpectStatus(
        VTPixelRotationSessionRotateImage(rotation, source: nil, destination: nil),
        kVTPixelRotationNotSupportedErr,
        "rotate missing"
    )
    vtExpect(VTPixelRotationSessionGetTypeID() == 0, "VTPixelRotationSessionGetTypeID")
    VTPixelRotationSessionInvalidate(rotation)
}
