// Core geometry types.
//
// M15 (docs/APP_COMPAT.md "Foundation coexistence"): where Foundation already
// declares the type, we no longer declare our own -- we alias to Foundation's,
// so there is exactly ONE `CGRect` (etc.) in any program that imports both
// OpenUIKit and Foundation. The collision was never about missing API; it was
// about duplicate NAMES. See docs/PORTABILITY.md.
//
//   * Linux corelibs-Foundation declares CGFloat/CGPoint/CGSize/CGVector/
//     CGRect *and* the whole geometry API (minX, insetBy, integral, ...).
//   * Darwin's Foundation re-exports the CoreGraphics structs, but the Swift
//     members live in the CoreGraphics overlay, hence the `import CoreGraphics`
//     below. It is a plain (non-`@_exported`) import: it makes the overlay's
//     extension members visible, and deliberately does NOT re-export
//     CoreGraphics' own type names, so OpenCoreGraphics' CGColor / CGLineCap /
//     CGAffineTransform stay ours on both platforms.
//
// `CGAffineTransform` is NOT aliased: Foundation has none (measured), so there
// is no collision to remove, and keeping one implementation for both platforms
// is what keeps the Linux render byte-identical.

#if canImport(Foundation)
import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

public typealias CGFloat = Foundation.CGFloat
public typealias CGPoint = Foundation.CGPoint
public typealias CGSize = Foundation.CGSize
public typealias CGVector = Foundation.CGVector
public typealias CGRect = Foundation.CGRect

#else

// Foundation-less build (embedded / freestanding). Keep the original structs;
// they are the reference semantics the Foundation types are checked against by
// the oracle suite.
public typealias CGFloat = Double

public struct CGPoint: Equatable, Hashable, Sendable {
    public var x: CGFloat
    public var y: CGFloat
    public init(x: CGFloat, y: CGFloat) { self.x = x; self.y = y }
    public init() { self.init(x: 0, y: 0) }
    public static let zero = CGPoint()
}

public struct CGSize: Equatable, Hashable, Sendable {
    public var width: CGFloat
    public var height: CGFloat
    public init(width: CGFloat, height: CGFloat) { self.width = width; self.height = height }
    public init() { self.init(width: 0, height: 0) }
    public static let zero = CGSize()
}

public struct CGVector: Equatable, Sendable {
    public var dx: CGFloat
    public var dy: CGFloat
    public init(dx: CGFloat, dy: CGFloat) { self.dx = dx; self.dy = dy }
    public static let zero = CGVector(dx: 0, dy: 0)
}

public struct CGRect: Equatable, Hashable, Sendable {
    public var origin: CGPoint
    public var size: CGSize
    public init(origin: CGPoint, size: CGSize) { self.origin = origin; self.size = size }
    public init(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        self.init(origin: CGPoint(x: x, y: y), size: CGSize(width: width, height: height))
    }
    public init() { self.init(origin: .zero, size: .zero) }

    public static let zero = CGRect()
    public static let null = CGRect(x: .infinity, y: .infinity, width: 0, height: 0)

    public var isNull: Bool { origin.x == .infinity || origin.y == .infinity }
    public var isEmpty: Bool { isNull || size.width == 0 || size.height == 0 }

    // Standardized accessors (handle negative width/height like CG does).
    public var standardized: CGRect {
        if isNull { return self }
        var r = self
        if r.size.width < 0 { r.origin.x += r.size.width; r.size.width = -r.size.width }
        if r.size.height < 0 { r.origin.y += r.size.height; r.size.height = -r.size.height }
        return r
    }
    public var minX: CGFloat { let s = standardized; return s.origin.x }
    public var minY: CGFloat { let s = standardized; return s.origin.y }
    public var maxX: CGFloat { let s = standardized; return s.origin.x + s.size.width }
    public var maxY: CGFloat { let s = standardized; return s.origin.y + s.size.height }
    public var midX: CGFloat { (minX + maxX) / 2 }
    public var midY: CGFloat { (minY + maxY) / 2 }
    public var width: CGFloat { standardized.size.width }
    public var height: CGFloat { standardized.size.height }

    public func contains(_ p: CGPoint) -> Bool {
        !isEmpty && p.x >= minX && p.x < maxX && p.y >= minY && p.y < maxY
    }
    public func contains(_ r: CGRect) -> Bool {
        if r.isEmpty { return true }
        return r.minX >= minX && r.maxX <= maxX && r.minY >= minY && r.maxY <= maxY
    }
    public func intersects(_ r: CGRect) -> Bool { !intersection(r).isNull }

    public func intersection(_ r: CGRect) -> CGRect {
        if isNull || r.isNull { return .null }
        let x0 = Swift.max(minX, r.minX), x1 = Swift.min(maxX, r.maxX)
        let y0 = Swift.max(minY, r.minY), y1 = Swift.min(maxY, r.maxY)
        if x0 > x1 || y0 > y1 { return .null }
        return CGRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0)
    }
    public func union(_ r: CGRect) -> CGRect {
        if isNull { return r.standardized }
        if r.isNull { return standardized }
        let x0 = Swift.min(minX, r.minX), x1 = Swift.max(maxX, r.maxX)
        let y0 = Swift.min(minY, r.minY), y1 = Swift.max(maxY, r.maxY)
        return CGRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0)
    }
    public func insetBy(dx: CGFloat, dy: CGFloat) -> CGRect {
        let s = standardized
        let r = CGRect(x: s.origin.x + dx, y: s.origin.y + dy,
                       width: s.size.width - 2 * dx, height: s.size.height - 2 * dy)
        return (r.size.width < 0 || r.size.height < 0) ? .null : r
    }
    public func offsetBy(dx: CGFloat, dy: CGFloat) -> CGRect {
        var s = standardized
        s.origin.x += dx; s.origin.y += dy
        return s
    }
    public var integral: CGRect {
        let s = standardized
        if s.isNull { return s }
        let x0 = s.minX.rounded(.down), y0 = s.minY.rounded(.down)
        let x1 = s.maxX.rounded(.up), y1 = s.maxY.rounded(.up)
        return CGRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0)
    }
}

