// Software rasterizer implementation for Canvas.
// OWNED BY: rasterizer module.
//
// Analytic-coverage scanline rasterizer (signed-area accumulation, the
// "cell" technique used by font-rs / stb_truetype's newer rasterizer):
// every flattened line segment deposits exact per-pixel trapezoid area
// deltas into an accumulation grid; a horizontal prefix sum then yields
// the exact analytic coverage of the (piecewise-linear) path per pixel.
//
// Properties:
// - Axis-aligned rects at any subpixel position get EXACT coverage
//   (rect starting at x=10.25 -> edge pixel coverage 0.75, exactly).
// - Cost is O(segments x pixels_touched_by_segments + bbox_area):
//   no O(pixels x segments) loops anywhere.
// - Beziers are flattened adaptively to ~0.05 device px tolerance.
// - Non-zero winding by default; even-odd via winding folding (exact for
//   non-overlapping subpaths such as border rings).
// - Blending is source-over on straight-alpha gamma-encoded sRGB bytes.
//
// See Canvas.swift for the frozen API contract.

// MARK: - Flattening

/// Flattening tolerance in device pixels.
private let _flattenTolerance: CGFloat = 0.05

struct _Subpath {
    var points: [CGPoint] = []
    var closed = false
}

/// Flatten a path through `transform` into polylines in device space.
/// Curves are transformed control-point-wise (affine maps preserve beziers)
/// and subdivided uniformly with a Wang-style bound so the maximum chord
/// deviation is below `_flattenTolerance` device pixels.
func _flattenSubpaths(_ path: Path, transform t: CGAffineTransform) -> [_Subpath] {
    var subpaths: [_Subpath] = []
    var current = _Subpath()
    var cur = CGPoint.zero

    @inline(__always) func flush() {
        if current.points.count > 1 { subpaths.append(current) }
        current = _Subpath()
    }
    @inline(__always) func begin(at p: CGPoint) {
        flush()
        current.points.append(p)
        cur = p
    }
    @inline(__always) func lineTo(_ p: CGPoint) {
        if current.points.isEmpty { current.points.append(cur) }
        current.points.append(p)
        cur = p
    }

    for e in path.elements {
        switch e {
        case .move(let p):
            begin(at: p.applying(t))
        case .line(let p):
            lineTo(p.applying(t))
        case .quad(let c, let p):
            let p0 = cur, p1 = c.applying(t), p2 = p.applying(t)
            // Max second derivative of a quad is 2|p0 - 2c + p2|; linear
            // interpolation error over 1/n parameter steps <= d/(4n^2).
            let dx = p0.x - 2 * p1.x + p2.x, dy = p0.y - 2 * p1.y + p2.y
            let d = (dx * dx + dy * dy).squareRoot()
            let n = Swift.max(1, Swift.min(256, Int((d / (4 * _flattenTolerance)).squareRoot().rounded(.up))))
            for i in 1...n {
                let s = CGFloat(i) / CGFloat(n), m = 1 - s
                lineTo(CGPoint(x: m * m * p0.x + 2 * m * s * p1.x + s * s * p2.x,
                               y: m * m * p0.y + 2 * m * s * p1.y + s * s * p2.y))
            }
        case .cubic(let c1, let c2, let p):
            let p0 = cur, p1 = c1.applying(t), p2 = c2.applying(t), p3 = p.applying(t)
            // |B''| <= 6 * max(|p0-2p1+p2|, |p1-2p2+p3|); error <= 3m/(4n^2).
            let ax = p0.x - 2 * p1.x + p2.x, ay = p0.y - 2 * p1.y + p2.y
            let bx = p1.x - 2 * p2.x + p3.x, by = p1.y - 2 * p2.y + p3.y
            let m2 = Swift.max(ax * ax + ay * ay, bx * bx + by * by).squareRoot()
            let n = Swift.max(1, Swift.min(256, Int((3 * m2 / (4 * _flattenTolerance)).squareRoot().rounded(.up))))
            for i in 1...n {
                let s = CGFloat(i) / CGFloat(n), m = 1 - s
                let x = m * m * m * p0.x + 3 * m * m * s * p1.x + 3 * m * s * s * p2.x + s * s * s * p3.x
                let y = m * m * m * p0.y + 3 * m * m * s * p1.y + 3 * m * s * s * p2.y + s * s * s * p3.y
                lineTo(CGPoint(x: x, y: y))
            }
        case .close:
            if let first = current.points.first {
                if cur != first { current.points.append(first) }
                current.closed = true
                subpaths.append(current)
                // A new segment after close continues from the subpath start.
                current = _Subpath()
                cur = first
            }
        }
    }
    flush()
    return subpaths
}

