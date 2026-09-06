// iOS 26 liquid-glass platter material. Owner: chrome / quartz equivalent of
// QZLayerSetGlassModel. CQuartz's retained layer compositor has no
// destination-sampling node, so the iOS cut applies this through the Canvas
// backdrop-filter path (same kernel as UIVisualEffectView) and
// `containsRenderPassOnlyEffect` selects that compositor.
//
// MEASURED 2026-09-04, probe family glass_{toolbar,tabbar,navbar}_{white,
// black,red,grad} + glass_sigma_edge_se, iPhone SE 3rd gen 2x and iPhone 16
// 3x / iOS 26.1 (scripts/render_sim_scenes.sh). Glyph-free interior of a
// 48 pt toolbar platter (UIPlatformGlassInteractionView), a 62 pt tab-bar
// platter (_UITabBarPlatterView, unselected region) and a 44 pt nav-bar
// back platter (PlatterView):
//
//   backdrop              toolbar/tab unselected   notes
//   white  (255,255,255)  (253,253,253)            std 0; SE 2x = iPhone 16 3x
//   black  (  0,  0,  0)  (220,220,220)            Focus Done over unpainted bar
//   red    (255, 56, 60)  (255,201,204)            captured systemRed
//   grad   white→black    dL 6.7 over 76.5 pt      flatten ratio 0.129
//
// Two-unknown mix  out = (1−α)·blur(B, σ) + α·T  (T gray), four samples:
//   white & black ⇒ α = 222/255, T = 220/α = 252.703/255
//     equivalently k = 33/255, c = 220
//   grad flatten  predicted k·0.68·76.5 = 6.76 vs measured 6.7
//   red / yellow / green close with unclamped sat 5.651 (MEASURED
//     /tmp/materials-probe tab-bar, SE 2x / iOS 26.1): red (255,56,60)→
//     (255,201,204), yellow (242,179,64)→(255,240,156), green (52,199,89)
//     →(162,255,189) at Δ≤1. Clamp-before-tint floors yellow B at 220.
//
// σ: glass_sigma_edge_se, white|black split through the first platter
// centre (x 149.5). Glyph-free scan at platter-local y = 8, erf fit on
// x = 140…160: σ = 2.25 pt, μ = 149.20, rms 1.04 (10–90 % = 6.0 pt → 2.34).
// Same method as the scroll-edge pocket's σ = 1.85 (rms 1.1).
//
// Ring: 2 device px (= 1 pt at 2x) inside the geometric edge. Black:
// dx=0,1 are 240/233, dx=2 is 220 interior. White: 255/255 then 253.
// Corner: capsule, r = height/2 (toolbar 24, tab 31, nav 22).
// Selected-tab capsule is a 18/253 black overlay on this glass (white
// 253→235; black 220→204 vs measured 198, residual 6).
// Floating systemBackground sheet 245 is the same mix over the 20 % dim
// (0.1294·204 + 220 = 246.4, residual 1.4).
//
// Catalyst keeps the flat fills. Dark floating-card glass is a second
// mix (sheet, α=203/255). Dark tab-bar / toolbar platters are a third
// (MEASURED /tmp/glass-dark-out, SE 2x) — not the sheet mix (57 over
// black) and not the light mix (220 over black).
// Nav title / menu / search platters (probe /tmp/glass-navplatters,
// iPhone 16 @3x, four backdrops under a transparent bar + filled content):
//
//   item                         white   black   red              r
//   Done title `[303.667,0,73.333,44]`  255     198     (255,174,179)   22
//   UIBarButtonItem+menu "Top" `[16,0,62,44]`  255  198  (255,174,179)  22
//   searchController field `[28,835,337,48]`  — bottom toolbar, not a
//     44×44 nav icon (Hackers search is `.searchable` + `.minimize`)
//
// Same mix as the toolbar table; black frost 198 matches
// glass_navbar_iphone16_black Back (filled content under the bar). Focus
// Done over the unpainted bar stays 220. Mix is not retuned.
//
// Hackers Top is NOT a UIKit menu item: it is SwiftUI
// `.glassEffect(.regular.interactive(), in: .capsule)` 79.333×44, r=22,
// title pad leading 14 / trailing 10, HStack spacing 8, chevron in an
// 18×18 circle, host 119.667×36 at y 4. Search/settings are two isolated
// 44×44 platters.
//
// Pad popovers are two further light mixes (content 252/215, action-sheet
// 246/178; MEASURED `/tmp/ipad-open-cap`, iPad A16 2x). Dark bar glass is
// not a kind: `_usesIOSDarkBarGlass` on `.platter` (19 over black / 84
// over white).

