#import <Foundation/Foundation.h>
#include "test_common.h"
#include <string.h>

enum { kW = 64, kH = 64 };

static CGColorSpaceRef srgb(void) {
    return CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
}

static CGContextRef apple_ctx(void) {
    CGColorSpaceRef cs = srgb();
    CGContextRef ctx = CGBitmapContextCreate(
        NULL, kW, kH, 8, (size_t)kW * 4, cs,
        kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(cs);
    if (ctx) CGContextClearRect(ctx, CGRectMake(0, 0, kW, kH));
    return ctx;
}

static QZContextRef qz_ctx(void) {
    return QZBitmapContextCreate(NULL, kW, kH, 8, (size_t)kW * 4,
                                 kQZImageAlphaPremultipliedLast);
}

static int compare_pix(const char *tag, CGContextRef ac, QZContextRef qc,
                       double *out_mae, double *out_close) {
    const uint8_t *a = (const uint8_t *)CGBitmapContextGetData(ac);
    const uint8_t *q = (const uint8_t *)QZBitmapContextGetData(qc);
    size_t abpr = CGBitmapContextGetBytesPerRow(ac);
    size_t qbpr = QZBitmapContextGetBytesPerRow(qc);
    int n = kW * kH;
    int over8 = 0, mx = 0;
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
            if (pd > mx) mx = pd;
            if (pd > 8) over8++;
        }
    }
    double mae = sum / (4.0 * n);
    double close = 100.0 * (n - over8) / n;
    if (out_mae) *out_mae = mae;
    if (out_close) *out_close = close;
    int ok = (close >= 99.5) && (mae < 0.5);
    fprintf(stderr, "%s: max=%d close<=8=%.2f%% mae=%.4f %s\n",
            tag, mx, close, mae, ok ? "ok" : "BAD");
    if (!ok) {
        int dumped = 0;
        for (int y = 0; y < kH && dumped < 12; y++) {
            const uint8_t *ar = a + (size_t)y * abpr;
            const uint8_t *qr = q + (size_t)y * qbpr;
            for (int x = 0; x < kW && dumped < 12; x++) {
                if (memcmp(ar + x * 4, qr + x * 4, 4) == 0) continue;
                fprintf(stderr,
                        "  mismatch mem(%d,%d) apple=%d %d %d %d qz=%d %d %d %d\n",
                        x, y, ar[x * 4], ar[x * 4 + 1], ar[x * 4 + 2], ar[x * 4 + 3],
                        qr[x * 4], qr[x * 4 + 1], qr[x * 4 + 2], qr[x * 4 + 3]);
                dumped++;
            }
        }
        return 1;
    }
    return 0;
}

/* 1. Layer 20x20 filled red, DrawLayerAtPoint (8,8) on white parent. */
static int test_at_point(double *mae, double *close) {
    CGContextRef ac = apple_ctx();
    QZContextRef qc = qz_ctx();
    if (!ac || !qc) return qz_fail("atpoint bitmap");

    CGLayerRef al = CGLayerCreateWithContext(ac, CGSizeMake(20, 20), NULL);
    CGContextRef alc = CGLayerGetContext(al);
    CGContextSetRGBFillColor(alc, 1, 0, 0, 1);
    CGContextFillRect(alc, CGRectMake(0, 0, 20, 20));

    QZCGLayerRef ql = QZCGLayerCreateWithContext(qc, QZSizeMake(20, 20));
    QZContextRef qlc = QZCGLayerGetContext(ql);
    QZContextSetRGBFillColor(qlc, 1, 0, 0, 1);
    QZContextFillRect(qlc, QZRectMake(0, 0, 20, 20));

    CGContextSetRGBFillColor(ac, 1, 1, 1, 1);
    CGContextFillRect(ac, CGRectMake(0, 0, kW, kH));
    QZContextSetRGBFillColor(qc, 1, 1, 1, 1);
    QZContextFillRect(qc, QZRectMake(0, 0, kW, kH));

    CGContextDrawLayerAtPoint(ac, CGPointMake(8, 8), al);
    QZContextDrawLayerAtPoint(qc, QZPointMake(8, 8), ql);

    int bad = compare_pix("atpoint", ac, qc, mae, close);
    CGLayerRelease(al);
    QZCGLayerRelease(ql);
    CGContextRelease(ac);
    QZContextRelease(qc);
    return bad;
}

