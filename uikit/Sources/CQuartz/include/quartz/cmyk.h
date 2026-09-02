/* OWNED BY package cmyk. Do not edit from other packages. */
#ifndef QUARTZ_CMYK_H
#define QUARTZ_CMYK_H
#ifdef __cplusplus
extern "C" {
#endif

QZColorSpaceRef QZColorSpaceCreateDeviceCMYK(void);
QZColorRef QZColorCreateGenericCMYK(QZFloat c, QZFloat m, QZFloat y, QZFloat k, QZFloat a);
void QZContextSetCMYKFillColor(QZContextRef ctx, QZFloat c, QZFloat m, QZFloat y, QZFloat k, QZFloat a);
void QZContextSetCMYKStrokeColor(QZContextRef ctx, QZFloat c, QZFloat m, QZFloat y, QZFloat k, QZFloat a);

#ifdef __cplusplus
}
#endif
#endif
