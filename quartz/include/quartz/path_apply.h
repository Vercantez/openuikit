/* OWNED BY package path-apply. Do not edit from other packages. */
#ifndef QUARTZ_PATH_APPLY_H
#define QUARTZ_PATH_APPLY_H
#ifdef __cplusplus
extern "C" {
#endif

/* Element types match CGPathElementType. Quadratic segments are stored as
 * cubics (2/3 elevation), so Apply reports AddCurveToPoint for quads. */
typedef enum {
    kQZPathElementMoveToPoint = 0,
    kQZPathElementAddLineToPoint,
    kQZPathElementAddQuadCurveToPoint,
    kQZPathElementAddCurveToPoint,
    kQZPathElementCloseSubpath
} QZPathElementType;

typedef struct {
    QZPathElementType type;
    QZPoint points[3];
} QZPathElement;

typedef void (*QZPathApplierFunction)(void *info, const QZPathElement *element);

void QZPathApply(QZPathRef path, void *info, QZPathApplierFunction function);
size_t QZPathGetElementCount(QZPathRef path);
void QZPathAddArcToPoint(QZMutablePathRef path, const QZAffineTransform *m,
                         QZFloat x1, QZFloat y1, QZFloat x2, QZFloat y2, QZFloat radius);
void QZPathAddLines(QZMutablePathRef path, const QZAffineTransform *m,
                    const QZPoint *points, size_t count);

#ifdef __cplusplus
}
#endif
#endif
