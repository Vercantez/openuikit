#include "qz_internal.hpp"
/* OWNED BY package context-misc. */

/* Bitmap device space is y-down pixels (origin top-left), matching
 * CGContextGetUserSpaceToDeviceSpaceTransform on a CGBitmapContext. */
static QZAffineTransform user_to_device(const QZContext *ctx) {
    QZAffineTransform yflip = QZAffineTransformMake(1, 0, 0, -1, 0, (QZFloat)ctx->height);
    return QZAffineTransformConcat(yflip, ctx->gs.ctm);
}

void QZContextResetClip(QZContextRef ctx) {
    if (!ctx) return;
    ctx->gs.clip.assign((size_t)ctx->width * (size_t)ctx->height, 255);
}

QZImageRef QZBitmapContextCreateImage(QZContextRef ctx) {
    if (!ctx || !ctx->pixels) return nullptr;
    auto *img = new QZImage();
    img->width = ctx->width;
    img->height = ctx->height;
    img->rgba.resize((size_t)ctx->width * (size_t)ctx->height * 4);
    for (int y = 0; y < ctx->height; y++) {
        memcpy(img->rgba.data() + (size_t)y * ctx->width * 4,
               ctx->pixels + (size_t)y * ctx->bpr, (size_t)ctx->width * 4);
    }
    return img;
}

/* Snapshot the backing with rows reversed (bottom-up), pixels kept
 * premultiplied. QZContextDrawImage maps image row 0 to the dest rect's TOP
 * in y-up user space, so a top-down backing snapshot composited under a
 * top-down flip CTM needs this orientation to land upright. Used for
 * layer-contents caching (composite once, blit thereafter) without a lossy
 * premul -> straight -> premul round trip. */
QZImageRef QZBitmapContextCreateImageRowsFlipped(QZContextRef ctx) {
    if (!ctx || !ctx->pixels) return nullptr;
    auto *img = new QZImage();
    img->width = ctx->width;
    img->height = ctx->height;
    img->rgba.resize((size_t)ctx->width * (size_t)ctx->height * 4);
    for (int y = 0; y < ctx->height; y++) {
        memcpy(img->rgba.data() + (size_t)(ctx->height - 1 - y) * ctx->width * 4,
               ctx->pixels + (size_t)y * ctx->bpr, (size_t)ctx->width * 4);
    }
    return img;
}

void QZContextSetGrayFillColor(QZContextRef ctx, QZFloat gray, QZFloat alpha) {
    QZContextSetRGBFillColor(ctx, gray, gray, gray, alpha);
}

void QZContextSetGrayStrokeColor(QZContextRef ctx, QZFloat gray, QZFloat alpha) {
    QZContextSetRGBStrokeColor(ctx, gray, gray, gray, alpha);
}

QZPoint QZContextConvertPointToDeviceSpace(QZContextRef ctx, QZPoint p) {
    if (!ctx) return p;
    return QZPointApplyAffineTransform(p, user_to_device(ctx));
}

QZPoint QZContextConvertPointToUserSpace(QZContextRef ctx, QZPoint p) {
    if (!ctx) return p;
    return QZPointApplyAffineTransform(p, QZAffineTransformInvert(user_to_device(ctx)));
}

QZSize QZContextConvertSizeToDeviceSpace(QZContextRef ctx, QZSize s) {
    if (!ctx) return s;
    return QZSizeApplyAffineTransform(s, user_to_device(ctx));
}

QZSize QZContextConvertSizeToUserSpace(QZContextRef ctx, QZSize s) {
    if (!ctx) return s;
    return QZSizeApplyAffineTransform(s, QZAffineTransformInvert(user_to_device(ctx)));
}

QZRect QZContextConvertRectToDeviceSpace(QZContextRef ctx, QZRect r) {
    if (!ctx) return r;
    return QZRectApplyAffineTransform(r, user_to_device(ctx));
}

QZRect QZContextConvertRectToUserSpace(QZContextRef ctx, QZRect r) {
    if (!ctx) return r;
    return QZRectApplyAffineTransform(r, QZAffineTransformInvert(user_to_device(ctx)));
}

bool QZContextIsPathEmpty(QZContextRef ctx) {
    return !ctx || ctx->path.cmds.empty();
}

QZPoint QZContextGetPathCurrentPoint(QZContextRef ctx) {
    if (!ctx) return QZPointMake(0, 0);
    return ctx->path.current.qz();
}

QZRect QZContextGetPathBoundingBox(QZContextRef ctx) {
    if (!ctx) return QZRectMake(INFINITY, INFINITY, 0, 0);
    QZPath tmp;
    tmp.p = ctx->path;
    return QZPathGetBoundingBox(&tmp);
}

QZPathRef QZContextCopyPath(QZContextRef ctx) {
    if (!ctx || ctx->path.cmds.empty()) return nullptr;
    QZPath tmp;
    tmp.p = ctx->path;
    return QZPathCreateCopy(&tmp);
}
