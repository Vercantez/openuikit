/* isa_mask.c -- the `isa_mask` rung: every loaded image must sit below 2^47.
 *
 * This fixture exists because a loader bug that breaks the entire Swift
 * standard library is invisible to every other fixture in the corpus.
 *
 * Apple's arm64 runtimes pack flags into the low and high bits of an object's
 * isa field and mask them off before use. The Swift standard library has the
 * 47-bit form -- `and x8, x8, #0x7ffffffffff8` -- INLINED into compiled code at
 * 48 sites, including inside swift_getObjectType, swift_unknownObjectRetain
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
 * THE HEAP IS PROBED TOO, and that is the second half of the bug. Not every
 * class object lives in an image: libswiftCore builds a generic class's
 * metadata at RUN TIME, and objc4's objc_allocateClassPair does the same for a
 * class pair. The first 64 KiB of Swift metadata come from a static pool inside
 * libswiftCore's own __DATA -- so a small program passes no matter how wrong
 * the policy is, which is exactly how this half stayed hidden -- and past that
 * the allocator falls through to malloc. On aarch64 Linux a PIE lands at
 * 2*TASK_SIZE/3 and brk follows the image, so the heap inherited an address
 * above 2^47 that no mmap policy could move; the loader is therefore linked
 * non-PIE at 1 TiB. Measured: a guest instantiating 900 distinct generic
 * classes died 8 runs out of 8 at `libswiftCore+0x332898, fault
 * 0x2aaaec0e1818` -- an ordinary main-arena address with bit 47 cut -- and
 * passes 8 out of 8 with the loader linked low.
 *
 * The STACK is deliberately NOT probed. Nothing masks a stack address, so
 * requiring it to be low would be inventing a constraint; under machorun it
 * legitimately sits above 2^47.
 *
 * Neither is an allocation above glibc's 32 MiB mmap threshold, which still
 * comes from mmap and still lands high. That is a real residue, stated in
 * docs/UNIMPLEMENTED.md#isa-va-width rather than asserted here: no class object
 * is 32 MiB, and a guest asking for a buffer that size is asking for a buffer.
 *
 * BEFORE the image fix this printed `below_2_47=no` for printf and strtod on
 * Linux and `yes` on macOS; before the heap fix, `no` for the malloc probes.
 * Either way difftest reports FAIL. That is the check.
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

    /* The heap, where a runtime-built class object comes from. Small is the
     * size that matters -- Swift's metadata pool refills at 64 KiB, objc4's
     * class pairs are a few hundred bytes -- and 1 MiB is here to catch a
     * too-eager mmap threshold. Both stay under glibc's 32 MiB threshold on
     * purpose; see the header. Freed in reverse so nothing is leaked. */
    {
        void *small = malloc(64);
        void *mid   = malloc(1024 * 1024);
        if (!small || !mid) { fputs("malloc failed\n", stderr); return 1; }
        probe("malloc64", small);
        probe("malloc1M", mid);
        free(mid);
        free(small);
    }

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
