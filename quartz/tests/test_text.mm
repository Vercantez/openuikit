#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#include "test_common.h"
#include <string.h>

#pragma clang diagnostic ignored "-Wdeprecated-declarations"

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

static void fill_white_cg(CGContextRef ctx) {
    CGContextSetRGBFillColor(ctx, 1, 1, 1, 1);
    CGContextFillRect(ctx, CGRectMake(0, 0, kW, kH));
}

static void fill_white_qz(QZContextRef ctx) {
    QZContextSetRGBFillColor(ctx, 1, 1, 1, 1);
    QZContextFillRect(ctx, QZRectMake(0, 0, kW, kH));
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
    for (int y = 0; y < kH && n < 12; y++) {
        const uint8_t *ar = a + (size_t)y * abpr;
        const uint8_t *qr = q + (size_t)y * qbpr;
        for (int x = 0; x < kW && n < 12; x++) {
            int md = 0;
            for (int c = 0; c < 4; c++) {
                int d = (int)ar[x * 4 + c] - (int)qr[x * 4 + c];
                if (d < 0) d = -d;
                if (d > md) md = d;
            }
            if (md <= 8) continue;
            fprintf(stderr,
                    "  %s mismatch mem(%d,%d) apple=%d %d %d %d qz=%d %d %d %d\n",
                    name, x, y, ar[x * 4], ar[x * 4 + 1], ar[x * 4 + 2], ar[x * 4 + 3],
                    qr[x * 4], qr[x * 4 + 1], qr[x * 4 + 2], qr[x * 4 + 3]);
            n++;
        }
    }
}

static int check_pix_lim(const char *name, CGContextRef ac, QZContextRef qc,
                         double min_close, double max_mae) {
    const uint8_t *ap = (const uint8_t *)CGBitmapContextGetData(ac);
    const uint8_t *qp = (const uint8_t *)QZBitmapContextGetData(qc);
    size_t abpr = CGBitmapContextGetBytesPerRow(ac);
    size_t qbpr = QZBitmapContextGetBytesPerRow(qc);
    double mae = mae_bufs(ap, abpr, qp, qbpr);
    double close = close_pct(ap, abpr, qp, qbpr);
    if (close >= min_close && mae < max_mae) {
        printf("PASS %s mae=%.4f close=%.2f%%\n", name, mae, close);
        return 0;
    }
    fprintf(stderr, "FAIL %s mae=%.4f close=%.2f%%\n", name, mae, close);
    dump_mismatch(name, ap, abpr, qp, qbpr);
    return 1;
}

static int check_pix(const char *name, CGContextRef ac, QZContextRef qc) {
    return check_pix_lim(name, ac, qc, 92.0, 8.0);
}

static int test_metrics(void) {
    CGContextRef ac = apple_ctx();
    QZContextRef qc = qz_ctx();

    CGContextSelectFont(ac, "Helvetica", 24, kCGEncodingMacRoman);
    QZContextSelectFont(qc, "Helvetica", 24);

    CGAffineTransform aid = CGAffineTransformIdentity;
    QZContextSetTextMatrix(qc, QZAffineTransformIdentity());
    CGContextSetTextMatrix(ac, aid);
    CGAffineTransform ag = CGContextGetTextMatrix(ac);
    QZAffineTransform qg = QZContextGetTextMatrix(qc);
    if (fabs(ag.a - qg.a) > 1e-9 || fabs(ag.d - qg.d) > 1e-9 ||
        fabs(ag.tx - qg.tx) > 1e-9 || fabs(ag.ty - qg.ty) > 1e-9) {
        fprintf(stderr, "FAIL text matrix identity apple=(%.4f,%.4f,%.4f,%.4f,%.4f,%.4f) "
                        "qz=(%.4f,%.4f,%.4f,%.4f,%.4f,%.4f)\n",
                ag.a, ag.b, ag.c, ag.d, ag.tx, ag.ty,
                qg.a, qg.b, qg.c, qg.d, qg.tx, qg.ty);
        QZContextRelease(qc);
        CGContextRelease(ac);
        return 1;
    }

    CGContextSetTextMatrix(ac, CGAffineTransformMakeScale(2, 3));
    QZContextSetTextMatrix(qc, QZAffineTransformMakeScale(2, 3));
    ag = CGContextGetTextMatrix(ac);
    qg = QZContextGetTextMatrix(qc);
    if (fabs(ag.a - 2) > 1e-9 || fabs(ag.d - 3) > 1e-9 ||
        fabs(qg.a - 2) > 1e-9 || fabs(qg.d - 3) > 1e-9) {
        fprintf(stderr, "FAIL text matrix scale apple a=%.4f d=%.4f qz a=%.4f d=%.4f\n",
                ag.a, ag.d, qg.a, qg.d);
        QZContextRelease(qc);
        CGContextRelease(ac);
        return 1;
    }

    CGContextSetTextMatrix(ac, CGAffineTransformIdentity);
    QZContextSetTextMatrix(qc, QZAffineTransformIdentity());
    CGContextSetTextPosition(ac, 10, 20);
    QZContextSetTextPosition(qc, 10, 20);
    CGContextShowText(ac, "Hello", 5);
    QZContextShowText(qc, "Hello", 5);
    CGPoint ap = CGContextGetTextPosition(ac);
    QZPoint qp = QZContextGetTextPosition(qc);
    double dx = ap.x - qp.x, dy = ap.y - qp.y;
    double err = sqrt(dx * dx + dy * dy);
    if (err > 0.75) {
        fprintf(stderr, "FAIL text pos after Hello apple=(%.4f,%.4f) qz=(%.4f,%.4f) err=%.4f\n",
                ap.x, ap.y, qp.x, qp.y, err);
        QZContextRelease(qc);
        CGContextRelease(ac);
        return 1;
    }
    printf("PASS metrics pos=(%.4f,%.4f) err=%.4f\n", qp.x, qp.y, err);
    QZContextRelease(qc);
    CGContextRelease(ac);
    return 0;
}

