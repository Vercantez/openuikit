// LayerBridge — M5: render a laid-out UIView tree through quartz's REAL
// CALayer compositor (QZLayer) instead of the hand-written RenderPass
// traversal. Owner: view module.
//
// Selected via `OpenUIKitRuntime.compositor == .layers` (openrender honors
// OPENUIKIT_COMPOSITOR=layers|renderpass). Requires the quartz backend;
// UIRenderer.render falls back to the render pass under `.swift` so the
// pure-Swift path stays dependency-free.
//
// Mapping (mirrors RenderPass semantics, verified against the 42-scene
// golden suite):
//   - Geometry: layer position = view.center, anchor (0.5, 0.5) default,
//     bounds, affineTransform = view.transform. The root layer's own
//     position/transform are neutralized (CALayer.render(in:) semantics:
//     a layer's transform is applied by its superlayer).
//   - backgroundColor resolved through the view's traitCollection;
//     cornerRadius / borderWidth / borderColor / masksToBounds / opacity /
//     isHidden map 1:1. The quartz compositor (patched, see
//     docs/QUARTZ_PATCHES.md) reproduces the UIKit quirks the render pass
//     implements: unclamped corner radius, hard-edged transformed layers
//     (QZLayerSetEdgeAntialias false when the view's own transform is not
//     a pure translation), border above sublayers, group-opacity shadow
//     ordering, shadow-under-content, CA shadowRadius blur scaling.
//   - Shadows: QZLayerSetShadow(offset, shadowRadius, rgb,
//     shadowColor.alpha * shadowOpacity); not set when masksToBounds
//     (CA hides it) — the compositor also guards.
//   - UIGradientView -> QZGradientLayer with the raw resolved stops
//     (quartz interpolates in CA's Generic-RGB space itself).
//   - View custom content (label glyphs, images, control chrome): each
//     content-bearing view's drawContent is rendered into a transparent
//     offscreen Canvas at device scale (the EXISTING content path — glyph
//     ink tables, CG-profile image resampling, control chrome all
//     unchanged) and attached as the contents image of a dedicated
//     sublayer at index 0 (content composites above the background, below
//     subviews, below the border — CALayer order). The sublayer's frame is
//     the content extent snapped OUT to the device grid, so the composite
//     is a 1:1 device-aligned blit (scene geometry is on the half-point
//     grid). UIImageView content may overflow bounds (aspectFill /
//     center &c. clip only via clipsToBounds) — the extent covers the
//     overflow and the parent layer's masksToBounds clips when set.

import CQuartz

public enum LayerBridge {
    // MARK: Entry

    /// Render a laid-out view hierarchy into a fresh bitmap via the QZLayer
    /// compositor. Bit-compatible contract with UIRenderer.render.
    public static func render(_ root: UIView, scale: CGFloat) -> Bitmap {
        let w = Int((root.bounds.width * scale).rounded())
        let h = Int((root.bounds.height * scale).rounded())
        let bitmap = Bitmap(width: w, height: h)
        guard w > 0, h > 0,
              let ctx = QZBitmapContextCreate(nil, w, h, 8, w * 4, 1)
        else { return bitmap }
        defer { QZContextRelease(ctx) }

        // Flip: QZ user space (y-up, device px) -> top-down point space at
        // `scale` px/pt (same mapping as QuartzBackend).
        QZContextTranslateCTM(ctx, 0, QZFloat(h))
        QZContextScaleCTM(ctx, QZFloat(scale), -QZFloat(scale))

        var arena = Arena()
        defer { arena.releaseAll() }
        guard let rootLayer = buildLayer(for: root, scale: scale, arena: &arena)
        else { return bitmap }
        // Like CALayer.render(in:), the root's OWN transform/position are
        // not applied — neutralize them so bounds render at the origin.
        QZLayerSetAffineTransform(rootLayer, QZAffineTransformIdentity())
        QZLayerSetPosition(rootLayer, QZPoint(x: root.bounds.midX,
                                              y: root.bounds.midY))
        QZLayerRenderInContext(rootLayer, ctx)

        copyPremultipliedBacking(ctx, into: bitmap)
        return bitmap
    }

    // MARK: QZ object lifetime

    struct Arena {
        var layers: [QZLayerRef] = []
        var images: [QZImageRef] = []
        mutating func track(_ l: QZLayerRef) -> QZLayerRef {
            layers.append(l)
            return l
        }
        mutating func releaseAll() {
            for l in layers { QZLayerRelease(l) }
            for i in images { QZImageRelease(i) }
            layers.removeAll()
            images.removeAll()
        }
    }

    // MARK: Tree construction

