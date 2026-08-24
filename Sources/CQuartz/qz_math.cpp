#include "qz_internal.hpp"

QZAffineTransform QZAffineTransformIdentity(void) {
    return {1, 0, 0, 1, 0, 0};
}
QZAffineTransform QZAffineTransformMake(QZFloat a, QZFloat b, QZFloat c, QZFloat d,
                                        QZFloat tx, QZFloat ty) {
    return {a, b, c, d, tx, ty};
}
QZAffineTransform QZAffineTransformMakeTranslation(QZFloat tx, QZFloat ty) {
    return {1, 0, 0, 1, tx, ty};
}
QZAffineTransform QZAffineTransformMakeScale(QZFloat sx, QZFloat sy) {
    return {sx, 0, 0, sy, 0, 0};
}
QZAffineTransform QZAffineTransformMakeRotation(QZFloat angle) {
    double c = std::cos(angle), s = std::sin(angle);
    return {c, s, -s, c, 0, 0};
}

QZAffineTransform QZAffineTransformConcat(QZAffineTransform t1, QZAffineTransform t2) {
    /* t' = t1 ∘ t2  (t2 applied first, matching Apple) */
    QZAffineTransform r;
    r.a  = t1.a * t2.a + t1.c * t2.b;
    r.b  = t1.b * t2.a + t1.d * t2.b;
    r.c  = t1.a * t2.c + t1.c * t2.d;
    r.d  = t1.b * t2.c + t1.d * t2.d;
    r.tx = t1.a * t2.tx + t1.c * t2.ty + t1.tx;
    r.ty = t1.b * t2.tx + t1.d * t2.ty + t1.ty;
    return r;
}

QZAffineTransform QZAffineTransformTranslate(QZAffineTransform t, QZFloat tx, QZFloat ty) {
    /* t' = t ∘ T : translation in user space, matching CoreGraphics. */
    return QZAffineTransformConcat(t, QZAffineTransformMakeTranslation(tx, ty));
}
QZAffineTransform QZAffineTransformScale(QZAffineTransform t, QZFloat sx, QZFloat sy) {
    return QZAffineTransformConcat(t, QZAffineTransformMakeScale(sx, sy));
}
QZAffineTransform QZAffineTransformRotate(QZAffineTransform t, QZFloat angle) {
    return QZAffineTransformConcat(t, QZAffineTransformMakeRotation(angle));
}

QZAffineTransform QZAffineTransformInvert(QZAffineTransform t) {
    double det = t.a * t.d - t.b * t.c;
    if (std::fabs(det) < 1e-20) return QZAffineTransformIdentity();
    double inv = 1.0 / det;
    QZAffineTransform r;
    r.a =  t.d * inv;
    r.b = -t.b * inv;
    r.c = -t.c * inv;
    r.d =  t.a * inv;
    r.tx = -(t.tx * r.a + t.ty * r.c);
    r.ty = -(t.tx * r.b + t.ty * r.d);
    return r;
}

QZPoint QZPointApplyAffineTransform(QZPoint p, QZAffineTransform t) {
    return QZPointMake(t.a * p.x + t.c * p.y + t.tx, t.b * p.x + t.d * p.y + t.ty);
}
QZSize QZSizeApplyAffineTransform(QZSize s, QZAffineTransform t) {
    return QZSizeMake(t.a * s.width + t.c * s.height, t.b * s.width + t.d * s.height);
}
QZRect QZRectApplyAffineTransform(QZRect r, QZAffineTransform t) {
    QZPoint p[4] = {
        r.origin,
        QZPointMake(r.origin.x + r.size.width, r.origin.y),
        QZPointMake(r.origin.x, r.origin.y + r.size.height),
        QZPointMake(r.origin.x + r.size.width, r.origin.y + r.size.height)
    };
    double minx = 1e300, miny = 1e300, maxx = -1e300, maxy = -1e300;
    for (int i = 0; i < 4; i++) {
        QZPoint q = QZPointApplyAffineTransform(p[i], t);
        minx = std::min(minx, q.x); miny = std::min(miny, q.y);
        maxx = std::max(maxx, q.x); maxy = std::max(maxy, q.y);
    }
    return QZRectMake(minx, miny, maxx - minx, maxy - miny);
}
