#include "qz_internal.hpp"

using namespace qz;

void qz_shape_paint_stroke(QZLayer *layer, QZContext *ctx);

QZLayerRef QZLayerCreate(void) { return new QZLayer(); }
QZLayerRef QZShapeLayerCreate(void) {
    auto *l = new QZLayer();
    l->kind = QZLayerKindInternal::Shape;
    return l;
}
QZLayerRef QZGradientLayerCreate(void) {
    auto *l = new QZLayer();
    l->kind = QZLayerKindInternal::Gradient;
    l->grad_colors = {{0, 0, 0, 1}, {1, 1, 1, 1}};
    l->grad_locs = {0, 1};
    return l;
}
void QZLayerRelease(QZLayerRef layer) {
    if (!layer) return;
    /* Drop sampled animations so a later allocation that reuses this
     * pointer does not inherit the previous layer's timeline. */
    QZLayerRemoveAllAnimations(layer);
    /* Sublayers are not owned uniquely if the test harness keeps pointers;
       only delete this node. Callers must release children themselves. */
    delete layer;
}

void QZLayerSetBounds(QZLayerRef layer, QZRect bounds) {
    if (layer) layer->bounds = bounds;
}
void QZLayerSetPosition(QZLayerRef layer, QZPoint position) {
    if (layer) layer->position = position;
}
void QZLayerSetAnchorPoint(QZLayerRef layer, QZPoint anchor) {
    if (layer) layer->anchor = anchor;
}
void QZLayerSetFrame(QZLayerRef layer, QZRect frame) {
    if (!layer) return;
    layer->bounds.size = frame.size;
    layer->bounds.origin = {0, 0};
    layer->position = {
        frame.origin.x + layer->anchor.x * frame.size.width,
        frame.origin.y + layer->anchor.y * frame.size.height
    };
}
void QZLayerSetZPosition(QZLayerRef layer, QZFloat z) {
    if (layer) layer->z_position = z;
}
void QZLayerSetAffineTransform(QZLayerRef layer, QZAffineTransform t) {
    if (layer) layer->transform = QZTransform3DMakeAffineTransform(t);
}
void QZLayerSetTransform(QZLayerRef layer, QZTransform3D t) {
    if (layer) layer->transform = t;
}
void QZLayerSetBackgroundColor(QZLayerRef layer, QZFloat r, QZFloat g, QZFloat b, QZFloat a) {
    if (layer) layer->background = {r, g, b, a};
}
void QZLayerSetOpacity(QZLayerRef layer, QZFloat opacity) {
    if (layer) layer->opacity = clampd(opacity, 0, 1);
}
void QZLayerSetCornerRadius(QZLayerRef layer, QZFloat radius) {
    if (layer) layer->corner_radius = std::max(0.0, (double)radius);
}
void QZLayerSetBorderWidth(QZLayerRef layer, QZFloat width) {
    if (layer) layer->border_width = std::max(0.0, (double)width);
}
void QZLayerSetBorderColor(QZLayerRef layer, QZFloat r, QZFloat g, QZFloat b, QZFloat a) {
    if (layer) layer->border_color = {r, g, b, a};
}
void QZLayerSetMasksToBounds(QZLayerRef layer, bool masks) {
    if (layer) layer->masks_to_bounds = masks;
}
void QZLayerSetHidden(QZLayerRef layer, bool hidden) {
    if (layer) layer->hidden = hidden;
}
void QZLayerAddSublayer(QZLayerRef layer, QZLayerRef child) {
    if (!layer || !child) return;
    if (child->superlayer) QZLayerRemoveFromSuperlayer(child);
    layer->sublayers.push_back(child);
    child->superlayer = layer;
}
void QZLayerSetContents(QZLayerRef layer, QZImageRef image) {
    if (layer) layer->contents = image;
}