// MARK: - Coverage accumulation

/// Signed-area accumulation grid over an integer pixel window
/// [originX, originX+width) x [originY, originY+height) in device space.
///
/// `add` deposits the per-pixel area deltas of one line segment; after all
/// segments are added, `enumerateRows` prefix-sums each row and reports
/// analytic coverage in [0, 1] per pixel.
struct _CoverageAccumulator {
    let originX: Int
    let originY: Int
    let width: Int   // emitted pixel columns
    let height: Int  // emitted pixel rows
    private let stride: Int  // width + 2: accumulation spills one column right
    private var accum: [CGFloat]

    init?(clippingBoxMinX minX: CGFloat, minY: CGFloat, maxX: CGFloat, maxY: CGFloat,
          limitWidth: Int, limitHeight: Int) {
        let x0 = Swift.max(0, Int(minX.rounded(.down)))
        let y0 = Swift.max(0, Int(minY.rounded(.down)))
        let x1 = Swift.min(limitWidth, Int(maxX.rounded(.up)))
        let y1 = Swift.min(limitHeight, Int(maxY.rounded(.up)))
        guard x1 > x0, y1 > y0 else { return nil }
        originX = x0; originY = y0
        width = x1 - x0; height = y1 - y0
        stride = width + 2
        accum = Array<CGFloat>(repeating: 0, count: stride * height)
    }

    /// Add one device-space line segment. Geometry outside the window is
    /// clamped horizontally (preserving winding for visible pixels) and
    /// clipped vertically (rows outside the window are irrelevant).
    mutating func add(from a: CGPoint, to b: CGPoint) {
        var p0 = CGPoint(x: a.x - CGFloat(originX), y: a.y - CGFloat(originY))
        var p1 = CGPoint(x: b.x - CGFloat(originX), y: b.y - CGFloat(originY))
        if p0.y == p1.y { return }
        var dir: CGFloat = 1
        if p0.y > p1.y { swap(&p0, &p1); dir = -1 }
        let yTop = Swift.max(0, p0.y), yBot = Swift.min(CGFloat(height), p1.y)
        guard yTop < yBot else { return }
        let dxdy = (p1.x - p0.x) / (p1.y - p0.y)
        var x = p0.x + (yTop - p0.y) * dxdy
        let clampHi = CGFloat(width)
        var y = Int(yTop)  // floor; yTop >= 0
        let yEnd = Swift.min(height, Int(yBot.rounded(.up)))

        accum.withUnsafeMutableBufferPointer { acc in
            while y < yEnd {
                let rowTop = Swift.max(CGFloat(y), yTop)
                let rowBot = Swift.min(CGFloat(y + 1), yBot)
                let dy = rowBot - rowTop
                if dy <= 0 { y += 1; continue }
                let xNext = x + dxdy * dy
                var x0 = Swift.min(x, xNext), x1 = Swift.max(x, xNext)
                x = xNext
                // Horizontal clamp into [0, width].
                x0 = Swift.min(Swift.max(x0, 0), clampHi)
                x1 = Swift.min(Swift.max(x1, 0), clampHi)
                let d = dy * dir
                let base = y * stride
                let x0floor = x0.rounded(.down)
                let x0i = Int(x0floor)
                let x1ceil = x1.rounded(.up)
                let x1i = Int(x1ceil)
                if x1i <= x0i + 1 {
                    // Span within one pixel column: split by midpoint.
                    let xmf = 0.5 * (x0 + x1) - x0floor
                    acc[base + x0i] += d * (1 - xmf)
                    acc[base + x0i + 1] += d * xmf
                } else {
                    // Span crosses columns: exact trapezoid areas per column.
                    let s = 1 / (x1 - x0)
                    let x0f = x0 - x0floor
                    let a0 = 0.5 * s * (1 - x0f) * (1 - x0f)
                    let x1f = x1 - x1ceil + 1
                    let am = 0.5 * s * x1f * x1f
                    acc[base + x0i] += d * a0
                    if x1i == x0i + 2 {
                        acc[base + x0i + 1] += d * (1 - a0 - am)
                    } else {
                        let a1 = s * (1.5 - x0f)
                        acc[base + x0i + 1] += d * (a1 - a0)
                        let ds = d * s
                        for xi in (x0i + 2)..<(x1i - 1) { acc[base + xi] += ds }
                        let a2 = a1 + CGFloat(x1i - x0i - 3) * s
                        acc[base + x1i - 1] += d * (1 - a2 - am)
                    }
                    acc[base + x1i] += d * am
                }
                y += 1
            }
        }
    }

