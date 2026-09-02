#include "qz_internal.hpp"
/* OWNED BY package path-stroke. */

using namespace qz;

static constexpr double kStrokeFlatness = 0.25;

static Path transformed_path(const Path &src, const QZAffineTransform *m) {
    Path out;
    out.append(src, m);
    return out;
}

static void polylines_to_path(const std::vector<Polyline> &pls, Path &dst) {
    for (const Polyline &pl : pls) {
        if (pl.pts.size() < 2) continue;
        dst.move_to(pl.pts[0]);
        for (size_t i = 1; i < pl.pts.size(); i++) dst.line_to(pl.pts[i]);
        if (pl.closed) dst.close();
    }
}

/* Dash: split a polyline into on/off segments. Odd-length patterns are doubled
 * (PDF / Quartz behaviour). Mirrors qz_stroke.cpp (static there). */
static void dash_polyline(const Polyline &src, double phase,
                          std::vector<double> pattern,
                          std::vector<Polyline> &out) {
    if (pattern.empty() || src.pts.size() < 2) {
        out.push_back(src);
        return;
    }
    if (pattern.size() % 2 == 1) {
        size_t n = pattern.size();
        for (size_t i = 0; i < n; i++) pattern.push_back(pattern[i]);
    }
    double pat_len = 0;
    for (double v : pattern) pat_len += std::max(0.0, v);
    if (pat_len < 1e-12) {
        out.push_back(src);
        return;
    }
    phase = std::fmod(phase, pat_len);
    if (phase < 0) phase += pat_len;

    size_t idx = 0;
    double into = phase;
    while (into >= pattern[idx] && idx < pattern.size()) {
        into -= pattern[idx];
        idx++;
        if (idx >= pattern.size()) idx = 0;
    }

    auto remaining = [&]() { return pattern[idx] - into; };
    bool on = (idx % 2 == 0);

    Polyline cur;
    auto emit_cur = [&]() {
        if (cur.pts.size() >= 2) {
            cur.closed = false;
            out.push_back(cur);
        }
        cur = Polyline{};
    };

    std::vector<Vec2> pts = src.pts;
    if (src.closed && (pts.empty() || length(pts.front() - pts.back()) > 1e-12)) {
        pts.push_back(pts.front());
    }

    auto append_pt = [&](Vec2 p) {
        if (!on) return;
        if (cur.pts.empty() || length(cur.pts.back() - p) > 1e-14) cur.pts.push_back(p);
    };

    append_pt(pts[0]);
    for (size_t i = 0; i + 1 < pts.size(); i++) {
        Vec2 a = pts[i], b = pts[i + 1];
        Vec2 d = b - a;
        double seg = length(d);
        if (seg < 1e-12) continue;
        Vec2 dir = d * (1.0 / seg);
        double pos = 0;
        while (pos < seg - 1e-12) {
            double rem = remaining();
            double take = std::min(rem, seg - pos);
            pos += take;
            Vec2 p = a + dir * pos;
            into += take;
            if (on) append_pt(p);
            if (into + 1e-12 >= pattern[idx]) {
                if (on) append_pt(p);
                emit_cur();
                idx = (idx + 1) % pattern.size();
                into = 0;
                on = (idx % 2 == 0);
                if (on) append_pt(p);
            }
        }
    }
    emit_cur();
}

QZPathRef QZPathCreateCopyByStrokingPath(QZPathRef path, const QZAffineTransform *m,
                                         QZFloat lineWidth, QZLineCap cap, QZLineJoin join,
                                         QZFloat miterLimit) {
    if (!path) return nullptr;
    Path src = transformed_path(path->p, m);
    std::vector<Polyline> flat;
    flatten_path(src, kStrokeFlatness, flat);
    std::vector<Polyline> outlines;
    std::vector<double> nodash;
    stroke_polylines(flat, lineWidth, cap, join, miterLimit, 0, nodash, outlines);
    auto *out = new QZPath();
    polylines_to_path(outlines, out->p);
    return out;
}

QZPathRef QZPathCreateCopyByDashingPath(QZPathRef path, const QZAffineTransform *m,
                                        QZFloat phase, const QZFloat *lengths, size_t count) {
    if (!path) return nullptr;
    if (!lengths || count == 0) {
        return QZPathCreateCopyByTransformingPath(path, m);
    }
    Path src = transformed_path(path->p, m);
    std::vector<Polyline> flat;
    flatten_path(src, kStrokeFlatness, flat);
    std::vector<double> pattern;
    pattern.reserve(count);
    for (size_t i = 0; i < count; i++) pattern.push_back(lengths[i]);
    std::vector<Polyline> dashed;
    for (const Polyline &pl : flat) dash_polyline(pl, phase, pattern, dashed);
    auto *out = new QZPath();
    polylines_to_path(dashed, out->p);
    return out;
}

void QZContextReplacePathWithStrokedPath(QZContextRef ctx) {
    if (!ctx) return;
    double flat = std::max(0.08, ctx->gs.flatness * 0.25);
    std::vector<Polyline> flat_user;
    flatten_path(ctx->path, flat, flat_user);
    std::vector<Polyline> outlines;
    stroke_polylines(flat_user, ctx->gs.line_width, ctx->gs.line_cap, ctx->gs.line_join,
                     ctx->gs.miter_limit, ctx->gs.dash_phase, ctx->gs.dash, outlines);
    ctx->path.clear();
    polylines_to_path(outlines, ctx->path);
}

void QZContextAddLines(QZContextRef ctx, const QZPoint *points, size_t count) {
    if (!ctx || !points || count == 0) return;
    QZContextMoveToPoint(ctx, points[0].x, points[0].y);
    for (size_t i = 1; i < count; i++) QZContextAddLineToPoint(ctx, points[i].x, points[i].y);
}

void QZContextStrokeLineSegments(QZContextRef ctx, const QZPoint *points, size_t count) {
    if (!ctx || !points || count < 2) return;
    /* CG: BeginPath, Move/Line per pair, StrokePath once — does not clear GState. */
    QZContextBeginPath(ctx);
    for (size_t i = 0; i + 1 < count; i += 2) {
        QZContextMoveToPoint(ctx, points[i].x, points[i].y);
        QZContextAddLineToPoint(ctx, points[i + 1].x, points[i + 1].y);
    }
    QZContextStrokePath(ctx);
}

void QZContextFillRects(QZContextRef ctx, const QZRect *rects, size_t count) {
    if (!ctx || !rects) return;
    for (size_t i = 0; i < count; i++) QZContextFillRect(ctx, rects[i]);
}
