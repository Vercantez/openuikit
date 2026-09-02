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

static int check_qz_qz(const char *name, QZContextRef a, QZContextRef b,
                       double mae_lim) {
    const uint8_t *ap = (const uint8_t *)QZBitmapContextGetData(a);
    const uint8_t *bp = (const uint8_t *)QZBitmapContextGetData(b);
    size_t abpr = QZBitmapContextGetBytesPerRow(a);
    size_t bbpr = QZBitmapContextGetBytesPerRow(b);
    PixStats s = pix_stats(ap, abpr, bp, bbpr);
    int ok = s.mae < mae_lim;
    printf("%s %s mae=%.4f close<=8=%.2f%% max=%d exact=%.2f%%\n",
           ok ? "PASS" : "FAIL", name, s.mae, s.close_pct, s.maxd,
           100.0 * (double)s.exact / (double)s.pixels);
    if (!ok) {
        fprintf(stderr, "FAIL %s mae=%.4f (lim %.4f)\n", name, s.mae, mae_lim);
        dump_mismatch(name, ap, abpr, bp, bbpr);
        return 1;
    }
    return 0;
}

static CALayer *apple_white_root(void) {
    CALayer *r = [CALayer layer];
    r.frame = CGRectMake(0, 0, kW, kH);
    CGColorRef w = cg_rgb(1, 1, 1, 1);
    r.backgroundColor = w;
    CGColorRelease(w);
    return r;
}

static CALayer *apple_square(CGFloat x, CGFloat y, CGFloat r, CGFloat g, CGFloat b) {
    CALayer *s = [CALayer layer];
    s.frame = CGRectMake(x, y, 40, 40);
    CGColorRef c = cg_rgb(r, g, b, 1);
    s.backgroundColor = c;
    CGColorRelease(c);
    return s;
}

static QZLayerRef qz_white_root(void) {
    QZLayerRef r = QZLayerCreate();
    QZLayerSetFrame(r, QZRectMake(0, 0, kW, kH));
    QZLayerSetBackgroundColor(r, 1, 1, 1, 1);
    return r;
}

static QZLayerRef qz_square(QZFloat x, QZFloat y, QZFloat r, QZFloat g, QZFloat b) {
    QZLayerRef s = QZLayerCreate();
    QZLayerSetFrame(s, QZRectMake(x, y, 40, 40));
    QZLayerSetBackgroundColor(s, r, g, b, 1);
    return s;
}

/* 1. Identity 3D: two 40x40 squares offset in x. Match a normal parent (MAE 0)
 * and Apple CATransformLayer (close<=8 >=99%, MAE < 1). */
static int test_identity_two_squares(void) {
    CGContextRef ac = apple_ctx();
    CALayer *aroot = apple_white_root();
    CATransformLayer *atl = [CATransformLayer layer];
    atl.frame = CGRectMake(0, 0, kW, kH);
    [atl addSublayer:apple_square(20, 44, 1, 0, 0)];
    [atl addSublayer:apple_square(68, 44, 0, 0, 1)];
    [aroot addSublayer:atl];
    [aroot renderInContext:ac];

    QZContextRef qc = qz_ctx();
    QZLayerRef qroot = qz_white_root();
    QZLayerRef qtl = QZTransformLayerCreate();
    QZLayerSetFrame(qtl, QZRectMake(0, 0, kW, kH));
    QZLayerRef qred = qz_square(20, 44, 1, 0, 0);
    QZLayerRef qblue = qz_square(68, 44, 0, 0, 1);
    QZLayerAddSublayer(qtl, qred);
    QZLayerAddSublayer(qtl, qblue);
    QZLayerAddSublayer(qroot, qtl);
    QZLayerRenderInContext(qroot, qc);

    QZContextRef nc = qz_ctx();
    QZLayerRef nroot = qz_white_root();
    QZLayerRef npar = QZLayerCreate();
    QZLayerSetFrame(npar, QZRectMake(0, 0, kW, kH));
    QZLayerRef nred = qz_square(20, 44, 1, 0, 0);
    QZLayerRef nblue = qz_square(68, 44, 0, 0, 1);
    QZLayerAddSublayer(npar, nred);
    QZLayerAddSublayer(npar, nblue);
    QZLayerAddSublayer(nroot, npar);
    QZLayerRenderInContext(nroot, nc);

    int fail = 0;
    fail |= check_qz_qz("identity vs normal parent", qc, nc, 0.01);
    fail |= check_pix("identity two squares", ac, qc, 1.0, 99.0);

    QZLayerRelease(qroot); QZLayerRelease(qtl); QZLayerRelease(qred); QZLayerRelease(qblue);
    QZLayerRelease(nroot); QZLayerRelease(npar); QZLayerRelease(nred); QZLayerRelease(nblue);
    QZContextRelease(qc); QZContextRelease(nc);
    CGContextRelease(ac);
    return fail;
}

