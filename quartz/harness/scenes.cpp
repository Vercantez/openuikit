#include "backend.h"
#include <cmath>
#include <vector>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

static void s_clear_white(Backend &b, int w, int h) {
    b.set_fill(1, 1, 1, 1);
    b.fill_rect(0, 0, w, h);
}

static void scene_fill_rects(Backend &b, int w, int h) {
    s_clear_white(b, w, h);
    b.set_fill(1, 0, 0, 1);
    b.fill_rect(16, 16, 80, 50);
    b.set_fill(0, 0.6, 0.2, 1);
    b.fill_rect(120, 40, 60, 90);
    b.set_fill(0.1, 0.2, 0.9, 1);
    b.fill_rect(40, 140, 160, 40);
}

static void scene_fill_rects_alpha(Backend &b, int w, int h) {
    s_clear_white(b, w, h);
    b.set_fill(1, 0, 0, 0.5);
    b.fill_rect(30, 30, 120, 120);
    b.set_fill(0, 0, 1, 0.5);
    b.fill_rect(90, 90, 120, 120);
}

static void scene_subpixel_rects(Backend &b, int w, int h) {
    s_clear_white(b, w, h);
    b.set_fill(0, 0, 0, 1);
    b.fill_rect(20.5, 20.5, 40, 40);
    b.fill_rect(80.25, 30.75, 50.5, 20.25);
    b.fill_rect(20.0, 100.5, 80.0, 1.0);
    b.set_fill(0.8, 0.1, 0.1, 1);
    b.fill_rect(140.3, 140.3, 70.4, 70.4);
}

static void scene_nested_eofill(Backend &b, int w, int h) {
    s_clear_white(b, w, h);
    b.set_fill(0.9, 0.7, 0.1, 1);
    b.begin_path();
    b.add_rect(30, 30, 180, 180);
    b.add_rect(70, 70, 100, 100);
    b.eofill();
}

static void scene_nested_winding(Backend &b, int w, int h) {
    s_clear_white(b, w, h);
    b.set_fill(0.2, 0.5, 0.8, 1);
    b.begin_path();
    b.add_rect(30, 30, 180, 180);
    b.add_rect(70, 70, 100, 100);
    b.fill();
}

static void scene_opposite_winding(Backend &b, int w, int h) {
    s_clear_white(b, w, h);
    b.set_fill(0.7, 0.2, 0.4, 1);
    b.begin_path();
    b.move_to(30, 30); b.line_to(210, 30); b.line_to(210, 210); b.line_to(30, 210); b.close_path();
    b.move_to(70, 70); b.line_to(70, 170); b.line_to(170, 170); b.line_to(170, 70); b.close_path();
    b.fill();
}

static void scene_triangle(Backend &b, int w, int h) {
    s_clear_white(b, w, h);
    b.set_fill(0.1, 0.1, 0.1, 1);
    b.begin_path();
    b.move_to(128, 220);
    b.line_to(30, 30);
    b.line_to(226, 30);
    b.close_path();
    b.fill();
}

static void scene_star_eofill(Backend &b, int w, int h) {
    s_clear_white(b, w, h);
    b.set_fill(0.85, 0.15, 0.15, 1);
    b.begin_path();
    const double cx = 128, cy = 128, r = 90;
    for (int i = 0; i < 5; i++) {
        double a = -M_PI / 2 + i * 4.0 * M_PI / 5.0;
        double x = cx + r * std::cos(a), y = cy + r * std::sin(a);
        if (i == 0) b.move_to(x, y); else b.line_to(x, y);
    }
    b.close_path();
    b.eofill();
}

static void scene_circle_fill(Backend &b, int w, int h) {
    s_clear_white(b, w, h);
    b.set_fill(0.1, 0.4, 0.9, 1);
    b.fill_ellipse(40, 40, 176, 176);
}

static void scene_circle_stroke(Backend &b, int w, int h) {
    s_clear_white(b, w, h);
    b.set_stroke(0.1, 0.4, 0.9, 1);
    b.set_width(8);
    b.stroke_ellipse(40, 40, 176, 176);
}

static void scene_ellipse(Backend &b, int w, int h) {
    s_clear_white(b, w, h);
    b.set_fill(0.2, 0.7, 0.3, 0.85);
    b.fill_ellipse(20, 60, 216, 120);
    b.set_stroke(0, 0, 0, 1);
    b.set_width(3);
    b.stroke_ellipse(20, 60, 216, 120);
}

