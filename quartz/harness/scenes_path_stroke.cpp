#include "registry.h"

static void s_clear_white(Backend &b, int w, int h) {
    b.set_fill(1, 1, 1, 1);
    b.fill_rect(0, 0, w, h);
}

static void scene_stroke_line_segments(Backend &b, int w, int h) {
    (void)w;
    (void)h;
    s_clear_white(b, w, h);
    b.set_stroke(0.1, 0.1, 0.1, 1);
    b.set_width(4);
    b.set_cap(kQZLineCapButt);
    b.begin_path();
    b.move_to(20, 40);
    b.line_to(220, 40);
    b.move_to(30, 90);
    b.line_to(200, 130);
    b.move_to(40, 200);
    b.line_to(230, 170);
    b.stroke();
}

QZ_CG_SCENE("stroke_line_segments", scene_stroke_line_segments);
