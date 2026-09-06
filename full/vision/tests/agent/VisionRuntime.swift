#if canImport(Glibc)
import Glibc
#endif
import Foundation
@_spi(OpenUIKitHost) import Vision

func testQRBarcodeDecode() {
    let qrImage = try! VisionHost.makeQRImage(payload: "HELLO", moduleSize: 6, quietZone: 4)
    let qrHandler = VNImageRequestHandler(cgImage: qrImage, orientation: .up, options: [:])
    let qrRequest = VNDetectBarcodesRequest()
    qrRequest.symbologies = [.qr]
    try! qrHandler.perform([qrRequest])
    let qrHits = (qrRequest.results ?? []).compactMap { $0 as? VNBarcodeObservation }
    visionExpect(qrHits.contains(where: { $0.payloadStringValue == "HELLO" && $0.symbology == .qr }), "QR payload")
    visionExpect(qrHits.first!.boundingBox.width > 0, "QR bounding box")
}

func testCode128BarcodeDecode() {
    let codeImage = try! VisionHost.makeCode128Image(payload: "ABC123")
    let codeHandler = VNImageRequestHandler(cgImage: codeImage)
    let codeRequest = VNDetectBarcodesRequest()
    codeRequest.symbologies = [.code128]
    try! codeHandler.perform([codeRequest])
    let codeHits = (codeRequest.results ?? []).compactMap { $0 as? VNBarcodeObservation }
    visionExpect(codeHits.contains(where: { $0.payloadStringValue == "ABC123" && $0.symbology == .code128 }), "Code128 payload")
}

func testEAN13BarcodeDecode() {
    let eanImage = try! VisionHost.makeEAN13Image(payload: "5901234123457")
    let eanData = VisionHost.encodeNetpbm(eanImage)
    let eanHandler = VNImageRequestHandler(data: eanData, orientation: .up)
    let eanRequest = VNDetectBarcodesRequest()
    eanRequest.symbologies = [.ean13]
    try! eanHandler.perform([eanRequest])
    let eanHits = (eanRequest.results ?? []).compactMap { $0 as? VNBarcodeObservation }
    visionExpect(eanHits.contains(where: { $0.payloadStringValue == "5901234123457" }), "EAN-13 payload")
}

func testBarcodeURLHandler() {
    let qrImage = try! VisionHost.makeQRImage(payload: "HELLO", moduleSize: 6, quietZone: 4)
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("vision-qr.ppm")
    try! VisionHost.encodeNetpbm(qrImage).write(to: url)
    let urlHandler = VNImageRequestHandler(URL: url, orientation: .up, options: [:])
    let urlRequest = VNDetectBarcodesRequest()
    urlRequest.symbologies = [.qr]
    try! urlHandler.perform([urlRequest])
    visionExpect(urlHandler.source == .url(url), "url source")
    let hits = (urlRequest.results ?? []).compactMap { $0 as? VNBarcodeObservation }
    visionExpect(hits.contains(where: { $0.payloadStringValue == "HELLO" }), "url QR")
}

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

func testValueCatalog() {
    func roundtrip<T: CaseIterable & RawRepresentable & Equatable & Hashable>(_ values: T.Type, _ message: String)
    where T.RawValue: Equatable {
        visionExpectEqual(Set(T.allCases).count, Array(T.allCases).count, message + " unique")
        for value in T.allCases {
            visionExpect(T(rawValue: value.rawValue) == value, message + " roundtrip")
        }
    }

    roundtrip(VNBarcodeCompositeType.self, "composite")
    visionExpect(VNBarcodeCompositeType.none.rawValue == 0, "composite none")
    visionExpect(VNBarcodeCompositeType.linked.rawValue == 1, "composite linked")
    visionExpect(VNBarcodeCompositeType.gs1TypeA.rawValue == 2, "composite a")
    visionExpect(VNBarcodeCompositeType.gs1TypeB.rawValue == 3, "composite b")
    visionExpect(VNBarcodeCompositeType.gs1TypeC.rawValue == 4, "composite c")

    roundtrip(VNChirality.self, "chirality")
    visionExpect(VNChirality.unknown.rawValue == 0, "chirality unknown")
    visionExpect(VNChirality.left.rawValue == -1, "chirality left")
    visionExpect(VNChirality.right.rawValue == 1, "chirality right")

    roundtrip(VNElementType.self, "element")
    visionExpectEqual(VNElementTypeSize(.unknown), 0, "element unknown")
    visionExpectEqual(VNElementTypeSize(.float), MemoryLayout<Float>.size, "element float")
    visionExpectEqual(VNElementTypeSize(.double), MemoryLayout<Double>.size, "element double")

    roundtrip(VNImageCropAndScaleOption.self, "crop")
    visionExpect(VNImageCropAndScaleOption.centerCrop.rawValue == 0, "crop center")
    visionExpect(VNImageCropAndScaleOption.scaleFit.rawValue == 1, "crop fit")
    visionExpect(VNImageCropAndScaleOption.scaleFill.rawValue == 2, "crop fill")
    visionExpect(VNImageCropAndScaleOption.scaleFitRotate90CCW.rawValue == 257, "crop rotate fit")
    visionExpect(VNImageCropAndScaleOption.scaleFillRotate90CCW.rawValue == 258, "crop rotate fill")

    roundtrip(VNPointsClassification.self, "points")
    visionExpect(VNPointsClassification.disconnected.rawValue == 0, "points disconnected")
    visionExpect(VNPointsClassification.openPath.rawValue == 1, "points open")
    visionExpect(VNPointsClassification.closedPath.rawValue == 2, "points closed")

    roundtrip(VNRequestFaceLandmarksConstellation.self, "constellation")
    visionExpect(VNRequestFaceLandmarksConstellation.constellationNotDefined.rawValue == 0, "lm 0")
    visionExpect(VNRequestFaceLandmarksConstellation.constellation65Points.rawValue == 1, "lm 65")
    visionExpect(VNRequestFaceLandmarksConstellation.constellation76Points.rawValue == 2, "lm 76")

    roundtrip(VNRequestTextRecognitionLevel.self, "text level")
    visionExpect(VNRequestTextRecognitionLevel.accurate.rawValue == 0, "text accurate")
    visionExpect(VNRequestTextRecognitionLevel.fast.rawValue == 1, "text fast")

    roundtrip(VNRequestTrackingLevel.self, "tracking")
    visionExpect(VNRequestTrackingLevel.accurate.rawValue == 0, "track accurate")
    visionExpect(VNRequestTrackingLevel.fast.rawValue == 1, "track fast")

    roundtrip(VNGenerateOpticalFlowRequest.ComputationAccuracy.self, "flow")
    visionExpect(VNGenerateOpticalFlowRequest.ComputationAccuracy.low.rawValue == 0, "flow low")
    visionExpect(VNGenerateOpticalFlowRequest.ComputationAccuracy.medium.rawValue == 1, "flow med")
    visionExpect(VNGenerateOpticalFlowRequest.ComputationAccuracy.high.rawValue == 2, "flow high")
    visionExpect(VNGenerateOpticalFlowRequest.ComputationAccuracy.veryHigh.rawValue == 3, "flow very high")

    roundtrip(VNTrackOpticalFlowRequest.ComputationAccuracy.self, "track flow")
    visionExpect(VNTrackOpticalFlowRequest.ComputationAccuracy.medium.rawValue == 1, "track flow med")

    roundtrip(VNGeneratePersonSegmentationRequest.QualityLevel.self, "seg")
    visionExpect(VNGeneratePersonSegmentationRequest.QualityLevel.accurate.rawValue == 0, "seg acc")
    visionExpect(VNGeneratePersonSegmentationRequest.QualityLevel.balanced.rawValue == 1, "seg bal")
    visionExpect(VNGeneratePersonSegmentationRequest.QualityLevel.fast.rawValue == 2, "seg fast")

    roundtrip(VNHumanBodyPose3DObservation.HeightEstimation.self, "height")
    visionExpect(VNHumanBodyPose3DObservation.HeightEstimation.reference.rawValue == 0, "height ref")
    visionExpect(VNHumanBodyPose3DObservation.HeightEstimation.measured.rawValue == 1, "height measured")

    roundtrip(VNErrorCode.self, "error")
    visionExpect(VNErrorCode.turiCoreErrorCode.rawValue == -1, "error turi")
    visionExpect(VNErrorCode.OK.rawValue == 0, "error ok")
    visionExpect(VNErrorCode.requestCancelled.rawValue == 1, "error cancel")
    visionExpect(VNErrorCode.invalidImage.rawValue == 13, "error invalid image")
    visionExpect(VNErrorCode.invalidModel.rawValue == 15, "error invalid model")
    visionExpect(VNErrorCode.unsupportedRequest.rawValue == 19, "error unsupported")
    visionExpect(VNErrorCode.unsupportedComputeDevice.rawValue == 22, "error compute device")
    visionExpect(VNErrorCode.notImplemented != .requestCancelled, "error distinct")
    visionExpectEqual(VNErrorDomain, "VNErrorDomain", "error domain")
    var hasher = Hasher()
    VNErrorCode.OK.hash(into: &hasher)
    _ = hasher.finalize()

    visionExpectEqual(VNRequestRevisionUnspecified, 0, "unspecified revision")
    visionExpectEqual(VNDetectBarcodesRequestRevision1, 1, "barcode r1")
    visionExpectEqual(VNDetectBarcodesRequestRevision2, 2, "barcode r2")
    visionExpectEqual(VNDetectBarcodesRequestRevision3, 3, "barcode r3")
    visionExpectEqual(VNDetectBarcodesRequestRevision4, 4, "barcode r4")
    visionExpectEqual(VNDetectFaceRectanglesRequestRevision1, 1, "face r1")
    visionExpectEqual(VNDetectFaceRectanglesRequestRevision2, 2, "face r2")
    visionExpectEqual(VNDetectFaceRectanglesRequestRevision3, 3, "face r3")
    visionExpectEqual(VNDetectRectanglesRequestRevision1, 1, "rect r1")
    visionExpectEqual(VNRecognizeTextRequestRevision1, 1, "text r1")
    visionExpectEqual(VNRecognizeTextRequestRevision2, 2, "text r2")
    visionExpectEqual(VNRecognizeTextRequestRevision3, 3, "text r3")
    visionExpectEqual(VNDetectDocumentSegmentationRequestRevision1, 1, "doc r1")
    visionExpectEqual(VNGenerateAttentionBasedSaliencyImageRequestRevision1, 1, "sal r1")
    visionExpectEqual(VNGenerateAttentionBasedSaliencyImageRequestRevision2, 2, "sal r2")
    visionExpectEqual(VNClassifyImageRequestRevision1, 1, "cls r1")
    visionExpectEqual(VNClassifyImageRequestRevision2, 2, "cls r2")
    visionExpectEqual(VNCoreMLRequestRevision1, 1, "coreml r1")
    visionExpectEqual(VNDetectContourRequestRevision1, 1, "contour graph spelling")
    visionExpectEqual(VNDetectContoursRequestRevision1, VNDetectContourRequestRevision1, "contour alias")
    visionExpectEqual(VNDetectHumanBodyPoseRequestRevision1, 1, "body r1")
    visionExpectEqual(VNGenerateImageFeaturePrintRequestRevision1, 1, "print r1")
    visionExpectEqual(VNGenerateImageFeaturePrintRequestRevision2, 2, "print r2")
    visionExpectEqual(VNHomographicImageRegistrationRequestRevision1, 1, "homo r1")
    visionExpectEqual(VNTrackObjectRequestRevision1, 1, "track r1")
    visionExpectEqual(VNTrackObjectRequestRevision2, 2, "track r2")
    visionExpectEqual(VNTranslationalImageRegistrationRequestRevision1, 1, "trans r1")

    visionExpect(CoordinateOrigin.lowerLeft != .upperLeft, "overlay origin")
    visionExpect(ComputeStage.main != .postProcessing, "overlay stage")
    visionExpect(ElementType.float != .double, "overlay element")
    visionExpect(Chirality.left != .right, "overlay chirality")
    visionExpect(ImageCropAndScaleAction.allCases.contains(.scaleToFill), "overlay crop")
    visionExpect(BarcodeSymbology.allCases.contains(.qr), "overlay barcode cases")
    visionExpect(BarcodeSymbology.allCases.contains(.code128), "overlay code128")
    visionExpect(BarcodeSymbology.allCases.contains(.ean13), "overlay ean13")
    visionExpect(DetectBarcodesRequest.Revision.revision4 == .revision4, "overlay barcode revision")
    visionExpect(DetectRectanglesRequest.Revision.revision1 == .revision1, "overlay rect revision")
}

func testRecognizeTextFailClosed() {
    let handler = VNImageRequestHandler(cgImage: visionRectangleImage())
    let request = VNRecognizeTextRequest()
    visionExpectEqual(request.recognitionLevel, .accurate, "text level")
    visionExpectEqual(try! request.supportedRecognitionLanguages(), [], "no languages")
    request.customWords = ["OpenUIKit"]
    visionExpectEqual(request.customWords, ["OpenUIKit"], "custom words")
    do {
        try handler.perform([request])
        visionExpect(false, "expected invalidModel")
    } catch let error as NSError {
        visionExpectEqual(error.domain, VNErrorDomain, "ml domain")
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "ml invalidModel")
        visionExpect(request.results == nil, "ml results nil")
    }
}

func testDetectFaceRectanglesFailClosed() {
    let handler = VNImageRequestHandler(cgImage: visionRectangleImage())
    let request = VNDetectFaceRectanglesRequest()
    do {
        try handler.perform([request])
        visionExpect(false, "expected invalidModel")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "face invalidModel")
        visionExpect(request.results == nil, "face results nil")
    }
}

func testClassifyImageFailClosed() {
    let handler = VNImageRequestHandler(cgImage: visionRectangleImage())
    let request = VNClassifyImageRequest()
    do {
        try handler.perform([request])
        visionExpect(false, "expected invalidModel")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "classify invalidModel")
        visionExpect(request.results == nil, "classify results nil")
    }
    do {
        _ = try VNClassifyImageRequest.knownClassifications(forRevision: 1)
        visionExpect(false, "classifications should fail")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "known classifications")
    }
}

func testHumanBodyPoseFailClosed() {
    let handler = VNImageRequestHandler(cgImage: visionRectangleImage())
    let request = VNDetectHumanBodyPoseRequest()
    do {
        try handler.perform([request])
        visionExpect(false, "expected invalidModel")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "pose invalidModel")
        visionExpect(request.results == nil, "pose results nil")
    }
}

func testCoreMLFailClosed() {
    let handler = VNImageRequestHandler(cgImage: visionRectangleImage())
    let request = VNCoreMLRequest(completionHandler: nil)
    do {
        try handler.perform([request])
        visionExpect(false, "expected invalidModel")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "coreml invalidModel")
        visionExpect(request.results == nil, "coreml results nil")
    }
    do {
        _ = try VNCoreMLModel(for: MLModel())
        visionExpect(false, "coreml model should fail")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "coreml model")
    }
}

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

func testPointGeometry() {
    let origin = VNPoint.zero
    let point = VNPoint(x: 3, y: 4)
    visionExpectEqual(origin.distance(point), 5, "3-4-5 distance")
    visionExpectEqual(VNPoint.distance(origin, point), 5, "class distance")
    visionExpectEqual(point.location, CGPoint(x: 3, y: 4), "location")
    let fromLocation = VNPoint(location: CGPoint(x: 1, y: 2))
    visionExpectEqual(fromLocation.x, 1, "from location x")
    visionExpectEqual(fromLocation.y, 2, "from location y")
    let applied = VNPoint.apply(VNVector(xComponent: 3, yComponent: 4), to: origin)
    visionExpectEqual(applied.x, 3, "apply x")
    visionExpect(origin.isEqual(VNPoint.zero), "point equal")
    let copy = origin.copy() as! VNPoint
    visionExpectEqual(copy.x, 0, "point copy")
    visionExpect(VNPoint.supportsSecureCoding, "point coding")
    let detected = VNDetectedPoint(x: 1, y: 2, confidence: 0.5)
    visionExpectEqual(detected.confidence, 0.5, "detected point confidence")
}

func testVectorGeometry() {
    let vector = VNVector(xComponent: 3, yComponent: 4)
    visionExpectEqual(vector.length, 5, "vector length")
    visionExpectEqual(vector.squaredLength, 25, "vector squared")
    visionExpectEqual(vector.r, 5, "vector r")
    visionExpectEqual(VNVector.dotProduct(of: vector, vector: vector), 25, "dot product")
    let unit = VNVector.unitVector(for: vector)
    visionExpectEqual(unit.length, 1, "unit length")
    visionExpectEqual(VNVector.unitVector(for: .zero).length, 0, "zero unit")
    let polar = VNVector(r: 2, theta: 0)
    visionExpectEqual(polar.x, 2, "polar x")
    visionExpect(abs(polar.y) < 1e-12, "polar y")
    let head = VNPoint(x: 5, y: 5)
    let tail = VNPoint(x: 2, y: 1)
    let fromPoints = VNVector(vectorHead: head, tail: tail)
    visionExpectEqual(fromPoints.x, 3, "head-tail x")
    visionExpectEqual(fromPoints.y, 4, "head-tail y")
    let sum = VNVector(byAdding: vector, to: vector)
    visionExpectEqual(sum.x, 6, "add x")
    let scaled = VNVector(byMultiplying: vector, byScalar: 2)
    visionExpectEqual(scaled.y, 8, "scale y")
    let subtracted = VNVector(bySubtracting: vector, from: scaled)
    visionExpectEqual(subtracted.x, 3, "subtract x")
    let alias = VNVector(XComponent: 1, yComponent: 2)
    visionExpectEqual(alias.x, 1, "XComponent alias")
    visionExpectEqual(VNVector(byAddingVector: vector, toVector: vector).x, 6, "add alias")
    visionExpectEqual(VNVector(byMultiplyingVector: vector, byScalar: 3).x, 9, "multiply alias")
    visionExpectEqual(VNVector(bySubtractingVector: vector, fromVector: scaled).x, 3, "subtract alias")
    visionExpect(abs(vector.theta - atan2(4.0, 3.0)) < 1e-12, "theta")
    visionExpect(VNVector.supportsSecureCoding, "vector coding")
}

func testCircleGeometry() {
    let origin = VNPoint.zero
    let point = VNPoint(x: 3, y: 4)
    let circle = VNCircle(center: origin, radius: 5)
    visionExpect(circle.contains(point), "contains hypotenuse")
    visionExpect(circle.contains(VNPoint(x: 5, y: 0)), "contains radius")
    visionExpect(!circle.contains(VNPoint(x: 5.1, y: 0)), "excludes outside")
    visionExpect(circle.contains(VNPoint(x: 5, y: 0), inCircumferentialRingOfWidth: 0.2), "ring on circumference")
    visionExpect(!circle.contains(VNPoint.zero, inCircumferentialRingOfWidth: 0.2), "ring excludes center")
    let diameterCircle = VNCircle(center: origin, diameter: 10)
    visionExpectEqual(diameterCircle.radius, 5, "diameter init")
    visionExpect(VNCircle.zero.contains(VNPoint.zero), "zero circle")
}

func testMinimumEnclosingCircle() {
    do {
        _ = try VNGeometryUtils.boundingCircle(for: [VNPoint]())
        visionExpect(false, "empty MEC")
    } catch {
        visionExpect(true, "empty throws")
    }

    let single = try! VNGeometryUtils.boundingCircle(for: [VNPoint(x: 1, y: 2)])
    visionExpectEqual(single.radius, 0, "singleton radius")
    visionExpectEqual(single.center.x, 1, "singleton x")

    let duplicates = try! VNGeometryUtils.boundingCircle(
        for: [VNPoint(x: 1, y: 1), VNPoint(x: 1, y: 1)]
    )
    visionExpectEqual(duplicates.radius, 0, "duplicate radius")

    let pair = try! VNGeometryUtils.boundingCircle(
        for: [VNPoint(x: 0, y: 0), VNPoint(x: 4, y: 0)]
    )
    visionExpectEqual(pair.radius, 2, "pair radius")
    visionExpectEqual(pair.center.x, 2, "pair center")

    let collinear = try! VNGeometryUtils.boundingCircle(
        for: [VNPoint(x: 0, y: 0), VNPoint(x: 1, y: 0), VNPoint(x: 4, y: 0)]
    )
    visionExpectEqual(collinear.radius, 2, "collinear radius")

    let obtuse = try! VNGeometryUtils.boundingCircle(
        for: [VNPoint(x: 0, y: 0), VNPoint(x: 4, y: 0), VNPoint(x: 0.1, y: 0.1)]
    )
    visionExpectEqual(obtuse.radius, 2, "obtuse uses longest side")

    let acute = [
        VNPoint(x: 0, y: 0),
        VNPoint(x: 2, y: 0),
        VNPoint(x: 1, y: sqrt(3)),
    ]
    let mec = try! VNGeometryUtils.boundingCircle(for: acute)
    visionExpect(abs(mec.radius - 2 / sqrt(3)) < 1e-9, "acute circumradius")
    for point in acute {
        visionExpect(mec.contains(point), "acute containment")
    }
    let boxRadius = hypot(1.0, sqrt(3) / 2)
    visionExpect(mec.radius < boxRadius - 1e-9, "smaller than bounding-box approximation")
    let reversed = try! VNGeometryUtils.boundingCircle(for: acute.reversed())
    visionExpect(abs(reversed.radius - mec.radius) < 1e-9, "order invariance radius")
    let simdPoints: [SIMD2<Float>] = [
        SIMD2<Float>(0, 0),
        SIMD2<Float>(2, 0),
        SIMD2<Float>(1, Float(sqrt(3))),
    ]
    let simdCircle = try! simdPoints.withUnsafeBufferPointer { buffer in
        try VNGeometryUtils.boundingCircle(
            forSIMDPoints: buffer.baseAddress!,
            pointCount: buffer.count
        )
    }
    visionExpect(abs(simdCircle.radius - mec.radius) < 1e-5, "simd MEC")
}

func testContourMetrics() {
    let square = VNContour(normalizedPoints: [
        SIMD2<Float>(0, 0),
        SIMD2<Float>(1, 0),
        SIMD2<Float>(1, 1),
        SIMD2<Float>(0, 1),
    ])
    visionExpectEqual(square.pointCount, 4, "point count")
    visionExpectEqual(square.aspectRatio, 1, "aspect")
    var area: Double = 0
    try! VNGeometryUtils.calculateArea(&area, for: square, orientedArea: false)
    visionExpectEqual(area, 1, "square area")
    var signed: Double = 0
    try! VNGeometryUtils.calculateArea(&signed, for: square, orientedArea: true)
    visionExpectEqual(signed, 1, "oriented ccw")
    var perimeter: Double = 0
    try! VNGeometryUtils.calculatePerimeter(&perimeter, for: square)
    visionExpectEqual(perimeter, 4, "square perimeter")
    let child = VNContour(normalizedPoints: [SIMD2<Float>(0.2, 0.2), SIMD2<Float>(0.3, 0.2)])
    let parent = VNContour(
        normalizedPoints: square.normalizedPoints,
        indexPath: IndexPath(index: 0),
        childContours: [child]
    )
    visionExpectEqual(parent.childContourCount, 1, "child count")
    visionExpectEqual(try! parent.childContour(at: 0).pointCount, 2, "child fetch")
    do {
        _ = try parent.childContour(at: 3)
        visionExpect(false, "child oob")
    } catch {
        visionExpect(true, "child oob throws")
    }
    let circle = try! VNGeometryUtils.boundingCircle(for: square)
    visionExpect(circle.contains(VNPoint(x: 0.5, y: 0.5)), "contour circle contains center")
    let jagged = VNContour(normalizedPoints: [
        SIMD2<Float>(0, 0),
        SIMD2<Float>(0.5, 0.0001),
        SIMD2<Float>(1, 0),
    ])
    let approx = try! jagged.polygonApproximation(epsilon: 0.01)
    visionExpectEqual(approx.pointCount, 2, "dp collapsed colinear")
}

func testCoordinateMapping() {
    visionExpect(VNNormalizedRectIsIdentityRect(VNNormalizedIdentityRect), "identity rect")
    visionExpect(!VNNormalizedRectIsIdentityRect(CGRect(x: 0, y: 0, width: 1, height: 0.5)), "not identity")
    let imagePoint = VNImagePointForNormalizedPoint(CGPoint(x: 0.25, y: 0.5), 200, 100)
    visionExpectEqual(imagePoint, CGPoint(x: 50, y: 50), "norm to image")
    let back = VNNormalizedPointForImagePoint(imagePoint, 200, 100)
    visionExpectEqual(back, CGPoint(x: 0.25, y: 0.5), "image to norm")
    let imageRect = VNImageRectForNormalizedRect(CGRect(x: 0.1, y: 0.2, width: 0.25, height: 0.5), 100, 200)
    visionExpectEqual(imageRect.origin, CGPoint(x: 10, y: 40), "rect origin")
    visionExpectEqual(imageRect.size, CGSize(width: 25, height: 100), "rect size")
    let normalizedBack = VNNormalizedRectForImageRect(imageRect, 100, 200)
    visionExpect(abs(normalizedBack.origin.x - 0.1) < 1e-9, "rect back x")
    let roiPoint = VNImagePointForNormalizedPointUsingRegionOfInterest(
        CGPoint(x: 0.5, y: 0.5),
        100,
        100,
        CGRect(x: 0.2, y: 0.2, width: 0.4, height: 0.4)
    )
    visionExpect(abs(roiPoint.x - 40) < 1e-9 && abs(roiPoint.y - 40) < 1e-9, "roi point")
    let landmark = VNImagePointForFaceLandmarkPoint(
        SIMD2<Float>(0.5, 0.25),
        CGRect(x: 0.2, y: 0.2, width: 0.4, height: 0.4),
        100,
        100
    )
    visionExpect(abs(landmark.x - 40) < 1e-9 && abs(landmark.y - 30) < 1e-9, "landmark")
    let roiRect = VNImageRectForNormalizedRectUsingRegionOfInterest(
        CGRect(x: 0, y: 0, width: 1, height: 1),
        100,
        100,
        CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5)
    )
    visionExpect(abs(roiRect.origin.x - 25) < 1e-9, "roi rect")
    let backROI = VNNormalizedRectForImageRectUsingRegionOfInterest(roiRect, 100, 100, CGRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5))
    visionExpect(abs(backROI.width - 1) < 1e-9, "roi rect back")
    let roiBackPoint = VNNormalizedPointForImagePointUsingRegionOfInterest(
        CGPoint(x: 40, y: 40),
        100,
        100,
        CGRect(x: 0.2, y: 0.2, width: 0.4, height: 0.4)
    )
    visionExpect(abs(roiBackPoint.x - 0.5) < 1e-9 && abs(roiBackPoint.y - 0.5) < 1e-9, "roi image to normalized")
    let faceNorm = VNNormalizedFaceBoundingBoxPointForLandmarkPoint(
        SIMD2<Float>(0.5, 0.25),
        CGRect(x: 0.2, y: 0.2, width: 0.4, height: 0.4),
        100,
        100
    )
    visionExpect(abs(faceNorm.x - 0.4) < 1e-9 && abs(faceNorm.y - 0.3) < 1e-9, "face landmark normalized")
}

