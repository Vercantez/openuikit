// UIBezierPath — app-side path construction and drawing.
// Owner: image/drawing module (app-compat cluster).
//
// Backed by OpenCoreGraphics `Path` (`cgPath`), so everything the render
// pipeline already does with paths — analytic-coverage fills, the quartz
// stroker, clipping — applies unchanged. `fill()` / `stroke()` /
// `addClip()` draw into the CURRENT graphics context
// (UIGraphicsRenderer.swift: `UIGraphicsGetCurrentContext()`), which is
// what a `draw(_ rect:)` override or a `UIGraphicsImageRenderer` block
// runs inside.
//
// Curve construction follows CoreGraphics exactly where CG is exact:
// ellipses and rounded-rect corners are the 4-cubic kappa construction
// (`Path.roundedRect` already implements the latter for layer corners), and
// arcs are split into <= 90-degree cubic segments with the standard
// k = 4/3 * tan(sweep/4) control-point rule.

// M15: a DEFAULT ARGUMENT or an `@inlinable` body may only use members whose
// defining module THIS FILE imports -- `CGRect.zero` and `CGFloat.pi` do not
// ride in on OpenCoreGraphics' typealias the way ordinary uses do. These are
// SCOPED imports on purpose: they satisfy that rule without pulling in
// CoreGraphics' CGColor / CGAffineTransform, which would collide with
// OpenCoreGraphics' own.
#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGPoint
import struct CoreGraphics.CGRect
import struct CoreGraphics.CGSize
#elseif canImport(Foundation)
import Foundation
#endif


/// Corner selection for `UIBezierPath(roundedRect:byRoundingCorners:cornerRadii:)`.


public struct UIRectCorner: OptionSet, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let topLeft = UIRectCorner(rawValue: 1 << 0)
    public static let topRight = UIRectCorner(rawValue: 1 << 1)
    public static let bottomLeft = UIRectCorner(rawValue: 1 << 2)
    public static let bottomRight = UIRectCorner(rawValue: 1 << 3)
    public static let allCorners: UIRectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
}

/// CG line cap styles (`CGLineCap`).
public enum CGLineCap: Sendable { case butt, round, square }
/// CG line join styles (`CGLineJoin`).
public enum CGLineJoin: Sendable { case miter, round, bevel }

public class UIBezierPath {
    /// The underlying OpenCoreGraphics path (UIKit's `cgPath`).
    public var cgPath: Path

    // Stroking / filling attributes (UIKit defaults).
    public var lineWidth: CGFloat = 1
    public var lineCapStyle: CGLineCap = .butt
    public var lineJoinStyle: CGLineJoin = .miter
    public var miterLimit: CGFloat = 10
    public var flatness: CGFloat = 0.6
    public var usesEvenOddFillRule: Bool = false

    /// Kappa: the circular-arc cubic control-point ratio CG uses for
    /// quarter-circle corners and ellipses.
    static let kappa: CGFloat = 0.5522847498307936

    public init() { cgPath = Path() }
    public init(cgPath: Path) { self.cgPath = cgPath }

    public init(rect: CGRect) { cgPath = .rect(rect) }

    /// Ellipse inscribed in `rect`, built like CGPathAddEllipseInRect:
    /// four kappa cubics starting at the right-middle point, clockwise in
    /// UIKit's top-left geometry.
    public init(ovalIn rect: CGRect) {
        cgPath = UIBezierPath.oval(in: rect)
    }

    /// Rounded rect with a uniform radius (identical to the layer corner
    /// construction — radius clamps to half the smaller side, like CGPath).
    public init(roundedRect rect: CGRect, cornerRadius: CGFloat) {
        cgPath = .roundedRect(rect, cornerRadius: cornerRadius)
    }

    /// Rounded rect with only `corners` rounded. UIKit takes a CGSize of
    /// radii; the circular construction uses `cornerRadii.width` for the
    /// horizontal reach and `.height` for the vertical one (a true elliptic
    /// corner), each clamped to half the corresponding side.
    public init(roundedRect rect: CGRect, byRoundingCorners corners: UIRectCorner,
                cornerRadii: CGSize) {
        cgPath = UIBezierPath.roundedRect(rect, corners: corners, radii: cornerRadii)
    }

    // MARK: Construction

    public var currentPoint: CGPoint? {
        var start: CGPoint? = nil
        var cur: CGPoint? = nil
        for e in cgPath.elements {
            switch e {
            case .move(let p): cur = p; start = p
            case .line(let p): cur = p
            case .quad(_, let p): cur = p
            case .cubic(_, _, let p): cur = p
            case .close: cur = start
            }
        }
        return cur
    }

    public var isEmpty: Bool { cgPath.elements.isEmpty }