void QZShapeLayerSetPath(QZLayerRef layer, QZPathRef path) {
    if (layer && path) layer->shape_path = path->p;
}
void QZShapeLayerSetFillColor(QZLayerRef layer, QZFloat r, QZFloat g, QZFloat b, QZFloat a) {
    if (layer) layer->shape_fill = {r, g, b, a};
}
void QZShapeLayerSetStrokeColor(QZLayerRef layer, QZFloat r, QZFloat g, QZFloat b, QZFloat a) {
    if (layer) layer->shape_stroke = {r, g, b, a};
}
void QZShapeLayerSetLineWidth(QZLayerRef layer, QZFloat width) {
    if (layer) layer->shape_line_width = width;
}
void QZShapeLayerSetFillEvenOdd(QZLayerRef layer, bool even_odd) {
    if (layer) layer->shape_eo = even_odd;
}
void QZShapeLayerSetLineCap(QZLayerRef layer, QZLineCap cap) {
    if (layer) layer->shape_cap = cap;
}
void QZShapeLayerSetLineJoin(QZLayerRef layer, QZLineJoin join) {
    if (layer) layer->shape_join = join;
}

void QZGradientLayerSetColors(QZLayerRef layer, const QZFloat *rgba, const QZFloat *locations, int n) {
    if (!layer || n < 2) return;
    layer->grad_colors.clear();
    layer->grad_locs.clear();
    for (int i = 0; i < n; i++) {
        layer->grad_colors.push_back({rgba[i * 4], rgba[i * 4 + 1], rgba[i * 4 + 2], rgba[i * 4 + 3]});
        layer->grad_locs.push_back(locations ? locations[i] : (n == 1 ? 0 : (double)i / (n - 1)));
    }
}
void QZGradientLayerSetStartPoint(QZLayerRef layer, QZPoint p) {
    if (layer) layer->grad_start = p;
}
void QZGradientLayerSetEndPoint(QZLayerRef layer, QZPoint p) {
    if (layer) layer->grad_end = p;
}
void QZGradientLayerSetRadial(QZLayerRef layer, bool radial) {
    if (layer) layer->grad_radial = radial;
}

static void rounded_or_rect(QZContextRef ctx, QZRect r, double radius,
                            uint32_t masked_corners) {
    masked_corners &= 0x0fu;
    if (radius <= 0.5 || masked_corners == 0) {
        QZContextAddRect(ctx, r);
        return;
    }
    double half = std::min(std::fabs(r.size.width), std::fabs(r.size.height)) * 0.5;
    if (masked_corners == 0x0f && radius <= half) {
        QZContextAddRoundedRect(ctx, r, radius);
        return;
    }
    /* CoreAnimation does NOT clamp layer cornerRadius to half the smaller
     * side (iOS 26): an oversized radius produces the classic
     * self-intersecting kappa rounded-rect (spikes past the corners, a
     * four-pointed star hole under non-zero winding) drawn outside the
     * bounds. Build the unclamped kappa construction directly; for
     * radius <= min(w,h)/2 this is identical to QZContextAddRoundedRect. */
    const double k = 0.5522847498307936;
    double kr = k * radius;
    double x0 = r.origin.x, y0 = r.origin.y;
    double x1 = x0 + r.size.width, y1 = y0 + r.size.height;
    bool min_x_min_y = masked_corners & 0x01;
    bool max_x_min_y = masked_corners & 0x02;
    bool min_x_max_y = masked_corners & 0x04;
    bool max_x_max_y = masked_corners & 0x08;
    QZContextMoveToPoint(ctx, x0 + (min_x_min_y ? radius : 0), y0);
    QZContextAddLineToPoint(ctx, x1 - (max_x_min_y ? radius : 0), y0);
    if (max_x_min_y) {
        QZContextAddCurveToPoint(ctx, x1 - radius + kr, y0,
                                 x1, y0 + radius - kr, x1, y0 + radius);
    } else {
        QZContextAddLineToPoint(ctx, x1, y0);
    }
    QZContextAddLineToPoint(ctx, x1, y1 - (max_x_max_y ? radius : 0));
    if (max_x_max_y) {
        QZContextAddCurveToPoint(ctx, x1, y1 - radius + kr,
                                 x1 - radius + kr, y1, x1 - radius, y1);
    } else {
        QZContextAddLineToPoint(ctx, x1, y1);
    }
    QZContextAddLineToPoint(ctx, x0 + (min_x_max_y ? radius : 0), y1);
    if (min_x_max_y) {
        QZContextAddCurveToPoint(ctx, x0 + radius - kr, y1,
                                 x0, y1 - radius + kr, x0, y1 - radius);
    } else {
        QZContextAddLineToPoint(ctx, x0, y1);
    }
    QZContextAddLineToPoint(ctx, x0, y0 + (min_x_min_y ? radius : 0));
    if (min_x_min_y) {
        QZContextAddCurveToPoint(ctx, x0, y0 + radius - kr,
                                 x0 + radius - kr, y0, x0 + radius, y0);
    } else {
        QZContextAddLineToPoint(ctx, x0, y0);
    }
    QZContextClosePath(ctx);
}

