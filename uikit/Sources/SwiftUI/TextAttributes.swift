#if canImport(Foundation)
import Foundation
#elseif canImport(FoundationEssentials)
import FoundationEssentials
#endif
import OpenUIKit

// SwiftUI's AttributedString overlay is independent from its view modifiers.
// Markdown clients use these keys directly when styling parsed runs, so they
// must exist even when no Text view is rendered yet.
public extension _OpenText {
    struct LineStyle: Hashable, Sendable {
        public struct Pattern: Hashable, Sendable {
            private let rawValue: UInt8

            private init(_ rawValue: UInt8) { self.rawValue = rawValue }

            public static let solid = Pattern(0)
            public static let dot = Pattern(1)
            public static let dash = Pattern(2)
            public static let dashDot = Pattern(3)
            public static let dashDotDot = Pattern(4)
        }

        private let pattern: Pattern
        private let color: _OpenColor?

        public init(pattern: Pattern = .solid, color: _OpenColor? = nil) {
            self.pattern = pattern
            self.color = color
        }

        public static let single = LineStyle()
    }
}

#if (canImport(Foundation) || canImport(FoundationEssentials)) && !canImport(SwiftUICore)
@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension AttributeScopes {
    public var swiftUI: SwiftUIAttributes.Type { SwiftUIAttributes.self }

    public struct SwiftUIAttributes: AttributeScope {
        public let font: FontAttribute
        public let foregroundColor: ForegroundColorAttribute
        public let backgroundColor: BackgroundColorAttribute
        public let strikethroughStyle: StrikethroughStyleAttribute
        public let underlineStyle: UnderlineStyleAttribute
        public let kern: KerningAttribute
        public let tracking: TrackingAttribute
        public let baselineOffset: BaselineOffsetAttribute
        public let foundation: AttributeScopes.FoundationAttributes
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension AttributeDynamicLookup {
    public subscript<T: AttributedStringKey>(
        dynamicMember keyPath: KeyPath<AttributeScopes.SwiftUIAttributes, T>
    ) -> T {
        fatalError("AttributeDynamicLookup values are only used as key paths")
    }
}

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension AttributeScopes.SwiftUIAttributes {
    public enum FontAttribute: AttributedStringKey, Sendable {
        public typealias Value = _OpenFont
        public static let name = "SwiftUI.Font"
    }

    public enum ForegroundColorAttribute: AttributedStringKey, Sendable {
        public typealias Value = _OpenColor
        public static let name = "SwiftUI.ForegroundColor"
    }

    public enum BackgroundColorAttribute: AttributedStringKey, Sendable {
        public typealias Value = _OpenColor
        public static let name = "SwiftUI.BackgroundColor"
    }

    public enum StrikethroughStyleAttribute: AttributedStringKey, Sendable {
        public typealias Value = _OpenText.LineStyle
        public static let name = "SwiftUI.StrikethroughStyle"
    }

    public enum UnderlineStyleAttribute: AttributedStringKey, Sendable {
        public typealias Value = _OpenText.LineStyle
        public static let name = "SwiftUI.UnderlineStyle"
    }

    public enum KerningAttribute: AttributedStringKey, Sendable {
        public typealias Value = CGFloat
        public static let name = "SwiftUI.Kern"
    }

    public enum TrackingAttribute: AttributedStringKey, Sendable {
        public typealias Value = CGFloat
        public static let name = "SwiftUI.Tracking"
    }

    public enum BaselineOffsetAttribute: AttributedStringKey, Sendable {
        public typealias Value = CGFloat
        public static let name = "SwiftUI.BaselineOffset"
    }
}
#endif
