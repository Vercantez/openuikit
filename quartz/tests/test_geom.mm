#import <Foundation/Foundation.h>
#include "test_common.h"
#include <stdarg.h>
#include <math.h>
#include <string.h>

static int g_fails = 0;
static int g_checks = 0;

static void failf(const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    fprintf(stderr, "FAIL ");
    vfprintf(stderr, fmt, ap);
    fprintf(stderr, "\n");
    va_end(ap);
    g_fails++;
}

static bool feq(double a, double b) {
    if (a == b) return true;
    if (isnan(a) && isnan(b)) return true;
    return false;
}

static QZRect qzr(CGRect r) {
    return QZRectMake(r.origin.x, r.origin.y, r.size.width, r.size.height);
}
static QZPoint qzp(CGPoint p) { return QZPointMake(p.x, p.y); }
static QZSize qzs(CGSize s) { return QZSizeMake(s.width, s.height); }
static QZAffineTransform qzt(CGAffineTransform t) {
    QZAffineTransform q;
    q.a = t.a; q.b = t.b; q.c = t.c; q.d = t.d; q.tx = t.tx; q.ty = t.ty;
    return q;
}

static bool rects_eq(QZRect q, CGRect c) {
    return feq(q.origin.x, c.origin.x) && feq(q.origin.y, c.origin.y) &&
           feq(q.size.width, c.size.width) && feq(q.size.height, c.size.height);
}

static void check_bool(const char *tag, bool q, bool c) {
    g_checks++;
    if (q != c) failf("%s QZ=%d CG=%d", tag, (int)q, (int)c);
}
static void check_f(const char *tag, double q, double c) {
    g_checks++;
    if (!feq(q, c)) failf("%s QZ=%.17g CG=%.17g", tag, q, c);
}
static void check_rect(const char *tag, QZRect q, CGRect c) {
    g_checks++;
    if (!rects_eq(q, c)) {
        failf("%s QZ(%.17g,%.17g %.17gx%.17g) CG(%.17g,%.17g %.17gx%.17g)",
              tag, q.origin.x, q.origin.y, q.size.width, q.size.height,
              c.origin.x, c.origin.y, c.size.width, c.size.height);
    }
}

static void check_unary(const char *name, CGRect c) {
    QZRect q = qzr(c);
    char buf[192];

    snprintf(buf, sizeof(buf), "%s GetMinX", name);
    check_f(buf, QZRectGetMinX(q), CGRectGetMinX(c));
    snprintf(buf, sizeof(buf), "%s GetMinY", name);
    check_f(buf, QZRectGetMinY(q), CGRectGetMinY(c));
    snprintf(buf, sizeof(buf), "%s GetMaxX", name);
    check_f(buf, QZRectGetMaxX(q), CGRectGetMaxX(c));
    snprintf(buf, sizeof(buf), "%s GetMaxY", name);
    check_f(buf, QZRectGetMaxY(q), CGRectGetMaxY(c));
    snprintf(buf, sizeof(buf), "%s GetMidX", name);
    check_f(buf, QZRectGetMidX(q), CGRectGetMidX(c));
    snprintf(buf, sizeof(buf), "%s GetMidY", name);
    check_f(buf, QZRectGetMidY(q), CGRectGetMidY(c));
    snprintf(buf, sizeof(buf), "%s GetWidth", name);
    check_f(buf, QZRectGetWidth(q), CGRectGetWidth(c));
    snprintf(buf, sizeof(buf), "%s GetHeight", name);
    check_f(buf, QZRectGetHeight(q), CGRectGetHeight(c));
    snprintf(buf, sizeof(buf), "%s IsEmpty", name);
    check_bool(buf, QZRectIsEmpty(q), CGRectIsEmpty(c));
    snprintf(buf, sizeof(buf), "%s Standardize", name);
    check_rect(buf, QZRectStandardize(q), CGRectStandardize(c));
    snprintf(buf, sizeof(buf), "%s Integral", name);
    check_rect(buf, QZRectIntegral(q), CGRectIntegral(c));

    const double insets[][2] = {
        {0, 0}, {1, 1}, {2, 3}, {-2, -3}, {5, 5}, {5, 0}, {0, 5},
        {5.0001, 5}, {6, 6}, {20, 5}, {0.5, 0.25}, {-1, 2}, {4.999, 0}
    };
    for (size_t i = 0; i < sizeof(insets) / sizeof(insets[0]); i++) {
        snprintf(buf, sizeof(buf), "%s Inset(%.4g,%.4g)", name, insets[i][0], insets[i][1]);
        check_rect(buf, QZRectInset(q, insets[i][0], insets[i][1]),
                   CGRectInset(c, insets[i][0], insets[i][1]));
    }
    const double offs[][2] = {
        {0, 0}, {5, -7}, {1, 1}, {-3, 4}, {0.5, -0.5}, {100, 0}
    };
    for (size_t i = 0; i < sizeof(offs) / sizeof(offs[0]); i++) {
        snprintf(buf, sizeof(buf), "%s Offset(%.4g,%.4g)", name, offs[i][0], offs[i][1]);
        check_rect(buf, QZRectOffset(q, offs[i][0], offs[i][1]),
                   CGRectOffset(c, offs[i][0], offs[i][1]));
    }
}

