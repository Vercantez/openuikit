/* OWNED BY package color. Do not edit from other packages. */
#ifndef QUARTZ_COLOR_H
#define QUARTZ_COLOR_H

#ifdef __cplusplus
extern "C" {
#endif

typedef struct QZColor *QZColorRef;
typedef struct QZColorSpace *QZColorSpaceRef;

QZColorSpaceRef QZColorSpaceCreateDeviceRGB(void);
QZColorSpaceRef QZColorSpaceCreateDeviceGray(void);
QZColorSpaceRef QZColorSpaceCreateWithNameSRGB(void);
void QZColorSpaceRelease(QZColorSpaceRef space);

QZColorRef QZColorCreateGenericRGB(QZFloat r, QZFloat g, QZFloat b, QZFloat a);
QZColorRef QZColorCreate(QZColorSpaceRef space, const QZFloat *components);
QZColorRef QZColorRetain(QZColorRef color);
void QZColorRelease(QZColorRef color);
size_t QZColorGetNumberOfComponents(QZColorRef color);
const QZFloat *QZColorGetComponents(QZColorRef color);

void QZContextSetFillColorWithColor(QZContextRef ctx, QZColorRef color);
void QZContextSetStrokeColorWithColor(QZContextRef ctx, QZColorRef color);

#ifdef __cplusplus
}
#endif
#endif
