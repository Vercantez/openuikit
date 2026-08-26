/* 11_varargs -- the arm64 Darwin variadic ABI, in anger.
 *
 * WHY THIS FIXTURE EXISTS (measured 2026-08-25, see docs/ABI.md):
 *
 *   Darwin/arm64 passes EVERY variadic argument on the stack, one 8-byte slot
 *   each, in declaration order; va_list is a bare char * (8 bytes).
 *   Linux/aarch64 (AAPCS64) passes the first eight integer variadics in x1-x7
 *   and the first eight FP variadics in v0-v7, spilling them to a register
 *   save area in the callee; va_list is a 32-byte struct.
 *
 * So a libSystem whose printf hands its va_list to glibc's vprintf reads the
 * FIRST INTEGER ARGUMENT as the `stack` field of a __va_list. That is not a
 * theory: docs/ABI.md records the actual SIGSEGV, at fault address 0x4d2 --
 * which is 1234, the first argument of `printf("int=%d\n", 1234)`.
 *
 * 03_printf proves the easy half. This fixture is the one that would catch a
 * printf that walks the Darwin va_list ALMOST right: more than eight
 * arguments (so any register-based reader runs off the end), integers and
 * doubles interleaved (the register-file split that AAPCS64 makes and Darwin
 * does not), default promotions, and a va_list handed onward by the guest's
 * own variadic function -- which only works if va_list is genuinely a
 * pointer-sized cursor on both sides of the call.
 *
 * Deterministic output only: no pointers, no addresses, no times.
 */
#include <stdarg.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>

/* The guest's own variadic function, forwarding a va_list to libSystem. */
static int guest_vformat(char *buf, size_t cap, const char *fmt, ...)
{
    va_list ap;
    int n;
    va_start(ap, fmt);
    n = vsnprintf(buf, cap, fmt, ap);
    va_end(ap);
    return n;
}

/* va_copy: the same list walked twice. */
static void guest_twice(const char *fmt, ...)
{
    char a[64], b[64];
    va_list ap, cp;
    va_start(ap, fmt);
    va_copy(cp, ap);
    vsnprintf(a, sizeof a, fmt, ap);
    vsnprintf(b, sizeof b, fmt, cp);
    va_end(cp);
    va_end(ap);
    printf("va_copy=[%s][%s] same=%s\n", a, b, strcmp(a, b) == 0 ? "yes" : "no");
}

/* A guest variadic that consumes with va_arg itself, then sums. Catches a
 * loader that gets the stack argument area right for printf but not for the
 * guest's own frames. */
static long guest_sum(int count, ...)
{
    va_list ap;
    long total = 0;
    va_start(ap, count);
    for (int i = 0; i < count; i++) total += va_arg(ap, int);
    va_end(ap);
    return total;
}

static double guest_dsum(int count, ...)
{
    va_list ap;
    double total = 0;
    va_start(ap, count);
    for (int i = 0; i < count; i++) total += va_arg(ap, double);
    va_end(ap);
    return total;
}

/* Mixed integer/double/pointer consumption in one list. On AAPCS64 these come
 * from two different register files; on Darwin they are consecutive stack
 * slots. Reading them in the wrong order is exactly the bug this catches. */
static void guest_mixed(const char *label, ...)
{
    va_list ap;
    int i1, i2;
    double d1, d2;
    const char *s;
    long long ll;
    va_start(ap, label);
    i1 = va_arg(ap, int);
    d1 = va_arg(ap, double);
    s  = va_arg(ap, const char *);
    i2 = va_arg(ap, int);
    d2 = va_arg(ap, double);
    ll = va_arg(ap, long long);
    va_end(ap);
    printf("%s i=%d,%d d=%.2f,%.2f s=%s ll=%lld\n", label, i1, i2, d1, d2, s, ll);
}

int main(void)
{
    char buf[64];
    int n;

    /* Twelve integer arguments: four past the eight AAPCS64 would have had. */
    printf("wide=%d %d %d %d %d %d %d %d %d %d %d %d\n",
           1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12);

    /* Twelve doubles: past v0-v7 as well. */
    printf("dwide=%.1f %.1f %.1f %.1f %.1f %.1f %.1f %.1f %.1f %.1f %.1f %.1f\n",
           1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 8.5, 9.5, 10.5, 11.5, 12.5);

    /* Interleaved: the AAPCS64 register split versus Darwin's flat stack. */
    printf("inter=%d %.1f %d %.1f %s %d %.1f %lld %u %c %.1f %s\n",
           1, 2.5, 3, 4.5, "five", 6, 7.5, 8LL, 9u, 'a', 11.5, "twelve");

    /* Default argument promotions: char and short arrive as int, float as
     * double, and the conversion still has to consume one slot. */
    {
        char c = 'q';
        signed char sc = -3;
        short sh = -1234;
        unsigned short ush = 60000;
        float f = 0.5f;
        printf("promo=%c %d %d %u %.1f %hhd %hd\n", c, sc, sh, ush, (double)f, sc, sh);
    }

    /* Length modifiers over the whole slot: long long, size_t, intmax. */
    printf("lens=%lld %llu %ld %lu %zu %jd\n",
           -9007199254740993LL, 18446744073709551615ULL,
           -1234567890123L, 1234567890123UL, (size_t)4096, (intmax_t)-42);

    /* Width and precision taken from the argument list -- each '*' eats a
     * slot of its own, ahead of the value. */
    printf("star=[%*d][%-*d][%.*f][%*.*f]\n", 6, 42, 6, 42, 3, 3.14159265, 9, 2, 2.5);

    /* Flags and bases. */
    printf("bases=%x %X %#x %o %#o %+d % d %05.2f\n",
           48879, 48879, 48879, 64, 64, 7, 7, 1.5);

    /* Strings: precision truncation, NULL, padding. */
    printf("strs=[%.3s][%10s][%-10s]|\n", "abcdef", "right", "left");

    /* Exponent and shortest forms come from the same slot walk. */
    printf("floats=%e %E %g %G %.0f %.10f\n",
           12345.6789, 12345.6789, 0.00001234, 123456789.0, 2.5, 1.0 / 3.0);

    /* The guest's own variadic frames. */
    printf("sum=%ld\n", guest_sum(10, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10));
    printf("dsum=%.2f\n", guest_dsum(10, 1.5, 2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 8.5, 9.5, 10.5));
    guest_mixed("mixed", 11, 1.25, "str", 22, 2.75, 333333333333LL);

    /* va_list handed from the guest into libSystem's vsnprintf. */
    n = guest_vformat(buf, sizeof buf, "fwd=%d/%s/%.2f", 7, "seven", 7.5);
    printf("%s (n=%d)\n", buf, n);

    /* And walked twice via va_copy. */
    guest_twice("copy %d %.1f %s", 3, 4.5, "six");

    /* snprintf truncation semantics: the return value is what WOULD have been
     * written, and the buffer is NUL-terminated within its capacity. */
    n = snprintf(buf, 8, "0123456789 %d", 42);
    printf("trunc=[%s] n=%d len=%zu\n", buf, n, strlen(buf));

    /* Sizing pass: capacity zero must not touch the buffer at all. */
    strcpy(buf, "untouched");
    n = snprintf(buf, 0, "%s-%d", "sized", 1234);
    printf("size=%d buf=[%s]\n", n, buf);

    /* sprintf, the unbounded sibling. */
    sprintf(buf, "sp=%d,%s,%.1f", -5, "x", 0.25);
    puts(buf);

    fflush(stdout);
    return 0;
}
