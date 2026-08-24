#pragma once

#include "quartz/quartz.h"

#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <string>
#include <vector>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

namespace qz {

constexpr double kPi = 3.14159265358979323846;
constexpr double kTwoPi = 6.28318530717958647692;
constexpr int kAASamples = 64; /* vertical coverage samples per pixel row */

inline double clampd(double v, double lo, double hi) {
    return v < lo ? lo : (v > hi ? hi : v);
}
inline int clampi(int v, int lo, int hi) {
    return v < lo ? lo : (v > hi ? hi : v);
}
inline uint8_t clamp8(int v) {
    return (uint8_t)(v < 0 ? 0 : (v > 255 ? 255 : v));
}
/* 8-bit * 8-bit / 255 with round-to-nearest (Apple premul over). */
inline uint8_t mul255(unsigned a, unsigned b) {
    return (uint8_t)((a * b + 127u) / 255u);
}
inline uint8_t u8_from_unit(double v) {
    v = clampd(v, 0.0, 1.0);
    return (uint8_t)(v * 255.0 + 0.5);
}
inline double hypot2(double x, double y) { return std::sqrt(x * x + y * y); }

struct Vec2 {
    double x = 0, y = 0;
    Vec2() = default;
    Vec2(double x_, double y_) : x(x_), y(y_) {}
    Vec2(QZPoint p) : x(p.x), y(p.y) {}
    QZPoint qz() const { return QZPointMake(x, y); }
    Vec2 operator+(Vec2 o) const { return {x + o.x, y + o.y}; }
    Vec2 operator-(Vec2 o) const { return {x - o.x, y - o.y}; }
    Vec2 operator*(double s) const { return {x * s, y * s}; }
    Vec2 operator-() const { return {-x, -y}; }
};

inline double dot(Vec2 a, Vec2 b) { return a.x * b.x + a.y * b.y; }
inline double cross(Vec2 a, Vec2 b) { return a.x * b.y - a.y * b.x; }
inline double length(Vec2 v) { return hypot2(v.x, v.y); }
inline Vec2 normalized(Vec2 v) {
    double L = length(v);
    if (L < 1e-20) return {0, 0};
    return {v.x / L, v.y / L};
}
/* 90° CCW perpendicular */
inline Vec2 perp(Vec2 v) { return {-v.y, v.x}; }

inline Vec2 apply(const QZAffineTransform &t, Vec2 p) {
    return {t.a * p.x + t.c * p.y + t.tx, t.b * p.x + t.d * p.y + t.ty};
}

enum class PathOp : uint8_t { Move, Line, Cubic, Close };

struct PathCmd {
    PathOp op;
    Vec2 p[3];
};

struct Path {
    int ref = 1;
    std::vector<PathCmd> cmds;
    Vec2 start{0, 0};
    Vec2 current{0, 0};
    bool has_current = false;
    bool subpath_used = false;

    void move_to(Vec2 p);
    void line_to(Vec2 p);
    void cubic_to(Vec2 c1, Vec2 c2, Vec2 p);
    void quad_to(Vec2 c, Vec2 p);
    void close();
    void add_rect(QZRect r);
    void add_rounded_rect(QZRect r, double radius);
    void add_ellipse(QZRect r);
    void add_arc(double x, double y, double radius,
                 double start, double end, int clockwise);
    void add_arc_to(Vec2 p1, Vec2 p2, double radius);
    void append(const Path &other, const QZAffineTransform *m);
    void clear();
};

struct Polyline {
    std::vector<Vec2> pts;
    bool closed = false;
};

/* Flatten in the given (already transformed) space. */
void flatten_path(const Path &path, double flatness, std::vector<Polyline> &out);

/* Stroke polylines in the same space as the points. */
void stroke_polylines(const std::vector<Polyline> &src,
                      double width, QZLineCap cap, QZLineJoin join, double miter_limit,
                      double dash_phase, const std::vector<double> &dash,
                      std::vector<Polyline> &out);

struct Color {
    double r = 0, g = 0, b = 0, a = 0;
};

struct GState {
    QZAffineTransform ctm = {1, 0, 0, 1, 0, 0};
    Color fill{0, 0, 0, 1};
    Color stroke{0, 0, 0, 1};
    double line_width = 1;
    QZLineCap line_cap = kQZLineCapButt;
    QZLineJoin line_join = kQZLineJoinMiter;
    double miter_limit = 10;
    double flatness = 0.6;
    double alpha = 1;
    QZBlendMode blend = kQZBlendModeNormal;
    bool antialias = true;
    QZInterpolationQuality interp = kQZInterpolationDefault;
    double dash_phase = 0;
    std::vector<double> dash;
    std::vector<uint8_t> clip; /* 8-bit, size w*h, 255 = visible */
    bool shadow = false;
    double shadow_ox = 0, shadow_oy = 0, shadow_blur = 0;
    Color shadow_color{0, 0, 0, 1.0 / 3.0};
    QZAffineTransform text_matrix = {1, 0, 0, 1, 0, 0};
    QZPoint text_position{0, 0};
    double font_size = 12;
    char font_name[64] = "Helvetica";
    int text_drawing_mode = 0; /* 0 fill, 1 stroke, 2 fillStroke, 3 clip, 4 clipStroke, 5 fillClip, 6 fillStrokeClip */
};

struct Edge {
    double y0, y1; /* y0 < y1 */
    double x0;
    double dxdy;
    int wind; /* +1 or -1 */
};

void build_edges(const std::vector<Polyline> &polys, std::vector<Edge> &edges);

/* Rasterize polygons into coverage [0,1] for each pixel (row-major, y-down).
 * even_odd selects the fill rule. antialias uses kAASamples; otherwise pixel centers. */
void rasterize(const std::vector<Edge> &edges, int w, int h,
               bool even_odd, bool antialias, float *coverage);

void blend_coverage(uint8_t *dst, int w, int h, size_t bpr,
                    const float *coverage, const uint8_t *clip,
                    Color color, double global_alpha, QZBlendMode mode);

void blend_pixel(uint8_t *dst, uint8_t sr, uint8_t sg, uint8_t sb, uint8_t sa,
                 QZBlendMode mode);

struct Gradient {
    std::vector<double> stops;           /* locations */
    std::vector<Color> colors;           /* non-premul */
    Color sample(double t) const;
};

} /* namespace qz */