#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGRect
#elseif canImport(Foundation)
import Foundation
#endif

@preconcurrency @MainActor
enum _UIGlassMaterial {
    /// Gaussian sigma in points. MEASURED glass_sigma_edge_se, SE 2x.
    static let blurSigma: CGFloat = 2.25
    /// Mix weight α. MEASURED white 253 & black 220: 1 − 33/255 = 222/255.
    static let mixAlpha: CGFloat = 222.0 / 255.0
    /// Gray tint T/255. MEASURED α·T = 220 ⇒ T = 220/222.
    static let tintGray: CGFloat = 220.0 / 222.0
    /// Unclamped Rec.709 saturation. MEASURED /tmp/materials-probe tab-bar
    /// platter, iPhone SE 2x / iOS 26.1: yellow (242,179,64) → (255,240,156)
    /// with k=33/255, c=220 (B channel). Same s hits red (255,56,60)→
    /// (255,201,204) and green (52,199,89)→(162,255,189) at Δ≤1. sat=1
    /// left those at (253,227,228) / (251,243,228) / (227,246,232) — the
    /// glass-material.md red residual. Clamping sat before the tint floors
    /// yellow B at 220; `clampsSaturation: false` is required.
    static let saturation: CGFloat = 5.651
    /// Inner highlight ring width in points. MEASURED 2 device px at 2x.
    static let ringWidth: CGFloat = 1
    /// Ring source-over alpha. MEASURED black dx=1 (233) over interior 220:
    /// 13/35 = 0.371.
    static let ringAlpha: CGFloat = 13.0 / 35.0
    /// Selected-tab capsule as black-over-glass. MEASURED white 253→235:
    /// 18/253.
    static let capsuleOverlayAlpha: CGFloat = 18.0 / 253.0

    /// Dark floating-card glass. MEASURED /tmp/sheetfill_dark, iPhone SE 2x
    /// / iOS 26.1, one process per case (sheet-then-sheet drops glass):
    /// medium `systemBackground` interiors
    ///   black (  0,  0,  0) → (57, 57, 57)
    ///   gray33 (51, 51, 51) → (62, 62, 62)
    ///   white (255,255,255) → (84, 84, 84)
    ///   red   (255,  0,  0) → (116, 48, 48)  chroma residual, not fitted
    /// Dim is 0.48 black (Modal t1200.dark UIDimmingView), so the sampled
    /// backdrop is B_dim = 0.52·B. Gray samples fit
    ///   out = (52/255)·B_dim + 57
    /// i.e. α = 203/255, α·T = 57/255, T = 57/203. Same two-unknown mix
    /// as light (k·B + c); red |res| R=32 G=9 like the light red residual.
    static let darkMixAlpha: CGFloat = 203.0 / 255.0
    static let darkTintGray: CGFloat = 57.0 / 203.0
    /// Flat fallback when the render-pass glass does not run (tests).
    /// MEASURED medium_black / Modal t1200.dark interior.
    static let darkFloatingFallback: CGFloat = 57.0 / 255.0

