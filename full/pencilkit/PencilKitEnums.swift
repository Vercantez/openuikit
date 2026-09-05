import Foundation

/// PencilKit document format generations. Raw values match the macios
/// corroboration of the imported `NS_ENUM` (`version1 = 1` … `version4 = 4`).
public enum PKContentVersion: Int, Sendable, Hashable {
    case version1 = 1
    case version2 = 2
    case version3 = 3
    case version4 = 4

    public static var latest: PKContentVersion { .version4 }
}

/// Canvas input policy. Raw values match the imported `NS_ENUM` order
/// (`default = 0`, `anyInput = 1`, `pencilOnly = 2`).
public enum PKCanvasViewDrawingPolicy: UInt, Sendable, Hashable {
    case `default` = 0
    case anyInput = 1
    case pencilOnly = 2
}

/// Tool-picker chrome visibility. The Swift overlay publishes `hidden`,
/// `inactive`, and `visible`. Independent bindings also list `inherited` as
/// raw value 0; that case is not in the pinned graph, so Linux uses the
/// overlay cases with C raw values `inactive = 1`, `hidden = 2`, `visible = 3`.
public enum PKToolPickerVisibility: Int, Sendable, Hashable {
    case inactive = 1
    case hidden = 2
    case visible = 3

    /// Linux toggle: `visible` becomes `hidden`; any other case becomes `visible`.
    /// Apple's exact cycle (and whether `inactive` participates) is an oracle question.
    public mutating func toggle() {
        if self == .visible {
            self = .hidden
        } else {
            self = .visible
        }
    }
}

extension PKToolPickerCustomItem {
    /// Attribute chrome shown beside a custom tool. Bit values match the
    /// imported option set (`width = 1 << 0`, `opacity = 1 << 1`).
    public struct ControlOptions: OptionSet, Sendable, Hashable {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        public static let width = ControlOptions(rawValue: 1 << 0)
        public static let opacity = ControlOptions(rawValue: 1 << 1)
    }
}

/// ObjC `PKFloatRange` stand-in used by reference-class interpolation APIs.
public struct __PKFloatRange: Equatable, Sendable {
    public var location: CGFloat
    public var length: CGFloat

    public init(location: CGFloat, length: CGFloat) {
        self.location = location
        self.length = length
    }

    public init(closedRange: ClosedRange<CGFloat>) {
        self.location = closedRange.lowerBound
        self.length = closedRange.upperBound - closedRange.lowerBound
    }

    public var closedRange: ClosedRange<CGFloat> {
        let upper = location + length
        if upper >= location {
            return location...upper
        }
        return location...location
    }
}

func pk_closedRangeToFloatRange(_ range: ClosedRange<CGFloat>) -> __PKFloatRange {
    __PKFloatRange(closedRange: range)
}
