import Foundation
import Vision

func requireClose(_ actual: Double, _ expected: Double, epsilon: Double = 1e-6) {
    precondition(
        abs(actual - expected) <= epsilon,
        "expected \(expected) got \(actual)"
    )
}

func requirePoint(_ actual: CGPoint, _ expected: CGPoint, epsilon: CGFloat = 1e-6) {
    requireClose(Double(actual.x), Double(expected.x), epsilon: Double(epsilon))
    requireClose(Double(actual.y), Double(expected.y), epsilon: Double(epsilon))
}

func requireRect(_ actual: CGRect, _ expected: CGRect, epsilon: CGFloat = 1e-6) {
    requirePoint(actual.origin, expected.origin, epsilon: epsilon)
    requireClose(Double(actual.size.width), Double(expected.size.width), epsilon: Double(epsilon))
    requireClose(Double(actual.size.height), Double(expected.size.height), epsilon: Double(epsilon))
}

func requireVNError(_ error: any Error, _ code: VNErrorCode) {
    guard let typed = error as? VNError else {
        fatalError("expected VNError, got \(error)")
    }
    precondition(typed.code == code, "expected \(code) got \(typed.code)")
}

func bboxApproximationRadius(_ points: [VNPoint]) -> Double {
    var minX = points[0].x
    var maxX = points[0].x
    var minY = points[0].y
    var maxY = points[0].y
    for point in points {
        minX = min(minX, point.x)
        maxX = max(maxX, point.x)
        minY = min(minY, point.y)
        maxY = max(maxY, point.y)
    }
    let center = VNPoint(x: (minX + maxX) / 2, y: (minY + maxY) / 2)
    return points.map { VNPoint.distance(center, $0) }.max() ?? 0
}

func testGeometryMapping() {
    precondition(VNNormalizedRectIsIdentityRect(VNNormalizedIdentityRect))
    precondition(!VNNormalizedRectIsIdentityRect(CGRect(x: 0, y: 0, width: 1, height: 0.99)))
    precondition(VNElementTypeSize(.unknown) == 0)
    precondition(VNElementTypeSize(.float) == MemoryLayout<Float>.size)
    precondition(VNElementTypeSize(.double) == MemoryLayout<Double>.size)

    let normalized = CGRect(x: 0.25, y: 0.5, width: 0.25, height: 0.25)
    let imageRect = VNImageRectForNormalizedRect(normalized, 200, 100)
    requireRect(imageRect, CGRect(x: 50, y: 50, width: 50, height: 25))
    requireRect(VNNormalizedRectForImageRect(imageRect, 200, 100), normalized)
    requirePoint(
        VNImagePointForNormalizedPoint(CGPoint(x: 0.25, y: 0.5), 200, 100),
        CGPoint(x: 50, y: 50)
    )
    requirePoint(
        VNNormalizedPointForImagePoint(CGPoint(x: 50, y: 50), 200, 100),
        CGPoint(x: 0.25, y: 0.5)
    )

    let roi = CGRect(x: 0.1, y: 0.2, width: 0.5, height: 0.4)
    let roiPoint = VNImagePointForNormalizedPointUsingRegionOfInterest(
        CGPoint(x: 0.5, y: 0.5),
        100,
        100,
        roi
    )
    requirePoint(roiPoint, CGPoint(x: 35, y: 40))
    requirePoint(
        VNNormalizedPointForImagePointUsingRegionOfInterest(roiPoint, 100, 100, roi),
        CGPoint(x: 0.5, y: 0.5)
    )
    let roiRect = VNImageRectForNormalizedRectUsingRegionOfInterest(
        CGRect(x: 0.5, y: 0.25, width: 0.25, height: 0.5),
        100,
        100,
        roi
    )
    requireRect(roiRect, CGRect(x: 35, y: 30, width: 12.5, height: 20))
    requireRect(
        VNNormalizedRectForImageRectUsingRegionOfInterest(roiRect, 100, 100, roi),
        CGRect(x: 0.5, y: 0.25, width: 0.25, height: 0.5)
    )

    let landmark = VNImagePointForFaceLandmarkPoint(
        SIMD2<Float>(0.5, 0.5),
        CGRect(x: 0.2, y: 0.2, width: 0.4, height: 0.4),
        100,
        100
    )
    requirePoint(landmark, CGPoint(x: 40, y: 40))
    requirePoint(
        VNNormalizedFaceBoundingBoxPointForLandmarkPoint(
            SIMD2<Float>(0.5, 0.5),
            CGRect(x: 0.2, y: 0.2, width: 0.4, height: 0.4),
            100,
            100
        ),
        CGPoint(x: 0.4, y: 0.4)
    )
}

