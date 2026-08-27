/* mod_init -- the `cxx_init` rung, C half: __mod_init_func / __mod_term_func.
 *
 * __attribute__((constructor)) puts a function pointer in
 * __DATA_CONST,__mod_init_func (section type S_MOD_INIT_FUNC_POINTERS);
 * __attribute__((destructor)) routes through __cxa_atexit.
 *
 * Ordering matters and is asserted by the output: initialisers run in
 * priority order (low number first) before main, destructors after main in
 * reverse. The loader must run __mod_init_func entries with the Darwin
 * initialiser signature (int argc, char **argv, char **envp, char **apple)
 * BEFORE calling the LC_MAIN entry point, and must run them for every image.
 */
#include <stdio.h>

static int order = 0;

__attribute__((constructor(102))) static void ctor_late(void) {
    printf("ctor 102 order=%d\n", ++order);
}

__attribute__((constructor(101))) static void ctor_early(void) {
    printf("ctor 101 order=%d\n", ++order);
}

__attribute__((constructor)) static void ctor_default(void) {
    printf("ctor default order=%d\n", ++order);
}

__attribute__((destructor)) static void dtor(void) {
    printf("dtor order=%d\n", ++order);
    fflush(stdout);
}

int main(void) {
    printf("main order=%d\n", ++order);
    return 0;
}
