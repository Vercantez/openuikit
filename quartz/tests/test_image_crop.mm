#import <Foundation/Foundation.h>
#include "test_common.h"
#include <string.h>
#include <vector>

static const int kW = 32;
static const int kH = 32;
static const int kIW = 16;
static const int kIH = 16;

static CGColorSpaceRef srgb(void) {
    return CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
}

static CGContextRef make_cg(void) {
    CGColorSpaceRef cs = srgb();
    CGContextRef ctx = CGBitmapContextCreate(
        NULL, kW, kH, 8, (size_t)kW * 4, cs,
        kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(cs);
    if (ctx) {
        CGContextClearRect(ctx, CGRectMake(0, 0, kW, kH));
        CGContextSetShouldAntialias(ctx, false);
        CGContextSetInterpolationQuality(ctx, kCGInterpolationNone);
    }
    return ctx;
}

static QZContextRef make_qz(void) {
    QZContextRef ctx = QZBitmapContextCreate(NULL, kW, kH, 8, (size_t)kW * 4,
                                            kQZImageAlphaPremultipliedLast);
    if (ctx) {
        QZContextSetShouldAntialias(ctx, false);
        QZContextSetInterpolationQuality(ctx, kQZInterpolationNone);
    }
    return ctx;
}

static CGImageRef make_cg_rgba(int w, int h, const uint8_t *nonpremul) {
    CGColorSpaceRef cs = srgb();
    std::vector<uint8_t> prem((size_t)w * h * 4);
    for (int i = 0; i < w * h; i++) {
        uint8_t a = nonpremul[i * 4 + 3];
        prem[i * 4 + 0] = (uint8_t)((nonpremul[i * 4 + 0] * a) / 255);
        prem[i * 4 + 1] = (uint8_t)((nonpremul[i * 4 + 1] * a) / 255);
        prem[i * 4 + 2] = (uint8_t)((nonpremul[i * 4 + 2] * a) / 255);
        prem[i * 4 + 3] = a;
    }
    CGContextRef ic = CGBitmapContextCreate(
        prem.data(), w, h, 8, (size_t)w * 4, cs,
        kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGImageRef img = CGBitmapContextCreateImage(ic);
    CGContextRelease(ic);
    CGColorSpaceRelease(cs);
    return img;
}

static void fill_pattern(uint8_t *rgba, int w, int h) {
    for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
            uint8_t *p = rgba + (y * w + x) * 4;
            p[0] = (uint8_t)(x * 16 + 1);
            p[1] = (uint8_t)(y * 16 + 1);
            p[2] = (uint8_t)(80 + ((x + y) & 3) * 30);
            p[3] = 255;
        }
    }
}

struct PixStats {
    int maxd;
    int over8;
    int n;
    double mae;
    double close_pct;
};

static PixStats compare_buffers(const uint8_t *a, size_t abpr,
                                const uint8_t *q, size_t qbpr) {
    PixStats s{};
    s.n = kW * kH;
    long sum = 0;
    for (int y = 0; y < kH; y++) {
        const uint8_t *ar = a + (size_t)y * abpr;
        const uint8_t *qr = q + (size_t)y * qbpr;
        for (int x = 0; x < kW; x++) {
            int pd = 0;
            for (int c = 0; c < 4; c++) {
                int d = (int)ar[x * 4 + c] - (int)qr[x * 4 + c];
                if (d < 0) d = -d;
                if (d > pd) pd = d;
                sum += d;
            }
            if (pd > s.maxd) s.maxd = pd;
            if (pd > 8) s.over8++;
        }
    }
    s.mae = sum / (4.0 * s.n);
    s.close_pct = 100.0 * (s.n - s.over8) / (double)s.n;
    return s;
}

static void dump_pair(const uint8_t *a, size_t abpr, const uint8_t *q, size_t qbpr,
                      const char *stem) {
    QZContextRef da = QZBitmapContextCreate(NULL, kW, kH, 8, 0, kQZImageAlphaPremultipliedLast);
    QZContextRef dq = QZBitmapContextCreate(NULL, kW, kH, 8, 0, kQZImageAlphaPremultipliedLast);
    uint8_t *pa = (uint8_t *)QZBitmapContextGetData(da);
    uint8_t *pq = (uint8_t *)QZBitmapContextGetData(dq);
    size_t bpr = QZBitmapContextGetBytesPerRow(da);
    for (int y = 0; y < kH; y++) {
        memcpy(pa + (size_t)y * bpr, a + (size_t)y * abpr, (size_t)kW * 4);
        memcpy(pq + (size_t)y * bpr, q + (size_t)y * qbpr, (size_t)kW * 4);
    }
    char pa_path[256], pq_path[256];
    snprintf(pa_path, sizeof(pa_path), "/tmp/qz_image_crop_%s_apple.png", stem);
    snprintf(pq_path, sizeof(pq_path), "/tmp/qz_image_crop_%s_qz.png", stem);
    QZContextWritePNG(da, pa_path);
    QZContextWritePNG(dq, pq_path);
    QZContextRelease(da);
    QZContextRelease(dq);
}

