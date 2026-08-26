/* 03_printf -- rung (c): first real libSystem dependency.
 *
 * Exercises: a lazy/chained import of _printf and _puts, a __cstring literal
 * referenced through an ADRP/ADD pair, varargs on the arm64 Darwin ABI (which
 * differs from AAPCS64: Darwin passes variadic arguments on the stack, each
 * slot-aligned to 8 bytes), and stdout being line/flush-correct at exit.
 *
 * Deterministic output only -- no pointers, no times, no addresses.
 */
#include <stdio.h>

int main(void) {
    puts("printf fixture");
    printf("int=%d\n", 1234);
    printf("neg=%d\n", -7);
    printf("uint=%u hex=%x\n", 4294967295u, 48879u);
    printf("long=%ld\n", 1234567890123L);
    printf("str=%s char=%c\n", "abc", 'Z');
    printf("pct=%d%%\n", 50);
    printf("pad=[%5d][%-5d][%05d]\n", 42, 42, 42);
    printf("dbl=%.3f\n", 3.14159);
    printf("mix=%s %d %.1f %c\n", "s", 8, 2.5, 'x');
    fflush(stdout);
    return 0;
}
