// Software rendering surface API. Pure Swift, portable.
//
// This file defines the CONTRACT the rest of OpenUIKit builds against.
// Bodies marked `rasterizer:` are implemented in Rasterizer.swift by the
// rasterizer module — keep signatures stable.

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


/// Straight (non-premultiplied) sRGB color with 0–1 components.


public struct CGColor: Equatable, Sendable {
    public var red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat
    public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        self.red = red; self.green = green; self.blue = blue; self.alpha = alpha
    }
    public static let clear = CGColor(red: 0, green: 0, blue: 0, alpha: 0)
    public static let black = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
    public static let white = CGColor(red: 1, green: 1, blue: 1, alpha: 1)
    public func withAlpha(_ a: CGFloat) -> CGColor {
        CGColor(red: red, green: green, blue: blue, alpha: alpha * a)
    }
}

/// Color-space identity accepted by bitmap graphics contexts.
///
/// The current renderer is an 8-bit sRGB pipeline, so device RGB is the one
/// truthful writable space. Keeping it as a reference value matches the
/// CoreGraphics ownership shape and leaves room for calibrated spaces without
/// pretending that they are already implemented.
public final class CGColorSpace: @unchecked Sendable {
    enum Model: Equatable { case deviceRGB }
    let model: Model

    fileprivate init(model: Model) {
        self.model = model
    }
}

/// Creates the writable device-RGB space used by RGBA bitmap contexts.
public func CGColorSpaceCreateDeviceRGB() -> CGColorSpace {
    CGColorSpace(model: .deviceRGB)
}

/// Alpha placement values in the low five bits of a bitmap-info word.
public enum CGImageAlphaInfo: UInt32, Sendable {
    case none = 0
    case premultipliedLast = 1
    case premultipliedFirst = 2
    case last = 3
    case first = 4
    case noneSkipLast = 5
    case noneSkipFirst = 6
    case alphaOnly = 7
}

/// RGBA8 bitmap, non-premultiplied sRGB, row-major, 4 bytes/pixel.
public final class Bitmap {
    public let width: Int
    public let height: Int
    public var pixels: [UInt8]  // count == width * height * 4

    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
        self.pixels = [UInt8](repeating: 0, count: Swift.max(0, width * height * 4))
    }

    /// Encode as PNG. Implemented in PNG.swift (may use uncompressed
    /// deflate blocks — validity matters, size does not).
    public func pngData() -> [UInt8] { _pngEncode(self) }
}

/// Bezier path in user (point) space.
public struct Path: Sendable {
    public enum Element: Sendable {
        case move(CGPoint)
        case line(CGPoint)
        case quad(control: CGPoint, end: CGPoint)
        case cubic(control1: CGPoint, control2: CGPoint, end: CGPoint)
        case close
    }
    public var elements: [Element] = []
    public init() {}

    public mutating func move(to p: CGPoint) { elements.append(.move(p)) }
    public mutating func addLine(to p: CGPoint) { elements.append(.line(p)) }
    public mutating func addQuad(to p: CGPoint, control: CGPoint) {
        elements.append(.quad(control: control, end: p))
    }
    public mutating func addCurve(to p: CGPoint, control1: CGPoint, control2: CGPoint) {
        elements.append(.cubic(control1: control1, control2: control2, end: p))
    }
    public mutating func close() { elements.append(.close) }

    public static func rect(_ r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.close()
        return p
    }

