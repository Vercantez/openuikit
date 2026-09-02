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

static void cg_draw_checker(void *info, CGContextRef ctx) {
    (void)info;
    CGContextSetRGBFillColor(ctx, 1, 0, 0, 1);
    CGContextFillRect(ctx, CGRectMake(0, 0, 2, 2));
    CGContextSetRGBFillColor(ctx, 0, 0, 1, 1);
    CGContextFillRect(ctx, CGRectMake(2, 2, 2, 2));
}

static void qz_draw_checker(void *info, QZContextRef ctx) {
    (void)info;
    QZContextSetRGBFillColor(ctx, 1, 0, 0, 1);
    QZContextFillRect(ctx, QZRectMake(0, 0, 2, 2));
    QZContextSetRGBFillColor(ctx, 0, 0, 1, 1);
    QZContextFillRect(ctx, QZRectMake(2, 2, 2, 2));
}

/* Uncolored stencil: fill a circle. Do not SetRGBFillColor — Apple then
 * paints the pattern components. (Setting RGB black in the callback makes
 * CG emit black instead of the stencil color.) */
static void cg_draw_stencil(void *info, CGContextRef ctx) {
    (void)info;
    CGContextFillEllipseInRect(ctx, CGRectMake(0, 0, 8, 8));
}

static void qz_draw_stencil(void *info, QZContextRef ctx) {
    (void)info;
    QZContextFillEllipseInRect(ctx, QZRectMake(0, 0, 8, 8));
}

static CGPatternRef cg_colored_pattern(void) {
    static const CGPatternCallbacks cb = {0, &cg_draw_checker, NULL};
    return CGPatternCreate(NULL, CGRectMake(0, 0, 8, 8),
                           CGAffineTransformIdentity, 8, 8,
                           kCGPatternTilingNoDistortion, true, &cb);
}

static CGPatternRef cg_stencil_pattern(void) {
    static const CGPatternCallbacks cb = {0, &cg_draw_stencil, NULL};
    return CGPatternCreate(NULL, CGRectMake(0, 0, 8, 8),
                           CGAffineTransformIdentity, 8, 8,
                           kCGPatternTilingNoDistortion, false, &cb);
}

static void cg_set_colored(CGContextRef ctx, CGPatternRef pat, CGFloat alpha) {
    CGColorSpaceRef pcs = CGColorSpaceCreatePattern(NULL);
    CGContextSetFillColorSpace(ctx, pcs);
    CGColorSpaceRelease(pcs);
    CGContextSetFillPattern(ctx, pat, &alpha);
}

static void cg_set_stencil(CGContextRef ctx, CGPatternRef pat, const CGFloat *comps) {
    CGColorSpaceRef base = srgb();
    CGColorSpaceRef pcs = CGColorSpaceCreatePattern(base);
    CGColorSpaceRelease(base);
    CGContextSetFillColorSpace(ctx, pcs);
    CGColorSpaceRelease(pcs);
    CGContextSetFillPattern(ctx, pat, comps);
}

static int test_colored(void) {
    CGContextRef ac = apple_ctx();
    QZContextRef qc = qz_ctx();
    if (!ac || !qc) return qz_fail("colored bitmap");

    CGPatternRef cp = cg_colored_pattern();
    cg_set_colored(ac, cp, 1);
    CGContextFillRect(ac, CGRectMake(10, 10, 40, 40));
    CGPatternRelease(cp);

    QZPatternRef qp = QZPatternCreate(NULL, QZRectMake(0, 0, 8, 8),
                                      QZAffineTransformIdentity(), 8, 8,
                                      kQZPatternTilingNoDistortion, 1, qz_draw_checker);
    QZFloat a = 1;
    QZContextSetFillPattern(qc, qp, &a, 1);
    QZContextFillRect(qc, QZRectMake(10, 10, 40, 40));
    QZPatternRelease(qp);

    int r = compare_pix("colored checker", ac, qc);
    CGContextRelease(ac);
    QZContextRelease(qc);
    return r;
}

static int test_stencil(void) {
    CGContextRef ac = apple_ctx();
    QZContextRef qc = qz_ctx();
    if (!ac || !qc) return qz_fail("stencil bitmap");

    CGPatternRef cp = cg_stencil_pattern();
    CGFloat comps[4] = {0, 0.5, 1, 1};
    cg_set_stencil(ac, cp, comps);
    CGContextFillRect(ac, CGRectMake(10, 10, 40, 40));
    CGPatternRelease(cp);

    QZPatternRef qp = QZPatternCreate(NULL, QZRectMake(0, 0, 8, 8),
                                      QZAffineTransformIdentity(), 8, 8,
                                      kQZPatternTilingNoDistortion, 0, qz_draw_stencil);
    QZFloat qcomps[4] = {0, 0.5, 1, 1};
    QZContextSetFillPattern(qc, qp, qcomps, 4);
    QZContextFillRect(qc, QZRectMake(10, 10, 40, 40));
    QZPatternRelease(qp);

    int r = compare_pix("stencil circle", ac, qc);
    CGContextRelease(ac);
    QZContextRelease(qc);
    return r;
}

static int test_phase(CGFloat px, CGFloat py, const char *tag) {
    CGContextRef ac = apple_ctx();
    QZContextRef qc = qz_ctx();
    if (!ac || !qc) return qz_fail("phase bitmap");

    CGPatternRef cp = cg_colored_pattern();
    cg_set_colored(ac, cp, 1);
    CGContextSetPatternPhase(ac, CGSizeMake(px, py));
    CGContextFillRect(ac, CGRectMake(10, 10, 40, 40));
    CGPatternRelease(cp);

    QZPatternRef qp = QZPatternCreate(NULL, QZRectMake(0, 0, 8, 8),
                                      QZAffineTransformIdentity(), 8, 8,
                                      kQZPatternTilingNoDistortion, 1, qz_draw_checker);
    QZFloat a = 1;
    QZContextSetFillPattern(qc, qp, &a, 1);
    QZContextSetPatternPhase(qc, QZSizeMake(px, py));
    QZContextFillRect(qc, QZRectMake(10, 10, 40, 40));
    QZPatternRelease(qp);

    int r = compare_pix(tag, ac, qc);
    CGContextRelease(ac);
    QZContextRelease(qc);
    return r;
}

int main(void) {
    QZPatternRef p = QZPatternCreate(NULL, QZRectMake(0, 0, 8, 8),
                                     QZAffineTransformIdentity(), 8, 8,
                                     kQZPatternTilingNoDistortion, 1, NULL);
    if (!p) return qz_fail("pattern create");
    QZPatternRelease(p);

    if (test_colored()) return 1;
    if (test_stencil()) return 1;
    if (test_phase(8, 0, "phase (8,0)")) return 1;
    if (test_phase(2, 0, "phase (2,0)")) return 1;

    qz_pass("pattern");
    return 0;
}
