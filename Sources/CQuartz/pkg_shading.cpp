#include "qz_internal.hpp"
/* OWNED BY package shading. */

using namespace qz;

struct QZFunction {
    int ref = 1;
    void *info = nullptr;
    size_t din = 1, dout = 4;
    std::vector<QZFloat> domain{0, 1};
    std::vector<QZFloat> range{0, 1, 0, 1, 0, 1, 0, 1};
    bool has_domain = false;
    bool has_range = false;
    QZFunctionEvaluate evaluate = nullptr;
};

struct QZShading {
    int kind = 0; /* 0 axial, 1 radial */
    QZPoint a{0, 0}, b{0, 0};
    QZFloat r0 = 0, r1 = 0;
    QZFunctionRef fn = nullptr;
    bool extend0 = false, extend1 = false;
};

static QZAffineTransform yflip(int height) {
    return QZAffineTransformMake(1, 0, 0, -1, 0, (QZFloat)height);
}

static QZAffineTransform user_to_mem(const GState &gs, int height) {
    return QZAffineTransformConcat(yflip(height), gs.ctm);
}

static void ensure_clip(GState &gs, int w, int h) {
    size_t n = (size_t)w * (size_t)h;
    if (gs.clip.size() != n) gs.clip.assign(n, 255);
}

static void color_to_src(Color c, double alpha, double cover,
                         uint8_t *sr, uint8_t *sg, uint8_t *sb, uint8_t *sa) {
    double a = clampd(c.a * alpha * cover, 0, 1);
    *sr = u8_from_unit(c.r * a);
    *sg = u8_from_unit(c.g * a);
    *sb = u8_from_unit(c.b * a);
    *sa = u8_from_unit(a);
}

static void function_eval(const QZFunction *f, QZFloat t, Color *out) {
    QZFloat in = t;
    if (f->has_domain && f->domain.size() >= 2)
        in = (QZFloat)clampd(in, f->domain[0], f->domain[1]);

    QZFloat o[8] = {0, 0, 0, 1, 0, 0, 0, 0};
    if (f->evaluate)
        f->evaluate(f->info, &in, o);

    size_t n = f->dout < 8 ? f->dout : 8;
    if (f->has_range) {
        for (size_t i = 0; i < n; i++) {
            if (f->range.size() >= (i + 1) * 2)
                o[i] = (QZFloat)clampd(o[i], f->range[2 * i], f->range[2 * i + 1]);
        }
    }
    out->r = n > 0 ? o[0] : 0;
    out->g = n > 1 ? o[1] : 0;
    out->b = n > 2 ? o[2] : 0;
    out->a = n > 3 ? o[3] : 1;
}

static bool axial_t(Vec2 p, Vec2 s, Vec2 e, bool ext0, bool ext1, double *t_out) {
    Vec2 d = e - s;
    double L2 = dot(d, d);
    if (L2 < 1e-20) return false;
    double t = dot(p - s, d) / L2;
    if (t < 0 && !ext0) return false;
    if (t > 1 && !ext1) return false;
    *t_out = t;
    return true;
}

/* Solve |p - (c0 + t (c1-c0))| = r0 + t (r1-r0) with r(t) >= 0.
 * Prefer the largest valid t (PDF Type 3 / Apple convention). */
static bool radial_t(Vec2 p, Vec2 c0, double r0, Vec2 c1, double r1,
                     bool ext0, bool ext1, double *t_out) {
    Vec2 dc = c1 - c0;
    double dr = r1 - r0;
    Vec2 q = p - c0;
    double A = dot(dc, dc) - dr * dr;
    double B = -2.0 * (dot(q, dc) + r0 * dr);
    double C = dot(q, q) - r0 * r0;

    double roots[2];
    int n = 0;
    if (std::fabs(A) < 1e-12) {
        if (std::fabs(B) > 1e-12)
            roots[n++] = -C / B;
    } else {
        double disc = B * B - 4.0 * A * C;
        if (disc >= 0) {
            double sdisc = std::sqrt(disc);
            roots[n++] = (-B + sdisc) / (2.0 * A);
            roots[n++] = (-B - sdisc) / (2.0 * A);
        }
    }
    if (n == 0) return false;

    bool have = false;
    double best = 0;
    for (int i = 0; i < n; i++) {
        double t = roots[i];
        double rt = r0 + t * dr;
        if (rt < -1e-9) continue;
        if (!have || t > best) {
            best = t;
            have = true;
        }
    }
    if (!have) return false;
    if (best < 0 && !ext0) return false;
    if (best > 1 && !ext1) return false;
    *t_out = best;
    return true;
}

