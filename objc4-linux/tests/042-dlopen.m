// 042-dlopen -- an image that arrives after the process is already running.
//
// On Darwin dyld notifies objc4 of every image it maps, whenever it maps it,
// so a dlopen'ed bundle's classes are registered and its +load methods run
// before dlopen() returns. Linux has no such notification: dl_iterate_phdr can
// be asked but not subscribed to. This test is the measurement of whether the
// port reproduces the Darwin timing.
//
// The companion image is tests/042-dlopen.dlopen.m. The harness builds it as a
// shared library, does NOT link it, and passes its path in
// OBJC4_TEST_DLOPEN_LIB.
#include "testsupport.h"
#include <dlfcn.h>

typedef int (*IntMsg)(id, SEL);
typedef id  (*IdMsg)(id, SEL);

int main(void) {
    const char *libpath = getenv("OBJC4_TEST_DLOPEN_LIB");
    say("libpath=%s", NULLNESS(libpath));
    if (!libpath || !*libpath) {
        say("SKIP=no OBJC4_TEST_DLOPEN_LIB");
        return 0;
    }

    say("before.class=%s", NULLNESS(objc_getClass("PluginRoot")));

    // Anything the plugin prints from +load has to land HERE, between these
    // two lines, exactly as it does on Darwin.
    void *h = dlopen(libpath, RTLD_NOW | RTLD_LOCAL);
    say("dlopen=%s", NULLNESS(h));
    if (!h) {
        say("dlerror=%s", SAFESTR(dlerror()));
        return 1;
    }

    Class plugin = objc_getClass("PluginRoot");
    say("after.class=%s", NULLNESS(plugin));
    if (!plugin) return 1;

    say("after.name=%s", class_getName(plugin));
    say("after.superclass=%s", NULLNESS(class_getSuperclass(plugin)));

    // Selectors registered from the new image must be the same SEL the
    // executable's selector table already knows.
    SEL answer = sel_registerName("answer");
    say("responds.answer=%s", YN(class_respondsToSelector(plugin, answer)));

    id obj = ((IdMsg)objc_msgSend)((id)plugin, sel_registerName("alloc"));
    say("obj=%s", NULLNESS(obj));
    say("answer=%d", ((IntMsg)objc_msgSend)(obj, answer));

    // A category inside the newly-loaded image must have been attached too.
    SEL fromCategory = sel_registerName("fromCategory");
    say("responds.fromCategory=%s",
        YN(class_respondsToSelector(plugin, fromCategory)));
    say("fromCategory=%d", ((IntMsg)objc_msgSend)(obj, fromCategory));

    // The runtime must attribute the class to the newly-loaded image, and to
    // a different image from the executable's own classes.
    const char *pluginImage = class_getImageName(plugin);
    const char *rootImage   = class_getImageName(objc_getClass("TestRoot"));
    say("plugin.image=%s", NULLNESS(pluginImage));
    say("plugin.image!=exe.image=%s",
        YN(pluginImage && rootImage && strcmp(pluginImage, rootImage) != 0));

    // getClassList must include it.
    int n = objc_getClassList(NULL, 0);
    Class *all = (Class *)calloc((size_t)n, sizeof(Class));
    n = objc_getClassList(all, n);
    int found = 0;
    for (int i = 0; i < n; i++) if (all[i] == plugin) found = 1;
    free(all);
    say("in.classList=%s", YN(found));

    return 0;
}
