/* Portable Quartz 2D (Core Graphics) — C API.
 *
 * Types and functions mirror Apple's CoreGraphics with a QZ prefix so this
 * header can coexist with <CoreGraphics/CoreGraphics.h> on macOS.
 *
 * Coordinate system matches a CGBitmapContext: origin at the bottom-left,
 * y-up in user space. Bitmap memory is top-down RGBA premultiplied 8-bit.
 */
#ifndef QUARTZ_QUARTZ_H
#define QUARTZ_QUARTZ_H

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef double QZFloat;

typedef struct { QZFloat x, y; } QZPoint;
typedef struct { QZFloat width, height; } QZSize;
typedef struct { QZPoint origin; QZSize size; } QZRect;
typedef struct { QZFloat a, b, c, d, tx, ty; } QZAffineTransform;

typedef struct QZContext *QZContextRef;
typedef struct QZPath *QZPathRef;
typedef struct QZPath *QZMutablePathRef;
typedef struct QZImage *QZImageRef;
typedef struct QZGradient *QZGradientRef;

typedef enum {
    kQZLineCapButt = 0,
    kQZLineCapRound = 1,
    kQZLineCapSquare = 2
} QZLineCap;

typedef enum {
    kQZLineJoinMiter = 0,
    kQZLineJoinRound = 1,
    kQZLineJoinBevel = 2
} QZLineJoin;

typedef enum {
    kQZPathFill = 0,
    kQZPathEOFill,
    kQZPathStroke,
    kQZPathFillStroke,
    kQZPathEOFillStroke
} QZPathDrawingMode;

typedef enum {
    kQZBlendModeNormal = 0,
    kQZBlendModeMultiply,
    kQZBlendModeScreen,
    kQZBlendModeOverlay,
    kQZBlendModeDarken,
    kQZBlendModeLighten,
    kQZBlendModeColorDodge,
    kQZBlendModeColorBurn,
    kQZBlendModeSoftLight,
    kQZBlendModeHardLight,
    kQZBlendModeDifference,
    kQZBlendModeExclusion,
    kQZBlendModeHue,
    kQZBlendModeSaturation,
    kQZBlendModeColor,
    kQZBlendModeLuminosity,
    kQZBlendModeClear,
    kQZBlendModeCopy,
    kQZBlendModeSourceIn,
    kQZBlendModeSourceOut,
    kQZBlendModeSourceAtop,
    kQZBlendModeDestinationOver,
    kQZBlendModeDestinationIn,
    kQZBlendModeDestinationOut,
    kQZBlendModeDestinationAtop,
    kQZBlendModeXOR,
    kQZBlendModePlusDarker,
    kQZBlendModePlusLighter
} QZBlendMode;

typedef enum {
    kQZGradientDrawsBeforeStartLocation = 1 << 0,
    kQZGradientDrawsAfterEndLocation    = 1 << 1
} QZGradientDrawingOptions;

typedef enum {
    kQZInterpolationDefault = 0,
    kQZInterpolationNone = 1,
    kQZInterpolationLow = 2,
    kQZInterpolationHigh = 3,
    kQZInterpolationMedium = 4
} QZInterpolationQuality;

#define kQZImageAlphaPremultipliedLast 1u

/* Geometry helpers */
static inline QZPoint QZPointMake(QZFloat x, QZFloat y) {
    QZPoint p; p.x = x; p.y = y; return p;
}
static inline QZSize QZSizeMake(QZFloat w, QZFloat h) {
    QZSize s; s.width = w; s.height = h; return s;
}
static inline QZRect QZRectMake(QZFloat x, QZFloat y, QZFloat w, QZFloat h) {
    QZRect r; r.origin.x = x; r.origin.y = y; r.size.width = w; r.size.height = h; return r;
}

QZAffineTransform QZAffineTransformIdentity(void);
QZAffineTransform QZAffineTransformMake(QZFloat a, QZFloat b, QZFloat c, QZFloat d,
                                        QZFloat tx, QZFloat ty);
QZAffineTransform QZAffineTransformMakeTranslation(QZFloat tx, QZFloat ty);
QZAffineTransform QZAffineTransformMakeScale(QZFloat sx, QZFloat sy);
QZAffineTransform QZAffineTransformMakeRotation(QZFloat angle);
QZAffineTransform QZAffineTransformTranslate(QZAffineTransform t, QZFloat tx, QZFloat ty);
QZAffineTransform QZAffineTransformScale(QZAffineTransform t, QZFloat sx, QZFloat sy);
QZAffineTransform QZAffineTransformRotate(QZAffineTransform t, QZFloat angle);
QZAffineTransform QZAffineTransformConcat(QZAffineTransform t1, QZAffineTransform t2);
QZAffineTransform QZAffineTransformInvert(QZAffineTransform t);
QZPoint QZPointApplyAffineTransform(QZPoint p, QZAffineTransform t);
QZSize  QZSizeApplyAffineTransform(QZSize s, QZAffineTransform t);
QZRect  QZRectApplyAffineTransform(QZRect r, QZAffineTransform t);