static void check_pair(const char *na, CGRect ca, const char *nb, CGRect cb) {
    QZRect qa = qzr(ca), qb = qzr(cb);
    char buf[256];
    snprintf(buf, sizeof(buf), "Union(%s,%s)", na, nb);
    check_rect(buf, QZRectUnion(qa, qb), CGRectUnion(ca, cb));
    snprintf(buf, sizeof(buf), "Intersection(%s,%s)", na, nb);
    check_rect(buf, QZRectIntersection(qa, qb), CGRectIntersection(ca, cb));
    snprintf(buf, sizeof(buf), "ContainsRect(%s,%s)", na, nb);
    check_bool(buf, QZRectContainsRect(qa, qb), CGRectContainsRect(ca, cb));
    snprintf(buf, sizeof(buf), "IntersectsRect(%s,%s)", na, nb);
    check_bool(buf, QZRectIntersectsRect(qa, qb), CGRectIntersectsRect(ca, cb));
    snprintf(buf, sizeof(buf), "EqualToRect(%s,%s)", na, nb);
    check_bool(buf, QZRectEqualToRect(qa, qb), CGRectEqualToRect(ca, cb));
}

static void check_point(const char *nr, CGRect c, const char *np, CGPoint p) {
    char buf[192];
    snprintf(buf, sizeof(buf), "ContainsPoint(%s,%s)", nr, np);
    check_bool(buf, QZRectContainsPoint(qzr(c), qzp(p)), CGRectContainsPoint(c, p));
}