    mutating func add(subpaths: [_Subpath], implicitClose: Bool) {
        for sp in subpaths {
            let pts = sp.points
            guard pts.count > 1 else { continue }
            for i in 1..<pts.count { add(from: pts[i - 1], to: pts[i]) }
            if implicitClose && !sp.closed && pts.first! != pts.last! {
                add(from: pts.last!, to: pts.first!)
            }
        }
    }

    /// Prefix-sum each row and hand a coverage row (length `width`,
    /// values in [0, 1]) to `body`. Row index is window-relative.
    func enumerateRows(evenOdd: Bool, _ body: (_ row: Int, _ coverage: UnsafeBufferPointer<CGFloat>) -> Void) {
        var cov = Array<CGFloat>(repeating: 0, count: width)
        accum.withUnsafeBufferPointer { acc in
            cov.withUnsafeMutableBufferPointer { out in
                for y in 0..<height {
                    var sum: CGFloat = 0
                    let base = y * stride
                    if evenOdd {
                        for xi in 0..<width {
                            sum += acc[base + xi]
                            var c = sum.magnitude.truncatingRemainder(dividingBy: 2)
                            if c > 1 { c = 2 - c }
                            out[xi] = c
                        }
                    } else {
                        for xi in 0..<width {
                            sum += acc[base + xi]
                            out[xi] = Swift.min(sum.magnitude, 1)
                        }
                    }
                    body(y, UnsafeBufferPointer(rebasing: out[0..<width]))
                }
            }
        }
    }
}

// MARK: - Canvas implementation

extension Canvas {
    func _save() {
        stateStack.append(state)
    }
    func _restore() {
        if let s = stateStack.popLast() { state = s }
    }
    func _concatenate(_ t: CGAffineTransform) {
        state.ctm = t.concatenating(state.ctm)
    }

    // MARK: Fill

    func _fill(_ path: Path, _ color: CGColor, _ evenOdd: Bool) {
        guard color.alpha > 0 else { return }
        let subpaths = _flattenSubpaths(path, transform: state.ctm)
        _fillDeviceSubpaths(subpaths, color: color, evenOdd: evenOdd)
    }

