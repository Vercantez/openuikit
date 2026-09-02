#include "qz_internal.hpp"
/* OWNED BY package pattern. */

#include <unordered_map>

using namespace qz;

struct QZPattern {
    void *info = nullptr;
    QZRect bounds{{0, 0}, {0, 0}};
    QZAffineTransform matrix{1, 0, 0, 1, 0, 0};
    QZFloat xStep = 0, yStep = 0;
    QZPatternTiling tiling = kQZPatternTilingNoDistortion;
    int isColored = 1;
    QZPatternDrawCallback draw = nullptr;
};

struct CtxPat {
    uint8_t *pixels = nullptr;
    int w = 0, h = 0;
    bool has_fill = false;
    QZPattern fill;
    QZFloat fill_c[4] = {1, 1, 1, 1};
    size_t fill_n = 0;
    bool has_stroke = false;
    QZPattern stroke;
    QZFloat stroke_c[4] = {1, 1, 1, 1};
    size_t stroke_n = 0;
    QZSize phase{0, 0};
    int depth = 0;
};

static std::unordered_map<QZContext *, CtxPat> g_pat;

static CtxPat &pat_state(QZContext *ctx) {
    CtxPat &s = g_pat[ctx];
    if (s.pixels != ctx->pixels || s.w != ctx->width || s.h != ctx->height) {
        QZSize phase = s.phase;
        int depth = s.depth;
        s = CtxPat{};
        s.pixels = ctx->pixels;
        s.w = ctx->width;
        s.h = ctx->height;
        s.phase = phase;
        s.depth = depth;
    }
    return s;
}

static void copy_comps(QZFloat *dst, size_t *dn, const QZFloat *src, size_t n) {
    *dn = 0;
    dst[0] = dst[1] = dst[2] = 0;
    dst[3] = 1;
    if (!src || n == 0) return;
    size_t m = n < 4 ? n : 4;
    for (size_t i = 0; i < m; i++) dst[i] = src[i];
    *dn = n;
}

static QZAffineTransform yflip(int height) {
    return QZAffineTransformMake(1, 0, 0, -1, 0, (QZFloat)height);
}

static void ensure_clip(GState &gs, int w, int h) {
    size_t n = (size_t)w * (size_t)h;
    if (gs.clip.size() != n) gs.clip.assign(n, 255);
}

static Color comps_to_color(const QZFloat *c, size_t n) {
    if (n >= 4) return {c[0], c[1], c[2], c[3]};
    if (n == 3) return {c[0], c[1], c[2], 1};
    if (n == 2) return {c[0], c[0], c[0], c[1]};
    if (n == 1) return {c[0], c[0], c[0], 1};
    return {0, 0, 0, 1};
}

static void mem_bbox(const std::vector<Polyline> &polys,
                     double *minx, double *miny, double *maxx, double *maxy) {
    *minx = 1e300;
    *miny = 1e300;
    *maxx = -1e300;
    *maxy = -1e300;
    for (const Polyline &pl : polys) {
        for (Vec2 p : pl.pts) {
            *minx = std::min(*minx, p.x);
            *miny = std::min(*miny, p.y);
            *maxx = std::max(*maxx, p.x);
            *maxy = std::max(*maxy, p.y);
        }
    }
}

static void expand_user_bbox(QZAffineTransform user_from_mem,
                             double minx, double miny, double maxx, double maxy,
                             double *uminx, double *uminy, double *umaxx, double *umaxy) {
    Vec2 c[4] = {{minx, miny}, {maxx, miny}, {minx, maxy}, {maxx, maxy}};
    *uminx = 1e300;
    *uminy = 1e300;
    *umaxx = -1e300;
    *umaxy = -1e300;
    for (int i = 0; i < 4; i++) {
        Vec2 u = apply(user_from_mem, c[i]);
        *uminx = std::min(*uminx, u.x);
        *uminy = std::min(*uminy, u.y);
        *umaxx = std::max(*umaxx, u.x);
        *umaxy = std::max(*umaxy, u.y);
    }
}

static void pattern_bbox(QZAffineTransform pat_from_user, QZSize phase,
                         double uminx, double uminy, double umaxx, double umaxy,
                         double *pminx, double *pminy, double *pmaxx, double *pmaxy) {
    Vec2 c[4] = {
        {uminx - phase.width, uminy - phase.height},
        {umaxx - phase.width, uminy - phase.height},
        {uminx - phase.width, umaxy - phase.height},
        {umaxx - phase.width, umaxy - phase.height}};
    *pminx = 1e300;
    *pminy = 1e300;
    *pmaxx = -1e300;
    *pmaxy = -1e300;
    for (int i = 0; i < 4; i++) {
        Vec2 p = apply(pat_from_user, c[i]);
        *pminx = std::min(*pminx, p.x);
        *pminy = std::min(*pminy, p.y);
        *pmaxx = std::max(*pmaxx, p.x);
        *pmaxy = std::max(*pmaxy, p.y);
    }
}

static void tile_range(double pmin, double pmax, double b0, double b1, double step,
                       int *i0, int *i1) {
    if (!(step > 1e-12)) {
        *i0 = 0;
        *i1 = 0;
        return;
    }
    *i0 = (int)std::floor((pmin - b1) / step) - 1;
    *i1 = (int)std::ceil((pmax - b0) / step) + 1;
}

/* Apple: CTM' = CTM * T(phase) * patternMatrix * T(i*xStep, j*yStep).
 * Callback origin is the pattern cell; drawing is clipped to bounds. */
