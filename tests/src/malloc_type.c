/* malloc_type.c -- the `malloc_type` rung: Apple's TYPED allocator, malloc_type_*.
 *
 * THIS FIXTURE EXISTS BECAUSE THE BUG IT CATCHES COST THE PROJECT ITS LONGEST
 * HUNT. machorun's libSystem had no malloc_type family at all, so a sibling
 * repo supplied its own malloc_type_zone_malloc_with_options_internal with
 * four parameters instead of five. The real signature is
 * (zone, align, size, options, type_id), so the argument it forwarded to
 * malloc as the size was the ALIGNMENT -- sixteen bytes, whatever was asked
 * for. Every caller then wrote its whole object over the neighbours. That one
 * wrong register was the entirety of "46 UIKit scenes fail with
 * nondeterministic memory corruption": 22 glibc heap aborts, 19 SIGSEGVs on
 * wild addresses, 9 silent failures, no two alike, because a heap overflow of
 * arbitrary size onto arbitrary neighbours never fails the same way twice.
 *
 * WHY EVERY REQUEST HERE USES A SIZE AND AN ALIGNMENT THAT DIFFER, AND WHY
 * NEITHER IS 16. A wrong-argument bug in this family is invisible whenever the
 * two happen to coincide, and 16 is both the usual alignment and a plausible
 * size, so it is the one value that hides the bug rather than showing it. Each
 * case below asks for a size that no argument confusion could produce by
 * accident: not the alignment, not the count, not the options word, not the
 * zone pointer.
 *
 * WHY malloc_size IS CHECKED BEFORE ANYTHING IS WRITTEN. The broken version
 * returned a perfectly valid pointer every single time; the damage surfaced
 * somewhere else, later, as somebody else's crash. A fixture that only wrote
 * and looked for a crash would be testing the heap's luck. Asking the
 * allocator how big the block is turns the size into a checked property at the
 * point of allocation, which is the only place the answer is unambiguous.
 *
 * The guard blocks and the fill are a second layer, not the first: they catch
 * a block that is honestly reported and still too small.
 *
 * On macOS this runs against the real libmalloc, so the oracle is Apple's own
 * answer to every one of these questions.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <malloc/malloc.h>

/* The zone-level "with options" entry is SPI: it has no public declaration
 * even in Apple's SDK, so declare it exactly as malloc/malloc.h:192 spells the
 * zone function pointer of the same name. Getting THIS declaration wrong is
 * the whole bug, so it is written out in full rather than shortened. */
extern void *malloc_type_zone_malloc_with_options_internal(malloc_zone_t *zone,
                                                           size_t align,
                                                           size_t size,
                                                           unsigned long long options,
                                                           malloc_type_id_t type_id);

#define TYPE_ID 0x00080c4018a671a6ULL   /* a real one, from libswiftCore's call sites */

static int failures;

static void fail(const char *what, size_t want, size_t got)
{
    printf("FAIL %s: wanted %zu, got %zu\n", what, want, got);
    failures++;
}

/* Fill `n` bytes with a position-dependent pattern and read it back. A block
 * that is too small either faults here or silently damages a neighbour, and
 * the guards below turn the second case into a report. */
static void fill(unsigned char *p, size_t n, unsigned char seed)
{
    for (size_t i = 0; i < n; i++) p[i] = (unsigned char)(seed + (i & 0xff));
}

static int check_fill(const unsigned char *p, size_t n, unsigned char seed)
{
    for (size_t i = 0; i < n; i++)
        if (p[i] != (unsigned char)(seed + (i & 0xff))) return 0;
    return 1;
}

/* One allocation, fully checked: reported size, alignment, a full-size write,
 * and two neighbours that must survive it. */
static void check_block(const char *what, void *p, size_t size, size_t align)
{
    unsigned char *guard_lo, *guard_hi;
    size_t reported;

    if (!p) { printf("FAIL %s: returned NULL\n", what); failures++; return; }

    reported = malloc_size(p);
    if (reported < size) { fail(what, size, reported); return; }

    if (align && ((unsigned long)(unsigned long long)(size_t)p & (align - 1)) != 0) {
        printf("FAIL %s: %p is not %zu-aligned\n", what, p, align);
        failures++;
        return;
    }

    guard_lo = malloc(256);
    guard_hi = malloc(256);
    if (!guard_lo || !guard_hi) { printf("FAIL %s: guard allocation\n", what); failures++; return; }
    fill(guard_lo, 256, 0x5a);
    fill(guard_hi, 256, 0xa5);

    fill(p, size, 0x11);

    if (!check_fill(p, size, 0x11)) { printf("FAIL %s: block did not hold its own bytes\n", what); failures++; }
    if (!check_fill(guard_lo, 256, 0x5a)) { printf("FAIL %s: damaged a neighbour (lo)\n", what); failures++; }
    if (!check_fill(guard_hi, 256, 0xa5)) { printf("FAIL %s: damaged a neighbour (hi)\n", what); failures++; }

    free(guard_lo);
    free(guard_hi);
    printf("ok   %-46s size=%-6zu align=%-5zu reported>=size\n", what, size, align);
}

