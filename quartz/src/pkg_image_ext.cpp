#include "qz_internal.hpp"

/* OWNED BY package image-ext. */

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

/* Same sampling as QZContextDrawImage (nearest vs bilinear). */
static void sample_image(const QZImage *img, double u, double v,
                         QZInterpolationQuality q, uint8_t *out) {
    int w = img->width, h = img->height;
    if (w <= 0 || h <= 0) {
        out[0] = out[1] = out[2] = out[3] = 0;
        return;
    }
    if (q == kQZInterpolationNone) {
        int x = clampi((int)std::floor(u), 0, w - 1);
        int y = clampi((int)std::floor(v), 0, h - 1);
        const uint8_t *p = img->rgba.data() + ((size_t)y * w + x) * 4;
        memcpy(out, p, 4);
        return;
    }
    u -= 0.5;
    v -= 0.5;
    int x0 = (int)std::floor(u), y0 = (int)std::floor(v);
    double fx = u - x0, fy = v - y0;
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

static double wrap_period(double x, double period) {
    if (!(period > 0)) return 0;
    double m = std::fmod(x, period);
    if (m < 0) m += period;
    if (m >= period) m = 0;
    return m;
}

/* Image-space map of dest rect, matching QZContextDrawImage (y-up dest, top-down image). */
static QZAffineTransform img_from_mem(QZContextRef ctx, QZRect rect, int iw, int ih) {
    QZAffineTransform to_mem = user_to_mem(ctx->gs, ctx->height);
    QZAffineTransform user_from_img = QZAffineTransformMake(
        rect.size.width / (QZFloat)iw, 0, 0,
        rect.size.height / (QZFloat)ih,
        rect.origin.x, rect.origin.y);
    QZAffineTransform img_flip = QZAffineTransformMake(1, 0, 0, -1, 0, (QZFloat)ih);
    QZAffineTransform user_from_img_px = QZAffineTransformConcat(user_from_img, img_flip);
    QZAffineTransform mem_from_img = QZAffineTransformConcat(to_mem, user_from_img_px);
    return QZAffineTransformInvert(mem_from_img);
}

void QZContextDrawTiledImage(QZContextRef ctx, QZRect rect, QZImageRef image) {
    if (!ctx || !image || image->width <= 0 || image->height <= 0) return;
    if (std::fabs(rect.size.width) < 1e-12 || std::fabs(rect.size.height) < 1e-12) return;

    QZAffineTransform to_img = img_from_mem(ctx, rect, image->width, image->height);
    ensure_clip(ctx->gs, ctx->width, ctx->height);
    double iw = image->width, ih = image->height;

    for (int y = 0; y < ctx->height; y++) {
        for (int x = 0; x < ctx->width; x++) {
            float cov = ctx->gs.clip[(size_t)y * ctx->width + x] / 255.0f;
            if (cov < 1.0f / 255.0f) continue;
            Vec2 imgp = apply(to_img, Vec2{x + 0.5, y + 0.5});
            double u = wrap_period(imgp.x, iw);
            double v = wrap_period(imgp.y, ih);
            uint8_t s[4];
            sample_image(image, u, v, ctx->gs.interp, s);
            uint8_t sr = (uint8_t)(s[0] * cov * ctx->gs.alpha);
            uint8_t sg = (uint8_t)(s[1] * cov * ctx->gs.alpha);
            uint8_t sb = (uint8_t)(s[2] * cov * ctx->gs.alpha);
            uint8_t sa = (uint8_t)(s[3] * cov * ctx->gs.alpha);
            uint8_t *p = ctx->pixels + (size_t)y * ctx->bpr + (size_t)x * 4;
            blend_pixel(p, sr, sg, sb, sa, ctx->gs.blend);
        }
    }
}

void QZContextClipToMask(QZContextRef ctx, QZRect rect, QZImageRef mask) {
    if (!ctx || !mask || mask->width <= 0 || mask->height <= 0) return;
    if (std::fabs(rect.size.width) < 1e-12 || std::fabs(rect.size.height) < 1e-12) {
        ensure_clip(ctx->gs, ctx->width, ctx->height);
        std::fill(ctx->gs.clip.begin(), ctx->gs.clip.end(), 0);
        return;
    }

    QZAffineTransform to_img = img_from_mem(ctx, rect, mask->width, mask->height);
    ensure_clip(ctx->gs, ctx->width, ctx->height);
    int iw = mask->width, ih = mask->height;

    for (int y = 0; y < ctx->height; y++) {
        for (int x = 0; x < ctx->width; x++) {
            size_t i = (size_t)y * ctx->width + x;
            if (ctx->gs.clip[i] == 0) continue;
            Vec2 imgp = apply(to_img, Vec2{x + 0.5, y + 0.5});
            uint8_t ma = 0;
            if (imgp.x >= 0 && imgp.y >= 0 && imgp.x < iw && imgp.y < ih) {
                uint8_t s[4];
                sample_image(mask, imgp.x, imgp.y, ctx->gs.interp, s);
                ma = s[3];
            }
            unsigned v = (unsigned)(ctx->gs.clip[i] * ma + 127u) / 255u;
            ctx->gs.clip[i] = (uint8_t)(v > 255 ? 255 : v);
        }
    }
}

QZImageRef QZImageCreateWithMask(QZImageRef image, QZImageRef mask) {
    if (!image) return nullptr;
    auto *out = new QZImage();
    out->width = image->width;
    out->height = image->height;
    size_t n = (size_t)out->width * (size_t)out->height;
    out->rgba.resize(n * 4);
    if (!mask || mask->width <= 0 || mask->height <= 0) {
        out->rgba = image->rgba;
        return out;
    }

    bool same = mask->width == image->width && mask->height == image->height;
    for (int y = 0; y < out->height; y++) {
        for (int x = 0; x < out->width; x++) {
            size_t i = ((size_t)y * out->width + x) * 4;
            uint8_t ma;
            if (same) {
                ma = mask->rgba[i + 3];
            } else {
                double u = (x + 0.5) * mask->width / (double)out->width;
                double v = (y + 0.5) * mask->height / (double)out->height;
                uint8_t s[4];
                sample_image(mask, u, v, kQZInterpolationLow, s);
                ma = s[3];
            }
            const uint8_t *s = image->rgba.data() + i;
            out->rgba[i + 0] = (uint8_t)((s[0] * ma) / 255);
            out->rgba[i + 1] = (uint8_t)((s[1] * ma) / 255);
            out->rgba[i + 2] = (uint8_t)((s[2] * ma) / 255);
            out->rgba[i + 3] = (uint8_t)((s[3] * ma) / 255);
        }
    }
    return out;
}

QZRect QZContextGetClipBoundingBox(QZContextRef ctx) {
    if (!ctx) return QZRectMake(0, 0, 0, 0);
    int w = ctx->width, h = ctx->height;
    ensure_clip(ctx->gs, w, h);
    int minx = w, miny = h, maxx = -1, maxy = -1;
    for (int y = 0; y < h; y++) {
        const uint8_t *row = ctx->gs.clip.data() + (size_t)y * w;
        for (int x = 0; x < w; x++) {
            if (row[x] == 0) continue;
            if (x < minx) minx = x;
            if (x > maxx) maxx = x;
            if (y < miny) miny = y;
            if (y > maxy) maxy = y;
        }
    }
    if (maxx < minx) return QZRectMake(0, 0, 0, 0);
    QZRect mem = QZRectMake((QZFloat)minx, (QZFloat)miny,
                            (QZFloat)(maxx - minx + 1), (QZFloat)(maxy - miny + 1));
    QZAffineTransform to_user = QZAffineTransformInvert(user_to_mem(ctx->gs, h));
    return QZRectApplyAffineTransform(mem, to_user);
}