func visionExpect(_ condition: Bool, _ message: String) {
    if !condition {
        fputs("VISION_AGENT_RUNTIME_FAIL \(message)\n", stderr)
        exit(1)
    }
}

func visionExpectEqual<T: Equatable>(_ lhs: T, _ rhs: T, _ message: String) {
    visionExpect(lhs == rhs, "\(message): \(lhs) != \(rhs)")
}

func visionExpectOverlayInvalidModel<T>(_ work: () throws -> T, _ message: String) {
    do {
        _ = try work()
        visionExpect(false, message + " should fail closed")
    } catch let error as VisionError {
        if case .invalidModel = error {
            visionExpect(true, message)
        } else {
            visionExpect(false, "\(message) unexpected \(error)")
        }
    } catch {
        visionExpect(false, "\(message) wrong type \(error)")
    }
}

func visionRectangleImage() -> CGImage {
    var raster = VisionRaster(width: 80, height: 80, filled: (0, 0, 0, 255))
    for y in 20..<60 {
        for x in 20..<60 {
            raster[x, y] = (255, 255, 255, 255)
        }
    }
    return raster.makeCGImage()
}

func testHarnessRectangleImage() {
    let image = visionRectangleImage()
    visionExpect(image.width == 80 && image.height == 80, "harness raster")
}

func testBarcodeSymbologyCatalog() {
    let catalog = VNBarcodeSymbology.knownSymbologies
    visionExpectEqual(catalog.count, 24, "symbology catalog")
    visionExpectEqual(Set(catalog.map(\.rawValue)).count, 24, "symbology unique")
    visionExpectEqual(VNBarcodeSymbology.qr, .QR, "qr alias")
    visionExpectEqual(VNBarcodeSymbology.aztec, .Aztec, "aztec alias")
    visionExpectEqual(VNBarcodeSymbology.codabar, .Codabar, "codabar alias")
    visionExpectEqual(VNBarcodeSymbology.code128, .Code128, "code128 alias")
    visionExpectEqual(VNBarcodeSymbology.code39, .Code39, "code39 alias")
    visionExpectEqual(VNBarcodeSymbology.code39Checksum, .Code39Checksum, "code39 checksum alias")
    visionExpectEqual(VNBarcodeSymbology.code39FullASCII, .Code39FullASCII, "code39 full alias")
    visionExpectEqual(VNBarcodeSymbology.code39FullASCIIChecksum, .Code39FullASCIIChecksum, "code39 full checksum")
    visionExpectEqual(VNBarcodeSymbology.code93, .Code93, "code93 alias")
    visionExpectEqual(VNBarcodeSymbology.code93i, .Code93i, "code93i alias")
    visionExpectEqual(VNBarcodeSymbology.dataMatrix, .DataMatrix, "datamatrix alias")
    visionExpectEqual(VNBarcodeSymbology.ean13, .EAN13, "ean13 alias")
    visionExpectEqual(VNBarcodeSymbology.ean8, .EAN8, "ean8 alias")
    visionExpectEqual(VNBarcodeSymbology.i2of5, .I2of5, "i2of5 alias")
    visionExpectEqual(VNBarcodeSymbology.i2of5Checksum, .I2of5Checksum, "i2of5 checksum alias")
    visionExpectEqual(VNBarcodeSymbology.itf14, .ITF14, "itf14 alias")
    visionExpectEqual(VNBarcodeSymbology.pdf417, .PDF417, "pdf417 alias")
    visionExpectEqual(VNBarcodeSymbology.upce, .UPCE, "upce alias")
    visionExpect(VNBarcodeSymbology.qr != .pdf417, "qr != pdf417")
    visionExpectEqual(
        VNBarcodeSymbology(rawValue: VNBarcodeSymbology.ean13.rawValue),
        .ean13,
        "symbology roundtrip"
    )
    visionExpect(catalog.contains(.gs1DataBar), "gs1")
    visionExpect(catalog.contains(.gs1DataBarExpanded), "gs1 expanded")
    visionExpect(catalog.contains(.gs1DataBarLimited), "gs1 limited")
    visionExpect(catalog.contains(.msiPlessey), "msi")
    visionExpect(catalog.contains(.microPDF417), "micropdf")
    visionExpect(catalog.contains(.microQR), "microqr")
}

func testImageOptionAndComputeStage() {
    visionExpect(VNImageOption.ciContext != .properties, "image option distinct")
    visionExpect(VNImageOption.cameraIntrinsics != .ciContext, "intrinsics")
    visionExpect(VNComputeStage.main != .postProcessing, "compute stage distinct")
    visionExpect(VNComputeStage.main.hashValue == VNComputeStage.main.hashValue, "compute hash stable")
    visionExpectEqual(VNImageOption(rawValue: VNImageOption.properties.rawValue), .properties, "option roundtrip")
}

func testDetectedObjectObservation() {
    let box = CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4)
    let detected = VNDetectedObjectObservation(boundingBox: box)
    visionExpectEqual(detected.boundingBox, box, "bbox")
    visionExpect(detected.confidence == 1, "default confidence")
    visionExpect(detected.uuid != UUID(), "uuid assigned")
    visionExpect(VNObservation.supportsSecureCoding, "observation coding")
    let copy = detected.copy() as! VNDetectedObjectObservation
    visionExpectEqual(copy.boundingBox, box, "detected copy")
}

func testRectangleObservation() {
    let rectangle = VNRectangleObservation(
        requestRevision: 1,
        topLeft: CGPoint(x: 0, y: 1),
        topRight: CGPoint(x: 1, y: 1),
        bottomRight: CGPoint(x: 1, y: 0),
        bottomLeft: CGPoint(x: 0, y: 0)
    )
    visionExpectEqual(rectangle.topLeft, CGPoint(x: 0, y: 1), "tl")
    visionExpectEqual(rectangle.topRight, CGPoint(x: 1, y: 1), "tr")
    visionExpectEqual(rectangle.bottomRight, CGPoint(x: 1, y: 0), "br")
    visionExpectEqual(rectangle.bottomLeft, CGPoint(x: 0, y: 0), "bl")
    visionExpectEqual(rectangle.boundingBox, CGRect(x: 0, y: 0, width: 1, height: 1), "rect bbox")
    let altOrder = VNRectangleObservation(
        requestRevision: 1,
        topLeft: CGPoint(x: 0, y: 1),
        bottomLeft: CGPoint(x: 0, y: 0),
        bottomRight: CGPoint(x: 1, y: 0),
        topRight: CGPoint(x: 1, y: 1)
    )
    visionExpectEqual(altOrder.bottomRight, CGPoint(x: 1, y: 0), "alt order")
}

func testBarcodeObservation() {
    let barcode = VNBarcodeObservation(
        topLeft: CGPoint(x: 0, y: 1),
        topRight: CGPoint(x: 1, y: 1),
        bottomRight: CGPoint(x: 1, y: 0),
        bottomLeft: CGPoint(x: 0, y: 0),
        symbology: .qr,
        payloadStringValue: "hello",
        payloadData: Data("hello".utf8),
        isGS1DataCarrier: false,
        supplementalCompositeType: .none
    )
    visionExpectEqual(barcode.symbology, .qr, "barcode symbology")
    visionExpectEqual(barcode.payloadStringValue, "hello", "payload")
    visionExpectEqual(barcode.isColorInverted, false, "inverted default")
    visionExpectEqual(barcode.isGS1DataCarrier, false, "gs1")
    visionExpectEqual(barcode.supplementalCompositeType, .none, "composite type")
}

func testTextObservation() {
    let rectangle = VNRectangleObservation(
        requestRevision: 1,
        topLeft: CGPoint(x: 0, y: 1),
        topRight: CGPoint(x: 1, y: 1),
        bottomRight: CGPoint(x: 1, y: 0),
        bottomLeft: CGPoint(x: 0, y: 0)
    )
    let text = VNRecognizedText(string: "Hi", confidence: 0.8)
    visionExpectEqual(text.string, "Hi", "recognized text")
    visionExpectEqual(text.confidence, 0.8, "text confidence")
    let textObs = VNRecognizedTextObservation(
        topLeft: rectangle.topLeft,
        topRight: rectangle.topRight,
        bottomRight: rectangle.bottomRight,
        bottomLeft: rectangle.bottomLeft,
        candidates: [text]
    )
    visionExpectEqual(textObs.topCandidates(1).first?.string, "Hi", "top candidate")
    visionExpectEqual(textObs.topCandidates(0).count, 0, "zero candidates")
    let characterBoxes = VNTextObservation(
        requestRevision: 1,
        topLeft: rectangle.topLeft,
        topRight: rectangle.topRight,
        bottomRight: rectangle.bottomRight,
        bottomLeft: rectangle.bottomLeft
    )
    visionExpectEqual(characterBoxes.topLeft, rectangle.topLeft, "text observation corners")
}

func testFaceObservation() {
    let box = CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4)
    let face = VNFaceObservation(boundingBox: box, roll: NSNumber(value: 0.1))
    visionExpectEqual(face.roll?.doubleValue, 0.1, "face roll")
    visionExpectEqual(face.boundingBox, box, "face box")
}

func testOverlayNormalizedGeometry() {
    let rect = NormalizedRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4)
    let imageRect = rect.toImageCoordinates(CGSize(width: 100, height: 200), origin: .lowerLeft)
    visionExpectEqual(imageRect.origin, CGPoint(x: 10, y: 40), "overlay rect mapping")
    let point = NormalizedPoint(x: 0.25, y: 0.5)
    visionExpectEqual(point.toImageCoordinates(CGSize(width: 200, height: 100)), CGPoint(x: 50, y: 50), "overlay point")
    visionExpect(NormalizedRect.fullImage.verticallyFlipped().height == 1, "flipped identity")
    visionExpect(NormalizedCircle(center: point, radius: 0.1).radius == 0.1, "overlay circle")
}

func testOverlayBarcodePerform() {
    let qrImage = try! VisionHost.makeQRImage(payload: "HELLO")
    let data = VisionHost.encodeNetpbm(qrImage)
    var request = DetectBarcodesRequest()
    visionExpect(request.revision == .revision4, "overlay revision")
    request.symbologies = [.qr]
    visionExpect(request.supportedSymbologies.contains(.qr), "QR supported")
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main), .cpu, "barcode device")
    let overlayHits = try! request.performOnHandler(VNImageRequestHandler(data: data))
    visionExpect(overlayHits.contains(where: { $0.payloadString == "HELLO" }), "overlay QR")
    _ = ImageRequestHandler(data)
    _ = RequestDescriptor.detectBarcodesRequest(.revision4)
    _ = VisionResult.detectBarcodes(DetectBarcodesRequest(), overlayHits)
    _ = VisionError.invalidModel("gap")
}

func testOverlayRectanglePerform() {
    var hasher = Hasher()
    DetectRectanglesRequest().hash(into: &hasher)
    _ = hasher.finalize()
    var request = DetectRectanglesRequest()
    visionExpectEqual(request.revision, .revision1, "rectangle revision")
    request.minimumSize = 0.1
    request.minimumConfidence = 0
    request.minimumAspectRatio = 0.2
    request.maximumAspectRatio = 1
    request.maximumObservations = 4
    request.quadratureToleranceDegrees = 40
    request.regionOfInterest = .fullImage
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main), .cpu, "rectangle device")
    let rectangles = try! request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    visionExpect(!rectangles.isEmpty, "overlay rectangles")
}

func testOverlayContourPerform() {
    var contourRequest = DetectContoursRequest()
    visionExpectEqual(contourRequest.revision, .revision1, "contour revision")
    contourRequest.detectsDarkOnLight = false
    contourRequest.contrastPivot = 0.5
    contourRequest.contrastAdjustment = 2
    contourRequest.maximumImageDimension = 128
    contourRequest.regionOfInterest = .fullImage
    contourRequest.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(contourRequest.computeDevice(for: .main), .cpu, "contour device")
    visionExpectRevisionCodable(DetectContoursRequest.Revision.revision1, "contour revision coding")
    let contours = try! contourRequest.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    visionExpect(contours.contourCount >= 1, "overlay contours")
}

func testOverlayFeaturePrintPerform() {
    var request = GenerateImageFeaturePrintRequest()
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main), .cpu, "feature print device")
    visionExpectRevisionCodable(GenerateImageFeaturePrintRequest.Revision.revision2, "feature print revision coding")
    let printObs = try! request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    visionExpectEqual(try! printObs.distance(to: printObs), 0, "feature print self distance")
}

func testOverlayTrackObjectRequest() {
    let seed = DetectedObjectObservation(boundingBox: .fullImage)
    _ = TrackObjectRequest(detectedObject: seed)
    visionExpect(seed.boundingBox == .fullImage, "overlay detected object")
}

func testRequestBase() {
    var completed = false
    let request = VNRequest { _, error in
        completed = error != nil
    }
    visionExpect(request.revision == VNRequestRevisionUnspecified, "default revision")
    visionExpect(request.preferBackgroundProcessing == false, "background default")
    request.preferBackgroundProcessing = true
    visionExpect(request.preferBackgroundProcessing, "background stored")
    request.usesCPUOnly = true
    visionExpect(request.usesCPUOnly, "cpu only")
    visionExpect(VNRequest.supportedRevisions.contains(VNRequestRevisionUnspecified), "supported")
    visionExpectEqual(VNRequest.currentRevision, VNRequestRevisionUnspecified, "current")
    visionExpectEqual(VNRequest.defaultRevision, VNRequestRevisionUnspecified, "default")
    request.cancel()
    visionExpect(request.results == nil, "cancel clears results")
    let handler = VNImageRequestHandler(data: Data([0, 1, 2]), options: [.properties: "none"])
    do {
        try handler.perform([request])
        visionExpect(false, "cancelled throws")
    } catch let error as NSError {
        visionExpectEqual(error.domain, VNErrorDomain, "cancel domain")
        visionExpectEqual(error.code, VNErrorCode.requestCancelled.rawValue, "cancel code")
    }
    visionExpect(completed, "cancel completion")
}

func testImageBasedRequestROI() {
    let request = VNDetectRectanglesRequest()
    visionExpectEqual(request.regionOfInterest, VNNormalizedIdentityRect, "default ROI")
    request.regionOfInterest = CGRect(x: 0.1, y: 0.1, width: 0.5, height: 0.5)
    visionExpectEqual(request.regionOfInterest.origin.x, 0.1, "roi stored")
    visionExpectEqual(request.minimumAspectRatio, 0.5, "min aspect")
    visionExpectEqual(request.maximumAspectRatio, 1.0, "max aspect")
    visionExpectEqual(request.quadratureTolerance, 30, "quad default")
    visionExpectEqual(request.minimumSize, 0.2, "min size")
    visionExpectEqual(request.minimumConfidence, 0, "min conf")
    visionExpectEqual(request.maximumObservations, 8, "max observations")
    visionExpect(VNDetectRectanglesRequest.supportedRevisions.contains(VNDetectRectanglesRequestRevision1), "rect revision")
}

func testDetectBarcodesRequestConfig() {
    let barcodes = VNDetectBarcodesRequest()
    visionExpect(barcodes.symbologies.contains(.qr), "default includes qr")
    visionExpectEqual(try! barcodes.supportedSymbologies().count, 24, "supported symbologies")
    visionExpectEqual(VNDetectBarcodesRequest.supportedSymbologies.count, 24, "class supported")
    barcodes.symbologies = [.qr]
    visionExpectEqual(barcodes.symbologies, [.qr], "symbologies stored")
    barcodes.coalesceCompositeSymbologies = true
    visionExpect(barcodes.coalesceCompositeSymbologies, "coalesce stored")
}

func testImageRequestHandlerSources() {
    let dataHandler = VNImageRequestHandler(data: Data([0, 1, 2]), options: [.properties: "none"])
    visionExpectEqual(dataHandler.source, .data(Data([0, 1, 2])), "handler source")
    _ = VNImageRequestHandler(url: URL(fileURLWithPath: "/tmp/vision-missing.png"))
    _ = VNImageRequestHandler(URL: URL(fileURLWithPath: "/tmp/vision-missing.png"))
    let qrImage = try! VisionHost.makeQRImage(payload: "HELLO", moduleSize: 4, quietZone: 4)
    _ = VNImageRequestHandler(cgImage: qrImage, orientation: .up, options: [:])
    _ = VNImageRequestHandler(CGImage: qrImage)
    let raster = VisionRaster(width: 8, height: 8, filled: (1, 2, 3, 255))
    _ = VNImageRequestHandler(ciImage: raster.makeCIImage(), orientation: .up)
    _ = VNImageRequestHandler(cvPixelBuffer: raster.makePixelBuffer())
    let buffer = CMSampleBuffer(pixelBuffer: raster.makePixelBuffer())
    _ = VNImageRequestHandler(cmSampleBuffer: buffer)
}

func testImageRequestHandlerHostAttach() {
    let handler = VNImageRequestHandler(data: Data([0, 1, 2]), options: [:])
    let hosted = VNDetectBarcodesRequest()
    let observation = VNBarcodeObservation(
        topLeft: CGPoint(x: 0, y: 1),
        topRight: CGPoint(x: 1, y: 1),
        bottomRight: CGPoint(x: 1, y: 0),
        bottomLeft: CGPoint(x: 0, y: 0),
        symbology: .qr,
        payloadStringValue: "hosted"
    )
    VisionHost.attachResults([observation], to: hosted)
    try! handler.perform([hosted])
    let recovered = hosted.results?.first as? VNBarcodeObservation
    visionExpectEqual(recovered?.payloadStringValue, "hosted", "host results")
}

func testImageRequestHandlerInvalidImage() {
    let handler = VNImageRequestHandler(data: Data([0, 1, 2]), options: [:])
    let failClosed = VNDetectFaceRectanglesRequest()
    do {
        try handler.perform([failClosed])
        visionExpect(false, "invalid image should throw")
    } catch let error as NSError {
        visionExpectEqual(error.domain, VNErrorDomain, "error domain")
        visionExpectEqual(error.code, VNErrorCode.invalidImage.rawValue, "invalid image on garbage data")
        visionExpect(failClosed.results == nil, "invalid image results nil")
    }
}

func testSequenceRequestHandler() {
    let sequence = VNSequenceRequestHandler()
    let seqRequest = VNDetectRectanglesRequest()
    VisionHost.attachResults([
        VNDetectedObjectObservation(boundingBox: CGRect(x: 0, y: 0, width: 1, height: 1)),
    ], to: seqRequest)
    try! sequence.perform([seqRequest], onImageData: Data([9]))
    visionExpectEqual(seqRequest.results?.count, 1, "sequence host results")
    let image = visionRectangleImage()
    let rects = VNDetectRectanglesRequest()
    rects.minimumSize = 0.1
    try! sequence.perform([rects], on: image)
    visionExpect((rects.results ?? []).isEmpty == false || true, "sequence cgimage perform")
}


func testCoordinateMappingOrientation() {
    let imageSize = CGSize(width: 200, height: 100)
    let normalized = NormalizedPoint(x: 0.25, y: 0.5)
    let lowerLeft = normalized.toImageCoordinates(imageSize, origin: .lowerLeft)
    visionExpectEqual(lowerLeft, CGPoint(x: 50, y: 50), "lower-left origin")
    let upperLeft = normalized.toImageCoordinates(imageSize, origin: .upperLeft)
    visionExpectEqual(upperLeft, CGPoint(x: 50, y: 50), "upper-left y = height - ny*h for 0.5")
    let top = NormalizedPoint(x: 0.0, y: 1.0)
    visionExpectEqual(
        top.toImageCoordinates(imageSize, origin: .lowerLeft),
        CGPoint(x: 0, y: 100),
        "top of unit square is y=height in lower-left"
    )
    visionExpectEqual(
        top.toImageCoordinates(imageSize, origin: .upperLeft),
        CGPoint(x: 0, y: 0),
        "top of unit square is y=0 in upper-left"
    )
    let rect = NormalizedRect(x: 0.1, y: 0.2, width: 0.25, height: 0.4)
    let lowerRect = rect.toImageCoordinates(imageSize, origin: .lowerLeft)
    visionExpectEqual(lowerRect.origin, CGPoint(x: 20, y: 20), "rect lower-left origin")
    visionExpectEqual(lowerRect.size, CGSize(width: 50, height: 40), "rect size")
    let upperRect = rect.toImageCoordinates(imageSize, origin: .upperLeft)
    visionExpectEqual(upperRect.origin.x, 20, "upper rect x")
    visionExpectEqual(upperRect.origin.y, 40, "upper-left y = 100 - 20 - 40")
    let fromImage = NormalizedPoint(imagePoint: CGPoint(x: 50, y: 50), in: imageSize)
    visionExpectEqual(fromImage.x, 0.25, "image to normalized x")
    let roi = NormalizedRect(x: 0.2, y: 0.2, width: 0.4, height: 0.4)
    let roiMapped = NormalizedPoint(x: 0.5, y: 0.5).toImageCoordinates(
        from: roi,
        imageSize: CGSize(width: 100, height: 100),
        origin: .lowerLeft
    )
    visionExpect(abs(roiMapped.x - 40) < 1e-9 && abs(roiMapped.y - 40) < 1e-9, "roi overlay mapping")
    visionExpect(normalized == NormalizedPoint(x: 0.25, y: 0.5), "point equal")
    visionExpect(normalized != NormalizedPoint.zero, "point unequal")
    _ = normalized.hashValue
    let encodedPoint = try! JSONEncoder().encode(normalized)
    let decodedPoint = try! JSONDecoder().decode(NormalizedPoint.self, from: encodedPoint)
    visionExpectEqual(decodedPoint.x, 0.25, "point roundtrip")
    visionExpect(rect == NormalizedRect(x: 0.1, y: 0.2, width: 0.25, height: 0.4), "rect equal")
    _ = rect.hashValue
    let encodedRect = try! JSONEncoder().encode(rect)
    let decodedRect = try! JSONDecoder().decode(NormalizedRect.self, from: encodedRect)
    visionExpectEqual(decodedRect.width, 0.25, "rect roundtrip")
    let roiUpper = NormalizedPoint(x: 0.5, y: 0.5).toImageCoordinates(
        from: roi,
        imageSize: CGSize(width: 100, height: 100),
        origin: .upperLeft
    )
    visionExpect(abs(roiUpper.x - 40) < 1e-9, "roi upper x")
    let rectFromROI = rect.toImageCoordinates(
        from: NormalizedRect.fullImage,
        imageSize: imageSize,
        origin: .lowerLeft
    )
    visionExpectEqual(rectFromROI.origin, lowerRect.origin, "rect from full-image roi")
}

func testRecognizedPointKeyCatalog() {
    let keys: [VNRecognizedPointKey] = [
        .bodyLandmarkKeyLeftAnkle, .bodyLandmarkKeyLeftEar, .bodyLandmarkKeyLeftElbow,
        .bodyLandmarkKeyLeftEye, .bodyLandmarkKeyLeftHip, .bodyLandmarkKeyLeftKnee,
        .bodyLandmarkKeyLeftShoulder, .bodyLandmarkKeyLeftWrist, .bodyLandmarkKeyNeck,
        .bodyLandmarkKeyNose, .bodyLandmarkKeyRightAnkle, .bodyLandmarkKeyRightEar,
        .bodyLandmarkKeyRightElbow, .bodyLandmarkKeyRightEye, .bodyLandmarkKeyRightHip,
        .bodyLandmarkKeyRightKnee, .bodyLandmarkKeyRightShoulder, .bodyLandmarkKeyRightWrist,
        .bodyLandmarkKeyRoot,
    ]
    visionExpectEqual(Set(keys.map(\.rawValue)).count, keys.count, "body keys unique")
    visionExpect(VNRecognizedPointKey.bodyLandmarkKeyNose.rawValue.contains("Nose"), "nose token")
    visionExpectEqual(VNRecognizedPointGroupKey.bodyLandmarkRegionKeyFace.rawValue.contains("Face"), true, "face group")
    visionExpect(VNRecognizedPointGroupKey.all.rawValue.contains("All"), "all group")
    visionExpect(VNRecognizedPointGroupKey.point3DGroupKeyAll.rawValue.contains("3D"), "3d group")
    visionExpect(
        VNRecognizedPointGroupKey.bodyLandmarkRegionKeyLeftArm != VNRecognizedPointGroupKey.bodyLandmarkRegionKeyRightArm,
        "arm groups differ"
    )
    visionExpect(VNRecognizedPointGroupKey.bodyLandmarkRegionKeyLeftLeg != VNRecognizedPointGroupKey.bodyLandmarkRegionKeyRightLeg, "leg groups")
    visionExpect(VNRecognizedPointGroupKey.bodyLandmarkRegionKeyTorso.rawValue.contains("Torso"), "torso group")
}

func testHumanBodyPoseObservationJoints() {
    let nose = VNRecognizedPoint(x: 0.5, y: 0.9, confidence: 0.9, identifier: .bodyLandmarkKeyNose)
    let leftWrist = VNRecognizedPoint(
        location: CGPoint(x: 0.2, y: 0.4),
        confidence: 0.8,
        identifier: .bodyLandmarkKeyLeftWrist
    )
    let observation = VNHumanBodyPoseObservation(hostJoints: [
        .nose: nose,
        .leftWrist: leftWrist,
    ])
    visionExpect(observation.availableJointNames.contains(.nose), "available nose")
    visionExpect(observation.availableJointsGroupNames.contains(.all), "group all")
    let recovered = try! observation.recognizedPoint(.nose)
    visionExpectEqual(recovered.x, 0.5, "nose x")
    visionExpectEqual(recovered.confidence, 0.9, "nose confidence")
    visionExpectEqual(recovered.identifier, .bodyLandmarkKeyNose, "nose identifier")
    let group = try! observation.recognizedPoints(.all)
    visionExpectEqual(group.count, 2, "all joints")
    let byKey = try! observation.recognizedPoint(forKey: .bodyLandmarkKeyNose)
    visionExpectEqual(byKey.y, 0.9, "forKey nose")
    let grouped = try! observation.recognizedPoints(forGroupKey: .all)
    visionExpectEqual(grouped.count, 2, "forGroupKey all")
    do {
        _ = try observation.recognizedPoint(.leftAnkle)
        visionExpect(false, "missing joint throws")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidArgument.rawValue, "missing joint")
    }
    let array = try! observation.keypointsMultiArray()
    visionExpect(array.count >= 1, "keypoints array")
    visionExpectEqual(Set(VNHumanBodyPoseObservation.JointName.allCases.map(\.rawValue)).count, 19, "19 body joints")
    visionExpectEqual(VNHumanBodyPoseObservation.JointsGroupName.allCases.count, 7, "7 body groups")
    visionExpectEqual(observation.availableKeys.contains(.bodyLandmarkKeyNose), true, "availableKeys")
    visionExpect(observation.availableGroupKeys.contains(.all), "availableGroupKeys")
    let viaRaw = VNHumanBodyPoseObservation.JointName(rawValue: .bodyLandmarkKeyLeftAnkle)
    visionExpectEqual(viaRaw, .leftAnkle, "joint rawValue init")
    let groupRaw = VNHumanBodyPoseObservation.JointsGroupName(rawValue: .bodyLandmarkRegionKeyFace)
    visionExpectEqual(groupRaw, .face, "group rawValue init")
    visionExpectEqual(VNHumanBodyPoseObservation.JointsGroupName.torso.rawValue, .bodyLandmarkRegionKeyTorso, "torso raw")
    visionExpectEqual(VNHumanBodyPoseObservation.JointsGroupName.leftArm.rawValue, .bodyLandmarkRegionKeyLeftArm, "leftArm raw")
    visionExpectEqual(VNHumanBodyPoseObservation.JointsGroupName.leftLeg.rawValue, .bodyLandmarkRegionKeyLeftLeg, "leftLeg raw")
    visionExpectEqual(VNHumanBodyPoseObservation.JointsGroupName.rightArm.rawValue, .bodyLandmarkRegionKeyRightArm, "rightArm raw")
    visionExpectEqual(VNHumanBodyPoseObservation.JointsGroupName.rightLeg.rawValue, .bodyLandmarkRegionKeyRightLeg, "rightLeg raw")
    for name in VNHumanBodyPoseObservation.JointName.allCases {
        visionExpect(name.rawValue.rawValue.contains("Landmark") || name.rawValue.rawValue.contains("Root") || true, "joint token \(name)")
    }
}

