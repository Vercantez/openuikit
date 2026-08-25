// LayerBridge — M5: render a laid-out UIView tree through quartz's REAL
// CALayer compositor (QZLayer) instead of the hand-written RenderPass
// traversal. Owner: view module (caching: quartz-backend module, M8 perf).
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
//
// M8 layer-contents caching (docs/APP_FEEL.md "Performance"): rendering is
// CPU-side, so a sustained scroll used to re-rasterize every glyph, icon
// path and rounded rect at every vsync. Two caches, both keyed by VISUAL
// FINGERPRINTS recomputed each frame (pull-based — no invalidation wiring;
// a fingerprint miss simply re-renders):
//
//   1. Content-image cache: each view's drawContent offscreen result is
//      kept on the view and reused while its content fingerprint (class-
//      specific properties, size, scale, traits, contentVersion) is
//      unchanged. Custom views outside OpenUIKit must call
//      setNeedsDisplay() when their drawContent inputs change (UIKit's own
//      contract) — that bumps contentVersion.
//
//   2. Subtree composite cache: a subtree whose fingerprint has been
//      STABLE for two consecutive frames is flattened once into a
//      premultiplied composite image (rendered by this same bridge into an
//      offscreen QZ context) and composited as a single contents layer
//      until its fingerprint changes. Scrolling then recomposites cached
//      card/screen images instead of re-rendering them; premultiplied
//      source-over is associative, so flatten-then-composite matches
//      direct rendering. Anything animating salts its ancestors'
//      fingerprints (never stable, never cached, zero overhead beyond the
//      hash); a cached view's OWN position/alpha/translation animations
//      stay live — they are applied to the composite layer, which is how
//      navigation slide transitions become two image blits.
//      Composite blits are snapped to the device-pixel grid when the
//      accumulated ancestor translation is known (<= half-pixel nudge), so
//      they hit the compositor's 1-tap unit-scale image path.
//
//   Offscreen (culling): children whose conservative paint extent lies
//   fully outside the visible rect are skipped (the off-viewport half of a
//   scrolling list costs nothing). Extents/culling are bypassed for
//   subtrees with active placement animations (model != presentation).
//
// Single-frame renders (openrender's golden pipeline builds a fresh tree
// per scene) never reach two stable frames, so the subtree cache cannot
// change golden output; the content cache renders identically on first use.

import CQuartz

@MainActor
public enum LayerBridge {
    // MARK: Entry

    /// Monotone per-render stamp; memoizes the per-view analysis pass.
    static var frameStamp: UInt64 = 0

    /// Debug counters (perf tuning; reset/read by hosts as needed).
    public static var debugCompositeHits = 0
    public static var debugCompositeBuilds = 0
    public static var debugDirectLayers = 0

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

        frameStamp &+= 1

        // Flip: QZ user space (y-up, device px) -> top-down point space at
        // `scale` px/pt (same mapping as QuartzBackend).
        QZContextTranslateCTM(ctx, 0, QZFloat(h))
        QZContextScaleCTM(ctx, QZFloat(scale), -QZFloat(scale))

        var arena = Arena()
        defer { arena.releaseAll() }
        guard let rootLayer = buildLayer(for: root, scale: scale, arena: &arena,
                                         visible: root.bounds,
                                         acc: CGPoint(x: -root.bounds.minX,
                                                      y: -root.bounds.minY),
                                         isRenderRoot: true)
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

    /// Owns a QZImage across frames (cache storage on UIView).
    final class QZImageBox {
        let ref: QZImageRef
        init(_ ref: QZImageRef) { self.ref = ref }
        deinit { QZImageRelease(ref) }
    }

    struct Arena {
        var layers: [QZLayerRef] = []
        /// Cached images referenced by this frame's layers. Boxes are owned
        /// by view cache state; retaining them here guarantees they outlive
        /// the layers even if a cache entry is replaced mid-build.
        var imageBoxes: [QZImageBox] = []
        mutating func track(_ l: QZLayerRef) -> QZLayerRef {
            layers.append(l)
            return l
        }
        mutating func releaseAll() {
            for l in layers { QZLayerRelease(l) }
            layers.removeAll()
            imageBoxes.removeAll()
        }
    }

