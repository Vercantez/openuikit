// The AttributedString half of UIButton.Configuration. Owner: button module.
//
// WHY A SEPARATE FILE
// -------------------
// UIButton.swift imports CoreGraphics by SCOPED declaration on purpose (its
// header explains: an unscoped import would put CoreGraphics' `CGColor` and
// `CGAffineTransform` in the same file as OpenCoreGraphics' own). `import
// Foundation` re-exports those same names on Darwin, so the three members
// that need `AttributedString`, `AttributeContainer` and `AttributeScopes` —
// `attributedTitle`, `titleTextAttributesTransformer` and
// `imageColorTransformer`'s companion — live here instead, and UIButton.swift
// calls them through hooks that traffic only in `UIFont`, `UIColor` and the
// port's own `NSAttributedString`.
//
// Each hook has a Foundation-free `#else` twin so a guest build with neither
// Foundation nor FoundationEssentials still compiles; there, a configuration
// simply has no attributed title and no text transformer, which is the same
// thing as not using them.

#if canImport(Foundation)
import Foundation
#elseif canImport(FoundationEssentials)
import FoundationEssentials
#endif

#if canImport(Foundation) || canImport(FoundationEssentials)

@available(macOS 12, iOS 15, tvOS 15, watchOS 8, *)
extension UIButton {
    /// The font the configuration's attributed title names, if any. MEASURED:
    /// a `.borderless()` whose `attributedTitle` carries 20 pt bold renders
    /// its label in `.SFUI-Bold@20.0`, not the 17 pt configuration default.
    static func attributedTitleFont(in value: AttributedString) -> UIFont? {
        for run in value.runs {
            if let font = run[AttributeScopes.OpenUIKitAttributes.FontAttribute.self] {
                return font
            }
        }
        return nil
    }

    /// The colour the configuration's attributed title names, if any.
    /// MEASURED: the same button's label reads systemRed.
    static func attributedTitleColor(in value: AttributedString) -> UIColor? {
        for run in value.runs {
            if let color =
                run[AttributeScopes.OpenUIKitAttributes.ForegroundColorAttribute.self] {
                return color
            }
        }
        return nil
    }
}

extension UIButton {
    /// The attributed title's font, or nil when the configuration has none.
    func configurationAttributedFont(_ configuration: Configuration) -> UIFont? {
        guard #available(macOS 12, iOS 15, tvOS 15, watchOS 8, *),
              let attributed = configuration.attributedTitle else { return nil }
        return UIButton.attributedTitleFont(in: attributed)
    }

    /// The attributed title's foreground colour, or nil.
    func configurationAttributedColor(_ configuration: Configuration) -> UIColor? {
        guard #available(macOS 12, iOS 15, tvOS 15, watchOS 8, *),
              let attributed = configuration.attributedTitle else { return nil }
        return UIButton.attributedTitleColor(in: attributed)
    }

    /// The attributed title converted into the port's own attributed string,
    /// which is what the label and the text renderer consume.
    func configurationAttributedText(_ configuration: Configuration,
                                     defaultFont: UIFont,
                                     defaultColor: UIColor) -> NSAttributedString? {
        guard #available(macOS 12, iOS 15, tvOS 15, watchOS 8, *),
              let attributed = configuration.attributedTitle else { return nil }
        return NSAttributedString.fromAttributedString(attributed,
                                                       defaultFont: defaultFont,
                                                       defaultColor: defaultColor)
    }

    /// Runs `titleTextAttributesTransformer` over the container UIKit would
    /// hand it — the resolved font and the untreated base colour — and
    /// returns whatever it names.
    ///
    /// MEASURED (`transformers` section): the incoming container carries
    /// exactly `NSFont` and `NSColor`, holding the 17 pt body font and the
    /// configuration's `baseForegroundColor`. A transformer that returns its
    /// input unchanged leaves both alone; one that writes them wins.
    func configurationTransformedTextAttributes(_ configuration: Configuration,
                                                font: UIFont,
                                                color: UIColor)
        -> (font: UIFont?, color: UIColor?) {
        guard #available(macOS 12, iOS 15, tvOS 15, watchOS 8, *),
              let transformer = configuration.titleTextAttributesTransformer
        else { return (nil, nil) }
        let outgoing = transformer(
            AttributeContainer.openUIKitTitleAttributes(font: font, foregroundColor: color))
        return (outgoing.openUIKitFont, outgoing.openUIKitForegroundColor)
    }
}

#else

extension UIButton {
    func configurationAttributedFont(_: Configuration) -> UIFont? { nil }
    func configurationAttributedColor(_: Configuration) -> UIColor? { nil }
    func configurationAttributedText(_: Configuration, defaultFont _: UIFont,
                                     defaultColor _: UIColor) -> NSAttributedString? { nil }
    func configurationTransformedTextAttributes(_: Configuration, font _: UIFont,
                                                color _: UIColor)
        -> (font: UIFont?, color: UIColor?) { (nil, nil) }
}

#endif
