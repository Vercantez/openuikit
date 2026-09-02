#include "qz_internal.hpp"

/* OWNED BY package image-crop. */

QZImageRef QZImageCreateWithImageInRect(QZImageRef image, QZRect rect) {
    if (!image || image->width <= 0 || image->height <= 0) return nullptr;

    /* CGImageCreateWithImageInRect: CGRectIntegral, then intersect with
     * image bounds in pixel space. Origin is the first (top-left) pixel. */
    QZRect crop = QZRectIntersection(
        QZRectIntegral(rect),
        QZRectMake(0, 0, (QZFloat)image->width, (QZFloat)image->height));
    if (QZRectIsEmpty(crop)) return nullptr;

    int x0 = (int)std::lround(crop.origin.x);
    int y0 = (int)std::lround(crop.origin.y);
    int cw = (int)std::lround(crop.size.width);
    int ch = (int)std::lround(crop.size.height);
    if (x0 < 0) {
        cw += x0;
        x0 = 0;
    }
    if (y0 < 0) {
        ch += y0;
        y0 = 0;
    }
    if (x0 + cw > image->width) cw = image->width - x0;
    if (y0 + ch > image->height) ch = image->height - y0;
    if (cw <= 0 || ch <= 0) return nullptr;

    auto *out = new QZImage();
    out->width = cw;
    out->height = ch;
    out->rgba.resize((size_t)cw * (size_t)ch * 4);
    const uint8_t *src = image->rgba.data();
    int sw = image->width;
    for (int y = 0; y < ch; y++) {
        memcpy(out->rgba.data() + (size_t)y * (size_t)cw * 4,
               src + ((size_t)(y0 + y) * (size_t)sw + (size_t)x0) * 4,
               (size_t)cw * 4);
    }
    return out;
}

QZFloat QZColorGetAlpha(QZColorRef color) {
    if (!color) return 0;
    size_t n = QZColorGetNumberOfComponents(color);
    const QZFloat *c = QZColorGetComponents(color);
    if (!c || n == 0) return 0;
    return c[n - 1];
}

int QZImageGetBitsPerComponent(QZImageRef image) {
    return image ? 8 : 0;
}

int QZImageGetBitsPerPixel(QZImageRef image) {
    return image ? 32 : 0;
}

size_t QZImageGetBytesPerRow(QZImageRef image) {
    return image ? (size_t)image->width * 4u : 0;
}