func testPointsVectorsCircles() {
    let origin = VNPoint.zero
    precondition(origin.x == 0 && origin.y == 0)
    let fromLocation = VNPoint(location: CGPoint(x: 3, y: 4))
    requirePoint(fromLocation.location, CGPoint(x: 3, y: 4))
    precondition(VNPoint.distance(origin, fromLocation) == 5)
    precondition(origin.distance(fromLocation) == 5)

    let polar = VNVector(r: 2, theta: 0)
    requireClose(polar.x, 2)
    requireClose(polar.y, 0)
    let cartesian = VNVector(xComponent: 3, yComponent: 4)
    let aliased = VNVector(XComponent: 3, yComponent: 4)
    precondition(cartesian.x == aliased.x && cartesian.y == aliased.y)
    requireClose(cartesian.length, 5)
    requireClose(cartesian.squaredLength, 25)
    requireClose(cartesian.r, 5)
    requireClose(cartesian.theta, atan2(4.0, 3.0))
    let fromPoints = VNVector(vectorHead: fromLocation, tail: origin)
    requireClose(fromPoints.length, 5)
    let sum = VNVector(byAdding: cartesian, to: cartesian)
    requireClose(sum.x, 6)
    let sumAlias = VNVector(byAddingVector: cartesian, toVector: VNVector.zero)
    requireClose(sumAlias.x, 3)
    let delta = VNVector(bySubtracting: cartesian, from: sum)
    requireClose(delta.x, 3)
    let scaled = VNVector(byMultiplying: cartesian, byScalar: 2)
    requireClose(scaled.y, 8)
    let scaledAlias = VNVector(byMultiplyingVector: cartesian, byScalar: 0)
    requireClose(scaledAlias.length, 0)
    requireClose(VNVector.dotProduct(of: cartesian, vector: cartesian), 25)
    requireClose(VNVector.unitVector(for: cartesian).length, 1)
    requireClose(VNVector.unitVector(for: .zero).length, 0)
    let moved = VNPoint.apply(cartesian, to: origin)
    requireClose(moved.x, 3)
    requireClose(moved.y, 4)

    let circle = VNCircle(center: origin, radius: 5)
    precondition(circle.diameter == 10)
    precondition(circle.contains(fromLocation))
    precondition(!circle.contains(VNPoint(x: 6, y: 0)))
    precondition(circle.contains(fromLocation, inCircumferentialRingOfWidth: 0.5))
    precondition(!circle.contains(origin, inCircumferentialRingOfWidth: 0.5))
    let fromDiameter = VNCircle(center: origin, diameter: 10)
    requireClose(fromDiameter.radius, 5)
    precondition(VNCircle.zero.radius == 0)

    let detected = VNDetectedPoint(x: 0.2, y: 0.3, confidence: 0.9)
    precondition(detected.confidence == 0.9)
    let key = VNRecognizedPointKey(rawValue: "test.joint")
    let recognized = VNRecognizedPoint(
        x: 0.2,
        y: 0.3,
        confidence: 0.9,
        identifier: key
    )
    precondition(recognized.identifier == key)
}

