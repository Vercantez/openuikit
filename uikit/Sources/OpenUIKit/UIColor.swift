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
// MARK: sugar-unify scoped imports (docs/agent_reports/sugar-unify.md):
// Foundation / ObjectiveC names OpenUIKit re-exports rather than re-declares.
// Each is @_exported here too: a plain scoped import that precedes the
// re-export in file order hides the name from clients (swiftc).
#if canImport(Foundation)
@_exported import class Foundation.Bundle
#endif

#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGPoint
import struct CoreGraphics.CGRect
import struct CoreGraphics.CGSize
#elseif canImport(Foundation)
import Foundation
#endif

// UIColor is an NSObject in UIKit (MEASURED Tools/oracle2/objcsubclassprobe:
// class_getSuperclass(UIColor) == NSObject). Same provider choice as
// UIResponder.swift.
#if canImport(Foundation)
import class Foundation.NSObject
#elseif canImport(ObjectiveC)
import class ObjectiveC.NSObject
#else
#error("OpenUIKit requires Foundation.NSObject or ObjectiveC.NSObject")
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
/// `.leading` / `.trailing` follow this via `effectiveUserInterfaceLayoutDirection`.
#if OPENUIKIT_OBJC_SUBCLASSING
@objc
#endif
public enum UIUserInterfaceLayoutDirection: Int, Sendable {
    case leftToRight = 0, rightToLeft = 1
}

/// UIKit's `UITraitCollection` is an immutable NSObject class
/// (`@interface UITraitCollection : NSObject <NSCopying, NSSecureCoding>`;
/// MEASURED Tools/oracle2/objcsubclassprobe: class_getSuperclass ==
/// NSObject). It used to be a mutable struct here; it is a class now so
/// `UIView.traitCollection` and `traitCollectionDidChange(_:)` can be
/// Objective-C override points (an Objective-C app's
/// `-traitCollectionDidChange:` must be reached). The modeled traits and
/// every initializer are unchanged; OpenUIKit's own "copy with one trait
/// changed" sites use `_with { … }` instead of mutating a local copy.
public final class UITraitCollection: NSObject, @unchecked Sendable {
    /// The modeled traits as a value (the former struct's stored fields).
    struct _Values: Equatable {
        var userInterfaceStyle: UIUserInterfaceStyle
        var displayScale: CGFloat
        var horizontalSizeClass: UIUserInterfaceSizeClass
        var verticalSizeClass: UIUserInterfaceSizeClass
        var preferredContentSizeCategory: UIContentSizeCategory
        var userInterfaceIdiom: UIUserInterfaceIdiom

        static let empty = _Values(userInterfaceStyle: .unspecified, displayScale: 0,
                                   horizontalSizeClass: .unspecified, verticalSizeClass: .unspecified,
                                   preferredContentSizeCategory: .unspecified,
                                   userInterfaceIdiom: .unspecified)

        func with(_ change: (inout _Values) -> Void) -> _Values {
            var v = self
            change(&v)
            return v
        }
    }
    let _values: _Values

    public var userInterfaceStyle: UIUserInterfaceStyle { _values.userInterfaceStyle }
    public var displayScale: CGFloat { _values.displayScale }
    public var horizontalSizeClass: UIUserInterfaceSizeClass { _values.horizontalSizeClass }
    public var verticalSizeClass: UIUserInterfaceSizeClass { _values.verticalSizeClass }
    /// Dynamic Type setting (M14). A partial collection defaults to
    /// `.unspecified`; OpenUIKit's complete host environment defaults to
    /// `.large`, the category where every `UIFontMetrics` factor is 1.0.
    public var preferredContentSizeCategory: UIContentSizeCategory { _values.preferredContentSizeCategory }
    /// Device class. A partial collection defaults to `.unspecified`;
    /// hosts that want pad chrome (realapp_settings_light_ipad) must set
    /// `.pad` — unspecified does not inherit `UIDevice.current`.
    public var userInterfaceIdiom: UIUserInterfaceIdiom { _values.userInterfaceIdiom }

