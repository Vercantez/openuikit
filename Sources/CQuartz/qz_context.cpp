#include "qz_internal.hpp"

using namespace qz;

static QZAffineTransform yflip(int height) {
    /* device y-up, origin bottom-left  ->  memory y-down, origin top-left */
    return QZAffineTransformMake(1, 0, 0, -1, 0, (QZFloat)height);
}

static QZAffineTransform user_to_mem(const GState &gs, int height) {
    return QZAffineTransformConcat(yflip(height), gs.ctm);
}

static Path transform_path(const Path &src, QZAffineTransform t) {
    Path out;
    out.append(src, &t);
    return out;
}

static void ensure_clip(GState &gs, int w, int h) {
    size_t n = (size_t)w * (size_t)h;
    if (gs.clip.size() != n) {
        gs.clip.assign(n, 255);
    }
}

static void box_blur(std::vector<float> &img, int w, int h, int radius) {
    if (radius < 1) return;
    std::vector<float> tmp(img.size());
    int span = radius * 2 + 1;
    for (int y = 0; y < h; y++) {
        double acc = 0;
        for (int x = -radius; x <= radius; x++) {
            int xx = clampi(x, 0, w - 1);
            acc += img[y * w + xx];
        }
        for (int x = 0; x < w; x++) {
            tmp[y * w + x] = (float)(acc / span);
            int xout = x - radius;
            int xin = x + radius + 1;
            acc -= img[y * w + clampi(xout, 0, w - 1)];
            acc += img[y * w + clampi(xin, 0, w - 1)];
        }
    }
    for (int x = 0; x < w; x++) {
        double acc = 0;
        for (int y = -radius; y <= radius; y++) {
            int yy = clampi(y, 0, h - 1);
            acc += tmp[yy * w + x];
        }
        for (int y = 0; y < h; y++) {
            img[y * w + x] = (float)(acc / span);
            int yout = y - radius;
            int yin = y + radius + 1;
            acc -= tmp[clampi(yout, 0, h - 1) * w + x];
            acc += tmp[clampi(yin, 0, h - 1) * w + x];
        }
    }
}

/* Three box blurs ≈ Gaussian with sigma = blur/2 (CoreGraphics shadow). */
static void shadow_blur_approx(std::vector<float> &img, int w, int h, double blur) {
    if (blur < 0.5) {
        if (blur > 0.05) box_blur(img, w, h, 1);
        return;
    }
    double sigma = blur * 0.5;
    const int n = 3;
    double w_ideal = std::sqrt((12.0 * sigma * sigma) / n + 1.0);
    int wl = (int)std::floor(w_ideal);
    if ((wl % 2) == 0) wl--;
    if (wl < 1) wl = 1;
    int wu = wl + 2;
    double m_ideal = (12.0 * sigma * sigma - n * wl * wl - 4.0 * n * wl - 3.0 * n)
                     / (-4.0 * wl - 4.0);
    int m = (int)std::lround(m_ideal);
    if (m < 0) m = 0;
    if (m > n) m = n;
    for (int i = 0; i < n; i++) {
        int size = (i < m) ? wl : wu;
        int radius = (size - 1) / 2;
        if (radius >= 1) box_blur(img, w, h, radius);
    }
}

/* ---- Axis-aligned rectangle fast paths ------------------------------- */
/* Layer backgrounds, plain view fills and masksToBounds clips are almost
 * always axis-aligned rectangles; the generic pipeline pays a full-surface
 * float coverage buffer plus kAASamples scanline passes for them. These
 * helpers reproduce the rasterizer's coverage model exactly (vertical
 * kAASamples subsample quantization, analytic horizontal spans, the same
 * floor(cov*255) application) without any of that. */

/* Single closed 4-corner polyline forming an axis-aligned rect. */
static bool polys_as_rect(const std::vector<Polyline> &polys,
                          double *ox0, double *oy0, double *ox1, double *oy1) {
    if (polys.size() != 1) return false;
    const std::vector<Vec2> &p = polys[0].pts;
    size_t n = p.size();
    if (n == 5) {
        if (std::fabs(p[4].x - p[0].x) > 1e-9 ||
            std::fabs(p[4].y - p[0].y) > 1e-9) return false;
        n = 4;
    }
    if (n != 4) return false;
    double minx = p[0].x, maxx = p[0].x, miny = p[0].y, maxy = p[0].y;
    for (size_t i = 1; i < 4; i++) {
        minx = std::min(minx, p[i].x); maxx = std::max(maxx, p[i].x);
        miny = std::min(miny, p[i].y); maxy = std::max(maxy, p[i].y);
    }
    if (maxx - minx <= 1e-9 || maxy - miny <= 1e-9) return false;
    unsigned corners = 0;
    for (size_t i = 0; i < 4; i++) {
        bool xmin = std::fabs(p[i].x - minx) < 1e-9;
        bool xmax = std::fabs(p[i].x - maxx) < 1e-9;
        bool ymin = std::fabs(p[i].y - miny) < 1e-9;
        bool ymax = std::fabs(p[i].y - maxy) < 1e-9;
        if ((!xmin && !xmax) || (!ymin && !ymax)) return false;
        corners |= 1u << ((xmax ? 1 : 0) | (ymax ? 2 : 0));
    }
    if (corners != 0xF) return false;
    *ox0 = minx; *oy0 = miny; *ox1 = maxx; *oy1 = maxy;
    return true;
}

/* Vertical coverage of [y0,y1) for pixel row y, matching rasterize():
 * kAASamples subsample centers (AA) or the pixel-center threshold. */
static double rect_vcov(double y0, double y1, int y, bool antialias) {
    if (!antialias) {
        double yc = y + 0.5;
        return (yc >= y0 && yc < y1) ? 1.0 : 0.0;
    }
    if (y >= y0 && (y + 1) <= y1) return 1.0;
    int cnt = 0;
    for (int s = 0; s < kAASamples; s++) {
        double ys = y + (s + 0.5) / (double)kAASamples;
        if (ys >= y0 && ys < y1) cnt++;
    }
    return cnt / (double)kAASamples;
}

