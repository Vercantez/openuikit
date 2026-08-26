#include "qz_internal.hpp"
#include <unordered_map>
#include <unordered_set>
/* OWNED BY package color-p3. */

static std::unordered_set<QZColorSpaceRef> g_p3_spaces;
static std::unordered_map<QZContextRef, bool> g_fill_p3;

/* sRGB / Display P3 transfer (IEC 61966-2-1). */
static double srgb_decode(double c) {
    if (c < 0.0) return -srgb_decode(-c);
    if (c <= 0.04045) return c / 12.92;
    return std::pow((c + 0.055) / 1.055, 2.4);
}
static double srgb_encode(double c) {
    if (c < 0.0) return -srgb_encode(-c);
    if (c <= 0.0031308) return 12.92 * c;
    return 1.055 * std::pow(c, 1.0 / 2.4) - 0.055;
}

/* Linear Display P3 → linear sRGB, D65. Rows sum to 1 so equal RGB
 * (shared white) is an identity. B column of R/G is ~0 (same blue primary). */
static void p3_to_srgb(QZFloat pr, QZFloat pg, QZFloat pb,
                       QZFloat *sr, QZFloat *sg, QZFloat *sb) {
    if (pr == pg && pg == pb) {
        *sr = pr;
        *sg = pg;
        *sb = pb;
        return;
    }
    double R = srgb_decode((double)pr);
    double G = srgb_decode((double)pg);
    double B = srgb_decode((double)pb);
    const double m00 = 1.224940176280560, m01 = -0.224940176280560;
    const double m10 = -0.042056954709688, m11 = 1.042056954709688;
    const double m20 = -0.019637554590334, m21 = -0.078636045550632;
    const double m22 = 1.0 - m20 - m21;
    double lr = m00 * R + m01 * G;
    double lg = m10 * R + m11 * G;
    double lb = m20 * R + m21 * G + m22 * B;
    *sr = (QZFloat)qz::clampd(srgb_encode(lr), 0.0, 1.0);
    *sg = (QZFloat)qz::clampd(srgb_encode(lg), 0.0, 1.0);
    *sb = (QZFloat)qz::clampd(srgb_encode(lb), 0.0, 1.0);
}

QZColorSpaceRef QZColorSpaceCreateDisplayP3(void) {
    QZColorSpaceRef s = QZColorSpaceCreateWithNameSRGB();
    if (s) g_p3_spaces.insert(s);
    return s;
}

QZColorRef QZColorCreateGenericP3(QZFloat r, QZFloat g, QZFloat b, QZFloat a) {
    QZFloat sr, sg, sb;
    p3_to_srgb(r, g, b, &sr, &sg, &sb);
    return QZColorCreateGenericRGB(sr, sg, sb, a);
}

void QZContextSetFillColorSpace(QZContextRef ctx, QZColorSpaceRef space) {
    if (!ctx) return;
    g_fill_p3[ctx] = space && g_p3_spaces.count(space) != 0;
}

void QZContextSetFillColor(QZContextRef ctx, const QZFloat *components) {
    if (!ctx || !components) return;
    auto it = g_fill_p3.find(ctx);
    if (it != g_fill_p3.end() && it->second) {
        QZFloat sr, sg, sb;
        p3_to_srgb(components[0], components[1], components[2], &sr, &sg, &sb);
        QZContextSetRGBFillColor(ctx, sr, sg, sb, components[3]);
    } else {
        QZContextSetRGBFillColor(ctx, components[0], components[1], components[2],
                                 components[3]);
    }
}
