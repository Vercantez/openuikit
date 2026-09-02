#import <Foundation/Foundation.h>
#import <ImageIO/ImageIO.h>
#include "test_common.h"
#include <string.h>
#include <vector>

enum { kW = 32, kH = 32 };
enum { kIW = 16, kIH = 16 };

static CGColorSpaceRef srgb(void) {
    return CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
}

static CGContextRef apple_ctx(void) {
    CGColorSpaceRef cs = srgb();
    CGContextRef ctx = CGBitmapContextCreate(
        NULL, kW, kH, 8, (size_t)kW * 4, cs,
        kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(cs);
    if (ctx) {
        CGContextClearRect(ctx, CGRectMake(0, 0, kW, kH));
        CGContextSetInterpolationQuality(ctx, kCGInterpolationNone);
        CGContextSetShouldAntialias(ctx, false);
    }
    return ctx;
}

static QZContextRef qz_ctx(void) {
    QZContextRef ctx = QZBitmapContextCreate(NULL, kW, kH, 8, (size_t)kW * 4,
                                            kQZImageAlphaPremultipliedLast);
    if (ctx) {
        QZContextSetInterpolationQuality(ctx, kQZInterpolationNone);
        QZContextSetShouldAntialias(ctx, false);
    }
    return ctx;
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
    snprintf(pa_path, sizeof(pa_path), "/tmp/qz_data_provider_%s_apple.png", stem);
    snprintf(pq_path, sizeof(pq_path), "/tmp/qz_data_provider_%s_qz.png", stem);
    QZContextWritePNG(da, pa_path);
    QZContextWritePNG(dq, pq_path);
    QZContextRelease(da);
    QZContextRelease(dq);
}

static int check_stats(const char *tag, PixStats s) {
    int ok = (s.close_pct >= 99.0) && (s.mae < 1.0);
    fprintf(stderr, "%s: max=%d close<=8=%.2f%% mae=%.4f %s\n",
            tag, s.maxd, s.close_pct, s.mae, ok ? "ok" : "BAD");
    return ok ? 0 : 1;
}

static void fill_rg_alpha(uint8_t *px, int w, int h) {
    for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
            uint8_t *p = px + (y * w + x) * 4;
            p[0] = (uint8_t)(x * 255 / (w - 1));
            p[1] = (uint8_t)(y * 255 / (h - 1));
            p[2] = 40;
            p[3] = (uint8_t)(48 + ((x + 2 * y) * 8) % 200);
        }
    }
}

static void release_cgimage_pixels(void *info, const void *data, size_t size) {
    (void)info;
    (void)size;
    free((void *)data);
}

static CGImageRef cgimage_from_nonpremul(int w, int h, const uint8_t *np) {
    size_t n = (size_t)w * (size_t)h * 4;
    uint8_t *prem = (uint8_t *)malloc(n);
    if (!prem) return NULL;
    for (int i = 0; i < w * h; i++) {
        uint8_t a = np[i * 4 + 3];
        prem[i * 4 + 0] = (uint8_t)((np[i * 4 + 0] * a) / 255);
        prem[i * 4 + 1] = (uint8_t)((np[i * 4 + 1] * a) / 255);
        prem[i * 4 + 2] = (uint8_t)((np[i * 4 + 2] * a) / 255);
        prem[i * 4 + 3] = a;
    }
    CGColorSpaceRef cs = srgb();
    CGDataProviderRef prov =
        CGDataProviderCreateWithData(NULL, prem, n, release_cgimage_pixels);
    CGBitmapInfo info = (CGBitmapInfo)(kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGImageRef img = CGImageCreate((size_t)w, (size_t)h, 8, 32, (size_t)w * 4, cs, info,
                                   prov, NULL, false, kCGRenderingIntentDefault);
    CGDataProviderRelease(prov);
    CGColorSpaceRelease(cs);
    return img;
}

static int apple_write_png(const char *path, CGImageRef img) {
    NSURL *url = [NSURL fileURLWithPath:@(path)];
    CGImageDestinationRef dest =
        CGImageDestinationCreateWithURL((__bridge CFURLRef)url, CFSTR("public.png"), 1, NULL);
    if (!dest) return 0;
    CGImageDestinationAddImage(dest, img, NULL);
    bool ok = CGImageDestinationFinalize(dest);
    CFRelease(dest);
    return ok ? 1 : 0;
}

static CGImageRef apple_load_source(const char *path) {
    NSURL *url = [NSURL fileURLWithPath:@(path)];
    CGImageSourceRef src = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL);
    if (!src) return NULL;
    CGImageRef img = CGImageSourceCreateImageAtIndex(src, 0, NULL);
    CFRelease(src);
    return img;
}

