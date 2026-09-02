/* OWNED BY package geom. */
#ifndef QUARTZ_GEOM_H
#define QUARTZ_GEOM_H
#ifdef __cplusplus
extern "C" {
#endif

bool QZPointEqualToPoint(QZPoint a, QZPoint b);
bool QZSizeEqualToSize(QZSize a, QZSize b);
bool QZRectEqualToRect(QZRect a, QZRect b);
QZFloat QZRectGetMinX(QZRect r);
QZFloat QZRectGetMinY(QZRect r);
QZFloat QZRectGetMaxX(QZRect r);
QZFloat QZRectGetMaxY(QZRect r);
QZFloat QZRectGetMidX(QZRect r);
QZFloat QZRectGetMidY(QZRect r);
QZFloat QZRectGetWidth(QZRect r);
QZFloat QZRectGetHeight(QZRect r);
bool QZRectIsEmpty(QZRect r);
QZRect QZRectStandardize(QZRect r);
QZRect QZRectInset(QZRect r, QZFloat dx, QZFloat dy);
QZRect QZRectOffset(QZRect r, QZFloat dx, QZFloat dy);
QZRect QZRectIntegral(QZRect r);
QZRect QZRectUnion(QZRect a, QZRect b);
QZRect QZRectIntersection(QZRect a, QZRect b);
bool QZRectContainsPoint(QZRect r, QZPoint p);
bool QZRectContainsRect(QZRect a, QZRect b);
bool QZRectIntersectsRect(QZRect a, QZRect b);
bool QZAffineTransformIsIdentity(QZAffineTransform t);
bool QZAffineTransformEqualToTransform(QZAffineTransform a, QZAffineTransform b);

#ifdef __cplusplus
}
#endif
#endif
