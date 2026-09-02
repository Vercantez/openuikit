#include "backend.h"
#include <vector>

struct QZBackend final : Backend {
    QZContextRef ctx = nullptr;
    int W = 0, H = 0;

    const char *name() const override { return "qz"; }
    bool begin(int w, int h) override {
        end();
        W = w; H = h;
        ctx = QZBitmapContextCreate(nullptr, w, h, 8, (size_t)w * 4, kQZImageAlphaPremultipliedLast);
        return ctx != nullptr;
    }
    const uint8_t *pixels() const override {
        return (const uint8_t *)QZBitmapContextGetData(ctx);
    }
    size_t bpr() const override { return QZBitmapContextGetBytesPerRow(ctx); }
    void end() override {
        if (ctx) { QZContextRelease(ctx); ctx = nullptr; }
    }
    ~QZBackend() override { end(); }

    void save() override { QZContextSaveGState(ctx); }
    void restore() override { QZContextRestoreGState(ctx); }
    void translate(double x, double y) override { QZContextTranslateCTM(ctx, x, y); }
    void scale(double x, double y) override { QZContextScaleCTM(ctx, x, y); }
    void rotate(double a) override { QZContextRotateCTM(ctx, a); }
    void concat(QZAffineTransform t) override { QZContextConcatCTM(ctx, t); }

    void set_fill(double r, double g, double b, double a) override {
        QZContextSetRGBFillColor(ctx, r, g, b, a);
    }
    void set_stroke(double r, double g, double b, double a) override {
        QZContextSetRGBStrokeColor(ctx, r, g, b, a);
    }
    void set_width(double w) override { QZContextSetLineWidth(ctx, w); }
    void set_cap(QZLineCap cap) override { QZContextSetLineCap(ctx, cap); }
    void set_join(QZLineJoin join) override { QZContextSetLineJoin(ctx, join); }
    void set_miter(double m) override { QZContextSetMiterLimit(ctx, m); }
    void set_dash(double phase, const double *len, int n) override {
        std::vector<QZFloat> L(n);
        for (int i = 0; i < n; i++) L[i] = len[i];
        QZContextSetLineDash(ctx, phase, L.data(), (size_t)n);
    }
    void set_alpha(double a) override { QZContextSetAlpha(ctx, a); }
    void set_blend(QZBlendMode m) override { QZContextSetBlendMode(ctx, m); }
    void set_aa(bool on) override { QZContextSetShouldAntialias(ctx, on); }

    void begin_path() override { QZContextBeginPath(ctx); }
    void move_to(double x, double y) override { QZContextMoveToPoint(ctx, x, y); }
    void line_to(double x, double y) override { QZContextAddLineToPoint(ctx, x, y); }
    void curve_to(double c1x, double c1y, double c2x, double c2y, double x, double y) override {
        QZContextAddCurveToPoint(ctx, c1x, c1y, c2x, c2y, x, y);
    }
    void quad_to(double cx, double cy, double x, double y) override {
        QZContextAddQuadCurveToPoint(ctx, cx, cy, x, y);
    }
    void add_rect(double x, double y, double w, double h) override {
        QZContextAddRect(ctx, QZRectMake(x, y, w, h));
    }
    void add_ellipse(double x, double y, double w, double h) override {
        QZContextAddEllipseInRect(ctx, QZRectMake(x, y, w, h));
    }
    void add_arc(double x, double y, double r, double a0, double a1, int cw) override {
        QZContextAddArc(ctx, x, y, r, a0, a1, cw);
    }
    void add_arc_to(double x1, double y1, double x2, double y2, double r) override {
        QZContextAddArcToPoint(ctx, x1, y1, x2, y2, r);
    }
    void close_path() override { QZContextClosePath(ctx); }
    void fill() override { QZContextFillPath(ctx); }
    void eofill() override { QZContextEOFillPath(ctx); }
    void stroke() override { QZContextStrokePath(ctx); }
    void fill_stroke() override { QZContextDrawPath(ctx, kQZPathFillStroke); }

    void fill_rect(double x, double y, double w, double h) override {
        QZContextFillRect(ctx, QZRectMake(x, y, w, h));
    }
    void stroke_rect(double x, double y, double w, double h) override {
        QZContextStrokeRect(ctx, QZRectMake(x, y, w, h));
    }
    void fill_ellipse(double x, double y, double w, double h) override {
        QZContextFillEllipseInRect(ctx, QZRectMake(x, y, w, h));
    }
    void stroke_ellipse(double x, double y, double w, double h) override {
        QZContextStrokeEllipseInRect(ctx, QZRectMake(x, y, w, h));
    }
    void clear_rect(double x, double y, double w, double h) override {
        QZContextClearRect(ctx, QZRectMake(x, y, w, h));
    }
    void clip() override { QZContextClip(ctx); }
    void eoclip() override { QZContextEOClip(ctx); }
    void clip_rect(double x, double y, double w, double h) override {
        QZContextClipToRect(ctx, QZRectMake(x, y, w, h));
    }

    void draw_linear(const double *locs, const double *rgba, int n,
                     double x0, double y0, double x1, double y1, uint32_t opt) override {
        std::vector<QZFloat> L(n), C(n * 4);
        for (int i = 0; i < n; i++) {
            L[i] = locs[i];
            C[i * 4 + 0] = rgba[i * 4 + 0];
            C[i * 4 + 1] = rgba[i * 4 + 1];
            C[i * 4 + 2] = rgba[i * 4 + 2];
            C[i * 4 + 3] = rgba[i * 4 + 3];
        }
        QZGradientRef g = QZGradientCreate(L.data(), C.data(), (size_t)n);
        QZContextDrawLinearGradient(ctx, g, QZPointMake(x0, y0), QZPointMake(x1, y1), opt);
        QZGradientRelease(g);
    }
    void draw_radial(const double *locs, const double *rgba, int n,
                     double cx0, double cy0, double r0,
                     double cx1, double cy1, double r1, uint32_t opt) override {
        std::vector<QZFloat> L(n), C(n * 4);
        for (int i = 0; i < n; i++) {
            L[i] = locs[i];
            C[i * 4 + 0] = rgba[i * 4 + 0];
            C[i * 4 + 1] = rgba[i * 4 + 1];
            C[i * 4 + 2] = rgba[i * 4 + 2];
            C[i * 4 + 3] = rgba[i * 4 + 3];
        }
        QZGradientRef g = QZGradientCreate(L.data(), C.data(), (size_t)n);
        QZContextDrawRadialGradient(ctx, g, QZPointMake(cx0, cy0), r0,
                                    QZPointMake(cx1, cy1), r1, opt);
        QZGradientRelease(g);
    }
    void draw_image(const uint8_t *rgba, int iw, int ih,
                    double x, double y, double w, double h) override {
        QZImageRef img = QZImageCreate((size_t)iw, (size_t)ih, rgba);
        QZContextDrawImage(ctx, QZRectMake(x, y, w, h), img);
        QZImageRelease(img);
    }
    void begin_transparency() override { QZContextBeginTransparencyLayer(ctx); }
    void end_transparency() override { QZContextEndTransparencyLayer(ctx); }
    void set_shadow(double ox, double oy, double blur,
                    double r, double g, double b, double a) override {
        QZContextSetShadowWithColor(ctx, QZSizeMake(ox, oy), blur, r, g, b, a);
    }
    void add_rounded_rect(double x, double y, double w, double h, double rad) override {
        QZContextAddRoundedRect(ctx, QZRectMake(x, y, w, h), rad);
    }
};

Backend *make_qz_backend() { return new QZBackend(); }