    public func move(to point: CGPoint) { cgPath.move(to: point) }
    public func addLine(to point: CGPoint) { cgPath.addLine(to: point) }
    public func addQuadCurve(to point: CGPoint, controlPoint: CGPoint) {
        cgPath.addQuad(to: point, control: controlPoint)
    }
    public func addCurve(to point: CGPoint, controlPoint1: CGPoint, controlPoint2: CGPoint) {
        cgPath.addCurve(to: point, control1: controlPoint1, control2: controlPoint2)
    }
    public func close() { cgPath.close() }
    public func removeAllPoints() { cgPath = Path() }

    /// Append another path's elements (UIKit's `append(_:)`).
    public func append(_ path: UIBezierPath) {
        cgPath.elements.append(contentsOf: path.cgPath.elements)
    }

    /// Circular arc, angles in radians measured in UIKit's top-left
    /// geometry (y down), so `clockwise: true` means visually clockwise —
    /// the same convention UIKit documents for UIBezierPath.
    public func addArc(withCenter center: CGPoint, radius: CGFloat,
                       startAngle: CGFloat, endAngle: CGFloat, clockwise: Bool) {
        let start = CGPoint(x: center.x + radius * _bpCos(startAngle),
                            y: center.y + radius * _bpSin(startAngle))
        if currentPoint == nil {
            cgPath.move(to: start)
        } else {
            cgPath.addLine(to: start)
        }
        var sweep = endAngle - startAngle
        if clockwise {
            while sweep <= 0 { sweep += 2 * .pi }
        } else {
            while sweep >= 0 { sweep -= 2 * .pi }
        }
        if sweep.magnitude > 2 * .pi { sweep = sweep < 0 ? -2 * .pi : 2 * .pi }

        // <= 90 degrees per cubic segment (CG's own subdivision rule).
        let count = Swift.max(1, Int((sweep.magnitude / (.pi / 2)).rounded(.up)))
        let step = sweep / CGFloat(count)
        let k = 4.0 / 3.0 * _bpTan(step / 4)
        var a = startAngle
        for _ in 0..<count {
            let b = a + step
            let p0 = CGPoint(x: center.x + radius * _bpCos(a), y: center.y + radius * _bpSin(a))
            let p1 = CGPoint(x: center.x + radius * _bpCos(b), y: center.y + radius * _bpSin(b))
            let t0 = CGPoint(x: -radius * _bpSin(a), y: radius * _bpCos(a))
            let t1 = CGPoint(x: -radius * _bpSin(b), y: radius * _bpCos(b))
            cgPath.addCurve(to: p1,
                            control1: CGPoint(x: p0.x + k * t0.x, y: p0.y + k * t0.y),
                            control2: CGPoint(x: p1.x - k * t1.x, y: p1.y - k * t1.y))
            a = b
        }
    }

    /// UIKit convenience: a full circle/arc path.
    public convenience init(arcCenter center: CGPoint, radius: CGFloat,
                            startAngle: CGFloat, endAngle: CGFloat, clockwise: Bool) {
        self.init()
        addArc(withCenter: center, radius: radius, startAngle: startAngle,
               endAngle: endAngle, clockwise: clockwise)
    }

    /// Transform every point of the path in place (UIKit's `apply(_:)`).
    public func apply(_ transform: CGAffineTransform) {
        cgPath = cgPath.applying(transform)
    }

    /// A copy with `transform` applied (not UIKit API — the non-mutating
    /// form the drawing code here wants).
    public func applying(_ transform: CGAffineTransform) -> UIBezierPath {
        let p = UIBezierPath(cgPath: cgPath.applying(transform))
        p.copyAttributes(from: self)
        return p
    }

    public func copy() -> UIBezierPath {
        let p = UIBezierPath(cgPath: cgPath)
        p.copyAttributes(from: self)
        return p
    }

    func copyAttributes(from other: UIBezierPath) {
        lineWidth = other.lineWidth
        lineCapStyle = other.lineCapStyle
        lineJoinStyle = other.lineJoinStyle
        miterLimit = other.miterLimit
        flatness = other.flatness
        usesEvenOddFillRule = other.usesEvenOddFillRule
    }

    // MARK: Geometry queries

