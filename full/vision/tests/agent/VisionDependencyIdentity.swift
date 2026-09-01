// Future EC2 dependency-identity client. Isolated host compilation of
// VisionRuntime.swift does not import CoreGraphics/CoreImage; this probe is
// the client that run must compile against the real guest modules and
// libVision.dylib.
//
// Expected EC2 flow (no local Docker):
//   1. Build guest CoreGraphics, CoreImage, and Foundation modules/dylibs.
//   2. Build Vision with those -I/-L paths.
//   3. Link this file importing Vision + CoreGraphics + CoreImage + Foundation.
//   4. Pass real CoreGraphics CGPoint/CGRect values through public observation
//      APIs. Do not pass substitute image types: CIImage/CGImage handler
//      overloads stay absent in this partition.
//   5. Run with LD_LIBRARY_PATH and confirm libVision.dylib is loaded.

import CoreGraphics
import CoreImage
import Foundation
import Vision

@inline(__always)
func _coreGraphicsRect(_ rect: CGRect) -> CoreGraphics.CGRect {
    rect
}

@inline(__always)
func _coreGraphicsPoint(_ point: CGPoint) -> CoreGraphics.CGPoint {
    point
}

let box = VNDetectedObjectObservation(
    boundingBox: _coreGraphicsRect(CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4))
)
let geometry: CoreGraphics.CGRect = box.boundingBox
precondition(geometry.origin.x == 0.1)
precondition(geometry.size.width == 0.3)
let origin: CoreGraphics.CGPoint = box.boundingBox.origin
precondition(origin.y == 0.2)

let mapped = VNImageRectForNormalizedRect(geometry, 100, 50)
let mappedAsCoreGraphics: CoreGraphics.CGRect = mapped
precondition(mappedAsCoreGraphics.origin.x == 10)
precondition(mappedAsCoreGraphics.size.height == 20)

let quad = VNRectangleObservation(
    requestRevision: 1,
    topLeft: _coreGraphicsPoint(CGPoint(x: 0, y: 1)),
    topRight: _coreGraphicsPoint(CGPoint(x: 1, y: 1)),
    bottomRight: _coreGraphicsPoint(CGPoint(x: 1, y: 0)),
    bottomLeft: _coreGraphicsPoint(CGPoint(x: 0, y: 0))
)
let corner: CoreGraphics.CGPoint = quad.topLeft
precondition(corner.y == 1)

// Real CoreImage type from the guest module. Handler CIImage/CGImage
// overloads are intentionally absent (deferred) rather than backed by a
// Vision-local substitute named CIImage/CGImage.
let coreImage: CoreImage.CIImage? = CIFilter.linearGradient().outputImage
precondition(coreImage != nil)
_ = CIContext()

let handler = VNImageRequestHandler(
    data: Data([0x89, 0x50]),
    options: [:]
)
do {
    try handler.perform([VNDetectBarcodesRequest()])
} catch {
    precondition(error is VNError)
}
do {
    try VNSequenceRequestHandler().perform(
        [VNDetectHorizonRequest()],
        onImageData: Data([0x00])
    )
} catch {
    precondition(error is VNError)
}

print("VISION_DEPENDENCY_IDENTITY_OK")
