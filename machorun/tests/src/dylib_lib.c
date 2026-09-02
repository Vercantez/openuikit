/* dylib_lib -- the shipped-alongside dylib for the `dylib_classic` rung.
 *
 * Exports a function, a piece of mutable data, and a read-only string
 * pointer, plus its own __mod_init_func constructor. Built with
 * -install_name @rpath/libdylib_greet.dylib so the executable's LC_LOAD_DYLIB
 * must be resolved through LC_RPATH + @loader_path.
 */
#include <stdio.h>

/* exported mutable data: the executable imports this via a GOT slot */
int greet_counter = 10;

/* exported read-only pointer to a string in this image */
const char *const greet_name = "libgreet";

__attribute__((constructor)) static void lib_ctor(void) {
    printf("lib ctor\n");
}

int greet(int n) {
    greet_counter += n;
    printf("greet(%d) from %s counter=%d\n", n, greet_name, greet_counter);
    return greet_counter;
}

/* calls back into a symbol the *executable* exports -- a cross-image
 * reference in the other direction, resolved by flat/two-level lookup. */
extern int exe_callback(int);

int greet_via_callback(int n) {
    return exe_callback(n) + 1;
}