/* CAGradientLayer interpolates in Apple Generic RGB (ICC gamma 461/256,
 * Generic RGB primaries), not sRGB. Matrices are linear sRGB ↔ linear
 * Generic RGB from the system ICC XYZ D50 tags. */
static double ca_srgb_to_lin(double c) {
    c = clampd(c, 0, 1);
    return c <= 0.04045 ? c / 12.92 : std::pow((c + 0.055) / 1.055, 2.4);
}
static double ca_lin_to_srgb(double c) {
    c = std::max(0.0, c);
    return c <= 0.0031308 ? 12.92 * c : 1.055 * std::pow(c, 1.0 / 2.4) - 0.055;
}
static constexpr double kCAGenericGamma = 461.0 / 256.0; /* ICC u8Fixed8 1.8 */
static constexpr double kCASrgbToGenLin[3][3] = {
    {9.7484917974770069e-01, 2.7309556109666667e-02, -2.1511098458265321e-03},
    {-2.0014545215952678e-02, 1.0541919927631225e+00, -3.4223538833221240e-02},
    {1.6844140792443146e-03, 1.5574332292297977e-03, 9.9674259518806707e-01},
};
static constexpr double kCAGenLinToSrgb[3][3] = {
    {1.0252521192065480e+00, -2.6561770636452719e-02, 1.3006288137804073e-03},
    {1.9407870427636215e-02, 9.4804288464073738e-01, 3.2593300513153081e-02},
    {-1.7629181045961113e-03, -1.4364515751175389e-03, 1.0032149244355040e+00},
};
static void ca_matmul(const double m[3][3], double x, double y, double z,
                      double *ox, double *oy, double *oz) {
    *ox = m[0][0] * x + m[0][1] * y + m[0][2] * z;
    *oy = m[1][0] * x + m[1][1] * y + m[1][2] * z;
    *oz = m[2][0] * x + m[2][1] * y + m[2][2] * z;
}
static Color ca_srgb_to_generic(Color c) {
    double lr = ca_srgb_to_lin(c.r), lg = ca_srgb_to_lin(c.g), lb = ca_srgb_to_lin(c.b);
    double x, y, z;
    ca_matmul(kCASrgbToGenLin, lr, lg, lb, &x, &y, &z);
    double inv_g = 1.0 / kCAGenericGamma;
    return {std::pow(std::max(x, 0.0), inv_g), std::pow(std::max(y, 0.0), inv_g),
            std::pow(std::max(z, 0.0), inv_g), c.a};
}
static Color ca_generic_to_srgb(Color c) {
    double x = std::pow(std::max(c.r, 0.0), kCAGenericGamma);
    double y = std::pow(std::max(c.g, 0.0), kCAGenericGamma);
    double z = std::pow(std::max(c.b, 0.0), kCAGenericGamma);
    double lr, lg, lb;
    ca_matmul(kCAGenLinToSrgb, x, y, z, &lr, &lg, &lb);
    return {ca_lin_to_srgb(lr), ca_lin_to_srgb(lg), ca_lin_to_srgb(lb), c.a};
}
static Color ca_grad_sample(const std::vector<double> &stops,
                            const std::vector<Color> &cols, double t) {
    if (cols.empty()) return {};
    if (t <= stops.front()) return cols.front();
    if (t >= stops.back()) return cols.back();
    for (size_t i = 1; i < stops.size(); i++) {
        if (t <= stops[i]) {
            double span = stops[i] - stops[i - 1] + 1e-15;
            double u = (t - stops[i - 1]) / span;
            Color a = ca_srgb_to_generic(cols[i - 1]);
            Color b = ca_srgb_to_generic(cols[i]);
            Color g{a.r + (b.r - a.r) * u, a.g + (b.g - a.g) * u,
                    a.b + (b.b - a.b) * u, a.a + (b.a - a.a) * u};
            Color out = ca_generic_to_srgb(g);
            out.a = g.a;
            return out;
        }
    }
    return cols.back();
}

