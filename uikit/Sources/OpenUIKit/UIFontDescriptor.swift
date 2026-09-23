// UIFontDescriptor. Owner: text module (M12 — attributed text).
//
// Real UIFontDescriptor is an attribute bag that can name any installed
// family. OpenUIKit's font model is (pointSize, weight, design) — the system
// face only (docs/KNOWN_GAPS.md) — so the descriptor is a value type over
// exactly that, wide enough for the idiom apps actually write:
//
//     let d = label.font.fontDescriptor.withSymbolicTraits([.traitBold])!
//     label.font = UIFont(descriptor: d, size: 0)
//
// `withSymbolicTraits` REPLACES the trait set (real UIKit semantics), so
// `.traitBold` alone drops italic. Traits map onto the weight/design model:
// traitBold → weight .bold (any lighter weight is promoted; already-bold or
// heavier weights are kept), traitItalic → design .italic, traitMonoSpace →
// design .monospaced.

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


public struct UIFontDescriptor: Equatable {
    public static func == (lhs: UIFontDescriptor, rhs: UIFontDescriptor) -> Bool {
        lhs.pointSize == rhs.pointSize && lhs.weight == rhs.weight && lhs.design == rhs.design
            && lhs.customFontName == rhs.customFontName
            && lhs.featureSettings.map { [$0.type, $0.selector] } == rhs.featureSettings.map { [$0.type, $0.selector] }
    }

    public struct SymbolicTraits: OptionSet, Sendable {
        public let rawValue: UInt32
        public init(rawValue: UInt32) { self.rawValue = rawValue }
        public static let traitItalic = SymbolicTraits(rawValue: 1 << 0)
        public static let traitBold = SymbolicTraits(rawValue: 1 << 1)
        public static let traitExpanded = SymbolicTraits(rawValue: 1 << 5)
        public static let traitCondensed = SymbolicTraits(rawValue: 1 << 6)
        public static let traitMonoSpace = SymbolicTraits(rawValue: 1 << 10)
        public static let traitVertical = SymbolicTraits(rawValue: 1 << 11)
        public static let traitUIOptimized = SymbolicTraits(rawValue: 1 << 12)
        public static let traitTightLeading = SymbolicTraits(rawValue: 1 << 15)
        public static let traitLooseLeading = SymbolicTraits(rawValue: 1 << 16)
    }

    /// `UIFontDescriptor.SystemDesign` — the rounded/serif designs are not
    /// available portably; `.default` and `.monospaced` are.
    public struct SystemDesign: Hashable, RawRepresentable, Sendable {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public static let `default` = SystemDesign(rawValue: "default")
        public static let monospaced = SystemDesign(rawValue: "monospaced")
        public static let rounded = SystemDesign(rawValue: "rounded")
        public static let serif = SystemDesign(rawValue: "serif")
    }

    /// UIKit's `UIFontDescriptor.AttributeName`. iOS 26.1 raw values
    /// (iososswallsprobe `fontdesc.attr.*`).
    public struct AttributeName: Hashable, RawRepresentable, Sendable {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public init(_ rawValue: String) { self.rawValue = rawValue }
        public static let family = AttributeName("NSFontFamilyAttribute")
        public static let name = AttributeName("NSFontNameAttribute")
        public static let size = AttributeName("NSFontSizeAttribute")
        public static let traits = AttributeName("NSCTFontTraitsAttribute")
        public static let featureSettings = AttributeName("NSCTFontFeatureSettingsAttribute")
        public static let textStyle = AttributeName("NSCTFontUIUsageAttribute")
    }

    /// UIKit's `UIFontDescriptor.FeatureKey` (iOS 26.1 raws, `fontdesc.feature.*`).
    public struct FeatureKey: Hashable, RawRepresentable, Sendable {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public init(_ rawValue: String) { self.rawValue = rawValue }
        public static let type = FeatureKey("CTFeatureTypeIdentifier")
        public static let selector = FeatureKey("CTFeatureSelectorIdentifier")
    }

    /// UIKit's `UIFontDescriptor.TraitKey` (iOS 26.1 raws, `fontdesc.trait.*`).
    public struct TraitKey: Hashable, RawRepresentable, Sendable {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public init(_ rawValue: String) { self.rawValue = rawValue }
        public static let symbolic = TraitKey("NSCTFontSymbolicTrait")
        public static let weight = TraitKey("NSCTFontWeightTrait")
        public static let width = TraitKey("NSCTFontProportionTrait")
        public static let slant = TraitKey("NSCTFontSlantTrait")
    }

    public var pointSize: CGFloat
    /// PostScript name of a registered face (CTFontManager.swift), kept
    /// through descriptor edits so a custom font stays custom.
    var customFontName: String?
    /// Feature settings added with `addingAttributes`, as
    /// (type, selector) pairs. Stored only: OpenUIKit does not apply SFNT
    /// layout features (iOS 26.1 draws monospaced digits for (6, 0): the
    /// digit "1" in 17 pt system widens from 7.454 to 10.276 pt).
    public internal(set) var featureSettings: [(type: Int, selector: Int)] = []
    /// The weight this descriptor resolves to (OpenUIKit extension: real
    /// UIKit hides it inside the traits dictionary).
    public var weight: UIFont.Weight
    /// The design this descriptor resolves to (OpenUIKit extension).
    public var design: UIFont.Design

    public init(pointSize: CGFloat = 17, weight: UIFont.Weight = .regular,
                design: UIFont.Design = .default) {
        self.pointSize = pointSize
        self.weight = weight
        self.design = design
    }

