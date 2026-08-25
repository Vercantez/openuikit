// Dynamic Type: UIContentSizeCategory, UIFont.TextStyle,
// UIFont.preferredFont(forTextStyle:), UIFontDescriptor
// .preferredFontDescriptor(withTextStyle:) and UIFontMetrics.
// Owner: text module (M14).
//
// docs/APP_COMPAT.md ranks Dynamic Type as the largest remaining cluster
// (~142 uses across the four-app corpus). It is entirely a table of numbers,
// and NONE of them are guessed: Resources/dynamic_type.json is the verbatim
// dump of Tools/oracle2/dyntypeprobe running on real iOS 26 in the Simulator
// (scripts/dyntype_probe_sim.sh). For every one of the 11 text styles x 12
// content size categories it records what real UIKit returns for
//
//   UIFontDescriptor.preferredFontDescriptor(withTextStyle:compatibleWith:)
//   UIFont.preferredFont(forTextStyle:compatibleWith:)   (+ line metrics)
//   UIFontMetrics(forTextStyle:).scaledValue(for: v, compatibleWith:)
//   UIFontMetrics(forTextStyle:).scaledFont(for: .systemFont(ofSize: v, …))
//
// at 19 base values spanning 8...64 pt.
//
// WHAT IS EXACT AND WHAT IS NOT — stated plainly:
//
//   * At the default category (`.large`, what a device ships with and what
//     OpenUIKit renders unless told otherwise) real UIKit's scaledValue is
//     the IDENTITY for every style and every base value in the probe. Our
//     table reproduces that exactly, so a default-Dynamic-Type app gets
//     real-UIKit point sizes.
//   * At the other 11 categories the probed base values are exact table
//     lookups. Base values BETWEEN probe points are linearly interpolated.
//     Real UIKit's curve is not a plain ratio — measured, it is piecewise
//     with 1/3-pt quantization and the slope changes at sizes the probe does
//     not resolve — so interpolated values can be off by up to ~2/3 pt at
//     large accessibility sizes. Extending the probe's `baseValues` list
//     closes that; nothing here is hand-tuned to hide it.
//   * There is no notification when the category changes: OpenUIKit has no
//     Settings app. `UIApplication.shared.preferredContentSizeCategory` is
//     settable by a host, and `adjustsFontForContentSizeCategory` is honoured
//     at layout time.

/// Real UIKit's `UIContentSizeCategory` (a String-backed struct).
public struct UIContentSizeCategory: Hashable, RawRepresentable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let extraSmall = UIContentSizeCategory(rawValue: "extraSmall")
    public static let small = UIContentSizeCategory(rawValue: "small")
    public static let medium = UIContentSizeCategory(rawValue: "medium")
    public static let large = UIContentSizeCategory(rawValue: "large")
    public static let extraLarge = UIContentSizeCategory(rawValue: "extraLarge")
    public static let extraExtraLarge = UIContentSizeCategory(rawValue: "extraExtraLarge")
    public static let extraExtraExtraLarge =
        UIContentSizeCategory(rawValue: "extraExtraExtraLarge")
    public static let accessibilityMedium =
        UIContentSizeCategory(rawValue: "accessibilityMedium")
    public static let accessibilityLarge =
        UIContentSizeCategory(rawValue: "accessibilityLarge")
    public static let accessibilityExtraLarge =
        UIContentSizeCategory(rawValue: "accessibilityExtraLarge")
    public static let accessibilityExtraExtraLarge =
        UIContentSizeCategory(rawValue: "accessibilityExtraExtraLarge")
    public static let accessibilityExtraExtraExtraLarge =
        UIContentSizeCategory(rawValue: "accessibilityExtraExtraExtraLarge")
    public static let unspecified = UIContentSizeCategory(rawValue: "unspecified")

    public var isAccessibilityCategory: Bool { rawValue.hasPrefix("accessibility") }
}

