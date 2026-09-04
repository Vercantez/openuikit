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
