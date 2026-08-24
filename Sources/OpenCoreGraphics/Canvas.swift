// Software rendering surface API. Pure Swift, portable.
//
// This file defines the CONTRACT the rest of OpenUIKit builds against.
// Bodies marked `rasterizer:` are implemented in Rasterizer.swift by the
// rasterizer module — keep signatures stable.

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
    // storage here if needed).
    var state: CanvasState
    var stateStack: [CanvasState] = []
    var layerStack: [TransparencyLayer] = []

    public init(bitmap: Bitmap, scale: CGFloat) {
        self.bitmap = bitmap
        self.scale = scale
        self.state = CanvasState(ctm: CGAffineTransform(scaleX: scale, y: scale))
    }

    public func save() { _save() }
    public func restore() { _restore() }
    /// Concatenate t onto the CTM (new user space = t applied before current CTM).
    public func concatenate(_ t: CGAffineTransform) { _concatenate(t) }
    public func translate(x: CGFloat, y: CGFloat) { concatenate(CGAffineTransform(translationX: x, y: y)) }

    /// Intersect the clip with a (possibly rounded) rect in current user space.
    public func clip(to rect: CGRect, cornerRadius: CGFloat = 0) {
        clip(to: cornerRadius > 0 ? .roundedRect(rect, cornerRadius: cornerRadius) : .rect(rect))
    }
    public func clip(to path: Path) { _clip(path) }

    public func beginTransparencyLayer(alpha: CGFloat) { _beginLayer(alpha) }
    public func endTransparencyLayer() { _endLayer() }

    public func fill(_ path: Path, color: CGColor, evenOdd: Bool = false) { _fill(path, color, evenOdd) }
    public func fill(rect: CGRect, color: CGColor) { fill(.rect(rect), color: color) }
    public func stroke(_ path: Path, color: CGColor, lineWidth: CGFloat) { _stroke(path, color, lineWidth) }

    /// Draw a bitmap into `rect` (user space). `interpolate` = bilinear.
    public func draw(_ image: Bitmap, in rect: CGRect, interpolate: Bool = true) {
        _drawImage(image, rect, interpolate)
    }

    /// Draw an 8-bit coverage mask (e.g. a rasterized glyph) tinted with
    /// `color`. `origin` is in DEVICE PIXELS (already scaled/positioned by
    /// the text engine); mask is width×height bytes.
    public func drawMask(_ mask: [UInt8], width: Int, height: Int,
                         atPixelX x: Int, pixelY y: Int, color: CGColor) {
        _drawMask(mask, width, height, x, y, color)
    }

    /// Current CTM (points → device pixels).
    public var ctm: CGAffineTransform { state.ctm }
}

struct CanvasState {
    var ctm: CGAffineTransform
    /// Clip as an 8-bit coverage mask in device space; nil = no clip.
    var clipMask: [UInt8]? = nil
}

struct TransparencyLayer {
    var savedPixels: [UInt8]
    var alpha: CGFloat
    var savedStateStackDepth: Int
}
