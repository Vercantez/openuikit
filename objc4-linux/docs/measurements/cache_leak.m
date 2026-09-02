// cache_leak.m -- see docs/STATUS.md 4.2 and UNIMPLEMENTED B1.
// Linux: ~8.7 KB leaked per cache invalidation. macOS peak RSS at 20000
// rounds is 4.7 MB; this port reaches 176.8 MB. Run: ./cache_leak <rounds>
// Measure the method-cache leak (docs/UNIMPLEMENTED.md B1) instead of assuming it.
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <objc/runtime.h>
#include <objc/message.h>
@interface TR { Class isa; } @end
@implementation TR - (int)a { return 1; } @end
static int impl(id self, SEL _cmd) { return 3; }
static long rss_kb(void) {
#ifdef __linux__
    FILE *f = fopen("/proc/self/statm", "r");
    long size=0, res=0; if (f) { if (fscanf(f, "%ld %ld", &size, &res) != 2) res = 0; fclose(f); }
    return res * (sysconf(_SC_PAGESIZE)/1024);
#else
    return 0;
#endif
}
int main(int argc, char **argv) {
    setvbuf(stdout, NULL, _IONBF, 0);
    int rounds = argc > 1 ? atoi(argv[1]) : 20000;
    Class cls = objc_getClass("TR");
    id obj = class_createInstance(cls, 0);
    // Warm a wide cache: 256 distinct selectors.
    for (int i = 0; i < 256; i++) {
        char n[32]; snprintf(n, sizeof n, "sel%d", i);
        SEL s = sel_registerName(n);
        class_addMethod(cls, s, (IMP)impl, "i@:");
    }
    for (int i = 0; i < 256; i++) {
        char n[32]; snprintf(n, sizeof n, "sel%d", i);
        ((int(*)(id,SEL))objc_msgSend)(obj, sel_registerName(n));
    }
    long base = rss_kb();
    printf("rss.after.warm.kb=%ld\n", base);
    // Each class_addMethod flushes the class's cache -> reallocation -> leak.
    for (int r = 0; r < rounds; r++) {
        char n[32]; snprintf(n, sizeof n, "extra%d", r);
        class_addMethod(cls, sel_registerName(n), (IMP)impl, "i@:");
        for (int i = 0; i < 256; i++) {
            char m[32]; snprintf(m, sizeof m, "sel%d", i);
            ((int(*)(id,SEL))objc_msgSend)(obj, sel_registerName(m));
        }
    }
    long end = rss_kb();
    printf("rounds=%d\n", rounds);
    printf("rss.end.kb=%ld\n", end);
    printf("rss.growth.kb=%ld\n", end - base);
    return 0;
}