static void scene_line_caps(Backend &b, int w, int h) {
    s_clear_white(b, w, h);
    b.set_stroke(0.1, 0.1, 0.1, 1);
    b.set_width(18);
    QZLineCap caps[3] = {kQZLineCapButt, kQZLineCapRound, kQZLineCapSquare};
    for (int i = 0; i < 3; i++) {
        b.set_cap(caps[i]);
        b.begin_path();
        b.move_to(40, 50.0 + i * 70);
        b.line_to(216, 50.0 + i * 70);
        b.stroke();
    }
}

static void scene_line_joins(Backend &b, int w, int h) {
    s_clear_white(b, w, h);
    b.set_stroke(0.15, 0.15, 0.6, 1);
    b.set_width(16);
    b.set_miter(10);
    QZLineJoin joins[3] = {kQZLineJoinMiter, kQZLineJoinRound, kQZLineJoinBevel};
    for (int i = 0; i < 3; i++) {
        b.set_join(joins[i]);
        double y = 40 + i * 70;
        b.begin_path();
        b.move_to(30, y);
        b.line_to(110, y + 50);
        b.line_to(190, y);
        b.stroke();
    }
}

static void scene_thick_polyline(Backend &b, int w, int h) {
    s_clear_white(b, w, h);
    b.set_stroke(0.8, 0.2, 0.1, 1);
    b.set_width(14);
    b.set_join(kQZLineJoinRound);
    b.set_cap(kQZLineCapRound);
    b.begin_path();
    b.move_to(20, 40);
    b.line_to(80, 200);
    b.line_to(140, 60);
    b.line_to(200, 180);
    b.line_to(240, 100);
    b.stroke();
}

static void scene_thin_lines(Backend &b, int w, int h) {
    s_clear_white(b, w, h);
    b.set_stroke(0, 0, 0, 1);
    b.set_width(1);
    b.set_cap(kQZLineCapButt);
    for (int i = 0; i < 12; i++) {
        b.begin_path();
        b.move_to(20, 20 + i * 18);
        b.line_to(236, 40 + i * 16);
        b.stroke();
    }
}

static void scene_dashed(Backend &b, int w, int h) {
    s_clear_white(b, w, h);
    b.set_stroke(0, 0.2, 0.5, 1);
    b.set_width(4);
    double dash[] = {12, 6, 3, 6};
    b.set_dash(0, dash, 4);
    b.begin_path();
    b.add_rect(30, 30, 196, 196);
    b.stroke();
    b.set_dash(8, dash, 4);
    b.begin_path();
    b.add_ellipse(60, 60, 136, 136);
    b.stroke();
}

static void scene_cubic(Backend &b, int w, int h) {
    s_clear_white(b, w, h);
    b.set_stroke(0.5, 0, 0.6, 1);
    b.set_width(3);
    b.set_cap(kQZLineCapRound);
    b.begin_path();
    b.move_to(20, 128);
    b.curve_to(20, 240, 236, 16, 236, 128);
    b.stroke();
    b.set_fill(0.5, 0, 0.6, 0.25);
    b.begin_path();
    b.move_to(20, 40);
    b.curve_to(80, 220, 176, 220, 236, 40);
    b.line_to(20, 40);
    b.fill();
}

static void scene_quad(Backend &b, int w, int h) {
    s_clear_white(b, w, h);
    b.set_stroke(0, 0.4, 0.2, 1);
    b.set_width(4);
    b.begin_path();
    b.move_to(20, 40);
    b.quad_to(128, 240, 236, 40);
    b.stroke();
}

static void scene_arcs(Backend &b, int w, int h) {
    s_clear_white(b, w, h);
    b.set_stroke(0.1, 0.1, 0.1, 1);
    b.set_width(6);
    b.set_cap(kQZLineCapRound);
    b.begin_path();
    b.add_arc(128, 128, 80, 0.3, 4.5, 0);
    b.stroke();
    b.set_fill(0.9, 0.4, 0.1, 1);
    b.begin_path();
    b.move_to(128, 128);
    b.add_arc(128, 128, 50, -0.4, 1.8, 0);
    b.close_path();
    b.fill();
}

static void scene_arc_to(Backend &b, int w, int h) {
    s_clear_white(b, w, h);
    b.set_stroke(0.2, 0.2, 0.7, 1);
    b.set_width(10);
    b.set_join(kQZLineJoinMiter);
    b.set_cap(kQZLineCapButt);
    b.begin_path();
    b.move_to(30, 30);
    b.add_arc_to(30, 220, 220, 220, 40);
    b.line_to(220, 220);
    b.stroke();
}