    init(_values values: _Values) {
        self._values = values
        super.init()
    }

    /// A copy with some traits changed (the former struct's
    /// `var t = traits; t.x = …` idiom).
    func _with(_ change: (inout _Values) -> Void) -> UITraitCollection {
        UITraitCollection(_values: _values.with(change))
    }

    /// UIKit's empty collection: every modeled trait is unspecified.
    public convenience override init() {
        self.init(_values: .empty)
    }

    /// UIKit's partial collection containing only an interface style.
    public convenience init(userInterfaceStyle: UIUserInterfaceStyle) {
        self.init(_values: _Values.empty.with { $0.userInterfaceStyle = userInterfaceStyle })
    }

    /// UIKit's partial collection containing only a display scale.
    public convenience init(displayScale: CGFloat) {
        self.init(_values: _Values.empty.with { $0.displayScale = displayScale })
    }

    /// UIKit's partial collection containing only a horizontal size class.
    public convenience init(horizontalSizeClass: UIUserInterfaceSizeClass) {
        self.init(_values: _Values.empty.with { $0.horizontalSizeClass = horizontalSizeClass })
    }

    /// UIKit's partial collection containing only a vertical size class.
    public convenience init(verticalSizeClass: UIUserInterfaceSizeClass) {
        self.init(_values: _Values.empty.with { $0.verticalSizeClass = verticalSizeClass })
    }

    /// UIKit's partial collection containing only a Dynamic Type category.
    public convenience init(preferredContentSizeCategory: UIContentSizeCategory) {
        self.init(_values: _Values.empty.with {
            $0.preferredContentSizeCategory = preferredContentSizeCategory
        })
    }

    /// UIKit's partial collection containing only a user-interface idiom.
    public convenience init(userInterfaceIdiom: UIUserInterfaceIdiom) {
        self.init(_values: _Values.empty.with { $0.userInterfaceIdiom = userInterfaceIdiom })
    }

    /// OpenUIKit host convenience: construct a complete render environment in
    /// one call. The existing style/scale spelling is retained; size classes
    /// may be supplied by a host that already knows them, while `.unspecified`
    /// lets UIScreen/UIWindow derive the portable bounds approximation.
    public convenience init(
        userInterfaceStyle: UIUserInterfaceStyle,
        displayScale: CGFloat,
        horizontalSizeClass: UIUserInterfaceSizeClass = .unspecified,
        verticalSizeClass: UIUserInterfaceSizeClass = .unspecified,
        preferredContentSizeCategory: UIContentSizeCategory = .large,
        userInterfaceIdiom: UIUserInterfaceIdiom = .unspecified
    ) {
        self.init(_values: _Values(userInterfaceStyle: userInterfaceStyle, displayScale: displayScale,
                                   horizontalSizeClass: horizontalSizeClass,
                                   verticalSizeClass: verticalSizeClass,
                                   preferredContentSizeCategory: preferredContentSizeCategory,
                                   userInterfaceIdiom: userInterfaceIdiom))
    }

    /// UIKit's legacy merge initializer. Later collections win for each trait,
    /// but an unspecified/default value does not erase an earlier value. This
    /// includes Dynamic Type deliberately; it is part of the modeled trait
    /// environment rather than an unrelated OpenUIKit setting.
    public convenience init(traitsFrom traitCollections: [UITraitCollection]) {
        var v = _Values.empty
        for traits in traitCollections {
            if traits.userInterfaceStyle != .unspecified {
                v.userInterfaceStyle = traits.userInterfaceStyle
            }
            if traits.displayScale != 0 {
                v.displayScale = traits.displayScale
            }
            if traits.horizontalSizeClass != .unspecified {
                v.horizontalSizeClass = traits.horizontalSizeClass
            }
            if traits.verticalSizeClass != .unspecified {
                v.verticalSizeClass = traits.verticalSizeClass
            }
            if traits.preferredContentSizeCategory != .unspecified {
                v.preferredContentSizeCategory = traits.preferredContentSizeCategory
            }
            if traits.userInterfaceIdiom != .unspecified {
                v.userInterfaceIdiom = traits.userInterfaceIdiom
            }
        }
        self.init(_values: v)
    }