    static func buildLayer(for v: UIView, scale: CGFloat,
                           arena: inout Arena) -> QZLayerRef? {
        let gradient = v as? UIGradientView
        let isGradientLayer = (gradient?.colors.count ?? 0) >= 2
        guard let raw = isGradientLayer ? QZGradientLayerCreate() : QZLayerCreate()
        else { return nil }
        let l = arena.track(raw)

        let b = v.bounds
        QZLayerSetBounds(l, qzRect(b))
        QZLayerSetPosition(l, QZPoint(x: v.center.x, y: v.center.y))
        let t = v.transform
        QZLayerSetAffineTransform(l, QZAffineTransform(a: t.a, b: t.b, c: t.c,
                                                       d: t.d, tx: t.tx, ty: t.ty))
        QZLayerSetHidden(l, v.isHidden)
        QZLayerSetOpacity(l, QZFloat(Swift.min(Swift.max(v.alpha, 0), 1)))
        QZLayerSetCornerRadius(l, QZFloat(v.layer.cornerRadius))
        QZLayerSetMasksToBounds(l, v.clipsToBounds)

        let traits = v.traitCollection
        if let bg = v.backgroundColor {
            let c = bg.resolvedCGColor(with: traits)
            QZLayerSetBackgroundColor(l, QZFloat(c.red), QZFloat(c.green),
                                      QZFloat(c.blue), QZFloat(c.alpha))
        }
        if v.layer.borderWidth > 0, let bc = v.layer.borderColor {
            QZLayerSetBorderWidth(l, QZFloat(v.layer.borderWidth))
            QZLayerSetBorderColor(l, QZFloat(bc.red), QZFloat(bc.green),
                                  QZFloat(bc.blue), QZFloat(bc.alpha))
        }

        // UIKit does not anti-alias the edges of transformed (rotated /
        // scaled) layers — same rule as RenderPass.isAxisAlignedTranslationOnly.
        if !(t.a == 1 && t.b == 0 && t.c == 0 && t.d == 1) {
            QZLayerSetEdgeAntialias(l, false)
        }

        // Layer shadow (spec v2). Invisible while masksToBounds, like CA.
        let lay = v.layer
        if lay.shadowOpacity > 0, !lay.masksToBounds, !b.isEmpty,
           let sc = lay.shadowColor {
            let op = CGFloat(Swift.min(Swift.max(lay.shadowOpacity, 0), 1))
            let strength = sc.alpha * op
            if strength > 0 {
                QZLayerSetShadow(l, QZFloat(lay.shadowOffset.width),
                                 QZFloat(lay.shadowOffset.height),
                                 QZFloat(lay.shadowRadius),
                                 QZFloat(sc.red), QZFloat(sc.green),
                                 QZFloat(sc.blue), QZFloat(strength))
            }
        }

        if let g = gradient, isGradientLayer {
            configureGradient(l, view: g, traits: traits)
        } else if let content = contentLayer(for: v, scale: scale, arena: &arena) {
            QZLayerAddSublayer(l, content)
        }

        for sub in v.subviews {
            if let child = buildLayer(for: sub, scale: scale, arena: &arena) {
                QZLayerAddSublayer(l, child)
            }
        }
        return l
    }

    static func configureGradient(_ l: QZLayerRef, view: UIGradientView,
                                  traits: UITraitCollection) {
        let resolved = view.colors.map { $0.resolvedCGColor(with: traits) }
        let n = resolved.count
        var locs: [QZFloat]
        if let ll = view.locations, ll.count == n {
            locs = ll.map { QZFloat(Swift.min(Swift.max($0, 0), 1)) }
        } else {
            locs = (0..<n).map { QZFloat($0) / QZFloat(n - 1) }
        }
        var rgba = [QZFloat]()
        rgba.reserveCapacity(n * 4)
        for c in resolved {
            rgba.append(QZFloat(c.red)); rgba.append(QZFloat(c.green))
            rgba.append(QZFloat(c.blue)); rgba.append(QZFloat(c.alpha))
        }
        QZGradientLayerSetColors(l, &rgba, &locs, Int32(n))
        QZGradientLayerSetStartPoint(l, QZPoint(x: view.startPoint.x,
                                                y: view.startPoint.y))
        QZGradientLayerSetEndPoint(l, QZPoint(x: view.endPoint.x,
                                              y: view.endPoint.y))
    }

    // MARK: Content (drawContent -> contents image sublayer)