/* Bitmap context: 8-bit RGBA premultiplied, sRGB. data may be NULL (owned). */
QZContextRef QZBitmapContextCreate(void *data, size_t width, size_t height,
                                   size_t bitsPerComponent, size_t bytesPerRow,
                                   uint32_t bitmapInfo);
void QZContextRelease(QZContextRef ctx);
void *QZBitmapContextGetData(QZContextRef ctx);
size_t QZBitmapContextGetWidth(QZContextRef ctx);
size_t QZBitmapContextGetHeight(QZContextRef ctx);
size_t QZBitmapContextGetBytesPerRow(QZContextRef ctx);

/* Graphics state */
void QZContextSaveGState(QZContextRef ctx);
void QZContextRestoreGState(QZContextRef ctx);

void QZContextScaleCTM(QZContextRef ctx, QZFloat sx, QZFloat sy);
void QZContextTranslateCTM(QZContextRef ctx, QZFloat tx, QZFloat ty);
void QZContextRotateCTM(QZContextRef ctx, QZFloat angle);
void QZContextConcatCTM(QZContextRef ctx, QZAffineTransform t);
QZAffineTransform QZContextGetCTM(QZContextRef ctx);

void QZContextSetLineWidth(QZContextRef ctx, QZFloat width);
void QZContextSetLineCap(QZContextRef ctx, QZLineCap cap);
void QZContextSetLineJoin(QZContextRef ctx, QZLineJoin join);
void QZContextSetMiterLimit(QZContextRef ctx, QZFloat limit);
void QZContextSetLineDash(QZContextRef ctx, QZFloat phase, const QZFloat *lengths, size_t count);
void QZContextSetFlatness(QZContextRef ctx, QZFloat flatness);
void QZContextSetAlpha(QZContextRef ctx, QZFloat alpha);
void QZContextSetBlendMode(QZContextRef ctx, QZBlendMode mode);
void QZContextSetShouldAntialias(QZContextRef ctx, bool antialias);
void QZContextSetInterpolationQuality(QZContextRef ctx, QZInterpolationQuality q);

void QZContextSetRGBFillColor(QZContextRef ctx, QZFloat r, QZFloat g, QZFloat b, QZFloat a);
void QZContextSetRGBStrokeColor(QZContextRef ctx, QZFloat r, QZFloat g, QZFloat b, QZFloat a);

/* Path construction on the context's current path */
void QZContextBeginPath(QZContextRef ctx);
void QZContextMoveToPoint(QZContextRef ctx, QZFloat x, QZFloat y);
void QZContextAddLineToPoint(QZContextRef ctx, QZFloat x, QZFloat y);
void QZContextAddCurveToPoint(QZContextRef ctx, QZFloat cp1x, QZFloat cp1y,
                              QZFloat cp2x, QZFloat cp2y, QZFloat x, QZFloat y);
void QZContextAddQuadCurveToPoint(QZContextRef ctx, QZFloat cpx, QZFloat cpy,
                                  QZFloat x, QZFloat y);
void QZContextAddRect(QZContextRef ctx, QZRect rect);
void QZContextAddEllipseInRect(QZContextRef ctx, QZRect rect);
void QZContextAddArc(QZContextRef ctx, QZFloat x, QZFloat y, QZFloat radius,
                     QZFloat startAngle, QZFloat endAngle, int clockwise);
void QZContextAddArcToPoint(QZContextRef ctx, QZFloat x1, QZFloat y1,
                            QZFloat x2, QZFloat y2, QZFloat radius);
void QZContextAddPath(QZContextRef ctx, QZPathRef path);
void QZContextClosePath(QZContextRef ctx);

void QZContextDrawPath(QZContextRef ctx, QZPathDrawingMode mode);
void QZContextFillPath(QZContextRef ctx);
void QZContextEOFillPath(QZContextRef ctx);
void QZContextStrokePath(QZContextRef ctx);

void QZContextFillRect(QZContextRef ctx, QZRect rect);
void QZContextStrokeRect(QZContextRef ctx, QZRect rect);
void QZContextStrokeRectWithWidth(QZContextRef ctx, QZRect rect, QZFloat width);
void QZContextClearRect(QZContextRef ctx, QZRect rect);
void QZContextFillEllipseInRect(QZContextRef ctx, QZRect rect);
void QZContextStrokeEllipseInRect(QZContextRef ctx, QZRect rect);

