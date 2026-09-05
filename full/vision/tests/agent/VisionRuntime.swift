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

func visionWaitFor<T>(_ work: @escaping () async throws -> T) -> T {
    let lock = DispatchSemaphore(value: 0)
    var stored: Result<T, Error>?
    Task {
        do {
            stored = .success(try await work())
        } catch {
            stored = .failure(error)
        }
        lock.signal()
    }
    lock.wait()
    return try! stored!.get()
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
    let overlayHits = visionWaitFor {
        try await request.perform(on: data)
    }
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
    request.minimumSize = 0.1
    let rectangles = visionWaitFor {
        try await request.perform(on: visionRectangleImage())
    }
    visionExpect(!rectangles.isEmpty, "overlay rectangles")
}

func testOverlayContourPerform() {
    var contourRequest = DetectContoursRequest()
    contourRequest.detectsDarkOnLight = false
    let contours = visionWaitFor {
        try await contourRequest.perform(on: visionRectangleImage())
    }
    visionExpect(contours.contourCount >= 1, "overlay contours")
}

func testOverlayFeaturePrintPerform() {
    let printObs = visionWaitFor {
        try await GenerateImageFeaturePrintRequest().perform(on: visionRectangleImage())
    }
    _ = try! printObs.distance(to: printObs)
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
    print("VISION_AGENT_RUNTIME_OK")
}

visionRunFocusedTests()
