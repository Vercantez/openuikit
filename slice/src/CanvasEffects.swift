// Additive Canvas APIs (scene-spec v2): layer shadows + linear gradients.
// Owner: view/effects work; extends the frozen Canvas contract ADDITIVELY
// (docs/ARCHITECTURE.md rule 3) — no existing signature changes.
//
// Shadow model (matches CoreGraphics/CoreAnimation):
// - `setShadow` stores shadow parameters in the graphics state; every
//   subsequent FILL composites a blurred, offset silhouette of the filled
//   shape BENEATH the fill itself (quartz does this natively in
//   fill_polylines; the Swift rasterizer mirrors it in RasterizerEffects).
// - `offset` is in user-space points, positive y = DOWN (Canvas's top-down
//   user space; verified against golden/shadows_basic offset [4,4] — the
//   shadow falls right+below). `blur` is in points; the rendered Gaussian
//   sigma is blur/2 * ctmScale device pixels (CG's blur semantics — both
//   backends approximate the Gaussian with the same 3x box blur).
// - The shadow is part of the saved state: `restore()` pops it, exactly like
//   CGContextSetShadow. `clearShadow()` removes it without a restore.
//
// Gradient model (matches CGGradient in an sRGB stop space):
// - Piecewise-linear interpolation of the gamma-encoded sRGB components
//   between adjacent stops; t clamps to the first/last stop color outside
//   [0, 1] (CG's draws-before/after-location options — the gradient fills
//   all of `rect`). CAGradientLayer's different interpolation colorspace is
//   handled ABOVE this API (UIGradientView densifies its stops).

/// Shadow parameters carried in the Canvas graphics state.
struct CanvasShadow {
    var color: CGColor    // straight-alpha sRGB; alpha is the shadow opacity
    var offset: CGSize    // user-space points, +y down
    var blur: CGFloat     // user-space points; sigma = blur/2 (Ã— ctm scale in device px)
}

extension Canvas {
    /// Set the layer shadow for subsequent fills. Cleared by `restore()`
    /// (state-stack semantics) or `clearShadow()`.
    public func setShadow(color: CGColor, offset: CGSize, blur: CGFloat) {
        state.shadow = CanvasShadow(color: color, offset: offset,
                                    blur: Swift.max(0, blur))
    }

    /// Remove the layer shadow.
    public func clearShadow() {
        state.shadow = nil
    }

    /// Draw ONLY the shadow of `path` (the blurred, offset, tinted
    /// silhouette) without filling the path itself, using the current
    /// shadow state. No-op when no shadow is set. Used by the render pass
    /// to composite a layer's shadow beneath a group-opacity transparency
    /// layer (CoreAnimation draws the shadow under the whole layer tree,
    /// NOT occluded by the layer content — golden/alpha_shadow_group).
    public func drawShadow(of path: Path, evenOdd: Bool = false) {
        guard let sh = state.shadow, sh.color.alpha > 0 else { return }
        backend.drawShadowOnly(path, evenOdd: evenOdd, sh)
    }

    /// Draw an axial (linear) gradient covering `rect` (user space).
    /// `colors[i]` sits at `locations[i]` (0–1, ascending); pixels project
    /// onto the start→end axis and interpolate linearly between adjacent
    /// stops in gamma-encoded sRGB, clamping to the end colors outside the
    /// axis span (the whole rect is always covered). `start`/`end` are in
    /// user space. Rect edges are anti-aliased like fills.
    public func drawLinearGradient(colors: [CGColor], locations: [CGFloat],
                                   start: CGPoint, end: CGPoint, in rect: CGRect) {
        guard !colors.isEmpty, colors.count == locations.count,
              !rect.isEmpty else { return }
        backend.drawLinearGradient(colors: colors, locations: locations,
                                   start: start, end: end, in: rect)
    }
}
