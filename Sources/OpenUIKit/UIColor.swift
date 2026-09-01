// UIColor + UITraitCollection. Owner: color module.
// Semantic color resolution is data-driven from Resources/system_colors.json
// (see SystemColors.swift).

// M15: a DEFAULT ARGUMENT or an `@inlinable` body may only use members whose
// defining module THIS FILE imports -- `CGRect.zero` and `CGFloat.pi` do not
// ride in on OpenCoreGraphics' typealias the way ordinary uses do. These are
// SCOPED imports on purpose: they satisfy that rule without pulling in
// CoreGraphics' CGColor / CGAffineTransform, which would collide with
// OpenCoreGraphics' own. One knock-on, measured: in a file where the name is
// visible twice, `[CGFloat](repeating:count:)` array sugar stops parsing as a
// type; spell it `Array<CGFloat>(...)`.
#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGPoint
import struct CoreGraphics.CGRect
import struct CoreGraphics.CGSize
#elseif canImport(Foundation)
import Foundation
#endif


public enum UIUserInterfaceStyle: Sendable {
    case unspecified, light, dark
}

/// Raw values match UIKit's `UIUserInterfaceSizeClass`.
public enum UIUserInterfaceSizeClass: Int, Sendable {
    case unspecified = 0
    case compact = 1
    case regular = 2
}

/// Raw values are Darwin's `UIUserInterfaceLayoutDirection` (UIApplication.h).
/// Auto Layout in OpenUIKit is LTR throughout — `leading` aliases `left`
/// everywhere (docs/KNOWN_GAPS.md) — so this is a declared value, not a
/// switch: nothing in the layout or render path reads it.
public enum UIUserInterfaceLayoutDirection: Int, Sendable {
    case leftToRight = 0, rightToLeft = 1
}

public struct UITraitCollection: Equatable, Sendable {
    public var userInterfaceStyle: UIUserInterfaceStyle
    public var displayScale: CGFloat
    public var horizontalSizeClass: UIUserInterfaceSizeClass
    public var verticalSizeClass: UIUserInterfaceSizeClass
    /// Dynamic Type setting (M14). A partial collection defaults to
    /// `.unspecified`; OpenUIKit's complete host environment defaults to
    /// `.large`, the category where every `UIFontMetrics` factor is 1.0.
    public var preferredContentSizeCategory: UIContentSizeCategory

    /// UIKit's empty collection: every modeled trait is unspecified.
    public init() {
        userInterfaceStyle = .unspecified
        displayScale = 0
        horizontalSizeClass = .unspecified
        verticalSizeClass = .unspecified
        preferredContentSizeCategory = .unspecified
    }

    /// UIKit's partial collection containing only an interface style.
    public init(userInterfaceStyle: UIUserInterfaceStyle) {
        self.init()
        self.userInterfaceStyle = userInterfaceStyle
    }

    /// UIKit's partial collection containing only a display scale.
    public init(displayScale: CGFloat) {
        self.init()
        self.displayScale = displayScale
    }

    /// UIKit's partial collection containing only a horizontal size class.
    public init(horizontalSizeClass: UIUserInterfaceSizeClass) {
        self.init()
        self.horizontalSizeClass = horizontalSizeClass
    }

    /// UIKit's partial collection containing only a vertical size class.
    public init(verticalSizeClass: UIUserInterfaceSizeClass) {
        self.init()
        self.verticalSizeClass = verticalSizeClass
    }

    /// UIKit's partial collection containing only a Dynamic Type category.
    public init(preferredContentSizeCategory: UIContentSizeCategory) {
        self.init()
        self.preferredContentSizeCategory = preferredContentSizeCategory
    }

    /// OpenUIKit host convenience: construct a complete render environment in
    /// one call. The existing style/scale spelling is retained; size classes
    /// may be supplied by a host that already knows them, while `.unspecified`
    /// lets UIScreen/UIWindow derive the portable bounds approximation.
    public init(
        userInterfaceStyle: UIUserInterfaceStyle,
        displayScale: CGFloat,
        horizontalSizeClass: UIUserInterfaceSizeClass = .unspecified,
        verticalSizeClass: UIUserInterfaceSizeClass = .unspecified,
        preferredContentSizeCategory: UIContentSizeCategory = .large
    ) {
        self.userInterfaceStyle = userInterfaceStyle
        self.displayScale = displayScale
        self.horizontalSizeClass = horizontalSizeClass
        self.verticalSizeClass = verticalSizeClass
        self.preferredContentSizeCategory = preferredContentSizeCategory
    }

