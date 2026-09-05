@_spi(OpenUIKitHost) import VisionKit
import Foundation

func testRecognizedItemBounds() {
    let bounds = RecognizedItem.Bounds(
        topLeft: CGPoint(x: 0, y: 1),
        topRight: CGPoint(x: 1, y: 1),
        bottomRight: CGPoint(x: 1, y: 0),
        bottomLeft: CGPoint(x: 0, y: 0)
    )
    precondition(bounds.topLeft.y == 1)
    precondition(bounds.topRight.x == 1)
    precondition(bounds.bottomRight.y == 0)
    precondition(bounds.bottomLeft.x == 0)
}

func testRecognizedItemText() {
    let bounds = RecognizedItem.Bounds(
        topLeft: CGPoint(x: 0, y: 1),
        topRight: CGPoint(x: 1, y: 1),
        bottomRight: CGPoint(x: 1, y: 0),
        bottomLeft: CGPoint(x: 0, y: 0)
    )
    let id = UUID()
    let text = RecognizedItem.Text.hostFixture(transcript: "code", bounds: bounds, id: id)
    precondition(text.transcript == "code")
    precondition(text.id == id)
    precondition(text.bounds.bottomRight.x == 1)
    precondition(RecognizedItem.Text.ID.self == UUID.self)
    let item = RecognizedItem.text(text)
    precondition(item.id == text.id)
    precondition(item.bounds.topLeft.x == 0)
}

func testRecognizedItemBarcode() {
    let bounds = RecognizedItem.Bounds(
        topLeft: CGPoint(x: 0, y: 1),
        topRight: CGPoint(x: 1, y: 1),
        bottomRight: CGPoint(x: 1, y: 0),
        bottomLeft: CGPoint(x: 0, y: 0)
    )
    let id = UUID()
    let barcode = RecognizedItem.Barcode.hostFixture(
        payloadStringValue: "payload",
        bounds: bounds,
        id: id
    )
    precondition(barcode.payloadStringValue == "payload")
    precondition(barcode.id == id)
    precondition(RecognizedItem.Barcode.ID.self == UUID.self)
    let item = RecognizedItem.barcode(barcode)
    precondition(item.id == barcode.id)
    precondition(item.bounds.topRight.y == 1)
    let empty = RecognizedItem.Barcode.hostFixture(payloadStringValue: nil, bounds: bounds)
    precondition(empty.payloadStringValue == nil)
}

func testRecognizedItemIdentity() {
    let bounds = RecognizedItem.Bounds(
        topLeft: .zero,
        topRight: .zero,
        bottomRight: .zero,
        bottomLeft: .zero
    )
    let text = RecognizedItem.Text.hostFixture(transcript: "a", bounds: bounds)
    let barcode = RecognizedItem.Barcode.hostFixture(payloadStringValue: "b", bounds: bounds)
    let textItem = RecognizedItem.text(text)
    let barcodeItem = RecognizedItem.barcode(barcode)
    precondition(textItem.id == text.id)
    precondition(barcodeItem.id == barcode.id)
    precondition(RecognizedItem.ID.self == UUID.self)
    precondition(textItem.bounds.topLeft == .zero)
    precondition(barcodeItem.bounds.bottomRight == .zero)
}
