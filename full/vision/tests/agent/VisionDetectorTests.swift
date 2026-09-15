#if canImport(Glibc)
import Glibc
#endif
import Foundation
@_spi(OpenUIKitHost) import Vision

func testRectangleDetector() {
    let image = visionRectangleImage()
    let handler = VNImageRequestHandler(cgImage: image)
    let rectangles = VNDetectRectanglesRequest()
    rectangles.minimumSize = 0.1
    rectangles.minimumAspectRatio = 0.2
    rectangles.maximumAspectRatio = 1.0
    rectangles.quadratureTolerance = 40
    rectangles.minimumConfidence = 0
    rectangles.maximumObservations = 4
    try! handler.perform([rectangles])
    let found = (rectangles.results ?? []).compactMap { $0 as? VNRectangleObservation }
    visionExpect(!found.isEmpty, "detected rectangle")
    if let box = found.first?.boundingBox {
        visionExpect(box.width > 0.2 && box.height > 0.2, "rectangle size")
        visionExpect(box.origin.y >= 0, "lower-left origin")
    }
}

func testContourDetector() {
    let image = visionRectangleImage()
    let handler = VNImageRequestHandler(cgImage: image)
    let contours = VNDetectContoursRequest()
    contours.detectsDarkOnLight = false
    contours.detectDarkOnLight = false
    contours.contrastAdjustment = 2
    contours.contrastPivot = NSNumber(value: 0.5)
    contours.maximumImageDimension = 128
    try! handler.perform([contours])
    let contourObs = contours.results?.first as? VNContoursObservation
    visionExpect((contourObs?.contourCount ?? 0) >= 1, "contour count")
    visionExpect(contourObs?.normalizedPath != nil, "normalized path")
    visionExpect((contourObs?.topLevelContourCount ?? 0) >= 1, "top level")
    if let first = try? contourObs?.contour(at: 0) {
        visionExpect(first.pointCount >= 4, "contour points")
        _ = first.normalizedPath
        var area: Double = 0
        try! VNGeometryUtils.calculateArea(&area, for: first, orientedArea: false)
        visionExpect(area > 0, "contour area")
    }
}

func testContourDetectorInvertedPolarity() {
    // Default detectsDarkOnLight on the light-on-dark rectangle fixture traces
    // the background blob's region border instead of collapsing.
    let image = visionRectangleImage()
    let handler = VNImageRequestHandler(cgImage: image)
    let contours = VNDetectContoursRequest()
    try! handler.perform([contours])
    let contourObs = contours.results?.first as? VNContoursObservation
    visionExpect((contourObs?.contourCount ?? 0) >= 1, "inverted contour count")
    visionExpect((contourObs?.topLevelContourCount ?? 0) >= 1, "inverted top level")
    visionExpect(contourObs?.normalizedPath != nil, "inverted normalized path")
}

func testHorizonDetector() {
    let tilted = VNDetectHorizonRequest()
    try! VNImageRequestHandler(cgImage: visionHorizonImage(slope: 0.25)).perform([tilted])
    let tiltedObs = tilted.results?.first as? VNHorizonObservation
    visionExpect(tiltedObs != nil, "horizon observation")
    visionExpect(abs(tiltedObs!.angle + 0.245) < 0.2, "tilted horizon angle")
    visionExpect(tiltedObs!.confidence > 0, "horizon confidence")
    _ = tiltedObs!.transform
    _ = tiltedObs!.transform(forImageWidth: 80, height: 80)

    let level = VNDetectHorizonRequest()
    var levelRaster = VisionRaster(width: 80, height: 80, filled: (0, 0, 0, 255))
    for y in 0..<40 {
        for x in 0..<80 {
            levelRaster[x, y] = (220, 220, 220, 255)
        }
    }
    try! VNImageRequestHandler(cgImage: levelRaster.makeCGImage()).perform([level])
    let levelObs = level.results?.first as? VNHorizonObservation
    visionExpect(levelObs != nil, "level horizon")
    visionExpect(abs(levelObs!.angle) < 0.2, "level horizon near 0")
}

func testLensSmudgeDetector() {
    let request = DetectLensSmudgeRequest()
    let sharp = try! request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    let smudged = try! request.performOnHandler(VNImageRequestHandler(cgImage: visionUniformGrayImage()))
    visionExpect(smudged.confidence > sharp.confidence, "uniform is more smudged than sharp rectangle")
    visionExpect(smudged.confidence > 0.8, "uniform smudge high")
    visionExpect(sharp.confidence < 0.6, "sharp rectangle smudge low")
    visionExpectEqual(smudged.originatingRequestDescriptor, .detectLensSmudgeRequest(.revision1), "smudge descriptor")
}