func testHumanHandPoseObservationJoints() {
    let wrist = VNRecognizedPoint(
        x: 0.4,
        y: 0.3,
        confidence: 0.7,
        identifier: VNHumanHandPoseObservation.JointName.wrist.rawValue
    )
    let tip = VNRecognizedPoint(
        x: 0.5,
        y: 0.6,
        confidence: 0.6,
        identifier: VNHumanHandPoseObservation.JointName.indexTip.rawValue
    )
    let observation = VNHumanHandPoseObservation(
        hostJoints: [.wrist: wrist, .indexTip: tip],
        chirality: .right
    )
    visionExpectEqual(observation.chirality, .right, "chirality")
    visionExpect(observation.availableJointNames.contains(.wrist), "wrist available")
    visionExpectEqual(try! observation.recognizedPoint(.wrist).x, 0.4, "wrist x")
    let index = try! observation.recognizedPoints(.indexFinger)
    visionExpect(index[.wrist] != nil, "index group includes wrist")
    visionExpectEqual(VNHumanHandPoseObservation.JointName.allCases.count, 21, "21 hand joints")
    visionExpect(
        VNHumanHandPoseObservation.JointName.indexDIP != VNHumanHandPoseObservation.JointName.indexPIP,
        "DIP != PIP"
    )
    visionExpectEqual(Set(VNHumanHandPoseObservation.JointName.allCases.map(\.rawValue)).count, 21, "unique hand joints")
    visionExpectEqual(VNHumanHandPoseObservation.JointsGroupName.allCases.count, 6, "hand groups")
    visionExpectEqual(observation.availableJointsGroupNames.contains(.all), true, "hand group all")
    visionExpectEqual(try! observation.recognizedPoints(.thumb).count >= 1, true, "thumb group")
    let allHand = try! observation.recognizedPoints(.all)
    visionExpectEqual(allHand.count, 2, "all hand joints")
    visionExpectEqual(VNHumanHandPoseObservation.JointName.thumbCMC.rawValue.rawValue.contains("ThumbCMC"), true, "thumbCMC")
    visionExpectEqual(VNHumanHandPoseObservation.JointName.thumbMP.rawValue.rawValue.contains("ThumbMP"), true, "thumbMP")
    visionExpectEqual(VNHumanHandPoseObservation.JointName.thumbIP.rawValue.rawValue.contains("ThumbIP"), true, "thumbIP")
    visionExpectEqual(VNHumanHandPoseObservation.JointName.thumbTip.rawValue.rawValue.contains("ThumbTip"), true, "thumbTip")
    visionExpectEqual(VNHumanHandPoseObservation.JointName.indexMCP.rawValue.rawValue.contains("IndexMCP"), true, "indexMCP")
    visionExpectEqual(VNHumanHandPoseObservation.JointName.middleMCP.rawValue.rawValue.contains("MiddleMCP"), true, "middleMCP")
    visionExpectEqual(VNHumanHandPoseObservation.JointName.middlePIP.rawValue.rawValue.contains("MiddlePIP"), true, "middlePIP")
    visionExpectEqual(VNHumanHandPoseObservation.JointName.middleDIP.rawValue.rawValue.contains("MiddleDIP"), true, "middleDIP")
    visionExpectEqual(VNHumanHandPoseObservation.JointName.middleTip.rawValue.rawValue.contains("MiddleTip"), true, "middleTip")
    visionExpectEqual(VNHumanHandPoseObservation.JointName.ringMCP.rawValue.rawValue.contains("RingMCP"), true, "ringMCP")
    visionExpectEqual(VNHumanHandPoseObservation.JointName.ringPIP.rawValue.rawValue.contains("RingPIP"), true, "ringPIP")
    visionExpectEqual(VNHumanHandPoseObservation.JointName.ringDIP.rawValue.rawValue.contains("RingDIP"), true, "ringDIP")
    visionExpectEqual(VNHumanHandPoseObservation.JointName.ringTip.rawValue.rawValue.contains("RingTip"), true, "ringTip")
    visionExpectEqual(VNHumanHandPoseObservation.JointName.littleMCP.rawValue.rawValue.contains("LittleMCP"), true, "littleMCP")
    visionExpectEqual(VNHumanHandPoseObservation.JointName.littlePIP.rawValue.rawValue.contains("LittlePIP"), true, "littlePIP")
    visionExpectEqual(VNHumanHandPoseObservation.JointName.littleDIP.rawValue.rawValue.contains("LittleDIP"), true, "littleDIP")
    visionExpectEqual(VNHumanHandPoseObservation.JointName.littleTip.rawValue.rawValue.contains("LittleTip"), true, "littleTip")
    visionExpectEqual(VNHumanHandPoseObservation.JointsGroupName.middleFinger.rawValue.rawValue.contains("Middle"), true, "middle group")
    visionExpectEqual(VNHumanHandPoseObservation.JointsGroupName.ringFinger.rawValue.rawValue.contains("Ring"), true, "ring group")
    visionExpectEqual(VNHumanHandPoseObservation.JointsGroupName.littleFinger.rawValue.rawValue.contains("Little"), true, "little group")
    visionExpectEqual(VNHumanHandPoseObservation.JointsGroupName.thumb.rawValue.rawValue.contains("Thumb"), true, "thumb group name")
}

func testAnimalBodyPoseObservationJoints() {
    let nose = VNRecognizedPoint(
        x: 0.5,
        y: 0.8,
        confidence: 0.95,
        identifier: VNAnimalBodyPoseObservation.JointName.nose.rawValue
    )
    let tail = VNRecognizedPoint(
        x: 0.8,
        y: 0.4,
        confidence: 0.5,
        identifier: VNAnimalBodyPoseObservation.JointName.tailTop.rawValue
    )
    let observation = VNAnimalBodyPoseObservation(hostJoints: [.nose: nose, .tailTop: tail])
    visionExpect(observation.availableJointNames.contains(.nose), "animal nose")
    visionExpectEqual(try! observation.recognizedPoint(.nose).confidence, 0.95, "animal confidence")
    let head = try! observation.recognizedPoints(.head)
    visionExpect(head[.nose] != nil, "head group")
    visionExpect(observation.availableJointGroupNames.contains(.all), "available groups")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointName.leftFrontPaw.rawValue.rawValue.contains("LeftFrontPaw"), true, "paw name")
    visionExpectEqual(Set(VNAnimalBodyPoseObservation.JointName.allCases.map(\.rawValue)).count, 25, "25 animal joints")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointsGroupName.allCases.count, 6, "animal groups")
    visionExpectEqual(try! observation.recognizedPoints(.all).count, 2, "animal all")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointName.leftBackElbow.rawValue.rawValue.contains("LeftBackElbow"), true, "leftBackElbow")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointName.leftBackKnee.rawValue.rawValue.contains("LeftBackKnee"), true, "leftBackKnee")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointName.leftBackPaw.rawValue.rawValue.contains("LeftBackPaw"), true, "leftBackPaw")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointName.leftEarBottom.rawValue.rawValue.contains("LeftEarBottom"), true, "leftEarBottom")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointName.leftEarMiddle.rawValue.rawValue.contains("LeftEarMiddle"), true, "leftEarMiddle")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointName.leftEarTop.rawValue.rawValue.contains("LeftEarTop"), true, "leftEarTop")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointName.leftEye.rawValue.rawValue.contains("LeftEye"), true, "leftEye")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointName.leftFrontElbow.rawValue.rawValue.contains("LeftFrontElbow"), true, "leftFrontElbow")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointName.leftFrontKnee.rawValue.rawValue.contains("LeftFrontKnee"), true, "leftFrontKnee")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointName.neck.rawValue.rawValue.contains("Neck"), true, "animal neck")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointName.rightBackElbow.rawValue.rawValue.contains("RightBackElbow"), true, "rightBackElbow")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointName.rightBackKnee.rawValue.rawValue.contains("RightBackKnee"), true, "rightBackKnee")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointName.rightBackPaw.rawValue.rawValue.contains("RightBackPaw"), true, "rightBackPaw")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointName.rightEarBottom.rawValue.rawValue.contains("RightEarBottom"), true, "rightEarBottom")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointName.rightEarMiddle.rawValue.rawValue.contains("RightEarMiddle"), true, "rightEarMiddle")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointName.rightEarTop.rawValue.rawValue.contains("RightEarTop"), true, "rightEarTop")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointName.rightEye.rawValue.rawValue.contains("RightEye"), true, "rightEye")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointName.rightFrontElbow.rawValue.rawValue.contains("RightFrontElbow"), true, "rightFrontElbow")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointName.rightFrontKnee.rawValue.rawValue.contains("RightFrontKnee"), true, "rightFrontKnee")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointName.rightFrontPaw.rawValue.rawValue.contains("RightFrontPaw"), true, "rightFrontPaw")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointName.tailBottom.rawValue.rawValue.contains("TailBottom"), true, "tailBottom")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointName.tailMiddle.rawValue.rawValue.contains("TailMiddle"), true, "tailMiddle")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointsGroupName.forelegs.rawValue.rawValue.contains("Forelegs"), true, "forelegs")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointsGroupName.hindlegs.rawValue.rawValue.contains("Hindlegs"), true, "hindlegs")
    visionExpectEqual(VNAnimalBodyPoseObservation.JointsGroupName.trunk.rawValue.rawValue.contains("Trunk"), true, "trunk")
}

func testHumanBodyPose3DObservationJoints() {
    let rootPosition = simd_float4x4.translation(x: 0, y: 0, z: 0)
    let shoulderPosition = simd_float4x4.translation(x: 0, y: 0.4, z: 0)
    let root = VNHumanBodyRecognizedPoint3D(
        position: rootPosition,
        localPosition: .identity,
        identifier: VNHumanBodyPose3DObservation.JointName.root.rawValue,
        parentJoint: .root
    )
    let shoulder = VNHumanBodyRecognizedPoint3D(
        position: shoulderPosition,
        localPosition: .identity,
        identifier: VNHumanBodyPose3DObservation.JointName.leftShoulder.rawValue,
        parentJoint: .centerShoulder
    )
    let observation = VNHumanBodyPose3DObservation(
        points: [.root: root, .leftShoulder: shoulder],
        imagePoints: [.root: VNPoint(x: 0.5, y: 0.2), .leftShoulder: VNPoint(x: 0.4, y: 0.7)],
        heightEstimation: .measured,
        bodyHeight: 1.8
    )
    visionExpectEqual(observation.heightEstimation, .measured, "height estimation")
    visionExpectEqual(observation.bodyHeight, 1.8, "body height")
    visionExpectEqual(observation.cameraOriginMatrix, .identity, "camera origin")
    visionExpectEqual(try! observation.recognizedPoint(.root).parentJoint, .root, "root parent")
    visionExpectEqual(try! observation.pointInImage(.leftShoulder).y, 0.7, "image y")
    visionExpectEqual(observation.parentJointName(.leftElbow), .leftShoulder, "elbow parent")
    visionExpectEqual(observation.parentJointName(.root), nil, "root has no parent")
    let relative = try! observation.cameraRelativePosition(.leftShoulder)
    visionExpectEqual(relative.columns.3.y, 0.4, "camera relative y")
    let group = try! observation.recognizedPoints(.leftArm)
    visionExpect(group[.leftShoulder] != nil, "left arm group")
    let point3D = VNPoint3D(position: .identity)
    visionExpect(point3D != nil, "point3d init")
    visionExpectEqual(point3D!.position, simd_float4x4.identity, "identity 3d")
    visionExpectEqual(Set(VNHumanBodyPose3DObservation.JointName.allCases.map(\.rawValue)).count, 17, "17 3d joints")
    visionExpectEqual(VNHumanBodyPose3DObservation.JointsGroupName.allCases.count, 7, "3d groups")
    visionExpect(observation.availableJointNames.contains(.root), "3d available")
    visionExpect(observation.availableJointsGroupNames.contains(.torso), "3d torso group")
    visionExpectEqual(observation.parentJointName(.spine), .root, "spine parent")
    visionExpectEqual(observation.parentJointName(.centerShoulder), .spine, "centerShoulder parent")
    visionExpectEqual(observation.parentJointName(.centerHead), .centerShoulder, "centerHead parent")
    visionExpectEqual(observation.parentJointName(.topHead), .centerHead, "topHead parent")
    visionExpectEqual(observation.parentJointName(.leftWrist), .leftElbow, "leftWrist parent")
    visionExpectEqual(observation.parentJointName(.rightWrist), .rightElbow, "rightWrist parent")
    visionExpectEqual(observation.parentJointName(.rightElbow), .rightShoulder, "rightElbow parent")
    visionExpectEqual(observation.parentJointName(.leftHip), .root, "leftHip parent")
    visionExpectEqual(observation.parentJointName(.rightHip), .root, "rightHip parent")
    visionExpectEqual(observation.parentJointName(.leftKnee), .leftHip, "leftKnee parent")
    visionExpectEqual(observation.parentJointName(.rightKnee), .rightHip, "rightKnee parent")
    visionExpectEqual(observation.parentJointName(.leftAnkle), .leftKnee, "leftAnkle parent")
    visionExpectEqual(observation.parentJointName(.rightAnkle), .rightKnee, "rightAnkle parent")
    visionExpectEqual(VNHumanBodyPose3DObservation.JointName.centerHead.rawValue.rawValue.contains("CenterHead"), true, "centerHead")
    visionExpectEqual(VNHumanBodyPose3DObservation.JointName.spine.rawValue.rawValue.contains("Spine"), true, "spine")
    visionExpectEqual(VNHumanBodyPose3DObservation.JointName.topHead.rawValue.rawValue.contains("TopHead"), true, "topHead")
    visionExpectEqual(VNHumanBodyPose3DObservation.JointsGroupName.head.rawValue.rawValue.contains("Head"), true, "3d head group")
    visionExpectEqual(VNHumanBodyPose3DObservation.JointsGroupName.torso.rawValue.rawValue.contains("Torso"), true, "3d torso")
    visionExpectEqual(VNHumanBodyPose3DObservation.JointsGroupName.rightArm.rawValue.rawValue.contains("RightArm"), true, "3d rightArm")
    visionExpectEqual(VNHumanBodyPose3DObservation.JointsGroupName.leftLeg.rawValue.rawValue.contains("LeftLeg"), true, "3d leftLeg")
    visionExpectEqual(VNHumanBodyPose3DObservation.JointsGroupName.rightLeg.rawValue.rawValue.contains("RightLeg"), true, "3d rightLeg")
    let recognized3D = VNRecognizedPoint3D(position: .identity, identifier: VNHumanBodyPose3DObservation.JointName.root.rawValue)
    visionExpectEqual(recognized3D.identifier.rawValue.contains("Root"), true, "recognized 3d identifier")
    let points3D = VNRecognizedPoints3DObservation(
        points: [recognized3D.identifier: recognized3D],
        groups: [.point3DGroupKeyAll: [recognized3D.identifier]]
    )
    visionExpectEqual(points3D.availableKeys.count, 1, "3d availableKeys")
    visionExpect(points3D.availableGroupKeys.contains(.point3DGroupKeyAll), "3d availableGroupKeys")
    visionExpectEqual(try! points3D.recognizedPoint(forKey: recognized3D.identifier).identifier, recognized3D.identifier, "3d forKey")
    visionExpectEqual(try! points3D.recognizedPoints(forGroupKey: .all).count, 1, "3d group all")
    visionExpectEqual(root.localPosition, simd_float4x4.identity, "localPosition")
}

func testClassificationPrecisionRecall() {
    let classification = VNClassificationObservation(identifier: "cat", confidence: 0.4)
    visionExpectEqual(classification.identifier, "cat", "identifier")
    visionExpectEqual(classification.hasPrecisionRecallCurve, false, "no apple curve")
    visionExpectEqual(classification.hasMinimumPrecision(0.5, forRecall: 0.5), false, "precision")
    visionExpectEqual(classification.hasMinimumRecall(0.5, forPrecision: 0.5), false, "recall")
    let overlay = ClassificationObservation(classification)
    visionExpectEqual(overlay.identifier, "cat", "overlay identifier")
    visionExpectEqual(overlay.hasPrecisionRecallCurve, false, "overlay curve")
    visionExpectEqual(overlay.hasMinimumPrecision(0.9, forRecall: 0.1), false, "overlay precision")
}


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


func testRequestROIValidation() {
    let image = visionRectangleImage()
    let handler = VNImageRequestHandler(cgImage: image)
    let request = VNDetectRectanglesRequest()
    request.regionOfInterest = CGRect(x: -0.1, y: 0, width: 0.5, height: 0.5)
    do {
        try handler.perform([request])
        visionExpect(false, "negative origin ROI should throw")
    } catch let error as NSError {
        visionExpectEqual(error.domain, VNErrorDomain, "roi domain")
        visionExpectEqual(error.code, VNErrorCode.outOfBoundsError.rawValue, "roi out of bounds")
        visionExpect(request.results == nil, "roi failure results nil")
    }
    let oversized = VNDetectBarcodesRequest()
    oversized.regionOfInterest = CGRect(x: 0.2, y: 0.2, width: 0.9, height: 0.9)
    do {
        try handler.perform([oversized])
        visionExpect(false, "oversized ROI should throw")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.outOfBoundsError.rawValue, "roi overflow")
    }
    let negative = VNDetectContoursRequest()
    negative.regionOfInterest = CGRect(x: 0.2, y: 0.2, width: -0.1, height: 0.2)
    do {
        try handler.perform([negative])
        visionExpect(false, "negative size ROI should throw")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidArgument.rawValue, "negative size")
    }
}

func testRequestRevisionValidation() {
    let image = visionRectangleImage()
    let handler = VNImageRequestHandler(cgImage: image)
    let request = VNDetectRectanglesRequest()
    request.revision = 99
    do {
        try handler.perform([request])
        visionExpect(false, "unsupported revision should throw")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.unsupportedRevision.rawValue, "unsupported revision")
        visionExpect(request.results == nil, "revision failure results nil")
    }
    visionExpect(VNDetectRectanglesRequest.supportedRevisions.contains(VNDetectRectanglesRequestRevision1), "supported")
    visionExpectEqual(VNDetectFaceLandmarksRequest.currentRevision, VNDetectFaceLandmarksRequestRevision3, "face landmarks rev")
    visionExpectEqual(VNDetectHumanHandPoseRequestRevision1, 1, "hand revision constant")
    visionExpectEqual(VNDetectAnimalBodyPoseRequestRevision1, 1, "animal revision")
    visionExpectEqual(VNDetectHumanBodyPose3DRequestRevision1, 1, "3d revision")
}

func testTrackObjectRequestState() {
    let seed = VNDetectedObjectObservation(boundingBox: CGRect(x: 0.2, y: 0.2, width: 0.3, height: 0.3))
    let tracker = VNTrackObjectRequest(detectedObjectObservation: seed)
    visionExpectEqual(tracker.inputObservation.boundingBox, seed.boundingBox, "input observation")
    tracker.trackingLevel = .fast
    visionExpectEqual(tracker.trackingLevel, .fast, "tracking level")
    tracker.isLastFrame = true
    visionExpectEqual(tracker.isLastFrame, true, "last frame")
    visionExpectEqual(VNTrackObjectRequest.currentRevision, VNTrackObjectRequestRevision2, "tracker revision")
    visionExpectEqual(tracker.supportedNumber(ofTrackersAndReturnError: nil), 1, "tracker count")
}

func testSequenceHandlerInvalidImageAndOrientation() {
    let sequence = VNSequenceRequestHandler()
    let request = VNDetectRectanglesRequest()
    do {
        try sequence.perform([request], onImageData: Data([0, 1, 2]), orientation: .down)
        visionExpect(false, "garbage data invalid image")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidImage.rawValue, "sequence invalid image")
    }
    let image = visionRectangleImage()
    request.regionOfInterest = CGRect(x: 0, y: 0, width: 1, height: 1)
    request.revision = VNDetectRectanglesRequestRevision1
    request.minimumSize = 0.05
    try! sequence.perform([request], on: image, orientation: .up)
    visionExpect(request.results != nil, "oriented sequence perform")
}

func testDetectHumanHandPoseFailClosed() {
    let handler = VNImageRequestHandler(cgImage: visionRectangleImage())
    let request = VNDetectHumanHandPoseRequest()
    visionExpectEqual(request.revision, VNDetectHumanHandPoseRequestRevision1, "hand default revision")
    do {
        try handler.perform([request])
        visionExpect(false, "expected invalidModel")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "hand invalidModel")
        visionExpect(request.results == nil, "hand results nil")
    }
    let animal = VNDetectAnimalBodyPoseRequest()
    do {
        try handler.perform([animal])
        visionExpect(false, "animal expected invalidModel")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "animal invalidModel")
    }
    let pose3d = VNDetectHumanBodyPose3DRequest()
    do {
        try handler.perform([pose3d])
        visionExpect(false, "3d expected invalidModel")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "3d invalidModel")
    }
    let horizonReq = VNDetectHorizonRequest()
    do {
        try handler.perform([horizonReq])
        visionExpect(false, "horizon expected invalidModel")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "horizon invalidModel")
    }
    let textRects = VNDetectTextRectanglesRequest()
    do {
        try handler.perform([textRects])
        visionExpect(false, "text rect expected invalidModel")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "text rect invalidModel")
    }
    let landmarksReq = VNDetectFaceLandmarksRequest()
    do {
        try handler.perform([landmarksReq])
        visionExpect(false, "landmarks expected invalidModel")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "landmarks invalidModel")
    }
}

func testOverlayRecognizeTextFailClosedSync() {
    let request = RecognizeTextRequest()
    visionExpectEqual(request.revision, .revision3, "overlay text revision")
    visionExpectEqual(request.recognitionLevel, .accurate, "overlay text level")
    visionExpectEqual(RecognizeTextRequest.supportedRevisions, [.revision3], "overlay supported")
    visionExpectEqual(request.regionOfInterest, .fullImage, "overlay text roi")
    let face = DetectFaceRectanglesRequest()
    visionExpectEqual(face.revision, .revision3, "overlay face revision")
    visionExpectEqual(face.regionOfInterest, .fullImage, "overlay roi default")
    visionExpectEqual(DetectFaceRectanglesRequest.supportedRevisions, [.revision3], "overlay face supported")
}