    /// Dark tab-bar / toolbar platter glass. MEASURED /tmp/glass-dark-out
    /// glass_{tabbar,toolbar}_dark_{black,white,gray33,red}, iPhone SE 2x
    /// / iOS 26.1, glyph-free interiors (tab left of selected; toolbar
    /// below the title):
    ///   black  (  0,  0,  0) → (19, 19, 19)
    ///   gray33 (51, 51, 51) → (32, 32, 32)
    ///   white (255,255,255) → (84, 83, 83)
    ///   red    (255, 56, 60) → (157, 13, 16)  chroma residual, not fitted
    /// Gray samples fit out = (65/255)·B + 19, i.e. α = 190/255,
    /// α·T = 19/255, T = 19/190. Same σ as light. Red |res| R=73
    /// (pred 84 vs 157) reported like the light red residual. Tabs
    /// t200.dark unselected 25 / selected 58 are this mix over the
    /// table (not uniform black); probe over black is 19 / 53.
    static let darkBarMixAlpha: CGFloat = 190.0 / 255.0
    static let darkBarTintGray: CGFloat = 19.0 / 190.0
    /// Selected-tab capsule as white-over-bar-glass. MEASURED
    /// glass_tabbar_dark_black 19→53: 34/236. gray33 pred 64.1 vs 65.
    /// White residual pred 108.6 vs 115 reported not fitted.
    static let darkBarCapsuleOverlayAlpha: CGFloat = 34.0 / 236.0

    /// Pad action-sheet popover glass. MEASURED `/tmp/ipad-open-cap`
    /// popover_actionsheet_{white,black,red,grad}, iPad (A16) 820×1180 @2x
    /// / iOS 26.1, one process per CASE: interiors white **246**, black
    /// **178**, red (255, 175, 176). Two-unknown
    /// `out = (1−α)·B + α·T`: black ⇒ α·T = 178; white 246 − 178 = 68 ⇒
    /// 1−α = 68/255, α = **187/255**, T = **178/187**. Grad-left predicted
    /// 223 vs measured 221. σ is not identified from the interiors; the
    /// platter kernel (2.25) is reused. This mix is NOT the content-popover
    /// 252/215 mix and NOT the platter 253/220 mix.
    static let padActionSheetMixAlpha: CGFloat = 187.0 / 255.0
    static let padActionSheetTintGray: CGFloat = 178.0 / 187.0
    /// Ring over black: edge 233 vs interior 178 ⇒ 55/77.
    static let padActionSheetRingAlpha: CGFloat = 55.0 / 77.0

    /// Pad bar-button content popover glass. MEASURED `/tmp/ipad-open-cap`
    /// popover_{white,black,red,grad}, iPad (A16) 820×1180 @2x / iOS 26.1:
    /// interiors white **252**, black **215**, red (255, 216, 218).
    /// `out = (1−α)·B + α·T`: 252 − 215 = 37 ⇒ 1−α = 37/255, α = **218/255**,
    /// T = **215/218**. Ring over black 240/230/215 matches the platter
    /// ring (240/233/220) within 3 counts — reused. Dump has no
    /// `_UIRoundedRectShadowView`; the 11-count halo is not this mix.
    static let padContentPopoverMixAlpha: CGFloat = 218.0 / 255.0
    static let padContentPopoverTintGray: CGFloat = 215.0 / 218.0

    static var configuration: CanvasBackdropFilterConfiguration {
        configuration(dark: false)
    }

    static func configuration(dark: Bool, bar: Bool = false) -> CanvasBackdropFilterConfiguration {
        // Dark chroma is unmeasured (glass-material.md red residual). Keep
        // sat=1 + clamp so gray interiors 19 / 57 / 84 stay exact.
        if dark && bar {
            return CanvasBackdropFilterConfiguration(
                blurRadius: blurSigma,
                saturation: 1,
                tintColor: CGColor(red: darkBarTintGray, green: darkBarTintGray,
                                   blue: darkBarTintGray, alpha: darkBarMixAlpha),
                intensity: 1,
                clampsSaturation: true)
        }
        if dark {
            return CanvasBackdropFilterConfiguration(
                blurRadius: blurSigma,
                saturation: 1,
                tintColor: CGColor(red: darkTintGray, green: darkTintGray,
                                   blue: darkTintGray, alpha: darkMixAlpha),
                intensity: 1,
                clampsSaturation: true)
        }
        return CanvasBackdropFilterConfiguration(
            blurRadius: blurSigma,
            saturation: saturation,
            tintColor: CGColor(red: tintGray, green: tintGray,
                               blue: tintGray, alpha: mixAlpha),
            intensity: 1,
            clampsSaturation: false)
    }

