/* OWNED BY package color-p3. */
#ifndef QUARTZ_COLOR_P3_H
#define QUARTZ_COLOR_P3_H
#ifdef __cplusplus
extern "C" {
#endif

QZColorSpaceRef QZColorSpaceCreateDisplayP3(void);
QZColorRef QZColorCreateGenericP3(QZFloat r, QZFloat g, QZFloat b, QZFloat a);
void QZContextSetFillColorSpace(QZContextRef ctx, QZColorSpaceRef space);
void QZContextSetFillColor(QZContextRef ctx, const QZFloat *components);

#ifdef __cplusplus
}
#endif
#endif
