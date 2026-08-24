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
    func endTransparencyLayer()

    func fill(_ path: Path, color: CGColor, evenOdd: Bool, hardEdges: Bool)
    func stroke(_ path: Path, color: CGColor, lineWidth: CGFloat)
    func drawImage(_ image: Bitmap, in rect: CGRect, interpolate: Bool)
    func drawMask(_ mask: [UInt8], width: Int, height: Int,
                  atPixelX x: Int, pixelY y: Int, color: CGColor)
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
    func endTransparencyLayer() { canvas._endLayer() }

    func fill(_ path: Path, color: CGColor, evenOdd: Bool, hardEdges: Bool) {
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
}
