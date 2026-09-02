/* OWNED BY package shape-stroke. */
#ifndef QUARTZ_SHAPE_STROKE_H
#define QUARTZ_SHAPE_STROKE_H
#ifdef __cplusplus
extern "C" {
#endif

void QZShapeLayerSetStrokeStart(QZLayerRef layer, QZFloat t);
void QZShapeLayerSetStrokeEnd(QZLayerRef layer, QZFloat t);
void QZShapeLayerSetMiterLimit(QZLayerRef layer, QZFloat limit);
void QZShapeLayerSetLineDash(QZLayerRef layer, QZFloat phase, const QZFloat *lengths, size_t count);

#ifdef __cplusplus
}
#endif
#endif