func testMinimumEnclosingCircle() {
    do {
        _ = try VNGeometryUtils.boundingCircle(for: [])
        fatalError("empty points must throw")
    } catch {
        requireVNError(error, .invalidArgument)
    }

    let singleton = try! VNGeometryUtils.boundingCircle(for: [VNPoint(x: 7, y: -3)])
    requireClose(singleton.center.x, 7)
    requireClose(singleton.center.y, -3)
    requireClose(singleton.radius, 0)

    let duplicates = try! VNGeometryUtils.boundingCircle(for: [
        VNPoint(x: 1, y: 1),
        VNPoint(x: 1, y: 1),
        VNPoint(x: 1, y: 1),
    ])
    requireClose(duplicates.radius, 0)
    requireClose(duplicates.center.x, 1)

    let collinear = [
        VNPoint(x: 0, y: 0),
        VNPoint(x: 1, y: 0),
        VNPoint(x: 3, y: 0),
    ]
    let collinearCircle = try! VNGeometryUtils.boundingCircle(for: collinear)
    requireClose(collinearCircle.center.x, 1.5)
    requireClose(collinearCircle.center.y, 0)
    requireClose(collinearCircle.radius, 1.5)

    let obtuse = [
        VNPoint(x: 0, y: 0),
        VNPoint(x: 3, y: 0),
        VNPoint(x: 0.2, y: 0.2),
    ]
    let obtuseCircle = try! VNGeometryUtils.boundingCircle(for: obtuse)
    requireClose(obtuseCircle.center.x, 1.5)
    requireClose(obtuseCircle.center.y, 0)
    requireClose(obtuseCircle.radius, 1.5)
    for point in obtuse {
        precondition(obtuseCircle.contains(point))
    }

    let sqrt3 = 3.0.squareRoot()
    let equilateral = [
        VNPoint(x: 0, y: 0),
        VNPoint(x: 2, y: 0),
        VNPoint(x: 1, y: sqrt3),
    ]
    let acute = try! VNGeometryUtils.boundingCircle(for: equilateral)
    requireClose(acute.center.x, 1)
    requireClose(acute.center.y, sqrt3 / 3)
    requireClose(acute.radius, 2 / sqrt3)
    let bboxRadius = bboxApproximationRadius(equilateral)
    precondition(acute.radius < bboxRadius - 1e-6)
    for point in equilateral {
        precondition(acute.contains(point))
    }

    let skew = [
        VNPoint(x: 0, y: 0),
        VNPoint(x: 4, y: 0),
        VNPoint(x: 1, y: 2),
    ]
    let skewCircle = try! VNGeometryUtils.boundingCircle(for: skew)
    precondition(skewCircle.radius < bboxApproximationRadius(skew) - 1e-6)
    for point in skew {
        precondition(skewCircle.contains(point))
    }

    let shuffled = try! VNGeometryUtils.boundingCircle(for: equilateral.reversed())
    requireClose(shuffled.center.x, acute.center.x)
    requireClose(shuffled.center.y, acute.center.y)
    requireClose(shuffled.radius, acute.radius)
}

func testIdentifiers() {
    let composites: [VNBarcodeCompositeType] = [
        .none, .linked, .gs1TypeA, .gs1TypeB, .gs1TypeC,
    ]
    precondition(Set(composites).count == 5)
    let chiralities: [VNChirality] = [.unknown, .left, .right]
    precondition(Set(chiralities).count == 3)
    let crops: [VNImageCropAndScaleOption] = [
        .centerCrop, .scaleFit, .scaleFill, .scaleFitRotate90CCW, .scaleFillRotate90CCW,
    ]
    precondition(Set(crops).count == 5)
    let points: [VNPointsClassification] = [.disconnected, .openPath, .closedPath]
    precondition(Set(points).count == 3)
    let constellations: [VNRequestFaceLandmarksConstellation] = [
        .constellationNotDefined, .constellation65Points, .constellation76Points,
    ]
    precondition(Set(constellations).count == 3)
    precondition(VNRequestTextRecognitionLevel.accurate != .fast)
    precondition(VNRequestTrackingLevel.accurate != .fast)

    let camel: [VNBarcodeSymbology] = [
        .aztec, .codabar, .code128, .code39, .code39Checksum, .code39FullASCII,
        .code39FullASCIIChecksum, .code93, .code93i, .dataMatrix, .ean13, .ean8,
        .gs1DataBar, .gs1DataBarExpanded, .gs1DataBarLimited, .i2of5, .i2of5Checksum,
        .itf14, .msiPlessey, .microPDF417, .microQR, .pdf417, .qr, .upce,
    ]
    precondition(Set(camel).count == 24)
    precondition(VNBarcodeSymbology.allCases.count == 24)
    precondition(VNBarcodeSymbology.qr == .QR)
    precondition(VNBarcodeSymbology.aztec == .Aztec)
    precondition(VNBarcodeSymbology.code128 == .Code128)
    precondition(VNBarcodeSymbology.code39 == .Code39)
    precondition(VNBarcodeSymbology.code39Checksum == .Code39Checksum)
    precondition(VNBarcodeSymbology.code39FullASCII == .Code39FullASCII)
    precondition(VNBarcodeSymbology.code39FullASCIIChecksum == .Code39FullASCIIChecksum)
    precondition(VNBarcodeSymbology.code93 == .Code93)
    precondition(VNBarcodeSymbology.code93i == .Code93i)
    precondition(VNBarcodeSymbology.dataMatrix == .DataMatrix)
    precondition(VNBarcodeSymbology.ean13 == .EAN13)
    precondition(VNBarcodeSymbology.ean8 == .EAN8)
    precondition(VNBarcodeSymbology.i2of5 == .I2of5)
    precondition(VNBarcodeSymbology.i2of5Checksum == .I2of5Checksum)
    precondition(VNBarcodeSymbology.itf14 == .ITF14)
    precondition(VNBarcodeSymbology.pdf417 == .PDF417)
    precondition(VNBarcodeSymbology.upce == .UPCE)
    precondition(VNBarcodeSymbology.qr != .ean13)

    let options: [VNImageOption] = [.ciContext, .cameraIntrinsics, .properties]
    precondition(Set(options).count == 3)
    let stages: [VNComputeStage] = [.main, .postProcessing]
    precondition(Set(stages).count == 2)
    precondition(VNAnimalIdentifier.cat != .dog)
}

