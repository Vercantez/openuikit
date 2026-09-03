/* cache_layout -- load a dylib whose segments are the dyld-shared-cache shape.
 *
 * Same program as the `dylib` rung: a function import, a data import, a
 * reverse import, constructors across two images. The variable is the
 * dylib's LAYOUT, not the C. `libcache_layout.dylib` is Apple-built and
 * page-aligned; `libcache_packed.dylib` is that binary rewritten by
 * scripts/pack_macho.py into packed, non-page-aligned vmaddr/fileoff
 * (contiguous cache data); `libcache_sparse.dylib` is the same rewrite
 * with Apple's cache-wide TEXT-to-DATA gap (0x22256720). All three
 * executables must print the same bytes. `libcache_nofix.dylib` is the
 * aligned dylib with rebase/bind load commands stripped — the loader
 * must refuse it. `libcache_emptyfix.dylib` is the libCombine shape:
 * LC_DYLD_INFO_ONLY present, every size zero; the loader must LOAD it.
 * See docs/FIXTURES.md.
 */
#include <stdio.h>

extern int greet(int);
extern int greet_via_callback(int);
extern int greet_counter;
extern const char *const greet_name;

__attribute__((constructor)) static void exe_ctor(void) {
    printf("exe ctor\n");
}

int exe_callback(int n) {
    printf("exe_callback(%d)\n", n);
    return n * 2;
}

int main(void) {
    printf("name=%s\n", greet_name);
    printf("counter-before=%d\n", greet_counter);
    greet(5);
    printf("counter-after=%d\n", greet_counter);
    greet_counter = 100;
    greet(1);
    printf("via-callback=%d\n", greet_via_callback(3));
    return 0;
}
