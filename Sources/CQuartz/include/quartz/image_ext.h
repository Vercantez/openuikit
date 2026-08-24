/* OWNED BY package image-ext. Do not edit from other packages. */
#ifndef QUARTZ_IMAGE_EXT_H
#define QUARTZ_IMAGE_EXT_H

#ifdef __cplusplus
extern "C" {
#endif

void QZContextDrawTiledImage(QZContextRef ctx, QZRect rect, QZImageRef image);
void QZContextClipToMask(QZContextRef ctx, QZRect rect, QZImageRef mask);
QZImageRef QZImageCreateWithMask(QZImageRef image, QZImageRef mask);
QZRect QZContextGetClipBoundingBox(QZContextRef ctx);

#ifdef __cplusplus
}
#endif
#endif
