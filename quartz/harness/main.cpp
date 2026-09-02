#include "backend.h"
#include "layer_backend.h"
#include "registry.h"

#define STB_IMAGE_WRITE_STATIC
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

#include <chrono>
#include <cmath>
#include <cstdio>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>

namespace fs = std::filesystem;

struct Metrics {
    std::string name;
    std::string suite;
    double mae = 0;
    double rmse = 0;
    int max_err = 0;
    int64_t exact = 0;
    int64_t close = 0; /* max channel diff <= 8 */
    int64_t pixels = 0;
    double ms_apple = 0;
    double ms_qz = 0;
};

static Metrics compare_buf(const char *name,
                           const uint8_t *a, size_t abpr,
                           const uint8_t *q, size_t qbpr,
                           int w, int h,
                           uint8_t *diff) {
    Metrics m;
    m.name = name;
    m.pixels = (int64_t)w * h;
    double sse = 0, sae = 0;
    for (int y = 0; y < h; y++) {
        const uint8_t *ar = a + y * abpr;
        const uint8_t *qr = q + y * qbpr;
        uint8_t *dr = diff + (size_t)y * w * 4;
        for (int x = 0; x < w; x++) {
            int maxc = 0;
            int sumc = 0;
            for (int c = 0; c < 4; c++) {
                int d = (int)ar[x * 4 + c] - (int)qr[x * 4 + c];
                if (d < 0) d = -d;
                if (d > maxc) maxc = d;
                sumc += d;
                sae += d;
                sse += (double)d * d;
            }
            if (maxc == 0) m.exact++;
            if (maxc <= 8) m.close++;
            if (maxc > m.max_err) m.max_err = maxc;
            /* amplified abs diff in red, dim grey elsewhere */
            int amp = maxc * 8;
            if (amp > 255) amp = 255;
            dr[x * 4 + 0] = (uint8_t)amp;
            dr[x * 4 + 1] = (uint8_t)(maxc ? 0 : 0);
            dr[x * 4 + 2] = (uint8_t)(maxc ? 0 : 0);
            dr[x * 4 + 3] = 255;
        }
    }
    m.mae = sae / (m.pixels * 4.0);
    m.rmse = std::sqrt(sse / (m.pixels * 4.0));
    return m;
}

static std::string json_escape(const std::string &s) { return s; }

static void write_png(const fs::path &p, int w, int h, const uint8_t *pix, size_t bpr) {
    if (bpr == (size_t)w * 4) {
        stbi_write_png(p.c_str(), w, h, 4, pix, (int)bpr);
        return;
    }
    std::vector<uint8_t> packed((size_t)w * h * 4);
    for (int y = 0; y < h; y++)
        memcpy(packed.data() + (size_t)y * w * 4, pix + y * bpr, (size_t)w * 4);
    stbi_write_png(p.c_str(), w, h, 4, packed.data(), w * 4);
}

static void print_and_score(const std::vector<Metrics> &all, const char *label,
                            double *out_score, double *out_mae, double *out_exact, double *out_close,
                            int *out_worst) {
    double sum_mae = 0, sum_exact = 0, sum_close = 0;
    int worst_max = 0;
    for (const auto &m : all) {
        sum_mae += m.mae;
        sum_exact += (double)m.exact / m.pixels;
        sum_close += (double)m.close / m.pixels;
        if (m.max_err > worst_max) worst_max = m.max_err;
    }
    int N = (int)all.size();
    double mean_mae = N ? sum_mae / N : 0;
    double mean_exact = N ? 100.0 * sum_exact / N : 0;
    double mean_close = N ? 100.0 * sum_close / N : 0;
    double score = 0;
    if (N) {
        score = 0.40 * mean_exact + 0.40 * mean_close + 0.20 * std::max(0.0, 100.0 - mean_mae * 8.0);
        if (score < 0) score = 0;
        if (score > 100) score = 100;
    }
    printf("\n=== %s n=%d  mean MAE=%.4f  exact=%.2f%%  close<=8=%.2f%%  worst_max=%d  SCORE=%.2f ===\n",
           label, N, mean_mae, mean_exact, mean_close, worst_max, score);
    *out_score = score; *out_mae = mean_mae; *out_exact = mean_exact;
    *out_close = mean_close; *out_worst = worst_max;
}

