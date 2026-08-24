/* OWNED BY package path-query. Do not edit from other packages.
 * CGPath query/copy APIs. Types come from quartz.h (include this after). */
#ifndef QUARTZ_PATH_QUERY_H
#define QUARTZ_PATH_QUERY_H

#ifdef __cplusplus
extern "C" {
#endif

QZRect QZPathGetBoundingBox(QZPathRef path);
QZRect QZPathGetPathBoundingBox(QZPathRef path);
bool QZPathIsEmpty(QZPathRef path);
QZPoint QZPathGetCurrentPoint(QZPathRef path);
bool QZPathContainsPoint(QZPathRef path, const QZAffineTransform *m,
                         QZPoint point, bool even_odd);
QZPathRef QZPathCreateCopy(QZPathRef path);
QZPathRef QZPathCreateCopyByTransformingPath(QZPathRef path, const QZAffineTransform *m);
bool QZPathEqualToPath(QZPathRef a, QZPathRef b);

#ifdef __cplusplus
}
#endif
#endif
