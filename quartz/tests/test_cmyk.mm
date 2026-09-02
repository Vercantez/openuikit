#import <Foundation/Foundation.h>
#include "test_common.h"
#include <string.h>

static const int kW = 32;
static const int kH = 32;

static CGContextRef make_cg_ctx(void) {
    CGColorSpaceRef cs = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    CGContextRef ctx = CGBitmapContextCreate(
        NULL, kW, kH, 8, (size_t)kW * 4, cs,
        kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(cs);
    if (ctx) CGContextClearRect(ctx, CGRectMake(0, 0, kW, kH));
    return ctx;
}

static QZContextRef make_qz_ctx(void) {
    return QZBitmapContextCreate(NULL, kW, kH, 8, (size_t)kW * 4,
                                 kQZImageAlphaPremultipliedLast);
}

static int compare_pix(const char *tag, CGContextRef ac, QZContextRef qc,
                       double *out_mae, double *out_close) {
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
    if (out_mae) *out_mae = mae;
    if (out_close) *out_close = close;
    int ok = (close >= 99.0) && (mae < 1.0);
    fprintf(stderr, "%s: max=%d close<=8=%.2f%% mae=%.4f %s\n",
            tag, mx, close, mae, ok ? "ok" : "BAD");
    if (!ok) {
        int dumped = 0;
        for (int y = 0; y < kH && dumped < 8; y++) {
            const uint8_t *ar = a + (size_t)y * abpr;
            const uint8_t *qr = q + (size_t)y * qbpr;
            for (int x = 0; x < kW && dumped < 8; x++) {
                if (memcmp(ar + x * 4, qr + x * 4, 4) == 0) continue;
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

static int fill_cmyk(const char *tag, CGFloat c, CGFloat m, CGFloat y, CGFloat k,
                     CGFloat a, int via_color, double *mae, double *close) {
    CGContextRef cg = make_cg_ctx();
    QZContextRef qz = make_qz_ctx();
    if (!cg || !qz) {
        if (cg) CGContextRelease(cg);
        if (qz) QZContextRelease(qz);
        return qz_fail("bitmap create");
    }

    CGContextSetCMYKFillColor(cg, c, m, y, k, a);
    CGContextFillRect(cg, CGRectMake(0, 0, kW, kH));

    if (via_color) {
        QZColorRef col = QZColorCreateGenericCMYK(c, m, y, k, a);
        if (!col) {
            CGContextRelease(cg);
            QZContextRelease(qz);
            return qz_fail("QZColorCreateGenericCMYK");
        }
        QZContextSetFillColorWithColor(qz, col);
        QZColorRelease(col);
    } else {
        QZContextSetCMYKFillColor(qz, c, m, y, k, a);
    }
    QZContextFillRect(qz, QZRectMake(0, 0, kW, kH));

    int rc = compare_pix(tag, cg, qz, mae, close);
    CGContextRelease(cg);
    QZContextRelease(qz);
    return rc;
}

static int stroke_cmyk(const char *tag, CGFloat c, CGFloat m, CGFloat y, CGFloat k,
                       CGFloat a, double *mae, double *close) {
    CGContextRef cg = make_cg_ctx();
    QZContextRef qz = make_qz_ctx();
    if (!cg || !qz) {
        if (cg) CGContextRelease(cg);
        if (qz) QZContextRelease(qz);
        return qz_fail("bitmap create");
    }

    CGContextSetCMYKStrokeColor(cg, c, m, y, k, a);
    CGContextSetLineWidth(cg, kH);
    CGContextSetLineCap(cg, kCGLineCapButt);
    CGContextBeginPath(cg);
    CGContextMoveToPoint(cg, 0, kH / 2.0);
    CGContextAddLineToPoint(cg, kW, kH / 2.0);
    CGContextStrokePath(cg);

    QZContextSetCMYKStrokeColor(qz, c, m, y, k, a);
    QZContextSetLineWidth(qz, kH);
    QZContextSetLineCap(qz, kQZLineCapButt);
    QZContextBeginPath(qz);
    QZContextMoveToPoint(qz, 0, kH / 2.0);
    QZContextAddLineToPoint(qz, kW, kH / 2.0);
    QZContextStrokePath(qz);

    int rc = compare_pix(tag, cg, qz, mae, close);
    CGContextRelease(cg);
    QZContextRelease(qz);
    return rc;
}

int main(void) {
    struct Sample {
        const char *tag;
        CGFloat c, m, y, k, a;
    };
    const Sample required[] = {
        {"C 1,0,0,0", 1, 0, 0, 0, 1},
        {"M 0,1,0,0", 0, 1, 0, 0, 1},
        {"Y 0,0,1,0", 0, 0, 1, 0, 1},
        {"K 0,0,0,1", 0, 0, 0, 1, 1},
        {"mix 0.2,0.4,0.1,0.1 a=0.8", 0.2, 0.4, 0.1, 0.1, 0.8},
    };

    double mae_sum = 0;
    int nmae = 0;
    int rc = 0;

    for (size_t i = 0; i < sizeof(required) / sizeof(required[0]); i++) {
        const Sample *s = &required[i];
        char tag[80];
        double mae = 0, close = 0;
        snprintf(tag, sizeof(tag), "SetCMYKFill %s", s->tag);
        rc |= fill_cmyk(tag, s->c, s->m, s->y, s->k, s->a, 0, &mae, &close);
        mae_sum += mae;
        nmae++;
        snprintf(tag, sizeof(tag), "GenericCMYK %s", s->tag);
        rc |= fill_cmyk(tag, s->c, s->m, s->y, s->k, s->a, 1, &mae, &close);
        mae_sum += mae;
        nmae++;
    }

    /* Grid lock: Apple DeviceCMYK vs QZ at n/8 samples (on LUT knots) plus
     * a few off-grid mixes. */
    const Sample grid[] = {
        {"paper", 0, 0, 0, 0, 1},
        {"C50", 0.5, 0, 0, 0, 1},
        {"M50", 0, 0.5, 0, 0, 1},
        {"Y50", 0, 0, 0.5, 0, 1},
        {"K50", 0, 0, 0, 0.5, 1},
        {"CMY", 1, 1, 1, 0, 1},
        {"rich black", 1, 1, 1, 1, 1},
        {"C+K", 1, 0, 0, 0.5, 1},
        {"eq 0.25", 0.25, 0.25, 0.25, 0, 1},
        {"eq 0.5+K", 0.5, 0.5, 0.5, 0.5, 1},
        {"offgrid", 0.1, 0.2, 0.3, 0.4, 1},
        {"alpha paper", 0, 0, 0, 0, 0.5},
        {"alpha C", 1, 0, 0, 0, 0.5},
    };
    for (size_t i = 0; i < sizeof(grid) / sizeof(grid[0]); i++) {
        const Sample *s = &grid[i];
        char tag[80];
        double mae = 0, close = 0;
        snprintf(tag, sizeof(tag), "grid %s", s->tag);
        rc |= fill_cmyk(tag, s->c, s->m, s->y, s->k, s->a, 0, &mae, &close);
        mae_sum += mae;
        nmae++;
    }

    {
        double mae = 0, close = 0;
        rc |= stroke_cmyk("SetCMYKStroke C", 1, 0, 0, 0, 1, &mae, &close);
        mae_sum += mae;
        nmae++;
    }

    QZColorSpaceRef dcs = QZColorSpaceCreateDeviceCMYK();
    if (!dcs) rc |= qz_fail("DeviceCMYK space");
    QZColorSpaceRelease(dcs);
    QZContextSetCMYKFillColor(NULL, 0, 0, 0, 1, 1);
    QZContextSetCMYKStrokeColor(NULL, 0, 0, 0, 1, 1);

    if (rc) return 1;
    printf("MAE %.4f (mean over cases)\n", mae_sum / nmae);
    qz_pass("cmyk");
    return 0;
}