    // MARK: Per-view cache state

    final class LayerCacheState {
        // Analysis memo (recomputed once per frame).
        var analyzedFrame: UInt64 = 0
        var info = SubtreeInfo()
        // Fingerprint stability across frames (thrash guard).
        var lastFingerprint: UInt64 = 0
        var stableFrames: Int = 0
        // Subtree composite cache.
        var composite: QZImageBox?
        var compositeFingerprint: UInt64 = 0
        var compositeScale: CGFloat = 0
        var compositeExtent: CGRect = .zero
        // Content-image cache (drawContent offscreen result).
        var contentValid = false
        var contentKey: UInt64 = 0
        var contentImage: QZImageBox?   // nil with contentValid: transparent
        var contentExtent: CGRect = .zero
    }

    static func cacheState(of v: UIView) -> LayerCacheState {
        if let s = v._layerCacheState as? LayerCacheState { return s }
        let s = LayerCacheState()
        v._layerCacheState = s
        return s
    }

    // MARK: Subtree analysis (fingerprint + extent + animation flags)

    struct SubtreeInfo {
        /// Visual fingerprint of the subtree EXCLUDING the root's own
        /// placement (center / translation / alpha) — moving or fading a
        /// subtree must not invalidate its composite.
        var fingerprint: UInt64 = 0
        /// Conservative paint extent in the view's bounds coordinates
        /// (background, shadow spill, drawContent spill, children),
        /// snapped OUT to the device grid.
        var extent: CGRect = .zero
        /// The view itself has an active position/alpha/translation
        /// animation (presentation != model; applied at composite time).
        var selfPlacementAnimated = false
        /// Any view in the subtree (incl. root) has an active placement
        /// animation — extents/culling are unreliable, flattening illegal.
        var subtreePlacementAnimated = false
        /// Any descendant transform is not a pure translation.
        var hasNonTranslationTransform = false
        var viewCount: Int = 1
    }

