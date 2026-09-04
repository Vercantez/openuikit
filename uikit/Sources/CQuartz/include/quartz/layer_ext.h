/* OWNED BY package layer-ext. Do not edit from other packages. */
#ifndef QUARTZ_LAYER_EXT_H
#define QUARTZ_LAYER_EXT_H

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
    kQZContentsGravityResize = 0,
    kQZContentsGravityResizeAspect,
    kQZContentsGravityResizeAspectFill,
    kQZContentsGravityCenter,
    kQZContentsGravityTop,
    kQZContentsGravityBottom,
    kQZContentsGravityLeft,
    kQZContentsGravityRight
} QZContentsGravity;

void QZLayerRemoveFromSuperlayer(QZLayerRef layer);
void QZLayerInsertSublayer(QZLayerRef layer, QZLayerRef child, int index);
void QZLayerSetMask(QZLayerRef layer, QZLayerRef mask);
void QZLayerSetContentsGravity(QZLayerRef layer, QZContentsGravity gravity);
void QZLayerSetContentsRect(QZLayerRef layer, QZRect rect);
void QZLayerSetContentsScale(QZLayerRef layer, QZFloat scale);
void QZLayerSetShadow(QZLayerRef layer, QZFloat ox, QZFloat oy, QZFloat radius,
                      QZFloat r, QZFloat g, QZFloat b, QZFloat opacity);
/* Four-bit CALayer.maskedCorners equivalent. Bits are minX/minY,
 * maxX/minY, minX/maxY, maxX/maxY; default 0xf. */
void QZLayerSetMaskedCorners(QZLayerRef layer, uint32_t corners);

/* How an OVERSIZED cornerRadius (> half the smaller side) renders.
 *   QZCornerModelKappa (0): the Mac oracle's self-intersecting kappa
 *     rounded-rect (spikes past the corners, star hole) — Catalyst.
 *   QZCornerModelDisc (1): iOS 26.1 — each rounded corner is a disc
 *     constraint (a point in the corner's quadrant must lie within the
 *     radius of the corner's centre), never clamped, so an oversized
 *     radius leaves the intersection of the corner discs (an 80 x 60
 *     layer with radius 100 is a 23 x 20 curved diamond).
 * Process-global; OpenUIKit sets it from its platform cut per render. */
enum { QZCornerModelKappa = 0, QZCornerModelDisc = 1 };
void QZLayerSetCornerModel(int model);
int QZLayerGetCornerModel(void);

/* Where a layer's shadow goes when the layer has GROUP OPACITY (< 1).
 *   QZGroupShadowBeneath (0): the Mac oracle — the shadow is composited
 *     onto the destination beneath the whole group at shadowOpacity *
 *     opacity, never occluded by the layer's own content (a 60 % white
 *     card shows its shadow through its interior).
 *   QZGroupShadowInside (1): iOS 26.1 (allowsGroupOpacity is on by
 *     default there) — the shadow is drawn INSIDE the group, occluded by
 *     the content, and the group's opacity scales what remains (the same
 *     card's interior is plain 60 % white: measured alpha_shadow_group).
 * Process-global, like the corner model. */
enum { QZGroupShadowBeneath = 0, QZGroupShadowInside = 1 };
void QZLayerSetGroupShadowModel(int model);
int QZLayerGetGroupShadowModel(void);

/* Where a layer whose device-space origin is FRACTIONAL renders.
 *   QZOriginSnapNone (0): at the exact position, edges anti-aliased.
 *   QZOriginSnapFloor (1): iOS 26.1 (MEASURED 2026-09-04 on the iPhone
 *     16 at 3x with views at every sixth-of-a-point offset): the layer's
 *     device origin is FLOORED to the pixel and its pixel size kept — a
 *     29 pt view at y 46.5 covers rows 138 ... 224 (half-pixel edges
 *     never anti-alias, sublayers inherit the shift); a rounded layer
 *     draws its path at the exact position clipped to that snapped
 *     store (top row 50 %, bottom row cut). Axis-aligned layers only. */
enum { QZOriginSnapNone = 0, QZOriginSnapFloor = 1 };
void QZLayerSetOriginSnapModel(int model);
int QZLayerGetOriginSnapModel(void);
/* CALayer.allowsEdgeAntialiasing: when false, the layer's background fill
 * and border are rasterized without edge anti-aliasing (hard 0/1 coverage
 * thresholded at pixel centers) — how iOS composites transformed layers.
 * Default true (anti-aliased edges). */
void QZLayerSetEdgeAntialias(QZLayerRef layer, bool antialias);
QZPoint QZLayerConvertPointToLayer(QZLayerRef from, QZPoint p, QZLayerRef to);
void QZLayerSetSublayerTransform(QZLayerRef layer, QZTransform3D t);

#ifdef __cplusplus
}
#endif
#endif
