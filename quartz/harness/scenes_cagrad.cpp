#include "registry.h"

static int white_root(LayerTree &t, int w, int h) {
    int r = t.create("layer");
    t.set_frame(r, 0, 0, w, h);
    t.set_bg(r, 1, 1, 1, 1);
    return r;
}

/* Horizontal 3-stop strip: same colors as ca_gradient, isolates interpolation. */
static void ca_grad_hstrip(LayerTree &t, int w, int h) {
    int r = white_root(t, w, h);
    int g = t.create("gradient");
    t.set_frame(g, 48, 112, 160, 24);
    double col[] = {1, 0.2, 0.2, 1,  1, 0.85, 0.2, 1,  0.2, 0.3, 1, 1};
    double loc[] = {0, 0.45, 1};
    t.grad_colors(g, col, loc, 3);
    t.grad_points(g, 0, 0.5, 1, 0.5);
    t.add_sub(r, g);
    t.render(r);
}

/* Non-square bounds: unit-space t vs pixel-Euclidean differ. */
static void ca_grad_nonsquare(LayerTree &t, int w, int h) {
    int r = white_root(t, w, h);
    int g = t.create("gradient");
    t.set_frame(g, 36, 88, 176, 72);
    t.set_corner(g, 12);
    t.set_masks(g, true);
    double col[] = {1, 0.2, 0.2, 1,  1, 0.85, 0.2, 1,  0.2, 0.3, 1, 1};
    double loc[] = {0, 0.45, 1};
    t.grad_colors(g, col, loc, 3);
    t.grad_points(g, 0, 0, 1, 1);
    t.add_sub(r, g);
    t.render(r);
}

QZ_CA_SCENE("ca_grad_hstrip", ca_grad_hstrip);
QZ_CA_SCENE("ca_grad_nonsquare", ca_grad_nonsquare);