    /// Rounded rect matching UIKit's layer.cornerRadius (circular corners,
    /// radius clamped to half the smaller side).
    public static func roundedRect(_ r: CGRect, cornerRadius: CGFloat) -> Path {
        let radius = Swift.min(cornerRadius, Swift.min(r.width, r.height) / 2)
        if radius <= 0 { return .rect(r) }
        // Approximate quarter circles with cubics (kappa).
        let k: CGFloat = 0.5522847498307936
        let kr = k * radius
        var p = Path()
        p.move(to: CGPoint(x: r.minX + radius, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - radius, y: r.minY))
        p.addCurve(to: CGPoint(x: r.maxX, y: r.minY + radius),
                   control1: CGPoint(x: r.maxX - radius + kr, y: r.minY),
                   control2: CGPoint(x: r.maxX, y: r.minY + radius - kr))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - radius))
        p.addCurve(to: CGPoint(x: r.maxX - radius, y: r.maxY),
                   control1: CGPoint(x: r.maxX, y: r.maxY - radius + kr),
                   control2: CGPoint(x: r.maxX - radius + kr, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + radius, y: r.maxY))
        p.addCurve(to: CGPoint(x: r.minX, y: r.maxY - radius),
                   control1: CGPoint(x: r.minX + radius - kr, y: r.maxY),
                   control2: CGPoint(x: r.minX, y: r.maxY - radius + kr))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + radius))
        p.addCurve(to: CGPoint(x: r.minX + radius, y: r.minY),
                   control1: CGPoint(x: r.minX, y: r.minY + radius - kr),
                   control2: CGPoint(x: r.minX + radius - kr, y: r.minY))
        p.close()
        return p
    }

    public func applying(_ t: CGAffineTransform) -> Path {
        var out = Path()
        out.elements = elements.map { e in
            switch e {
            case .move(let p): return .move(p.applying(t))
            case .line(let p): return .line(p.applying(t))
            case .quad(let c, let p): return .quad(control: c.applying(t), end: p.applying(t))
            case .cubic(let c1, let c2, let p):
                return .cubic(control1: c1.applying(t), control2: c2.applying(t), end: p.applying(t))
            case .close: return .close
            }
        }
        return out
    }
}

/// Drawing surface. User space is POINTS; `scale` maps points → device pixels.
/// The CTM starts as scale-by-`scale` and is modified via concatenate().
///
/// Semantics to match CoreGraphics/UIKit behavior:
/// - Fills are anti-aliased with analytic coverage (CG-quality AA).
/// - Non-zero winding rule for fill (evenOdd variant available).
/// - Alpha compositing is source-over in *linear-ish sRGB approximation*:
///   CG composites in the bitmap's color space (sRGB, gamma-encoded) —
///   match that: blend on gamma-encoded values like CG does for sRGB surfaces.
/// - Transparency layers: drawing between begin/end goes to an offscreen
///   buffer composited on end with the given alpha (this is how UIView
///   alpha groups its subviews).
public final class Canvas {
    public let bitmap: Bitmap
    public let scale: CGFloat

    // Rasterizer-owned state (Rasterizer.swift may add fields via extension
    // storage here if needed). Canvas maintains this mirror state for BOTH
    // backends: it serves the public `ctm`, the Swift rasterizer's whole
    // graphics state, and the clip mask QuartzBackend.drawMask consumes.
    var state: CanvasState
    var stateStack: [CanvasState] = []
    var layerStack: [TransparencyLayer] = []

    /// Rendering backend (Backend.swift), chosen at creation from
    /// `CanvasBackendSelection.current`. All drawing ops dispatch through it.
    var backend: CanvasBackend!
    private var externalBitmapData: UnsafeMutableRawPointer?
    private var externalBitmapBytesPerRow = 0

    public init(bitmap: Bitmap, scale: CGFloat) {
        self.bitmap = bitmap
        self.scale = scale
        self.state = CanvasState(ctm: CGAffineTransform(scaleX: scale, y: scale))
        switch CanvasBackendSelection.current {
        case .quartz:
            // Falls back to the Swift rasterizer for degenerate (empty)
            // surfaces that a QZBitmapContext cannot represent.
            self.backend = QuartzBackend(canvas: self) ?? SwiftRasterizerBackend(canvas: self)
        case .swift:
            self.backend = SwiftRasterizerBackend(canvas: self)
        }
    }

