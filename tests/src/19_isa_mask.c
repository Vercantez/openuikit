/* 19_isa_mask.c -- rung (r): every loaded image must sit below 2^47.
 *
 * This fixture exists because a loader bug that breaks the entire Swift
 * standard library is invisible to every other fixture in the corpus.
 *
 * Apple's arm64 runtimes pack flags into the low and high bits of an object's
 * isa field and mask them off before use. The Swift standard library has the
 * 47-bit form -- `and x8, x8, #0x7ffffffffff8` -- INLINED into compiled code at
 * 20+ sites, including inside swift_getObjectType, swift_unknownObjectRetain
 * and swift_unknownObjectRelease, and then reads class->bits at +0x20. So any
 * class living at or above 2^47 is truncated to an address that is not mapped,
 * and the standard library faults on a pointer it computed itself.
 *
 * aarch64 Linux serves mmap(NULL, ...) top-down from near 2^48, so machorun
 * used to load every dylib at 0xffff_xxxx_xxxx and Swift died the moment it
 * touched a class that was not in the main executable -- which is every stdlib,
 * Foundation and UIKit class. src/map.c now places images deliberately.
 *
 * WHAT THIS PRINTS, and why none of it is an address. Addresses are not
 * comparable between the two hosts: macOS puts libSystem in the dyld shared
 * cache and machorun puts it in an arena at 8 GiB. So the fixture prints
 * PREDICATES, which are identical on both when the invariant holds -- and it
 * holds on macOS for free, because macOS gives user space a 47-bit address
 * space in the first place. That is the whole reason Apple could bake this mask
 * into a compiler.
 *
 * The probes are deliberately one address per IMAGE, and only addresses that
 * live inside a loaded image:
 *
 *   main         this executable's __TEXT
 *   a string     this executable's __TEXT,__cstring
 *   a global     this executable's __DATA
 *   printf       libSystem (machorun's own dylib; Apple's shared cache)
 *   strtod       libSystem again, to catch a partially-mapped image
 *
 * A stack or heap address would NOT do: under machorun those come from glibc
 * and legitimately sit above 2^47, because nothing masks them.
 *
 * BEFORE the fix this fixture printed `below_2_47=no` for printf and strtod on
 * Linux and `yes` on macOS, so difftest reported FAIL. That is the check.
 */
#include <stdio.h>
#include <stdlib.h>

#define ISA_LIMIT 0x800000000000ULL      /* 2^47 */
#define ISA_MASK  0x00007ffffffffff8ULL  /* what libswiftCore keeps */

static int a_global = 7;

/* The predicate a class pointer has to satisfy: masking must not move it.
 * Stated as the mask itself rather than as "< 2^47" so the test says what the
 * runtime does, not a paraphrase of it. These probes are all 8-aligned or
 * better in practice; the & ~7 keeps the question about the HIGH bits, which
 * are the ones the loader controls. */
static int survives_mask(const void *p)
{
    unsigned long long v = (unsigned long long)(unsigned long)p;
    return ((v & ~7ULL) & ISA_MASK) == (v & ~7ULL);
}

static void probe(const char *what, const void *p)
{
    printf("%-10s below_2_47=%s mask_preserves=%s\n", what,
           (unsigned long long)(unsigned long)p < ISA_LIMIT ? "yes" : "no",
           survives_mask(p) ? "yes" : "no");
}

int main(void)
{
    probe("main",   (const void *)(unsigned long)main);
    probe("cstring", (const void *)"a string in __cstring");
    probe("global", (const void *)&a_global);
    probe("printf", (const void *)(unsigned long)printf);
    probe("strtod", (const void *)(unsigned long)strtod);

    /* The arithmetic itself, on a value that is known-bad, so that a reader can
     * see what the failure looks like without having to reproduce it. */
    {
        unsigned long long bad = 0xffff8a2c6018ULL;
        printf("worked_example 0x%llx -> 0x%llx (%s)\n",
               bad, bad & ISA_MASK,
               (bad & ISA_MASK) == bad ? "unchanged" : "TRUNCATED");
    }
    return 0;
}