static int test_crop_draw(void) {
    uint8_t src[kIW * kIH * 4];
    fill_pattern(src, kIW, kIH);

    CGImageRef cimg = make_cg_rgba(kIW, kIH, src);
    QZImageRef qimg = QZImageCreate((size_t)kIW, (size_t)kIH, src);
    if (!cimg || !qimg) return qz_fail("src image");

    if (QZImageGetBitsPerComponent(qimg) != (int)CGImageGetBitsPerComponent(cimg))
        return qz_fail("bitsPerComponent");
    if (QZImageGetBitsPerPixel(qimg) != (int)CGImageGetBitsPerPixel(cimg))
        return qz_fail("bitsPerPixel");
    if (QZImageGetBytesPerRow(qimg) != CGImageGetBytesPerRow(cimg))
        return qz_fail("bytesPerRow");

    CGImageRef ccrop = CGImageCreateWithImageInRect(cimg, CGRectMake(2, 2, 8, 8));
    QZImageRef qcrop = QZImageCreateWithImageInRect(qimg, QZRectMake(2, 2, 8, 8));
    if (!ccrop || !qcrop) return qz_fail("crop null");
    if (QZImageGetWidth(qcrop) != CGImageGetWidth(ccrop) ||
        QZImageGetHeight(qcrop) != CGImageGetHeight(ccrop))
        return qz_fail("crop size");
    if (QZImageGetBitsPerComponent(qcrop) != (int)CGImageGetBitsPerComponent(ccrop))
        return qz_fail("crop bitsPerComponent");
    if (QZImageGetBitsPerPixel(qcrop) != (int)CGImageGetBitsPerPixel(ccrop))
        return qz_fail("crop bitsPerPixel");

    CGContextRef cg = make_cg();
    QZContextRef qz = make_qz();
    CGContextSetRGBFillColor(cg, 1, 1, 1, 1);
    CGContextFillRect(cg, CGRectMake(0, 0, kW, kH));
    QZContextSetRGBFillColor(qz, 1, 1, 1, 1);
    QZContextFillRect(qz, QZRectMake(0, 0, kW, kH));

    CGContextDrawImage(cg, CGRectMake(8, 8, 8, 8), ccrop);
    QZContextDrawImage(qz, QZRectMake(8, 8, 8, 8), qcrop);

    PixStats s = compare_buffers((const uint8_t *)CGBitmapContextGetData(cg),
                                 CGBitmapContextGetBytesPerRow(cg),
                                 (const uint8_t *)QZBitmapContextGetData(qz),
                                 QZBitmapContextGetBytesPerRow(qz));
    fprintf(stderr, "crop: max=%d close<=8=%.2f%% mae=%.4f\n",
            s.maxd, s.close_pct, s.mae);
    int bad = (s.close_pct < 99.0) || (s.mae >= 1.0);
    if (bad) {
        dump_pair((const uint8_t *)CGBitmapContextGetData(cg),
                  CGBitmapContextGetBytesPerRow(cg),
                  (const uint8_t *)QZBitmapContextGetData(qz),
                  QZBitmapContextGetBytesPerRow(qz), "crop");
    }

    CGImageRelease(cimg);
    CGImageRelease(ccrop);
    QZImageRelease(qimg);
    QZImageRelease(qcrop);
    CGContextRelease(cg);
    QZContextRelease(qz);
    if (bad) return qz_fail("crop draw");
    return 0;
}

static int test_color_alpha(void) {
    {
        QZColorRef qc = QZColorCreateGenericRGB(0.2, 0.4, 0.6, 0.8);
        CGColorRef cc = CGColorCreateGenericRGB(0.2, 0.4, 0.6, 0.8);
        if (!qc || !cc) return qz_fail("rgb color");
        if (fabs(QZColorGetAlpha(qc) - CGColorGetAlpha(cc)) > 1e-9)
            return qz_fail("rgb alpha");
        QZColorRelease(qc);
        CGColorRelease(cc);
    }
    {
        QZColorSpaceRef qcs = QZColorSpaceCreateDeviceGray();
        CGColorSpaceRef ccs = CGColorSpaceCreateDeviceGray();
        QZFloat qcomp[2] = {0.3, 0.7};
        CGFloat ccomp[2] = {0.3, 0.7};
        QZColorRef qc = QZColorCreate(qcs, qcomp);
        CGColorRef cc = CGColorCreate(ccs, ccomp);
        if (!qc || !cc) return qz_fail("gray color");
        if (fabs(QZColorGetAlpha(qc) - CGColorGetAlpha(cc)) > 1e-9)
            return qz_fail("gray alpha");
        QZColorSpaceRelease(qcs);
        CGColorSpaceRelease(ccs);
        QZColorRelease(qc);
        CGColorRelease(cc);
    }
    if (QZColorGetAlpha(NULL) != 0) return qz_fail("null alpha");
    if (QZImageGetBitsPerComponent(NULL) != 0) return qz_fail("null bpc");
    if (QZImageGetBitsPerPixel(NULL) != 0) return qz_fail("null bpp");
    if (QZImageGetBytesPerRow(NULL) != 0) return qz_fail("null bpr");
    if (QZImageCreateWithImageInRect(NULL, QZRectMake(0, 0, 1, 1)) != NULL)
        return qz_fail("crop null image");
    return 0;
}

int main(void) {
    int rc = 0;
    rc |= test_color_alpha();
    rc |= test_crop_draw();
    if (rc) return qz_fail("image-crop");
    qz_pass("image-crop");
    return 0;
}
