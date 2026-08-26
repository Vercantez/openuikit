#include "qz_internal.hpp"
/* OWNED BY package pdf. */

#include <cctype>
#include <cstdio>
#include <cstdlib>
#include <unordered_map>

using namespace qz;

struct PDFPageRec {
    QZRect box{{0, 0}, {0, 0}};
    std::string content;
};

struct PDFWriter {
    std::string path;
    QZRect mediaBox{{0, 0}, {0, 0}};
    std::string content;
    std::vector<PDFPageRec> pages;
    bool pageOpen = false;
};

struct QZPDFPage {
    QZRect box{{0, 0}, {0, 0}};
    std::string content;
};

struct QZPDFDocument {
    std::vector<QZPDFPage> pages;
};

static std::unordered_map<QZContext *, PDFWriter> g_writers;

static PDFWriter *writer_of(QZContextRef ctx) {
    if (!ctx) return nullptr;
    auto it = g_writers.find(ctx);
    return it == g_writers.end() ? nullptr : &it->second;
}

static void append_num(std::string &o, double v) {
    if (!std::isfinite(v)) v = 0;
    char buf[64];
    snprintf(buf, sizeof(buf), "%.6f", v);
    char *dot = strchr(buf, '.');
    if (dot) {
        char *end = buf + strlen(buf);
        while (end > dot + 1 && end[-1] == '0') *--end = 0;
        if (end > buf && end[-1] == '.') *--end = 0;
    }
    o += buf;
}

static void emit(PDFWriter *w, const char *op) {
    if (!w || !w->pageOpen) return;
    w->content += op;
    w->content += '\n';
}

static void emit(PDFWriter *w, double a, const char *op) {
    if (!w || !w->pageOpen) return;
    append_num(w->content, a);
    w->content += ' ';
    w->content += op;
    w->content += '\n';
}

static void emit(PDFWriter *w, double a, double b, const char *op) {
    if (!w || !w->pageOpen) return;
    append_num(w->content, a);
    w->content += ' ';
    append_num(w->content, b);
    w->content += ' ';
    w->content += op;
    w->content += '\n';
}

static void emit(PDFWriter *w, double a, double b, double c, const char *op) {
    if (!w || !w->pageOpen) return;
    append_num(w->content, a);
    w->content += ' ';
    append_num(w->content, b);
    w->content += ' ';
    append_num(w->content, c);
    w->content += ' ';
    w->content += op;
    w->content += '\n';
}

static void emit(PDFWriter *w, double a, double b, double c, double d, const char *op) {
    if (!w || !w->pageOpen) return;
    append_num(w->content, a);
    w->content += ' ';
    append_num(w->content, b);
    w->content += ' ';
    append_num(w->content, c);
    w->content += ' ';
    append_num(w->content, d);
    w->content += ' ';
    w->content += op;
    w->content += '\n';
}

static void emit6(PDFWriter *w, double a, double b, double c, double d, double e, double f,
                  const char *op) {
    if (!w || !w->pageOpen) return;
    append_num(w->content, a);
    w->content += ' ';
    append_num(w->content, b);
    w->content += ' ';
    append_num(w->content, c);
    w->content += ' ';
    append_num(w->content, d);
    w->content += ' ';
    append_num(w->content, e);
    w->content += ' ';
    append_num(w->content, f);
    w->content += ' ';
    w->content += op;
    w->content += '\n';
}

static size_t media_w(QZRect box) {
    size_t w = (size_t)std::ceil(std::fabs(box.size.width));
    return w < 1 ? 1 : w;
}
static size_t media_h(QZRect box) {
    size_t h = (size_t)std::ceil(std::fabs(box.size.height));
    return h < 1 ? 1 : h;
}

static void end_page_unlocked(PDFWriter *w) {
    if (!w || !w->pageOpen) return;
    PDFPageRec rec;
    rec.box = w->mediaBox;
    rec.content = w->content;
    w->pages.push_back(std::move(rec));
    w->content.clear();
    w->pageOpen = false;
}

