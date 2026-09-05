import Foundation
#if canImport(Glibc)
import Glibc
#endif
@_spi(OpenUIKitHost) import Vision

enum VisionRuntimeFailure: Error {
    case message(String)
}

func expect(_ condition: Bool, _ message: String) throws {
    if !condition {
        throw VisionRuntimeFailure.message(message)
    }
}

func expectEqual<T: Equatable>(_ lhs: T, _ rhs: T, _ message: String) throws {
    try expect(lhs == rhs, "\(message): \(lhs) != \(rhs)")
}

func expectClose(_ lhs: Double, _ rhs: Double, _ message: String, eps: Double = 1e-9) throws {
    try expect(abs(lhs - rhs) <= eps, "\(message): \(lhs) != \(rhs)")
}

func expectClosePoint(_ lhs: CGPoint, _ rhs: CGPoint, _ message: String) throws {
    try expectClose(Double(lhs.x), Double(rhs.x), message + " x")
    try expectClose(Double(lhs.y), Double(rhs.y), message + " y")
}

func expectThrows(_ message: String, _ work: () throws -> Void) throws {
    var threw = false
    do {
        try work()
    } catch {
        threw = true
    }
    try expect(threw, message)
}

func run() throws {
    try testEnums()
    try testIdentifiers()
    try testGeometry()
    try testMinimumEnclosingCircle()
    try testContourMetrics()
    try testCoordinateMapping()
    try testObservations()
    try testRequestsAndHandler()
    try testBarcodeFixtures()
    try testRectangleAndContourDetectors()
    try testFeaturePrintAndRegistration()
    try testObjectTracker()
    try testFailClosedModels()
    try testSwiftOverlay()
    print("VISION_AGENT_RUNTIME_OK")
}

func testEnums() throws {
    try expectEqual(Set(VNBarcodeCompositeType.allCases).count, 5, "composite allCases")
    for value in VNBarcodeCompositeType.allCases {
        try expect(VNBarcodeCompositeType(rawValue: value.rawValue) == value, "composite roundtrip")
    }
    try expectEqual(Set(VNErrorCode.allCases).count, 24, "error allCases")
    for value in VNErrorCode.allCases {
        try expect(VNErrorCode(rawValue: value.rawValue) == value, "error roundtrip")
    }
    try expectEqual(VNImageCropAndScaleOption.allCases.count, 5, "crop allCases")
    try expectEqual(VNPointsClassification.allCases.count, 3, "points allCases")
    try expectEqual(VNRequestFaceLandmarksConstellation.allCases.count, 3, "constellation allCases")
    try expectEqual(VNRequestTextRecognitionLevel.allCases.count, 2, "text level allCases")
    try expectEqual(VNRequestTrackingLevel.allCases.count, 2, "tracking allCases")
    try expectEqual(VNGenerateOpticalFlowRequest.ComputationAccuracy.allCases.count, 4, "flow allCases")
    try expectEqual(VNGeneratePersonSegmentationRequest.QualityLevel.allCases.count, 3, "quality allCases")
    try expectEqual(VNHumanBodyPose3DObservation.HeightEstimation.allCases.count, 2, "height allCases")
    try expectEqual(VNTrackOpticalFlowRequest.ComputationAccuracy.allCases.count, 4, "track flow allCases")
    try expectEqual(VNElementType.allCases.count, 3, "element allCases")
    try expectEqual(VNChirality.allCases.count, 3, "chirality allCases")
    try expect(VNBarcodeCompositeType.linked != .gs1TypeA, "composite distinct")
    try expectEqual(Set([VNChirality.unknown, .left, .right]).count, 3, "chirality count")
    try expectEqual(VNChirality.left.rawValue, -1, "chirality left")
    try expectEqual(VNChirality.right.rawValue, 1, "chirality right")
    try expectEqual(VNElementTypeSize(.unknown), 0, "element unknown")
    try expectEqual(VNElementTypeSize(.float), MemoryLayout<Float>.size, "element float")
    try expectEqual(VNElementTypeSize(.double), MemoryLayout<Double>.size, "element double")
    try expectEqual(VNImageCropAndScaleOption.scaleFitRotate90CCW.rawValue, 257, "crop rotate fit")
    try expectEqual(VNImageCropAndScaleOption.scaleFillRotate90CCW.rawValue, 258, "crop rotate fill")
    try expectEqual(VNPointsClassification.closedPath.rawValue, 2, "points closed")
    try expectEqual(VNRequestFaceLandmarksConstellation.constellation65Points.rawValue, 1, "landmarks 65")
    try expectEqual(VNRequestTextRecognitionLevel.fast.rawValue, 1, "text fast")
    try expectEqual(VNRequestTrackingLevel.accurate.rawValue, 0, "track accurate")
    try expectEqual(VNGenerateOpticalFlowRequest.ComputationAccuracy.veryHigh.rawValue, 3, "flow accuracy")
    try expectEqual(VNGeneratePersonSegmentationRequest.QualityLevel.fast.rawValue, 2, "seg quality")
    try expectEqual(VNHumanBodyPose3DObservation.HeightEstimation.measured.rawValue, 1, "height est")
    try expectEqual(VNTrackOpticalFlowRequest.ComputationAccuracy.medium.rawValue, 1, "track flow")
    try expectEqual(VNErrorCode.OK.rawValue, 0, "error ok")
    try expectEqual(VNErrorCode.turiCoreErrorCode.rawValue, -1, "error turi")
    try expectEqual(VNErrorCode.unsupportedComputeDevice.rawValue, 22, "error compute device")
    try expect(VNErrorCode.notImplemented != .requestCancelled, "error distinct")
    var hasher = Hasher()
    VNErrorCode.OK.hash(into: &hasher)
    _ = hasher.finalize()
    try expect(VNErrorCode.OK.hashValue == VNErrorCode.OK.hashValue, "error hash stable")
}