    /// Tight bounding box of the path's ON-CURVE geometry (UIKit's
    /// `bounds` is the control-point box; `bounds` here flattens curves, so
    /// it is the drawn extent — documented divergence, and the useful one).
    public var bounds: CGRect {
        let pts = flattened()
        guard !pts.isEmpty else { return .zero }
        var minX = pts[0].x, maxX = pts[0].x, minY = pts[0].y, maxY = pts[0].y
        for p in pts {
            minX = Swift.min(minX, p.x); maxX = Swift.max(maxX, p.x)
            minY = Swift.min(minY, p.y); maxY = Swift.max(maxY, p.y)
        }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    /// Point-in-path test honoring `usesEvenOddFillRule` (UIKit's
    /// `contains(_:)`; subpaths are implicitly closed, like filling).
    public func contains(_ point: CGPoint) -> Bool {
        var winding = 0
        var crossings = 0
        for (a, b) in flattenedSegments(closingSubpaths: true) {
            guard (a.y <= point.y && b.y > point.y) || (b.y <= point.y && a.y > point.y)
            else { continue }
            let t = (point.y - a.y) / (b.y - a.y)
            if a.x + t * (b.x - a.x) > point.x {
                crossings += 1
                winding += b.y > a.y ? 1 : -1
            }
        }
        return usesEvenOddFillRule ? (crossings % 2 != 0) : (winding != 0)
    }

    /// Flatten to polyline vertices (curve subdivision at a fixed 16 steps,
    /// which is well under half a pixel for control-point spans up to a few
    /// hundred points).
    func flattened() -> [CGPoint] {
        var out: [CGPoint] = []
        for (a, b) in flattenedSegments(closingSubpaths: false) {
            if out.isEmpty { out.append(a) }
            out.append(b)
        }
        if out.isEmpty, case .move(let p)? = cgPath.elements.first { out.append(p) }
        return out
    }

    func flattenedSegments(closingSubpaths: Bool) -> [(CGPoint, CGPoint)] {
        var segs: [(CGPoint, CGPoint)] = []
        var start = CGPoint.zero
        var cur = CGPoint.zero
        var open = false
        func emitCurve(_ f: (CGFloat) -> CGPoint) {
            let steps = 16
            var prev = cur
            for i in 1...steps {
                let p = f(CGFloat(i) / CGFloat(steps))
                segs.append((prev, p))
                prev = p
            }
            cur = prev
        }
        for e in cgPath.elements {
            switch e {
            case .move(let p):
                if closingSubpaths, open, cur != start { segs.append((cur, start)) }
                start = p; cur = p; open = true
            case .line(let p):
                segs.append((cur, p)); cur = p
            case .quad(let c, let p):
                let from = cur
                emitCurve { t in
                    let mt = 1 - t
                    return CGPoint(x: mt * mt * from.x + 2 * mt * t * c.x + t * t * p.x,
                                   y: mt * mt * from.y + 2 * mt * t * c.y + t * t * p.y)
                }
            case .cubic(let c1, let c2, let p):
                let from = cur
                emitCurve { t in
                    let mt = 1 - t
                    let x = mt * mt * mt * from.x + 3 * mt * mt * t * c1.x
                          + 3 * mt * t * t * c2.x + t * t * t * p.x
                    let y = mt * mt * mt * from.y + 3 * mt * mt * t * c1.y
                          + 3 * mt * t * t * c2.y + t * t * t * p.y
                    return CGPoint(x: x, y: y)
                }
            case .close:
                if cur != start { segs.append((cur, start)) }
                cur = start
                open = false
            }
        }
        if closingSubpaths, open, cur != start { segs.append((cur, start)) }
        return segs
    }

    // MARK: Drawing into the current context

    /// Fill with the current context's fill color (`UIColor.setFill()`).
    public func fill() {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.fill(cgPath, color: UIGraphicsCurrentFillColor(), evenOdd: usesEvenOddFillRule)
    }

    /// Fill with an explicit color (not UIKit API, but the honest spelling
    /// for code that does not want the implicit color state).
    public func fill(with color: UIColor) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.fill(cgPath, color: color.resolvedCGColor(with: UITraitCollection.current),
                 evenOdd: usesEvenOddFillRule)
    }

    /// Stroke with the current context's stroke color (`UIColor.setStroke()`),
    /// honoring `lineWidth` / `lineCapStyle` / `lineJoinStyle`.
    public func stroke() {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.stroke(cgPath, color: UIGraphicsCurrentStrokeColor(), lineWidth: lineWidth,
                   cap: canvasCap, join: canvasJoin, miterLimit: miterLimit)
    }

