#import <Foundation/Foundation.h>
#include "test_common.h"
#include <vector>
#include <string.h>

static const int kW = 32;
static const int kH = 32;

static CGColorSpaceRef srgb(void) {
    return CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
}

static CGContextRef make_cg(void) {
    CGColorSpaceRef cs = srgb();
    CGContextRef ctx = CGBitmapContextCreate(
        NULL, kW, kH, 8, (size_t)kW * 4, cs,
        kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(cs);
    CGContextClearRect(ctx, CGRectMake(0, 0, kW, kH));
    CGContextSetShouldAntialias(ctx, true);
    CGContextSetInterpolationQuality(ctx, kCGInterpolationNone);
    return ctx;
}

static QZContextRef make_qz(void) {
    QZContextRef ctx = QZBitmapContextCreate(NULL, kW, kH, 8, 0, kQZImageAlphaPremultipliedLast);
    QZContextSetShouldAntialias(ctx, true);
    QZContextSetInterpolationQuality(ctx, kQZInterpolationNone);
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

/* DeviceGray, no alpha — valid for CGContextClipToMask / CGImageCreateWithMask. */
static CGImageRef make_cg_gray(int w, int h, const uint8_t *gray) {
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceGray();
    std::vector<uint8_t> copy(gray, gray + (size_t)w * h);
    CGContextRef ic = CGBitmapContextCreate(copy.data(), w, h, 8, (size_t)w, cs,
                                            kCGImageAlphaNone);
    CGImageRef img = CGBitmapContextCreateImage(ic);
    CGContextRelease(ic);
    CGColorSpaceRelease(cs);
    return img;
}

static void fill_pattern(uint8_t *rgba, int w, int h) {
    for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
            uint8_t *p = rgba + (y * w + x) * 4;
            p[0] = (uint8_t)(40 + x * 24);
            p[1] = (uint8_t)(40 + y * 24);
            p[2] = (uint8_t)(180 + ((x + y) & 1) * 40);
            p[3] = 255;
        }
    }
}

static int compare_pix(const uint8_t *a, size_t abpr, const uint8_t *q, size_t qbpr,
                       int w, int h, const char *tag, int *out_over8) {
    int mx = 0, over8 = 0, n = w * h;
    long sum = 0;
    for (int y = 0; y < h; y++) {
        const uint8_t *ar = a + (size_t)y * abpr;
        const uint8_t *qr = q + (size_t)y * qbpr;
        for (int x = 0; x < w; x++) {
            int pd = 0;
            for (int c = 0; c < 4; c++) {
                int d = (int)ar[x * 4 + c] - (int)qr[x * 4 + c];
                if (d < 0) d = -d;
                if (d > pd) pd = d;
                sum += d;
            }
            if (pd > mx) mx = pd;
            if (pd > 8) over8++;
        }
    }
    *out_over8 = over8;
    double mae = sum / (4.0 * n);
    /* Max diff <= 8 on most pixels: allow a few edge outliers. */
    int ok = (over8 * 20 <= n); /* <= 5% of pixels */
    fprintf(stderr, "%s: max=%d over8=%d/%d mae=%.3f %s\n",
            tag, mx, over8, n, mae, ok ? "ok" : "BAD");
    return ok ? 0 : 1;
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
    snprintf(pa_path, sizeof(pa_path), "/tmp/qz_%s_apple.png", stem);
    snprintf(pq_path, sizeof(pq_path), "/tmp/qz_%s_qz.png", stem);
    QZContextWritePNG(da, pa_path);
    QZContextWritePNG(dq, pq_path);
    QZContextRelease(da);
    QZContextRelease(dq);
}

