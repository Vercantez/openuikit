import PencilKit
import Foundation

func pkExpect(_ condition: Bool, _ message: String) {
    if !condition {
        fatalError(message)
    }
}

func pkExpectEqual<T: Equatable>(_ lhs: T, _ rhs: T, _ message: String) {
    if lhs != rhs {
        fatalError("\(message): \(String(describing: lhs)) != \(String(describing: rhs))")
    }
}

func testContentVersionRawValues() {
    pkExpectEqual(PKContentVersion.version1.rawValue, 1, "v1")
    pkExpectEqual(PKContentVersion.version2.rawValue, 2, "v2")
    pkExpectEqual(PKContentVersion.version3.rawValue, 3, "v3")
    pkExpectEqual(PKContentVersion.version4.rawValue, 4, "v4")
    pkExpectEqual(PKContentVersion.latest, .version4, "latest")
    pkExpectEqual(PKContentVersion(rawValue: 1), .version1, "init 1")
    pkExpect(PKContentVersion(rawValue: 0) == nil, "unknown raw")
    pkExpect(PKContentVersion.version1 != .version2, "inequality")
    var hasher = Hasher()
    PKContentVersion.version2.hash(into: &hasher)
    _ = PKContentVersion.version2.hashValue
}

func testDrawingPolicyRawValues() {
    pkExpectEqual(PKCanvasViewDrawingPolicy.default.rawValue, 0, "default")
    pkExpectEqual(PKCanvasViewDrawingPolicy.anyInput.rawValue, 1, "any")
    pkExpectEqual(PKCanvasViewDrawingPolicy.pencilOnly.rawValue, 2, "pencil")
    pkExpectEqual(PKCanvasViewDrawingPolicy(rawValue: 1), .anyInput, "init")
    pkExpect(PKCanvasViewDrawingPolicy(rawValue: 9) == nil, "unknown")
    pkExpect(PKCanvasViewDrawingPolicy.default != .pencilOnly, "inequality")
    var hasher = Hasher()
    PKCanvasViewDrawingPolicy.anyInput.hash(into: &hasher)
    _ = PKCanvasViewDrawingPolicy.anyInput.hashValue
}

func testToolPickerVisibilityRawValuesAndToggle() {
    pkExpectEqual(PKToolPickerVisibility.inactive.rawValue, 1, "inactive")
    pkExpectEqual(PKToolPickerVisibility.hidden.rawValue, 2, "hidden")
    pkExpectEqual(PKToolPickerVisibility.visible.rawValue, 3, "visible")
    pkExpectEqual(PKToolPickerVisibility(rawValue: 2), .hidden, "init")
    pkExpect(PKToolPickerVisibility(rawValue: 0) == nil, "inherited omitted")
    var visibility = PKToolPickerVisibility.hidden
    visibility.toggle()
    pkExpectEqual(visibility, .visible, "hidden -> visible")
    visibility.toggle()
    pkExpectEqual(visibility, .hidden, "visible -> hidden")
    visibility = .inactive
    visibility.toggle()
    pkExpectEqual(visibility, .visible, "inactive -> visible")
    pkExpect(PKToolPickerVisibility.hidden != .visible, "inequality")
    var hasher = Hasher()
    PKToolPickerVisibility.visible.hash(into: &hasher)
    _ = PKToolPickerVisibility.visible.hashValue
}