static bool fill_rect_fast(QZContext *ctx, const std::vector<Polyline> &polys,
                           Color color) {
    if (ctx->gs.shadow || ctx->gs.blend != kQZBlendModeNormal) return false;
    double x0, y0, x1, y1;
    if (!polys_as_rect(polys, &x0, &y0, &x1, &y1)) return false;
    ensure_clip(ctx->gs, ctx->width, ctx->height);
    const int w = ctx->width, h = ctx->height;
    int ry0 = clampi((int)std::floor(y0), 0, h);
    int ry1 = clampi((int)std::ceil(y1), 0, h);
    double cx0 = std::max(x0, 0.0), cx1 = std::min(x1, (double)w);
    if (cx1 <= cx0 || ry0 >= ry1) return true; /* fully clipped out */
    int rx0 = clampi((int)std::floor(cx0), 0, w);
    int rx1 = clampi((int)std::ceil(cx1), 0, w);
    if (rx0 >= rx1) return true;

    /* Row-invariant horizontal coverage per column (add_span model). */
    std::vector<float> hcov((size_t)(rx1 - rx0));
    for (int x = rx0; x < rx1; x++) {
        double l = std::max((double)x, cx0), r = std::min((double)(x + 1), cx1);
        hcov[x - rx0] = (float)std::max(0.0, r - l);
    }

    const bool aa = ctx->gs.antialias;
    const double galpha = ctx->gs.alpha;
    /* Constant full-coverage source (cov == 1: floor(255)/255 == 1). */
    double fullA = clampd(color.a * galpha, 0.0, 1.0);
    uint8_t fr = u8_from_unit(color.r * fullA), fg = u8_from_unit(color.g * fullA);
    uint8_t fb = u8_from_unit(color.b * fullA), fa = u8_from_unit(fullA);
    uint8_t patBytes[4] = {fr, fg, fb, fa};
    uint32_t pat32;
    memcpy(&pat32, patBytes, 4);
    const bool opaque = (fa == 255);
    const uint8_t *clip = ctx->gs.clip.data();

    for (int y = ry0; y < ry1; y++) {
        double vc = rect_vcov(y0, y1, y, aa);
        if (vc <= 0) continue;
        uint8_t *drow = ctx->pixels + (size_t)y * ctx->bpr;
        const uint8_t *crow = clip + (size_t)y * w;
        const bool fullRow = vc >= 1.0;
        for (int x = rx0; x < rx1; x++) {
            const float hx = hcov[x - rx0];
            const uint8_t cl = crow[x];
            if (cl == 0) continue;
            if (fullRow && cl == 255 && hx >= 1.0f) {
                if (opaque) {
                    /* Opaque interior: run of straight stores. */
                    int xr = x + 1;
                    while (xr < rx1 && crow[xr] == 255 && hcov[xr - rx0] >= 1.0f) xr++;
                    uint32_t *d32 = (uint32_t *)(drow + (size_t)x * 4);
                    for (int i = x; i < xr; i++) *d32++ = pat32;
                    x = xr - 1;
                } else {
                    blend_pixel(drow + (size_t)x * 4, fr, fg, fb, fa,
                                kQZBlendModeNormal);
                }
                continue;
            }
            float cov = (float)vc * hx;
            if (cl != 255) cov *= cl / 255.0f;
            if (cov <= 1.0f / 255.0f) continue;
            /* Same application as blend_coverage. */
            float c8 = std::floor(cov * 255.0f) / 255.0f;
            double a = clampd(color.a * galpha * (double)c8, 0.0, 1.0);
            blend_pixel(drow + (size_t)x * 4,
                        u8_from_unit(color.r * a), u8_from_unit(color.g * a),
                        u8_from_unit(color.b * a), u8_from_unit(a),
                        kQZBlendModeNormal);
        }
    }
    return true;
}

/* Rect clip: multiply the clip mask analytically (memset outside, exact
 * edge coverage), matching clip_with_path's rasterize + multiply. */
static bool clip_rect_fast(QZContext *ctx, const std::vector<Polyline> &polys) {
    double x0, y0, x1, y1;
    if (!polys_as_rect(polys, &x0, &y0, &x1, &y1)) return false;
    ensure_clip(ctx->gs, ctx->width, ctx->height);
    const int w = ctx->width, h = ctx->height;
    const bool aa = ctx->gs.antialias;
    uint8_t *clip = ctx->gs.clip.data();
    double cx0 = std::max(x0, 0.0), cx1 = std::min(x1, (double)w);
    int rx0 = clampi((int)std::floor(cx0), 0, w);
    int rx1 = clampi((int)std::ceil(cx1), 0, w);
    for (int y = 0; y < h; y++) {
        uint8_t *crow = clip + (size_t)y * w;
        double vc = (cx1 > cx0) ? rect_vcov(y0, y1, y, aa) : 0.0;
        if (vc <= 0) {
            memset(crow, 0, (size_t)w);
            continue;
        }
        if (rx0 > 0) memset(crow, 0, (size_t)rx0);
        if (rx1 < w) memset(crow + rx1, 0, (size_t)(w - rx1));
        for (int x = rx0; x < rx1; x++) {
            double l = std::max((double)x, cx0), r = std::min((double)(x + 1), cx1);
            float c = (float)(vc * std::max(0.0, r - l));
            if (c >= 1.0f) continue; /* multiply by 1 */
            unsigned v = (unsigned)(c * crow[x] + 0.5f);
            crow[x] = (uint8_t)(v > 255 ? 255 : v);
        }
    }
    return true;
}

