// QuartzBackend: Canvas rendering through the vendored libquartz
// (Sources/CQuartz, C API QZ* mirroring CG*). Owner: quartz-backend module.
//
// Coordinate mapping. QZ user space is y-up/bottom-left over a top-down
// premultiplied RGBA8888 backing (like CGBitmapContext). Canvas user space is
// top-down POINTS with the initial CTM = scale-by-`scale`. At creation we
// concat (translate 0,H_px; scale s,-s) so QZ user space becomes exactly
// Canvas user space: user (x,y) in points -> backing memory pixel
// (s*x, s*y), top-down. All Canvas coordinates then pass through unchanged.
//
// Backing conversion. quartz composites premultiplied; Bitmap/pngData expect
// straight alpha. The context renders into its own premultiplied backing and
// the affected device region is converted premultiplied->straight into
// `bitmap.pixels` after every drawing op (skipped inside transparency
// layers; a full-surface sync runs when the outermost layer ends). The
// conversion is the ONLY premul->straight step, so no double conversion.
//
// Glyph masks. drawMask blends 8-bit coverage masks CPU-side directly into
// the QZ backing with premultiplied source-over math that mirrors the Swift
// rasterizer's straight-alpha blend exactly (same float math, one rounding),
// preserving the tuned glyph-smoothing appearance. The clip comes from
// Canvas's mirror clip mask (Canvas.state.clipMask).

import CQuartz

final class QuartzBackend: CanvasBackend {
    unowned let canvas: Canvas
    private let bitmap: Bitmap
    private let ctx: QZContextRef
    private let width: Int
    private let height: Int
    private let bytesPerRow: Int
    /// Transparency-layer nesting depth; the backing->Bitmap sync only runs
    /// at depth 0 (the QZ backing pointer is redirected inside layers).
    private var layerDepth = 0

    init?(canvas: Canvas) {
        let bitmap = canvas.bitmap
        guard bitmap.width > 0, bitmap.height > 0,
              let ctx = QZBitmapContextCreate(nil, bitmap.width, bitmap.height,
                                              8, bitmap.width * 4, 1)
        else { return nil }
        self.canvas = canvas
        self.bitmap = bitmap
        self.ctx = ctx
        self.width = bitmap.width
        self.height = bitmap.height
        self.bytesPerRow = QZBitmapContextGetBytesPerRow(ctx)

        // Seed the premultiplied backing from the (straight-alpha) bitmap.
        if let data = QZBitmapContextGetData(ctx) {
            let dst = data.assumingMemoryBound(to: UInt8.self)
            bitmap.pixels.withUnsafeBufferPointer { src in
                for y in 0..<height {
                    let srow = y * width * 4
                    let drow = y * bytesPerRow
                    for x in 0..<width {
                        let s = srow + x * 4, d = drow + x * 4
                        let a = Int(src[s + 3])
                        if a == 0 {
                            dst[d] = 0; dst[d + 1] = 0; dst[d + 2] = 0; dst[d + 3] = 0
                        } else if a == 255 {
                            dst[d] = src[s]; dst[d + 1] = src[s + 1]
                            dst[d + 2] = src[s + 2]; dst[d + 3] = 255
                        } else {
                            dst[d] = UInt8((Int(src[s]) * a + 127) / 255)
                            dst[d + 1] = UInt8((Int(src[s + 1]) * a + 127) / 255)
                            dst[d + 2] = UInt8((Int(src[s + 2]) * a + 127) / 255)
                            dst[d + 3] = UInt8(a)
                        }
                    }
                }
            }
        }

        // Flip: QZ user space (y-up, device pixels) -> Canvas user space
        // (top-down, points at `scale` px/pt).
        QZContextTranslateCTM(ctx, 0, QZFloat(height))
        QZContextScaleCTM(ctx, QZFloat(canvas.scale), -QZFloat(canvas.scale))
    }

    deinit { QZContextRelease(ctx) }

    // MARK: State

    func saveState() { QZContextSaveGState(ctx) }
    func restoreState() { QZContextRestoreGState(ctx) }

    func concatenate(_ t: CGAffineTransform) {
        QZContextConcatCTM(ctx, QZAffineTransform(a: t.a, b: t.b, c: t.c,
                                                  d: t.d, tx: t.tx, ty: t.ty))
    }