    /// Creates an 8-bit premultiplied-last device-RGB bitmap context.
    ///
    /// A non-nil data pointer remains the live Quartz backing for the context;
    /// callers retain ownership and must keep it valid for this object's
    /// lifetime, matching CoreGraphics. Unsupported component/layout choices
    /// fail closed instead of being silently reinterpreted.
    public convenience init?(
        data: UnsafeMutableRawPointer?,
        width: Int,
        height: Int,
        bitsPerComponent: Int,
        bytesPerRow: Int,
        space: CGColorSpace,
        bitmapInfo: UInt32
    ) {
        let (minimumBytesPerRow, rowWidthOverflow) = width.multipliedReportingOverflow(by: 4)
        let (_, bitmapSizeOverflow) = minimumBytesPerRow.multipliedReportingOverflow(by: height)
        let (_, backingSizeOverflow) = bytesPerRow.multipliedReportingOverflow(by: height)
        guard width > 0, height > 0,
              width <= Int(Int32.max), height <= Int(Int32.max),
              !rowWidthOverflow, !bitmapSizeOverflow, !backingSizeOverflow,
              bitsPerComponent == 8,
              bytesPerRow >= minimumBytesPerRow,
              space.model == .deviceRGB,
              bitmapInfo == CGImageAlphaInfo.premultipliedLast.rawValue
        else { return nil }

        let bitmap = Bitmap(width: width, height: height)
        if let data {
            let source = data.assumingMemoryBound(to: UInt8.self)
            for y in 0..<height {
                let sourceRow = y * bytesPerRow
                let destinationRow = y * width * 4
                for x in 0..<width {
                    let sourceOffset = sourceRow + x * 4
                    let destinationOffset = destinationRow + x * 4
                    let alpha = Int(source[sourceOffset + 3])
                    bitmap.pixels[destinationOffset + 3] = UInt8(alpha)
                    if alpha == 0 {
                        bitmap.pixels[destinationOffset] = 0
                        bitmap.pixels[destinationOffset + 1] = 0
                        bitmap.pixels[destinationOffset + 2] = 0
                    } else if alpha == 255 {
                        bitmap.pixels[destinationOffset] = source[sourceOffset]
                        bitmap.pixels[destinationOffset + 1] = source[sourceOffset + 1]
                        bitmap.pixels[destinationOffset + 2] = source[sourceOffset + 2]
                    } else {
                        bitmap.pixels[destinationOffset] = UInt8(Swift.min(
                            255, (Int(source[sourceOffset]) * 255 + alpha / 2) / alpha
                        ))
                        bitmap.pixels[destinationOffset + 1] = UInt8(Swift.min(
                            255, (Int(source[sourceOffset + 1]) * 255 + alpha / 2) / alpha
                        ))
                        bitmap.pixels[destinationOffset + 2] = UInt8(Swift.min(
                            255, (Int(source[sourceOffset + 2]) * 255 + alpha / 2) / alpha
                        ))
                    }
                }
            }
        }

        self.init(bitmap: bitmap, scale: 1)
        guard let context = QuartzBackend(
            canvas: self,
            data: data,
            bytesPerRow: bytesPerRow,
            bitmapInfo: bitmapInfo
        ) else { return nil }
        externalBitmapData = data
        externalBitmapBytesPerRow = bytesPerRow
        backend = context
    }

    /// Returns an immutable-by-value snapshot of the context's current image.
    public func makeImage() -> Bitmap? {
        if let data = externalBitmapData {
            let source = data.assumingMemoryBound(to: UInt8.self)
            for y in 0..<bitmap.height {
                let sourceRow = y * externalBitmapBytesPerRow
                let destinationRow = y * bitmap.width * 4
                for x in 0..<bitmap.width {
                    let sourceOffset = sourceRow + x * 4
                    let destinationOffset = destinationRow + x * 4
                    let alpha = Int(source[sourceOffset + 3])
                    bitmap.pixels[destinationOffset + 3] = UInt8(alpha)
                    for component in 0..<3 {
                        bitmap.pixels[destinationOffset + component] = alpha == 0
                            ? 0
                            : UInt8(Swift.min(
                                255,
                                (Int(source[sourceOffset + component]) * 255
                                    + alpha / 2) / alpha
                            ))
                    }
                }
            }
        }
        let image = Bitmap(width: bitmap.width, height: bitmap.height)
        image.pixels = bitmap.pixels
        return image
    }

    public func save() { _save(); backend.saveState() }
    public func restore() { _restore(); backend.restoreState() }
    /// Concatenate t onto the CTM (new user space = t applied before current CTM).
    public func concatenate(_ t: CGAffineTransform) { _concatenate(t); backend.concatenate(t) }
    public func translate(x: CGFloat, y: CGFloat) { concatenate(CGAffineTransform(translationX: x, y: y)) }

    /// Intersect the clip with a (possibly rounded) rect in current user space.
    public func clip(to rect: CGRect, cornerRadius: CGFloat = 0) {
        clip(to: cornerRadius > 0 ? .roundedRect(rect, cornerRadius: cornerRadius) : .rect(rect))
    }
    public func clip(to path: Path) { _clip(path); backend.clip(path) }

    public func beginTransparencyLayer(alpha: CGFloat) { backend.beginTransparencyLayer(alpha: alpha) }

    /// Begin an offscreen transparency group whose completed pixels are
    /// multiplied by `mask` coverage exactly once before compositing. This
    /// additive entry point models CALayer.mask; using `clip(to:)` would
    /// attenuate every overlapping draw independently at antialiased edges.
    public func beginMaskedTransparencyLayer(alpha: CGFloat, mask: Path) {
        backend.beginMaskedTransparencyLayer(alpha: alpha, mask: mask)
    }
    public func endTransparencyLayer() { backend.endTransparencyLayer() }

