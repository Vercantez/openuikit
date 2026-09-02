/* OWNED BY package scroll-layer. */
#ifndef QUARTZ_SCROLL_LAYER_H
#define QUARTZ_SCROLL_LAYER_H
#ifdef __cplusplus
extern "C" {
#endif

QZLayerRef QZScrollLayerCreate(void);
void QZScrollLayerScrollToPoint(QZLayerRef layer, QZPoint p);
void QZScrollLayerScrollToRect(QZLayerRef layer, QZRect r);
QZPoint QZScrollLayerGetScrollOffset(QZLayerRef layer);

#ifdef __cplusplus
}
#endif
#endif