static int test_show_text_pixels(void) {
    CGContextRef ac = apple_ctx();
    QZContextRef qc = qz_ctx();
    fill_white_cg(ac);
    fill_white_qz(qc);

    CGContextSetRGBFillColor(ac, 0.1, 0.1, 0.15, 1);
    QZContextSetRGBFillColor(qc, 0.1, 0.1, 0.15, 1);
    CGContextSelectFont(ac, "Helvetica", 48, kCGEncodingMacRoman);
    QZContextSelectFont(qc, "Helvetica", 48);
    CGContextShowTextAtPoint(ac, 16, 40, "Ag", 2);
    QZContextShowTextAtPoint(qc, 16, 40, "Ag", 2);

    int fail = check_pix("ShowTextAtPoint Ag", ac, qc);
    QZContextRelease(qc);
    CGContextRelease(ac);
    return fail;
}

static int test_text_layer(void) {
    CGContextRef ac = apple_ctx();
    fill_white_cg(ac);

    CALayer *aroot = [CALayer layer];
    aroot.frame = CGRectMake(0, 0, kW, kH);
    CGColorRef w = cg_rgb(1, 1, 1, 1);
    aroot.backgroundColor = w;
    CGColorRelease(w);

    CATextLayer *atl = [CATextLayer layer];
    atl.string = @"Hi";
    atl.font = CFSTR("Helvetica");
    atl.fontSize = 36;
    atl.foregroundColor = CGColorGetConstantColor(kCGColorBlack);
    atl.frame = CGRectMake(10, 40, 120, 50);
    atl.contentsScale = 1;
    atl.wrapped = NO;
    atl.alignmentMode = kCAAlignmentLeft;
    [aroot addSublayer:atl];
    [aroot renderInContext:ac];

    QZContextRef qc = qz_ctx();
    QZLayerRef qroot = QZLayerCreate();
    QZLayerSetFrame(qroot, QZRectMake(0, 0, kW, kH));
    QZLayerSetBackgroundColor(qroot, 1, 1, 1, 1);
    QZLayerRef qtl = QZTextLayerCreate();
    QZTextLayerSetString(qtl, "Hi");
    QZTextLayerSetFontName(qtl, "Helvetica");
    QZTextLayerSetFontSize(qtl, 36);
    QZTextLayerSetForegroundColor(qtl, 0, 0, 0, 1);
    QZTextLayerSetAlignment(qtl, 0);
    QZTextLayerSetWrapped(qtl, false);
    QZLayerSetFrame(qtl, QZRectMake(10, 40, 120, 50));
    QZLayerAddSublayer(qroot, qtl);
    QZLayerRenderInContext(qroot, qc);

    int fail = check_pix("CATextLayer Hi", ac, qc);
    QZLayerRelease(qtl);
    QZLayerRelease(qroot);
    QZContextRelease(qc);
    CGContextRelease(ac);
    return fail;
}

