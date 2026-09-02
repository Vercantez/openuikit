#import <Foundation/Foundation.h>
#include "test_common.h"
#include <string.h>
#include <math.h>

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

static double close_pct(const uint8_t *a, size_t abpr, const uint8_t *q, size_t qbpr) {
    int close = 0;
    for (int y = 0; y < kH; y++) {
        const uint8_t *ar = a + (size_t)y * abpr;
        const uint8_t *qr = q + (size_t)y * qbpr;
        for (int x = 0; x < kW; x++) {
            int md = 0;
            for (int c = 0; c < 4; c++) {
                int d = (int)ar[x * 4 + c] - (int)qr[x * 4 + c];
                if (d < 0) d = -d;
                if (d > md) md = d;
            }
            if (md <= 8) close++;
        }
    }
    return 100.0 * close / (double)(kW * kH);
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

static int check_pix(const char *name, CGContextRef ac, QZContextRef qc) {
    const uint8_t *ap = (const uint8_t *)CGBitmapContextGetData(ac);
    const uint8_t *qp = (const uint8_t *)QZBitmapContextGetData(qc);
    size_t abpr = CGBitmapContextGetBytesPerRow(ac);
    size_t qbpr = QZBitmapContextGetBytesPerRow(qc);
    double mae = mae_bufs(ap, abpr, qp, qbpr);
    double close = close_pct(ap, abpr, qp, qbpr);
    if (mae < 2.0 || close >= 99.0) {
        printf("PASS %s mae=%.4f close=%.2f%%\n", name, mae, close);
        return 0;
    }
    fprintf(stderr, "FAIL %s mae=%.4f close=%.2f%%\n", name, mae, close);
    dump_mismatch(name, ap, abpr, qp, qbpr);
    return 1;
}

static int test_circle_stroke_end(void) {
    CGColorRef white = cg_rgb(1, 1, 1, 1);
    CGColorRef stroke = cg_rgb(0.85, 0.15, 0.12, 1);

    CGContextRef ac = apple_ctx();
    CALayer *aroot = [CALayer layer];
    aroot.frame = CGRectMake(0, 0, kW, kH);
    aroot.backgroundColor = white;
    CAShapeLayer *ashape = [CAShapeLayer layer];
    ashape.frame = CGRectMake(0, 0, kW, kH);
    ashape.fillColor = nil;
    ashape.strokeColor = stroke;
    ashape.lineWidth = 4;
    ashape.lineCap = kCALineCapButt;
    ashape.lineJoin = kCALineJoinMiter;
    ashape.miterLimit = 10;
    ashape.strokeStart = 0;
    ashape.strokeEnd = 0.5;
    CGMutablePathRef ap = CGPathCreateMutable();
    CGPathAddArc(ap, NULL, 32, 32, 22, 0, 2 * M_PI, true);
    CGPathCloseSubpath(ap);
    ashape.path = ap;
    CGPathRelease(ap);
    [aroot addSublayer:ashape];
    [aroot renderInContext:ac];

    QZContextRef qc = qz_ctx();
    QZLayerRef qroot = QZLayerCreate();
    QZLayerSetFrame(qroot, QZRectMake(0, 0, kW, kH));
    QZLayerSetBackgroundColor(qroot, 1, 1, 1, 1);
    QZLayerRef qshape = QZShapeLayerCreate();
    QZLayerSetFrame(qshape, QZRectMake(0, 0, kW, kH));
    QZShapeLayerSetFillColor(qshape, 0, 0, 0, 0);
    QZShapeLayerSetStrokeColor(qshape, 0.85, 0.15, 0.12, 1);
    QZShapeLayerSetLineWidth(qshape, 4);
    QZShapeLayerSetLineCap(qshape, kQZLineCapButt);
    QZShapeLayerSetLineJoin(qshape, kQZLineJoinMiter);
    QZShapeLayerSetMiterLimit(qshape, 10);
    QZShapeLayerSetStrokeStart(qshape, 0);
    QZShapeLayerSetStrokeEnd(qshape, 0.5);
    QZMutablePathRef qp = QZPathCreateMutable();
    QZPathAddArc(qp, NULL, 32, 32, 22, 0, 2 * M_PI, 1);
    QZPathCloseSubpath(qp);
    QZShapeLayerSetPath(qshape, qp);
    QZPathRelease(qp);
    QZLayerAddSublayer(qroot, qshape);
    QZLayerRenderInContext(qroot, qc);

    int fail = check_pix("circle strokeEnd=0.5", ac, qc);
    QZLayerRelease(qroot);
    QZLayerRelease(qshape);
    QZContextRelease(qc);
    CGContextRelease(ac);
    CGColorRelease(white);
    CGColorRelease(stroke);
    return fail;
}

static int test_dashed_rect(void) {
    CGColorRef white = cg_rgb(1, 1, 1, 1);
    CGColorRef stroke = cg_rgb(0.12, 0.25, 0.85, 1);

    CGContextRef ac = apple_ctx();
    CALayer *aroot = [CALayer layer];
    aroot.frame = CGRectMake(0, 0, kW, kH);
    aroot.backgroundColor = white;
    CAShapeLayer *ashape = [CAShapeLayer layer];
    ashape.frame = CGRectMake(0, 0, kW, kH);
    ashape.fillColor = nil;
    ashape.strokeColor = stroke;
    ashape.lineWidth = 4;
    ashape.lineCap = kCALineCapButt;
    ashape.lineJoin = kCALineJoinMiter;
    ashape.miterLimit = 10;
    ashape.lineDashPattern = @[@8, @5];
    ashape.lineDashPhase = 3;
    CGPathRef ap = CGPathCreateWithRect(CGRectMake(10, 12, 40, 36), NULL);
    ashape.path = ap;
    CGPathRelease(ap);
    [aroot addSublayer:ashape];
    [aroot renderInContext:ac];

    QZContextRef qc = qz_ctx();
    QZLayerRef qroot = QZLayerCreate();
    QZLayerSetFrame(qroot, QZRectMake(0, 0, kW, kH));
    QZLayerSetBackgroundColor(qroot, 1, 1, 1, 1);
    QZLayerRef qshape = QZShapeLayerCreate();
    QZLayerSetFrame(qshape, QZRectMake(0, 0, kW, kH));
    QZShapeLayerSetFillColor(qshape, 0, 0, 0, 0);
    QZShapeLayerSetStrokeColor(qshape, 0.12, 0.25, 0.85, 1);
    QZShapeLayerSetLineWidth(qshape, 4);
    QZShapeLayerSetLineCap(qshape, kQZLineCapButt);
    QZShapeLayerSetLineJoin(qshape, kQZLineJoinMiter);
    QZShapeLayerSetMiterLimit(qshape, 10);
    QZFloat dash[2] = {8, 5};
    QZShapeLayerSetLineDash(qshape, 3, dash, 2);
    QZMutablePathRef qp = QZPathCreateMutable();
    QZPathAddRect(qp, NULL, QZRectMake(10, 12, 40, 36));
    QZShapeLayerSetPath(qshape, qp);
    QZPathRelease(qp);
    QZLayerAddSublayer(qroot, qshape);
    QZLayerRenderInContext(qroot, qc);

    int fail = check_pix("dashed rect", ac, qc);
    QZLayerRelease(qroot);
    QZLayerRelease(qshape);
    QZContextRelease(qc);
    CGContextRelease(ac);
    CGColorRelease(white);
    CGColorRelease(stroke);
    return fail;
}

int main(void) {
    int fail = 0;
    fail += test_circle_stroke_end();
    fail += test_dashed_rect();
    if (fail) return qz_fail("shape-stroke");
    qz_pass("shape-stroke");
    return 0;
}
