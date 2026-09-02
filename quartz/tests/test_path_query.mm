#import <Foundation/Foundation.h>
#include "test_common.h"
#include <stdarg.h>

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

static bool rects_close(QZRect q, CGRect c, double tol) {
    int qnull = !isfinite(q.origin.x) && !isfinite(q.origin.y);
    if (CGRectIsNull(c)) return qnull;
    if (qnull) return false;
    return fabs(q.origin.x - c.origin.x) <= tol &&
           fabs(q.origin.y - c.origin.y) <= tol &&
           fabs(q.size.width - c.size.width) <= tol &&
           fabs(q.size.height - c.size.height) <= tol;
}

static bool pts_close(QZPoint q, CGPoint c, double tol) {
    return fabs(q.x - c.x) <= tol && fabs(q.y - c.y) <= tol;
}

static void check_bbox(const char *name, QZPathRef qp, CGPathRef cp) {
    QZRect qb = QZPathGetBoundingBox(qp);
    CGRect cb = CGPathGetBoundingBox(cp);
    if (!rects_close(qb, cb, 1.0)) {
        failf("%s bounding box QZ(%.6f,%.6f %.6fx%.6f) CG(%.6f,%.6f %.6fx%.6f)",
              name, qb.origin.x, qb.origin.y, qb.size.width, qb.size.height,
              cb.origin.x, cb.origin.y, cb.size.width, cb.size.height);
    }
    QZRect qpb = QZPathGetPathBoundingBox(qp);
    CGRect cpb = CGPathGetPathBoundingBox(cp);
    if (!rects_close(qpb, cpb, 1.0)) {
        failf("%s path bounding box QZ(%.6f,%.6f %.6fx%.6f) CG(%.6f,%.6f %.6fx%.6f)",
              name, qpb.origin.x, qpb.origin.y, qpb.size.width, qpb.size.height,
              cpb.origin.x, cpb.origin.y, cpb.size.width, cpb.size.height);
    }
}

static void check_current(const char *name, QZPathRef qp, CGPathRef cp) {
    QZPoint q = QZPathGetCurrentPoint(qp);
    CGPoint c = CGPathGetCurrentPoint(cp);
    if (!pts_close(q, c, 1e-6)) {
        failf("%s current point QZ(%.6f,%.6f) CG(%.6f,%.6f)", name, q.x, q.y, c.x, c.y);
    }
}

static void check_empty(const char *name, QZPathRef qp, CGPathRef cp) {
    bool qe = QZPathIsEmpty(qp);
    bool ce = CGPathIsEmpty(cp);
    if (qe != ce) failf("%s isEmpty QZ=%d CG=%d", name, qe, ce);
}

static void check_contains_grid(const char *name, QZPathRef qp, CGPathRef cp,
                                double x0, double y0, double x1, double y1, double step,
                                const QZAffineTransform *qm, const CGAffineTransform *cm) {
    int mismatches = 0;
    int samples = 0;
    for (double y = y0; y <= y1 + 1e-9; y += step) {
        for (double x = x0; x <= x1 + 1e-9; x += step) {
            for (int eo = 0; eo <= 1; eo++) {
                samples++;
                bool q = QZPathContainsPoint(qp, qm, QZPointMake(x, y), eo != 0);
                bool c = CGPathContainsPoint(cp, cm, CGPointMake(x, y), eo != 0);
                if (q != c) {
                    if (mismatches < 8) {
                        failf("%s contains (%.3f,%.3f) eo=%d QZ=%d CG=%d",
                              name, x, y, eo, q, c);
                    }
                    mismatches++;
                }
            }
        }
    }
    if (mismatches > 8) {
        failf("%s contains-point %d further mismatches (%d samples)", name,
              mismatches - 8, samples);
    }
}

static void add_rect_both(QZMutablePathRef qp, CGMutablePathRef cp, QZRect r) {
    QZPathAddRect(qp, NULL, r);
    CGPathAddRect(cp, NULL, CGRectMake(r.origin.x, r.origin.y, r.size.width, r.size.height));
}

static void add_ellipse_both(QZMutablePathRef qp, CGMutablePathRef cp, QZRect r) {
    QZPathAddEllipseInRect(qp, NULL, r);
    CGPathAddEllipseInRect(cp, NULL, CGRectMake(r.origin.x, r.origin.y, r.size.width, r.size.height));
}