    func clip(_ path: Path) {
        setPath(path)
        QZContextClip(ctx)
    }

    // MARK: Transparency layers

    func beginTransparencyLayer(alpha: CGFloat) {
        // CG semantics: the alpha in effect at Begin is captured as the group
        // alpha and applied when the layer is composited at End.
        QZContextSetAlpha(ctx, alpha)
        QZContextBeginTransparencyLayer(ctx)
        layerDepth += 1
    }

    func endTransparencyLayer() {
        guard layerDepth > 0 else { return }
        QZContextEndTransparencyLayer(ctx)
        // Canvas's layer alpha is a per-layer parameter, not sticky state.
        QZContextSetAlpha(ctx, 1)
        layerDepth -= 1
        if layerDepth == 0 { syncAll() }
    }

    // MARK: Drawing

    func fill(_ path: Path, color: CGColor, evenOdd: Bool, hardEdges: Bool) {
        guard color.alpha > 0 else { return }
        // Layer shadow (Canvas.state.shadow): QZ composites a blurred,
        // offset silhouette beneath the fill within the same op. The offset
        // is CTM-transformed by QZ (our flip CTM makes +y = down, matching
        // Canvas user space); QZ's blur parameter is in DEVICE pixels
        // (sigma = blur/2), so scale the point-space blur by the CTM.
        var shadowMargin = 0
        if let sh = canvas.state.shadow, sh.color.alpha > 0 {
            let t = canvas.state.ctm
            let s = ((t.a * t.d - t.b * t.c).magnitude).squareRoot()
            QZContextSaveGState(ctx)
            QZContextSetShadowWithColor(
                ctx, QZSize(width: sh.offset.width, height: sh.offset.height),
                sh.blur * s, sh.color.red, sh.color.green, sh.color.blue,
                sh.color.alpha)
            let off = Swift.max(sh.offset.width.magnitude, sh.offset.height.magnitude)
            shadowMargin = Int(((off + 2 * sh.blur) * s).rounded(.up)) + 2
        }
        QZContextSetRGBFillColor(ctx, color.red, color.green, color.blue, color.alpha)
        if hardEdges { QZContextSetShouldAntialias(ctx, false) }
        setPath(path)
        if evenOdd { QZContextEOFillPath(ctx) } else { QZContextFillPath(ctx) }
        if hardEdges { QZContextSetShouldAntialias(ctx, true) }
        if shadowMargin > 0 { QZContextRestoreGState(ctx) }
        syncRegion(deviceBounds(of: path, margin: 2 + shadowMargin))
    }

    func drawShadowOnly(_ path: Path, evenOdd: Bool, _ shadow: CanvasShadow) {
        // Fill the path with a fully transparent color while the QZ shadow
        // is set: QZ composites the shadow from the shape's coverage
        // independently of the fill color, and a zero-alpha fill blends
        // nothing — leaving exactly the shadow.
        let t = canvas.state.ctm
        let s = ((t.a * t.d - t.b * t.c).magnitude).squareRoot()
        QZContextSaveGState(ctx)
        QZContextSetShadowWithColor(
            ctx, QZSize(width: shadow.offset.width, height: shadow.offset.height),
            shadow.blur * s, shadow.color.red, shadow.color.green,
            shadow.color.blue, shadow.color.alpha)
        QZContextSetRGBFillColor(ctx, 0, 0, 0, 0)
        setPath(path)
        if evenOdd { QZContextEOFillPath(ctx) } else { QZContextFillPath(ctx) }
        QZContextRestoreGState(ctx)
        let off = Swift.max(shadow.offset.width.magnitude, shadow.offset.height.magnitude)
        let margin = Int(((off + 2 * shadow.blur) * s).rounded(.up)) + 2
        syncRegion(deviceBounds(of: path, margin: margin))
    }

