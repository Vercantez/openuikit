/* sscanf.c -- a bounded parser, and the two things it must get right.
 *
 * sscanf cannot be forwarded to glibc. It is variadic, and Darwin's arm64 ABI
 * passes variadic arguments on the STACK where AAPCS64 passes the first eight
 * in REGISTERS -- so glibc would read registers this caller never wrote. Every
 * one of sscanf's variadic arguments is a POINTER IT WRITES THROUGH, which
 * makes a forward a wild store per conversion rather than a wrong number.
 *
 * IT IS DELIBERATELY NOT A GENERAL sscanf. CoreFoundation's link census shows
 * ONE call site plus one behind a TARGET_OS_MAC gate, so the directives those
 * need are an afternoon and a general parser is a project. The unsupported
 * case ABORTS BY NAME, because sscanf reports failure by returning a SHORT
 * COUNT -- indistinguishable at the call site from input that legitimately did
 * not match. A directive we cannot handle must not look like a caller's bad
 * input.
 *
 * THE TWO THINGS THIS GRADES MOST CLOSELY:
 *
 *   THE LENGTH MODIFIER DECIDES THE WIDTH OF THE STORE, and a caller cannot
 *   recover from getting it wrong: writing four bytes through a `short *`
 *   clobbers whatever follows. The uuid call site uses %hhx into a byte array,
 *   so each case below writes into a struct with a known-value guard after it
 *   and checks the guard survived. A version that always stored an int would
 *   pass every value check and fail every guard.
 *
 *   %c DOES NOT SKIP LEADING WHITESPACE, which is the one directive here that
 *   differs from the others. A version that skipped would silently consume a
 *   separator the caller was about to match literally, and the value it
 *   returned would still look right.
 *
 * The return value is the number of items ASSIGNED, and EOF (-1) when input ran
 * out before the first conversion -- not 0. Both are exercised, because a
 * caller checking specifically for EOF behaves differently from one checking
 * for a short count.
 */
#include <stdio.h>
#include <string.h>

int main(void)
{
    puts("== the two call sites the census found");
    {
        /* uuid-shaped: bytes through %hhx. */
        unsigned char b[4] = { 0, 0, 0, 0 };
        int n = sscanf("de:ad:be:ef", "%hhx:%hhx:%hhx:%hhx", &b[0], &b[1], &b[2], &b[3]);
        printf("  uuid-shaped n=%d  bytes %02x %02x %02x %02x\n", n, b[0], b[1], b[2], b[3]);
    }
    {
        /* version-shaped: %d.%d.%d */
        int maj = -1, min = -1, pat = -1;
        int n = sscanf("14.7.2", "%d.%d.%d", &maj, &min, &pat);
        printf("  version-shaped n=%d  %d.%d.%d\n", n, maj, min, pat);
    }

    puts("== the length modifier decides the width of the store");
    {
        /* Each target is followed by a guard with a known value. A store that
         * is too wide overwrites the guard while leaving the value correct. */
        struct { unsigned char v; unsigned char guard[3]; } c = { 0, { 0xAA, 0xBB, 0xCC } };
        struct { unsigned short v; unsigned short guard; } h = { 0, 0xBEEF };
        struct { unsigned int v; unsigned int guard; } i = { 0, 0xDEADBEEFu };
        sscanf("255", "%hhu", &c.v);
        sscanf("65535", "%hu", &h.v);
        sscanf("123456", "%u", &i.v);
        printf("  %%hhu -> %u  guard intact: %s\n", c.v,
               (c.guard[0] == 0xAA && c.guard[1] == 0xBB && c.guard[2] == 0xCC) ? "yes" : "NO");
        printf("  %%hu  -> %u  guard intact: %s\n", h.v, h.guard == 0xBEEF ? "yes" : "NO");
        printf("  %%u   -> %u  guard intact: %s\n", i.v, i.guard == 0xDEADBEEFu ? "yes" : "NO");
    }
    {
        unsigned long long ll = 0;
        sscanf("4294967296", "%llu", &ll);
        printf("  %%llu -> %llu  (exceeds 32 bits: %s)\n", ll, ll > 0xFFFFFFFFull ? "yes" : "NO");
    }

    puts("== %c does not skip whitespace, everything else does");
    {
        char ch = '?';
        int a = -1, b = -1;
        int n = sscanf("  42   7", "%d %d", &a, &b);
        printf("  leading and inner space skipped: n=%d a=%d b=%d\n", n, a, b);
        n = sscanf(" x", "%c", &ch);
        printf("  %%c on \" x\" reads '%c' (a space, not 'x'): %s\n",
               ch == ' ' ? '_' : ch, ch == ' ' ? "yes" : "NO");
    }

    puts("== bases, signs and widths");
    {
        int d1 = 0, d2 = 0, d3 = 0;
        unsigned u1 = 0;
        sscanf("-17", "%d", &d1);
        sscanf("0x1f", "%x", &u1);
        sscanf("0755", "%o", &d2);
        sscanf("0x2A", "%i", &d3);
        printf("  %%d(-17)=%d  %%x(0x1f)=%u  %%o(0755)=%d  %%i(0x2A)=%d\n", d1, u1, d2, d3);
    }
    {
        int w1 = 0, w2 = 0;
        int n = sscanf("123456", "%3d%3d", &w1, &w2);
        printf("  width splits 123456 into n=%d %d and %d\n", n, w1, w2);
    }

    puts("== strings, suppression, %n and %%");
    {
        char s1[32] = "", s2[32] = "";
        int n = sscanf("alpha beta", "%s %s", s1, s2);
        printf("  two strings n=%d [%s] [%s]\n", n, s1, s2);
        n = sscanf("skip 99", "%*s %d", &(int){0});
        printf("  suppression returns only the counted one: n=%d\n", n);
    }
    {
        int v = 0, pos = -1;
        int n = sscanf("42abc", "%d%n", &v, &pos);
        printf("  %%n reports consumed=%d (n=%d, and %%n is not counted)\n", pos, n);
        n = sscanf("50%", "%d%%", &v);
        printf("  %%%% matches a literal percent: n=%d v=%d\n", n, v);
    }

    puts("== short counts and EOF are different answers");
    {
        int a = -1, b = -1;
        int n = sscanf("7", "%d %d", &a, &b);
        printf("  input shorter than format: n=%d (a=%d, b untouched=%s)\n",
               n, a, b == -1 ? "yes" : "NO");
        n = sscanf("", "%d", &a);
        printf("  empty input returns EOF: %s\n", n == EOF ? "yes" : "NO");
        n = sscanf("zz", "%d", &a);
        printf("  non-matching input returns 0: %s\n", n == 0 ? "yes" : "NO");
    }

    puts("done");
    return 0;
}
