import Foundation

public struct PKInk: Equatable {
    public typealias InkType = PKInkingTool.InkType

    public var inkType: InkType
    public var color: PencilKitColor

    public init(_ inkType: InkType, color: PencilKitColor = .black) {
        self.inkType = inkType
        self.color = color
    }

    public var requiredContentVersion: PKContentVersion {
        inkType.requiredContentVersion
    }

    public static func == (lhs: PKInk, rhs: PKInk) -> Bool {
        lhs.inkType == rhs.inkType && pk_colorsEqual(lhs.color, rhs.color)
    }
}

open class PKInkReference: NSObject {
    public var ink: PKInk

    public init(inkType type: __PKInkType, color: PencilKitColor) {
        self.ink = PKInk(type, color: color)
        super.init()
    }

    public var color: PencilKitColor { ink.color }
    public var inkType: __PKInkType { ink.inkType }
    public var requiredContentVersion: PKContentVersion { ink.requiredContentVersion }
}

public typealias __PKInkType = PKInkingTool.InkType

public struct PKInkingTool: PKTool, Equatable {
    public enum InkType: String, Sendable, Hashable {
        case pen
        case pencil
        case marker
        case monoline
        case fountainPen
        case watercolor
        case crayon
        case reed

        /// Linux default widths (points). Apple's exact defaults are an oracle question.
        public var defaultWidth: CGFloat {
            switch self {
            case .pen: return 5
            case .pencil: return 5
            case .marker: return 15
            case .monoline: return 5
            case .fountainPen: return 5
            case .watercolor: return 20
            case .crayon: return 10
            case .reed: return 8
            }
        }

        public var validWidthRange: ClosedRange<CGFloat> {
            1...50
        }

        /// Availability-driven content version: classic inks are v1, iOS 17 inks
        /// are v2, reed (iOS 26) is v4. Exact Apple mapping is corroborated by
        /// availability on the imported overlay, not by runtime measurement.
        public var requiredContentVersion: PKContentVersion {
            switch self {
            case .pen, .pencil, .marker:
                return .version1
            case .monoline, .fountainPen, .watercolor, .crayon:
                return .version2
            case .reed:
                return .version4
            }
        }
    }

    public var inkType: InkType
    public var color: PencilKitColor
    public var width: CGFloat
    public var azimuth: CGFloat

    public init(
        _ inkType: InkType,
        color: PencilKitColor = .black,
        width: CGFloat? = nil,
        azimuth: CGFloat
    ) {
        self.inkType = inkType
        self.color = color
        let resolved = width ?? inkType.defaultWidth
        self.width = PKInkingTool.clampWidth(resolved, for: inkType)
        self.azimuth = azimuth
    }

    public init(_ inkType: InkType, color: PencilKitColor = .black, width: CGFloat? = nil) {
        self.init(inkType, color: color, width: width, azimuth: 0)
    }

    public init(ink: PKInk, width: CGFloat) {
        self.init(ink.inkType, color: ink.color, width: width, azimuth: 0)
    }

    public var ink: PKInk {
        PKInk(inkType, color: color)
    }

    public var requiredContentVersion: PKContentVersion {
        inkType.requiredContentVersion
    }

    public static func defaultWidth(forInkType inkType: __PKInkType) -> CGFloat {
        inkType.defaultWidth
    }

    public static func minimumWidth(forInkType inkType: __PKInkType) -> CGFloat {
        inkType.validWidthRange.lowerBound
    }

    public static func maximumWidth(forInkType inkType: __PKInkType) -> CGFloat {
        inkType.validWidthRange.upperBound
    }

    /// Linux no-op conversion: identity when styles match, otherwise the input
    /// color is returned unchanged. Apple's light/dark ink remapping is not
    /// observed here.
    public static func convertColor(
        _ color: PencilKitColor,
        from: PencilKitUserInterfaceStyle,
        to: PencilKitUserInterfaceStyle
    ) -> PencilKitColor {
        _ = (from, to)
        return color
    }

    public static func convert(
        _ color: PencilKitColor,
        from fromUserInterfaceStyle: PencilKitUserInterfaceStyle,
        to toUserInterfaceStyle: PencilKitUserInterfaceStyle
    ) -> PencilKitColor {
        convertColor(color, from: fromUserInterfaceStyle, to: toUserInterfaceStyle)
    }

    public static func == (lhs: PKInkingTool, rhs: PKInkingTool) -> Bool {
        lhs.inkType == rhs.inkType
            && pk_colorsEqual(lhs.color, rhs.color)
            && lhs.width == rhs.width
            && lhs.azimuth == rhs.azimuth
    }