    /// Fill already-flattened device-space subpaths (implicitly closed).
    func _fillDeviceSubpaths(_ subpaths: [_Subpath], color: CGColor, evenOdd: Bool) {
        guard let box = _bounds(of: subpaths) else { return }
        guard var acc = _CoverageAccumulator(clippingBoxMinX: box.0, minY: box.1,
                                             maxX: box.2, maxY: box.3,
                                             limitWidth: bitmap.width,
                                             limitHeight: bitmap.height) else { return }
        acc.add(subpaths: subpaths, implicitClose: true)

        let ox = acc.originX, oy = acc.originY, w = acc.width
        let bw = bitmap.width
        let clip = state.clipMask
        acc.enumerateRows(evenOdd: evenOdd) { row, cov in
            let by = oy + row
            let rowBase = by * bw
            for xi in 0..<w {
                var c = cov[xi]
                if c < 0.001 { continue }
                let px = ox + xi
                if let m = clip {
                    let mv = m[rowBase + px]
                    if mv == 0 { continue }
                    c *= CGFloat(mv) / 255
                }
                _blendPixel(at: (rowBase + px) * 4,
                            r: color.red, g: color.green, b: color.blue,
                            a: color.alpha * c)
            }
        }
    }

    private func _bounds(of subpaths: [_Subpath]) -> (CGFloat, CGFloat, CGFloat, CGFloat)? {
        var minX = CGFloat.infinity, minY = CGFloat.infinity
        var maxX = -CGFloat.infinity, maxY = -CGFloat.infinity
        for sp in subpaths {
            for p in sp.points {
                if p.x < minX { minX = p.x }
                if p.x > maxX { maxX = p.x }
                if p.y < minY { minY = p.y }
                if p.y > maxY { maxY = p.y }
            }
        }
        guard minX <= maxX, minY <= maxY else { return nil }
        return (minX, minY, maxX, maxY)
    }

    // MARK: Clip

    /// Rasterize a path into a standalone full-surface coverage mask. Unlike
    /// `_clip`, this intentionally does not multiply the current clip: a
    /// masked transparency layer applies this coverage to its final group,
    /// while the inherited graphics clip still governs the individual draws.
    func _coverageMask(_ path: Path, alpha: CGFloat = 1) -> [UInt8] {
        let subpaths = _flattenSubpaths(path, transform: state.ctm)
        let bw = bitmap.width, bh = bitmap.height
        // Coverage of the clip path, full-bitmap, zero outside its bbox.
        var newMask = [UInt8](repeating: 0, count: bw * bh)
        if let box = _bounds(of: subpaths),
           var acc = _CoverageAccumulator(clippingBoxMinX: box.0, minY: box.1,
                                          maxX: box.2, maxY: box.3,
                                          limitWidth: bw, limitHeight: bh) {
            acc.add(subpaths: subpaths, implicitClose: true)
            let ox = acc.originX, oy = acc.originY, w = acc.width
            newMask.withUnsafeMutableBufferPointer { mask in
                acc.enumerateRows(evenOdd: false) { row, cov in
                    let rowBase = (oy + row) * bw + ox
                    for xi in 0..<w {
                        mask[rowBase + xi] = UInt8(
                            (cov[xi] * Swift.min(Swift.max(alpha, 0), 1) * 255)
                                .rounded())
                    }
                }
            }
        }
        return newMask
    }

    func _clip(_ path: Path) {
        var newMask = _coverageMask(path)
        if let old = state.clipMask {
            for i in 0..<newMask.count {
                let o = old[i]
                if o == 255 { continue }
                let n = newMask[i]
                newMask[i] = n == 0 ? 0 : UInt8((Int(n) * Int(o) + 127) / 255)
            }
        }
        state.clipMask = newMask
    }

    // MARK: Transparency layers

    func _beginLayer(_ alpha: CGFloat, mask: [UInt8]? = nil) {
        layerStack.append(TransparencyLayer(savedPixels: bitmap.pixels, alpha: alpha,
                                            savedStateStackDepth: stateStack.count,
                                            mask: mask))
        // Fresh transparent buffer for the layer's content.
        bitmap.pixels.withUnsafeMutableBufferPointer { buf in
            for i in 0..<buf.count { buf[i] = 0 }
        }
    }

