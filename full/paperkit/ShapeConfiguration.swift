import Foundation

/// A configuration that specifies the appearance of a shape.
public struct ShapeConfiguration: Sendable {
    /// The type of shape.
    public var type: Shape
    /// The fill color of the shape.
    ///
    /// Defaults to black.
    public var fillColor: CGColor?
    /// The stroke color of the shape.
    ///
    /// Defaults to `nil`.
    public var strokeColor: CGColor?
    /// The line width of the shape.
    ///
    /// Defaults to `0`.
    public var lineWidth: CGFloat

    /// Create a new shape configuration.
    public init(
        type: Shape,
        fillColor: CGColor? = CGColor(srgbRed: 0, green: 0, blue: 0, alpha: 1),
        strokeColor: CGColor? = nil,
        lineWidth: CGFloat = 0
    ) {
        self.type = type
        self.fillColor = fillColor
        self.strokeColor = strokeColor
        self.lineWidth = lineWidth
    }

    public enum Shape: Equatable, Hashable, Sendable, CaseIterable {
        /// A rectangle shape.
        case rectangle
        /// An ellipse shape.
        case ellipse
        /// A line shape.
        case line
        /// A chat bubble shape.
        case chatBubble
        /// A rounded rectangle.
        case roundedRectangle
        /// A n-sided polygon shape.
        case regularPolygon
        /// A n-pointed star shape.
        case star
        /// A filled arrow shape.
        case arrowShape
    }

    var linuxTypeName: String {
        switch type {
        case .rectangle: return "rectangle"
        case .ellipse: return "ellipse"
        case .line: return "line"
        case .chatBubble: return "chatBubble"
        case .roundedRectangle: return "roundedRectangle"
        case .regularPolygon: return "regularPolygon"
        case .star: return "star"
        case .arrowShape: return "arrowShape"
        }
    }

    static func shape(named name: String) -> Shape? {
        switch name {
        case "rectangle": return .rectangle
        case "ellipse": return .ellipse
        case "line": return .line
        case "chatBubble": return .chatBubble
        case "roundedRectangle": return .roundedRectangle
        case "regularPolygon": return .regularPolygon
        case "star": return .star
        case "arrowShape": return .arrowShape
        default: return nil
        }
    }
}
