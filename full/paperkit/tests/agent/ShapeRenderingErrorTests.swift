import PaperKit
import Foundation

func testShapeConfigurationDefaults() {
    let configuration = ShapeConfiguration(type: .rectangle)
    precondition(configuration.type == .rectangle)
    precondition(configuration.strokeColor == nil)
    precondition(configuration.lineWidth == 0)
    let fill = configuration.fillColor
    precondition(fill != nil)
    let parts = (fill!.red, fill!.green, fill!.blue, fill!.alpha)
    precondition(parts.0 == 0 && parts.1 == 0 && parts.2 == 0 && parts.3 == 1)
}

func testShapeConfigurationExplicitColors() {
    let stroke = CGColor(srgbRed: 1, green: 0, blue: 0, alpha: 1)
    let fill = CGColor(srgbRed: 0, green: 1, blue: 0, alpha: 0.5)
    let configuration = ShapeConfiguration(
        type: .ellipse,
        fillColor: fill,
        strokeColor: stroke,
        lineWidth: 2.5
    )
    precondition(configuration.type == .ellipse)
    precondition(configuration.lineWidth == 2.5)
    precondition(configuration.strokeColor != nil)
    precondition(configuration.fillColor != nil)
}

func testShapeConfigurationShapeCases() {
    let expected: [ShapeConfiguration.Shape] = [
        .rectangle, .ellipse, .line, .chatBubble,
        .roundedRectangle, .regularPolygon, .star, .arrowShape,
    ]
    precondition(ShapeConfiguration.Shape.allCases == expected)
    let typed: ShapeConfiguration.Shape.AllCases = ShapeConfiguration.Shape.allCases
    precondition(typed.count == 8)
    precondition(ShapeConfiguration.Shape.star == .star)
    precondition(ShapeConfiguration.Shape.star != .rectangle)
    var hasher = Hasher()
    ShapeConfiguration.Shape.arrowShape.hash(into: &hasher)
    _ = ShapeConfiguration.Shape.line.hashValue
}

func testRenderingOptionsDefaults() {
    let options = RenderingOptions()
    precondition(options.darkUserInterfaceStyle == false)
    precondition(options.rightToLeftLayoutDirection == false)
    let dark = RenderingOptions(darkUserInterfaceStyle: true, layoutRightToLeft: true)
    precondition(dark.darkUserInterfaceStyle)
    precondition(dark.rightToLeftLayoutDirection)
    precondition(options != dark)
    precondition(options == RenderingOptions(darkUserInterfaceStyle: false, layoutRightToLeft: false))
}

func testRenderingOptionsTraitCollection() {
    let dark = UITraitCollection(userInterfaceStyle: .dark, layoutDirection: .leftToRight)
    let options = RenderingOptions(traitCollection: dark)
    precondition(options.darkUserInterfaceStyle)
    precondition(!options.rightToLeftLayoutDirection)

    let rtl = UITraitCollection(userInterfaceStyle: .light, layoutDirection: .rightToLeft)
    let rtlOptions = RenderingOptions(traitCollection: rtl)
    precondition(!rtlOptions.darkUserInterfaceStyle)
    precondition(rtlOptions.rightToLeftLayoutDirection)
}

func testMarkupErrorCases() {
    let errors: [MarkupError] = [.incorrectFormat, .malformedData, .incompatibleFormatTooNew]
    precondition(errors[0] == .incorrectFormat)
    precondition(errors[1] != .incorrectFormat)
    precondition(MarkupError.malformedData.localizedDescription.contains("malformed"))
    precondition(MarkupError.incorrectFormat.localizedDescription.contains("header"))
    precondition(MarkupError.incompatibleFormatTooNew.localizedDescription.contains("newer"))
    var hasher = Hasher()
    MarkupError.incorrectFormat.hash(into: &hasher)
    _ = MarkupError.malformedData.hashValue
}

func testUTTypePaperkit() {
    let type = UTType.paperkit
    precondition(!type.identifier.isEmpty)
    precondition(type.identifier.contains("paperkit"))
}
