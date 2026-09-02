#include "qz_internal.hpp"
/* OWNED BY package trans-rect. */

void QZContextBeginTransparencyLayerWithRect(QZContextRef ctx, QZRect rect) {
    if (!ctx) return;
    /* Apple: save GState, intersect clip with rect, alpha=1, shadows off;
     * EndTransparencyLayer restores that save. QZ End does not pop GState,
     * so this extra save is leftover after End (Apple extra Restore is a
     * no-op). Sample usage is BeginWithRect … draw … End — no Restore. */
    QZContextSaveGState(ctx);
    QZContextClipToRect(ctx, rect);
    ctx->gs.shadow = false;
    QZContextBeginTransparencyLayer(ctx);
}

void QZContextSetShadowWithColorQZ(QZContextRef ctx, QZSize offset, QZFloat blur,
                                   QZColorRef color) {
    if (!ctx) return;
    /* Apple CGContextSetShadowWithColor with NULL color disables the shadow. */
    if (!color) {
        ctx->gs.shadow = false;
        ctx->gs.shadow_ox = offset.width;
        ctx->gs.shadow_oy = offset.height;
        ctx->gs.shadow_blur = std::max(0.0, (double)blur);
        ctx->gs.shadow_color = {0, 0, 0, 0};
        return;
    }
    QZFloat r = 0, g = 0, b = 0, a = 1;
    size_t n = QZColorGetNumberOfComponents(color);
    const QZFloat *c = QZColorGetComponents(color);
    if (c && n >= 4) {
        r = c[0];
        g = c[1];
        b = c[2];
        a = c[3];
    } else if (c && n >= 2) {
        r = g = b = c[0];
        a = c[1];
    } else if (c && n >= 1) {
        r = g = b = c[0];
        a = 1;
    }
    QZContextSetShadowWithColor(ctx, offset, blur, r, g, b, a);
}

void QZContextBeginTransparencyLayerWithInfo(QZContextRef ctx) {
    QZContextBeginTransparencyLayer(ctx);
}