/* 2. Child CATransform3DMakeRotation(0.4, 0,0,1) vs Apple. */
static int test_child_z_rotation(void) {
    CATransform3D rot = CATransform3DMakeRotation(0.4, 0, 0, 1);

    CGContextRef ac = apple_ctx();
    CALayer *aroot = apple_white_root();
    CATransformLayer *atl = [CATransformLayer layer];
    atl.frame = CGRectMake(0, 0, kW, kH);
    CALayer *asq = apple_square(44, 44, 1, 0, 0);
    asq.transform = rot;
    [atl addSublayer:asq];
    [aroot addSublayer:atl];
    [aroot renderInContext:ac];

    QZContextRef qc = qz_ctx();
    QZLayerRef qroot = qz_white_root();
    QZLayerRef qtl = QZTransformLayerCreate();
    QZLayerSetFrame(qtl, QZRectMake(0, 0, kW, kH));
    QZLayerRef qsq = qz_square(44, 44, 1, 0, 0);
    QZLayerSetTransform(qsq, qz_t3d(rot));
    QZLayerAddSublayer(qtl, qsq);
    QZLayerAddSublayer(qroot, qtl);
    QZLayerRenderInContext(qroot, qc);

    int fail = check_pix("child z-rot 0.4", ac, qc, 2.0, 97.0);

    QZLayerRelease(qroot); QZLayerRelease(qtl); QZLayerRelease(qsq);
    QZContextRelease(qc);
    CGContextRelease(ac);
    return fail;
}

/* 3. Parent sublayerTransform z rotation: children rotate together vs Apple. */
static int test_parent_sublayer_transform(void) {
    CATransform3D rot = CATransform3DMakeRotation(0.4, 0, 0, 1);

    CGContextRef ac = apple_ctx();
    CALayer *aroot = apple_white_root();
    CATransformLayer *atl = [CATransformLayer layer];
    atl.frame = CGRectMake(0, 0, kW, kH);
    atl.sublayerTransform = rot;
    [atl addSublayer:apple_square(20, 44, 1, 0, 0)];
    [atl addSublayer:apple_square(68, 44, 0, 0, 1)];
    [aroot addSublayer:atl];
    [aroot renderInContext:ac];

    QZContextRef qc = qz_ctx();
    QZLayerRef qroot = qz_white_root();
    QZLayerRef qtl = QZTransformLayerCreate();
    QZLayerSetFrame(qtl, QZRectMake(0, 0, kW, kH));
    QZLayerSetSublayerTransform(qtl, qz_t3d(rot));
    QZLayerRef qred = qz_square(20, 44, 1, 0, 0);
    QZLayerRef qblue = qz_square(68, 44, 0, 0, 1);
    QZLayerAddSublayer(qtl, qred);
    QZLayerAddSublayer(qtl, qblue);
    QZLayerAddSublayer(qroot, qtl);
    QZLayerRenderInContext(qroot, qc);

    int fail = check_pix("parent sublayerTransform z-rot", ac, qc, 2.0, 97.0);

    QZLayerRelease(qroot); QZLayerRelease(qtl); QZLayerRelease(qred); QZLayerRelease(qblue);
    QZContextRelease(qc);
    CGContextRelease(ac);
    return fail;
}

int main(void) {
    int fail = 0;
    fail |= test_identity_two_squares();
    fail |= test_child_z_rotation();
    fail |= test_parent_sublayer_transform();
    if (fail) return qz_fail("transform_layer");
    qz_pass("transform_layer");
    return 0;
}