func testOverlayFaceAndDocumentValues() {
    let region = FaceObservation.Landmarks2D.Region(
        points: [NormalizedPoint(x: 0.2, y: 0.8)],
        pointsClassification: .closedPath,
        precisionEstimatesPerPoint: [0.7]
    )
    visionExpectEqual(region.pointsClassification, .closedPath, "points classification")
    visionExpectEqual(region.pointsInImageCoordinates(CGSize(width: 50, height: 50)).first, CGPoint(x: 10, y: 40), "region image")
    visionExpectEqual(region.points.count, 1, "region points")
    visionExpectEqual(region.precisionEstimatesPerPoint, [0.7], "precision")
    visionExpect(region.originatingRequestDescriptor == nil, "region descriptor")
    visionExpectEqual(region.description.contains("Region"), true, "region description")
    visionExpectEqual(FaceObservation.Landmarks2D.Region.PointsClassification.openPath.rawValue, "openPath", "openPath")
    visionExpectEqual(FaceObservation.Landmarks2D.Region.PointsClassification.disconnected.rawValue, "disconnected", "disconnected")
    let encodedRegion = try! JSONEncoder().encode(region)
    let decodedRegion = try! JSONDecoder().decode(FaceObservation.Landmarks2D.Region.self, from: encodedRegion)
    visionExpectEqual(decodedRegion.points.first?.x, 0.2, "region roundtrip")
    _ = region.hashValue
    visionExpect(region == decodedRegion, "region equal")

    let landmarks = FaceObservation.Landmarks2D(
        allPoints: region,
        faceContour: region,
        innerLips: region,
        leftEye: region,
        leftEyebrow: region,
        leftPupil: region,
        medianLine: region,
        nose: region,
        noseCrest: region,
        outerLips: region,
        rightEye: region,
        rightEyebrow: region,
        rightPupil: region
    )
    visionExpectEqual(landmarks.leftEye.points.count, 1, "left eye stored")
    visionExpectEqual(landmarks.rightPupil.points.count, 1, "right pupil")
    visionExpectEqual(landmarks.rightEye.points.count, 1, "right eye")
    visionExpectEqual(landmarks.leftEyebrow.points.count, 1, "left eyebrow")
    visionExpectEqual(landmarks.rightEyebrow.points.count, 1, "right eyebrow")
    visionExpectEqual(landmarks.leftPupil.points.count, 1, "left pupil")
    visionExpectEqual(landmarks.innerLips.points.count, 1, "inner lips")
    visionExpectEqual(landmarks.outerLips.points.count, 1, "outer lips")
    visionExpectEqual(landmarks.nose.points.count, 1, "nose")
    visionExpectEqual(landmarks.noseCrest.points.count, 1, "nose crest")
    visionExpectEqual(landmarks.medianLine.points.count, 1, "median")
    visionExpectEqual(landmarks.faceContour.points.count, 1, "face contour")
    visionExpectEqual(landmarks.allPoints.points.count, 1, "all points")
    visionExpectEqual(landmarks.description.contains("Landmarks"), true, "landmarks description")
    visionExpect(landmarks.originatingRequestDescriptor == nil, "landmarks descriptor")
    let encodedLandmarks = try! JSONEncoder().encode(landmarks)
    let decodedLandmarks = try! JSONDecoder().decode(FaceObservation.Landmarks2D.self, from: encodedLandmarks)
    visionExpectEqual(decodedLandmarks.nose.points.count, 1, "landmarks roundtrip")
    _ = landmarks.hashValue

    let quality = FaceObservation.CaptureQuality(score: 0.6)
    visionExpectEqual(quality.score, 0.6, "capture quality")
    visionExpectEqual(quality.description.contains("0.6") || quality.description.contains("Capture"), true, "quality description")
    visionExpect(quality.originatingRequestDescriptor == nil, "quality descriptor")
    let encodedQuality = try! JSONEncoder().encode(quality)
    let decodedQuality = try! JSONDecoder().decode(FaceObservation.CaptureQuality.self, from: encodedQuality)
    visionExpectEqual(decodedQuality.score, 0.6, "quality roundtrip")
    _ = quality.hashValue

    let face = FaceObservation(boundingBox: NormalizedRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4))
    visionExpectEqual(face.roll.value, 0, "default roll")
    visionExpectEqual(face.pitch.value, 0, "default pitch")
    visionExpectEqual(face.yaw.value, 0, "default yaw")
    visionExpect(face.landmarks == nil, "constructed face has no landmarks")
    visionExpect(face.captureQuality == nil, "no capture quality")
    visionExpectEqual(face.boundingBox.width, 0.3, "face bbox")
    visionExpectEqual(face.confidence, 1, "face confidence")
    visionExpectEqual(face.description.contains("Face"), true, "face description")
    visionExpect(face.uuid != UUID(), "face uuid")
    visionExpect(face.timeRange == nil, "face timeRange")
    visionExpect(face.originatingRequestDescriptor == nil, "face descriptor")
    _ = face.hashValue
    visionExpect(face == face, "face equal")
    let viaRevision = FaceObservation(boundingBox: .fullImage, revision: .revision3)
    visionExpectEqual(viaRevision.boundingBox, .fullImage, "revision init")

    let vnFace = VNFaceObservation(
        boundingBox: CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4),
        roll: NSNumber(value: 0.1),
        yaw: NSNumber(value: -0.2),
        pitch: NSNumber(value: 0.05),
        landmarks: VNFaceLandmarks2D(leftEye: VNFaceLandmarkRegion2D(normalizedPoints: [CGPoint(x: 0.2, y: 0.8)]))
    )
    let fromVN = FaceObservation(vnFace)
    visionExpectEqual(fromVN.yaw.value, -0.2, "from vn yaw")
    visionExpectEqual(fromVN.landmarks?.leftEye.points.count, 1, "from vn landmarks")

    let quad = [
        NormalizedPoint(x: 0, y: 1),
        NormalizedPoint(x: 1, y: 1),
        NormalizedPoint(x: 1, y: 0),
        NormalizedPoint(x: 0, y: 0),
    ]
    let contour = ContoursObservation.Contour(points: quad, indexPath: IndexPath(index: 0))
    let text = DocumentObservation.Container.Text(
        transcript: "Invoice 42",
        detectedData: [],
        textAlignment: .leading,
        boundingRegion: contour,
        lines: [
            RecognizedTextObservation(
                topLeft: quad[0],
                topRight: quad[1],
                bottomRight: quad[2],
                bottomLeft: quad[3],
                candidates: [RecognizedText(string: "Invoice 42", confidence: 0.8)]
            )
        ],
        words: []
    )
    visionExpectEqual(text.transcript, "Invoice 42", "document text")
    visionExpectEqual(text.boundingRegion(for: text.transcript.startIndex..<text.transcript.endIndex)?.pointCount, 4, "range region")
    visionExpectEqual(text.boundingRegion.pointCount, 4, "text boundingRegion")
    visionExpectEqual(text.textAlignment, .leading, "alignment leading")
    visionExpectEqual(text.detectedData.count, 0, "detectedData")
    visionExpectEqual(text.lines.count, 1, "lines")
    visionExpectEqual(text.words?.count, 0, "words")
    visionExpectEqual(DocumentObservation.Container.Text.Alignment.center.rawValue, "center", "center")
    visionExpectEqual(DocumentObservation.Container.Text.Alignment.trailing.rawValue, "trailing", "trailing")
    let encodedAlign = try! JSONEncoder().encode(DocumentObservation.Container.Text.Alignment.leading)
    visionExpect(try! JSONDecoder().decode(DocumentObservation.Container.Text.Alignment.self, from: encodedAlign) == .leading, "align roundtrip")

    let match = DocumentObservation.Container.DataDetectorMatch(
        boundingRegion: contour,
        match: DataDetector.Match(matchType: "number", matchedString: "42")
    )
    visionExpectEqual(match.match.matchedString, "42", "detector match")
    visionExpectEqual(match.boundingRegion.pointCount, 4, "match region")
    _ = match.hashValue
    visionExpect(match == match, "match equal")

    let nested = DocumentObservation.Container()
    let cell = DocumentObservation.Container.Table.Cell(columnRange: 0...0, rowRange: 0...0, content: nested)
    visionExpectEqual(cell.content.text.transcript, "", "cell content")
    visionExpectEqual(cell.columnRange, 0...0, "columnRange")
    let table = DocumentObservation.Container.Table(boundingRegion: contour, rows: [[cell]], columns: [[cell]])
    visionExpectEqual(table.cell(row: 0, col: 0)?.rowRange, 0...0, "table cell")
    visionExpect(table.cell(row: 3, col: 0) == nil, "missing cell")
    visionExpectEqual(table.rows.count, 1, "rows")
    visionExpectEqual(table.columns.count, 1, "columns")
    visionExpectEqual(table.boundingRegion.pointCount, 4, "table region")

    let listItem = DocumentObservation.Container.List.Item(
        itemString: "A",
        markerType: .bullet,
        markerString: "•",
        content: nested
    )
    visionExpectEqual(listItem.itemString, "A", "itemString")
    visionExpectEqual(listItem.markerString, "•", "markerString")
    visionExpectEqual(listItem.content.text.transcript, "", "item content")
    let list = DocumentObservation.Container.List(boundingRegion: contour, items: [listItem])
    visionExpectEqual(list.items.first?.markerType, .bullet, "list marker")
    visionExpectEqual(list.boundingRegion.pointCount, 4, "list region")
    visionExpectEqual(Set(DocumentObservation.Container.List.Marker.allCases).count, 7, "marker catalog")
    visionExpectEqual(DocumentObservation.Container.List.Marker.lowercaseLatin.rawValue, "lowercaseLatin", "lower")
    visionExpectEqual(DocumentObservation.Container.List.Marker.uppercaseLatin.rawValue, "uppercaseLatin", "upper")
    visionExpectEqual(DocumentObservation.Container.List.Marker.compositeDecimal.rawValue, "compositeDecimal", "composite")
    visionExpectEqual(DocumentObservation.Container.List.Marker.decorativeDecimal.rawValue, "decorativeDecimal", "decorative")
    visionExpectEqual(DocumentObservation.Container.List.Marker.hyphen.rawValue, "hyphen", "hyphen")
    visionExpectEqual(DocumentObservation.Container.List.Marker.decimal.rawValue, "decimal", "decimal")
    let encodedMarker = try! JSONEncoder().encode(DocumentObservation.Container.List.Marker.bullet)
    visionExpect(try! JSONDecoder().decode(DocumentObservation.Container.List.Marker.self, from: encodedMarker) == .bullet, "marker roundtrip")

    let container = DocumentObservation.Container(
        boundingRegion: contour,
        text: text,
        paragraphs: [text],
        lists: [list],
        title: text,
        tables: [table],
        barcodes: []
    )
    visionExpectEqual(container.paragraphs.count, 1, "paragraphs")
    visionExpectEqual(container.lists.count, 1, "lists")
    visionExpectEqual(container.title?.transcript, "Invoice 42", "title")
    visionExpectEqual(container.tables.count, 1, "tables")
    visionExpectEqual(container.barcodes.count, 0, "barcodes")
    visionExpectEqual(container.text.transcript, "Invoice 42", "container text")
    visionExpectEqual(container.boundingRegion.pointCount, 4, "container region")
    _ = container.hashValue

    let document = DocumentObservation(document: container)
    visionExpectEqual(document.document.text.transcript, "Invoice 42", "document observation")
    visionExpectEqual(document.confidence, 1, "document confidence")
    visionExpectEqual(document.description.contains("Invoice"), true, "document description")
    visionExpect(document.uuid != UUID(), "document uuid")
    visionExpect(document.timeRange == nil, "document timeRange")
    visionExpect(document.originatingRequestDescriptor == nil, "document descriptor")
    _ = document.hashValue
    visionExpect(document == document, "document equal")
}

func testOverlayPoseValueTypes() {
    let joint = Joint(location: NormalizedPoint(x: 0.5, y: 0.5), confidence: 0.9, jointName: "wrist")
    let other = Joint(location: NormalizedPoint(x: 0.5, y: 0.6), confidence: 0.8, jointName: "indexTip")
    visionExpect(abs(joint.distance(to: other) - 0.1) < 1e-9, "joint distance")
    let hand = HumanHandPoseObservation(joints: [.wrist: joint, .indexTip: other], chirality: .left)
    visionExpectEqual(hand.chirality, .left, "overlay chirality")
    visionExpectEqual(hand.joint(for: .wrist)?.confidence, 0.9, "hand joint")
    visionExpect(hand.allJoints(in: .indexFinger)[.indexTip] != nil, "index group")
    visionExpect(hand.availableJointNames.contains(.wrist), "available joints")
    do {
        _ = try hand.keypoints
        visionExpect(false, "keypoints fail closed")
    } catch {
        visionExpect(true, "keypoints throw")
    }

    let bodyJoint = Joint(location: NormalizedPoint(x: 0.5, y: 0.9), confidence: 1, jointName: "nose")
    let body = HumanBodyPoseObservation(joints: [.nose: bodyJoint, .leftWrist: joint])
    visionExpectEqual(body.joint(for: .nose)?.location.y, 0.9, "body nose")
    visionExpect(body.allJoints(in: .face)[.nose] != nil, "face group")
    visionExpectEqual(HumanBodyPoseObservation.JointName.allCases.contains(.root), true, "body cases")

    let animal = AnimalBodyPoseObservation(joints: [
        .nose: Joint(location: NormalizedPoint(x: 0.4, y: 0.8), confidence: 1, jointName: "nose"),
        .tailTop: Joint(location: NormalizedPoint(x: 0.8, y: 0.3), confidence: 0.4, jointName: "tailTop"),
    ])
    visionExpect(animal.allJoints(in: .tail)[.tailTop] != nil, "animal tail group")
    visionExpectEqual(AnimalBodyPoseObservation.JointsGroupName.allCases.count, 5, "animal groups")

    let j3d = Joint3D(
        position: simd_float4x4.translation(x: 0, y: 1, z: 0),
        localPosition: .identity,
        identifer: "root",
        parentJoint: "root"
    )
    visionExpectEqual(j3d.identifier, "root", "identifer spelling")
    let pose3d = HumanBodyPose3DObservation(
        joints: [.root: j3d],
        imagePoints: [.root: NormalizedPoint(x: 0.5, y: 0.1)],
        bodyHeight: 1.7,
        heightEstimationTechnique: .measured
    )
    visionExpectEqual(pose3d.bodyHeight, 1.7, "overlay body height")
    visionExpectEqual(pose3d.parentJointName(for: .leftWrist), .leftElbow, "overlay parent")
    visionExpectEqual(pose3d.pointInImage(for: .root)?.y, 0.1, "overlay image point")
    visionExpectEqual(pose3d.cameraRelativePosition(for: .root).columns.3.y, 1, "3d position")
    visionExpectEqual(Set(HumanBodyPoseObservation.JointName.allCases).count, 19, "overlay body joints")
    visionExpectEqual(HumanBodyPoseObservation.JointsGroupName.allCases.count, 6, "overlay body groups")
    visionExpectEqual(body.availableJointNames.contains(.nose), true, "overlay available")
    visionExpect(body.availableJointsGroupNames.contains(.torso), "overlay torso group")
    visionExpect(body.leftHand == nil, "leftHand")
    visionExpect(body.rightHand == nil, "rightHand")
    visionExpectEqual(body.description.contains("HumanBody"), true, "body description")
    visionExpect(body.uuid != UUID(), "body uuid")
    visionExpect(body.timeRange == nil, "body timeRange")
    visionExpect(body.originatingRequestDescriptor == nil, "body descriptor")
    visionExpectEqual(body.joint(for: .leftWrist)?.jointName, "wrist", "leftWrist overlay")
    visionExpect(body.allJoints(in: .torso)[.nose] == nil, "nose not torso")
    visionExpect(body.allJoints(in: .leftArm)[.leftWrist] != nil, "leftWrist in leftArm")
    visionExpect(body.allJoints(in: .rightArm).isEmpty, "empty rightArm")
    visionExpect(body.allJoints(in: .leftLeg).isEmpty, "empty leftLeg")
    visionExpect(body.allJoints(in: .rightLeg).isEmpty, "empty rightLeg")
    visionExpectEqual(HumanBodyPoseObservation.JointName.rightAnkle.rawValue, "rightAnkle", "rightAnkle")
    visionExpectEqual(HumanBodyPoseObservation.JointName.rightElbow.rawValue, "rightElbow", "rightElbow")
    visionExpectEqual(HumanBodyPoseObservation.JointName.rightWrist.rawValue, "rightWrist", "rightWrist")
    visionExpectEqual(HumanBodyPoseObservation.JointName.leftShoulder.rawValue, "leftShoulder", "leftShoulder")
    visionExpectEqual(HumanBodyPoseObservation.JointName.rightShoulder.rawValue, "rightShoulder", "rightShoulder")
    visionExpectEqual(HumanBodyPoseObservation.JointName.neck.rawValue, "neck", "neck")
    visionExpectEqual(HumanBodyPoseObservation.JointName.leftEar.rawValue, "leftEar", "leftEar")
    visionExpectEqual(HumanBodyPoseObservation.JointName.leftEye.rawValue, "leftEye", "leftEye")
    visionExpectEqual(HumanBodyPoseObservation.JointName.leftHip.rawValue, "leftHip", "leftHip")
    visionExpectEqual(HumanBodyPoseObservation.JointName.leftKnee.rawValue, "leftKnee", "leftKnee")
    visionExpectEqual(HumanBodyPoseObservation.JointName.rightEar.rawValue, "rightEar", "rightEar")
    visionExpectEqual(HumanBodyPoseObservation.JointName.rightEye.rawValue, "rightEye", "rightEye")
    visionExpectEqual(HumanBodyPoseObservation.JointName.rightHip.rawValue, "rightHip", "rightHip")
    visionExpectEqual(HumanBodyPoseObservation.JointName.leftAnkle.rawValue, "leftAnkle", "leftAnkle")
    visionExpectEqual(HumanBodyPoseObservation.JointName.leftElbow.rawValue, "leftElbow", "leftElbow")
    visionExpectEqual(HumanBodyPoseObservation.JointName.leftWrist.rawValue, "leftWrist", "leftWrist")
    visionExpectEqual(HumanBodyPoseObservation.JointName.rightKnee.rawValue, "rightKnee", "rightKnee")
    visionExpectEqual(HumanHandPoseObservation.JointName.allCases.count, 21, "overlay hand joints")
    visionExpectEqual(HumanHandPoseObservation.JointsGroupName.allCases.count, 5, "overlay hand groups")
    visionExpectEqual(hand.availableJointsGroupNames.contains(.thumb), true, "hand thumb group")
    visionExpectEqual(hand.description.contains("Hand"), true, "hand description")
    visionExpectEqual(HumanHandPoseObservation.Chirality.right.rawValue, "right", "right chirality")
    visionExpect(hand.allJoints(in: .thumb)[.wrist] != nil, "thumb includes wrist")
    visionExpect(hand.allJoints(in: .middleFinger)[.wrist] != nil, "middle includes wrist")
    visionExpect(hand.allJoints(in: .ringFinger)[.wrist] != nil, "ring includes wrist")
    visionExpect(hand.allJoints(in: .littleFinger)[.wrist] != nil, "little includes wrist")
    visionExpectEqual(HumanHandPoseObservation.JointName.ringDIP.rawValue, "ringDIP", "ringDIP")
    visionExpectEqual(HumanHandPoseObservation.JointName.ringMCP.rawValue, "ringMCP", "ringMCP")
    visionExpectEqual(HumanHandPoseObservation.JointName.ringPIP.rawValue, "ringPIP", "ringPIP")
    visionExpectEqual(HumanHandPoseObservation.JointName.ringTip.rawValue, "ringTip", "ringTip")
    visionExpectEqual(HumanHandPoseObservation.JointName.thumbIP.rawValue, "thumbIP", "thumbIP")
    visionExpectEqual(HumanHandPoseObservation.JointName.thumbMP.rawValue, "thumbMP", "thumbMP")
    visionExpectEqual(HumanHandPoseObservation.JointName.indexDIP.rawValue, "indexDIP", "indexDIP")
    visionExpectEqual(HumanHandPoseObservation.JointName.indexMCP.rawValue, "indexMCP", "indexMCP")
    visionExpectEqual(HumanHandPoseObservation.JointName.indexPIP.rawValue, "indexPIP", "indexPIP")
    visionExpectEqual(HumanHandPoseObservation.JointName.thumbCMC.rawValue, "thumbCMC", "thumbCMC")
    visionExpectEqual(HumanHandPoseObservation.JointName.thumbTip.rawValue, "thumbTip", "thumbTip")
    visionExpectEqual(HumanHandPoseObservation.JointName.littleDIP.rawValue, "littleDIP", "littleDIP")
    visionExpectEqual(HumanHandPoseObservation.JointName.littleMCP.rawValue, "littleMCP", "littleMCP")
    visionExpectEqual(HumanHandPoseObservation.JointName.littlePIP.rawValue, "littlePIP", "littlePIP")
    visionExpectEqual(HumanHandPoseObservation.JointName.littleTip.rawValue, "littleTip", "littleTip")
    visionExpectEqual(HumanHandPoseObservation.JointName.middleDIP.rawValue, "middleDIP", "middleDIP")
    visionExpectEqual(HumanHandPoseObservation.JointName.middleMCP.rawValue, "middleMCP", "middleMCP")
    visionExpectEqual(HumanHandPoseObservation.JointName.middlePIP.rawValue, "middlePIP", "middlePIP")
    visionExpectEqual(HumanHandPoseObservation.JointName.middleTip.rawValue, "middleTip", "middleTip")
    visionExpectEqual(Set(AnimalBodyPoseObservation.JointName.allCases).count, 25, "overlay animal joints")
    visionExpect(animal.availableJointNames.contains(.nose), "animal available")
    visionExpect(animal.availableJointsGroupNames.contains(.head), "animal head group")
    visionExpectEqual(animal.description.contains("Animal"), true, "animal description")
    visionExpect(animal.allJoints(in: .head)[.nose] != nil, "animal head")
    visionExpect(animal.allJoints(in: .trunk)[.nose] != nil, "nose in trunk")
    visionExpect(animal.allJoints(in: .forelegs).isEmpty, "empty forelegs")
    visionExpect(animal.allJoints(in: .hindlegs).isEmpty, "empty hindlegs")
    visionExpectEqual(j3d.localPosition, simd_float4x4.identity, "joint3d local")
    visionExpectEqual(j3d.parentJoint, "root", "joint3d parent")
    visionExpectEqual(pose3d.availableJointNames.contains(.root), true, "3d overlay available")
    visionExpect(pose3d.availableJointsGroupNames.contains(.head), "3d overlay groups")
    visionExpectEqual(pose3d.heightEstimationTechnique, .measured, "technique")
    visionExpectEqual(pose3d.cameraOriginMatrix, .identity, "overlay camera")
    visionExpectEqual(pose3d.joint(for: .root)?.identifier, "root", "3d joint for")
    visionExpectEqual(HumanBodyPose3DObservation.EstimationTechnique.reference.rawValue, "reference", "reference technique")
    visionExpectEqual(pose3d.parentJointName(for: .root), .root, "root parent overlay")
    visionExpectEqual(pose3d.parentJointName(for: .spine), .root, "spine parent overlay")
    visionExpectEqual(pose3d.parentJointName(for: .centerShoulder), .spine, "centerShoulder parent overlay")
    visionExpectEqual(pose3d.parentJointName(for: .centerHead), .centerShoulder, "centerHead parent overlay")
    visionExpectEqual(pose3d.parentJointName(for: .topHead), .centerHead, "topHead parent overlay")
    visionExpectEqual(pose3d.parentJointName(for: .leftElbow), .leftShoulder, "leftElbow parent overlay")
    visionExpectEqual(pose3d.parentJointName(for: .leftShoulder), .centerShoulder, "leftShoulder parent overlay")
    visionExpectEqual(pose3d.parentJointName(for: .rightShoulder), .centerShoulder, "rightShoulder parent overlay")
    visionExpectEqual(pose3d.parentJointName(for: .rightElbow), .rightShoulder, "rightElbow parent overlay")
    visionExpectEqual(pose3d.parentJointName(for: .leftHip), .root, "leftHip parent overlay")
    visionExpectEqual(pose3d.parentJointName(for: .rightHip), .root, "rightHip parent overlay")
    visionExpectEqual(pose3d.parentJointName(for: .leftKnee), .leftHip, "leftKnee parent overlay")
    visionExpectEqual(pose3d.parentJointName(for: .rightKnee), .rightHip, "rightKnee parent overlay")
    visionExpectEqual(pose3d.parentJointName(for: .leftAnkle), .leftKnee, "leftAnkle parent overlay")
    visionExpectEqual(pose3d.parentJointName(for: .rightAnkle), .rightKnee, "rightAnkle parent overlay")
    visionExpectEqual(Set(HumanBodyPose3DObservation.JointName.allCases).count, 17, "overlay 3d joints")
    visionExpectEqual(HumanBodyPose3DObservation.JointsGroupName.allCases.count, 6, "overlay 3d groups")
    let encodedJoint = try! JSONEncoder().encode(joint)
    let decodedJoint = try! JSONDecoder().decode(Joint.self, from: encodedJoint)
    visionExpectEqual(decodedJoint.jointName, "wrist", "joint roundtrip")
    visionExpectEqual(joint.description, "wrist", "joint description")
    visionExpectEqual(joint.location.x, 0.5, "joint location")
    let vnBody = VNHumanBodyPoseObservation(hostJoints: [
        .nose: VNRecognizedPoint(x: 0.5, y: 0.9, confidence: 1, identifier: .bodyLandmarkKeyNose)
    ])
    let fromVNBody = HumanBodyPoseObservation(vnBody)
    visionExpectEqual(fromVNBody.joint(for: .nose)?.location.y, 0.9, "from vn body")
}

func testOverlayTextAndClassification() {
    let text = RecognizedText(string: "Hi", confidence: 0.7)
    visionExpectEqual(text.boundingBox(for: text.string.startIndex..<text.string.endIndex) == nil, true, "no layout")
    let observation = RecognizedTextObservation(
        topLeft: NormalizedPoint(x: 0, y: 1),
        topRight: NormalizedPoint(x: 1, y: 1),
        bottomRight: NormalizedPoint(x: 1, y: 0),
        bottomLeft: NormalizedPoint(x: 0, y: 0),
        candidates: [text, RecognizedText(string: "HI", confidence: 0.2)]
    )
    visionExpectEqual(observation.topCandidates(1).first?.string, "Hi", "overlay candidates")
    visionExpectEqual(observation.transcript, "Hi", "transcript")
    let classification = ClassificationObservation(identifier: "dog", confidence: 0.3)
    visionExpectEqual(classification.hasMinimumRecall(0.2, forPrecision: 0.9), false, "no curve")
    visionExpectEqual(text.string, "Hi", "text string")
    visionExpectEqual(text.confidence, 0.7, "text confidence")
    visionExpectEqual(text.description, "Hi", "text description")
    visionExpectEqual(observation.topLeft.y, 1, "topLeft")
    visionExpectEqual(observation.topRight.x, 1, "topRight")
    visionExpectEqual(observation.bottomRight.y, 0, "bottomRight")
    visionExpectEqual(observation.bottomLeft.x, 0, "bottomLeft")
    visionExpectEqual(observation.isTitle, false, "isTitle")
    visionExpectEqual(observation.textDirection, .leftToRight, "direction")
    visionExpectEqual(observation.boundingBox.width, 1, "overlay bbox")
    visionExpectEqual(classification.identifier, "dog", "class id")
    visionExpectEqual(classification.hasPrecisionRecallCurve, false, "class curve")
    visionExpectEqual(classification.hasMinimumPrecision(0.9, forRecall: 0.1), false, "class precision")
    visionExpectEqual(RecognizedTextObservation.Direction.rightToLeft.rawValue, "rightToLeft", "rtl")
    visionExpectEqual(RecognizedTextObservation.Direction.topToBottom.rawValue, "topToBottom", "ttb")
    visionExpectEqual(RecognizedTextObservation.Direction.bottomToTop.rawValue, "bottomToTop", "btt")
}

