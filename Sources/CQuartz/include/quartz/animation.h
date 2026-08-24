/* OWNED BY package anim. */
#ifndef QUARTZ_ANIMATION_H
#define QUARTZ_ANIMATION_H
#ifdef __cplusplus
extern "C" {
#endif

typedef struct QZAnimation *QZAnimationRef;

QZAnimationRef QZBasicAnimationCreate(const char *keyPath);
void QZAnimationRelease(QZAnimationRef anim);
void QZBasicAnimationSetFromValue(QZAnimationRef anim, const QZFloat *v, size_t n);
void QZBasicAnimationSetToValue(QZAnimationRef anim, const QZFloat *v, size_t n);
void QZAnimationSetDuration(QZAnimationRef anim, QZFloat duration);
void QZLayerAddAnimation(QZLayerRef layer, QZAnimationRef anim, const char *key);
void QZLayerRemoveAllAnimations(QZLayerRef layer);
/* Snapshot one layer with animations applied at local time t (seconds).
 * Linear lerp of opacity, position, cornerRadius, bounds.size; t is clamped
 * to [0,1] via duration. The copy is shallow: sublayers/mask/contents are
 * pointer-shared with the model layer. Caller releases. */
QZLayerRef QZLayerCopyPresentation(QZLayerRef layer, QZFloat t);
/* Deep-copy the layer tree with each node's animations sampled at t.
 * Release with QZLayerReleasePresentationTree (not QZLayerRelease). */
QZLayerRef QZLayerCopyPresentationTree(QZLayerRef layer, QZFloat t);
void QZLayerReleasePresentationTree(QZLayerRef layer);

QZFloat QZLayerGetOpacity(QZLayerRef layer);
QZPoint QZLayerGetPosition(QZLayerRef layer);
QZRect  QZLayerGetBounds(QZLayerRef layer);
QZFloat QZLayerGetCornerRadius(QZLayerRef layer);

#ifdef __cplusplus
}
#endif
#endif
