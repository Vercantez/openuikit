#import <Foundation/Foundation.h>
#include "test_common.h"
#include <string.h>

enum { kW = 64, kH = 64 };

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

static double mae_bufs(const uint8_t *a, size_t abpr, const uint8_t *q, size_t qbpr) {
    double sae = 0;
    for (int y = 0; y < kH; y++) {
        const uint8_t *ar = a + (size_t)y * abpr;
        const uint8_t *qr = q + (size_t)y * qbpr;
        for (int x = 0; x < kW; x++) {
            for (int c = 0; c < 4; c++) {
                int d = (int)ar[x * 4 + c] - (int)qr[x * 4 + c];
                if (d < 0) d = -d;
                sae += d;
            }
        }
    }
    return sae / (kW * kH * 4.0);
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

static int check_mae(const char *name, CGContextRef ac, QZContextRef qc) {
    const uint8_t *ap = (const uint8_t *)CGBitmapContextGetData(ac);
    const uint8_t *qp = (const uint8_t *)QZBitmapContextGetData(qc);
    size_t abpr = CGBitmapContextGetBytesPerRow(ac);
    size_t qbpr = QZBitmapContextGetBytesPerRow(qc);
    double mae = mae_bufs(ap, abpr, qp, qbpr);
    if (mae >= 2.0) {
        fprintf(stderr, "FAIL %s mae=%.4f\n", name, mae);
        dump_mismatch(name, ap, abpr, qp, qbpr);
        return 1;
    }
    printf("PASS %s mae=%.4f\n", name, mae);
    return 0;
}

static CGImageRef cg_solid(int w, int h, CGFloat r, CGFloat g, CGFloat b, CGFloat a) {
    CGColorSpaceRef cs = srgb();
    CGContextRef c = CGBitmapContextCreate(
        NULL, w, h, 8, (size_t)w * 4, cs,
        kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(cs);
    CGContextSetRGBFillColor(c, r, g, b, a);
    CGContextFillRect(c, CGRectMake(0, 0, w, h));
    CGImageRef img = CGBitmapContextCreateImage(c);
    CGContextRelease(c);
    return img;
}

static QZImageRef qz_solid(int w, int h, uint8_t r, uint8_t g, uint8_t b, uint8_t a) {
    uint8_t *px = (uint8_t *)malloc((size_t)w * h * 4);
    for (int i = 0; i < w * h; i++) {
        px[i * 4 + 0] = r;
        px[i * 4 + 1] = g;
        px[i * 4 + 2] = b;
        px[i * 4 + 3] = a;
    }
    QZImageRef img = QZImageCreate((size_t)w, (size_t)h, px);
    free(px);
    return img;
}

static int test_insert_order(void) {
    CGContextRef ac = apple_ctx();
    CALayer *aroot = [CALayer layer];
    aroot.frame = CGRectMake(0, 0, kW, kH);
    CGColorRef w = cg_rgb(1, 1, 1, 1);
    aroot.backgroundColor = w;
    CGColorRelease(w);
    CALayer *ared = [CALayer layer];
    ared.frame = CGRectMake(8, 8, 32, 32);
    CGColorRef rc = cg_rgb(1, 0, 0, 1);
    ared.backgroundColor = rc;
    CGColorRelease(rc);
    CALayer *ablue = [CALayer layer];
    ablue.frame = CGRectMake(16, 16, 32, 32);
    CGColorRef bc = cg_rgb(0, 0, 1, 1);
    ablue.backgroundColor = bc;
    CGColorRelease(bc);
    [aroot insertSublayer:ared atIndex:0];
    [aroot insertSublayer:ablue atIndex:0]; /* blue at back, red on top */
    [aroot renderInContext:ac];

    QZContextRef qc = qz_ctx();
    QZLayerRef qroot = QZLayerCreate();
    QZLayerSetFrame(qroot, QZRectMake(0, 0, kW, kH));
    QZLayerSetBackgroundColor(qroot, 1, 1, 1, 1);
    QZLayerRef qred = QZLayerCreate();
    QZLayerSetFrame(qred, QZRectMake(8, 8, 32, 32));
    QZLayerSetBackgroundColor(qred, 1, 0, 0, 1);
    QZLayerRef qblue = QZLayerCreate();
    QZLayerSetFrame(qblue, QZRectMake(16, 16, 32, 32));
    QZLayerSetBackgroundColor(qblue, 0, 0, 1, 1);
    QZLayerInsertSublayer(qroot, qred, 0);
    QZLayerInsertSublayer(qroot, qblue, 0);
    QZLayerRenderInContext(qroot, qc);

    int fail = check_mae("insert order", ac, qc);
    QZLayerRelease(qroot);
    QZLayerRelease(qred);
    QZLayerRelease(qblue);
    QZContextRelease(qc);
    CGContextRelease(ac);
    return fail;
}

static int test_contents_gravity_center(void) {
    CGImageRef cimg = cg_solid(16, 16, 0, 1, 0, 1);
    CGContextRef ac = apple_ctx();
    CALayer *aroot = [CALayer layer];
    aroot.frame = CGRectMake(0, 0, kW, kH);
    CGColorRef w = cg_rgb(1, 1, 1, 1);
    aroot.backgroundColor = w;
    CGColorRelease(w);
    CALayer *al = [CALayer layer];
    al.frame = CGRectMake(8, 8, 48, 48);
    CGColorRef bg = cg_rgb(1, 0, 0, 1);
    al.backgroundColor = bg;
    CGColorRelease(bg);
    al.contents = (__bridge id)cimg;
    al.contentsGravity = kCAGravityCenter;
    [aroot addSublayer:al];
    [aroot renderInContext:ac];

    QZImageRef qimg = qz_solid(16, 16, 0, 255, 0, 255);
    QZContextRef qc = qz_ctx();
    QZLayerRef qroot = QZLayerCreate();
    QZLayerSetFrame(qroot, QZRectMake(0, 0, kW, kH));
    QZLayerSetBackgroundColor(qroot, 1, 1, 1, 1);
    QZLayerRef ql = QZLayerCreate();
    QZLayerSetFrame(ql, QZRectMake(8, 8, 48, 48));
    QZLayerSetBackgroundColor(ql, 1, 0, 0, 1);
    QZLayerSetContents(ql, qimg);
    QZLayerSetContentsGravity(ql, kQZContentsGravityCenter);
    QZLayerAddSublayer(qroot, ql);
    QZLayerRenderInContext(qroot, qc);

    int fail = check_mae("contentsGravity center", ac, qc);
    QZLayerRelease(qroot);
    QZLayerRelease(ql);
    QZImageRelease(qimg);
    QZContextRelease(qc);
    CGImageRelease(cimg);
    CGContextRelease(ac);
    return fail;
}

static int test_mask(void) {
    CGContextRef ac = apple_ctx();
    CALayer *aroot = [CALayer layer];
    aroot.frame = CGRectMake(0, 0, kW, kH);
    CGColorRef w = cg_rgb(1, 1, 1, 1);
    aroot.backgroundColor = w;
    CGColorRelease(w);
    CALayer *ared = [CALayer layer];
    ared.frame = CGRectMake(8, 8, 48, 48);
    CGColorRef rc = cg_rgb(1, 0, 0, 1);
    ared.backgroundColor = rc;
    CGColorRelease(rc);
    CALayer *amask = [CALayer layer];
    amask.frame = CGRectMake(0, 0, 24, 24);
    CGColorRef mc = cg_rgb(1, 1, 1, 1);
    amask.backgroundColor = mc;
    CGColorRelease(mc);
    ared.mask = amask;
    [aroot addSublayer:ared];
    [aroot renderInContext:ac];

    QZContextRef qc = qz_ctx();
    QZLayerRef qroot = QZLayerCreate();
    QZLayerSetFrame(qroot, QZRectMake(0, 0, kW, kH));
    QZLayerSetBackgroundColor(qroot, 1, 1, 1, 1);
    QZLayerRef qred = QZLayerCreate();
    QZLayerSetFrame(qred, QZRectMake(8, 8, 48, 48));
    QZLayerSetBackgroundColor(qred, 1, 0, 0, 1);
    QZLayerRef qmask = QZLayerCreate();
    QZLayerSetFrame(qmask, QZRectMake(0, 0, 24, 24));
    QZLayerSetBackgroundColor(qmask, 1, 1, 1, 1);
    QZLayerSetMask(qred, qmask);
    QZLayerAddSublayer(qroot, qred);
    QZLayerRenderInContext(qroot, qc);

    int fail = check_mae("mask", ac, qc);
    QZLayerRelease(qroot);
    QZLayerRelease(qred);
    QZLayerRelease(qmask);
    QZContextRelease(qc);
    CGContextRelease(ac);
    return fail;
}

static int test_convert_point(void) {
    CALayer *aroot = [CALayer layer];
    aroot.frame = CGRectMake(0, 0, 100, 100);
    CALayer *aa = [CALayer layer];
    aa.frame = CGRectMake(10, 20, 40, 50);
    CALayer *ab = [CALayer layer];
    ab.frame = CGRectMake(30, 10, 20, 20);
    [aroot addSublayer:aa];
    [aroot addSublayer:ab];
    CALayer *ad = [CALayer layer];
    ad.bounds = CGRectMake(0, 0, 40, 40);
    ad.position = CGPointMake(50, 50);
    ad.anchorPoint = CGPointMake(0.5, 0.5);
    ad.affineTransform = CGAffineTransformMakeRotation(0.4);
    [aroot addSublayer:ad];

    QZLayerRef qroot = QZLayerCreate();
    QZLayerSetFrame(qroot, QZRectMake(0, 0, 100, 100));
    QZLayerRef qa = QZLayerCreate();
    QZLayerSetFrame(qa, QZRectMake(10, 20, 40, 50));
    QZLayerRef qb = QZLayerCreate();
    QZLayerSetFrame(qb, QZRectMake(30, 10, 20, 20));
    QZLayerAddSublayer(qroot, qa);
    QZLayerAddSublayer(qroot, qb);
    QZLayerRef qd = QZLayerCreate();
    QZLayerSetBounds(qd, QZRectMake(0, 0, 40, 40));
    QZLayerSetPosition(qd, QZPointMake(50, 50));
    QZLayerSetAnchorPoint(qd, QZPointMake(0.5, 0.5));
    QZLayerSetAffineTransform(qd, QZAffineTransformMakeRotation(0.4));
    QZLayerAddSublayer(qroot, qd);

    struct {
        CALayer *from, *to;
        QZLayerRef qfrom, qto;
        CGPoint p;
        const char *name;
    } cases[] = {
        {aa, ab, qa, qb, CGPointMake(5, 5), "a->b"},
        {aa, aroot, qa, qroot, CGPointMake(5, 5), "a->root"},
        {aa, nil, qa, NULL, CGPointMake(5, 5), "a->nil"},
        {ad, aroot, qd, qroot, CGPointMake(0, 0), "rot origin"},
        {ad, aroot, qd, qroot, CGPointMake(20, 20), "rot center"},
    };
    int fail = 0;
    for (size_t i = 0; i < sizeof(cases) / sizeof(cases[0]); i++) {
        CGPoint ap = [cases[i].from convertPoint:cases[i].p toLayer:cases[i].to];
        QZPoint qp = QZLayerConvertPointToLayer(
            cases[i].qfrom, QZPointMake(cases[i].p.x, cases[i].p.y), cases[i].qto);
        double dx = ap.x - qp.x, dy = ap.y - qp.y;
        double err = sqrt(dx * dx + dy * dy);
        if (err > 0.02) {
            fprintf(stderr, "FAIL convertPoint %s apple=(%.3f,%.3f) qz=(%.3f,%.3f)\n",
                    cases[i].name, ap.x, ap.y, qp.x, qp.y);
            fail = 1;
        }
    }
    if (!fail) printf("PASS convertPoint\n");
    QZLayerRelease(qroot);
    QZLayerRelease(qa);
    QZLayerRelease(qb);
    QZLayerRelease(qd);
    return fail;
}

int main(void) {
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    int fails = 0;
    fails += test_insert_order();
    fails += test_contents_gravity_center();
    fails += test_mask();
    fails += test_convert_point();
    [CATransaction commit];
    if (fails) return qz_fail("layer-ext");
    qz_pass("layer-ext");
    return 0;
}
