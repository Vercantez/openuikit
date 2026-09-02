#import <Foundation/Foundation.h>
#include "test_common.h"
#include <stdarg.h>
#include <string.h>

static const int kW = 32;
static const int kH = 32;
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

static CGContextRef make_cg(void) {
    CGColorSpaceRef cs = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    CGContextRef ctx = CGBitmapContextCreate(
        NULL, kW, kH, 8, (size_t)kW * 4, cs,
        kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(cs);
    if (ctx) CGContextClearRect(ctx, CGRectMake(0, 0, kW, kH));
    return ctx;
}

static QZContextRef make_qz(void) {
    return QZBitmapContextCreate(NULL, kW, kH, 8, (size_t)kW * 4,
                                 kQZImageAlphaPremultipliedLast);
}

static bool pts_close(QZPoint q, CGPoint c, double tol) {
    return fabs(q.x - c.x) <= tol && fabs(q.y - c.y) <= tol;
}

static bool sizes_close(QZSize q, CGSize c, double tol) {
    return fabs(q.width - c.width) <= tol && fabs(q.height - c.height) <= tol;
}

static bool rects_close(QZRect q, CGRect c, double tol) {
    int qnull = !isfinite(q.origin.x) && !isfinite(q.origin.y);
    if (CGRectIsNull(c)) return qnull;
    if (qnull) return false;
    return fabs(q.origin.x - c.origin.x) <= tol &&
           fabs(q.origin.y - c.origin.y) <= tol &&
           fabs(q.size.width - c.size.width) <= tol &&
           fabs(q.size.height - c.size.height) <= tol;
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

static const uint8_t *pix_user(const uint8_t *base, size_t bpr, int ux, int uy) {
    int my = kH - 1 - uy;
    return base + (size_t)my * bpr + (size_t)ux * 4;
}

int main(void) {
    /* Convert point/size/rect after TranslateCTM — device space is y-down. */
    {
        CGContextRef cg = make_cg();
        QZContextRef qz = make_qz();
        CGContextTranslateCTM(cg, 5, 10);
        QZContextTranslateCTM(qz, 5, 10);

        QZPoint qp = QZContextConvertPointToDeviceSpace(qz, QZPointMake(3, 4));
        CGPoint cp = CGContextConvertPointToDeviceSpace(cg, CGPointMake(3, 4));
        if (!pts_close(qp, cp, 1e-9)) {
            failf("convert point to device QZ(%.6f,%.6f) CG(%.6f,%.6f)",
                  qp.x, qp.y, cp.x, cp.y);
        }

        QZPoint qu = QZContextConvertPointToUserSpace(qz, QZPointMake(8, 24));
        CGPoint cu = CGContextConvertPointToUserSpace(cg, CGPointMake(8, 24));
        if (!pts_close(qu, cu, 1e-9)) {
            failf("convert point to user QZ(%.6f,%.6f) CG(%.6f,%.6f)",
                  qu.x, qu.y, cu.x, cu.y);
        }

        QZSize qs = QZContextConvertSizeToDeviceSpace(qz, QZSizeMake(10, 20));
        CGSize cs = CGContextConvertSizeToDeviceSpace(cg, CGSizeMake(10, 20));
        if (!sizes_close(qs, cs, 1e-9)) {
            failf("convert size to device QZ(%.6f,%.6f) CG(%.6f,%.6f)",
                  qs.width, qs.height, cs.width, cs.height);
        }

        QZSize qsu = QZContextConvertSizeToUserSpace(qz, QZSizeMake(10, 20));
        CGSize csu = CGContextConvertSizeToUserSpace(cg, CGSizeMake(10, 20));
        if (!sizes_close(qsu, csu, 1e-9)) {
            failf("convert size to user QZ(%.6f,%.6f) CG(%.6f,%.6f)",
                  qsu.width, qsu.height, csu.width, csu.height);
        }

        QZRect qr = QZContextConvertRectToDeviceSpace(qz, QZRectMake(4, 6, 8, 10));
        CGRect cr = CGContextConvertRectToDeviceSpace(cg, CGRectMake(4, 6, 8, 10));
        if (!rects_close(qr, cr, 1e-9)) {
            failf("convert rect to device QZ(%.6f,%.6f %.6fx%.6f) CG(%.6f,%.6f %.6fx%.6f)",
                  qr.origin.x, qr.origin.y, qr.size.width, qr.size.height,
                  cr.origin.x, cr.origin.y, cr.size.width, cr.size.height);
        }

        QZRect qru = QZContextConvertRectToUserSpace(qz, QZRectMake(4, 6, 8, 10));
        CGRect cru = CGContextConvertRectToUserSpace(cg, CGRectMake(4, 6, 8, 10));
        if (!rects_close(qru, cru, 1e-9)) {
            failf("convert rect to user QZ(%.6f,%.6f %.6fx%.6f) CG(%.6f,%.6f %.6fx%.6f)",
                  qru.origin.x, qru.origin.y, qru.size.width, qru.size.height,
                  cru.origin.x, cru.origin.y, cru.size.width, cru.size.height);
        }

        /* identity CTM: (0,0) user -> (0, height) device */
        CGContextRelease(cg);
        QZContextRelease(qz);
        cg = make_cg();
        qz = make_qz();
        qp = QZContextConvertPointToDeviceSpace(qz, QZPointMake(0, 0));
        cp = CGContextConvertPointToDeviceSpace(cg, CGPointMake(0, 0));
        if (!pts_close(qp, cp, 1e-9)) {
            failf("identity origin to device QZ(%.6f,%.6f) CG(%.6f,%.6f)",
                  qp.x, qp.y, cp.x, cp.y);
        }
        qp = QZContextConvertPointToDeviceSpace(qz, QZPointMake(8, 8));
        cp = CGContextConvertPointToDeviceSpace(cg, CGPointMake(8, 8));
        if (!pts_close(qp, cp, 1e-9)) {
            failf("identity (8,8) to device QZ(%.6f,%.6f) CG(%.6f,%.6f)",
                  qp.x, qp.y, cp.x, cp.y);
        }

        /* scale + translate round-trip */
        CGContextTranslateCTM(cg, 5, 10);
        QZContextTranslateCTM(qz, 5, 10);
        CGContextScaleCTM(cg, 2, 0.5);
        QZContextScaleCTM(qz, 2, 0.5);
        QZPoint orig = QZPointMake(3.25, 7.5);
        QZPoint dev = QZContextConvertPointToDeviceSpace(qz, orig);
        CGPoint cdev = CGContextConvertPointToDeviceSpace(cg, CGPointMake(3.25, 7.5));
        if (!pts_close(dev, cdev, 1e-9)) {
            failf("scale convert point QZ(%.6f,%.6f) CG(%.6f,%.6f)",
                  dev.x, dev.y, cdev.x, cdev.y);
        }
        QZPoint back = QZContextConvertPointToUserSpace(qz, dev);
        if (fabs(back.x - orig.x) > 1e-9 || fabs(back.y - orig.y) > 1e-9) {
            failf("convert round-trip QZ(%.6f,%.6f)", back.x, back.y);
        }

        /* rotation: rect uses all four corners */
        CGContextRelease(cg);
        QZContextRelease(qz);
        cg = make_cg();
        qz = make_qz();
        CGContextTranslateCTM(cg, 16, 16);
        QZContextTranslateCTM(qz, 16, 16);
        CGContextRotateCTM(cg, M_PI / 6);
        QZContextRotateCTM(qz, M_PI / 6);
        qr = QZContextConvertRectToDeviceSpace(qz, QZRectMake(1, 2, 5, 7));
        cr = CGContextConvertRectToDeviceSpace(cg, CGRectMake(1, 2, 5, 7));
        if (!rects_close(qr, cr, 1e-5)) {
            failf("rotated rect to device QZ(%.6f,%.6f %.6fx%.6f) CG(%.6f,%.6f %.6fx%.6f)",
                  qr.origin.x, qr.origin.y, qr.size.width, qr.size.height,
                  cr.origin.x, cr.origin.y, cr.size.width, cr.size.height);
        }
        qs = QZContextConvertSizeToDeviceSpace(qz, QZSizeMake(4, 2));
        cs = CGContextConvertSizeToDeviceSpace(cg, CGSizeMake(4, 2));
        if (!sizes_close(qs, cs, 1e-5)) {
            failf("rotated size to device QZ(%.6f,%.6f) CG(%.6f,%.6f)",
                  qs.width, qs.height, cs.width, cs.height);
        }
        CGContextRelease(cg);
        QZContextRelease(qz);
    }

    /* Gray fill pixel exact vs CG. */
    {
        CGContextRef cg = make_cg();
        QZContextRef qz = make_qz();
        CGContextSetGrayFillColor(cg, 0.5, 1);
        QZContextSetGrayFillColor(qz, 0.5, 1);
        CGContextFillRect(cg, CGRectMake(0, 0, 8, 8));
        QZContextFillRect(qz, QZRectMake(0, 0, 8, 8));

        const uint8_t *ap = (const uint8_t *)CGBitmapContextGetData(cg);
        const uint8_t *qp = (const uint8_t *)QZBitmapContextGetData(qz);
        size_t abpr = CGBitmapContextGetBytesPerRow(cg);
        size_t qbpr = QZBitmapContextGetBytesPerRow(qz);

        const uint8_t *a4 = pix_user(ap, abpr, 4, 4);
        const uint8_t *q4 = pix_user(qp, qbpr, 4, 4);
        if (a4[0] != 128 || a4[1] != 128 || a4[2] != 128 || a4[3] != 255) {
            failf("CG gray 0.5 expected 128 got %d %d %d %d", a4[0], a4[1], a4[2], a4[3]);
        }
        if (q4[0] != a4[0] || q4[1] != a4[1] || q4[2] != a4[2] || q4[3] != a4[3]) {
            failf("gray fill pixel QZ %d %d %d %d CG %d %d %d %d",
                  q4[0], q4[1], q4[2], q4[3], a4[0], a4[1], a4[2], a4[3]);
        }
        int md = max_channel_diff(ap, abpr, qp, qbpr);
        if (md > 1) failf("gray fill 0.5 maxdiff=%d", md);

        QZImageRef img = QZBitmapContextCreateImage(qz);
        if (!img || QZImageGetWidth(img) != (size_t)kW ||
            QZImageGetHeight(img) != (size_t)kH) {
            failf("create image size");
        }
        QZImageRelease(img);

        /* premul gray 0.5 alpha 0.5 */
        CGContextRelease(cg);
        QZContextRelease(qz);
        cg = make_cg();
        qz = make_qz();
        CGContextSetGrayFillColor(cg, 0.5, 0.5);
        QZContextSetGrayFillColor(qz, 0.5, 0.5);
        CGContextFillRect(cg, CGRectMake(0, 0, kW, kH));
        QZContextFillRect(qz, QZRectMake(0, 0, kW, kH));
        ap = (const uint8_t *)CGBitmapContextGetData(cg);
        qp = (const uint8_t *)QZBitmapContextGetData(qz);
        abpr = CGBitmapContextGetBytesPerRow(cg);
        qbpr = QZBitmapContextGetBytesPerRow(qz);
        a4 = pix_user(ap, abpr, 16, 16);
        q4 = pix_user(qp, qbpr, 16, 16);
        if (q4[0] != a4[0] || q4[1] != a4[1] || q4[2] != a4[2] || q4[3] != a4[3]) {
            failf("premul gray QZ %d %d %d %d CG %d %d %d %d",
                  q4[0], q4[1], q4[2], q4[3], a4[0], a4[1], a4[2], a4[3]);
        }
        md = max_channel_diff(ap, abpr, qp, qbpr);
        if (md > 1) failf("gray fill 0.5a maxdiff=%d", md);
        CGContextRelease(cg);
        QZContextRelease(qz);
    }

    /* Gray stroke. */
    {
        CGContextRef cg = make_cg();
        QZContextRef qz = make_qz();
        CGContextSetGrayStrokeColor(cg, 0.25, 1);
        QZContextSetGrayStrokeColor(qz, 0.25, 1);
        CGContextSetLineWidth(cg, kH);
        QZContextSetLineWidth(qz, kH);
        CGContextSetShouldAntialias(cg, false);
        QZContextSetShouldAntialias(qz, false);
        CGContextBeginPath(cg);
        CGContextMoveToPoint(cg, 0, kH / 2.0);
        CGContextAddLineToPoint(cg, kW, kH / 2.0);
        CGContextStrokePath(cg);
        QZContextBeginPath(qz);
        QZContextMoveToPoint(qz, 0, kH / 2.0);
        QZContextAddLineToPoint(qz, kW, kH / 2.0);
        QZContextStrokePath(qz);
        const uint8_t *ap = (const uint8_t *)CGBitmapContextGetData(cg);
        const uint8_t *qp = (const uint8_t *)QZBitmapContextGetData(qz);
        const uint8_t *a4 = pix_user(ap, CGBitmapContextGetBytesPerRow(cg), 16, 16);
        const uint8_t *q4 = pix_user(qp, QZBitmapContextGetBytesPerRow(qz), 16, 16);
        if (q4[0] != a4[0] || q4[1] != a4[1] || q4[2] != a4[2] || q4[3] != a4[3]) {
            failf("gray stroke QZ %d %d %d %d CG %d %d %d %d",
                  q4[0], q4[1], q4[2], q4[3], a4[0], a4[1], a4[2], a4[3]);
        }
        CGContextRelease(cg);
        QZContextRelease(qz);
    }

    /* Path query + CopyPath bbox. */
    {
        CGContextRef cg = make_cg();
        QZContextRef qz = make_qz();
        if (!QZContextIsPathEmpty(qz) || !CGContextIsPathEmpty(cg)) {
            failf("empty path not empty");
        }
        if (QZContextCopyPath(qz) != NULL) failf("copy empty path not NULL");
        QZRect qeb = QZContextGetPathBoundingBox(qz);
        CGRect ceb = CGContextGetPathBoundingBox(cg);
        if (!rects_close(qeb, ceb, 1e-9)) failf("empty path bbox");

        CGContextMoveToPoint(cg, 2, 3);
        CGContextAddLineToPoint(cg, 10, 20);
        CGContextAddLineToPoint(cg, 5, 8);
        CGContextClosePath(cg);
        QZContextMoveToPoint(qz, 2, 3);
        QZContextAddLineToPoint(qz, 10, 20);
        QZContextAddLineToPoint(qz, 5, 8);
        QZContextClosePath(qz);

        if (QZContextIsPathEmpty(qz) != (bool)CGContextIsPathEmpty(cg)) {
            failf("triangle isEmpty QZ=%d CG=%d", QZContextIsPathEmpty(qz),
                  CGContextIsPathEmpty(cg));
        }
        QZPoint qcur = QZContextGetPathCurrentPoint(qz);
        CGPoint ccur = CGContextGetPathCurrentPoint(cg);
        if (!pts_close(qcur, ccur, 1e-9)) {
            failf("path current QZ(%.6f,%.6f) CG(%.6f,%.6f)",
                  qcur.x, qcur.y, ccur.x, ccur.y);
        }
        QZRect qb = QZContextGetPathBoundingBox(qz);
        CGRect cb = CGContextGetPathBoundingBox(cg);
        if (!rects_close(qb, cb, 1e-9)) {
            failf("path bbox QZ(%.6f,%.6f %.6fx%.6f) CG(%.6f,%.6f %.6fx%.6f)",
                  qb.origin.x, qb.origin.y, qb.size.width, qb.size.height,
                  cb.origin.x, cb.origin.y, cb.size.width, cb.size.height);
        }

        QZPathRef qcopy = QZContextCopyPath(qz);
        CGPathRef ccopy = CGContextCopyPath(cg);
        if (!qcopy || !ccopy) {
            failf("copy path null");
        } else {
            QZRect qcb = QZPathGetBoundingBox(qcopy);
            CGRect ccb = CGPathGetBoundingBox(ccopy);
            if (!rects_close(qcb, ccb, 1e-9)) {
                failf("copy path bbox QZ(%.6f,%.6f %.6fx%.6f) CG(%.6f,%.6f %.6fx%.6f)",
                      qcb.origin.x, qcb.origin.y, qcb.size.width, qcb.size.height,
                      ccb.origin.x, ccb.origin.y, ccb.size.width, ccb.size.height);
            }
            QZPoint qcc = QZPathGetCurrentPoint(qcopy);
            CGPoint ccc = CGPathGetCurrentPoint(ccopy);
            if (!pts_close(qcc, ccc, 1e-9)) {
                failf("copy path current QZ(%.6f,%.6f) CG(%.6f,%.6f)",
                      qcc.x, qcc.y, ccc.x, ccc.y);
            }
        }
        if (qcopy) QZPathRelease(qcopy);
        if (ccopy) CGPathRelease(ccopy);
        CGContextRelease(cg);
        QZContextRelease(qz);
    }

    /* ResetClip: clip becomes infinite (all visible). */
    {
        CGContextRef cg = make_cg();
        QZContextRef qz = make_qz();
        CGContextClipToRect(cg, CGRectMake(4, 4, 8, 8));
        QZContextClipToRect(qz, QZRectMake(4, 4, 8, 8));
        CGContextResetClip(cg);
        QZContextResetClip(qz);
        CGContextSetRGBFillColor(cg, 0, 1, 0, 1);
        QZContextSetRGBFillColor(qz, 0, 1, 0, 1);
        CGContextFillRect(cg, CGRectMake(20, 20, 8, 8));
        QZContextFillRect(qz, QZRectMake(20, 20, 8, 8));
        const uint8_t *ap = (const uint8_t *)CGBitmapContextGetData(cg);
        const uint8_t *qp = (const uint8_t *)QZBitmapContextGetData(qz);
        const uint8_t *a4 = pix_user(ap, CGBitmapContextGetBytesPerRow(cg), 24, 24);
        const uint8_t *q4 = pix_user(qp, QZBitmapContextGetBytesPerRow(qz), 24, 24);
        if (a4[1] < 250) failf("CG reset clip did not fill outside old clip");
        if (q4[0] != a4[0] || q4[1] != a4[1] || q4[2] != a4[2] || q4[3] != a4[3]) {
            failf("reset clip fill QZ %d %d %d %d CG %d %d %d %d",
                  q4[0], q4[1], q4[2], q4[3], a4[0], a4[1], a4[2], a4[3]);
        }
        int md = max_channel_diff(ap, CGBitmapContextGetBytesPerRow(cg),
                                  qp, QZBitmapContextGetBytesPerRow(qz));
        if (md > 1) failf("reset clip fill maxdiff=%d", md);
        CGContextRelease(cg);
        QZContextRelease(qz);
    }

    /* Null-safe */
    QZContextResetClip(NULL);
    if (QZBitmapContextCreateImage(NULL) != NULL) failf("create image null");
    QZContextSetGrayFillColor(NULL, 0.5, 1);
    QZContextSetGrayStrokeColor(NULL, 0.5, 1);
    if (!QZContextIsPathEmpty(NULL)) failf("null path empty");

    if (g_fails) {
        fprintf(stderr, "FAIL context-misc (%d)\n", g_fails);
        return 1;
    }
    qz_pass("context-misc");
    return 0;
}