static void paint_tiles(QZContext *ctx, const QZPattern &pat, QZSize phase,
                        double uminx, double uminy, double umaxx, double umaxy) {
    QZAffineTransform pat_from_user = QZAffineTransformInvert(pat.matrix);
    double pminx, pminy, pmaxx, pmaxy;
    pattern_bbox(pat_from_user, phase, uminx, uminy, umaxx, umaxy,
                 &pminx, &pminy, &pmaxx, &pmaxy);
    double xStep = pat.xStep > 1e-12 ? pat.xStep : pat.bounds.size.width;
    double yStep = pat.yStep > 1e-12 ? pat.yStep : pat.bounds.size.height;
    double bx0 = pat.bounds.origin.x;
    double by0 = pat.bounds.origin.y;
    double bx1 = bx0 + pat.bounds.size.width;
    double by1 = by0 + pat.bounds.size.height;
    int i0, i1, j0, j1;
    tile_range(pminx, pmaxx, bx0, bx1, xStep, &i0, &i1);
    tile_range(pminy, pmaxy, by0, by1, yStep, &j0, &j1);
    if (i1 - i0 > 4096) i1 = i0 + 4096;
    if (j1 - j0 > 4096) j1 = j0 + 4096;

    for (int j = j0; j <= j1; j++) {
        for (int i = i0; i <= i1; i++) {
            QZContextSaveGState(ctx);
            QZContextTranslateCTM(ctx, phase.width, phase.height);
            QZContextConcatCTM(ctx, pat.matrix);
            QZContextTranslateCTM(ctx, i * xStep, j * yStep);
            QZContextClipToRect(ctx, pat.bounds);
            if (pat.draw) pat.draw(pat.info, ctx);
            QZContextRestoreGState(ctx);
        }
    }
}

QZPatternRef QZPatternCreate(void *info, QZRect bounds, QZAffineTransform matrix,
                             QZFloat xStep, QZFloat yStep, QZPatternTiling tiling,
                             int isColored, QZPatternDrawCallback draw) {
    auto *p = new QZPattern();
    p->info = info;
    p->bounds = bounds;
    p->matrix = matrix;
    p->xStep = xStep;
    p->yStep = yStep;
    p->tiling = tiling;
    p->isColored = isColored;
    p->draw = draw;
    return p;
}

void QZPatternRelease(QZPatternRef pattern) { delete pattern; }

void QZContextSetFillPattern(QZContextRef ctx, QZPatternRef pattern,
                             const QZFloat *components, size_t ncomponents) {
    if (!ctx) return;
    CtxPat &s = pat_state(ctx);
    if (!pattern) {
        s.has_fill = false;
        return;
    }
    s.has_fill = true;
    s.fill = *pattern;
    copy_comps(s.fill_c, &s.fill_n, components, ncomponents);
}

void QZContextSetStrokePattern(QZContextRef ctx, QZPatternRef pattern,
                               const QZFloat *components, size_t ncomponents) {
    if (!ctx) return;
    CtxPat &s = pat_state(ctx);
    if (!pattern) {
        s.has_stroke = false;
        return;
    }
    s.has_stroke = true;
    s.stroke = *pattern;
    copy_comps(s.stroke_c, &s.stroke_n, components, ncomponents);
}

void QZContextSetPatternPhase(QZContextRef ctx, QZSize phase) {
    if (!ctx) return;
    pat_state(ctx).phase = phase;
}

bool qz_pkg_try_pattern_fill(QZContext *ctx, const std::vector<qz::Polyline> &polys,
                             bool even_odd, qz::Color color) {
    (void)color;
    if (!ctx || polys.empty()) return false;
    auto it = g_pat.find(ctx);
    if (it == g_pat.end()) return false;
    CtxPat &s = it->second;
    if (s.pixels != ctx->pixels || s.w != ctx->width || s.h != ctx->height) {
        g_pat.erase(it);
        return false;
    }
    if (!s.has_fill || s.depth > 0) return false;

    const QZPattern pat = s.fill;
    const QZSize phase = s.phase;
    QZFloat comps[4] = {s.fill_c[0], s.fill_c[1], s.fill_c[2], s.fill_c[3]};
    size_t ncomp = s.fill_n;
    s.depth++;

    int w = ctx->width, h = ctx->height;
    std::vector<Edge> edges;
    build_edges(polys, edges);
    std::vector<float> cov((size_t)w * (size_t)h);
    rasterize(edges, w, h, even_odd, ctx->gs.antialias, cov.data());
    ensure_clip(ctx->gs, w, h);

    QZContextSaveGState(ctx);
    for (int i = 0, n = w * h; i < n; i++) {
        float c = cov[i];
        if (c < 0) c = 0;
        if (c > 1) c = 1;
        unsigned v = (unsigned)(c * ctx->gs.clip[i] + 0.5f);
        ctx->gs.clip[i] = (uint8_t)(v > 255 ? 255 : v);
    }

    /* Callback FillRect must not re-enter pattern fill. */
    s.has_fill = false;

    if (pat.isColored) {
        double a = (ncomp >= 1) ? (double)comps[0] : 1.0;
        ctx->gs.alpha *= clampd(a, 0, 1);
    } else {
        Color fc = comps_to_color(comps, ncomp);
        QZContextSetRGBFillColor(ctx, fc.r, fc.g, fc.b, fc.a);
    }

    double minx, miny, maxx, maxy;
    mem_bbox(polys, &minx, &miny, &maxx, &maxy);
    QZAffineTransform user_from_mem =
        QZAffineTransformInvert(QZAffineTransformConcat(yflip(h), ctx->gs.ctm));
    double uminx, uminy, umaxx, umaxy;
    expand_user_bbox(user_from_mem, minx, miny, maxx, maxy,
                     &uminx, &uminy, &umaxx, &umaxy);
    paint_tiles(ctx, pat, phase, uminx, uminy, umaxx, umaxy);

    s.has_fill = true;
    QZContextRestoreGState(ctx);
    s.depth--;
    return true;
}