    /// Fill a path. `hardEdges: true` disables edge anti-aliasing: coverage is
    /// thresholded to 0/1 by sampling at the pixel center (i.e. threshold at
    /// 0.5 coverage). Used by the render pass for rotated/scaled layers, whose
    /// edges real UIKit does NOT anti-alias (see docs/ARCHITECTURE.md).
    /// ADDITIVE extension of the frozen contract: `hardEdges` has a default
    /// value, so all previous call sites are unchanged.
    public func fill(_ path: Path, color: CGColor, evenOdd: Bool = false,
                     hardEdges: Bool = false) {
        backend.fill(path, color: color, evenOdd: evenOdd, hardEdges: hardEdges)
    }
    public func fill(rect: CGRect, color: CGColor) { fill(.rect(rect), color: color) }
    public func stroke(_ path: Path, color: CGColor, lineWidth: CGFloat) {
        backend.stroke(path, color: color, lineWidth: lineWidth)
    }

    /// Stroke with explicit cap/join styles (ADDITIVE extension of the
    /// frozen contract — the 3-argument form above is unchanged and keeps
    /// its historical butt-cap / round-join behavior). App-side drawing
    /// (`UIBezierPath.lineCapStyle` / `lineJoinStyle`) needs the styles;
    /// the quartz backend maps them onto QZ's stroker, the pure-Swift
    /// rasterizer ignores them (documented in docs/KNOWN_GAPS.md).
    public func stroke(_ path: Path, color: CGColor, lineWidth: CGFloat,
                       cap: CanvasLineCap, join: CanvasLineJoin,
                       miterLimit: CGFloat = 10) {
        backend.stroke(path, color: color, lineWidth: lineWidth, cap: cap,
                       join: join, miterLimit: miterLimit)
    }

    /// Draw a bitmap into `rect` (user space). `interpolate` = bilinear.
    public func draw(_ image: Bitmap, in rect: CGRect, interpolate: Bool = true) {
        backend.drawImage(image, in: rect, interpolate: interpolate)
    }

    /// Draw an 8-bit coverage mask (e.g. a rasterized glyph) tinted with
    /// `color`. `origin` is in DEVICE PIXELS (already scaled/positioned by
    /// the text engine); mask is width×height bytes.
    public func drawMask(_ mask: [UInt8], width: Int, height: Int,
                         atPixelX x: Int, pixelY y: Int, color: CGColor) {
        backend.drawMask(mask, width: width, height: height,
                         atPixelX: x, pixelY: y, color: color)
    }

    /// Current CTM (points → device pixels).
    public var ctm: CGAffineTransform { state.ctm }
}

struct CanvasState {
    var ctm: CGAffineTransform
    /// Clip as an 8-bit coverage mask in device space; nil = no clip.
    var clipMask: [UInt8]? = nil
    /// Layer shadow applied to subsequent fills; nil = none. Part of the
    /// saved graphics state (save/restore), like CG shadows.
    /// (Additive v2 state — see CanvasEffects.swift for the public API.)
    var shadow: CanvasShadow? = nil
}

struct TransparencyLayer {
    var savedPixels: [UInt8]
    var alpha: CGFloat
    var savedStateStackDepth: Int
    /// Device-space coverage applied to the completed group, not its draws.
    var mask: [UInt8]?
}

