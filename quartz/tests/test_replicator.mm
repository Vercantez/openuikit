#import <Foundation/Foundation.h>
#include "test_common.h"
#include <string.h>
#include <math.h>

enum { kW = 128, kH = 128 };

static CGColorSpaceRef srgb(void) {
    return CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
}

static CGColorRef cg_rgb(CGFloat r, CGFloat g, CGFloat b, CGFloat a) {
    CGColorSpaceRef cs = srgb();
    CGFloat c[4] = {r, g, b, a};
    CGColorRef col = CGColorCreate(cs, c);
    CGColorSpaceRelease(cs);
    return col;
}

static CGContextRef apple_ctx(void) {
    CGColorSpaceRef cs = srgb();
    CGContextRef ctx = CGBitmapContextCreate(
        NULL, kW, kH, 8, (size_t)kW * 4, cs,
        kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(cs);
    CGContextClearRect(ctx, CGRectMake(0, 0, kW, kH));
    return ctx;
}

static QZContextRef qz_ctx(void) {
    return QZBitmapContextCreate(NULL, kW, kH, 8, (size_t)kW * 4,
                                 kQZImageAlphaPremultipliedLast);
}

static QZTransform3D qz_t3d(CATransform3D t) {
    QZTransform3D q;
    q.m11 = t.m11; q.m12 = t.m12; q.m13 = t.m13; q.m14 = t.m14;
    q.m21 = t.m21; q.m22 = t.m22; q.m23 = t.m23; q.m24 = t.m24;
    q.m31 = t.m31; q.m32 = t.m32; q.m33 = t.m33; q.m34 = t.m34;
    q.m41 = t.m41; q.m42 = t.m42; q.m43 = t.m43; q.m44 = t.m44;
    return q;
}

typedef struct {
    double mae;
    double close_pct;
    int maxd;
    int64_t exact;
    int64_t pixels;
} PixStats;

static PixStats pix_stats(const uint8_t *a, size_t abpr, const uint8_t *q, size_t qbpr) {
    PixStats s;
    memset(&s, 0, sizeof(s));
    s.pixels = (int64_t)kW * kH;
    double sae = 0;
    for (int y = 0; y < kH; y++) {
        const uint8_t *ar = a + (size_t)y * abpr;
        const uint8_t *qr = q + (size_t)y * qbpr;
        for (int x = 0; x < kW; x++) {
            int md = 0;
            for (int c = 0; c < 4; c++) {
                int d = (int)ar[x * 4 + c] - (int)qr[x * 4 + c];
                if (d < 0) d = -d;
                sae += d;
                if (d > md) md = d;
                if (d > s.maxd) s.maxd = d;
            }
            if (md == 0) s.exact++;
            if (md <= 8) s.close_pct += 1;
        }
    }
    s.mae = sae / (s.pixels * 4.0);
    s.close_pct = 100.0 * s.close_pct / (double)s.pixels;
    return s;
}

static void dump_mismatch(const char *name, const uint8_t *a, size_t abpr,
                          const uint8_t *q, size_t qbpr) {
    int n = 0;
    for (int y = 0; y < kH && n < 8; y++) {
        const uint8_t *ar = a + (size_t)y * abpr;
        const uint8_t *qr = q + (size_t)y * qbpr;
        for (int x = 0; x < kW && n < 8; x++) {
            if (memcmp(ar + x * 4, qr + x * 4, 4) == 0) continue;
            fprintf(stderr,
                    "  %s mismatch mem(%d,%d) apple=%d %d %d %d qz=%d %d %d %d\n",
                    name, x, y, ar[x * 4], ar[x * 4 + 1], ar[x * 4 + 2], ar[x * 4 + 3],
                    qr[x * 4], qr[x * 4 + 1], qr[x * 4 + 2], qr[x * 4 + 3]);
            n++;
        }
    }
}

/* user-space (y-up) sample from a bitmap-context buffer */
static const uint8_t *px_user(const uint8_t *p, size_t bpr, int ux, int uy) {
    int by = (kH - 1) - uy;
    return p + (size_t)by * bpr + (size_t)ux * 4;
}

static int check_pix(const char *name, CGContextRef ac, QZContextRef qc,
                     double mae_lim, double close_lim) {
    const uint8_t *ap = (const uint8_t *)CGBitmapContextGetData(ac);
    const uint8_t *qp = (const uint8_t *)QZBitmapContextGetData(qc);
    size_t abpr = CGBitmapContextGetBytesPerRow(ac);
    size_t qbpr = QZBitmapContextGetBytesPerRow(qc);
    PixStats s = pix_stats(ap, abpr, qp, qbpr);
    int ok = (s.mae < mae_lim) && (s.close_pct + 1e-9 >= close_lim);
    printf("%s %s mae=%.4f close<=8=%.2f%% max=%d exact=%.2f%%\n",
           ok ? "PASS" : "FAIL", name, s.mae, s.close_pct, s.maxd,
           100.0 * (double)s.exact / (double)s.pixels);
    if (!ok) {
        fprintf(stderr, "FAIL %s mae=%.4f (lim %.4f) close=%.2f%% (lim %.2f)\n",
                name, s.mae, mae_lim, s.close_pct, close_lim);
        dump_mismatch(name, ap, abpr, qp, qbpr);
        return 1;
    }
    return 0;
}

/* 1. instanceCount=1: identical to a normal parent (one 40x40 red square). */
static int test_count1(void) {
    CGColorRef white = cg_rgb(1, 1, 1, 1);
    CGColorRef red = cg_rgb(1, 0, 0, 1);

    CGContextRef ac = apple_ctx();
    CALayer *aroot = [CALayer layer];
    aroot.frame = CGRectMake(0, 0, kW, kH);
    aroot.backgroundColor = white;
    CAReplicatorLayer *arep = [CAReplicatorLayer layer];
    arep.frame = CGRectMake(0, 0, kW, kH);
    arep.instanceCount = 1;
    CALayer *asq = [CALayer layer];
    asq.frame = CGRectMake(24, 32, 40, 40);
    asq.backgroundColor = red;
    [arep addSublayer:asq];
    [aroot addSublayer:arep];
    [aroot renderInContext:ac];

    QZContextRef qc = qz_ctx();
    QZLayerRef qroot = QZLayerCreate();
    QZLayerSetFrame(qroot, QZRectMake(0, 0, kW, kH));
    QZLayerSetBackgroundColor(qroot, 1, 1, 1, 1);
    QZLayerRef qrep = QZReplicatorLayerCreate();
    QZLayerSetFrame(qrep, QZRectMake(0, 0, kW, kH));
    QZReplicatorLayerSetInstanceCount(qrep, 1);
    QZLayerRef qsq = QZLayerCreate();
    QZLayerSetFrame(qsq, QZRectMake(24, 32, 40, 40));
    QZLayerSetBackgroundColor(qsq, 1, 0, 0, 1);
    QZLayerAddSublayer(qrep, qsq);
    QZLayerAddSublayer(qroot, qrep);
    QZLayerRenderInContext(qroot, qc);

    int fail = check_pix("count=1 red 40x40", ac, qc, 0.01, 100.0);

    QZLayerRelease(qroot);
    QZLayerRelease(qrep);
    QZLayerRelease(qsq);
    QZContextRelease(qc);
    CGContextRelease(ac);
    CGColorRelease(white);
    CGColorRelease(red);
    return fail;
}

/* 2. instanceCount=4, translate(18,0): four red 16x16 squares in a row. */
static int test_translate_row(void) {
    CGColorRef white = cg_rgb(1, 1, 1, 1);
    CGColorRef red = cg_rgb(1, 0, 0, 1);
    CATransform3D at = CATransform3DMakeTranslation(18, 0, 0);

    CGContextRef ac = apple_ctx();
    CALayer *aroot = [CALayer layer];
    aroot.frame = CGRectMake(0, 0, kW, kH);
    aroot.backgroundColor = white;
    CAReplicatorLayer *arep = [CAReplicatorLayer layer];
    arep.frame = CGRectMake(0, 0, kW, kH);
    arep.instanceCount = 4;
    arep.instanceTransform = at;
    CALayer *asq = [CALayer layer];
    asq.frame = CGRectMake(12, 40, 16, 16);
    asq.backgroundColor = red;
    [arep addSublayer:asq];
    [aroot addSublayer:arep];
    [aroot renderInContext:ac];

    QZContextRef qc = qz_ctx();
    QZLayerRef qroot = QZLayerCreate();
    QZLayerSetFrame(qroot, QZRectMake(0, 0, kW, kH));
    QZLayerSetBackgroundColor(qroot, 1, 1, 1, 1);
    QZLayerRef qrep = QZReplicatorLayerCreate();
    QZLayerSetFrame(qrep, QZRectMake(0, 0, kW, kH));
    QZReplicatorLayerSetInstanceCount(qrep, 4);
    QZReplicatorLayerSetInstanceTransform(qrep, qz_t3d(at));
    QZLayerRef qsq = QZLayerCreate();
    QZLayerSetFrame(qsq, QZRectMake(12, 40, 16, 16));
    QZLayerSetBackgroundColor(qsq, 1, 0, 0, 1);
    QZLayerAddSublayer(qrep, qsq);
    QZLayerAddSublayer(qroot, qrep);
    QZLayerRenderInContext(qroot, qc);

    int fail = check_pix("count=4 translate(18,0)", ac, qc, 1.0, 99.0);

    QZLayerRelease(qroot);
    QZLayerRelease(qrep);
    QZLayerRelease(qsq);
    QZContextRelease(qc);
    CGContextRelease(ac);
    CGColorRelease(white);
    CGColorRelease(red);
    return fail;
}

/* 3. instanceCount=3, ~15° z-rotation plus a small translation, one green square. */
static int test_rotate_translate(void) {
    CGColorRef white = cg_rgb(1, 1, 1, 1);
    CGColorRef green = cg_rgb(0, 1, 0, 1);
    CATransform3D rot = CATransform3DMakeRotation(15.0 * M_PI / 180.0, 0, 0, 1);
    CATransform3D at = CATransform3DConcat(rot, CATransform3DMakeTranslation(12, 6, 0));

    CGContextRef ac = apple_ctx();
    CALayer *aroot = [CALayer layer];
    aroot.frame = CGRectMake(0, 0, kW, kH);
    aroot.backgroundColor = white;
    CAReplicatorLayer *arep = [CAReplicatorLayer layer];
    arep.frame = CGRectMake(0, 0, kW, kH);
    arep.instanceCount = 3;
    arep.instanceTransform = at;
    CALayer *asq = [CALayer layer];
    asq.frame = CGRectMake(36, 48, 16, 16);
    asq.backgroundColor = green;
    [arep addSublayer:asq];
    [aroot addSublayer:arep];
    [aroot renderInContext:ac];

    QZContextRef qc = qz_ctx();
    QZLayerRef qroot = QZLayerCreate();
    QZLayerSetFrame(qroot, QZRectMake(0, 0, kW, kH));
    QZLayerSetBackgroundColor(qroot, 1, 1, 1, 1);
    QZLayerRef qrep = QZReplicatorLayerCreate();
    QZLayerSetFrame(qrep, QZRectMake(0, 0, kW, kH));
    QZReplicatorLayerSetInstanceCount(qrep, 3);
    QZReplicatorLayerSetInstanceTransform(qrep, qz_t3d(at));
    QZLayerRef qsq = QZLayerCreate();
    QZLayerSetFrame(qsq, QZRectMake(36, 48, 16, 16));
    QZLayerSetBackgroundColor(qsq, 0, 1, 0, 1);
    QZLayerAddSublayer(qrep, qsq);
    QZLayerAddSublayer(qroot, qrep);
    QZLayerRenderInContext(qroot, qc);

    int fail = check_pix("count=3 rot15+trans", ac, qc, 2.0, 97.0);

    QZLayerRelease(qroot);
    QZLayerRelease(qrep);
    QZLayerRelease(qsq);
    QZContextRelease(qc);
    CGContextRelease(ac);
    CGColorRelease(white);
    CGColorRelease(green);
    return fail;
}

/* 4. instanceColor / redOffset: match Apple flatten (probe showed no compositor
 * tint in renderInContext:). Fail if Apple tints and we are a no-op. */
static int test_instance_color(void) {
    CGColorRef white = cg_rgb(1, 1, 1, 1);
    CGColorRef red = cg_rgb(1, 0, 0, 1);
    CGColorRef ic = cg_rgb(1, 1, 1, 0.5);
    CATransform3D at = CATransform3DMakeTranslation(30, 0, 0);

    CGContextRef ac = apple_ctx();
    CALayer *aroot = [CALayer layer];
    aroot.frame = CGRectMake(0, 0, kW, kH);
    aroot.backgroundColor = white;
    CAReplicatorLayer *arep = [CAReplicatorLayer layer];
    arep.frame = CGRectMake(0, 0, kW, kH);
    arep.instanceCount = 3;
    arep.instanceTransform = at;
    arep.instanceColor = ic;
    arep.instanceRedOffset = 0.1f;
    CALayer *asq = [CALayer layer];
    asq.frame = CGRectMake(8, 8, 20, 20);
    asq.backgroundColor = red;
    [arep addSublayer:asq];
    [aroot addSublayer:arep];
    [aroot renderInContext:ac];

    QZContextRef qc = qz_ctx();
    QZLayerRef qroot = QZLayerCreate();
    QZLayerSetFrame(qroot, QZRectMake(0, 0, kW, kH));
    QZLayerSetBackgroundColor(qroot, 1, 1, 1, 1);
    QZLayerRef qrep = QZReplicatorLayerCreate();
    QZLayerSetFrame(qrep, QZRectMake(0, 0, kW, kH));
    QZReplicatorLayerSetInstanceCount(qrep, 3);
    QZReplicatorLayerSetInstanceTransform(qrep, qz_t3d(at));
    QZReplicatorLayerSetInstanceColor(qrep, 1, 1, 1, 0.5);
    QZReplicatorLayerSetInstanceRedOffset(qrep, 0.1);
    QZLayerRef qsq = QZLayerCreate();
    QZLayerSetFrame(qsq, QZRectMake(8, 8, 20, 20));
    QZLayerSetBackgroundColor(qsq, 1, 0, 0, 1);
    QZLayerAddSublayer(qrep, qsq);
    QZLayerAddSublayer(qroot, qrep);
    QZLayerRenderInContext(qroot, qc);

    const uint8_t *ap = (const uint8_t *)CGBitmapContextGetData(ac);
    const uint8_t *qp = (const uint8_t *)QZBitmapContextGetData(qc);
    size_t abpr = CGBitmapContextGetBytesPerRow(ac);
    size_t qbpr = QZBitmapContextGetBytesPerRow(qc);

    const uint8_t *a0 = px_user(ap, abpr, 18, 18);
    const uint8_t *a1 = px_user(ap, abpr, 48, 18);
    const uint8_t *a2 = px_user(ap, abpr, 78, 18);
    int apple_tints = (a0[0] != a1[0] || a0[1] != a1[1] || a0[2] != a1[2] || a0[3] != a1[3] ||
                       a0[0] != a2[0] || a0[1] != a2[1] || a0[2] != a2[2] || a0[3] != a2[3]);
    const uint8_t *q0 = px_user(qp, qbpr, 18, 18);
    const uint8_t *q1 = px_user(qp, qbpr, 48, 18);
    const uint8_t *q2 = px_user(qp, qbpr, 78, 18);
    int qz_tints = (q0[0] != q1[0] || q0[1] != q1[1] || q0[2] != q1[2] || q0[3] != q1[3] ||
                    q0[0] != q2[0] || q0[1] != q2[1] || q0[2] != q2[2] || q0[3] != q2[3]);
    printf("  apple i0=%d %d %d %d i1=%d %d %d %d i2=%d %d %d %d tints=%d\n",
           a0[0], a0[1], a0[2], a0[3], a1[0], a1[1], a1[2], a1[3],
           a2[0], a2[1], a2[2], a2[3], apple_tints);
    printf("  qz    i0=%d %d %d %d i1=%d %d %d %d i2=%d %d %d %d tints=%d\n",
           q0[0], q0[1], q0[2], q0[3], q1[0], q1[1], q1[2], q1[3],
           q2[0], q2[1], q2[2], q2[3], qz_tints);

    int fail = 0;
    if (apple_tints && !qz_tints) {
        fprintf(stderr, "FAIL instanceColor: Apple tints replicas, QZ is a no-op\n");
        fail = 1;
    }
    fail |= check_pix("instanceColor+redOffset", ac, qc, 3.0, 90.0);

    QZLayerRelease(qroot);
    QZLayerRelease(qrep);
    QZLayerRelease(qsq);
    QZContextRelease(qc);
    CGContextRelease(ac);
    CGColorRelease(white);
    CGColorRelease(red);
    CGColorRelease(ic);
    return fail;
}

int main(void) {
    int fail = 0;
    fail |= test_count1();
    fail |= test_translate_row();
    fail |= test_rotate_translate();
    fail |= test_instance_color();
    if (fail) return qz_fail("replicator");
    qz_pass("replicator");
    return 0;
}
