/* exp10_strings.c -- __exp10 and the BSD string forms, and the reason this
 * fixture COMPUTES rather than links.
 *
 * __exp10 IS IN THE FALSE-GREEN CATALOGUE. Written the obvious way --
 * `return pow(10.0, x);` -- clang recognises the exp10 idiom and tail-calls
 * __exp10, the function being defined. It compiled to a single unconditional
 * branch to itself, with no warning, and produced ZERO undefined symbols: the
 * symbol table looked HEALTHIER than the correct version, which references
 * pow. std::__sort later did the same thing for the same reason, and the
 * lesson recorded then is the one this file is built around:
 *
 *     a symbol that exists and links is precisely the reassuring signal that
 *     hid it.
 *
 * So every line below produces a VALUE. A fixture that merely called these and
 * checked they returned would pass against an infinite self-branch right up
 * until it hung, and a link check would have passed forever.
 *
 * The values are chosen to be exactly representable and printed as integers
 * where possible, because libm is only agreed to within an ulp between the two
 * systems (docs/UNIMPLEMENTED.md#libm-ulp) and this fixture must not become a
 * transcendental-accuracy test by accident. 10^0, 10^1, 10^2 and 10^-1 are the
 * cases where both systems must agree exactly.
 *
 * flsl is here because glibc has ffsl -- find FIRST set -- and not flsl -- find
 * LAST. The two names differ by one letter and their answers differ by the
 * whole width of the word, so binding one to the other would compile, link,
 * and return a plausible small number for every input. The cases below are
 * chosen so ffsl and flsl disagree on every one.
 *
 * strnstr's bound applies to the HAYSTACK, not the needle, and the haystack
 * need not be NUL-terminated within it -- so the last case deliberately passes
 * a bound that stops mid-buffer with a match sitting just past it.
 */
#include <stdio.h>
#include <string.h>
#include <strings.h>
#include <math.h>

extern double __exp10(double);
extern float  __exp10f(float);

int main(void)
{
    puts("== __exp10 computes rather than recursing");
    /* Exactly representable, so both systems must agree to the bit. */
    printf("  10^0  = %.0f\n", __exp10(0.0));
    printf("  10^1  = %.0f\n", __exp10(1.0));
    printf("  10^2  = %.0f\n", __exp10(2.0));
    printf("  10^3  = %.0f\n", __exp10(3.0));
    printf("  10^-1 = %.4f\n", __exp10(-1.0));
    printf("  10^-2 = %.4f\n", __exp10(-2.0));
    printf("  float 10^2 = %.0f\n", (double)__exp10f(2.0f));
    /* The relation, which no self-branch and no wrong function satisfies. */
    printf("  10^2 * 10^3 == 10^5: %s\n",
           __exp10(2.0) * __exp10(3.0) == __exp10(5.0) ? "yes" : "NO");

    puts("== flsl finds the LAST set bit, not the first");
    {
        /* Every case has its first and last set bits in different places, so
         * an ffsl binding gives a different answer for all of them. */
        static const struct { unsigned long v; const char *n; } C[] = {
            { 0UL,          "0" },
            { 1UL,          "1" },
            { 3UL,          "3" },
            { 0x80UL,       "0x80" },
            { 0x81UL,       "0x81" },
            { 0xF0F0UL,     "0xF0F0" },
            { 1UL << 62,    "1<<62" },
        };
        size_t i;
        for (i = 0; i < sizeof C / sizeof C[0]; i++)
            printf("  flsl(%-8s) = %d\n", C[i].n, flsl((long)C[i].v));
    }

    puts("== strnstr bounds the HAYSTACK, not the needle");
    {
        const char *h = "alphabetagamma";
        printf("  found at start:      %s\n", strnstr(h, "alpha", 14) ? "yes" : "NO");
        printf("  found in the middle: %s\n", strnstr(h, "beta",  14) ? "yes" : "NO");
        printf("  empty needle:        %s\n", strnstr(h, "",      14) == h ? "start" : "NO");
        printf("  needle longer than bound: %s\n",
               strnstr(h, "alpha", 3) ? "FOUND" : "not found");
        /* The bound stops one character before the match completes. A version
         * that read to the NUL would find it anyway. */
        printf("  match just past the bound: %s\n",
               strnstr(h, "beta", 8) ? "FOUND" : "not found");
        printf("  and with one more byte:    %s\n",
               strnstr(h, "beta", 9) ? "found" : "NOT FOUND");
    }

    puts("== strncasecmp and strtok");
    printf("  strncasecmp(\"ABC\",\"abc\",3) = %d\n", strncasecmp("ABC", "abc", 3));
    printf("  strncasecmp(\"ABC\",\"abd\",3) < 0: %s\n",
           strncasecmp("ABC", "abd", 3) < 0 ? "yes" : "NO");
    printf("  strncasecmp(\"ABC\",\"abd\",2) = %d\n", strncasecmp("ABC", "abd", 2));
    {
        char buf[] = "one,two,,three";
        char *save = NULL, *t;
        printf("  strtok_r:");
        for (t = strtok_r(buf, ",", &save); t; t = strtok_r(NULL, ",", &save))
            printf(" [%s]", t);
        printf("\n");
    }

    puts("done");
    return 0;
}
