/* OWNED BY package image-crop. Do not edit from other packages. */
#ifndef QUARTZ_IMAGE_CROP_H
#define QUARTZ_IMAGE_CROP_H

#ifdef __cplusplus
extern "C" {
#endif

QZImageRef QZImageCreateWithImageInRect(QZImageRef image, QZRect rect);
QZFloat QZColorGetAlpha(QZColorRef color);
int QZImageGetBitsPerComponent(QZImageRef image);
int QZImageGetBitsPerPixel(QZImageRef image);
size_t QZImageGetBytesPerRow(QZImageRef image);

#ifdef __cplusplus
}
#endif
#endif
