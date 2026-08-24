/* OWNED BY package path-stroke. */
#ifndef QUARTZ_PATH_STROKE_H
#define QUARTZ_PATH_STROKE_H
#ifdef __cplusplus
extern "C" {
#endif

QZPathRef QZPathCreateCopyByStrokingPath(QZPathRef path, const QZAffineTransform *m,
                                         QZFloat lineWidth, QZLineCap cap, QZLineJoin join,
                                         QZFloat miterLimit);
QZPathRef QZPathCreateCopyByDashingPath(QZPathRef path, const QZAffineTransform *m,
                                        QZFloat phase, const QZFloat *lengths, size_t count);
void QZContextReplacePathWithStrokedPath(QZContextRef ctx);
void QZContextAddLines(QZContextRef ctx, const QZPoint *points, size_t count);
void QZContextStrokeLineSegments(QZContextRef ctx, const QZPoint *points, size_t count);
void QZContextFillRects(QZContextRef ctx, const QZRect *rects, size_t count);

#ifdef __cplusplus
}
#endif
#endif