static void scene_rotate(Backend &b, int w, int h) {
    s_clear_white(b, w, h);
    b.translate(128, 128);
    b.rotate(0.4);
    b.set_fill(0.8, 0.2, 0.2, 1);
    b.fill_rect(-50, -30, 100, 60);
    b.set_stroke(0, 0, 0, 1);
    b.set_width(2);
    b.stroke_rect(-50, -30, 100, 60);
}

static void scene_scale_translate(Backend &b, int w, int h) {
    s_clear_white(b, w, h);
    b.translate(20, 20);
    b.scale(1.8, 0.7);
    b.set_fill(0.2, 0.5, 0.9, 1);
    b.fill_ellipse(10, 10, 100, 100);
    b.set_stroke(0, 0, 0, 1);
    b.set_width(2);
    b.stroke_rect(10, 10, 100, 100);
}

static void scene_clip_rect(Backend &b, int w, int h) {
    s_clear_white(b, w, h);
    b.save();
    b.clip_rect(60, 60, 136, 136);
    b.set_fill(0.9, 0.2, 0.2, 1);
    b.fill_ellipse(20, 20, 216, 216);
    b.restore();
    b.set_stroke(0, 0, 0, 1);
    b.set_width(2);
    b.stroke_rect(60, 60, 136, 136);
}

static void scene_clip_circle(Backend &b, int w, int h) {
    s_clear_white(b, w, h);
    b.save();
    b.begin_path();
    b.add_ellipse(40, 40, 176, 176);
    b.clip();
    b.set_fill(0.1, 0.6, 0.3, 1);
    for (int i = 0; i < 12; i++) b.fill_rect(0, i * 22.0, w, 12);
    b.restore();
}

static void scene_save_restore(Backend &b, int w, int h) {
    s_clear_white(b, w, h);
    b.set_fill(1, 0, 0, 1);
    b.save();
    b.translate(40, 40);
    b.set_fill(0, 0, 1, 1);
    b.fill_rect(0, 0, 60, 60);
    b.restore();
    b.fill_rect(120, 40, 60, 60);
}

static void scene_global_alpha(Backend &b, int w, int h) {
    s_clear_white(b, w, h);
    b.set_fill(0, 0, 1, 1);
    b.set_alpha(0.35);
    b.fill_rect(40, 40, 140, 140);
    b.set_alpha(1);
    b.set_fill(1, 0, 0, 1);
    b.fill_rect(90, 90, 140, 140);
}

static void scene_blend_modes(Backend &b, int w, int h) {
    s_clear_white(b, w, h);
    QZBlendMode modes[] = {
        kQZBlendModeNormal, kQZBlendModeMultiply, kQZBlendModeScreen,
        kQZBlendModeOverlay, kQZBlendModeDarken, kQZBlendModeLighten
    };
    for (int i = 0; i < 6; i++) {
        double x = 16 + (i % 3) * 80;
        double y = 30 + (i / 3) * 110;
        b.set_blend(kQZBlendModeNormal);
        b.set_fill(1, 0.2, 0.2, 1);
        b.fill_rect(x, y, 50, 50);
        b.set_blend(modes[i]);
        b.set_fill(0.2, 0.3, 1, 0.85);
        b.fill_rect(x + 18, y + 18, 50, 50);
    }
}

static void scene_linear_gradient(Backend &b, int w, int h) {
    s_clear_white(b, w, h);
    b.save();
    b.clip_rect(20, 20, 216, 216);
    double loc[] = {0, 0.5, 1};
    double col[] = {1, 0, 0, 1,  1, 1, 0, 1,  0, 0.3, 1, 1};
    b.draw_linear(loc, col, 3, 20, 20, 236, 236,
                  kQZGradientDrawsBeforeStartLocation | kQZGradientDrawsAfterEndLocation);
    b.restore();
}

static void scene_radial_gradient(Backend &b, int w, int h) {
    s_clear_white(b, w, h);
    b.save();
    b.begin_path();
    b.add_ellipse(20, 20, 216, 216);
    b.clip();
    double loc[] = {0, 1};
    double col[] = {1, 1, 1, 1,  0.1, 0.2, 0.6, 1};
    b.draw_radial(loc, col, 2, 110, 130, 10, 128, 128, 110,
                  kQZGradientDrawsBeforeStartLocation | kQZGradientDrawsAfterEndLocation);
    b.restore();
}

