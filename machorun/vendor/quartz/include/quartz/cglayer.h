/* OWNED BY package cglayer. Do not edit from other packages. */
#ifndef QUARTZ_CGLAYER_H
#define QUARTZ_CGLAYER_H
#ifdef __cplusplus
extern "C" {
#endif

typedef struct QZCGLayer *QZCGLayerRef;

QZCGLayerRef QZCGLayerCreateWithContext(QZContextRef ctx, QZSize size);
void QZCGLayerRelease(QZCGLayerRef layer);
QZContextRef QZCGLayerGetContext(QZCGLayerRef layer);
QZSize QZCGLayerGetSize(QZCGLayerRef layer);
void QZContextDrawLayerAtPoint(QZContextRef ctx, QZPoint point, QZCGLayerRef layer);
void QZContextDrawLayerInRect(QZContextRef ctx, QZRect rect, QZCGLayerRef layer);

#ifdef __cplusplus
}
#endif
#endif