static bool write_pdf_file(PDFWriter *w) {
    if (!w || w->path.empty()) return false;
    if (w->pageOpen) end_page_unlocked(w);
    if (w->pages.empty()) {
        PDFPageRec rec;
        rec.box = w->mediaBox;
        w->pages.push_back(std::move(rec));
    }

    const int n = (int)w->pages.size();
    /* objs: 1 Catalog, 2 Pages, then (Page, Contents) per page. Size = 3 + 2n */
    const int nobj = 3 + 2 * n;
    std::vector<size_t> off((size_t)nobj, 0);
    std::string pdf;
    pdf += "%PDF-1.4\n%\xE2\xE3\xCF\xD3\n";

    off[1] = pdf.size();
    pdf += "1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n";

    off[2] = pdf.size();
    pdf += "2 0 obj\n<< /Type /Pages /Count ";
    {
        char buf[32];
        snprintf(buf, sizeof(buf), "%d", n);
        pdf += buf;
    }
    pdf += " /Kids [";
    for (int i = 0; i < n; i++) {
        char buf[32];
        snprintf(buf, sizeof(buf), "%s%d 0 R", i ? " " : "", 3 + 2 * i);
        pdf += buf;
    }
    pdf += "] >>\nendobj\n";

    for (int i = 0; i < n; i++) {
        const PDFPageRec &pg = w->pages[(size_t)i];
        int pageObj = 3 + 2 * i;
        int contObj = 4 + 2 * i;
        double x0 = pg.box.origin.x;
        double y0 = pg.box.origin.y;
        double x1 = x0 + pg.box.size.width;
        double y1 = y0 + pg.box.size.height;

        off[(size_t)pageObj] = pdf.size();
        pdf += std::to_string(pageObj);
        pdf += " 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [";
        append_num(pdf, x0);
        pdf += ' ';
        append_num(pdf, y0);
        pdf += ' ';
        append_num(pdf, x1);
        pdf += ' ';
        append_num(pdf, y1);
        pdf += "] /Contents ";
        pdf += std::to_string(contObj);
        pdf += " 0 R /Resources << /ProcSet [/PDF] >> >>\nendobj\n";

        off[(size_t)contObj] = pdf.size();
        pdf += std::to_string(contObj);
        pdf += " 0 obj\n<< /Length ";
        pdf += std::to_string(pg.content.size());
        pdf += " >>\nstream\n";
        pdf += pg.content;
        pdf += "endstream\nendobj\n";
    }

    size_t xref = pdf.size();
    {
        char buf[64];
        snprintf(buf, sizeof(buf), "xref\n0 %d\n", nobj);
        pdf += buf;
    }
    pdf += "0000000000 65535 f \n";
    for (int i = 1; i < nobj; i++) {
        char buf[32];
        snprintf(buf, sizeof(buf), "%010zu 00000 n \n", off[(size_t)i]);
        pdf += buf;
    }
    {
        char buf[96];
        snprintf(buf, sizeof(buf), "trailer\n<< /Size %d /Root 1 0 R >>\nstartxref\n%zu\n",
                 nobj, xref);
        pdf += buf;
    }
    pdf += "%%EOF\n";

    FILE *fp = fopen(w->path.c_str(), "wb");
    if (!fp) return false;
    size_t nw = fwrite(pdf.data(), 1, pdf.size(), fp);
    fclose(fp);
    return nw == pdf.size();
}

QZContextRef QZPDFContextCreate(const char *path, QZRect mediaBox) {
    if (!path || !path[0]) return nullptr;
    size_t w = media_w(mediaBox);
    size_t h = media_h(mediaBox);
    QZContextRef ctx = QZBitmapContextCreate(nullptr, w, h, 8, w * 4,
                                             kQZImageAlphaPremultipliedLast);
    if (!ctx) return nullptr;
    PDFWriter rec;
    rec.path = path;
    rec.mediaBox = mediaBox;
    rec.pageOpen = true;
    g_writers[ctx] = std::move(rec);
    return ctx;
}

void QZPDFContextBeginPage(QZContextRef ctx, const QZRect *mediaBox) {
    PDFWriter *w = writer_of(ctx);
    if (!w) return;
    if (w->pageOpen) end_page_unlocked(w);
    if (mediaBox) w->mediaBox = *mediaBox;
    w->content.clear();
    w->pageOpen = true;
}

void QZPDFContextEndPage(QZContextRef ctx) {
    end_page_unlocked(writer_of(ctx));
}

