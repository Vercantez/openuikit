#include "qz_internal.hpp"

#include <cctype>
#include <cstdio>

#include "stb_truetype.h"

/* OWNED BY package font-ext. */

namespace {

static std::string lower_alnum(const char *s) {
    std::string o;
    if (!s) return o;
    for (const char *p = s; *p; p++) {
        unsigned char c = (unsigned char)*p;
        if (c == '-' || c == '_') c = ' ';
        if (std::isalpha(c) || std::isdigit(c) || c == ' ')
            o.push_back((char)std::tolower(c));
    }
    std::string r;
    bool sp = false;
    for (char c : o) {
        if (c == ' ') {
            if (!r.empty() && !sp) r.push_back(' ');
            sp = true;
        } else {
            r.push_back(c);
            sp = false;
        }
    }
    return r;
}

static std::string utf16be_ascii(const char *p, int len) {
    std::string s;
    for (int i = 0; i + 1 < len; i += 2) {
        unsigned c = ((unsigned char)p[i] << 8) | (unsigned char)p[i + 1];
        if (c >= 32 && c < 127) s.push_back((char)c);
    }
    return s;
}

static bool read_all(const char *path, std::vector<unsigned char> &out) {
    FILE *fp = std::fopen(path, "rb");
    if (!fp) return false;
    if (std::fseek(fp, 0, SEEK_END) != 0) {
        std::fclose(fp);
        return false;
    }
    long n = std::ftell(fp);
    if (n <= 0) {
        std::fclose(fp);
        return false;
    }
    std::rewind(fp);
    out.resize((size_t)n);
    size_t rd = std::fread(out.data(), 1, (size_t)n, fp);
    std::fclose(fp);
    return rd == (size_t)n;
}

static int find_table(const unsigned char *data, int fontstart, const char *tag) {
    if (!data || !tag) return 0;
    int num_tables = (data[fontstart + 4] << 8) | data[fontstart + 5];
    int rec = fontstart + 12;
    for (int i = 0; i < num_tables; i++, rec += 16) {
        if (data[rec] == (unsigned char)tag[0] && data[rec + 1] == (unsigned char)tag[1] &&
            data[rec + 2] == (unsigned char)tag[2] && data[rec + 3] == (unsigned char)tag[3]) {
            return (data[rec + 8] << 24) | (data[rec + 9] << 16) | (data[rec + 10] << 8) |
                   data[rec + 11];
        }
    }
    return 0;
}

static int16_t be_i16(const unsigned char *p) {
    return (int16_t)((p[0] << 8) | p[1]);
}

struct FontRec {
    std::vector<unsigned char> bytes;
    stbtt_fontinfo info{};
    std::string key;
    bool ok = false;
    int ascent_u = 0;
    int descent_u = 0; /* typically negative hhea descender */
    int leading_u = 0;
    int cap_u = 0;
    int xh_u = 0;
    std::vector<int> glyph_to_ascii; /* 0 = unmapped */
};

static const char *kFontFiles[] = {
    "/System/Library/Fonts/Helvetica.ttc",
    "/System/Library/Fonts/Supplemental/Helvetica.ttf",
    "/Library/Fonts/Helvetica.ttf",
    "/System/Library/Fonts/Supplemental/Helvetica.ttc",
    "/System/Library/Fonts/Supplemental/Arial.ttf",
    "/Library/Fonts/Arial.ttf",
    "/System/Library/Fonts/Geneva.ttf",
    nullptr,
};

static int pick_ttc_index(const unsigned char *data, const std::string &want) {
    int n = stbtt_GetNumberOfFonts(data);
    if (n < 1) n = 1;
    int fallback = 0;
    for (int i = 0; i < n; i++) {
        stbtt_fontinfo tmp;
        int off = stbtt_GetFontOffsetForIndex(data, i);
        if (off < 0 || !stbtt_InitFont(&tmp, data, off)) continue;
        int ids[] = {6, 4, 1}; /* PS, full, family */
        for (int id : ids) {
            int len = 0;
            const char *nm = stbtt_GetFontNameString(
                &tmp, &len, STBTT_PLATFORM_ID_MAC, STBTT_MAC_EID_ROMAN,
                STBTT_MAC_LANG_ENGLISH, id);
            if (nm && len > 0 && lower_alnum(std::string(nm, nm + len).c_str()) == want)
                return i;
            nm = stbtt_GetFontNameString(
                &tmp, &len, STBTT_PLATFORM_ID_MICROSOFT, STBTT_MS_EID_UNICODE_BMP,
                STBTT_MS_LANG_ENGLISH, id);
            if (nm && len > 0 && lower_alnum(utf16be_ascii(nm, len).c_str()) == want)
                return i;
        }
        if (i == 0) fallback = 0;
    }
    return fallback;
}

static void finish_metrics(FontRec &rec) {
    stbtt_GetFontVMetrics(&rec.info, &rec.ascent_u, &rec.descent_u, &rec.leading_u);

    int x0 = 0, y0 = 0, x1 = 0, y1 = 0;
    if (stbtt_GetCodepointBox(&rec.info, 'H', &x0, &y0, &x1, &y1)) rec.cap_u = y1;
    if (stbtt_GetCodepointBox(&rec.info, 'x', &x0, &y0, &x1, &y1)) rec.xh_u = y1;

    int os2 = find_table(rec.bytes.data(), rec.info.fontstart, "OS/2");
    if (os2) {
        unsigned ver = (unsigned)((rec.bytes[os2] << 8) | rec.bytes[os2 + 1]);
        if (ver >= 2) {
            rec.xh_u = be_i16(&rec.bytes[os2 + 86]);
            rec.cap_u = be_i16(&rec.bytes[os2 + 88]);
        }
    }

    int n = rec.info.numGlyphs;
    if (n < 1) n = 1;
    rec.glyph_to_ascii.assign((size_t)n, 0);
    for (int c = 0; c < 128; c++) {
        int g = stbtt_FindGlyphIndex(&rec.info, c);
        if (g >= 0 && g < n) rec.glyph_to_ascii[(size_t)g] = c;
    }
}

static FontRec &cached_font(const char *name) {
    static FontRec rec;
    std::string key = lower_alnum(name && name[0] ? name : "helvetica");
    if (rec.ok && rec.key == key) return rec;

    rec = FontRec{};
    rec.key = key;

    bool want_arial = key.find("arial") != std::string::npos;
    for (int pass = 0; pass < 2 && !rec.ok; pass++) {
        for (int i = 0; kFontFiles[i]; i++) {
            const char *path = kFontFiles[i];
            bool is_arial = std::strstr(path, "Arial") != nullptr;
            if (pass == 0 && want_arial != is_arial) continue;
            if (pass == 1 && want_arial == is_arial) continue;
            if (!read_all(path, rec.bytes)) continue;
            int idx = pick_ttc_index(rec.bytes.data(), key);
            int off = stbtt_GetFontOffsetForIndex(rec.bytes.data(), idx);
            if (off < 0) off = 0;
            if (stbtt_InitFont(&rec.info, rec.bytes.data(), off)) {
                rec.ok = true;
                finish_metrics(rec);
                break;
            }
            rec.bytes.clear();
        }
    }
    return rec;
}

static double font_scale(const FontRec &f, double size) {
    if (!f.ok || size <= 0) return 0;
    return (double)stbtt_ScaleForMappingEmToPixels(&f.info, (float)size);
}

static void append_glyph(QZContext *ctx, const FontRec &f, int glyph,
                         double x, double y, double scale) {
    stbtt_vertex *verts = nullptr;
    int n = stbtt_GetGlyphShape(&f.info, glyph, &verts);
    bool open = false;
    for (int i = 0; i < n; i++) {
        const stbtt_vertex &v = verts[i];
        double px = x + (double)v.x * scale;
        double py = y + (double)v.y * scale;
        double cx = x + (double)v.cx * scale;
        double cy = y + (double)v.cy * scale;
        double cx1 = x + (double)v.cx1 * scale;
        double cy1 = y + (double)v.cy1 * scale;
        switch (v.type) {
        case STBTT_vmove:
            if (open) QZContextClosePath(ctx);
            QZContextMoveToPoint(ctx, px, py);
            open = true;
            break;
        case STBTT_vline:
            QZContextAddLineToPoint(ctx, px, py);
            break;
        case STBTT_vcurve:
            QZContextAddQuadCurveToPoint(ctx, cx, cy, px, py);
            break;
        case STBTT_vcubic:
            QZContextAddCurveToPoint(ctx, cx, cy, cx1, cy1, px, py);
            break;
        default:
            break;
        }
    }
    if (open) QZContextClosePath(ctx);
    stbtt_FreeShape(&f.info, verts);
}

static void sync_text_pos(QZContext *ctx) {
    ctx->gs.text_position.x = ctx->gs.text_matrix.tx;
    ctx->gs.text_position.y = ctx->gs.text_matrix.ty;
}

} /* namespace */

