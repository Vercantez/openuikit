#import <Foundation/Foundation.h>
#include "test_common.h"
#include <stdarg.h>
#include <string.h>

enum { kMaxEl = 256, kW = 64, kH = 64 };

static int g_fails = 0;
static int g_apple_el_ok = 0;
static int g_apple_el_fail = 0;

static void failf(const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    fprintf(stderr, "FAIL ");
    vfprintf(stderr, fmt, ap);
    fprintf(stderr, "\n");
    va_end(ap);
    g_fails++;
}

static int npts_for(int type) {
    switch (type) {
    case kCGPathElementMoveToPoint: return 1;
    case kCGPathElementAddLineToPoint: return 1;
    case kCGPathElementAddQuadCurveToPoint: return 2;
    case kCGPathElementAddCurveToPoint: return 3;
    default: return 0;
    }
}

typedef struct {
    int type;
    int npts;
    double x[3], y[3];
} El;

typedef struct {
    El els[kMaxEl];
    int n;
} Bag;

static void qz_collect(void *info, const QZPathElement *e) {
    Bag *b = (Bag *)info;
    if (b->n >= kMaxEl) return;
    El *el = &b->els[b->n++];
    el->type = (int)e->type;
    el->npts = npts_for(el->type);
    for (int i = 0; i < el->npts; i++) {
        el->x[i] = e->points[i].x;
        el->y[i] = e->points[i].y;
    }
}

static void cg_collect(void *info, const CGPathElement *e) {
    Bag *b = (Bag *)info;
    if (b->n >= kMaxEl) return;
    El *el = &b->els[b->n++];
    el->type = (int)e->type;
    el->npts = npts_for(el->type);
    for (int i = 0; i < el->npts; i++) {
        el->x[i] = e->points[i].x;
        el->y[i] = e->points[i].y;
    }
}

static void qz_count(void *info, const QZPathElement *e) {
    (void)e;
    *(int *)info += 1;
}

static bool coord_close(double a, double b, double abs_eps, double rel_eps) {
    double d = fabs(a - b);
    double tol = abs_eps;
    double m = fabs(a) > fabs(b) ? fabs(a) : fabs(b);
    if (rel_eps * m > tol) tol = rel_eps * m;
    return d <= tol;
}

static bool el_close(const El *q, const El *c, double abs_eps, double rel_eps) {
    if (q->type != c->type) return false;
    if (q->npts != c->npts) return false;
    for (int i = 0; i < q->npts; i++) {
        if (!coord_close(q->x[i], c->x[i], abs_eps, rel_eps) ||
            !coord_close(q->y[i], c->y[i], abs_eps, rel_eps))
            return false;
    }
    return true;
}

static void compare_bags(const char *name, const Bag *q, const Bag *c,
                         double abs_eps, double rel_eps) {
    int n = q->n < c->n ? q->n : c->n;
    if (q->n != c->n) {
        failf("%s element count QZ=%d CG=%d", name, q->n, c->n);
    }
    for (int i = 0; i < n; i++) {
        if (el_close(&q->els[i], &c->els[i], abs_eps, rel_eps)) {
            g_apple_el_ok++;
        } else {
            g_apple_el_fail++;
            failf("%s el[%d] type QZ=%d CG=%d QZ(%.6f,%.6f %.6f,%.6f %.6f,%.6f) "
                  "CG(%.6f,%.6f %.6f,%.6f %.6f,%.6f)",
                  name, i, q->els[i].type, c->els[i].type,
                  q->els[i].x[0], q->els[i].y[0], q->els[i].x[1], q->els[i].y[1],
                  q->els[i].x[2], q->els[i].y[2],
                  c->els[i].x[0], c->els[i].y[0], c->els[i].x[1], c->els[i].y[1],
                  c->els[i].x[2], c->els[i].y[2]);
        }
    }
}