static int apple_provider_size(CGDataProviderRef dp, size_t *out) {
    if (!dp || !out) return 0;
    CFDataRef data = CGDataProviderCopyData(dp);
    if (!data) return 0;
    *out = (size_t)CFDataGetLength(data);
    CFRelease(data);
    return 1;
}

static int test_memory_roundtrip(void) {
    uint8_t b[8] = {1, 2, 3, 4, 5, 6, 7, 8};
    QZDataProviderRef qdp = QZDataProviderCreateWithData(b, sizeof(b));
    if (!qdp) return qz_fail("create data");
    if (QZDataProviderGetSize(qdp) != sizeof(b)) return qz_fail("qz size");
    const uint8_t *qp = (const uint8_t *)QZDataProviderGetBytePtr(qdp);
    if (!qp || memcmp(qp, b, sizeof(b)) != 0) return qz_fail("qz bytes");

    CGDataProviderRef cdp = CGDataProviderCreateWithData(NULL, b, sizeof(b), NULL);
    if (!cdp) {
        QZDataProviderRelease(qdp);
        return qz_fail("apple create data");
    }
    size_t asz = 0;
    if (!apple_provider_size(cdp, &asz) || asz != QZDataProviderGetSize(qdp)) {
        CGDataProviderRelease(cdp);
        QZDataProviderRelease(qdp);
        return qz_fail("apple size");
    }
    CFDataRef cd = CGDataProviderCopyData(cdp);
    if (!cd || memcmp(qp, CFDataGetBytePtr(cd), sizeof(b)) != 0) {
        if (cd) CFRelease(cd);
        CGDataProviderRelease(cdp);
        QZDataProviderRelease(qdp);
        return qz_fail("apple bytes");
    }
    CFRelease(cd);
    CGDataProviderRelease(cdp);
    QZDataProviderRelease(qdp);

    if (QZDataProviderGetSize(NULL) != 0) return qz_fail("null size");
    if (QZDataProviderGetBytePtr(NULL) != NULL) return qz_fail("null ptr");
    if (QZDataProviderCreateWithFilename(NULL) != NULL) return qz_fail("null filename");
    if (QZDataProviderCreateWithFilename("/no/such/qz_data_provider.bin") != NULL)
        return qz_fail("missing file");
    QZDataProviderRelease(NULL);
    return 0;
}

static int test_filename_roundtrip(const char *path) {
    QZDataProviderRef qdp = QZDataProviderCreateWithFilename(path);
    CGDataProviderRef cdp = CGDataProviderCreateWithFilename(path);
    if (!qdp || !cdp) {
        if (qdp) QZDataProviderRelease(qdp);
        if (cdp) CGDataProviderRelease(cdp);
        return qz_fail("filename create");
    }
    size_t qsz = QZDataProviderGetSize(qdp);
    size_t asz = 0;
    if (!apple_provider_size(cdp, &asz) || qsz != asz || qsz == 0) {
        QZDataProviderRelease(qdp);
        CGDataProviderRelease(cdp);
        return qz_fail("filename size");
    }
    CFDataRef cd = CGDataProviderCopyData(cdp);
    const uint8_t *qp = (const uint8_t *)QZDataProviderGetBytePtr(qdp);
    if (!cd || !qp || memcmp(qp, CFDataGetBytePtr(cd), qsz) != 0) {
        if (cd) CFRelease(cd);
        QZDataProviderRelease(qdp);
        CGDataProviderRelease(cdp);
        return qz_fail("filename bytes");
    }
    CFRelease(cd);
    QZDataProviderRelease(qdp);
    CGDataProviderRelease(cdp);
    return 0;
}