    /// UIKit's legacy merge initializer. Later collections win for each trait,
    /// but an unspecified/default value does not erase an earlier value. This
    /// includes Dynamic Type deliberately; it is part of the modeled trait
    /// environment rather than an unrelated OpenUIKit setting.
    public init(traitsFrom traitCollections: [UITraitCollection]) {
        self.init()
        for traits in traitCollections {
            if traits.userInterfaceStyle != .unspecified {
                userInterfaceStyle = traits.userInterfaceStyle
            }
            if traits.displayScale != 0 {
                displayScale = traits.displayScale
            }
            if traits.horizontalSizeClass != .unspecified {
                horizontalSizeClass = traits.horizontalSizeClass
            }
            if traits.verticalSizeClass != .unspecified {
                verticalSizeClass = traits.verticalSizeClass
            }
            if traits.preferredContentSizeCategory != .unspecified {
                preferredContentSizeCategory = traits.preferredContentSizeCategory
            }
        }
    }

    /// A portable host approximation, not Apple's idiom/multitasking policy:
    /// each unspecified axis becomes regular at 600 pt and compact below it.
    /// Explicit host/current axes remain authoritative.
    mutating func _resolveUnspecifiedSizeClasses(for size: CGSize) {
        if horizontalSizeClass == .unspecified {
            horizontalSizeClass = size.width >= 600 ? .regular : .compact
        }
        if verticalSizeClass == .unspecified {
            verticalSizeClass = size.height >= 600 ? .regular : .compact
        }
    }

    /// Process-wide current traits (real UIKit: UITraitCollection.current).
    public static var current = UITraitCollection(userInterfaceStyle: .light,
                                                   displayScale: 2)
}

public class UIColor: Hashable, @unchecked Sendable {
    /// Static color, or a named semantic color resolved via traits.
    enum Storage {
        case fixed(CGColor)
        case semantic(name: String)
        case dynamic((UITraitCollection) -> CGColor)
    }
    let storage: Storage