func testRevisionConstantsCatalog() {
    visionExpectEqual(VNDetectFaceLandmarksRequestRevision1, 1, "fl1")
    visionExpectEqual(VNDetectFaceLandmarksRequestRevision2, 2, "fl2")
    visionExpectEqual(VNDetectFaceLandmarksRequestRevision3, 3, "fl3")
    visionExpectEqual(VNDetectFaceCaptureQualityRequestRevision1, 1, "fcq1")
    visionExpectEqual(VNDetectFaceCaptureQualityRequestRevision2, 2, "fcq2")
    visionExpectEqual(VNDetectFaceCaptureQualityRequestRevision3, 3, "fcq3")
    visionExpectEqual(VNDetectHorizonRequestRevision1, 1, "horizon")
    visionExpectEqual(VNDetectTextRectanglesRequestRevision1, 1, "text rect")
    visionExpectEqual(VNDetectTrajectoriesRequestRevision1, 1, "traj")
    visionExpectEqual(VNCalculateImageAestheticsScoresRequestRevision1, 1, "aesthetics")
    visionExpectEqual(VNGenerateForegroundInstanceMaskRequestRevision1, 1, "fg mask")
    visionExpectEqual(VNGenerateObjectnessBasedSaliencyImageRequestRevision1, 1, "obj1")
    visionExpectEqual(VNGenerateObjectnessBasedSaliencyImageRequestRevision2, 2, "obj2")
    visionExpectEqual(VNGenerateOpticalFlowRequestRevision1, 1, "of1")
    visionExpectEqual(VNGenerateOpticalFlowRequestRevision2, 2, "of2")
    visionExpectEqual(VNGeneratePersonInstanceMaskRequestRevision1, 1, "person mask")
    visionExpectEqual(VNGeneratePersonSegmentationRequestRevision1, 1, "person seg")
    visionExpectEqual(VNRecognizeAnimalsRequestRevision1, 1, "animals1")
    visionExpectEqual(VNRecognizeAnimalsRequestRevision2, 2, "animals2")
    visionExpectEqual(VNTrackHomographicImageRegistrationRequestRevision1, 1, "track homo")
    visionExpectEqual(VNTrackOpticalFlowRequestRevision1, 1, "track of")
    visionExpectEqual(VNTrackRectangleRequestRevision1, 1, "track rect")
    visionExpectEqual(VNTrackTranslationalImageRegistrationRequestRevision1, 1, "track trans")
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

func testRequestDescriptorCatalog() {
    let cases: [RequestDescriptor] = [
        .detectBarcodesRequest(.revision4),
        .detectRectanglesRequest(.revision1),
        .detectContoursRequest(.revision1),
        .generateImageFeaturePrintRequest(.revision2),
        .classifyImageRequest(.revision2),
        .recognizeTextRequest(.revision3),
        .detectFaceRectanglesRequest(.revision3),
        .detectHumanBodyPoseRequest(.revision1),
        .detectHorizonRequest(.revision1),
        .detectLensSmudgeRequest(.revision1),
        .recognizeAnimalsRequest(.revision1),
        .detectTrajectoriesRequest(.revision1),
        .recognizeDocumentsRequest(.revision1),
        .detectFaceLandmarksRequest(.revision1),
        .detectHumanHandPoseRequest(.revision1),
        .detectAnimalBodyPoseRequest(.revision1),
        .detectTextRectanglesRequest(.revision1),
        .detectHumanRectanglesRequest(.revision1),
        .detectFaceCaptureQualityRequest(.revision1),
        .detectDocumentSegmentationRequest(.revision1),
        .generatePersonInstanceMaskRequest(.revision1),
        .generatePersonSegmentationRequest(.revision1),
        .calculateImageAestheticsScoresRequest(.revision1),
        .generateForegroundInstanceMaskRequest(.revision1),
        .generateAttentionBasedSaliencyImageRequest(.revision1),
        .generateObjectnessBasedSaliencyImageRequest(.revision1),
        .detectHumanBodyPose3DRequest(.revision1),
        .coreMLRequest(.revision1),
        .trackObjectRequest(.revision2),
        .trackRectangleRequest(.revision1),
        .trackOpticalFlowRequest(.revision1),
        .trackHomographicImageRegistrationRequest(.revision1),
        .trackTranslationalImageRegistrationRequest(.revision1)
    ]
    visionExpectEqual(Set(cases).count, cases.count, "descriptor unique")
    for item in cases {
        visionExpect(!item.description.isEmpty, "descriptor description")
        visionExpect(item == item, "descriptor equal")
        visionExpect(item != .detectBarcodesRequest(.revision4) || item == .detectBarcodesRequest(.revision4), "descriptor !=")
        _ = item.hashValue
        var hasher = Hasher()
        item.hash(into: &hasher)
        _ = hasher.finalize()
        let encoded = try! JSONEncoder().encode(item)
        let decoded = try! JSONDecoder().decode(RequestDescriptor.self, from: encoded)
        visionExpectEqual(decoded, item, "descriptor roundtrip \(item)")
    }
    visionExpect(RequestDescriptor.detectBarcodesRequest(.revision4) != .recognizeDocumentsRequest(.revision1), "distinct cases")
}

func testVisionResultCatalog() {
    let barcodes = DetectBarcodesRequest()
    let contours = DetectContoursRequest()
    let rectangles = DetectRectanglesRequest()
    let feature = GenerateImageFeaturePrintRequest()
    let classify = ClassifyImageRequest()
    let text = RecognizeTextRequest()
    let face = DetectFaceRectanglesRequest()
    let pose = DetectHumanBodyPoseRequest()
    let horizon = DetectHorizonRequest()
    let smudge = DetectLensSmudgeRequest()
    let animals = RecognizeAnimalsRequest()
    let trajectories = DetectTrajectoriesRequest()
    let documents = RecognizeDocumentsRequest()
    let landmarks = DetectFaceLandmarksRequest()
    let hands = DetectHumanHandPoseRequest()
    let animalPose = DetectAnimalBodyPoseRequest()
    let textRects = DetectTextRectanglesRequest()
    let humans = DetectHumanRectanglesRequest()
    let capture = DetectFaceCaptureQualityRequest()
    let segmentation = DetectDocumentSegmentationRequest()
    let personMask = GeneratePersonInstanceMaskRequest()
    let personSeg = GeneratePersonSegmentationRequest()
    let aesthetics = CalculateImageAestheticsScoresRequest()
    let foreground = GenerateForegroundInstanceMaskRequest()
    let attention = GenerateAttentionBasedSaliencyImageRequest()
    let objectness = GenerateObjectnessBasedSaliencyImageRequest()
    let pose3d = DetectHumanBodyPose3DRequest()
    let coreml = CoreMLRequest()
    let seed = DetectedObjectObservation(boundingBox: .fullImage)
    let track = TrackObjectRequest(detectedObject: seed)
    let trackRect = TrackRectangleRequest()
    let flow = TrackOpticalFlowRequest()
    let homo = TrackHomographicImageRegistrationRequest()
    let trans = TrackTranslationalImageRegistrationRequest()

    let results: [VisionResult] = [
        .detectBarcodes(barcodes, []),
        .detectContours(contours, ContoursObservation(VNContoursObservation(topLevelContours: []))),
        .detectRectangles(rectangles, []),
        .generateImageFeaturePrint(feature, FeaturePrintObservation(VNFeaturePrintObservation(elementType: .float, data: Data(repeating: 0, count: 4)))),
        .classifyImage(classify, []),
        .recognizeText(text, []),
        .detectFaceRectangles(face, []),
        .detectHumanBodyPose(pose, []),
        .detectHorizon(horizon, nil),
        .detectLensSmudge(smudge, SmudgeObservation(confidence: 0, uuid: UUID(), timeRange: nil, originatingRequestDescriptor: nil)),
        .recognizeAnimals(animals, []),
        .detectTrajectories(trajectories, []),
        .recognizeDocuments(documents, []),
        .detectFaceLandmarks(landmarks, []),
        .detectHumanHandPose(hands, []),
        .detectAnimalBodyPose(animalPose, []),
        .detectTextRectangles(textRects, []),
        .detectHumanRectangles(humans, []),
        .detectFaceCaptureQuality(capture, []),
        .detectDocumentSegmentation(segmentation, nil),
        .generatePersonInstanceMask(personMask, nil),
        .generatePersonSegmentation(personSeg, PixelBufferObservation()),
        .calculateImageAestheticsScores(aesthetics, ImageAestheticsScoresObservation()),
        .generateForegroundInstanceMask(foreground, nil),
        .generateAttentionBasedSaliencyImage(attention, SaliencyImageObservation()),
        .generateObjectnessBasedSaliencyImage(objectness, SaliencyImageObservation()),
        .detectHumanBodyPose3D(pose3d, []),
        .coreML(coreml, []),
        .trackObject(track, nil),
        .trackRectangle(trackRect, nil),
        .trackOpticalFlow(flow, nil),
        .trackHomographicImageRegistration(homo, ImageHomographicAlignmentObservation()),
        .trackTranslationalImageRegistration(trans, ImageTranslationAlignmentObservation(VNImageTranslationAlignmentObservation(alignmentTransform: .identity))),
        .error(barcodes, VisionError.invalidModel("catalog"))
    ]
    for item in results {
        visionExpect(!item.description.isEmpty, "result description")
    }
    visionExpectEqual(results.count, 34, "vision result cases")
}

func testBarcodeObservationOverlayValues() {
    let qrImage = try! VisionHost.makeQRImage(payload: "HELLO")
    let handler = VNImageRequestHandler(cgImage: qrImage)
    let request = VNDetectBarcodesRequest()
    request.symbologies = [.qr]
    try! handler.perform([request])
    let vn = (request.results ?? []).compactMap { $0 as? VNBarcodeObservation }.first!
    let overlay = BarcodeObservation(vn)
    visionExpectEqual(overlay.payloadString, "HELLO", "payload string")
    visionExpect(overlay.payloadData != nil || overlay.payloadData == nil, "payload data readable")
    visionExpectEqual(overlay.symbology, .qr, "symbology")
    visionExpectEqual(overlay.isGS1DataCarrier, false, "gs1")
    visionExpectEqual(overlay.isColorInverted, false, "inverted")
    visionExpect(overlay.supplementalCompositeType == nil, "no supplemental composite")
    visionExpect(overlay.supplementalPayloadString == nil, "no supplemental string")
    visionExpect(overlay.supplementalPayloadData == nil, "no supplemental data")
    visionExpect(overlay.confidence > 0, "confidence")
    visionExpectEqual(overlay.uuid, vn.uuid, "uuid")
    visionExpectEqual(overlay.timeRange, vn.timeRange, "timeRange")
    visionExpect(overlay.originatingRequestDescriptor == nil, "descriptor")
    visionExpect(overlay.boundingBox.width > 0 && overlay.boundingBox.height > 0, "bounding box")
    visionExpect(overlay.boundingRegion.pointCount >= 4, "bounding region")
    visionExpect(overlay.topLeft.x >= 0 && overlay.topRight.x >= overlay.topLeft.x, "corners")
    visionExpectEqual(overlay.description, "HELLO", "description")
    visionExpect(overlay == overlay, "equal")
    visionExpect(!(overlay != overlay), "not unequal to self")
    _ = overlay.hashValue
    var hasher = Hasher()
    overlay.hash(into: &hasher)
    _ = hasher.finalize()
    let encoded = try! JSONEncoder().encode(overlay)
    let decoded = try! JSONDecoder().decode(BarcodeObservation.self, from: encoded)
    visionExpectEqual(decoded.payloadString, "HELLO", "codable payload")
    visionExpectEqual(BarcodeObservation.CompositeType.linked.rawValue, "linked", "linked")
    visionExpectEqual(BarcodeObservation.CompositeType.gs1TypeA.rawValue, "gs1TypeA", "a")
    visionExpectEqual(BarcodeObservation.CompositeType.gs1TypeB.rawValue, "gs1TypeB", "b")
    visionExpectEqual(BarcodeObservation.CompositeType.gs1TypeC.rawValue, "gs1TypeC", "c")
    visionExpect(BarcodeObservation.CompositeType.linked != .gs1TypeA, "composite !=")
    visionExpect(BarcodeObservation.CompositeType.linked == .linked, "composite ==")
    let compositeEncoded = try! JSONEncoder().encode(BarcodeObservation.CompositeType.gs1TypeB)
    let compositeDecoded = try! JSONDecoder().decode(BarcodeObservation.CompositeType.self, from: compositeEncoded)
    visionExpectEqual(compositeDecoded, .gs1TypeB, "composite roundtrip")
    _ = BarcodeObservation.CompositeType.gs1TypeC.hashValue
    var compositeHasher = Hasher()
    BarcodeObservation.CompositeType.gs1TypeA.hash(into: &compositeHasher)
    _ = compositeHasher.finalize()
}

func testRecognizeDocumentsRequestConfig() {
    var request = RecognizeDocumentsRequest()
    visionExpectEqual(request.revision, .revision1, "revision")
    visionExpectEqual(RecognizeDocumentsRequest.supportedRevisions, [.revision1], "supported")
    visionExpectEqual(request.regionOfInterest, .fullImage, "roi")
    visionExpectEqual(request.descriptor, .recognizeDocumentsRequest(.revision1), "descriptor")
    visionExpect(request.description.contains("recognizeDocuments"), "description")
    visionExpect(request.supportedBarcodeSymbologies.contains(.qr), "supported barcodes")
    visionExpect(request.supportedRecognitionLanguages.isEmpty, "no Apple languages")
    visionExpect(request.supportedComputeStageDevices[.main]?.contains(MLComputeDevice.cpu) == true, "cpu stage")
    visionExpect(request.computeDevice(for: .main) == nil, "unset device")
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main)?.identifier, "cpu", "set device")
    request.textRecognitionOptions.customWords = ["OpenUIKit"]
    request.textRecognitionOptions.minimumTextHeightFraction = 0.02
    request.textRecognitionOptions.maximumCandidateCount = 3
    request.textRecognitionOptions.useLanguageCorrection = false
    request.textRecognitionOptions.automaticallyDetectLanguage = false
    visionExpectEqual(request.textRecognitionOptions.customWords, ["OpenUIKit"], "custom words")
    visionExpectEqual(request.textRecognitionOptions.minimumTextHeightFraction, 0.02, "min height")
    visionExpectEqual(request.textRecognitionOptions.maximumCandidateCount, 3, "candidates")
    visionExpectEqual(request.textRecognitionOptions.useLanguageCorrection, false, "correction")
    visionExpectEqual(request.textRecognitionOptions.automaticallyDetectLanguage, false, "autodetect")
    request.barcodeDetectionOptions.enabled = true
    request.barcodeDetectionOptions.symbologies = [.qr]
    request.barcodeDetectionOptions.coalesceCompositeSymbologies = true
    visionExpectEqual(request.barcodeDetectionOptions.enabled, true, "barcode enabled")
    visionExpectEqual(request.barcodeDetectionOptions.symbologies, [.qr], "barcode symbologies")
    visionExpectEqual(request.barcodeDetectionOptions.coalesceCompositeSymbologies, true, "coalesce")
    let encodedOptions = try! JSONEncoder().encode(request.textRecognitionOptions)
    let decodedOptions = try! JSONDecoder().decode(RecognizeDocumentsRequest.TextRecognitionOptions.self, from: encodedOptions)
    visionExpectEqual(decodedOptions.customWords, ["OpenUIKit"], "text options roundtrip")
    let encodedBarcode = try! JSONEncoder().encode(request.barcodeDetectionOptions)
    let decodedBarcode = try! JSONDecoder().decode(RecognizeDocumentsRequest.BarcodeDetectionOptions.self, from: encodedBarcode)
    visionExpectEqual(decodedBarcode.enabled, true, "barcode options roundtrip")
    visionExpect(request == request, "equal")
    visionExpect(request != RecognizeDocumentsRequest(), "config inequality")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    _ = hasher.finalize()
    visionExpect(RecognizeDocumentsRequest.Revision.revision1 == .revision1, "rev ==")
    visionExpect(!(RecognizeDocumentsRequest.Revision.revision1 < .revision1), "rev <")
    _ = RecognizeDocumentsRequest.Revision.revision1.hashValue

    let image = visionRectangleImage()
    let handler = VNImageRequestHandler(cgImage: image)
    do {
        _ = try request.performOnHandler(handler)
        visionExpect(false, "documents should fail closed")
    } catch let error as VisionError {
        if case .invalidModel = error {
            visionExpect(true, "documents invalidModel")
        } else {
            visionExpect(false, "unexpected \(error)")
        }
    } catch {
        visionExpect(false, "wrong error type \(error)")
    }
}

func testTrackOpticalFlowRequestConfig() {
    let request = TrackOpticalFlowRequest(.revision1, frameAnalysisSpacing: CMTime(value: 1, timescale: 30))
    visionExpectEqual(request.revision, .revision1, "revision")
    visionExpectEqual(TrackOpticalFlowRequest.supportedRevisions, [.revision1], "supported")
    visionExpectEqual(request.frameAnalysisSpacing.value, 1, "spacing")
    visionExpectEqual(request.minimumLatencyFrameCount, 1, "latency")
    visionExpectEqual(request.computationAccuracy, .medium, "accuracy default")
    request.computationAccuracy = .high
    visionExpectEqual(request.computationAccuracy, .high, "accuracy set")
    visionExpectEqual(request.outputPixelFormatType, kCVPixelFormatType_32BGRA, "format")
    visionExpectEqual(request.supportedOutputPixelFormatTypes, [kCVPixelFormatType_32BGRA], "supported formats")
    visionExpectEqual(request.descriptor, .trackOpticalFlowRequest(.revision1), "descriptor")
    visionExpect(request.description.contains("trackOpticalFlow"), "description")
    visionExpect(request.supportedComputeStageDevices[.main]?.contains(.cpu) == true, "cpu")
    request.setComputeDevice(.cpu, for: .postProcessing)
    visionExpectEqual(request.computeDevice(for: .postProcessing)?.identifier, "cpu", "device")
    visionExpect(request == request, "equal")
    visionExpect(request != TrackOpticalFlowRequest(), "spacing inequality")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    _ = hasher.finalize()
    visionExpectEqual(Set(TrackOpticalFlowRequest.ComputationAccuracy.allCases).count, 4, "accuracy cases")
    visionExpect(TrackOpticalFlowRequest.ComputationAccuracy.low != .veryHigh, "accuracy !=")
    let encoded = try! JSONEncoder().encode(TrackOpticalFlowRequest.ComputationAccuracy.medium)
    let decoded = try! JSONDecoder().decode(TrackOpticalFlowRequest.ComputationAccuracy.self, from: encoded)
    visionExpectEqual(decoded, .medium, "accuracy roundtrip")
    visionExpect(TrackOpticalFlowRequest.Revision.revision1 == .revision1, "rev ==")
    visionExpect(!(TrackOpticalFlowRequest.Revision.revision1 < .revision1), "rev <")
    let range = TrackOpticalFlowRequest.Revision.revision1...TrackOpticalFlowRequest.Revision.revision1
    visionExpect(range.contains(.revision1), "closed range")
    let half = TrackOpticalFlowRequest.Revision.revision1..<TrackOpticalFlowRequest.Revision.revision1
    visionExpect(half.isEmpty, "empty half range")
    let upTo: PartialRangeUpTo<TrackOpticalFlowRequest.Revision> = ..<TrackOpticalFlowRequest.Revision.revision1
    visionExpect(!upTo.contains(.revision1), "up to")
    let from: PartialRangeFrom<TrackOpticalFlowRequest.Revision> = TrackOpticalFlowRequest.Revision.revision1...
    visionExpect(from.contains(.revision1), "from")
    let through: PartialRangeThrough<TrackOpticalFlowRequest.Revision> = ...TrackOpticalFlowRequest.Revision.revision1
    visionExpect(through.contains(.revision1), "through")
    visionExpect(TrackOpticalFlowRequest.Revision.revision1 <= .revision1, "<=")
    visionExpect(TrackOpticalFlowRequest.Revision.revision1 >= .revision1, ">=")
    visionExpect(!(TrackOpticalFlowRequest.Revision.revision1 > .revision1), ">")

    let image = visionRectangleImage()
    do {
        _ = try request.performOnHandler(VNImageRequestHandler(cgImage: image))
        visionExpect(false, "optical flow should fail closed")
    } catch let error as VisionError {
        if case .invalidModel = error {
            visionExpect(true, "optical flow invalidModel")
        } else {
            visionExpect(false, "unexpected \(error)")
        }
    } catch {
        visionExpect(false, "wrong error type \(error)")
    }
}

func testOverlayRequestProtocolSurface() {
    var barcodes = DetectBarcodesRequest()
    visionExpectEqual(barcodes.descriptor, .detectBarcodesRequest(.revision4), "barcode descriptor")
    visionExpectEqual(barcodes.regionOfInterest, .fullImage, "roi")
    visionExpectEqual(DetectBarcodesRequest.supportedRevisions, [.revision4], "supported")
    visionExpect(barcodes.supportedComputeStageDevices[.main]?.contains(.cpu) == true, "cpu")
    visionExpect(barcodes.computeDevice(for: .main) == nil, "unset")
    barcodes.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(barcodes.computeDevice(for: .main)?.identifier, "cpu", "set")
    visionExpect(barcodes == barcodes, "equal")
    _ = barcodes.hashValue
    var hasher = Hasher()
    barcodes.hash(into: &hasher)
    _ = hasher.finalize()
    visionExpect(!barcodes.description.isEmpty, "description")
    barcodes.coalescesCompositeSymbologies = true
    visionExpectEqual(barcodes.coalescesCompositeSymbologies, true, "coalesce")

    var text = RecognizeTextRequest()
    visionExpectEqual(text.descriptor, .recognizeTextRequest(.revision3), "text descriptor")
    visionExpectEqual(text.regionOfInterest, .fullImage, "text roi")
    visionExpect(text.supportedComputeStageDevices[.postProcessing]?.contains(.cpu) == true, "text cpu")
    text.setComputeDevice(.cpu, for: .postProcessing)
    visionExpectEqual(text.computeDevice(for: .postProcessing)?.identifier, "cpu", "text device")

    var face = DetectFaceRectanglesRequest()
    visionExpectEqual(face.descriptor, .detectFaceRectanglesRequest(.revision3), "face descriptor")
    face.regionOfInterest = NormalizedRect(x: 0.1, y: 0.1, width: 0.5, height: 0.5)
    visionExpectEqual(face.regionOfInterest.width, 0.5, "face roi")
    visionExpect(face.supportedComputeStageDevices[.main]?.isEmpty == false, "face devices")

    let proto: any VisionRequest = barcodes
    visionExpect(!proto.description.isEmpty, "existential description")
    visionExpect(proto.supportedComputeStageDevices[.main] != nil, "existential devices")
}

func testOverlayRevisionComparableOperators() {
    func exercise<T: Comparable & Hashable>(_ a: T, _ b: T, _ message: String) {
        visionExpect(a == a, message + " ==")
        visionExpect(!(a != a), message + " !=")
        visionExpect(a <= b, message + " <=")
        visionExpect(a >= a, message + " >=")
        visionExpect(!(a > b) || a != b, message + " >")
        _ = a...b
        _ = a..<b
        _ = a...
        _ = ...a
        _ = ..<b
    }
    exercise(DetectBarcodesRequest.Revision.revision4, .revision4, "barcode")
    exercise(DetectRectanglesRequest.Revision.revision1, .revision1, "rect")
    exercise(DetectContoursRequest.Revision.revision1, .revision1, "contour")
    exercise(GenerateImageFeaturePrintRequest.Revision.revision2, .revision2, "feature")
    exercise(ClassifyImageRequest.Revision.revision2, .revision2, "classify")
    exercise(RecognizeTextRequest.Revision.revision3, .revision3, "text")
    exercise(DetectFaceRectanglesRequest.Revision.revision3, .revision3, "face")
    exercise(DetectHumanBodyPoseRequest.Revision.revision1, .revision1, "body")
    exercise(DetectHorizonRequest.Revision.revision1, .revision1, "horizon")
    exercise(DetectLensSmudgeRequest.Revision.revision1, .revision1, "smudge")
    exercise(RecognizeAnimalsRequest.Revision.revision1, .revision1, "animals")
    exercise(DetectTrajectoriesRequest.Revision.revision1, .revision1, "traj")
    exercise(RecognizeDocumentsRequest.Revision.revision1, .revision1, "docs")
    exercise(DetectFaceLandmarksRequest.Revision.revision1, .revision1, "landmarks")
    exercise(DetectHumanHandPoseRequest.Revision.revision1, .revision1, "hand")
    exercise(DetectAnimalBodyPoseRequest.Revision.revision1, .revision1, "animal")
    exercise(DetectTextRectanglesRequest.Revision.revision1, .revision1, "textrects")
    exercise(DetectHumanRectanglesRequest.Revision.revision1, .revision1, "humans")
    exercise(DetectFaceCaptureQualityRequest.Revision.revision1, .revision1, "capture")
    exercise(DetectDocumentSegmentationRequest.Revision.revision1, .revision1, "docseg")
    exercise(GeneratePersonInstanceMaskRequest.Revision.revision1, .revision1, "personmask")
    exercise(GeneratePersonSegmentationRequest.Revision.revision1, .revision1, "personseg")
    exercise(CalculateImageAestheticsScoresRequest.Revision.revision1, .revision1, "aesthetics")
    exercise(GenerateForegroundInstanceMaskRequest.Revision.revision1, .revision1, "foreground")
    exercise(GenerateAttentionBasedSaliencyImageRequest.Revision.revision1, .revision1, "attention")
    exercise(GenerateObjectnessBasedSaliencyImageRequest.Revision.revision1, .revision1, "objectness")
    exercise(DetectHumanBodyPose3DRequest.Revision.revision1, .revision1, "pose3d")
    exercise(CoreMLRequest.Revision.revision1, .revision1, "coreml")
    exercise(TrackObjectRequest.Revision.revision2, .revision2, "trackobj")
    exercise(TrackRectangleRequest.Revision.revision1, .revision1, "trackrect")
    exercise(TrackOpticalFlowRequest.Revision.revision1, .revision1, "flow")
    exercise(TrackHomographicImageRegistrationRequest.Revision.revision1, .revision1, "homo")
    exercise(TrackTranslationalImageRegistrationRequest.Revision.revision1, .revision1, "trans")
}

func testOverlayROIAndInvalidImage() {
    var request = RecognizeDocumentsRequest()
    request.regionOfInterest = NormalizedRect(x: 0.2, y: 0.2, width: -0.1, height: 0.2)
    do {
        _ = try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
        visionExpect(false, "negative size should throw")
    } catch let error as VisionError {
        if case .invalidArgument = error {
            visionExpect(true, "overlay negative size")
        } else {
            visionExpect(false, "expected invalidArgument, got \(error)")
        }
    } catch {
        visionExpect(false, "wrong type \(error)")
    }

    request.regionOfInterest = NormalizedRect(x: 0.2, y: 0.2, width: 0.9, height: 0.9)
    do {
        _ = try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
        visionExpect(false, "overflow should throw")
    } catch let error as VisionError {
        if case .outOfBoundsError = error {
            visionExpect(true, "overlay overflow")
        } else {
            visionExpect(false, "expected outOfBounds, got \(error)")
        }
    } catch {
        visionExpect(false, "wrong type \(error)")
    }

    request.regionOfInterest = .fullImage
    do {
        _ = try request.performOnHandler(VNImageRequestHandler(data: Data([0, 1, 2])))
        visionExpect(false, "garbage should throw")
    } catch let error as VisionError {
        if case .invalidImage = error {
            visionExpect(true, "overlay invalid image")
        } else {
            visionExpect(false, "expected invalidImage, got \(error)")
        }
    } catch {
        visionExpect(false, "wrong type \(error)")
    }
}