static void scene_image(Backend &b, int w, int h) {
    s_clear_white(b, w, h);
    const int iw = 32, ih = 32;
    std::vector<uint8_t> im(iw * ih * 4);
    for (int y = 0; y < ih; y++) {
        for (int x = 0; x < iw; x++) {
            uint8_t *p = im.data() + (y * iw + x) * 4;
            p[0] = (uint8_t)(x * 8);
            p[1] = (uint8_t)(y * 8);
            p[2] = 180;
            p[3] = 255;
        }
    }
    b.draw_image(im.data(), iw, ih, 32, 32, 192, 192);
}

static void scene_stroke_and_fill(Backend &b, int w, int h) {
    s_clear_white(b, w, h);
    b.set_fill(1, 0.8, 0.2, 1);
    b.set_stroke(0.3, 0.15, 0, 1);
    b.set_width(8);
    b.set_join(kQZLineJoinRound);
    b.begin_path();
    b.move_to(40, 40);
    b.line_to(216, 40);
    b.line_to(128, 216);
    b.close_path();
    b.fill_stroke();
}

static void scene_rounded_rect(Backend &b, int w, int h) {
    s_clear_white(b, w, h);
    b.set_fill(0.15, 0.45, 0.75, 1);
    double x = 36, y = 48, rw = 184, rh = 160, r = 28;
    b.begin_path();
    b.move_to(x + r, y);
    b.line_to(x + rw - r, y);
    b.add_arc_to(x + rw, y, x + rw, y + r, r);
    b.line_to(x + rw, y + rh - r);
    b.add_arc_to(x + rw, y + rh, x + rw - r, y + rh, r);
    b.line_to(x + r, y + rh);
    b.add_arc_to(x, y + rh, x, y + rh - r, r);
    b.line_to(x, y + r);
    b.add_arc_to(x, y, x + r, y, r);
    b.close_path();
    b.fill();
}

static void scene_self_intersect(Backend &b, int w, int h) {
    s_clear_white(b, w, h);
    b.set_fill(0.2, 0.6, 0.3, 0.9);
    b.begin_path();
    b.move_to(40, 40);
    b.line_to(216, 40);
    b.line_to(40, 216);
    b.line_to(216, 216);
    b.close_path();
    b.fill();
}

static void scene_miter_limit(Backend &b, int w, int h) {
    s_clear_white(b, w, h);
    b.set_stroke(0, 0, 0, 1);
    b.set_width(10);
    b.set_join(kQZLineJoinMiter);
    b.set_miter(2);
    b.begin_path();
    b.move_to(30, 40);
    b.line_to(80, 200);
    b.line_to(130, 40);
    b.stroke();
    b.set_miter(20);
    b.begin_path();
    b.move_to(126, 40);
    b.line_to(176, 200);
    b.line_to(226, 40);
    b.stroke();
}

static void scene_overlapping(Backend &b, int w, int h) {
    s_clear_white(b, w, h);
    b.set_fill(1, 0, 0, 0.4);
    b.fill_ellipse(30, 40, 140, 140);
    b.set_fill(0, 1, 0, 0.4);
    b.fill_ellipse(90, 40, 140, 140);
    b.set_fill(0, 0, 1, 0.4);
    b.fill_ellipse(60, 90, 140, 140);
}

static void scene_ctm_concat(Backend &b, int w, int h) {
    s_clear_white(b, w, h);
    QZAffineTransform t = QZAffineTransformMakeRotation(0.25);
    t = QZAffineTransformTranslate(t, 80, 70);
    t = QZAffineTransformScale(t, 1.2, 1.2);
    b.concat(t);
    b.set_fill(0.6, 0.1, 0.5, 1);
    b.fill_rect(0, 0, 80, 50);
    b.set_stroke(0, 0, 0, 1);
    b.set_width(3);
    b.begin_path();
    b.move_to(0, 0);
    b.line_to(80, 50);
    b.stroke();
}

static void scene_diamond(Backend &b, int w, int h) {
    s_clear_white(b, w, h);
    b.set_fill(0.05, 0.05, 0.05, 1);
    b.begin_path();
    b.move_to(128, 30);
    b.line_to(226, 128);
    b.line_to(128, 226);
    b.line_to(30, 128);
    b.close_path();
    b.fill();
}