    func _endLayer() {
        guard let layer = layerStack.popLast() else { return }
        // Clean up any unbalanced saves made inside the layer.
        if stateStack.count > layer.savedStateStackDepth {
            state = stateStack[layer.savedStateStackDepth]
            stateStack.removeLast(stateStack.count - layer.savedStateStackDepth)
        }
        let content = bitmap.pixels
        bitmap.pixels = layer.savedPixels
        // Composite content over saved, scaled by layer alpha.
        let n = bitmap.width * bitmap.height
        let la = layer.alpha
        for i in 0..<n {
            let o = i * 4
            let ca = content[o + 3]
            if ca == 0 { continue }
            var sa = CGFloat(ca) / 255 * la
            if let mask = layer.mask {
                let coverage = mask[i]
                if coverage == 0 { continue }
                sa *= CGFloat(coverage) / 255
            }
            if sa <= 0 { continue }
            _blendPixel(at: o,
                        r: CGFloat(content[o]) / 255,
                        g: CGFloat(content[o + 1]) / 255,
                        b: CGFloat(content[o + 2]) / 255,
                        a: sa)
        }
    }

    // MARK: Stroke

    func _stroke(_ path: Path, _ color: CGColor, _ lineWidth: CGFloat) {
        guard color.alpha > 0, lineWidth > 0 else { return }
        let t = state.ctm
        // Uniform-scale approximation of the CTM for the stroke width.
        let det = (t.a * t.d - t.b * t.c).magnitude
        let hw = Swift.max(1e-6, lineWidth * det.squareRoot() / 2)
        let subpaths = _flattenSubpaths(path, transform: t)

        // Build one polygon soup: a quad per segment (butt ends) plus a
        // 16-gon at each interior joint, all with the SAME chirality so a
        // single non-zero (|winding| clamped) pass unions them without
        // double-blending overlaps.
        var soup: [_Subpath] = []
        var gon: [CGPoint] = []  // clockwise unit 16-gon (screen coords)
        for k in 0..<16 {
            let ang = -2 * CGFloat.pi * CGFloat(k) / 16
            gon.append(CGPoint(x: _cos(ang), y: _sin(ang)))
        }
        for sp in subpaths {
            var pts = sp.points
            guard pts.count > 1 else { continue }
            if sp.closed && pts.first! != pts.last! { pts.append(pts.first!) }
            for i in 1..<pts.count {
                let a = pts[i - 1], b = pts[i]
                let dx = b.x - a.x, dy = b.y - a.y
                let len = (dx * dx + dy * dy).squareRoot()
                guard len > 0 else { continue }
                let nx = -dy / len * hw, ny = dx / len * hw
                var quad = _Subpath()
                quad.points = [CGPoint(x: a.x + nx, y: a.y + ny),
                               CGPoint(x: b.x + nx, y: b.y + ny),
                               CGPoint(x: b.x - nx, y: b.y - ny),
                               CGPoint(x: a.x - nx, y: a.y - ny)]
                quad.closed = false  // implicit close in fill
                soup.append(quad)
            }
            // Joints: every interior vertex; for closed subpaths also the seam.
            var jointRange = Array(1..<(pts.count - 1))
            if sp.closed { jointRange.append(0) }
            for j in jointRange {
                let v = pts[j]
                var poly = _Subpath()
                poly.points = gon.map { CGPoint(x: v.x + $0.x * hw, y: v.y + $0.y * hw) }
                soup.append(poly)
            }
        }
        _fillDeviceSubpaths(soup, color: color, evenOdd: false)
    }

    // MARK: Images