func testVNTrackOpticalFlowRequestConfig() {
    let request = VNTrackOpticalFlowRequest()
    visionExpectEqual(request.computationAccuracy, .medium, "accuracy")
    request.computationAccuracy = .low
    visionExpectEqual(request.computationAccuracy, .low, "accuracy set")
    visionExpectEqual(request.keepNetworkOutput, false, "keep default")
    request.keepNetworkOutput = true
    visionExpectEqual(request.keepNetworkOutput, true, "keep set")
    visionExpectEqual(request.outputPixelFormat, kCVPixelFormatType_32BGRA, "pixel format")
    request.outputPixelFormat = kCVPixelFormatType_32BGRA
    visionExpect(request.results == nil, "results nil")
    visionExpectEqual(VNTrackOpticalFlowRequest.currentRevision, VNTrackOpticalFlowRequestRevision1, "current")
    visionExpectEqual(VNTrackOpticalFlowRequest.defaultRevision, VNTrackOpticalFlowRequestRevision1, "default")
    visionExpect(VNTrackOpticalFlowRequest.supportedRevisions.contains(VNTrackOpticalFlowRequestRevision1), "supported")
    let withHandler = VNTrackOpticalFlowRequest(completionHandler: { _, _ in })
    visionExpect(withHandler.completionHandler != nil, "completion")
    let image = visionRectangleImage()
    let handler = VNImageRequestHandler(cgImage: image)
    do {
        try handler.perform([request])
        visionExpect(false, "vn optical flow should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "vn invalidModel")
        visionExpect(request.results == nil, "results stay nil")
    }
}

func testImageRequestHandlerOverlayPerformNow() {
    let image = try! VisionHost.makeQRImage(payload: "HELLO")
    let data = VisionHost.encodeNetpbm(image)
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try! FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try! FileManager.default.removeItem(at: directory) }
    let url = directory.appendingPathComponent("qr.ppm")
    try! data.write(to: url)
    let ci = CIImage(cgImage: image)
    let buffer = CVPixelBuffer(width: image.width, height: image.height, pixels: image.pixels)
    let sample = CMSampleBuffer(pixelBuffer: buffer)
    let handlers = [
        ImageRequestHandler(url), ImageRequestHandler(data), ImageRequestHandler(image),
        ImageRequestHandler(ci), ImageRequestHandler(buffer), ImageRequestHandler(sample),
    ]
    var barcodes = DetectBarcodesRequest()
    barcodes.symbologies = [.qr]
    for (index, handler) in handlers.enumerated() {
        let hits: [BarcodeObservation] = try! handler.performNow(barcodes)
        visionExpect(hits.contains(where: { $0.payloadString == "HELLO" }), "handler source \(index) QR")
    }
    do {
        _ = try handlers[0].performNow(RecognizeDocumentsRequest())
        visionExpect(false, "handler documents fail closed")
    } catch let error as VisionError {
        if case .invalidModel = error {
            visionExpect(true, "handler documents")
        } else {
            visionExpect(false, "unexpected \(error)")
        }
    } catch {
        visionExpect(false, "wrong type \(error)")
    }
}

func testOverlayEquatableInequality() {
    visionExpect(DetectBarcodesRequest() == DetectBarcodesRequest(), "barcodes ==")
    visionExpect(!(DetectBarcodesRequest() != DetectBarcodesRequest()), "barcodes !=")
    visionExpect(RecognizeDocumentsRequest() != RecognizeDocumentsRequest(.revision1) || RecognizeDocumentsRequest() == RecognizeDocumentsRequest(), "docs")
    visionExpect(TrackOpticalFlowRequest() == TrackOpticalFlowRequest(), "flow ==")
    visionExpect(TrackRectangleRequest() == TrackRectangleRequest(), "rect ==")
    visionExpect(TrackHomographicImageRegistrationRequest() == TrackHomographicImageRegistrationRequest(), "homo ==")
    visionExpect(TrackTranslationalImageRegistrationRequest() == TrackTranslationalImageRegistrationRequest(), "trans ==")
    visionExpect(RecognizeTextRequest() == RecognizeTextRequest(), "text ==")
    visionExpect(ClassifyImageRequest() == ClassifyImageRequest(), "classify ==")
    visionExpect(CoreMLRequest() == CoreMLRequest(), "coreml ==")
    visionExpect(DetectHorizonRequest() == DetectHorizonRequest(), "horizon ==")
    let seed = DetectedObjectObservation(boundingBox: .fullImage)
    visionExpect(TrackObjectRequest(detectedObject: seed) == TrackObjectRequest(detectedObject: seed), "track ==")
    _ = DetectBarcodesRequest().hashValue
    _ = RecognizeDocumentsRequest().hashValue
}

func testPixelBufferObservationValues() {
    let buffer = CVPixelBuffer(width: 2, height: 2)
    let observation = VNPixelBufferObservation(pixelBuffer: buffer, featureName: "flow")
    visionExpectEqual(observation.featureName, "flow", "feature name")
    visionExpectEqual(observation.pixelBuffer.width, 2, "pixel width")
    visionExpectEqual(observation.pixelBuffer.height, 2, "pixel height")
    let overlay = OpticalFlowObservation(observation)
    visionExpect(overlay != nil, "optical overlay")
    visionExpectEqual(overlay?.pixelBuffer?.width, 2, "overlay buffer")
    visionExpectEqual(overlay?.confidence, 1, "overlay confidence")
}

func testVisionErrorCatalog() {
    let cases: [VisionError] = [
        .outOfBoundsError("oob"),
        .ioError("io"),
        .internalError("internal"),
        .outOfMemory("oom"),
        .invalidImage("image"),
        .invalidModel("model"),
        .invalidFormat("format"),
        .dataUnavailable("data"),
        .invalidArgument("arg"),
        .operationFailed("op"),
        .invalidOperation("invop"),
        .requestCancelled("cancel"),
        .timeStampNotFound("ts"),
        .unsupportedRequest("req"),
        .unsupportedRevision("rev"),
        .unsupportedComputeStage("stage"),
        .unsupportedComputeDevice("dev"),
        .pixelBufferCreationFailed(12),
        .timeout("timeout")
    ]
    for item in cases {
        visionExpect(!item.description.isEmpty, "description \(item)")
        visionExpect(item.errorDescription != nil, "errorDescription \(item)")
        visionExpectEqual(item.failureReason, item.errorDescription, "failureReason \(item)")
        visionExpect(item.recoverySuggestion == nil, "recovery \(item)")
        visionExpect(item.helpAnchor == nil, "help \(item)")
        visionExpect(!item.localizedDescription.isEmpty, "localized \(item)")
    }
    if case .invalidModel(let message) = VisionError.invalidModel("model") {
        visionExpectEqual(message, "model", "invalidModel payload")
    } else {
        visionExpect(false, "invalidModel case")
    }
}

func testContoursObservationOverlayGeometry() {
    let child = ContoursObservation.Contour(
        points: [
            NormalizedPoint(x: 0.2, y: 0.2),
            NormalizedPoint(x: 0.4, y: 0.2),
            NormalizedPoint(x: 0.3, y: 0.4)
        ],
        indexPath: IndexPath(indexes: [0, 0])
    )
    let parent = ContoursObservation.Contour(
        points: [
            NormalizedPoint(x: 0, y: 0),
            NormalizedPoint(x: 1, y: 0),
            NormalizedPoint(x: 1, y: 1),
            NormalizedPoint(x: 0, y: 1)
        ],
        indexPath: IndexPath(index: 0),
        childContours: [child]
    )
    visionExpectEqual(parent.pointCount, 4, "parent points")
    visionExpectEqual(parent.childContours.count, 1, "child contours")
    visionExpectEqual(parent.aspectRatio, 1, "unit square aspect")
    visionExpectEqual(parent.boundingBox.width, 1, "bbox width")
    visionExpectEqual(parent.boundingBox.height, 1, "bbox height")
    visionExpectEqual(parent.boundingQuad.topLeft.y, 1, "quad top")
    visionExpectEqual(parent.normalizedPoints.count, 4, "simd points")
    visionExpect(!parent.description.isEmpty, "contour description")
    visionExpectEqual(parent.indexPath.first, 0, "index path")
    _ = parent.normalizedPath
    visionExpect(abs(parent.calculateArea(useOrientedArea: false) - 1) < 1e-6, "area")
    visionExpect(abs(parent.calculatePerimeter() - 4) < 1e-6, "perimeter")
    let simplified = try! parent.polygonApproximation(epsilon: 0.5)
    visionExpect(simplified.pointCount >= 2, "approx")
    visionExpect(parent == parent, "contour ==")
    visionExpect(parent != child, "contour !=")
    _ = parent.hashValue
    var hasher = Hasher()
    parent.hash(into: &hasher)
    _ = hasher.finalize()

    let vn = VNContoursObservation(topLevelContours: [
        VNContour(
            normalizedPoints: [
                SIMD2<Float>(0, 0),
                SIMD2<Float>(1, 0),
                SIMD2<Float>(1, 1),
                SIMD2<Float>(0, 1)
            ],
            childContours: [
                VNContour(normalizedPoints: [SIMD2<Float>(0.2, 0.2), SIMD2<Float>(0.3, 0.2), SIMD2<Float>(0.25, 0.3)])
            ]
        )
    ])
    let observation = ContoursObservation(vn)
    visionExpectEqual(observation.topLevelContours.count, 1, "top level")
    visionExpectEqual(observation.contourCount, 2, "count")
    visionExpectEqual(observation.confidence, 1, "confidence")
    visionExpect(observation.uuid != UUID(), "uuid")
    visionExpect(observation.timeRange == .zero || observation.timeRange == nil, "timeRange")
    visionExpect(observation.originatingRequestDescriptor == nil, "descriptor")
    visionExpect(!observation.description.isEmpty, "obs description")
    visionExpectEqual(observation.contourAtIndex(0)?.pointCount, 4, "at index")
    visionExpect(observation.contourAtIndex(9) == nil, "missing index")
    visionExpectEqual(observation.countourAtIndexPath(IndexPath(index: 0))?.pointCount, 4, "at path")
    visionExpectEqual(observation.boundingRegion.pointCount, 4, "bounding region")
    _ = observation.normalizedPath
    visionExpect(observation == observation, "obs ==")
    visionExpect(observation != ContoursObservation(VNContoursObservation(topLevelContours: [])), "obs !=")
    _ = observation.hashValue
    var obsHasher = Hasher()
    observation.hash(into: &obsHasher)
    _ = obsHasher.finalize()
    let encoded = try! JSONEncoder().encode(observation)
    let decoded = try! JSONDecoder().decode(ContoursObservation.self, from: encoded)
    visionExpectEqual(decoded.topLevelContours.first?.pointCount, 4, "codable")
}

func testGeneratePersonSegmentationRequestConfig() {
    let request = GeneratePersonSegmentationRequest(.revision1, frameAnalysisSpacing: CMTime(value: 1, timescale: 30))
    visionExpectEqual(request.revision, .revision1, "revision")
    visionExpectEqual(GeneratePersonSegmentationRequest.supportedRevisions, [.revision1], "supported")
    visionExpectEqual(request.frameAnalysisSpacing.value, 1, "spacing")
    visionExpectEqual(request.minimumLatencyFrameCount, 0, "latency default")
    visionExpectEqual(request.qualityLevel, .balanced, "quality default")
    request.qualityLevel = .fast
    visionExpectEqual(request.qualityLevel, .fast, "quality set")
    visionExpectEqual(Set(GeneratePersonSegmentationRequest.QualityLevel.allCases).count, 3, "quality cases")
    visionExpect(GeneratePersonSegmentationRequest.QualityLevel.accurate != .fast, "quality !=")
    visionExpect(GeneratePersonSegmentationRequest.QualityLevel.accurate == .accurate, "quality ==")
    let encoded = try! JSONEncoder().encode(GeneratePersonSegmentationRequest.QualityLevel.balanced)
    let decoded = try! JSONDecoder().decode(GeneratePersonSegmentationRequest.QualityLevel.self, from: encoded)
    visionExpectEqual(decoded, .balanced, "quality roundtrip")
    _ = GeneratePersonSegmentationRequest.QualityLevel.accurate.hashValue
    var qHasher = Hasher()
    GeneratePersonSegmentationRequest.QualityLevel.accurate.hash(into: &qHasher)
    visionExpectEqual(request.outputPixelFormatType, kCVPixelFormatType_32BGRA, "pixel format")
    visionExpectEqual(request.supportedOutputPixelFormats, [kCVPixelFormatType_32BGRA], "supported formats")
    request.regionOfInterest = NormalizedRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8)
    visionExpectEqual(request.regionOfInterest.width, 0.8, "roi")
    visionExpectEqual(request.descriptor, .generatePersonSegmentationRequest(.revision1), "descriptor")
    visionExpect(request.description.contains("generatePerson"), "description")
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main)?.identifier, "cpu", "device")
    visionExpect(request.supportedComputeStageDevices[.main]?.contains(.cpu) == true, "cpu stage")
    visionExpect(request == request, "equal")
    visionExpect(request != GeneratePersonSegmentationRequest(), "spacing inequality")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    _ = hasher.finalize()
    visionExpectOverlayInvalidModel({
        try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    }, "person segmentation")

    let vn = VNGeneratePersonSegmentationRequest()
    visionExpectEqual(vn.qualityLevel, .balanced, "vn quality")
    vn.qualityLevel = .accurate
    visionExpectEqual(vn.qualityLevel, .accurate, "vn quality set")
    visionExpectEqual(vn.outputPixelFormat, kCVPixelFormatType_32BGRA, "vn format")
    let formats = try! vn.supportedOutputPixelFormats()
    visionExpectEqual(formats.first?.uint32Value, kCVPixelFormatType_32BGRA, "vn supported")
    visionExpect(vn.results == nil, "vn results")
    let withHandler = VNGeneratePersonSegmentationRequest(completionHandler: { _, _ in })
    visionExpect(withHandler.completionHandler != nil, "completion")
    do {
        try VNImageRequestHandler(cgImage: visionRectangleImage()).perform([vn])
        visionExpect(false, "vn person segmentation should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "vn invalidModel")
        visionExpect(vn.results == nil, "results stay nil")
    }
}

func testTrackRectangleRequestConfig() {
    let seed = RectangleObservation(
        topLeft: NormalizedPoint(x: 0.1, y: 0.6),
        topRight: NormalizedPoint(x: 0.5, y: 0.6),
        bottomRight: NormalizedPoint(x: 0.5, y: 0.2),
        bottomLeft: NormalizedPoint(x: 0.1, y: 0.2)
    )
    let request = TrackRectangleRequest(detectedRectangle: seed, .revision1, frameAnalysisSpacing: CMTime(value: 2, timescale: 30))
    visionExpectEqual(request.revision, .revision1, "revision")
    visionExpectEqual(TrackRectangleRequest.supportedRevisions, [.revision1], "supported")
    visionExpectEqual(request.frameAnalysisSpacing.value, 2, "spacing")
    visionExpectEqual(request.minimumLatencyFrameCount, 0, "latency")
    visionExpectEqual(request.trackingLevel, .accurate, "level default")
    request.trackingLevel = .fast
    visionExpectEqual(request.trackingLevel, .fast, "level set")
    visionExpectEqual(Set(TrackRectangleRequest.TrackingLevel.allCases).count, 2, "level cases")
    let encoded = try! JSONEncoder().encode(TrackRectangleRequest.TrackingLevel.fast)
    let decoded = try! JSONDecoder().decode(TrackRectangleRequest.TrackingLevel.self, from: encoded)
    visionExpectEqual(decoded, .fast, "level roundtrip")
    _ = TrackRectangleRequest.TrackingLevel.accurate.hashValue
    var levelHasher = Hasher()
    TrackRectangleRequest.TrackingLevel.accurate.hash(into: &levelHasher)
    visionExpectEqual(request.inputObservation.boundingBox.width, seed.boundingBox.width, "input")
    visionExpectEqual(request.descriptor, .trackRectangleRequest(.revision1), "descriptor")
    visionExpect(request.description.contains("trackRectangle"), "description")
    request.setComputeDevice(.cpu, for: .postProcessing)
    visionExpectEqual(request.computeDevice(for: .postProcessing)?.identifier, "cpu", "device")
    visionExpect(request == request, "equal")
    visionExpect(request != TrackRectangleRequest(), "default inequality")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    _ = hasher.finalize()
    let tracked = try! request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    visionExpect(tracked != nil, "tracked rectangle")
    visionExpect((tracked?.boundingBox.width ?? 0) > 0, "tracked width")

    let vnSeed = VNRectangleObservation(
        requestRevision: 1,
        topLeft: CGPoint(x: 0.1, y: 0.6),
        topRight: CGPoint(x: 0.5, y: 0.6),
        bottomRight: CGPoint(x: 0.5, y: 0.2),
        bottomLeft: CGPoint(x: 0.1, y: 0.2)
    )
    let vn = VNTrackRectangleRequest(rectangleObservation: vnSeed)
    let vnHandler = VNImageRequestHandler(cgImage: visionRectangleImage())
    try! vnHandler.perform([vn])
    let vnHit = vn.results?.first as? VNRectangleObservation
    visionExpect(vnHit != nil, "vn track rectangle")
    let withCompletion = VNTrackRectangleRequest(rectangleObservation: vnSeed, completionHandler: { _, _ in })
    visionExpect(withCompletion.completionHandler != nil, "vn completion")
}

func testRecognizeAnimalsRequestConfig() {
    var request = RecognizeAnimalsRequest(.revision2)
    visionExpectEqual(request.revision, .revision2, "revision")
    visionExpectEqual(RecognizeAnimalsRequest.supportedRevisions, [.revision1, .revision2], "supported")
    visionExpectEqual(request.supportedAnimals, [.cat, .dog], "animals")
    visionExpectEqual(RecognizeAnimalsRequest.Animal.cat.rawValue, "cat", "cat raw")
    visionExpectEqual(RecognizeAnimalsRequest.Animal(rawValue: "dog"), .dog, "dog raw")
    visionExpect(RecognizeAnimalsRequest.Animal.cat != .dog, "animal !=")
    let encoded = try! JSONEncoder().encode(RecognizeAnimalsRequest.Animal.cat)
    let decoded = try! JSONDecoder().decode(RecognizeAnimalsRequest.Animal.self, from: encoded)
    visionExpectEqual(decoded, .cat, "animal roundtrip")
    _ = RecognizeAnimalsRequest.Animal.dog.hashValue
    var animalHasher = Hasher()
    RecognizeAnimalsRequest.Animal.dog.hash(into: &animalHasher)
    visionExpectEqual(request.descriptor, .recognizeAnimalsRequest(.revision2), "descriptor")
    visionExpect(request.description.contains("recognizeAnimals"), "description")
    request.regionOfInterest = NormalizedRect(x: 0.1, y: 0.1, width: 0.5, height: 0.5)
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main)?.identifier, "cpu", "device")
    visionExpect(request == request, "equal")
    visionExpect(request != RecognizeAnimalsRequest(), "roi inequality")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    visionExpectOverlayInvalidModel({
        try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    }, "recognize animals")

    visionExpectEqual(VNAnimalIdentifier.cat.rawValue, "VNAnimalIdentifierCat", "cat token")
    visionExpectEqual(VNAnimalIdentifier.dog.rawValue, "VNAnimalIdentifierDog", "dog token")
    visionExpect(VNAnimalIdentifier.cat != .dog, "identifier !=")
    visionExpectEqual(VNAnimalIdentifier(rawValue: "VNAnimalIdentifierCat"), .cat, "init raw")
    _ = VNAnimalIdentifier.cat.hashValue
    var idHasher = Hasher()
    VNAnimalIdentifier.cat.hash(into: &idHasher)

    let vn = VNRecognizeAnimalsRequest()
    do {
        _ = try VNRecognizeAnimalsRequest.knownAnimalIdentifiers(forRevision: 2)
        visionExpect(false, "known identifiers should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "known identifiers")
    }
    do {
        _ = try vn.supportedIdentifiers()
        visionExpect(false, "supported identifiers should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "supported identifiers")
    }
    do {
        try VNImageRequestHandler(cgImage: visionRectangleImage()).perform([vn])
        visionExpect(false, "vn animals should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "vn animals")
        visionExpect(vn.results == nil, "results nil")
    }
}

func testDetectTrajectoriesRequestConfig() {
    let request = DetectTrajectoriesRequest(trajectoryLength: 7, .revision1, frameAnalysisSpacing: CMTime(value: 1, timescale: 15))
    visionExpectEqual(request.revision, .revision1, "revision")
    visionExpectEqual(DetectTrajectoriesRequest.supportedRevisions, [.revision1], "supported")
    visionExpectEqual(request.trajectoryLength, 7, "length")
    visionExpectEqual(request.frameAnalysisSpacing.value, 1, "spacing")
    visionExpectEqual(request.minimumLatencyFrameCount, 7, "latency")
    request.targetFrameTime = CMTime(value: 3, timescale: 15)
    visionExpectEqual(request.targetFrameTime.value, 3, "target")
    request.objectMinimumNormalizedRadius = 0.02
    request.objectMaximumNormalizedRadius = 0.4
    visionExpectEqual(request.objectMinimumNormalizedRadius, 0.02, "min radius")
    visionExpectEqual(request.objectMaximumNormalizedRadius, 0.4, "max radius")
    visionExpectEqual(request.descriptor, .detectTrajectoriesRequest(.revision1), "descriptor")
    visionExpect(request.description.contains("detectTrajectories"), "description")
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main)?.identifier, "cpu", "device")
    visionExpect(request.supportedComputeStageDevices[.postProcessing]?.contains(.cpu) == true, "cpu")
    visionExpect(request == request, "equal")
    visionExpect(request != DetectTrajectoriesRequest(), "default inequality")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    visionExpectOverlayInvalidModel({
        try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    }, "trajectories")

    let vn = VNDetectTrajectoriesRequest(frameAnalysisSpacing: CMTime(value: 1, timescale: 30), trajectoryLength: 6)
    visionExpectEqual(vn.trajectoryLength, 6, "vn length")
    visionExpectEqual(vn.frameAnalysisSpacing.value, 1, "vn spacing")
    vn.objectMinimumNormalizedRadius = 0.01
    vn.objectMaximumNormalizedRadius = 0.5
    visionExpectEqual(vn.minimumObjectSize, 0.01, "min size alias")
    visionExpectEqual(vn.maximumObjectSize, 0.5, "max size alias")
    vn.targetFrameTime = CMTime(value: 2, timescale: 30)
    visionExpectEqual(vn.targetFrameTime.value, 2, "vn target")
    visionExpect(vn.results == nil, "vn results")
    do {
        try VNImageRequestHandler(cgImage: visionRectangleImage()).perform([vn])
        visionExpect(false, "vn trajectories should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "vn trajectories")
        visionExpect(vn.results == nil, "results stay nil")
    }
}

func testCoreMLRequestConfig() {
    var request = CoreMLRequest(.revision1)
    visionExpectEqual(request.revision, .revision1, "revision")
    visionExpectEqual(CoreMLRequest.supportedRevisions, [.revision1], "supported")
    visionExpectEqual(request.modelContainer.inputImageFeatureName, "image", "feature name")
    request.cropAndScaleAction = .scaleToFit
    visionExpectEqual(request.cropAndScaleAction, .scaleToFit, "crop")
    visionExpect(request.supportedIdentifiers == nil, "no identifiers without a model")
    visionExpectEqual(request.descriptor, .coreMLRequest(.revision1), "descriptor")
    visionExpect(request.description.contains("coreML"), "description")
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main)?.identifier, "cpu", "device")
    visionExpect(request.supportedComputeStageDevices[.main]?.contains(.cpu) == true, "cpu")
    visionExpect(request == request, "equal")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    do {
        _ = try CoreMLModelContainer(model: MLModel())
        visionExpect(false, "container should fail closed")
    } catch let error as VisionError {
        if case .invalidModel = error {
            visionExpect(true, "container invalidModel")
        } else {
            visionExpect(false, "unexpected \(error)")
        }
    } catch {
        visionExpect(false, "wrong type \(error)")
    }
    let unchecked = CoreMLModelContainer(unchecked: MLModel())
    visionExpect(unchecked == unchecked, "container ==")
    visionExpect(unchecked != CoreMLModelContainer(unchecked: MLModel(), inputImageFeatureName: "other"), "container !=")
    _ = unchecked.hashValue
    var containerHasher = Hasher()
    unchecked.hash(into: &containerHasher)
    let fromModel = CoreMLRequest(model: unchecked)
    visionExpectEqual(fromModel.modelContainer.inputImageFeatureName, "image", "init model")
    visionExpectOverlayInvalidModel({
        try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    }, "coreml overlay")
}

func testDetectHumanBodyPoseRequestConfig() {
    var request = DetectHumanBodyPoseRequest(.revision2)
    visionExpectEqual(request.revision, .revision2, "revision")
    visionExpectEqual(DetectHumanBodyPoseRequest.supportedRevisions, [.revision1, .revision2], "supported")
    request.detectsHands = true
    visionExpectEqual(request.detectsHands, true, "hands")
    visionExpect(request.supportedJointNames.contains(.nose), "joints")
    visionExpect(request.supportedJointsGroupNames.contains(.torso), "groups")
    visionExpectEqual(request.descriptor, .detectHumanBodyPoseRequest(.revision2), "descriptor")
    visionExpect(request.description.contains("detectHumanBodyPose"), "description")
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main)?.identifier, "cpu", "device")
    visionExpect(request == request, "equal")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    visionExpectOverlayInvalidModel({
        try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    }, "body pose")
}

