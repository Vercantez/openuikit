/* OWNED BY package text. Do not edit from other packages. */
#ifndef QUARTZ_TEXT_H
#define QUARTZ_TEXT_H
#ifdef __cplusplus
extern "C" {
#endif

void QZContextSelectFont(QZContextRef ctx, const char *name, QZFloat size);
void QZContextSetFontSize(QZContextRef ctx, QZFloat size);
void QZContextSetTextMatrix(QZContextRef ctx, QZAffineTransform t);
QZAffineTransform QZContextGetTextMatrix(QZContextRef ctx);
void QZContextSetTextPosition(QZContextRef ctx, QZFloat x, QZFloat y);
QZPoint QZContextGetTextPosition(QZContextRef ctx);
void QZContextShowText(QZContextRef ctx, const char *bytes, size_t length);
void QZContextShowTextAtPoint(QZContextRef ctx, QZFloat x, QZFloat y,
                              const char *bytes, size_t length);

/* Matches CGTextDrawingMode. */
typedef enum {
    kQZTextFill = 0,
    kQZTextStroke,
    kQZTextFillStroke,
    kQZTextInvisible,
    kQZTextFillClip,
    kQZTextStrokeClip,
    kQZTextFillStrokeClip,
    kQZTextClip
} QZTextDrawingMode;

void QZContextSetTextDrawingMode(QZContextRef ctx, QZTextDrawingMode mode);
QZTextDrawingMode QZContextGetTextDrawingMode(QZContextRef ctx);

QZLayerRef QZTextLayerCreate(void);
void QZTextLayerSetString(QZLayerRef layer, const char *utf8);
void QZTextLayerSetFontName(QZLayerRef layer, const char *name);
void QZTextLayerSetFontSize(QZLayerRef layer, QZFloat size);
void QZTextLayerSetForegroundColor(QZLayerRef layer, QZFloat r, QZFloat g, QZFloat b, QZFloat a);
void QZTextLayerSetAlignment(QZLayerRef layer, int align); /* 0 left, 1 center, 2 right */
void QZTextLayerSetWrapped(QZLayerRef layer, bool wrapped);

#ifdef __cplusplus
}
#endif
#endif