    static func clampWidth(_ width: CGFloat, for inkType: InkType) -> CGFloat {
        min(max(width, inkType.validWidthRange.lowerBound), inkType.validWidthRange.upperBound)
    }
}

open class PKInkingToolReference: NSObject, PKTool {
    public var tool: PKInkingTool

    public init(inkType type: __PKInkType, color: PencilKitColor, width: CGFloat) {
        self.tool = PKInkingTool(type, color: color, width: width)
        super.init()
    }

    public convenience init(inkType type: __PKInkType, color: PencilKitColor) {
        self.init(inkType: type, color: color, width: type.defaultWidth)
    }

    public init(inkType type: __PKInkType, color: PencilKitColor, width: CGFloat, azimuth angle: CGFloat) {
        self.tool = PKInkingTool(type, color: color, width: width, azimuth: angle)
        super.init()
    }

    public convenience init(ink: PKInk, width: CGFloat) {
        self.init(inkType: ink.inkType, color: ink.color, width: width)
    }

    public var azimuth: CGFloat { tool.azimuth }
    public var color: PencilKitColor { tool.color }
    public var ink: PKInk { tool.ink }
    public var inkType: __PKInkType { tool.inkType }
    public var requiredContentVersion: PKContentVersion { tool.requiredContentVersion }
    public var width: CGFloat { tool.width }

    public class func convert(
        _ color: PencilKitColor,
        from fromUserInterfaceStyle: PencilKitUserInterfaceStyle,
        to toUserInterfaceStyle: PencilKitUserInterfaceStyle
    ) -> PencilKitColor {
        PKInkingTool.convertColor(color, from: fromUserInterfaceStyle, to: toUserInterfaceStyle)
    }

    public class func defaultWidth(forInkType inkType: __PKInkType) -> CGFloat {
        PKInkingTool.defaultWidth(forInkType: inkType)
    }

    public class func maximumWidth(forInkType inkType: __PKInkType) -> CGFloat {
        PKInkingTool.maximumWidth(forInkType: inkType)
    }

    public class func minimumWidth(forInkType inkType: __PKInkType) -> CGFloat {
        PKInkingTool.minimumWidth(forInkType: inkType)
    }
}

public struct PKEraserTool: PKTool, Equatable, Sendable {
    public enum EraserType: Int, Sendable, Hashable {
        case vector = 0
        case bitmap = 1
        case fixedWidthBitmap = 2

        /// Linux default widths. Apple's exact defaults are an oracle question.
        public var defaultWidth: CGFloat {
            switch self {
            case .vector: return 10
            case .bitmap: return 20
            case .fixedWidthBitmap: return 20
            }
        }

        public var validWidthRange: ClosedRange<CGFloat> {
            1...50
        }
    }

    public var eraserType: EraserType
    public var width: CGFloat

    public init(_ eraserType: EraserType) {
        self.init(eraserType, width: eraserType.defaultWidth)
    }

    public init(_ eraserType: EraserType, width: CGFloat) {
        self.eraserType = eraserType
        self.width = min(max(width, eraserType.validWidthRange.lowerBound), eraserType.validWidthRange.upperBound)
    }

    public static func == (lhs: PKEraserTool, rhs: PKEraserTool) -> Bool {
        lhs.eraserType == rhs.eraserType && lhs.width == rhs.width
    }
}

public typealias __PKEraserType = PKEraserTool.EraserType

open class PKEraserToolReference: NSObject, PKTool {
    public var tool: PKEraserTool

    public init(eraserType: __PKEraserType) {
        self.tool = PKEraserTool(eraserType)
        super.init()
    }

    public init(eraserType: __PKEraserType, width: CGFloat) {
        self.tool = PKEraserTool(eraserType, width: width)
        super.init()
    }

    public var eraserType: __PKEraserType { tool.eraserType }
    public var width: CGFloat { tool.width }

    public class func defaultWidth(for eraserType: __PKEraserType) -> CGFloat {
        eraserType.defaultWidth
    }

    public class func maximumWidth(for eraserType: __PKEraserType) -> CGFloat {
        eraserType.validWidthRange.upperBound
    }

    public class func minimumWidth(for eraserType: __PKEraserType) -> CGFloat {
        eraserType.validWidthRange.lowerBound
    }
}

public struct PKLassoTool: PKTool, Equatable, Sendable {
    public init() {}

    public static func == (a: PKLassoTool, b: PKLassoTool) -> Bool {
        true
    }
}

open class PKLassoToolReference: NSObject, PKTool {
    public override init() {
        super.init()
    }
}
