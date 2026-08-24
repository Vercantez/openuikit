/* OWNED BY package gstate-get. Do not edit from other packages. */
#ifndef QUARTZ_GSTATE_GET_H
#define QUARTZ_GSTATE_GET_H
#ifdef __cplusplus
extern "C" {
#endif

QZFloat QZContextGetLineWidth(QZContextRef ctx);
QZLineCap QZContextGetLineCap(QZContextRef ctx);
QZLineJoin QZContextGetLineJoin(QZContextRef ctx);
QZFloat QZContextGetMiterLimit(QZContextRef ctx);
QZFloat QZContextGetAlpha(QZContextRef ctx);
QZBlendMode QZContextGetBlendMode(QZContextRef ctx);
QZInterpolationQuality QZContextGetInterpolationQuality(QZContextRef ctx);
bool QZContextGetShouldAntialias(QZContextRef ctx);
QZFloat QZContextGetFlatness(QZContextRef ctx);
void QZContextGetFillColor(QZContextRef ctx, QZFloat rgba[4]);
void QZContextGetStrokeColor(QZContextRef ctx, QZFloat rgba[4]);
void QZContextGetLineDash(QZContextRef ctx, QZFloat *phase, QZFloat *lengths, size_t *count);

#ifdef __cplusplus
}
#endif
#endif
