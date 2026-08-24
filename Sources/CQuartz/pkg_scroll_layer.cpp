#include "qz_internal.hpp"
/* OWNED BY package scroll-layer. */

/* CAScrollLayer.scrollToPoint: sets bounds.origin so that point of the
 * scroll layer's coordinate system moves to the origin of the visible
 * bounds. render_layer already maps bounds.origin through the CTM, so
 * sublayers shift without a paint hook. masksToBounds defaults to YES. */

QZLayerRef QZScrollLayerCreate(void) {
    auto *l = new QZLayer();
    l->masks_to_bounds = true;
    return l;
}

void QZScrollLayerScrollToPoint(QZLayerRef layer, QZPoint p) {
    if (layer) layer->bounds.origin = p;
}

static double scroll_axis(double vis0, double vis, double r0, double r) {
    if (r <= vis) {
        if (r0 < vis0) return r0;
        if (r0 + r > vis0 + vis) return r0 + r - vis;
        return vis0;
    }
    if (vis0 < r0) return r0;
    if (vis0 + vis > r0 + r) return r0 + r - vis;
    return vis0;
}

void QZScrollLayerScrollToRect(QZLayerRef layer, QZRect r) {
    if (!layer) return;
    QZRect b = layer->bounds;
    QZPoint p;
    p.x = scroll_axis(b.origin.x, b.size.width, r.origin.x, r.size.width);
    p.y = scroll_axis(b.origin.y, b.size.height, r.origin.y, r.size.height);
    layer->bounds.origin = p;
}

QZPoint QZScrollLayerGetScrollOffset(QZLayerRef layer) {
    return layer ? layer->bounds.origin : QZPointMake(0, 0);
}
