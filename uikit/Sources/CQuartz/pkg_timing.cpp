#include "qz_internal.hpp"
#include <unordered_map>
/* OWNED BY package timing. */

struct QZMediaTimingFunction {
    QZFloat c1x = 0, c1y = 0, c2x = 1, c2y = 1;
};

static std::unordered_map<QZAnimationRef, QZMediaTimingFunction> g_anim_tf;

/* Unit cubic Bezier (0,0)→(1,1) with controls (c1x,c1y),(c2x,c2y).
 * Coefficients of X(u) = ax u^3 + bx u^2 + cx u  (same for Y). */
static void unit_bezier_coeff(double p1, double p2,
                              double *a, double *b, double *c) {
    *c = 3.0 * p1;
    *b = 3.0 * (p2 - p1) - *c;
    *a = 1.0 - *c - *b;
}
static double sample_poly(double a, double b, double c, double u) {
    return ((a * u + b) * u + c) * u;
}
static double sample_poly_d(double a, double b, double c, double u) {
    return (3.0 * a * u + 2.0 * b) * u + c;
}

/* Solve X(u)=t for u in [0,1], then return Y(u). Newton + bisection. */
double qz_pkg_cubic_bezier_solve(double c1x, double c1y, double c2x, double c2y, double t) {
    t = qz::clampd(t, 0.0, 1.0);
    if (t <= 0.0) return 0.0;
    if (t >= 1.0) return 1.0;
    /* Linear unit curve: X(u)=u, Y(u)=u. */
    if (c1x == c1y && c2x == c2y) return t;

    double ax, bx, cx, ay, by, cy;
    unit_bezier_coeff(c1x, c2x, &ax, &bx, &cx);
    unit_bezier_coeff(c1y, c2y, &ay, &by, &cy);

    const double eps = 1e-6;
    double u = t;
    bool newton_ok = false;
    for (int i = 0; i < 8; i++) {
        double x = sample_poly(ax, bx, cx, u) - t;
        if (std::fabs(x) < eps) {
            newton_ok = true;
            break;
        }
        double dx = sample_poly_d(ax, bx, cx, u);
        if (std::fabs(dx) < 1e-6) break;
        u = u - x / dx;
        if (u < 0.0) u = 0.0;
        else if (u > 1.0) u = 1.0;
    }
    if (!newton_ok) {
        double lo = 0.0, hi = 1.0;
        u = t;
        for (int i = 0; i < 24; i++) {
            double x = sample_poly(ax, bx, cx, u);
            if (std::fabs(x - t) < eps) break;
            if (x < t) lo = u;
            else hi = u;
            u = 0.5 * (lo + hi);
        }
    }
    return sample_poly(ay, by, cy, u);
}

bool qz_pkg_keyframe_sample(const QZAnimation &a, double u, size_t component, double *out) {
    if (!out) return false;
    size_t stride = a.kf_stride ? a.kf_stride : 1;
    if (a.kf_values.size() < stride) return false;
    if (component >= stride) return false;
    size_t nkeys = a.kf_values.size() / stride;
    if (nkeys == 0) return false;

    u = qz::clampd(u, 0.0, 1.0);
    if (nkeys == 1) {
        *out = (double)a.kf_values[component];
        return true;
    }

    bool even = a.kf_times.size() != nkeys;
    auto time_at = [&](size_t i) -> double {
        if (!even) return qz::clampd((double)a.kf_times[i], 0.0, 1.0);
        return (double)i / (double)(nkeys - 1);
    };

    if (u <= time_at(0)) {
        *out = (double)a.kf_values[component];
        return true;
    }
    if (u >= time_at(nkeys - 1)) {
        *out = (double)a.kf_values[(nkeys - 1) * stride + component];
        return true;
    }

    size_t i = 0;
    for (; i + 1 < nkeys; i++) {
        if (u <= time_at(i + 1)) break;
    }
    double t0 = time_at(i);
    double t1 = time_at(i + 1);
    double local = (t1 > t0) ? (u - t0) / (t1 - t0) : 1.0;
    double v0 = (double)a.kf_values[i * stride + component];
    double v1 = (double)a.kf_values[(i + 1) * stride + component];
    *out = v0 + (v1 - v0) * local;
    return true;
}