void QZPDFContextClose(QZContextRef ctx) {
    PDFWriter *w = writer_of(ctx);
    if (!w) return;
    write_pdf_file(w);
    g_writers.erase(ctx);
}

void QZPDFContextSetRGBFillColor(QZContextRef ctx, QZFloat r, QZFloat g, QZFloat b, QZFloat a) {
    QZContextSetRGBFillColor(ctx, r, g, b, a);
    emit(writer_of(ctx), r, g, b, "rg");
}

void QZPDFContextSetRGBStrokeColor(QZContextRef ctx, QZFloat r, QZFloat g, QZFloat b, QZFloat a) {
    QZContextSetRGBStrokeColor(ctx, r, g, b, a);
    emit(writer_of(ctx), r, g, b, "RG");
}

void QZPDFContextSetLineWidth(QZContextRef ctx, QZFloat width) {
    QZContextSetLineWidth(ctx, width);
    emit(writer_of(ctx), width, "w");
}

void QZPDFContextFillRect(QZContextRef ctx, QZRect rect) {
    QZContextFillRect(ctx, rect);
    emit(writer_of(ctx), rect.origin.x, rect.origin.y, rect.size.width, rect.size.height, "re");
    emit(writer_of(ctx), "f");
}

void QZPDFContextStrokeRect(QZContextRef ctx, QZRect rect) {
    QZContextStrokeRect(ctx, rect);
    emit(writer_of(ctx), rect.origin.x, rect.origin.y, rect.size.width, rect.size.height, "re");
    emit(writer_of(ctx), "S");
}

void QZPDFContextBeginPath(QZContextRef ctx) {
    QZContextBeginPath(ctx);
}

void QZPDFContextMoveToPoint(QZContextRef ctx, QZFloat x, QZFloat y) {
    QZContextMoveToPoint(ctx, x, y);
    emit(writer_of(ctx), x, y, "m");
}

void QZPDFContextAddLineToPoint(QZContextRef ctx, QZFloat x, QZFloat y) {
    QZContextAddLineToPoint(ctx, x, y);
    emit(writer_of(ctx), x, y, "l");
}

void QZPDFContextAddCurveToPoint(QZContextRef ctx, QZFloat cp1x, QZFloat cp1y,
                                 QZFloat cp2x, QZFloat cp2y, QZFloat x, QZFloat y) {
    QZContextAddCurveToPoint(ctx, cp1x, cp1y, cp2x, cp2y, x, y);
    emit6(writer_of(ctx), cp1x, cp1y, cp2x, cp2y, x, y, "c");
}

void QZPDFContextClosePath(QZContextRef ctx) {
    QZContextClosePath(ctx);
    emit(writer_of(ctx), "h");
}

void QZPDFContextFillPath(QZContextRef ctx) {
    QZContextFillPath(ctx);
    emit(writer_of(ctx), "f");
}

void QZPDFContextStrokePath(QZContextRef ctx) {
    QZContextStrokePath(ctx);
    emit(writer_of(ctx), "S");
}

/* ---- reader: our uncompressed files only (rg/RG/re/f/m/l/c/h/S/w/cm/q/Q) ---- */

static bool is_ident(unsigned char c) {
    return std::isalnum(c) || c == '*' || c == '\'' || c == '"';
}

static bool load_file(const char *path, std::string *out) {
    if (!path || !out) return false;
    FILE *fp = fopen(path, "rb");
    if (!fp) return false;
    if (fseek(fp, 0, SEEK_END) != 0) {
        fclose(fp);
        return false;
    }
    long n = ftell(fp);
    if (n < 0) {
        fclose(fp);
        return false;
    }
    rewind(fp);
    out->assign((size_t)n, '\0');
    size_t nr = n ? fread(out->data(), 1, (size_t)n, fp) : 0;
    fclose(fp);
    out->resize(nr);
    return nr >= 8;
}

static bool keyword_at(const std::string &s, size_t i, const char *kw) {
    size_t n = strlen(kw);
    if (i + n > s.size()) return false;
    if (memcmp(s.data() + i, kw, n) != 0) return false;
    if (i > 0 && is_ident((unsigned char)s[i - 1])) return false;
    if (i + n < s.size() && is_ident((unsigned char)s[i + n])) return false;
    return true;
}

