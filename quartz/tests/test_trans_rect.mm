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
    if (ctx) {
        CGContextClearRect(ctx, CGRectMake(0, 0, kW, kH));
        CGContextSetShouldAntialias(ctx, true);
    }
    return ctx;
}

static QZContextRef qz_ctx(void) {
    QZContextRef ctx = QZBitmapContextCreate(NULL, kW, kH, 8, (size_t)kW * 4,
                                            kQZImageAlphaPremultipliedLast);
    if (ctx) QZContextSetShouldAntialias(ctx, true);
    return ctx;
}

static int compare_pix(const char *tag, CGContextRef ac, QZContextRef qc) {
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
    int ok = (close >= 99.0) && (mae < 1.0);
    fprintf(stderr, "%s: max=%d close<=8=%.2f%% mae=%.3f %s\n",
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
        return qz_fail(tag);
    }
    return 0;
}

/* Overlapping 0.5-alpha red/blue rects isolated as a transparency group. */
static void apple_draw_overlap(CGContextRef ctx) {
    CGContextSetRGBFillColor(ctx, 1, 0, 0, 0.5);
    CGContextFillRect(ctx, CGRectMake(8, 8, 32, 32));
    CGContextSetRGBFillColor(ctx, 0, 0, 1, 0.5);
    CGContextFillRect(ctx, CGRectMake(24, 24, 32, 32));
}
static void qz_draw_overlap(QZContextRef ctx) {
    QZContextSetRGBFillColor(ctx, 1, 0, 0, 0.5);
    QZContextFillRect(ctx, QZRectMake(8, 8, 32, 32));
    QZContextSetRGBFillColor(ctx, 0, 0, 1, 0.5);
    QZContextFillRect(ctx, QZRectMake(24, 24, 32, 32));
}

static int test_clipped_group(void) {
    CGContextRef ac = apple_ctx();
    QZContextRef qc = qz_ctx();
    if (!ac || !qc) return qz_fail("clipped bitmap");

    CGContextSetRGBFillColor(ac, 1, 1, 1, 1);
    CGContextFillRect(ac, CGRectMake(0, 0, kW, kH));
    QZContextSetRGBFillColor(qc, 1, 1, 1, 1);
    QZContextFillRect(qc, QZRectMake(0, 0, kW, kH));

    /* Apple sample: BeginWithRect … draw … End. No extra Restore. */
    CGContextBeginTransparencyLayerWithRect(ac, CGRectMake(16, 16, 32, 32), NULL);
    apple_draw_overlap(ac);
    CGContextEndTransparencyLayer(ac);

    QZContextBeginTransparencyLayerWithRect(qc, QZRectMake(16, 16, 32, 32));
    qz_draw_overlap(qc);
    QZContextEndTransparencyLayer(qc);

    int rc = compare_pix("clipped_group", ac, qc);
    CGContextRelease(ac);
    QZContextRelease(qc);
    return rc;
}

static int test_unclipped_group(void) {
    CGContextRef ac = apple_ctx();
    QZContextRef qc = qz_ctx();
    if (!ac || !qc) return qz_fail("unclipped bitmap");

    CGContextSetRGBFillColor(ac, 1, 1, 1, 1);
    CGContextFillRect(ac, CGRectMake(0, 0, kW, kH));
    QZContextSetRGBFillColor(qc, 1, 1, 1, 1);
    QZContextFillRect(qc, QZRectMake(0, 0, kW, kH));

    CGContextBeginTransparencyLayer(ac, NULL);
    apple_draw_overlap(ac);
    CGContextEndTransparencyLayer(ac);

    QZContextBeginTransparencyLayerWithInfo(qc);
    qz_draw_overlap(qc);
    QZContextEndTransparencyLayer(qc);

    int rc = compare_pix("unclipped_group", ac, qc);
    CGContextRelease(ac);
    QZContextRelease(qc);
    return rc;
}