void QZContextClip(QZContextRef ctx);
void QZContextEOClip(QZContextRef ctx);
void QZContextClipToRect(QZContextRef ctx, QZRect rect);

void QZContextBeginTransparencyLayer(QZContextRef ctx);
void QZContextEndTransparencyLayer(QZContextRef ctx);
void QZContextSetShadow(QZContextRef ctx, QZSize offset, QZFloat blur);
void QZContextSetShadowWithColor(QZContextRef ctx, QZSize offset, QZFloat blur,
                                 QZFloat r, QZFloat g, QZFloat b, QZFloat a);

void QZContextDrawImage(QZContextRef ctx, QZRect rect, QZImageRef image);
void QZContextDrawLinearGradient(QZContextRef ctx, QZGradientRef gradient,
                                 QZPoint startPoint, QZPoint endPoint, uint32_t options);
void QZContextDrawRadialGradient(QZContextRef ctx, QZGradientRef gradient,
                                 QZPoint startCenter, QZFloat startRadius,
                                 QZPoint endCenter, QZFloat endRadius, uint32_t options);

/* Path objects */
QZMutablePathRef QZPathCreateMutable(void);
QZPathRef QZPathRetain(QZPathRef path);
void QZPathRelease(QZPathRef path);
void QZPathMoveToPoint(QZMutablePathRef path, const QZAffineTransform *m, QZFloat x, QZFloat y);
void QZPathAddLineToPoint(QZMutablePathRef path, const QZAffineTransform *m, QZFloat x, QZFloat y);
void QZPathAddCurveToPoint(QZMutablePathRef path, const QZAffineTransform *m,
                           QZFloat cp1x, QZFloat cp1y, QZFloat cp2x, QZFloat cp2y,
                           QZFloat x, QZFloat y);
void QZPathAddQuadCurveToPoint(QZMutablePathRef path, const QZAffineTransform *m,
                               QZFloat cpx, QZFloat cpy, QZFloat x, QZFloat y);
void QZPathAddRect(QZMutablePathRef path, const QZAffineTransform *m, QZRect rect);
void QZPathAddRoundedRect(QZMutablePathRef path, const QZAffineTransform *m,
                          QZRect rect, QZFloat cornerRadius);
void QZPathAddEllipseInRect(QZMutablePathRef path, const QZAffineTransform *m, QZRect rect);
void QZPathAddArc(QZMutablePathRef path, const QZAffineTransform *m,
                  QZFloat x, QZFloat y, QZFloat radius,
                  QZFloat startAngle, QZFloat endAngle, int clockwise);
void QZPathCloseSubpath(QZMutablePathRef path);
void QZPathAddPath(QZMutablePathRef path, const QZAffineTransform *m, QZPathRef other);

/* Images: 8-bit non-premultiplied RGBA input is accepted; stored premul. */
QZImageRef QZImageCreate(size_t width, size_t height, const uint8_t *rgba_nonpremul);
void QZImageRelease(QZImageRef image);
size_t QZImageGetWidth(QZImageRef image);
size_t QZImageGetHeight(QZImageRef image);

/* Gradients: locations in [0,1], colors as RGBA (non-premul) in sRGB. */
QZGradientRef QZGradientCreate(const QZFloat *locations, const QZFloat *components,
                               size_t count);
void QZGradientRelease(QZGradientRef gradient);

void QZContextAddRoundedRect(QZContextRef ctx, QZRect rect, QZFloat cornerRadius);

/* PNG helper (for the comparison harness). */
int QZContextWritePNG(QZContextRef ctx, const char *path);

/* ---- 3D transform (Core Animation) ---- */
typedef struct {
    QZFloat m11, m12, m13, m14;
    QZFloat m21, m22, m23, m24;
    QZFloat m31, m32, m33, m34;
    QZFloat m41, m42, m43, m44;
} QZTransform3D;

QZTransform3D QZTransform3DIdentity(void);
QZTransform3D QZTransform3DMakeTranslation(QZFloat tx, QZFloat ty, QZFloat tz);
QZTransform3D QZTransform3DMakeScale(QZFloat sx, QZFloat sy, QZFloat sz);
QZTransform3D QZTransform3DMakeRotation(QZFloat angle, QZFloat x, QZFloat y, QZFloat z);
QZTransform3D QZTransform3DConcat(QZTransform3D a, QZTransform3D b);
QZTransform3D QZTransform3DInvert(QZTransform3D t);
QZTransform3D QZTransform3DMakeAffineTransform(QZAffineTransform m);
bool QZTransform3DIsAffine(QZTransform3D t);
QZAffineTransform QZTransform3DGetAffineTransform(QZTransform3D t);

