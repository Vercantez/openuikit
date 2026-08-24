#include "qz_internal.hpp"
#include <string>
#include <unordered_map>
/* OWNED BY package anim. */

static std::unordered_map<QZLayer *, std::vector<QZAnimation>> g_anims;

QZAnimationRef QZBasicAnimationCreate(const char *keyPath) {
    auto *a = new QZAnimation();
    a->keyPath = keyPath ? keyPath : "";
    return a;
}
void QZAnimationRelease(QZAnimationRef anim) { delete anim; }
void QZBasicAnimationSetFromValue(QZAnimationRef anim, const QZFloat *v, size_t n) {
    if (!anim) return;
    if (v && n) anim->from.assign(v, v + n);
    else anim->from.clear();
}
void QZBasicAnimationSetToValue(QZAnimationRef anim, const QZFloat *v, size_t n) {
    if (!anim) return;
    if (v && n) anim->to.assign(v, v + n);
    else anim->to.clear();
}
void QZAnimationSetDuration(QZAnimationRef anim, QZFloat duration) {
    if (anim) anim->duration = std::max(0.0, (double)duration);
}
void QZLayerAddAnimation(QZLayerRef layer, QZAnimationRef anim, const char *key) {
    if (!layer || !anim) return;
    QZAnimation copy = *anim;
    copy.key = key ? key : "";
    auto &list = g_anims[layer];
    if (!copy.key.empty()) {
        for (auto it = list.begin(); it != list.end(); ++it) {
            if (it->key == copy.key) {
                *it = copy;
                return;
            }
        }
    }
    list.push_back(copy);
}
void QZLayerRemoveAllAnimations(QZLayerRef layer) {
    if (layer) g_anims.erase(layer);
}

QZFloat QZLayerGetOpacity(QZLayerRef layer) {
    return layer ? (QZFloat)layer->opacity : 0;
}
QZPoint QZLayerGetPosition(QZLayerRef layer) {
    return layer ? layer->position : QZPointMake(0, 0);
}
QZRect QZLayerGetBounds(QZLayerRef layer) {
    return layer ? layer->bounds : QZRectMake(0, 0, 0, 0);
}
QZFloat QZLayerGetCornerRadius(QZLayerRef layer) {
    return layer ? (QZFloat)layer->corner_radius : 0;
}

QZLayerRef QZLayerCopyPresentation(QZLayerRef layer, QZFloat t) {
    if (!layer) return nullptr;
    /* Shallow copy of one layer. sublayers, mask, and contents are pointer-shared
     * with the model; value fields (path, colors, bounds, …) are copied. */
    auto *c = new QZLayer(*layer);
    c->superlayer = nullptr;
    auto it = g_anims.find(layer);
    if (it == g_anims.end()) return c;
    for (const auto &a : it->second) {
        if (qz_pkg_group_apply(a, c, (double)t))
            continue;
        double u = a.duration > 0 ? qz::clampd((double)t / (double)a.duration, 0, 1) : 1;
        if (a.has_timing)
            u = qz_pkg_cubic_bezier_solve(a.c1x, a.c1y, a.c2x, a.c2y, u);
        auto lerp = [&](size_t i, double fallback) {
            double kf = 0;
            if (qz_pkg_keyframe_sample(a, u, i, &kf)) return kf;
            double a0 = i < a.from.size() ? a.from[i] : fallback;
            double a1 = i < a.to.size() ? a.to[i] : a0;
            return a0 + (a1 - a0) * u;
        };
        if (a.keyPath == "opacity") {
            c->opacity = lerp(0, c->opacity);
        } else if (a.keyPath == "position") {
            c->position.x = lerp(0, c->position.x);
            c->position.y = lerp(1, c->position.y);
        } else if (a.keyPath == "position.x") {
            c->position.x = lerp(0, c->position.x);
        } else if (a.keyPath == "position.y") {
            c->position.y = lerp(0, c->position.y);
        } else if (a.keyPath == "bounds.size") {
            c->bounds.size.width = lerp(0, c->bounds.size.width);
            c->bounds.size.height = lerp(1, c->bounds.size.height);
        } else if (a.keyPath == "cornerRadius") {
            c->corner_radius = lerp(0, c->corner_radius);
        } else if (a.keyPath == "transform.rotation.z" || a.keyPath == "transform.rotation") {
            double ang = lerp(0, 0);
            c->transform = QZTransform3DMakeRotation(ang, 0, 0, 1);
        }
    }
    return c;
}

QZLayerRef QZLayerCopyPresentationTree(QZLayerRef layer, QZFloat t) {
    if (!layer) return nullptr;
    QZLayer *p = (QZLayer *)QZLayerCopyPresentation(layer, t);
    std::vector<QZLayer *> kids = p->sublayers;
    p->sublayers.clear();
    for (QZLayer *ch : kids) {
        QZLayer *cp = (QZLayer *)QZLayerCopyPresentationTree(ch, t);
        if (!cp) continue;
        p->sublayers.push_back(cp);
        cp->superlayer = p;
    }
    return p;
}

void QZLayerReleasePresentationTree(QZLayerRef layer) {
    if (!layer) return;
    std::vector<QZLayer *> kids = layer->sublayers;
    layer->sublayers.clear();
    for (QZLayer *ch : kids) {
        ch->superlayer = nullptr;
        QZLayerReleasePresentationTree(ch);
    }
    QZLayerRelease(layer);
}