    func drawLinearGradient(colors: [CGColor], locations: [CGFloat],
                            start: CGPoint, end: CGPoint, in rect: CGRect) {
        var locs = [QZFloat]()
        var comps = [QZFloat]()
        locs.reserveCapacity(locations.count)
        comps.reserveCapacity(colors.count * 4)
        for (c, l) in zip(colors, locations) {
            locs.append(QZFloat(l))
            comps.append(QZFloat(c.red)); comps.append(QZFloat(c.green))
            comps.append(QZFloat(c.blue)); comps.append(QZFloat(c.alpha))
        }
        guard let grad = QZGradientCreate(&locs, &comps, locs.count) else { return }
        QZContextSaveGState(ctx)
        QZContextClipToRect(ctx, QZRect(origin: QZPoint(x: rect.minX, y: rect.minY),
                                        size: QZSize(width: rect.width,
                                                     height: rect.height)))
        let options = kQZGradientDrawsBeforeStartLocation.rawValue
                    | kQZGradientDrawsAfterEndLocation.rawValue
        QZContextDrawLinearGradient(ctx, grad,
                                    QZPoint(x: start.x, y: start.y),
                                    QZPoint(x: end.x, y: end.y),
                                    UInt32(options))
        QZContextRestoreGState(ctx)
        QZGradientRelease(grad)
        syncRegion(deviceBounds(of: .rect(rect), margin: 2))
    }

    func stroke(_ path: Path, color: CGColor, lineWidth: CGFloat) {
        guard color.alpha > 0, lineWidth > 0 else { return }
        QZContextSetRGBStrokeColor(ctx, color.red, color.green, color.blue, color.alpha)
        QZContextSetLineWidth(ctx, lineWidth)
        // Match the Swift rasterizer's stroking model: butt caps, round joins.
        QZContextSetLineCap(ctx, kQZLineCapButt)
        QZContextSetLineJoin(ctx, kQZLineJoinRound)
        setPath(path)
        QZContextStrokePath(ctx)
        let t = canvas.state.ctm
        let s = ((t.a * t.d - t.b * t.c).magnitude).squareRoot()
        syncRegion(deviceBounds(of: path, margin: Int((lineWidth * s / 2).rounded(.up)) + 2))
    }

    func drawImage(_ image: Bitmap, in rect: CGRect, interpolate: Bool) {
        guard image.width > 0, image.height > 0, rect.width > 0, rect.height > 0 else { return }
        let img = image.pixels.withUnsafeBufferPointer {
            QZImageCreate(image.width, image.height, $0.baseAddress)
        }
        guard let img else { return }
        QZContextSaveGState(ctx)
        QZContextSetInterpolationQuality(
            ctx, interpolate ? kQZInterpolationDefault : kQZInterpolationNone)
        // QZ (like CG) maps the image bottom row to rect.minY in y-up user
        // space; our user space is top-down, so counter-flip about the rect.
        QZContextTranslateCTM(ctx, 0, rect.minY + rect.maxY)
        QZContextScaleCTM(ctx, 1, -1)
        QZContextDrawImage(ctx, QZRect(origin: QZPoint(x: rect.minX, y: rect.minY),
                                       size: QZSize(width: rect.width, height: rect.height)),
                           img)
        QZContextRestoreGState(ctx)
        QZImageRelease(img)
        syncRegion(deviceBounds(of: .rect(rect), margin: 2))
    }

