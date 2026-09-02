#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>
#include "test_common.h"
#include <string.h>

#pragma clang diagnostic ignored "-Wdeprecated-declarations"

enum { kW = 128, kH = 128 };

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

static int check_pix(const char *name, CGContextRef ac, QZContextRef qc) {
    const uint8_t *ap = (const uint8_t *)CGBitmapContextGetData(ac);
    const uint8_t *qp = (const uint8_t *)QZBitmapContextGetData(qc);
    size_t abpr = CGBitmapContextGetBytesPerRow(ac);
    size_t qbpr = QZBitmapContextGetBytesPerRow(qc);
    double mae = mae_bufs(ap, abpr, qp, qbpr);
    double close = close_pct(ap, abpr, qp, qbpr);
    if (close >= 90.0 && mae < 8.0) {
        printf("PASS %s mae=%.4f close=%.2f%%\n", name, mae, close);
        return 0;
    }
    fprintf(stderr, "FAIL %s mae=%.4f close=%.2f%%\n", name, mae, close);
    dump_mismatch(name, ap, abpr, qp, qbpr);
    return 1;
}

static bool metric_ok(double q, double a) {
    double d = fabs(q - a);
    double rel = fabs(a) > 1e-9 ? d / fabs(a) : d;
    return d < 0.5 || rel < 0.03;
}

static int test_metrics(void) {
    const double size = 24;
    CTFontRef ct = CTFontCreateWithName(CFSTR("Helvetica"), size, NULL);
    QZFontRef qf = QZFontCreateWithFontName("Helvetica", size);
    if (!ct || !qf) {
        if (ct) CFRelease(ct);
        if (qf) QZFontRelease(qf);
        fprintf(stderr, "FAIL font create\n");
        return 1;
    }

    struct {
        const char *name;
        double q;
        double a;
    } rows[] = {
        {"ascent", QZFontGetAscent(qf), CTFontGetAscent(ct)},
        {"descent", QZFontGetDescent(qf), CTFontGetDescent(ct)},
        {"leading", QZFontGetLeading(qf), CTFontGetLeading(ct)},
        {"capHeight", QZFontGetCapHeight(qf), CTFontGetCapHeight(ct)},
        {"xHeight", QZFontGetXHeight(qf), CTFontGetXHeight(ct)},
    };

    printf("Helvetica %.0fpt metrics vs CTFont\n", size);
    printf("%-10s %12s %12s %12s %10s\n", "metric", "CTFont", "QZ", "abs_err", "rel_err");
    int fail = 0;
    for (size_t i = 0; i < sizeof(rows) / sizeof(rows[0]); i++) {
        double d = fabs(rows[i].q - rows[i].a);
        double rel = fabs(rows[i].a) > 1e-9 ? d / fabs(rows[i].a) : d;
        printf("%-10s %12.6f %12.6f %12.6f %9.3f%%\n",
               rows[i].name, rows[i].a, rows[i].q, d, rel * 100.0);
        if (!metric_ok(rows[i].q, rows[i].a)) {
            fprintf(stderr, "FAIL metric %s QZ=%.6f CT=%.6f\n",
                    rows[i].name, rows[i].q, rows[i].a);
            fail = 1;
        }
    }

    if (QZFontGetSize(qf) != size) {
        fprintf(stderr, "FAIL size QZ=%.6f want=%.6f\n", QZFontGetSize(qf), size);
        fail = 1;
    }

    QZFontRelease(qf);
    CFRelease(ct);
    if (!fail) printf("PASS metrics\n");
    return fail;
}

static int test_advances(void) {
    const double size = 24;
    CTFontRef ct = CTFontCreateWithName(CFSTR("Helvetica"), size, NULL);
    QZFontRef qf = QZFontCreateWithFontName("Helvetica", size);
    const char *chars = "AiW ";
    size_t n = strlen(chars);
    UniChar uc[8];
    CGGlyph ag[8];
    CGSize aadv[8];
    QZGlyph qg[8];
    QZSize qadv[8];
    for (size_t i = 0; i < n; i++) uc[i] = (unsigned char)chars[i];
    CTFontGetGlyphsForCharacters(ct, uc, ag, (CFIndex)n);
    CTFontGetAdvancesForGlyphs(ct, kCTFontOrientationHorizontal, ag, aadv, (CFIndex)n);
    QZFontGetGlyphsForCharacters(qf, chars, n, qg);
    QZFontGetGlyphAdvances(qf, qg, n, qadv);

    printf("Helvetica %.0fpt glyph advances vs CTFont\n", size);
    printf("%-4s %8s %8s %12s %12s %12s\n",
           "ch", "CTgid", "QZgid", "CT_adv", "QZ_adv", "abs_err");
    int fail = 0;
    for (size_t i = 0; i < n; i++) {
        double d = fabs(qadv[i].width - aadv[i].width);
        printf("'%c'  %8u %8u %12.6f %12.6f %12.6f\n",
               chars[i], (unsigned)ag[i], (unsigned)qg[i],
               aadv[i].width, qadv[i].width, d);
        if (d >= 0.5) {
            fprintf(stderr, "FAIL advance '%c' QZ=%.6f CT=%.6f\n",
                    chars[i], qadv[i].width, aadv[i].width);
            fail = 1;
        }
        if (qg[i] != (QZGlyph)ag[i]) {
            fprintf(stderr, "FAIL glyph id '%c' QZ=%u CT=%u\n",
                    chars[i], (unsigned)qg[i], (unsigned)ag[i]);
            fail = 1;
        }
    }

    QZFontRelease(qf);
    CFRelease(ct);
    if (!fail) printf("PASS advances\n");
    return fail;
}