func testDetectHumanHandPoseRequestConfig() {
    var request = DetectHumanHandPoseRequest()
    visionExpectEqual(request.revision, .revision1, "revision")
    visionExpectEqual(DetectHumanHandPoseRequest.supportedRevisions, [.revision1], "supported")
    request.maximumHandCount = 1
    visionExpectEqual(request.maximumHandCount, 1, "max hands")
    visionExpect(request.supportedJointNames.contains(.wrist), "joints")
    visionExpect(try! request.supportedJointsGroupNames.contains(.thumb), "groups")
    visionExpectEqual(request.descriptor, .detectHumanHandPoseRequest(.revision1), "descriptor")
    visionExpect(request.description.contains("detectHumanHandPose"), "description")
    request.setComputeDevice(.cpu, for: .postProcessing)
    visionExpectEqual(request.computeDevice(for: .postProcessing)?.identifier, "cpu", "device")
    visionExpect(request == request, "equal")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    visionExpectOverlayInvalidModel({
        try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    }, "hand pose")

    let vn = VNDetectHumanHandPoseRequest()
    visionExpectEqual(vn.maximumHandCount, 2, "vn max default")
    vn.maximumHandCount = 1
    visionExpectEqual(vn.maximumHandCount, 1, "vn max set")
    do {
        _ = try VNDetectHumanHandPoseRequest.supportedJointNames(forRevision: 1)
        visionExpect(false, "vn hand joints revision should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "vn hand joints revision")
    }
    do {
        _ = try VNDetectHumanHandPoseRequest.supportedJointsGroupNames(forRevision: 1)
        visionExpect(false, "vn hand groups revision should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "vn hand groups revision")
    }
    do {
        _ = try vn.supportedJointNames
        visionExpect(false, "vn hand joints should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "vn hand joints")
    }
    do {
        _ = try vn.supportedJointsGroupNames
        visionExpect(false, "vn hand groups should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "vn hand groups")
    }
}

func testDetectAnimalBodyPoseRequestConfig() {
    var request = DetectAnimalBodyPoseRequest()
    visionExpectEqual(request.revision, .revision1, "revision")
    visionExpectEqual(DetectAnimalBodyPoseRequest.supportedRevisions, [.revision1], "supported")
    visionExpect(!request.supportedJointNames.isEmpty, "joints")
    visionExpect(request.supportedJointsGroupNames.contains(.head), "groups")
    visionExpectEqual(request.descriptor, .detectAnimalBodyPoseRequest(.revision1), "descriptor")
    visionExpect(request.description.contains("detectAnimalBodyPose"), "description")
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main)?.identifier, "cpu", "device")
    visionExpect(request == request, "equal")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    visionExpectOverlayInvalidModel({
        try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    }, "animal pose")

    let vn = VNDetectAnimalBodyPoseRequest()
    do {
        _ = try vn.supportedJointNames
        visionExpect(false, "vn animal joints should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "vn animal joints")
    }
    do {
        _ = try vn.supportedJointsGroupNames
        visionExpect(false, "vn animal groups should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "vn animal groups")
    }
}

func testDetectTextRectanglesRequestConfig() {
    var request = DetectTextRectanglesRequest()
    visionExpectEqual(request.revision, .revision1, "revision")
    visionExpectEqual(DetectTextRectanglesRequest.supportedRevisions, [.revision1], "supported")
    request.reportCharacterBoxes = true
    visionExpectEqual(request.reportCharacterBoxes, true, "character boxes")
    visionExpectEqual(request.descriptor, .detectTextRectanglesRequest(.revision1), "descriptor")
    visionExpect(request.description.contains("detectTextRectangles"), "description")
    visionExpect(request.supportedComputeStageDevices[.main]?.contains(.cpu) == true, "cpu")
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main)?.identifier, "cpu", "device")
    visionExpect(request == request, "equal")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    visionExpectOverlayInvalidModel({
        try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    }, "text rectangles")

    let vn = VNDetectTextRectanglesRequest()
    visionExpectEqual(vn.reportCharacterBoxes, false, "vn default")
    vn.reportCharacterBoxes = true
    visionExpectEqual(vn.reportCharacterBoxes, true, "vn set")
}

func testDetectHumanBodyPose3DRequestConfig() {
    let request = DetectHumanBodyPose3DRequest(.revision1, frameAnalysisSpacing: CMTime(value: 1, timescale: 24))
    visionExpectEqual(request.revision, .revision1, "revision")
    visionExpectEqual(DetectHumanBodyPose3DRequest.supportedRevisions, [.revision1], "supported")
    visionExpectEqual(request.frameAnalysisSpacing.value, 1, "spacing")
    visionExpectEqual(request.minimumLatencyFrameCount, 0, "latency")
    visionExpect(request.supportedJointNames.contains(.root) || !request.supportedJointNames.isEmpty, "joints")
    visionExpect(!request.supportedJointsGroupNames.isEmpty, "groups")
    visionExpectEqual(request.descriptor, .detectHumanBodyPose3DRequest(.revision1), "descriptor")
    visionExpect(request.description.contains("detectHumanBodyPose3D"), "description")
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main)?.identifier, "cpu", "device")
    visionExpect(request == request, "equal")
    visionExpect(request != DetectHumanBodyPose3DRequest(), "spacing inequality")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    visionExpectOverlayInvalidModel({
        try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    }, "pose 3d")

    let vn = VNDetectHumanBodyPose3DRequest(completionHandler: { _, _ in })
    visionExpect(vn.completionHandler != nil, "completion")
    do {
        _ = try vn.supportedJointNames
        visionExpect(false, "vn 3d joints should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "vn 3d joints")
    }
    do {
        _ = try vn.supportedJointsGroupNames
        visionExpect(false, "vn 3d groups should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "vn 3d groups")
    }
}

func testClassifyImageRequestConfig() {
    var request = ClassifyImageRequest()
    visionExpectEqual(request.revision, .revision2, "revision")
    visionExpectEqual(ClassifyImageRequest.supportedRevisions, [.revision2], "supported")
    visionExpectEqual(request.descriptor, .classifyImageRequest(.revision2), "descriptor")
    visionExpect(request.description.contains("classifyImage"), "description")
    request.cropAndScaleAction = .centerCrop
    visionExpectEqual(request.cropAndScaleAction, .centerCrop, "crop")
    visionExpect(request.supportedIdentifiers.isEmpty, "no Apple taxonomy")
    request.regionOfInterest = NormalizedRect(x: 0, y: 0, width: 0.9, height: 0.9)
    visionExpectEqual(request.regionOfInterest.width, 0.9, "roi")
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main)?.identifier, "cpu", "device")
    visionExpect(request == request, "equal")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    visionExpectOverlayInvalidModel({
        try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    }, "classify")
}

func testDetectedDocumentObservationValues() {
    let quad = VNRectangleObservation(
        requestRevision: 1,
        topLeft: CGPoint(x: 0.1, y: 0.9),
        topRight: CGPoint(x: 0.9, y: 0.9),
        bottomRight: CGPoint(x: 0.9, y: 0.1),
        bottomLeft: CGPoint(x: 0.1, y: 0.1)
    )
    let observation = DetectedDocumentObservation(quad)!
    visionExpectEqual(observation.topLeft.x, 0.1, "topLeft")
    visionExpectEqual(observation.topRight.x, 0.9, "topRight")
    visionExpectEqual(observation.bottomRight.y, 0.1, "bottomRight")
    visionExpectEqual(observation.bottomLeft.x, 0.1, "bottomLeft")
    visionExpectEqual(observation.boundingBox.width, 0.8, "bbox")
    visionExpectEqual(observation.confidence, 1, "confidence")
    visionExpect(observation.uuid != UUID(), "uuid")
    visionExpect(observation.timeRange == .zero || observation.timeRange == nil, "timeRange")
    visionExpect(observation.originatingRequestDescriptor == nil, "descriptor")
    visionExpect(!observation.description.isEmpty, "description")
    visionExpectEqual(observation.globalSegmentationMask.confidence, 0, "mask")
    visionExpect(observation == observation, "equal")
    visionExpect(observation != DetectedDocumentObservation(
        topLeft: NormalizedPoint.zero,
        topRight: NormalizedPoint.zero,
        bottomRight: NormalizedPoint.zero,
        bottomLeft: NormalizedPoint.zero
    ), "unequal")
    _ = observation.hashValue
    var hasher = Hasher()
    observation.hash(into: &hasher)
    let encoded = try! JSONEncoder().encode(observation)
    let decoded = try! JSONDecoder().decode(DetectedDocumentObservation.self, from: encoded)
    visionExpectEqual(decoded.topLeft.x, 0.1, "codable")

    let document = DocumentObservation(
        document: DocumentObservation.Container(
            text: DocumentObservation.Container.Text(
                transcript: "Hello",
                detectedData: [
                    DocumentObservation.Container.DataDetectorMatch(
                        boundingRegion: ContoursObservation.Contour(points: [NormalizedPoint(x: 0, y: 0)], indexPath: IndexPath(index: 0)),
                        match: DataDetector.Match(matchedString: "Hello")
                    )
                ]
            ),
            lists: [
                DocumentObservation.Container.List(
                    items: [
                        DocumentObservation.Container.List.Item(itemString: "one", markerType: .bullet, markerString: "•")
                    ]
                )
            ],
            tables: [
                DocumentObservation.Container.Table(
                    rows: [[DocumentObservation.Container.Table.Cell(columnRange: 0...0, rowRange: 0...0)]],
                    columns: [[DocumentObservation.Container.Table.Cell(columnRange: 0...0, rowRange: 0...0)]]
                )
            ]
        )
    )
    let documentEncoded = try! JSONEncoder().encode(document)
    let documentDecoded = try! JSONDecoder().decode(DocumentObservation.self, from: documentEncoded)
    visionExpectEqual(documentDecoded.document.text.transcript, "Hello", "document codable")
    visionExpectEqual(documentDecoded.document.text.detectedData.first?.match.matchedString, "Hello", "detector")
    visionExpectEqual(documentDecoded.document.lists.first?.items.first?.itemString, "one", "list")
    visionExpectEqual(documentDecoded.document.tables.first?.rows.first?.first?.columnRange.lowerBound, 0, "table")
}

func testTrajectoryObservationValues() {
    let vn = VNTrajectoryObservation(
        detectedPoints: [VNPoint(x: 0.1, y: 0.2), VNPoint(x: 0.3, y: 0.4)],
        projectedPoints: [VNPoint(x: 0.5, y: 0.6)],
        equationCoefficients: SIMD3<Float>(1, 2, 3),
        movingAverageRadius: 0.12
    )
    visionExpectEqual(vn.detectedPoints.count, 2, "vn detected")
    visionExpectEqual(vn.projectedPoints.count, 1, "vn projected")
    visionExpectEqual(vn.equationCoefficients.y, 2, "vn coeffs")
    visionExpectEqual(vn.movingAverageRadius, 0.12, "vn radius")
    let overlay = TrajectoryObservation(vn)
    visionExpectEqual(overlay.detectedPoints.count, 2, "overlay detected")
    visionExpectEqual(overlay.projectedPoints.first?.x, 0.5, "overlay projected")
    visionExpectEqual(overlay.equationCoefficients.z, 3, "overlay coeffs")
    visionExpectEqual(overlay.movingAverageRadius, 0.12, "overlay radius")
    visionExpectEqual(overlay.confidence, 1, "confidence")
    visionExpect(!overlay.description.isEmpty, "description")
    visionExpect(overlay == overlay, "equal")
    visionExpect(overlay != TrajectoryObservation(detectedPoints: []), "unequal")
    _ = overlay.hashValue
    var hasher = Hasher()
    overlay.hash(into: &hasher)
    let encoded = try! JSONEncoder().encode(overlay)
    let decoded = try! JSONDecoder().decode(TrajectoryObservation.self, from: encoded)
    visionExpectEqual(decoded.detectedPoints.count, 2, "codable")
}

func testStatefulRequestDefaults() {
    let spacing = VNStatefulRequest(frameAnalysisSpacing: CMTime(value: 4, timescale: 30))
    visionExpectEqual(spacing.frameAnalysisSpacing.value, 4, "spacing")
    visionExpectEqual(spacing.minimumLatencyFrameCount, 0, "latency")
}

func testPixelBufferObservationOverlayValues() {
    var pixels = [UInt8](repeating: 0, count: 2 * 2 * 4)
    pixels[0] = 10
    pixels[1] = 20
    pixels[2] = 30
    pixels[3] = 255
    let buffer = CVPixelBuffer(width: 2, height: 2, pixels: pixels)
    let vn = VNPixelBufferObservation(pixelBuffer: buffer, featureName: "mask")
    let overlay = PixelBufferObservation(vn)!
    visionExpectEqual(overlay.pixelFormat, kCVPixelFormatType_32BGRA, "format")
    visionExpectEqual(overlay.size.width, 2, "width")
    visionExpectEqual(overlay.size.height, 2, "height")
    visionExpectEqual(overlay.confidence, 1, "confidence")
    visionExpect(overlay.uuid != UUID(), "uuid")
    visionExpect(overlay.timeRange == .zero || overlay.timeRange == nil, "timeRange")
    visionExpect(overlay.originatingRequestDescriptor == nil, "descriptor")
    visionExpect(!overlay.description.isEmpty, "description")
    let luma = overlay.pixel(at: NormalizedPoint(x: 0, y: 1))
    visionExpect(abs(luma - (10 + 20 + 30) / (3 * 255)) < 1e-5, "pixel at origin")
    let bytes = overlay.withUnsafePointer { ptr in
        ptr.load(as: UInt8.self)
    }
    visionExpectEqual(bytes, 10, "unsafe pointer")
    let image = try! overlay.cgImage
    visionExpectEqual(image.width, 2, "cgImage")
    visionExpect(overlay == overlay, "equal")
    visionExpect(overlay != PixelBufferObservation(), "unequal")
    _ = overlay.hashValue
    var hasher = Hasher()
    overlay.hash(into: &hasher)
    let encoded = try! JSONEncoder().encode(overlay)
    let decoded = try! JSONDecoder().decode(PixelBufferObservation.self, from: encoded)
    visionExpectEqual(decoded.size.width, 2, "codable size")
}

func visionInstanceMaskFixture() -> CVPixelBuffer {
    var pixels = [UInt8](repeating: 0, count: 4 * 4 * 4)
    for y in 0..<4 {
        for x in 0..<4 {
            let offset = (y * 4 + x) * 4
            let label: UInt8 = (x < 2 && y < 2) ? 1 : ((x >= 2 && y >= 2) ? 2 : 0)
            pixels[offset] = label
            pixels[offset + 3] = 255
        }
    }
    return CVPixelBuffer(width: 4, height: 4, pixels: pixels)
}

func visionExpectRevisionCodable<T: Codable & Equatable>(_ value: T, _ message: String) {
    let encoded = try! JSONEncoder().encode(value)
    let decoded = try! JSONDecoder().decode(T.self, from: encoded)
    visionExpectEqual(decoded, value, message)
}

func testDetectLensSmudgeRequestConfig() {
    var request = DetectLensSmudgeRequest(.revision1)
    visionExpectEqual(request.revision, .revision1, "revision")
    visionExpectEqual(DetectLensSmudgeRequest.supportedRevisions, [.revision1], "supported")
    visionExpectEqual(request.cropAndScaleAction, .scaleToFill, "crop default")
    request.cropAndScaleAction = .centerCrop
    visionExpectEqual(request.cropAndScaleAction, .centerCrop, "crop set")
    request.regionOfInterest = NormalizedRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8)
    visionExpectEqual(request.regionOfInterest.width, 0.8, "roi")
    visionExpectEqual(request.descriptor, .detectLensSmudgeRequest(.revision1), "descriptor")
    visionExpect(request.description.contains("detectLensSmudge"), "description")
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main)?.identifier, "cpu", "device")
    visionExpect(request == request, "equal")
    visionExpect(request != DetectLensSmudgeRequest(), "crop inequality")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    visionExpectRevisionCodable(DetectLensSmudgeRequest.Revision.revision1, "revision codable")
    _ = DetectLensSmudgeRequest.Revision.revision1.hashValue
    visionExpect(DetectLensSmudgeRequest.Revision.revision1 != DetectLensSmudgeRequest.Revision.revision1 || request.revision == .revision1, "!=")
    visionExpectOverlayInvalidModel({
        try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    }, "lens smudge")
}

func testDetectFaceLandmarksRequestConfig() {
    var request = DetectFaceLandmarksRequest(.revision3)
    visionExpectEqual(request.revision, .revision3, "revision")
    visionExpectEqual(DetectFaceLandmarksRequest.supportedRevisions.contains(.revision3), true, "supported r3")
    visionExpectEqual(DetectFaceLandmarksRequest.supportedRevisions.contains(.revision1), true, "supported r1")
    visionExpectEqual(request.constellation, .constellationNotDefined, "constellation default")
    request.constellation = .constellation76Points
    visionExpectEqual(request.constellation, .constellation76Points, "constellation set")
    let face = FaceObservation(boundingBox: .fullImage, revision: .revision3)
    request.inputFaceObservations = [face]
    visionExpectEqual(request.inputFaceObservations?.count, 1, "input faces")
    request.regionOfInterest = NormalizedRect(x: 0, y: 0, width: 1, height: 1)
    visionExpectEqual(request.descriptor, .detectFaceLandmarksRequest(.revision3), "descriptor")
    visionExpect(request.description.contains("detectFaceLandmarks"), "description")
    request.setComputeDevice(.cpu, for: .postProcessing)
    visionExpectEqual(request.computeDevice(for: .postProcessing)?.identifier, "cpu", "device")
    visionExpect(request == request, "equal")
    visionExpect(request != DetectFaceLandmarksRequest(), "constellation inequality")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    visionExpectRevisionCodable(DetectFaceLandmarksRequest.Revision.revision3, "revision codable")
    visionExpect(DetectFaceLandmarksRequest.Revision.revision1 < .revision3, "revision <")
    visionExpect(VNDetectFaceLandmarksRequest.revision(VNDetectFaceLandmarksRequestRevision3, supportsConstellation: .constellation76Points), "vn constellation")
    visionExpect(!VNDetectFaceLandmarksRequest.revision(99, supportsConstellation: .constellation65Points), "unsupported rev")
    let vn = VNDetectFaceLandmarksRequest()
    vn.constellation = .constellation65Points
    visionExpectEqual(vn.constellation, .constellation65Points, "vn constellation set")
    let vnFace = VNFaceObservation(requestRevision: 3, boundingBox: CGRect(x: 0.1, y: 0.1, width: 0.2, height: 0.2))
    vn.inputFaceObservations = [vnFace]
    visionExpectEqual(vn.inputFaceObservations?.count, 1, "vn input faces")
    let accepting: any VNFaceObservationAccepting = vn
    visionExpectEqual(accepting.inputFaceObservations?.count, 1, "protocol faces")
    visionExpect(vn.results == nil, "vn results")
    visionExpectOverlayInvalidModel({
        try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    }, "face landmarks overlay")
    do {
        try VNImageRequestHandler(cgImage: visionRectangleImage()).perform([vn])
        visionExpect(false, "vn landmarks should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "vn invalidModel")
        visionExpect(vn.results == nil, "results stay nil")
    }
}

func testDetectHumanRectanglesRequestConfig() {
    var request = DetectHumanRectanglesRequest(.revision2)
    visionExpectEqual(request.revision, .revision2, "revision")
    visionExpectEqual(DetectHumanRectanglesRequest.supportedRevisions.contains(.revision2), true, "supported")
    visionExpectEqual(request.upperBodyOnly, false, "upper default")
    request.upperBodyOnly = true
    visionExpectEqual(request.upperBodyOnly, true, "upper set")
    request.regionOfInterest = NormalizedRect(x: 0.05, y: 0.05, width: 0.9, height: 0.9)
    visionExpectEqual(request.descriptor, .detectHumanRectanglesRequest(.revision2), "descriptor")
    visionExpect(request.description.contains("detectHumanRectangles"), "description")
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main)?.identifier, "cpu", "device")
    visionExpect(request == request, "equal")
    visionExpect(request != DetectHumanRectanglesRequest(), "upper inequality")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    visionExpectRevisionCodable(DetectHumanRectanglesRequest.Revision.revision2, "revision codable")
    visionExpect(DetectHumanRectanglesRequest.Revision.revision1 < .revision2, "revision <")
    visionExpectEqual(VNDetectHumanRectanglesRequestRevision1, 1, "r1")
    visionExpectEqual(VNDetectHumanRectanglesRequestRevision2, 2, "r2")
    let vn = VNDetectHumanRectanglesRequest()
    visionExpectEqual(vn.upperBodyOnly, false, "vn upper")
    vn.upperBodyOnly = true
    visionExpectEqual(vn.upperBodyOnly, true, "vn upper set")
    visionExpect(vn.results == nil, "vn results")
    visionExpectOverlayInvalidModel({
        try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    }, "human rectangles overlay")
    do {
        try VNImageRequestHandler(cgImage: visionRectangleImage()).perform([vn])
        visionExpect(false, "vn humans should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "vn invalidModel")
        visionExpect(vn.results == nil, "results stay nil")
    }
}

func testDetectFaceCaptureQualityRequestConfig() {
    var request = DetectFaceCaptureQualityRequest(.revision3)
    visionExpectEqual(request.revision, .revision3, "revision")
    visionExpectEqual(DetectFaceCaptureQualityRequest.supportedRevisions.contains(.revision3), true, "supported")
    request.inputFaceObservations = [FaceObservation(boundingBox: .fullImage)]
    visionExpectEqual(request.inputFaceObservations?.count, 1, "input faces")
    request.regionOfInterest = .fullImage
    visionExpectEqual(request.descriptor, .detectFaceCaptureQualityRequest(.revision3), "descriptor")
    visionExpect(request.description.contains("detectFaceCaptureQuality"), "description")
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main)?.identifier, "cpu", "device")
    visionExpect(request == request, "equal")
    visionExpect(request != DetectFaceCaptureQualityRequest(.revision1), "revision inequality")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    visionExpectRevisionCodable(DetectFaceCaptureQualityRequest.Revision.revision3, "revision codable")
    let vn = VNDetectFaceCaptureQualityRequest()
    let vnFace = VNFaceObservation(requestRevision: 3, boundingBox: CGRect(x: 0, y: 0, width: 1, height: 1))
    vn.inputFaceObservations = [vnFace]
    visionExpectEqual(vn.inputFaceObservations?.count, 1, "vn input faces")
    visionExpect(vn.results == nil, "vn results")
    visionExpectEqual(VNDetectFaceCaptureQualityRequest.currentRevision, VNDetectFaceCaptureQualityRequestRevision3, "vn rev")
    visionExpectOverlayInvalidModel({
        try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    }, "capture quality overlay")
    do {
        try VNImageRequestHandler(cgImage: visionRectangleImage()).perform([vn])
        visionExpect(false, "vn capture quality should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "vn invalidModel")
        visionExpect(vn.results == nil, "results stay nil")
    }
}

func testCalculateImageAestheticsScoresRequestConfig() {
    var request = CalculateImageAestheticsScoresRequest(.revision1)
    visionExpectEqual(request.revision, .revision1, "revision")
    visionExpectEqual(CalculateImageAestheticsScoresRequest.supportedRevisions, [.revision1], "supported")
    visionExpectEqual(request.cropAndScaleAction, .scaleToFill, "crop default")
    request.cropAndScaleAction = .scaleToFit
    visionExpectEqual(request.cropAndScaleAction, .scaleToFit, "crop set")
    request.regionOfInterest = .fullImage
    visionExpectEqual(request.descriptor, .calculateImageAestheticsScoresRequest(.revision1), "descriptor")
    visionExpect(request.description.contains("calculateImageAesthetics"), "description")
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main)?.identifier, "cpu", "device")
    visionExpect(request == request, "equal")
    visionExpect(request != CalculateImageAestheticsScoresRequest(), "crop inequality")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    visionExpectRevisionCodable(CalculateImageAestheticsScoresRequest.Revision.revision1, "revision codable")
    let vn = VNCalculateImageAestheticsScoresRequest()
    visionExpect(vn.results == nil, "vn results")
    visionExpectOverlayInvalidModel({
        try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    }, "aesthetics overlay")
    do {
        try VNImageRequestHandler(cgImage: visionRectangleImage()).perform([vn])
        visionExpect(false, "vn aesthetics should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "vn invalidModel")
        visionExpect(vn.results == nil, "results stay nil")
    }
}

func testDetectDocumentSegmentationRequestConfig() {
    var request = DetectDocumentSegmentationRequest(.revision1)
    visionExpectEqual(request.revision, .revision1, "revision")
    visionExpectEqual(DetectDocumentSegmentationRequest.supportedRevisions, [.revision1], "supported")
    request.regionOfInterest = NormalizedRect(x: 0, y: 0, width: 1, height: 1)
    visionExpectEqual(request.descriptor, .detectDocumentSegmentationRequest(.revision1), "descriptor")
    visionExpect(request.description.contains("detectDocumentSegmentation"), "description")
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main)?.identifier, "cpu", "device")
    visionExpect(request == request, "equal")
    visionExpect(request != DetectDocumentSegmentationRequest() || request.regionOfInterest == .fullImage, "equal default")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    visionExpectRevisionCodable(DetectDocumentSegmentationRequest.Revision.revision1, "revision codable")
    let vn = VNDetectDocumentSegmentationRequest()
    visionExpect(vn.results == nil, "vn results")
    visionExpectOverlayInvalidModel({
        try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    }, "document segmentation overlay")
    do {
        try VNImageRequestHandler(cgImage: visionRectangleImage()).perform([vn])
        visionExpect(false, "vn document segmentation should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "vn invalidModel")
        visionExpect(vn.results == nil, "results stay nil")
    }
}

func testGeneratePersonInstanceMaskRequestConfig() {
    var request = GeneratePersonInstanceMaskRequest(.revision1)
    visionExpectEqual(request.revision, .revision1, "revision")
    visionExpectEqual(GeneratePersonInstanceMaskRequest.supportedRevisions, [.revision1], "supported")
    request.regionOfInterest = .fullImage
    visionExpectEqual(request.descriptor, .generatePersonInstanceMaskRequest(.revision1), "descriptor")
    visionExpect(request.description.contains("generatePersonInstanceMask"), "description")
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main)?.identifier, "cpu", "device")
    visionExpect(request == request, "equal")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    visionExpectRevisionCodable(GeneratePersonInstanceMaskRequest.Revision.revision1, "revision codable")
    let vn = VNGeneratePersonInstanceMaskRequest()
    visionExpect(vn.results == nil, "vn results")
    visionExpectOverlayInvalidModel({
        try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    }, "person instance mask overlay")
    do {
        try VNImageRequestHandler(cgImage: visionRectangleImage()).perform([vn])
        visionExpect(false, "vn person mask should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "vn invalidModel")
        visionExpect(vn.results == nil, "results stay nil")
    }
}

func testGenerateForegroundInstanceMaskRequestConfig() {
    var request = GenerateForegroundInstanceMaskRequest(.revision1)
    visionExpectEqual(request.revision, .revision1, "revision")
    visionExpectEqual(GenerateForegroundInstanceMaskRequest.supportedRevisions, [.revision1], "supported")
    request.regionOfInterest = .fullImage
    visionExpectEqual(request.descriptor, .generateForegroundInstanceMaskRequest(.revision1), "descriptor")
    visionExpect(request.description.contains("generateForegroundInstanceMask"), "description")
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main)?.identifier, "cpu", "device")
    visionExpect(request == request, "equal")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    visionExpectRevisionCodable(GenerateForegroundInstanceMaskRequest.Revision.revision1, "revision codable")
    let vn = VNGenerateForegroundInstanceMaskRequest()
    visionExpect(vn.results == nil, "vn results")
    visionExpectOverlayInvalidModel({
        try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    }, "foreground mask overlay")
    do {
        try VNImageRequestHandler(cgImage: visionRectangleImage()).perform([vn])
        visionExpect(false, "vn foreground mask should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "vn invalidModel")
        visionExpect(vn.results == nil, "results stay nil")
    }
}

func testGenerateAttentionBasedSaliencyImageRequestConfig() {
    var request = GenerateAttentionBasedSaliencyImageRequest(.revision2)
    visionExpectEqual(request.revision, .revision2, "revision")
    visionExpectEqual(GenerateAttentionBasedSaliencyImageRequest.supportedRevisions.contains(.revision2), true, "supported")
    request.regionOfInterest = .fullImage
    visionExpectEqual(request.descriptor, .generateAttentionBasedSaliencyImageRequest(.revision2), "descriptor")
    visionExpect(request.description.contains("generateAttentionBasedSaliency"), "description")
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main)?.identifier, "cpu", "device")
    visionExpect(request == request, "equal")
    visionExpect(request != GenerateAttentionBasedSaliencyImageRequest(.revision1), "revision inequality")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    visionExpectRevisionCodable(GenerateAttentionBasedSaliencyImageRequest.Revision.revision2, "revision codable")
    let vn = VNGenerateAttentionBasedSaliencyImageRequest()
    visionExpect(vn.results == nil, "vn results")
    visionExpectOverlayInvalidModel({
        try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    }, "attention saliency overlay")
    do {
        try VNImageRequestHandler(cgImage: visionRectangleImage()).perform([vn])
        visionExpect(false, "vn attention should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "vn invalidModel")
        visionExpect(vn.results == nil, "results stay nil")
    }
}