static void fill_polylines(QZContext *ctx, const std::vector<Polyline> &polys,
                           bool even_odd, Color color) {
    if (polys.empty()) return;
    if (qz_pkg_try_pattern_fill(ctx, polys, even_odd, color)) return;
    if (fill_rect_fast(ctx, polys, color)) return;
    std::vector<Edge> edges;
    build_edges(polys, edges);
    std::vector<float> cov((size_t)ctx->width * (size_t)ctx->height);
    rasterize(edges, ctx->width, ctx->height, even_odd, ctx->gs.antialias, cov.data());
    ensure_clip(ctx->gs, ctx->width, ctx->height);
    if (ctx->gs.shadow) {
        QZSize d = QZSizeApplyAffineTransform(
            QZSizeMake(ctx->gs.shadow_ox, ctx->gs.shadow_oy), ctx->gs.ctm);
        int dx = (int)std::lround(d.width);
        int dy = (int)std::lround(-d.height);
        std::vector<float> sh(cov.size(), 0.f);
        int w = ctx->width, h = ctx->height;
        for (int y = 0; y < h; y++) {
            int sy = y - dy;
            if (sy < 0 || sy >= h) continue;
            for (int x = 0; x < w; x++) {
                int sx = x - dx;
                if (sx < 0 || sx >= w) continue;
                sh[y * w + x] = cov[sy * w + sx];
            }
        }
        if (ctx->gs.shadow_blur > 0.05) {
            shadow_blur_approx(sh, w, h, ctx->gs.shadow_blur);
        }
        blend_coverage(ctx->pixels, w, h, ctx->bpr, sh.data(), ctx->gs.clip.data(),
                       ctx->gs.shadow_color, ctx->gs.alpha, kQZBlendModeNormal);
    }
    blend_coverage(ctx->pixels, ctx->width, ctx->height, ctx->bpr,
                   cov.data(), ctx->gs.clip.data(), color, ctx->gs.alpha, ctx->gs.blend);
}

static void close_open_for_fill(std::vector<Polyline> &polys) {
    for (Polyline &pl : polys) {
        if (!pl.closed && pl.pts.size() >= 3) {
            if (length(pl.pts.front() - pl.pts.back()) > 1e-12)
                pl.pts.push_back(pl.pts.front());
            pl.closed = true;
        }
    }
}

static double ctm_scale(const QZAffineTransform &t) {
    double sx = hypot2(t.a, t.b);
    double sy = hypot2(t.c, t.d);
    return 0.5 * (sx + sy);
}

static void draw_fill(QZContext *ctx, bool even_odd) {
    QZAffineTransform t = user_to_mem(ctx->gs, ctx->height);
    Path tp = transform_path(ctx->path, t);
    double flat = std::max(0.08, std::min(0.25, ctx->gs.flatness * 0.25));
    std::vector<Polyline> polys;
    flatten_path(tp, flat, polys);
    close_open_for_fill(polys);
    fill_polylines(ctx, polys, even_odd, ctx->gs.fill);
}

static void draw_stroke(QZContext *ctx) {
    /* Flatten in user space, stroke, then transform outline to memory. */
    double sc = ctm_scale(ctx->gs.ctm);
    if (sc < 1e-8) return;
    double flat = std::max(0.08, ctx->gs.flatness * 0.25) / sc;
    std::vector<Polyline> flat_user;
    flatten_path(ctx->path, flat, flat_user);
    std::vector<Polyline> outlines;
    stroke_polylines(flat_user, ctx->gs.line_width, ctx->gs.line_cap, ctx->gs.line_join,
                     ctx->gs.miter_limit, ctx->gs.dash_phase, ctx->gs.dash, outlines);
    QZAffineTransform t = user_to_mem(ctx->gs, ctx->height);
    std::vector<Polyline> device;
    device.reserve(outlines.size());
    for (const Polyline &pl : outlines) {
        Polyline d;
        d.closed = pl.closed;
        d.pts.reserve(pl.pts.size());
        for (Vec2 p : pl.pts) d.pts.push_back(apply(t, p));
        device.push_back(std::move(d));
    }
    fill_polylines(ctx, device, false, ctx->gs.stroke);
}

static void clip_with_path(QZContext *ctx, bool even_odd) {
    QZAffineTransform t = user_to_mem(ctx->gs, ctx->height);
    Path tp = transform_path(ctx->path, t);
    std::vector<Polyline> polys;
    flatten_path(tp, std::max(0.08, std::min(0.25, ctx->gs.flatness * 0.25)), polys);
    close_open_for_fill(polys);
    if (clip_rect_fast(ctx, polys)) return;
    std::vector<Edge> edges;
    build_edges(polys, edges);
    std::vector<float> cov((size_t)ctx->width * (size_t)ctx->height);
    rasterize(edges, ctx->width, ctx->height, even_odd, ctx->gs.antialias, cov.data());
    ensure_clip(ctx->gs, ctx->width, ctx->height);
    for (int i = 0, n = ctx->width * ctx->height; i < n; i++) {
        float c = cov[i];
        if (c < 0) c = 0;
        if (c > 1) c = 1;
        unsigned v = (unsigned)(c * ctx->gs.clip[i] + 0.5f);
        ctx->gs.clip[i] = (uint8_t)(v > 255 ? 255 : v);
    }
}

QZContextRef QZBitmapContextCreate(void *data, size_t width, size_t height,
                                   size_t bitsPerComponent, size_t bytesPerRow,
                                   uint32_t bitmapInfo) {
    (void)bitmapInfo;
    if (bitsPerComponent != 8 || width == 0 || height == 0) return nullptr;
    auto *ctx = new QZContext();
    ctx->width = (int)width;
    ctx->height = (int)height;
    ctx->bpr = bytesPerRow ? bytesPerRow : width * 4;
    if (ctx->bpr < width * 4) ctx->bpr = width * 4;
    if (data) {
        ctx->pixels = (uint8_t *)data;
        ctx->owns = false;
    } else {
        ctx->owned.assign(ctx->bpr * height, 0);
        ctx->pixels = ctx->owned.data();
        ctx->owns = true;
    }
    ctx->gs = GState{};
    ensure_clip(ctx->gs, ctx->width, ctx->height);
    return ctx;
}

void QZContextRelease(QZContextRef ctx) { delete ctx; }

