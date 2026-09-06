import PaperKit
import Foundation

func paperKitTestArchive(version: UInt32, payload: Data) -> Data {
    var data = Data()
    data.append(PaperMarkupOpenUIKitMagic)
    var ver = version.bigEndian
    withUnsafeBytes(of: &ver) { data.append(contentsOf: $0) }
    var length = UInt32(payload.count).bigEndian
    withUnsafeBytes(of: &length) { data.append(contentsOf: $0) }
    data.append(payload)
    return data
}

func testPaperMarkupInitBounds() {
    let rect = CGRect(x: 10, y: 20, width: 300, height: 400)
    let markup = PaperMarkup(bounds: rect)
    precondition(markup.bounds == rect)
    precondition(markup.featureSet.features.isEmpty)
    precondition(markup.contentsRenderFrame.isNull)
}

func testPaperMarkupBoundsMutation() {
    var markup = PaperMarkup(bounds: .zero)
    let rect = CGRect(x: 1, y: 2, width: 3, height: 4)
    markup.bounds = rect
    precondition(markup.bounds == rect)
}

func testPaperMarkupEquality() {
    let a = PaperMarkup(bounds: CGRect(x: 0, y: 0, width: 10, height: 10))
    let b = PaperMarkup(bounds: CGRect(x: 0, y: 0, width: 10, height: 10))
    precondition(a == b)
    var c = b
    c.insertNewShape(
        configuration: ShapeConfiguration(type: .rectangle),
        frame: CGRect(x: 0, y: 0, width: 1, height: 1)
    )
    precondition(a != c)
}

func testPaperMarkupInsertShape() {
    var markup = PaperMarkup(bounds: CGRect(x: 0, y: 0, width: 100, height: 100))
    markup.insertNewShape(
        configuration: ShapeConfiguration(type: .star, lineWidth: 4),
        frame: CGRect(x: 10, y: 10, width: 20, height: 20),
        rotation: 0.5
    )
    precondition(markup.featureSet.shapes.contains(.star))
    precondition(markup.featureSet.contains(.shapeFills))
    precondition(markup.featureSet.contains(.shapeStrokes))
    precondition(!markup.contentsRenderFrame.isNull)
}

func testPaperMarkupInsertLine() {
    var markup = PaperMarkup(bounds: CGRect(x: 0, y: 0, width: 100, height: 100))
    markup.insertNewLine(
        configuration: ShapeConfiguration(type: .line, fillColor: nil, strokeColor: CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1), lineWidth: 2),
        from: CGPoint(x: 0, y: 0),
        to: CGPoint(x: 40, y: 10),
        startMarker: true,
        endMarker: false
    )
    precondition(markup.featureSet.shapes.contains(.line))
    precondition(markup.featureSet.lineMarkerPositions.contains(.single))
}

func testPaperMarkupInsertTextboxNSAttributedString() {
    var markup = PaperMarkup(bounds: CGRect(x: 0, y: 0, width: 80, height: 80))
    markup.insertNewTextbox(
        attributedText: NSAttributedString(string: "hello"),
        frame: CGRect(x: 5, y: 5, width: 40, height: 20)
    )
    precondition(markup.featureSet.contains(.text))
}

func testPaperMarkupInsertTextboxAttributedString() {
    var markup = PaperMarkup(bounds: CGRect(x: 0, y: 0, width: 80, height: 80))
    markup.insertNewTextbox(
        attributedText: AttributedString("world"),
        frame: CGRect(x: 5, y: 5, width: 40, height: 20),
        rotation: 0.1
    )
    precondition(markup.featureSet.contains(.text))
}

func testPaperMarkupInsertImage() {
    var markup = PaperMarkup(bounds: CGRect(x: 0, y: 0, width: 200, height: 200))
    let image = CGImage(width: 16, height: 8)
    markup.insertNewImage(image, frame: CGRect(x: 2, y: 2, width: 16, height: 8))
    precondition(markup.featureSet.contains(.images))
}

func testPaperMarkupAppendMarkup() {
    var base = PaperMarkup(bounds: CGRect(x: 0, y: 0, width: 50, height: 50))
    var other = PaperMarkup(bounds: CGRect(x: 0, y: 0, width: 10, height: 10))
    other.insertNewTextbox(
        attributedText: NSAttributedString(string: "x"),
        frame: CGRect(x: 0, y: 0, width: 8, height: 8)
    )
    base.append(contentsOf: other)
    precondition(base.featureSet.contains(.text))
}

