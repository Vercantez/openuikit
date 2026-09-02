#include "qz_internal.hpp"

namespace qz {

static Vec2 line_intersect(Vec2 p, Vec2 r, Vec2 q, Vec2 s, bool *ok) {
    double rxs = cross(r, s);
    if (std::fabs(rxs) < 1e-12) {
        *ok = false;
        return p;
    }
    Vec2 qp = q - p;
    double t = cross(qp, s) / rxs;
    *ok = true;
    return p + r * t;
}

static void add_fan(std::vector<Vec2> &dst, Vec2 center, Vec2 from, Vec2 to,
                    double radius, bool cw) {
    double a0 = std::atan2(from.y - center.y, from.x - center.x);
    double a1 = std::atan2(to.y - center.y, to.x - center.x);
    double sweep = a1 - a0;
    if (cw) {
        while (sweep > 0) sweep -= kTwoPi;
        while (sweep < -kTwoPi) sweep += kTwoPi;
        if (std::fabs(sweep) < 1e-12) sweep = 0;
    } else {
        while (sweep < 0) sweep += kTwoPi;
        while (sweep > kTwoPi) sweep -= kTwoPi;
        if (std::fabs(sweep) < 1e-12) sweep = 0;
    }
    double arc_len = std::fabs(sweep) * radius;
    int n = std::max(1, (int)std::ceil(arc_len / 0.35));
    if (n > 64) n = 64;
    for (int i = 1; i <= n; i++) {
        double a = a0 + sweep * (double)i / (double)n;
        dst.push_back({center.x + radius * std::cos(a),
                       center.y + radius * std::sin(a)});
    }
}

struct OffsetSeg {
    Vec2 p0, p1;
    Vec2 dir;
    Vec2 n; /* left normal * w2 */
};

static std::vector<OffsetSeg> offset_segments(const std::vector<Vec2> &pts, double w2) {
    std::vector<OffsetSeg> segs;
    for (size_t i = 0; i + 1 < pts.size(); i++) {
        Vec2 d = pts[i + 1] - pts[i];
        double L = length(d);
        if (L < 1e-12) continue;
        d = d * (1.0 / L);
        OffsetSeg s;
        s.p0 = pts[i];
        s.p1 = pts[i + 1];
        s.dir = d;
        s.n = perp(d) * w2;
        segs.push_back(s);
    }
    return segs;
}

static void stroke_one(const std::vector<Vec2> &pts, bool closed,
                       double width, QZLineCap cap, QZLineJoin join, double miter_limit,
                       std::vector<Polyline> &out) {
    if (width <= 0) return;
    double w2 = width * 0.5;
    if (pts.size() == 1) {
        if (cap == kQZLineCapButt) return;
        Polyline pl;
        pl.closed = true;
        if (cap == kQZLineCapRound) {
            int n = std::max(8, (int)std::ceil(kTwoPi * w2 / 0.35));
            for (int i = 0; i < n; i++) {
                double a = kTwoPi * i / n;
                pl.pts.push_back({pts[0].x + w2 * std::cos(a), pts[0].y + w2 * std::sin(a)});
            }
        } else {
            pl.pts.push_back({pts[0].x - w2, pts[0].y - w2});
            pl.pts.push_back({pts[0].x + w2, pts[0].y - w2});
            pl.pts.push_back({pts[0].x + w2, pts[0].y + w2});
            pl.pts.push_back({pts[0].x - w2, pts[0].y + w2});
        }
        out.push_back(std::move(pl));
        return;
    }

    auto segs = offset_segments(pts, w2);
    if (segs.empty()) return;

    std::vector<Vec2> outline;

    auto cap_points = [&](Vec2 center, Vec2 dir, Vec2 n, bool start) {
        Vec2 l = center + n;
        Vec2 r = center - n;
        if (closed || cap == kQZLineCapButt) {
            if (start) {
                outline.push_back(r);
                outline.push_back(l);
            } else {
                outline.push_back(l);
                outline.push_back(r);
            }
            return;
        }
        if (cap == kQZLineCapSquare) {
            Vec2 d = dir * w2;
            if (start) {
                outline.push_back(r - d);
                outline.push_back(l - d);
            } else {
                outline.push_back(l + d);
                outline.push_back(r + d);
            }
            return;
        }
        /* Round caps: semicircle through -dir (start) or +dir (end).
           With n = perp(dir)*w2, that arc is clockwise from right to left
           at the start, and clockwise from left to right at the end. */
        if (start) {
            outline.push_back(r);
            add_fan(outline, center, r, l, w2, true);
        } else {
            outline.push_back(l);
            add_fan(outline, center, l, r, w2, true);
        }
    };

    auto join_outer = [&](Vec2 vertex, const OffsetSeg &in, const OffsetSeg &out, bool left_side) {
        Vec2 in_pt  = left_side ? vertex + in.n  : vertex - in.n;
        Vec2 out_pt = left_side ? vertex + out.n : vertex - out.n;
        Vec2 in_dir = in.dir;
        Vec2 out_dir = out.dir;
        double cr = cross(in.dir, out.dir);
        bool this_is_outer = left_side ? (cr < 0) : (cr > 0);

        if (!this_is_outer) {
            /* inner corner: just connect (bevel on the inside is fine) */
            outline.push_back(in_pt);
            outline.push_back(out_pt);
            return;
        }
        if (join == kQZLineJoinBevel || std::fabs(cr) < 1e-14) {
            outline.push_back(in_pt);
            outline.push_back(out_pt);
            return;
        }
        if (join == kQZLineJoinRound) {
            outline.push_back(in_pt);
            bool cw = !left_side ? false : true;
            /* outer arc: from in_pt to out_pt the long/short way matching the turn */
            add_fan(outline, vertex, in_pt, out_pt, w2, cr < 0);
            (void)cw;
            return;
        }
        bool ok = false;
        Vec2 m = line_intersect(in_pt, in_dir, out_pt, out_dir, &ok);
        if (ok && length(m - vertex) <= miter_limit * w2) {
            outline.push_back(m);
        } else {
            outline.push_back(in_pt);
            outline.push_back(out_pt);
        }
    };

    size_t nseg = segs.size();
    if (closed) {
        std::vector<Vec2> outer, inner;
        for (size_t i = 0; i < nseg; i++) {
            const OffsetSeg &in = segs[i];
            const OffsetSeg &ou = segs[(i + 1) % nseg];
            size_t before = outline.size();
            join_outer(in.p1, in, ou, true);
            for (size_t k = before; k < outline.size(); k++) outer.push_back(outline[k]);
            outline.resize(before);
            join_outer(in.p1, in, ou, false);
            for (size_t k = before; k < outline.size(); k++) inner.push_back(outline[k]);
            outline.resize(before);
        }
        if (outer.size() >= 3) {
            Polyline pl;
            pl.closed = true;
            pl.pts = std::move(outer);
            out.push_back(std::move(pl));
        }
        if (inner.size() >= 3) {
            Polyline pl;
            pl.closed = true;
            pl.pts = std::move(inner);
            std::reverse(pl.pts.begin(), pl.pts.end());
            out.push_back(std::move(pl));
        }
        return;
    }

    cap_points(segs.front().p0, segs.front().dir, segs.front().n, true);
    for (size_t i = 0; i + 1 < nseg; i++) {
        join_outer(segs[i].p1, segs[i], segs[i + 1], true);
    }
    cap_points(segs.back().p1, segs.back().dir, segs.back().n, false);
    for (size_t i = nseg - 1; i > 0; i--) {
        OffsetSeg in_rev{segs[i].p1, segs[i].p0, segs[i].dir * -1.0, segs[i].n * -1.0};
        OffsetSeg out_rev{segs[i - 1].p1, segs[i - 1].p0, segs[i - 1].dir * -1.0,
                          segs[i - 1].n * -1.0};
        join_outer(segs[i].p0, in_rev, out_rev, true);
    }

    if (outline.size() >= 3) {
        Polyline pl;
        pl.closed = true;
        pl.pts = std::move(outline);
        out.push_back(std::move(pl));
    }
}

/* CG default flatness: dash length is walked on chords at this tolerance. */
static constexpr double kDashFlatness = 0.6;

static double dist_point_to_seg(Vec2 p, Vec2 a, Vec2 b) {
    Vec2 ab = b - a;
    double L2 = dot(ab, ab);
    if (L2 < 1e-24) return length(p - a);
    double t = clampd(dot(p - a, ab) / L2, 0.0, 1.0);
    return length(p - (a + ab * t));
}

static void rdp_mark(const std::vector<Vec2> &pts, std::vector<char> &keep,
                     size_t a, size_t b, double eps) {
    struct Span { size_t lo, hi; };
    std::vector<Span> st;
    st.push_back({a, b});
    while (!st.empty()) {
        Span s = st.back();
        st.pop_back();
        if (s.hi <= s.lo + 1) continue;
        double maxd = -1;
        size_t mid = s.lo;
        for (size_t i = s.lo + 1; i < s.hi; i++) {
            double d = dist_point_to_seg(pts[i], pts[s.lo], pts[s.hi]);
            if (d > maxd) {
                maxd = d;
                mid = i;
            }
        }
        if (maxd > eps) {
            keep[mid] = 1;
            st.push_back({mid, s.hi});
            st.push_back({s.lo, mid});
        }
    }
}

static std::vector<size_t> rdp_indices(const std::vector<Vec2> &pts, double eps) {
    const size_t n = pts.size();
    std::vector<size_t> idx;
    if (n == 0) return idx;
    std::vector<char> keep(n, 0);
    keep.front() = 1;
    keep.back() = 1;
    if (n >= 3) rdp_mark(pts, keep, 0, n - 1, eps);
    for (size_t i = 0; i < n; i++) if (keep[i]) idx.push_back(i);
    return idx;
}

static Vec2 point_along_fine(const std::vector<Vec2> &pts, size_t i0, size_t i1,
                             double t) {
    if (i1 <= i0) return pts[i0];
    t = clampd(t, 0.0, 1.0);
    double total = 0;
    for (size_t i = i0; i < i1; i++) total += length(pts[i + 1] - pts[i]);
    if (total < 1e-12) return pts[i0];
    double target = t * total;
    double acc = 0;
    for (size_t i = i0; i < i1; i++) {
        double sl = length(pts[i + 1] - pts[i]);
        if (acc + sl >= target - 1e-15) {
            double u = sl > 1e-12 ? (target - acc) / sl : 0;
            return pts[i] + (pts[i + 1] - pts[i]) * u;
        }
        acc += sl;
    }
    return pts[i1];
}

static void append_fine_span(Polyline &cur, const std::vector<Vec2> &pts,
                             size_t i0, size_t i1, double t0, double t1) {
    auto add = [&](Vec2 p) {
        if (cur.pts.empty() || length(cur.pts.back() - p) > 1e-14)
            cur.pts.push_back(p);
    };
    add(point_along_fine(pts, i0, i1, t0));
    double total = 0;
    for (size_t i = i0; i < i1; i++) total += length(pts[i + 1] - pts[i]);
    if (total > 1e-12) {
        double acc = 0;
        for (size_t i = i0 + 1; i < i1; i++) {
            acc += length(pts[i] - pts[i - 1]);
            double f = acc / total;
            if (f > t0 + 1e-12 && f < t1 - 1e-12) add(pts[i]);
        }
    }
    add(point_along_fine(pts, i0, i1, t1));
}

/* Dash: odd-length patterns are doubled (PDF / Quartz). Distance uses a
 * coarse flatten (default CG flatness); geometry stays on the fine polyline.
 * Dashed pieces are open so cap style applies at each dash end. */
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
    for (double &v : pattern) v = std::max(0.0, v);
    double pat_len = 0;
    for (double v : pattern) pat_len += v;
    if (pat_len < 1e-12) {
        out.push_back(src);
        return;
    }
    phase = std::fmod(phase, pat_len);
    if (phase < 0) phase += pat_len;