static bool t3d_is_identity(const QZTransform3D &t) {
    return std::fabs(t.m11 - 1) < 1e-12 && std::fabs(t.m12) < 1e-12 &&
           std::fabs(t.m13) < 1e-12 && std::fabs(t.m14) < 1e-12 &&
           std::fabs(t.m21) < 1e-12 && std::fabs(t.m22 - 1) < 1e-12 &&
           std::fabs(t.m23) < 1e-12 && std::fabs(t.m24) < 1e-12 &&
           std::fabs(t.m31) < 1e-12 && std::fabs(t.m32) < 1e-12 &&
           std::fabs(t.m33 - 1) < 1e-12 && std::fabs(t.m34) < 1e-12 &&
           std::fabs(t.m41) < 1e-12 && std::fabs(t.m42) < 1e-12 &&
           std::fabs(t.m43) < 1e-12 && std::fabs(t.m44 - 1) < 1e-12;
}

/* Map contents (after contentsRect / contentsScale) into bounds via gravity. */
static QZRect contents_dest_rect(const QZLayer *layer) {
    QZRect b = layer->bounds;
    const QZImage *img = layer->contents;
    double scale = layer->contents_scale > 1e-12 ? layer->contents_scale : 1.0;
    double crw = layer->contents_rect.size.width;
    double crh = layer->contents_rect.size.height;
    double iw = (img->width / scale) * crw;
    double ih = (img->height / scale) * crh;
    double bw = b.size.width, bh = b.size.height;
    QZContentsGravity g = layer->contents_gravity;
    if (g == kQZContentsGravityResize || iw <= 1e-12 || ih <= 1e-12)
        return b;
    if (g == kQZContentsGravityResizeAspect || g == kQZContentsGravityResizeAspectFill) {
        double s = (g == kQZContentsGravityResizeAspect)
                       ? std::min(bw / iw, bh / ih)
                       : std::max(bw / iw, bh / ih);
        double w = iw * s, h = ih * s;
        return QZRectMake(b.origin.x + (bw - w) * 0.5, b.origin.y + (bh - h) * 0.5, w, h);
    }
    double w = iw, h = ih;
    double x = b.origin.x + (bw - w) * 0.5;
    double y = b.origin.y + (bh - h) * 0.5;
    if (g == kQZContentsGravityTop) y = b.origin.y + bh - h;
    else if (g == kQZContentsGravityBottom) y = b.origin.y;
    else if (g == kQZContentsGravityLeft) x = b.origin.x;
    else if (g == kQZContentsGravityRight) x = b.origin.x + bw - w;
    return QZRectMake(x, y, w, h);
}

static void draw_layer_contents(QZLayer *layer, QZContextRef ctx) {
    if (!layer->contents) return;
    QZRect dest = contents_dest_rect(layer);
    if (dest.size.width <= 0 || dest.size.height <= 0) return;
    QZRect cr = layer->contents_rect;
    bool full = std::fabs(cr.origin.x) < 1e-12 && std::fabs(cr.origin.y) < 1e-12 &&
                std::fabs(cr.size.width - 1) < 1e-12 && std::fabs(cr.size.height - 1) < 1e-12;
    if (full) {
        QZContextDrawImage(ctx, dest, layer->contents);
        return;
    }
    if (cr.size.width <= 1e-12 || cr.size.height <= 1e-12) return;
    QZRect fullr = QZRectMake(
        dest.origin.x - cr.origin.x * dest.size.width / cr.size.width,
        dest.origin.y - cr.origin.y * dest.size.height / cr.size.height,
        dest.size.width / cr.size.width,
        dest.size.height / cr.size.height);
    QZContextSaveGState(ctx);
    QZContextClipToRect(ctx, dest);
    QZContextDrawImage(ctx, fullr, layer->contents);
    QZContextRestoreGState(ctx);
}

static void render_layer(QZLayer *layer, QZContextRef ctx);

/* Apply the mask layer's alpha to the already-composited layer group.
 *
 * CALayer.mask is an outer alpha mask: it covers the layer shadow as well
 * as the layer's content, sublayers and border, and partial mask alpha is
 * multiplied into that final composite once. Applying mask alpha through
 * the drawing clip would be observably wrong when shadow and content
 * overlap because each operation would be attenuated separately. */
