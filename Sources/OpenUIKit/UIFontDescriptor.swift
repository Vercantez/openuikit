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

    public var pointSize: CGFloat
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
        // Bold: promote, never demote a heavier weight.
        if traits.contains(.traitBold) {
            switch d.weight {
            case .bold, .heavy, .black: break
            default: d.weight = .bold
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

extension UIFont {
    public var fontDescriptor: UIFontDescriptor {
        UIFontDescriptor(pointSize: pointSize, weight: weight, design: design)
    }

    /// `size == 0` keeps the descriptor's point size (UIKit semantics).
    public init(descriptor: UIFontDescriptor, size: CGFloat) {
        self.init(pointSize: size > 0 ? size : descriptor.pointSize,
                  weight: descriptor.weight,
                  design: descriptor.design)
    }
}
