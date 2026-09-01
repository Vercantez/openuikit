import Foundation
import Vision

precondition(VNErrorDomain == "VNErrorDomain")
precondition(VNError.errorDomain == VNErrorDomain)
precondition(VNErrorCode.OK.rawValue == 0)
precondition(VNErrorCode.notImplemented.rawValue == 8)
precondition(VNNormalizedRectIsIdentityRect(VNNormalizedIdentityRect))
precondition(VNElementTypeSize(.float) == MemoryLayout<Float>.size)
precondition(VNElementTypeSize(.double) == MemoryLayout<Double>.size)
precondition(VNElementTypeSize(.unknown) == 0)

let normalized = CGRect(x: 0.25, y: 0.5, width: 0.25, height: 0.25)
let imageRect = VNImageRectForNormalizedRect(normalized, 200, 100)
precondition(imageRect.origin.x == 50)
precondition(imageRect.origin.y == 50)
precondition(imageRect.size.width == 50)
precondition(imageRect.size.height == 25)
let roundTrip = VNNormalizedRectForImageRect(imageRect, 200, 100)
precondition(roundTrip.origin.x == 0.25)
precondition(roundTrip.origin.y == 0.5)

let roi = CGRect(x: 0.1, y: 0.2, width: 0.5, height: 0.4)
let roiPoint = VNImagePointForNormalizedPointUsingRegionOfInterest(
    CGPoint(x: 0.5, y: 0.5),
    100,
    100,
    roi
)
precondition(roiPoint.x == 35)
precondition(roiPoint.y == 40)

let landmark = VNImagePointForFaceLandmarkPoint(
    SIMD2<Float>(0.5, 0.5),
    CGRect(x: 0.2, y: 0.2, width: 0.4, height: 0.4),
    100,
    100
)
precondition(landmark.x == 40)
precondition(landmark.y == 40)

let origin = VNPoint(x: 0, y: 0)
let offset = VNPoint(x: 3, y: 4)
precondition(VNPoint.distance(origin, offset) == 5)
let vector = VNVector(vectorHead: offset, tail: origin)
precondition(vector.length == 5)
precondition(VNVector.dotProduct(of: vector, vector: vector) == 25)
let unit = VNVector.unitVector(for: vector)
precondition(abs(unit.length - 1) < 0.000_001)
let moved = VNPoint.apply(vector, to: origin)
precondition(moved.x == 3 && moved.y == 4)
let circle = VNCircle(center: origin, radius: 5)
precondition(circle.contains(offset))
precondition(!circle.contains(VNPoint(x: 6, y: 0)))
precondition(circle.contains(offset, inCircumferentialRingOfWidth: 0.5))

let enclosing = try! VNGeometryUtils.boundingCircle(for: [
    VNPoint(x: 0, y: 0),
    VNPoint(x: 2, y: 0),
    VNPoint(x: 0, y: 2),
])
precondition(enclosing.contains(VNPoint(x: 2, y: 2)))

precondition(VNBarcodeSymbology.qr == VNBarcodeSymbology.QR)
precondition(VNDetectBarcodesRequest.supportedSymbologies.contains(.qr))
let barcodes = VNDetectBarcodesRequest()
precondition(barcodes.revision == VNDetectBarcodesRequestRevision4)
barcodes.symbologies = [.qr, .ean13]
precondition(barcodes.symbologies.count == 2)

let faces = VNDetectFaceRectanglesRequest()
precondition(faces.revision == VNDetectFaceRectanglesRequestRevision3)
let text = VNRecognizeTextRequest()
text.recognitionLanguages = ["en-US"]
text.customWords = ["OpenUIKit"]
text.recognitionLevel = .fast
precondition(text.revision == VNRecognizeTextRequestRevision3)
do {
    _ = try VNRecognizeTextRequest.supportedRecognitionLanguages(
        for: .accurate,
        revision: VNRecognizeTextRequestRevision3
    )
    fatalError("text languages must fail closed")
} catch let error as VNError {
    precondition(error.code == .dataUnavailable)
    precondition(error.errorCode == VNErrorCode.dataUnavailable.rawValue)
} catch {
    fatalError("expected VNError")
}

let animals = try! VNRecognizeAnimalsRequest.knownAnimalIdentifiers(
    forRevision: VNRecognizeAnimalsRequestRevision2
)
precondition(animals == [.cat, .dog])

let box = VNDetectedObjectObservation(
    boundingBox: CGRect(x: 0.1, y: 0.2, width: 0.3, height: 0.4)
)
precondition(box.boundingBox.width == 0.3)
let face = VNFaceObservation(
    requestRevision: VNDetectFaceRectanglesRequestRevision3,
    boundingBox: box.boundingBox,
    roll: NSNumber(value: 0.1),
    yaw: NSNumber(value: -0.2),
    pitch: NSNumber(value: 0)
)
precondition(face.roll?.doubleValue == 0.1)
precondition(face.landmarks == nil)

let quad = VNRectangleObservation(
    requestRevision: 1,
    topLeft: CGPoint(x: 0, y: 1),
    topRight: CGPoint(x: 1, y: 1),
    bottomRight: CGPoint(x: 1, y: 0),
    bottomLeft: CGPoint(x: 0, y: 0)
)
precondition(quad.topLeft.y == 1)
precondition(quad.boundingBox.width == 1)

var completed: [String] = []
let saliency = VNGenerateAttentionBasedSaliencyImageRequest { request, error in
    completed.append(String(describing: type(of: request)))
    guard let error = error as? VNError else {
        fatalError("expected fail-closed VNError")
    }
    precondition(error.code == .notImplemented)
}
let handler = VNImageRequestHandler(data: Data([0x89, 0x50, 0x4E, 0x47]))
do {
    try handler.perform([barcodes, faces, text, saliency])
    fatalError("ML perform must fail closed")
} catch let error as VNError {
    precondition(error.code == .notImplemented)
} catch {
    fatalError("expected VNError from perform")
}
precondition(completed == ["VNGenerateAttentionBasedSaliencyImageRequest"])
precondition(barcodes.results == nil)

let empty = VNImageRequestHandler(data: Data())
do {
    try empty.perform([VNDetectRectanglesRequest()])
    fatalError("empty image must fail closed")
} catch let error as VNError {
    precondition(error.code == .invalidImage)
} catch {
    fatalError("expected invalidImage")
}

let missing = VNImageRequestHandler(
    url: URL(fileURLWithPath: "/tmp/vision-missing-image-\(UUID().uuidString).png")
)
do {
    try missing.perform([VNDetectHorizonRequest()])
    fatalError("missing URL must fail closed")
} catch let error as VNError {
    precondition(error.code == .ioError)
} catch {
    fatalError("expected ioError")
}

let cancelled = VNDetectHumanRectanglesRequest()
cancelled.cancel()
do {
    try VNSequenceRequestHandler().perform(
        [cancelled],
        onImageData: Data([0x00])
    )
    fatalError("cancelled request must fail closed")
} catch let error as VNError {
    precondition(error.code == .requestCancelled)
} catch {
    fatalError("expected requestCancelled")
}

let track = VNTrackObjectRequest(detectedObjectObservation: box)
precondition(track.inputObservation.boundingBox.width == 0.3)
precondition(
    track.supportedNumber(ofTrackersAndReturnError: nil) == 0
)

let landmarks = VNDetectFaceLandmarksRequest()
landmarks.inputFaceObservations = [face]
precondition(
    VNDetectFaceLandmarksRequest.revision(
        VNDetectFaceLandmarksRequestRevision3,
        supportsConstellation: .constellation65Points
    )
)

print("VISION_AGENT_RUNTIME_OK")

