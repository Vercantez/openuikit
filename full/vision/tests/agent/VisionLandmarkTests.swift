#if canImport(Glibc)
import Glibc
#endif
import Foundation
@_spi(OpenUIKitHost) import Vision

func testFaceLandmarks2D() {
    let leftEye = VNFaceLandmarkRegion2D(
        normalizedPoints: [CGPoint(x: 0.3, y: 0.7), CGPoint(x: 0.35, y: 0.72)],
        precisionEstimatesPerPoint: [0.9, 0.8],
        pointsClassification: .openPath
    )
    visionExpectEqual(leftEye.pointCount, 2, "region count")
    visionExpectEqual(leftEye.pointsClassification, .openPath, "open path")
    let inImage = leftEye.pointsInImage(imageSize: CGSize(width: 100, height: 200))
    visionExpectEqual(inImage[0], CGPoint(x: 30, y: 140), "landmark in image")
    let landmarks = VNFaceLandmarks2D(
        confidence: 0.8,
        allPoints: VNFaceLandmarkRegion2D(normalizedPoints: [CGPoint(x: 0.5, y: 0.5)]),
        faceContour: VNFaceLandmarkRegion2D(normalizedPoints: [CGPoint(x: 0.1, y: 0.2), CGPoint(x: 0.9, y: 0.2)]),
        leftEye: leftEye,
        nose: VNFaceLandmarkRegion2D(normalizedPoints: [CGPoint(x: 0.5, y: 0.4)])
    )
    visionExpectEqual(landmarks.confidence, 0.8, "landmarks confidence")
    visionExpectEqual(landmarks.leftEye?.pointCount, 2, "left eye")
    visionExpectEqual(landmarks.nose?.normalizedPoints.first, CGPoint(x: 0.5, y: 0.4), "nose")
    let face = VNFaceObservation(
        boundingBox: CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4),
        roll: NSNumber(value: 0.1),
        yaw: NSNumber(value: -0.2),
        pitch: NSNumber(value: 0.05),
        landmarks: landmarks
    )
    visionExpectEqual(face.landmarks?.leftEye?.pointCount, 2, "face landmarks")
    visionExpectEqual(face.yaw?.doubleValue, -0.2, "yaw")
    let viaRevision = VNFaceObservation(
        requestRevision: 3,
        boundingBox: CGRect(x: 0, y: 0, width: 1, height: 1),
        roll: nil,
        yaw: nil
    )
    visionExpectEqual(viaRevision.landmarks == nil, true, "nil landmarks")
    let overlay = FaceObservation(face)
    visionExpectEqual(overlay.landmarks?.leftEye.points.count, 2, "overlay region")
    let imagePts = overlay.landmarks!.leftEye.pointsInImageCoordinates(CGSize(width: 100, height: 200), origin: .lowerLeft)
    visionExpectEqual(imagePts[0], CGPoint(x: 30, y: 140), "overlay pointsInImageCoordinates")
    let constructed = FaceObservation(boundingBox: .fullImage, revision: .revision3)
    visionExpectEqual(constructed.boundingBox, .fullImage, "face init boundingBox")
    let emptyRegion = VNFaceLandmarkRegion2D(normalizedPoints: [])
    let allLandmarks = VNFaceLandmarks2D(
        confidence: 0.5,
        allPoints: VNFaceLandmarkRegion2D(normalizedPoints: [CGPoint(x: 0.5, y: 0.5)]),
        faceContour: VNFaceLandmarkRegion2D(normalizedPoints: [CGPoint(x: 0.1, y: 0.1)]),
        innerLips: VNFaceLandmarkRegion2D(normalizedPoints: [CGPoint(x: 0.45, y: 0.35)]),
        leftEye: leftEye,
        leftEyebrow: VNFaceLandmarkRegion2D(normalizedPoints: [CGPoint(x: 0.3, y: 0.8)]),
        leftPupil: VNFaceLandmarkRegion2D(normalizedPoints: [CGPoint(x: 0.32, y: 0.71)]),
        medianLine: VNFaceLandmarkRegion2D(normalizedPoints: [CGPoint(x: 0.5, y: 0.2), CGPoint(x: 0.5, y: 0.8)]),
        nose: VNFaceLandmarkRegion2D(normalizedPoints: [CGPoint(x: 0.5, y: 0.4)]),
        noseCrest: VNFaceLandmarkRegion2D(normalizedPoints: [CGPoint(x: 0.5, y: 0.5)]),
        outerLips: VNFaceLandmarkRegion2D(normalizedPoints: [CGPoint(x: 0.4, y: 0.3)]),
        rightEye: VNFaceLandmarkRegion2D(normalizedPoints: [CGPoint(x: 0.7, y: 0.7)]),
        rightEyebrow: VNFaceLandmarkRegion2D(normalizedPoints: [CGPoint(x: 0.7, y: 0.8)]),
        rightPupil: VNFaceLandmarkRegion2D(normalizedPoints: [CGPoint(x: 0.72, y: 0.71)])
    )
    visionExpectEqual(allLandmarks.innerLips?.pointCount, 1, "innerLips")
    visionExpectEqual(allLandmarks.leftEyebrow?.pointCount, 1, "leftEyebrow")
    visionExpectEqual(allLandmarks.leftPupil?.pointCount, 1, "leftPupil")
    visionExpectEqual(allLandmarks.medianLine?.pointCount, 2, "medianLine")
    visionExpectEqual(allLandmarks.noseCrest?.pointCount, 1, "noseCrest")
    visionExpectEqual(allLandmarks.outerLips?.pointCount, 1, "outerLips")
    visionExpectEqual(allLandmarks.rightEye?.pointCount, 1, "rightEye")
    visionExpectEqual(allLandmarks.rightEyebrow?.pointCount, 1, "rightEyebrow")
    visionExpectEqual(allLandmarks.rightPupil?.pointCount, 1, "rightPupil")
    visionExpectEqual(allLandmarks.faceContour?.pointCount, 1, "faceContour")
    visionExpectEqual(allLandmarks.allPoints?.pointCount, 1, "allPoints")
    visionExpectEqual(emptyRegion.pointCount, 0, "empty region")
    let baseRegion = VNFaceLandmarkRegion(pointCount: 3, pointsClassification: .disconnected)
    visionExpectEqual(baseRegion.pointCount, 3, "base region count")
    visionExpectEqual(baseRegion.pointsClassification, .disconnected, "disconnected")
}

