// UIColor + UITraitCollection. Owner: color module.
// Semantic color resolution is data-driven from Resources/system_colors.json
// (see SystemColors.swift).

// M15: a DEFAULT ARGUMENT or an `@inlinable` body may only use members whose
// defining module THIS FILE imports -- `CGRect.zero` and `CGFloat.pi` do not
// ride in on OpenCoreGraphics' typealias the way ordinary uses do. These are
// SCOPED imports on purpose: they satisfy that rule without pulling in
// CoreGraphics' CGColor / CGAffineTransform, which would collide with
// OpenCoreGraphics' own.
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

public struct UITraitCollection: Equatable, Sendable {
    public var userInterfaceStyle: UIUserInterfaceStyle
    public var displayScale: CGFloat
    /// Dynamic Type setting (M14). Defaults to `.large`, which is what a
    /// device ships with and the size at which every `UIFontMetrics` scale
    /// factor measures 1.0 — see UIFontMetrics.swift.
    public var preferredContentSizeCategory: UIContentSizeCategory

    public init(userInterfaceStyle: UIUserInterfaceStyle = .unspecified, displayScale: CGFloat = 2) {
        self.userInterfaceStyle = userInterfaceStyle
        self.displayScale = displayScale
        self.preferredContentSizeCategory = .large
    }
    /// Real UIKit's `UITraitCollection(preferredContentSizeCategory:)`; the
    /// other axes take the process-wide current values, as UIKit's does.
    public init(preferredContentSizeCategory: UIContentSizeCategory) {
        self.userInterfaceStyle = UITraitCollection.current.userInterfaceStyle
        self.displayScale = UITraitCollection.current.displayScale
        self.preferredContentSizeCategory = preferredContentSizeCategory
    }
    /// Process-wide current traits (real UIKit: UITraitCollection.current).
    public static var current = UITraitCollection(userInterfaceStyle: .light)
}

public class UIColor: Equatable {
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