static void skip_ws_and_comments(const std::string &s, size_t *i) {
    size_t n = s.size();
    size_t p = *i;
    for (;;) {
        while (p < n && std::isspace((unsigned char)s[p])) p++;
        if (p < n && s[p] == '%') {
            while (p < n && s[p] != '\n' && s[p] != '\r') p++;
            continue;
        }
        break;
    }
    *i = p;
}

static bool parse_number_at(const std::string &s, size_t *i, double *out) {
    skip_ws_and_comments(s, i);
    size_t p = *i;
    size_t n = s.size();
    if (p >= n) return false;
    char *end = nullptr;
    double v = strtod(s.data() + p, &end);
    if (end == s.data() + p) return false;
    *out = v;
    *i = (size_t)(end - s.data());
    return true;
}

static bool extract_stream(const std::string &s, size_t stream_kw, std::string *out) {
    size_t i = stream_kw + 6;
    if (i < s.size() && s[i] == '\r') i++;
    if (i < s.size() && s[i] == '\n') i++;
    size_t e = i;
    while (e < s.size() && !keyword_at(s, e, "endstream")) e++;
    if (e >= s.size()) return false;
    size_t t = e;
    if (t > i && s[t - 1] == '\n') t--;
    if (t > i && s[t - 1] == '\r') t--;
    *out = s.substr(i, t - i);
    return true;
}

static bool parse_our_pdf(const std::string &s, QZPDFDocument *doc) {
    std::vector<QZRect> boxes;
    std::vector<std::string> streams;
    size_t n = s.size();
    for (size_t i = 0; i < n; i++) {
        if (s[i] == '/' && i + 9 <= n && memcmp(s.data() + i, "/MediaBox", 9) == 0) {
            size_t p = i + 9;
            skip_ws_and_comments(s, &p);
            if (p < n && s[p] == '[') p++;
            double v[4];
            bool ok = true;
            for (int k = 0; k < 4; k++) {
                if (!parse_number_at(s, &p, &v[k])) {
                    ok = false;
                    break;
                }
            }
            if (ok) {
                QZRect box = QZRectMake(v[0], v[1], v[2] - v[0], v[3] - v[1]);
                boxes.push_back(box);
            }
            i = p;
            continue;
        }
        if (keyword_at(s, i, "stream")) {
            std::string body;
            if (extract_stream(s, i, &body)) {
                streams.push_back(std::move(body));
                i += 6;
            }
        }
    }
    if (streams.empty()) return false;
    size_t np = streams.size();
    if (boxes.size() < np) {
        while (boxes.size() < np) boxes.push_back(QZRectMake(0, 0, 1, 1));
    }
    doc->pages.resize(np);
    for (size_t i = 0; i < np; i++) {
        doc->pages[i].box = boxes[i];
        doc->pages[i].content = std::move(streams[i]);
    }
    return true;
}

QZPDFDocumentRef QZPDFDocumentCreateWithFile(const char *path) {
    std::string data;
    if (!load_file(path, &data)) return nullptr;
    if (data.size() < 5 || memcmp(data.data(), "%PDF-", 5) != 0) return nullptr;
    auto *doc = new QZPDFDocument();
    if (!parse_our_pdf(data, doc) || doc->pages.empty()) {
        delete doc;
        return nullptr;
    }
    return doc;
}

void QZPDFDocumentRelease(QZPDFDocumentRef doc) { delete doc; }

size_t QZPDFDocumentGetNumberOfPages(QZPDFDocumentRef doc) {
    return doc ? doc->pages.size() : 0;
}

QZPDFPageRef QZPDFDocumentGetPage(QZPDFDocumentRef doc, size_t index) {
    if (!doc || index == 0 || index > doc->pages.size()) return nullptr;
    return &doc->pages[index - 1];
}

QZRect QZPDFPageGetBoxRect(QZPDFPageRef page) {
    return page ? page->box : QZRectMake(0, 0, 0, 0);
}

static bool popn(std::vector<double> &st, int n, double *out) {
    if ((int)st.size() < n) return false;
    for (int i = 0; i < n; i++) out[i] = st[st.size() - (size_t)n + (size_t)i];
    st.resize(st.size() - (size_t)n);
    return true;
}