static void apply_both(QZPathRef qp, CGPathRef cp, Bag *qb, Bag *cb) {
    memset(qb, 0, sizeof(*qb));
    memset(cb, 0, sizeof(*cb));
    QZPathApply(qp, qb, qz_collect);
    CGPathApply(cp, cb, cg_collect);
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

static void fill_compare(const char *name, QZPathRef qp, CGPathRef cp) {
    CGContextRef ac = apple_ctx();
    QZContextRef qc = qz_ctx();
    CGContextSetRGBFillColor(ac, 0, 0, 0, 1);
    QZContextSetRGBFillColor(qc, 0, 0, 0, 1);
    CGContextAddPath(ac, cp);
    CGContextFillPath(ac);
    QZContextAddPath(qc, qp);
    QZContextFillPath(qc);

    const uint8_t *ap = (const uint8_t *)CGBitmapContextGetData(ac);
    const uint8_t *qpix = (const uint8_t *)QZBitmapContextGetData(qc);
    size_t abpr = CGBitmapContextGetBytesPerRow(ac);
    size_t qbpr = QZBitmapContextGetBytesPerRow(qc);
    double sae = 0;
    int64_t close = 0;
    int64_t n = (int64_t)kW * kH;
    int maxd = 0;
    for (int y = 0; y < kH; y++) {
        const uint8_t *ar = ap + (size_t)y * abpr;
        const uint8_t *qr = qpix + (size_t)y * qbpr;
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
    int ok = (close_frac >= 0.995) && (mae < 0.5);
    fprintf(stderr, "%s: mae=%.4f close<=8=%.2f%% max=%d %s\n",
            name, mae, close_frac * 100.0, maxd, ok ? "ok" : "BAD");
    if (!ok) failf("%s mae=%.4f close=%.2f%%", name, mae, close_frac * 100.0);
    CGContextRelease(ac);
    QZContextRelease(qc);
}

static void test_null_empty(void) {
    QZPathApply(NULL, NULL, qz_collect);
    if (QZPathGetElementCount(NULL) != 0) failf("NULL element count");

    QZMutablePathRef p = QZPathCreateMutable();
    int n = 0;
    QZPathApply(p, &n, qz_count);
    if (n != 0) failf("empty apply callbacks=%d", n);
    if (QZPathGetElementCount(p) != 0) failf("empty element count");
    QZPathApply(p, &n, NULL);
    QZPathAddArcToPoint(NULL, NULL, 1, 2, 3, 4, 5);
    QZPathAddArcToPoint(p, NULL, 1, 2, 3, 4, 5);
    if (QZPathGetElementCount(p) != 0) failf("arc-to with no current added elements");
    QZPathAddLines(NULL, NULL, NULL, 3);
    QZPoint dummy = QZPointMake(1, 1);
    QZPathAddLines(p, NULL, NULL, 3);
    QZPathAddLines(p, NULL, &dummy, 0);
    if (QZPathGetElementCount(p) != 0) failf("AddLines null/zero mutated path");
    QZPathRelease(p);
}

static void test_move_line_cubic_close(void) {
    QZMutablePathRef qp = QZPathCreateMutable();
    CGMutablePathRef cp = CGPathCreateMutable();
    QZPathMoveToPoint(qp, NULL, 0, 0);
    QZPathAddLineToPoint(qp, NULL, 10, 0);
    QZPathAddCurveToPoint(qp, NULL, 10, 10, 20, 10, 20, 0);
    QZPathCloseSubpath(qp);
    CGPathMoveToPoint(cp, NULL, 0, 0);
    CGPathAddLineToPoint(cp, NULL, 10, 0);
    CGPathAddCurveToPoint(cp, NULL, 10, 10, 20, 10, 20, 0);
    CGPathCloseSubpath(cp);

    Bag qb, cb;
    apply_both(qp, cp, &qb, &cb);
    if (QZPathGetElementCount(qp) != (size_t)qb.n)
        failf("GetElementCount %zu vs apply %d", QZPathGetElementCount(qp), qb.n);
    compare_bags("move/line/cubic/close", &qb, &cb, 1e-6, 0);

    QZPathRelease(qp);
    CGPathRelease(cp);
}

static void test_rect_ellipse(void) {
    QZMutablePathRef qp = QZPathCreateMutable();
    CGMutablePathRef cp = CGPathCreateMutable();
    QZPathAddRect(qp, NULL, QZRectMake(1, 2, 3, 4));
    CGPathAddRect(cp, NULL, CGRectMake(1, 2, 3, 4));
    Bag qb, cb;
    apply_both(qp, cp, &qb, &cb);
    compare_bags("rect", &qb, &cb, 1e-6, 0);
    QZPathRelease(qp);
    CGPathRelease(cp);

    qp = QZPathCreateMutable();
    cp = CGPathCreateMutable();
    QZPathAddEllipseInRect(qp, NULL, QZRectMake(0, 0, 40, 40));
    CGPathAddEllipseInRect(cp, NULL, CGRectMake(0, 0, 40, 40));
    apply_both(qp, cp, &qb, &cb);
    compare_bags("ellipse", &qb, &cb, 1e-4, 1e-4);
    QZPathRelease(qp);
    CGPathRelease(cp);
}

static void test_two_subpaths(void) {
    QZMutablePathRef qp = QZPathCreateMutable();
    CGMutablePathRef cp = CGPathCreateMutable();
    QZPathMoveToPoint(qp, NULL, 0, 0);
    QZPathAddLineToPoint(qp, NULL, 10, 0);
    QZPathMoveToPoint(qp, NULL, 0, 10);
    QZPathAddLineToPoint(qp, NULL, 10, 10);
    QZPathCloseSubpath(qp);
    CGPathMoveToPoint(cp, NULL, 0, 0);
    CGPathAddLineToPoint(cp, NULL, 10, 0);
    CGPathMoveToPoint(cp, NULL, 0, 10);
    CGPathAddLineToPoint(cp, NULL, 10, 10);
    CGPathCloseSubpath(cp);
    Bag qb, cb;
    apply_both(qp, cp, &qb, &cb);
    compare_bags("two subpaths", &qb, &cb, 1e-6, 0);
    QZPathRelease(qp);
    CGPathRelease(cp);
}

static void test_quad_elevated(void) {
    /* QZ stores quads as cubics (2/3 rule). Compare against elevated Apple quad. */
    QZMutablePathRef qp = QZPathCreateMutable();
    CGMutablePathRef cp = CGPathCreateMutable();
    QZPathMoveToPoint(qp, NULL, 0, 0);
    QZPathAddQuadCurveToPoint(qp, NULL, 10, 20, 20, 0);
    CGPathMoveToPoint(cp, NULL, 0, 0);
    CGPathAddQuadCurveToPoint(cp, NULL, 10, 20, 20, 0);

    Bag qb, cb;
    apply_both(qp, cp, &qb, &cb);
    if (qb.n != 2 || cb.n != 2) {
        failf("quad count QZ=%d CG=%d", qb.n, cb.n);
    } else {
        if (el_close(&qb.els[0], &cb.els[0], 1e-6, 0)) g_apple_el_ok++;
        else {
            g_apple_el_fail++;
            failf("quad move mismatch");
        }
        if (cb.els[1].type != kCGPathElementAddQuadCurveToPoint ||
            qb.els[1].type != kQZPathElementAddCurveToPoint) {
            failf("quad types QZ=%d CG=%d (QZ elevates to cubic)",
                  qb.els[1].type, cb.els[1].type);
            g_apple_el_fail++;
        } else {
            double p0x = cb.els[0].x[0], p0y = cb.els[0].y[0];
            double cx = cb.els[1].x[0], cy = cb.els[1].y[0];
            double px = cb.els[1].x[1], py = cb.els[1].y[1];
            double c1x = p0x + (cx - p0x) * (2.0 / 3.0);
            double c1y = p0y + (cy - p0y) * (2.0 / 3.0);
            double c2x = px + (cx - px) * (2.0 / 3.0);
            double c2y = py + (cy - py) * (2.0 / 3.0);
            El elev = cb.els[1];
            elev.type = kQZPathElementAddCurveToPoint;
            elev.npts = 3;
            elev.x[0] = c1x; elev.y[0] = c1y;
            elev.x[1] = c2x; elev.y[1] = c2y;
            elev.x[2] = px;  elev.y[2] = py;
            if (el_close(&qb.els[1], &elev, 1e-6, 0)) g_apple_el_ok++;
            else {
                g_apple_el_fail++;
                failf("quad elevated cubic mismatch QZ(%.6f,%.6f %.6f,%.6f %.6f,%.6f)",
                      qb.els[1].x[0], qb.els[1].y[0], qb.els[1].x[1], qb.els[1].y[1],
                      qb.els[1].x[2], qb.els[1].y[2]);
            }
        }
    }
    QZPathRelease(qp);
    CGPathRelease(cp);
}

static void test_add_lines(void) {
    QZPoint qpts[] = {
        QZPointMake(10, 20), QZPointMake(30, 40), QZPointMake(50, 60)
    };
    CGPoint cpts[] = {
        CGPointMake(10, 20), CGPointMake(30, 40), CGPointMake(50, 60)
    };

    /* empty path */
    QZMutablePathRef qp = QZPathCreateMutable();
    CGMutablePathRef cp = CGPathCreateMutable();
    QZPathAddLines(qp, NULL, qpts, 3);
    CGPathAddLines(cp, NULL, cpts, 3);
    Bag qb, cb;
    apply_both(qp, cp, &qb, &cb);
    compare_bags("AddLines empty", &qb, &cb, 1e-6, 0);
    QZPathRelease(qp);
    CGPathRelease(cp);

    /* existing current point: Apple starts a new subpath */
    qp = QZPathCreateMutable();
    cp = CGPathCreateMutable();
    QZPathMoveToPoint(qp, NULL, 0, 0);
    QZPathAddLineToPoint(qp, NULL, 5, 5);
    QZPathAddLines(qp, NULL, qpts, 3);
    CGPathMoveToPoint(cp, NULL, 0, 0);
    CGPathAddLineToPoint(cp, NULL, 5, 5);
    CGPathAddLines(cp, NULL, cpts, 3);
    apply_both(qp, cp, &qb, &cb);
    compare_bags("AddLines after current", &qb, &cb, 1e-6, 0);
    QZPathRelease(qp);
    CGPathRelease(cp);

    /* count = 1 is a move */
    qp = QZPathCreateMutable();
    cp = CGPathCreateMutable();
    QZPathAddLines(qp, NULL, qpts, 1);
    CGPathAddLines(cp, NULL, cpts, 1);
    apply_both(qp, cp, &qb, &cb);
    compare_bags("AddLines count=1", &qb, &cb, 1e-6, 0);
    QZPathRelease(qp);
    CGPathRelease(cp);

    /* transform */
    QZAffineTransform qt = QZAffineTransformMakeTranslation(1, 2);
    CGAffineTransform ct = CGAffineTransformMakeTranslation(1, 2);
    qp = QZPathCreateMutable();
    cp = CGPathCreateMutable();
    QZPathAddLines(qp, &qt, qpts, 3);
    CGPathAddLines(cp, &ct, cpts, 3);
    apply_both(qp, cp, &qb, &cb);
    compare_bags("AddLines translate", &qb, &cb, 1e-6, 0);
    QZPathRelease(qp);
    CGPathRelease(cp);

    QZAffineTransform qr = QZAffineTransformMakeRotation(0.3);
    CGAffineTransform cr = CGAffineTransformMakeRotation(0.3);
    qp = QZPathCreateMutable();
    cp = CGPathCreateMutable();
    QZPathAddLines(qp, &qr, qpts, 3);
    CGPathAddLines(cp, &cr, cpts, 3);
    apply_both(qp, cp, &qb, &cb);
    compare_bags("AddLines rotate", &qb, &cb, 1e-6, 0);
    QZPathRelease(qp);
    CGPathRelease(cp);
}

static void add_arc_to_both(QZMutablePathRef qp, CGMutablePathRef cp,
                            const QZAffineTransform *qm, const CGAffineTransform *cm,
                            double x0, double y0, double x1, double y1,
                            double x2, double y2, double r) {
    QZPathMoveToPoint(qp, qm, x0, y0);
    QZPathAddArcToPoint(qp, qm, x1, y1, x2, y2, r);
    CGPathMoveToPoint(cp, cm, x0, y0);
    CGPathAddArcToPoint(cp, cm, x1, y1, x2, y2, r);
}

static void test_arc_to_elements(void) {
    Bag qb, cb;

    QZMutablePathRef qp = QZPathCreateMutable();
    CGMutablePathRef cp = CGPathCreateMutable();
    add_arc_to_both(qp, cp, NULL, NULL, 0, 20, 40, 20, 40, 60, 10);
    apply_both(qp, cp, &qb, &cb);
    compare_bags("arc-to 90", &qb, &cb, 1e-3, 1e-4);
    QZPathRelease(qp);
    CGPathRelease(cp);

    qp = QZPathCreateMutable();
    cp = CGPathCreateMutable();
    add_arc_to_both(qp, cp, NULL, NULL, 0, 20, 40, 20, 40, 0, 10);
    apply_both(qp, cp, &qb, &cb);
    compare_bags("arc-to 90 cw", &qb, &cb, 1e-3, 1e-4);
    QZPathRelease(qp);
    CGPathRelease(cp);

    qp = QZPathCreateMutable();
    cp = CGPathCreateMutable();
    add_arc_to_both(qp, cp, NULL, NULL, 0, 0, 40, 0, 40, 10, 8);
    apply_both(qp, cp, &qb, &cb);
    compare_bags("arc-to acute", &qb, &cb, 1e-3, 1e-4);
    QZPathRelease(qp);
    CGPathRelease(cp);

    qp = QZPathCreateMutable();
    cp = CGPathCreateMutable();
    add_arc_to_both(qp, cp, NULL, NULL, 0, 0, 30, 0, 50, 40, 8);
    apply_both(qp, cp, &qb, &cb);
    compare_bags("arc-to obtuse", &qb, &cb, 1e-3, 1e-4);
    QZPathRelease(qp);
    CGPathRelease(cp);

    qp = QZPathCreateMutable();
    cp = CGPathCreateMutable();
    add_arc_to_both(qp, cp, NULL, NULL, 0, 0, 10, 0, 20, 0, 5);
    apply_both(qp, cp, &qb, &cb);
    compare_bags("arc-to collinear", &qb, &cb, 1e-3, 1e-4);
    QZPathRelease(qp);
    CGPathRelease(cp);

    QZAffineTransform qs = QZAffineTransformMakeScale(2, 2);
    CGAffineTransform cs = CGAffineTransformMakeScale(2, 2);
    qp = QZPathCreateMutable();
    cp = CGPathCreateMutable();
    add_arc_to_both(qp, cp, &qs, &cs, 0, 20, 40, 20, 40, 60, 10);
    apply_both(qp, cp, &qb, &cb);
    compare_bags("arc-to scale2", &qb, &cb, 1e-3, 1e-4);
    QZPathRelease(qp);
    CGPathRelease(cp);

    QZAffineTransform qt = QZAffineTransformMakeTranslation(5, 7);
    CGAffineTransform ct = CGAffineTransformMakeTranslation(5, 7);
    qp = QZPathCreateMutable();
    cp = CGPathCreateMutable();
    /* move in path space, arc-to with transform (mixed spaces) */
    QZPathMoveToPoint(qp, NULL, 0, 20);
    QZPathAddArcToPoint(qp, &qt, 40, 20, 40, 60, 10);
    CGPathMoveToPoint(cp, NULL, 0, 20);
    CGPathAddArcToPoint(cp, &ct, 40, 20, 40, 60, 10);
    apply_both(qp, cp, &qb, &cb);
    compare_bags("arc-to translate mixed", &qb, &cb, 1e-3, 1e-4);
    QZPathRelease(qp);
    CGPathRelease(cp);

    QZAffineTransform qr = QZAffineTransformMakeRotation(M_PI / 2);
    CGAffineTransform cr = CGAffineTransformMakeRotation(M_PI / 2);
    qp = QZPathCreateMutable();
    cp = CGPathCreateMutable();
    add_arc_to_both(qp, cp, &qr, &cr, 0, 20, 40, 20, 40, 60, 10);
    apply_both(qp, cp, &qb, &cb);
    compare_bags("arc-to rotate90", &qb, &cb, 1e-3, 1e-4);
    QZPathRelease(qp);
    CGPathRelease(cp);

    QZAffineTransform qn = QZAffineTransformMakeScale(2, 0.5);
    CGAffineTransform cn = CGAffineTransformMakeScale(2, 0.5);
    qp = QZPathCreateMutable();
    cp = CGPathCreateMutable();
    add_arc_to_both(qp, cp, &qn, &cn, 0, 20, 40, 20, 40, 60, 10);
    apply_both(qp, cp, &qb, &cb);
    compare_bags("arc-to nonuniform", &qb, &cb, 1e-3, 1e-4);
    QZPathRelease(qp);
    CGPathRelease(cp);
}

static void test_arc_to_fill(void) {
    QZMutablePathRef qp;
    CGMutablePathRef cp;

    qp = QZPathCreateMutable();
    cp = CGPathCreateMutable();
    QZPathMoveToPoint(qp, NULL, 8, 16);
    QZPathAddArcToPoint(qp, NULL, 56, 16, 56, 56, 12);
    QZPathAddLineToPoint(qp, NULL, 8, 56);
    QZPathCloseSubpath(qp);
    CGPathMoveToPoint(cp, NULL, 8, 16);
    CGPathAddArcToPoint(cp, NULL, 56, 16, 56, 56, 12);
    CGPathAddLineToPoint(cp, NULL, 8, 56);
    CGPathCloseSubpath(cp);
    fill_compare("fill arc-to corner", qp, cp);
    QZPathRelease(qp);
    CGPathRelease(cp);

    qp = QZPathCreateMutable();
    cp = CGPathCreateMutable();
    QZPathMoveToPoint(qp, NULL, 8, 16);
    QZPathAddLineToPoint(qp, NULL, 8, 48);
    QZPathAddArcToPoint(qp, NULL, 8, 56, 16, 56, 8);
    QZPathAddLineToPoint(qp, NULL, 48, 56);
    QZPathAddArcToPoint(qp, NULL, 56, 56, 56, 48, 8);
    QZPathAddLineToPoint(qp, NULL, 56, 16);
    QZPathAddArcToPoint(qp, NULL, 56, 8, 48, 8, 8);
    QZPathAddLineToPoint(qp, NULL, 16, 8);
    QZPathAddArcToPoint(qp, NULL, 8, 8, 8, 16, 8);
    QZPathCloseSubpath(qp);
    CGPathMoveToPoint(cp, NULL, 8, 16);
    CGPathAddLineToPoint(cp, NULL, 8, 48);
    CGPathAddArcToPoint(cp, NULL, 8, 56, 16, 56, 8);
    CGPathAddLineToPoint(cp, NULL, 48, 56);
    CGPathAddArcToPoint(cp, NULL, 56, 56, 56, 48, 8);
    CGPathAddLineToPoint(cp, NULL, 56, 16);
    CGPathAddArcToPoint(cp, NULL, 56, 8, 48, 8, 8);
    CGPathAddLineToPoint(cp, NULL, 16, 8);
    CGPathAddArcToPoint(cp, NULL, 8, 8, 8, 16, 8);
    CGPathCloseSubpath(cp);
    fill_compare("fill rounded-rect arc-to", qp, cp);
    QZPathRelease(qp);
    CGPathRelease(cp);

    QZAffineTransform qs = QZAffineTransformMakeScale(0.9, 1.1);
    CGAffineTransform cs = CGAffineTransformMakeScale(0.9, 1.1);
    qp = QZPathCreateMutable();
    cp = CGPathCreateMutable();
    QZPathMoveToPoint(qp, &qs, 10, 12);
    QZPathAddArcToPoint(qp, &qs, 50, 12, 50, 52, 10);
    QZPathAddLineToPoint(qp, &qs, 10, 52);
    QZPathCloseSubpath(qp);
    CGPathMoveToPoint(cp, &cs, 10, 12);
    CGPathAddArcToPoint(cp, &cs, 50, 12, 50, 52, 10);
    CGPathAddLineToPoint(cp, &cs, 10, 52);
    CGPathCloseSubpath(cp);
    fill_compare("fill arc-to scaled", qp, cp);
    QZPathRelease(qp);
    CGPathRelease(cp);

    qp = QZPathCreateMutable();
    cp = CGPathCreateMutable();
    QZPathMoveToPoint(qp, NULL, 8, 8);
    QZPathAddArcToPoint(qp, NULL, 32, 40, 56, 8, 10);
    QZPathCloseSubpath(qp);
    CGPathMoveToPoint(cp, NULL, 8, 8);
    CGPathAddArcToPoint(cp, NULL, 32, 40, 56, 8, 10);
    CGPathCloseSubpath(cp);
    fill_compare("fill arc-to chevron", qp, cp);
    QZPathRelease(qp);
    CGPathRelease(cp);
}

static void test_transformed_curve(void) {
    QZAffineTransform qt = QZAffineTransformMakeTranslation(1, 2);
    CGAffineTransform ct = CGAffineTransformMakeTranslation(1, 2);
    QZMutablePathRef qp = QZPathCreateMutable();
    CGMutablePathRef cp = CGPathCreateMutable();
    QZPathMoveToPoint(qp, &qt, 0, 0);
    QZPathAddCurveToPoint(qp, &qt, 0, 10, 10, 10, 10, 0);
    CGPathMoveToPoint(cp, &ct, 0, 0);
    CGPathAddCurveToPoint(cp, &ct, 0, 10, 10, 10, 10, 0);
    Bag qb, cb;
    apply_both(qp, cp, &qb, &cb);
    compare_bags("cubic translate", &qb, &cb, 1e-6, 0);
    QZPathRelease(qp);
    CGPathRelease(cp);
}

int main(void) {
    test_null_empty();
    test_move_line_cubic_close();
    test_rect_ellipse();
    test_two_subpaths();
    test_quad_elevated();
    test_add_lines();
    test_arc_to_elements();
    test_arc_to_fill();
    test_transformed_curve();

    fprintf(stderr, "apple_element_checks passed=%d failed=%d\n",
            g_apple_el_ok, g_apple_el_fail);
    if (g_fails) {
        fprintf(stderr, "FAIL path-apply (%d)\n", g_fails);
        return 1;
    }
    qz_pass("path-apply");
    return 0;
}