func testIdentifiers() throws {
    let catalog = VNBarcodeSymbology.knownSymbologies
    try expectEqual(catalog.count, 24, "symbology catalog")
    try expectEqual(Set(catalog.map(\.rawValue)).count, 24, "symbology unique")
    try expectEqual(VNBarcodeSymbology.qr, .QR, "qr alias")
    try expectEqual(VNBarcodeSymbology.aztec, .Aztec, "aztec alias")
    try expect(VNBarcodeSymbology.qr != .pdf417, "qr != pdf417")
    try expectEqual(
        VNBarcodeSymbology(rawValue: VNBarcodeSymbology.ean13.rawValue),
        .ean13,
        "symbology roundtrip"
    )
    try expect(VNImageOption.ciContext != .properties, "image option distinct")
    try expect(VNComputeStage.main != .postProcessing, "compute stage distinct")
    try expect(VNComputeStage.main.hashValue == VNComputeStage.main.hashValue, "compute hash stable")
}

func testGeometry() throws {
    let origin = VNPoint.zero
    let point = VNPoint(x: 3, y: 4)
    try expectEqual(origin.distance(point), 5, "3-4-5 distance")
    try expectEqual(VNPoint.distance(origin, point), 5, "class distance")
    try expectEqual(point.location, CGPoint(x: 3, y: 4), "location")
    let fromLocation = VNPoint(location: CGPoint(x: 1, y: 2))
    try expectEqual(fromLocation.x, 1, "from location x")

    let vector = VNVector(xComponent: 3, yComponent: 4)
    try expectEqual(vector.length, 5, "vector length")
    try expectEqual(vector.squaredLength, 25, "vector squared")
    try expectEqual(vector.r, 5, "vector r")
    try expectEqual(VNVector.dotProduct(of: vector, vector: vector), 25, "dot product")
    let unit = VNVector.unitVector(for: vector)
    try expectEqual(unit.length, 1, "unit length")
    try expectEqual(VNVector.unitVector(for: .zero).length, 0, "zero unit")
    let polar = VNVector(r: 2, theta: 0)
    try expectEqual(polar.x, 2, "polar x")
    try expect(abs(polar.y) < 1e-12, "polar y")
    let head = VNPoint(x: 5, y: 5)
    let tail = VNPoint(x: 2, y: 1)
    let fromPoints = VNVector(vectorHead: head, tail: tail)
    try expectEqual(fromPoints.x, 3, "head-tail x")
    try expectEqual(fromPoints.y, 4, "head-tail y")
    let sum = VNVector(byAdding: vector, to: vector)
    try expectEqual(sum.x, 6, "add x")
    let scaled = VNVector(byMultiplying: vector, byScalar: 2)
    try expectEqual(scaled.y, 8, "scale y")
    let subtracted = VNVector(bySubtracting: vector, from: scaled)
    try expectEqual(subtracted.x, 3, "subtract x")
    let alias = VNVector(XComponent: 1, yComponent: 2)
    try expectEqual(alias.x, 1, "XComponent alias")
    try expectEqual(VNVector(byAddingVector: vector, toVector: vector).x, 6, "add alias")
    try expectEqual(VNVector(byMultiplyingVector: vector, byScalar: 3).x, 9, "multiply alias")
    try expectEqual(VNVector(bySubtractingVector: vector, fromVector: scaled).x, 3, "subtract alias")
    try expect(abs(vector.theta - atan2(4.0, 3.0)) < 1e-12, "theta")
    let applied = VNPoint.apply(vector, to: origin)
    try expectEqual(applied.x, 3, "apply x")

    let circle = VNCircle(center: origin, radius: 5)
    try expect(circle.contains(point), "contains hypotenuse")
    try expect(circle.contains(VNPoint(x: 5, y: 0)), "contains radius")
    try expect(!circle.contains(VNPoint(x: 5.1, y: 0)), "excludes outside")
    try expect(circle.contains(VNPoint(x: 5, y: 0), inCircumferentialRingOfWidth: 0.2), "ring on circumference")
    try expect(!circle.contains(VNPoint.zero, inCircumferentialRingOfWidth: 0.2), "ring excludes center")
    let diameterCircle = VNCircle(center: origin, diameter: 10)
    try expectEqual(diameterCircle.radius, 5, "diameter init")
    try expect(VNCircle.zero.contains(VNPoint.zero), "zero circle")
}

