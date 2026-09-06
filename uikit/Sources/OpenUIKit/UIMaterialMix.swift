// Per-style material mix for UIVisualEffectView / UIGlassEffect.
//
// MEASURED /tmp/materials-probe, iPhone SE 2x / iOS 26.1. Classic
// UIBlurEffect styles dump CAFilter gaussianBlur + colorSaturate 1.8 and
// a `_UIVisualEffectSubview` source-over overlay. System materials dump
// luminanceCurveMap + colorSaturate + colorBrightness + gaussianBlur
// (no overlay); interiors are modelled as the two-unknown gray mix
// `out = (1−α)·sat(B) + α·T` fitted from white/black, with the dumped
// radius and saturation. luminanceCurveMap's LUT is not in the dump
// (no inputValues); chroma residuals for chrome / ultraThin are in
// docs/MATERIALS.md.
//
// Guard: `OpenUIKitRuntime.systemFontCut == .iOS`. Catalyst keeps the
// historical uniform radius-20 gaussian with no tint.

#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
#elseif canImport(Foundation)
import Foundation
#endif

enum _UIMaterialMix {
    struct Recipe {
        var radius: CGFloat
        var saturation: CGFloat
        var overlayAlpha: CGFloat
        var overlayGray: CGFloat
        var clampsSaturation: Bool
    }

    /// Classic overlay from `_UIVisualEffectSubview.backgroundColor`.
    /// extraLight / prominent: rgba(0.970, 0.970, 0.970, 0.800), σ=20.
    /// light / regular (light appearance): rgba(1, 1, 1, 0.300), σ=30.
    /// dark / regular (dark appearance): rgba(0.110, 0.110, 0.110, 0.730), σ=20.
    /// colorSaturate inputAmount=1.8. Interiors match 6 backdrops (Δ≤1).
    static let extraLight = Recipe(radius: 20, saturation: 1.8,
                                   overlayAlpha: 0.8, overlayGray: 0.97,
                                   clampsSaturation: true)
    static let light = Recipe(radius: 30, saturation: 1.8,
                              overlayAlpha: 0.3, overlayGray: 1,
                              clampsSaturation: true)
    static let dark = Recipe(radius: 20, saturation: 1.8,
                             overlayAlpha: 0.73, overlayGray: 0.11,
                             clampsSaturation: true)

    /// UIGlassEffect.regular interiors: white 251, black 175.
    /// α = 179/255, T = 175/179. sat=2 from red G (255,56,60)→(255,179,182).
    /// Unclamped: yellow/green maxΔ=6 (`PIXEL_TOL`). σ reused from
    /// `_UIGlassMaterial` (no CAFilter on the glass view).
    static let glassRegular = Recipe(radius: _UIGlassMaterial.blurSigma,
                                     saturation: 2,
                                     overlayAlpha: 179.0 / 255.0,
                                     overlayGray: 175.0 / 179.0,
                                     clampsSaturation: false)
    /// Dark appearance. MEASURED /tmp/materials-dark-probe, iPhone SE 2x /
    /// iOS 26.1: white 91, black 24, gray33 39 (mix predicts 37).
    /// α = 188/255, T = 24/188. sat=2.225 from red G
    /// (255,56,60)→(150,25,28).
    static let glassRegularDark = Recipe(radius: _UIGlassMaterial.blurSigma,
                                         saturation: 2.225,
                                         overlayAlpha: 188.0 / 255.0,
                                         overlayGray: 24.0 / 188.0,
                                         clampsSaturation: false)
    /// UIGlassEffect.clear interiors: white 255, black 19.
    /// α = 19/255, T = 1. sat=1. Gray exact; chroma residual reported.
    static let glassClear = Recipe(radius: _UIGlassMaterial.blurSigma,
                                   saturation: 1,
                                   overlayAlpha: 19.0 / 255.0,
                                   overlayGray: 1,
                                   clampsSaturation: true)

    static func configuration(_ recipe: Recipe) -> CanvasBackdropFilterConfiguration {
        CanvasBackdropFilterConfiguration(
            blurRadius: recipe.radius,
            saturation: recipe.saturation,
            tintColor: CGColor(red: recipe.overlayGray,
                               green: recipe.overlayGray,
                               blue: recipe.overlayGray,
                               alpha: recipe.overlayAlpha),
            intensity: 1,
            clampsSaturation: recipe.clampsSaturation)
    }

    /// Two-unknown mix from measured gray interiors (0…255) plus dumped
    /// CAFilter radius / saturation.
    static func configuration(white: CGFloat, black: CGFloat,
                              saturation: CGFloat, radius: CGFloat,
                              clampsSaturation: Bool)
        -> CanvasBackdropFilterConfiguration {
        let k = (white - black) / 255
        let alpha = 1 - k
        let gray: CGFloat
        if alpha > 0 {
            gray = (black / 255) / alpha
        } else {
            gray = 1
        }
        return CanvasBackdropFilterConfiguration(
            blurRadius: radius,
            saturation: saturation,
            tintColor: CGColor(red: gray, green: gray, blue: gray, alpha: alpha),
            intensity: 1,
            clampsSaturation: clampsSaturation)
    }

