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

/* t → (t, 0, 1-t, 1) */
static void eval_rb(void *info, const CGFloat *in, CGFloat *out) {
    (void)info;
    CGFloat t = in[0];
    out[0] = t;
    out[1] = 0;
    out[2] = 1 - t;
    out[3] = 1;
}

/* t → (1, t, 0, 1) */
static void eval_yg(void *info, const CGFloat *in, CGFloat *out) {
    (void)info;
    CGFloat t = in[0];
    out[0] = 1;
    out[1] = t;
    out[2] = 0;
    out[3] = 1;
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
    int ok = (close >= 98.0) || (mae < 1.5);
    fprintf(stderr, "%s: max=%d close<=8=%.2f%% mae=%.3f %s\n",
            tag, mx, close, mae, ok ? "ok" : "BAD");
    if (!ok) {
        int dumped = 0;
        for (int y = 0; y < kH && dumped < 12; y++) {
            const uint8_t *ar = a + (size_t)y * abpr;
            const uint8_t *qr = q + (size_t)y * qbpr;
            for (int x = 0; x < kW && dumped < 12; x++) {
                if (memcmp(ar + x * 4, qr + x * 4, 4) == 0) continue;
                int pd = 0;
                for (int c = 0; c < 4; c++) {
                    int d = (int)ar[x * 4 + c] - (int)qr[x * 4 + c];
                    if (d < 0) d = -d;
                    if (d > pd) pd = d;
                }
                if (pd <= 8) continue;
                fprintf(stderr,
                        "  mismatch (%d,%d) apple=%d %d %d %d qz=%d %d %d %d\n",
                        x, y, ar[x * 4], ar[x * 4 + 1], ar[x * 4 + 2], ar[x * 4 + 3],
                        qr[x * 4], qr[x * 4 + 1], qr[x * 4 + 2], qr[x * 4 + 3]);
                dumped++;
            }
        }
        return qz_fail(tag);
    }
    return 0;
}

static CGFunctionRef apple_fn(void (*eval)(void *, const CGFloat *, CGFloat *)) {
    CGFloat domain[2] = {0, 1};
    CGFloat range[8] = {0, 1, 0, 1, 0, 1, 0, 1};
    CGFunctionCallbacks cb = {0, eval, NULL};
    return CGFunctionCreate(NULL, 1, domain, 4, range, &cb);
}

static QZFunctionRef qz_fn(QZFunctionEvaluate eval) {
    QZFloat domain[2] = {0, 1};
    QZFloat range[8] = {0, 1, 0, 1, 0, 1, 0, 1};
    return QZFunctionCreate(NULL, 1, domain, 4, range, (QZFunctionEvaluate)eval);
}

static int test_axial(const char *tag, CGPoint s, CGPoint e, bool ext0, bool ext1,
                      void (^clip_cg)(CGContextRef), void (^clip_qz)(QZContextRef)) {
    CGContextRef ac = apple_ctx();
    QZContextRef qc = qz_ctx();
    if (!ac || !qc) {
        if (ac) CGContextRelease(ac);
        if (qc) QZContextRelease(qc);
        return qz_fail("bitmap create");
    }
    if (clip_cg) clip_cg(ac);
    if (clip_qz) clip_qz(qc);

    CGColorSpaceRef cs = srgb();
    CGFunctionRef af = apple_fn(eval_rb);
    CGShadingRef as = CGShadingCreateAxial(cs, s, e, af, ext0, ext1);
    CGContextDrawShading(ac, as);
    CGShadingRelease(as);
    CGFunctionRelease(af);
    CGColorSpaceRelease(cs);

    QZFunctionRef qf = qz_fn(eval_rb);
    QZShadingRef qs = QZShadingCreateAxial(QZPointMake(s.x, s.y), QZPointMake(e.x, e.y),
                                           qf, ext0, ext1);
    QZContextDrawShading(qc, qs);
    QZShadingRelease(qs);
    QZFunctionRelease(qf);

    int r = compare_pix(tag, ac, qc);
    CGContextRelease(ac);
    QZContextRelease(qc);
    return r;
}

static int test_radial(const char *tag, CGPoint c0, CGFloat r0, CGPoint c1, CGFloat r1,
                       bool ext0, bool ext1) {
    CGContextRef ac = apple_ctx();
    QZContextRef qc = qz_ctx();
    if (!ac || !qc) {
        if (ac) CGContextRelease(ac);
        if (qc) QZContextRelease(qc);
        return qz_fail("bitmap create");
    }

    CGColorSpaceRef cs = srgb();
    CGFunctionRef af = apple_fn(eval_yg);
    CGShadingRef as = CGShadingCreateRadial(cs, c0, r0, c1, r1, af, ext0, ext1);
    CGContextDrawShading(ac, as);
    CGShadingRelease(as);
    CGFunctionRelease(af);
    CGColorSpaceRelease(cs);

    QZFunctionRef qf = qz_fn(eval_yg);
    QZShadingRef qs = QZShadingCreateRadial(QZPointMake(c0.x, c0.y), r0,
                                            QZPointMake(c1.x, c1.y), r1,
                                            qf, ext0, ext1);
    QZContextDrawShading(qc, qs);
    QZShadingRelease(qs);
    QZFunctionRelease(qf);

    int r = compare_pix(tag, ac, qc);
    CGContextRelease(ac);
    QZContextRelease(qc);
    return r;
}

int main(void) {
    if (test_axial("axial", CGPointMake(0, 32), CGPointMake(64, 32), false, false,
                   nil, nil))
        return 1;
    if (test_axial("axial extend", CGPointMake(16, 32), CGPointMake(48, 32), true, true,
                   nil, nil))
        return 1;
    if (test_radial("radial concentric", CGPointMake(32, 32), 4,
                    CGPointMake(32, 32), 28, false, false))
        return 1;
    if (test_axial("clip circle", CGPointMake(0, 32), CGPointMake(64, 32), true, true,
                   ^(CGContextRef c) {
                       CGContextAddEllipseInRect(c, CGRectMake(8, 8, 48, 48));
                       CGContextClip(c);
                   },
                   ^(QZContextRef c) {
                       QZContextAddEllipseInRect(c, QZRectMake(8, 8, 48, 48));
                       QZContextClip(c);
                   }))
        return 1;

    qz_pass("shading");
    return 0;
}
