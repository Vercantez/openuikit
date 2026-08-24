#include "qz_internal.hpp"

/* OWNED BY package shape-stroke. */

void QZShapeLayerSetStrokeStart(QZLayerRef layer, QZFloat t) {
    if (layer) layer->shape_stroke_start = qz::clampd(t, 0, 1);
}
void QZShapeLayerSetStrokeEnd(QZLayerRef layer, QZFloat t) {
    if (layer) layer->shape_stroke_end = qz::clampd(t, 0, 1);
}
void QZShapeLayerSetMiterLimit(QZLayerRef layer, QZFloat limit) {
    if (layer) layer->shape_miter = std::max(1.0, (double)limit);
}
void QZShapeLayerSetLineDash(QZLayerRef layer, QZFloat phase, const QZFloat *lengths, size_t count) {
    if (!layer) return;
    layer->shape_dash_phase = phase;
    layer->shape_dash.clear();
    for (size_t i = 0; i < count; i++) layer->shape_dash.push_back(lengths[i]);
}

using qz::Polyline;
using qz::Vec2;
using qz::length;
using qz::flatten_path;

static double polyline_arc_length(const Polyline &pl) {
    double L = 0;
    if (pl.pts.size() < 2) return 0;
    for (size_t i = 0; i + 1 < pl.pts.size(); i++)
        L += length(pl.pts[i + 1] - pl.pts[i]);
    if (pl.closed) {
        double g = length(pl.pts.front() - pl.pts.back());
        if (g > 1e-12) L += g;
    }
    return L;
}

/* Extract the [s, e] arc-length span of one flattened polyline. A fully covered
 * closed contour stays closed; a partial take is always open. */
static void extract_span(const Polyline &pl, double s, double e, bool full, Polyline &out) {
    out = Polyline{};
    if (pl.pts.size() < 2 || e <= s) return;
    if (full) {
        out = pl;
        return;
    }
    std::vector<Vec2> pts = pl.pts;
    if (pl.closed && length(pts.front() - pts.back()) > 1e-12)
        pts.push_back(pts.front());
    out.closed = false;
    double dist = 0;
    bool started = false;
    for (size_t i = 0; i + 1 < pts.size(); i++) {
        Vec2 a = pts[i], b = pts[i + 1];
        double seg = length(b - a);
        if (seg < 1e-12) continue;
        double d0 = dist, d1 = dist + seg;
        dist = d1;
        if (d1 < s - 1e-12) continue;
        if (d0 > e + 1e-12) break;
        double u0 = (s <= d0) ? 0.0 : (s - d0) / seg;
        double u1 = (e >= d1) ? 1.0 : (e - d0) / seg;
        if (u0 < 0) u0 = 0;
        if (u1 > 1) u1 = 1;
        if (u1 <= u0) continue;
        Vec2 p0 = a + (b - a) * u0;
        Vec2 p1 = a + (b - a) * u1;
        if (!started) {
            out.pts.push_back(p0);
            started = true;
        }
        if (out.pts.empty() || length(out.pts.back() - p1) > 1e-14)
            out.pts.push_back(p1);
    }
}

static void trim_polylines(const std::vector<Polyline> &src, double t0, double t1,
                           std::vector<Polyline> &dst) {
    dst.clear();
    t0 = qz::clampd(t0, 0, 1);
    t1 = qz::clampd(t1, 0, 1);
    if (t1 <= t0) return;
    double total = 0;
    for (const auto &pl : src) total += polyline_arc_length(pl);
    if (total < 1e-12) return;
    double s = t0 * total, e = t1 * total;
    double acc = 0;
    for (const auto &pl : src) {
        double L = polyline_arc_length(pl);
        double a = acc, b = acc + L;
        acc += L;
        double os = std::max(s, a);
        double oe = std::min(e, b);
        if (oe - os <= 1e-12) continue;
        bool full = (os <= a + 1e-12 && oe >= b - 1e-12);
        Polyline out;
        extract_span(pl, os - a, oe - a, full, out);
        if (out.pts.size() >= 2) dst.push_back(std::move(out));
    }
}

static void add_polylines(QZContextRef ctx, const std::vector<Polyline> &polys) {
    for (const auto &pl : polys) {
        if (pl.pts.size() < 2) continue;
        QZContextMoveToPoint(ctx, pl.pts[0].x, pl.pts[0].y);
        for (size_t i = 1; i < pl.pts.size(); i++)
            QZContextAddLineToPoint(ctx, pl.pts[i].x, pl.pts[i].y);
        if (pl.closed) QZContextClosePath(ctx);
    }
}

/* Honor strokeStart/End (arc-length trim), dash, and miter on a shape layer. */
void qz_shape_paint_stroke(QZLayer *layer, QZContext *ctx) {
    if (!layer || !ctx) return;
    QZContextSetRGBStrokeColor(ctx, layer->shape_stroke.r, layer->shape_stroke.g,
                               layer->shape_stroke.b, layer->shape_stroke.a);
    QZContextSetLineWidth(ctx, layer->shape_line_width);
    QZContextSetLineCap(ctx, layer->shape_cap);
    QZContextSetLineJoin(ctx, layer->shape_join);
    QZContextSetMiterLimit(ctx, layer->shape_miter);
    if (!layer->shape_dash.empty()) {
        QZContextSetLineDash(ctx, layer->shape_dash_phase,
                             layer->shape_dash.data(), layer->shape_dash.size());
    } else {
        QZContextSetLineDash(ctx, 0, nullptr, 0);
    }

    double t0 = layer->shape_stroke_start;
    double t1 = layer->shape_stroke_end;
    if (t1 <= t0 + 1e-12) return;

    QZContextBeginPath(ctx);
    bool full = (t0 <= 1e-9 && t1 >= 1.0 - 1e-9);
    if (full) {
        QZPath tmp;
        tmp.p = layer->shape_path;
        QZContextAddPath(ctx, &tmp);
    } else {
        QZAffineTransform ctm = ctx->gs.ctm;
        double sc = 0.5 * (qz::hypot2(ctm.a, ctm.b) + qz::hypot2(ctm.c, ctm.d));
        if (sc < 1e-8) sc = 1;
        double flat = std::max(0.08, ctx->gs.flatness * 0.25) / sc;
        std::vector<Polyline> flat_user, trimmed;
        flatten_path(layer->shape_path, flat, flat_user);
        trim_polylines(flat_user, t0, t1, trimmed);
        add_polylines(ctx, trimmed);
    }
    QZContextStrokePath(ctx);
    QZContextSetLineDash(ctx, 0, nullptr, 0);
}