static int test_shadow_with_color(void) {
    CGContextRef ac = apple_ctx();
    QZContextRef qc = qz_ctx();
    if (!ac || !qc) return qz_fail("shadow bitmap");

    CGContextSetRGBFillColor(ac, 1, 1, 1, 1);
    CGContextFillRect(ac, CGRectMake(0, 0, kW, kH));
    QZContextSetRGBFillColor(qc, 1, 1, 1, 1);
    QZContextFillRect(qc, QZRectMake(0, 0, kW, kH));

    CGColorSpaceRef acs = srgb();
    CGFloat scc[4] = {0, 0, 1, 0.75};
    CGColorRef sc = CGColorCreate(acs, scc);
    CGColorSpaceRelease(acs);
    QZColorSpaceRef qcs = QZColorSpaceCreateWithNameSRGB();
    QZFloat qcc[4] = {0, 0, 1, 0.75};
    QZColorRef qc_col = QZColorCreate(qcs, qcc);
    QZColorSpaceRelease(qcs);
    CGContextSetShadowWithColor(ac, CGSizeMake(6, -6), 0, sc);
    QZContextSetShadowWithColorQZ(qc, QZSizeMake(6, -6), 0, qc_col);
    CGColorRelease(sc);
    QZColorRelease(qc_col);

    CGContextSetRGBFillColor(ac, 1, 0, 0, 1);
    CGContextFillRect(ac, CGRectMake(16, 24, 16, 16));
    QZContextSetRGBFillColor(qc, 1, 0, 0, 1);
    QZContextFillRect(qc, QZRectMake(16, 24, 16, 16));

    int rc = compare_pix("shadow_color", ac, qc);
    CGContextRelease(ac);
    QZContextRelease(qc);
    return rc;
}

static int test_shadow_null_color(void) {
    CGContextRef ac = apple_ctx();
    QZContextRef qc = qz_ctx();
    if (!ac || !qc) return qz_fail("shadow-null bitmap");

    CGContextSetRGBFillColor(ac, 1, 1, 1, 1);
    CGContextFillRect(ac, CGRectMake(0, 0, kW, kH));
    QZContextSetRGBFillColor(qc, 1, 1, 1, 1);
    QZContextFillRect(qc, QZRectMake(0, 0, kW, kH));

    CGContextSetShadowWithColor(ac, CGSizeMake(6, -6), 0, NULL);
    QZContextSetShadowWithColorQZ(qc, QZSizeMake(6, -6), 0, NULL);

    CGContextSetRGBFillColor(ac, 0, 1, 0, 1);
    CGContextFillRect(ac, CGRectMake(16, 24, 16, 16));
    QZContextSetRGBFillColor(qc, 0, 1, 0, 1);
    QZContextFillRect(qc, QZRectMake(16, 24, 16, 16));

    int rc = compare_pix("shadow_null", ac, qc);
    CGContextRelease(ac);
    QZContextRelease(qc);
    return rc;
}

/* Extra Restore after End is a no-op on Apple (does not crash). */
static int test_extra_restore_noop(void) {
    CGContextRef ac = apple_ctx();
    QZContextRef qc = qz_ctx();
    if (!ac || !qc) return qz_fail("restore bitmap");

    CGContextBeginTransparencyLayerWithRect(ac, CGRectMake(4, 4, 8, 8), NULL);
    CGContextEndTransparencyLayer(ac);
    CGContextRestoreGState(ac); /* Apple: no-op */

    QZContextBeginTransparencyLayerWithRect(qc, QZRectMake(4, 4, 8, 8));
    QZContextEndTransparencyLayer(qc);
    QZContextRestoreGState(qc); /* QZ: pops the Save from BeginWithRect */

    CGContextRelease(ac);
    QZContextRelease(qc);
    return 0;
}

int main(void) {
    int rc = 0;
    rc |= test_clipped_group();
    rc |= test_unclipped_group();
    rc |= test_shadow_with_color();
    rc |= test_shadow_null_color();
    rc |= test_extra_restore_noop();
    if (rc) return 1;
    qz_pass("trans_rect");
    return 0;
}