void *QZBitmapContextGetData(QZContextRef ctx) { return ctx ? ctx->pixels : nullptr; }
size_t QZBitmapContextGetWidth(QZContextRef ctx) { return ctx ? (size_t)ctx->width : 0; }
size_t QZBitmapContextGetHeight(QZContextRef ctx) { return ctx ? (size_t)ctx->height : 0; }
size_t QZBitmapContextGetBytesPerRow(QZContextRef ctx) { return ctx ? ctx->bpr : 0; }

void QZContextSaveGState(QZContextRef ctx) {
    if (!ctx) return;
    ctx->stack.push_back(ctx->gs);
}
void QZContextRestoreGState(QZContextRef ctx) {
    if (!ctx || ctx->stack.empty()) return;
    ctx->gs = std::move(ctx->stack.back());
    ctx->stack.pop_back();
}

void QZContextScaleCTM(QZContextRef ctx, QZFloat sx, QZFloat sy) {
    if (ctx) ctx->gs.ctm = QZAffineTransformScale(ctx->gs.ctm, sx, sy);
}
void QZContextTranslateCTM(QZContextRef ctx, QZFloat tx, QZFloat ty) {
    if (ctx) ctx->gs.ctm = QZAffineTransformTranslate(ctx->gs.ctm, tx, ty);
}
void QZContextRotateCTM(QZContextRef ctx, QZFloat angle) {
    if (ctx) ctx->gs.ctm = QZAffineTransformRotate(ctx->gs.ctm, angle);
}
void QZContextConcatCTM(QZContextRef ctx, QZAffineTransform t) {
    if (ctx) ctx->gs.ctm = QZAffineTransformConcat(ctx->gs.ctm, t);
}
QZAffineTransform QZContextGetCTM(QZContextRef ctx) {
    return ctx ? ctx->gs.ctm : QZAffineTransformIdentity();
}

void QZContextSetLineWidth(QZContextRef ctx, QZFloat width) {
    if (ctx) ctx->gs.line_width = std::max(0.0, (double)width);
}
void QZContextSetLineCap(QZContextRef ctx, QZLineCap cap) {
    if (ctx) ctx->gs.line_cap = cap;
}
void QZContextSetLineJoin(QZContextRef ctx, QZLineJoin join) {
    if (ctx) ctx->gs.line_join = join;
}
void QZContextSetMiterLimit(QZContextRef ctx, QZFloat limit) {
    if (ctx) ctx->gs.miter_limit = std::max(1.0, (double)limit);
}
void QZContextSetLineDash(QZContextRef ctx, QZFloat phase, const QZFloat *lengths, size_t count) {
    if (!ctx) return;
    ctx->gs.dash_phase = phase;
    ctx->gs.dash.clear();
    for (size_t i = 0; i < count; i++) ctx->gs.dash.push_back(lengths[i]);
}
void QZContextSetFlatness(QZContextRef ctx, QZFloat flatness) {
    if (ctx) ctx->gs.flatness = std::max(0.1, (double)flatness);
}
void QZContextSetAlpha(QZContextRef ctx, QZFloat alpha) {
    if (ctx) ctx->gs.alpha = clampd(alpha, 0, 1);
}
void QZContextSetBlendMode(QZContextRef ctx, QZBlendMode mode) {
    if (ctx) ctx->gs.blend = mode;
}
void QZContextSetShouldAntialias(QZContextRef ctx, bool antialias) {
    if (ctx) ctx->gs.antialias = antialias;
}
void QZContextSetInterpolationQuality(QZContextRef ctx, QZInterpolationQuality q) {
    if (ctx) ctx->gs.interp = q;
}
void QZContextSetRGBFillColor(QZContextRef ctx, QZFloat r, QZFloat g, QZFloat b, QZFloat a) {
    if (ctx) ctx->gs.fill = {clampd(r,0,1), clampd(g,0,1), clampd(b,0,1), clampd(a,0,1)};
}
void QZContextSetRGBStrokeColor(QZContextRef ctx, QZFloat r, QZFloat g, QZFloat b, QZFloat a) {
    if (ctx) ctx->gs.stroke = {clampd(r,0,1), clampd(g,0,1), clampd(b,0,1), clampd(a,0,1)};
}

void QZContextBeginPath(QZContextRef ctx) { if (ctx) ctx->path.clear(); }
void QZContextMoveToPoint(QZContextRef ctx, QZFloat x, QZFloat y) {
    if (ctx) ctx->path.move_to({x, y});
}
void QZContextAddLineToPoint(QZContextRef ctx, QZFloat x, QZFloat y) {
    if (ctx) ctx->path.line_to({x, y});
}
void QZContextAddCurveToPoint(QZContextRef ctx, QZFloat cp1x, QZFloat cp1y,
                              QZFloat cp2x, QZFloat cp2y, QZFloat x, QZFloat y) {
    if (ctx) ctx->path.cubic_to({cp1x, cp1y}, {cp2x, cp2y}, {x, y});
}
void QZContextAddQuadCurveToPoint(QZContextRef ctx, QZFloat cpx, QZFloat cpy,
                                  QZFloat x, QZFloat y) {
    if (ctx) ctx->path.quad_to({cpx, cpy}, {x, y});
}
void QZContextAddRect(QZContextRef ctx, QZRect rect) {
    if (ctx) ctx->path.add_rect(rect);
}
void QZContextAddEllipseInRect(QZContextRef ctx, QZRect rect) {
    if (ctx) ctx->path.add_ellipse(rect);
}
void QZContextAddArc(QZContextRef ctx, QZFloat x, QZFloat y, QZFloat radius,
                     QZFloat startAngle, QZFloat endAngle, int clockwise) {
    if (ctx) ctx->path.add_arc(x, y, radius, startAngle, endAngle, clockwise);
}
void QZContextAddArcToPoint(QZContextRef ctx, QZFloat x1, QZFloat y1,
                            QZFloat x2, QZFloat y2, QZFloat radius) {
    if (ctx) ctx->path.add_arc_to({x1, y1}, {x2, y2}, radius);
}
void QZContextAddPath(QZContextRef ctx, QZPathRef path) {
    if (ctx && path) ctx->path.append(path->p, nullptr);
}
void QZContextClosePath(QZContextRef ctx) { if (ctx) ctx->path.close(); }