func testPaperMarkupAppendDrawing() {
    var markup = PaperMarkup(bounds: CGRect(x: 0, y: 0, width: 50, height: 50))
    markup.append(contentsOf: PKDrawing())
    precondition(markup.featureSet.contains(.drawing))
}

func testPaperMarkupTransformContent() {
    var markup = PaperMarkup(bounds: CGRect(x: 0, y: 0, width: 100, height: 100))
    markup.insertNewShape(
        configuration: ShapeConfiguration(type: .rectangle),
        frame: CGRect(x: 10, y: 20, width: 10, height: 10)
    )
    let transform = CGAffineTransform(a: 2, b: 0, c: 0, d: 2, tx: 5, ty: 7)
    markup.transformContent(transform)
    let frame = markup.contentsRenderFrame
    precondition(frame.origin.x > 20)
    precondition(frame.origin.y > 40)
}

func testPaperMarkupRemoveUnsupported() {
    var markup = PaperMarkup(bounds: CGRect(x: 0, y: 0, width: 100, height: 100))
    markup.insertNewShape(
        configuration: ShapeConfiguration(type: .rectangle),
        frame: CGRect(x: 0, y: 0, width: 10, height: 10)
    )
    markup.insertNewTextbox(
        attributedText: NSAttributedString(string: "keep?"),
        frame: CGRect(x: 0, y: 0, width: 10, height: 10)
    )
    var allowed = FeatureSet.empty
    allowed.insert(.text)
    markup.removeContentUnsupported(by: allowed)
    precondition(markup.featureSet.contains(.text))
    precondition(!markup.featureSet.shapes.contains(.rectangle))
    precondition(markup.featureSet.isSubset(of: allowed))
}

func testPaperMarkupContentsRenderFrameEmpty() {
    let markup = PaperMarkup(bounds: CGRect(x: 0, y: 0, width: 10, height: 10))
    precondition(markup.contentsRenderFrame.isNull)
}

func testPaperMarkupInitIncorrectFormat() {
    do {
        _ = try PaperMarkup(dataRepresentation: Data([0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B]))
        preconditionFailure("expected incorrectFormat")
    } catch MarkupError.incorrectFormat {
        ()
    } catch {
        preconditionFailure("wrong error")
    }
    do {
        _ = try PaperMarkup(dataRepresentation: Data())
        preconditionFailure("expected incorrectFormat")
    } catch MarkupError.incorrectFormat {
        ()
    } catch {
        preconditionFailure("wrong error")
    }
}

func testPaperMarkupInitTooNew() {
    let archive = paperKitTestArchive(version: 99, payload: Data("{}".utf8))
    do {
        _ = try PaperMarkup(dataRepresentation: archive)
        preconditionFailure("expected incompatibleFormatTooNew")
    } catch MarkupError.incompatibleFormatTooNew {
        ()
    } catch {
        preconditionFailure("wrong error")
    }
}

func testPaperMarkupInitMalformedData() {
    let archive = paperKitTestArchive(version: 1, payload: Data("not-json".utf8))
    do {
        _ = try PaperMarkup(dataRepresentation: archive)
        preconditionFailure("expected malformedData")
    } catch MarkupError.malformedData {
        ()
    } catch {
        preconditionFailure("wrong error")
    }
}

func testPaperMarkupInitValidLinuxData() {
    let json = """
    {"bounds":{"x":1,"y":2,"w":30,"h":40},"elements":[{"kind":"textbox","text":"hi","frame":{"x":3,"y":4,"w":5,"h":6},"rotation":0}]}
    """
    let archive = paperKitTestArchive(version: 1, payload: Data(json.utf8))
    let markup = try! PaperMarkup(dataRepresentation: archive)
    precondition(markup.bounds == CGRect(x: 1, y: 2, width: 30, height: 40))
    precondition(markup.featureSet.contains(.text))
}

func testPaperMarkupFeatureSetFromContents() {
    var markup = PaperMarkup(bounds: .zero)
    precondition(markup.featureSet == FeatureSet.empty || markup.featureSet.features.isEmpty)
    markup.insertNewImage(CGImage(width: 1, height: 1), frame: CGRect(x: 0, y: 0, width: 1, height: 1))
    precondition(markup.featureSet.contains(.images))
    precondition(!markup.featureSet.contains(.stickers))
}