struct QZTransLayer {
    std::vector<uint8_t> buf;
    uint8_t *parent = nullptr;
    double group_alpha = 1;
};

struct QZContext {
    int width = 0;
    int height = 0;
    size_t bpr = 0;
    std::vector<uint8_t> owned;
    uint8_t *pixels = nullptr;
    bool owns = false;
    qz::GState gs;
    std::vector<qz::GState> stack;
    qz::Path path;
    std::vector<QZTransLayer> trans;
};

enum class QZLayerKindInternal { Base, Shape, Gradient, Text, Replicator, Transform };

struct QZLayer {
    QZLayerKindInternal kind = QZLayerKindInternal::Base;
    QZRect bounds{{0, 0}, {0, 0}};
    QZPoint position{0, 0};
    QZPoint anchor{0.5, 0.5};
    double z_position = 0;
    QZTransform3D transform{};
    qz::Color background{0, 0, 0, 0};
    double opacity = 1;
    double corner_radius = 0;
    double border_width = 0;
    qz::Color border_color{0, 0, 0, 1};
    bool masks_to_bounds = false;
    bool hidden = false;
    /* CALayer.allowsEdgeAntialiasing: iOS composites transformed layers
     * with hard (non-anti-aliased) background/border edges by default.
     * true (= AA on) preserves historical QZ behavior. */
    bool edge_antialias = true;
    QZImageRef contents = nullptr;
    QZLayer *superlayer = nullptr;
    QZLayer *mask = nullptr;
    QZContentsGravity contents_gravity = kQZContentsGravityResize;
    QZRect contents_rect{{0, 0}, {1, 1}};
    double contents_scale = 1;
    bool layer_shadow = false;
    double layer_shadow_ox = 0, layer_shadow_oy = 0, layer_shadow_radius = 0;
    qz::Color layer_shadow_color{0, 0, 0, 1};
    double layer_shadow_opacity = 0;
    QZTransform3D sublayer_transform{};
    std::vector<QZLayer *> sublayers;
    qz::Path shape_path;
    qz::Color shape_fill{0, 0, 0, 1};
    qz::Color shape_stroke{0, 0, 0, 0};
    bool shape_eo = false;
    double shape_line_width = 1;
    QZLineCap shape_cap = kQZLineCapButt;
    QZLineJoin shape_join = kQZLineJoinMiter;
    double shape_miter = 10;
    double shape_stroke_start = 0, shape_stroke_end = 1;
    double shape_dash_phase = 0;
    std::vector<double> shape_dash;
    std::vector<qz::Color> grad_colors;
    std::vector<double> grad_locs;
    QZPoint grad_start{0.5, 0};
    QZPoint grad_end{0.5, 1};
    bool grad_radial = false;
    bool grad_conic = false;
    std::string text;
    std::string text_font = "Helvetica";
    double text_font_size = 36;
    int text_align = 0; /* 0 natural/left, 1 center, 2 right, 3 justified */
    bool text_wrapped = false;
    qz::Color text_color{0, 0, 0, 1};
    int repl_count = 1;
    QZTransform3D repl_instance_transform{};
    qz::Color repl_instance_color{1, 1, 1, 1};
    double repl_r_off = 0, repl_g_off = 0, repl_b_off = 0, repl_a_off = 0;
    QZLayer() {
        transform = QZTransform3DIdentity();
        sublayer_transform = QZTransform3DIdentity();
        repl_instance_transform = QZTransform3DIdentity();
    }
};

/* Package hooks — implemented in src/pkg_*.cpp */
bool qz_pkg_try_pattern_fill(QZContext *ctx, const std::vector<qz::Polyline> &polys,
                             bool even_odd, qz::Color color);
void qz_pkg_paint_text_layer(QZLayer *layer, QZContext *ctx);
void qz_pkg_replicator_sublayers(QZLayer *layer, QZContext *ctx,
                                 void (*render_one)(QZLayer *, QZContext *));
void qz_pkg_transform_layer_sublayers(QZLayer *layer, QZContext *ctx,
                                      void (*render_one)(QZLayer *, QZContext *));

struct QZPath {
    qz::Path p;
};

struct QZImage {
    int width = 0, height = 0;
    std::vector<uint8_t> rgba; /* premul RGBA */
};

struct QZGradient {
    qz::Gradient g;
};

struct QZAnimation {
    std::string keyPath;
    std::string key;
    std::vector<QZFloat> from, to;
    QZFloat duration = 1;
    bool has_timing = false;
    double c1x = 0, c1y = 0, c2x = 1, c2y = 1;
    std::vector<QZFloat> kf_values, kf_times;
    size_t kf_stride = 1;
    bool is_group = false;
    bool is_spring = false;
    std::vector<QZAnimation> children;
    double mass = 1;
    double stiffness = 100;
    double damping = 10;
    double initial_velocity = 0;
};

double qz_pkg_cubic_bezier_solve(double c1x, double c1y, double c2x, double c2y, double t);
bool qz_pkg_keyframe_sample(const QZAnimation &a, double u, size_t component, double *out);
bool qz_pkg_group_apply(const QZAnimation &a, QZLayer *copy, double t);
