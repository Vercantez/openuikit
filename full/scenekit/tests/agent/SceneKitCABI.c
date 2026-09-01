#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#include <SceneKit/SceneKit.h>

#define SCN_CABI_FAIL(msg) do { \
    fprintf(stderr, "SCENEKIT_AGENT_CABI_FAIL %s\n", (msg)); \
    return 1; \
} while (0)

static void *require_symbol(void *handle, const char *name) {
    void *symbol = dlsym(handle, name);
    if (symbol == NULL) {
        fprintf(stderr, "SCENEKIT_AGENT_CABI_FAIL missing unmangled export %s (%s)\n", name, dlerror());
        exit(1);
    }
    return symbol;
}

int main(void) {
    if (sizeof(SCNVector3) != 12) {
        SCN_CABI_FAIL("SCNVector3 layout is not 12 bytes");
    }
    if (sizeof(SCNVector4) != 16) {
        SCN_CABI_FAIL("SCNVector4 layout is not 16 bytes");
    }
    if (sizeof(SCNMatrix4) != 64) {
        SCN_CABI_FAIL("SCNMatrix4 layout is not 64 bytes");
    }
    SCNVector3 layout3;
    SCNVector4 layout4;
    SCNMatrix4 layoutM;
    if ((char *)&layout3.z - (char *)&layout3 != 8) {
        SCN_CABI_FAIL("SCNVector3.z offset");
    }
    if ((char *)&layout4.w - (char *)&layout4 != 12) {
        SCN_CABI_FAIL("SCNVector4.w offset");
    }
    if ((char *)&layoutM.m44 - (char *)&layoutM != 60) {
        SCN_CABI_FAIL("SCNMatrix4.m44 offset");
    }

    void *handle = dlopen("libSceneKit.dylib", RTLD_NOW | RTLD_GLOBAL);
    if (handle == NULL) {
        fprintf(stderr, "SCENEKIT_AGENT_CABI_FAIL dlopen libSceneKit.dylib: %s\n", dlerror());
        return 1;
    }

    const char *required[] = {
        "SCNVector3EqualToVector3",
        "SCNVector4EqualToVector4",
        "SCNMatrix4EqualToMatrix4",
        "SCNMatrix4IsIdentity",
        "SCNMatrix4Invert",
        "SCNMatrix4MakeRotation",
        "SCNMatrix4Mult",
        "SCNMatrix4Rotate",
        "SCNMatrix4Scale",
        "SCNVector3Zero",
        "SCNVector4Zero",
        "SCNMatrix4Identity",
        NULL
    };
    for (const char **name = required; *name != NULL; name++) {
        require_symbol(handle, *name);
    }

    Dl_info info;
    void *equal = dlsym(handle, "SCNVector3EqualToVector3");
    if (dladdr(equal, &info) == 0 || info.dli_fname == NULL) {
        SCN_CABI_FAIL("dladdr could not locate SCNVector3EqualToVector3");
    }
    if (strstr(info.dli_fname, "libSceneKit.dylib") == NULL) {
        fprintf(stderr, "SCENEKIT_AGENT_CABI_FAIL loaded from %s, expected libSceneKit.dylib\n", info.dli_fname);
        return 1;
    }

    SCNVector3 made = SCNVector3Make(1.f, 2.f, 3.f);
    if (!SCNVector3EqualToVector3(made, (SCNVector3){1.f, 2.f, 3.f})) {
        SCN_CABI_FAIL("SCNVector3Make/Equal mismatch");
    }
    if (!SCNVector3EqualToVector3(SCNVector3Zero, (SCNVector3){0.f, 0.f, 0.f})) {
        SCN_CABI_FAIL("SCNVector3Zero mismatch");
    }
    if (!SCNMatrix4IsIdentity(SCNMatrix4Identity)) {
        SCN_CABI_FAIL("SCNMatrix4Identity is not identity");
    }

    SCNMatrix4 translated = SCNMatrix4MakeTranslation(3.f, 4.f, 5.f);
    SCNMatrix4 inverted = SCNMatrix4Invert(translated);
    SCNMatrix4 product = SCNMatrix4Mult(inverted, translated);
    if (!SCNMatrix4IsIdentity(product)) {
        /* inversion of a pure translation should round-trip to identity */
        if (product.m11 < 0.999f || product.m22 < 0.999f || product.m33 < 0.999f || product.m44 < 0.999f) {
            SCN_CABI_FAIL("SCNMatrix4Invert/Mult round-trip");
        }
    }

    printf("SCENEKIT_AGENT_CABI_OK\n");
    dlclose(handle);
    return 0;
}
