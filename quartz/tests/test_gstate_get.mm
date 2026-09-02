#import <Foundation/Foundation.h>
#include "test_common.h"
#include <stdarg.h>
#include <string.h>

enum { kW = 64, kH = 64 };

static int g_fails = 0;

/* Private CoreGraphics getters present on this Mac (dlsym + compile probe).
 * Public headers only expose GetInterpolationQuality among these. */
#ifdef __cplusplus
extern "C" {
#endif
extern CGFloat CGContextGetLineWidth(CGContextRef c);
extern CGLineCap CGContextGetLineCap(CGContextRef c);
extern CGLineJoin CGContextGetLineJoin(CGContextRef c);
extern CGFloat CGContextGetMiterLimit(CGContextRef c);
extern CGFloat CGContextGetAlpha(CGContextRef c);
extern CGBlendMode CGContextGetBlendMode(CGContextRef c);
extern bool CGContextGetShouldAntialias(CGContextRef c);
extern CGFloat CGContextGetFlatness(CGContextRef c);
extern void CGContextGetFillColor(CGContextRef c, CGFloat components[]);
extern void CGContextGetStrokeColor(CGContextRef c, CGFloat components[]);
#ifdef __cplusplus
}
#endif

static void failf(const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    fprintf(stderr, "FAIL ");
    vfprintf(stderr, fmt, ap);
    fprintf(stderr, "\n");
    va_end(ap);
    g_fails++;
}

static bool feq(double a, double b) {
    return fabs(a - b) <= 1e-12;
}

