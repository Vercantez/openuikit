#if canImport(Glibc)
import Glibc
#endif
import Foundation
@_spi(OpenUIKitHost) import Vision

func testFeaturePrint() {
    let red = VisionRaster(width: 32, height: 32, filled: (200, 20, 20, 255))
    let blue = VisionRaster(width: 32, height: 32, filled: (20, 20, 200, 255))
    let redHandler = VNImageRequestHandler(cgImage: red.makeCGImage())
    let blueHandler = VNImageRequestHandler(ciImage: blue.makeCIImage(), orientation: .up)
    let redPrint = VNGenerateImageFeaturePrintRequest()
    redPrint.imageCropAndScaleOption = .scaleFill
    let bluePrint = VNGenerateImageFeaturePrintRequest()
    try! redHandler.perform([redPrint])
    try! blueHandler.perform([bluePrint])
    let lhs = redPrint.results?.first as? VNFeaturePrintObservation
    let rhs = bluePrint.results?.first as? VNFeaturePrintObservation
    visionExpect(lhs != nil && rhs != nil, "feature prints")
    visionExpect(lhs!.elementCount > 0, "element count")
    visionExpect(lhs!.elementType == .float, "element type")
    visionExpect(!lhs!.data.isEmpty, "feature data")
    var same: Float = 0
    var different: Float = 0
    try! lhs!.computeDistance(&same, to: lhs!)
    try! lhs!.computeDistance(&different, to: rhs!)
    visionExpect(same < 1e-5, "identical feature print")
    visionExpect(different > same, "colour histograms differ")
}

func testTranslationalRegistration() {
    var shifted = VisionRaster(width: 64, height: 64, filled: (0, 0, 0, 255))
    var base = VisionRaster(width: 64, height: 64, filled: (0, 0, 0, 255))
    for y in 10..<30 {
        for x in 10..<30 {
            base[x, y] = (255, 255, 255, 255)
            shifted[x + 8, y + 4] = (255, 255, 255, 255)
        }
    }
    let registration = VNTranslationalImageRegistrationRequest(
        targetedCGImage: base.makeCGImage(),
        orientation: .up
    )
    let moving = VNImageRequestHandler(cgImage: shifted.makeCGImage())
    try! moving.perform([registration])
    let align = registration.results?.first as? VNImageTranslationAlignmentObservation
    visionExpect(align != nil, "translation observation")
    visionExpect(abs(align!.alignmentTransform.tx - 8) < 3, "tx")
    visionExpect(abs(align!.alignmentTransform.ty - 4) < 3, "ty")
}

func testHomographicRegistrationFailClosed() {
    let base = VisionRaster(width: 32, height: 32, filled: (255, 255, 255, 255))
    let moving = VNImageRequestHandler(cgImage: base.makeCGImage())
    let homo = VNHomographicImageRegistrationRequest(targetedCGImage: base.makeCGImage())
    do {
        try moving.perform([homo])
        visionExpect(false, "homography should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.unsupportedRequest.rawValue, "homography unsupported")
        visionExpect(homo.results == nil, "homography results nil")
    }
}

func testObjectTracker() {
    var frame1 = VisionRaster(width: 60, height: 60, filled: (0, 0, 0, 255))
    var frame2 = VisionRaster(width: 60, height: 60, filled: (0, 0, 0, 255))
    for y in 10..<22 {
        for x in 10..<22 {
            frame1[x, y] = (255, 255, 255, 255)
        }
    }
    for y in 14..<26 {
        for x in 18..<30 {
            frame2[x, y] = (255, 255, 255, 255)
        }
    }
    let seedBox = CGRect(x: 10.0 / 60.0, y: 1 - 22.0 / 60.0, width: 12.0 / 60.0, height: 12.0 / 60.0)
    let seed = VNDetectedObjectObservation(boundingBox: seedBox)
    let tracker = VNTrackObjectRequest(detectedObjectObservation: seed)
    tracker.trackingLevel = .accurate
    try! VNImageRequestHandler(cgImage: frame1.makeCGImage()).perform([tracker])
    try! VNImageRequestHandler(cvPixelBuffer: frame2.makePixelBuffer()).perform([tracker])
    let tracked = tracker.results?.first as? VNDetectedObjectObservation
    visionExpect(tracked != nil, "tracked box")
    visionExpect(tracked!.boundingBox.origin.x > seedBox.origin.x - 0.05, "centroid moved")
}
