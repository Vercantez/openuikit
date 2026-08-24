# Vendored quartz patches (patches/quartz/)

`Sources/CQuartz` is an exact mirror of `~/quartz` (scripts/sync_quartz.sh)
**plus** the minimal patches below, applied by the sync script after rsync
(`git apply`, lexical order — each patch is generated on top of the previous
ones). They exist because M5 renders through quartz's real QZLayer
compositor (`QZLayerRenderInContext`), and a few CoreAnimation behaviors the
golden suite pins down were missing upstream. Each entry states the
upstream-suggested fix so the patches can be retired by adopting them in
`~/quartz`.

Never edit `Sources/CQuartz` without regenerating the corresponding patch;
re-running `scripts/sync_quartz.sh` reapplies exactly these patches.

## 001-layer-unclamped-corner-radius.patch

`src/qz_layer.cpp` — `rounded_or_rect()` (the layer background / clip /
gradient-clip / silhouette path builder) clamped `cornerRadius` to half the
smaller side via `QZContextAddRoundedRect`. iOS 26 CoreAnimation does NOT
clamp: an oversized radius produces the self-intersecting kappa rounded rect
(spikes past the corners, four-pointed star hole under non-zero winding)
drawn outside the bounds — see `golden/corner_radius.png` (80x60 view,
cornerRadius 100). The patch builds the unclamped kappa construction
directly when `radius > min(w,h)/2`; below that it is byte-identical to the
old path.

Upstream fix: apply the same unclamped construction in
`rounded_or_rect` (layer paths only — `QZPathAddRoundedRect`/CG semantics
should keep clamping, matching CGPath).

## 002-layer-edge-antialias.patch

`src/qz_internal.hpp`, `include/quartz/layer_ext.h`,
`src/pkg_layer_ext.cpp`, `src/qz_layer.cpp` — adds
`QZLayerSetEdgeAntialias(layer, bool)` (CALayer.allowsEdgeAntialiasing).
When false, the layer's background fill and border are rasterized with
anti-aliasing off (QZ's non-AA rasterizer thresholds at pixel centers).
iOS composites transformed (rotated/scaled) layers with hard edges — see
`golden/transforms.png`; the bridge sets this for any view whose own
transform is not a pure translation. Default `true` preserves historical QZ
behavior for existing users.

Upstream fix: adopt the field + setter as-is; consider defaulting to
CA-accurate `false` once quartz's own harness accounts for it.

## 003-layer-ca-shadow-semantics.patch

`src/qz_layer.cpp` — reworks the layer shadow in `render_layer()` to match
CoreAnimation (verified against golden/shadows_*, alpha_shadow_group):

- **Blur scaling**: CA `shadowRadius` is a Gaussian sigma in layer units;
  QZ's context shadow blur parameter is device pixels with sigma = blur/2.
  The patch passes `2 * radius * sqrt(|det CTM|)` instead of the raw radius
  (which was interpreted as device px and rendered ~4x too tight at 2x).
- **Group opacity ordering**: with `opacity < 1` CA composites the shadow
  onto the destination BENEATH the whole opacity group (it is never
  occluded by the layer's own content and shows through a translucent
  layer) at strength `shadowOpacity * opacity`. The patch draws the
  shadow-only silhouette (zero-alpha fill with the shadow state set) before
  `QZContextBeginTransparencyLayer`; previously the shadow rode the
  background fill inside the group and was hidden by opaque content.
- **Border-ring silhouette**: a layer with no visible background but a
  visible border casts the shadow of the border ring (previously: no shadow
  at all). Non-group case pre-draws the border with the shadow active (the
  normal border pass repaints the identical ring above sublayers); group
  case uses the even-odd outer/inner ring as the silhouette.
- **masksToBounds hides the shadow** (CA behavior), and no silhouette
  (no background, no border) means no shadow.

Upstream fix: adopt wholesale — the old behavior disagrees with CA in all
four aspects. `set_layer_shadow` / `add_shadow_silhouette` / `draw_border`
are self-contained statics in qz_layer.cpp.