struct QZFont {
    std::string name = "Helvetica";
    QZFloat size = 12;
};

QZFontRef QZFontCreateWithFontName(const char *name, QZFloat size) {
    auto *f = new QZFont();
    if (name) f->name = name;
    f->size = size > 0 ? size : 12;
    (void)cached_font(f->name.c_str());
    return f;
}
void QZFontRelease(QZFontRef font) { delete font; }
QZFloat QZFontGetSize(QZFontRef font) { return font ? font->size : 0; }

QZFloat QZFontGetAscent(QZFontRef font) {
    if (!font) return 0;
    FontRec &f = cached_font(font->name.c_str());
    return (QZFloat)(f.ascent_u * font_scale(f, font->size));
}
QZFloat QZFontGetDescent(QZFontRef font) {
    if (!font) return 0;
    FontRec &f = cached_font(font->name.c_str());
    /* CTFontGetDescent is the magnitude below the baseline. */
    return (QZFloat)(std::fabs((double)f.descent_u) * font_scale(f, font->size));
}
QZFloat QZFontGetLeading(QZFontRef font) {
    if (!font) return 0;
    FontRec &f = cached_font(font->name.c_str());
    return (QZFloat)(f.leading_u * font_scale(f, font->size));
}
QZFloat QZFontGetXHeight(QZFontRef font) {
    if (!font) return 0;
    FontRec &f = cached_font(font->name.c_str());
    return (QZFloat)(f.xh_u * font_scale(f, font->size));
}
QZFloat QZFontGetCapHeight(QZFontRef font) {
    if (!font) return 0;
    FontRec &f = cached_font(font->name.c_str());
    return (QZFloat)(f.cap_u * font_scale(f, font->size));
}