func testRecognizedTextTopCandidates() {
    let first = VNRecognizedText(string: "Hello", confidence: 0.9)
    let second = VNRecognizedText(string: "Hallo", confidence: 0.4)
    let observation = VNRecognizedTextObservation(
        topLeft: CGPoint(x: 0, y: 1),
        topRight: CGPoint(x: 1, y: 1),
        bottomRight: CGPoint(x: 1, y: 0),
        bottomLeft: CGPoint(x: 0, y: 0),
        candidates: [first, second]
    )
    visionExpectEqual(observation.topCandidates(1).map(\.string), ["Hello"], "top 1")
    visionExpectEqual(observation.topCandidates(8).count, 2, "top 8 capped")
    visionExpectEqual(observation.topCandidates(0).count, 0, "top 0")
    let overlay = RecognizedTextObservation(observation)
    visionExpectEqual(overlay.transcript, "Hello", "transcript")
    visionExpectEqual(overlay.topCandidates(1).first?.string, "Hello", "overlay top")
    visionExpectEqual(overlay.textDirection, .leftToRight, "direction")
    visionExpectEqual(overlay.isTitle, false, "isTitle")
    let box = overlay.boundingBox
    visionExpectEqual(box.width, 1, "text bbox width")
}

func testContoursObservationTree() {
    let child = VNContour(normalizedPoints: [SIMD2<Float>(0.2, 0.2), SIMD2<Float>(0.3, 0.2), SIMD2<Float>(0.25, 0.3)])
    let parent = VNContour(
        normalizedPoints: [
            SIMD2<Float>(0, 0),
            SIMD2<Float>(1, 0),
            SIMD2<Float>(1, 1),
            SIMD2<Float>(0, 1),
        ],
        childContours: [child]
    )
    let observation = VNContoursObservation(topLevelContours: [parent])
    visionExpectEqual(observation.topLevelContourCount, 1, "top level")
    visionExpectEqual(observation.contourCount, 2, "flat count")
    visionExpectEqual(try! observation.contour(at: 0).pointCount, 4, "index 0")
    visionExpectEqual(try! observation.contour(at: IndexPath(indexes: [0, 0])).pointCount, 3, "child path")
    _ = observation.normalizedPath
    visionExpectEqual(observation.topLevelContours.first?.childContourCount, 1, "child attached")
    do {
        _ = try observation.contour(at: 9)
        visionExpect(false, "oob")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.outOfBoundsError.rawValue, "contour oob")
    }
}

func testFeaturePrintDistanceMismatch() {
    let lhs = VNFeaturePrintObservation(elementType: .float, data: Data([0, 0, 0, 0]))
    let rhs = VNFeaturePrintObservation(elementType: .double, data: Data(repeating: 0, count: 8))
    do {
        var distance: Float = 0
        try lhs.computeDistance(&distance, to: rhs)
        visionExpect(false, "type mismatch should throw")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidArgument.rawValue, "element type mismatch")
    }
    var same: Float = 1
    try! lhs.computeDistance(&same, to: lhs)
    visionExpectEqual(same, 0, "identical distance")
}

func testHorizonObservation() {
    let horizon = VNHorizonObservation(angle: Double.pi / 2, confidence: 0.9)
    visionExpectEqual(horizon.angle, Double.pi / 2, "angle")
    visionExpectEqual(horizon.confidence, 0.9, "horizon confidence")
    let identity = VNHorizonObservation(angle: 0)
    visionExpectEqual(identity.transform.a, 1, "identity a")
    visionExpectEqual(identity.transform.d, 1, "identity d")
    let centered = horizon.transform(forImageWidth: 100, height: 100)
    let mappedX = centered.a * 50 + centered.c * 50 + centered.tx
    let mappedY = centered.b * 50 + centered.d * 50 + centered.ty
    visionExpect(abs(mappedX - 50) < 1e-6, "center x stays")
    visionExpect(abs(mappedY - 50) < 1e-6, "center y stays")
    let overlay = HorizonObservation(horizon)
    visionExpectEqual(overlay.angle.value, Double.pi / 2, "overlay angle")
    visionExpectEqual(overlay.angle.unit, .radians, "radians")
    visionExpectEqual(overlay.description.contains("Horizon"), true, "overlay description")
    visionExpect(overlay.uuid != UUID(), "overlay uuid")
    visionExpect(overlay.timeRange == .zero, "overlay timeRange")
    visionExpect(overlay.originatingRequestDescriptor == nil, "overlay descriptor")
    _ = overlay.hashValue
    visionExpect(overlay == overlay, "overlay equal")
    visionExpect(overlay != HorizonObservation(angle: Measurement(value: 0, unit: .radians)), "overlay unequal")
    let sized = overlay.transform(for: CGSize(width: 100, height: 100))
    visionExpect(abs(sized.a - centered.a) < 1e-6, "overlay transform for size")
    let constructed = HorizonObservation(angle: Measurement(value: 0.2, unit: .radians))
    visionExpectEqual(constructed.transform, .identity, "constructed default transform")
}
