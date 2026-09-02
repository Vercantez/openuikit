#pragma once

#include "quartz/quartz.h"
#include <cstddef>
#include <cstdint>

/* Shared layer-tree builder used by Apple QuartzCore and QZLayer. */
struct LayerTree {
    virtual ~LayerTree() = default;
    virtual const char *name() const = 0;
    virtual bool begin(int w, int h) = 0;
    virtual void end() = 0;
    virtual const uint8_t *pixels() const = 0;
    virtual size_t bpr() const = 0;

    virtual int create(const char *kind) = 0; /* "layer" | "shape" | "gradient" */
    virtual void set_frame(int id, double x, double y, double w, double h) = 0;
    virtual void set_bounds(int id, double x, double y, double w, double h) = 0;
    virtual void set_position(int id, double x, double y) = 0;
    virtual void set_anchor(int id, double x, double y) = 0;
    virtual void set_z(int id, double z) = 0;
    virtual void set_bg(int id, double r, double g, double b, double a) = 0;
    virtual void set_opacity(int id, double o) = 0;
    virtual void set_corner(int id, double radius) = 0;
    virtual void set_border(int id, double width, double r, double g, double b, double a) = 0;
    virtual void set_masks(int id, bool on) = 0;
    virtual void set_hidden(int id, bool on) = 0;
    virtual void set_affine(int id, QZAffineTransform t) = 0;
    virtual void add_sub(int parent, int child) = 0;

    virtual void shape_rect(int id, double x, double y, double w, double h) = 0;
    virtual void shape_ellipse(int id, double x, double y, double w, double h) = 0;
    virtual void shape_fill(int id, double r, double g, double b, double a) = 0;
    virtual void shape_stroke(int id, double r, double g, double b, double a, double width) = 0;
    virtual void shape_eofill(int id, bool on) = 0;

    virtual void grad_colors(int id, const double *rgba, const double *loc, int n) = 0;
    virtual void grad_points(int id, double x0, double y0, double x1, double y1) = 0;
    virtual void grad_radial(int id, bool on) = 0;

    virtual void render(int root) = 0;
};

LayerTree *make_apple_layers();
LayerTree *make_qz_layers();

struct LayerScene {
    const char *name;
    void (*build)(LayerTree &t, int w, int h);
};

const LayerScene *all_layer_scenes(int *count);
