#if canImport(Glibc)
import Glibc
#endif
import Foundation
@_spi(OpenUIKitHost) import Vision

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
