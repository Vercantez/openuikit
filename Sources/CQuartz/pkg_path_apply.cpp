#include "qz_internal.hpp"
/* OWNED BY package path-apply. */

void QZPathApply(QZPathRef path, void *info, QZPathApplierFunction function) {
    if (!path || !function) return;
    for (const auto &cmd : path->p.cmds) {
        QZPathElement e{};
        switch (cmd.op) {
        case qz::PathOp::Move:
            e.type = kQZPathElementMoveToPoint;
            e.points[0] = cmd.p[0].qz();
            break;
        case qz::PathOp::Line:
            e.type = kQZPathElementAddLineToPoint;
            e.points[0] = cmd.p[0].qz();
            break;
        case qz::PathOp::Cubic:
            e.type = kQZPathElementAddCurveToPoint;
            e.points[0] = cmd.p[0].qz();
            e.points[1] = cmd.p[1].qz();
            e.points[2] = cmd.p[2].qz();
            break;
        case qz::PathOp::Close:
            e.type = kQZPathElementCloseSubpath;
            break;
        }
        function(info, &e);
    }
}

size_t QZPathGetElementCount(QZPathRef path) {
    return path ? path->p.cmds.size() : 0;
}

void QZPathAddArcToPoint(QZMutablePathRef path, const QZAffineTransform *m,
                         QZFloat x1, QZFloat y1, QZFloat x2, QZFloat y2, QZFloat radius) {
    if (!path || !path->p.has_current) return;
    qz::Vec2 p1(x1, y1), p2(x2, y2);
    if (!m) {
        path->p.add_arc_to(p1, p2, radius);
        return;
    }
    /* Apple: construct the arc in the pre-transform space, then transform the
     * resulting Bézier curves. Inverse-map the current point, skip the tmp Move. */
    QZAffineTransform inv = QZAffineTransformInvert(*m);
    qz::Path tmp;
    tmp.move_to(qz::apply(inv, path->p.current));
    tmp.add_arc_to(p1, p2, radius);
    for (size_t i = 1; i < tmp.cmds.size(); i++) {
        const qz::PathCmd &c = tmp.cmds[i];
        switch (c.op) {
        case qz::PathOp::Move:
            path->p.move_to(qz::apply(*m, c.p[0]));
            break;
        case qz::PathOp::Line:
            path->p.line_to(qz::apply(*m, c.p[0]));
            break;
        case qz::PathOp::Cubic:
            path->p.cubic_to(qz::apply(*m, c.p[0]), qz::apply(*m, c.p[1]),
                             qz::apply(*m, c.p[2]));
            break;
        case qz::PathOp::Close:
            path->p.close();
            break;
        }
    }
}

void QZPathAddLines(QZMutablePathRef path, const QZAffineTransform *m,
                    const QZPoint *points, size_t count) {
    if (!path || !points || count == 0) return;
    for (size_t i = 0; i < count; i++) {
        qz::Vec2 p(points[i].x, points[i].y);
        if (m) p = qz::apply(*m, p);
        if (i == 0) path->p.move_to(p);
        else path->p.line_to(p);
    }
}