static int test_tiled(void) {
    const int iw = 8, ih = 8;
    uint8_t tile[8 * 8 * 4];
    fill_pattern(tile, iw, ih);

    CGContextRef cg = make_cg();
    QZContextRef qz = make_qz();
    CGContextSetRGBFillColor(cg, 1, 1, 1, 1);
    CGContextFillRect(cg, CGRectMake(0, 0, kW, kH));
    QZContextSetRGBFillColor(qz, 1, 1, 1, 1);
    QZContextFillRect(qz, QZRectMake(0, 0, kW, kH));

    CGImageRef cimg = make_cg_rgba(iw, ih, tile);
    QZImageRef qimg = QZImageCreate((size_t)iw, (size_t)ih, tile);
    CGRect crect = CGRectMake(2, 3, 8, 8);
    QZRect qrect = QZRectMake(2, 3, 8, 8);
    CGContextDrawTiledImage(cg, crect, cimg);
    QZContextDrawTiledImage(qz, qrect, qimg);

    int over8 = 0;
    int bad = compare_pix((const uint8_t *)CGBitmapContextGetData(cg),
                          CGBitmapContextGetBytesPerRow(cg),
                          (const uint8_t *)QZBitmapContextGetData(qz),
                          QZBitmapContextGetBytesPerRow(qz),
                          kW, kH, "tiled", &over8);
    if (bad) dump_pair((const uint8_t *)CGBitmapContextGetData(cg),
                       CGBitmapContextGetBytesPerRow(cg),
                       (const uint8_t *)QZBitmapContextGetData(qz),
                       QZBitmapContextGetBytesPerRow(qz), "tiled");
    CGImageRelease(cimg);
    QZImageRelease(qimg);
    CGContextRelease(cg);
    QZContextRelease(qz);
    return bad;
}

static int test_clip_mask(void) {
    const int mw = 16, mh = 16;
    uint8_t gray[16 * 16];
    uint8_t rgba[16 * 16 * 4];
    for (int y = 0; y < mh; y++) {
        for (int x = 0; x < mw; x++) {
            uint8_t g = (uint8_t)(x * 16 + 8); /* 8..248 ramp */
            gray[y * mw + x] = g;
            uint8_t *p = rgba + (y * mw + x) * 4;
            p[0] = p[1] = p[2] = p[3] = g;
        }
    }

    CGContextRef cg = make_cg();
    QZContextRef qz = make_qz();
    CGContextSetRGBFillColor(cg, 0, 0, 1, 1);
    CGContextFillRect(cg, CGRectMake(0, 0, kW, kH));
    QZContextSetRGBFillColor(qz, 0, 0, 1, 1);
    QZContextFillRect(qz, QZRectMake(0, 0, kW, kH));

    CGImageRef cmask = make_cg_gray(mw, mh, gray);
    QZImageRef qmask = QZImageCreate((size_t)mw, (size_t)mh, rgba);
    CGContextClipToMask(cg, CGRectMake(8, 8, 16, 16), cmask);
    QZContextClipToMask(qz, QZRectMake(8, 8, 16, 16), qmask);

    CGContextSetRGBFillColor(cg, 1, 0, 0, 1);
    CGContextFillRect(cg, CGRectMake(0, 0, kW, kH));
    QZContextSetRGBFillColor(qz, 1, 0, 0, 1);
    QZContextFillRect(qz, QZRectMake(0, 0, kW, kH));

    int over8 = 0;
    int bad = compare_pix((const uint8_t *)CGBitmapContextGetData(cg),
                          CGBitmapContextGetBytesPerRow(cg),
                          (const uint8_t *)QZBitmapContextGetData(qz),
                          QZBitmapContextGetBytesPerRow(qz),
                          kW, kH, "clipmask", &over8);
    if (bad) dump_pair((const uint8_t *)CGBitmapContextGetData(cg),
                       CGBitmapContextGetBytesPerRow(cg),
                       (const uint8_t *)QZBitmapContextGetData(qz),
                       QZBitmapContextGetBytesPerRow(qz), "clipmask");
    CGImageRelease(cmask);
    QZImageRelease(qmask);
    CGContextRelease(cg);
    QZContextRelease(qz);
    return bad;
}