    public func stroke(with color: UIColor) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.stroke(cgPath, color: color.resolvedCGColor(with: UITraitCollection.current),
                   lineWidth: lineWidth, cap: canvasCap, join: canvasJoin,
                   miterLimit: miterLimit)
    }

    /// Intersect the current context's clip with this path.
    public func addClip() {
        UIGraphicsGetCurrentContext()?.clip(to: cgPath)
    }

    var canvasCap: CanvasLineCap {
        switch lineCapStyle {
        case .butt: return .butt
        case .round: return .round
        case .square: return .square
        }
    }
    var canvasJoin: CanvasLineJoin {
        switch lineJoinStyle {
        case .miter: return .miter
        case .round: return .round
        case .bevel: return .bevel
        }
    }

    // MARK: Shape builders

    static func oval(in rect: CGRect) -> Path {
        var p = Path()
        guard rect.width > 0, rect.height > 0 else { return p }
        let rx = rect.width / 2, ry = rect.height / 2
        let cx = rect.midX, cy = rect.midY
        let kx = kappa * rx, ky = kappa * ry
        p.move(to: CGPoint(x: rect.maxX, y: cy))
        p.addCurve(to: CGPoint(x: cx, y: rect.maxY),
                   control1: CGPoint(x: rect.maxX, y: cy + ky),
                   control2: CGPoint(x: cx + kx, y: rect.maxY))
        p.addCurve(to: CGPoint(x: rect.minX, y: cy),
                   control1: CGPoint(x: cx - kx, y: rect.maxY),
                   control2: CGPoint(x: rect.minX, y: cy + ky))
        p.addCurve(to: CGPoint(x: cx, y: rect.minY),
                   control1: CGPoint(x: rect.minX, y: cy - ky),
                   control2: CGPoint(x: cx - kx, y: rect.minY))
        p.addCurve(to: CGPoint(x: rect.maxX, y: cy),
                   control1: CGPoint(x: cx + kx, y: rect.minY),
                   control2: CGPoint(x: rect.maxX, y: cy - ky))
        p.close()
        return p
    }

    static func roundedRect(_ r: CGRect, corners: UIRectCorner, radii: CGSize) -> Path {
        let rx = Swift.max(0, Swift.min(radii.width, r.width / 2))
        let ry = Swift.max(0, Swift.min(radii.height, r.height / 2))
        if rx <= 0 || ry <= 0 || corners.isEmpty { return .rect(r) }
        let kx = kappa * rx, ky = kappa * ry
        let tl = corners.contains(.topLeft), tr = corners.contains(.topRight)
        let bl = corners.contains(.bottomLeft), br = corners.contains(.bottomRight)
        var p = Path()
        p.move(to: CGPoint(x: r.minX + (tl ? rx : 0), y: r.minY))
        // top edge -> top-right corner
        p.addLine(to: CGPoint(x: r.maxX - (tr ? rx : 0), y: r.minY))
        if tr {
            p.addCurve(to: CGPoint(x: r.maxX, y: r.minY + ry),
                       control1: CGPoint(x: r.maxX - rx + kx, y: r.minY),
                       control2: CGPoint(x: r.maxX, y: r.minY + ry - ky))
        }
        // right edge -> bottom-right corner
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - (br ? ry : 0)))
        if br {
            p.addCurve(to: CGPoint(x: r.maxX - rx, y: r.maxY),
                       control1: CGPoint(x: r.maxX, y: r.maxY - ry + ky),
                       control2: CGPoint(x: r.maxX - rx + kx, y: r.maxY))
        }
        // bottom edge -> bottom-left corner
        p.addLine(to: CGPoint(x: r.minX + (bl ? rx : 0), y: r.maxY))
        if bl {
            p.addCurve(to: CGPoint(x: r.minX, y: r.maxY - ry),
                       control1: CGPoint(x: r.minX + rx - kx, y: r.maxY),
                       control2: CGPoint(x: r.minX, y: r.maxY - ry + ky))
        }
        // left edge -> top-left corner
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + (tl ? ry : 0)))
        if tl {
            p.addCurve(to: CGPoint(x: r.minX + rx, y: r.minY),
                       control1: CGPoint(x: r.minX, y: r.minY + ry - ky),
                       control2: CGPoint(x: r.minX + rx - kx, y: r.minY))
        }
        p.close()
        return p
    }
}

// MARK: - Local transcendentals
//
// OpenUIKit cannot import Foundation/Glibc; OpenCoreGraphics keeps its own
// series-based helpers internal, so the drawing module carries the two it
// needs (same argument-reduced Taylor construction, ~1e-15 over the reduced
// range).

@inlinable func _bpSin(_ x: CGFloat) -> CGFloat {
    var x = x.truncatingRemainder(dividingBy: 2 * .pi)
    if x > .pi { x -= 2 * .pi }
    if x < -.pi { x += 2 * .pi }
    var term = x, sum = x
    for k in 1...12 {
        let kk = CGFloat(2 * k) * CGFloat(2 * k + 1)
        term *= -x * x / kk
        sum += term
    }
    return sum
}
@inlinable func _bpCos(_ x: CGFloat) -> CGFloat { _bpSin(x + .pi / 2) }
@inlinable func _bpTan(_ x: CGFloat) -> CGFloat {
    let c = _bpCos(x)
    return c == 0 ? 0 : _bpSin(x) / c
}