    public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        storage = .fixed(CGColor(red: red, green: green, blue: blue, alpha: alpha))
    }
    public init(white: CGFloat, alpha: CGFloat) {
        storage = .fixed(CGColor(red: white, green: white, blue: white, alpha: alpha))
    }
    init(_ storage: Storage) { self.storage = storage }
    init(semantic name: String) { storage = .semantic(name: name) }
    public init(dynamicProvider: @escaping (UITraitCollection) -> UIColor) {
        storage = .dynamic { traits in dynamicProvider(traits).resolvedCGColor(with: traits) }
    }

    /// UIKit's bundle-selecting named-color initializer.
    ///
    /// OpenUIKit first reads the packager's materialized asset-catalog index.
    /// Indexed sRGB, extended-sRGB, Display-P3 and gray-gamma-22 colors use
    /// the component reporting measured from UIKit. Only when a name is
    /// genuinely absent from every valid index does lookup fall back to an
    /// uncompiled sRGB `.colorset/Contents.json` resource.
    /// `traitCollection` is accepted for source compatibility; luminosity is
    /// selected when the returned color is resolved, just like other dynamic
    /// OpenUIKit colors.
    public convenience init?(named name: String,
                             in bundle: Bundle?,
                             compatibleWith traitCollection: UITraitCollection?) {
        let roots = BundleAssetLookup.resourceRoots(in: bundle)
        let initialTraits = traitCollection ?? UITraitCollection.current
        switch BundleAssetLookup.indexedColor(
            named: name, resourceRoots: roots
        ) {
        case .blocked:
            return nil
        case .value(let indexed):
            guard let initial = indexed.resolvedColor(for: initialTraits) else {
                return nil
            }
            if indexed.hasAppearanceVariants {
                self.init(.dynamic { traits in
                    indexed.resolvedColor(for: traits)
                        ?? CGColor(red: 0, green: 0, blue: 0, alpha: 0)
                })
            } else {
                self.init(red: initial.red, green: initial.green,
                          blue: initial.blue, alpha: initial.alpha)
            }
        case .absent:
            guard let asset = _NamedColorAsset.load(
                name: name, resourceRoots: roots
            ) else { return nil }

            if asset.hasAppearanceVariants {
                self.init(dynamicProvider: { traits in
                    let color = asset.resolvedColor(for: traits)
                    return UIColor(red: color.red, green: color.green,
                                   blue: color.blue, alpha: color.alpha)
                })
            } else {
                let color = asset.resolvedColor(for: initialTraits)
                self.init(red: color.red, green: color.green,
                          blue: color.blue, alpha: color.alpha)
            }
        }
    }

    /// UIKit's main-bundle shorthand.
    public convenience init?(named name: String) {
        self.init(named: name, in: nil, compatibleWith: nil)
    }

    /// Resolve to concrete sRGB components for the given traits.
    public func resolvedCGColor(with traits: UITraitCollection) -> CGColor {
        switch storage {
        case .fixed(let c): return c
        case .semantic(let name): return SystemColors.resolve(name, traits: traits)
        case .dynamic(let f): return f(traits)
        }
    }
    public func resolvedColor(with traits: UITraitCollection) -> UIColor {
        let c = resolvedCGColor(with: traits)
        return UIColor(red: c.red, green: c.green, blue: c.blue, alpha: c.alpha)
    }
    public var cgColor: CGColor { resolvedCGColor(with: .current) }

    public func withAlphaComponent(_ alpha: CGFloat) -> UIColor {
        switch storage {
        case .fixed(let c):
            return UIColor(.fixed(CGColor(red: c.red, green: c.green, blue: c.blue, alpha: alpha)))
        case .semantic(let name):
            return UIColor(.dynamic { t in
                var c = SystemColors.resolve(name, traits: t); c.alpha = alpha; return c
            })
        case .dynamic(let f):
            return UIColor(.dynamic { t in var c = f(t); c.alpha = alpha; return c })
        }
    }

    public static func == (lhs: UIColor, rhs: UIColor) -> Bool {
        lhs.resolvedCGColor(with: .current) == rhs.resolvedCGColor(with: .current)
    }

    public func hash(into hasher: inout Hasher) {
        let color = resolvedCGColor(with: .current)
        hasher.combine(color.red)
        hasher.combine(color.green)
        hasher.combine(color.blue)
        hasher.combine(color.alpha)
    }

    // Fixed palette colors (values match UIKit's fixed colors).
    public static let clear = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
    public static let black = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
    public static let white = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
    public static let red = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
    public static let green = UIColor(red: 0, green: 1, blue: 0, alpha: 1)
    public static let blue = UIColor(red: 0, green: 0, blue: 1, alpha: 1)
    public static let gray = UIColor(white: 0.5, alpha: 1)
    public static let lightGray = UIColor(white: 2.0 / 3.0, alpha: 1)
    public static let darkGray = UIColor(white: 1.0 / 3.0, alpha: 1)
    public static let yellow = UIColor(red: 1, green: 1, blue: 0, alpha: 1)
    public static let orange = UIColor(red: 1, green: 0.5, blue: 0, alpha: 1)
    public static let purple = UIColor(red: 0.5, green: 0, blue: 0.5, alpha: 1)
    public static let cyan = UIColor(red: 0, green: 1, blue: 1, alpha: 1)
    public static let magenta = UIColor(red: 1, green: 0, blue: 1, alpha: 1)
    public static let brown = UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1)

    // Semantic colors — resolved via SystemColors table.
    public static let systemRed = UIColor(semantic: "systemRed")
    public static let systemOrange = UIColor(semantic: "systemOrange")
    public static let systemYellow = UIColor(semantic: "systemYellow")
    public static let systemGreen = UIColor(semantic: "systemGreen")
    public static let systemMint = UIColor(semantic: "systemMint")
    public static let systemTeal = UIColor(semantic: "systemTeal")
    public static let systemCyan = UIColor(semantic: "systemCyan")
    public static let systemBlue = UIColor(semantic: "systemBlue")
    public static let systemIndigo = UIColor(semantic: "systemIndigo")
    public static let systemPurple = UIColor(semantic: "systemPurple")
    public static let systemPink = UIColor(semantic: "systemPink")
    public static let systemBrown = UIColor(semantic: "systemBrown")
    public static let systemGray = UIColor(semantic: "systemGray")
    public static let systemGray2 = UIColor(semantic: "systemGray2")
    public static let systemGray3 = UIColor(semantic: "systemGray3")
    public static let systemGray4 = UIColor(semantic: "systemGray4")
    public static let systemGray5 = UIColor(semantic: "systemGray5")
    public static let systemGray6 = UIColor(semantic: "systemGray6")
    public static let label = UIColor(semantic: "label")
    public static let secondaryLabel = UIColor(semantic: "secondaryLabel")
    public static let tertiaryLabel = UIColor(semantic: "tertiaryLabel")
    public static let quaternaryLabel = UIColor(semantic: "quaternaryLabel")
    public static let systemBackground = UIColor(semantic: "systemBackground")
    public static let secondarySystemBackground = UIColor(semantic: "secondarySystemBackground")
    public static let tertiarySystemBackground = UIColor(semantic: "tertiarySystemBackground")
    public static let systemGroupedBackground = UIColor(semantic: "systemGroupedBackground")
    public static let secondarySystemGroupedBackground = UIColor(semantic: "secondarySystemGroupedBackground")
    public static let tertiarySystemGroupedBackground = UIColor(semantic: "tertiarySystemGroupedBackground")
    public static let separator = UIColor(semantic: "separator")
    public static let opaqueSeparator = UIColor(semantic: "opaqueSeparator")
    public static let link = UIColor(semantic: "link")
    public static let placeholderText = UIColor(semantic: "placeholderText")
    public static let systemFill = UIColor(semantic: "systemFill")
    public static let secondarySystemFill = UIColor(semantic: "secondarySystemFill")
    public static let tertiarySystemFill = UIColor(semantic: "tertiarySystemFill")
    public static let quaternarySystemFill = UIColor(semantic: "quaternarySystemFill")
    public static let tintColor = UIColor(semantic: "tintColor")
}

