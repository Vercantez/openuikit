// Pure-Swift rasterizer implementations of the additive v2 Canvas ops
// (CanvasEffects.swift): layer shadows and linear gradients.
//
// The shadow pipeline is a deliberate port of the vendored libquartz's
// (Sources/CQuartz/qz_context.cpp): rasterize the shape's analytic coverage
// over the full surface, shift by the CTM-transformed offset (rounded to
// whole device pixels), approximate the Gaussian with THREE box blurs
// (sigma = blurDevice/2, identical kernel-width selection), then composite
// the tinted result. Keeping the exact same blur construction makes the two
// backends agree to rounding on shadow scenes.

extension Canvas {
    /// Device-space bbox of flattened subpaths (local copy — Rasterizer's
    /// `_bounds` is private and this file only extends additively).
    private func _effectsBounds(of subpaths: [_Subpath])
        -> (CGFloat, CGFloat, CGFloat, CGFloat)? {
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

    // MARK: - Shadow

    /// Composite the shadow of `path` (blurred, offset silhouette tinted
    /// with `sh.color`) into the bitmap. Called by the Swift backend BEFORE
    /// the fill itself, mirroring quartz's fill_polylines order.
    func _drawShadow(_ path: Path, evenOdd: Bool, _ sh: CanvasShadow) {
        let w = bitmap.width, h = bitmap.height
        guard w > 0, h > 0 else { return }
        let t = state.ctm

        // Full-surface coverage of the shape (pre-clip, like quartz).
        let subpaths = _flattenSubpaths(path, transform: t)
        guard let box = _effectsBounds(of: subpaths) else { return }
        var cov = [CGFloat](repeating: 0, count: w * h)
        guard var acc = _CoverageAccumulator(clippingBoxMinX: box.0, minY: box.1,
                                             maxX: box.2, maxY: box.3,
                                             limitWidth: w, limitHeight: h) else { return }
        acc.add(subpaths: subpaths, implicitClose: true)
        let ox = acc.originX, oy = acc.originY, aw = acc.width
        cov.withUnsafeMutableBufferPointer { buf in
            acc.enumerateRows(evenOdd: evenOdd) { row, coverage in
                let base = (oy + row) * w + ox
                for xi in 0..<aw { buf[base + xi] = coverage[xi] }
            }
        }

        // Offset: user-space points through the CTM's linear part (top-down
        // device space, so +y offset shifts the shadow down), rounded to
        // whole pixels — same as quartz.
        let dx = Int((t.a * sh.offset.width + t.c * sh.offset.height).rounded())
        let dy = Int((t.b * sh.offset.width + t.d * sh.offset.height).rounded())
        var img = [CGFloat](repeating: 0, count: w * h)
        if dx != 0 || dy != 0 {
            for y in 0..<h {
                let sy = y - dy
                if sy < 0 || sy >= h { continue }
                let srow = sy * w, drow = y * w
                let x0 = Swift.max(0, dx), x1 = Swift.min(w, w + dx)
                if x0 >= x1 { continue }
                for x in x0..<x1 { img[drow + x] = cov[srow + x - dx] }
            }
        } else {
            img = cov
        }

        // Blur in device pixels: sigma = blur * ctmScale / 2.
        let ctmScale = ((t.a * t.d - t.b * t.c).magnitude).squareRoot()
        _shadowBlurApprox(&img, w, h, blur: Double(sh.blur * ctmScale))

        // Composite (before the fill). Clip applies here, not to the
        // silhouette source — quartz's blend_coverage semantics.
        let clip = state.clipMask
        let cr = sh.color.red, cg = sh.color.green, cb = sh.color.blue
        let ca = sh.color.alpha
        for y in 0..<h {
            let rowBase = y * w
            for x in 0..<w {
                let c = img[rowBase + x]
                if c < 0.001 { continue }
                var a = ca * Swift.min(c, 1)
                if let m = clip {
                    let mv = m[rowBase + x]
                    if mv == 0 { continue }
                    a *= CGFloat(mv) / 255
                }
                if a <= 0 { continue }
                _blendPixel(at: (rowBase + x) * 4, r: cr, g: cg, b: cb, a: a)
            }
        }
    }

    /// Three box blurs ≈ Gaussian with sigma = blur/2 — exact port of
    /// libquartz's shadow_blur_approx (identical kernel-width selection and
    /// edge-clamp behavior, so backend outputs match).
    private func _shadowBlurApprox(_ img: inout [CGFloat], _ w: Int, _ h: Int,
                                   blur: Double) {
        if blur < 0.5 {
            if blur > 0.05 { _boxBlur(&img, w, h, radius: 1) }
            return
        }
        let sigma = blur * 0.5
        let n = 3.0
        let wIdeal = ((12.0 * sigma * sigma) / n + 1.0).squareRoot()
        var wl = Int(wIdeal.rounded(.down))
        if wl % 2 == 0 { wl -= 1 }
        if wl < 1 { wl = 1 }
        let wu = wl + 2
        let mIdeal = (12.0 * sigma * sigma - n * Double(wl * wl)
                      - 4.0 * n * Double(wl) - 3.0 * n)
                     / (-4.0 * Double(wl) - 4.0)
        var m = Int(mIdeal.rounded())
        if m < 0 { m = 0 }
        if m > 3 { m = 3 }
        for i in 0..<3 {
            let size = i < m ? wl : wu
            let radius = (size - 1) / 2
            if radius >= 1 { _boxBlur(&img, w, h, radius: radius) }
        }
    }

    /// Separable box blur with edge clamp (replicate), matching libquartz.
    private func _boxBlur(_ img: inout [CGFloat], _ w: Int, _ h: Int, radius: Int) {
        guard radius >= 1 else { return }
        var tmp = [CGFloat](repeating: 0, count: img.count)
        let span = CGFloat(radius * 2 + 1)
        @inline(__always) func clampi(_ v: Int, _ lo: Int, _ hi: Int) -> Int {
            Swift.min(hi, Swift.max(lo, v))
        }
        img.withUnsafeBufferPointer { src in
            tmp.withUnsafeMutableBufferPointer { dst in
                for y in 0..<h {
                    let row = y * w
                    var accum: CGFloat = 0
                    for x in -radius...radius { accum += src[row + clampi(x, 0, w - 1)] }
                    for x in 0..<w {
                        dst[row + x] = accum / span
                        accum -= src[row + clampi(x - radius, 0, w - 1)]
                        accum += src[row + clampi(x + radius + 1, 0, w - 1)]
                    }
                }
            }
        }
        tmp.withUnsafeBufferPointer { src in
            img.withUnsafeMutableBufferPointer { dst in
                for x in 0..<w {
                    var accum: CGFloat = 0
                    for y in -radius...radius { accum += src[clampi(y, 0, h - 1) * w + x] }
                    for y in 0..<h {
                        dst[y * w + x] = accum / span
                        accum -= src[clampi(y - radius, 0, h - 1) * w + x]
                        accum += src[clampi(y + radius + 1, 0, h - 1) * w + x]
                    }
                }
            }
        }
    }

    // MARK: - Linear gradient

    /// Fill `rect` with an axial gradient (per-pixel projection onto the
    /// start→end axis; piecewise-linear stop interpolation on gamma-encoded
    /// sRGB components, clamped to the end colors — CanvasEffects contract).
    /// Rect edge anti-aliasing uses the same analytic coverage as fills.
    func _drawLinearGradient(_ colors: [CGColor], _ locations: [CGFloat],
                             _ start: CGPoint, _ end: CGPoint, _ rect: CGRect) {
        let axis = CGPoint(x: end.x - start.x, y: end.y - start.y)
        let len2 = axis.x * axis.x + axis.y * axis.y
        guard len2 > 1e-20 else { return }

        let subpaths = _flattenSubpaths(.rect(rect), transform: state.ctm)
        guard let box = _effectsBounds(of: subpaths) else { return }
        guard var acc = _CoverageAccumulator(clippingBoxMinX: box.0, minY: box.1,
                                             maxX: box.2, maxY: box.3,
                                             limitWidth: bitmap.width,
                                             limitHeight: bitmap.height) else { return }
        acc.add(subpaths: subpaths, implicitClose: true)

        let inv = state.ctm.inverted()
        let ox = acc.originX, oy = acc.originY, w = acc.width
        let bw = bitmap.width
        let clip = state.clipMask

        acc.enumerateRows(evenOdd: false) { row, cov in
            let by = oy + row
            let rowBase = by * bw
            let py = CGFloat(by) + 0.5
            for xi in 0..<w {
                var c = cov[xi]
                if c < 0.001 { continue }
                let px = ox + xi
                if let m = clip {
                    let mv = m[rowBase + px]
                    if mv == 0 { continue }
                    c *= CGFloat(mv) / 255
                }
                // Device pixel center back to user space.
                let user = CGPoint(x: CGFloat(px) + 0.5, y: py).applying(inv)
                let t = ((user.x - start.x) * axis.x + (user.y - start.y) * axis.y) / len2
                let col = Self._gradientColor(colors, locations, at: t)
                let a = col.alpha * c
                if a <= 0 { continue }
                _blendPixel(at: (rowBase + px) * 4,
                            r: col.red, g: col.green, b: col.blue, a: a)
            }
        }
    }

    /// Piecewise-linear stop lookup; clamps outside the location span.
    /// Mirrors libquartz's grad_lerp so backend outputs match to rounding.
    static func _gradientColor(_ colors: [CGColor], _ locations: [CGFloat],
                               at t: CGFloat) -> CGColor {
        if t <= locations[0] { return colors[0] }
        if t >= locations[locations.count - 1] { return colors[colors.count - 1] }
        for i in 1..<locations.count {
            if t <= locations[i] {
                let span = locations[i] - locations[i - 1]
                let u = span > 0 ? (t - locations[i - 1]) / span : 0
                let a = colors[i - 1], b = colors[i]
                return CGColor(red: a.red + (b.red - a.red) * u,
                               green: a.green + (b.green - a.green) * u,
                               blue: a.blue + (b.blue - a.blue) * u,
                               alpha: a.alpha + (b.alpha - a.alpha) * u)
            }
        }
        return colors[colors.count - 1]
    }
}