static void replay_content(QZContextRef ctx, const std::string &cs) {
    std::vector<double> st;
    st.reserve(16);
    size_t i = 0, n = cs.size();
    while (i < n) {
        skip_ws_and_comments(cs, &i);
        if (i >= n) break;
        unsigned char c = (unsigned char)cs[i];
        if (c == '+' || c == '-' || c == '.' || std::isdigit(c)) {
            double v;
            if (!parse_number_at(cs, &i, &v)) break;
            st.push_back(v);
            continue;
        }
        if (c == '/') {
            i++;
            while (i < n && is_ident((unsigned char)cs[i])) i++;
            st.clear();
            continue;
        }
        if (c == '[' || c == ']') {
            i++;
            continue;
        }
        if (c == '(') {
            i++;
            int depth = 1;
            while (i < n && depth) {
                if (cs[i] == '\\') {
                    i += (i + 1 < n) ? 2 : 1;
                    continue;
                }
                if (cs[i] == '(') depth++;
                else if (cs[i] == ')') depth--;
                i++;
            }
            continue;
        }
        size_t a = i;
        while (i < n && is_ident((unsigned char)cs[i])) i++;
        if (a == i) {
            i++;
            continue;
        }
        std::string op(cs.data() + a, i - a);
        double v[6];
        if (op == "rg") {
            if (popn(st, 3, v)) QZContextSetRGBFillColor(ctx, v[0], v[1], v[2], 1);
        } else if (op == "RG") {
            if (popn(st, 3, v)) QZContextSetRGBStrokeColor(ctx, v[0], v[1], v[2], 1);
        } else if (op == "g") {
            if (popn(st, 1, v)) QZContextSetRGBFillColor(ctx, v[0], v[0], v[0], 1);
        } else if (op == "G") {
            if (popn(st, 1, v)) QZContextSetRGBStrokeColor(ctx, v[0], v[0], v[0], 1);
        } else if (op == "w") {
            if (popn(st, 1, v)) QZContextSetLineWidth(ctx, v[0]);
        } else if (op == "re") {
            if (popn(st, 4, v)) QZContextAddRect(ctx, QZRectMake(v[0], v[1], v[2], v[3]));
        } else if (op == "m") {
            if (popn(st, 2, v)) QZContextMoveToPoint(ctx, v[0], v[1]);
        } else if (op == "l") {
            if (popn(st, 2, v)) QZContextAddLineToPoint(ctx, v[0], v[1]);
        } else if (op == "c") {
            if (popn(st, 6, v))
                QZContextAddCurveToPoint(ctx, v[0], v[1], v[2], v[3], v[4], v[5]);
        } else if (op == "h") {
            QZContextClosePath(ctx);
        } else if (op == "f" || op == "F") {
            QZContextFillPath(ctx);
        } else if (op == "f*") {
            QZContextEOFillPath(ctx);
        } else if (op == "S") {
            QZContextStrokePath(ctx);
        } else if (op == "s") {
            QZContextClosePath(ctx);
            QZContextStrokePath(ctx);
        } else if (op == "B") {
            QZContextDrawPath(ctx, kQZPathFillStroke);
        } else if (op == "b") {
            QZContextClosePath(ctx);
            QZContextDrawPath(ctx, kQZPathFillStroke);
        } else if (op == "n") {
            QZContextBeginPath(ctx);
        } else if (op == "q") {
            QZContextSaveGState(ctx);
        } else if (op == "Q") {
            QZContextRestoreGState(ctx);
        } else if (op == "cm") {
            if (popn(st, 6, v)) {
                QZAffineTransform t = QZAffineTransformMake(v[0], v[1], v[2], v[3], v[4], v[5]);
                QZContextConcatCTM(ctx, t);
            }
        } else {
            st.clear();
        }
    }
}

void QZContextDrawPDFPage(QZContextRef ctx, QZPDFPageRef page) {
    if (!ctx || !page) return;
    QZContextSaveGState(ctx);
    QZContextClipToRect(ctx, page->box);
    QZContextSetRGBFillColor(ctx, 0, 0, 0, 1);
    QZContextSetRGBStrokeColor(ctx, 0, 0, 0, 1);
    QZContextSetLineWidth(ctx, 1);
    QZContextBeginPath(ctx);
    replay_content(ctx, page->content);
    QZContextRestoreGState(ctx);
}