void QZContextDrawPath(QZContextRef ctx, QZPathDrawingMode mode) {
    if (!ctx) return;
    switch (mode) {
    case kQZPathFill: draw_fill(ctx, false); break;
    case kQZPathEOFill: draw_fill(ctx, true); break;
    case kQZPathStroke: draw_stroke(ctx); break;
    case kQZPathFillStroke: draw_fill(ctx, false); draw_stroke(ctx); break;
    case kQZPathEOFillStroke: draw_fill(ctx, true); draw_stroke(ctx); break;
    }
    ctx->path.clear();
}
void QZContextFillPath(QZContextRef ctx) { QZContextDrawPath(ctx, kQZPathFill); }
void QZContextEOFillPath(QZContextRef ctx) { QZContextDrawPath(ctx, kQZPathEOFill); }
void QZContextStrokePath(QZContextRef ctx) { QZContextDrawPath(ctx, kQZPathStroke); }

void QZContextFillRect(QZContextRef ctx, QZRect rect) {
    if (!ctx) return;
    Path saved = ctx->path;
    ctx->path.clear();
    ctx->path.add_rect(rect);
    draw_fill(ctx, false);
    ctx->path = std::move(saved);
}
void QZContextStrokeRect(QZContextRef ctx, QZRect rect) {
    if (!ctx) return;
    Path saved = ctx->path;
    ctx->path.clear();
    ctx->path.add_rect(rect);
    draw_stroke(ctx);
    ctx->path = std::move(saved);
}
void QZContextStrokeRectWithWidth(QZContextRef ctx, QZRect rect, QZFloat width) {
    if (!ctx) return;
    double old = ctx->gs.line_width;
    ctx->gs.line_width = width;
    QZContextStrokeRect(ctx, rect);
    ctx->gs.line_width = old;
}
void QZContextClearRect(QZContextRef ctx, QZRect rect) {
    if (!ctx) return;
    QZBlendMode old = ctx->gs.blend;
    Color oldf = ctx->gs.fill;
    ctx->gs.blend = kQZBlendModeCopy;
    ctx->gs.fill = {0, 0, 0, 0};
    QZContextFillRect(ctx, rect);
    ctx->gs.blend = old;
    ctx->gs.fill = oldf;
}
void QZContextFillEllipseInRect(QZContextRef ctx, QZRect rect) {
    if (!ctx) return;
    Path saved = ctx->path;
    ctx->path.clear();
    ctx->path.add_ellipse(rect);
    draw_fill(ctx, false);
    ctx->path = std::move(saved);
}
void QZContextStrokeEllipseInRect(QZContextRef ctx, QZRect rect) {
    if (!ctx) return;
    Path saved = ctx->path;
    ctx->path.clear();
    ctx->path.add_ellipse(rect);
    draw_stroke(ctx);
    ctx->path = std::move(saved);
}

void QZContextClip(QZContextRef ctx) {
    if (!ctx) return;
    clip_with_path(ctx, false);
    ctx->path.clear();
}
void QZContextEOClip(QZContextRef ctx) {
    if (!ctx) return;
    clip_with_path(ctx, true);
    ctx->path.clear();
}
void QZContextClipToRect(QZContextRef ctx, QZRect rect) {
    if (!ctx) return;
    Path saved = ctx->path;
    ctx->path.clear();
    ctx->path.add_rect(rect);
    clip_with_path(ctx, false);
    ctx->path = std::move(saved);
}

void QZContextAddRoundedRect(QZContextRef ctx, QZRect rect, QZFloat cornerRadius) {
    if (ctx) ctx->path.add_rounded_rect(rect, cornerRadius);
}

void QZContextBeginTransparencyLayer(QZContextRef ctx) {
    if (!ctx) return;
    QZTransLayer tl;
    tl.parent = ctx->pixels;
    tl.group_alpha = ctx->gs.alpha;
    tl.buf.assign(ctx->bpr * (size_t)ctx->height, 0);
    ctx->trans.push_back(std::move(tl));
    ctx->pixels = ctx->trans.back().buf.data();
    ctx->gs.alpha = 1; /* drawing into the layer is at full group intensity */
}

void QZContextEndTransparencyLayer(QZContextRef ctx) {
    if (!ctx || ctx->trans.empty()) return;
    QZTransLayer tl = std::move(ctx->trans.back());
    ctx->trans.pop_back();
    uint8_t *dst = tl.parent;
    const uint8_t *src = tl.buf.data();
    unsigned ga8 = (unsigned)(tl.group_alpha * 255.0 + 0.5);
    if (ga8 > 255) ga8 = 255;
    for (int y = 0; y < ctx->height; y++) {
        for (int x = 0; x < ctx->width; x++) {
            const uint8_t *s = src + (size_t)y * ctx->bpr + (size_t)x * 4;
            if (s[3] == 0 || ga8 == 0) continue;
            uint8_t sr = mul255(s[0], ga8);
            uint8_t sg = mul255(s[1], ga8);
            uint8_t sb = mul255(s[2], ga8);
            uint8_t sa = mul255(s[3], ga8);
            if (sa == 0) continue;
            blend_pixel(dst + (size_t)y * ctx->bpr + (size_t)x * 4, sr, sg, sb, sa,
                        kQZBlendModeNormal);
        }
    }
    ctx->pixels = dst;
    ctx->gs.alpha = tl.group_alpha;
}

void QZContextSetShadow(QZContextRef ctx, QZSize offset, QZFloat blur) {
    QZContextSetShadowWithColor(ctx, offset, blur, 0, 0, 0, 1.0 / 3.0);
}
void QZContextSetShadowWithColor(QZContextRef ctx, QZSize offset, QZFloat blur,
                                 QZFloat r, QZFloat g, QZFloat b, QZFloat a) {
    if (!ctx) return;
    ctx->gs.shadow = true;
    ctx->gs.shadow_ox = offset.width;
    ctx->gs.shadow_oy = offset.height;
    ctx->gs.shadow_blur = std::max(0.0, (double)blur);
    ctx->gs.shadow_color = {clampd(r,0,1), clampd(g,0,1), clampd(b,0,1), clampd(a,0,1)};
}

