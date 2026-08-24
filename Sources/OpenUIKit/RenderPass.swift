// View-hierarchy render traversal. Owner: view module.
//
// Order matches CALayer compositing (docs/ARCHITECTURE.md):
//   1. transparency layer if alpha < 1 (groups the WHOLE subtree)
//   2. masksToBounds clip (rounded by cornerRadius) — applied BEFORE
//      background/content, and it also clips subviews
//   3. background rounded fill
//   4. drawContent (text / images / control chrome)
//   5. subviews in array order (translate to center, concat transform,
//      translate by -bounds.mid)
//   6. border ring ABOVE sublayers (even-odd ring fill; inner radius
//      = max(0, cornerRadius - borderWidth))
//   7. end transparency layer
//
// Hard-edge rule: UIKit does not anti-alias the edges of transformed
// (rotated/scaled) layers — see golden/transforms.png. When a view's own
// transform is non-identity and not a pure translation, its background and
// border fills use hard (0/1 threshold at 0.5 coverage) edges.

public enum UIRenderer {
    /// CALayer's cornerRadius path, WITHOUT clamping the radius.
    ///
    /// iOS 26 CoreAnimation does not clamp `cornerRadius` to half the
    /// smaller side when compositing a layer: a radius larger than
    /// min(w,h)/2 produces the classic self-intersecting kappa rounded-rect
    /// (spikes past the corners, a four-pointed star hole in the middle
    /// under the non-zero winding rule) drawn well outside the bounds —
    /// see golden/corner_radius.png, the 80x60 view with cornerRadius 100.
    /// `Path.roundedRect` (frozen Canvas contract) clamps, so the render
    /// pass builds the layer path itself. For radius <= min(w,h)/2 this is
    /// numerically identical to `Path.roundedRect`.
    static func layerRoundedRect(_ r: CGRect, cornerRadius radius: CGFloat) -> Path {
        if radius <= 0 { return .rect(r) }
        if radius <= Swift.min(r.width, r.height) / 2 {
            return .roundedRect(r, cornerRadius: radius)
        }
        // Unclamped kappa construction (same control-point math as
        // Path.roundedRect, radius NOT limited to half the smaller side).
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

    /// Render a laid-out view hierarchy into a fresh bitmap.
    public static func render(_ root: UIView, scale: CGFloat) -> Bitmap {
        let w = Int((root.bounds.width * scale).rounded())
        let h = Int((root.bounds.height * scale).rounded())
        let bitmap = Bitmap(width: w, height: h)
        let canvas = Canvas(bitmap: bitmap, scale: scale)
        // Note: like CALayer.render(in:), the root's OWN transform is not
        // applied — a layer's transform is applied by its superlayer.
        renderView(root, into: canvas)
        return bitmap
    }

    /// True when `t` scales/rotates/skews (anything beyond translation).
    /// Such views composite with hard (non-anti-aliased) edges, matching
    /// UIKit's edge behavior for transformed layers.
    static func isAxisAlignedTranslationOnly(_ t: CGAffineTransform) -> Bool {
        t.a == 1 && t.b == 0 && t.c == 0 && t.d == 1
    }

    static func renderView(_ v: UIView, into c: Canvas) {
        if v.isHidden { return }
        let alpha = min(v.alpha, 1)
        if alpha <= 0 { return }

        c.save()
        let grouped = alpha < 1

        let bounds = v.bounds
        let radius = v.layer.cornerRadius
        let hardEdges = !isAxisAlignedTranslationOnly(v.transform)
        let shadow = shadowParams(of: v)

        // Group opacity + shadow: CoreAnimation composites the shadow onto
        // the destination BENEATH the whole group (it is not occluded by the
        // layer's own content) with the group alpha baked into its strength
        // — verified against golden/alpha_shadow_group (shadow shows through
        // the translucent card at shadowOpacity × alpha). Draw it before the
        // transparency layer opens.
        if grouped, let sh = shadow, let sil = shadowSilhouette(of: v) {
            c.save()
            c.setShadow(color: sh.color.withAlpha(alpha),
                        offset: sh.offset, blur: sh.blur)
            c.drawShadow(of: sil.path, evenOdd: sil.evenOdd)
            c.restore()
        }

        if grouped { c.beginTransparencyLayer(alpha: alpha) }

        // masksToBounds clips background, content AND subviews — apply first.
        if v.clipsToBounds { c.clip(to: layerRoundedRect(bounds, cornerRadius: radius)) }

        // Layer shadow (spec v2), non-grouped case: CoreAnimation derives
        // the shadow from the layer's content alpha (background + border
        // silhouette — the outer rounded rect) and composites it beneath
        // everything. Setting the Canvas shadow state around the
        // silhouette-defining fill makes both backends draw the blurred,
        // offset silhouette beneath that fill in one op. blur = 2 ×
        // shadowRadius renders a Gaussian sigma of shadowRadius points —
        // matches golden/shadows_radii (sigma fits 0.93·r·scale px against
        // the same 3x-box-blur family both backends use).
        let shadowHere = grouped ? nil : shadow

        var backgroundDrawn = false
        if let bg = v.backgroundColor {
            let color = bg.resolvedCGColor(with: v.traitCollection)
            if color.alpha > 0, !bounds.isEmpty {
                if let sh = shadowHere {
                    c.save()
                    c.setShadow(color: sh.color, offset: sh.offset, blur: sh.blur)
                }
                c.fill(layerRoundedRect(bounds, cornerRadius: radius), color: color,
                       hardEdges: hardEdges)
                if shadowHere != nil { c.restore() }
                backgroundDrawn = true
            }
        }
        // No background to cast the shadow: the silhouette is the border
        // ring alone (if any). Pre-draw it with the shadow active; the
        // regular border pass repaints the identical ring on top later.
        if !backgroundDrawn, let sh = shadowHere {
            c.save()
            c.setShadow(color: sh.color, offset: sh.offset, blur: sh.blur)
            renderBorder(of: v, bounds: bounds, radius: radius,
                         hardEdges: hardEdges, into: c)
            c.restore()
        }

        v.drawContent(in: c, bounds: bounds)

        for sub in v.subviews {
            c.save()
            // Position the subview: its center (in our bounds coordinates),
            // then its transform about that center (anchor 0.5/0.5), then
            // shift so the subview's own bounds coordinates line up.
            c.translate(x: sub.center.x, y: sub.center.y)
            c.concatenate(sub.transform)
            c.translate(x: -sub.bounds.midX, y: -sub.bounds.midY)
            renderView(sub, into: c)
            c.restore()
        }

        // CALayer draws its border ABOVE its contents and sublayers.
        renderBorder(of: v, bounds: bounds, radius: radius,
                     hardEdges: hardEdges, into: c)

        if grouped { c.endTransparencyLayer() }
        c.restore()
    }

    /// Effective shadow parameters for `v`, or nil when no shadow is
    /// visible. `color` carries shadowColor.alpha × shadowOpacity; `blur`
    /// is the Canvas blur (2 × shadowRadius → sigma = shadowRadius points).
    static func shadowParams(of v: UIView)
        -> (color: CGColor, offset: CGSize, blur: CGFloat)? {
        let l = v.layer
        guard l.shadowOpacity > 0, !l.masksToBounds, !v.bounds.isEmpty,
              let sc = l.shadowColor else { return nil }
        let opacity = CGFloat(min(max(l.shadowOpacity, 0), 1))
        let color = sc.withAlpha(opacity)
        guard color.alpha > 0 else { return nil }
        return (color, l.shadowOffset, 2 * l.shadowRadius)
    }

    /// The shadow-casting silhouette of `v`'s layer: the outer rounded rect
    /// when the background is visible, else the border ring, else nil.
    static func shadowSilhouette(of v: UIView) -> (path: Path, evenOdd: Bool)? {
        let bounds = v.bounds
        guard !bounds.isEmpty else { return nil }
        let radius = v.layer.cornerRadius
        if let bg = v.backgroundColor,
           bg.resolvedCGColor(with: v.traitCollection).alpha > 0 {
            return (layerRoundedRect(bounds, cornerRadius: radius), false)
        }
        let bw = v.layer.borderWidth
        if bw > 0, let bc = v.layer.borderColor, bc.alpha > 0 {
            let innerRect = bounds.insetBy(dx: bw, dy: bw)
            if !innerRect.isNull && innerRect.width > 0 && innerRect.height > 0 {
                var ring = layerRoundedRect(bounds, cornerRadius: radius)
                ring.elements += layerRoundedRect(
                    innerRect, cornerRadius: Swift.max(0, radius - bw)).elements
                return (ring, true)
            }
            return (layerRoundedRect(bounds, cornerRadius: radius), false)
        }
        return nil
    }

    static func renderBorder(of v: UIView, bounds: CGRect, radius: CGFloat,
                             hardEdges: Bool, into c: Canvas) {
        let bw = v.layer.borderWidth
        guard bw > 0, !bounds.isEmpty, let bc = v.layer.borderColor, bc.alpha > 0
        else { return }
        let outer = layerRoundedRect(bounds, cornerRadius: radius)
        let innerRect = bounds.insetBy(dx: bw, dy: bw)
        if !innerRect.isNull && innerRect.width > 0 && innerRect.height > 0 {
            // Even-odd ring between the outer rounded rect and the inner one
            // (inner corner radius shrinks by the border width, floored at 0).
            let innerRadius = Swift.max(0, radius - bw)
            var ring = outer
            ring.elements += layerRoundedRect(innerRect, cornerRadius: innerRadius).elements
            c.fill(ring, color: bc, evenOdd: true, hardEdges: hardEdges)
        } else {
            // Border consumes the whole bounds.
            c.fill(outer, color: bc, hardEdges: hardEdges)
        }
    }
}