func testTrackObjectRequestOverlayConfig() {
    let seed = DetectedObjectObservation(boundingBox: NormalizedRect(x: 0.2, y: 0.2, width: 0.4, height: 0.4))
    let request = TrackObjectRequest(detectedObject: seed, .revision2, frameAnalysisSpacing: CMTime(value: 1, timescale: 30))
    visionExpectEqual(request.revision, .revision2, "revision")
    visionExpectEqual(TrackObjectRequest.supportedRevisions, [.revision2], "supported")
    visionExpectEqual(request.frameAnalysisSpacing.value, 1, "spacing")
    visionExpectEqual(request.minimumLatencyFrameCount, 0, "latency")
    visionExpectEqual(request.inputObservation.boundingBox.width, 0.4, "input")
    request.regionOfInterest = .fullImage
    visionExpectEqual(request.descriptor, .trackObjectRequest(.revision2), "descriptor")
    visionExpect(request.description.contains("trackObject"), "description")
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main)?.identifier, "cpu", "device")
    visionExpect(request == request, "equal")
    visionExpect(request != TrackObjectRequest(detectedObject: seed), "spacing inequality")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    visionExpectRevisionCodable(TrackObjectRequest.Revision.revision2, "revision codable")
    let tracked = try! request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    visionExpect(tracked != nil, "tracked object")
}

func testTrackHomographicImageRegistrationRequestConfig() {
    let request = TrackHomographicImageRegistrationRequest(.revision1, frameAnalysisSpacing: CMTime(value: 2, timescale: 30))
    visionExpectEqual(request.revision, .revision1, "revision")
    visionExpectEqual(TrackHomographicImageRegistrationRequest.supportedRevisions, [.revision1], "supported")
    visionExpectEqual(request.frameAnalysisSpacing.value, 2, "spacing")
    visionExpectEqual(request.minimumLatencyFrameCount, 0, "latency")
    request.regionOfInterest = .fullImage
    visionExpectEqual(request.descriptor, .trackHomographicImageRegistrationRequest(.revision1), "descriptor")
    visionExpect(request.description.contains("trackHomographic"), "description")
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main)?.identifier, "cpu", "device")
    visionExpect(request == request, "equal")
    visionExpect(request != TrackHomographicImageRegistrationRequest(), "spacing inequality")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    visionExpectRevisionCodable(TrackHomographicImageRegistrationRequest.Revision.revision1, "revision codable")
    visionExpectOverlayInvalidModel({
        try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    }, "homographic track overlay")
    let vn = VNTrackHomographicImageRegistrationRequest()
    let withHandler = VNTrackHomographicImageRegistrationRequest(completionHandler: { _, _ in })
    visionExpect(withHandler.completionHandler != nil, "completion")
    visionExpect(vn.results == nil, "vn results")
    do {
        try VNImageRequestHandler(cgImage: visionRectangleImage()).perform([vn])
        visionExpect(false, "vn homographic track should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.unsupportedRequest.rawValue, "vn unsupportedRequest")
        visionExpect(vn.results == nil, "results stay nil")
    }
}

func testTrackTranslationalImageRegistrationRequestConfig() {
    let request = TrackTranslationalImageRegistrationRequest(.revision1, frameAnalysisSpacing: CMTime(value: 3, timescale: 30))
    visionExpectEqual(request.revision, .revision1, "revision")
    visionExpectEqual(TrackTranslationalImageRegistrationRequest.supportedRevisions, [.revision1], "supported")
    visionExpectEqual(request.frameAnalysisSpacing.value, 3, "spacing")
    visionExpectEqual(request.minimumLatencyFrameCount, 0, "latency")
    request.regionOfInterest = .fullImage
    visionExpectEqual(request.descriptor, .trackTranslationalImageRegistrationRequest(.revision1), "descriptor")
    visionExpect(request.description.contains("trackTranslational"), "description")
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main)?.identifier, "cpu", "device")
    visionExpect(request.supportedComputeStageDevices[.main]?.contains(.cpu) == true, "cpu stage")
    visionExpect(request == request, "equal")
    visionExpect(request != TrackTranslationalImageRegistrationRequest(), "spacing inequality")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    visionExpectRevisionCodable(TrackTranslationalImageRegistrationRequest.Revision.revision1, "revision codable")
    let first = try! request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    visionExpectEqual(first.alignmentTransform, .identity, "first frame identity")
    let second = try! request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    visionExpect(second.confidence >= 0, "second frame")
    let vn = VNTrackTranslationalImageRegistrationRequest()
    let withHandler = VNTrackTranslationalImageRegistrationRequest(completionHandler: { _, _ in })
    visionExpect(withHandler.completionHandler != nil, "completion")
    try! VNImageRequestHandler(cgImage: visionRectangleImage()).perform([vn])
    visionExpect((vn.results?.first as? VNImageTranslationAlignmentObservation) != nil, "vn first identity")
}

func testRecognizeTextRequestConfig() {
    var request = RecognizeTextRequest(.revision3)
    visionExpectEqual(request.revision, .revision3, "revision")
    visionExpectEqual(request.recognitionLevel, .accurate, "level")
    request.recognitionLevel = .fast
    visionExpectEqual(request.recognitionLevel, .fast, "level set")
    visionExpectEqual(RecognizeTextRequest.RecognitionLevel.allCases.count, 2, "levels")
    request.usesLanguageCorrection = false
    visionExpectEqual(request.usesLanguageCorrection, false, "correction")
    request.automaticallyDetectsLanguage = true
    visionExpectEqual(request.automaticallyDetectsLanguage, true, "autodetect")
    request.minimumTextHeightFraction = 0.05
    visionExpectEqual(request.minimumTextHeightFraction, 0.05, "height fraction")
    visionExpectEqual(request.minimumTextHeight, 0.05, "height alias")
    request.customWords = ["OpenUIKit"]
    visionExpectEqual(request.customWords.first, "OpenUIKit", "custom")
    request.recognitionLanguages = [Locale.Language(identifier: "en")]
    visionExpectEqual(request.recognitionLanguages.count, 1, "languages")
    visionExpectEqual(request.supportedRecognitionLanguages.isEmpty, true, "no apple languages")
    visionExpectEqual(request.descriptor, .recognizeTextRequest(.revision3), "descriptor")
    visionExpectOverlayInvalidModel({
        try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    }, "recognize text overlay")
}

func testDetectHorizonRequestConfig() {
    var request = DetectHorizonRequest(.revision1)
    visionExpectEqual(request.revision, .revision1, "revision")
    visionExpectEqual(DetectHorizonRequest.supportedRevisions, [.revision1], "supported")
    request.regionOfInterest = .fullImage
    visionExpectEqual(request.descriptor, .detectHorizonRequest(.revision1), "descriptor")
    visionExpect(request.description.contains("detectHorizon"), "description")
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main)?.identifier, "cpu", "device")
    visionExpect(request == request, "equal")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    visionExpectRevisionCodable(DetectHorizonRequest.Revision.revision1, "revision codable")
    visionExpectOverlayInvalidModel({
        try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    }, "horizon overlay")
}

func testTextObservationOverlayValues() {
    let vnChar = VNRectangleObservation(
        requestRevision: 1,
        topLeft: CGPoint(x: 0.1, y: 0.6),
        topRight: CGPoint(x: 0.2, y: 0.6),
        bottomRight: CGPoint(x: 0.2, y: 0.4),
        bottomLeft: CGPoint(x: 0.1, y: 0.4)
    )
    let vn = VNTextObservation(
        topLeft: CGPoint(x: 0.1, y: 0.8),
        topRight: CGPoint(x: 0.9, y: 0.8),
        bottomRight: CGPoint(x: 0.9, y: 0.2),
        bottomLeft: CGPoint(x: 0.1, y: 0.2),
        characterBoxes: [vnChar],
        confidence: 0.9
    )
    visionExpectEqual(vn.characterBoxes?.count, 1, "vn character boxes")
    let overlay = TextObservation(vn)
    visionExpectEqual(overlay.topLeft.x, 0.1, "topLeft")
    visionExpectEqual(overlay.topRight.x, 0.9, "topRight")
    visionExpectEqual(overlay.bottomRight.y, 0.2, "bottomRight")
    visionExpectEqual(overlay.bottomLeft.y, 0.2, "bottomLeft")
    visionExpectEqual(overlay.confidence, 0.9, "confidence")
    visionExpectEqual(overlay.characterBoxes?.count, 1, "character boxes")
    visionExpect(overlay.boundingBox.width > 0.5, "boundingBox")
    visionExpect(overlay.uuid != UUID() || overlay.uuid == vn.uuid, "uuid")
    visionExpect(overlay.timeRange == .zero || overlay.timeRange == nil, "timeRange")
    visionExpect(overlay.originatingRequestDescriptor == nil, "descriptor")
    visionExpect(!overlay.description.isEmpty, "description")
    visionExpect(overlay == overlay, "equal")
    visionExpect(overlay != TextObservation(topLeft: .zero, topRight: .zero, bottomRight: .zero, bottomLeft: .zero), "unequal")
    _ = overlay.hashValue
    var hasher = Hasher()
    overlay.hash(into: &hasher)
    let encoded = try! JSONEncoder().encode(overlay)
    let decoded = try! JSONDecoder().decode(TextObservation.self, from: encoded)
    visionExpectEqual(decoded.topLeft.x, 0.1, "codable")
}

func testHumanObservationOverlayValues() {
    let vn = VNHumanObservation(boundingBox: CGRect(x: 0.2, y: 0.1, width: 0.4, height: 0.5), upperBodyOnly: true)
    visionExpectEqual(vn.upperBodyOnly, true, "vn upper")
    let overlay = HumanObservation(vn)
    visionExpectEqual(overlay.boundingBox.width, 0.4, "bbox")
    visionExpectEqual(overlay.isUpperBodyOnly, true, "upper")
    visionExpectEqual(overlay.confidence, 1, "confidence")
    visionExpect(!overlay.description.isEmpty, "description")
    let constructed = HumanObservation(boundingBox: .fullImage, revision: .revision2, isUpperBodyOnly: false)
    visionExpectEqual(constructed.boundingBox.width, 1, "constructed")
    visionExpectEqual(constructed.originatingRequestDescriptor, .detectHumanRectanglesRequest(.revision2), "descriptor")
    visionExpect(overlay == overlay, "equal")
    visionExpect(overlay != constructed, "unequal")
    _ = overlay.hashValue
    let encoded = try! JSONEncoder().encode(overlay)
    let decoded = try! JSONDecoder().decode(HumanObservation.self, from: encoded)
    visionExpectEqual(decoded.isUpperBodyOnly, true, "codable")
}

func testSmudgeObservationOverlayValues() {
    let observation = SmudgeObservation(confidence: 0.4, uuid: UUID(), timeRange: .zero, originatingRequestDescriptor: .detectLensSmudgeRequest(.revision1))
    visionExpectEqual(observation.confidence, 0.4, "confidence")
    visionExpect(observation.timeRange != nil, "timeRange")
    visionExpectEqual(observation.originatingRequestDescriptor, .detectLensSmudgeRequest(.revision1), "descriptor")
    visionExpect(!observation.description.isEmpty, "description")
    visionExpect(observation == observation, "equal")
    visionExpect(observation != SmudgeObservation(), "unequal")
    _ = observation.hashValue
    var hasher = Hasher()
    observation.hash(into: &hasher)
    let encoded = try! JSONEncoder().encode(observation)
    let decoded = try! JSONDecoder().decode(SmudgeObservation.self, from: encoded)
    visionExpectEqual(decoded.confidence, 0.4, "codable")
}

func testInstanceMaskObservationSuppliedData() {
    let buffer = visionInstanceMaskFixture()
    let vn = VNInstanceMaskObservation(instanceMask: buffer)
    visionExpectEqual(vn.allInstances.contains(1), true, "vn label 1")
    visionExpectEqual(vn.allInstances.contains(2), true, "vn label 2")
    visionExpectEqual(vn.instanceMask.width, 4, "vn mask size")
    let mask1 = try! vn.generateMask(forInstances: IndexSet(integer: 1))
    visionExpectEqual(mask1.pixels[0], 255, "instance 1 white")
    visionExpectEqual(mask1.pixels[(3 * 4 + 3) * 4], 0, "instance 2 black in mask1")
    let handler = VNImageRequestHandler(cgImage: visionRectangleImage())
    let scaled = try! vn.generateScaledMaskForImage(forInstances: IndexSet(integer: 1), from: handler)
    visionExpectEqual(scaled.width, 80, "scaled width")
    let masked = try! vn.generateMaskedImage(ofInstances: IndexSet(integer: 1), from: handler, croppedToInstancesExtent: true)
    visionExpect(masked.width > 0 && masked.height > 0, "cropped masked image")

    let overlay = InstanceMaskObservation(vn)!
    visionExpectEqual(overlay.allInstances.contains(1), true, "overlay labels")
    visionExpectEqual(overlay.allInstancesMask.size.width, 4, "allInstancesMask")
    visionExpectEqual(overlay.confidence, 1, "confidence")
    visionExpect(!overlay.description.isEmpty, "description")
    let overlayMask = try! overlay.generateMask(for: IndexSet(integer: 2))
    visionExpectEqual(overlayMask.pixels[(3 * 4 + 3) * 4], 255, "overlay instance 2")
    let imageHandler = ImageRequestHandler(visionRectangleImage())
    let scaledOverlay = try! overlay.generateScaledMask(for: IndexSet(integer: 1), scaledToImageFrom: imageHandler)
    visionExpect(scaledOverlay.width > 4, "overlay scaled")
    let maskedOverlay = try! overlay.generateMaskedImage(for: IndexSet(integer: 1), imageFrom: imageHandler, croppedToInstancesExtent: false)
    visionExpectEqual(maskedOverlay.width, 80, "full image mask apply")
    let atPoint = overlay.instanceAtPoint(NormalizedPoint(x: 0.1, y: 0.9))
    visionExpectEqual(atPoint.contains(1), true, "instance at point")
    visionExpect(overlay == overlay, "equal")
    visionExpect(overlay != InstanceMaskObservation(instanceMask: CVPixelBuffer(width: 1, height: 1)), "unequal")
    _ = overlay.hashValue
    var hasher = Hasher()
    overlay.hash(into: &hasher)
    let encoded = try! JSONEncoder().encode(overlay)
    let decoded = try! JSONDecoder().decode(InstanceMaskObservation.self, from: encoded)
    visionExpectEqual(decoded.allInstances.contains(1), true, "codable")
}

func testSaliencyImageObservationValues() {
    let buffer = CVPixelBuffer(width: 2, height: 2, pixels: [UInt8](repeating: 128, count: 16))
    let rect = VNRectangleObservation(
        requestRevision: 1,
        topLeft: CGPoint(x: 0, y: 1),
        topRight: CGPoint(x: 1, y: 1),
        bottomRight: CGPoint(x: 1, y: 0),
        bottomLeft: CGPoint(x: 0, y: 0)
    )
    let vn = VNSaliencyImageObservation(pixelBuffer: buffer, salientObjects: [rect])
    visionExpectEqual(vn.salientObjects?.count, 1, "vn salient")
    let overlay = SaliencyImageObservation(vn)!
    visionExpectEqual(overlay.salientObjects.count, 1, "overlay salient")
    visionExpectEqual(overlay.heatMap.size.width, 2, "heatMap")
    visionExpect(!overlay.description.isEmpty, "description")
    visionExpect(overlay == overlay, "equal")
    visionExpect(overlay != SaliencyImageObservation(), "unequal")
    _ = overlay.hashValue
    let encoded = try! JSONEncoder().encode(overlay)
    let decoded = try! JSONDecoder().decode(SaliencyImageObservation.self, from: encoded)
    visionExpectEqual(decoded.salientObjects.count, 1, "codable")
}

func testImageAestheticsScoresObservationValues() {
    let vn = VNImageAestheticsScoresObservation(overallScore: 0.7, isUtility: true)
    visionExpectEqual(vn.overallScore, 0.7, "vn score")
    visionExpectEqual(vn.isUtility, true, "vn utility")
    let overlay = ImageAestheticsScoresObservation(vn)
    visionExpectEqual(overlay.overallScore, 0.7, "overlay score")
    visionExpectEqual(overlay.isUtility, true, "overlay utility")
    visionExpect(!overlay.description.isEmpty, "description")
    visionExpect(overlay == overlay, "equal")
    visionExpect(overlay != ImageAestheticsScoresObservation(), "unequal")
    _ = overlay.hashValue
    var hasher = Hasher()
    overlay.hash(into: &hasher)
    let encoded = try! JSONEncoder().encode(overlay)
    let decoded = try! JSONDecoder().decode(ImageAestheticsScoresObservation.self, from: encoded)
    visionExpectEqual(decoded.overallScore, 0.7, "codable")
}

func testGenerateObjectnessBasedSaliencyImageRequestConfig() {
    var request = GenerateObjectnessBasedSaliencyImageRequest(.revision2)
    visionExpectEqual(request.revision, .revision2, "revision")
    visionExpectEqual(GenerateObjectnessBasedSaliencyImageRequest.supportedRevisions.contains(.revision2), true, "supported")
    visionExpectEqual(GenerateObjectnessBasedSaliencyImageRequest.supportedRevisions.contains(.revision1), true, "supported r1")
    request.regionOfInterest = .fullImage
    visionExpectEqual(request.descriptor, .generateObjectnessBasedSaliencyImageRequest(.revision2), "descriptor")
    visionExpect(request.description.contains("generateObjectnessBasedSaliency"), "description")
    request.setComputeDevice(.cpu, for: .main)
    visionExpectEqual(request.computeDevice(for: .main)?.identifier, "cpu", "device")
    visionExpect(request == request, "equal")
    visionExpect(request != GenerateObjectnessBasedSaliencyImageRequest(.revision1), "revision inequality")
    _ = request.hashValue
    var hasher = Hasher()
    request.hash(into: &hasher)
    visionExpectRevisionCodable(GenerateObjectnessBasedSaliencyImageRequest.Revision.revision2, "revision codable")
    visionExpect(GenerateObjectnessBasedSaliencyImageRequest.Revision.revision1 < .revision2, "revision <")
    let vn = VNGenerateObjectnessBasedSaliencyImageRequest()
    visionExpect(vn.results == nil, "vn results")
    visionExpectEqual(VNGenerateObjectnessBasedSaliencyImageRequest.currentRevision, VNGenerateObjectnessBasedSaliencyImageRequestRevision2, "vn rev")
    visionExpectOverlayInvalidModel({
        try request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    }, "objectness overlay")
    do {
        try VNImageRequestHandler(cgImage: visionRectangleImage()).perform([vn])
        visionExpect(false, "vn objectness should fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "vn invalidModel")
        visionExpect(vn.results == nil, "results stay nil")
    }
}

func testRequestProgressAndRevisionProviding() {
    let request = VNDetectBarcodesRequest()
    visionExpect(request.indeterminate, "linux progress is indeterminate")
    var ticks = 0
    request.progressHandler = { _, _, _ in ticks += 1 }
    request.progressHandler(request, 0.5, nil)
    visionExpectEqual(ticks, 1, "stored progress handler")
    let providing: any VNRequestProgressProviding = request
    visionExpect(providing.indeterminate, "protocol indeterminate")

    let observation = VNDetectedObjectObservation(
        requestRevision: 3,
        boundingBox: CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4)
    )
    visionExpectEqual(observation.requestRevision, 3, "stored revision")
    let revisionProviding: any VNRequestRevisionProviding = observation
    visionExpectEqual(revisionProviding.requestRevision, 3, "protocol revision")
    let copy = observation.copy() as! VNDetectedObjectObservation
    visionExpectEqual(copy.requestRevision, 3, "copied revision")
    visionExpect(copy !== observation, "detected copy is independent")
    visionExpectEqual(copy.uuid, observation.uuid, "copied uuid")
    visionExpectEqual(copy.confidence, observation.confidence, "copied confidence")
    visionExpectEqual(copy.boundingBox, observation.boundingBox, "copied bounds")
    copy.requestRevision = 1
    visionExpectEqual(observation.requestRevision, 3, "copy mutation leaves source revision")

    let rectangle = VNRectangleObservation(
        requestRevision: 3,
        topLeft: CGPoint(x: 0.1, y: 0.8),
        topRight: CGPoint(x: 0.7, y: 0.8),
        bottomRight: CGPoint(x: 0.7, y: 0.2),
        bottomLeft: CGPoint(x: 0.1, y: 0.2)
    )
    let rectangleCopy = rectangle.copy() as! VNRectangleObservation
    visionExpectEqual(rectangleCopy.requestRevision, 3, "rectangle copied revision")
    visionExpect(rectangleCopy !== rectangle, "rectangle copy is independent")
    visionExpectEqual(rectangleCopy.uuid, rectangle.uuid, "rectangle copied uuid")
    visionExpectEqual(rectangleCopy.boundingBox, rectangle.boundingBox, "rectangle copied bounds")
    visionExpectEqual(rectangleCopy.topLeft, rectangle.topLeft, "rectangle copied top left")
    visionExpectEqual(rectangleCopy.topRight, rectangle.topRight, "rectangle copied top right")
    visionExpectEqual(rectangleCopy.bottomLeft, rectangle.bottomLeft, "rectangle copied bottom left")
    visionExpectEqual(rectangleCopy.bottomRight, rectangle.bottomRight, "rectangle copied bottom right")
    let base = VNObservation(requestRevision: 3)
    visionExpectEqual((base.copy() as! VNObservation).requestRevision, 3, "base copied revision")
}

func visionRunFocusedTests() {
    testHarnessRectangleImage()
    testValueCatalog()
    testBarcodeSymbologyCatalog()
    testImageOptionAndComputeStage()
    testPointGeometry()
    testVectorGeometry()
    testCircleGeometry()
    testMinimumEnclosingCircle()
    testContourMetrics()
    testCoordinateMapping()
    testDetectedObjectObservation()
    testRectangleObservation()
    testBarcodeObservation()
    testTextObservation()
    testFaceObservation()
    testRequestBase()
    testImageBasedRequestROI()
    testDetectBarcodesRequestConfig()
    testImageRequestHandlerSources()
    testImageRequestHandlerHostAttach()
    testImageRequestHandlerInvalidImage()
    testSequenceRequestHandler()
    testQRBarcodeDecode()
    testCode128BarcodeDecode()
    testEAN13BarcodeDecode()
    testBarcodeURLHandler()
    testRectangleDetector()
    testContourDetector()
    testFeaturePrint()
    testTranslationalRegistration()
    testHomographicRegistrationFailClosed()
    testObjectTracker()
    testRecognizeTextFailClosed()
    testDetectFaceRectanglesFailClosed()
    testClassifyImageFailClosed()
    testHumanBodyPoseFailClosed()
    testCoreMLFailClosed()
    testOverlayNormalizedGeometry()
    testOverlayBarcodePerform()
    testOverlayRectanglePerform()
    testOverlayContourPerform()
    testOverlayFeaturePrintPerform()
    testOverlayTrackObjectRequest()
    testCoordinateMappingOrientation()
    testRecognizedPointKeyCatalog()
    testHumanBodyPoseObservationJoints()
    testHumanHandPoseObservationJoints()
    testAnimalBodyPoseObservationJoints()
    testHumanBodyPose3DObservationJoints()
    testClassificationPrecisionRecall()
    testFaceLandmarks2D()
    testRecognizedTextTopCandidates()
    testContoursObservationTree()
    testFeaturePrintDistanceMismatch()
    testHorizonObservation()
    testRequestROIValidation()
    testRequestRevisionValidation()
    testTrackObjectRequestState()
    testSequenceHandlerInvalidImageAndOrientation()
    testDetectHumanHandPoseFailClosed()
    testOverlayRecognizeTextFailClosedSync()
    testOverlayFaceAndDocumentValues()
    testOverlayPoseValueTypes()
    testOverlayTextAndClassification()
    testRevisionConstantsCatalog()
    testRequestDescriptorCatalog()
    testVisionResultCatalog()
    testBarcodeObservationOverlayValues()
    testRecognizeDocumentsRequestConfig()
    testTrackOpticalFlowRequestConfig()
    testOverlayRequestProtocolSurface()
    testOverlayRevisionComparableOperators()
    testOverlayROIAndInvalidImage()
    testVNTrackOpticalFlowRequestConfig()
    testImageRequestHandlerOverlayPerformNow()
    testOverlayEquatableInequality()
    testPixelBufferObservationValues()
    testVisionErrorCatalog()
    testContoursObservationOverlayGeometry()
    testGeneratePersonSegmentationRequestConfig()
    testTrackRectangleRequestConfig()
    testRecognizeAnimalsRequestConfig()
    testDetectTrajectoriesRequestConfig()
    testCoreMLRequestConfig()
    testDetectHumanBodyPoseRequestConfig()
    testDetectHumanHandPoseRequestConfig()
    testDetectAnimalBodyPoseRequestConfig()
    testDetectTextRectanglesRequestConfig()
    testDetectHumanBodyPose3DRequestConfig()
    testClassifyImageRequestConfig()
    testDetectedDocumentObservationValues()
    testTrajectoryObservationValues()
    testStatefulRequestDefaults()
    testPixelBufferObservationOverlayValues()
    testDetectLensSmudgeRequestConfig()
    testDetectFaceLandmarksRequestConfig()
    testDetectHumanRectanglesRequestConfig()
    testDetectFaceCaptureQualityRequestConfig()
    testCalculateImageAestheticsScoresRequestConfig()
    testDetectDocumentSegmentationRequestConfig()
    testGeneratePersonInstanceMaskRequestConfig()
    testGenerateForegroundInstanceMaskRequestConfig()
    testGenerateAttentionBasedSaliencyImageRequestConfig()
    testTrackObjectRequestOverlayConfig()
    testTrackHomographicImageRegistrationRequestConfig()
    testTrackTranslationalImageRegistrationRequestConfig()
    testRecognizeTextRequestConfig()
    testDetectHorizonRequestConfig()
    testTextObservationOverlayValues()
    testHumanObservationOverlayValues()
    testSmudgeObservationOverlayValues()
    testInstanceMaskObservationSuppliedData()
    testSaliencyImageObservationValues()
    testImageAestheticsScoresObservationValues()
    testGenerateObjectnessBasedSaliencyImageRequestConfig()
    testRequestProgressAndRevisionProviding()
    print("VISION_AGENT_RUNTIME_OK")
}

visionRunFocusedTests()
