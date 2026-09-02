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

static int max_channel_diff(const uint8_t *a, size_t abpr,
                            const uint8_t *b, size_t bbpr) {
    int md = 0;
    for (int y = 0; y < kH; y++) {
        const uint8_t *pa = a + (size_t)y * abpr;
        const uint8_t *pb = b + (size_t)y * bbpr;
        for (int x = 0; x < kW; x++) {
            for (int c = 0; c < 4; c++) {
                int d = abs((int)pa[x * 4 + c] - (int)pb[x * 4 + c]);
                if (d > md) md = d;
            }
        }
    }
    return md;
}

static int compare_fill(CGColorRef cgColor, QZColorRef qzColor, const char *tag) {
    CGContextRef cg = make_cg_ctx();
    QZContextRef qz = make_qz_ctx();
    if (!cg || !qz) {
        if (cg) CGContextRelease(cg);
        if (qz) QZContextRelease(qz);
        return qz_fail("bitmap create");
    }

    CGContextSetFillColorWithColor(cg, cgColor);
    CGContextFillRect(cg, CGRectMake(0, 0, kW, kH));

    QZContextSetFillColorWithColor(qz, qzColor);
    QZContextFillRect(qz, QZRectMake(0, 0, kW, kH));

    const uint8_t *ap = (const uint8_t *)CGBitmapContextGetData(cg);
    const uint8_t *qp = (const uint8_t *)QZBitmapContextGetData(qz);
    size_t abpr = CGBitmapContextGetBytesPerRow(cg);
    size_t qbpr = QZBitmapContextGetBytesPerRow(qz);
    int md = max_channel_diff(ap, abpr, qp, qbpr);

    CGContextRelease(cg);
    QZContextRelease(qz);

    if (md > 1) {
        char buf[128];
        snprintf(buf, sizeof(buf), "%s pixel maxdiff=%d", tag, md);
        return qz_fail(buf);
    }
    return 0;
}

static int check_components(QZColorRef qz, CGColorRef cg, const char *tag) {
    size_t qn = QZColorGetNumberOfComponents(qz);
    size_t cn = CGColorGetNumberOfComponents(cg);
    if (qn != cn) {
        char buf[128];
        snprintf(buf, sizeof(buf), "%s ncomp QZ=%zu CG=%zu", tag, qn, cn);
        return qz_fail(buf);
    }
    const QZFloat *qc = QZColorGetComponents(qz);
    const CGFloat *cc = CGColorGetComponents(cg);
    if (!qc || !cc) return qz_fail("null components");
    for (size_t i = 0; i < qn; i++) {
        if (fabs(qc[i] - cc[i]) > 1e-9) {
            char buf[128];
            snprintf(buf, sizeof(buf), "%s component[%zu] QZ=%g CG=%g", tag, i,
                     (double)qc[i], (double)cc[i]);
            return qz_fail(buf);
        }
    }
    return 0;
}