void QZFontGetGlyphsForCharacters(QZFontRef font, const char *bytes, size_t n, QZGlyph *out) {
    if (!bytes || !out) return;
    FontRec &f = cached_font(font ? font->name.c_str() : "Helvetica");
    for (size_t i = 0; i < n; i++) {
        unsigned char b = (unsigned char)bytes[i];
        int g = f.ok ? stbtt_FindGlyphIndex(&f.info, (int)b) : (int)b;
        out[i] = (QZGlyph)g;
    }
}

void QZFontGetGlyphAdvances(QZFontRef font, const QZGlyph *glyphs, size_t n, QZSize *advances) {
    if (!advances) return;
    FontRec &f = cached_font(font ? font->name.c_str() : "Helvetica");
    double scale = font ? font_scale(f, font->size) : 0;
    for (size_t i = 0; i < n; i++) {
        int adv = 0, lsb = 0;
        if (f.ok && glyphs) stbtt_GetGlyphHMetrics(&f.info, (int)glyphs[i], &adv, &lsb);
        advances[i] = QZSizeMake((QZFloat)(adv * scale), 0);
    }
}

QZRect QZFontGetGlyphBBox(QZFontRef font, QZGlyph glyph) {
    FontRec &f = cached_font(font ? font->name.c_str() : "Helvetica");
    double scale = font ? font_scale(f, font->size) : 0;
    int x0 = 0, y0 = 0, x1 = 0, y1 = 0;
    if (!f.ok || !stbtt_GetGlyphBox(&f.info, (int)glyph, &x0, &y0, &x1, &y1))
        return QZRectMake(0, 0, 0, 0);
    return QZRectMake((QZFloat)(x0 * scale), (QZFloat)(y0 * scale),
                      (QZFloat)((x1 - x0) * scale), (QZFloat)((y1 - y0) * scale));
}

void QZContextSetFont(QZContextRef ctx, QZFontRef font) {
    if (!ctx || !font) return;
    QZContextSelectFont(ctx, font->name.c_str(), font->size);
}

void QZContextShowGlyphsAtPoint(QZContextRef ctx, QZFloat x, QZFloat y,
                                const QZGlyph *glyphs, size_t count) {
    if (!ctx) return;
    QZContextSetTextPosition(ctx, x, y);
    if (!glyphs || count == 0) return;

    FontRec &f = cached_font(ctx->gs.font_name);
    double size = ctx->gs.font_size;
    if (!f.ok || size <= 0) return;
    double scale = font_scale(f, size);

    /* ASCII glyphs can reuse ShowText (already pixel-matches Apple). */
    bool all_ascii = true;
    std::string ascii;
    ascii.resize(count);
    for (size_t i = 0; i < count; i++) {
        int g = (int)glyphs[i];
        int ch = 0;
        if (g >= 0 && g < (int)f.glyph_to_ascii.size()) ch = f.glyph_to_ascii[(size_t)g];
        if (ch <= 0) {
            all_ascii = false;
            break;
        }
        ascii[i] = (char)ch;
    }
    if (all_ascii) {
        QZContextShowTextAtPoint(ctx, x, y, ascii.c_str(), ascii.size());
        return;
    }

    double width = 0;
    QZContextSaveGState(ctx);
    QZContextConcatCTM(ctx, ctx->gs.text_matrix);
    QZContextBeginPath(ctx);
    double pen = 0;
    for (size_t i = 0; i < count; i++) {
        append_glyph(ctx, f, (int)glyphs[i], pen, 0, scale);
        int adv = 0, lsb = 0;
        stbtt_GetGlyphHMetrics(&f.info, (int)glyphs[i], &adv, &lsb);
        double w = (double)adv * scale;
        pen += w;
        width += w;
    }
    QZContextFillPath(ctx);
    QZContextRestoreGState(ctx);
    ctx->gs.text_matrix.tx += ctx->gs.text_matrix.a * width;
    ctx->gs.text_matrix.ty += ctx->gs.text_matrix.b * width;
    sync_text_pos(ctx);
}

void QZContextShowGlyphsWithAdvances(QZContextRef ctx, const QZGlyph *glyphs,
                                     const QZSize *advances, size_t count) {
    if (!ctx || !glyphs || !advances || count == 0) return;
    /* Advances are user-space deltas added to the current text position. */
    QZPoint p = QZContextGetTextPosition(ctx);
    for (size_t i = 0; i < count; i++) {
        QZContextShowGlyphsAtPoint(ctx, p.x, p.y, &glyphs[i], 1);
        p.x += advances[i].width;
        p.y += advances[i].height;
        QZContextSetTextPosition(ctx, p.x, p.y);
    }
}
