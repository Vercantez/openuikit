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
    int ok = (close >= 99.5) && (mae < 0.5);
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

enum { kViaGenericP3 = 0, kViaSetFillColor = 1 };

static int fill_p3(const char *tag, CGFloat r, CGFloat g, CGFloat b, CGFloat a, int via) {
    CGContextRef cg = make_cg_ctx();
    QZContextRef qz = make_qz_ctx();
    if (!cg || !qz) {
        if (cg) CGContextRelease(cg);
        if (qz) QZContextRelease(qz);
        return qz_fail("bitmap create");
    }

    CGColorSpaceRef p3 = CGColorSpaceCreateWithName(kCGColorSpaceDisplayP3);
    CGFloat comps[4] = {r, g, b, a};
    CGColorRef cc = CGColorCreate(p3, comps);
    CGContextSetFillColorWithColor(cg, cc);
    CGContextFillRect(cg, CGRectMake(0, 0, kW, kH));
    CGColorRelease(cc);

    if (via == kViaGenericP3) {
        QZColorRef col = QZColorCreateGenericP3(r, g, b, a);
        if (!col) {
            CGColorSpaceRelease(p3);
            CGContextRelease(cg);
            QZContextRelease(qz);
            return qz_fail("QZColorCreateGenericP3");
        }
        QZContextSetFillColorWithColor(qz, col);
        QZColorRelease(col);
    } else {
        QZColorSpaceRef qp3 = QZColorSpaceCreateDisplayP3();
        if (!qp3) {
            CGColorSpaceRelease(p3);
            CGContextRelease(cg);
            QZContextRelease(qz);
            return qz_fail("QZColorSpaceCreateDisplayP3");
        }
        QZContextSetFillColorSpace(qz, qp3);
        QZFloat qcomp[4] = {r, g, b, a};
        QZContextSetFillColor(qz, qcomp);
        QZColorSpaceRelease(qp3);
    }
    QZContextFillRect(qz, QZRectMake(0, 0, kW, kH));

    int rc = compare_pix(tag, cg, qz);
    CGColorSpaceRelease(p3);
    CGContextRelease(cg);
    QZContextRelease(qz);
    return rc;
}

static int fill_tiles(const char *tag) {
    CGContextRef cg = make_cg_ctx();
    QZContextRef qz = make_qz_ctx();
    if (!cg || !qz) {
        if (cg) CGContextRelease(cg);
        if (qz) QZContextRelease(qz);
        return qz_fail("bitmap create");
    }

    struct Tile {
        CGFloat r, g, b, a;
        CGFloat x, y, w, h;
    };
    const Tile tiles[] = {
        {1, 0, 0, 1, 0, 0, 16, 16},           /* P3 red, outside sRGB */
        {0, 1, 0, 1, 16, 0, 16, 16},
        {0, 0, 1, 1, 0, 16, 16, 16},
        {0.2, 0.5, 0.8, 1, 16, 16, 16, 16},
        {1, 1, 1, 0.5, 8, 8, 16, 16},
        {0.9, 0.1, 0.2, 1, 20, 4, 8, 8},
        {0.1, 0.2, 0.3, 0.8, 4, 20, 10, 10},
    };

    CGColorSpaceRef p3 = CGColorSpaceCreateWithName(kCGColorSpaceDisplayP3);
    QZColorSpaceRef qp3 = QZColorSpaceCreateDisplayP3();
    CGContextSetFillColorSpace(cg, p3);
    QZContextSetFillColorSpace(qz, qp3);

    for (size_t i = 0; i < sizeof(tiles) / sizeof(tiles[0]); i++) {
        const Tile *t = &tiles[i];
        CGFloat c[4] = {t->r, t->g, t->b, t->a};
        QZFloat q[4] = {t->r, t->g, t->b, t->a};
        CGContextSetFillColor(cg, c);
        CGContextFillRect(cg, CGRectMake(t->x, t->y, t->w, t->h));
        QZContextSetFillColor(qz, q);
        QZContextFillRect(qz, QZRectMake(t->x, t->y, t->w, t->h));
    }

    int rc = compare_pix(tag, cg, qz);
    CGColorSpaceRelease(p3);
    QZColorSpaceRelease(qp3);
    CGContextRelease(cg);
    QZContextRelease(qz);
    return rc;
}

int main(void) {
    struct Sample {
        const char *tag;
        CGFloat r, g, b, a;
    };
    const Sample samples[] = {
        {"P3 red (OOG)", 1, 0, 0, 1},
        {"P3 green", 0, 1, 0, 1},
        {"P3 blue", 0, 0, 1, 1},
        {"P3 white", 1, 1, 1, 1},
        {"P3 mix 0.2,0.5,0.8", 0.2, 0.5, 0.8, 1},
        {"P3 black", 0, 0, 0, 1},
        {"P3 gray", 0.5, 0.5, 0.5, 1},
        {"P3 mid red", 0.5, 0, 0, 1},
        {"P3 in-gamut", 0.1, 0.2, 0.3, 1},
        {"P3-ish 0.9,0.1,0.2", 0.9, 0.1, 0.2, 1},
        {"P3 mix a=0.6", 0.2, 0.5, 0.8, 0.6},
        {"P3 red a=0.5", 1, 0, 0, 0.5},
        {"P3 yellow", 1, 1, 0, 1},
        {"P3 cyan", 0, 1, 1, 1},
        {"P3 magenta", 1, 0, 1, 1},
    };

    int rc = 0;
    for (size_t i = 0; i < sizeof(samples) / sizeof(samples[0]); i++) {
        const Sample *s = &samples[i];
        char tag[96];
        snprintf(tag, sizeof(tag), "GenericP3 %s", s->tag);
        rc |= fill_p3(tag, s->r, s->g, s->b, s->a, kViaGenericP3);
        snprintf(tag, sizeof(tag), "SetFillColor %s", s->tag);
        rc |= fill_p3(tag, s->r, s->g, s->b, s->a, kViaSetFillColor);
    }

    rc |= fill_tiles("P3 tiles");

    QZColorSpaceRef s = QZColorSpaceCreateDisplayP3();
    if (!s) rc |= qz_fail("p3 space");
    QZColorSpaceRelease(s);
    QZContextSetFillColorSpace(NULL, NULL);
    QZContextSetFillColor(NULL, NULL);
    QZColorRef z = QZColorCreateGenericP3(0, 0, 0, 0);
    if (!z) rc |= qz_fail("generic p3 zero");
    QZColorRelease(z);

    if (rc) return 1;
    qz_pass("color_p3");
    return 0;
}