static int draw_compare(const char *tag, CGImageRef cimg, QZImageRef qimg) {
    if (!cimg || !qimg) return qz_fail(tag);
    if (QZImageGetWidth(qimg) != CGImageGetWidth(cimg) ||
        QZImageGetHeight(qimg) != CGImageGetHeight(cimg))
        return qz_fail("image size");

    CGContextRef cg = apple_ctx();
    QZContextRef qz = qz_ctx();
    CGContextDrawImage(cg, CGRectMake(0, 0, kW, kH), cimg);
    QZContextDrawImage(qz, QZRectMake(0, 0, kW, kH), qimg);

    const uint8_t *ap = (const uint8_t *)CGBitmapContextGetData(cg);
    const uint8_t *qp = (const uint8_t *)QZBitmapContextGetData(qz);
    size_t abpr = CGBitmapContextGetBytesPerRow(cg);
    size_t qbpr = QZBitmapContextGetBytesPerRow(qz);
    PixStats s = compare_buffers(ap, abpr, qp, qbpr);
    int bad = check_stats(tag, s);
    if (bad) dump_pair(ap, abpr, qp, qbpr, tag);

    CGContextRelease(cg);
    QZContextRelease(qz);
    return bad ? qz_fail(tag) : 0;
}

static int test_png_file(void) {
    uint8_t rgba[kIW * kIH * 4];
    fill_rg_alpha(rgba, kIW, kIH);

    const char *png_path = "/tmp/qz_data_provider_apple.png";
    CGImageRef src = cgimage_from_nonpremul(kIW, kIH, rgba);
    if (!src) return qz_fail("cg png src");
    if (!apple_write_png(png_path, src)) {
        CGImageRelease(src);
        return qz_fail("apple png write");
    }
    CGImageRelease(src);

    int rc = test_filename_roundtrip(png_path);
    if (rc) return rc;

    CGImageRef cimg = apple_load_source(png_path);
    if (!cimg) return qz_fail("cgimagesource");

    QZDataProviderRef dp = QZDataProviderCreateWithFilename(png_path);
    if (!dp) {
        CGImageRelease(cimg);
        return qz_fail("png filename");
    }

    QZImageRef from_bytes = QZImageCreateWithBytes(
        (const uint8_t *)QZDataProviderGetBytePtr(dp), QZDataProviderGetSize(dp));
    int bad = draw_compare("png-bytes", cimg, from_bytes);
    if (from_bytes) QZImageRelease(from_bytes);

    QZImageRef from_dp = QZImageCreateWithDataProvider(dp, 0, 0, 0, 0);
    bad |= draw_compare("png-provider", cimg, from_dp);
    if (from_dp) QZImageRelease(from_dp);

    QZImageRef from_dp_wh = QZImageCreateWithDataProvider(
        dp, (size_t)kIW, (size_t)kIH, 8, (size_t)kIW * 4);
    bad |= draw_compare("png-provider-wh", cimg, from_dp_wh);
    if (from_dp_wh) QZImageRelease(from_dp_wh);

    QZDataProviderRelease(dp);
    CGImageRelease(cimg);
    return bad;
}

static int test_raw_rgba(void) {
    uint8_t rgba[kIW * kIH * 4];
    for (int y = 0; y < kIH; y++) {
        for (int x = 0; x < kIW; x++) {
            uint8_t *p = rgba + (y * kIW + x) * 4;
            p[0] = (uint8_t)(x * 16 + 1);
            p[1] = (uint8_t)(y * 16 + 2);
            p[2] = (uint8_t)(80 + ((x + y) & 3) * 30);
            p[3] = 255;
        }
    }

    QZDataProviderRef qdp = QZDataProviderCreateWithData(rgba, sizeof(rgba));
    QZImageRef qimg = QZImageCreateWithDataProvider(qdp, kIW, kIH, 8, (size_t)kIW * 4);

    CGColorSpaceRef cs = srgb();
    CGDataProviderRef cdp = CGDataProviderCreateWithData(NULL, rgba, sizeof(rgba), NULL);
    CGImageRef cimg = CGImageCreate(
        (size_t)kIW, (size_t)kIH, 8, 32, (size_t)kIW * 4, cs,
        (CGBitmapInfo)(kCGImageAlphaLast | kCGBitmapByteOrder32Big),
        cdp, NULL, false, kCGRenderingIntentDefault);
    CGDataProviderRelease(cdp);
    CGColorSpaceRelease(cs);

    int bad = draw_compare("raw-rgba", cimg, qimg);
    if (cimg) CGImageRelease(cimg);
    if (qimg) QZImageRelease(qimg);
    QZDataProviderRelease(qdp);
    return bad;
}

int main(void) {
    int fails = 0;
    fails += test_memory_roundtrip();
    fails += test_png_file();
    fails += test_raw_rgba();
    if (fails) return 1;
    qz_pass("data_provider");
    return 0;
}
