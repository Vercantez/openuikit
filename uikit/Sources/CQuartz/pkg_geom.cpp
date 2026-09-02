#include "qz_internal.hpp"
/* OWNED BY package geom. */

/* Null iff origin.x or origin.y is +inf (CGRectNull is {inf,inf,0,0}). */

static const QZRect kQZRectNull = {{INFINITY, INFINITY}, {0, 0}};

static bool qz_rect_is_null(QZRect r) {
    return r.origin.x == INFINITY || r.origin.y == INFINITY;
}

/* Flip negative width/height; do not canonicalize null. Used by getters. */
static QZRect qz_rect_pos_size(QZRect r) {
    if (r.size.width < 0) {
        r.origin.x += r.size.width;
        r.size.width = -r.size.width;
    }
    if (r.size.height < 0) {
        r.origin.y += r.size.height;
        r.size.height = -r.size.height;
    }
    return r;
}

bool QZPointEqualToPoint(QZPoint a, QZPoint b) {
    return a.x == b.x && a.y == b.y;
}
bool QZSizeEqualToSize(QZSize a, QZSize b) {
    return a.width == b.width && a.height == b.height;
}
bool QZRectEqualToRect(QZRect a, QZRect b) {
    if (qz_rect_is_null(a)) return qz_rect_is_null(b);
    if (qz_rect_is_null(b)) return false;
    a = qz_rect_pos_size(a);
    b = qz_rect_pos_size(b);
    return QZPointEqualToPoint(a.origin, b.origin) && QZSizeEqualToSize(a.size, b.size);
}

QZFloat QZRectGetMinX(QZRect r) {
    r = qz_rect_pos_size(r);
    return r.origin.x;
}
QZFloat QZRectGetMinY(QZRect r) {
    r = qz_rect_pos_size(r);
    return r.origin.y;
}
QZFloat QZRectGetMaxX(QZRect r) {
    r = qz_rect_pos_size(r);
    return r.origin.x + r.size.width;
}
QZFloat QZRectGetMaxY(QZRect r) {
    r = qz_rect_pos_size(r);
    return r.origin.y + r.size.height;
}
QZFloat QZRectGetMidX(QZRect r) {
    r = qz_rect_pos_size(r);
    return r.origin.x + r.size.width * 0.5;
}
QZFloat QZRectGetMidY(QZRect r) {
    r = qz_rect_pos_size(r);
    return r.origin.y + r.size.height * 0.5;
}
QZFloat QZRectGetWidth(QZRect r) {
    r = qz_rect_pos_size(r);
    return r.size.width;
}
QZFloat QZRectGetHeight(QZRect r) {
    r = qz_rect_pos_size(r);
    return r.size.height;
}

bool QZRectIsEmpty(QZRect r) {
    if (qz_rect_is_null(r)) return true;
    r = qz_rect_pos_size(r);
    return r.size.width == 0 || r.size.height == 0;
}

QZRect QZRectStandardize(QZRect r) {
    if (qz_rect_is_null(r)) return kQZRectNull;
    return qz_rect_pos_size(r);
}

QZRect QZRectInset(QZRect r, QZFloat dx, QZFloat dy) {
    if (qz_rect_is_null(r)) return r;
    r = qz_rect_pos_size(r);
    r.origin.x += dx;
    r.origin.y += dy;
    r.size.width -= 2 * dx;
    r.size.height -= 2 * dy;
    if (r.size.width < 0 || r.size.height < 0) return kQZRectNull;
    return r;
}

QZRect QZRectOffset(QZRect r, QZFloat dx, QZFloat dy) {
    if (qz_rect_is_null(r)) return r;
    r = qz_rect_pos_size(r);
    r.origin.x += dx;
    r.origin.y += dy;
    return r;
}

QZRect QZRectIntegral(QZRect r) {
    if (qz_rect_is_null(r)) return r;
    r = qz_rect_pos_size(r);
    QZFloat x1 = std::floor(r.origin.x);
    QZFloat y1 = std::floor(r.origin.y);
    QZFloat x2 = std::ceil(r.origin.x + r.size.width);
    QZFloat y2 = std::ceil(r.origin.y + r.size.height);
    return QZRectMake(x1, y1, x2 - x1, y2 - y1);
}