    /// Traits implied by the weight/design pair.
    public var symbolicTraits: SymbolicTraits {
        var t: SymbolicTraits = []
        switch weight {
        case .semibold, .bold, .heavy, .black: t.insert(.traitBold)
        default: break
        }
        if design == .italic { t.insert(.traitItalic) }
        if design == .monospaced { t.insert(.traitMonoSpace) }
        return t
    }

    /// Real UIKit returns nil when the family cannot satisfy the traits; the
    /// system face always can, so this never fails — it stays Optional so
    /// call sites that write `?` / `!` compile unchanged.
    public func withSymbolicTraits(_ traits: SymbolicTraits) -> UIFontDescriptor? {
        var d = self
        // Bold: promote, never demote a heavier weight. iOS 26.1
        // (iososswallsprobe `fontdesc.withBold`): the 17 pt regular system
        // font with `.traitBold` is `.SFUI-Semibold`, not Bold. Lighter
        // weights are promoted the same way (not separately measured).
        if traits.contains(.traitBold) {
            switch d.weight {
            case .semibold, .bold, .heavy, .black: break
            default: d.weight = .semibold
            }
        } else {
            switch d.weight {
            case .semibold, .bold, .heavy, .black: d.weight = .regular
            default: break
            }
        }
        if traits.contains(.traitMonoSpace) {
            d.design = .monospaced
        } else if traits.contains(.traitItalic) {
            d.design = .italic
        } else {
            d.design = .default
        }
        return d
    }

    public func withSize(_ newPointSize: CGFloat) -> UIFontDescriptor {
        var d = self
        d.pointSize = newPointSize
        return d
    }

    public func withWeight(_ newWeight: UIFont.Weight) -> UIFontDescriptor {
        var d = self
        d.weight = newWeight
        return d
    }

    /// Real UIKit returns nil for a design the family lacks. `.rounded` and
    /// `.serif` are not portable — they return nil rather than silently
    /// giving back the default face.
    public func withDesign(_ design: SystemDesign) -> UIFontDescriptor? {
        var d = self
        switch design {
        case .monospaced: d.design = .monospaced
        case .default: d.design = .default
        default: return nil
        }
        return d
    }
}

extension UIFontDescriptor {
    /// UIKit's `fontAttributes`. iOS 26.1: a system font's descriptor
    /// carries exactly the text-style usage and size keys; OpenUIKit reports
    /// the size (the private usage value is not modelled), the traits once a
    /// weight was added, and any feature settings.
    public var fontAttributes: [AttributeName: Any] {
        var out: [AttributeName: Any] = [.size: pointSize]
        if let customFontName { out[.name] = customFontName }
        if weight != .regular { out[.traits] = [TraitKey.weight: weight] }
        if !featureSettings.isEmpty {
            out[.featureSettings] = featureSettings.map { [FeatureKey.type: $0.type, FeatureKey.selector: $0.selector] }
        }
        return out
    }

    /// UIKit's `addingAttributes(_:)`. Understood: `.traits` with a
    /// `.weight` (a `UIFont.Weight`, or its measured raw value — iOS 26.1
    /// `fontdesc.weight.raws`), `.size`, and `.featureSettings` (stored).
    /// iOS 26.1 (`fontdesc.weighted.*`): adding a bold / semibold weight to
    /// the 17 pt system descriptor gives `.SFUI-Bold` / `.SFUI-Semibold`
    /// 17, equal to `systemFont(ofSize: 17, weight:)`.
    public func addingAttributes(_ attributes: [AttributeName: Any]) -> UIFontDescriptor {
        var d = self
        if let traits = attributes[.traits] as? [TraitKey: Any], let w = traits[.weight] {
            if let weight = w as? UIFont.Weight {
                d.weight = weight
            } else if let raw = (w as? Double) ?? (w as? CGFloat).map(Double.init) ?? (w as? Float).map(Double.init),
                      let weight = UIFont.Weight(measuredRawValue: raw) {
                d.weight = weight
            }
        }
        if let size = attributes[.size] as? CGFloat, size > 0 { d.pointSize = size }
        if let features = attributes[.featureSettings] as? [[FeatureKey: Any]] {
            for f in features {
                if let t = f[.type] as? Int, let s = f[.selector] as? Int {
                    d.featureSettings.append((t, s))
                }
            }
        }
        return d
    }
}

extension UIFont.Weight {
    /// UIKit's `UIFont.Weight.rawValue`, iOS 26.1 (`fontdesc.weight.raws`).
    public var rawValue: CGFloat {
        switch self {
        case .ultraLight: return -0.8
        case .thin: return -0.6
        case .light: return -0.4
        case .regular: return 0
        case .medium: return 0.23
        case .semibold: return 0.3
        case .bold: return 0.4
        case .heavy: return 0.56
        case .black: return 0.62
        }
    }

    /// The weight whose measured raw value is `raw` (within 0.01), else nil.
    init?(measuredRawValue raw: Double) {
        let all: [UIFont.Weight] = [.ultraLight, .thin, .light, .regular, .medium, .semibold, .bold, .heavy, .black]
        guard let w = all.first(where: { abs(Double($0.rawValue) - raw) < 0.01 }) else { return nil }
        self = w
    }
}

extension UIFont {
    public var fontDescriptor: UIFontDescriptor {
        var d = UIFontDescriptor(pointSize: pointSize, weight: weight, design: design)
        d.customFontName = customFontName
        return d
    }

    /// `size == 0` keeps the descriptor's point size (UIKit semantics).
    public convenience init(descriptor: UIFontDescriptor, size: CGFloat) {
        self.init(pointSize: size > 0 ? size : descriptor.pointSize,
                  weight: descriptor.weight,
                  design: descriptor.design,
                  customFontName: descriptor.customFontName)
    }
}
