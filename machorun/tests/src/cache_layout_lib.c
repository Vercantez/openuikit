/* cache_layout_lib -- the dylib for the cache_layout / cache_layout_packed
 * pair. Built Apple-aligned; scripts/pack_macho.py then rewrites a copy
 * into dyld-shared-cache layout without changing these bytes' meaning.
 */
#include <stdio.h>

int greet_counter = 10;
const char *const greet_name = "libgreet";

__attribute__((constructor)) static void lib_ctor(void) {
    printf("lib ctor\n");
}

int greet(int n) {
    greet_counter += n;
    printf("greet(%d) from %s counter=%d\n", n, greet_name, greet_counter);
    return greet_counter;
}

extern int exe_callback(int);

int greet_via_callback(int n) {
    return exe_callback(n) + 1;
}