int main(void) {
    struct { const char *n; CGRect r; } rects[] = {
        {"zero", CGRectZero},
        {"null", CGRectNull},
        {"pos", CGRectMake(10, 20, 30, 40)},
        {"neg", CGRectMake(10, 20, -30, -40)},
        {"mixedWH", CGRectMake(5, 10, -8, 12)},
        {"mixedHW", CGRectMake(5, 10, 8, -12)},
        {"unit", CGRectMake(0, 0, 10, 10)},
        {"one", CGRectMake(0, 0, 1, 1)},
        {"frac", CGRectMake(1.5, 2.5, 3.5, 4.5)},
        {"negfrac", CGRectMake(-1.5, -2.5, 3.2, 4.7)},
        {"negWfrac", CGRectMake(-10.2, 5.0, -3.3, 2.1)},
        {"tiny", CGRectMake(1.0, 2.0, 0.0001, 0.0001)},
        {"ptfrac", CGRectMake(1.5, 2.5, 0, 0)},
        {"emptyW", CGRectMake(5.5, 6.5, 0, 10)},
        {"emptyH", CGRectMake(5.5, 6.5, 10, 0)},
        {"ptInt", CGRectMake(5, 6, 0, 0)},
        {"hLine", CGRectMake(0, 0, 10, 0)},
        {"vLine", CGRectMake(0, 0, 0, 10)},
        {"pt55", CGRectMake(5, 5, 0, 0)},
        {"rightAdj", CGRectMake(10, 0, 5, 5)},
        {"leftAdj", CGRectMake(-5, 0, 5, 5)},
        {"overlapBR", CGRectMake(9, 9, 2, 2)},
        {"far", CGRectMake(20, 20, 1, 1)},
        {"nullX", CGRectMake(INFINITY, 0, 0, 0)},
        {"nullLike", CGRectMake(INFINITY, 5, 3, 4)},
        {"half", CGRectMake(0.5, 0.5, 0.5, 0.5)},
        {"negHalf", CGRectMake(-0.5, -0.5, 1.0, 1.0)},
        {"eps", CGRectMake(0.9999999999999999, 1.0000000000000002, 2.0, 3.0)},
        {"negTinyW", CGRectMake(10, 20, -0.1, 5)},
        {"intAlready", CGRectMake(-3, -4, 5, 6)},
        {"subpix", CGRectMake(0, 15.6, 20.3, 30.1)},
        {"pt11", CGRectMake(1, 1, 0, 0)},
        {"pt22", CGRectMake(2, 2, 0, 0)},
        {"hMid", CGRectMake(0, 5, 10, 0)},
        {"vMid", CGRectMake(5, 0, 0, 10)},
        {"negUnit", CGRectMake(10, 10, -10, -10)},
        {"negFromOrigin", CGRectMake(0, 0, -10, -10)},
        {"botAdj", CGRectMake(0, -5, 5, 5)},
        {"topAdj", CGRectMake(0, 10, 5, 5)},
        {"ptMax", CGRectMake(10, 10, 0, 0)},
        {"ptOnMaxX", CGRectMake(10, 5, 0, 0)},
        {"emptyWH0", CGRectMake(1, 2, 0, -5)},
        {"negZero", CGRectMake(-0.0, -0.0, 1, 1)},
        {"square", CGRectMake(0, 0, 4, 4)},
        {"intOriginEmpty", CGRectMake(5, 6, 0, 10)},
        {"bothNegEmpty", CGRectMake(1, 2, -1, -1)},
        {"wide", CGRectMake(-100, -50, 200, 75)},
        {"vLineInterior", CGRectMake(5, 0, 0, 10)},
        {"hLineOutside", CGRectMake(0, 20, 10, 0)},
        {"crossV", CGRectMake(0, 0, 0, 10)},
        {"crossH", CGRectMake(0, 0, 10, 0)},
    };
    const int nrect = (int)(sizeof(rects) / sizeof(rects[0]));

    for (int i = 0; i < nrect; i++) {
        check_unary(rects[i].n, rects[i].r);
    }

    /* Pairwise algebra on a representative subset plus hand-picked edges. */
    int pair_idx[] = {0, 1, 2, 3, 4, 6, 11, 12, 16, 17, 18, 19, 20, 21, 23, 24, 34, 35, 36, 40};
    int npair = (int)(sizeof(pair_idx) / sizeof(pair_idx[0]));
    for (int i = 0; i < npair; i++) {
        for (int j = 0; j < npair; j++) {
            int ia = pair_idx[i], ib = pair_idx[j];
            check_pair(rects[ia].n, rects[ia].r, rects[ib].n, rects[ib].r);
        }
    }

    /* Extra well-known pairs. */
    check_pair("unit", CGRectMake(0, 0, 10, 10), "zero", CGRectZero);
    check_pair("unit", CGRectMake(0, 0, 10, 10), "null", CGRectNull);
    check_pair("unit", CGRectMake(0, 0, 10, 10), "self", CGRectMake(0, 0, 10, 10));
    check_pair("unit", CGRectMake(0, 0, 10, 10), "inner", CGRectMake(2, 2, 3, 3));
    check_pair("unit", CGRectMake(0, 0, 10, 10), "oversize", CGRectMake(-1, -1, 12, 12));
    check_pair("neg", CGRectMake(10, 20, -30, -40), "std", CGRectMake(-20, -20, 30, 40));
    check_pair("a", CGRectMake(0, 0, 10, 10), "b", CGRectMake(5, 5, 10, 10));
    check_pair("a", CGRectMake(0, 0, 1, 1), "b", CGRectMake(10, 10, 1, 1));
    check_pair("a", CGRectMake(0, 0, 10, 10), "touchR", CGRectMake(10, 0, 5, 5));
    check_pair("a", CGRectMake(0, 0, 10, 10), "touchPt", CGRectMake(10, 10, 5, 5));
    check_pair("emptyA", CGRectMake(1, 1, 0, 0), "emptyB", CGRectMake(2, 2, 0, 0));
    check_pair("sameEmpty", CGRectMake(1, 1, 0, 0), "sameEmpty", CGRectMake(1, 1, 0, 0));
    check_pair("lineV", CGRectMake(5, 0, 0, 10), "lineH", CGRectMake(0, 5, 10, 0));
    check_pair("lineV", CGRectMake(5, 0, 0, 10), "lineV2", CGRectMake(5, 5, 0, 10));
    check_pair("h1", CGRectMake(0, 5, 10, 0), "h2", CGRectMake(5, 5, 10, 0));
    check_pair("h1", CGRectMake(0, 5, 5, 0), "h2", CGRectMake(5, 5, 5, 0));
    check_pair("negA", CGRectMake(10, 10, -8, -8), "negB", CGRectMake(8, 8, -8, -8));
    check_pair("pos", CGRectMake(0, 0, 10, 10), "negFlip", CGRectMake(0, 0, -10, -10));
    check_pair("zero", CGRectZero, "null", CGRectNull);
    check_pair("null", CGRectNull, "null", CGRectNull);
    check_pair("lineEncA", CGRectMake(0, 0, 0, 5), "lineEncB", CGRectMake(0, 5, 0, -5));
    check_pair("ptOnLine", CGRectMake(3, 5, 0, 0), "hMid", CGRectMake(0, 5, 10, 0));
    check_pair("ptEnd", CGRectMake(10, 5, 0, 0), "hMid", CGRectMake(0, 5, 10, 0));
    check_pair("ptStart", CGRectMake(0, 5, 0, 0), "hMid", CGRectMake(0, 5, 10, 0));
    check_pair("sliver", CGRectMake(9.999, 0, 0.001, 10), "unit", CGRectMake(0, 0, 10, 10));

    struct { const char *n; CGPoint p; } pts[] = {
        {"o", CGPointMake(0, 0)},
        {"in", CGPointMake(5, 5)},
        {"maxC", CGPointMake(10, 10)},
        {"maxX", CGPointMake(10, 5)},
        {"maxY", CGPointMake(5, 10)},
        {"minX", CGPointMake(0, 5)},
        {"minY", CGPointMake(5, 0)},
        {"out", CGPointMake(-1, 5)},
        {"negIn", CGPointMake(-5, -5)},
        {"negO", CGPointMake(10, 20)},
        {"almost", CGPointMake(9.999, 9.999)},
        {"negMin", CGPointMake(-20, -20)},
        {"negMinY", CGPointMake(-20, -19)},
        {"inf", CGPointMake(INFINITY, INFINITY)},
        {"mid", CGPointMake(2, 3)},
        {"pt55", CGPointMake(5, 5)},
        {"onH", CGPointMake(5, 0)},
        {"far", CGPointMake(100, 100)},
        {"n1n1", CGPointMake(-1, -1)},
    };
    const char *pt_rects[] = {"unit", "zero", "null", "neg", "hLine", "vLine", "pt55", "emptyW", "pos"};
    for (size_t ri = 0; ri < sizeof(pt_rects) / sizeof(pt_rects[0]); ri++) {
        CGRect cr = CGRectZero;
        const char *rn = pt_rects[ri];
        for (int i = 0; i < nrect; i++) {
            if (strcmp(rects[i].n, rn) == 0) { cr = rects[i].r; break; }
        }
        for (size_t pi = 0; pi < sizeof(pts) / sizeof(pts[0]); pi++) {
            check_point(rn, cr, pts[pi].n, pts[pi].p);
        }
    }

    /* Point / size equality */
    check_bool("PointEqual same",
               QZPointEqualToPoint(QZPointMake(1, 2), QZPointMake(1, 2)),
               CGPointEqualToPoint(CGPointMake(1, 2), CGPointMake(1, 2)));
    check_bool("PointEqual diff",
               QZPointEqualToPoint(QZPointMake(1, 2), QZPointMake(1, 3)),
               CGPointEqualToPoint(CGPointMake(1, 2), CGPointMake(1, 3)));
    check_bool("PointEqual -0",
               QZPointEqualToPoint(QZPointMake(0, 0), QZPointMake(-0.0, -0.0)),
               CGPointEqualToPoint(CGPointMake(0, 0), CGPointMake(-0.0, -0.0)));
    check_bool("PointEqual nan",
               QZPointEqualToPoint(QZPointMake(NAN, 0), QZPointMake(NAN, 0)),
               CGPointEqualToPoint(CGPointMake(NAN, 0), CGPointMake(NAN, 0)));
    check_bool("SizeEqual same",
               QZSizeEqualToSize(QZSizeMake(1, 2), QZSizeMake(1, 2)),
               CGSizeEqualToSize(CGSizeMake(1, 2), CGSizeMake(1, 2)));
    check_bool("SizeEqual -0",
               QZSizeEqualToSize(QZSizeMake(0, 0), QZSizeMake(-0.0, -0.0)),
               CGSizeEqualToSize(CGSizeMake(0, 0), CGSizeMake(-0.0, -0.0)));
    check_bool("SizeEqual diff",
               QZSizeEqualToSize(QZSizeMake(1, 2), QZSizeMake(2, 1)),
               CGSizeEqualToSize(CGSizeMake(1, 2), CGSizeMake(2, 1)));

    /* Affine identity / equality */
    CGAffineTransform cidents[] = {
        CGAffineTransformIdentity,
        CGAffineTransformMake(1, 0, 0, 1, 0, 0),
        CGAffineTransformMake(1, +0.0, +0.0, 1, +0.0, +0.0),
        CGAffineTransformMake(1, -0.0, -0.0, 1, -0.0, -0.0),
        CGAffineTransformMakeTranslation(0, 0),
        CGAffineTransformMakeScale(1, 1),
        CGAffineTransformMakeRotation(0),
        CGAffineTransformMake(1.0000000000000002, 0, 0, 1, 0, 0),
        CGAffineTransformMake(1, 0, 0, 1, 1e-20, 0),
        CGAffineTransformMake(1, 0, 0, 1, 0, nextafter(0.0, 1.0)),
        CGAffineTransformMake(nextafter(1.0, 2.0), 0, 0, 1, 0, 0),
        CGAffineTransformMake(1, 0.1, 0, 1, 0, 0),
        CGAffineTransformMake(2, 0, 0, 2, 0, 0),
        CGAffineTransformMake(1, 0, 0, 1, 5, -3),
        CGAffineTransformMakeRotation(0.5),
        CGAffineTransformMakeRotation(-0.5),
        CGAffineTransformTranslate(CGAffineTransformIdentity, 0, 0),
    };
    const int nt = (int)(sizeof(cidents) / sizeof(cidents[0]));
    for (int i = 0; i < nt; i++) {
        char buf[64];
        snprintf(buf, sizeof(buf), "IsIdentity[%d]", i);
        check_bool(buf, QZAffineTransformIsIdentity(qzt(cidents[i])),
                   CGAffineTransformIsIdentity(cidents[i]));
        for (int j = 0; j < nt; j++) {
            snprintf(buf, sizeof(buf), "EqualToTransform[%d,%d]", i, j);
            check_bool(buf,
                       QZAffineTransformEqualToTransform(qzt(cidents[i]), qzt(cidents[j])),
                       CGAffineTransformEqualToTransform(cidents[i], cidents[j]));
        }
    }

    if (g_fails) {
        fprintf(stderr, "%d FAIL of %d checks\n", g_fails, g_checks);
        return 1;
    }
    printf("PASS geom (%d checks)\n", g_checks);
    return 0;
}