func testMinimumEnclosingCircle() throws {
    try expectThrows("empty MEC") {
        _ = try VNGeometryUtils.boundingCircle(for: [VNPoint]())
    }

    let single = try VNGeometryUtils.boundingCircle(for: [VNPoint(x: 1, y: 2)])
    try expectEqual(single.radius, 0, "singleton radius")
    try expectEqual(single.center.x, 1, "singleton x")

    let duplicates = try VNGeometryUtils.boundingCircle(
        for: [VNPoint(x: 1, y: 1), VNPoint(x: 1, y: 1)]
    )
    try expectEqual(duplicates.radius, 0, "duplicate radius")

    let pair = try VNGeometryUtils.boundingCircle(
        for: [VNPoint(x: 0, y: 0), VNPoint(x: 4, y: 0)]
    )
    try expectEqual(pair.radius, 2, "pair radius")
    try expectEqual(pair.center.x, 2, "pair center")

    let collinear = try VNGeometryUtils.boundingCircle(
        for: [VNPoint(x: 0, y: 0), VNPoint(x: 1, y: 0), VNPoint(x: 4, y: 0)]
    )
    try expectEqual(collinear.radius, 2, "collinear radius")
    try expectEqual(collinear.center.x, 2, "collinear center")

    let obtuse = try VNGeometryUtils.boundingCircle(
        for: [VNPoint(x: 0, y: 0), VNPoint(x: 4, y: 0), VNPoint(x: 0.1, y: 0.1)]
    )
    try expectEqual(obtuse.radius, 2, "obtuse uses longest side")

    // Equilateral-ish triangle where a bounding-box radius would be too large.
    let acute = [
        VNPoint(x: 0, y: 0),
        VNPoint(x: 2, y: 0),
        VNPoint(x: 1, y: sqrt(3)),
    ]
    let mec = try VNGeometryUtils.boundingCircle(for: acute)
    try expect(abs(mec.radius - 2 / sqrt(3)) < 1e-9, "acute circumradius")
    for point in acute {
        try expect(mec.contains(point), "acute containment")
    }
    let boxRadius = hypot(1.0, sqrt(3) / 2)
    try expect(mec.radius < boxRadius - 1e-9, "smaller than bounding-box approximation")

    let reversed = try VNGeometryUtils.boundingCircle(for: acute.reversed())
    try expect(abs(reversed.radius - mec.radius) < 1e-9, "order invariance radius")
    try expect(abs(reversed.center.x - mec.center.x) < 1e-9, "order invariance x")
    try expect(abs(reversed.center.y - mec.center.y) < 1e-9, "order invariance y")

    let simdPoints: [SIMD2<Float>] = [
        SIMD2<Float>(0, 0),
        SIMD2<Float>(2, 0),
        SIMD2<Float>(1, Float(sqrt(3))),
    ]
    let simdCircle = try simdPoints.withUnsafeBufferPointer { buffer in
        try VNGeometryUtils.boundingCircle(
            forSIMDPoints: buffer.baseAddress!,
            pointCount: buffer.count
        )
    }
    try expect(abs(simdCircle.radius - mec.radius) < 1e-5, "simd MEC")
}

