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
    int ok = (close > 95.0) || (mae < 3.0);
    fprintf(stderr, "%s: max=%d close<=8=%.2f%% mae=%.3f %s\n",
            tag, mx, close, mae, ok ? "ok" : "BAD");
    if (!ok) {
        int dumped = 0;
        for (int y = 0; y < kH && dumped < 8; y++) {
            const uint8_t *ar = a + (size_t)y * abpr;
            const uint8_t *qr = q + (size_t)y * qbpr;
            for (int x = 0; x < kW && dumped < 8; x++) {
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

static int test_conic_draw(const char *tag,
                           const CGFloat *loc, const CGFloat *col, size_t nstops,
                           CGPoint center, CGFloat angle,
                           void (^extra_cg)(CGContextRef),
                           void (^extra_qz)(QZContextRef)) {
    CGContextRef ac = apple_ctx();
    QZContextRef qc = qz_ctx();
    if (!ac || !qc) {
        if (ac) CGContextRelease(ac);
        if (qc) QZContextRelease(qc);
        return qz_fail("bitmap create");
    }
    if (extra_cg) extra_cg(ac);
    if (extra_qz) extra_qz(qc);

    CGColorSpaceRef cs = srgb();
    CGGradientRef ag = CGGradientCreateWithColorComponents(cs, col, loc, nstops);
    CGColorSpaceRelease(cs);
    CGContextDrawConicGradient(ac, ag, center, angle);
    CGGradientRelease(ag);

    QZGradientRef qg = QZGradientCreate(loc, col, nstops);
    QZContextDrawConicGradient(qc, qg, QZPointMake(center.x, center.y), angle, 0);
    QZGradientRelease(qg);

    int r = compare_pix(tag, ac, qc);
    CGContextRelease(ac);
    QZContextRelease(qc);
    return r;
}

/* Smoke: conic flag paints an angular sweep (right of center ≠ above center). */
static int test_layer_conic_smoke(void) {
    QZContextRef qc = qz_ctx();
    if (!qc) return qz_fail("layer bitmap create");
    QZLayerRef ql = QZGradientLayerCreate();
    QZLayerSetFrame(ql, QZRectMake(0, 0, kW, kH));
    QZLayerSetAnchorPoint(ql, QZPointMake(0, 0));
    QZLayerSetPosition(ql, QZPointMake(0, 0));
    QZFloat cols[8] = {1, 0, 0, 1, 0, 0, 1, 1};
    QZFloat locs[2] = {0, 1};
    QZGradientLayerSetColors(ql, cols, locs, 2);
    QZGradientLayerSetStartPoint(ql, QZPointMake(0.5, 0.5));
    QZGradientLayerSetEndPoint(ql, QZPointMake(1.0, 0.5));
    QZGradientLayerSetConic(ql, true);
    QZLayerRenderInContext(ql, qc);
    QZLayerRelease(ql);

    const uint8_t *p = (const uint8_t *)QZBitmapContextGetData(qc);
    size_t bpr = QZBitmapContextGetBytesPerRow(qc);
    const uint8_t *right = p + (size_t)(kH / 2) * bpr + (size_t)(kW - 4) * 4;
    const uint8_t *up = p + (size_t)4 * bpr + (size_t)(kW / 2) * 4;
    int same = 1;
    for (int c = 0; c < 3; c++) {
        if (abs((int)right[c] - (int)up[c]) > 8) same = 0;
    }
    QZContextRelease(qc);
    if (same) return qz_fail("layer conic not angular");
    return 0;
}

int main(void) {
    CGFloat loc2[] = {0, 1};
    CGFloat col2[] = {1, 0, 0, 1,  0, 0, 1, 1};
    CGFloat loc3[] = {0, 0.5, 1};
    CGFloat col3[] = {1, 0, 0, 1,  0, 1, 0, 1,  0, 0, 1, 1};

    if (test_conic_draw("conic center 0", loc2, col2, 2,
                        CGPointMake(32, 32), 0, nil, nil))
        return 1;
    if (test_conic_draw("conic angle pi/2", loc2, col2, 2,
                        CGPointMake(32, 32), (CGFloat)M_PI_2, nil, nil))
        return 1;
    if (test_conic_draw("conic offset 3-stop", loc3, col3, 3,
                        CGPointMake(20, 40), (CGFloat)(0.3), nil, nil))
        return 1;
    if (test_conic_draw("conic clip", loc2, col2, 2,
                        CGPointMake(32, 32), 0,
                        ^(CGContextRef c) { CGContextClipToRect(c, CGRectMake(8, 8, 40, 40)); },
                        ^(QZContextRef c) { QZContextClipToRect(c, QZRectMake(8, 8, 40, 40)); }))
        return 1;
    if (test_layer_conic_smoke()) return 1;

    qz_pass("gradient-ext");
    return 0;
}
