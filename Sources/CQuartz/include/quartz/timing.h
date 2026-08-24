/* OWNED BY package timing. Do not edit from other packages. */
#ifndef QUARTZ_TIMING_H
#define QUARTZ_TIMING_H
#ifdef __cplusplus
extern "C" {
#endif

typedef struct QZMediaTimingFunction *QZMediaTimingFunctionRef;

QZMediaTimingFunctionRef QZMediaTimingFunctionCreate(const char *name);
QZMediaTimingFunctionRef QZMediaTimingFunctionCreateWithControlPoints(
    QZFloat c1x, QZFloat c1y, QZFloat c2x, QZFloat c2y);
void QZMediaTimingFunctionRelease(QZMediaTimingFunctionRef fn);
void QZMediaTimingFunctionGetControlPoint(QZMediaTimingFunctionRef fn, int index,
                                          QZFloat out[2]);
QZFloat QZMediaTimingFunctionSolve(QZMediaTimingFunctionRef fn, QZFloat t);
void QZAnimationSetTimingFunction(QZAnimationRef anim, QZMediaTimingFunctionRef fn);

QZAnimationRef QZKeyframeAnimationCreate(const char *keyPath);
void QZKeyframeAnimationSetValues(QZAnimationRef anim, const QZFloat *values,
                                  size_t nvalues, size_t stride);
void QZKeyframeAnimationSetKeyTimes(QZAnimationRef anim, const QZFloat *times, size_t n);

#ifdef __cplusplus
}
#endif
#endif
