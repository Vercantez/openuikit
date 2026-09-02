#include "qz_internal.hpp"
/* OWNED BY package gradient-ext. */

using namespace qz;

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

void QZContextDrawConicGradient(QZContextRef ctx, QZGradientRef gradient,
                                QZPoint center, QZFloat angle, uint32_t options) {
    if (!ctx || !gradient) return;
    ensure_clip(ctx->gs, ctx->width, ctx->height);
    QZAffineTransform t = user_to_mem(ctx->gs, ctx->height);
    QZAffineTransform inv = QZAffineTransformInvert(t);
    bool before = options & kQZGradientDrawsBeforeStartLocation;
    bool after  = options & kQZGradientDrawsAfterEndLocation;
    Vec2 c{center};
    for (int y = 0; y < ctx->height; y++) {
        for (int x = 0; x < ctx->width; x++) {
            float clip = ctx->gs.clip[y * ctx->width + x] / 255.0f;
            if (clip < 1.0f / 255.0f) continue;
            Vec2 user = apply(inv, Vec2{x + 0.5, y + 0.5});
            double a = std::atan2(user.y - c.y, user.x - c.x) - (double)angle;
            double tt = a / kTwoPi;
            tt -= std::floor(tt); /* wrap to [0,1) */
            if (tt < 0 && !before) continue;
            if (tt > 1 && !after) continue;
            Color col = gradient->g.sample(tt);
            uint8_t sr, sg, sb, sa;
            color_to_src(col, ctx->gs.alpha, clip, &sr, &sg, &sb, &sa);
            uint8_t *p = ctx->pixels + (size_t)y * ctx->bpr + (size_t)x * 4;
            blend_pixel(p, sr, sg, sb, sa, ctx->gs.blend);
        }
    }
}

void QZGradientLayerSetConic(QZLayerRef layer, bool on) {
    if (layer) layer->grad_conic = on;
}