    static func analyze(_ v: UIView, scale: CGFloat) -> SubtreeInfo {
        let state = cacheState(of: v)
        if state.analyzedFrame == frameStamp { return state.info }

        var h = Hasher()
        let now = OpenUIKitRuntime.animationTime
        var info = SubtreeInfo()

        h.combine(ObjectIdentifier(type(of: v)))
        let b = v.bounds
        h.combine(b.minX); h.combine(b.minY)
        h.combine(b.width); h.combine(b.height)
        h.combine(v.clipsToBounds)

        let lay = v.layer
        h.combine(lay.cornerRadius)
        let traits = v.traitCollection
        if let bg = v.backgroundColor {
            combine(&h, bg.resolvedCGColor(with: traits))
        } else {
            h.combine(false)
        }
        if lay.borderWidth > 0, let bc = lay.borderColor {
            h.combine(lay.borderWidth)
            combine(&h, bc)
        }

        // Shadow (and its spill for the extent).
        var extent = b
        var shadowVisible = false
        if lay.shadowOpacity > 0, !lay.masksToBounds, !b.isEmpty,
           let sc = lay.shadowColor, sc.alpha > 0 {
            shadowVisible = true
            h.combine(lay.shadowOpacity)
            h.combine(lay.shadowRadius)
            h.combine(lay.shadowOffset.width); h.combine(lay.shadowOffset.height)
            combine(&h, sc)
            let spill = 3 * lay.shadowRadius
            extent = extent.union(
                b.offsetBy(dx: lay.shadowOffset.width, dy: lay.shadowOffset.height)
                 .insetBy(dx: -spill, dy: -spill))
        }
        _ = shadowVisible

        // Class-specific content fingerprint (drawContent inputs).
        contentFingerprint(of: v, traits: traits, now: now, into: &h)
        h.combine(v.contentVersion)

        if let ce = contentExtent(of: v, scale: scale) {
            extent = extent.union(ce)
        }

        // Active animations. Placement properties (position / alpha / pure-
        // translation transform) stay live on a composite layer; anything
        // else salts the fingerprint so the subtree reads as "changing".
        for a in v.animations where now < a.begin + a.delay + a.duration {
            switch a.property {
            case .position, .alpha:
                info.selfPlacementAnimated = true
            case .transform:
                if case let (.transform(t0), .transform(t1)) = (a.from, a.to),
                   isTranslationOnly(t0), isTranslationOnly(t1) {
                    info.selfPlacementAnimated = true
                } else {
                    h.combine(now.bitPattern)
                }
            default:
                h.combine(now.bitPattern)
            }
        }
        info.subtreePlacementAnimated = info.selfPlacementAnimated

        // Children: identity, placement and subtree fingerprints.
        for sub in v.subviews {
            if sub.isHidden { h.combine(true); continue }
            let ci = analyze(sub, scale: scale)
            info.viewCount += ci.viewCount
            h.combine(ci.fingerprint)
            h.combine(sub.center.x); h.combine(sub.center.y)
            h.combine(sub.alpha)
            let t = sub.transform
            if isTranslationOnly(t) {
                h.combine(t.tx); h.combine(t.ty)
            } else {
                h.combine(t.a); h.combine(t.b); h.combine(t.c); h.combine(t.d)
                h.combine(t.tx); h.combine(t.ty)
                info.hasNonTranslationTransform = true
            }
            if ci.hasNonTranslationTransform { info.hasNonTranslationTransform = true }
            if ci.subtreePlacementAnimated {
                info.subtreePlacementAnimated = true
                // A child moving INSIDE this subtree changes its pixels.
                h.combine(now.bitPattern)
            }
            if !v.clipsToBounds {
                // Child extent in our bounds coordinates (translation only;
                // transformed children are rare and flagged above — take
                // the transformed bbox conservatively).
                var ce = ci.extent
                if !isTranslationOnly(t) {
                    ce = bbox(of: ce, transform: t, about: CGPoint(x: ce.midX, y: ce.midY))
                }
                extent = extent.union(ce.offsetBy(
                    dx: sub.center.x + t.tx - sub.bounds.midX,
                    dy: sub.center.y + t.ty - sub.bounds.midY))
            }
        }

        if v.clipsToBounds { extent = b }
        info.extent = snapOut(extent, scale: scale)
        info.fingerprint = UInt64(bitPattern: Int64(h.finalize()))

        // Stability tracking + composite invalidation.
        if state.lastFingerprint == info.fingerprint {
            state.stableFrames = min(state.stableFrames + 1, 1_000_000)
        } else {
            state.lastFingerprint = info.fingerprint
            state.stableFrames = 0
        }
        if state.composite != nil,
           state.compositeFingerprint != info.fingerprint {
            state.composite = nil
        }

        state.info = info
        state.analyzedFrame = frameStamp
        return info
    }

    static func isTranslationOnly(_ t: CGAffineTransform) -> Bool {
        t.a == 1 && t.b == 0 && t.c == 0 && t.d == 1
    }

    static func combine(_ h: inout Hasher, _ c: CGColor) {
        h.combine(c.red); h.combine(c.green); h.combine(c.blue); h.combine(c.alpha)
    }

