#include "qz_internal.hpp"

/* OWNED BY package layer-ext. Wire up the extra fields on QZLayer. */

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

/* Local (bounds) space -> superlayer local space. */
static QZAffineTransform local_to_parent(const QZLayer *layer) {
    double ax = layer->anchor.x * layer->bounds.size.width;
    double ay = layer->anchor.y * layer->bounds.size.height;
    QZAffineTransform t = QZAffineTransformMakeTranslation(
        -(layer->bounds.origin.x + ax), -(layer->bounds.origin.y + ay));
    t = QZAffineTransformConcat(QZTransform3DGetAffineTransform(layer->transform), t);
    t = QZAffineTransformConcat(
        QZAffineTransformMakeTranslation(layer->position.x, layer->position.y), t);
    if (layer->superlayer && !t3d_is_identity(layer->superlayer->sublayer_transform)) {
        const QZLayer *p = layer->superlayer;
        double pax = p->anchor.x * p->bounds.size.width + p->bounds.origin.x;
        double pay = p->anchor.y * p->bounds.size.height + p->bounds.origin.y;
        QZAffineTransform st = QZAffineTransformMakeTranslation(-pax, -pay);
        st = QZAffineTransformConcat(QZTransform3DGetAffineTransform(p->sublayer_transform), st);
        st = QZAffineTransformConcat(QZAffineTransformMakeTranslation(pax, pay), st);
        t = QZAffineTransformConcat(st, t);
    }
    return t;
}

static QZAffineTransform local_to_ancestor(const QZLayer *from, const QZLayer *anc) {
    QZAffineTransform t = QZAffineTransformIdentity();
    for (const QZLayer *l = from; l && l != anc; l = l->superlayer)
        t = QZAffineTransformConcat(local_to_parent(l), t);
    return t;
}

static QZLayer *common_ancestor(QZLayer *a, QZLayer *b) {
    if (!b) return nullptr;
    for (QZLayer *p = a; p; p = p->superlayer)
        for (QZLayer *q = b; q; q = q->superlayer)
            if (p == q) return p;
    return nullptr;
}

void QZLayerRemoveFromSuperlayer(QZLayerRef layer) {
    if (!layer || !layer->superlayer) return;
    auto &v = layer->superlayer->sublayers;
    v.erase(std::remove(v.begin(), v.end(), layer), v.end());
    layer->superlayer = nullptr;
}

void QZLayerInsertSublayer(QZLayerRef layer, QZLayerRef child, int index) {
    if (!layer || !child || child == layer) return;
    for (QZLayer *p = layer->superlayer; p; p = p->superlayer)
        if (p == child) return;
    if (child->superlayer) QZLayerRemoveFromSuperlayer(child);
    if (index < 0) index = 0;
    if (index > (int)layer->sublayers.size()) index = (int)layer->sublayers.size();
    layer->sublayers.insert(layer->sublayers.begin() + index, child);
    child->superlayer = layer;
}

void QZLayerSetMask(QZLayerRef layer, QZLayerRef mask) {
    if (!layer) return;
    if (mask && mask->superlayer) QZLayerRemoveFromSuperlayer(mask);
    layer->mask = mask;
}

void QZLayerSetContentsGravity(QZLayerRef layer, QZContentsGravity gravity) {
    if (layer) layer->contents_gravity = gravity;
}
void QZLayerSetContentsRect(QZLayerRef layer, QZRect rect) {
    if (layer) layer->contents_rect = rect;
}
void QZLayerSetContentsScale(QZLayerRef layer, QZFloat scale) {
    if (layer) layer->contents_scale = scale > 0 ? (double)scale : 1.0;
}
void QZLayerSetShadow(QZLayerRef layer, QZFloat ox, QZFloat oy, QZFloat radius,
                      QZFloat r, QZFloat g, QZFloat b, QZFloat opacity) {
    if (!layer) return;
    layer->layer_shadow = true;
    layer->layer_shadow_ox = ox;
    layer->layer_shadow_oy = oy;
    layer->layer_shadow_radius = radius;
    layer->layer_shadow_color = {r, g, b, 1};
    layer->layer_shadow_opacity = qz::clampd(opacity, 0, 1);
}
QZPoint QZLayerConvertPointToLayer(QZLayerRef from, QZPoint p, QZLayerRef to) {
    if (!from || from == to) return p;
    QZLayer *anc = common_ancestor(from, to);
    p = QZPointApplyAffineTransform(p, local_to_ancestor(from, anc));
    if (!to) return p;
    QZAffineTransform down = local_to_ancestor(to, anc);
    return QZPointApplyAffineTransform(p, QZAffineTransformInvert(down));
}
void QZLayerSetSublayerTransform(QZLayerRef layer, QZTransform3D t) {
    if (layer) layer->sublayer_transform = t;
}
