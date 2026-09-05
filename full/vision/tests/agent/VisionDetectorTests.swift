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