    static func blurConfiguration(
        style: UIBlurEffect.Style?,
        traits: UITraitCollection
    ) -> CanvasBackdropFilterConfiguration? {
        guard let style else { return nil }
        let isDark = traits.userInterfaceStyle == .dark
        switch style {
        case .extraLight, .prominent:
            return configuration(extraLight)
        case .light:
            return configuration(light)
        case .dark:
            return configuration(Self.dark)
        case .regular:
            return configuration(isDark ? Self.dark : light)
        case .systemUltraThinMaterial:
            return isDark
                ? configuration(white: 177, black: 31, saturation: 1.1, radius: 22.5,
                                clampsSaturation: true)
                : configuration(white: 245, black: 88, saturation: 1.1, radius: 22.5,
                                clampsSaturation: true)
        case .systemThinMaterial:
            return isDark
                ? configuration(white: 125, black: 31, saturation: 1.35, radius: 29.5,
                                clampsSaturation: true)
                : configuration(white: 245, black: 142, saturation: 1.35, radius: 29.5,
                                clampsSaturation: true)
        case .systemMaterial:
            return isDark
                ? configuration(white: 83, black: 31, saturation: 1.5, radius: 29.5,
                                clampsSaturation: true)
                : configuration(white: 245, black: 197, saturation: 1.5, radius: 29.5,
                                clampsSaturation: true)
        case .systemThickMaterial:
            return isDark
                ? configuration(white: 37, black: 31, saturation: 1.5, radius: 45,
                                clampsSaturation: true)
                : configuration(white: 245, black: 232, saturation: 1.5, radius: 45,
                                clampsSaturation: true)
        case .systemChromeMaterial:
            return isDark
                ? configuration(white: 87, black: 18, saturation: 2, radius: 22.5,
                                clampsSaturation: true)
                : configuration(white: 247, black: 178, saturation: 1.1, radius: 22.5,
                                clampsSaturation: true)
        case .systemUltraThinMaterialLight:
            return configuration(white: 245, black: 88, saturation: 1.1, radius: 22.5,
                                 clampsSaturation: true)
        case .systemThinMaterialLight:
            return configuration(white: 245, black: 142, saturation: 1.35, radius: 29.5,
                                 clampsSaturation: true)
        case .systemMaterialLight:
            return configuration(white: 245, black: 197, saturation: 1.5, radius: 29.5,
                                 clampsSaturation: true)
        case .systemThickMaterialLight:
            return configuration(white: 245, black: 232, saturation: 1.5, radius: 45,
                                 clampsSaturation: true)
        case .systemChromeMaterialLight:
            return configuration(white: 247, black: 178, saturation: 1.1, radius: 22.5,
                                 clampsSaturation: true)
        case .systemUltraThinMaterialDark:
            return configuration(white: 177, black: 31, saturation: 1.1, radius: 22.5,
                                 clampsSaturation: true)
        case .systemThinMaterialDark:
            return configuration(white: 125, black: 31, saturation: 1.35, radius: 29.5,
                                 clampsSaturation: true)
        case .systemMaterialDark:
            return configuration(white: 83, black: 31, saturation: 1.5, radius: 29.5,
                                 clampsSaturation: true)
        case .systemThickMaterialDark:
            return configuration(white: 37, black: 31, saturation: 1.5, radius: 45,
                                 clampsSaturation: true)
        case .systemChromeMaterialDark:
            return configuration(white: 87, black: 18, saturation: 2, radius: 22.5,
                                 clampsSaturation: true)
        default:
            // Unnamed tags 3 and 21 (MEASURED iOS 26.1) follow dark.
            return configuration(Self.dark)
        }
    }

    static func glassConfiguration(
        style: UIGlassEffect.Style,
        tintColor: UIColor?,
        traits: UITraitCollection
    ) -> CanvasBackdropFilterConfiguration {
        if let tintColor {
            // MEASURED glass.regular.tintRed: G=B=0, R white 253 / black 223.
            // Same α as `_UIGlassMaterial` (222/255) with T = tint, sat 5.651
            // unclamped. White 253 exact; black 220 vs 223 residual 3.
            let c = tintColor.cgColor
            return CanvasBackdropFilterConfiguration(
                blurRadius: _UIGlassMaterial.blurSigma,
                saturation: _UIGlassMaterial.saturation,
                tintColor: CGColor(red: c.red, green: c.green, blue: c.blue,
                                   alpha: _UIGlassMaterial.mixAlpha),
                intensity: 1,
                clampsSaturation: false)
        }
        switch style {
        case .regular:
            if traits.userInterfaceStyle == .dark {
                return configuration(glassRegularDark)
            }
            return configuration(glassRegular)
        case .clear:
            // MEASURED dark probe: white 255 / black 19, same as light.
            return configuration(glassClear)
        }
    }

}