int main(void) {
    /* empty */
    {
        QZMutablePathRef qp = QZPathCreateMutable();
        CGMutablePathRef cp = CGPathCreateMutable();
        check_empty("empty", qp, cp);
        check_bbox("empty", qp, cp);
        check_current("empty", qp, cp);
        if (QZPathContainsPoint(qp, NULL, QZPointMake(0, 0), false)) {
            failf("empty contains origin");
        }
        QZPathRef qc = QZPathCreateCopy(qp);
        if (!QZPathEqualToPath(qp, qc) || !QZPathIsEmpty(qc)) {
            failf("empty copy");
        }
        QZPathRelease(qc);
        QZPathRelease(qp);
        CGPathRelease(cp);
    }

    /* NULL */
    {
        if (!QZPathIsEmpty(NULL)) failf("NULL isEmpty");
        if (QZPathCreateCopy(NULL) != NULL) failf("NULL copy");
        if (QZPathCreateCopyByTransformingPath(NULL, NULL) != NULL) failf("NULL xform copy");
        if (!QZPathEqualToPath(NULL, NULL)) failf("NULL equal NULL");
        QZMutablePathRef empty = QZPathCreateMutable();
        if (QZPathEqualToPath(empty, NULL)) failf("empty equal NULL");
        QZPathRelease(empty);
        if (QZPathContainsPoint(NULL, NULL, QZPointMake(1, 1), true)) failf("NULL contains");
    }

    /* rect */
    {
        QZMutablePathRef qp = QZPathCreateMutable();
        CGMutablePathRef cp = CGPathCreateMutable();
        add_rect_both(qp, cp, QZRectMake(10, 20, 30, 40));
        check_empty("rect", qp, cp);
        if (QZPathIsEmpty(qp)) failf("rect path empty");
        check_bbox("rect", qp, cp);
        check_current("rect", qp, cp);
        check_contains_grid("rect", qp, cp, 0, 0, 60, 80, 2.0, NULL, NULL);

        QZPathRef qc = QZPathCreateCopy(qp);
        if (!QZPathEqualToPath(qp, qc)) failf("rect copy not equal");
        check_bbox("rect copy", qc, cp);
        check_current("rect copy", qc, cp);

        QZMutablePathRef qp2 = QZPathCreateMutable();
        QZPathAddRect(qp2, NULL, QZRectMake(10, 20, 30, 40));
        if (!QZPathEqualToPath(qp, qp2)) failf("two rects not equal");

        QZAffineTransform qs = QZAffineTransformMakeScale(2, 3);
        CGAffineTransform cs = CGAffineTransformMakeScale(2, 3);
        QZPathRef qt = QZPathCreateCopyByTransformingPath(qp, &qs);
        CGPathRef ct = CGPathCreateCopyByTransformingPath(cp, &cs);
        check_bbox("scaled rect", qt, ct);
        check_current("scaled rect", qt, ct);
        check_contains_grid("scaled rect", qt, ct, 0, 0, 90, 140, 5.0, NULL, NULL);
        if (QZPathEqualToPath(qp, qt)) failf("scaled rect equal to original");

        QZAffineTransform qid = QZAffineTransformIdentity();
        QZPathRef qidc = QZPathCreateCopyByTransformingPath(qp, &qid);
        if (!QZPathEqualToPath(qp, qidc)) failf("identity transform copy not equal");

        QZAffineTransform qt1 = QZAffineTransformMakeTranslation(10, 10);
        CGAffineTransform ct1 = CGAffineTransformMakeTranslation(10, 10);
        check_contains_grid("rect point-xform", qp, cp, -5, 0, 50, 70, 5.0, &qt1, &ct1);

        QZPathRelease(qp);
        QZPathRelease(qp2);
        QZPathRelease(qc);
        QZPathRelease(qt);
        QZPathRelease(qidc);
        CGPathRelease(cp);
        CGPathRelease(ct);
    }

    /* ellipse */
    {
        QZMutablePathRef qp = QZPathCreateMutable();
        CGMutablePathRef cp = CGPathCreateMutable();
        add_ellipse_both(qp, cp, QZRectMake(10, 20, 80, 40));
        check_empty("ellipse", qp, cp);
        check_bbox("ellipse", qp, cp);
        check_current("ellipse", qp, cp);
        check_contains_grid("ellipse", qp, cp, 0, 0, 100, 80, 2.0, NULL, NULL);
        QZPathRelease(qp);
        CGPathRelease(cp);
    }

    /* line */
    {
        QZMutablePathRef qp = QZPathCreateMutable();
        CGMutablePathRef cp = CGPathCreateMutable();
        QZPathMoveToPoint(qp, NULL, 0, 0);
        QZPathAddLineToPoint(qp, NULL, 10, 0);
        CGPathMoveToPoint(cp, NULL, 0, 0);
        CGPathAddLineToPoint(cp, NULL, 10, 0);
        check_bbox("line", qp, cp);
        check_current("line", qp, cp);
        check_contains_grid("line", qp, cp, -2, -2, 12, 4, 1.0, NULL, NULL);
        QZPathRelease(qp);
        CGPathRelease(cp);
    }

    /* cubic (control box vs tight path box) */
    {
        QZMutablePathRef qp = QZPathCreateMutable();
        CGMutablePathRef cp = CGPathCreateMutable();
        QZPathMoveToPoint(qp, NULL, 0, 0);
        QZPathAddCurveToPoint(qp, NULL, 0, 100, 100, 100, 100, 0);
        CGPathMoveToPoint(cp, NULL, 0, 0);
        CGPathAddCurveToPoint(cp, NULL, 0, 100, 100, 100, 100, 0);
        check_bbox("cubic", qp, cp);
        check_current("cubic", qp, cp);
        QZRect ctrl = QZPathGetBoundingBox(qp);
        QZRect tight = QZPathGetPathBoundingBox(qp);
        if (fabs(ctrl.size.height - 100) > 1.0) {
            failf("cubic control box height %.6f", ctrl.size.height);
        }
        if (fabs(tight.size.height - 75) > 1.0) {
            failf("cubic tight box height %.6f (want ~75)", tight.size.height);
        }
        check_contains_grid("cubic", qp, cp, -5, -5, 105, 90, 5.0, NULL, NULL);
        QZPathRelease(qp);
        CGPathRelease(cp);
    }

    /* nested rects: even-odd hole vs nonzero fill */
    {
        QZMutablePathRef qp = QZPathCreateMutable();
        CGMutablePathRef cp = CGPathCreateMutable();
        add_rect_both(qp, cp, QZRectMake(0, 0, 100, 100));
        add_rect_both(qp, cp, QZRectMake(25, 25, 50, 50));
        check_bbox("nested", qp, cp);
        check_contains_grid("nested", qp, cp, -5, -5, 105, 105, 5.0, NULL, NULL);
        if (!QZPathContainsPoint(qp, NULL, QZPointMake(10, 10), true)) {
            failf("nested outer even-odd");
        }
        if (QZPathContainsPoint(qp, NULL, QZPointMake(50, 50), true)) {
            failf("nested hole even-odd should be empty");
        }
        if (!QZPathContainsPoint(qp, NULL, QZPointMake(50, 50), false)) {
            failf("nested hole nonzero should be filled");
        }
        QZPathRelease(qp);
        CGPathRelease(cp);
    }

    /* open triangle fills as closed */
    {
        QZMutablePathRef qp = QZPathCreateMutable();
        CGMutablePathRef cp = CGPathCreateMutable();
        QZPathMoveToPoint(qp, NULL, 0, 0);
        QZPathAddLineToPoint(qp, NULL, 20, 0);
        QZPathAddLineToPoint(qp, NULL, 10, 20);
        CGPathMoveToPoint(cp, NULL, 0, 0);
        CGPathAddLineToPoint(cp, NULL, 20, 0);
        CGPathAddLineToPoint(cp, NULL, 10, 20);
        check_current("open tri", qp, cp);
        check_contains_grid("open tri", qp, cp, -2, -2, 22, 22, 2.0, NULL, NULL);
        QZPathCloseSubpath(qp);
        CGPathCloseSubpath(cp);
        check_current("closed tri", qp, cp);
        check_contains_grid("closed tri", qp, cp, -2, -2, 22, 22, 2.0, NULL, NULL);
        QZPathRelease(qp);
        CGPathRelease(cp);
    }

    if (g_fails) {
        fprintf(stderr, "FAIL path-query (%d)\n", g_fails);
        return 1;
    }
    qz_pass("path-query");
    return 0;
}