    /// Extent of `v`'s custom content in bounds coordinates, or nil when the
    /// view draws none. Snapped OUT to the device-pixel grid.
    static func contentExtent(of v: UIView, scale: CGFloat) -> CGRect? {
        // Plain containers draw no content — skip the offscreen entirely.
        if type(of: v) == UIView.self { return nil }
        if v is UIStackView || v is UIGradientView { return nil }
        let b = v.bounds
        guard !b.isEmpty else { return nil }
        var raw: CGRect
        if let iv = v as? UIImageView {
            guard let image = iv.image, image.bitmap.width > 0,
                  image.bitmap.height > 0 else { return nil }
            raw = UIImageView.contentRect(imageSize: image.size, bounds: b,
                                          mode: iv.contentMode)
            guard raw.width > 0, raw.height > 0 else { return nil }
        } else {
            // Glyph ink / control chrome can spill a hair past bounds
            // (side bearings, AA) — pad so the offscreen never clips what
            // the in-place render pass would have drawn.
            raw = b.insetBy(dx: -2, dy: -2)
        }
        return snapOut(raw, scale: scale)
    }

    static func snapOut(_ r: CGRect, scale: CGFloat) -> CGRect {
        let x0 = (r.minX * scale).rounded(.down) / scale
        let y0 = (r.minY * scale).rounded(.down) / scale
        let x1 = (r.maxX * scale).rounded(.up) / scale
        let y1 = (r.maxY * scale).rounded(.up) / scale
        return CGRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0)
    }

    /// Render `v.drawContent` into a transparent offscreen Canvas (existing
    /// content path: glyph ink tables, image resampling, control chrome)
    /// and wrap it as a contents-image sublayer. nil when nothing drew.
    static func contentLayer(for v: UIView, scale: CGFloat,
                             arena: inout Arena) -> QZLayerRef? {
        guard let extent = contentExtent(of: v, scale: scale) else { return nil }
        let pw = Int((extent.width * scale).rounded())
        let ph = Int((extent.height * scale).rounded())
        guard pw > 0, ph > 0 else { return nil }

        let offscreen = Bitmap(width: pw, height: ph)
        let canvas = Canvas(bitmap: offscreen, scale: scale)
        canvas.translate(x: -extent.minX, y: -extent.minY)
        v.drawContent(in: canvas, bounds: v.bounds)

        // Skip fully transparent content (e.g. empty labels).
        var any = false
        var i = 3
        let px = offscreen.pixels
        while i < px.count {
            if px[i] != 0 { any = true; break }
            i += 4
        }
        guard any else { return nil }

        // QZContextDrawImage maps the image bottom row to the dest rect's
        // minY in y-up space; under the top-down flip CTM that renders the
        // stored rows upside down — feed them bottom-up to compensate.
        var flipped = [UInt8](repeating: 0, count: px.count)
        let rowBytes = pw * 4
        for y in 0..<ph {
            let src = (ph - 1 - y) * rowBytes
            let dst = y * rowBytes
            flipped.replaceSubrange(dst..<(dst + rowBytes),
                                    with: px[src..<(src + rowBytes)])
        }
        guard let img = flipped.withUnsafeBufferPointer({
            QZImageCreate(pw, ph, $0.baseAddress)
        }) else { return nil }
        arena.images.append(img)

        guard let raw = QZLayerCreate() else { return nil }
        let l = arena.track(raw)
        QZLayerSetBounds(l, QZRect(origin: QZPoint(x: 0, y: 0),
                                   size: QZSize(width: extent.width,
                                                height: extent.height)))
        QZLayerSetPosition(l, QZPoint(x: extent.midX, y: extent.midY))
        QZLayerSetContents(l, img)
        return l
    }

    // MARK: Backing conversion

    static func qzRect(_ r: CGRect) -> QZRect {
        QZRect(origin: QZPoint(x: r.minX, y: r.minY),
               size: QZSize(width: r.width, height: r.height))
    }

    /// Premultiplied QZ backing -> straight-alpha Bitmap (same conversion
    /// as QuartzBackend.syncRegion).
    static func copyPremultipliedBacking(_ ctx: QZContextRef, into bitmap: Bitmap) {
        guard let data = QZBitmapContextGetData(ctx) else { return }
        let src = data.assumingMemoryBound(to: UInt8.self)
        let bpr = QZBitmapContextGetBytesPerRow(ctx)
        let w = bitmap.width, h = bitmap.height
        bitmap.pixels.withUnsafeMutableBufferPointer { dst in
            for y in 0..<h {
                let srow = y * bpr
                let drow = y * w * 4
                for x in 0..<w {
                    let s = srow + x * 4, d = drow + x * 4
                    let a = Int(src[s + 3])
                    if a == 0 {
                        dst[d] = 0; dst[d + 1] = 0; dst[d + 2] = 0; dst[d + 3] = 0
                    } else if a == 255 {
                        dst[d] = src[s]; dst[d + 1] = src[s + 1]
                        dst[d + 2] = src[s + 2]; dst[d + 3] = 255
                    } else {
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