QZRect QZRectUnion(QZRect a, QZRect b) {
    if (qz_rect_is_null(a)) return b;
    if (qz_rect_is_null(b)) return a;
    a = qz_rect_pos_size(a);
    b = qz_rect_pos_size(b);
    QZFloat x1 = std::min(a.origin.x, b.origin.x);
    QZFloat y1 = std::min(a.origin.y, b.origin.y);
    QZFloat x2 = std::max(a.origin.x + a.size.width, b.origin.x + b.size.width);
    QZFloat y2 = std::max(a.origin.y + a.size.height, b.origin.y + b.size.height);
    return QZRectMake(x1, y1, x2 - x1, y2 - y1);
}

QZRect QZRectIntersection(QZRect a, QZRect b) {
    if (qz_rect_is_null(a) || qz_rect_is_null(b)) return kQZRectNull;
    a = qz_rect_pos_size(a);
    b = qz_rect_pos_size(b);
    QZFloat x1 = std::max(a.origin.x, b.origin.x);
    QZFloat y1 = std::max(a.origin.y, b.origin.y);
    QZFloat x2 = std::min(a.origin.x + a.size.width, b.origin.x + b.size.width);
    QZFloat y2 = std::min(a.origin.y + a.size.height, b.origin.y + b.size.height);
    if (x2 < x1 || y2 < y1) return kQZRectNull;
    return QZRectMake(x1, y1, x2 - x1, y2 - y1);
}

bool QZRectContainsPoint(QZRect r, QZPoint p) {
    if (QZRectIsEmpty(r)) return false;
    r = qz_rect_pos_size(r);
    return p.x >= r.origin.x && p.x < r.origin.x + r.size.width &&
           p.y >= r.origin.y && p.y < r.origin.y + r.size.height;
}

bool QZRectContainsRect(QZRect a, QZRect b) {
    /* Closed min/max after standardize; every rect contains null. */
    if (qz_rect_is_null(b)) return true;
    if (qz_rect_is_null(a)) return false;
    a = qz_rect_pos_size(a);
    b = qz_rect_pos_size(b);
    return b.origin.x >= a.origin.x &&
           b.origin.x + b.size.width <= a.origin.x + a.size.width &&
           b.origin.y >= a.origin.y &&
           b.origin.y + b.size.height <= a.origin.y + a.size.height;
}

/* Half-open [min,max); a zero-length axis occupies the min point. */
static bool qz_in_span(QZFloat p, QZFloat lo, QZFloat hi) {
    return (lo < hi) ? (p >= lo && p < hi) : (p == lo);
}
static bool qz_span_overlap(QZFloat lo1, QZFloat hi1, QZFloat lo2, QZFloat hi2) {
    QZFloat x1 = std::max(lo1, lo2);
    QZFloat x2 = std::min(hi1, hi2);
    if (x1 < x2) return true;
    if (x1 > x2) return false;
    return qz_in_span(x1, lo1, hi1) && qz_in_span(x1, lo2, hi2);
}

bool QZRectIntersectsRect(QZRect a, QZRect b) {
    if (qz_rect_is_null(a) || qz_rect_is_null(b)) return false;
    a = qz_rect_pos_size(a);
    b = qz_rect_pos_size(b);
    return qz_span_overlap(a.origin.x, a.origin.x + a.size.width,
                           b.origin.x, b.origin.x + b.size.width) &&
           qz_span_overlap(a.origin.y, a.origin.y + a.size.height,
                           b.origin.y, b.origin.y + b.size.height);
}

bool QZAffineTransformIsIdentity(QZAffineTransform t) {
    return t.a == 1 && t.b == 0 && t.c == 0 && t.d == 1 && t.tx == 0 && t.ty == 0;
}
bool QZAffineTransformEqualToTransform(QZAffineTransform a, QZAffineTransform b) {
    return a.a == b.a && a.b == b.b && a.c == b.c && a.d == b.d && a.tx == b.tx && a.ty == b.ty;
}
