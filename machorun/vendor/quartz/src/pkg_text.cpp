#include "qz_internal.hpp"

#include <cctype>
#include <cstdio>

#define STB_TRUETYPE_IMPLEMENTATION
#include "stb_truetype.h"

/* OWNED BY package text. */

namespace {

static const uint16_t kMacRoman[128] = {
    0x00C4, 0x00C5, 0x00C7, 0x00C9, 0x00D1, 0x00D6, 0x00DC, 0x00E1,
    0x00E0, 0x00E2, 0x00E4, 0x00E3, 0x00E5, 0x00E7, 0x00E9, 0x00E8,
    0x00EA, 0x00EB, 0x00ED, 0x00EC, 0x00EE, 0x00EF, 0x00F1, 0x00F3,
    0x00F2, 0x00F4, 0x00F6, 0x00F5, 0x00FA, 0x00F9, 0x00FB, 0x00FC,
    0x2020, 0x00B0, 0x00A2, 0x00A3, 0x00A7, 0x2022, 0x00B6, 0x00DF,
    0x00AE, 0x00A9, 0x2122, 0x00B4, 0x00A8, 0x2260, 0x00C6, 0x00D8,
    0x221E, 0x00B1, 0x2264, 0x2265, 0x00A5, 0x00B5, 0x2202, 0x2211,
    0x220F, 0x03C0, 0x222B, 0x00AA, 0x00BA, 0x03A9, 0x00E6, 0x00F8,
    0x00BF, 0x00A1, 0x00AC, 0x221A, 0x0192, 0x2248, 0x2206, 0x00AB,
    0x00BB, 0x2026, 0x00A0, 0x00C0, 0x00C3, 0x00D5, 0x0152, 0x0153,
    0x2013, 0x2014, 0x201C, 0x201D, 0x2018, 0x2019, 0x00F7, 0x25CA,
    0x00FF, 0x0178, 0x2044, 0x20AC, 0x2039, 0x203A, 0xFB01, 0xFB02,
    0x2021, 0x00B7, 0x201A, 0x201E, 0x2030, 0x00C2, 0x00CA, 0x00C1,
    0x00CB, 0x00C8, 0x00CD, 0x00CE, 0x00CF, 0x00CC, 0x00D3, 0x00D4,
    0xF8FF, 0x00D2, 0x00DA, 0x00DB, 0x00D9, 0x0131, 0x02C6, 0x02DC,
    0x00AF, 0x02D8, 0x02D9, 0x02DA, 0x00B8, 0x02DD, 0x02DB, 0x02C7,
};

static int macroman_cp(unsigned char b) {
    return b < 128 ? (int)b : (int)kMacRoman[b - 128];
}

static std::string lower_alnum(const char *s) {
    std::string o;
    if (!s) return o;
    for (const char *p = s; *p; p++) {
        unsigned char c = (unsigned char)*p;
        if (c == '-' || c == '_') c = ' ';
        if (std::isalpha(c) || std::isdigit(c) || c == ' ')
            o.push_back((char)std::tolower(c));
    }
    /* collapse spaces */
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

struct FontRec {
    std::vector<unsigned char> bytes;
    stbtt_fontinfo info{};
    std::string key;
    bool ok = false;
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

enum class BytesKind { MacRoman, Utf8 };

static double walk_string(QZContext *ctx, const FontRec &f, const char *bytes, size_t length,
                          double size, double origin_x, double origin_y, BytesKind kind,
                          bool emit) {
    if (!f.ok || !bytes || length == 0 || size <= 0) return 0;
    double scale = font_scale(f, size);
    double pen = 0;
    size_t i = 0;
    while (i < length) {
        int cp = 0;
        if (kind == BytesKind::MacRoman) {
            cp = macroman_cp((unsigned char)bytes[i++]);
        } else {
            unsigned char b = (unsigned char)bytes[i++];
            if (b < 0x80) {
                cp = b;
            } else if ((b & 0xE0) == 0xC0 && i < length) {
                cp = ((b & 0x1F) << 6) | ((unsigned char)bytes[i++] & 0x3F);
            } else if ((b & 0xF0) == 0xE0 && i + 1 < length) {
                cp = ((b & 0x0F) << 12) |
                     (((unsigned char)bytes[i] & 0x3F) << 6) |
                     ((unsigned char)bytes[i + 1] & 0x3F);
                i += 2;
            } else if ((b & 0xF8) == 0xF0 && i + 2 < length) {
                cp = ((b & 0x07) << 18) |
                     (((unsigned char)bytes[i] & 0x3F) << 12) |
                     (((unsigned char)bytes[i + 1] & 0x3F) << 6) |
                     ((unsigned char)bytes[i + 2] & 0x3F);
                i += 3;
            } else {
                cp = 0xFFFD;
            }
        }
        int glyph = stbtt_FindGlyphIndex(&f.info, cp);
        if (emit) append_glyph(ctx, f, glyph, origin_x + pen, origin_y, scale);
        int adv = 0, lsb = 0;
        stbtt_GetGlyphHMetrics(&f.info, glyph, &adv, &lsb);
        pen += (double)adv * scale;
    }
    return pen;
}

static double measure_macroman(const FontRec &f, const char *bytes, size_t length, double size) {
    return walk_string(nullptr, f, bytes, length, size, 0, 0, BytesKind::MacRoman, false);
}

static void sync_text_pos(QZContext *ctx) {
    ctx->gs.text_position.x = ctx->gs.text_matrix.tx;
    ctx->gs.text_position.y = ctx->gs.text_matrix.ty;
}

/* Honor GState.text_drawing_mode (CGTextDrawingMode integers). */
static void apply_text_drawing_mode(QZContext *ctx) {
    int mode = ctx->gs.text_drawing_mode;
    bool do_fill = (mode == kQZTextFill || mode == kQZTextFillStroke ||
                    mode == kQZTextFillClip || mode == kQZTextFillStrokeClip);
    bool do_stroke = (mode == kQZTextStroke || mode == kQZTextFillStroke ||
                      mode == kQZTextStrokeClip || mode == kQZTextFillStrokeClip);
    bool clip_fill = (mode == kQZTextClip || mode == kQZTextFillClip ||
                      mode == kQZTextFillStrokeClip);
    bool clip_stroke = (mode == kQZTextStrokeClip || mode == kQZTextFillStrokeClip);
    if (mode == kQZTextInvisible) return;

    qz::Path glyphs = ctx->path;
    if (do_fill) {
        ctx->path = glyphs;
        QZContextFillPath(ctx);
    }
    if (do_stroke) {
        ctx->path = glyphs;
        QZContextStrokePath(ctx);
    }
    if (clip_fill && clip_stroke) {
        std::vector<uint8_t> clip0 = ctx->gs.clip;
        ctx->path = glyphs;
        QZContextClip(ctx);
        std::vector<uint8_t> clip_f = ctx->gs.clip;
        ctx->gs.clip = std::move(clip0);
        ctx->path = glyphs;
        QZContextReplacePathWithStrokedPath(ctx);
        QZContextClip(ctx);
        size_t n = std::min(clip_f.size(), ctx->gs.clip.size());
        for (size_t i = 0; i < n; i++) {
            if (clip_f[i] > ctx->gs.clip[i]) ctx->gs.clip[i] = clip_f[i];
        }
    } else if (clip_stroke) {
        ctx->path = glyphs;
        QZContextReplacePathWithStrokedPath(ctx);
        QZContextClip(ctx);
    } else if (clip_fill) {
        ctx->path = glyphs;
        QZContextClip(ctx);
    }
}

} /* namespace */

void QZContextSetTextDrawingMode(QZContextRef ctx, QZTextDrawingMode mode) {
    if (ctx) ctx->gs.text_drawing_mode = (int)mode;
}

QZTextDrawingMode QZContextGetTextDrawingMode(QZContextRef ctx) {
    return ctx ? (QZTextDrawingMode)ctx->gs.text_drawing_mode : kQZTextFill;
}

QZLayerRef QZTextLayerCreate(void) {
    auto *l = new QZLayer();
    l->kind = QZLayerKindInternal::Text;
    return l;
}

void QZContextSelectFont(QZContextRef ctx, const char *name, QZFloat size) {
    if (!ctx) return;
    if (name) {
        std::snprintf(ctx->gs.font_name, sizeof(ctx->gs.font_name), "%s", name);
    }
    ctx->gs.font_size = size > 0 ? (double)size : 12;
}

void QZContextSetFontSize(QZContextRef ctx, QZFloat size) {
    if (ctx) ctx->gs.font_size = size > 0 ? (double)size : 12;
}

void QZContextSetTextMatrix(QZContextRef ctx, QZAffineTransform t) {
    if (!ctx) return;
    ctx->gs.text_matrix = t;
    sync_text_pos(ctx);
}

QZAffineTransform QZContextGetTextMatrix(QZContextRef ctx) {
    return ctx ? ctx->gs.text_matrix : QZAffineTransformIdentity();
}

void QZContextSetTextPosition(QZContextRef ctx, QZFloat x, QZFloat y) {
    if (!ctx) return;
    ctx->gs.text_matrix.tx = x;
    ctx->gs.text_matrix.ty = y;
    sync_text_pos(ctx);
}

QZPoint QZContextGetTextPosition(QZContextRef ctx) {
    if (!ctx) return QZPointMake(0, 0);
    return QZPointMake(ctx->gs.text_matrix.tx, ctx->gs.text_matrix.ty);
}

void QZContextShowText(QZContextRef ctx, const char *bytes, size_t length) {
    if (!ctx) return;
    FontRec &font = cached_font(ctx->gs.font_name);
    double size = ctx->gs.font_size;
    double width = measure_macroman(font, bytes, length, size);
    if (font.ok && bytes && length > 0 && size > 0) {
        qz::Path saved_path = ctx->path;
        QZAffineTransform saved_ctm = ctx->gs.ctm;
        QZContextConcatCTM(ctx, ctx->gs.text_matrix);
        QZContextBeginPath(ctx);
        walk_string(ctx, font, bytes, length, size, 0, 0, BytesKind::MacRoman, true);
        apply_text_drawing_mode(ctx);
        ctx->gs.ctm = saved_ctm;
        ctx->path = std::move(saved_path);
    }
    /* Advance in text space, then through the linear part of the text matrix. */
    ctx->gs.text_matrix.tx += ctx->gs.text_matrix.a * width;
    ctx->gs.text_matrix.ty += ctx->gs.text_matrix.b * width;
    sync_text_pos(ctx);
}

void QZContextShowTextAtPoint(QZContextRef ctx, QZFloat x, QZFloat y,
                              const char *bytes, size_t length) {
    if (!ctx) return;
    QZContextSetTextPosition(ctx, x, y);
    QZContextShowText(ctx, bytes, length);
}

void QZTextLayerSetString(QZLayerRef layer, const char *utf8) {
    if (layer) layer->text = utf8 ? utf8 : "";
}
void QZTextLayerSetFontName(QZLayerRef layer, const char *name) {
    if (layer) layer->text_font = name ? name : "Helvetica";
}
void QZTextLayerSetFontSize(QZLayerRef layer, QZFloat size) {
    if (layer) layer->text_font_size = size > 0 ? (double)size : 36;
}
void QZTextLayerSetForegroundColor(QZLayerRef layer, QZFloat r, QZFloat g, QZFloat b, QZFloat a) {
    if (layer) layer->text_color = {r, g, b, a};
}
void QZTextLayerSetAlignment(QZLayerRef layer, int align) {
    if (layer) layer->text_align = align;
}
void QZTextLayerSetWrapped(QZLayerRef layer, bool wrapped) {
    if (layer) layer->text_wrapped = wrapped;
}

void qz_pkg_paint_text_layer(QZLayer *layer, QZContext *ctx) {
    if (!layer || !ctx || layer->text.empty()) return;
    FontRec &font = cached_font(layer->text_font.c_str());
    if (!font.ok) return;
    double size = layer->text_font_size > 0 ? layer->text_font_size : 36;
    const std::string &s = layer->text;
    double width = walk_string(nullptr, font, s.c_str(), s.size(), size, 0, 0,
                               BytesKind::Utf8, false);
    QZRect b = layer->bounds;
    double x = b.origin.x;
    if (layer->text_align == 1)
        x += (b.size.width - width) * 0.5;
    else if (layer->text_align == 2)
        x += b.size.width - width;
    /* CATextLayer places the em-square flush with the top of the bounds:
       baseline = origin.y + height - fontSize (y-up). */
    double y = b.origin.y + b.size.height - size;

    QZContextSaveGState(ctx);
    QZContextSetRGBFillColor(ctx, layer->text_color.r, layer->text_color.g,
                             layer->text_color.b, layer->text_color.a);
    QZContextBeginPath(ctx);
    walk_string(ctx, font, s.c_str(), s.size(), size, x, y, BytesKind::Utf8, true);
    QZContextFillPath(ctx);
    QZContextRestoreGState(ctx);
}