static void apply_layer_mask(QZLayer *layer, QZContextRef ctx) {
    if (!layer->mask || layer->mask == layer || ctx->trans.empty()) return;
    QZContextRef mctx = QZBitmapContextCreate(
        nullptr, (size_t)ctx->width, (size_t)ctx->height, 8, ctx->bpr,
        kQZImageAlphaPremultipliedLast);
    if (!mctx) return;
    mctx->gs.ctm = ctx->gs.ctm;
    mctx->gs.antialias = ctx->gs.antialias;
    render_layer(layer->mask, mctx);
    uint8_t *group = ctx->pixels;
    const uint8_t *mp = mctx->pixels;
    for (int y = 0; y < ctx->height; y++) {
        for (int x = 0; x < ctx->width; x++) {
            size_t gi = (size_t)y * ctx->bpr + (size_t)x * 4;
            uint8_t ma = mp[(size_t)y * mctx->bpr + (size_t)x * 4 + 3];
            group[gi + 0] = mul255(group[gi + 0], ma);
            group[gi + 1] = mul255(group[gi + 1], ma);
            group[gi + 2] = mul255(group[gi + 2], ma);
            group[gi + 3] = mul255(group[gi + 3], ma);
        }
    }
    QZContextRelease(mctx);
}

/* CoreAnimation shadow semantics (verified against Mac Catalyst):
 * shadowRadius is a Gaussian sigma in the layer's user-space units. QZ's
 * shadow blur parameter is in DEVICE pixels with sigma = blur/2, so the
 * blur is 2 * radius scaled by the CTM in effect when the casting shape
 * is filled. */
static double ctm_scale(QZContextRef ctx) {
    const QZAffineTransform &m = ctx->gs.ctm;
    return std::sqrt(std::fabs(m.a * m.d - m.b * m.c));
}

static void set_layer_shadow(QZLayer *layer, QZContextRef ctx, double extra_alpha) {
    QZContextSetShadowWithColor(
        ctx, QZSizeMake(layer->layer_shadow_ox, layer->layer_shadow_oy),
        2.0 * layer->layer_shadow_radius * ctm_scale(ctx),
        layer->layer_shadow_color.r, layer->layer_shadow_color.g,
        layer->layer_shadow_color.b,
        layer->layer_shadow_color.a * layer->layer_shadow_opacity * extra_alpha);
}

/* CALayer borders draw ABOVE contents and sublayers, inside the bounds. */
static void draw_border(QZLayer *layer, QZContextRef ctx, QZRect b, double cr) {
    double bw = layer->border_width;
    QZRect inner = QZRectMake(b.origin.x + bw * 0.5, b.origin.y + bw * 0.5,
                              std::max(0.0, b.size.width - bw),
                              std::max(0.0, b.size.height - bw));
    double inner_cr = std::max(0.0, cr - bw * 0.5);
    QZContextSaveGState(ctx);
    if (!layer->edge_antialias) QZContextSetShouldAntialias(ctx, false);
    QZContextSetRGBStrokeColor(ctx, layer->border_color.r, layer->border_color.g,
                               layer->border_color.b, layer->border_color.a);
    QZContextSetLineWidth(ctx, bw);
    QZContextSetLineJoin(ctx, kQZLineJoinMiter);
    QZContextSetLineCap(ctx, kQZLineCapButt);
    QZContextBeginPath(ctx);
    rounded_or_rect(ctx, inner, inner_cr, layer->masked_corners);
    QZContextStrokePath(ctx);
    QZContextRestoreGState(ctx);
}

/* The shadow-casting silhouette: the outer rounded rect when the
 * background is visible, else the border ring (even-odd). Returns whether
 * the built path must be filled even-odd. */
static bool add_shadow_silhouette(QZLayer *layer, QZContextRef ctx,
                                  QZRect b, double cr, bool bg_visible) {
    rounded_or_rect(ctx, b, cr, layer->masked_corners);
    if (bg_visible) return false;
    double bw = layer->border_width;
    QZRect inner = QZRectMake(b.origin.x + bw, b.origin.y + bw,
                              b.size.width - 2 * bw, b.size.height - 2 * bw);
    if (inner.size.width <= 0 || inner.size.height <= 0) return false;
    rounded_or_rect(ctx, inner, std::max(0.0, cr - bw), layer->masked_corners);
    return true;
}

