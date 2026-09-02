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

static int test_offset_api(void) {
    QZLayerRef s = QZScrollLayerCreate();
    QZScrollLayerScrollToPoint(s, QZPointMake(10, 20));
    QZPoint p = QZScrollLayerGetScrollOffset(s);
    if (p.x != 10 || p.y != 20) {
        QZLayerRelease(s);
        return qz_fail("offset");
    }
    QZLayerSetFrame(s, QZRectMake(0, 0, 100, 100));
    QZScrollLayerScrollToRect(s, QZRectMake(80, 80, 40, 40));
    p = QZScrollLayerGetScrollOffset(s);
    if (fabs(p.x - 20) > 1e-9 || fabs(p.y - 20) > 1e-9) {
        fprintf(stderr, "FAIL scrollToRect offset got (%.1f,%.1f)\n", p.x, p.y);
        QZLayerRelease(s);
        return 1;
    }
    QZLayerRelease(s);
    printf("PASS offset api\n");
    return 0;
}

/* Nested CAScrollLayer: renderInContext applies bounds.origin. A 40x40 red
 * child at (80,80) after scrollToPoint(40,40) lands at (40,40). */
static int test_scroll_to_point_pixels(void) {
    CGColorRef white = cg_rgb(1, 1, 1, 1);
    CGColorRef red = cg_rgb(1, 0, 0, 1);

    CGContextRef ac = apple_ctx();
    CALayer *aroot = [CALayer layer];
    aroot.frame = CGRectMake(0, 0, kW, kH);
    aroot.backgroundColor = white;
    CAScrollLayer *asl = [CAScrollLayer layer];
    asl.frame = CGRectMake(0, 0, kW, kH);
    CALayer *ach = [CALayer layer];
    ach.frame = CGRectMake(80, 80, 40, 40);
    ach.backgroundColor = red;
    [asl addSublayer:ach];
    [asl scrollToPoint:CGPointMake(40, 40)];
    [aroot addSublayer:asl];
    [aroot renderInContext:ac];

    QZContextRef qc = qz_ctx();
    QZLayerRef qroot = QZLayerCreate();
    QZLayerSetFrame(qroot, QZRectMake(0, 0, kW, kH));
    QZLayerSetBackgroundColor(qroot, 1, 1, 1, 1);
    QZLayerRef qsl = QZScrollLayerCreate();
    QZLayerSetFrame(qsl, QZRectMake(0, 0, kW, kH));
    QZLayerRef qch = QZLayerCreate();
    QZLayerSetFrame(qch, QZRectMake(80, 80, 40, 40));
    QZLayerSetBackgroundColor(qch, 1, 0, 0, 1);
    QZLayerAddSublayer(qsl, qch);
    QZScrollLayerScrollToPoint(qsl, QZPointMake(40, 40));
    QZLayerAddSublayer(qroot, qsl);
    QZLayerRenderInContext(qroot, qc);

    int fail = check_pix("scrollToPoint(40,40) red 40x40", ac, qc, 1.0, 99.0);

    QZLayerRelease(qroot);
    QZLayerRelease(qsl);
    QZLayerRelease(qch);
    QZContextRelease(qc);
    CGContextRelease(ac);
    CGColorRelease(white);
    CGColorRelease(red);
    return fail;
}

static int test_unscrolled_pixels(void) {
    CGColorRef white = cg_rgb(1, 1, 1, 1);
    CGColorRef red = cg_rgb(1, 0, 0, 1);

    CGContextRef ac = apple_ctx();
    CALayer *aroot = [CALayer layer];
    aroot.frame = CGRectMake(0, 0, kW, kH);
    aroot.backgroundColor = white;
    CAScrollLayer *asl = [CAScrollLayer layer];
    asl.frame = CGRectMake(0, 0, kW, kH);
    CALayer *ach = [CALayer layer];
    ach.frame = CGRectMake(80, 80, 40, 40);
    ach.backgroundColor = red;
    [asl addSublayer:ach];
    [aroot addSublayer:asl];
    [aroot renderInContext:ac];

    QZContextRef qc = qz_ctx();
    QZLayerRef qroot = QZLayerCreate();
    QZLayerSetFrame(qroot, QZRectMake(0, 0, kW, kH));
    QZLayerSetBackgroundColor(qroot, 1, 1, 1, 1);
    QZLayerRef qsl = QZScrollLayerCreate();
    QZLayerSetFrame(qsl, QZRectMake(0, 0, kW, kH));
    QZLayerRef qch = QZLayerCreate();
    QZLayerSetFrame(qch, QZRectMake(80, 80, 40, 40));
    QZLayerSetBackgroundColor(qch, 1, 0, 0, 1);
    QZLayerAddSublayer(qsl, qch);
    QZLayerAddSublayer(qroot, qsl);
    QZLayerRenderInContext(qroot, qc);

    int fail = check_pix("unscrolled red 40x40", ac, qc, 1.0, 99.0);

    QZLayerRelease(qroot);
    QZLayerRelease(qsl);
    QZLayerRelease(qch);
    QZContextRelease(qc);
    CGContextRelease(ac);
    CGColorRelease(white);
    CGColorRelease(red);
    return fail;
}

int main(void) {
    int fail = 0;
    fail |= test_offset_api();
    fail |= test_unscrolled_pixels();
    fail |= test_scroll_to_point_pixels();
    if (fail) return qz_fail("scroll_layer");
    qz_pass("scroll_layer");
    return 0;
}
