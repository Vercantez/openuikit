#if canImport(Glibc)
import Glibc
#endif
import Foundation
@_spi(OpenUIKitHost) import Vision

func testGenerateOpticalFlowFailClosedConfiguration() {
    let request = VNGenerateOpticalFlowRequest(targetedCGImage: visionRectangleImage())
    visionExpectEqual(request.computationAccuracy, .medium, "default accuracy")
    request.computationAccuracy = .veryHigh
    request.outputPixelFormat = 42
    request.keepNetworkOutput = true
    visionExpectEqual(request.computationAccuracy, .veryHigh, "accuracy mutation")
    visionExpectEqual(request.outputPixelFormat, 42, "pixel format mutation")
    visionExpect(request.keepNetworkOutput, "network-output mutation")
    visionExpect(request.results == nil, "results begin empty")
    do {
        try VNImageRequestHandler(cgImage: visionRectangleImage()).perform([request])
        visionExpect(false, "optical flow must fail closed")
    } catch let error as NSError {
        visionExpectEqual(error.code, VNErrorCode.invalidModel.rawValue, "optical-flow error")
        visionExpect(request.results == nil, "failed request has no fabricated results")
    }
}

func testRecognizedObjectObservationLabels() {
    let low = VNClassificationObservation(identifier: "background", confidence: 0.2)
    let high = VNClassificationObservation(identifier: "subject", confidence: 0.9)
    let observation = VNRecognizedObjectObservation(
        boundingBox: CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4),
        labels: [low, high],
        confidence: 0.8,
        requestRevision: 2
    )
    visionExpectEqual(observation.labels.map(\.identifier), ["subject", "background"], "confidence ordering")
    visionExpectEqual(observation.boundingBox.width, 0.3, "bounding box")
    visionExpectEqual(observation.confidence, 0.8, "confidence")
    let copy = observation.copy() as! VNRecognizedObjectObservation
    visionExpectEqual(copy.labels.map(\.identifier), ["subject", "background"], "copied labels")
    visionExpectEqual(copy.requestRevision, 2, "copied revision")
}

func testTargetedImageRequestHandlerInputs() {
    let image = visionRectangleImage()
    let data = VisionHost.encodeRaw(image)
    let pixelBuffer = CVPixelBuffer(width: image.width, height: image.height, pixels: image.pixels)
    let sampleBuffer = CMSampleBuffer(pixelBuffer: pixelBuffer)
    let ciImage = CIImage(cgImage: image)
    let temporary = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent("vision-targeted-\(UUID().uuidString).raw")
    try! data.write(to: temporary)
    defer { try? FileManager.default.removeItem(at: temporary) }

    let handlers = [
        TargetedImageRequestHandler(sourceURL: temporary, targetURL: temporary, orientation: .up),
        TargetedImageRequestHandler(source: data, target: data, orientation: .right),
        TargetedImageRequestHandler(source: image, target: image, orientation: .down),
        TargetedImageRequestHandler(source: ciImage, target: ciImage, orientation: .left),
        TargetedImageRequestHandler(source: pixelBuffer, target: pixelBuffer, orientation: .up),
        TargetedImageRequestHandler(source: sampleBuffer, target: sampleBuffer, orientation: .up)
    ]
    visionExpectEqual(handlers.count, 6, "all targeted input forms")
    for handler in handlers {
        do {
            try handler.validateInputs()
        } catch {
            visionExpect(false, "valid targeted inputs rejected: \(error)")
        }
    }

    let invalid = TargetedImageRequestHandler(source: Data(), target: data)
    do {
        try invalid.validateInputs()
        visionExpect(false, "empty targeted source accepted")
    } catch let error as VisionError {
        if case .invalidImage = error {} else { visionExpect(false, "wrong targeted validation error") }
    } catch {
        visionExpect(false, "wrong targeted validation type")
    }
}

func testRemainingOverlayProtocolContracts() {
    func boundingBox<T: BoundingBoxProviding>(_ value: T) -> NormalizedRect { value.boundingBox }
    func boundingRegion<T: BoundingRegionProviding>(_ value: T) -> NormalizedRegion { value.boundingRegion }
    func acceptsTargeted<T: TargetedRequest>(_ type: T.Type) -> Bool { type == T.self }
    func barcodeResult<T: VisionRequest>(_ request: T) -> T.Result.Type { T.Result.self }

    let rectangle = RectangleObservation(
        topLeft: NormalizedPoint(x: 0, y: 1), topRight: NormalizedPoint(x: 1, y: 1),
        bottomRight: NormalizedPoint(x: 1, y: 0), bottomLeft: NormalizedPoint(x: 0, y: 0)
    )
    visionExpectEqual(boundingBox(rectangle), .fullImage, "bounding-box protocol")
    let contours = ContoursObservation(VNContoursObservation(topLevelContours: []))
    let region: NormalizedRegion = boundingRegion(contours)
    visionExpectEqual(region.pointCount, 0, "bounding-region protocol and normalized-region alias")
    visionExpect(acceptsTargeted(TrackObjectRequest.self), "targeted-request conformance")
    visionExpect(barcodeResult(DetectBarcodesRequest()) == [BarcodeObservation].self, "barcode result alias")
    visionExpect(VNVisionVersionNumber.isFinite, "Linux-local version sentinel is finite")
}

func testRemainingObservationCodable() {
    let face = FaceObservation(VNFaceObservation(boundingBox: CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4)))
    let faceData = try! JSONEncoder().encode(face)
    let decodedFace = try! JSONDecoder().decode(FaceObservation.self, from: faceData)
    visionExpectEqual(decodedFace.boundingBox, face.boundingBox, "face codable")

    let horizon = HorizonObservation(VNHorizonObservation(angle: 0.25))
    let horizonData = try! JSONEncoder().encode(horizon)
    let decodedHorizon = try! JSONDecoder().decode(HorizonObservation.self, from: horizonData)
    visionExpectEqual(decodedHorizon.angle, horizon.angle, "horizon codable")
}
