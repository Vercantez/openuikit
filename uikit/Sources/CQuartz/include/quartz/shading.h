/* OWNED BY package shading. Do not edit from other packages. */
#ifndef QUARTZ_SHADING_H
#define QUARTZ_SHADING_H
#ifdef __cplusplus
extern "C" {
#endif

typedef struct QZFunction *QZFunctionRef;
typedef struct QZShading *QZShadingRef;

typedef void (*QZFunctionEvaluate)(void *info, const QZFloat *in, QZFloat *out);

QZFunctionRef QZFunctionCreate(void *info,
                               size_t domainDimension, const QZFloat *domain,
                               size_t rangeDimension, const QZFloat *range,
                               QZFunctionEvaluate evaluate);
void QZFunctionRelease(QZFunctionRef fn);

QZShadingRef QZShadingCreateAxial(QZPoint start, QZPoint end, QZFunctionRef function,
                                  bool extendStart, bool extendEnd);
QZShadingRef QZShadingCreateRadial(QZPoint startCenter, QZFloat startRadius,
                                   QZPoint endCenter, QZFloat endRadius,
                                   QZFunctionRef function,
                                   bool extendStart, bool extendEnd);
void QZShadingRelease(QZShadingRef shading);
void QZContextDrawShading(QZContextRef ctx, QZShadingRef shading);

#ifdef __cplusplus
}
#endif
#endif
