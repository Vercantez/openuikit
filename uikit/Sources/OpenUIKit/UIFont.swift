// UIFont. Owner: text module.
// Metrics are data-driven from Resources/font_metrics.json via FontEngine,
// matching real UIKit exactly (goldens win).

// UIFont is an NSObject in UIKit (UIFont.h: `@interface UIFont : NSObject
// <NSCopying, NSSecureCoding>`; MEASURED Tools/oracle2/objcsurfaceprobe:
// class_getSuperclass(UIFont) == NSObject). Same provider choice as
// UIColor.swift.
#if canImport(Foundation)
import class Foundation.NSObject
#elseif canImport(ObjectiveC)
import class ObjectiveC.NSObject
#else
#error("OpenUIKit requires Foundation.NSObject or ObjectiveC.NSObject")
#endif

/// An immutable NSObject class, as in UIKit. It used to be a struct here,
/// which left Objective-C with no `UIFont` class at all: a category such as
/// Artsy+UIFonts' `+[UIFont serifFontWithSize:]` could not be declared and
/// every `[UIFont …]` message was a forward-declaration error
/// (docs/agent_reports/objc-surface.md). Wherever the Objective-C runtime
/// exists the generated header declares `@interface UIFont : NSObject`, so
/// Objective-C code and categories compile against it and bind to this
/// class. The RUNTIME name is UIKit's `UIFont` on the Foundation-hidden
/// Mach-O guest, where OpenUIKit is the process's only UIKit
/// (`NSClassFromString(@"UIFont")`, archived class names). A Foundation
/// build keeps the mangled Swift name: on the macOS host the private
/// UIFoundation framework already registers a class `UIFont` (MEASURED,
/// objc4: "Class UIFont is implemented in both …/UIFoundation and …").
///
/// Value semantics are kept where apps can observe them. Every stored
/// property is a `let`; `==` (NSObject's `isEqual:`) and `hash` compare the
/// font's description, as the iOS 26.1 simulator does (objcsurfaceprobe
/// `## font`): `systemFont(ofSize: 17)` equals another `systemFont(ofSize: 17)`,
/// `systemFont(ofSize: 18).withSize(17)` and `systemFont(ofSize: 17, weight:
/// .regular)`; `boldSystemFont(ofSize: 17)` equals neither weight-based
/// font; `preferredFont(forTextStyle: .body)` is not `systemFont(ofSize: 17)`.
/// Identity is not part of the contract (iOS caches system fonts; OpenUIKit
/// builds a new object per call).
#if _runtime(_ObjC) && !canImport(Foundation)
@objc(UIFont)
#endif
public final class UIFont: NSObject, Sendable {
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

    public let pointSize: CGFloat
    public let weight: Weight
    public let design: Design
    /// Extra inter-line spacing `UIFont.leading` reports for a preferred
    /// text-style font. `nil` for `systemFont(ofSize:)` (font-file leading,
    /// 0 at 15 pt). Set only by `UIFont.preferredFont(forTextStyle:)` on
    /// the iOS cut.
    let textStyleLeading: CGFloat?
    /// PostScript name of a registered (CTFontManager) face, nil for the
    /// system font. See CTFontManager.swift.
    let customFontName: String?
    /// The text style of a `preferredFont(forTextStyle:)` font. Identity
    /// only: iOS 26.1 reports `preferredFont(forTextStyle: .body)` (17 pt
    /// `.SFUI-Regular`) not equal to `systemFont(ofSize: 17)`
    /// (objcsurfaceprobe `## identity`).
    let textStyle: String?
    /// `boldSystemFont(ofSize:)`. iOS 26.1 names it `.SFUI-Semibold` and it
    /// equals neither `systemFont(ofSize:weight: .bold)` nor `.semibold`
    /// (objcsurfaceprobe `## font`): it is the system font with the bold
    /// symbolic trait, not a weight. The glyph weight OpenUIKit draws is
    /// unchanged (`.bold`; the text goldens own that).
    let isSymbolicBold: Bool

    init(pointSize: CGFloat, weight: Weight, design: Design,
         textStyleLeading: CGFloat? = nil, customFontName: String? = nil,
         textStyle: String? = nil, isSymbolicBold: Bool = false) {
        self.pointSize = pointSize
        self.weight = weight
        self.design = design
        self.textStyleLeading = textStyleLeading
        self.customFontName = customFontName
        self.textStyle = textStyle
        self.isSymbolicBold = isSymbolicBold
        super.init()
    }

    /// The same font at another point size: every other stored property is
    /// kept, exactly what assigning `pointSize` on the former struct did.
    func _withPointSize(_ size: CGFloat) -> UIFont {
        UIFont(pointSize: size, weight: weight, design: design,
               textStyleLeading: textStyleLeading, customFontName: customFontName,
               textStyle: textStyle, isSymbolicBold: isSymbolicBold)
    }

    func _withTextStyleLeading(_ leading: CGFloat?) -> UIFont {
        UIFont(pointSize: pointSize, weight: weight, design: design,
               textStyleLeading: leading, customFontName: customFontName,
               textStyle: textStyle, isSymbolicBold: isSymbolicBold)
    }

    /// UIKit's `withSize(_:)` (`-fontWithSize:`). iOS 26.1:
    /// `[systemFontOfSize:17 fontWithSize:34]` is the 34 pt `.SFUI-Regular`
    /// and `[systemFontOfSize:18 fontWithSize:17]` equals
    /// `systemFontOfSize:17` (objcsurfaceprobe `## font`).
    public func withSize(_ fontSize: CGFloat) -> UIFont { _withPointSize(fontSize) }

    public static func systemFont(ofSize size: CGFloat, weight: Weight = .regular) -> UIFont {
        UIFont(pointSize: size, weight: weight, design: .default)
    }
    public static func boldSystemFont(ofSize size: CGFloat) -> UIFont {
        UIFont(pointSize: size, weight: .bold, design: .default, isSymbolicBold: true)
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

    // MARK: Equality (NSObject's isEqual:/hash, which Swift's == and Hashable use)

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? UIFont else { return false }
        if other === self { return true }
        return pointSize == other.pointSize && weight == other.weight && design == other.design
            && textStyleLeading == other.textStyleLeading && customFontName == other.customFontName
            && textStyle == other.textStyle && isSymbolicBold == other.isSymbolicBold
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(pointSize)
        hasher.combine(weight)
        hasher.combine(design)
        hasher.combine(customFontName)
        hasher.combine(textStyle)
        hasher.combine(isSymbolicBold)
        return hasher.finalize()
    }
}