func testContourMetrics() throws {
    let square = VNContour(normalizedPoints: [
        SIMD2<Float>(0, 0),
        SIMD2<Float>(1, 0),
        SIMD2<Float>(1, 1),
        SIMD2<Float>(0, 1),
    ])
    try expectEqual(square.pointCount, 4, "point count")
    try expectEqual(square.aspectRatio, 1, "aspect")
    var area: Double = 0
    try VNGeometryUtils.calculateArea(&area, for: square, orientedArea: false)
    try expectEqual(area, 1, "square area")
    var signed: Double = 0
    try VNGeometryUtils.calculateArea(&signed, for: square, orientedArea: true)
    try expectEqual(signed, 1, "oriented ccw")
    var perimeter: Double = 0
    try VNGeometryUtils.calculatePerimeter(&perimeter, for: square)
    try expectEqual(perimeter, 4, "square perimeter")

    let child = VNContour(normalizedPoints: [SIMD2<Float>(0.2, 0.2), SIMD2<Float>(0.3, 0.2)])
    let parent = VNContour(
        normalizedPoints: square.normalizedPoints,
        indexPath: IndexPath(index: 0),
        childContours: [child]
    )
    try expectEqual(parent.childContourCount, 1, "child count")
    try expectEqual(try parent.childContour(at: 0).pointCount, 2, "child fetch")
    try expectThrows("child oob") {
        _ = try parent.childContour(at: 3)
    }

    let circle = try VNGeometryUtils.boundingCircle(for: square)
    try expect(circle.contains(VNPoint(x: 0.5, y: 0.5)), "contour circle contains center")

    let jagged = VNContour(normalizedPoints: [
        SIMD2<Float>(0, 0),
        SIMD2<Float>(0.5, 0.0001),
        SIMD2<Float>(1, 0),
    ])
    let approx = try jagged.polygonApproximation(epsilon: 0.01)
    try expectEqual(approx.pointCount, 2, "dp collapsed colinear")
}

func testCoordinateMapping() throws {
    try expect(VNNormalizedRectIsIdentityRect(VNNormalizedIdentityRect), "identity rect")
    try expect(!VNNormalizedRectIsIdentityRect(CGRect(x: 0, y: 0, width: 1, height: 0.5)), "not identity")
    let imagePoint = VNImagePointForNormalizedPoint(CGPoint(x: 0.25, y: 0.5), 200, 100)
    try expectEqual(imagePoint, CGPoint(x: 50, y: 50), "norm to image")
    let back = VNNormalizedPointForImagePoint(imagePoint, 200, 100)
    try expectEqual(back, CGPoint(x: 0.25, y: 0.5), "image to norm")
    let imageRect = VNImageRectForNormalizedRect(CGRect(x: 0.1, y: 0.2, width: 0.25, height: 0.5), 100, 200)
    try expectEqual(imageRect.origin, CGPoint(x: 10, y: 40), "rect origin")
    try expectEqual(imageRect.size, CGSize(width: 25, height: 100), "rect size")
    let roiPoint = VNImagePointForNormalizedPointUsingRegionOfInterest(
        CGPoint(x: 0.5, y: 0.5),
        100,
        100,
        CGRect(x: 0.2, y: 0.2, width: 0.4, height: 0.4)
    )
    try expectClosePoint(roiPoint, CGPoint(x: 40, y: 40), "roi point")
    let landmark = VNImagePointForFaceLandmarkPoint(
        SIMD2<Float>(0.5, 0.25),
        CGRect(x: 0.2, y: 0.2, width: 0.4, height: 0.4),
        100,
        100
    )
    try expectClosePoint(landmark, CGPoint(x: 40, y: 30), "landmark")
}

