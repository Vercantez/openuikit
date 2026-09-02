#import <Foundation/Foundation.h>
#include "test_common.h"
#include <string.h>
#include <stdarg.h>

enum { kW = 64, kH = 64 };

static int g_fails = 0;

static void failf(const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    fprintf(stderr, "FAIL ");
    vfprintf(stderr, fmt, ap);
    fprintf(stderr, "\n");
    va_end(ap);
    g_fails++;
}

static CGColorSpaceRef srgb(void) {
    return CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
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

static bool pix_ok(const uint8_t *a, size_t abpr, const uint8_t *q, size_t qbpr,
                   const char *name) {
    double sae = 0;
    int64_t close = 0;
    int64_t n = (int64_t)kW * kH;
    int maxd = 0;
    for (int y = 0; y < kH; y++) {
        const uint8_t *ar = a + (size_t)y * abpr;
        const uint8_t *qr = q + (size_t)y * qbpr;
        for (int x = 0; x < kW; x++) {
            int pd = 0;
            for (int c = 0; c < 4; c++) {
                int d = (int)ar[x * 4 + c] - (int)qr[x * 4 + c];
                if (d < 0) d = -d;
                sae += d;
                if (d > pd) pd = d;
            }
            if (pd > maxd) maxd = pd;
            if (pd <= 8) close++;
        }
    }
    double mae = sae / (n * 4.0);
    double close_frac = (double)close / (double)n;
    int ok = (mae < 1.0) || (close_frac > 0.99);
    fprintf(stderr, "%s: mae=%.4f close<=8=%.2f%% max=%d %s\n",
            name, mae, close_frac * 100.0, maxd, ok ? "ok" : "BAD");
    if (!ok) failf("%s mae=%.4f close=%.2f%%", name, mae, close_frac * 100.0);
    return ok != 0;
}

static int check_ctx(const char *name, CGContextRef ac, QZContextRef qc) {
    const uint8_t *ap = (const uint8_t *)CGBitmapContextGetData(ac);
    const uint8_t *qp = (const uint8_t *)QZBitmapContextGetData(qc);
    size_t abpr = CGBitmapContextGetBytesPerRow(ac);
    size_t qbpr = QZBitmapContextGetBytesPerRow(qc);
    return pix_ok(ap, abpr, qp, qbpr, name) ? 0 : 1;
}

static void test_stroke_line(void) {
    CGMutablePathRef cp = CGPathCreateMutable();
    CGPathMoveToPoint(cp, NULL, 8, 32);
    CGPathAddLineToPoint(cp, NULL, 56, 32);
    CGPathRef cs = CGPathCreateCopyByStrokingPath(cp, NULL, 6,
                                                  kCGLineCapButt, kCGLineJoinMiter, 10);

    QZMutablePathRef qp = QZPathCreateMutable();
    QZPathMoveToPoint(qp, NULL, 8, 32);
    QZPathAddLineToPoint(qp, NULL, 56, 32);
    QZPathRef qs = QZPathCreateCopyByStrokingPath(qp, NULL, 6,
                                                 kQZLineCapButt, kQZLineJoinMiter, 10);
    if (!qs) {
        failf("stroke line copy is NULL");
        CGPathRelease(cs);
        CGPathRelease(cp);
        QZPathRelease(qp);
        return;
    }

    CGContextRef ac = apple_ctx();
    QZContextRef qc = qz_ctx();
    CGContextSetRGBFillColor(ac, 0, 0, 0, 1);
    QZContextSetRGBFillColor(qc, 0, 0, 0, 1);
    CGContextAddPath(ac, cs);
    CGContextFillPath(ac);
    QZContextAddPath(qc, qs);
    QZContextFillPath(qc);
    check_ctx("stroke line fill", ac, qc);

    CGContextRelease(ac);
    QZContextRelease(qc);
    CGPathRelease(cs);
    CGPathRelease(cp);
    QZPathRelease(qs);
    QZPathRelease(qp);
}

static void test_stroke_polyline(void) {
    CGMutablePathRef cp = CGPathCreateMutable();
    CGPathMoveToPoint(cp, NULL, 10, 14);
    CGPathAddLineToPoint(cp, NULL, 48, 22);
    CGPathAddLineToPoint(cp, NULL, 40, 48);
    CGPathAddLineToPoint(cp, NULL, 14, 54);

    QZMutablePathRef qp = QZPathCreateMutable();
    QZPathMoveToPoint(qp, NULL, 10, 14);
    QZPathAddLineToPoint(qp, NULL, 48, 22);
    QZPathAddLineToPoint(qp, NULL, 40, 48);
    QZPathAddLineToPoint(qp, NULL, 14, 54);

    CGPathRef cs = CGPathCreateCopyByStrokingPath(cp, NULL, 5,
                                                  kCGLineCapButt, kCGLineJoinMiter, 10);
    QZPathRef qs = QZPathCreateCopyByStrokingPath(qp, NULL, 5,
                                                 kQZLineCapButt, kQZLineJoinMiter, 10);
    if (!qs) {
        failf("stroke polyline copy is NULL");
        CGPathRelease(cs);
        CGPathRelease(cp);
        QZPathRelease(qp);
        return;
    }

    CGContextRef ac = apple_ctx();
    QZContextRef qc = qz_ctx();
    CGContextSetRGBFillColor(ac, 0.1, 0.1, 0.1, 1);
    QZContextSetRGBFillColor(qc, 0.1, 0.1, 0.1, 1);
    CGContextAddPath(ac, cs);
    CGContextFillPath(ac);
    QZContextAddPath(qc, qs);
    QZContextFillPath(qc);
    check_ctx("stroke polyline fill", ac, qc);

    CGContextRelease(ac);
    QZContextRelease(qc);
    CGPathRelease(cs);
    CGPathRelease(cp);
    QZPathRelease(qs);
    QZPathRelease(qp);
}

static void test_fill_rects(void) {
    CGContextRef ac = apple_ctx();
    QZContextRef qc = qz_ctx();
    CGContextSetRGBFillColor(ac, 1, 0, 0, 1);
    QZContextSetRGBFillColor(qc, 1, 0, 0, 1);
    CGRect crects[] = {
        CGRectMake(8, 8, 20, 16),
        CGRectMake(30, 20, 22, 18),
        CGRectMake(10, 40, 40, 12),
    };
    QZRect qrects[] = {
        QZRectMake(8, 8, 20, 16),
        QZRectMake(30, 20, 22, 18),
        QZRectMake(10, 40, 40, 12),
    };
    CGContextFillRects(ac, crects, 3);
    QZContextFillRects(qc, qrects, 3);
    check_ctx("FillRects", ac, qc);
    CGContextRelease(ac);
    QZContextRelease(qc);
}

static void test_stroke_line_segments(void) {
    CGContextRef ac = apple_ctx();
    QZContextRef qc = qz_ctx();
    CGContextSetRGBStrokeColor(ac, 0, 0, 0, 1);
    QZContextSetRGBStrokeColor(qc, 0, 0, 0, 1);
    CGContextSetLineWidth(ac, 3);
    QZContextSetLineWidth(qc, 3);
    CGContextSetLineCap(ac, kCGLineCapButt);
    QZContextSetLineCap(qc, kQZLineCapButt);

    CGPoint cpts[] = {
        CGPointMake(8, 10), CGPointMake(56, 10),
        CGPointMake(8, 32), CGPointMake(56, 40),
        CGPointMake(20, 56), CGPointMake(50, 20),
    };
    QZPoint qpts[] = {
        QZPointMake(8, 10), QZPointMake(56, 10),
        QZPointMake(8, 32), QZPointMake(56, 40),
        QZPointMake(20, 56), QZPointMake(50, 20),
    };
    CGContextStrokeLineSegments(ac, cpts, 6);
    QZContextStrokeLineSegments(qc, qpts, 6);
    check_ctx("StrokeLineSegments", ac, qc);
    CGContextRelease(ac);
    QZContextRelease(qc);
}

static void test_replace_stroked(void) {
    CGContextRef ac = apple_ctx();
    QZContextRef qc = qz_ctx();
    CGContextSetLineWidth(ac, 6);
    QZContextSetLineWidth(qc, 6);
    CGContextSetLineCap(ac, kCGLineCapButt);
    QZContextSetLineCap(qc, kQZLineCapButt);
    CGContextSetRGBFillColor(ac, 0, 0, 0, 1);
    QZContextSetRGBFillColor(qc, 0, 0, 0, 1);

    CGContextBeginPath(ac);
    CGContextMoveToPoint(ac, 10, 32);
    CGContextAddLineToPoint(ac, 54, 32);
    CGContextReplacePathWithStrokedPath(ac);
    CGContextFillPath(ac);

    QZContextBeginPath(qc);
    QZContextMoveToPoint(qc, 10, 32);
    QZContextAddLineToPoint(qc, 54, 32);
    QZContextReplacePathWithStrokedPath(qc);
    QZContextFillPath(qc);

    check_ctx("ReplacePathWithStrokedPath", ac, qc);
    CGContextRelease(ac);
    QZContextRelease(qc);
}

static void test_dash_copy(void) {
    CGMutablePathRef cp = CGPathCreateMutable();
    CGPathMoveToPoint(cp, NULL, 6, 32);
    CGPathAddLineToPoint(cp, NULL, 58, 32);
    CGFloat clen[] = {8, 4};
    CGPathRef cd = CGPathCreateCopyByDashingPath(cp, NULL, 0, clen, 2);

    QZMutablePathRef qp = QZPathCreateMutable();
    QZPathMoveToPoint(qp, NULL, 6, 32);
    QZPathAddLineToPoint(qp, NULL, 58, 32);
    QZFloat qlen[] = {8, 4};
    QZPathRef qd = QZPathCreateCopyByDashingPath(qp, NULL, 0, qlen, 2);
    if (!qd) {
        failf("dash copy is NULL");
        CGPathRelease(cd);
        CGPathRelease(cp);
        QZPathRelease(qp);
        return;
    }

    CGContextRef ac = apple_ctx();
    QZContextRef qc = qz_ctx();
    CGContextSetRGBStrokeColor(ac, 0, 0, 0, 1);
    QZContextSetRGBStrokeColor(qc, 0, 0, 0, 1);
    CGContextSetLineWidth(ac, 4);
    QZContextSetLineWidth(qc, 4);
    CGContextSetLineCap(ac, kCGLineCapButt);
    QZContextSetLineCap(qc, kQZLineCapButt);
    CGContextAddPath(ac, cd);
    CGContextStrokePath(ac);
    QZContextAddPath(qc, qd);
    QZContextStrokePath(qc);
    check_ctx("dash copy stroke", ac, qc);

    CGContextRelease(ac);
    QZContextRelease(qc);
    CGPathRelease(cd);
    CGPathRelease(cp);
    QZPathRelease(qd);
    QZPathRelease(qp);
}

static void test_nulls(void) {
    if (QZPathCreateCopyByStrokingPath(NULL, NULL, 2, kQZLineCapButt, kQZLineJoinMiter, 10))
        failf("stroke NULL path");
    if (QZPathCreateCopyByDashingPath(NULL, NULL, 0, NULL, 0))
        failf("dash NULL path");
    QZContextReplacePathWithStrokedPath(NULL);
    QZContextAddLines(NULL, NULL, 0);
    QZContextStrokeLineSegments(NULL, NULL, 0);
    QZContextFillRects(NULL, NULL, 0);

    QZMutablePathRef empty = QZPathCreateMutable();
    QZPathRef s = QZPathCreateCopyByStrokingPath(empty, NULL, 2, kQZLineCapButt,
                                                kQZLineJoinMiter, 10);
    if (!s) failf("stroke empty returned NULL");
    else QZPathRelease(s);
    QZPathRef d = QZPathCreateCopyByDashingPath(empty, NULL, 0, NULL, 0);
    if (!d) failf("dash empty returned NULL");
    else QZPathRelease(d);
    QZPathRelease(empty);
}

int main(void) {
    test_nulls();
    test_stroke_line();
    test_stroke_polyline();
    test_fill_rects();
    test_stroke_line_segments();
    test_replace_stroked();
    test_dash_copy();

    if (g_fails) {
        fprintf(stderr, "FAIL path-stroke (%d)\n", g_fails);
        return 1;
    }
    qz_pass("path-stroke");
    return 0;
}