    /// Value equality over the modeled traits (the former struct's
    /// synthesized `==`; Swift's `==` on an NSObject calls this).
    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UITraitCollection else { return false }
        return _values == other._values
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(_values.displayScale)
        hasher.combine(_values.horizontalSizeClass)
        hasher.combine(_values.verticalSizeClass)
        return hasher.finalize()
    }

    /// Pad chrome under the iOS cut. Unspecified does not count — a host
    /// that wants iPad metrics must set `.pad` on current (RealApp.swift
    /// does, for `realapp_settings_light_ipad`).
    var isPad: Bool { userInterfaceIdiom == .pad }

    /// A portable host approximation, not Apple's idiom/multitasking policy:
    /// each unspecified axis becomes regular at 600 pt and compact below it.
    /// Explicit host/current axes remain authoritative.
    func _resolvingUnspecifiedSizeClasses(for size: CGSize) -> UITraitCollection {
        _with { v in
            if v.horizontalSizeClass == .unspecified {
                v.horizontalSizeClass = size.width >= 600 ? .regular : .compact
            }
            if v.verticalSizeClass == .unspecified {
                v.verticalSizeClass = size.height >= 600 ? .regular : .compact
            }
        }
    }

    /// Process-wide current traits (real UIKit: UITraitCollection.current).
    /// UIKit exposes the process/thread current traits through a synchronous
    /// nonisolated getter. The portable host updates this snapshot when it
    /// enters a trait environment; the value itself is immutable and
    /// Sendable, while synchronization belongs to the UI host boundary.
    public nonisolated(unsafe) static var current = UITraitCollection(
        userInterfaceStyle: .light,
        displayScale: 2
    )
}

/// Host-facing iOS 17 trait-override bag. Real UIKit's `traitOverrides` is
/// `UIMutableTraits`; OpenUIKit models the one field the conformance and
/// real-app harnesses pin: Dynamic Type. Unspecified inherits
/// `UITraitCollection.current`. Set on the window **before** `makeRoot()`
/// so `UIFont.preferredFont(forTextStyle:)` at construction sees the
/// category (confprobe / `conformance_flow.sh --ax1` / `--xxxl`).
public final class UITraitOverrides {
    public var preferredContentSizeCategory: UIContentSizeCategory = .unspecified
    public init() {}
}

/// NSObject-derived so a `UIColor` can cross an `@objc` signature
/// (`UIView.tintColor` is an Objective-C override point, and an Objective-C
/// app passes colors to every view). Equality and hashing keep their
/// previous meaning (resolved components under the current traits) through
/// `isEqual(_:)` / `hash`, which is what Swift's `==` on an NSObject calls.
public class UIColor: NSObject, @unchecked Sendable {
    /// Static color, or a named semantic color resolved via traits.
    enum Storage {
        case fixed(CanvasColor)
        case semantic(name: String)
        case dynamic((UITraitCollection) -> CanvasColor)
    }
    let storage: Storage
    /// The CoreGraphics colour a `UIColor(cgColor:)` was made from. iOS 26.1
    /// keeps it: `cgColor` returns a colour in the same space (GenericGray,
    /// SRGB, …), and such a colour is not `==` to the same components in
    /// UIKit's own extended spaces (cgunifyprobe `## color`).
    private(set) var _sourceCGColor: CGColor?

