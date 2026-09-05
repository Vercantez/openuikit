import PencilKit
import Foundation

func pkSampleDrawing() -> PKDrawing {
    let ink = PKInk(.pen, color: .black)
    let path = PKStrokePath(
        controlPoints: [pkMakePoint(0, 0), pkMakePoint(10, 5)],
        creationDate: Date(timeIntervalSince1970: 100)
    )
    let stroke = PKStroke(ink: ink, path: path, randomSeed: 11)
    return PKDrawing(strokes: [stroke])
}

func testPKDrawingEmptyAndAppend() {
    var drawing = PKDrawing()
    pkExpect(drawing.strokes.isEmpty, "empty")
    pkExpectEqual(drawing.bounds, .zero, "empty bounds")
    pkExpectEqual(drawing.requiredContentVersion, .version1, "empty version")
    drawing.append(pkSampleDrawing())
    pkExpectEqual(drawing.strokes.count, 1, "appended")
    let combined = PKDrawing().appending(pkSampleDrawing())
    pkExpectEqual(combined.strokes.count, 1, "appending")
    pkExpect(drawing != PKDrawing(), "inequality")
    pkExpect(drawing == drawing, "equality")
}

func testPKDrawingRoundTrip() {
    let original = pkSampleDrawing()
    let data = original.dataRepresentation()
    pkExpect(data.starts(with: PKDrawingOpenUIKitMagic), "magic prefix")
    let restored = try! PKDrawing(data: data)
    pkExpectEqual(restored.strokes.count, 1, "stroke count")
    pkExpectEqual(restored.strokes[0].ink.inkType, .pen, "ink")
    pkExpectEqual(restored.strokes[0].randomSeed, 11, "seed")
    pkExpectEqual(restored.strokes[0].path.count, 2, "points")
    pkExpectEqual(restored.strokes[0].path[1].location.x, 10, "x")
}

func testPKDrawingRejectsAppleBytes() {
    do {
        _ = try PKDrawing(data: Data([0x00, 0x01, 0x02, 0x03, 0x04]))
        fatalError("expected apple-format rejection")
    } catch PKDrawingDataError.appleFormatUnsupported {
        ()
    } catch {
        fatalError("unexpected \(error)")
    }
    do {
        _ = try PKDrawing(data: Data())
        fatalError("expected malformed")
    } catch PKDrawingDataError.malformedOpenUIKitDrawing {
        ()
    } catch PKDrawingDataError.appleFormatUnsupported {
        ()
    } catch {
        fatalError("unexpected \(error)")
    }
    do {
        _ = try PKDrawing(data: PKDrawingOpenUIKitMagic + Data("{}".utf8))
        fatalError("expected malformed json object")
    } catch PKDrawingDataError.malformedOpenUIKitDrawing {
        ()
    } catch {
        fatalError("unexpected \(error)")
    }
}

func testPKDrawingTransformAndBounds() {
    let drawing = pkSampleDrawing()
    pkExpect(drawing.bounds.width > 0, "bounds")
    let moved = drawing.transformed(using: PencilKitTransform(a: 1, b: 0, c: 0, d: 1, tx: 20, ty: 0))
    pkExpect(moved.strokes[0].path[0].location.x == 20, "tx")
    var mutated = drawing
    mutated.transform(using: PencilKitTransform(a: 1, b: 0, c: 0, d: 1, tx: 0, ty: 4))
    pkExpectEqual(mutated.strokes[0].path[0].location.y, 4, "ty")
}

func testPKDrawingImageSize() {
    let image = pkSampleDrawing().image(from: CGRect(x: 0, y: 0, width: 20, height: 10), scale: 2)
    pkExpectEqual(image.size.width, 40, "width")
    pkExpectEqual(image.size.height, 20, "height")
}

func testPKDrawingCodable() {
    let original = pkSampleDrawing()
    let encoded = try! JSONEncoder().encode(original)
    let decoded = try! JSONDecoder().decode(PKDrawing.self, from: encoded)
    pkExpectEqual(decoded.strokes.count, original.strokes.count, "codable")
}

func testPKDrawingReferenceCoderFailClosed() {
    let reference = PKDrawingReference()
    pkExpect(reference.strokes.isEmpty, "empty ref")
    let filled = PKDrawingReference(strokes: pkSampleDrawing().strokes)
    pkExpectEqual(filled.strokes.count, 1, "strokes init")
    pkExpectEqual(filled.appending(pkSampleDrawing()).strokes.count, 2, "appending")
    pkExpectEqual(filled.appendingStrokes(pkSampleDrawing().strokes).strokes.count, 2, "appendingStrokes")
    let applied = filled.applying(PencilKitTransform(a: 1, b: 0, c: 0, d: 1, tx: 3, ty: 0))
    pkExpectEqual(applied.strokes[0].path[0].location.x, 3, "applying")
    _ = filled.dataRepresentation()
    _ = filled.bounds
    _ = filled.requiredContentVersion
    _ = filled.image(from: CGRect(x: 0, y: 0, width: 1, height: 1), scale: 1)
    let data = filled.dataRepresentation()
    let fromData = try! PKDrawingReference(data: data)
    pkExpectEqual(fromData.strokes.count, 1, "data init")
    let dummy = NSCoder()
    pkExpect(PKDrawingReference(coder: dummy) == nil, "coder fail-closed")
}

func testPKDrawingInequality() {
    pkExpect(pkSampleDrawing() != PKDrawing(), "neq")
    pkExpect(!(pkSampleDrawing() != pkSampleDrawing()), "eq via neq")
}
