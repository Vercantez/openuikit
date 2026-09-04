import CoreFoundation
import Foundation

extension AttributedString {
    public enum TextAlignment: String, Codable, Hashable, Sendable, CaseIterable {
        case left
        case right
        case center
    }

    public struct LineHeight: Hashable, Sendable, Codable {
        enum Kind: Hashable, Sendable, Codable {
            case tight
            case normal
            case loose
            case variable
            case exact(CGFloat)
            case leading(CGFloat)
            case multiple(CGFloat)
        }

        var kind: Kind

        public static var tight: LineHeight { LineHeight(kind: .tight) }
        public static var normal: LineHeight { LineHeight(kind: .normal) }
        public static var loose: LineHeight { LineHeight(kind: .loose) }
        public static var variable: LineHeight { LineHeight(kind: .variable) }

        public static func exact(points: CGFloat) -> LineHeight {
            LineHeight(kind: .exact(points))
        }

        public static func leading(increase: CGFloat) -> LineHeight {
            LineHeight(kind: .leading(increase))
        }

        public static func multiple(factor: CGFloat) -> LineHeight {
            LineHeight(kind: .multiple(factor))
        }
    }
}

extension AttributeScopes {
    public struct CoreTextAttributes: AttributeScope {
        public var coreTextLineHeight: LineHeightAttribute
        public var coreTextAlignment: TextAlignmentAttribute

        @frozen public enum LineHeightAttribute: CodableAttributedStringKey, Sendable {
            public typealias Value = AttributedString.LineHeight
            public static let name = "SwiftUI.Character.LineHeight"
            public static let runBoundaries: AttributedString.AttributeRunBoundaries? = .paragraph
            public static var inheritedByAddedText: Bool { true }
            public static var invalidationConditions: Set<AttributedString.AttributeInvalidationCondition>? {
                nil
            }
        }

        @frozen public enum TextAlignmentAttribute: CodableAttributedStringKey, Sendable {
            public typealias Value = AttributedString.TextAlignment
            public static let name = "SwiftUI.Character.TextAlignment"
            public static let runBoundaries: AttributedString.AttributeRunBoundaries? = .paragraph
            public static var inheritedByAddedText: Bool { true }
            public static var invalidationConditions: Set<AttributedString.AttributeInvalidationCondition>? {
                nil
            }
        }
    }
}