int main(int argc, char **argv) {
    int W = 256, H = 256;
    fs::path out = "output";
    std::string only;
    std::string suite = "all";
    for (int i = 1; i < argc; i++) {
        std::string a = argv[i];
        if (a == "--out" && i + 1 < argc) out = argv[++i];
        else if (a == "--size" && i + 1 < argc) W = H = atoi(argv[++i]);
        else if (a == "--only" && i + 1 < argc) only = argv[++i];
        else if (a == "--suite" && i + 1 < argc) suite = argv[++i];
    }

    bool run_cg = (suite == "all" || suite == "cg");
    bool run_ca = (suite == "all" || suite == "ca");

    fs::create_directories(out / "apple");
    fs::create_directories(out / "qz");
    fs::create_directories(out / "diff");

    std::vector<Metrics> all;
    std::vector<uint8_t> diff((size_t)W * H * 4);

    if (run_cg) {
        std::vector<Scene> scene_list = qz_all_cg_scenes();
        int nscenes = (int)scene_list.size();
        const Scene *scenes = scene_list.data();
        Backend *apple = make_apple_backend();
        Backend *qz = make_qz_backend();
        if (!apple || !qz) {
            fprintf(stderr, "failed to create CG backends\n");
            return 1;
        }
        printf("--- suite cg (Core Graphics vs official CoreGraphics) ---\n");
        for (int i = 0; i < nscenes; i++) {
            if (!only.empty() && only != scenes[i].name) continue;
            if (!apple->begin(W, H) || !qz->begin(W, H)) {
                fprintf(stderr, "begin failed for %s\n", scenes[i].name);
                continue;
            }
            auto t0 = std::chrono::high_resolution_clock::now();
            scenes[i].draw(*apple, W, H);
            auto t1 = std::chrono::high_resolution_clock::now();
            scenes[i].draw(*qz, W, H);
            auto t2 = std::chrono::high_resolution_clock::now();

            Metrics m = compare_buf(scenes[i].name,
                                    apple->pixels(), apple->bpr(),
                                    qz->pixels(), qz->bpr(),
                                    W, H, diff.data());
            m.suite = "cg";
            m.ms_apple = std::chrono::duration<double, std::milli>(t1 - t0).count();
            m.ms_qz = std::chrono::duration<double, std::milli>(t2 - t1).count();
            all.push_back(m);
            write_png(out / "apple" / (std::string(scenes[i].name) + ".png"), W, H, apple->pixels(), apple->bpr());
            write_png(out / "qz" / (std::string(scenes[i].name) + ".png"), W, H, qz->pixels(), qz->bpr());
            write_png(out / "diff" / (std::string(scenes[i].name) + ".png"), W, H, diff.data(), (size_t)W * 4);
            printf("%-22s  MAE=%6.3f  RMSE=%6.3f  max=%3d  exact=%5.1f%%  close=%5.1f%%  apple=%.2fms qz=%.2fms\n",
                   scenes[i].name, m.mae, m.rmse, m.max_err,
                   100.0 * m.exact / m.pixels, 100.0 * m.close / m.pixels,
                   m.ms_apple, m.ms_qz);
            apple->end();
            qz->end();
        }
        delete apple;
        delete qz;
    }

    if (run_ca) {
        std::vector<LayerScene> scene_list = qz_all_ca_scenes();
        int nscenes = (int)scene_list.size();
        const LayerScene *scenes = scene_list.data();
        LayerTree *apple = make_apple_layers();
        LayerTree *qz = make_qz_layers();
        if (!apple || !qz) {
            fprintf(stderr, "failed to create CA backends\n");
            return 1;
        }
        printf("--- suite ca (Core Animation vs official QuartzCore) ---\n");
        for (int i = 0; i < nscenes; i++) {
            if (!only.empty() && only != scenes[i].name) continue;
            if (!apple->begin(W, H) || !qz->begin(W, H)) {
                fprintf(stderr, "begin failed for %s\n", scenes[i].name);
                continue;
            }
            auto t0 = std::chrono::high_resolution_clock::now();
            scenes[i].build(*apple, W, H);
            auto t1 = std::chrono::high_resolution_clock::now();
            scenes[i].build(*qz, W, H);
            auto t2 = std::chrono::high_resolution_clock::now();

            Metrics m = compare_buf(scenes[i].name,
                                    apple->pixels(), apple->bpr(),
                                    qz->pixels(), qz->bpr(),
                                    W, H, diff.data());
            m.suite = "ca";
            m.ms_apple = std::chrono::duration<double, std::milli>(t1 - t0).count();
            m.ms_qz = std::chrono::duration<double, std::milli>(t2 - t1).count();
            all.push_back(m);
            write_png(out / "apple" / (std::string(scenes[i].name) + ".png"), W, H, apple->pixels(), apple->bpr());
            write_png(out / "qz" / (std::string(scenes[i].name) + ".png"), W, H, qz->pixels(), qz->bpr());
            write_png(out / "diff" / (std::string(scenes[i].name) + ".png"), W, H, diff.data(), (size_t)W * 4);
            printf("%-22s  MAE=%6.3f  RMSE=%6.3f  max=%3d  exact=%5.1f%%  close=%5.1f%%  apple=%.2fms qz=%.2fms\n",
                   scenes[i].name, m.mae, m.rmse, m.max_err,
                   100.0 * m.exact / m.pixels, 100.0 * m.close / m.pixels,
                   m.ms_apple, m.ms_qz);
            apple->end();
            qz->end();
        }
        delete apple;
        delete qz;
    }

    auto subset = [&](const char *sname) {
        std::vector<Metrics> v;
        for (const auto &m : all) if (m.suite == sname) v.push_back(m);
        return v;
    };
    double score = 0, mean_mae = 0, mean_exact = 0, mean_close = 0;
    int worst_max = 0;
    if (run_cg) {
        double s, a, e, c; int w;
        auto v = subset("cg");
        print_and_score(v, "CG", &s, &a, &e, &c, &w);
    }
    if (run_ca) {
        double s, a, e, c; int w;
        auto v = subset("ca");
        print_and_score(v, "CA", &s, &a, &e, &c, &w);
    }
    print_and_score(all, "SUMMARY", &score, &mean_mae, &mean_exact, &mean_close, &worst_max);

    fs::path jsonp = out / "metrics.json";
    std::ofstream js(jsonp);
    js << "{\n  \"score\": " << score << ",\n  \"mean_mae\": " << mean_mae
       << ",\n  \"mean_exact_pct\": " << mean_exact << ",\n  \"mean_close_pct\": " << mean_close
       << ",\n  \"worst_max\": " << worst_max << ",\n  \"scenes\": [\n";
    for (size_t i = 0; i < all.size(); i++) {
        const auto &m = all[i];
        js << "    {\"name\": \"" << json_escape(m.name) << "\", \"suite\": \"" << m.suite
           << "\", \"mae\": " << m.mae
           << ", \"rmse\": " << m.rmse << ", \"max_err\": " << m.max_err
           << ", \"exact_pct\": " << (100.0 * m.exact / m.pixels)
           << ", \"close_pct\": " << (100.0 * m.close / m.pixels)
           << ", \"ms_apple\": " << m.ms_apple << ", \"ms_qz\": " << m.ms_qz << "}";
        js << (i + 1 == all.size() ? "\n" : ",\n");
    }
    js << "  ]\n}\n";
    js.close();
    return 0;
}