extension UIFont {
    /// Real UIKit's `UIFont.TextStyle`.
    public struct TextStyle: Hashable, RawRepresentable, Sendable {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let largeTitle = TextStyle(rawValue: "largeTitle")
        public static let title1 = TextStyle(rawValue: "title1")
        public static let title2 = TextStyle(rawValue: "title2")
        public static let title3 = TextStyle(rawValue: "title3")
        public static let headline = TextStyle(rawValue: "headline")
        public static let subheadline = TextStyle(rawValue: "subheadline")
        public static let body = TextStyle(rawValue: "body")
        public static let callout = TextStyle(rawValue: "callout")
        public static let footnote = TextStyle(rawValue: "footnote")
        public static let caption1 = TextStyle(rawValue: "caption1")
        public static let caption2 = TextStyle(rawValue: "caption2")
    }
}

/// Resources/dynamic_type.json, decoded once.
enum DynamicTypeTable {
    struct Entry {
        var pointSize: CGFloat
        var bold: Bool
        var scaled: [CGFloat]
        var scaledFont: [CGFloat]
    }

    /// The base values the probe measured, ascending.
    private(set) static var bases: [CGFloat] = []
    /// style raw value -> category raw value -> entry.
    private(set) static var table: [String: [String: Entry]] = [:]

    static let isAvailable: Bool = load()

    private static func load() -> Bool {
        guard let json = ResourceIO.loadJSONResource("dynamic_type.json"),
              let baseArr = json["bases"]?.arrayValue,
              let styles = json["styles"]?.objectValue else { return false }
        bases = baseArr.compactMap { $0.doubleValue.map { CGFloat($0) } }
        for (style, catsJ) in styles {
            guard let cats = catsJ.objectValue else { continue }
            var byCat: [String: Entry] = [:]
            for (cat, eJ) in cats {
                guard let e = eJ.objectValue,
                      let pt = e["pointSize"]?.doubleValue else { continue }
                byCat[cat] = Entry(
                    pointSize: CGFloat(pt),
                    bold: e["bold"]?.boolValue ?? false,
                    scaled: (e["scaled"]?.arrayValue ?? [])
                        .compactMap { $0.doubleValue.map { CGFloat($0) } },
                    scaledFont: (e["scaledFont"]?.arrayValue ?? [])
                        .compactMap { $0.doubleValue.map { CGFloat($0) } })
            }
            table[style] = byCat
        }
        return !table.isEmpty
    }

    static func entry(style: UIFont.TextStyle,
                      category: UIContentSizeCategory) -> Entry? {
        guard let byCat = table[style.rawValue] else { return nil }
        return byCat[category.rawValue] ?? byCat[UIContentSizeCategory.large.rawValue]
    }

    /// Piecewise-linear read of one of the measured curves. Below/above the
    /// probed range the nearest segment's slope is extended, which is what
    /// real UIKit does for the linear part of its own curve.
    static func interpolate(_ curve: [CGFloat], at v: CGFloat) -> CGFloat? {
        guard curve.count == bases.count, !bases.isEmpty else { return nil }
        if v <= bases[0] {
            guard bases.count >= 2 else { return curve[0] }
            let t = (v - bases[0]) / (bases[1] - bases[0])
            return curve[0] + t * (curve[1] - curve[0])
        }
        for i in 1..<bases.count where v <= bases[i] {
            if v == bases[i] { return curve[i] }
            let t = (v - bases[i - 1]) / (bases[i] - bases[i - 1])
            return curve[i - 1] + t * (curve[i] - curve[i - 1])
        }
        let n = bases.count
        guard n >= 2 else { return curve[n - 1] }
        let t = (v - bases[n - 2]) / (bases[n - 1] - bases[n - 2])
        return curve[n - 2] + t * (curve[n - 1] - curve[n - 2])
    }
}