    public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        storage = .fixed(CanvasColor(red: red, green: green, blue: blue, alpha: alpha))
        super.init()
    }
    public init(white: CGFloat, alpha: CGFloat) {
        storage = .fixed(CanvasColor(gray: white, alpha: alpha))
        super.init()
    }
    init(_ storage: Storage) { self.storage = storage; super.init() }
    init(semantic name: String) { storage = .semantic(name: name); super.init() }
    public init(dynamicProvider: @escaping (UITraitCollection) -> UIColor) {
        storage = .dynamic { traits in dynamicProvider(traits).resolvedCGColor(with: traits) }
        super.init()
    }

    /// Decomposes the color resolved in the current trait environment into
    /// extended sRGB components. OpenUIKit's CanvasColor representation is
    /// normalized RGBA, so every supported color space is representable.
    @discardableResult
    public func getRed(
        _ red: UnsafeMutablePointer<CGFloat>?,
        green: UnsafeMutablePointer<CGFloat>?,
        blue: UnsafeMutablePointer<CGFloat>?,
        alpha: UnsafeMutablePointer<CGFloat>?
    ) -> Bool {
        let color = resolvedCGColor(with: .current)
        red?.pointee = color.red
        green?.pointee = color.green
        blue?.pointee = color.blue
        alpha?.pointee = color.alpha
        return true
    }

    /// Standard sRGB → HSV. Pattern colours do not exist here, so this
    /// always succeeds (UIKit returns false only for pattern colours).
    @discardableResult
    public func getHue(
        _ hue: UnsafeMutablePointer<CGFloat>?,
        saturation: UnsafeMutablePointer<CGFloat>?,
        brightness: UnsafeMutablePointer<CGFloat>?,
        alpha: UnsafeMutablePointer<CGFloat>?
    ) -> Bool {
        let color = resolvedCGColor(with: .current)
        let (h, s, v) = UIColor._rgbToHSB(red: color.red, green: color.green, blue: color.blue)
        hue?.pointee = h
        saturation?.pointee = s
        brightness?.pointee = v
        alpha?.pointee = color.alpha
        return true
    }

    public convenience init(hue: CGFloat, saturation: CGFloat, brightness: CGFloat, alpha: CGFloat) {
        let (r, g, b) = UIColor._hsbToRGB(hue: hue, saturation: saturation, brightness: brightness)
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }

    static func _rgbToHSB(red: CGFloat, green: CGFloat, blue: CGFloat) -> (CGFloat, CGFloat, CGFloat) {
        let maxC = Swift.max(red, Swift.max(green, blue))
        let minC = Swift.min(red, Swift.min(green, blue))
        let delta = maxC - minC
        var h: CGFloat = 0
        if delta > 0 {
            if maxC == red {
                h = (green - blue) / delta
                if h < 0 { h += 6 }
            } else if maxC == green {
                h = 2 + (blue - red) / delta
            } else {
                h = 4 + (red - green) / delta
            }
            h /= 6
        }
        let s: CGFloat = maxC == 0 ? 0 : delta / maxC
        return (h, s, maxC)
    }

    static func _hsbToRGB(hue: CGFloat, saturation: CGFloat, brightness: CGFloat) -> (CGFloat, CGFloat, CGFloat) {
        var h = hue.truncatingRemainder(dividingBy: 1)
        if h < 0 { h += 1 }
        let s = Swift.min(Swift.max(saturation, 0), 1)
        let v = Swift.min(Swift.max(brightness, 0), 1)
        if s == 0 { return (v, v, v) }
        let sextant = h * 6
        let i = Swift.min(5, Int(sextant))
        let f = sextant - CGFloat(i)
        let p = v * (1 - s)
        let q = v * (1 - s * f)
        let t = v * (1 - s * (1 - f))
        switch i {
        case 0: return (v, t, p)
        case 1: return (q, v, p)
        case 2: return (p, v, t)
        case 3: return (p, q, v)
        case 4: return (t, p, v)
        default: return (v, p, q)
        }
    }

    /// Returns a monochrome decomposition only when all resolved channels
    /// agree. This preserves UIKit's fail-closed color-model contract instead
    /// of silently discarding chroma.
    @discardableResult
    public func getWhite(
        _ white: UnsafeMutablePointer<CGFloat>?,
        alpha: UnsafeMutablePointer<CGFloat>?
    ) -> Bool {
        let color = resolvedCGColor(with: .current)
        let tolerance: CGFloat = 1.0 / 65_535.0
        guard (color.red - color.green).magnitude <= tolerance,
              (color.green - color.blue).magnitude <= tolerance else {
            return false
        }
        white?.pointee = color.red
        alpha?.pointee = color.alpha
        return true
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
                        ?? CanvasColor(red: 0, green: 0, blue: 0, alpha: 0)
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
    public func resolvedCGColor(with traits: UITraitCollection) -> CanvasColor {
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
    /// UIKit's `cgColor`: CoreGraphics' own `CGColor` where CoreGraphics
    /// exists (cg-unify), the renderer's value colour elsewhere. Gray-model
    /// colours are 2-component extended gray, the rest 4-component extended
    /// sRGB (iOS 26.1); a `UIColor(cgColor:)` returns its source colour.
    public var cgColor: CGColor { _cgColorObject(with: .current) }

    /// `cgColor` resolved for `traits`.
    func _cgColorObject(with traits: UITraitCollection) -> CGColor {
        _sourceCGColor ?? resolvedCGColor(with: traits).cgColor
    }

    /// The renderer's value colour in the current trait environment (what
    /// `cgColor` was before cg-unify; internal drawing reads this).
    var _canvasColor: CanvasColor { resolvedCGColor(with: .current) }

    /// UIKit's `init(cgColor:)`. The colour keeps its model (gray stays
    /// gray); a colour in another space is converted to sRGB.
    public convenience init(cgColor: CGColor) {
        self.init(.fixed(CanvasColor(cgColor)))
        _sourceCGColor = cgColor
    }

    public func withAlphaComponent(_ alpha: CGFloat) -> UIColor {
        switch storage {
        case .fixed(let c):
            var next = c
            next.alpha = alpha
            return UIColor(.fixed(next))
        case .semantic(let name):
            return UIColor(.dynamic { t in
                var c = SystemColors.resolve(name, traits: t); c.alpha = alpha; return c
            })
        case .dynamic(let f):
            return UIColor(.dynamic { t in var c = f(t); c.alpha = alpha; return c })
        }
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UIColor else { return false }
        if other === self { return true }
        if _sourceCGColor != nil || other._sourceCGColor != nil {
            return _cgColorObject(with: .current) == other._cgColorObject(with: .current)
        }
        return resolvedCGColor(with: .current) == other.resolvedCGColor(with: .current)
    }

    public override var hash: Int {
        let color = resolvedCGColor(with: .current)
        var hasher = Hasher()
        hasher.combine(color.red)
        hasher.combine(color.green)
        hasher.combine(color.blue)
        hasher.combine(color.alpha)
        return hasher.finalize()
    }

    // Fixed palette colors (values match UIKit's fixed colors).
    // iOS 26.1: these three are gray-model colours (two CanvasColor components).
    public static let clear = UIColor(white: 0, alpha: 0)
    public static let black = UIColor(white: 0, alpha: 1)
    public static let white = UIColor(white: 1, alpha: 1)
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

    let base: CanvasColor
    let light: CanvasColor?
    let dark: CanvasColor?

    var hasAppearanceVariants: Bool { light != nil || dark != nil }

    func resolvedColor(for traits: UITraitCollection) -> CanvasColor {
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

        var base: CanvasColor?
        var light: CanvasColor?
        var dark: CanvasColor?
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

    private static func parseColor(_ value: JSONValue?) -> CanvasColor? {
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
        return CanvasColor(red: clamp(red), green: clamp(green),
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