int main(void)
{
    malloc_zone_t *zone = malloc_default_zone();
    void *p;

    /* --- the plain typed family ------------------------------------- */
    check_block("malloc_type_malloc(3000)", malloc_type_malloc(3000, TYPE_ID), 3000, 0);

    p = malloc_type_calloc(300, 7, TYPE_ID);
    check_block("malloc_type_calloc(300, 7)", p, 2100, 0);

    p = malloc_type_malloc(700, TYPE_ID);
    p = malloc_type_realloc(p, 5000, TYPE_ID);
    check_block("malloc_type_realloc(->5000)", p, 5000, 0);

    /* align 64, size 3008: neither value can stand in for the other, and 3008
     * is a MULTIPLE of 64 because C11's aligned_alloc requires that and Apple
     * enforces it -- measured, `malloc_type_aligned_alloc(64, 3000)` returns
     * NULL on macOS. The negative case is checked separately below. */
    check_block("malloc_type_aligned_alloc(64, 3008)",
                malloc_type_aligned_alloc(64, 3008, TYPE_ID), 3008, 64);

    p = NULL;
    if (malloc_type_posix_memalign(&p, 128, 4400, TYPE_ID) != 0) p = NULL;
    check_block("malloc_type_posix_memalign(128, 4400)", p, 4400, 128);

    /* --- the zone family: note zone_malloc has NO alignment argument -- */
    check_block("malloc_type_zone_malloc(zone, 3300)",
                malloc_type_zone_malloc(zone, 3300, TYPE_ID), 3300, 0);

    p = malloc_type_zone_calloc(zone, 130, 9, TYPE_ID);
    check_block("malloc_type_zone_calloc(zone, 130, 9)", p, 1170, 0);

    check_block("malloc_type_zone_memalign(zone, 256, 3900)",
                malloc_type_zone_memalign(zone, 256, 3900, TYPE_ID), 3900, 256);

    /* --- THE ONE THAT WAS WRONG --------------------------------------
     * Five arguments. If `size` is read from the wrong register the block
     * comes back as 32 bytes (the alignment), 0 (the options word) or a
     * pointer-sized nonsense (the zone), and malloc_size says so before a
     * single byte is written. */
    check_block("..._zone_malloc_with_options_internal(32, 6144, 0)",
                malloc_type_zone_malloc_with_options_internal(zone, 32, 6144, 0, TYPE_ID),
                6144, 32);

    /* Same entry point with MALLOC_NP_OPTION_CLEAR: must be zeroed AND the
     * right size. A wrong size argument here zeroes the wrong amount too. */
    {
        unsigned char *z = malloc_type_zone_malloc_with_options_internal(zone, 64, 5120, 1,
                                                                         TYPE_ID);
        size_t i, nonzero = 0;
        if (!z) { printf("FAIL with_options(CLEAR): NULL\n"); failures++; }
        else {
            if (malloc_size(z) < 5120) fail("with_options(CLEAR) size", 5120, malloc_size(z));
            for (i = 0; i < 5120; i++) if (z[i]) nonzero++;
            if (nonzero) { printf("FAIL with_options(CLEAR): %zu of 5120 bytes not zero\n", nonzero); failures++; }
            else printf("ok   %-46s size=%-6d align=%-5d zeroed\n",
                        "..._with_options_internal(64, 5120, CLEAR)", 5120, 64);
            check_block("..._with_options_internal(64, 5120, CLEAR) block", z, 5120, 64);
        }
    }

    /* THE NEGATIVE CASES, measured against Apple's libmalloc rather than read
     * out of a header, because no header states them. They matter as much as
     * the positive ones: an implementation that succeeds where macOS returns
     * NULL diverges in the permissive direction, which nothing downstream
     * notices until much later. */
    {
        struct { const char *what; void *got; int want_null; } neg[] = {
            { "aligned_alloc(64, 3000) [not a multiple]",
              malloc_type_aligned_alloc(64, 3000, TYPE_ID), 1 },
            { "with_options_internal(32, 6000) [not a multiple]",
              malloc_type_zone_malloc_with_options_internal(zone, 32, 6000, 0, TYPE_ID), 1 },
            { "with_options_internal(16, 6000) [align <= 16 is exempt]",
              malloc_type_zone_malloc_with_options_internal(zone, 16, 6000, 0, TYPE_ID), 0 },
            { "zone_memalign(64, 3000) [no multiple rule]",
              malloc_type_zone_memalign(zone, 64, 3000, TYPE_ID), 0 },
            { "valloc(6000) [no multiple rule]",
              malloc_type_valloc(6000, TYPE_ID), 0 },
        };
        for (unsigned i = 0; i < sizeof(neg) / sizeof(neg[0]); i++) {
            int is_null = (neg[i].got == NULL);
            if (is_null != neg[i].want_null) {
                printf("FAIL %s: %s, expected %s\n", neg[i].what,
                       is_null ? "NULL" : "a pointer", neg[i].want_null ? "NULL" : "a pointer");
                failures++;
            } else {
                printf("ok   %-46s %s\n", neg[i].what, is_null ? "NULL" : "a pointer");
            }
            free(neg[i].got);
        }
    }

    /* --- free through the typed entry points ------------------------- */
    p = malloc_type_malloc(900, TYPE_ID);
    malloc_type_free(p, TYPE_ID);
    p = malloc_type_zone_malloc(zone, 900, TYPE_ID);
    malloc_type_zone_free(zone, p, TYPE_ID);
    printf("ok   %-46s\n", "malloc_type_free / malloc_type_zone_free");

    printf("%s: %d failure(s)\n", failures ? "FAILED" : "PASSED", failures);
    return failures ? 1 : 0;
}
