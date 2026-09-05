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
//   red residual  predicted (253.0, 227.2, 227.8) vs (255, 201, 204)
//     |res| G=26.2 B=23.8 — chroma is outside the two-unknown mix; reported,
//     not fitted (a third saturation unknown would close it)
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
// Catalyst keeps the flat fills. Dark iOS chrome is a separate measured
// flat (19,19,19) / (25,25,25) and is not this material.

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

    static var configuration: CanvasBackdropFilterConfiguration {
        configuration(dark: false)
    }

    static func configuration(dark: Bool) -> CanvasBackdropFilterConfiguration {
        if dark {
            return CanvasBackdropFilterConfiguration(
                blurRadius: blurSigma,
                saturation: 1,
                tintColor: CGColor(red: darkTintGray, green: darkTintGray,
                                   blue: darkTintGray, alpha: darkMixAlpha),
                intensity: 1)
        }
        return CanvasBackdropFilterConfiguration(
            blurRadius: blurSigma,
            saturation: 1,
            tintColor: CGColor(red: tintGray, green: tintGray,
                               blue: tintGray, alpha: mixAlpha),
            intensity: 1)
    }

    static var ringColor: CGColor {
        CGColor(red: 1, green: 1, blue: 1, alpha: ringAlpha)
    }

    static func shouldApply(_ view: UIView) -> Bool {
        guard view._usesIOSGlass,
              OpenUIKitRuntime.systemFontCut == .iOS else { return false }
        if view.traitCollection.userInterfaceStyle != .dark { return true }
        // Bar platters stay the measured dark flats (19/25). Only the
        // floating systemBackground sheet uses dark glass.
        return view._usesIOSDarkGlass
    }

    /// Backdrop blur + gray tint, clipped to `path`, plus the 1 pt inner
    /// highlight ring in light. Dark floating glass has no measured ring
    /// (Modal t1200.dark interior is a flat 57 cluster; a white ring would
    /// be a new unmatched edge).
    static func apply(in canvas: Canvas, path: Path, bounds: CGRect,
                      dark: Bool = false) {
        canvas.save()
        canvas.clip(to: path)
        canvas.applyBackdropFilter(configuration(dark: dark), in: bounds)
        if !dark {
            canvas.stroke(path, color: ringColor, lineWidth: ringWidth * 2)
        }
        canvas.restore()
    }
}
