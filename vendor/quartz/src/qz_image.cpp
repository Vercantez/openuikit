#include "qz_internal.hpp"

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

QZImageRef QZImageCreate(size_t width, size_t height, const uint8_t *rgba_nonpremul) {
    if (!width || !height || !rgba_nonpremul) return nullptr;
    auto *img = new QZImage();
    img->width = (int)width;
    img->height = (int)height;
    img->rgba.resize(width * height * 4);
    for (size_t i = 0; i < width * height; i++) {
        const uint8_t *s = rgba_nonpremul + i * 4;
        uint8_t a = s[3];
        img->rgba[i * 4 + 0] = (uint8_t)((s[0] * a) / 255);
        img->rgba[i * 4 + 1] = (uint8_t)((s[1] * a) / 255);
        img->rgba[i * 4 + 2] = (uint8_t)((s[2] * a) / 255);
        img->rgba[i * 4 + 3] = a;
    }
    return img;
}
void QZImageRelease(QZImageRef image) { delete image; }
size_t QZImageGetWidth(QZImageRef image) { return image ? (size_t)image->width : 0; }
size_t QZImageGetHeight(QZImageRef image) { return image ? (size_t)image->height : 0; }

QZGradientRef QZGradientCreate(const QZFloat *locations, const QZFloat *components,
                               size_t count) {
    if (!locations || !components || count < 2) return nullptr;
    auto *g = new QZGradient();
    for (size_t i = 0; i < count; i++) {
        g->g.stops.push_back(locations[i]);
        qz::Color c{components[i * 4 + 0], components[i * 4 + 1],
                    components[i * 4 + 2], components[i * 4 + 3]};
        g->g.colors.push_back(c);
    }
    return g;
}
void QZGradientRelease(QZGradientRef gradient) { delete gradient; }

int QZContextWritePNG(QZContextRef ctx, const char *path) {
    if (!ctx || !path || !ctx->pixels) return 0;
    /* stbi wants packed RGBA with no padding. Copy if bpr != width*4. */
    if (ctx->bpr == (size_t)ctx->width * 4) {
        return stbi_write_png(path, ctx->width, ctx->height, 4, ctx->pixels, (int)ctx->bpr);
    }
    std::vector<uint8_t> packed((size_t)ctx->width * ctx->height * 4);
    for (int y = 0; y < ctx->height; y++) {
        memcpy(packed.data() + (size_t)y * ctx->width * 4,
               ctx->pixels + (size_t)y * ctx->bpr, (size_t)ctx->width * 4);
    }
    return stbi_write_png(path, ctx->width, ctx->height, 4, packed.data(), ctx->width * 4);
}
