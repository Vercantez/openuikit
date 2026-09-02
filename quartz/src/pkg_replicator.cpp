#include "qz_internal.hpp"
/* OWNED BY package replicator. */

QZLayerRef QZReplicatorLayerCreate(void) {
    auto *l = new QZLayer();
    l->kind = QZLayerKindInternal::Replicator;
    l->repl_count = 1;
    l->repl_instance_transform = QZTransform3DIdentity();
    l->repl_instance_color = {1, 1, 1, 1};
    return l;
}
void QZReplicatorLayerSetInstanceCount(QZLayerRef layer, int count) {
    if (layer) layer->repl_count = count < 0 ? 0 : count;
}
void QZReplicatorLayerSetInstanceTransform(QZLayerRef layer, QZTransform3D t) {
    if (layer) layer->repl_instance_transform = t;
}
void QZReplicatorLayerSetInstanceColor(QZLayerRef layer,
                                       QZFloat r, QZFloat g, QZFloat b, QZFloat a) {
    if (layer) layer->repl_instance_color = {r, g, b, a};
}
void QZReplicatorLayerSetInstanceRedOffset(QZLayerRef layer, QZFloat v) {
    if (layer) layer->repl_r_off = v;
}
void QZReplicatorLayerSetInstanceGreenOffset(QZLayerRef layer, QZFloat v) {
    if (layer) layer->repl_g_off = v;
}
void QZReplicatorLayerSetInstanceBlueOffset(QZLayerRef layer, QZFloat v) {
    if (layer) layer->repl_b_off = v;
}
void QZReplicatorLayerSetInstanceAlphaOffset(QZLayerRef layer, QZFloat v) {
    if (layer) layer->repl_a_off = v;
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

void qz_pkg_replicator_sublayers(QZLayer *layer, QZContext *ctx,
                                 void (*render_one)(QZLayer *, QZContext *)) {
    if (!layer || !ctx || !render_one) return;
    int n = layer->repl_count;
    if (n < 1) return;

    /* instanceTransform is about the replicator's anchor, like CALayer.transform. */
    double ox = layer->bounds.origin.x + layer->anchor.x * layer->bounds.size.width;
    double oy = layer->bounds.origin.y + layer->anchor.y * layer->bounds.size.height;

    QZTransform3D acc = QZTransform3DIdentity();
    for (int i = 0; i < n; i++) {
        QZContextSaveGState(ctx);
        if (!t3d_is_identity(acc)) {
            QZContextTranslateCTM(ctx, ox, oy);
            QZContextConcatCTM(ctx, QZTransform3DGetAffineTransform(acc));
            QZContextTranslateCTM(ctx, -ox, -oy);
        }
        /* instanceColor is compositor-only; renderInContext: does not tint. */
        for (QZLayer *c : layer->sublayers) render_one(c, ctx);
        QZContextRestoreGState(ctx);
        acc = QZTransform3DConcat(acc, layer->repl_instance_transform);
    }
}