    func drawMask(_ mask: [UInt8], width w: Int, height h: Int,
                  atPixelX ox: Int, pixelY oy: Int, color: CGColor) {
        guard color.alpha > 0, w > 0, h > 0 else { return }
        guard let data = QZBitmapContextGetData(ctx) else { return }
        let px = data.assumingMemoryBound(to: UInt8.self)
        let clip = canvas.state.clipMask
        let my0 = Swift.max(0, -oy), my1 = Swift.min(h, height - oy)
        let mx0 = Swift.max(0, -ox), mx1 = Swift.min(w, width - ox)
        guard my0 < my1, mx0 < mx1 else { return }
        let cr = color.red, cg = color.green, cb = color.blue
        for my in my0..<my1 {
            let y = oy + my
            let maskRow = my * w
            let rowBase = y * width
            let dstRow = y * bytesPerRow
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
                // Premultiplied source-over (same math as the Swift
                // rasterizer's straight-alpha blend, expressed premultiplied).
                let o = dstRow + x * 4
                let inv = 1 - a
                func b8(_ v: CGFloat) -> UInt8 {
                    UInt8(Swift.min(255, Swift.max(0, (v * 255).rounded())))
                }
                px[o] = b8(cr * a + CGFloat(px[o]) / 255 * inv)
                px[o + 1] = b8(cg * a + CGFloat(px[o + 1]) / 255 * inv)
                px[o + 2] = b8(cb * a + CGFloat(px[o + 2]) / 255 * inv)
                px[o + 3] = b8(a + CGFloat(px[o + 3]) / 255 * inv)
            }
        }
        syncRegion((x0: Swift.max(0, ox), y0: Swift.max(0, oy),
                    x1: Swift.min(width, ox + w), y1: Swift.min(height, oy + h)))
    }

    // MARK: Path plumbing

    private func setPath(_ path: Path) {
        QZContextBeginPath(ctx)
        for e in path.elements {
            switch e {
            case .move(let p):
                QZContextMoveToPoint(ctx, p.x, p.y)
            case .line(let p):
                QZContextAddLineToPoint(ctx, p.x, p.y)
            case .quad(let c, let p):
                QZContextAddQuadCurveToPoint(ctx, c.x, c.y, p.x, p.y)
            case .cubic(let c1, let c2, let p):
                QZContextAddCurveToPoint(ctx, c1.x, c1.y, c2.x, c2.y, p.x, p.y)
            case .close:
                QZContextClosePath(ctx)
            }
        }
    }

    /// Conservative device-pixel bounding box of `path` under the current
    /// Canvas CTM (control points bound the curves), expanded by `margin`.
    private func deviceBounds(of path: Path, margin: Int)
        -> (x0: Int, y0: Int, x1: Int, y1: Int)? {
        let t = canvas.state.ctm
        var minX = CGFloat.infinity, minY = CGFloat.infinity
        var maxX = -CGFloat.infinity, maxY = -CGFloat.infinity
        func take(_ p: CGPoint) {
            let d = p.applying(t)
            if d.x < minX { minX = d.x }
            if d.x > maxX { maxX = d.x }
            if d.y < minY { minY = d.y }
            if d.y > maxY { maxY = d.y }
        }
        for e in path.elements {
            switch e {
            case .move(let p), .line(let p): take(p)
            case .quad(let c, let p): take(c); take(p)
            case .cubic(let c1, let c2, let p): take(c1); take(c2); take(p)
            case .close: break
            }
        }
        guard minX <= maxX, minY <= maxY else { return nil }
        let x0 = Swift.max(0, Int(minX.rounded(.down)) - margin)
        let y0 = Swift.max(0, Int(minY.rounded(.down)) - margin)
        let x1 = Swift.min(width, Int(maxX.rounded(.up)) + margin)
        let y1 = Swift.min(height, Int(maxY.rounded(.up)) + margin)
        guard x0 < x1, y0 < y1 else { return nil }
        return (x0, y0, x1, y1)
    }

    // MARK: Backing -> Bitmap sync (premultiplied -> straight)

    private func syncAll() {
        syncRegion((x0: 0, y0: 0, x1: width, y1: height))
    }

    private func syncRegion(_ r: (x0: Int, y0: Int, x1: Int, y1: Int)?) {
        guard layerDepth == 0, let r else { return }
        guard let data = QZBitmapContextGetData(ctx) else { return }
        let src = data.assumingMemoryBound(to: UInt8.self)
        let bpr = bytesPerRow, bw = width
        bitmap.pixels.withUnsafeMutableBufferPointer { dst in
            for y in r.y0..<r.y1 {
                let srow = y * bpr
                let drow = y * bw * 4
                for x in r.x0..<r.x1 {
                    let s = srow + x * 4, d = drow + x * 4
                    let a = Int(src[s + 3])
                    if a == 0 {
                        dst[d] = 0; dst[d + 1] = 0; dst[d + 2] = 0; dst[d + 3] = 0
                    } else if a == 255 {
                        dst[d] = src[s]; dst[d + 1] = src[s + 1]
                        dst[d + 2] = src[s + 2]; dst[d + 3] = 255
                    } else {
                        // straight = round(premul * 255 / alpha), clamped.
                        dst[d] = UInt8(Swift.min(255, (Int(src[s]) * 255 + a / 2) / a))
                        dst[d + 1] = UInt8(Swift.min(255, (Int(src[s + 1]) * 255 + a / 2) / a))
                        dst[d + 2] = UInt8(Swift.min(255, (Int(src[s + 2]) * 255 + a / 2) / a))
                        dst[d + 3] = UInt8(a)
                    }
                }
            }
        }
    }
}
