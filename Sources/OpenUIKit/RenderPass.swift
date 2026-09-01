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

@preconcurrency @MainActor
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
    static func layerRoundedRect(
        _ r: CGRect,
        cornerRadius radius: CGFloat,
        maskedCorners corners: CACornerMask = ._allKnown
    ) -> Path {
        let corners = corners.intersection(._allKnown)
        if radius <= 0 || corners.isEmpty { return .rect(r) }
        if corners == ._allKnown,
           radius <= Swift.min(r.width, r.height) / 2 {
            return .roundedRect(r, cornerRadius: radius)
        }
        // Per-corner, unclamped kappa construction. With all four bits this
        // is the same oversized-radius path as before; square corners use a
        // line to the vertex instead of a cubic quarter-circle.
        let k: CGFloat = 0.5522847498307936
        let kr = k * radius
        let minXMinY = corners.contains(.layerMinXMinYCorner)
        let maxXMinY = corners.contains(.layerMaxXMinYCorner)
        let minXMaxY = corners.contains(.layerMinXMaxYCorner)
        let maxXMaxY = corners.contains(.layerMaxXMaxYCorner)
        var p = Path()
        p.move(to: CGPoint(x: r.minX + (minXMinY ? radius : 0), y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - (maxXMinY ? radius : 0), y: r.minY))
        if maxXMinY {
            p.addCurve(to: CGPoint(x: r.maxX, y: r.minY + radius),
                       control1: CGPoint(x: r.maxX - radius + kr, y: r.minY),
                       control2: CGPoint(x: r.maxX, y: r.minY + radius - kr))
        } else {
            p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        }
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - (maxXMaxY ? radius : 0)))
        if maxXMaxY {
            p.addCurve(to: CGPoint(x: r.maxX - radius, y: r.maxY),
                       control1: CGPoint(x: r.maxX, y: r.maxY - radius + kr),
                       control2: CGPoint(x: r.maxX - radius + kr, y: r.maxY))
        } else {
            p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        }
        p.addLine(to: CGPoint(x: r.minX + (minXMaxY ? radius : 0), y: r.maxY))
        if minXMaxY {
            p.addCurve(to: CGPoint(x: r.minX, y: r.maxY - radius),
                       control1: CGPoint(x: r.minX + radius - kr, y: r.maxY),
                       control2: CGPoint(x: r.minX, y: r.maxY - radius + kr))
        } else {
            p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        }
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + (minXMinY ? radius : 0)))
        if minXMinY {
            p.addCurve(to: CGPoint(x: r.minX + radius, y: r.minY),
                       control1: CGPoint(x: r.minX, y: r.minY + radius - kr),
                       control2: CGPoint(x: r.minX + radius - kr, y: r.minY))
        } else {
            p.addLine(to: CGPoint(x: r.minX, y: r.minY))
        }
        p.close()
        return p
    }

    /// Render a laid-out view hierarchy into a fresh bitmap.
    ///
    /// Dispatches on `OpenUIKitRuntime.compositor`: `.layers` composites
    /// through quartz's QZLayer tree (LayerBridge, M5); `.renderPass` runs
    /// the traversal below. The layers compositor requires the quartz
    /// backend — under `.swift` the render pass is always used so that
    /// path stays pure Swift.
    public static func render(_ root: UIView, scale: CGFloat) -> Bitmap {
        if OpenUIKitRuntime.compositor == .layers,
           OpenUIKitRuntime.renderBackend == .quartz,
           !containsRenderPassOnlyEffect(root) {
            return LayerBridge.render(root, scale: scale)
        }
        return renderPassRender(root, scale: scale)
    }

    /// CQuartz's retained layer compositor does not yet expose a destination-
    /// sampling filter node. A hierarchy containing one therefore takes the
    /// established Canvas backdrop-filter route even when `.layers` is the
    /// global default. This is a semantic fallback, not a source-level fake:
    /// every other hierarchy still uses QZLayer, and the selected path runs
    /// the same backend-neutral filter kernel for Swift and Quartz Canvases.
    /// Color-adjustment groups currently execute in the Canvas compositor;
    /// retained QZLayer has no public color-matrix node yet. Select the same
    /// deterministic render-pass fallback used by backdrop filters rather
    /// than silently dropping the authored effect.
    static func containsRenderPassOnlyEffect(_ view: UIView) -> Bool {
        if let backdrop = view as? _UIVisualEffectBackdropView,
           let effectView = backdrop.superview as? UIVisualEffectView,
           effectView._canvasBackdropConfiguration(for: backdrop) != nil {
            return true
        }
        if view._openUIKitBrightness != 0 || view._openUIKitSaturation != 1 {
            return true
        }
        return view.subviews.contains(where: containsRenderPassOnlyEffect)
    }

    /// The hand-written render-pass traversal (always available; the
    /// fallback compositor).
    public static func renderPassRender(_ root: UIView, scale: CGFloat) -> Bitmap {
        // Keep the fallback path under the same finite/range/allocation guard
        // as LayerBridge. UIRenderer selects this path for the Swift backend
        // even when callers requested the layers compositor, so guarding only
        // LayerBridge would leave a public hostile-geometry trap.
        guard let rootPixels = _UIBitmapAllocation.checkedPixelSize(
            for: root.bounds,
            scale: scale
        ) else { return Bitmap(width: 0, height: 0) }
        let w = rootPixels.width
        let h = rootPixels.height
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

    static func renderView(_ v: UIView, into c: Canvas,
                           honorsMaskedCorners: Bool = true) {
        if v.isHidden { return }
        let backingPresentation = LayerBridge.presentationState(
            of: v, at: OpenUIKitRuntime.animationTime)
        let alpha = min(CGFloat(backingPresentation.opacity), 1)
        if alpha <= 0 { return }

        var maskAlpha: CGFloat = 1
        var maskClip: Path?
        if let mask = v.layer.mask {
            guard let maskState = solidMaskPresentation(
                mask, honorsMaskedCorners: honorsMaskedCorners) else { return }
            maskAlpha = maskState.alpha
            maskClip = maskState.clip
        }

        c.save()
        // CALayer.mask is outside the layer composite: it covers the shadow
        // as well as content and sublayers. Keep its transparency group open
        // around both the group-opacity shadow and the view opacity group so
        // partial mask alpha is multiplied into the final result exactly once.
        if let maskClip {
            c.beginMaskedTransparencyLayer(alpha: maskAlpha, mask: maskClip)
        }
        let adjustsColor = v._openUIKitBrightness != 0
            || v._openUIKitSaturation != 1
        let grouped = alpha < 1 || adjustsColor

        let bounds = backingPresentation.bounds
        let radius = backingPresentation.cornerRadius
        let corners = honorsMaskedCorners ? v.layer.maskedCorners : ._allKnown
        let hardEdges = !isAxisAlignedTranslationOnly(v.transform)
        let shadow = shadowParams(
            of: v, bounds: bounds, presentation: backingPresentation)

        // Group opacity + shadow: CoreAnimation composites the shadow onto
        // the destination BENEATH the whole group (it is not occluded by the
        // layer's own content) with the group alpha baked into its strength
        // — verified against golden/alpha_shadow_group (shadow shows through
        // the translucent card at shadowOpacity × alpha). Draw it before the
        // transparency layer opens.
        if grouped, let sh = shadow,
           let sil = shadowSilhouette(of: v, bounds: bounds, radius: radius,
                                      borderWidth: backingPresentation.borderWidth,
                                      maskedCorners: corners) {
            c.save()
            c.setShadow(color: sh.color.withAlpha(alpha),
                        offset: sh.offset, blur: sh.blur)
            c.drawShadow(of: sil.path, evenOdd: sil.evenOdd)
            c.restore()
        }

        if grouped { c.beginTransparencyLayer(alpha: alpha) }

        // masksToBounds clips background, content AND subviews — apply first.
        if v.clipsToBounds {
            c.clip(to: layerRoundedRect(bounds, cornerRadius: radius,
                                        maskedCorners: corners))
        }

        // A backdrop view changes pixels already present beneath its bounds;
        // it deliberately runs before this view's background/content and
        // before its content-host sibling. The filter rect is in the current
        // local coordinate system, so Canvas applies the accumulated UIView
        // transform and current clip to both sampling and replacement.
        if let backdrop = v as? _UIVisualEffectBackdropView,
           let effectView = backdrop.superview as? UIVisualEffectView,
           let configuration = effectView._canvasBackdropConfiguration(
                for: backdrop) {
            c.applyBackdropFilter(configuration, in: bounds)
        }

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
                c.fill(layerRoundedRect(bounds, cornerRadius: radius,
                                        maskedCorners: corners), color: color,
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
                         borderWidth: backingPresentation.borderWidth,
                         maskedCorners: corners, hardEdges: hardEdges, into: c)
            c.restore()
        }

        v.drawContent(in: c, bounds: bounds)

        // App-installed backing-layer children sit above the view's own
        // contents and below its UIView sublayers. Focus inserts gradients
        // at index zero for precisely this ordering.
        renderSublayers(of: v.layer, into: c,
                        honorsMaskedCorners: honorsMaskedCorners)

        for sub in v.subviews {
            c.save()
            // Position the subview at the live layer anchor, apply its view
            // transform there, then shift into the presented bounds space.
            let presentation = LayerBridge.presentationState(
                of: sub, at: OpenUIKitRuntime.animationTime)
            c.translate(x: presentation.position.x, y: presentation.position.y)
            c.concatenate(sub.transform)
            c.translate(
                x: -(presentation.bounds.minX
                     + presentation.anchorPoint.x * presentation.bounds.width),
                y: -(presentation.bounds.minY
                     + presentation.anchorPoint.y * presentation.bounds.height)
            )
            renderView(sub, into: c,
                       honorsMaskedCorners: honorsMaskedCorners)
            c.restore()
        }

        // CALayer draws its border ABOVE its contents and sublayers.
        renderBorder(of: v, bounds: bounds, radius: radius,
                     borderWidth: backingPresentation.borderWidth,
                     maskedCorners: corners, hardEdges: hardEdges, into: c)

        if adjustsColor {
            c.applyColorAdjustment(
                brightness: v._openUIKitBrightness,
                saturation: v._openUIKitSaturation
            )
        }
        if grouped { c.endTransparencyLayer() }
        if maskClip != nil { c.endTransparencyLayer() }
        c.restore()
    }

    // MARK: Explicit CALayer trees

    /// Render a standalone layer as the root of `CALayer.render(in:)`.
    /// Root placement is intentionally ignored; descendants use the normal
    /// position/bounds/anchor mapping.
    static func renderLayer(_ layer: CALayer, into c: Canvas,
                            honorsMaskedCorners: Bool = true) {
        guard !layer.isHidden else { return }
        let presentation = layer._presentationState(at: OpenUIKitRuntime.animationTime)
        let alpha = Swift.min(Swift.max(CGFloat(presentation.opacity), 0), 1)
        guard alpha > 0 else { return }

        var maskAlpha: CGFloat = 1
        var maskClip: Path?
        if let mask = layer.mask {
            guard let maskState = solidMaskPresentation(
                mask, honorsMaskedCorners: honorsMaskedCorners) else { return }
            maskAlpha = maskState.alpha
            maskClip = maskState.clip
        }

        c.save()
        if let maskClip {
            c.beginMaskedTransparencyLayer(alpha: maskAlpha, mask: maskClip)
        }
        if alpha < 1 { c.beginTransparencyLayer(alpha: alpha) }

        let bounds = presentation.bounds
        let corners = honorsMaskedCorners ? layer.maskedCorners : ._allKnown
        // The pure-Swift fallback can exactly alpha-mask with the Focus-used
        // solid rounded rectangle. Arbitrary alpha-mask layer trees are
        // handled by the CQuartz layers compositor (`QZLayerSetMask`).
        if layer.masksToBounds {
            c.clip(to: layerRoundedRect(bounds,
                                        cornerRadius: presentation.cornerRadius,
                                        maskedCorners: corners))
        }

        if let background = layer.backgroundColor, background.alpha > 0,
           !bounds.isEmpty {
            c.fill(layerRoundedRect(bounds,
                                    cornerRadius: presentation.cornerRadius,
                                    maskedCorners: corners),
                   color: background)
        }

        if let gradient = layer as? CAGradientLayer {
            c.save()
            c.clip(to: layerRoundedRect(bounds,
                                        cornerRadius: presentation.cornerRadius,
                                        maskedCorners: corners))
            renderGradientLayer(gradient, bounds: bounds,
                                locations: presentation.locations, into: c)
            c.restore()
        }

        renderSublayers(of: layer, into: c,
                        honorsMaskedCorners: honorsMaskedCorners)
        renderBorder(of: layer, bounds: bounds,
                     cornerRadius: presentation.cornerRadius,
                     borderWidth: presentation.borderWidth,
                     maskedCorners: corners, into: c)

        if alpha < 1 { c.endTransparencyLayer() }
        if maskClip != nil { c.endTransparencyLayer() }
        c.restore()
    }

    /// Presented alpha and geometry of the solid mask subset supported by
    /// the dependency-free renderer. Quartz handles arbitrary mask trees.
    private static func solidMaskPresentation(
        _ mask: CALayer,
        honorsMaskedCorners: Bool
    ) -> (alpha: CGFloat, clip: Path)? {
        precondition(mask._orderedSublayers.isEmpty,
                     "OpenUIKit's pure-Swift renderer supports only a solid CALayer mask")
        guard !mask.isHidden, let color = mask.backgroundColor else { return nil }
        let state = mask._presentationState(at: OpenUIKitRuntime.animationTime)
        let alpha = CGFloat(Swift.min(Swift.max(
            color.alpha * CGFloat(state.opacity), 0), 1))
        guard alpha > 0 else { return nil }
        let rect = CGRect(
            x: state.position.x - state.anchorPoint.x * state.bounds.width,
            y: state.position.y - state.anchorPoint.y * state.bounds.height,
            width: state.bounds.width, height: state.bounds.height)
        return (alpha, layerRoundedRect(rect, cornerRadius: state.cornerRadius,
                                        maskedCorners: honorsMaskedCorners
                                            ? mask.maskedCorners : ._allKnown))
    }

    /// Render children back-to-front in their array order.
    static func renderSublayers(of parent: CALayer, into c: Canvas,
                                honorsMaskedCorners: Bool = true) {
        for child in parent._orderedSublayers {
            c.save()
            let presentation = child._presentationState(
                at: OpenUIKitRuntime.animationTime)
            let b = presentation.bounds
            c.translate(x: presentation.position.x, y: presentation.position.y)
            c.translate(x: -(b.minX + presentation.anchorPoint.x * b.width),
                        y: -(b.minY + presentation.anchorPoint.y * b.height))
            renderLayer(child, into: c,
                        honorsMaskedCorners: honorsMaskedCorners)
            c.restore()
        }
    }

    /// Axial CAGradientLayer drawing through the same Generic-RGB calibrated
    /// stop densification as UIGradientView.
    static func renderGradientLayer(_ layer: CAGradientLayer, bounds: CGRect,
                                    locations presentedLocations: [CGFloat]? = nil,
                                    into c: Canvas) {
        guard !bounds.isEmpty, let colors = layer.colors, colors.count >= 2 else { return }
        let n = colors.count
        let locations: [CGFloat]
        if let requested = presentedLocations ?? layer.locations,
           requested.count == n {
            locations = requested.map { Swift.min(Swift.max($0, 0), 1) }
        } else {
            locations = (0..<n).map { CGFloat($0) / CGFloat(n - 1) }
        }
        let (denseColors, denseLocations) = _CAGradientColorSpace.densify(
            colors: colors, locations: locations)
        c.save()
        c.translate(x: bounds.minX, y: bounds.minY)
        c.concatenate(CGAffineTransform(scaleX: bounds.width, y: bounds.height))
        c.drawLinearGradient(colors: denseColors, locations: denseLocations,
                             start: layer.startPoint, end: layer.endPoint,
                             in: CGRect(x: 0, y: 0, width: 1, height: 1))
        c.restore()
    }

    static func renderBorder(of layer: CALayer, bounds: CGRect,
                             cornerRadius: CGFloat? = nil,
                             borderWidth: CGFloat? = nil,
                             maskedCorners: CACornerMask? = nil,
                             into c: Canvas) {
        let width = borderWidth ?? layer.borderWidth
        guard width > 0, !bounds.isEmpty, let color = layer.borderColor,
              color.alpha > 0 else { return }
        let radius = cornerRadius ?? layer.cornerRadius
        let corners = maskedCorners ?? layer.maskedCorners
        let outer = layerRoundedRect(bounds, cornerRadius: radius,
                                     maskedCorners: corners)
        let innerRect = bounds.insetBy(dx: width, dy: width)
        if !innerRect.isNull, innerRect.width > 0, innerRect.height > 0 {
            var ring = outer
            ring.elements += layerRoundedRect(
                innerRect,
                cornerRadius: Swift.max(0, radius - width),
                maskedCorners: corners).elements
            c.fill(ring, color: color, evenOdd: true)
        } else {
            c.fill(outer, color: color)
        }
    }

    /// Effective shadow parameters for `v`, or nil when no shadow is
    /// visible. `color` carries shadowColor.alpha × shadowOpacity; `blur`
    /// is the Canvas blur (2 × shadowRadius → sigma = shadowRadius points).
    static func shadowParams(
        of v: UIView,
        bounds: CGRect,
        presentation: _CALayerPresentationState
    )
        -> (color: CGColor, offset: CGSize, blur: CGFloat)? {
        let l = v.layer
        guard presentation.shadowOpacity > 0,
              !l.masksToBounds, !bounds.isEmpty,
              let sc = l.shadowColor else { return nil }
        let opacity = CGFloat(min(max(presentation.shadowOpacity, 0), 1))
        let color = sc.withAlpha(opacity)
        guard color.alpha > 0 else { return nil }
        return (color, presentation.shadowOffset,
                2 * presentation.shadowRadius)
    }

    /// The shadow-casting silhouette of `v`'s layer: the outer rounded rect
    /// when the background is visible, else the border ring, else nil.
    static func shadowSilhouette(of v: UIView, bounds: CGRect,
                                 radius: CGFloat,
                                 borderWidth: CGFloat,
                                 maskedCorners corners: CACornerMask)
        -> (path: Path, evenOdd: Bool)? {
        guard !bounds.isEmpty else { return nil }
        if let bg = v.backgroundColor,
           bg.resolvedCGColor(with: v.traitCollection).alpha > 0 {
            return (layerRoundedRect(bounds, cornerRadius: radius,
                                     maskedCorners: corners), false)
        }
        let bw = borderWidth
        if bw > 0, let bc = v.layer.borderColor, bc.alpha > 0 {
            let innerRect = bounds.insetBy(dx: bw, dy: bw)
            if !innerRect.isNull && innerRect.width > 0 && innerRect.height > 0 {
                var ring = layerRoundedRect(bounds, cornerRadius: radius,
                                            maskedCorners: corners)
                ring.elements += layerRoundedRect(
                    innerRect, cornerRadius: Swift.max(0, radius - bw),
                    maskedCorners: corners).elements
                return (ring, true)
            }
            return (layerRoundedRect(bounds, cornerRadius: radius,
                                     maskedCorners: corners), false)
        }
        return nil
    }

    static func renderBorder(of v: UIView, bounds: CGRect, radius: CGFloat,
                             borderWidth: CGFloat,
                             maskedCorners corners: CACornerMask,
                             hardEdges: Bool, into c: Canvas) {
        let bw = borderWidth
        guard bw > 0, !bounds.isEmpty, let bc = v.layer.borderColor, bc.alpha > 0
        else { return }
        let outer = layerRoundedRect(bounds, cornerRadius: radius,
                                     maskedCorners: corners)
        let innerRect = bounds.insetBy(dx: bw, dy: bw)
        if !innerRect.isNull && innerRect.width > 0 && innerRect.height > 0 {
            // Even-odd ring between the outer rounded rect and the inner one
            // (inner corner radius shrinks by the border width, floored at 0).
            let innerRadius = Swift.max(0, radius - bw)
            var ring = outer
            ring.elements += layerRoundedRect(innerRect, cornerRadius: innerRadius,
                                               maskedCorners: corners).elements
            c.fill(ring, color: bc, evenOdd: true, hardEdges: hardEdges)
        } else {
            // Border consumes the whole bounds.
            c.fill(outer, color: bc, hardEdges: hardEdges)
        }
    }
}
