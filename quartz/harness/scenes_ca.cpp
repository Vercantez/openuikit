#include "layer_backend.h"
#include <cmath>

static int white_root(LayerTree &t, int w, int h) {
    int r = t.create("layer");
    t.set_frame(r, 0, 0, w, h);
    t.set_bg(r, 1, 1, 1, 1);
    return r;
}

static void ca_solid(LayerTree &t, int w, int h) {
    int r = white_root(t, w, h);
    int c = t.create("layer");
    t.set_frame(c, 40, 48, 140, 90);
    t.set_bg(c, 0.82, 0.18, 0.16, 1);
    t.add_sub(r, c);
    t.render(r);
}

static void ca_stack(LayerTree &t, int w, int h) {
    int r = white_root(t, w, h);
    int a = t.create("layer");
    t.set_frame(a, 30, 40, 120, 120);
    t.set_bg(a, 0.9, 0.2, 0.2, 1);
    int b = t.create("layer");
    t.set_frame(b, 90, 80, 120, 120);
    t.set_bg(b, 0.15, 0.35, 0.9, 0.75);
    t.add_sub(r, a);
    t.add_sub(r, b);
    t.render(r);
}

static void ca_opacity(LayerTree &t, int w, int h) {
    int r = white_root(t, w, h);
    int a = t.create("layer");
    t.set_frame(a, 36, 40, 140, 140);
    t.set_bg(a, 0.1, 0.5, 0.2, 1);
    t.set_opacity(a, 0.45);
    int b = t.create("layer");
    t.set_frame(b, 50, 50, 60, 60);
    t.set_bg(b, 1, 1, 0, 1);
    t.add_sub(a, b);
    t.add_sub(r, a);
    t.render(r);
}

static void ca_corner(LayerTree &t, int w, int h) {
    int r = white_root(t, w, h);
    int c = t.create("layer");
    t.set_frame(c, 48, 48, 160, 160);
    t.set_bg(c, 0.15, 0.45, 0.85, 1);
    t.set_corner(c, 28);
    t.set_masks(c, true);
    t.add_sub(r, c);
    t.render(r);
}

static void ca_border(LayerTree &t, int w, int h) {
    int r = white_root(t, w, h);
    int c = t.create("layer");
    t.set_frame(c, 40, 50, 176, 140);
    t.set_bg(c, 0.95, 0.95, 0.9, 1);
    t.set_corner(c, 16);
    t.set_border(c, 8, 0.1, 0.1, 0.1, 1);
    t.add_sub(r, c);
    t.render(r);
}

static void ca_masks_sublayer(LayerTree &t, int w, int h) {
    int r = white_root(t, w, h);
    int p = t.create("layer");
    t.set_frame(p, 48, 48, 160, 160);
    t.set_bg(p, 0.2, 0.2, 0.25, 1);
    t.set_corner(p, 80);
    t.set_masks(p, true);
    int c = t.create("layer");
    t.set_frame(c, 80, 20, 120, 80);
    t.set_bg(c, 1, 0.3, 0.1, 1);
    t.add_sub(p, c);
    t.add_sub(r, p);
    t.render(r);
}

static void ca_zorder(LayerTree &t, int w, int h) {
    int r = white_root(t, w, h);
    int a = t.create("layer");
    t.set_frame(a, 40, 50, 100, 100);
    t.set_bg(a, 0.9, 0.2, 0.2, 1);
    t.set_z(a, 2);
    int b = t.create("layer");
    t.set_frame(b, 90, 80, 100, 100);
    t.set_bg(b, 0.2, 0.3, 0.9, 1);
    t.set_z(b, 1);
    t.add_sub(r, a);
    t.add_sub(r, b);
    t.render(r);
}

static void ca_anchor_rotate(LayerTree &t, int w, int h) {
    int r = white_root(t, w, h);
    int c = t.create("layer");
    t.set_bounds(c, 0, 0, 120, 50);
    t.set_position(c, 128, 128);
    t.set_anchor(c, 0.5, 0.5);
    t.set_bg(c, 0.75, 0.15, 0.45, 1);
    t.set_affine(c, QZAffineTransformMakeRotation(0.4));
    t.add_sub(r, c);
    t.render(r);
}

