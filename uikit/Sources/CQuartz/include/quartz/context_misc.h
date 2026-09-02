/* OWNED BY package context-misc. */
#ifndef QUARTZ_CONTEXT_MISC_H
#define QUARTZ_CONTEXT_MISC_H
#ifdef __cplusplus
extern "C" {
#endif

void QZContextResetClip(QZContextRef ctx);
QZImageRef QZBitmapContextCreateImage(QZContextRef ctx);
/* Same snapshot with rows reversed (bottom-up), premultiplied preserved —
 * the orientation layer-contents need under a top-down flip CTM. */
QZImageRef QZBitmapContextCreateImageRowsFlipped(QZContextRef ctx);
void QZContextSetGrayFillColor(QZContextRef ctx, QZFloat gray, QZFloat alpha);
void QZContextSetGrayStrokeColor(QZContextRef ctx, QZFloat gray, QZFloat alpha);
QZPoint QZContextConvertPointToDeviceSpace(QZContextRef ctx, QZPoint p);
QZPoint QZContextConvertPointToUserSpace(QZContextRef ctx, QZPoint p);
QZSize QZContextConvertSizeToDeviceSpace(QZContextRef ctx, QZSize s);
QZSize QZContextConvertSizeToUserSpace(QZContextRef ctx, QZSize s);
QZRect QZContextConvertRectToDeviceSpace(QZContextRef ctx, QZRect r);
QZRect QZContextConvertRectToUserSpace(QZContextRef ctx, QZRect r);
bool QZContextIsPathEmpty(QZContextRef ctx);
QZPoint QZContextGetPathCurrentPoint(QZContextRef ctx);
QZRect QZContextGetPathBoundingBox(QZContextRef ctx);
QZPathRef QZContextCopyPath(QZContextRef ctx);

#ifdef __cplusplus
}
#endif
#endif