QZMediaTimingFunctionRef QZMediaTimingFunctionCreate(const char *name) {
    auto *f = new QZMediaTimingFunction();
    std::string n = name ? name : "linear";
    if (n == "easeIn" || n == "kCAMediaTimingFunctionEaseIn") {
        f->c1x = 0.42; f->c1y = 0; f->c2x = 1; f->c2y = 1;
    } else if (n == "easeOut" || n == "kCAMediaTimingFunctionEaseOut") {
        f->c1x = 0; f->c1y = 0; f->c2x = 0.58; f->c2y = 1;
    } else if (n == "easeInEaseOut" || n == "kCAMediaTimingFunctionEaseInEaseOut") {
        f->c1x = 0.42; f->c1y = 0; f->c2x = 0.58; f->c2y = 1;
    } else if (n == "default" || n == "kCAMediaTimingFunctionDefault") {
        f->c1x = 0.25; f->c1y = 0.1; f->c2x = 0.25; f->c2y = 1;
    } else {
        f->c1x = 0; f->c1y = 0; f->c2x = 1; f->c2y = 1;
    }
    return f;
}
QZMediaTimingFunctionRef QZMediaTimingFunctionCreateWithControlPoints(
    QZFloat c1x, QZFloat c1y, QZFloat c2x, QZFloat c2y) {
    auto *f = new QZMediaTimingFunction();
    f->c1x = c1x; f->c1y = c1y; f->c2x = c2x; f->c2y = c2y;
    return f;
}
void QZMediaTimingFunctionRelease(QZMediaTimingFunctionRef fn) { delete fn; }
void QZMediaTimingFunctionGetControlPoint(QZMediaTimingFunctionRef fn, int index,
                                          QZFloat out[2]) {
    if (!fn || !out) return;
    if (index <= 0) { out[0] = 0; out[1] = 0; }
    else if (index == 1) { out[0] = fn->c1x; out[1] = fn->c1y; }
    else if (index == 2) { out[0] = fn->c2x; out[1] = fn->c2y; }
    else { out[0] = 1; out[1] = 1; }
}
QZFloat QZMediaTimingFunctionSolve(QZMediaTimingFunctionRef fn, QZFloat t) {
    if (!fn) return t;
    return (QZFloat)qz_pkg_cubic_bezier_solve(fn->c1x, fn->c1y, fn->c2x, fn->c2y, (double)t);
}
void QZAnimationSetTimingFunction(QZAnimationRef anim, QZMediaTimingFunctionRef fn) {
    if (!anim || !fn) return;
    g_anim_tf[anim] = *fn;
    anim->has_timing = true;
    anim->c1x = fn->c1x;
    anim->c1y = fn->c1y;
    anim->c2x = fn->c2x;
    anim->c2y = fn->c2y;
}

QZAnimationRef QZKeyframeAnimationCreate(const char *keyPath) {
    return QZBasicAnimationCreate(keyPath);
}
void QZKeyframeAnimationSetValues(QZAnimationRef anim, const QZFloat *values,
                                  size_t nvalues, size_t stride) {
    if (!anim) return;
    anim->kf_stride = stride ? stride : 1;
    if (!values || nvalues == 0) {
        anim->kf_values.clear();
        return;
    }
    anim->kf_values.assign(values, values + nvalues * anim->kf_stride);
}
void QZKeyframeAnimationSetKeyTimes(QZAnimationRef anim, const QZFloat *times, size_t n) {
    if (!anim) return;
    if (!times || n == 0) {
        anim->kf_times.clear();
        return;
    }
    anim->kf_times.assign(times, times + n);
}
