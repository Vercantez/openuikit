#include "qz_internal.hpp"

#include <cmath>

/* OWNED BY package path-query. Implement the declarations in path_query.h. */

static QZRect qz_null_rect(void) {
    return QZRectMake(INFINITY, INFINITY, 0, 0);
}

static void accum(bool &any, double &minx, double &miny, double &maxx, double &maxy,
                  qz::Vec2 p) {
    if (!any) {
        minx = maxx = p.x;
        miny = maxy = p.y;
        any = true;
        return;
    }
    minx = std::min(minx, p.x);
    miny = std::min(miny, p.y);
    maxx = std::max(maxx, p.x);
    maxy = std::max(maxy, p.y);
}

static QZRect box_from(bool any, double minx, double miny, double maxx, double maxy) {
    if (!any) return qz_null_rect();
    return QZRectMake(minx, miny, maxx - minx, maxy - miny);
}

static qz::Vec2 eval_cubic(qz::Vec2 p0, qz::Vec2 p1, qz::Vec2 p2, qz::Vec2 p3, double t) {
    double u = 1.0 - t;
    double u2 = u * u, t2 = t * t;
    return p0 * (u2 * u) + p1 * (3.0 * u2 * t) + p2 * (3.0 * u * t2) + p3 * (t2 * t);
}

/* Roots of B'(t)=0 for one cubic coordinate, t in (0,1). */
static void cubic_deriv_roots(double p0, double p1, double p2, double p3,
                              double ts[2], int *n) {
    double a = -p0 + 3.0 * p1 - 3.0 * p2 + p3;
    double b = 2.0 * p0 - 4.0 * p1 + 2.0 * p2;
    double c = p1 - p0;
    auto push = [&](double t) {
        if (t > 1e-12 && t < 1.0 - 1e-12) ts[(*n)++] = t;
    };
    if (std::fabs(a) < 1e-20) {
        if (std::fabs(b) > 1e-20) push(-c / b);
        return;
    }
    double disc = b * b - 4.0 * a * c;
    if (disc < -1e-18) return;
    if (disc < 0) disc = 0;
    double s = std::sqrt(disc);
    double inv = 0.5 / a;
    push((-b + s) * inv);
    push((-b - s) * inv);
}

static void accum_cubic_tight(bool &any, double &minx, double &miny, double &maxx,
                              double &maxy, qz::Vec2 p0, qz::Vec2 p1, qz::Vec2 p2,
                              qz::Vec2 p3) {
    accum(any, minx, miny, maxx, maxy, p0);
    accum(any, minx, miny, maxx, maxy, p3);
    double ts[4];
    int n = 0;
    cubic_deriv_roots(p0.x, p1.x, p2.x, p3.x, ts, &n);
    cubic_deriv_roots(p0.y, p1.y, p2.y, p3.y, ts + n, &n);
    for (int i = 0; i < n; i++) {
        accum(any, minx, miny, maxx, maxy, eval_cubic(p0, p1, p2, p3, ts[i]));
    }
}

static bool vec_eq(qz::Vec2 a, qz::Vec2 b) { return a.x == b.x && a.y == b.y; }

static bool cmd_equal(const qz::PathCmd &a, const qz::PathCmd &b) {
    if (a.op != b.op) return false;
    switch (a.op) {
    case qz::PathOp::Move:
    case qz::PathOp::Line:
        return vec_eq(a.p[0], b.p[0]);
    case qz::PathOp::Cubic:
        return vec_eq(a.p[0], b.p[0]) && vec_eq(a.p[1], b.p[1]) && vec_eq(a.p[2], b.p[2]);
    case qz::PathOp::Close:
        return true;
    }
    return false;
}

static bool on_segment(qz::Vec2 p, qz::Vec2 a, qz::Vec2 b, double eps) {
    qz::Vec2 ab = b - a;
    qz::Vec2 ap = p - a;
    double L2 = qz::dot(ab, ab);
    if (L2 <= eps * eps) return qz::length(ap) <= eps;
    double t = qz::dot(ap, ab) / L2;
    t = qz::clampd(t, 0.0, 1.0);
    return qz::length(p - (a + ab * t)) <= eps;
}

