// UIFont. Owner: text module.
// SKELETON — metrics must become data-driven from Resources/font_metrics.json
// (FontEngine.swift), matching real UIKit exactly.

public struct UIFont: Equatable {
    public enum Weight: Equatable, Sendable {
        case ultraLight, thin, light, regular, medium, semibold, bold, heavy, black
        public var name: String {
            switch self {
            case .ultraLight: return "ultraLight"
            case .thin: return "thin"
            case .light: return "light"
            case .regular: return "regular"
            case .medium: return "medium"
            case .semibold: return "semibold"
            case .bold: return "bold"
            case .heavy: return "heavy"
            case .black: return "black"
            }
        }
    }
    public enum Design: Equatable, Sendable { case `default`, monospaced, italic }

    public var pointSize: CGFloat
    public var weight: Weight
    public var design: Design

    public static func systemFont(ofSize size: CGFloat, weight: Weight = .regular) -> UIFont {
        UIFont(pointSize: size, weight: weight, design: .default)
    }
    public static func boldSystemFont(ofSize size: CGFloat) -> UIFont {
        systemFont(ofSize: size, weight: .bold)
    }
    public static func italicSystemFont(ofSize size: CGFloat) -> UIFont {
        UIFont(pointSize: size, weight: .regular, design: .italic)
    }
    public static func monospacedSystemFont(ofSize size: CGFloat, weight: Weight) -> UIFont {
        UIFont(pointSize: size, weight: weight, design: .monospaced)
    }

    // Metrics — text module: replace stubs with FontEngine table lookups.
    public var ascender: CGFloat { FontEngine.metrics(for: self).ascender }
    public var descender: CGFloat { FontEngine.metrics(for: self).descender }
    public var lineHeight: CGFloat { FontEngine.metrics(for: self).lineHeight }
    public var capHeight: CGFloat { FontEngine.metrics(for: self).capHeight }
    public var xHeight: CGFloat { FontEngine.metrics(for: self).xHeight }
    public var leading: CGFloat { FontEngine.metrics(for: self).leading }
}

public struct FontMetrics {
    public var ascender: CGFloat = 0
    public var descender: CGFloat = 0
    public var lineHeight: CGFloat = 0
    public var capHeight: CGFloat = 0
    public var xHeight: CGFloat = 0
    public var leading: CGFloat = 0
}

/// Owner: text module. Data-driven font engine: metrics + string measurement
/// from Resources/font_metrics.json; glyph rasterization via CSTBTrueType.
public enum FontEngine {
    public static func metrics(for font: UIFont) -> FontMetrics {
        // SKELETON: crude approximation until the table is wired up.
        FontMetrics(ascender: font.pointSize * 0.966,
                    descender: -font.pointSize * 0.211,
                    lineHeight: font.pointSize * 1.177,
                    capHeight: font.pointSize * 0.7,
                    xHeight: font.pointSize * 0.5,
                    leading: 0)
    }
    /// Width of a single-line string in points.
    public static func measure(_ text: String, font: UIFont) -> CGFloat {
        // SKELETON
        CGFloat(text.count) * font.pointSize * 0.5
    }
}
