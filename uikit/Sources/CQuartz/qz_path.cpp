#include "qz_internal.hpp"

namespace qz {

void Path::clear() {
    cmds.clear();
    has_current = false;
    subpath_used = false;
    start = {0, 0};
    current = {0, 0};
}

void Path::move_to(Vec2 p) {
    PathCmd c;
    c.op = PathOp::Move;
    c.p[0] = p;
    cmds.push_back(c);
    start = current = p;
    has_current = true;
    subpath_used = false;
}

void Path::line_to(Vec2 p) {
    if (!has_current) {
        move_to(p);
        return;
    }
    PathCmd c;
    c.op = PathOp::Line;
    c.p[0] = p;
    cmds.push_back(c);
    current = p;
    subpath_used = true;
}

void Path::cubic_to(Vec2 c1, Vec2 c2, Vec2 p) {
    if (!has_current) move_to({0, 0});
    PathCmd c;
    c.op = PathOp::Cubic;
    c.p[0] = c1;
    c.p[1] = c2;
    c.p[2] = p;
    cmds.push_back(c);
    current = p;
    subpath_used = true;
}

void Path::quad_to(Vec2 ctrl, Vec2 p) {
    /* Elevate quadratic to cubic. */
    Vec2 p0 = has_current ? current : Vec2{0, 0};
    Vec2 c1 = p0 + (ctrl - p0) * (2.0 / 3.0);
    Vec2 c2 = p + (ctrl - p) * (2.0 / 3.0);
    cubic_to(c1, c2, p);
}

void Path::close() {
    if (!has_current) return;
    PathCmd c;
    c.op = PathOp::Close;
    cmds.push_back(c);
    current = start;
    subpath_used = false;
}

void Path::add_rect(QZRect r) {
    double x = r.origin.x, y = r.origin.y;
    double w = r.size.width, h = r.size.height;
    move_to({x, y});
    line_to({x + w, y});
    line_to({x + w, y + h});
    line_to({x, y + h});
    close();
}

void Path::add_rounded_rect(QZRect r, double radius) {
    double x = r.origin.x, y = r.origin.y;
    double w = r.size.width, h = r.size.height;
    double rad = std::min(radius, std::min(std::fabs(w), std::fabs(h)) * 0.5);
    if (rad <= 1e-6) {
        add_rect(r);
        return;
    }
    move_to({x + rad, y});
    line_to({x + w - rad, y});
    add_arc_to({x + w, y}, {x + w, y + rad}, rad);
    line_to({x + w, y + h - rad});
    add_arc_to({x + w, y + h}, {x + w - rad, y + h}, rad);
    line_to({x + rad, y + h});
    add_arc_to({x, y + h}, {x, y + h - rad}, rad);
    line_to({x, y + rad});
    add_arc_to({x, y}, {x + rad, y}, rad);
    close();
}

static void cubic_arc_segment(Path *path, double cx, double cy, double r,
                              double a0, double a1) {
    double da = a1 - a0;
    double k = (4.0 / 3.0) * std::tan(da / 4.0);
    double c0 = std::cos(a0), s0 = std::sin(a0);
    double c1 = std::cos(a1), s1 = std::sin(a1);
    Vec2 p0{cx + r * c0, cy + r * s0};
    Vec2 p1{cx + r * c1, cy + r * s1};
    Vec2 t0{cx + r * (c0 - k * s0), cy + r * (s0 + k * c0)};
    Vec2 t1{cx + r * (c1 + k * s1), cy + r * (s1 - k * c1)};
    path->cubic_to(t0, t1, p1);
    (void)p0;
}

void Path::add_ellipse(QZRect r) {
    /* Four cubic Beziers with kappa = 4*(sqrt(2)-1)/3. */
    double x = r.origin.x, y = r.origin.y;
    double w = r.size.width, h = r.size.height;
    double cx = x + w * 0.5, cy = y + h * 0.5;
    double rx = w * 0.5, ry = h * 0.5;
    const double k = 0.5522847498307936;
    double kx = k * rx, ky = k * ry;
    move_to({cx + rx, cy});
    cubic_to({cx + rx, cy + ky}, {cx + kx, cy + ry}, {cx, cy + ry});
    cubic_to({cx - kx, cy + ry}, {cx - rx, cy + ky}, {cx - rx, cy});
    cubic_to({cx - rx, cy - ky}, {cx - kx, cy - ry}, {cx, cy - ry});
    cubic_to({cx + kx, cy - ry}, {cx + rx, cy - ky}, {cx + rx, cy});
    close();
}

void Path::add_arc(double x, double y, double radius,
                   double start, double end, int clockwise) {
    double sweep = end - start;
    if (clockwise) {
        while (sweep > 0) sweep -= kTwoPi;
        while (sweep < -kTwoPi) sweep += kTwoPi;
        if (sweep == 0 && end != start) sweep = -kTwoPi;
    } else {
        while (sweep < 0) sweep += kTwoPi;
        while (sweep > kTwoPi) sweep -= kTwoPi;
        if (sweep == 0 && end != start) sweep = kTwoPi;
    }
    /* Quartz lines from the current point to the first arc point. */
    Vec2 first{x + radius * std::cos(start), y + radius * std::sin(start)};
    if (has_current) line_to(first);
    else move_to(first);

    int n = (int)std::ceil(std::fabs(sweep) / (kPi * 0.5) - 1e-12);
    if (n < 1) n = 1;
    if (n > 8) n = 8;
    double da = sweep / n;
    double a = start;
    for (int i = 0; i < n; i++) {
        cubic_arc_segment(this, x, y, radius, a, a + da);
        a += da;
    }
}

void Path::add_arc_to(Vec2 p1, Vec2 p2, double radius) {
    if (!has_current) {
        move_to(p1);
        return;
    }
    Vec2 p0 = current;
    Vec2 d1 = p0 - p1;
    Vec2 d2 = p2 - p1;
    double L1 = length(d1), L2 = length(d2);
    if (L1 < 1e-12 || L2 < 1e-12 || radius <= 0) {
        line_to(p1);
        return;
    }
    d1 = d1 * (1.0 / L1);
    d2 = d2 * (1.0 / L2);
    double cos_phi = clampd(dot(d1, d2), -1.0, 1.0);
    double phi = std::acos(cos_phi);
    if (phi < 1e-12 || std::fabs(kPi - phi) < 1e-12) {
        line_to(p1);
        return;
    }
    double tan_half = std::tan(phi * 0.5);
    if (std::fabs(tan_half) < 1e-12) {
        line_to(p1);
        return;
    }
    double dist = radius / tan_half;
    dist = std::min(dist, std::min(L1, L2));
    Vec2 t1 = p1 + d1 * dist;
    Vec2 t2 = p1 + d2 * dist;
    /* Center: from t1 along perp of d1. */
    double sgn = cross(d1, d2) < 0 ? -1.0 : 1.0;
    Vec2 n1 = perp(d1) * sgn;
    Vec2 n1u = normalized(n1);
    Vec2 center = t1 + n1u * radius;

    double a0 = std::atan2(t1.y - center.y, t1.x - center.x);
    double a1 = std::atan2(t2.y - center.y, t2.x - center.x);
    /* CCW corner (cross(d1,d2)<0) needs a CCW short arc from t1 to t2. */
    int clockwise = (sgn < 0) ? 0 : 1;
    line_to(t1);
    /* Don't line-to first arc point (already there). */
    bool had = has_current;
    Vec2 cur = current;
    /* Temporarily pretend we don't need the connecting line. */
    (void)had; (void)cur;
    /* Build arc without extra line: reuse add_arc internals by a local copy. */
    double start = a0, end = a1;
    double sweep = end - start;
    if (clockwise) {
        while (sweep > 0) sweep -= kTwoPi;
        while (sweep < -kTwoPi) sweep += kTwoPi;
        if (sweep == 0 && end != start) sweep = -kTwoPi;
    } else {
        while (sweep < 0) sweep += kTwoPi;
        while (sweep > kTwoPi) sweep -= kTwoPi;
        if (sweep == 0 && end != start) sweep = kTwoPi;
    }
    int n = (int)std::ceil(std::fabs(sweep) / (kPi * 0.5) - 1e-12);
    if (n < 1) n = 1;
    if (n > 8) n = 8;
    double da = sweep / n;
    double a = start;
    for (int i = 0; i < n; i++) {
        cubic_arc_segment(this, center.x, center.y, radius, a, a + da);
        a += da;
    }
}

void Path::append(const Path &other, const QZAffineTransform *m) {
    QZAffineTransform id = QZAffineTransformIdentity();
    QZAffineTransform t = m ? *m : id;
    for (const PathCmd &c : other.cmds) {
        switch (c.op) {
        case PathOp::Move:
            move_to(apply(t, c.p[0]));
            break;
        case PathOp::Line:
            line_to(apply(t, c.p[0]));
            break;
        case PathOp::Cubic:
            cubic_to(apply(t, c.p[0]), apply(t, c.p[1]), apply(t, c.p[2]));
            break;
        case PathOp::Close:
            close();
            break;
        }
    }
}

static double dist_to_line(Vec2 p, Vec2 a, Vec2 b) {
    Vec2 ab = b - a;
    double L2 = dot(ab, ab);
    if (L2 < 1e-24) return length(p - a);
    double t = clampd(dot(p - a, ab) / L2, 0.0, 1.0);
    Vec2 q = a + ab * t;
    return length(p - q);
}

static void flatten_cubic(Vec2 p0, Vec2 p1, Vec2 p2, Vec2 p3,
                          double flatness, int depth, std::vector<Vec2> &out) {
    if (depth > 16) {
        out.push_back(p3);
        return;
    }
    double d = dist_to_line(p1, p0, p3) + dist_to_line(p2, p0, p3);
    if (d <= flatness) {
        out.push_back(p3);
        return;
    }
    Vec2 p01 = (p0 + p1) * 0.5;
    Vec2 p12 = (p1 + p2) * 0.5;
    Vec2 p23 = (p2 + p3) * 0.5;
    Vec2 p012 = (p01 + p12) * 0.5;
    Vec2 p123 = (p12 + p23) * 0.5;
    Vec2 p0123 = (p012 + p123) * 0.5;
    flatten_cubic(p0, p01, p012, p0123, flatness, depth + 1, out);
    flatten_cubic(p0123, p123, p23, p3, flatness, depth + 1, out);
}

void flatten_path(const Path &path, double flatness, std::vector<Polyline> &out) {
    if (flatness < 0.05) flatness = 0.05;
    Polyline cur;
    auto flush = [&](bool closed) {
        if (cur.pts.size() >= 2) {
            cur.closed = closed;
            out.push_back(std::move(cur));
        }
        cur = Polyline{};
    };
    Vec2 start{0, 0};
    Vec2 last{0, 0};
    bool have = false;
    for (const PathCmd &c : path.cmds) {
        switch (c.op) {
        case PathOp::Move:
            flush(false);
            start = last = c.p[0];
            cur.pts.push_back(start);
            have = true;
            break;
        case PathOp::Line:
            if (!have) {
                start = last = c.p[0];
                cur.pts.push_back(start);
                have = true;
            } else {
                if (length(c.p[0] - last) > 1e-12) cur.pts.push_back(c.p[0]);
                last = c.p[0];
            }
            break;
        case PathOp::Cubic:
            if (!have) {
                start = last = {0, 0};
                cur.pts.push_back(start);
                have = true;
            }
            flatten_cubic(last, c.p[0], c.p[1], c.p[2], flatness, 0, cur.pts);
            last = c.p[2];
            break;
        case PathOp::Close:
            if (have) {
                if (length(start - last) > 1e-12) cur.pts.push_back(start);
                flush(true);
                cur.pts.push_back(start);
                last = start;
            }
            break;
        }
    }
    flush(false);
}

} /* namespace qz */