    func _drawImage(_ image: Bitmap, _ rect: CGRect, _ interpolate: Bool) {
        guard image.width > 0, image.height > 0, rect.width > 0, rect.height > 0 else { return }
        let t = state.ctm
        let dev = rect.applying(t)
        let x0 = Swift.max(0, Int(dev.minX.rounded(.down)))
        let x1 = Swift.min(bitmap.width, Int(dev.maxX.rounded(.up)))
        let y0 = Swift.max(0, Int(dev.minY.rounded(.down)))
        let y1 = Swift.min(bitmap.height, Int(dev.maxY.rounded(.up)))
        guard x0 < x1, y0 < y1 else { return }
        let inv = t.inverted()
        // Axis-aligned CTMs get exact analytic edge coverage; rotated ones
        // draw hard edges (matches UIKit: transformed layers do not AA).
        let axisAligned = t.b.magnitude < 1e-9 && t.c.magnitude < 1e-9

        var covX = Array<CGFloat>(repeating: 1, count: x1 - x0)
        if axisAligned {
            for x in x0..<x1 {
                covX[x - x0] = Swift.min(CGFloat(x + 1), dev.maxX) - Swift.max(CGFloat(x), dev.minX)
            }
        }
        let iw = image.width, ih = image.height
        let srcW = CGFloat(iw), srcH = CGFloat(ih)
        let bw = bitmap.width
        let clip = state.clipMask

        image.pixels.withUnsafeBufferPointer { src in
            @inline(__always) func premulSample(_ sx: Int, _ sy: Int) -> (CGFloat, CGFloat, CGFloat, CGFloat) {
                let o = (sy * iw + sx) * 4
                let a = CGFloat(src[o + 3]) / 255
                return (CGFloat(src[o]) / 255 * a, CGFloat(src[o + 1]) / 255 * a,
                        CGFloat(src[o + 2]) / 255 * a, a)
            }
            for y in y0..<y1 {
                let covY: CGFloat = axisAligned
                    ? Swift.min(CGFloat(y + 1), dev.maxY) - Swift.max(CGFloat(y), dev.minY)
                    : 1
                if covY <= 0 { continue }
                for x in x0..<x1 {
                    var cov = covY * (axisAligned ? covX[x - x0] : 1)
                    if cov <= 0.001 { continue }
                    if cov > 1 { cov = 1 }
                    let user = CGPoint(x: CGFloat(x) + 0.5, y: CGFloat(y) + 0.5).applying(inv)
                    var u = (user.x - rect.minX) / rect.width
                    var v = (user.y - rect.minY) / rect.height
                    if !axisAligned {
                        // Hard-edged inclusion test for rotated draws.
                        if u < 0 || u >= 1 || v < 0 || v >= 1 { continue }
                    }
                    u = Swift.min(Swift.max(u, 0), 1)
                    v = Swift.min(Swift.max(v, 0), 1)

                    var pr: CGFloat, pg: CGFloat, pb: CGFloat, pa: CGFloat
                    if interpolate {
                        // Bilinear on premultiplied values, edge-clamped,
                        // source pixel centers at integer+0.5 (CG default).
                        let fx = u * srcW - 0.5
                        let fy = v * srcH - 0.5
                        let ix = Int(fx.rounded(.down)), iy = Int(fy.rounded(.down))
                        let tx = fx - CGFloat(ix), ty = fy - CGFloat(iy)
                        let sx0 = Swift.min(Swift.max(ix, 0), iw - 1)
                        let sx1 = Swift.min(Swift.max(ix + 1, 0), iw - 1)
                        let sy0 = Swift.min(Swift.max(iy, 0), ih - 1)
                        let sy1 = Swift.min(Swift.max(iy + 1, 0), ih - 1)
                        let s00 = premulSample(sx0, sy0), s10 = premulSample(sx1, sy0)
                        let s01 = premulSample(sx0, sy1), s11 = premulSample(sx1, sy1)
                        let w00 = (1 - tx) * (1 - ty), w10 = tx * (1 - ty)
                        let w01 = (1 - tx) * ty, w11 = tx * ty
                        pr = s00.0 * w00 + s10.0 * w10 + s01.0 * w01 + s11.0 * w11
                        pg = s00.1 * w00 + s10.1 * w10 + s01.1 * w01 + s11.1 * w11
                        pb = s00.2 * w00 + s10.2 * w10 + s01.2 * w01 + s11.2 * w11
                        pa = s00.3 * w00 + s10.3 * w10 + s01.3 * w01 + s11.3 * w11
                    } else {
                        let sx = Swift.min(iw - 1, Swift.max(0, Int((u * srcW).rounded(.down))))
                        let sy = Swift.min(ih - 1, Swift.max(0, Int((v * srcH).rounded(.down))))
                        (pr, pg, pb, pa) = premulSample(sx, sy)
                    }
                    var a = pa * cov
                    if let m = clip {
                        let mv = m[y * bw + x]
                        if mv == 0 { continue }
                        a *= CGFloat(mv) / 255
                    }
                    if a <= 0 { continue }
                    // Un-premultiply for the straight-alpha blend.
                    let invPa = pa > 0 ? 1 / pa : 0
                    _blendPixel(at: (y * bw + x) * 4,
                                r: pr * invPa, g: pg * invPa, b: pb * invPa, a: a)
                }
            }
        }
    }