/* Apple's default/low image interpolator is sharper than linear bilinear.
 * Dest samples at pixel centers (x+0.5); texels are centered (u-0.5).
 * Ease-in-out power matches CG upscales (probe: 6x ramp, 2x 4-tap). */
static double ease_inout_pow(double f) {
    f = clampd(f, 0.0, 1.0);
    constexpr double p = 2.7;
    if (f < 0.5) return 0.5 * std::pow(2.0 * f, p);
    return 1.0 - 0.5 * std::pow(2.0 * (1.0 - f), p);
}

static void sample_image(const QZImage *img, double u, double v,
                         QZInterpolationQuality q, uint8_t *out) {
    int w = img->width, h = img->height;
    if (w <= 0 || h <= 0) { out[0]=out[1]=out[2]=out[3]=0; return; }
    /* u,v in image pixel space */
    if (q == kQZInterpolationNone) {
        int x = clampi((int)std::floor(u), 0, w - 1);
        int y = clampi((int)std::floor(v), 0, h - 1);
        const uint8_t *p = img->rgba.data() + ((size_t)y * w + x) * 4;
        memcpy(out, p, 4);
        return;
    }
    u -= 0.5; v -= 0.5;
    int x0 = (int)std::floor(u), y0 = (int)std::floor(v);
    double fx = ease_inout_pow(u - x0), fy = ease_inout_pow(v - y0);
    auto px = [&](int x, int y) -> const uint8_t * {
        x = clampi(x, 0, w - 1);
        y = clampi(y, 0, h - 1);
        return img->rgba.data() + ((size_t)y * w + x) * 4;
    };
    const uint8_t *p00 = px(x0, y0), *p10 = px(x0 + 1, y0);
    const uint8_t *p01 = px(x0, y0 + 1), *p11 = px(x0 + 1, y0 + 1);
    for (int i = 0; i < 4; i++) {
        double a = p00[i] + (p10[i] - p00[i]) * fx;
        double b = p01[i] + (p11[i] - p01[i]) * fx;
        out[i] = clamp8((int)(a + (b - a) * fy + 0.5));
    }
}

/* Fast path for the overwhelmingly common compositing case: the image maps
 * onto the destination at unit scale with no rotation/skew (layer-contents
 * blits, cached-composite blits). The generic path pays a per-pixel affine
 * apply + two pow() interpolation-weight evaluations; at unit scale the
 * interpolation weights and the in-image bounds are ROW CONSTANTS, so the
 * inner loop reduces to a 1-tap (integral offset) or 4-tap (fractional
 * offset) premultiplied source-over blend. Sampling math matches
 * sample_image exactly (same ease weights, same rounding), so output is
 * bit-identical to the generic loop for every pixel it handles.
 * Returns false (nothing drawn) when the mapping/state disqualifies. */
