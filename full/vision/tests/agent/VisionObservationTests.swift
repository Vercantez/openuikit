#if canImport(Glibc)
import Glibc
#endif
import Foundation
@_spi(OpenUIKitHost) import Vision

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