    // MARK: Glyph masks

    func _drawMask(_ mask: [UInt8], _ w: Int, _ h: Int, _ ox: Int, _ oy: Int, _ color: CGColor) {
        guard color.alpha > 0, w > 0, h > 0 else { return }
        let bw = bitmap.width
        let clip = state.clipMask
        let my0 = Swift.max(0, -oy), my1 = Swift.min(h, bitmap.height - oy)
        let mx0 = Swift.max(0, -ox), mx1 = Swift.min(w, bw - ox)
        guard my0 < my1, mx0 < mx1 else { return }
        for my in my0..<my1 {
            let y = oy + my
            let maskRow = my * w
            let rowBase = y * bw
            for mx in mx0..<mx1 {
                let mv = mask[maskRow + mx]
                if mv == 0 { continue }
                let x = ox + mx
                var a = CGFloat(mv) / 255 * color.alpha
                if let m = clip {
                    let cv = m[rowBase + x]
                    if cv == 0 { continue }
                    a *= CGFloat(cv) / 255
                }
                if a <= 0 { continue }
                _blendPixel(at: (rowBase + x) * 4,
                            r: color.red, g: color.green, b: color.blue, a: a)
            }
        }
    }

    // MARK: Blending

    /// Source-over blend of straight-alpha color onto pixel at byte offset.
    /// Blending happens on gamma-encoded sRGB values (CG semantics for
    /// sRGB surfaces).
    @inline(__always)
    func _blendPixel(at o: Int, r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        if a >= 1 {
            bitmap.pixels[o] = UInt8((r * 255).rounded().clamped(0, 255))
            bitmap.pixels[o + 1] = UInt8((g * 255).rounded().clamped(0, 255))
            bitmap.pixels[o + 2] = UInt8((b * 255).rounded().clamped(0, 255))
            bitmap.pixels[o + 3] = 255
            return
        }
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
        let outR = (r * a + dr * da * (1 - a)) / outA
        let outG = (g * a + dg * da * (1 - a)) / outA
        let outB = (b * a + db * da * (1 - a)) / outA
        bitmap.pixels[o] = UInt8((outR * 255).rounded().clamped(0, 255))
        bitmap.pixels[o + 1] = UInt8((outG * 255).rounded().clamped(0, 255))
        bitmap.pixels[o + 2] = UInt8((outB * 255).rounded().clamped(0, 255))
        bitmap.pixels[o + 3] = UInt8((outA * 255).rounded().clamped(0, 255))
    }
}

// M15: this was `extension CGFloat` back when CGFloat was a typealias for
// Double, so it silently covered both. CGFloat is now Foundation's distinct
// struct, and the blend paths mix the two -- hence the generic form, which
// covers Double and CGFloat with one declaration and no overload ambiguity.
extension FloatingPoint {
    @inline(__always) func clamped(_ lo: Self, _ hi: Self) -> Self {
        Swift.min(hi, Swift.max(lo, self))
    }
}