// MARK: - Hard-edged (non-anti-aliased) fill
//
// Self-contained implementation (depends only on state declared in this file,
// not on Rasterizer.swift internals) so the rasterizer module can freely
// rewrite its analytic-AA pipeline without touching this.
extension Canvas {
    func _fillHardEdged(_ path: Path, _ color: CGColor, _ evenOdd: Bool) {
        guard color.alpha > 0 else { return }
        let dev = path.applying(state.ctm)

        // Flatten to line segments in device space.
        var segs: [(CGPoint, CGPoint)] = []
        var start = CGPoint.zero, cur = CGPoint.zero
        func flatten(_ f: (CGFloat) -> CGPoint) {
            let steps = 24
            var prev = cur
            for i in 1...steps {
                let p = f(CGFloat(i) / CGFloat(steps))
                segs.append((prev, p))
                prev = p
            }
            cur = prev
        }
        for e in dev.elements {
            switch e {
            case .move(let p): start = p; cur = p
            case .line(let p): segs.append((cur, p)); cur = p
            case .quad(let c, let p):
                let from = cur
                flatten { t in
                    // The intermediate annotations are load-bearing: without
                    // them the solver has to consider the CGFloat<->Double
                    // conversions at every one of these operators and times
                    // out (M15 — CGFloat stopped being a typealias for Double).
                    let mt: CGFloat = 1 - t
                    let a: CGFloat = mt * mt, b: CGFloat = 2 * mt * t, cc: CGFloat = t * t
                    return CGPoint(x: a * from.x + b * c.x + cc * p.x,
                                   y: a * from.y + b * c.y + cc * p.y)
                }
            case .cubic(let c1, let c2, let p):
                let from = cur
                flatten { t in
                    let mt: CGFloat = 1 - t
                    let w0: CGFloat = mt * mt * mt
                    let w1: CGFloat = 3 * mt * mt * t
                    let w2: CGFloat = 3 * mt * t * t
                    let w3: CGFloat = t * t * t
                    let x: CGFloat = w0 * from.x + w1 * c1.x + w2 * c2.x + w3 * p.x
                    let y: CGFloat = w0 * from.y + w1 * c1.y + w2 * c2.y + w3 * p.y
                    return CGPoint(x: x, y: y)
                }
            case .close:
                segs.append((cur, start)); cur = start
            }
        }
        guard !segs.isEmpty else { return }

        var minX = CGFloat.infinity, minY = CGFloat.infinity
        var maxX = -CGFloat.infinity, maxY = -CGFloat.infinity
        for s in segs {
            minX = Swift.min(minX, s.0.x, s.1.x); maxX = Swift.max(maxX, s.0.x, s.1.x)
            minY = Swift.min(minY, s.0.y, s.1.y); maxY = Swift.max(maxY, s.0.y, s.1.y)
        }
        let x0 = Swift.max(0, Int(minX.rounded(.down)))
        let x1 = Swift.min(bitmap.width - 1, Int(maxX.rounded(.up)))
        let y0 = Swift.max(0, Int(minY.rounded(.down)))
        let y1 = Swift.min(bitmap.height - 1, Int(maxY.rounded(.up)))
        guard x0 <= x1, y0 <= y1 else { return }

        for y in y0...y1 {
            let py = CGFloat(y) + 0.5
            for x in x0...x1 {
                let px = CGFloat(x) + 0.5
                // Single sample at the pixel center == 0/1 threshold at 0.5
                // coverage for straight edges.
                var winding = 0
                for (a, b) in segs {
                    if (a.y <= py && b.y > py) || (b.y <= py && a.y > py) {
                        let t = (py - a.y) / (b.y - a.y)
                        if a.x + t * (b.x - a.x) > px { winding += b.y > a.y ? 1 : -1 }
                    }
                }
                let inside = evenOdd ? (winding % 2 != 0) : (winding != 0)
                if !inside { continue }
                var a = color.alpha
                if let m = state.clipMask { a *= CGFloat(m[y * bitmap.width + x]) / 255 }
                if a <= 0 { continue }
                _hardBlend(at: (y * bitmap.width + x) * 4,
                           r: color.red, g: color.green, b: color.blue, a: a)
            }
        }
    }

    /// Straight-alpha source-over blend on gamma-encoded sRGB values
    /// (same semantics documented on Canvas).
    @inline(__always)
    private func _hardBlend(at o: Int, r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        let da = CGFloat(bitmap.pixels[o + 3]) / 255
        let outA = a + da * (1 - a)
        guard outA > 0 else {
            bitmap.pixels[o] = 0; bitmap.pixels[o + 1] = 0
            bitmap.pixels[o + 2] = 0; bitmap.pixels[o + 3] = 0
            return
        }
        let dr = CGFloat(bitmap.pixels[o]) / 255
        let dg = CGFloat(bitmap.pixels[o + 1]) / 255
        let db = CGFloat(bitmap.pixels[o + 2]) / 255
        func b8(_ v: CGFloat) -> UInt8 {
            UInt8(Swift.min(255, Swift.max(0, (v * 255).rounded())))
        }
        bitmap.pixels[o] = b8((r * a + dr * da * (1 - a)) / outA)
        bitmap.pixels[o + 1] = b8((g * a + dg * da * (1 - a)) / outA)
        bitmap.pixels[o + 2] = b8((b * a + db * da * (1 - a)) / outA)
        bitmap.pixels[o + 3] = b8(outA)
    }
}