QZFunctionRef QZFunctionCreate(void *info,
                               size_t domainDimension, const QZFloat *domain,
                               size_t rangeDimension, const QZFloat *range,
                               QZFunctionEvaluate evaluate) {
    auto *f = new QZFunction();
    f->info = info;
    f->din = domainDimension;
    f->dout = rangeDimension;
    if (domain && domainDimension > 0) {
        f->domain.assign(domain, domain + domainDimension * 2);
        f->has_domain = true;
    }
    if (range && rangeDimension > 0) {
        f->range.assign(range, range + rangeDimension * 2);
        f->has_range = true;
    }
    f->evaluate = evaluate;
    return f;
}

void QZFunctionRelease(QZFunctionRef fn) {
    if (!fn) return;
    if (--fn->ref == 0) delete fn;
}

static void function_retain(QZFunctionRef fn) {
    if (fn) fn->ref++;
}

QZShadingRef QZShadingCreateAxial(QZPoint start, QZPoint end, QZFunctionRef function,
                                  bool extendStart, bool extendEnd) {
    auto *s = new QZShading();
    s->kind = 0;
    s->a = start;
    s->b = end;
    s->fn = function;
    function_retain(function);
    s->extend0 = extendStart;
    s->extend1 = extendEnd;
    return s;
}

QZShadingRef QZShadingCreateRadial(QZPoint startCenter, QZFloat startRadius,
                                   QZPoint endCenter, QZFloat endRadius,
                                   QZFunctionRef function,
                                   bool extendStart, bool extendEnd) {
    auto *s = new QZShading();
    s->kind = 1;
    s->a = startCenter;
    s->b = endCenter;
    s->r0 = startRadius;
    s->r1 = endRadius;
    s->fn = function;
    function_retain(function);
    s->extend0 = extendStart;
    s->extend1 = extendEnd;
    return s;
}

void QZShadingRelease(QZShadingRef shading) {
    if (!shading) return;
    QZFunctionRelease(shading->fn);
    delete shading;
}

void QZContextDrawShading(QZContextRef ctx, QZShadingRef shading) {
    if (!ctx || !shading || !shading->fn) return;
    ensure_clip(ctx->gs, ctx->width, ctx->height);
    QZAffineTransform t = user_to_mem(ctx->gs, ctx->height);
    QZAffineTransform inv = QZAffineTransformInvert(t);
    Vec2 c0{shading->a}, c1{shading->b};
    double r0 = shading->r0, r1 = shading->r1;
    bool ext0 = shading->extend0, ext1 = shading->extend1;
    int kind = shading->kind;
    QZFunction *fn = shading->fn;

    for (int y = 0; y < ctx->height; y++) {
        for (int x = 0; x < ctx->width; x++) {
            float clip = ctx->gs.clip[(size_t)y * (size_t)ctx->width + (size_t)x] / 255.0f;
            if (clip < 1.0f / 255.0f) continue;
            Vec2 user = apply(inv, Vec2{x + 0.5, y + 0.5});
            double tt = 0;
            bool ok = false;
            if (kind == 0)
                ok = axial_t(user, c0, c1, ext0, ext1, &tt);
            else
                ok = radial_t(user, c0, r0, c1, r1, ext0, ext1, &tt);
            if (!ok) continue;
            Color col;
            function_eval(fn, (QZFloat)tt, &col);
            uint8_t sr, sg, sb, sa;
            color_to_src(col, ctx->gs.alpha, clip, &sr, &sg, &sb, &sa);
            uint8_t *p = ctx->pixels + (size_t)y * ctx->bpr + (size_t)x * 4;
            blend_pixel(p, sr, sg, sb, sa, ctx->gs.blend);
        }
    }
}