static void render_layer(QZLayer *layer, QZContextRef ctx) {
    if (!layer || layer->hidden || layer->opacity <= 0) return;

    QZContextSaveGState(ctx);
    QZContextTranslateCTM(ctx, layer->position.x, layer->position.y);
    if (QZTransform3DIsAffine(layer->transform)) {
        QZContextConcatCTM(ctx, QZTransform3DGetAffineTransform(layer->transform));
    } else {
        /* Project the linear 2D part; ignore true perspective for v1. */
        QZContextConcatCTM(ctx, QZTransform3DGetAffineTransform(layer->transform));
    }
    double ax = layer->anchor.x * layer->bounds.size.width;
    double ay = layer->anchor.y * layer->bounds.size.height;
    QZContextTranslateCTM(ctx, -(layer->bounds.origin.x + ax),
                          -(layer->bounds.origin.y + ay));

    QZRect b = layer->bounds;
    double cr = layer->corner_radius;

    /* A CALayer mask applies once to the final layer composite, including
     * a grouped shadow. Build that composite offscreen and multiply it by
     * the rendered mask immediately before returning to the destination. */
    bool masked = layer->mask && layer->mask != layer;
    if (masked) QZContextBeginTransparencyLayer(ctx);

    bool bg_visible = layer->background.a > 0.001;
    bool border_visible = layer->border_width > 0 && layer->border_color.a > 0.001;
    /* CA hides the layer shadow while masksToBounds is set, and there is
     * no shadow without a casting silhouette (background or border). */
    bool shadow_on = layer->layer_shadow && !layer->masks_to_bounds &&
                     layer->layer_shadow_color.a * layer->layer_shadow_opacity > 0.001 &&
                     b.size.width > 0 && b.size.height > 0 &&
                     (bg_visible || border_visible);

    bool group = layer->opacity < 0.999;
    double saved_alpha = ctx->gs.alpha;

    if (group && shadow_on) {
        /* Group opacity: CA composites the shadow onto the destination
         * BENEATH the whole group (never occluded by the layer's own
         * content) at strength shadowOpacity * opacity — draw it before
         * the transparency layer opens. The zero-alpha fill leaves exactly
         * the shadow (QZ derives it from geometry coverage). */
        QZContextSaveGState(ctx);
        set_layer_shadow(layer, ctx, layer->opacity);
        QZContextSetRGBFillColor(ctx, 0, 0, 0, 0);
        QZContextBeginPath(ctx);
        bool eo = add_shadow_silhouette(layer, ctx, b, cr, bg_visible);
        if (eo) QZContextEOFillPath(ctx);
        else QZContextFillPath(ctx);
        QZContextRestoreGState(ctx);
    }

    if (group) {
        ctx->gs.alpha = saved_alpha * layer->opacity;
        QZContextBeginTransparencyLayer(ctx);
    }

    if (layer->masks_to_bounds) {
        QZContextBeginPath(ctx);
        rounded_or_rect(ctx, b, cr, layer->masked_corners);
        QZContextClip(ctx);
    }

    if (bg_visible) {
        QZContextSaveGState(ctx);
        if (shadow_on && !group) set_layer_shadow(layer, ctx, 1.0);
        QZContextSetRGBFillColor(ctx, layer->background.r, layer->background.g,
                                 layer->background.b, layer->background.a);
        if (!layer->edge_antialias) QZContextSetShouldAntialias(ctx, false);
        QZContextBeginPath(ctx);
        rounded_or_rect(ctx, b, cr, layer->masked_corners);
        QZContextFillPath(ctx);
        QZContextRestoreGState(ctx);
    } else if (shadow_on && !group && border_visible) {
        /* No background to cast the shadow: the silhouette is the border
         * ring alone. Pre-draw it with the shadow active; the regular
         * border pass repaints the identical ring on top later. */
        QZContextSaveGState(ctx);
        set_layer_shadow(layer, ctx, 1.0);
        draw_border(layer, ctx, b, cr);
        QZContextRestoreGState(ctx);
    }

    if (layer->kind == QZLayerKindInternal::Gradient && layer->grad_colors.size() >= 2) {
        QZContextSaveGState(ctx);
        QZContextBeginPath(ctx);
        rounded_or_rect(ctx, b, cr, layer->masked_corners);
        QZContextClip(ctx);
        std::vector<double> stops(layer->grad_locs.begin(), layer->grad_locs.end());
        std::vector<double> ts;
        ts.reserve(256 + stops.size());
        for (int i = 0; i < 256; i++) ts.push_back((double)i / 255.0);
        for (double s : stops) ts.push_back(s);
        std::sort(ts.begin(), ts.end());
        ts.erase(std::unique(ts.begin(), ts.end(),
                             [](double a, double b) { return std::fabs(a - b) < 1e-9; }),
                 ts.end());
        std::vector<QZFloat> loc(ts.size()), comp(ts.size() * 4);
        for (size_t i = 0; i < ts.size(); i++) {
            Color c = ca_grad_sample(stops, layer->grad_colors, ts[i]);
            loc[i] = (QZFloat)ts[i];
            comp[i * 4 + 0] = c.r;
            comp[i * 4 + 1] = c.g;
            comp[i * 4 + 2] = c.b;
            comp[i * 4 + 3] = c.a;
        }
        QZGradientRef g = QZGradientCreate(loc.data(), comp.data(), ts.size());
        /* startPoint/endPoint are unit-space of bounds, not pixel-aspect
         * Euclidean. Scale so DrawLinearGradient's t matches CA. */
        double bw = std::max(b.size.width, 1e-12);
        double bh = std::max(b.size.height, 1e-12);
        QZContextTranslateCTM(ctx, b.origin.x, b.origin.y);
        QZContextScaleCTM(ctx, bw, bh);
        QZPoint s = layer->grad_start;
        QZPoint e = layer->grad_end;
        uint32_t opt = kQZGradientDrawsBeforeStartLocation | kQZGradientDrawsAfterEndLocation;
        if (layer->grad_conic) {
            double ang = std::atan2(e.y - s.y, e.x - s.x);
            QZContextDrawConicGradient(ctx, g, s, ang, opt);
        } else if (layer->grad_radial) {
            double rx = std::fabs(e.x - s.x), ry = std::fabs(e.y - s.y);
            QZContextDrawRadialGradient(ctx, g, s, 0, s, std::max(rx, ry), opt);
        } else {
            QZContextDrawLinearGradient(ctx, g, s, e, opt);
        }
        QZGradientRelease(g);
        QZContextRestoreGState(ctx);
    }

    if (layer->kind == QZLayerKindInternal::Shape) {
        QZPath tmp;
        tmp.p = layer->shape_path;
        if (layer->shape_fill.a > 0.001) {
            QZContextBeginPath(ctx);
            QZContextAddPath(ctx, &tmp);
            QZContextSetRGBFillColor(ctx, layer->shape_fill.r, layer->shape_fill.g,
                                     layer->shape_fill.b, layer->shape_fill.a);
            if (layer->shape_eo) QZContextEOFillPath(ctx);
            else QZContextFillPath(ctx);
        }
        if (layer->shape_stroke.a > 0.001) {
            qz_shape_paint_stroke(layer, ctx);
        }
    }

    draw_layer_contents(layer, ctx);

    if (layer->kind == QZLayerKindInternal::Text)
        qz_pkg_paint_text_layer(layer, ctx);

    /* renderInContext: paints sublayers in array order (back to front). */
    bool st = !t3d_is_identity(layer->sublayer_transform);
    if (st) {
        QZContextSaveGState(ctx);
        QZContextTranslateCTM(ctx, b.origin.x + ax, b.origin.y + ay);
        QZContextConcatCTM(ctx, QZTransform3DGetAffineTransform(layer->sublayer_transform));
        QZContextTranslateCTM(ctx, -(b.origin.x + ax), -(b.origin.y + ay));
    }
    if (layer->kind == QZLayerKindInternal::Replicator) {
        qz_pkg_replicator_sublayers(layer, ctx, render_layer);
    } else if (layer->kind == QZLayerKindInternal::Transform) {
        qz_pkg_transform_layer_sublayers(layer, ctx, render_layer);
    } else {
        for (QZLayer *c : layer->sublayers) render_layer(c, ctx);
    }
    if (st) QZContextRestoreGState(ctx);

    if (border_visible) {
        draw_border(layer, ctx, b, cr);
    }

    if (group) {
        QZContextEndTransparencyLayer(ctx);
        ctx->gs.alpha = saved_alpha;
    }
    if (masked) {
        apply_layer_mask(layer, ctx);
        QZContextEndTransparencyLayer(ctx);
    }
    QZContextRestoreGState(ctx);
}

void QZLayerRenderInContext(QZLayerRef layer, QZContextRef ctx) {
    if (!layer || !ctx) return;
    render_layer(layer, ctx);
}
