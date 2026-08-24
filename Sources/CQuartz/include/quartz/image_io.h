/* OWNED BY package image-io. Do not edit from other packages. */
#ifndef QUARTZ_IMAGE_IO_H
#define QUARTZ_IMAGE_IO_H
#ifdef __cplusplus
extern "C" {
#endif

QZImageRef QZImageCreateWithPNGFile(const char *path);
QZImageRef QZImageCreateWithJPEGFile(const char *path);
int QZImageWritePNGFile(QZImageRef image, const char *path);
QZImageRef QZImageCreateWithBytes(const uint8_t *data, size_t length); /* PNG or JPEG */

#ifdef __cplusplus
}
#endif
#endif
