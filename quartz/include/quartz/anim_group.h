/* OWNED BY package anim-group. */
#ifndef QUARTZ_ANIM_GROUP_H
#define QUARTZ_ANIM_GROUP_H
#ifdef __cplusplus
extern "C" {
#endif

QZAnimationRef QZAnimationGroupCreate(void);
void QZAnimationGroupAddAnimation(QZAnimationRef group, QZAnimationRef child);
QZAnimationRef QZSpringAnimationCreate(const char *keyPath);
void QZSpringAnimationSetDamping(QZAnimationRef anim, QZFloat damping);
void QZSpringAnimationSetMass(QZAnimationRef anim, QZFloat mass);
void QZSpringAnimationSetStiffness(QZAnimationRef anim, QZFloat stiffness);
void QZSpringAnimationSetInitialVelocity(QZAnimationRef anim, QZFloat v);

#ifdef __cplusplus
}
#endif
#endif
