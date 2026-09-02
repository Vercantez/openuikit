/* OWNED BY package trans-rect. */
#ifndef QUARTZ_TRANS_RECT_H
#define QUARTZ_TRANS_RECT_H
#ifdef __cplusplus
extern "C" {
#endif

void QZContextBeginTransparencyLayerWithRect(QZContextRef ctx, QZRect rect);
void QZContextSetShadowWithColorQZ(QZContextRef ctx, QZSize offset, QZFloat blur, QZColorRef color);
void QZContextBeginTransparencyLayerWithInfo(QZContextRef ctx); /* alias of BeginTransparencyLayer */

#ifdef __cplusplus
}
#endif
#endif