int main(void) {
    /* DeviceRGB */
    {
        QZColorSpaceRef qcs = QZColorSpaceCreateDeviceRGB();
        CGColorSpaceRef ccs = CGColorSpaceCreateDeviceRGB();
        if (!qcs || !ccs) return qz_fail("DeviceRGB space");
        QZFloat qcomp[4] = {0.2, 0.4, 0.6, 1.0};
        CGFloat ccomp[4] = {0.2, 0.4, 0.6, 1.0};
        QZColorRef qc = QZColorCreate(qcs, qcomp);
        CGColorRef cc = CGColorCreate(ccs, ccomp);
        if (!qc || !cc) return qz_fail("DeviceRGB color create");
        if (check_components(qc, cc, "DeviceRGB")) return 1;
        if (compare_fill(cc, qc, "DeviceRGB fill")) return 1;
        QZColorSpaceRelease(qcs);
        CGColorSpaceRelease(ccs);
        QZColorRelease(qc);
        CGColorRelease(cc);
    }

    /* sRGB name */
    {
        QZColorSpaceRef qcs = QZColorSpaceCreateWithNameSRGB();
        CGColorSpaceRef ccs = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
        if (!qcs || !ccs) return qz_fail("sRGB space");
        QZFloat qcomp[4] = {0.80, 0.10, 0.30, 1.0};
        CGFloat ccomp[4] = {0.80, 0.10, 0.30, 1.0};
        QZColorRef qc = QZColorCreate(qcs, qcomp);
        CGColorRef cc = CGColorCreate(ccs, ccomp);
        if (!qc || !cc) return qz_fail("sRGB color create");
        if (check_components(qc, cc, "sRGB")) return 1;
        if (compare_fill(cc, qc, "sRGB fill")) return 1;
        QZColorSpaceRelease(qcs);
        CGColorSpaceRelease(ccs);
        QZColorRelease(qc);
        CGColorRelease(cc);
    }

    /* DeviceGray expands to r=g=b */
    {
        QZColorSpaceRef qcs = QZColorSpaceCreateDeviceGray();
        CGColorSpaceRef ccs = CGColorSpaceCreateDeviceGray();
        if (!qcs || !ccs) return qz_fail("DeviceGray space");
        QZFloat qcomp[2] = {0.37, 1.0};
        CGFloat ccomp[2] = {0.37, 1.0};
        QZColorRef qc = QZColorCreate(qcs, qcomp);
        CGColorRef cc = CGColorCreate(ccs, ccomp);
        if (!qc || !cc) return qz_fail("DeviceGray color create");
        if (QZColorGetNumberOfComponents(qc) != 2)
            return qz_fail("DeviceGray ncomp");
        if (check_components(qc, cc, "DeviceGray")) return 1;
        if (compare_fill(cc, qc, "DeviceGray fill")) return 1;
        QZColorSpaceRelease(qcs);
        CGColorSpaceRelease(ccs);
        QZColorRelease(qc);
        CGColorRelease(cc);
    }

    /* Generic RGB + retain/release.
     * Apple GenericRGB is a calibrated space; QZ stores device RGB. Compare
     * fill against a DeviceRGB CGColor with the same components. */
    {
        QZColorRef qc = QZColorCreateGenericRGB(1, 0, 0, 1);
        CGColorRef cc = CGColorCreateGenericRGB(1, 0, 0, 1);
        if (!qc || !cc) return qz_fail("GenericRGB create");
        if (QZColorGetNumberOfComponents(qc) != 4)
            return qz_fail("GenericRGB ncomp");
        if (check_components(qc, cc, "GenericRGB")) return 1;

        CGColorSpaceRef dcs = CGColorSpaceCreateDeviceRGB();
        CGFloat rgb[4] = {1, 0, 0, 1};
        CGColorRef cc_dev = CGColorCreate(dcs, rgb);
        CGColorSpaceRelease(dcs);
        if (compare_fill(cc_dev, qc, "GenericRGB fill")) return 1;
        CGColorRelease(cc_dev);

        QZColorRetain(qc);
        QZColorRetain(qc);
        QZColorRelease(qc);
        QZColorRelease(qc);
        if (QZColorGetNumberOfComponents(qc) != 4)
            return qz_fail("retain/release ncomp");
        const QZFloat *c = QZColorGetComponents(qc);
        if (!c || c[0] != 1 || c[1] != 0 || c[2] != 0 || c[3] != 1)
            return qz_fail("retain/release comps");
        QZColorRelease(qc);
        CGColorRelease(cc);
    }

    /* Color keeps space alive after QZColorSpaceRelease */
    {
        QZColorSpaceRef qcs = QZColorSpaceCreateDeviceRGB();
        QZFloat qcomp[4] = {0, 1, 0, 1};
        QZColorRef qc = QZColorCreate(qcs, qcomp);
        QZColorSpaceRelease(qcs);
        CGColorSpaceRef ccs = CGColorSpaceCreateDeviceRGB();
        CGFloat ccomp[4] = {0, 1, 0, 1};
        CGColorRef cc = CGColorCreate(ccs, ccomp);
        CGColorSpaceRelease(ccs);
        if (compare_fill(cc, qc, "space released fill")) return 1;
        QZColorRelease(qc);
        CGColorRelease(cc);
    }

    /* Stroke color with color does not crash; gray stroke expands */
    {
        QZColorSpaceRef qcs = QZColorSpaceCreateDeviceGray();
        QZFloat g[2] = {0.5, 1.0};
        QZColorRef qc = QZColorCreate(qcs, g);
        QZContextRef qz = make_qz_ctx();
        QZContextSetStrokeColorWithColor(qz, qc);
        QZContextSetLineWidth(qz, kH);
        QZContextBeginPath(qz);
        QZContextMoveToPoint(qz, 0, kH / 2.0);
        QZContextAddLineToPoint(qz, kW, kH / 2.0);
        QZContextStrokePath(qz);
        QZContextRelease(qz);
        QZColorRelease(qc);
        QZColorSpaceRelease(qcs);
    }

    /* Null-safe */
    QZColorSpaceRelease(NULL);
    QZColorRelease(NULL);
    if (QZColorRetain(NULL) != NULL) return qz_fail("retain null");
    if (QZColorCreate(NULL, NULL) != NULL) return qz_fail("create null");
    if (QZColorGetNumberOfComponents(NULL) != 0) return qz_fail("ncomp null");
    if (QZColorGetComponents(NULL) != NULL) return qz_fail("comps null");

    qz_pass("color");
    return 0;
}