func testObservations() {
    let box = VNDetectedObjectObservation(
        boundingBox: CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4)
    )
    requireRect(box.boundingBox, CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4))
    precondition(box.confidence == 1)
    precondition(box.requestRevision == VNRequestRevisionUnspecified)
    let revised = VNDetectedObjectObservation(
        requestRevision: 2,
        boundingBox: box.boundingBox
    )
    precondition(revised.requestRevision == 2)

    let face = VNFaceObservation(
        requestRevision: VNDetectFaceRectanglesRequestRevision3,
        boundingBox: box.boundingBox,
        roll: NSNumber(value: 0.1),
        yaw: NSNumber(value: -0.2),
        pitch: NSNumber(value: 0)
    )
    precondition(face.roll?.doubleValue == 0.1)
    precondition(face.yaw?.doubleValue == -0.2)
    precondition(face.pitch?.doubleValue == 0)
    precondition(face.landmarks == nil)
    precondition(face.faceCaptureQuality == nil)

    let quad = VNRectangleObservation(
        requestRevision: 1,
        topLeft: CGPoint(x: 0, y: 1),
        topRight: CGPoint(x: 1, y: 1),
        bottomRight: CGPoint(x: 1, y: 0),
        bottomLeft: CGPoint(x: 0, y: 0)
    )
    requirePoint(quad.topLeft, CGPoint(x: 0, y: 1))
    requirePoint(quad.topRight, CGPoint(x: 1, y: 1))
    requirePoint(quad.bottomRight, CGPoint(x: 1, y: 0))
    requirePoint(quad.bottomLeft, CGPoint(x: 0, y: 0))
    requireRect(quad.boundingBox, CGRect(x: 0, y: 0, width: 1, height: 1))
    let reordered = VNRectangleObservation(
        requestRevision: 1,
        topLeft: CGPoint(x: 0, y: 1),
        bottomLeft: CGPoint(x: 0, y: 0),
        bottomRight: CGPoint(x: 1, y: 0),
        topRight: CGPoint(x: 1, y: 1)
    )
    requirePoint(reordered.bottomLeft, CGPoint(x: 0, y: 0))

    let barcode = VNBarcodeObservation(
        requestRevision: 4,
        boundingBox: quad.boundingBox,
        topLeft: quad.topLeft,
        topRight: quad.topRight,
        bottomRight: quad.bottomRight,
        bottomLeft: quad.bottomLeft,
        symbology: .qr,
        payloadStringValue: nil,
        payloadData: nil,
        confidence: 0,
        uuid: UUID()
    )
    precondition(barcode.symbology == .qr)
    precondition(barcode.payloadStringValue == nil)
    precondition(barcode.payloadData == nil)
    precondition(barcode.supplementalPayloadString == nil)
    precondition(barcode.supplementalPayloadData == nil)
    precondition(barcode.supplementalCompositeType == .none)
    precondition(!barcode.isGS1DataCarrier)
    precondition(!barcode.isColorInverted)

    let textBox = VNTextObservation(
        requestRevision: 1,
        boundingBox: quad.boundingBox,
        topLeft: quad.topLeft,
        topRight: quad.topRight,
        bottomRight: quad.bottomRight,
        bottomLeft: quad.bottomLeft,
        characterBoxes: [quad],
        confidence: 0.5,
        uuid: UUID()
    )
    precondition(textBox.characterBoxes?.count == 1)

    let candidate = VNRecognizedText(string: "hello", confidence: 0.8)
    precondition(candidate.string == "hello")
    precondition(candidate.confidence == 0.8)
    do {
        _ = try candidate.boundingBox(for: candidate.string.startIndex..<candidate.string.endIndex)
        fatalError("text bounding box must fail closed")
    } catch {
        requireVNError(error, .notImplemented)
    }
    let recognized = VNRecognizedTextObservation(
        requestRevision: 3,
        boundingBox: quad.boundingBox,
        topLeft: quad.topLeft,
        topRight: quad.topRight,
        bottomRight: quad.bottomRight,
        bottomLeft: quad.bottomLeft,
        candidates: [candidate],
        confidence: 0.8,
        uuid: UUID()
    )
    precondition(recognized.topCandidates(1).first?.string == "hello")
    precondition(recognized.topCandidates(0).isEmpty)

    let classification = VNClassificationObservation(
        requestRevision: 2,
        identifier: "cat",
        confidence: 0.4
    )
    precondition(classification.identifier == "cat")
    precondition(!classification.hasPrecisionRecallCurve)
    precondition(!classification.hasMinimumPrecision(0.9, forRecall: 0.1))
    precondition(!classification.hasMinimumRecall(0.9, forPrecision: 0.1))
    let object = VNRecognizedObjectObservation(
        requestRevision: 2,
        boundingBox: box.boundingBox,
        labels: [classification],
        confidence: 0.4,
        uuid: UUID()
    )
    precondition(object.labels.first?.identifier == "cat")

    let saliency = VNSaliencyImageObservation(
        requestRevision: 2,
        featureName: "attention",
        salientObjects: [quad],
        confidence: 1
    )
    precondition(saliency.featureName == "attention")
    precondition(saliency.salientObjects?.count == 1)
    let horizon = VNHorizonObservation(requestRevision: 1, angle: 0.25, confidence: 1)
    precondition(horizon.angle == 0.25)
    let human = VNHumanObservation(
        requestRevision: 2,
        boundingBox: box.boundingBox,
        upperBodyOnly: true,
        confidence: 1,
        uuid: UUID()
    )
    precondition(human.upperBodyOnly)

    let region = VNFaceLandmarkRegion2D(
        normalizedPoints: [CGPoint(x: 0.5, y: 0.25)],
        precisionEstimatesPerPoint: [0.9],
        pointsClassification: .openPath
    )
    precondition(region.pointCount == 1)
    requirePoint(region.pointsInImage(imageSize: CGSize(width: 10, height: 20)).first!, CGPoint(x: 5, y: 5))
    precondition(region.normalizedPoints.count == 1)
    precondition(region.precisionEstimatesPerPoint?.first == 0.9)
    precondition(region.pointsClassification == .openPath)
    let landmarks = VNFaceLandmarks2D(
        confidence: 0.7,
        allPoints: region,
        leftEye: region,
        nose: region
    )
    precondition(landmarks.confidence == 0.7)
    precondition(landmarks.allPoints?.pointCount == 1)
    precondition(landmarks.leftEye != nil)
    precondition(landmarks.rightEye == nil)
}

