#include "registry.h"

static std::vector<Scene> &cg_extra() {
    static std::vector<Scene> v;
    return v;
}
static std::vector<LayerScene> &ca_extra() {
    static std::vector<LayerScene> v;
    return v;
}

void qz_register_cg_scene(const char *name, void (*draw)(Backend &b, int w, int h)) {
    cg_extra().push_back({name, draw});
}
void qz_register_ca_scene(const char *name, void (*build)(LayerTree &t, int w, int h)) {
    ca_extra().push_back({name, build});
}

std::vector<Scene> qz_all_cg_scenes() {
    int n = 0;
    const Scene *base = all_scenes(&n);
    std::vector<Scene> out;
    out.reserve((size_t)n + cg_extra().size());
    for (int i = 0; i < n; i++) out.push_back(base[i]);
    for (const auto &s : cg_extra()) out.push_back(s);
    return out;
}

std::vector<LayerScene> qz_all_ca_scenes() {
    int n = 0;
    const LayerScene *base = all_layer_scenes(&n);
    std::vector<LayerScene> out;
    out.reserve((size_t)n + ca_extra().size());
    for (int i = 0; i < n; i++) out.push_back(base[i]);
    for (const auto &s : ca_extra()) out.push_back(s);
    return out;
}
