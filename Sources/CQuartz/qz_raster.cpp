#include "qz_internal.hpp"

namespace qz {

void build_edges(const std::vector<Polyline> &polys, std::vector<Edge> &edges) {
    edges.clear();
    for (const Polyline &pl : polys) {
        size_t n = pl.pts.size();
        if (n < 2) continue;
        size_t segs = pl.closed ? n : n - 1;
        for (size_t i = 0; i < segs; i++) {
            Vec2 a = pl.pts[i];
            Vec2 b = pl.pts[(i + 1) % n];
            if (!pl.closed && i + 1 >= n) break;
            double dy = b.y - a.y;
            if (std::fabs(dy) < 1e-12) continue; /* horizontal */
            Edge e;
            if (a.y < b.y) {
                e.y0 = a.y;
                e.y1 = b.y;
                e.x0 = a.x;
                e.dxdy = (b.x - a.x) / dy;
                e.wind = 1;
            } else {
                e.y0 = b.y;
                e.y1 = a.y;
                e.x0 = b.x;
                e.dxdy = (a.x - b.x) / -dy;
                e.wind = -1;
            }
            edges.push_back(e);
        }
    }
}

struct Hit {
    double x;
    int wind;
};

static void add_span(float *row, int w, double x0, double x1, float weight) {
    if (x1 <= x0) return;
    if (x1 <= 0 || x0 >= w) return;
    x0 = std::max(x0, 0.0);
    x1 = std::min(x1, (double)w);
    if (x1 <= x0) return;
    int i0 = (int)std::floor(x0);
    int i1 = (int)std::floor(x1);
    if (i0 == i1) {
        if (i0 >= 0 && i0 < w) row[i0] += (float)((x1 - x0) * weight);
        return;
    }
    if (i0 >= 0 && i0 < w) row[i0] += (float)(((i0 + 1) - x0) * weight);
    int mid0 = std::max(i0 + 1, 0);
    int mid1 = std::min(i1, w);
    for (int i = mid0; i < mid1; i++) row[i] += weight;
    if (i1 >= 0 && i1 < w) row[i1] += (float)((x1 - i1) * weight);
}

static void scan_hits(const std::vector<Edge> &edges, double y,
                      std::vector<Hit> &hits) {
    hits.clear();
    for (const Edge &e : edges) {
        if (y < e.y0 || y >= e.y1) continue;
        Hit h;
        h.x = e.x0 + (y - e.y0) * e.dxdy;
        h.wind = e.wind;
        hits.push_back(h);
    }
    std::sort(hits.begin(), hits.end(), [](const Hit &a, const Hit &b) {
        return a.x < b.x;
    });
}

void rasterize(const std::vector<Edge> &edges, int w, int h,
               bool even_odd, bool antialias, float *coverage) {
    std::memset(coverage, 0, (size_t)w * (size_t)h * sizeof(float));
    if (edges.empty() || w <= 0 || h <= 0) return;

    double ymin = 1e300, ymax = -1e300;
    for (const Edge &e : edges) {
        ymin = std::min(ymin, e.y0);
        ymax = std::max(ymax, e.y1);
    }
    int row0 = clampi((int)std::floor(ymin), 0, h - 1);
    int row1 = clampi((int)std::ceil(ymax), 0, h);

    std::vector<Hit> hits;
    hits.reserve(edges.size());

    auto inside = [&](int winding) {
        if (even_odd) return (winding & 1) != 0;
        return winding != 0;
    };

    if (!antialias) {
        for (int y = row0; y < row1; y++) {
            scan_hits(edges, y + 0.5, hits);
            int wind = 0;
            bool on = false;
            double xprev = 0;
            float *row = coverage + (size_t)y * (size_t)w;
            for (const Hit &h : hits) {
                bool next = inside(wind + h.wind);
                /* apply h */
                if (on) {
                    int a = clampi((int)std::floor(xprev + 0.5), 0, w);
                    int b = clampi((int)std::floor(h.x + 0.5), 0, w);
                    for (int x = a; x < b; x++) row[x] = 1.0f;
                }
                wind += h.wind;
                on = inside(wind);
                xprev = h.x;
                (void)next;
            }
        }
        return;
    }

    const int ss = kAASamples;
    const float weight = 1.0f / (float)ss;
    for (int y = row0; y < row1; y++) {
        float *row = coverage + (size_t)y * (size_t)w;
        for (int s = 0; s < ss; s++) {
            double ys = y + (s + 0.5) / (double)ss;
            scan_hits(edges, ys, hits);
            int wind = 0;
            bool on = false;
            double xprev = 0;
            for (const Hit &h : hits) {
                if (on) add_span(row, w, xprev, h.x, weight);
                wind += h.wind;
                on = inside(wind);
                xprev = h.x;
            }
        }
        for (int x = 0; x < w; x++) {
            if (row[x] > 1.0f) row[x] = 1.0f;
            if (row[x] < 0.0f) row[x] = 0.0f;
        }
    }
}

static void premul_color(Color c, double global_alpha, double cover,
                         uint8_t *sr, uint8_t *sg, uint8_t *sb, uint8_t *sa) {
    double a = clampd(c.a * global_alpha * cover, 0.0, 1.0);
    /* Premultiply in float, then quantize like Quartz: color channels round,
       coverage was already truncated by the caller via cover. */
    *sr = u8_from_unit(c.r * a);
    *sg = u8_from_unit(c.g * a);
    *sb = u8_from_unit(c.b * a);
    *sa = u8_from_unit(a);
}

/* Integer source-over: R = S + D*(255-Sa)/255 with +127 rounding. */
static void pd_over(uint8_t *d, uint8_t sr, uint8_t sg, uint8_t sb, uint8_t sa) {
    unsigned inv = 255 - sa;
    d[0] = clamp8(sr + mul255(d[0], inv));
    d[1] = clamp8(sg + mul255(d[1], inv));
    d[2] = clamp8(sb + mul255(d[2], inv));
    d[3] = clamp8(sa + mul255(d[3], inv));
}

static uint8_t iunpremul(uint8_t c, uint8_t a) {
    if (a == 0) return 0;
    return clamp8((c * 255) / a);
}

static void rgb_to_hsl(double r, double g, double b, double *h, double *s, double *l) {
    double max = std::max(r, std::max(g, b));
    double min = std::min(r, std::min(g, b));
    *l = (max + min) * 0.5;
    if (max == min) {
        *h = 0;
        *s = 0;
        return;
    }
    double d = max - min;
    *s = *l > 0.5 ? d / (2.0 - max - min) : d / (max + min);
    if (max == r) *h = (g - b) / d + (g < b ? 6 : 0);
    else if (max == g) *h = (b - r) / d + 2;
    else *h = (r - g) / d + 4;
    *h /= 6.0;
}

static double hue2rgb(double p, double q, double t) {
    if (t < 0) t += 1;
    if (t > 1) t -= 1;
    if (t < 1.0 / 6.0) return p + (q - p) * 6 * t;
    if (t < 0.5) return q;
    if (t < 2.0 / 3.0) return p + (q - p) * (2.0 / 3.0 - t) * 6;
    return p;
}

static void hsl_to_rgb(double h, double s, double l, double *r, double *g, double *b) {
    if (s == 0) {
        *r = *g = *b = l;
        return;
    }
    double q = l < 0.5 ? l * (1 + s) : l + s - l * s;
    double p = 2 * l - q;
    *r = hue2rgb(p, q, h + 1.0 / 3.0);
    *g = hue2rgb(p, q, h);
    *b = hue2rgb(p, q, h - 1.0 / 3.0);
}

static uint8_t mul8(uint8_t a, uint8_t b) { return mul255(a, b); }

void blend_pixel(uint8_t *dst, uint8_t sr, uint8_t sg, uint8_t sb, uint8_t sa,
                 QZBlendMode mode) {
    uint8_t dr = dst[0], dg = dst[1], db = dst[2], da = dst[3];
    switch (mode) {
    case kQZBlendModeNormal:
        pd_over(dst, sr, sg, sb, sa);
        return;
    case kQZBlendModeClear:
        dst[0] = dst[1] = dst[2] = dst[3] = 0;
        return;
    case kQZBlendModeCopy:
        dst[0] = sr; dst[1] = sg; dst[2] = sb; dst[3] = sa;
        return;
    case kQZBlendModeSourceIn:
        dst[0] = mul8(sr, da); dst[1] = mul8(sg, da);
        dst[2] = mul8(sb, da); dst[3] = mul8(sa, da);
        return;
    case kQZBlendModeSourceOut: {
        unsigned inv = 255 - da;
        dst[0] = (uint8_t)((sr * inv) / 255);
        dst[1] = (uint8_t)((sg * inv) / 255);
        dst[2] = (uint8_t)((sb * inv) / 255);
        dst[3] = (uint8_t)((sa * inv) / 255);
        return;
    }
    case kQZBlendModeSourceAtop: {
        unsigned invs = 255 - sa;
        dst[0] = (uint8_t)((sr * da + dr * invs) / 255);
        dst[1] = (uint8_t)((sg * da + dg * invs) / 255);
        dst[2] = (uint8_t)((sb * da + db * invs) / 255);
        dst[3] = da; /* Sa*Da + Da*(1-Sa) = Da */
        return;
    }
    case kQZBlendModeDestinationOver: {
        unsigned invd = 255 - da;
        dst[0] = (uint8_t)((sr * invd) / 255 + dr);
        dst[1] = (uint8_t)((sg * invd) / 255 + dg);
        dst[2] = (uint8_t)((sb * invd) / 255 + db);
        dst[3] = (uint8_t)((sa * invd) / 255 + da);
        return;
    }
    case kQZBlendModeDestinationIn:
        dst[0] = mul8(dr, sa); dst[1] = mul8(dg, sa);
        dst[2] = mul8(db, sa); dst[3] = mul8(da, sa);
        return;
    case kQZBlendModeDestinationOut: {
        unsigned inv = 255 - sa;
        dst[0] = (uint8_t)((dr * inv) / 255);
        dst[1] = (uint8_t)((dg * inv) / 255);
        dst[2] = (uint8_t)((db * inv) / 255);
        dst[3] = (uint8_t)((da * inv) / 255);
        return;
    }
    case kQZBlendModeDestinationAtop: {
        unsigned invd = 255 - da;
        dst[0] = (uint8_t)((sr * invd + dr * sa) / 255);
        dst[1] = (uint8_t)((sg * invd + dg * sa) / 255);
        dst[2] = (uint8_t)((sb * invd + db * sa) / 255);
        dst[3] = sa;
        return;
    }
    case kQZBlendModeXOR: {
        unsigned invs = 255 - sa, invd = 255 - da;
        dst[0] = (uint8_t)((sr * invd + dr * invs) / 255);
        dst[1] = (uint8_t)((sg * invd + dg * invs) / 255);
        dst[2] = (uint8_t)((sb * invd + db * invs) / 255);
        dst[3] = (uint8_t)((sa * invd + da * invs) / 255);
        return;
    }
    case kQZBlendModePlusLighter:
        dst[0] = clamp8(sr + dr);
        dst[1] = clamp8(sg + dg);
        dst[2] = clamp8(sb + db);
        dst[3] = clamp8(sa + da);
        return;
    case kQZBlendModePlusDarker:
        /* R = MAX(0, (1-D)+(1-S)) in non-premul? Apple: MAX(0,(1-D)+(1-S))
           with premultiplied S,D. Approximate with clamp0(sa+da-255) style. */
        dst[0] = clamp8(sr + dr - 255);
        dst[1] = clamp8(sg + dg - 255);
        dst[2] = clamp8(sb + db - 255);
        dst[3] = clamp8(sa + da - 255);
        return;
    default:
        break;
    }

    /* Separable / non-separable PDF blend modes. Work in non-premul, then
       restore source-over with the blended color. */
    double Cs_a = sa / 255.0, Cd_a = da / 255.0;
    double Cr = iunpremul(sr, sa) / 255.0;
    double Cg = iunpremul(sg, sa) / 255.0;
    double Cb = iunpremul(sb, sa) / 255.0;
    double Dr = iunpremul(dr, da) / 255.0;
    double Dg = iunpremul(dg, da) / 255.0;
    double Db = iunpremul(db, da) / 255.0;

    auto mul = [](double a, double b) { return a * b; };
    auto screen = [](double a, double b) { return a + b - a * b; };
    /* HardLight(backdrop=a, source=b): if b<=0.5 multiply else screen.
       Overlay(backdrop=a, source=b) = HardLight(b, a). */
    auto hard = [&](double backdrop, double source) {
        return source <= 0.5 ? mul(backdrop, 2 * source) : screen(backdrop, 2 * source - 1);
    };
    auto overlay = [&](double backdrop, double source) { return hard(source, backdrop); };

    double Br = Cr, Bg = Cg, Bb = Cb;
    switch (mode) {
    case kQZBlendModeMultiply:
        Br = mul(Cr, Dr); Bg = mul(Cg, Dg); Bb = mul(Cb, Db);
        break;
    case kQZBlendModeScreen:
        Br = screen(Cr, Dr); Bg = screen(Cg, Dg); Bb = screen(Cb, Db);
        break;
    case kQZBlendModeOverlay:
        Br = overlay(Dr, Cr); Bg = overlay(Dg, Cg); Bb = overlay(Db, Cb);
        break;
    case kQZBlendModeDarken:
        Br = std::min(Cr, Dr); Bg = std::min(Cg, Dg); Bb = std::min(Cb, Db);
        break;
    case kQZBlendModeLighten:
        Br = std::max(Cr, Dr); Bg = std::max(Cg, Dg); Bb = std::max(Cb, Db);
        break;
    case kQZBlendModeColorDodge:
        Br = Dr == 0 ? 0 : (Cr == 1 ? 1 : std::min(1.0, Dr / (1 - Cr)));
        Bg = Dg == 0 ? 0 : (Cg == 1 ? 1 : std::min(1.0, Dg / (1 - Cg)));
        Bb = Db == 0 ? 0 : (Cb == 1 ? 1 : std::min(1.0, Db / (1 - Cb)));
        break;
    case kQZBlendModeColorBurn:
        Br = Cr == 0 ? (Dr == 1 ? 1 : 0) : (Dr == 1 ? 1 : 1 - std::min(1.0, (1 - Dr) / Cr));
        Bg = Cg == 0 ? (Dg == 1 ? 1 : 0) : (Dg == 1 ? 1 : 1 - std::min(1.0, (1 - Dg) / Cg));
        Bb = Cb == 0 ? (Db == 1 ? 1 : 0) : (Db == 1 ? 1 : 1 - std::min(1.0, (1 - Db) / Cb));
        break;
    case kQZBlendModeHardLight:
        Br = hard(Dr, Cr); Bg = hard(Dg, Cg); Bb = hard(Db, Cb);
        break;
    case kQZBlendModeSoftLight: {
        auto sl = [](double cs, double cd) {
            if (cs <= 0.5) return cd - (1 - 2 * cs) * cd * (1 - cd);
            double d = (cd <= 0.25) ? ((16 * cd - 12) * cd + 4) * cd : std::sqrt(cd);
            return cd + (2 * cs - 1) * (d - cd);
        };
        Br = sl(Cr, Dr); Bg = sl(Cg, Dg); Bb = sl(Cb, Db);
        break;
    }
    case kQZBlendModeDifference:
        Br = std::fabs(Cr - Dr); Bg = std::fabs(Cg - Dg); Bb = std::fabs(Cb - Db);
        break;
    case kQZBlendModeExclusion:
        Br = Cr + Dr - 2 * Cr * Dr;
        Bg = Cg + Dg - 2 * Cg * Dg;
        Bb = Cb + Db - 2 * Cb * Db;
        break;
    case kQZBlendModeHue:
    case kQZBlendModeSaturation:
    case kQZBlendModeColor:
    case kQZBlendModeLuminosity: {
        double hs, ss, ls, hd, sd, ld;
        rgb_to_hsl(Cr, Cg, Cb, &hs, &ss, &ls);
        rgb_to_hsl(Dr, Dg, Db, &hd, &sd, &ld);
        if (mode == kQZBlendModeHue) hsl_to_rgb(hs, sd, ld, &Br, &Bg, &Bb);
        else if (mode == kQZBlendModeSaturation) hsl_to_rgb(hd, ss, ld, &Br, &Bg, &Bb);
        else if (mode == kQZBlendModeColor) hsl_to_rgb(hs, ss, ld, &Br, &Bg, &Bb);
        else hsl_to_rgb(hd, sd, ls, &Br, &Bg, &Bb);
        break;
    }
    default:
        break;
    }

    /* PDF: result = (1-Da)*S + (1-Sa)*D + Sa*Da*B , then premul. */
    double out_a = Cs_a + Cd_a - Cs_a * Cd_a;
    auto ch = [&](double Cs, double Cd, double B) {
        return (1 - Cd_a) * Cs_a * Cs + (1 - Cs_a) * Cd_a * Cd + Cs_a * Cd_a * B;
    };
    double or_ = ch(Cr, Dr, Br);
    double og = ch(Cg, Dg, Bg);
    double ob = ch(Cb, Db, Bb);
    dst[0] = u8_from_unit(or_);
    dst[1] = u8_from_unit(og);
    dst[2] = u8_from_unit(ob);
    dst[3] = u8_from_unit(out_a);
}

void blend_coverage(uint8_t *dst, int w, int h, size_t bpr,
                    const float *coverage, const uint8_t *clip,
                    Color color, double global_alpha, QZBlendMode mode) {
    for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
            float cov = coverage[y * w + x];
            if (clip) cov *= clip[y * w + x] / 255.0f;
            if (cov <= 1.0f / 255.0f) continue;
            /* Match Quartz: coverage_byte = floor(cov * 255) applied as scale. */
            float c8 = std::floor(cov * 255.0f) / 255.0f;
            uint8_t sr, sg, sb, sa;
            premul_color(color, global_alpha, c8, &sr, &sg, &sb, &sa);
            if (sa == 0 && mode == kQZBlendModeNormal) continue;
            uint8_t *p = dst + (size_t)y * bpr + (size_t)x * 4;
            blend_pixel(p, sr, sg, sb, sa, mode);
        }
    }
}

Color Gradient::sample(double t) const {
    if (colors.empty()) return {};
    if (t <= stops.front()) return colors.front();
    if (t >= stops.back()) return colors.back();
    for (size_t i = 1; i < stops.size(); i++) {
        if (t <= stops[i]) {
            double u = (t - stops[i - 1]) / (stops[i] - stops[i - 1] + 1e-15);
            Color a = colors[i - 1], b = colors[i];
            return {a.r + (b.r - a.r) * u, a.g + (b.g - a.g) * u,
                    a.b + (b.b - a.b) * u, a.a + (b.a - a.a) * u};
        }
    }
    return colors.back();
}

} /* namespace qz */
