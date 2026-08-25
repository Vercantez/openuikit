// OpenUIKit — portable UIKit reimplementation.
// RULES for every file in this target:
//   - No Foundation. No Apple frameworks. Pure Swift + OpenCoreGraphics
//     (+ CSTBTrueType/CPortableIO through dedicated wrappers only).
//   - Match real UIKit behavior; golden data in golden/ is ground truth.
@_exported import OpenCoreGraphics

/// Global runtime configuration. openrender (or any host app) sets
/// `resourceRoot` before using OpenUIKit; resource files live in
/// Sources/OpenUIKit/Resources/ and are read via CPortableIO.
public enum OpenUIKitRuntime {
    /// Directory containing system_colors.json, font_metrics.json, and fonts.
    public static var resourceRoot: String = "Sources/OpenUIKit/Resources"
    /// Optional explicit font file paths (system, bold-face variants, mono, italic).
    /// When empty, the font engine falls back to platform-known locations
    /// (e.g. /System/Library/Fonts/SFNS.ttf on macOS).
    public static var fontPaths: [String: String] = [:]
    /// Rendering backend for newly created Canvases: `.quartz` (vendored
    /// libquartz, the default) or `.swift` (pure-Swift rasterizer fallback).
    /// Hosts may override before rendering (openrender honors
    /// OPENUIKIT_BACKEND=swift|quartz); the library never reads env vars.
    public static var renderBackend: RenderBackend {
        get { CanvasBackendSelection.current }
        set { CanvasBackendSelection.current = newValue }
    }
    /// Compositor for UIRenderer.render (M5): `.layers` builds a QZLayer
    /// tree and lets quartz's CALayer compositor composite the hierarchy
    /// (LayerBridge.swift); `.renderPass` is the hand-written traversal
    /// (RenderPass.swift). `.layers` requires the quartz backend — with
    /// `renderBackend == .swift` the render pass is used regardless, so the
    /// pure-Swift zero-dependency path stays fully Swift.
    /// Hosts may override (openrender honors
    /// OPENUIKIT_COMPOSITOR=layers|renderpass); the library never reads
    /// env vars.
    public static var compositor: RenderCompositor = .layers
    /// Presentation clock for UIView animations (M6), in seconds since the
    /// animations were committed (t = 0 shows every non-delayed animation's
    /// FROM state). The host sets it, then renders: LayerBridge builds the
    /// layer tree from presentation values sampled at this time. Static
    /// hierarchies (no recorded animations) are unaffected by the clock.
    /// Requires the quartz backend + layers compositor (the render pass
    /// draws model values only — see docs/KNOWN_GAPS.md).
    public static var animationTime: Double = 0

    /// Host redraw hint (M7.5 dirty-flag rendering): the latest end time —
    /// on the `animationTime` clock — of any recorded UIView animation or
    /// control-internal animation (UISwitch toggle). A host needs to keep
    /// rendering frames while `animationTime <= animationWorkDeadline`;
    /// past it (and with no active scroll/navigation animation and no input)
    /// the frame is static and rendering can be skipped. Monotone
    /// non-decreasing; never reset.
    public internal(set) static var animationWorkDeadline: Double = -.infinity

    /// Record that presentation-affecting animation work runs until `t`.
    static func noteAnimationWork(until t: Double) {
        if t > animationWorkDeadline { animationWorkDeadline = t }
    }

    /// Layer-contents caching (M8 perf): LayerBridge reuses per-view content
    /// images and flattens visually-stable subtrees into cached composites,
    /// so a sustained scroll recomposites cached bitmaps instead of
    /// re-rasterizing every glyph/path each frame (docs/APP_FEEL.md
    /// "Performance"). Purely an optimization — single-frame renders (the
    /// golden pipeline builds a fresh tree per scene) never engage the
    /// subtree cache. Hosts may disable for A/B or debugging (openhost /
    /// openrender honor OPENUIKIT_LAYER_CACHE=off); the library never reads
    /// env vars.
    public static var layerCaching = true
}

/// Compositing strategy for view-hierarchy rendering (see
/// `OpenUIKitRuntime.compositor`).
public enum RenderCompositor: Sendable {
    case renderPass
    case layers
}
