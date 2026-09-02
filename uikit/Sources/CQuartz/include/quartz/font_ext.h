/* OWNED BY package font-ext. Do not edit from other packages. */
#ifndef QUARTZ_FONT_EXT_H
#define QUARTZ_FONT_EXT_H
#ifdef __cplusplus
extern "C" {
#endif

typedef struct QZFont *QZFontRef;
typedef unsigned short QZGlyph;

QZFontRef QZFontCreateWithFontName(const char *name, QZFloat size);
void QZFontRelease(QZFontRef font);
QZFloat QZFontGetSize(QZFontRef font);
QZFloat QZFontGetAscent(QZFontRef font);
QZFloat QZFontGetDescent(QZFontRef font);
QZFloat QZFontGetLeading(QZFontRef font);
QZFloat QZFontGetXHeight(QZFontRef font);
QZFloat QZFontGetCapHeight(QZFontRef font);
void QZFontGetGlyphsForCharacters(QZFontRef font, const char *bytes, size_t n, QZGlyph *out);
void QZFontGetGlyphAdvances(QZFontRef font, const QZGlyph *glyphs, size_t n, QZSize *advances);
QZRect QZFontGetGlyphBBox(QZFontRef font, QZGlyph glyph);

void QZContextSetFont(QZContextRef ctx, QZFontRef font);
void QZContextShowGlyphsAtPoint(QZContextRef ctx, QZFloat x, QZFloat y,
                                const QZGlyph *glyphs, size_t count);
void QZContextShowGlyphsWithAdvances(QZContextRef ctx, const QZGlyph *glyphs,
                                     const QZSize *advances, size_t count);

#ifdef __cplusplus
}
#endif
#endif
