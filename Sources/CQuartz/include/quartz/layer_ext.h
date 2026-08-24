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
QZPoint QZLayerConvertPointToLayer(QZLayerRef from, QZPoint p, QZLayerRef to);
void QZLayerSetSublayerTransform(QZLayerRef layer, QZTransform3D t);

#ifdef __cplusplus
}
#endif
#endif
