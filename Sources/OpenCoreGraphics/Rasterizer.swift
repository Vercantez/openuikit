// Software rasterizer implementation for Canvas.
// OWNED BY: rasterizer module.
//
// CURRENT STATE: naive bootstrap implementation so the pipeline runs
// end-to-end. Correct axis-aligned coverage; 4x4 supersampled path fills.
// The rasterizer module must replace fills/strokes with analytic-coverage
// anti-aliasing accurate to CoreGraphics within ±3/255 on edge pixels,
// proper bilinear image sampling, and an exact clip pipeline.
// See Canvas.swift for the contract.

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

    func _clip(_ path: Path) {
        let dev = path.applying(state.ctm)
        let flat = _flatten(dev)
        var mask = state.clipMask ?? [UInt8](repeating: 255, count: bitmap.width * bitmap.height)
        for y in 0..<bitmap.height {
            for x in 0..<bitmap.width {
                let idx = y * bitmap.width + x
                if mask[idx] == 0 { continue }
                let cov = _coverage(flat, x: x, y: y)
                mask[idx] = UInt8((CGFloat(mask[idx]) * cov).rounded())
            }
        }
        state.clipMask = mask
    }

    func _beginLayer(_ alpha: CGFloat) {
        layerStack.append(TransparencyLayer(savedPixels: bitmap.pixels, alpha: alpha,
                                            savedStateStackDepth: stateStack.count))
        // Fresh transparent buffer for the layer's content.
        for i in 0..<bitmap.pixels.count { bitmap.pixels[i] = 0 }
    }
    func _endLayer() {
        guard let layer = layerStack.popLast() else { return }
        let content = bitmap.pixels
        bitmap.pixels = layer.savedPixels
        // Composite content over saved, scaled by layer alpha.
        let n = bitmap.width * bitmap.height
        for i in 0..<n {
            let o = i * 4
            let sa = CGFloat(content[o + 3]) / 255 * layer.alpha
            if sa <= 0 { continue }
            _blendPixel(at: o,
                        r: CGFloat(content[o]) / 255,
                        g: CGFloat(content[o + 1]) / 255,
                        b: CGFloat(content[o + 2]) / 255,
                        a: sa)
        }
    }

    func _fill(_ path: Path, _ color: CGColor, _ evenOdd: Bool) {
        guard color.alpha > 0 else { return }
        let dev = path.applying(state.ctm)
        let flat = _flatten(dev)
        guard !flat.isEmpty else { return }
        var minX = CGFloat.infinity, minY = CGFloat.infinity
        var maxX = -CGFloat.infinity, maxY = -CGFloat.infinity
        for seg in flat {
            minX = Swift.min(minX, seg.0.x, seg.1.x); maxX = Swift.max(maxX, seg.0.x, seg.1.x)
            minY = Swift.min(minY, seg.0.y, seg.1.y); maxY = Swift.max(maxY, seg.0.y, seg.1.y)
        }
        let x0 = Swift.max(0, Int(minX.rounded(.down))), x1 = Swift.min(bitmap.width - 1, Int(maxX.rounded(.up)))
        let y0 = Swift.max(0, Int(minY.rounded(.down))), y1 = Swift.min(bitmap.height - 1, Int(maxY.rounded(.up)))
        guard x0 <= x1, y0 <= y1 else { return }
        for y in y0...y1 {
            for x in x0...x1 {
                var cov = _coverage(flat, x: x, y: y, evenOdd: evenOdd)
                if cov <= 0 { continue }
                if let m = state.clipMask { cov *= CGFloat(m[y * bitmap.width + x]) / 255 }
                if cov <= 0 { continue }
                _blendPixel(at: (y * bitmap.width + x) * 4,
                            r: color.red, g: color.green, b: color.blue, a: color.alpha * cov)
            }
        }
    }

    func _stroke(_ path: Path, _ color: CGColor, _ lineWidth: CGFloat) {
        // Naive: build a fillable outline by offsetting each flattened
        // segment into a quad of width lineWidth.
        let flat = _flatten(path)
        let hw = lineWidth / 2
        for (a, b) in flat {
            let dx = b.x - a.x, dy = b.y - a.y
            let len = (dx * dx + dy * dy).squareRoot()
            guard len > 0 else { continue }
            let nx = -dy / len * hw, ny = dx / len * hw
            var quad = Path()
            quad.move(to: CGPoint(x: a.x + nx, y: a.y + ny))
            quad.addLine(to: CGPoint(x: b.x + nx, y: b.y + ny))
            quad.addLine(to: CGPoint(x: b.x - nx, y: b.y - ny))
            quad.addLine(to: CGPoint(x: a.x - nx, y: a.y - ny))
            quad.close()
            _fill(quad, color, false)
        }
    }

    func _drawImage(_ image: Bitmap, _ rect: CGRect, _ interpolate: Bool) {
        // Map each device pixel in rect's device bbox back to image space.
        let dev = rect.applying(state.ctm)
        let inv = state.ctm.inverted()
        let x0 = Swift.max(0, Int(dev.minX.rounded(.down))), x1 = Swift.min(bitmap.width - 1, Int(dev.maxX.rounded(.up)) - 1)
        let y0 = Swift.max(0, Int(dev.minY.rounded(.down))), y1 = Swift.min(bitmap.height - 1, Int(dev.maxY.rounded(.up)) - 1)
        guard x1 >= x0, y1 >= y0, rect.width > 0, rect.height > 0 else { return }
        for y in y0...y1 {
            for x in x0...x1 {
                let user = CGPoint(x: CGFloat(x) + 0.5, y: CGFloat(y) + 0.5).applying(inv)
                let u = (user.x - rect.minX) / rect.width
                let v = (user.y - rect.minY) / rect.height
                guard u >= 0, u < 1, v >= 0, v < 1 else { continue }
                let sx = Swift.min(image.width - 1, Int(u * CGFloat(image.width)))
                let sy = Swift.min(image.height - 1, Int(v * CGFloat(image.height)))
                let so = (sy * image.width + sx) * 4
                var a = CGFloat(image.pixels[so + 3]) / 255
                if let m = state.clipMask { a *= CGFloat(m[y * bitmap.width + x]) / 255 }
                if a <= 0 { continue }
                _blendPixel(at: (y * bitmap.width + x) * 4,
                            r: CGFloat(image.pixels[so]) / 255,
                            g: CGFloat(image.pixels[so + 1]) / 255,
                            b: CGFloat(image.pixels[so + 2]) / 255,
                            a: a)
            }
        }
    }

    func _drawMask(_ mask: [UInt8], _ w: Int, _ h: Int, _ ox: Int, _ oy: Int, _ color: CGColor) {
        for my in 0..<h {
            let y = oy + my
            guard y >= 0, y < bitmap.height else { continue }
            for mx in 0..<w {
                let x = ox + mx
                guard x >= 0, x < bitmap.width else { continue }
                var a = CGFloat(mask[my * w + mx]) / 255 * color.alpha
                if let m = state.clipMask { a *= CGFloat(m[y * bitmap.width + x]) / 255 }
                if a <= 0 { continue }
                _blendPixel(at: (y * bitmap.width + x) * 4,
                            r: color.red, g: color.green, b: color.blue, a: a)
            }
        }
    }

    // MARK: - helpers

    /// Source-over blend of straight-alpha color onto pixel at byte offset.
    @inline(__always)
    func _blendPixel(at o: Int, r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
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

    /// Flatten path (already in device space) to line segments.
    func _flatten(_ path: Path) -> [(CGPoint, CGPoint)] {
        var segs: [(CGPoint, CGPoint)] = []
        var start = CGPoint.zero, cur = CGPoint.zero
        func flattenCurve(_ points: @escaping (CGFloat) -> CGPoint, from: CGPoint) {
            let steps = 24
            var prev = from
            for i in 1...steps {
                let p = points(CGFloat(i) / CGFloat(steps))
                segs.append((prev, p))
                prev = p
            }
            cur = prev
        }
        for e in path.elements {
            switch e {
            case .move(let p): start = p; cur = p
            case .line(let p): segs.append((cur, p)); cur = p
            case .quad(let c, let p):
                let from = cur
                flattenCurve({ t in
                    let mt = 1 - t
                    return CGPoint(x: mt * mt * from.x + 2 * mt * t * c.x + t * t * p.x,
                                   y: mt * mt * from.y + 2 * mt * t * c.y + t * t * p.y)
                }, from: from)
            case .cubic(let c1, let c2, let p):
                let from = cur
                flattenCurve({ t in
                    let mt = 1 - t
                    let x = mt * mt * mt * from.x + 3 * mt * mt * t * c1.x + 3 * mt * t * t * c2.x + t * t * t * p.x
                    let y = mt * mt * mt * from.y + 3 * mt * mt * t * c1.y + 3 * mt * t * t * c2.y + t * t * t * p.y
                    return CGPoint(x: x, y: y)
                }, from: from)
            case .close:
                segs.append((cur, start)); cur = start
            }
        }
        return segs
    }

    /// 4x4 supersampled winding coverage for pixel (x, y).
    func _coverage(_ segs: [(CGPoint, CGPoint)], x: Int, y: Int, evenOdd: Bool = false) -> CGFloat {
        var hits = 0
        for sy in 0..<4 {
            for sx in 0..<4 {
                let px = CGFloat(x) + (CGFloat(sx) + 0.5) / 4
                let py = CGFloat(y) + (CGFloat(sy) + 0.5) / 4
                var winding = 0
                for (a, b) in segs {
                    if (a.y <= py && b.y > py) || (b.y <= py && a.y > py) {
                        let t = (py - a.y) / (b.y - a.y)
                        let ix = a.x + t * (b.x - a.x)
                        if ix > px { winding += b.y > a.y ? 1 : -1 }
                    }
                }
                let inside = evenOdd ? (winding % 2 != 0) : (winding != 0)
                if inside { hits += 1 }
            }
        }
        return CGFloat(hits) / 16
    }
}

extension CGFloat {
    @inline(__always) func clamped(_ lo: CGFloat, _ hi: CGFloat) -> CGFloat {
        Swift.min(hi, Swift.max(lo, self))
    }
}