func testControlOptionsOptionSet() {
    pkExpectEqual(PKToolPickerCustomItem.ControlOptions.width.rawValue, 1, "width bit")
    pkExpectEqual(PKToolPickerCustomItem.ControlOptions.opacity.rawValue, 2, "opacity bit")
    let empty = PKToolPickerCustomItem.ControlOptions()
    pkExpect(empty.isEmpty, "empty")
    pkExpectEqual(empty.rawValue, 0, "zero")
    var options: PKToolPickerCustomItem.ControlOptions = [.width, .opacity]
    pkExpect(options.contains(.width), "contains width")
    pkExpect(options.contains(.opacity), "contains opacity")
    pkExpectEqual(options.union(.width), options, "union")
    pkExpectEqual(options.intersection(.width), .width, "intersection")
    pkExpectEqual(options.symmetricDifference(.width), .opacity, "symmetric")
    pkExpect(options.isSuperset(of: .width), "superset")
    pkExpect(options.isSubset(of: [.width, .opacity]), "subset")
    pkExpect(!options.isDisjoint(with: .width), "not disjoint")
    pkExpect(!options.isStrictSubset(of: options), "not strict subset of self")
    pkExpect(!options.isStrictSuperset(of: options), "not strict super of self")
    let subtracted = options.subtracting(.opacity)
    pkExpectEqual(subtracted, .width, "subtracting")
    options.subtract(.width)
    pkExpectEqual(options, .opacity, "subtract")
    options.formUnion(.width)
    options.formIntersection([.width, .opacity])
    options.formSymmetricDifference(.opacity)
    _ = options.insert(.width)
    _ = options.remove(.width)
    _ = options.update(with: .opacity)
    let fromSequence = PKToolPickerCustomItem.ControlOptions([.width, .opacity])
    pkExpect(fromSequence.contains(.width) && fromSequence.contains(.opacity), "sequence init")
    let literal: PKToolPickerCustomItem.ControlOptions = [.width]
    pkExpectEqual(literal, .width, "array literal")
    pkExpect(PKToolPickerCustomItem.ControlOptions.width != .opacity, "inequality")
}

func testInkTypeRawValuesAndWidths() {
    let cases: [(PKInkingTool.InkType, String, PKContentVersion, CGFloat)] = [
        (.pen, "pen", .version1, 5),
        (.pencil, "pencil", .version1, 5),
        (.marker, "marker", .version1, 15),
        (.monoline, "monoline", .version2, 5),
        (.fountainPen, "fountainPen", .version2, 5),
        (.watercolor, "watercolor", .version2, 20),
        (.crayon, "crayon", .version2, 10),
        (.reed, "reed", .version4, 8),
    ]
    for (inkType, raw, version, width) in cases {
        pkExpectEqual(inkType.rawValue, raw, raw)
        pkExpectEqual(PKInkingTool.InkType(rawValue: raw), inkType, "init \(raw)")
        pkExpectEqual(inkType.requiredContentVersion, version, "version \(raw)")
        pkExpectEqual(inkType.defaultWidth, width, "width \(raw)")
        pkExpectEqual(inkType.validWidthRange, 1...50, "range \(raw)")
        pkExpectEqual(PKInkingTool.defaultWidth(forInkType: inkType), width, "static default")
        pkExpectEqual(PKInkingTool.minimumWidth(forInkType: inkType), 1, "min")
        pkExpectEqual(PKInkingTool.maximumWidth(forInkType: inkType), 50, "max")
    }
    pkExpect(PKInkingTool.InkType(rawValue: "nope") == nil, "unknown ink")
    pkExpect(PKInkingTool.InkType.pen != .marker, "inequality")
    var hasher = Hasher()
    PKInkingTool.InkType.pen.hash(into: &hasher)
    _ = PKInkingTool.InkType.pen.hashValue
}

func testEraserTypeRawValuesAndWidths() {
    pkExpectEqual(PKEraserTool.EraserType.vector.rawValue, 0, "vector")
    pkExpectEqual(PKEraserTool.EraserType.bitmap.rawValue, 1, "bitmap")
    pkExpectEqual(PKEraserTool.EraserType.fixedWidthBitmap.rawValue, 2, "fixed")
    pkExpectEqual(PKEraserTool.EraserType.vector.defaultWidth, 10, "vector default")
    pkExpectEqual(PKEraserTool.EraserType.bitmap.defaultWidth, 20, "bitmap default")
    pkExpectEqual(PKEraserTool.EraserType.fixedWidthBitmap.defaultWidth, 20, "fixed default")
    pkExpectEqual(PKEraserTool.EraserType.vector.validWidthRange, 1...50, "range")
    pkExpect(PKEraserTool.EraserType.vector != .bitmap, "inequality")
    var hasher = Hasher()
    PKEraserTool.EraserType.bitmap.hash(into: &hasher)
    _ = PKEraserTool.EraserType.bitmap.hashValue
}

func testPKFloatRange() {
    let range = __PKFloatRange(location: 1, length: 3)
    pkExpectEqual(range.closedRange, 1...4, "closed")
    let fromClosed = __PKFloatRange(closedRange: 2...5)
    pkExpectEqual(fromClosed.location, 2, "loc")
    pkExpectEqual(fromClosed.length, 3, "len")
}