static int test_clip_bbox(void) {
    QZContextRef ctx = make_qz();
    QZRect b = QZContextGetClipBoundingBox(ctx);
    if (b.origin.x < -0.5 || b.origin.y < -0.5 ||
        b.origin.x + b.size.width < 31.5 || b.origin.y + b.size.height < 31.5)
        return qz_fail("clip bbox full");

    QZContextClipToRect(ctx, QZRectMake(8, 8, 16, 16));
    b = QZContextGetClipBoundingBox(ctx);
    if (fabs(b.origin.x - 8) > 1.5 || fabs(b.origin.y - 8) > 1.5 ||
        fabs(b.size.width - 16) > 2.0 || fabs(b.size.height - 16) > 2.0) {
        fprintf(stderr, "clip bbox after rect: %g %g %g %g\n",
                b.origin.x, b.origin.y, b.size.width, b.size.height);
        return qz_fail("clip bbox rect");
    }
    QZContextRelease(ctx);
    return 0;
}

static int test_create_with_mask(void) {
    const int iw = 8, ih = 8;
    uint8_t src[8 * 8 * 4];
    uint8_t mrgba[8 * 8 * 4];
    uint8_t gray[8 * 8];
    fill_pattern(src, iw, ih);
    for (int y = 0; y < ih; y++) {
        for (int x = 0; x < iw; x++) {
            uint8_t g = (uint8_t)(y * 32);
            gray[y * iw + x] = g;
            uint8_t *p = mrgba + (y * iw + x) * 4;
            p[0] = p[1] = p[2] = p[3] = g;
        }
    }

    CGContextRef cg = make_cg();
    QZContextRef qz = make_qz();
    CGContextSetRGBFillColor(cg, 1, 1, 1, 1);
    CGContextFillRect(cg, CGRectMake(0, 0, kW, kH));
    QZContextSetRGBFillColor(qz, 1, 1, 1, 1);
    QZContextFillRect(qz, QZRectMake(0, 0, kW, kH));

    CGImageRef cimg = make_cg_rgba(iw, ih, src);
    CGImageRef cmask = make_cg_gray(iw, ih, gray);
    CGImageRef cmasked = CGImageCreateWithMask(cimg, cmask);
    CGContextDrawImage(cg, CGRectMake(8, 8, 16, 16), cmasked);

    QZImageRef qimg = QZImageCreate((size_t)iw, (size_t)ih, src);
    QZImageRef qmask = QZImageCreate((size_t)iw, (size_t)ih, mrgba);
    QZImageRef qmasked = QZImageCreateWithMask(qimg, qmask);
    QZContextDrawImage(qz, QZRectMake(8, 8, 16, 16), qmasked);

    int over8 = 0;
    int bad = compare_pix((const uint8_t *)CGBitmapContextGetData(cg),
                          CGBitmapContextGetBytesPerRow(cg),
                          (const uint8_t *)QZBitmapContextGetData(qz),
                          QZBitmapContextGetBytesPerRow(qz),
                          kW, kH, "withmask", &over8);
    if (bad) dump_pair((const uint8_t *)CGBitmapContextGetData(cg),
                       CGBitmapContextGetBytesPerRow(cg),
                       (const uint8_t *)QZBitmapContextGetData(qz),
                       QZBitmapContextGetBytesPerRow(qz), "withmask");

    CGImageRelease(cimg);
    CGImageRelease(cmask);
    if (cmasked) CGImageRelease(cmasked);
    QZImageRelease(qimg);
    QZImageRelease(qmask);
    QZImageRelease(qmasked);
    CGContextRelease(cg);
    QZContextRelease(qz);
    if (!cmasked) return qz_fail("CGImageCreateWithMask returned NULL");
    return bad;
}

int main(void) {
    int rc = 0;
    rc |= test_clip_bbox();
    rc |= test_tiled();
    rc |= test_clip_mask();
    rc |= test_create_with_mask();
    if (rc) return qz_fail("image-ext");
    qz_pass("image-ext");
    return 0;
}