func testRequestsAndHandlers() {
    let barcodes = VNDetectBarcodesRequest()
    precondition(barcodes.revision == VNDetectBarcodesRequestRevision4)
    precondition(VNDetectBarcodesRequest.currentRevision == VNDetectBarcodesRequestRevision4)
    precondition(VNDetectBarcodesRequest.defaultRevision == VNDetectBarcodesRequestRevision4)
    precondition(VNDetectBarcodesRequest.supportedRevisions.contains(1))
    precondition(VNDetectBarcodesRequest.supportedRevisions.contains(4))
    barcodes.symbologies = [.qr, .ean13]
    barcodes.coalesceCompositeSymbologies = true
    precondition(barcodes.symbologies.count == 2)
    precondition(barcodes.coalesceCompositeSymbologies)
    precondition(VNDetectBarcodesRequest.supportedSymbologies.contains(.qr))
    precondition(try! barcodes.supportedSymbologies().contains(.pdf417))
    barcodes.preferBackgroundProcessing = true
    barcodes.usesCPUOnly = true
    barcodes.regionOfInterest = CGRect(x: 0, y: 0, width: 0.5, height: 0.5)
    precondition(barcodes.indeterminate)

    let faces = VNDetectFaceRectanglesRequest()
    precondition(faces.revision == VNDetectFaceRectanglesRequestRevision3)
    let landmarks = VNDetectFaceLandmarksRequest()
    landmarks.constellation = .constellation65Points
    landmarks.inputFaceObservations = [
        VNFaceObservation(
            requestRevision: 3,
            boundingBox: CGRect(x: 0, y: 0, width: 1, height: 1),
            roll: nil,
            yaw: nil
        )
    ]
    precondition(
        VNDetectFaceLandmarksRequest.revision(
            VNDetectFaceLandmarksRequestRevision3,
            supportsConstellation: .constellation65Points
        )
    )
    precondition(
        VNDetectFaceLandmarksRequest.revision(
            VNDetectFaceLandmarksRequestRevision1,
            supportsConstellation: .constellationNotDefined
        )
    )
    let quality = VNDetectFaceCaptureQualityRequest()
    quality.inputFaceObservations = landmarks.inputFaceObservations
    precondition(quality.inputFaceObservations?.count == 1)

    let rectangles = VNDetectRectanglesRequest()
    rectangles.minimumAspectRatio = 0.2
    rectangles.maximumAspectRatio = 0.9
    rectangles.quadratureTolerance = 15
    rectangles.minimumSize = 0.1
    rectangles.minimumConfidence = 0.4
    rectangles.maximumObservations = 3
    precondition(rectangles.maximumObservations == 3)
    let textRects = VNDetectTextRectanglesRequest()
    textRects.reportCharacterBoxes = true
    precondition(textRects.reportCharacterBoxes)

    let text = VNRecognizeTextRequest()
    text.recognitionLanguages = ["en-US"]
    text.customWords = ["OpenUIKit"]
    text.recognitionLevel = .fast
    text.usesLanguageCorrection = true
    text.automaticallyDetectsLanguage = true
    text.minimumTextHeight = 0.05
    precondition(text.revision == VNRecognizeTextRequestRevision3)
    do {
        _ = try VNRecognizeTextRequest.supportedRecognitionLanguages(
            for: .accurate,
            revision: VNRecognizeTextRequestRevision3
        )
        fatalError("languages must fail closed")
    } catch {
        requireVNError(error, .dataUnavailable)
    }
    do {
        _ = try text.supportedRecognitionLanguages()
        fatalError("instance languages must fail closed")
    } catch {
        requireVNError(error, .dataUnavailable)
    }

    do {
        _ = try VNClassifyImageRequest.knownClassifications(forRevision: 2)
        fatalError("taxonomy must fail closed")
    } catch {
        requireVNError(error, .dataUnavailable)
    }
    do {
        _ = try VNClassifyImageRequest().supportedIdentifiers()
        fatalError("identifiers must fail closed")
    } catch {
        requireVNError(error, .dataUnavailable)
    }
    let animals = try! VNRecognizeAnimalsRequest.knownAnimalIdentifiers(
        forRevision: VNRecognizeAnimalsRequestRevision2
    )
    precondition(animals == [.cat, .dog])
    precondition(try! VNRecognizeAnimalsRequest().supportedIdentifiers() == [.cat, .dog])

    let contours = VNDetectContoursRequest()
    contours.contrastAdjustment = 1.5
    contours.contrastPivot = NSNumber(value: 0.25)
    contours.detectsDarkOnLight = false
    contours.maximumImageDimension = 256
    precondition(!contours.detectDarkOnLight)
    _ = VNDetectDocumentSegmentationRequest()
    _ = VNDetectHorizonRequest()
    let humans = VNDetectHumanRectanglesRequest()
    humans.upperBodyOnly = true
    _ = VNCalculateImageAestheticsScoresRequest()
    _ = VNGenerateAttentionBasedSaliencyImageRequest()
    _ = VNGenerateObjectnessBasedSaliencyImageRequest()
    let segmentation = VNGeneratePersonSegmentationRequest()
    segmentation.qualityLevel = .fast
    segmentation.outputPixelFormat = 0
    precondition(
        Set([
            VNGeneratePersonSegmentationRequest.QualityLevel.accurate,
            .balanced,
            .fast,
        ]).count == 3
    )
    precondition(segmentation.minimumLatencyFrameCount == 0)
    do {
        _ = try segmentation.supportedOutputPixelFormats()
        fatalError("segmentation formats must fail closed")
    } catch {
        requireVNError(error, .unsupportedRequest)
    }
    let flow = VNGenerateOpticalFlowRequest()
    flow.computationAccuracy = .high
    precondition(flow.computationAccuracy == .high)
    precondition(
        Set([
            VNGenerateOpticalFlowRequest.ComputationAccuracy.low,
            .medium,
            .high,
            .veryHigh,
        ]).count == 4
    )
    _ = VNHomographicImageRegistrationRequest(
        targetedImageData: Data([0x01]),
        options: [.properties: [:]]
    )
    _ = VNTranslationalImageRegistrationRequest(
        targetedImageURL: URL(fileURLWithPath: "/tmp/vision-target.png")
    )
    let track = VNTrackObjectRequest(
        detectedObjectObservation: VNDetectedObjectObservation(
            boundingBox: CGRect(x: 0.1, y: 0.1, width: 0.2, height: 0.2)
        )
    )
    track.trackingLevel = .fast
    track.isLastFrame = true
    precondition(track.supportedNumber(ofTrackersAndReturnError: nil) == 0)
    _ = VNTrackRectangleRequest(rectangleObservation: VNRectangleObservation(
        requestRevision: 1,
        topLeft: CGPoint(x: 0, y: 1),
        topRight: CGPoint(x: 1, y: 1),
        bottomRight: CGPoint(x: 1, y: 0),
        bottomLeft: CGPoint(x: 0, y: 0)
    ))

    var completed: [String] = []
    let saliency = VNGenerateAttentionBasedSaliencyImageRequest { request, error in
        completed.append(String(describing: type(of: request)))
        requireVNError(error!, .notImplemented)
    }
    let handler = VNImageRequestHandler(
        data: Data([0x89, 0x50, 0x4E, 0x47]),
        options: [
            .properties: ["Width": 1],
            .cameraIntrinsics: Data(),
            .ciContext: "unused-on-linux",
        ]
    )
    do {
        try handler.perform([barcodes, faces, text, saliency])
        fatalError("ML perform must fail closed")
    } catch {
        requireVNError(error, .notImplemented)
    }
    precondition(completed == ["VNGenerateAttentionBasedSaliencyImageRequest"])
    precondition(barcodes.results == nil)

    try! VNImageRequestHandler(data: Data([0x00])).perform([])

    do {
        try VNImageRequestHandler(data: Data()).perform([VNDetectRectanglesRequest()])
        fatalError("empty image must fail closed")
    } catch {
        requireVNError(error, .invalidImage)
    }

    let missingURL = URL(fileURLWithPath: "/tmp/vision-missing-image-\(UUID().uuidString).png")
    do {
        try VNImageRequestHandler(url: missingURL).perform([VNDetectHorizonRequest()])
        fatalError("missing URL must fail closed")
    } catch {
        requireVNError(error, .ioError)
    }
    do {
        try VNImageRequestHandler(URL: missingURL).perform([VNDetectHorizonRequest()])
        fatalError("missing URL convenience must fail closed")
    } catch {
        requireVNError(error, .ioError)
    }

    let cancelled = VNDetectHumanRectanglesRequest()
    cancelled.cancel()
    do {
        try VNSequenceRequestHandler().perform([cancelled], onImageData: Data([0x00]))
        fatalError("cancelled request must fail closed")
    } catch {
        requireVNError(error, .requestCancelled)
    }
    do {
        try VNSequenceRequestHandler().perform(
            [VNDetectHorizonRequest()],
            onImageURL: missingURL
        )
        fatalError("sequence missing URL must fail closed")
    } catch {
        requireVNError(error, .ioError)
    }

    barcodes.revision = 99
    do {
        try VNImageRequestHandler(data: Data([0x01])).perform([barcodes])
        fatalError("bad revision must fail closed")
    } catch {
        requireVNError(error, .unsupportedRevision)
    }
}

testGeometryMapping()
testPointsVectorsCircles()
testMinimumEnclosingCircle()
testIdentifiers()
testObservations()
testRequestsAndHandlers()
print("VISION_AGENT_RUNTIME_OK")
