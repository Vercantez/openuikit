#include "backend.h"

#if defined(__APPLE__)
#include <CoreGraphics/CoreGraphics.h>
#include <cstring>
#include <vector>

struct AppleBackend final : Backend {
    CGContextRef ctx = nullptr;
    CGColorSpaceRef cs = nullptr;
    int W = 0, H = 0;
    std::vector<uint8_t> copy;

    const char *name() const override { return "apple"; }

    bool begin(int w, int h) override {
        end();
        W = w; H = h;
        cs = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
        ctx = CGBitmapContextCreate(NULL, w, h, 8, (size_t)w * 4, cs,
                                    kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
        if (!ctx) return false;
        CGContextClearRect(ctx, CGRectMake(0, 0, w, h));
        CGContextSetShouldAntialias(ctx, true);
        CGContextSetInterpolationQuality(ctx, kCGInterpolationDefault);
        return true;
    }
    const uint8_t *pixels() const override {
        return (const uint8_t *)CGBitmapContextGetData(ctx);
    }
    size_t bpr() const override { return CGBitmapContextGetBytesPerRow(ctx); }
    void end() override {
        if (ctx) { CGContextRelease(ctx); ctx = nullptr; }
        if (cs) { CGColorSpaceRelease(cs); cs = nullptr; }
    }
    ~AppleBackend() override { end(); }

    void save() override { CGContextSaveGState(ctx); }
    void restore() override { CGContextRestoreGState(ctx); }
    void translate(double x, double y) override { CGContextTranslateCTM(ctx, x, y); }
    void scale(double x, double y) override { CGContextScaleCTM(ctx, x, y); }
    void rotate(double a) override { CGContextRotateCTM(ctx, a); }
    void concat(QZAffineTransform t) override {
        CGAffineTransform ct = CGAffineTransformMake(t.a, t.b, t.c, t.d, t.tx, t.ty);
        CGContextConcatCTM(ctx, ct);
    }
    void set_fill(double r, double g, double b, double a) override {
        CGContextSetRGBFillColor(ctx, r, g, b, a);
    }
    void set_stroke(double r, double g, double b, double a) override {
        CGContextSetRGBStrokeColor(ctx, r, g, b, a);
    }
    void set_width(double w) override { CGContextSetLineWidth(ctx, w); }
    void set_cap(QZLineCap cap) override { CGContextSetLineCap(ctx, (CGLineCap)cap); }
    void set_join(QZLineJoin join) override { CGContextSetLineJoin(ctx, (CGLineJoin)join); }
    void set_miter(double m) override { CGContextSetMiterLimit(ctx, m); }
    void set_dash(double phase, const double *len, int n) override {
        std::vector<CGFloat> L(n);
        for (int i = 0; i < n; i++) L[i] = (CGFloat)len[i];
        CGContextSetLineDash(ctx, phase, L.data(), (size_t)n);
    }
    void set_alpha(double a) override { CGContextSetAlpha(ctx, a); }
    void set_blend(QZBlendMode m) override { CGContextSetBlendMode(ctx, (CGBlendMode)m); }
    void set_aa(bool on) override { CGContextSetShouldAntialias(ctx, on); }

    void begin_path() override { CGContextBeginPath(ctx); }
    void move_to(double x, double y) override { CGContextMoveToPoint(ctx, x, y); }
    void line_to(double x, double y) override { CGContextAddLineToPoint(ctx, x, y); }
    void curve_to(double c1x, double c1y, double c2x, double c2y, double x, double y) override {
        CGContextAddCurveToPoint(ctx, c1x, c1y, c2x, c2y, x, y);
    }
    void quad_to(double cx, double cy, double x, double y) override {
        CGContextAddQuadCurveToPoint(ctx, cx, cy, x, y);
    }
    void add_rect(double x, double y, double w, double h) override {
        CGContextAddRect(ctx, CGRectMake(x, y, w, h));
    }
    void add_ellipse(double x, double y, double w, double h) override {
        CGContextAddEllipseInRect(ctx, CGRectMake(x, y, w, h));
    }
    void add_arc(double x, double y, double r, double a0, double a1, int cw) override {
        CGContextAddArc(ctx, x, y, r, a0, a1, cw);
    }
    void add_arc_to(double x1, double y1, double x2, double y2, double r) override {
        CGContextAddArcToPoint(ctx, x1, y1, x2, y2, r);
    }
    void close_path() override { CGContextClosePath(ctx); }
    void fill() override { CGContextFillPath(ctx); }
    void eofill() override { CGContextEOFillPath(ctx); }
    void stroke() override { CGContextStrokePath(ctx); }
    void fill_stroke() override { CGContextDrawPath(ctx, kCGPathFillStroke); }

    void fill_rect(double x, double y, double w, double h) override {
        CGContextFillRect(ctx, CGRectMake(x, y, w, h));
    }
    void stroke_rect(double x, double y, double w, double h) override {
        CGContextStrokeRect(ctx, CGRectMake(x, y, w, h));
    }
    void fill_ellipse(double x, double y, double w, double h) override {
        CGContextFillEllipseInRect(ctx, CGRectMake(x, y, w, h));
    }
    void stroke_ellipse(double x, double y, double w, double h) override {
        CGContextStrokeEllipseInRect(ctx, CGRectMake(x, y, w, h));
    }
    void clear_rect(double x, double y, double w, double h) override {
        CGContextClearRect(ctx, CGRectMake(x, y, w, h));
    }
    void clip() override { CGContextClip(ctx); }
    void eoclip() override { CGContextEOClip(ctx); }
    void clip_rect(double x, double y, double w, double h) override {
        CGContextClipToRect(ctx, CGRectMake(x, y, w, h));
    }

    CGGradientRef make_grad(const double *locs, const double *rgba, int n) {
        std::vector<CGFloat> L(n), C(n * 4);
        for (int i = 0; i < n; i++) {
            L[i] = (CGFloat)locs[i];
            C[i * 4 + 0] = (CGFloat)rgba[i * 4 + 0];
            C[i * 4 + 1] = (CGFloat)rgba[i * 4 + 1];
            C[i * 4 + 2] = (CGFloat)rgba[i * 4 + 2];
            C[i * 4 + 3] = (CGFloat)rgba[i * 4 + 3];
        }
        return CGGradientCreateWithColorComponents(cs, C.data(), L.data(), (size_t)n);
    }
    void draw_linear(const double *locs, const double *rgba, int n,
                     double x0, double y0, double x1, double y1, uint32_t opt) override {
        CGGradientRef g = make_grad(locs, rgba, n);
        CGContextDrawLinearGradient(ctx, g, CGPointMake(x0, y0), CGPointMake(x1, y1),
                                    (CGGradientDrawingOptions)opt);
        CGGradientRelease(g);
    }
    void draw_radial(const double *locs, const double *rgba, int n,
                     double cx0, double cy0, double r0,
                     double cx1, double cy1, double r1, uint32_t opt) override {
        CGGradientRef g = make_grad(locs, rgba, n);
        CGContextDrawRadialGradient(ctx, g, CGPointMake(cx0, cy0), r0,
                                    CGPointMake(cx1, cy1), r1,
                                    (CGGradientDrawingOptions)opt);
        CGGradientRelease(g);
    }
    void draw_image(const uint8_t *rgba, int iw, int ih,
                    double x, double y, double w, double h) override {
        /* Input is non-premul RGBA. CG wants premul for bitmap. */
        size_t nb = (size_t)iw * ih * 4;
        std::vector<uint8_t> prem(nb);
        for (size_t i = 0; i < (size_t)iw * ih; i++) {
            uint8_t a = rgba[i * 4 + 3];
            prem[i * 4 + 0] = (uint8_t)((rgba[i * 4 + 0] * a) / 255);
            prem[i * 4 + 1] = (uint8_t)((rgba[i * 4 + 1] * a) / 255);
            prem[i * 4 + 2] = (uint8_t)((rgba[i * 4 + 2] * a) / 255);
            prem[i * 4 + 3] = a;
        }
        CGContextRef ic = CGBitmapContextCreate(prem.data(), iw, ih, 8, (size_t)iw * 4, cs,
                                                kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
        CGImageRef img = CGBitmapContextCreateImage(ic);
        CGContextDrawImage(ctx, CGRectMake(x, y, w, h), img);
        CGImageRelease(img);
        CGContextRelease(ic);
    }
    void begin_transparency() override { CGContextBeginTransparencyLayer(ctx, NULL); }
    void end_transparency() override { CGContextEndTransparencyLayer(ctx); }
    void set_shadow(double ox, double oy, double blur,
                    double r, double g, double b, double a) override {
        CGFloat c[4] = {(CGFloat)r, (CGFloat)g, (CGFloat)b, (CGFloat)a};
        CGColorRef col = CGColorCreate(cs, c);
        CGContextSetShadowWithColor(ctx, CGSizeMake(ox, oy), blur, col);
        CGColorRelease(col);
    }
    void add_rounded_rect(double x, double y, double w, double h, double rad) override {
        CGPathRef p = CGPathCreateWithRoundedRect(CGRectMake(x, y, w, h), rad, rad, NULL);
        CGContextAddPath(ctx, p);
        CGPathRelease(p);
    }
};

Backend *make_apple_backend() { return new AppleBackend(); }

#else
Backend *make_apple_backend() { return nullptr; }
#endif