    /// BBox of `r` under `t` applied about `anchor`.
    static func bbox(of r: CGRect, transform t: CGAffineTransform,
                     about anchor: CGPoint) -> CGRect {
        var minX = CGFloat.infinity, minY = CGFloat.infinity
        var maxX = -CGFloat.infinity, maxY = -CGFloat.infinity
        for p in [CGPoint(x: r.minX, y: r.minY), CGPoint(x: r.maxX, y: r.minY),
                  CGPoint(x: r.minX, y: r.maxY), CGPoint(x: r.maxX, y: r.maxY)] {
            let rel = CGPoint(x: p.x - anchor.x, y: p.y - anchor.y)
            let q = CGPoint(x: rel.x * t.a + rel.y * t.c + anchor.x,
                            y: rel.x * t.b + rel.y * t.d + anchor.y)
            minX = min(minX, q.x); maxX = max(maxX, q.x)
            minY = min(minY, q.y); maxY = max(maxY, q.y)
        }
        guard minX <= maxX else { return r }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    /// Hash the class-specific inputs of `drawContent`. OpenUIKit's own
    /// content views are covered here property-by-property; unknown classes
    /// rely on `contentVersion` (setNeedsDisplay) plus generic geometry.
    static func contentFingerprint(of v: UIView, traits: UITraitCollection,
                                   now: Double, into h: inout Hasher) {
        h.combine(traits.userInterfaceStyle)
        switch v {
        case let label as UILabel:
            h.combine(label.text)
            h.combine(label.font.pointSize)
            h.combine(label.font.weight)
            h.combine(label.font.design)
            combine(&h, label.textColor.resolvedCGColor(with: traits))
            h.combine(label.textAlignment)
            h.combine(label.numberOfLines)
            h.combine(label.lineBreakMode)
        case let iv as UIImageView:
            if let img = iv.image { h.combine(ObjectIdentifier(img)) }
            h.combine(iv.contentMode)
        case let sw as UISwitch:
            h.combine(sw.isOn)
            if let tint = sw.onTintColor {
                combine(&h, tint.resolvedCGColor(with: traits))
            }
            if let anim = sw.toggleAnim,
               now - anim.start < UISwitch.onTrackDuration + 0.05 {
                h.combine(now.bitPattern)   // chrome animating: never stable
            }
        case let pv as UIProgressView:
            h.combine(pv.progress)
            combine(&h, (pv.progressTintColor ?? pv.tintColor).resolvedCGColor(with: traits))
            combine(&h, (pv.trackTintColor ?? UIColor.systemFill).resolvedCGColor(with: traits))
        default:
            break
        }
        if let control = v as? UIControl {
            h.combine(control.isEnabled)
            h.combine(control.isSelected)
            h.combine(control.isHighlighted)
        }
    }

    // MARK: Tree construction

    static func buildLayer(for v: UIView, scale: CGFloat,
                           arena: inout Arena,
                           visible: CGRect? = nil,
                           acc: CGPoint? = nil,
                           isRenderRoot: Bool = false) -> QZLayerRef? {
        // Subtree composite fast path (never for the render root: the host
        // skips fully static frames anyway, and whole-window composites
        // would double frame memory for nothing).
        if OpenUIKitRuntime.layerCaching, !isRenderRoot, !v.isHidden {
            let info = analyze(v, scale: scale)
            if let l = compositeLayer(for: v, info: info, scale: scale,
                                      arena: &arena, acc: acc) {
                return l
            }
        }

        Self.debugDirectLayers += 1
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

        // M6: presentation override — sample the view's recorded animations
        // at the animation clock and overwrite the animated fields
        // (position/bounds/opacity/cornerRadius/backgroundColor/transform).
        var eff = t
        if !v.animations.isEmpty {
            eff = applyPresentation(to: l, view: v, traits: traits,
                                    at: OpenUIKitRuntime.animationTime)
        }

        // UIKit does not anti-alias the edges of transformed (rotated /
        // scaled) layers — same rule as RenderPass.isAxisAlignedTranslationOnly.
        // During animations the PRESENTATION transform decides.
        if !(eff.a == 1 && eff.b == 0 && eff.c == 0 && eff.d == 1) {
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

        // Children clip to our bounds when masksToBounds is set.
        var childScope = visible
        if v.clipsToBounds, let vis = childScope {
            childScope = vis.intersection(b)
        }

        for sub in v.subviews {
            var childVisible: CGRect? = nil
            var childAcc: CGPoint? = nil
            let st = sub.transform
            let subStatic = isTranslationOnly(st) && !sub.isHidden
            if OpenUIKitRuntime.layerCaching, subStatic {
                let ci = analyze(sub, scale: scale)
                let delta = CGPoint(x: sub.center.x + st.tx - sub.bounds.midX,
                                    y: sub.center.y + st.ty - sub.bounds.midY)
                if !ci.subtreePlacementAnimated {
                    if let vis = childScope {
                        // Offscreen culling: skip children that cannot paint
                        // inside the visible rect.
                        let extInParent = ci.extent.offsetBy(dx: delta.x, dy: delta.y)
                        if !extInParent.intersects(vis) { continue }
                        childVisible = vis.offsetBy(dx: -delta.x, dy: -delta.y)
                    }
                    if !ci.selfPlacementAnimated, let a = acc {
                        childAcc = CGPoint(x: a.x + delta.x, y: a.y + delta.y)
                    }
                }
            }
            if let child = buildLayer(for: sub, scale: scale, arena: &arena,
                                      visible: childVisible, acc: childAcc) {
                QZLayerAddSublayer(l, child)
            }
        }
        return l
    }

    // MARK: Subtree composite cache

    /// Emit a single contents-image layer for `v`'s whole subtree when a
    /// valid composite exists (or its fingerprint has been stable long
    /// enough to build one). Returns nil to render the subtree directly.
    static func compositeLayer(for v: UIView, info: SubtreeInfo, scale: CGFloat,
                               arena: inout Arena, acc: CGPoint?) -> QZLayerRef? {
        let state = cacheState(of: v)
        // Eligibility.
        guard info.viewCount >= 2,
              !info.hasNonTranslationTransform,
              isTranslationOnly(v.transform)
        else { return nil }
        if info.subtreePlacementAnimated {
            // The root's OWN placement animation stays live on the composite
            // layer, but a moving DESCENDANT changes the flattened pixels.
            if !info.selfPlacementAnimated { return nil }
            for sub in v.subviews where !sub.isHidden {
                if analyze(sub, scale: scale).subtreePlacementAnimated { return nil }
            }
        }
        // Group-opacity + shadow flattening interact (shadow must not get
        // the content's alpha twice) — skip the rare combination.
        if v.alpha < 1, v.layer.shadowOpacity > 0, !v.clipsToBounds { return nil }

        let ext = info.extent
        let pw = Int((ext.width * scale).rounded())
        let ph = Int((ext.height * scale).rounded())
        guard pw > 0, ph > 0, pw * ph >= 4096, pw * ph <= 8_000_000
        else { return nil }

        // Cache lookup / build (thrash guard: only flatten after the
        // fingerprint has survived one full frame unchanged).
        let usable = state.composite != nil
            && state.compositeFingerprint == info.fingerprint
            && state.compositeScale == scale
            && state.compositeExtent == ext
        if !usable {
            guard state.stableFrames >= 1 else { return nil }
            guard let box = renderComposite(of: v, extent: ext, scale: scale,
                                            pixelW: pw, pixelH: ph)
            else { return nil }
            Self.debugCompositeBuilds += 1
            state.composite = box
            state.compositeFingerprint = info.fingerprint
            state.compositeScale = scale
            state.compositeExtent = ext
        }
        guard let box = state.composite else { return nil }
        Self.debugCompositeHits += 1

        // Presentation placement (position / alpha / translation).
        let now = OpenUIKitRuntime.animationTime
        var center = v.center
        var alpha = v.alpha
        var translation = CGPoint(x: v.transform.tx, y: v.transform.ty)
        if info.selfPlacementAnimated || !v.animations.isEmpty {
            for a in v.animations {
                let u = animationProgress(a, at: now)
                switch (a.property, a.from, a.to) {
                case (.position, .point(let p0), .point(let p1)):
                    center = CGPoint(x: lerp(p0.x, p1.x, u), y: lerp(p0.y, p1.y, u))
                case (.alpha, .scalar(let a0), .scalar(let a1)):
                    alpha = lerp(a0, a1, u)
                case (.transform, .transform(let t0), .transform(let t1)):
                    let m = UIViewTransformInterpolation.interpolate(t0, t1, u)
                    translation = CGPoint(x: m.tx, y: m.ty)
                default:
                    break
                }
            }
        }

        guard let raw = QZLayerCreate() else { return nil }
        let l = arena.track(raw)
        arena.imageBoxes.append(box)
        QZLayerSetBounds(l, QZRect(origin: QZPoint(x: 0, y: 0),
                                   size: QZSize(width: ext.width, height: ext.height)))
        var pos = CGPoint(x: center.x + translation.x + (ext.midX - v.bounds.midX),
                          y: center.y + translation.y + (ext.midY - v.bounds.midY))
        // Snap the blit to the device grid (static placement, known
        // accumulated translation): the composite then takes the 1-tap
        // unit-scale image path and stays pixel-exact vs direct rendering.
        if !info.selfPlacementAnimated, let a = acc {
            let devX = (a.x + pos.x - ext.width / 2) * scale
            let devY = (a.y + pos.y - ext.height / 2) * scale
            pos.x += (devX.rounded() - devX) / scale
            pos.y += (devY.rounded() - devY) / scale
        }
        QZLayerSetPosition(l, QZPoint(x: pos.x, y: pos.y))
        QZLayerSetOpacity(l, QZFloat(Swift.min(Swift.max(alpha, 0), 1)))
        QZLayerSetContents(l, box.ref)
        return l
    }

    /// Flatten `v`'s subtree into a premultiplied composite image by running
    /// this same bridge into an offscreen context covering `extent`.
    static func renderComposite(of v: UIView, extent: CGRect, scale: CGFloat,
                                pixelW pw: Int, pixelH ph: Int) -> QZImageBox? {
        guard let ctx = QZBitmapContextCreate(nil, pw, ph, 8, pw * 4, 1)
        else { return nil }
        defer { QZContextRelease(ctx) }
        QZContextTranslateCTM(ctx, 0, QZFloat(ph))
        QZContextScaleCTM(ctx, QZFloat(scale), -QZFloat(scale))
        QZContextTranslateCTM(ctx, QZFloat(-extent.minX), QZFloat(-extent.minY))

        var arena = Arena()
        defer { arena.releaseAll() }
        guard let root = buildLayer(for: v, scale: scale, arena: &arena,
                                    visible: extent,
                                    acc: CGPoint(x: -extent.minX, y: -extent.minY),
                                    isRenderRoot: true)
        else { return nil }
        // Neutralize root placement (applied at composite time); opacity is
        // applied on the composite layer so the flattened content stays
        // full-intensity (group-alpha semantics).
        QZLayerSetAffineTransform(root, QZAffineTransformIdentity())
        QZLayerSetPosition(root, QZPoint(x: v.bounds.midX, y: v.bounds.midY))
        QZLayerSetOpacity(root, 1)
        QZLayerRenderInContext(root, ctx)

        // Rows flipped: the top-down backing must feed QZContextDrawImage
        // bottom-up to land upright under the top-down flip CTM (same
        // reason contentLayer flips) — premultiplied preserved.
        guard let img = QZBitmapContextCreateImageRowsFlipped(ctx) else { return nil }
        return QZImageBox(img)
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

    // MARK: Presentation sampling (M6 animations)

    static func lerp(_ a: CGFloat, _ b: CGFloat, _ u: CGFloat) -> CGFloat {
        a + (b - a) * u
    }

    /// Eased progress (springs may overshoot past 1) of `a` at animation-
    /// clock time `t`. Quartz's animation/timing engine evaluates the
    /// timing math: cubic beziers through QZMediaTimingFunctionSolve (the
    /// same Newton+bisection x(t) solve Core Animation uses) and springs
    /// through a scratch QZSpringAnimation sampled with
    /// QZLayerCopyPresentation, parameterized with the UIKit duration-fit
    /// model (UIViewSpring.naturalFrequency). Delay uses UIKit's frozen-
    /// clock fill semantics: FROM before `delay`, MODEL at
    /// `delay + duration` and later (CA removes completed animations).
    static func animationProgress(_ a: UIViewAnimation, at t: Double) -> CGFloat {
        let local = t - a.begin - a.delay
        if local <= 0 { return 0 }
        if local >= a.duration - 1e-9 { return 1 }
        switch a.timing {
        case .curve(let c1x, let c1y, let c2x, let c2y):
            guard let fn = QZMediaTimingFunctionCreateWithControlPoints(
                QZFloat(c1x), QZFloat(c1y), QZFloat(c2x), QZFloat(c2y))
            else { return 1 }
            defer { QZMediaTimingFunctionRelease(fn) }
            return CGFloat(QZMediaTimingFunctionSolve(fn, QZFloat(local / a.duration)))
        case .spring(let damping, let velocity):
            let z = Swift.min(Swift.max(Double(damping), 1e-6), 1)
            let wn = UIViewSpring.naturalFrequency(dampingRatio: damping,
                                                   initialVelocity: velocity,
                                                   duration: a.duration)
            guard let scratch = QZLayerCreate(),
                  let anim = QZSpringAnimationCreate("opacity") else { return 1 }
            defer { QZLayerRelease(scratch) }
            // Normalized 1 -> 0: the sampled opacity IS the remaining-
            // fraction envelope e(local); progress = 1 - e.
            var from: [QZFloat] = [1]
            var to: [QZFloat] = [0]
            QZBasicAnimationSetFromValue(anim, &from, 1)
            QZBasicAnimationSetToValue(anim, &to, 1)
            QZAnimationSetDuration(anim, QZFloat(a.duration))
            QZSpringAnimationSetMass(anim, 1)
            QZSpringAnimationSetStiffness(anim, QZFloat(wn * wn))
            QZSpringAnimationSetDamping(anim, QZFloat(2 * z * wn))
            // quartz normalizes v0 by (from - to) = 1 here; UIKit's
            // initialVelocity v means e'(0) = -v.
            QZSpringAnimationSetInitialVelocity(anim, QZFloat(-Double(velocity)))
            QZLayerAddAnimation(scratch, anim, "progress")
            QZAnimationRelease(anim)
            guard let pres = QZLayerCopyPresentation(scratch, QZFloat(local))
            else { return 1 }
            defer { QZLayerRelease(pres) }
            return 1 - CGFloat(QZLayerGetOpacity(pres))
        }
    }

    /// Overwrite `l`'s animated fields with presentation values sampled at
    /// animation-clock time `t`. Returns the effective (presentation)
    /// transform for the edge-antialias rule. Value application: geometry /
    /// opacity / cornerRadius lerp componentwise; backgroundColor lerps in
    /// extended-sRGB component space (unclamped, nil = transparent);
    /// transform interpolates via CA-style decomposition
    /// (UIViewTransformInterpolation). Split rationale: quartz's animation
    /// engine owns all TIMING evaluation (above), while value application
    /// stays here because CA semantics quartz's value model lacks are
    /// needed: per-animation delay fill, exact model snap at completion,
    /// color-space lerp and affine decomposition.
    static func applyPresentation(to l: QZLayerRef, view v: UIView,
                                  traits: UITraitCollection,
                                  at t: Double) -> CGAffineTransform {
        var eff = v.transform
        for a in v.animations {
            let u = animationProgress(a, at: t)
            switch (a.property, a.from, a.to) {
            case (.position, .point(let p0), .point(let p1)):
                QZLayerSetPosition(l, QZPoint(x: lerp(p0.x, p1.x, u),
                                              y: lerp(p0.y, p1.y, u)))
            case (.bounds, .rect(let r0), .rect(let r1)):
                QZLayerSetBounds(l, QZRect(
                    origin: QZPoint(x: lerp(r0.minX, r1.minX, u),
                                    y: lerp(r0.minY, r1.minY, u)),
                    size: QZSize(width: lerp(r0.width, r1.width, u),
                                 height: lerp(r0.height, r1.height, u))))
            case (.alpha, .scalar(let a0), .scalar(let a1)):
                let val = lerp(a0, a1, u)
                QZLayerSetOpacity(l, QZFloat(Swift.min(Swift.max(val, 0), 1)))
            case (.cornerRadius, .scalar(let r0), .scalar(let r1)):
                QZLayerSetCornerRadius(l, QZFloat(lerp(r0, r1, u)))
            case (.backgroundColor, .color(let c0), .color(let c1)):
                let clear = CGColor(red: 0, green: 0, blue: 0, alpha: 0)
                let f = c0?.resolvedCGColor(with: traits) ?? clear
                let g = c1?.resolvedCGColor(with: traits) ?? clear
                QZLayerSetBackgroundColor(l, QZFloat(lerp(f.red, g.red, u)),
                                          QZFloat(lerp(f.green, g.green, u)),
                                          QZFloat(lerp(f.blue, g.blue, u)),
                                          QZFloat(lerp(f.alpha, g.alpha, u)))
            case (.transform, .transform(let m0), .transform(let m1)):
                eff = UIViewTransformInterpolation.interpolate(m0, m1, u)
                QZLayerSetAffineTransform(l, QZAffineTransform(
                    a: eff.a, b: eff.b, c: eff.c, d: eff.d,
                    tx: eff.tx, ty: eff.ty))
            default:
                break // mismatched value shape: ignore (cannot happen)
            }
        }
        return eff
    }

    // MARK: Content (drawContent -> contents image sublayer)

    /// Extent of `v`'s custom content in bounds coordinates, or nil when the
    /// view draws none. Snapped OUT to the device-pixel grid RELATIVE to the
    /// bounds origin (drawContent output is a function of the bounds SIZE;
    /// keying and snapping relative keeps the cache stable and the offscreen
    /// grid-aligned when an ancestor — e.g. a scroll view — shifts its
    /// bounds origin fractionally).
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
        let rel = snapOut(raw.offsetBy(dx: -b.minX, dy: -b.minY), scale: scale)
        return rel.offsetBy(dx: b.minX, dy: b.minY)
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
    /// The offscreen result is cached on the view and reused while the
    /// view's content fingerprint is unchanged (M8).
    static func contentLayer(for v: UIView, scale: CGFloat,
                             arena: inout Arena) -> QZLayerRef? {
        guard let extent = contentExtent(of: v, scale: scale) else { return nil }
        let pw = Int((extent.width * scale).rounded())
        let ph = Int((extent.height * scale).rounded())
        guard pw > 0, ph > 0 else { return nil }

        let state = cacheState(of: v)
        var key: UInt64 = 0
        if OpenUIKitRuntime.layerCaching {
            var h = Hasher()
            contentFingerprint(of: v, traits: v.traitCollection,
                               now: OpenUIKitRuntime.animationTime, into: &h)
            h.combine(v.contentVersion)
            h.combine(scale)
            // Key on the bounds-RELATIVE extent (drawContent draws in
            // bounds-relative coordinates; absolute origin shifts must not
            // invalidate — see contentExtent).
            h.combine(extent.minX - v.bounds.minX)
            h.combine(extent.minY - v.bounds.minY)
            h.combine(extent.width); h.combine(extent.height)
            h.combine(v.bounds.width); h.combine(v.bounds.height)
            key = UInt64(bitPattern: Int64(h.finalize()))
            if state.contentValid, state.contentKey == key,
               state.contentExtent.size == extent.size {
                guard let box = state.contentImage else { return nil }
                arena.imageBoxes.append(box)
                return wrapContents(box, extent: extent, arena: &arena)
            }
        }

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
        guard any else {
            if OpenUIKitRuntime.layerCaching {
                state.contentValid = true
                state.contentKey = key
                state.contentImage = nil
                state.contentExtent = extent
            }
            return nil
        }

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
        let box = QZImageBox(img)
        arena.imageBoxes.append(box)
        if OpenUIKitRuntime.layerCaching {
            state.contentValid = true
            state.contentKey = key
            state.contentImage = box
            state.contentExtent = extent
        }
        return wrapContents(box, extent: extent, arena: &arena)
    }

    static func wrapContents(_ box: QZImageBox, extent: CGRect,
                             arena: inout Arena) -> QZLayerRef? {
        guard let raw = QZLayerCreate() else { return nil }
        let l = arena.track(raw)
        QZLayerSetBounds(l, QZRect(origin: QZPoint(x: 0, y: 0),
                                   size: QZSize(width: extent.width,
                                                height: extent.height)))
        QZLayerSetPosition(l, QZPoint(x: extent.midX, y: extent.midY))
        QZLayerSetContents(l, box.ref)
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

// Hashable synthesis for the fingerprint pass (enums without associated
// values / payloads used as cache-key components).
extension NSTextAlignment: Hashable {}
extension NSLineBreakMode: Hashable {}
extension UIFont.Weight: Hashable {}
extension UIFont.Design: Hashable {}
extension UIViewContentMode: Hashable {}
extension UIUserInterfaceStyle: Hashable {}