static bool draw_image_unit_scale(QZContext *ctx, const QZImage *image,
                                  QZAffineTransform mem_from_img,
                                  int x0, int y0, int x1, int y1) {
    if (ctx->gs.blend != kQZBlendModeNormal) return false;
    if (ctx->gs.interp == kQZInterpolationNone) return false;
    const double eps = 1.0 / 4096.0;
    /* Unit scale, no rotation/skew. d may be +1 (direct) or -1 (row-
     * mirrored — the standard case for layer contents: the top-down flip
     * CTM and DrawImage's bottom-up image mapping compose to a mirror). */
    if (std::fabs(mem_from_img.a - 1) > eps ||
        std::fabs(mem_from_img.b) > eps || std::fabs(mem_from_img.c) > eps)
        return false;
    bool yMirror;
    if (std::fabs(mem_from_img.d - 1) <= eps) yMirror = false;
    else if (std::fabs(mem_from_img.d + 1) <= eps) yMirror = true;
    else return false;
    const int w = image->width, h = image->height;
    if (w <= 0 || h <= 0) return true; /* nothing to draw */
    const double ga = ctx->gs.alpha;
    const double tx = mem_from_img.tx, ty = mem_from_img.ty;

    /* Generic loop inverse-maps dest pixel centers into image space and
     * rejects samples outside [0,w)x[0,h); the bilinear sampler subtracts
     * 0.5. At unit scale the sampler's floor/frac decompose into a per-
     * pixel integer offset plus a CONSTANT fraction:
     *   x: u = x + gx,             gx = -tx
     *   y: v = y + gy              (d=+1, gy = -ty)
     *      v = K - y               (d=-1, K = ty - 1)          */
    const double gx = -tx;
    const double fGx = std::floor(gx);
    const int Gx = (int)fGx;
    double hx = gx - fGx;
    /* Snap sub-1/4096 fractions to the integral fast case (positions come
     * from device-snapped layer geometry; tolerate float noise). */
    if (hx < eps) hx = 0; else if (hx > 1 - eps) { hx = 0; }
    const int Gx2 = (gx - fGx > 1 - eps) ? Gx + 1 : Gx;

    const double gy = yMirror ? (ty - 1) : -ty;  /* v = gy ± y */
    const double fGy = std::floor(gy);
    const int Gy = (int)fGy;
    double hy = gy - fGy;
    if (hy < eps) hy = 0; else if (hy > 1 - eps) { hy = 0; }
    const int Gy2 = (gy - fGy > 1 - eps) ? Gy + 1 : Gy;

    const double wx = hx > 0 ? ease_inout_pow(hx) : 0;
    const double wy = hy > 0 ? ease_inout_pow(hy) : 0;

    /* Dest columns whose sample point lies inside the image:
     * 0 <= x + 0.5 + gx < w  (same test as the generic loop). */
    int xa = x0, xb = x1;
    while (xa < xb && (xa + 0.5 + gx < 0 || xa + 0.5 + gx >= w)) xa++;
    while (xb > xa && ((xb - 1) + 0.5 + gx < 0 || (xb - 1) + 0.5 + gx >= w)) xb--;
    const uint8_t *src = image->rgba.data();
    for (int y = y0; y < y1; y++) {
        const double iy = yMirror ? (ty - (y + 0.5)) : (y + 0.5 - ty);
        if (iy < 0 || iy >= h) continue;
        /* Sampler rows: floor/frac of v with the constant fraction hy. */
        const int vRow = yMirror ? (Gy2 - y) : (y + Gy2);
        const int ry0 = clampi(vRow, 0, h - 1);
        const int ry1 = clampi(vRow + (wy > 0 ? 1 : 0), 0, h - 1);
        const uint8_t *r0 = src + (size_t)ry0 * w * 4;
        const uint8_t *r1 = src + (size_t)ry1 * w * 4;
        uint8_t *drow = ctx->pixels + (size_t)y * ctx->bpr;
        const uint8_t *crow = ctx->gs.clip.data() + (size_t)y * ctx->width;
        if (wx == 0 && wy == 0 && ga >= 1.0) {
            /* 1-tap: straight copy/blend of source texels. */
            for (int x = xa; x < xb; x++) {
                const uint8_t c = crow[x];
                if (c == 0) continue;
                const int ix = clampi(x + Gx2, 0, w - 1);
                const uint8_t *s = r0 + (size_t)ix * 4;
                if (s[3] == 0) continue;
                uint8_t *p = drow + (size_t)x * 4;
                if (c == 255) {
                    if (s[3] == 255) { p[0]=s[0]; p[1]=s[1]; p[2]=s[2]; p[3]=255; }
                    else blend_pixel(p, s[0], s[1], s[2], s[3], kQZBlendModeNormal);
                } else {
                    const float cov = c / 255.0f;
                    blend_pixel(p, (uint8_t)(s[0] * cov), (uint8_t)(s[1] * cov),
                                (uint8_t)(s[2] * cov), (uint8_t)(s[3] * cov),
                                kQZBlendModeNormal);
                }
            }
            continue;
        }
        for (int x = xa; x < xb; x++) {
            const uint8_t c = crow[x];
            if (c == 0) continue;
            /* Same 4 taps and arithmetic as sample_image (clamped edges). */
            const int ix0 = clampi(x + Gx2, 0, w - 1);
            const int ix1 = clampi(x + Gx2 + (wx > 0 ? 1 : 0), 0, w - 1);
            const uint8_t *p00 = r0 + (size_t)ix0 * 4;
            const uint8_t *p10 = r0 + (size_t)ix1 * 4;
            const uint8_t *p01 = r1 + (size_t)ix0 * 4;
            const uint8_t *p11 = r1 + (size_t)ix1 * 4;
            uint8_t s[4];
            for (int i = 0; i < 4; i++) {
                const double a = p00[i] + (p10[i] - p00[i]) * wx;
                const double b = p01[i] + (p11[i] - p01[i]) * wx;
                s[i] = clamp8((int)(a + (b - a) * wy + 0.5));
            }
            if (s[3] == 0) continue;
            const float cov = c / 255.0f;
            blend_pixel(drow + (size_t)x * 4,
                        (uint8_t)(s[0] * cov * ga), (uint8_t)(s[1] * cov * ga),
                        (uint8_t)(s[2] * cov * ga), (uint8_t)(s[3] * cov * ga),
                        kQZBlendModeNormal);
        }
    }
    return true;
}

void QZContextDrawImage(QZContextRef ctx, QZRect rect, QZImageRef image) {
    if (!ctx || !image) return;
    /* Inverse-map each pixel center from memory space to image space. */
    QZAffineTransform to_mem = user_to_mem(ctx->gs, ctx->height);
    /* user rect (origin, size) maps to image (0,0,w,h). Image y is top-down.
       Quartz DrawImage: dest rect in user space, image's bottom corresponds to
       rect.origin.y and top to origin.y+height (y-up). */
    QZAffineTransform user_from_img = QZAffineTransformMake(
        rect.size.width / image->width, 0, 0,
        rect.size.height / image->height,
        rect.origin.x, rect.origin.y);
    /* image y is top-down: img_y=0 is top = user y = origin.y+height. Flip in image. */
    QZAffineTransform img_flip = QZAffineTransformMake(1, 0, 0, -1, 0, (QZFloat)image->height);
    QZAffineTransform user_from_img_px = QZAffineTransformConcat(user_from_img, img_flip);
    QZAffineTransform mem_from_img = QZAffineTransformConcat(to_mem, user_from_img_px);
    QZAffineTransform img_from_mem = QZAffineTransformInvert(mem_from_img);

    ensure_clip(ctx->gs, ctx->width, ctx->height);
    QZRect d = QZRectApplyAffineTransform(rect, to_mem);
    int x0 = clampi((int)std::floor(d.origin.x) - 1, 0, ctx->width);
    int y0 = clampi((int)std::floor(d.origin.y) - 1, 0, ctx->height);
    int x1 = clampi((int)std::ceil(d.origin.x + d.size.width) + 1, 0, ctx->width);
    int y1 = clampi((int)std::ceil(d.origin.y + d.size.height) + 1, 0, ctx->height);

    if (draw_image_unit_scale(ctx, image, mem_from_img, x0, y0, x1, y1))
        return;

    for (int y = y0; y < y1; y++) {
        for (int x = x0; x < x1; x++) {
            Vec2 img = apply(img_from_mem, Vec2{x + 0.5, y + 0.5});
            if (img.x < 0 || img.y < 0 || img.x >= image->width || img.y >= image->height)
                continue;
            uint8_t s[4];
            sample_image(image, img.x, img.y, ctx->gs.interp, s);
            float cov = ctx->gs.clip[y * ctx->width + x] / 255.0f;
            if (cov < 1.0f / 255.0f) continue;
            uint8_t sr = (uint8_t)(s[0] * cov * ctx->gs.alpha);
            uint8_t sg = (uint8_t)(s[1] * cov * ctx->gs.alpha);
            uint8_t sb = (uint8_t)(s[2] * cov * ctx->gs.alpha);
            uint8_t sa = (uint8_t)(s[3] * cov * ctx->gs.alpha);
            uint8_t *p = ctx->pixels + (size_t)y * ctx->bpr + (size_t)x * 4;
            blend_pixel(p, sr, sg, sb, sa, ctx->gs.blend);
        }
    }
}