static int test_stroke_text(void) {
    CGContextRef ac = apple_ctx();
    QZContextRef qc = qz_ctx();
    fill_white_cg(ac);
    fill_white_qz(qc);

    CGContextSetRGBStrokeColor(ac, 0.15, 0.10, 0.08, 1);
    QZContextSetRGBStrokeColor(qc, 0.15, 0.10, 0.08, 1);
    CGContextSetLineWidth(ac, 1);
    QZContextSetLineWidth(qc, 1);
    CGContextSelectFont(ac, "Helvetica", 48, kCGEncodingMacRoman);
    QZContextSelectFont(qc, "Helvetica", 48);
    CGContextSetTextDrawingMode(ac, kCGTextStroke);
    QZContextSetTextDrawingMode(qc, kQZTextStroke);
    if (QZContextGetTextDrawingMode(qc) != kQZTextStroke) {
        fprintf(stderr, "FAIL text drawing mode getter\n");
        QZContextRelease(qc);
        CGContextRelease(ac);
        return 1;
    }
    CGContextShowTextAtPoint(ac, 20, 40, "A", 1);
    QZContextShowTextAtPoint(qc, 20, 40, "A", 1);

    int fail = check_pix_lim("text stroke A", ac, qc, 90.0, 10.0);
    QZContextRelease(qc);
    CGContextRelease(ac);
    return fail;
}

static int test_fill_stroke_text(void) {
    CGContextRef ac = apple_ctx();
    QZContextRef qc = qz_ctx();
    fill_white_cg(ac);
    fill_white_qz(qc);

    CGContextSetRGBFillColor(ac, 0.15, 0.25, 0.70, 1);
    QZContextSetRGBFillColor(qc, 0.15, 0.25, 0.70, 1);
    CGContextSetRGBStrokeColor(ac, 0.75, 0.12, 0.10, 1);
    QZContextSetRGBStrokeColor(qc, 0.75, 0.12, 0.10, 1);
    CGContextSetLineWidth(ac, 1);
    QZContextSetLineWidth(qc, 1);
    CGContextSelectFont(ac, "Helvetica", 48, kCGEncodingMacRoman);
    QZContextSelectFont(qc, "Helvetica", 48);
    CGContextSetTextDrawingMode(ac, kCGTextFillStroke);
    QZContextSetTextDrawingMode(qc, kQZTextFillStroke);
    CGContextShowTextAtPoint(ac, 20, 40, "A", 1);
    QZContextShowTextAtPoint(qc, 20, 40, "A", 1);

    int fail = check_pix_lim("text fillStroke A", ac, qc, 90.0, 10.0);
    QZContextRelease(qc);
    CGContextRelease(ac);
    return fail;
}

static int test_clip_text(void) {
    CGContextRef ac = apple_ctx();
    QZContextRef qc = qz_ctx();
    fill_white_cg(ac);
    fill_white_qz(qc);

    CGContextSelectFont(ac, "Helvetica", 64, kCGEncodingMacRoman);
    QZContextSelectFont(qc, "Helvetica", 64);
    CGContextSetTextDrawingMode(ac, kCGTextClip);
    QZContextSetTextDrawingMode(qc, kQZTextClip);
    CGContextShowTextAtPoint(ac, 16, 32, "A", 1);
    QZContextShowTextAtPoint(qc, 16, 32, "A", 1);

    CGContextSetRGBFillColor(ac, 0.2, 0.6, 0.3, 1);
    QZContextSetRGBFillColor(qc, 0.2, 0.6, 0.3, 1);
    CGContextFillRect(ac, CGRectMake(0, 0, kW, kH));
    QZContextFillRect(qc, QZRectMake(0, 0, kW, kH));

    int fail = check_pix("text clip A then fill", ac, qc);
    QZContextRelease(qc);
    CGContextRelease(ac);
    return fail;
}

int main(void) {
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    int fails = 0;
    fails += test_metrics();
    fails += test_show_text_pixels();
    fails += test_text_layer();
    fails += test_stroke_text();
    fails += test_fill_stroke_text();
    fails += test_clip_text();
    [CATransaction commit];
    if (fails) return qz_fail("text");
    qz_pass("text");
    return 0;
}