func testObservations() throws {
    let box = CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4)
    let detected = VNDetectedObjectObservation(boundingBox: box)
    try expectEqual(detected.boundingBox, box, "bbox")
    try expect(detected.confidence == 1, "default confidence")
    try expect(detected.uuid != UUID(), "uuid assigned")

    let rectangle = VNRectangleObservation(
        requestRevision: 1,
        topLeft: CGPoint(x: 0, y: 1),
        topRight: CGPoint(x: 1, y: 1),
        bottomRight: CGPoint(x: 1, y: 0),
        bottomLeft: CGPoint(x: 0, y: 0)
    )
    try expectEqual(rectangle.topLeft, CGPoint(x: 0, y: 1), "tl")
    try expectEqual(rectangle.boundingBox, CGRect(x: 0, y: 0, width: 1, height: 1), "rect bbox")

    let altOrder = VNRectangleObservation(
        requestRevision: 1,
        topLeft: CGPoint(x: 0, y: 1),
        bottomLeft: CGPoint(x: 0, y: 0),
        bottomRight: CGPoint(x: 1, y: 0),
        topRight: CGPoint(x: 1, y: 1)
    )
    try expectEqual(altOrder.bottomRight, CGPoint(x: 1, y: 0), "alt order")

    let barcode = VNBarcodeObservation(
        topLeft: rectangle.topLeft,
        topRight: rectangle.topRight,
        bottomRight: rectangle.bottomRight,
        bottomLeft: rectangle.bottomLeft,
        symbology: .qr,
        payloadStringValue: "hello",
        payloadData: Data("hello".utf8),
        isGS1DataCarrier: false,
        supplementalCompositeType: .none
    )
    try expectEqual(barcode.symbology, .qr, "barcode symbology")
    try expectEqual(barcode.payloadStringValue, "hello", "payload")
    try expectEqual(barcode.isColorInverted, false, "inverted default")

    let text = VNRecognizedText(string: "Hi", confidence: 0.8)
    try expectEqual(text.string, "Hi", "recognized text")
    let textObs = VNRecognizedTextObservation(
        topLeft: rectangle.topLeft,
        topRight: rectangle.topRight,
        bottomRight: rectangle.bottomRight,
        bottomLeft: rectangle.bottomLeft,
        candidates: [text]
    )
    try expectEqual(textObs.topCandidates(1).first?.string, "Hi", "top candidate")
    try expectEqual(textObs.topCandidates(0).count, 0, "zero candidates")

    let face = VNFaceObservation(boundingBox: box, roll: 0.1)
    try expectEqual(face.roll?.doubleValue, 0.1, "face roll")
}