/* 2. Same layer DrawLayerInRect scaled to 40x20. */
static int test_in_rect(double *mae, double *close) {
    CGContextRef ac = apple_ctx();
    QZContextRef qc = qz_ctx();
    if (!ac || !qc) return qz_fail("inrect bitmap");

    CGLayerRef al = CGLayerCreateWithContext(ac, CGSizeMake(20, 20), NULL);
    CGContextRef alc = CGLayerGetContext(al);
    CGContextSetRGBFillColor(alc, 1, 0, 0, 1);
    CGContextFillRect(alc, CGRectMake(0, 0, 20, 20));

    QZCGLayerRef ql = QZCGLayerCreateWithContext(qc, QZSizeMake(20, 20));
    QZContextRef qlc = QZCGLayerGetContext(ql);
    QZContextSetRGBFillColor(qlc, 1, 0, 0, 1);
    QZContextFillRect(qlc, QZRectMake(0, 0, 20, 20));

    CGContextSetRGBFillColor(ac, 1, 1, 1, 1);
    CGContextFillRect(ac, CGRectMake(0, 0, kW, kH));
    QZContextSetRGBFillColor(qc, 1, 1, 1, 1);
    QZContextFillRect(qc, QZRectMake(0, 0, kW, kH));

    CGContextDrawLayerInRect(ac, CGRectMake(8, 8, 40, 20), al);
    QZContextDrawLayerInRect(qc, QZRectMake(8, 8, 40, 20), ql);

    int bad = compare_pix("inrect", ac, qc, mae, close);
    CGLayerRelease(al);
    QZCGLayerRelease(ql);
    CGContextRelease(ac);
    QZContextRelease(qc);
    return bad;
}

/* 3. Layer with alpha 0.5 blue fill, over a green parent rect. */
static int test_blend(double *mae, double *close) {
    CGContextRef ac = apple_ctx();
    QZContextRef qc = qz_ctx();
    if (!ac || !qc) return qz_fail("blend bitmap");

    CGLayerRef al = CGLayerCreateWithContext(ac, CGSizeMake(20, 20), NULL);
    CGContextRef alc = CGLayerGetContext(al);
    CGContextSetRGBFillColor(alc, 0, 0, 1, 0.5);
    CGContextFillRect(alc, CGRectMake(0, 0, 20, 20));

    QZCGLayerRef ql = QZCGLayerCreateWithContext(qc, QZSizeMake(20, 20));
    QZContextRef qlc = QZCGLayerGetContext(ql);
    QZContextSetRGBFillColor(qlc, 0, 0, 1, 0.5);
    QZContextFillRect(qlc, QZRectMake(0, 0, 20, 20));

    CGContextSetRGBFillColor(ac, 0, 1, 0, 1);
    CGContextFillRect(ac, CGRectMake(4, 4, 40, 40));
    QZContextSetRGBFillColor(qc, 0, 1, 0, 1);
    QZContextFillRect(qc, QZRectMake(4, 4, 40, 40));

    CGContextDrawLayerAtPoint(ac, CGPointMake(8, 8), al);
    QZContextDrawLayerAtPoint(qc, QZPointMake(8, 8), ql);

    int bad = compare_pix("blend", ac, qc, mae, close);
    CGLayerRelease(al);
    QZCGLayerRelease(ql);
    CGContextRelease(ac);
    QZContextRelease(qc);
    return bad;
}

int main(void) {
    QZContextRef smoke = QZBitmapContextCreate(NULL, 32, 32, 8, 128,
                                               kQZImageAlphaPremultipliedLast);
    QZCGLayerRef ly = QZCGLayerCreateWithContext(smoke, QZSizeMake(16, 16));
    if (!ly || !QZCGLayerGetContext(ly)) return qz_fail("layer smoke");
    QZSize sz = QZCGLayerGetSize(ly);
    if (sz.width != 16 || sz.height != 16) return qz_fail("layer size");
    QZCGLayerRelease(ly);
    QZContextRelease(smoke);

    double mae[3] = {0}, close[3] = {0};
    int rc = 0;
    rc |= test_at_point(&mae[0], &close[0]);
    rc |= test_in_rect(&mae[1], &close[1]);
    rc |= test_blend(&mae[2], &close[2]);

    printf("MAE table:\n");
    printf("  atpoint  mae=%.4f  close<=8=%.2f%%\n", mae[0], close[0]);
    printf("  inrect   mae=%.4f  close<=8=%.2f%%\n", mae[1], close[1]);
    printf("  blend    mae=%.4f  close<=8=%.2f%%\n", mae[2], close[2]);

    if (rc) return qz_fail("cglayer");
    qz_pass("cglayer");
    return 0;
}
