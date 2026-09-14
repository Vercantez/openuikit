#if canImport(Glibc)
import Glibc
#endif
import Foundation
@_spi(OpenUIKitHost) import Vision

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
    let seedBox = NormalizedRect(x: 10.0 / 60.0, y: 1 - 22.0 / 60.0, width: 12.0 / 60.0, height: 12.0 / 60.0)
    let seed = DetectedObjectObservation(boundingBox: seedBox)
    let request = TrackObjectRequest(detectedObject: seed)
    visionExpect(seed.boundingBox == seedBox, "overlay detected object")
    let first = try! request.performOnHandler(VNImageRequestHandler(cgImage: frame1.makeCGImage()))
    visionExpect(first != nil, "first tracked frame")
    let second = try! request.performOnHandler(VNImageRequestHandler(cgImage: frame2.makeCGImage()))
    visionExpect(second != nil, "second tracked frame")
    visionExpect(second!.boundingBox.origin.x > seedBox.origin.x - 0.05, "overlay centroid moved")
}

func testOverlayHorizonPerform() {
    var request = DetectHorizonRequest()
    request.setComputeDevice(.cpu, for: .main)
    let observation = try! request.performOnHandler(VNImageRequestHandler(cgImage: visionHorizonImage()))
    visionExpect(observation != nil, "overlay horizon")
    visionExpect(observation!.confidence > 0, "overlay horizon confidence")
    _ = observation!.transform(for: CGSize(width: 80, height: 80))
}

func testOverlayLensSmudgePerform() {
    var request = DetectLensSmudgeRequest()
    request.cropAndScaleAction = .centerCrop
    let sharp = try! request.performOnHandler(VNImageRequestHandler(cgImage: visionRectangleImage()))
    let smudged = try! request.performOnHandler(VNImageRequestHandler(cgImage: visionUniformGrayImage()))
    visionExpect(smudged.confidence > sharp.confidence, "overlay lens smudge contrast")
}
