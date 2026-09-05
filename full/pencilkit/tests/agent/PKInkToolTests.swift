import PencilKit
import Foundation

func testPKInkInitAndEquality() {
    let ink = PKInk(.pen, color: .black)
    pkExpectEqual(ink.inkType, .pen, "type")
    pkExpectEqual(ink.requiredContentVersion, .version1, "version")
    pkExpectEqual(PKInk(.pen, color: .black), ink, "color via ink eq")
    let copy = PKInk(.pen, color: .black)
    pkExpectEqual(ink, copy, "equal")
    pkExpect(PKInk(.marker, color: .black) != ink, "type differs")
    typealias InkAlias = PKInk.InkType
    pkExpectEqual(InkAlias.pen, PKInkingTool.InkType.pen, "alias")
}

func testPKInkingToolInitClampAndConvert() {
    let tool = PKInkingTool(.pencil, color: .black, width: 5, azimuth: 0.25)
    pkExpectEqual(tool.inkType, .pencil, "type")
    pkExpectEqual(tool.width, 5, "width")
    pkExpectEqual(tool.azimuth, 0.25, "azimuth")
    pkExpectEqual(tool.ink.inkType, .pencil, "ink")
    pkExpectEqual(tool.requiredContentVersion, .version1, "version")
    let clampedLow = PKInkingTool(.pen, width: 0)
    pkExpectEqual(clampedLow.width, 1, "clamp low")
    let clampedHigh = PKInkingTool(.pen, width: 99)
    pkExpectEqual(clampedHigh.width, 50, "clamp high")
    let fromInk = PKInkingTool(ink: PKInk(.marker), width: 12)
    pkExpectEqual(fromInk.inkType, .marker, "from ink")
    pkExpectEqual(fromInk.width, 12, "from ink width")
    let defaulted = PKInkingTool(.watercolor)
    pkExpectEqual(defaulted.width, 20, "default watercolor")
    let same = PKInkingTool.convertColor(.black, from: .light, to: .light)
    pkExpectEqual(PKInk(.pen, color: same), PKInk(.pen, color: .black), "identity convert")
    let cross = PKInkingTool.convertColor(.black, from: .light, to: .dark)
    pkExpectEqual(PKInk(.pen, color: cross), PKInk(.pen, color: .black), "fail-closed convert")
    pkExpect(tool == PKInkingTool(.pencil, color: .black, width: 5, azimuth: 0.25), "eq")
    pkExpect(tool != PKInkingTool(.pen), "neq")
}

func testPKInkingToolReference() {
    let reference = PKInkingToolReference(inkType: .pen, color: .black, width: 6)
    pkExpectEqual(reference.inkType, .pen, "type")
    pkExpectEqual(reference.width, 6, "width")
    pkExpectEqual(reference.azimuth, 0, "azimuth")
    pkExpectEqual(reference.requiredContentVersion, .version1, "version")
    _ = reference.ink
    _ = reference.color
    let convenience = PKInkingToolReference(inkType: .marker, color: .black)
    pkExpectEqual(convenience.width, 15, "default marker width")
    let withAzimuth = PKInkingToolReference(inkType: .pen, color: .black, width: 4, azimuth: 1)
    pkExpectEqual(withAzimuth.azimuth, 1, "azimuth init")
    let fromInk = PKInkingToolReference(ink: PKInk(.crayon), width: 9)
    pkExpectEqual(fromInk.inkType, .crayon, "ink init")
    pkExpectEqual(PKInkingToolReference.defaultWidth(forInkType: .pen), 5, "class default")
    pkExpectEqual(PKInkingToolReference.minimumWidth(forInkType: .pen), 1, "class min")
    pkExpectEqual(PKInkingToolReference.maximumWidth(forInkType: .pen), 50, "class max")
    let converted = PKInkingToolReference.convert(.white, from: .unspecified, to: .unspecified)
    pkExpectEqual(PKInk(.pen, color: converted), PKInk(.pen, color: .white), "class convert")
}

func testPKEraserToolInitAndReference() {
    let eraser = PKEraserTool(.vector)
    pkExpectEqual(eraser.eraserType, .vector, "type")
    pkExpectEqual(eraser.width, 10, "default width")
    let wide = PKEraserTool(.bitmap, width: 30)
    pkExpectEqual(wide.width, 30, "width")
    pkExpect(eraser != wide, "neq")
    pkExpect(eraser == PKEraserTool(.vector, width: 10), "eq")
    let reference = PKEraserToolReference(eraserType: .vector)
    pkExpectEqual(reference.eraserType, .vector, "ref type")
    pkExpectEqual(reference.width, 10, "ref width")
    let sized = PKEraserToolReference(eraserType: .fixedWidthBitmap, width: 12)
    pkExpectEqual(sized.width, 12, "sized")
    pkExpectEqual(PKEraserToolReference.defaultWidth(for: .vector), 10, "class default")
    pkExpectEqual(PKEraserToolReference.minimumWidth(for: .vector), 1, "class min")
    pkExpectEqual(PKEraserToolReference.maximumWidth(for: .vector), 50, "class max")
}

func testPKLassoToolEquality() {
    pkExpect(PKLassoTool() == PKLassoTool(), "eq")
    pkExpect(!(PKLassoTool() != PKLassoTool()), "neq operator")
    _ = PKLassoToolReference()
}

func testPKAppleDrawingTypeIdentifier() {
    pkExpectEqual(
        PKAppleDrawingTypeIdentifier as String,
        "com.apple.pkdrawing",
        "uti"
    )
    pkExpectEqual(PKDrawingOpenUIKitMagic, Data([0x4F, 0x50, 0x4B, 0x31]), "magic")
}
