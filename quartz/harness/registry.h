#pragma once
#include "backend.h"
#include "layer_backend.h"
#include <vector>

void qz_register_cg_scene(const char *name, void (*draw)(Backend &b, int w, int h));
void qz_register_ca_scene(const char *name, void (*build)(LayerTree &t, int w, int h));

std::vector<Scene> qz_all_cg_scenes();
std::vector<LayerScene> qz_all_ca_scenes();

#define QZ_CG_SCENE(name, fn) \
    static int qz_reg_cg_##fn = (qz_register_cg_scene(name, fn), 0)

#define QZ_CA_SCENE(name, fn) \
    static int qz_reg_ca_##fn = (qz_register_ca_scene(name, fn), 0)
