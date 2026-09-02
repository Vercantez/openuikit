/* dylib_main -- the `dylib_classic` rung: two-image loading.
 *
 * Links libdylib_greet.dylib, which we also ship. Exercises:
 *   - LC_LOAD_DYLIB with an @rpath install name + LC_RPATH/@loader_path
 *   - a function import (branch through a stub / chained-fixup bind)
 *   - a *data* import (greet_counter, a GOT slot, no stub involved)
 *   - a reverse import: the dylib calls exe_callback, exported by the
 *     executable, so the loader must publish the main image's exports too
 *   - initialiser ordering across images: dependency's __mod_init_func runs
 *     before the executable's.
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
