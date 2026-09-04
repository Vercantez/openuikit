// UIFont. Owner: text module.
// Metrics are data-driven from Resources/font_metrics.json via FontEngine,
// matching real UIKit exactly (goldens win).

public struct UIFont: Hashable, Sendable {
    public enum Weight: Hashable, Sendable {
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
    public enum Design: Hashable, Sendable { case `default`, monospaced, italic }

    public var pointSize: CGFloat
    public var weight: Weight
    public var design: Design
    /// Extra inter-line spacing `UIFont.leading` reports for a preferred
    /// text-style font. `nil` for `systemFont(ofSize:)` (font-file leading,
    /// 0 at 15 pt). Set only by `UIFont.preferredFont(forTextStyle:)` on
    /// the iOS cut.
    var textStyleLeading: CGFloat? = nil

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

    // Metrics — table lookups through FontEngine (exact for table sizes,
    // linear interpolation between adjacent integer sizes otherwise).
    public var ascender: CGFloat { FontEngine.metrics(for: self).ascender }
    public var descender: CGFloat { FontEngine.metrics(for: self).descender }
    public var lineHeight: CGFloat { FontEngine.metrics(for: self).lineHeight }
    /// The height real UIKit gives ONE line of a UILabel in this font (see
    /// FontEngine.labelLineHeight — it is `lineHeight` plus one point in
    /// three measured size bands).
    public var labelLineHeight: CGFloat { FontEngine.labelLineHeight(for: self) }
    public var capHeight: CGFloat { FontEngine.metrics(for: self).capHeight }
    public var xHeight: CGFloat { FontEngine.metrics(for: self).xHeight }
    public var leading: CGFloat { textStyleLeading ?? FontEngine.metrics(for: self).leading }
}