static CGContextRef apple_ctx(void) {
    CGColorSpaceRef cs = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
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

static double close_frac(const uint8_t *a, size_t abpr, const uint8_t *q, size_t qbpr) {
    int64_t close = 0;
    int64_t n = (int64_t)kW * kH;
    for (int y = 0; y < kH; y++) {
        const uint8_t *ar = a + (size_t)y * abpr;
        const uint8_t *qr = q + (size_t)y * qbpr;
        for (int x = 0; x < kW; x++) {
            int pd = 0;
            for (int c = 0; c < 4; c++) {
                int d = (int)ar[x * 4 + c] - (int)qr[x * 4 + c];
                if (d < 0) d = -d;
                if (d > pd) pd = d;
            }
            if (pd <= 8) close++;
        }
    }
    return (double)close / (double)n;
}

static void check_stroke_pixels(const char *name, CGContextRef ac, QZContextRef qc) {
    const uint8_t *ap = (const uint8_t *)CGBitmapContextGetData(ac);
    const uint8_t *qp = (const uint8_t *)QZBitmapContextGetData(qc);
    size_t abpr = CGBitmapContextGetBytesPerRow(ac);
    size_t qbpr = QZBitmapContextGetBytesPerRow(qc);
    double cf = close_frac(ap, abpr, qp, qbpr);
    if (cf < 0.99) {
        failf("%s close<=8 = %.2f%% (need >=99%%)", name, cf * 100.0);
    }
}

static void stroke_hline(CGContextRef ac, QZContextRef qc, double width) {
    CGContextSetRGBStrokeColor(ac, 0.15, 0.25, 0.85, 1);
    QZContextSetRGBStrokeColor(qc, 0.15, 0.25, 0.85, 1);
    CGContextSetLineWidth(ac, width);
    QZContextSetLineWidth(qc, width);
    CGContextSetLineCap(ac, kCGLineCapButt);
    QZContextSetLineCap(qc, kQZLineCapButt);
    CGContextBeginPath(ac);
    CGContextMoveToPoint(ac, 8, 32);
    CGContextAddLineToPoint(ac, 56, 32);
    CGContextStrokePath(ac);
    QZContextBeginPath(qc);
    QZContextMoveToPoint(qc, 8, 32);
    QZContextAddLineToPoint(qc, 56, 32);
    QZContextStrokePath(qc);
}

static void stroke_polyline(CGContextRef ac, QZContextRef qc) {
    CGContextSetRGBStrokeColor(ac, 0.80, 0.12, 0.18, 1);
    QZContextSetRGBStrokeColor(qc, 0.80, 0.12, 0.18, 1);
    CGContextSetLineWidth(ac, 5);
    QZContextSetLineWidth(qc, 5);
    CGContextSetLineCap(ac, kCGLineCapRound);
    QZContextSetLineCap(qc, kQZLineCapRound);
    CGContextSetLineJoin(ac, kCGLineJoinRound);
    QZContextSetLineJoin(qc, kQZLineJoinRound);
    CGContextSetMiterLimit(ac, 8);
    QZContextSetMiterLimit(qc, 8);
    CGFloat dash[2] = {6, 4};
    QZFloat qdash[2] = {6, 4};
    CGContextSetLineDash(ac, 2, dash, 2);
    QZContextSetLineDash(qc, 2, qdash, 2);
    CGContextBeginPath(ac);
    CGContextMoveToPoint(ac, 10, 14);
    CGContextAddLineToPoint(ac, 48, 22);
    CGContextAddLineToPoint(ac, 40, 50);
    CGContextStrokePath(ac);
    QZContextBeginPath(qc);
    QZContextMoveToPoint(qc, 10, 14);
    QZContextAddLineToPoint(qc, 48, 22);
    QZContextAddLineToPoint(qc, 40, 50);
    QZContextStrokePath(qc);
}

int main(void) {
    /* Null-safe getters. */
    if (QZContextGetLineWidth(NULL) != 0) failf("null linewidth");
    if (QZContextGetLineCap(NULL) != kQZLineCapButt) failf("null cap");
    if (QZContextGetLineJoin(NULL) != kQZLineJoinMiter) failf("null join");
    if (QZContextGetMiterLimit(NULL) != 10) failf("null miter");
    if (QZContextGetAlpha(NULL) != 1) failf("null alpha");
    if (QZContextGetBlendMode(NULL) != kQZBlendModeNormal) failf("null blend");
    if (QZContextGetInterpolationQuality(NULL) != kQZInterpolationDefault)
        failf("null interp");
    if (!QZContextGetShouldAntialias(NULL)) failf("null aa");
    if (QZContextGetFlatness(NULL) != 0) failf("null flatness");
    QZContextGetFillColor(NULL, NULL);
    QZContextGetStrokeColor(NULL, NULL);
    QZFloat zc[4] = {1, 1, 1, 1};
    QZContextGetFillColor(NULL, zc);
    if (zc[0] != 0 || zc[1] != 0 || zc[2] != 0 || zc[3] != 0)
        failf("null fill color");
    QZContextGetStrokeColor(NULL, zc);
    if (zc[0] != 0 || zc[1] != 0 || zc[2] != 0 || zc[3] != 0)
        failf("null stroke color");
    QZFloat phase = 9;
    size_t n = 9;
    QZContextGetLineDash(NULL, &phase, NULL, &n);
    if (phase != 0 || n != 0) failf("null dash");

    CGContextRef ac = apple_ctx();
    QZContextRef qc = qz_ctx();
    if (!ac || !qc) return qz_fail("bitmap create");

    /* Defaults that match Apple. */
    if (!feq(QZContextGetLineWidth(qc), CGContextGetLineWidth(ac)))
        failf("default width QZ=%g CG=%g", QZContextGetLineWidth(qc),
              CGContextGetLineWidth(ac));
    if ((int)QZContextGetLineCap(qc) != (int)CGContextGetLineCap(ac))
        failf("default cap");
    if ((int)QZContextGetLineJoin(qc) != (int)CGContextGetLineJoin(ac))
        failf("default join");
    if (!feq(QZContextGetMiterLimit(qc), CGContextGetMiterLimit(ac)))
        failf("default miter QZ=%g CG=%g", QZContextGetMiterLimit(qc),
              CGContextGetMiterLimit(ac));
    if (!feq(QZContextGetAlpha(qc), CGContextGetAlpha(ac)))
        failf("default alpha");
    if ((int)QZContextGetBlendMode(qc) != (int)CGContextGetBlendMode(ac))
        failf("default blend");
    if ((int)QZContextGetInterpolationQuality(qc) !=
        (int)CGContextGetInterpolationQuality(ac))
        failf("default interp");
    if (QZContextGetShouldAntialias(qc) != CGContextGetShouldAntialias(ac))
        failf("default aa");

    /* Set then Get vs Apple private getters. */
    CGContextSetLineWidth(ac, 0.5);
    QZContextSetLineWidth(qc, 0.5);
    if (!feq(QZContextGetLineWidth(qc), 0.5)) failf("set width 0.5 vs set");
    if (!feq(QZContextGetLineWidth(qc), CGContextGetLineWidth(ac)))
        failf("width 0.5 QZ=%g CG=%g", QZContextGetLineWidth(qc),
              CGContextGetLineWidth(ac));

    CGContextSetLineWidth(ac, 1);
    QZContextSetLineWidth(qc, 1);
    if (!feq(QZContextGetLineWidth(qc), CGContextGetLineWidth(ac)))
        failf("width 1 QZ=%g CG=%g", QZContextGetLineWidth(qc),
              CGContextGetLineWidth(ac));

    CGContextSetLineWidth(ac, 8);
    QZContextSetLineWidth(qc, 8);
    if (!feq(QZContextGetLineWidth(qc), 8)) failf("set width 8 vs set");
    if (!feq(QZContextGetLineWidth(qc), CGContextGetLineWidth(ac)))
        failf("width 8 QZ=%g CG=%g", QZContextGetLineWidth(qc),
              CGContextGetLineWidth(ac));

    CGContextSetLineCap(ac, kCGLineCapRound);
    QZContextSetLineCap(qc, kQZLineCapRound);
    if (QZContextGetLineCap(qc) != kQZLineCapRound) failf("cap round vs set");
    if ((int)QZContextGetLineCap(qc) != (int)CGContextGetLineCap(ac))
        failf("cap round QZ=%d CG=%d", (int)QZContextGetLineCap(qc),
              (int)CGContextGetLineCap(ac));
    CGContextSetLineCap(ac, kCGLineCapSquare);
    QZContextSetLineCap(qc, kQZLineCapSquare);
    if ((int)QZContextGetLineCap(qc) != (int)CGContextGetLineCap(ac))
        failf("cap square");
    CGContextSetLineCap(ac, kCGLineCapButt);
    QZContextSetLineCap(qc, kQZLineCapButt);
    if ((int)QZContextGetLineCap(qc) != (int)CGContextGetLineCap(ac))
        failf("cap butt");

    CGContextSetLineJoin(ac, kCGLineJoinRound);
    QZContextSetLineJoin(qc, kQZLineJoinRound);
    if (QZContextGetLineJoin(qc) != kQZLineJoinRound) failf("join round vs set");
    if ((int)QZContextGetLineJoin(qc) != (int)CGContextGetLineJoin(ac))
        failf("join round");
    CGContextSetLineJoin(ac, kCGLineJoinBevel);
    QZContextSetLineJoin(qc, kQZLineJoinBevel);
    if ((int)QZContextGetLineJoin(qc) != (int)CGContextGetLineJoin(ac))
        failf("join bevel");
    CGContextSetLineJoin(ac, kCGLineJoinMiter);
    QZContextSetLineJoin(qc, kQZLineJoinMiter);
    if ((int)QZContextGetLineJoin(qc) != (int)CGContextGetLineJoin(ac))
        failf("join miter");

    CGContextSetMiterLimit(ac, 4);
    QZContextSetMiterLimit(qc, 4);
    if (!feq(QZContextGetMiterLimit(qc), 4)) failf("miter 4 vs set");
    if (!feq(QZContextGetMiterLimit(qc), CGContextGetMiterLimit(ac)))
        failf("miter 4 QZ=%g CG=%g", QZContextGetMiterLimit(qc),
              CGContextGetMiterLimit(ac));
    CGContextSetMiterLimit(ac, 0.5);
    QZContextSetMiterLimit(qc, 0.5);
    if (!feq(QZContextGetMiterLimit(qc), CGContextGetMiterLimit(ac)))
        failf("miter clamp QZ=%g CG=%g", QZContextGetMiterLimit(qc),
              CGContextGetMiterLimit(ac));

    CGContextSetAlpha(ac, 0.5);
    QZContextSetAlpha(qc, 0.5);
    if (!feq(QZContextGetAlpha(qc), 0.5)) failf("alpha 0.5 vs set");
    if (!feq(QZContextGetAlpha(qc), CGContextGetAlpha(ac)))
        failf("alpha 0.5 QZ=%g CG=%g", QZContextGetAlpha(qc), CGContextGetAlpha(ac));
    CGContextSetAlpha(ac, 1.5);
    QZContextSetAlpha(qc, 1.5);
    if (!feq(QZContextGetAlpha(qc), CGContextGetAlpha(ac)))
        failf("alpha clamp high");
    CGContextSetAlpha(ac, -0.2);
    QZContextSetAlpha(qc, -0.2);
    if (!feq(QZContextGetAlpha(qc), CGContextGetAlpha(ac)))
        failf("alpha clamp low");
    CGContextSetAlpha(ac, 1);
    QZContextSetAlpha(qc, 1);

    CGContextSetBlendMode(ac, kCGBlendModeMultiply);
    QZContextSetBlendMode(qc, kQZBlendModeMultiply);
    if (QZContextGetBlendMode(qc) != kQZBlendModeMultiply) failf("blend vs set");
    if ((int)QZContextGetBlendMode(qc) != (int)CGContextGetBlendMode(ac))
        failf("blend multiply");
    CGContextSetBlendMode(ac, kCGBlendModeXOR);
    QZContextSetBlendMode(qc, kQZBlendModeXOR);
    if ((int)QZContextGetBlendMode(qc) != (int)CGContextGetBlendMode(ac))
        failf("blend xor");
    CGContextSetBlendMode(ac, kCGBlendModeNormal);
    QZContextSetBlendMode(qc, kQZBlendModeNormal);

    /* Public CGContextGetInterpolationQuality. */
    static const CGInterpolationQuality kI[] = {
        kCGInterpolationDefault, kCGInterpolationNone, kCGInterpolationLow,
        kCGInterpolationHigh, kCGInterpolationMedium};
    static const QZInterpolationQuality kQI[] = {
        kQZInterpolationDefault, kQZInterpolationNone, kQZInterpolationLow,
        kQZInterpolationHigh, kQZInterpolationMedium};
    for (int i = 0; i < 5; i++) {
        CGContextSetInterpolationQuality(ac, kI[i]);
        QZContextSetInterpolationQuality(qc, kQI[i]);
        if (QZContextGetInterpolationQuality(qc) != kQI[i])
            failf("interp %d vs set", (int)kQI[i]);
        if ((int)QZContextGetInterpolationQuality(qc) !=
            (int)CGContextGetInterpolationQuality(ac))
            failf("interp %d QZ=%d CG=%d", (int)kI[i],
                  (int)QZContextGetInterpolationQuality(qc),
                  (int)CGContextGetInterpolationQuality(ac));
    }

    CGContextSetShouldAntialias(ac, false);
    QZContextSetShouldAntialias(qc, false);
    if (QZContextGetShouldAntialias(qc)) failf("aa false vs set");
    if (QZContextGetShouldAntialias(qc) != CGContextGetShouldAntialias(ac))
        failf("aa false");
    CGContextSetShouldAntialias(ac, true);
    QZContextSetShouldAntialias(qc, true);
    if (!QZContextGetShouldAntialias(qc)) failf("aa true vs set");
    if (QZContextGetShouldAntialias(qc) != CGContextGetShouldAntialias(ac))
        failf("aa true");

    /* QZ setter clamps flatness to >=0.1; compare in that range. */
    CGContextSetFlatness(ac, 0.5);
    QZContextSetFlatness(qc, 0.5);
    if (!feq(QZContextGetFlatness(qc), 0.5)) failf("flat 0.5 vs set");
    if (!feq(QZContextGetFlatness(qc), CGContextGetFlatness(ac)))
        failf("flat 0.5 QZ=%g CG=%g", QZContextGetFlatness(qc),
              CGContextGetFlatness(ac));
    CGContextSetFlatness(ac, 2.5);
    QZContextSetFlatness(qc, 2.5);
    if (!feq(QZContextGetFlatness(qc), CGContextGetFlatness(ac)))
        failf("flat 2.5 QZ=%g CG=%g", QZContextGetFlatness(qc),
              CGContextGetFlatness(ac));

    /* Fill/stroke color: QZ getter is always RGBA. */
    CGContextSetRGBFillColor(ac, 0.2, 0.4, 0.6, 0.8);
    QZContextSetRGBFillColor(qc, 0.2, 0.4, 0.6, 0.8);
    QZFloat fr[4];
    QZContextGetFillColor(qc, fr);
    if (!feq(fr[0], 0.2) || !feq(fr[1], 0.4) || !feq(fr[2], 0.6) || !feq(fr[3], 0.8))
        failf("fill rgba vs set %.6g %.6g %.6g %.6g", fr[0], fr[1], fr[2], fr[3]);
    CGFloat cfr[4] = {0};
    CGContextGetFillColor(ac, cfr);
    if (!feq(fr[0], cfr[0]) || !feq(fr[1], cfr[1]) || !feq(fr[2], cfr[2]) ||
        !feq(fr[3], cfr[3]))
        failf("fill rgba QZ=%.6g %.6g %.6g %.6g CG=%.6g %.6g %.6g %.6g",
              fr[0], fr[1], fr[2], fr[3], cfr[0], cfr[1], cfr[2], cfr[3]);

    CGContextSetRGBStrokeColor(ac, 0.1, 0.3, 0.5, 0.7);
    QZContextSetRGBStrokeColor(qc, 0.1, 0.3, 0.5, 0.7);
    QZFloat sr[4];
    QZContextGetStrokeColor(qc, sr);
    if (!feq(sr[0], 0.1) || !feq(sr[1], 0.3) || !feq(sr[2], 0.5) || !feq(sr[3], 0.7))
        failf("stroke rgba vs set");
    CGFloat csr[4] = {0};
    CGContextGetStrokeColor(ac, csr);
    if (!feq(sr[0], csr[0]) || !feq(sr[1], csr[1]) || !feq(sr[2], csr[2]) ||
        !feq(sr[3], csr[3]))
        failf("stroke rgba vs Apple");

    /* No public/private CGContextGetLineDash — compare to values set. */
    QZFloat dlen[3] = {2, 4, 6};
    QZContextSetLineDash(qc, 1.5, dlen, 3);
    QZFloat gp = 0, gout[8] = {0};
    size_t gn = 0;
    QZContextGetLineDash(qc, &gp, NULL, &gn);
    if (!feq(gp, 1.5) || gn != 3) failf("dash query phase=%g n=%zu", gp, gn);
    gn = 8;
    QZContextGetLineDash(qc, &gp, gout, &gn);
    if (gn != 3 || !feq(gp, 1.5) || !feq(gout[0], 2) || !feq(gout[1], 4) ||
        !feq(gout[2], 6))
        failf("dash copy");
    gn = 1;
    QZFloat g1[1] = {0};
    QZContextGetLineDash(qc, &gp, g1, &gn);
    if (gn != 3 || !feq(g1[0], 2)) failf("dash truncated n=%zu v=%g", gn, g1[0]);
    QZContextSetLineDash(qc, 0, NULL, 0);
    gn = 4;
    QZContextGetLineDash(qc, &gp, gout, &gn);
    if (gn != 0 || !feq(gp, 0)) failf("dash clear n=%zu phase=%g", gn, gp);

    /* Save / restore: width 5, save, set 1, restore -> 5. */
    QZContextSetLineWidth(qc, 5);
    CGContextSetLineWidth(ac, 5);
    QZContextSaveGState(qc);
    CGContextSaveGState(ac);
    QZContextSetLineWidth(qc, 1);
    CGContextSetLineWidth(ac, 1);
    if (!feq(QZContextGetLineWidth(qc), 1)) failf("width after save+set1");
    if (!feq(QZContextGetLineWidth(qc), CGContextGetLineWidth(ac)))
        failf("width saved inner vs Apple");
    QZContextRestoreGState(qc);
    CGContextRestoreGState(ac);
    if (!feq(QZContextGetLineWidth(qc), 5)) failf("width after restore QZ=%g",
                                                 QZContextGetLineWidth(qc));
    if (!feq(QZContextGetLineWidth(qc), CGContextGetLineWidth(ac)))
        failf("width restore vs Apple QZ=%g CG=%g", QZContextGetLineWidth(qc),
              CGContextGetLineWidth(ac));

    /* Save/restore of fill color + alpha. */
    QZContextSetRGBFillColor(qc, 0.9, 0.1, 0.2, 1);
    QZContextSetAlpha(qc, 0.4);
    QZContextSaveGState(qc);
    QZContextSetRGBFillColor(qc, 0, 1, 0, 1);
    QZContextSetAlpha(qc, 1);
    QZContextRestoreGState(qc);
    QZContextGetFillColor(qc, fr);
    if (!feq(fr[0], 0.9) || !feq(fr[1], 0.1) || !feq(fr[2], 0.2) || !feq(fr[3], 1))
        failf("fill after restore");
    if (!feq(QZContextGetAlpha(qc), 0.4)) failf("alpha after restore");

    CGContextRelease(ac);
    QZContextRelease(qc);

    /* Pixel-compare strokes that consume the retrieved attributes. */
    {
        const double widths[] = {0.5, 1.0, 8.0};
        for (int i = 0; i < 3; i++) {
            ac = apple_ctx();
            qc = qz_ctx();
            stroke_hline(ac, qc, widths[i]);
            if (!feq(QZContextGetLineWidth(qc), widths[i]))
                failf("hline getter width %g", widths[i]);
            char tag[64];
            snprintf(tag, sizeof(tag), "stroke width %g", widths[i]);
            check_stroke_pixels(tag, ac, qc);
            CGContextRelease(ac);
            QZContextRelease(qc);
        }
    }
    {
        ac = apple_ctx();
        qc = qz_ctx();
        stroke_polyline(ac, qc);
        if (QZContextGetLineCap(qc) != kQZLineCapRound) failf("poly cap getter");
        if (QZContextGetLineJoin(qc) != kQZLineJoinRound) failf("poly join getter");
        if (!feq(QZContextGetMiterLimit(qc), 8)) failf("poly miter getter");
        QZFloat dp = 0, dl[4];
        size_t dc = 4;
        QZContextGetLineDash(qc, &dp, dl, &dc);
        if (!feq(dp, 2) || dc != 2 || !feq(dl[0], 6) || !feq(dl[1], 4))
            failf("poly dash getter");
        check_stroke_pixels("stroke cap/join/dash", ac, qc);
        CGContextRelease(ac);
        QZContextRelease(qc);
    }

    if (g_fails) {
        fprintf(stderr, "FAIL gstate_get (%d)\n", g_fails);
        return 1;
    }
    qz_pass("gstate_get");
    return 0;
}