/// The intentionally small, portable part of an Xcode named-color asset.
/// Parsing uses OpenUIKit's Foundation-free JSON parser and CPortableIO, so
/// the same source remains buildable when Foundation is hidden.
private struct _NamedColorAsset {
    private enum Appearance {
        case base
        case light
        case dark
        case unsupported
    }

    let base: CGColor
    let light: CGColor?
    let dark: CGColor?

    var hasAppearanceVariants: Bool { light != nil || dark != nil }

    func resolvedColor(for traits: UITraitCollection) -> CGColor {
        switch traits.userInterfaceStyle {
        case .dark:
            return dark ?? base
        case .light:
            return light ?? base
        case .unspecified:
            return base
        }
    }

    static func load(name: String, resourceRoots: [String]) -> _NamedColorAsset? {
        guard let name = BundleAssetLookup.relativeResourceName(name) else {
            return nil
        }

        // Raw SPM/copied catalogs keep one of these shapes. `Colors.xcassets`
        // is the exact pinned Focus DesignSystem layout; the other two cover
        // the common root and generic catalog spellings without recursively
        // walking arbitrary host directories.
        let catalogPrefixes = ["", "Colors.xcassets", "Assets.xcassets", "Media.xcassets"]
        for root in resourceRoots {
            let rootPrefix = root.isEmpty || root.hasSuffix("/") ? root : root + "/"
            for catalog in catalogPrefixes {
                let catalogPrefix = catalog.isEmpty ? "" : catalog + "/"
                let path = rootPrefix + catalogPrefix + name + ".colorset/Contents.json"
                guard let bytes = ResourceIO.readFile(path),
                      let asset = parse(bytes) else { continue }
                return asset
            }
        }
        return nil
    }

    private static func parse(_ bytes: [UInt8]) -> _NamedColorAsset? {
        guard let entries = JSONValue.parse(bytes)?["colors"]?.arrayValue else {
            return nil
        }

        var base: CGColor?
        var light: CGColor?
        var dark: CGColor?
        for entry in entries {
            guard entry["idiom"]?.stringValue == "universal",
                  entry["display-gamut"] == nil else { continue }
            guard let value = parseColor(entry["color"]) else { continue }

            switch appearance(in: entry) {
            case .dark:
                if dark == nil { dark = value }
            case .light:
                if light == nil { light = value }
            case .base:
                if base == nil { base = value }
            case .unsupported:
                continue
            }
        }

        guard let fallback = base ?? light ?? dark else { return nil }
        return _NamedColorAsset(base: fallback, light: light, dark: dark)
    }

    private static func appearance(in entry: JSONValue) -> Appearance {
        guard let appearances = entry["appearances"]?.arrayValue else {
            return .base
        }
        guard appearances.count == 1,
              appearances[0]["appearance"]?.stringValue == "luminosity" else {
            return .unsupported
        }
        switch appearances[0]["value"]?.stringValue {
        case "light": return .light
        case "dark": return .dark
        default: return .unsupported
        }
    }

    private static func parseColor(_ value: JSONValue?) -> CGColor? {
        guard let value,
              value["color-space"]?.stringValue == "srgb",
              let components = value["components"],
              let red = component(components["red"]),
              let green = component(components["green"]),
              let blue = component(components["blue"]) else {
            return nil
        }
        let alpha: CGFloat
        if let encodedAlpha = components["alpha"] {
            guard let parsedAlpha = component(encodedAlpha) else { return nil }
            alpha = parsedAlpha
        } else {
            alpha = 1
        }
        return CGColor(red: clamp(red), green: clamp(green),
                       blue: clamp(blue), alpha: clamp(alpha))
    }

    private static func component(_ value: JSONValue?) -> CGFloat? {
        if let number = value?.doubleValue, number.isFinite {
            return CGFloat(number)
        }
        guard let string = value?.stringValue else { return nil }
        if string.hasPrefix("0x") || string.hasPrefix("0X") {
            let digits = string.dropFirst(2)
            guard digits.count == 2,
                  let byte = Int(digits, radix: 16), byte <= 0xFF else { return nil }
            return CGFloat(byte) / 255
        }
        guard let number = Double(string), number.isFinite else { return nil }
        return CGFloat(number)
    }

    private static func clamp(_ value: CGFloat) -> CGFloat {
        Swift.max(0, Swift.min(1, value))
    }
}