extension UIFontDescriptor {
    /// Real UIKit's `preferredFontDescriptor(withTextStyle:)`.
    public static func preferredFontDescriptor(
        withTextStyle style: UIFont.TextStyle) -> UIFontDescriptor {
        preferredFontDescriptor(withTextStyle: style,
                                compatibleWith: UITraitCollection.current)
    }

    public static func preferredFontDescriptor(
        withTextStyle style: UIFont.TextStyle,
        compatibleWith traits: UITraitCollection?) -> UIFontDescriptor {
        let cat = (traits ?? UITraitCollection.current).preferredContentSizeCategory
        guard let e = DynamicTypeTable.entry(style: style, category: cat) else {
            // Table absent (portability fallback, same shape as
            // GlyphInkTable): body's default size.
            return UIFontDescriptor(pointSize: 17, weight: .regular)
        }
        return UIFontDescriptor(pointSize: e.pointSize,
                                weight: e.bold ? .semibold : .regular)
    }
}

extension UIFont {
    /// Real UIKit's `UIFont.preferredFont(forTextStyle:)`. The weight comes
    /// from the probe: only `.headline` is semibold on iOS 26.
    public static func preferredFont(forTextStyle style: TextStyle) -> UIFont {
        preferredFont(forTextStyle: style, compatibleWith: UITraitCollection.current)
    }

    public static func preferredFont(forTextStyle style: TextStyle,
                                     compatibleWith traits: UITraitCollection?) -> UIFont {
        let d = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style,
                                                         compatibleWith: traits)
        return UIFont(pointSize: d.pointSize, weight: d.weight, design: .default)
    }
}

/// Real UIKit's `UIFontMetrics`.
public final class UIFontMetrics {
    public let textStyle: UIFont.TextStyle

    public init(forTextStyle textStyle: UIFont.TextStyle) {
        self.textStyle = textStyle
    }

    /// `UIFontMetrics.default` is the body metrics (documented UIKit
    /// behaviour, confirmed by the probe: `.default` and `.body` agree).
    public static let `default` = UIFontMetrics(forTextStyle: .body)

    public func scaledValue(for value: CGFloat) -> CGFloat {
        scaledValue(for: value, compatibleWith: UITraitCollection.current)
    }

    public func scaledValue(for value: CGFloat,
                            compatibleWith traits: UITraitCollection?) -> CGFloat {
        let cat = (traits ?? UITraitCollection.current).preferredContentSizeCategory
        guard let e = DynamicTypeTable.entry(style: textStyle, category: cat),
              let v = DynamicTypeTable.interpolate(e.scaled, at: value) else {
            return value
        }
        return v
    }

    public func scaledFont(for font: UIFont) -> UIFont {
        scaledFont(for: font, compatibleWith: UITraitCollection.current)
    }

    public func scaledFont(for font: UIFont,
                           compatibleWith traits: UITraitCollection?) -> UIFont {
        let cat = (traits ?? UITraitCollection.current).preferredContentSizeCategory
        guard let e = DynamicTypeTable.entry(style: textStyle, category: cat),
              let pt = DynamicTypeTable.interpolate(e.scaledFont, at: font.pointSize) else {
            return font
        }
        var f = font
        f.pointSize = pt
        return f
    }

    public func scaledFont(for font: UIFont, maximumPointSize: CGFloat) -> UIFont {
        scaledFont(for: font, maximumPointSize: maximumPointSize,
                   compatibleWith: UITraitCollection.current)
    }

    public func scaledFont(for font: UIFont, maximumPointSize: CGFloat,
                           compatibleWith traits: UITraitCollection?) -> UIFont {
        var f = scaledFont(for: font, compatibleWith: traits)
        if f.pointSize > maximumPointSize { f.pointSize = maximumPointSize }
        return f
    }

    public func scaledValue(for value: CGFloat, maximumPointSize: CGFloat) -> CGFloat {
        min(scaledValue(for: value), maximumPointSize)
    }
}
