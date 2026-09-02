/* OWNED BY package pattern. Do not edit from other packages. */
#ifndef QUARTZ_PATTERN_H
#define QUARTZ_PATTERN_H
#ifdef __cplusplus
extern "C" {
#endif

typedef struct QZPattern *QZPatternRef;

typedef enum {
    kQZPatternTilingNoDistortion = 0,
    kQZPatternTilingConstantSpacingMinimalDistortion = 1,
    kQZPatternTilingConstantSpacing = 2
} QZPatternTiling;

typedef void (*QZPatternDrawCallback)(void *info, QZContextRef ctx);

QZPatternRef QZPatternCreate(void *info, QZRect bounds, QZAffineTransform matrix,
                             QZFloat xStep, QZFloat yStep, QZPatternTiling tiling,
                             int isColored, QZPatternDrawCallback draw);
void QZPatternRelease(QZPatternRef pattern);
void QZContextSetFillPattern(QZContextRef ctx, QZPatternRef pattern,
                             const QZFloat *components, size_t ncomponents);
void QZContextSetStrokePattern(QZContextRef ctx, QZPatternRef pattern,
                               const QZFloat *components, size_t ncomponents);
void QZContextSetPatternPhase(QZContextRef ctx, QZSize phase);

#ifdef __cplusplus
}
#endif
#endif