static void color_to_src(Color c, double alpha, double cover,
                         uint8_t *sr, uint8_t *sg, uint8_t *sb, uint8_t *sa) {
    double a = clampd(c.a * alpha * cover, 0, 1);
    *sr = u8_from_unit(c.r * a);
    *sg = u8_from_unit(c.g * a);
    *sb = u8_from_unit(c.b * a);
    *sa = u8_from_unit(a);
}

/* Piecewise-linear sample without Gradient::sample's +1e-15 span pad,
 * which nudges exact u=0.5 below 127.5 and rounds 128→127 vs Apple. */
static Color grad_lerp(const Gradient &g, double t) {
    if (g.colors.empty()) return {};
    if (t <= g.stops.front()) return g.colors.front();
    if (t >= g.stops.back()) return g.colors.back();
    for (size_t i = 1; i < g.stops.size(); i++) {
        if (t <= g.stops[i]) {
            double span = g.stops[i] - g.stops[i - 1];
            double u = span > 0 ? (t - g.stops[i - 1]) / span : 0;
            Color a = g.colors[i - 1], b = g.colors[i];
            return {a.r + (b.r - a.r) * u, a.g + (b.g - a.g) * u,
                    a.b + (b.b - a.b) * u, a.a + (b.a - a.a) * u};
        }
    }
    return g.colors.back();
}

void QZContextDrawLinearGradient(QZContextRef ctx, QZGradientRef gradient,
                                 QZPoint startPoint, QZPoint endPoint, uint32_t options) {
    if (!ctx || !gradient) return;
    Vec2 s{startPoint}, e{endPoint};
    Vec2 d = e - s;
    double L2 = dot(d, d);
    if (L2 < 1e-20) return;
    ensure_clip(ctx->gs, ctx->width, ctx->height);
    QZAffineTransform t = user_to_mem(ctx->gs, ctx->height);
    QZAffineTransform inv = QZAffineTransformInvert(t);
    bool before = options & kQZGradientDrawsBeforeStartLocation;
    bool after  = options & kQZGradientDrawsAfterEndLocation;
    for (int y = 0; y < ctx->height; y++) {
        for (int x = 0; x < ctx->width; x++) {
            float clip = ctx->gs.clip[y * ctx->width + x] / 255.0f;
            if (clip < 1.0f / 255.0f) continue;
            Vec2 user = apply(inv, Vec2{x + 0.5, y + 0.5});
            double tt = dot(user - s, d) / L2;
            if (tt < 0 && !before) continue;
            if (tt > 1 && !after) continue;
            Color c = grad_lerp(gradient->g, tt);
            uint8_t sr, sg, sb, sa;
            color_to_src(c, ctx->gs.alpha, clip, &sr, &sg, &sb, &sa);
            uint8_t *p = ctx->pixels + (size_t)y * ctx->bpr + (size_t)x * 4;
            blend_pixel(p, sr, sg, sb, sa, ctx->gs.blend);
        }
    }
}

void QZContextDrawRadialGradient(QZContextRef ctx, QZGradientRef gradient,
                                 QZPoint startCenter, QZFloat startRadius,
                                 QZPoint endCenter, QZFloat endRadius, uint32_t options) {
    if (!ctx || !gradient) return;
    ensure_clip(ctx->gs, ctx->width, ctx->height);
    QZAffineTransform t = user_to_mem(ctx->gs, ctx->height);
    QZAffineTransform inv = QZAffineTransformInvert(t);
    bool before = options & kQZGradientDrawsBeforeStartLocation;
    bool after  = options & kQZGradientDrawsAfterEndLocation;
    Vec2 c0{startCenter}, c1{endCenter};
    double r0 = startRadius, r1 = endRadius;
    for (int y = 0; y < ctx->height; y++) {
        for (int x = 0; x < ctx->width; x++) {
            float clip = ctx->gs.clip[y * ctx->width + x] / 255.0f;
            if (clip < 1.0f / 255.0f) continue;
            Vec2 p = apply(inv, Vec2{x + 0.5, y + 0.5});
            /* Solve |p - (c0 + t (c1-c0))| = r0 + t (r1-r0) */
            Vec2 dc = c1 - c0;
            double dr = r1 - r0;
            Vec2 q = p - c0;
            double a = dot(dc, dc) - dr * dr;
            double b = -2.0 * (dot(q, dc) + r0 * dr);
            double c = dot(q, q) - r0 * r0;
            double tval = 0;
            bool ok = false;
            if (std::fabs(a) < 1e-12) {
                if (std::fabs(b) > 1e-12) {
                    tval = -c / b;
                    ok = true;
                }
            } else {
                double disc = b * b - 4 * a * c;
                if (disc >= 0) {
                    double sdisc = std::sqrt(disc);
                    double t1 = (-b + sdisc) / (2 * a);
                    double t2 = (-b - sdisc) / (2 * a);
                    /* Prefer the larger t (end circle). */
                    tval = std::max(t1, t2);
                    ok = true;
                }
            }
            if (!ok) continue;
            if (tval < 0 && !before) continue;
            if (tval > 1 && !after) continue;
            Color col = grad_lerp(gradient->g, tval);
            uint8_t sr, sg, sb, sa;
            color_to_src(col, ctx->gs.alpha, clip, &sr, &sg, &sb, &sa);
            uint8_t *pix = ctx->pixels + (size_t)y * ctx->bpr + (size_t)x * 4;
            blend_pixel(pix, sr, sg, sb, sa, ctx->gs.blend);
        }
    }
}