    size_t idx = 0;
    double into = phase;
    auto skip_zero = [&]() {
        size_t guard = 0;
        while (pattern[idx] <= 1e-12 && guard++ < pattern.size())
            idx = (idx + 1) % pattern.size();
    };
    skip_zero();
    while (into >= pattern[idx] - 1e-15) {
        into -= pattern[idx];
        idx = (idx + 1) % pattern.size();
        skip_zero();
        if (into < 1e-15) { into = 0; break; }
    }

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

    std::vector<size_t> coarse = rdp_indices(pts, kDashFlatness);
    if (coarse.size() < 2) {
        out.push_back(src);
        return;
    }

    auto remaining = [&]() { return pattern[idx] - into; };

    auto step_pattern = [&]() {
        emit_cur();
        idx = (idx + 1) % pattern.size();
        skip_zero();
        into = 0;
        on = (idx % 2 == 0);
    };

    for (size_t c = 0; c + 1 < coarse.size(); c++) {
        size_t i0 = coarse[c], i1 = coarse[c + 1];
        double chord = length(pts[i1] - pts[i0]);
        if (chord < 1e-12) continue;
        double pos = 0;
        while (pos < chord - 1e-12) {
            double rem = remaining();
            if (rem <= 1e-15) {
                step_pattern();
                continue;
            }
            double take = std::min(rem, chord - pos);
            double t0 = pos / chord;
            pos += take;
            double t1 = pos / chord;
            into += take;
            if (on) append_fine_span(cur, pts, i0, i1, t0, t1);
            if (into + 1e-12 >= pattern[idx]) step_pattern();
        }
    }
    emit_cur();
}

void stroke_polylines(const std::vector<Polyline> &src,
                      double width, QZLineCap cap, QZLineJoin join, double miter_limit,
                      double dash_phase, const std::vector<double> &dash,
                      std::vector<Polyline> &out) {
    std::vector<Polyline> dashed;
    if (dash.empty()) {
        dashed = src;
    } else {
        for (const auto &pl : src) dash_polyline(pl, dash_phase, dash, dashed);
    }
    for (const auto &pl : dashed) {
        stroke_one(pl.pts, pl.closed && dash.empty(), width, cap, join, miter_limit, out);
    }
}

} /* namespace qz */