func testRequestsAndHandler() throws {
    try expectEqual(VNRequestRevisionUnspecified, 0, "unspecified revision")
    try expectEqual(VNDetectContourRequestRevision1, 1, "contour revision graph spelling")
    try expectEqual(VNDetectContoursRequestRevision1, VNDetectContourRequestRevision1, "contour revision alias")
    let request = VNDetectRectanglesRequest()
    try expectEqual(request.minimumAspectRatio, 0.5, "min aspect")
    try expectEqual(request.maximumObservations, 8, "max observations")
    try expectEqual(request.regionOfInterest, VNNormalizedIdentityRect, "default ROI")
    try expectEqual(
        VNDetectRectanglesRequest.supportedRevisions.contains(VNDetectRectanglesRequestRevision1),
        true,
        "rect revision"
    )

    let barcodes = VNDetectBarcodesRequest()
    try expect(barcodes.symbologies.contains(.qr), "default includes qr")
    try expectEqual(try barcodes.supportedSymbologies().count, 24, "supported symbologies")
    barcodes.symbologies = [.qr]
    try expectEqual(barcodes.symbologies, [.qr], "symbologies stored")

    let text = VNRecognizeTextRequest()
    try expectEqual(text.recognitionLevel, .accurate, "text level")
    try expectEqual(try text.supportedRecognitionLanguages(), [], "no languages")
    text.customWords = ["OpenUIKit"]
    try expectEqual(text.customWords, ["OpenUIKit"], "custom words")

    var completed = false
    let cancellable = VNRequest { _, error in
        completed = error != nil
    }
    cancellable.cancel()
    let handler = VNImageRequestHandler(data: Data([0, 1, 2]), options: [.properties: "none"])
    try expectEqual(handler.source, .data(Data([0, 1, 2])), "handler source")
    _ = VNImageRequestHandler(url: URL(fileURLWithPath: "/tmp/vision-missing.png"))
    _ = VNImageRequestHandler(URL: URL(fileURLWithPath: "/tmp/vision-missing.png"))
    try expectThrows("cancelled throws") {
        try handler.perform([cancellable])
    }
    try expect(completed, "cancel completion")

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
    try handler.perform([hosted])
    let recovered = hosted.results?.first as? VNBarcodeObservation
    try expectEqual(recovered?.payloadStringValue, "hosted", "host results")

    let failClosed = VNDetectFaceRectanglesRequest()
    do {
        try handler.perform([failClosed])
        throw VisionRuntimeFailure.message("invalid image should throw")
    } catch let error as NSError {
        try expectEqual(error.domain, VNErrorDomain, "error domain")
        try expectEqual(error.code, VNErrorCode.invalidImage.rawValue, "invalid image on garbage data")
    }

    let sequence = VNSequenceRequestHandler()
    let seqRequest = VNDetectRectanglesRequest()
    VisionHost.attachResults([
        VNDetectedObjectObservation(boundingBox: CGRect(x: 0, y: 0, width: 1, height: 1)),
    ], to: seqRequest)
    try sequence.perform([seqRequest], onImageData: Data([9]))
    try expectEqual(seqRequest.results?.count, 1, "sequence host results")

    let flow = VNGenerateOpticalFlowRequest()
    flow.computationAccuracy = .veryHigh
    try expectEqual(flow.computationAccuracy, .veryHigh, "flow accuracy stored")
    let segmentation = VNGeneratePersonSegmentationRequest()
    segmentation.qualityLevel = .fast
    try expectEqual(segmentation.qualityLevel, .fast, "quality stored")
}

func waitFor<T>(_ work: @escaping () async throws -> T) throws -> T {
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
    return try stored!.get()
}

func testBarcodeFixtures() throws {
    let qrImage = try VisionHost.makeQRImage(payload: "HELLO", moduleSize: 6, quietZone: 4)
    let qrHandler = VNImageRequestHandler(cgImage: qrImage, orientation: .up, options: [:])
    let qrRequest = VNDetectBarcodesRequest()
    qrRequest.symbologies = [.qr]
    try qrHandler.perform([qrRequest])
    let qrHits = (qrRequest.results ?? []).compactMap { $0 as? VNBarcodeObservation }
    try expect(qrHits.contains(where: { $0.payloadStringValue == "HELLO" && $0.symbology == .qr }), "QR payload")

    let codeImage = try VisionHost.makeCode128Image(payload: "ABC123")
    let codeHandler = VNImageRequestHandler(cgImage: codeImage)
    let codeRequest = VNDetectBarcodesRequest()
    codeRequest.symbologies = [.code128]
    try codeHandler.perform([codeRequest])
    let codeHits = (codeRequest.results ?? []).compactMap { $0 as? VNBarcodeObservation }
    try expect(codeHits.contains(where: { $0.payloadStringValue == "ABC123" }), "Code128 payload")

    let eanImage = try VisionHost.makeEAN13Image(payload: "5901234123457")
    let eanData = VisionHost.encodeNetpbm(eanImage)
    let eanHandler = VNImageRequestHandler(data: eanData, orientation: .up)
    let eanRequest = VNDetectBarcodesRequest()
    eanRequest.symbologies = [.ean13]
    try eanHandler.perform([eanRequest])
    let eanHits = (eanRequest.results ?? []).compactMap { $0 as? VNBarcodeObservation }
    try expect(eanHits.contains(where: { $0.payloadStringValue == "5901234123457" }), "EAN-13 payload")

    let url = FileManager.default.temporaryDirectory.appendingPathComponent("vision-qr.ppm")
    try VisionHost.encodeNetpbm(qrImage).write(to: url)
    let urlHandler = VNImageRequestHandler(URL: url, orientation: .up, options: [:])
    let urlRequest = VNDetectBarcodesRequest()
    urlRequest.symbologies = [.qr]
    try urlHandler.perform([urlRequest])
    try expect((urlHandler.source == .url(url)), "url source")
}