#endif

// MARK: - The geometry Foundation does not have

// `applying(_:)` takes OpenCoreGraphics' CGAffineTransform. On Darwin the
// CoreGraphics overlay also declares `applying(_:)` taking *its* transform;
// the two are distinct types, so these are ordinary overloads, not a conflict.
extension CGPoint {
    public func applying(_ t: CGAffineTransform) -> CGPoint {
        CGPoint(x: t.a * x + t.c * y + t.tx, y: t.b * x + t.d * y + t.ty)
    }
}

extension CGRect {
    /// Bounding box of the four transformed corners (CGRectApplyAffineTransform semantics).
    public func applying(_ t: CGAffineTransform) -> CGRect {
        if isNull { return self }
        let s = standardized
        let p1 = CGPoint(x: s.minX, y: s.minY).applying(t)
        let p2 = CGPoint(x: s.maxX, y: s.minY).applying(t)
        let p3 = CGPoint(x: s.minX, y: s.maxY).applying(t)
        let p4 = CGPoint(x: s.maxX, y: s.maxY).applying(t)
        let x0 = Swift.min(p1.x, p2.x, p3.x, p4.x), x1 = Swift.max(p1.x, p2.x, p3.x, p4.x)
        let y0 = Swift.min(p1.y, p2.y, p3.y, p4.y), y1 = Swift.max(p1.y, p2.y, p3.y, p4.y)
        return CGRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0)
    }
}

// MARK: - CGAffineTransform (ours on every platform: Foundation has none)

public struct CGAffineTransform: Equatable, Sendable {
    public var a: CGFloat, b: CGFloat, c: CGFloat, d: CGFloat, tx: CGFloat, ty: CGFloat
    public init(a: CGFloat, b: CGFloat, c: CGFloat, d: CGFloat, tx: CGFloat, ty: CGFloat) {
        self.a = a; self.b = b; self.c = c; self.d = d; self.tx = tx; self.ty = ty
    }
    public static let identity = CGAffineTransform(a: 1, b: 0, c: 0, d: 1, tx: 0, ty: 0)
    public var isIdentity: Bool { self == .identity }

    public init(translationX tx: CGFloat, y ty: CGFloat) { self.init(a: 1, b: 0, c: 0, d: 1, tx: tx, ty: ty) }
    public init(scaleX sx: CGFloat, y sy: CGFloat) { self.init(a: sx, b: 0, c: 0, d: sy, tx: 0, ty: 0) }
    public init(rotationAngle angle: CGFloat) {
        let cs = _cos(angle), sn = _sin(angle)
        self.init(a: cs, b: sn, c: -sn, d: cs, tx: 0, ty: 0)
    }

    /// self * t2 in CG's row-vector convention: point.applying(r) == point.applying(self).applying(t2)...
    /// CG semantics: concatenating(t2) returns t2 ∘ self, i.e. p' = p * self * t2.
    public func concatenating(_ t2: CGAffineTransform) -> CGAffineTransform {
        CGAffineTransform(
            a: a * t2.a + b * t2.c,
            b: a * t2.b + b * t2.d,
            c: c * t2.a + d * t2.c,
            d: c * t2.b + d * t2.d,
            tx: tx * t2.a + ty * t2.c + t2.tx,
            ty: tx * t2.b + ty * t2.d + t2.ty)
    }
    public func translatedBy(x: CGFloat, y: CGFloat) -> CGAffineTransform {
        CGAffineTransform(translationX: x, y: y).concatenating(self)
    }
    public func scaledBy(x: CGFloat, y: CGFloat) -> CGAffineTransform {
        CGAffineTransform(scaleX: x, y: y).concatenating(self)
    }
    public func rotated(by angle: CGFloat) -> CGAffineTransform {
        CGAffineTransform(rotationAngle: angle).concatenating(self)
    }
    public func inverted() -> CGAffineTransform {
        let det = a * d - b * c
        if det == 0 { return self }
        let ia = d / det, ib = -b / det, ic = -c / det, id = a / det
        return CGAffineTransform(a: ia, b: ib, c: ic, d: id,
                                 tx: -(tx * ia + ty * ic), ty: -(tx * ib + ty * id))
    }
}

// Minimal transcendental helpers so we do not need libm here, and -- more to
// the point -- so both platforms use the SAME series and the Linux render stays
// byte-identical. Taylor/argument-reduction based; accurate to ~1e-15 over
// reduced range.
@inlinable func _sin(_ x: CGFloat) -> CGFloat {
    var x = x.truncatingRemainder(dividingBy: 2 * .pi)
    if x > .pi { x -= 2 * .pi }
    if x < -.pi { x += 2 * .pi }
    // Taylor series around 0 (|x| <= pi); 13 terms is plenty for Double.
    var term = x, sum = x
    for k in 1...12 {
        let kk = CGFloat(2 * k) * CGFloat(2 * k + 1)
        term *= -x * x / kk
        sum += term
    }
    return sum
}
@inlinable func _cos(_ x: CGFloat) -> CGFloat { _sin(x + .pi / 2) }