    static func configuration(for view: UIView) -> CanvasBackdropFilterConfiguration {
        switch view._iosGlassKind {
        case .padActionSheetPopover:
            // Pad mixes were fitted on gray interiors only
            // (`/tmp/ipad-open-cap`). Do not apply the phone-tab sat.
            return CanvasBackdropFilterConfiguration(
                blurRadius: blurSigma,
                saturation: 1,
                tintColor: CGColor(red: padActionSheetTintGray,
                                   green: padActionSheetTintGray,
                                   blue: padActionSheetTintGray,
                                   alpha: padActionSheetMixAlpha),
                intensity: 1,
                clampsSaturation: true)
        case .padContentPopover:
            return CanvasBackdropFilterConfiguration(
                blurRadius: blurSigma,
                saturation: 1,
                tintColor: CGColor(red: padContentPopoverTintGray,
                                   green: padContentPopoverTintGray,
                                   blue: padContentPopoverTintGray,
                                   alpha: padContentPopoverMixAlpha),
                intensity: 1,
                clampsSaturation: true)
        case .platter:
            // Dark bar is a flag on `.platter`, not a kind: the same view
            // is light platter (253/220) and dark-bar (19/84). MEASURED
            // /tmp/glass-dark-out, SE 2x.
            let dark = view.traitCollection.userInterfaceStyle == .dark
            return configuration(dark: dark, bar: view._usesIOSDarkBarGlass)
        }
    }

    static var ringColor: CGColor {
        CGColor(red: 1, green: 1, blue: 1, alpha: ringAlpha)
    }

    static func ringColor(for view: UIView) -> CGColor {
        switch view._iosGlassKind {
        case .padActionSheetPopover:
            return CGColor(red: 1, green: 1, blue: 1, alpha: padActionSheetRingAlpha)
        case .padContentPopover, .platter:
            return ringColor
        }
    }

    static func shouldApply(_ view: UIView) -> Bool {
        guard view._usesIOSGlass,
              OpenUIKitRuntime.systemFontCut == .iOS else { return false }
        if view.traitCollection.userInterfaceStyle != .dark { return true }
        // Sheet mix (57 over black) and bar mix (19 over black) are
        // distinct; each flag selects its own configuration.
        return view._usesIOSDarkGlass || view._usesIOSDarkBarGlass
    }

    /// Backdrop blur + gray tint, clipped to `path`, plus the 1 pt inner
    /// highlight ring in light. Dark floating glass has no measured ring
    /// (Modal t1200.dark interior is a flat 57 cluster; a white ring would
    /// be a new unmatched edge).
    static func apply(in canvas: Canvas, path: Path, bounds: CGRect,
                      dark: Bool = false, view: UIView) {
        canvas.save()
        canvas.clip(to: path)
        canvas.applyBackdropFilter(configuration(for: view), in: bounds)
        if !dark {
            canvas.stroke(path, color: ringColor(for: view),
                          lineWidth: ringWidth * 2)
        }
        canvas.restore()
    }
}

/// Measured iOS 26 glass mixes. `.platter` is the bar / floating-sheet
/// material. Pad popovers are two other mixes (action-sheet vs content);
/// they do not share α with the platter or each other. Dark bar glass
/// stays `_usesIOSDarkBarGlass` on `.platter` (light 253/220, dark 19/84)
/// rather than a `.darkBar` case — the chrome is the same view.
enum _UIGlassKind: Equatable {
    case platter
    case padActionSheetPopover
    case padContentPopover
}