func makeRectangleImage() -> CGImage {
    var raster = VisionRaster(width: 80, height: 80, filled: (0, 0, 0, 255))
    for y in 20..<60 {
        for x in 20..<60 {
            raster[x, y] = (255, 255, 255, 255)
        }
    }
    return raster.makeCGImage()
}

func testRectangleAndContourDetectors() throws {
    let image = makeRectangleImage()
    let handler = VNImageRequestHandler(cgImage: image)
    let rectangles = VNDetectRectanglesRequest()
    rectangles.minimumSize = 0.1
    rectangles.minimumAspectRatio = 0.2
    rectangles.maximumAspectRatio = 1.0
    rectangles.quadratureTolerance = 40
    rectangles.minimumConfidence = 0
    rectangles.maximumObservations = 4
    try handler.perform([rectangles])
    let found = (rectangles.results ?? []).compactMap { $0 as? VNRectangleObservation }
    try expect(!found.isEmpty, "detected rectangle")
    if let box = found.first?.boundingBox {
        try expect(box.width > 0.2 && box.height > 0.2, "rectangle size")
        try expect(box.origin.y >= 0, "lower-left origin")
    }

    let contours = VNDetectContoursRequest()
    contours.detectsDarkOnLight = false
    contours.maximumImageDimension = 128
    try handler.perform([contours])
    let contourObs = contours.results?.first as? VNContoursObservation
    try expect((contourObs?.contourCount ?? 0) >= 1, "contour count")
    let path = contourObs?.normalizedPath
    try expect(path != nil, "normalized path")
    if let first = try contourObs?.contour(at: 0) {
        try expect(first.pointCount >= 4, "contour points")
        _ = first.normalizedPath
        var area: Double = 0
        try VNGeometryUtils.calculateArea(&area, for: first, orientedArea: false)
        try expect(area > 0, "contour area")
    }
}

func testFeaturePrintAndRegistration() throws {
    let red = VisionRaster(width: 32, height: 32, filled: (200, 20, 20, 255))
    let blue = VisionRaster(width: 32, height: 32, filled: (20, 20, 200, 255))
    let redHandler = VNImageRequestHandler(cgImage: red.makeCGImage())
    let blueHandler = VNImageRequestHandler(ciImage: blue.makeCIImage(), orientation: .up)
    let redPrint = VNGenerateImageFeaturePrintRequest()
    let bluePrint = VNGenerateImageFeaturePrintRequest()
    try redHandler.perform([redPrint])
    try blueHandler.perform([bluePrint])
    let lhs = redPrint.results?.first as? VNFeaturePrintObservation
    let rhs = bluePrint.results?.first as? VNFeaturePrintObservation
    try expect(lhs != nil && rhs != nil, "feature prints")
    var same: Float = 0
    var different: Float = 0
    try lhs!.computeDistance(&same, to: lhs!)
    try lhs!.computeDistance(&different, to: rhs!)
    try expect(same < 1e-5, "identical feature print")
    try expect(different > same, "colour histograms differ")

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
    try moving.perform([registration])
    let align = registration.results?.first as? VNImageTranslationAlignmentObservation
    try expect(align != nil, "translation observation")
    try expect(abs(align!.alignmentTransform.tx - 8) < 3, "tx")
    try expect(abs(align!.alignmentTransform.ty - 4) < 3, "ty")

    let homo = VNHomographicImageRegistrationRequest(targetedCGImage: base.makeCGImage())
    do {
        try moving.perform([homo])
        throw VisionRuntimeFailure.message("homography should fail closed")
    } catch let error as NSError {
        try expectEqual(error.code, VNErrorCode.unsupportedRequest.rawValue, "homography unsupported")
        try expect(homo.results == nil, "homography results nil")
    }
}

func testObjectTracker() throws {
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
    try VNImageRequestHandler(cgImage: frame1.makeCGImage()).perform([tracker])
    try VNImageRequestHandler(cvPixelBuffer: frame2.makePixelBuffer()).perform([tracker])
    let tracked = tracker.results?.first as? VNDetectedObjectObservation
    try expect(tracked != nil, "tracked box")
    try expect(tracked!.boundingBox.origin.x > seedBox.origin.x - 0.05, "centroid moved")
}