QZRect QZPathGetBoundingBox(QZPathRef path) {
    if (!path || path->p.cmds.empty()) return qz_null_rect();
    bool any = false;
    double minx = 0, miny = 0, maxx = 0, maxy = 0;
    for (const qz::PathCmd &c : path->p.cmds) {
        switch (c.op) {
        case qz::PathOp::Move:
        case qz::PathOp::Line:
            accum(any, minx, miny, maxx, maxy, c.p[0]);
            break;
        case qz::PathOp::Cubic:
            accum(any, minx, miny, maxx, maxy, c.p[0]);
            accum(any, minx, miny, maxx, maxy, c.p[1]);
            accum(any, minx, miny, maxx, maxy, c.p[2]);
            break;
        case qz::PathOp::Close:
            break;
        }
    }
    return box_from(any, minx, miny, maxx, maxy);
}

QZRect QZPathGetPathBoundingBox(QZPathRef path) {
    if (!path || path->p.cmds.empty()) return qz_null_rect();
    bool any = false;
    double minx = 0, miny = 0, maxx = 0, maxy = 0;
    qz::Vec2 cur{0, 0};
    bool have = false;
    for (const qz::PathCmd &c : path->p.cmds) {
        switch (c.op) {
        case qz::PathOp::Move:
            accum(any, minx, miny, maxx, maxy, c.p[0]);
            cur = c.p[0];
            have = true;
            break;
        case qz::PathOp::Line:
            if (!have) {
                accum(any, minx, miny, maxx, maxy, qz::Vec2{0, 0});
                have = true;
            }
            accum(any, minx, miny, maxx, maxy, c.p[0]);
            cur = c.p[0];
            break;
        case qz::PathOp::Cubic:
            if (!have) {
                cur = {0, 0};
                have = true;
            }
            accum_cubic_tight(any, minx, miny, maxx, maxy, cur, c.p[0], c.p[1], c.p[2]);
            cur = c.p[2];
            break;
        case qz::PathOp::Close:
            break;
        }
    }
    return box_from(any, minx, miny, maxx, maxy);
}

bool QZPathIsEmpty(QZPathRef path) {
    return !path || path->p.cmds.empty();
}

QZPoint QZPathGetCurrentPoint(QZPathRef path) {
    if (!path) return QZPointMake(0, 0);
    return path->p.current.qz();
}

bool QZPathContainsPoint(QZPathRef path, const QZAffineTransform *m, QZPoint point,
                         bool even_odd) {
    if (!path || path->p.cmds.empty()) return false;
    qz::Vec2 pt{point.x, point.y};
    if (m) pt = qz::apply(*m, pt);

    const double eps = 1e-6;
    if (path->p.has_current && qz::length(pt - path->p.current) <= eps) return true;

    std::vector<qz::Polyline> polys;
    qz::flatten_path(path->p, 0.05, polys);

    int winding = 0;
    for (const qz::Polyline &pl : polys) {
        size_t n = pl.pts.size();
        if (n < 2) continue;
        for (size_t i = 0; i < n; i++) {
            qz::Vec2 a = pl.pts[i];
            qz::Vec2 b = pl.pts[(i + 1) % n];
            if (on_segment(pt, a, b, eps)) return true;
            double dy = b.y - a.y;
            if (std::fabs(dy) < 1e-15) continue;
            double y0, y1, x0, dxdy;
            int wind;
            if (a.y < b.y) {
                y0 = a.y;
                y1 = b.y;
                x0 = a.x;
                dxdy = (b.x - a.x) / dy;
                wind = 1;
            } else {
                y0 = b.y;
                y1 = a.y;
                x0 = b.x;
                dxdy = (a.x - b.x) / -dy;
                wind = -1;
            }
            if (pt.y < y0 || pt.y >= y1) continue;
            double x = x0 + (pt.y - y0) * dxdy;
            if (x > pt.x) winding += wind;
        }
    }

    if (even_odd) return (winding & 1) != 0;
    return winding != 0;
}

QZPathRef QZPathCreateCopy(QZPathRef path) {
    if (!path) return nullptr;
    auto *c = new QZPath();
    c->p = path->p;
    c->p.ref = 1;
    return c;
}

QZPathRef QZPathCreateCopyByTransformingPath(QZPathRef path, const QZAffineTransform *m) {
    if (!path) return nullptr;
    auto *c = new QZPath();
    c->p.append(path->p, m);
    return c;
}

bool QZPathEqualToPath(QZPathRef a, QZPathRef b) {
    if (a == b) return true;
    if (!a || !b) return false;
    if (a->p.cmds.size() != b->p.cmds.size()) return false;
    for (size_t i = 0; i < a->p.cmds.size(); i++) {
        if (!cmd_equal(a->p.cmds[i], b->p.cmds[i])) return false;
    }
    return true;
}
