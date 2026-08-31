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
    /// Directories searched by `UIImage(named:)`, in order. EMPTY by
    /// default: the library hardcodes no host paths — an app or host sets
    /// this to its asset directories (the analogue of a bundle's resource
    /// path). Call `UIImage.clearNamedCache()` after changing it.
    public static var imageSearchPaths: [String] = []
    /// Scale `UIImage(named:)` prefers when several `@Nx` variants exist
    /// (the analogue of `UIScreen.main.scale`; 2 = retina, matching the
    /// scene suite's default render scale).
    public static var imageScreenScale: CGFloat = 2
    /// Device idiom used by the Foundation-free asset-catalog resolver.
    ///
    /// `UIDevice.current` is MainActor-isolated while UIImage/UIColor named
    /// lookup is a synchronous, nonisolated framework API. Keep that boundary
    /// explicit and host-configurable instead of smuggling an actor hop into
    /// resource loading. The documented portable device is an iPhone, so the
    /// default matches `UIDevice.current.userInterfaceIdiom`.
    public static var assetCatalogIdiom: UIUserInterfaceIdiom = .phone
    /// Optional explicit font file paths (system, bold-face variants, mono, italic).
    /// When empty, the font engine falls back to platform-known locations
    /// (e.g. /System/Library/Fonts/SFNS.ttf on macOS).
    public static var fontPaths: [String: String] = [:]
    /// Which CUT of the San Francisco system font the metrics tables should
    /// describe (see `FontEngine.SystemFontCut`). Apple ships two different
    /// builds of SF: `.SFNS` on macOS / Mac Catalyst and `.SFUI` on iOS, and
    /// their advance widths differ by a measured per-size constant below
    /// 20 pt. Default `.macOS`, which is what the vendored
    /// font_metrics.json describes and what the rasterizer's SFNS.ttf draws.
    public static var systemFontCut: FontEngine.SystemFontCut = .macOS
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
    /// layer tree from presentation values sampled at this time. RenderPass
    /// also samples its supported geometry/opacity/corner-radius and explicit
    /// gradient-location subset on either Canvas backend; animated transforms
    /// and background colors still require the layers compositor. Static
    /// hierarchies (no recorded animations) are unaffected by the clock.
    /// See docs/KNOWN_GAPS.md for the exact split.
    public static var animationTime: Double = 0

    /// Host redraw hint (M7.5 dirty-flag rendering): the latest end time —
    /// on the `animationTime` clock — of any recorded presentation work. A
    /// host needs to keep rendering frames while
    /// `animationTime <= animationWorkDeadline`; past it (and with no active
    /// scroll/navigation animation and no input) the frame is static and
    /// rendering can be skipped.
    ///
    /// Most UIKit/control animations publish a monotone high-water mark.
    /// Explicit Core Animation work is tracked separately because removing
    /// or replacing an infinite animation must lower the live-work deadline.
    private static var retainedAnimationWorkDeadline: Double = -.infinity
    private static var coreAnimationWorkDeadline: Double = -.infinity
    public internal(set) static var animationWorkDeadline: Double {
        get { Swift.max(retainedAnimationWorkDeadline, coreAnimationWorkDeadline) }
        set {
            // The setter is intentionally a reset/restore seam for tests.
            retainedAnimationWorkDeadline = newValue
            coreAnimationWorkDeadline = -.infinity
        }
    }

    /// Record that presentation-affecting animation work runs until `t`.
    static func noteAnimationWork(until t: Double) {
        if t > retainedAnimationWorkDeadline {
            retainedAnimationWorkDeadline = t
        }
    }

    /// Replace the live explicit-Core-Animation deadline. Unlike the general
    /// high-water mark this value may move down when work is cancelled.
    static func _setCoreAnimationWorkDeadline(_ t: Double) {
        coreAnimationWorkDeadline = t
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
