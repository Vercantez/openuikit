#pragma once

#include "quartz/quartz.h"
#include <cstddef>
#include <cstdint>
#include <string>
#include <vector>

struct Backend {
    virtual ~Backend() = default;
    virtual const char *name() const = 0;
    virtual bool begin(int w, int h) = 0;
    virtual const uint8_t *pixels() const = 0;
    virtual size_t bpr() const = 0;
    virtual void end() = 0;

    virtual void save() = 0;
    virtual void restore() = 0;
    virtual void translate(double x, double y) = 0;
    virtual void scale(double x, double y) = 0;
    virtual void rotate(double a) = 0;
    virtual void concat(QZAffineTransform t) = 0;

    virtual void set_fill(double r, double g, double b, double a) = 0;
    virtual void set_stroke(double r, double g, double b, double a) = 0;
    virtual void set_width(double w) = 0;
    virtual void set_cap(QZLineCap cap) = 0;
    virtual void set_join(QZLineJoin join) = 0;
    virtual void set_miter(double m) = 0;
    virtual void set_dash(double phase, const double *len, int n) = 0;
    virtual void set_alpha(double a) = 0;
    virtual void set_blend(QZBlendMode m) = 0;
    virtual void set_aa(bool on) = 0;

    virtual void begin_path() = 0;
    virtual void move_to(double x, double y) = 0;
    virtual void line_to(double x, double y) = 0;
    virtual void curve_to(double c1x, double c1y, double c2x, double c2y, double x, double y) = 0;
    virtual void quad_to(double cx, double cy, double x, double y) = 0;
    virtual void add_rect(double x, double y, double w, double h) = 0;
    virtual void add_ellipse(double x, double y, double w, double h) = 0;
    virtual void add_arc(double x, double y, double r, double a0, double a1, int cw) = 0;
    virtual void add_arc_to(double x1, double y1, double x2, double y2, double r) = 0;
    virtual void close_path() = 0;
    virtual void fill() = 0;
    virtual void eofill() = 0;
    virtual void stroke() = 0;
    virtual void fill_stroke() = 0;

    virtual void fill_rect(double x, double y, double w, double h) = 0;
    virtual void stroke_rect(double x, double y, double w, double h) = 0;
    virtual void fill_ellipse(double x, double y, double w, double h) = 0;
    virtual void stroke_ellipse(double x, double y, double w, double h) = 0;
    virtual void clear_rect(double x, double y, double w, double h) = 0;
    virtual void clip() = 0;
    virtual void eoclip() = 0;
    virtual void clip_rect(double x, double y, double w, double h) = 0;

    virtual void draw_linear(const double *locs, const double *rgba, int n,
                             double x0, double y0, double x1, double y1, uint32_t opt) = 0;
    virtual void draw_radial(const double *locs, const double *rgba, int n,
                             double cx0, double cy0, double r0,
                             double cx1, double cy1, double r1, uint32_t opt) = 0;
    virtual void draw_image(const uint8_t *rgba, int iw, int ih,
                            double x, double y, double w, double h) = 0;

    virtual void begin_transparency() = 0;
    virtual void end_transparency() = 0;
    virtual void set_shadow(double ox, double oy, double blur,
                            double r, double g, double b, double a) = 0;
    virtual void add_rounded_rect(double x, double y, double w, double h, double rad) = 0;
};

Backend *make_apple_backend();
Backend *make_qz_backend();

struct Scene {
    const char *name;
    void (*draw)(Backend &b, int w, int h);
};

const Scene *all_scenes(int *count);