static void scene_shadow(Backend &b, int w, int h) {
    s_clear_white(b, w, h);
    b.set_shadow(6, -8, 0, 0, 0, 0, 0.4);
    b.set_fill(0.2, 0.45, 0.9, 1);
    b.fill_rect(50, 70, 120, 80);
}

static void scene_shadow_blur(Backend &b, int w, int h) {
    s_clear_white(b, w, h);
    b.set_shadow(4, -6, 6, 0, 0, 0, 0.5);
    b.set_fill(0.85, 0.2, 0.15, 1);
    b.fill_ellipse(60, 60, 130, 130);
}

static void scene_transparency_group(Backend &b, int w, int h) {
    s_clear_white(b, w, h);
    b.set_alpha(0.5);
    b.begin_transparency();
    b.set_alpha(1);
    b.set_fill(1, 0, 0, 1);
    b.fill_rect(40, 40, 120, 120);
    b.set_fill(0, 0, 1, 1);
    b.fill_rect(90, 90, 120, 120);
    b.end_transparency();
}

static void scene_nested_clip(Backend &b, int w, int h) {
    s_clear_white(b, w, h);
    b.save();
    b.clip_rect(40, 40, 176, 176);
    b.save();
    b.begin_path();
    b.add_ellipse(20, 20, 216, 216);
    b.clip();
    b.set_fill(0.1, 0.6, 0.4, 1);
    b.fill_rect(0, 0, w, h);
    b.restore();
    b.restore();
}

static void scene_h_v_strokes(Backend &b, int w, int h) {
    s_clear_white(b, w, h);
    b.set_stroke(0, 0, 0, 1);
    b.set_cap(kQZLineCapButt);
    b.set_width(1);
    b.begin_path(); b.move_to(20, 200); b.line_to(236, 200); b.stroke();
    b.set_width(2);
    b.begin_path(); b.move_to(20, 170); b.line_to(236, 170); b.stroke();
    b.set_width(4);
    b.begin_path(); b.move_to(20, 130); b.line_to(236, 130); b.stroke();
    b.set_width(1);
    b.begin_path(); b.move_to(60, 20); b.line_to(60, 236); b.stroke();
    b.set_width(2);
    b.begin_path(); b.move_to(100, 20); b.line_to(100, 236); b.stroke();
    b.set_width(8);
    b.begin_path(); b.move_to(160, 20); b.line_to(160, 236); b.stroke();
}

static const Scene kScenes[] = {
    {"fill_rects", scene_fill_rects},
    {"fill_rects_alpha", scene_fill_rects_alpha},
    {"subpixel_rects", scene_subpixel_rects},
    {"nested_eofill", scene_nested_eofill},
    {"nested_winding", scene_nested_winding},
    {"opposite_winding", scene_opposite_winding},
    {"triangle", scene_triangle},
    {"star_eofill", scene_star_eofill},
    {"circle_fill", scene_circle_fill},
    {"circle_stroke", scene_circle_stroke},
    {"ellipse", scene_ellipse},
    {"line_caps", scene_line_caps},
    {"line_joins", scene_line_joins},
    {"thick_polyline", scene_thick_polyline},
    {"thin_lines", scene_thin_lines},
    {"dashed", scene_dashed},
    {"cubic", scene_cubic},
    {"quad", scene_quad},
    {"arcs", scene_arcs},
    {"arc_to", scene_arc_to},
    {"rotate", scene_rotate},
    {"scale_translate", scene_scale_translate},
    {"clip_rect", scene_clip_rect},
    {"clip_circle", scene_clip_circle},
    {"save_restore", scene_save_restore},
    {"global_alpha", scene_global_alpha},
    {"blend_modes", scene_blend_modes},
    {"linear_gradient", scene_linear_gradient},
    {"radial_gradient", scene_radial_gradient},
    {"image", scene_image},
    {"stroke_and_fill", scene_stroke_and_fill},
    {"rounded_rect", scene_rounded_rect},
    {"self_intersect", scene_self_intersect},
    {"miter_limit", scene_miter_limit},
    {"overlapping", scene_overlapping},
    {"ctm_concat", scene_ctm_concat},
    {"diamond", scene_diamond},
    {"h_v_strokes", scene_h_v_strokes},
    {"shadow", scene_shadow},
    {"shadow_blur", scene_shadow_blur},
    {"transparency_group", scene_transparency_group},
    {"nested_clip", scene_nested_clip},
};

const Scene *all_scenes(int *count) {
    *count = (int)(sizeof(kScenes) / sizeof(kScenes[0]));
    return kScenes;
}