/* ---- public path objects ---- */

QZMutablePathRef QZPathCreateMutable(void) {
    return new QZPath();
}
QZPathRef QZPathRetain(QZPathRef path) {
    if (path) path->p.ref++;
    return path;
}
void QZPathRelease(QZPathRef path) {
    if (!path) return;
    if (--path->p.ref <= 0) delete path;
}

static QZAffineTransform ident_or(const QZAffineTransform *m) {
    return m ? *m : QZAffineTransformIdentity();
}

void QZPathMoveToPoint(QZMutablePathRef path, const QZAffineTransform *m, QZFloat x, QZFloat y) {
    if (!path) return;
    path->p.move_to(qz::apply(ident_or(m), qz::Vec2{x, y}));
}
void QZPathAddLineToPoint(QZMutablePathRef path, const QZAffineTransform *m, QZFloat x, QZFloat y) {
    if (!path) return;
    path->p.line_to(qz::apply(ident_or(m), qz::Vec2{x, y}));
}
void QZPathAddCurveToPoint(QZMutablePathRef path, const QZAffineTransform *m,
                           QZFloat cp1x, QZFloat cp1y, QZFloat cp2x, QZFloat cp2y,
                           QZFloat x, QZFloat y) {
    if (!path) return;
    QZAffineTransform t = ident_or(m);
    path->p.cubic_to(qz::apply(t, qz::Vec2{cp1x, cp1y}),
                     qz::apply(t, qz::Vec2{cp2x, cp2y}),
                     qz::apply(t, qz::Vec2{x, y}));
}
void QZPathAddQuadCurveToPoint(QZMutablePathRef path, const QZAffineTransform *m,
                               QZFloat cpx, QZFloat cpy, QZFloat x, QZFloat y) {
    if (!path) return;
    QZAffineTransform t = ident_or(m);
    path->p.quad_to(qz::apply(t, qz::Vec2{cpx, cpy}), qz::apply(t, qz::Vec2{x, y}));
}
void QZPathAddRect(QZMutablePathRef path, const QZAffineTransform *m, QZRect rect) {
    if (!path) return;
    qz::Path tmp;
    tmp.add_rect(rect);
    path->p.append(tmp, m);
}
void QZPathAddRoundedRect(QZMutablePathRef path, const QZAffineTransform *m,
                          QZRect rect, QZFloat cornerRadius) {
    if (!path) return;
    qz::Path tmp;
    tmp.add_rounded_rect(rect, cornerRadius);
    path->p.append(tmp, m);
}
void QZPathAddEllipseInRect(QZMutablePathRef path, const QZAffineTransform *m, QZRect rect) {
    if (!path) return;
    qz::Path tmp;
    tmp.add_ellipse(rect);
    path->p.append(tmp, m);
}
void QZPathAddArc(QZMutablePathRef path, const QZAffineTransform *m,
                  QZFloat x, QZFloat y, QZFloat radius,
                  QZFloat startAngle, QZFloat endAngle, int clockwise) {
    if (!path) return;
    qz::Path tmp;
    tmp.add_arc(x, y, radius, startAngle, endAngle, clockwise);
    path->p.append(tmp, m);
}
void QZPathCloseSubpath(QZMutablePathRef path) {
    if (path) path->p.close();
}
void QZPathAddPath(QZMutablePathRef path, const QZAffineTransform *m, QZPathRef other) {
    if (path && other) path->p.append(other->p, m);
}
