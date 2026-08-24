#include "qz_internal.hpp"
/* OWNED BY package anim-group. */

/* Damped harmonic oscillator remaining-fraction e(t): e(0)=1, e(∞)=0.
 * Animated value = to + (from - to) * e(t). Matches CASpringAnimation. */
static double spring_envelope(double mass, double stiffness, double damping,
                              double v0, double delta, double t) {
    if (t <= 0.0) return 1.0;
    if (!(mass > 0.0) || stiffness < 0.0) return 0.0;

    double omega0 = std::sqrt(stiffness / mass);
    double beta = damping / (2.0 * mass);
    double ve0 = 0.0;
    if (std::fabs(delta) > 1e-20)
        ve0 = v0 / delta;

    double disc = beta * beta - omega0 * omega0;
    const double eps = 1e-12;
    if (disc > eps) {
        double wh = std::sqrt(disc);
        double r1 = -beta + wh;
        double r2 = -beta - wh;
        double A = (ve0 - r2) / (r1 - r2);
        return A * std::exp(r1 * t) + (1.0 - A) * std::exp(r2 * t);
    }
    if (disc < -eps) {
        double wd = std::sqrt(-disc);
        double B = (ve0 + beta) / wd;
        return std::exp(-beta * t) * (std::cos(wd * t) + B * std::sin(wd * t));
    }
    double B = ve0 + omega0;
    return std::exp(-omega0 * t) * (1.0 + B * t);
}

static double lerp_component(const QZAnimation &a, double u, size_t i, double fallback) {
    double kf = 0;
    if (qz_pkg_keyframe_sample(a, u, i, &kf)) return kf;
    double a0 = i < a.from.size() ? (double)a.from[i] : fallback;
    double a1 = i < a.to.size() ? (double)a.to[i] : a0;
    return a0 + (a1 - a0) * u;
}

static void apply_progress(const QZAnimation &a, QZLayer *c, double u) {
    if (a.keyPath == "opacity") {
        c->opacity = lerp_component(a, u, 0, c->opacity);
    } else if (a.keyPath == "position") {
        c->position.x = lerp_component(a, u, 0, c->position.x);
        c->position.y = lerp_component(a, u, 1, c->position.y);
    } else if (a.keyPath == "position.x") {
        c->position.x = lerp_component(a, u, 0, c->position.x);
    } else if (a.keyPath == "position.y") {
        c->position.y = lerp_component(a, u, 0, c->position.y);
    } else if (a.keyPath == "bounds.size") {
        c->bounds.size.width = lerp_component(a, u, 0, c->bounds.size.width);
        c->bounds.size.height = lerp_component(a, u, 1, c->bounds.size.height);
    } else if (a.keyPath == "cornerRadius") {
        c->corner_radius = lerp_component(a, u, 0, c->corner_radius);
    } else if (a.keyPath == "transform.rotation.z" || a.keyPath == "transform.rotation") {
        double ang = lerp_component(a, u, 0, 0);
        c->transform = QZTransform3DMakeRotation(ang, 0, 0, 1);
    }
}

static void apply_one(const QZAnimation &a, QZLayer *copy, double t);

static void apply_spring(const QZAnimation &a, QZLayer *copy, double t) {
    if (a.duration <= 0) {
        apply_progress(a, copy, 1.0);
        return;
    }
    double teval = qz::clampd(t, 0.0, (double)a.duration);
    double from0 = !a.from.empty() ? (double)a.from[0] : 0.0;
    double to0 = !a.to.empty() ? (double)a.to[0] : from0;
    double env = spring_envelope(a.mass, a.stiffness, a.damping,
                                 a.initial_velocity, from0 - to0, teval);
    apply_progress(a, copy, 1.0 - env);
}

static void apply_one(const QZAnimation &a, QZLayer *copy, double t) {
    if (qz_pkg_group_apply(a, copy, t)) return;
    double u = a.duration > 0 ? qz::clampd(t / (double)a.duration, 0, 1) : 1;
    if (a.has_timing)
        u = qz_pkg_cubic_bezier_solve(a.c1x, a.c1y, a.c2x, a.c2y, u);
    apply_progress(a, copy, u);
}

bool qz_pkg_group_apply(const QZAnimation &a, QZLayer *copy, double t) {
    if (!copy) return false;
    if (a.is_group) {
        double tg = a.duration > 0 ? qz::clampd(t, 0.0, (double)a.duration) : std::max(0.0, t);
        if (a.has_timing && a.duration > 0) {
            double u = tg / (double)a.duration;
            u = qz_pkg_cubic_bezier_solve(a.c1x, a.c1y, a.c2x, a.c2y, u);
            tg = u * (double)a.duration;
        }
        for (const auto &child : a.children)
            apply_one(child, copy, tg);
        return true;
    }
    if (a.is_spring) {
        apply_spring(a, copy, t);
        return true;
    }
    return false;
}

QZAnimationRef QZAnimationGroupCreate(void) {
    QZAnimationRef a = QZBasicAnimationCreate("group");
    if (a) a->is_group = true;
    return a;
}
void QZAnimationGroupAddAnimation(QZAnimationRef group, QZAnimationRef child) {
    if (!group || !child) return;
    group->children.push_back(*child);
}
QZAnimationRef QZSpringAnimationCreate(const char *keyPath) {
    QZAnimationRef a = QZBasicAnimationCreate(keyPath);
    if (!a) return nullptr;
    a->is_spring = true;
    a->mass = 1;
    a->stiffness = 100;
    a->damping = 10;
    a->initial_velocity = 0;
    return a;
}
void QZSpringAnimationSetDamping(QZAnimationRef anim, QZFloat damping) {
    if (anim) anim->damping = (double)damping;
}
void QZSpringAnimationSetMass(QZAnimationRef anim, QZFloat mass) {
    if (anim) anim->mass = (double)mass;
}
void QZSpringAnimationSetStiffness(QZAnimationRef anim, QZFloat stiffness) {
    if (anim) anim->stiffness = (double)stiffness;
}
void QZSpringAnimationSetInitialVelocity(QZAnimationRef anim, QZFloat v) {
    if (anim) anim->initial_velocity = (double)v;
}