/* ---- Layer tree (Core Animation) ---- */
typedef struct QZLayer *QZLayerRef;

typedef enum {
    kQZLayerKindBase = 0,
    kQZLayerKindShape,
    kQZLayerKindGradient,
    kQZLayerKindText,
    kQZLayerKindReplicator,
    kQZLayerKindTransform
} QZLayerKind;

QZLayerRef QZLayerCreate(void);
QZLayerRef QZShapeLayerCreate(void);
QZLayerRef QZGradientLayerCreate(void);
void QZLayerRelease(QZLayerRef layer);

void QZLayerSetBounds(QZLayerRef layer, QZRect bounds);
void QZLayerSetPosition(QZLayerRef layer, QZPoint position);
void QZLayerSetAnchorPoint(QZLayerRef layer, QZPoint anchor);
void QZLayerSetFrame(QZLayerRef layer, QZRect frame);
void QZLayerSetZPosition(QZLayerRef layer, QZFloat z);
void QZLayerSetAffineTransform(QZLayerRef layer, QZAffineTransform t);
void QZLayerSetTransform(QZLayerRef layer, QZTransform3D t);
void QZLayerSetBackgroundColor(QZLayerRef layer, QZFloat r, QZFloat g, QZFloat b, QZFloat a);
void QZLayerSetOpacity(QZLayerRef layer, QZFloat opacity);
void QZLayerSetCornerRadius(QZLayerRef layer, QZFloat radius);
void QZLayerSetBorderWidth(QZLayerRef layer, QZFloat width);
void QZLayerSetBorderColor(QZLayerRef layer, QZFloat r, QZFloat g, QZFloat b, QZFloat a);
void QZLayerSetMasksToBounds(QZLayerRef layer, bool masks);
void QZLayerSetHidden(QZLayerRef layer, bool hidden);
void QZLayerAddSublayer(QZLayerRef layer, QZLayerRef child);
void QZLayerSetContents(QZLayerRef layer, QZImageRef image);

void QZShapeLayerSetPath(QZLayerRef layer, QZPathRef path);
void QZShapeLayerSetFillColor(QZLayerRef layer, QZFloat r, QZFloat g, QZFloat b, QZFloat a);
void QZShapeLayerSetStrokeColor(QZLayerRef layer, QZFloat r, QZFloat g, QZFloat b, QZFloat a);
void QZShapeLayerSetLineWidth(QZLayerRef layer, QZFloat width);
void QZShapeLayerSetFillEvenOdd(QZLayerRef layer, bool even_odd);
void QZShapeLayerSetLineCap(QZLayerRef layer, QZLineCap cap);
void QZShapeLayerSetLineJoin(QZLayerRef layer, QZLineJoin join);

void QZGradientLayerSetColors(QZLayerRef layer, const QZFloat *rgba, const QZFloat *locations, int n);
void QZGradientLayerSetStartPoint(QZLayerRef layer, QZPoint p);
void QZGradientLayerSetEndPoint(QZLayerRef layer, QZPoint p);
void QZGradientLayerSetRadial(QZLayerRef layer, bool radial);

void QZLayerRenderInContext(QZLayerRef layer, QZContextRef ctx);

#include "quartz/path_query.h"
#include "quartz/color.h"
#include "quartz/image_ext.h"
#include "quartz/layer_ext.h"
#include "quartz/geom.h"
#include "quartz/path_stroke.h"
#include "quartz/shape_stroke.h"
#include "quartz/gradient_ext.h"
#include "quartz/context_misc.h"
#include "quartz/animation.h"
#include "quartz/text.h"
#include "quartz/pattern.h"
#include "quartz/shading.h"
#include "quartz/path_apply.h"
#include "quartz/replicator.h"
#include "quartz/timing.h"
#include "quartz/cglayer.h"
#include "quartz/pdf.h"
#include "quartz/gstate_get.h"
#include "quartz/cmyk.h"
#include "quartz/image_io.h"
#include "quartz/font_ext.h"
#include "quartz/transform_layer.h"
#include "quartz/color_p3.h"
#include "quartz/trans_rect.h"
#include "quartz/image_crop.h"
#include "quartz/anim_group.h"
#include "quartz/data_provider.h"
#include "quartz/scroll_layer.h"

#ifdef __cplusplus
}
#endif

#endif /* QUARTZ_QUARTZ_H */
