#include "qz_internal.hpp"
/* OWNED BY package cglayer. */

struct QZCGLayer {
    QZSize size{0, 0};
    QZContextRef ctx = nullptr;
};

QZCGLayerRef QZCGLayerCreateWithContext(QZContextRef ctx, QZSize size) {
    (void)ctx;
    auto *l = new QZCGLayer();
    l->size = size;
    int w = (int)std::ceil(std::fabs(size.width));
    int h = (int)std::ceil(std::fabs(size.height));
    if (w < 1) w = 1;
    if (h < 1) h = 1;
    /* Same 8-bit premul RGBA backing as the parent bitmap context. User space
     * of the layer context is the layer size (y-up, origin bottom-left). */
    l->ctx = QZBitmapContextCreate(nullptr, (size_t)w, (size_t)h, 8, (size_t)w * 4,
                                   kQZImageAlphaPremultipliedLast);
    return l;
}
void QZCGLayerRelease(QZCGLayerRef layer) {
    if (!layer) return;
    QZContextRelease(layer->ctx);
    delete layer;
}
QZContextRef QZCGLayerGetContext(QZCGLayerRef layer) { return layer ? layer->ctx : nullptr; }
QZSize QZCGLayerGetSize(QZCGLayerRef layer) { return layer ? layer->size : QZSizeMake(0, 0); }
void QZContextDrawLayerAtPoint(QZContextRef ctx, QZPoint point, QZCGLayerRef layer) {
    if (!ctx || !layer || !layer->ctx) return;
    QZContextDrawLayerInRect(ctx, QZRectMake(point.x, point.y, layer->size.width, layer->size.height), layer);
}
void QZContextDrawLayerInRect(QZContextRef ctx, QZRect rect, QZCGLayerRef layer) {
    if (!ctx || !layer || !layer->ctx) return;
    /* Snapshot premul layer pixels into a QZImage (already premul). DrawImage
     * maps image-top to dest-top, matching CGLayer y-up blit. */
    QZContext *lc = layer->ctx;
    int w = lc->width, h = lc->height;
    if (w < 1 || h < 1) return;
    auto *img = new QZImage();
    img->width = w;
    img->height = h;
    img->rgba.resize((size_t)w * (size_t)h * 4);
    for (int y = 0; y < h; y++) {
        memcpy(img->rgba.data() + (size_t)y * w * 4,
               lc->pixels + (size_t)y * lc->bpr, (size_t)w * 4);
    }
    QZContextDrawImage(ctx, rect, img);
    QZImageRelease(img);
}
