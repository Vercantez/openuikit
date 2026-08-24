#include "qz_internal.hpp"
/* OWNED BY package transform-layer. */

QZLayerRef QZTransformLayerCreate(void) {
    auto *l = new QZLayer();
    l->kind = QZLayerKindInternal::Transform;
    return l;
}

/* CATransformLayer renderInContext: flattens like a grouping CALayer:
 * parent transform + sublayerTransform are already on the CTM (qz_layer.cpp),
 * each child then concatenates the affine part of its own transform.
 * Perspective (m34) is ignored at paint, matching the engine's 2D path.
 * Sibling order is sublayer-array order (back to front), not zPosition. */
void qz_pkg_transform_layer_sublayers(QZLayer *layer, QZContext *ctx,
                                      void (*render_one)(QZLayer *, QZContext *)) {
    if (!layer || !ctx || !render_one) return;
    for (QZLayer *c : layer->sublayers) render_one(c, ctx);
}
