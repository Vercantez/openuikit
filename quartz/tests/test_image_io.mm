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
    snprintf(pa_path, sizeof(pa_path), "/tmp/qz_image_io_%s_apple.png", stem);
    snprintf(pq_path, sizeof(pq_path), "/tmp/qz_image_io_%s_qz.png", stem);
    QZContextWritePNG(da, pa_path);
    QZContextWritePNG(dq, pq_path);
    QZContextRelease(da);
    QZContextRelease(dq);
}

static int check_stats(const char *tag, PixStats s, double min_close, double max_mae,
                       int or_ok) {
    int ok = (s.close_pct >= min_close) && (s.mae < max_mae);
    if (!ok && or_ok) ok = (s.close_pct >= min_close) || (s.mae < max_mae);
    fprintf(stderr, "%s: max=%d close<=8=%.2f%% mae=%.4f %s\n",
            tag, s.maxd, s.close_pct, s.mae, ok ? "ok" : "BAD");
    return ok ? 0 : 1;
}

static void fill_rg_alpha(uint8_t *px, int w, int h, int opaque) {
    for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
            uint8_t *p = px + (y * w + x) * 4;
            p[0] = (uint8_t)(x * 255 / (w - 1));
            p[1] = (uint8_t)(y * 255 / (h - 1));
            p[2] = 40;
            if (opaque)
                p[3] = 255;
            else
                p[3] = (uint8_t)(48 + ((x + 2 * y) * 8) % 200);
        }
    }
}

static void release_cgimage_pixels(void *info, const void *data, size_t size) {
    (void)info;
    (void)size;
    free((void *)data);
}

static CGImageRef cgimage_from_nonpremul(int w, int h, const uint8_t *np, int jpeg) {
    size_t n = (size_t)w * (size_t)h * 4;
    uint8_t *prem = (uint8_t *)malloc(n);
    if (!prem) return NULL;
    for (int i = 0; i < w * h; i++) {
        uint8_t a = jpeg ? 255 : np[i * 4 + 3];
        prem[i * 4 + 0] = (uint8_t)((np[i * 4 + 0] * a) / 255);
        prem[i * 4 + 1] = (uint8_t)((np[i * 4 + 1] * a) / 255);
        prem[i * 4 + 2] = (uint8_t)((np[i * 4 + 2] * a) / 255);
        prem[i * 4 + 3] = a;
    }
    CGColorSpaceRef cs = srgb();
    CGDataProviderRef prov =
        CGDataProviderCreateWithData(NULL, prem, n, release_cgimage_pixels);
    CGBitmapInfo info = (CGBitmapInfo)(kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    if (jpeg)
        info = (CGBitmapInfo)(kCGImageAlphaNoneSkipLast | kCGBitmapByteOrder32Big);
    CGImageRef img = CGImageCreate((size_t)w, (size_t)h, 8, 32, (size_t)w * 4, cs, info,
                                   prov, NULL, false, kCGRenderingIntentDefault);
    CGDataProviderRelease(prov);
    CGColorSpaceRelease(cs);
    return img;
}

static int apple_write_image(const char *path, CGImageRef img, CFStringRef uti,
                             float jpeg_quality) {
    NSURL *url = [NSURL fileURLWithPath:@(path)];
    CGImageDestinationRef dest =
        CGImageDestinationCreateWithURL((__bridge CFURLRef)url, uti, 1, NULL);
    if (!dest) return 0;
    CFDictionaryRef opts = NULL;
    if (jpeg_quality > 0) {
        float q = jpeg_quality;
        CFNumberRef qn = CFNumberCreate(NULL, kCFNumberFloatType, &q);
        const void *keys[] = {kCGImageDestinationLossyCompressionQuality};
        const void *vals[] = {qn};
        opts = CFDictionaryCreate(NULL, keys, vals, 1,
                                  &kCFTypeDictionaryKeyCallBacks,
                                  &kCFTypeDictionaryValueCallBacks);
        CFRelease(qn);
    }
    CGImageDestinationAddImage(dest, img, opts);
    if (opts) CFRelease(opts);
    bool ok = CGImageDestinationFinalize(dest);
    CFRelease(dest);
    return ok ? 1 : 0;
}

static CGImageRef apple_load(const char *path) {
    NSURL *url = [NSURL fileURLWithPath:@(path)];
    CGImageSourceRef src = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL);
    if (!src) return NULL;
    CGImageRef img = CGImageSourceCreateImageAtIndex(src, 0, NULL);
    CFRelease(src);
    return img;
}

static std::vector<uint8_t> read_path(const char *path) {
    std::vector<uint8_t> out;
    FILE *f = fopen(path, "rb");
    if (!f) return out;
    fseek(f, 0, SEEK_END);
    long n = ftell(f);
    fseek(f, 0, SEEK_SET);
    if (n > 0) {
        out.resize((size_t)n);
        size_t rd = fread(out.data(), 1, (size_t)n, f);
        out.resize(rd);
    }
    fclose(f);
    return out;
}

