/* OWNED BY package image-io. Do not edit from other packages. */
#ifndef QUARTZ_IMAGE_IO_H
#define QUARTZ_IMAGE_IO_H
#ifdef __cplusplus
extern "C" {
#endif

QZImageRef QZImageCreateWithPNGFile(const char *path);
QZImageRef QZImageCreateWithJPEGFile(const char *path);
int QZImageWritePNGFile(QZImageRef image, const char *path);
QZImageRef QZImageCreateWithBytes(const uint8_t *data, size_t length); /* PNG, JPEG, or GIF */

/* Straight (NON-premultiplied) RGBA8 codec entry points.
 *
 * QZImage stores premultiplied pixels, so decoding through QZImageCreate*
 * and reading back is lossy for translucent images. These functions hand
 * the caller stb_image's own straight-alpha buffer (and take one back for
 * encoding), which is what an image object with an unassociated-alpha
 * backing store (UIImage/CGImage-style) needs.
 *
 * Decode: PNG, JPEG, or GIF sniffed from the bytes; returns a malloc'd
 * width*height*4 buffer (free with QZImageFreeRGBA), NULL on failure.
 * Encode: returns a malloc'd buffer of *out_length bytes (free with
 * QZImageFreeRGBA), NULL on failure. JPEG quality is 1..100. */
uint8_t *QZImageDecodeRGBA(const uint8_t *data, size_t length, int *out_width, int *out_height);
void QZImageFreeRGBA(uint8_t *pixels);

/* Decode every composited GIF frame into one contiguous
 * width*height*frame_count*4 straight-alpha RGBA8 allocation. Frame delays
 * are milliseconds in a separately allocated frame_count-element array.
 * Free both with the matching functions below. */
uint8_t *QZImageDecodeGIFRGBA(const uint8_t *data, size_t length,
                              int *out_width, int *out_height,
                              int *out_frame_count, int **out_delays_ms);
void QZImageFreeGIFDelays(int *delays_ms);

uint8_t *QZImageEncodePNG(const uint8_t *rgba, int width, int height, size_t *out_length);
uint8_t *QZImageEncodeJPEG(const uint8_t *rgba, int width, int height, int quality,
                           size_t *out_length);

#ifdef __cplusplus
}
#endif
#endif