static void ca_nested_transform(LayerTree &t, int w, int h) {
    int r = white_root(t, w, h);
    int p = t.create("layer");
    t.set_frame(p, 40, 40, 180, 180);
    t.set_bg(p, 0.9, 0.9, 0.85, 1);
    t.set_affine(p, QZAffineTransformMakeRotation(0.15));
    int c = t.create("layer");
    t.set_frame(c, 30, 40, 80, 50);
    t.set_bg(c, 0.2, 0.5, 0.9, 1);
    t.add_sub(p, c);
    t.add_sub(r, p);
    t.render(r);
}

static void ca_shape_ellipse(LayerTree &t, int w, int h) {
    int r = white_root(t, w, h);
    int s = t.create("shape");
    t.set_frame(s, 0, 0, w, h);
    t.shape_ellipse(s, 40, 40, 176, 176);
    t.shape_fill(s, 0.15, 0.55, 0.35, 1);
    t.shape_stroke(s, 0, 0, 0, 1, 6);
    t.add_sub(r, s);
    t.render(r);
}

static void ca_shape_star(LayerTree &t, int w, int h) {
    int r = white_root(t, w, h);
    int s = t.create("shape");
    t.set_frame(s, 40, 40, 176, 176);
    t.shape_rect(s, 10, 10, 156, 156);
    t.shape_fill(s, 0.85, 0.2, 0.2, 1);
    t.add_sub(r, s);
    int hole = t.create("shape");
    t.set_frame(hole, 40, 40, 176, 176);
    t.shape_ellipse(hole, 48, 48, 80, 80);
    t.shape_fill(hole, 1, 1, 1, 1);
    t.add_sub(r, hole);
    t.render(r);
}

static void ca_gradient(LayerTree &t, int w, int h) {
    int r = white_root(t, w, h);
    int g = t.create("gradient");
    t.set_frame(g, 28, 28, 200, 200);
    t.set_corner(g, 20);
    t.set_masks(g, true);
    double col[] = {1, 0.2, 0.2, 1,  1, 0.85, 0.2, 1,  0.2, 0.3, 1, 1};
    double loc[] = {0, 0.45, 1};
    t.grad_colors(g, col, loc, 3);
    t.grad_points(g, 0, 0, 1, 1);
    t.add_sub(r, g);
    t.render(r);
}

static void ca_hidden(LayerTree &t, int w, int h) {
    int r = white_root(t, w, h);
    int a = t.create("layer");
    t.set_frame(a, 30, 30, 80, 80);
    t.set_bg(a, 1, 0, 0, 1);
    int b = t.create("layer");
    t.set_frame(b, 120, 80, 80, 80);
    t.set_bg(b, 0, 0, 1, 1);
    t.set_hidden(b, true);
    t.add_sub(r, a);
    t.add_sub(r, b);
    t.render(r);
}

static void ca_position_anchor(LayerTree &t, int w, int h) {
    int r = white_root(t, w, h);
    int c = t.create("layer");
    t.set_bounds(c, 0, 0, 80, 80);
    t.set_position(c, 64, 64);
    t.set_anchor(c, 0, 0);
    t.set_bg(c, 0.2, 0.7, 0.3, 1);
    t.add_sub(r, c);
    t.render(r);
}

static const LayerScene kLayerScenes[] = {
    {"ca_solid", ca_solid},
    {"ca_stack", ca_stack},
    {"ca_opacity", ca_opacity},
    {"ca_corner", ca_corner},
    {"ca_border", ca_border},
    {"ca_masks_sublayer", ca_masks_sublayer},
    {"ca_zorder", ca_zorder},
    {"ca_anchor_rotate", ca_anchor_rotate},
    {"ca_nested_transform", ca_nested_transform},
    {"ca_shape_ellipse", ca_shape_ellipse},
    {"ca_shape_star", ca_shape_star},
    {"ca_gradient", ca_gradient},
    {"ca_hidden", ca_hidden},
    {"ca_position_anchor", ca_position_anchor},
};

const LayerScene *all_layer_scenes(int *count) {
    *count = (int)(sizeof(kLayerScenes) / sizeof(kLayerScenes[0]));
    return kLayerScenes;
}
