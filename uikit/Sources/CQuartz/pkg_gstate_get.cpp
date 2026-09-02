#include "qz_internal.hpp"
/* OWNED BY package gstate-get. */

QZFloat QZContextGetLineWidth(QZContextRef ctx) {
    return ctx ? (QZFloat)ctx->gs.line_width : 0;
}
QZLineCap QZContextGetLineCap(QZContextRef ctx) {
    return ctx ? ctx->gs.line_cap : kQZLineCapButt;
}
QZLineJoin QZContextGetLineJoin(QZContextRef ctx) {
    return ctx ? ctx->gs.line_join : kQZLineJoinMiter;
}
QZFloat QZContextGetMiterLimit(QZContextRef ctx) {
    return ctx ? (QZFloat)ctx->gs.miter_limit : 10;
}
QZFloat QZContextGetAlpha(QZContextRef ctx) {
    return ctx ? (QZFloat)ctx->gs.alpha : 1;
}
QZBlendMode QZContextGetBlendMode(QZContextRef ctx) {
    return ctx ? ctx->gs.blend : kQZBlendModeNormal;
}
QZInterpolationQuality QZContextGetInterpolationQuality(QZContextRef ctx) {
    return ctx ? ctx->gs.interp : kQZInterpolationDefault;
}
bool QZContextGetShouldAntialias(QZContextRef ctx) {
    return ctx ? ctx->gs.antialias : true;
}
QZFloat QZContextGetFlatness(QZContextRef ctx) {
    return ctx ? (QZFloat)ctx->gs.flatness : 0;
}
void QZContextGetFillColor(QZContextRef ctx, QZFloat rgba[4]) {
    if (!rgba) return;
    if (!ctx) {
        rgba[0] = rgba[1] = rgba[2] = rgba[3] = 0;
        return;
    }
    rgba[0] = (QZFloat)ctx->gs.fill.r;
    rgba[1] = (QZFloat)ctx->gs.fill.g;
    rgba[2] = (QZFloat)ctx->gs.fill.b;
    rgba[3] = (QZFloat)ctx->gs.fill.a;
}
void QZContextGetStrokeColor(QZContextRef ctx, QZFloat rgba[4]) {
    if (!rgba) return;
    if (!ctx) {
        rgba[0] = rgba[1] = rgba[2] = rgba[3] = 0;
        return;
    }
    rgba[0] = (QZFloat)ctx->gs.stroke.r;
    rgba[1] = (QZFloat)ctx->gs.stroke.g;
    rgba[2] = (QZFloat)ctx->gs.stroke.b;
    rgba[3] = (QZFloat)ctx->gs.stroke.a;
}
void QZContextGetLineDash(QZContextRef ctx, QZFloat *phase, QZFloat *lengths, size_t *count) {
    if (phase) *phase = ctx ? (QZFloat)ctx->gs.dash_phase : 0;
    size_t n = ctx ? ctx->gs.dash.size() : 0;
    size_t copy = n;
    if (count) {
        if (lengths && *count < copy) copy = *count;
        *count = n;
    }
    if (lengths && ctx) {
        for (size_t i = 0; i < copy; i++) lengths[i] = (QZFloat)ctx->gs.dash[i];
    }
}