func testFailClosedModels() throws {
    let image = makeRectangleImage()
    let handler = VNImageRequestHandler(cgImage: image)
    let requests: [VNRequest] = [
        VNRecognizeTextRequest(),
        VNDetectFaceRectanglesRequest(),
        VNClassifyImageRequest(),
        VNDetectHumanBodyPoseRequest(),
        VNCoreMLRequest(completionHandler: nil),
    ]
    for request in requests {
        do {
            try handler.perform([request])
            throw VisionRuntimeFailure.message("expected invalidModel for \(type(of: request))")
        } catch let error as NSError {
            try expectEqual(error.domain, VNErrorDomain, "ml domain")
            try expectEqual(error.code, VNErrorCode.invalidModel.rawValue, "ml invalidModel")
            try expect(request.results == nil, "ml results nil")
        }
    }
    do {
        _ = try VNClassifyImageRequest.knownClassifications(forRevision: 1)
        throw VisionRuntimeFailure.message("classifications should fail")
    } catch let error as NSError {
        try expectEqual(error.code, VNErrorCode.invalidModel.rawValue, "known classifications")
    }
}

func testSwiftOverlay() throws {
    try expectEqual(BarcodeSymbology.qr, BarcodeSymbology.qr, "overlay symbology eq")
    try expect(BarcodeSymbology.allCases.contains(.code128), "overlay allCases")
    try expect(DetectBarcodesRequest.Revision.revision4 < DetectBarcodesRequest.Revision.revision4
        || DetectBarcodesRequest.Revision.revision4 == .revision4, "revision comparable")
    let rect = NormalizedRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4)
    let imageRect = rect.toImageCoordinates(CGSize(width: 100, height: 200), origin: .lowerLeft)
    try expectEqual(imageRect.origin, CGPoint(x: 10, y: 40), "overlay rect mapping")
    let point = NormalizedPoint(x: 0.25, y: 0.5)
    try expectEqual(point.toImageCoordinates(CGSize(width: 200, height: 100)), CGPoint(x: 50, y: 50), "overlay point")
    try expect(NormalizedRect.fullImage.verticallyFlipped().height == 1, "flipped identity")
    _ = CoordinateOrigin.lowerLeft
    _ = ComputeStage.main
    _ = ElementType.float
    _ = ImageCropAndScaleAction.allCases
    _ = Chirality.left
    var hasher = Hasher()
    DetectRectanglesRequest().hash(into: &hasher)
    _ = hasher.finalize()
    try expect(DetectBarcodesRequest().revision == .revision4, "overlay revision")
    _ = VisionError.invalidModel("gap")
    _ = RequestDescriptor.detectBarcodesRequest(.revision4)
    _ = VisionResult.detectBarcodes(DetectBarcodesRequest(), [])

    let qrImage = try VisionHost.makeQRImage(payload: "HELLO")
    let data = VisionHost.encodeNetpbm(qrImage)
    let overlayHits = try waitFor {
        try await DetectBarcodesRequest().perform(on: data)
    }
    try expect(overlayHits.contains(where: { $0.payloadString == "HELLO" }), "overlay QR")
    let rectangles = try waitFor {
        try await DetectRectanglesRequest().perform(on: makeRectangleImage())
    }
    try expect(!rectangles.isEmpty, "overlay rectangles")
    let printObs = try waitFor {
        try await GenerateImageFeaturePrintRequest().perform(on: makeRectangleImage())
    }
    _ = try printObs.distance(to: printObs)
    var contourRequest = DetectContoursRequest()
    contourRequest.detectsDarkOnLight = false
    let contours = try waitFor {
        try await contourRequest.perform(on: makeRectangleImage())
    }
    try expect(contours.contourCount >= 1, "overlay contours")
    _ = ImageRequestHandler(data)
    _ = TrackObjectRequest(detectedObject: DetectedObjectObservation(boundingBox: .fullImage))
}

do {
    try run()
} catch {
    fputs("VISION_AGENT_RUNTIME_FAIL \(error)\n", stderr)
    exit(1)
}
