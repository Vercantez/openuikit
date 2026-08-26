/* OWNED BY package gradient-ext. */
#ifndef QUARTZ_GRADIENT_EXT_H
#define QUARTZ_GRADIENT_EXT_H
#ifdef __cplusplus
extern "C" {
#endif

void QZContextDrawConicGradient(QZContextRef ctx, QZGradientRef gradient,
                                QZPoint center, QZFloat angle, uint32_t options);
void QZGradientLayerSetConic(QZLayerRef layer, bool on);

#ifdef __cplusplus
}
#endif
#endif