static int draw_and_compare(const char *tag, const char *path, int jpeg, int bytes_also) {
    CGImageRef cimg = apple_load(path);
    QZImageRef qimg = jpeg ? QZImageCreateWithJPEGFile(path) : QZImageCreateWithPNGFile(path);
    if (!cimg || !qimg) {
        if (cimg) CGImageRelease(cimg);
        if (qimg) QZImageRelease(qimg);
        return qz_fail(tag);
    }
    if (QZImageGetWidth(qimg) != (size_t)kIW || QZImageGetHeight(qimg) != (size_t)kIH) {
        CGImageRelease(cimg);
        QZImageRelease(qimg);
        return qz_fail("size");
    }

    CGContextRef cg = apple_ctx();
    QZContextRef qz = qz_ctx();
    CGContextDrawImage(cg, CGRectMake(0, 0, kW, kH), cimg);
    QZContextDrawImage(qz, QZRectMake(0, 0, kW, kH), qimg);

    const uint8_t *ap = (const uint8_t *)CGBitmapContextGetData(cg);
    const uint8_t *qp = (const uint8_t *)QZBitmapContextGetData(qz);
    size_t abpr = CGBitmapContextGetBytesPerRow(cg);
    size_t qbpr = QZBitmapContextGetBytesPerRow(qz);
    PixStats s = compare_buffers(ap, abpr, qp, qbpr);

    double min_close = jpeg ? 95.0 : 99.0;
    double max_mae = jpeg ? 3.0 : 1.0;
    int bad = check_stats(tag, s, min_close, max_mae, jpeg ? 1 : 0);
    if (bad) {
        dump_pair(ap, abpr, qp, qbpr, tag);
        int dumped = 0;
        for (int y = 0; y < kH && dumped < 8; y++) {
            const uint8_t *ar = ap + (size_t)y * abpr;
            const uint8_t *qr = qp + (size_t)y * qbpr;
            for (int x = 0; x < kW && dumped < 8; x++) {
                int pd = 0;
                for (int c = 0; c < 4; c++) {
                    int d = (int)ar[x * 4 + c] - (int)qr[x * 4 + c];
                    if (d < 0) d = -d;
                    if (d > pd) pd = d;
                }
                if (pd <= 8) continue;
                fprintf(stderr, "  (%d,%d) apple=%d %d %d %d qz=%d %d %d %d\n",
                        x, y, ar[x * 4], ar[x * 4 + 1], ar[x * 4 + 2], ar[x * 4 + 3],
                        qr[x * 4], qr[x * 4 + 1], qr[x * 4 + 2], qr[x * 4 + 3]);
                dumped++;
            }
        }
    }

    if (!bad && bytes_also) {
        std::vector<uint8_t> mem = read_path(path);
        QZImageRef bimg = QZImageCreateWithBytes(mem.data(), mem.size());
        if (!bimg) {
            bad = qz_fail("bytes load");
        } else {
            QZContextRef qzb = qz_ctx();
            QZContextDrawImage(qzb, QZRectMake(0, 0, kW, kH), bimg);
            PixStats sb = compare_buffers(
                (const uint8_t *)QZBitmapContextGetData(qz),
                QZBitmapContextGetBytesPerRow(qz),
                (const uint8_t *)QZBitmapContextGetData(qzb),
                QZBitmapContextGetBytesPerRow(qzb));
            int bbad = check_stats("png-bytes-vs-file", sb, 100.0, 0.001, 0);
            if (bbad) bad = 1;
            QZContextRelease(qzb);
            QZImageRelease(bimg);
        }
    }

    CGContextRelease(cg);
    QZContextRelease(qz);
    CGImageRelease(cimg);
    QZImageRelease(qimg);
    return bad ? qz_fail(tag) : 0;
}

int main(void) {
    uint8_t rgba[kIW * kIH * 4];
    fill_rg_alpha(rgba, kIW, kIH, 0);

    const char *png_apple = "/tmp/qz_image_io_apple.png";
    const char *png_qz = "/tmp/qz_image_io_qz.png";
    const char *jpg_apple = "/tmp/qz_image_io_apple.jpg";

    CGImageRef src_png = cgimage_from_nonpremul(kIW, kIH, rgba, 0);
    if (!src_png) return qz_fail("cg png src");
    if (!apple_write_image(png_apple, src_png, CFSTR("public.png"), 0)) {
        CGImageRelease(src_png);
        return qz_fail("apple png write");
    }
    CGImageRelease(src_png);

    QZImageRef qsrc = QZImageCreate((size_t)kIW, (size_t)kIH, rgba);
    if (!qsrc) return qz_fail("qz png src");
    if (!QZImageWritePNGFile(qsrc, png_qz)) {
        QZImageRelease(qsrc);
        return qz_fail("qz png write");
    }
    QZImageRelease(qsrc);

    int fails = 0;
    fails += draw_and_compare("png-apple-file", png_apple, 0, 1);
    fails += draw_and_compare("png-qz-file", png_qz, 0, 0);

    uint8_t rgb[kIW * kIH * 4];
    fill_rg_alpha(rgb, kIW, kIH, 1);
    CGImageRef src_jpg = cgimage_from_nonpremul(kIW, kIH, rgb, 1);
    if (!src_jpg) return qz_fail("cg jpeg src");
    if (!apple_write_image(jpg_apple, src_jpg, CFSTR("public.jpeg"), 0.85f)) {
        CGImageRelease(src_jpg);
        return qz_fail("apple jpeg write");
    }
    CGImageRelease(src_jpg);
    fails += draw_and_compare("jpeg-apple-file", jpg_apple, 1, 0);

    if (fails) return 1;
    qz_pass("image_io");
    return 0;
}
