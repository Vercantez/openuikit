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
