// Canvas backend abstraction. Owner: quartz-backend module.
//
// Canvas's public API (the frozen contract in Canvas.swift) dispatches every
// drawing operation through a CanvasBackend chosen at Canvas creation:
//
//   - SwiftRasterizerBackend: the pure-Swift analytic-coverage rasterizer in
//     Rasterizer.swift, unchanged behavior. Zero dependencies.
//   - QuartzBackend (QuartzBackend.swift): the vendored libquartz
//     (Sources/CQuartz) rendering into a QZBitmapContext.
//
// Canvas itself always maintains the mirror graphics state in
// Canvas.state/stateStack (CTM + device-space clip coverage mask):
//   - the public `ctm` property is served from it for both backends,
//   - the Swift rasterizer draws directly from it,
//   - QuartzBackend.drawMask (glyph masks blended CPU-side for exact parity
//     with the tuned glyph smoothing) reads the clip mask from it.

/// Which rendering backend newly created `Canvas` instances use.
public enum RenderBackend: Sendable {
    /// Pure-Swift analytic-coverage rasterizer (zero-dependency fallback).
    case swift
    /// Vendored libquartz (portable Quartz 2D) via QZBitmapContext.
    case quartz
}

/// Process-wide backend selection. The OpenUIKit layer exposes this as
/// `OpenUIKitRuntime.renderBackend`; hosts (e.g. openrender) may override it
/// before rendering. The library itself never reads environment variables.
public enum CanvasBackendSelection {
    public static var current: RenderBackend = .quartz
}

protocol CanvasBackend: AnyObject {
    // State mirroring (Canvas.state already tracks CTM + clip mask itself;
    // these let a backend with its own graphics state stay in lockstep).
    func saveState()
    func restoreState()
    func concatenate(_ t: CGAffineTransform)
    func clip(_ path: Path)

    func beginTransparencyLayer(alpha: CGFloat)
    func beginMaskedTransparencyLayer(alpha: CGFloat, mask: Path)
    func endTransparencyLayer()

    func fill(_ path: Path, color: CGColor, evenOdd: Bool, hardEdges: Bool)
    func stroke(_ path: Path, color: CGColor, lineWidth: CGFloat)
    /// Additive: stroke honoring cap/join styles. Default implementation
    /// falls back to the plain stroke (butt caps, round joins), so a
    /// backend that cannot express the styles needs no change.
    func stroke(_ path: Path, color: CGColor, lineWidth: CGFloat,
                cap: CanvasLineCap, join: CanvasLineJoin, miterLimit: CGFloat)
    func drawImage(_ image: Bitmap, in rect: CGRect, interpolate: Bool)
    func drawMask(_ mask: [UInt8], width: Int, height: Int,
                  atPixelX x: Int, pixelY y: Int, color: CGColor)

    // Additive v2 ops (CanvasEffects.swift). Shadow state lives in
    // Canvas.state.shadow and is honored by `fill`; drawShadowOnly renders
    // the shadow without the casting fill (for group-opacity layers).
    func drawLinearGradient(colors: [CGColor], locations: [CGFloat],
                            start: CGPoint, end: CGPoint, in rect: CGRect)
    func drawShadowOnly(_ path: Path, evenOdd: Bool, _ shadow: CanvasShadow)
}

/// Line cap / join styles for the additive stroke entry point
/// (CGLineCap / CGLineJoin).
public enum CanvasLineCap: Sendable { case butt, round, square }
public enum CanvasLineJoin: Sendable { case miter, round, bevel }

extension CanvasBackend {
    func stroke(_ path: Path, color: CGColor, lineWidth: CGFloat,
                cap: CanvasLineCap, join: CanvasLineJoin, miterLimit: CGFloat) {
        stroke(path, color: color, lineWidth: lineWidth)
    }
}

/// The existing pure-Swift rasterizer (Rasterizer.swift), reached through the
/// backend seam. Canvas keeps the graphics state; drawing methods forward to
/// the rasterizer's internal `_` hooks unchanged.
final class SwiftRasterizerBackend: CanvasBackend {
    unowned let canvas: Canvas
    init(canvas: Canvas) { self.canvas = canvas }

    // Canvas.state/stateStack already hold the whole graphics state the Swift
    // rasterizer needs — nothing extra to mirror.
    func saveState() {}
    func restoreState() {}
    func concatenate(_ t: CGAffineTransform) {}
    func clip(_ path: Path) {}

    func beginTransparencyLayer(alpha: CGFloat) { canvas._beginLayer(alpha) }
    func beginMaskedTransparencyLayer(alpha: CGFloat, mask: Path) {
        canvas._beginLayer(1, mask: canvas._coverageMask(mask, alpha: alpha))
    }
    func endTransparencyLayer() { canvas._endLayer() }

    func fill(_ path: Path, color: CGColor, evenOdd: Bool, hardEdges: Bool) {
        // Shadow first: a blurred, offset silhouette of the shape beneath the
        // fill (CG semantics; see CanvasEffects.swift / RasterizerEffects.swift).
        if let sh = canvas.state.shadow, sh.color.alpha > 0 {
            canvas._drawShadow(path, evenOdd: evenOdd, sh)
        }
        if hardEdges {
            canvas._fillHardEdged(path, color, evenOdd)
        } else {
            canvas._fill(path, color, evenOdd)
        }
    }
    func stroke(_ path: Path, color: CGColor, lineWidth: CGFloat) {
        canvas._stroke(path, color, lineWidth)
    }
    func drawImage(_ image: Bitmap, in rect: CGRect, interpolate: Bool) {
        canvas._drawImage(image, rect, interpolate)
    }
    func drawMask(_ mask: [UInt8], width: Int, height: Int,
                  atPixelX x: Int, pixelY y: Int, color: CGColor) {
        canvas._drawMask(mask, width, height, x, y, color)
    }
    func drawLinearGradient(colors: [CGColor], locations: [CGFloat],
                            start: CGPoint, end: CGPoint, in rect: CGRect) {
        canvas._drawLinearGradient(colors, locations, start, end, rect)
    }
    func drawShadowOnly(_ path: Path, evenOdd: Bool, _ shadow: CanvasShadow) {
        canvas._drawShadow(path, evenOdd: evenOdd, shadow)
    }
}