static int test_show_glyphs(void) {
    const double size = 48;
    CTFontRef ct = CTFontCreateWithName(CFSTR("Helvetica"), size, NULL);
    UniChar uc[2] = {'H', 'i'};
    CGGlyph ag[2];
    CTFontGetGlyphsForCharacters(ct, uc, ag, 2);
    CGFontRef cgfont = CTFontCopyGraphicsFont(ct, NULL);

    CGContextRef ac = apple_ctx();
    QZContextRef qc = qz_ctx();
    fill_white_cg(ac);
    fill_white_qz(qc);

    CGContextSetRGBFillColor(ac, 0.1, 0.1, 0.15, 1);
    CGContextSetFont(ac, cgfont);
    CGContextSetFontSize(ac, size);
    CGContextShowGlyphsAtPoint(ac, 16, 40, ag, 2);

    QZFontRef qf = QZFontCreateWithFontName("Helvetica", size);
    QZGlyph qg[2];
    QZFontGetGlyphsForCharacters(qf, "Hi", 2, qg);
    QZContextSetRGBFillColor(qc, 0.1, 0.1, 0.15, 1);
    QZContextSetFont(qc, qf);
    QZContextShowGlyphsAtPoint(qc, 16, 40, qg, 2);

    int fail = check_pix("ShowGlyphsAtPoint Hi", ac, qc);

    QZFontRelease(qf);
    QZContextRelease(qc);
    CGContextRelease(ac);
    CGFontRelease(cgfont);
    CFRelease(ct);
    return fail;
}

static int test_show_glyphs_with_advances(void) {
    const double size = 24;
    CTFontRef ct = CTFontCreateWithName(CFSTR("Helvetica"), size, NULL);
    UniChar uc[2] = {'H', 'i'};
    CGGlyph ag[2];
    CTFontGetGlyphsForCharacters(ct, uc, ag, 2);
    CGFontRef cgfont = CTFontCopyGraphicsFont(ct, NULL);

    QZFontRef qf = QZFontCreateWithFontName("Helvetica", size);
    QZGlyph qg[2];
    QZFontGetGlyphsForCharacters(qf, "Hi", 2, qg);

    int fail = 0;

    /* Custom user-space advances vs Apple ShowGlyphsWithAdvances. */
    {
        CGContextRef ac = apple_ctx();
        QZContextRef qc = qz_ctx();
        fill_white_cg(ac);
        fill_white_qz(qc);
        CGSize aadv[2] = {{20, 0}, {30, 0}};
        QZSize qadv[2] = {QZSizeMake(20, 0), QZSizeMake(30, 0)};

        CGContextSetRGBFillColor(ac, 0.1, 0.1, 0.15, 1);
        CGContextSetFont(ac, cgfont);
        CGContextSetFontSize(ac, size);
        CGContextSetTextPosition(ac, 16, 40);
        CGContextShowGlyphsWithAdvances(ac, ag, aadv, 2);

        QZContextSetRGBFillColor(qc, 0.1, 0.1, 0.15, 1);
        QZContextSetFont(qc, qf);
        QZContextSetTextPosition(qc, 16, 40);
        QZContextShowGlyphsWithAdvances(qc, qg, qadv, 2);

        fail += check_pix("ShowGlyphsWithAdvances custom", ac, qc);

        CGPoint ap = CGContextGetTextPosition(ac);
        QZPoint qp = QZContextGetTextPosition(qc);
        double dx = ap.x - qp.x, dy = ap.y - qp.y;
        double err = sqrt(dx * dx + dy * dy);
        if (err >= 0.5) {
            fprintf(stderr, "FAIL custom pos apple=(%.4f,%.4f) qz=(%.4f,%.4f)\n",
                    ap.x, ap.y, qp.x, qp.y);
            fail++;
        }
        QZContextRelease(qc);
        CGContextRelease(ac);
    }

    /* Default font advances should match Apple ShowGlyphsAtPoint. */
    {
        CGContextRef ac = apple_ctx();
        QZContextRef qc = qz_ctx();
        fill_white_cg(ac);
        fill_white_qz(qc);
        QZSize qadv[2];
        QZFontGetGlyphAdvances(qf, qg, 2, qadv);

        CGContextSetRGBFillColor(ac, 0.1, 0.1, 0.15, 1);
        CGContextSetFont(ac, cgfont);
        CGContextSetFontSize(ac, size);
        CGContextShowGlyphsAtPoint(ac, 16, 40, ag, 2);

        QZContextSetRGBFillColor(qc, 0.1, 0.1, 0.15, 1);
        QZContextSetFont(qc, qf);
        QZContextSetTextPosition(qc, 16, 40);
        QZContextShowGlyphsWithAdvances(qc, qg, qadv, 2);

        fail += check_pix("ShowGlyphsWithAdvances default vs AtPoint", ac, qc);
        QZContextRelease(qc);
        CGContextRelease(ac);
    }

    QZFontRelease(qf);
    CGFontRelease(cgfont);
    CFRelease(ct);
    return fail;
}

int main(void) {
    int fails = 0;
    fails += test_metrics();
    fails += test_advances();
    fails += test_show_glyphs();
    fails += test_show_glyphs_with_advances();
    if (fails) return qz_fail("font_ext");
    qz_pass("font_ext");
    return 0;
}
