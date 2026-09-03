/* map.c -- segment mapping, __PAGEZERO reservation, page-size policy.
 *
 * Measured facts this code rests on (docs/MACHO_NOTES.md §1, §9):
 *   - every segment vmaddr and fileoff Apple's arm64 toolchain emits is a
 *     multiple of 0x4000, and macOS itself SIGKILLs anything else, so a
 *     fixture that runs on the oracle is always >=16K aligned;
 *   - the target Linux container has a 4096-byte page, and 16384 is a
 *     multiple of 4096, so mmap/mprotect are exact and this is free;
 *   - a 64 KiB-page kernel cannot give __TEXT and __DATA_CONST distinct
 *     protections (they are 16 KiB apart) -- detected and refused here
 *     rather than silently mis-mapped.
 *
 * Extracted dyld-shared-cache dylibs are the exception the mmap path cannot
 * swallow. Apple packs data segments contiguously in the cache, so a
 * segment's vmaddr (and its fileoff after `ipsw dyld extract`) is not page
 * aligned -- measured 2026-09-03 on x86_64:
 *     libswiftObjectiveC.dylib __DATA_CONST vmaddr 0x7ff843287720
 * mmap requires both addr and fileoff to be page-aligned, so those images
 * take the COPY path below: one anonymous reservation covering the
 * page-rounded union of the segments, file bytes pread into place, then
 * per-page protections. Two segments that share a host page get the UNION
 * of their protections (typically rwx across a TEXT/DATA boundary, rw
 * across DATA_CONST/DATA). Documented rather than clever, because a host
 * page cannot hold two protection sets. The mmap fast path for page-aligned
 * segments is unchanged.
 */
#define _GNU_SOURCE
#include "machorun.h"

#include <errno.h>
#include <malloc.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>

#ifndef MAP_FIXED_NOREPLACE
#define MAP_FIXED_NOREPLACE 0x100000
#endif

#define EXEC_PREFERRED_BASE 0x100000000ull

/* ===================================================================== *
 * WHERE THINGS GO, and why it is not "wherever mmap feels like".
 *
 * Apple's arm64 runtimes do not treat an isa field as a whole pointer. The
 * Swift standard library has the 47-bit mask INLINED into compiled code --
 * `and x8, x8, #0x7ffffffffff8` appears at 48 sites in the libswiftCore we
 * run, including inside swift_getObjectType, swift_unknownObjectRetain and
 * swift_unknownObjectRelease -- and then reads class->bits at +0x20.
 *
 * aarch64 Linux serves mmap(NULL, ...) top-down from near 2^48, so every dylib
 * used to land at 0xffff_xxxx_xxxx. Masking that clears bit 47:
 *
 *     class                 0xffff8a2c6018
 *     isa & 0x7ffffffffff8  0x7fff8a2c6018     <- bit 47 gone
 *     read at +0x20         SIGSEGV
 *
 * Measured exactly that way: a Swift program reaching any class that lives in
 * a DYLIB -- which is every stdlib, Foundation and UIKit class -- died with
 * SIGSEGV in libswiftCore+0x332898 at fault address 0x7fff8a2c6010, the
 * truncation of a real class at 0xffff8a2c6010. Programs whose classes are all
 * in the EXECUTABLE survived by luck, because MH_EXECUTE lands at its
 * preferred 0x100000000 and that is already below the limit.
 *
 * objc4 is fine here only because patches-macho/0001 widens it to the 52-bit
 * arm64e shiftcls layout. libswiftCore cannot get the same treatment: the mask
 * is compiled into the library in many places, and a custom mask would fork
 * the standard library from upstream permanently. So the loader meets Swift
 * where it is, and places images itself.
 *
 * `ulimit -s unlimited` also "fixes" the IMAGE half of this -- it flips Linux
 * to the legacy bottom-up mmap layout process-wide -- but that is a property of
 * how machorun was invoked rather than of machorun, it stops applying the moment
 * something re-execs, and it moves every unrelated allocation too. A policy here
 * is checkable; an ambient rlimit is not. It also never fixed the heap half
 * below, which is the part that bites second.
 *
 * ---------------------------------------------------------------------
 * THE HEAP IS THE OTHER HALF, and mapping images low does not cover it.
 *
 * Not every class object lives in an image. libswiftCore builds the metadata
 * for a generic class at RUNTIME, and that metadata *is* the class an instance
 * points at. Its first 64 KiB come from InitialAllocationPool, a static array
 * in libswiftCore's own __DATA, which the arena below already places low -- so
 * a small program looks fine and stays fine no matter how wrong the policy is.
 * Past 64 KiB the allocator falls through to swift_slowAlloc -> malloc, and
 * glibc answers from wherever it likes.
 *
 * Measured, with images already placed low by the arena below: a program that
 * instantiates 900 distinct generic classes died with
 *
 *     SIGSEGV at pc libswiftCore+0x332898, fault address 0x2aaab6c04ea8
 *
 * which is 0xaaaab6c04ea8 -- a perfectly ordinary glibc main-arena address --
 * with bit 47 cleared. Same instruction as the dylib failure above; a different
 * source of high addresses. objc_allocateClassPair and objc_duplicateClass
 * reach it the same way.
 *
 * On aarch64 the main arena is the problem case and it is NOT an mmap: Linux
 * puts a PIE at 2*TASK_SIZE/3 (0xaaaa_xxxx_xxxx) and brk follows the image, so
 * the heap inherits an address above 2^47 that no mmap policy can move. That is
 * why the fix is a LINK-TIME one -- scripts/build.sh links the loader at
 * MR_LOADER_BASE, below the limit, so brk starts below it too -- plus the two
 * mallopt calls in mr_constrain_heap() that keep glibc from going to mmap for
 * the sizes that matter. mr_constrain_heap() then verifies the result rather
 * than trusting it.
 * ===================================================================== */

/* The arena starts at 8 GiB: clear of __PAGEZERO and of a 4 GiB executable at
 * EXEC_PREFERRED_BASE, and far below anything the kernel hands out itself. */
#define MR_ARENA_BASE  0x200000000ull
#define MR_ARENA_STEP  0x200000ull       /* 2 MiB probe step on collision */
#define MR_ARENA_TRIES 8192              /* 16 GiB of probing before giving up */

static uint64_t arena_cursor = MR_ARENA_BASE;

/* Reserve `span` bytes wholly below MR_ISA_LIMIT. Returns MAP_FAILED if the
 * arena is exhausted, and the caller treats that as fatal rather than falling
 * back to mmap(NULL): a fallback would put the image somewhere Swift cannot
 * address, turning a clear failure here into a SIGSEGV inside the standard
 * library later, with a fault address that looks like memory corruption. */
static void *reserve_in_arena(uint64_t span)
{
    uint64_t addr = mr_round_up(arena_cursor, MR.page.v);

    for (int i = 0; i < MR_ARENA_TRIES; i++) {
        void *got;
        if (addr > MR_ISA_LIMIT || span > MR_ISA_LIMIT - addr) break;

        got = mmap((void *)addr, span, PROT_NONE,
                   MAP_PRIVATE | MAP_ANONYMOUS | MAP_NORESERVE | MAP_FIXED_NOREPLACE, -1, 0);
        if (got != MAP_FAILED) {
            if (got == (void *)addr) {
                arena_cursor = addr + span;
                return got;
            }
            /* A kernel older than 4.17 does not know MAP_FIXED_NOREPLACE and
             * treats the address as a bare hint, so it may answer anywhere --
             * including back above 2^47. Hand it back and step past rather
             * than keep an address we did not choose. */
            munmap(got, span);
        }
        addr += MR_ARENA_STEP;
    }
    return MAP_FAILED;
}

static int prot_of(uint32_t vmprot)
{
    int p = 0;
    if (vmprot & VM_PROT_READ)    p |= PROT_READ;
    if (vmprot & VM_PROT_WRITE)   p |= PROT_WRITE;
    if (vmprot & VM_PROT_EXECUTE) p |= PROT_EXEC;
    return p;
}

/* Keep glibc's answers to the guest's malloc below MR_ISA_LIMIT, and prove it.
 *
 * Two knobs, because glibc has two ways of leaving the main arena and both of
 * them land above 2^47 on this kernel:
 *
 *   M_ARENA_MAX 1        a second thread otherwise gets its own arena, which is
 *                        mmap'd -- measured at 0xffffb4000b70. Every guest
 *                        thread shares the main arena instead. It costs
 *                        contention, which is the right trade against handing
 *                        Swift a class pointer it cannot address.
 *   M_MMAP_THRESHOLD     a single allocation at or above the threshold is
 *                        mmap'd rather than taken from brk. 32 MiB is glibc's
 *                        own DEFAULT_MMAP_THRESHOLD_MAX, so this is the largest
 *                        the knob goes; setting it also pins the threshold,
 *                        which otherwise adapts upward on its own.
 *
 * What is deliberately NOT claimed: a single allocation larger than 32 MiB
 * still comes from mmap and still lands high. That is documented rather than
 * fixed because no class object is 32 MiB -- the sizes at issue are Swift's
 * 64 KiB metadata pool refills and objc4's few-hundred-byte class pairs -- and
 * a guest asking for a 32 MiB buffer is asking for a buffer, not a class.
 * docs/UNIMPLEMENTED.md#isa-va-width states the residue exactly. */
/* Is this pointer inside glibc's main-arena heap?
 *
 * malloc_size(p) has to answer "did a malloc zone allocate this?", and
 * mr_addr_in_image() only answers the mapped-image half. Everything else --
 * a stack address, the loader's own statics, memory from an allocator that is
 * not glibc's -- used to fall through to malloc_usable_size(), which reads the
 * word before the pointer and validates NOTHING. It returns a plausible
 * non-zero for any address at all, so objc4's
 *     try_free(p) { if (p && malloc_size(p)) free(p); }
 * frees it, and glibc aborts with "free(): invalid pointer" or
 * "munmap_chunk(): invalid pointer". That is the exact symptom
 * darwin/src/libsystem.c's comment records fixing for tests/objc44/023, seen
 * again in the UIKit scenes -- so the fix was incomplete rather than wrong.
 *
 * The main arena is the brk region, and its bounds are knowable: [heap] in
 * /proc/self/maps gives the start exactly, and sbrk(0) the moving top. We read
 * the start once, here, before the guest exists, and cache the top -- it only
 * grows, so a cached value can only be stale in the safe direction and is
 * refreshed when a pointer sits above it.
 *
 * WHAT THIS DELIBERATELY GIVES UP: a single allocation at or above glibc's
 * 32 MiB M_MMAP_THRESHOLD comes from mmap rather than brk, so it is outside
 * these bounds and reports "not ours". A guest that try_free()s a >=32 MiB
 * block therefore leaks it. That is the correct direction to be wrong in --
 * guessing "not mine" leaks, guessing "mine" corrupts the heap -- and it is
 * the same 32 MiB residue docs/UNIMPLEMENTED.md#opaque-abi-class already
 * records. No class object is 32 MiB. */
static uintptr_t heap_lo;
static uintptr_t heap_hi_cache;

static void heap_bounds_init(void)
{
    char line[512];
    FILE *f = fopen("/proc/self/maps", "r");
    if (!f) { mr_log("heap bounds: /proc/self/maps unreadable; malloc_size "
                     "will answer \"not ours\" for every non-image pointer"); return; }
    while (fgets(line, sizeof line, f)) {
        unsigned long lo, hi;
        if (!strstr(line, "[heap]")) continue;
        if (sscanf(line, "%lx-%lx", &lo, &hi) == 2) {
            heap_lo = (uintptr_t)lo;
            heap_hi_cache = (uintptr_t)hi;
        }
        break;
    }
    fclose(f);
    if (!heap_lo)
        mr_log("heap bounds: no [heap] mapping yet; malloc_size will answer "
               "\"not ours\" until one appears");
}

int mr_addr_in_glibc_heap(const void *p)
{
    uintptr_t a = (uintptr_t)p, hi;
    if (!heap_lo || a < heap_lo) return 0;
    hi = __atomic_load_n(&heap_hi_cache, __ATOMIC_RELAXED);
    if (a < hi) return 1;
    /* Above what we last saw: the heap may simply have grown. */
    hi = (uintptr_t)sbrk(0);
    __atomic_store_n(&heap_hi_cache, hi, __ATOMIC_RELAXED);
    return a < hi;
}

void mr_constrain_heap(void)
{
    void *probe, *big;
    uint64_t brk_now;

    /* Before the first guest thread and before the runtimes allocate anything:
     * M_ARENA_MAX only governs arenas not yet created.
     *
     * A refusal is fatal rather than logged, because M_ARENA_MAX is doing most
     * of the work here, not hardening the edges. MEASURED on glibc 2.39 with 16
     * threads x 201 allocations: with these two calls, 0 allocations landed at
     * or above 2^47; with them removed and nothing else changed, 3216 of 3216
     * did -- every secondary thread allocates from an mmap'd arena at
     * 0xffff_xxxx_xxxx. Continuing past a refusal would mean running a threaded
     * Swift guest whose class pointers are all truncatable. */
    if (mallopt(M_ARENA_MAX, 1) == 0)
        mr_die("mallopt(M_ARENA_MAX, 1) was refused. Without it every guest thread "
               "after the first allocates from its own mmap'd arena above 2^47, and "
               "libswiftCore would truncate any class object living there.");
    /* M_MMAP_MAX 0 forbids malloc from using mmap AT ALL, which is what actually
     * closes this. M_MMAP_THRESHOLD alone could not: glibc caps it at
     * HEAP_MAX_SIZE/2 = 32 MiB, so every single allocation of 32 MiB or more
     * went to mmap and landed at 0xffff_xxxx_xxxx -- above the very ceiling this
     * function exists to enforce. That was a documented "residue" and it was the
     * wrong call: a hole in the guarantee is not made safe by writing it down.
     *
     * MEASURED, same program, only this knob differing:
     *     without   1 MiB low, 32/64/256 MiB and 1 GiB ALL at 0xffff...
     *     with      every size low, up to and including 1 GiB, each fully
     *               written to so the memory is demonstrably real
     *
     * The cost is real and worth naming: a large block freed by the guest goes
     * back to the brk free list instead of being munmap'd, so RSS can stay high
     * after a big free. That is a retention cost, and it buys the property that
     * NO allocation can be handed to Swift as an unaddressable class pointer.
     *
     * M_MMAP_THRESHOLD stays as defence in depth -- if M_MMAP_MAX is ever
     * reverted, it still keeps everything under 32 MiB on brk. */
    if (mallopt(M_MMAP_MAX, 0) == 0)
        mr_die("mallopt(M_MMAP_MAX, 0) was refused. Without it every allocation at "
               "or above glibc's 32 MiB mmap threshold comes from mmap and lands "
               "above 2^47, where libswiftCore's isa mask truncates it. There is no "
               "smaller value to fall back to: 0 is the only setting that forbids "
               "mmap outright.");
    if (mallopt(M_MMAP_THRESHOLD, 32 * 1024 * 1024) == 0)
        mr_die("mallopt(M_MMAP_THRESHOLD, 32 MiB) was refused. glibc caps it at "
               "HEAP_MAX_SIZE/2; if that cap has changed, lower this constant to "
               "the HIGHEST value glibc now accepts, not to the first value that "
               "stops this abort.");

    /* The link-time base is what actually decides this, so check the result
     * instead of assuming the linker was told. A loader that starts here and
     * hands Swift a truncatable class later is worse than one that stops. */
    brk_now = (uint64_t)(uintptr_t)sbrk(0);
    probe = malloc(64);
    if (!probe) mr_die("out of memory constraining the heap");

    /* THE SECOND PROBE IS THE POINT. A check that allocates 64 bytes and
     * concludes "the heap is below 2^47" verifies only the case it was written
     * for: small allocations come from brk, brk is where the link-time base put
     * it, and the answer was never in doubt. The case that WAS broken -- a
     * single allocation big enough for glibc to reach for mmap -- is invisible
     * to it. So probe on the far side of the old boundary too, and do it with a
     * size that would have failed before this function set M_MMAP_MAX.
     *
     * It is not touched, only measured: on Linux an untouched brk extension
     * costs address space and a syscall, not resident memory, so this is two
     * brk calls at startup rather than 33 MiB of RSS. */
    big = malloc(MR_HEAP_PROBE_LARGE);
    if (!big) mr_die("out of memory taking the large-allocation probe (%llu bytes)",
                     (unsigned long long)MR_HEAP_PROBE_LARGE);

    if (brk_now >= MR_ISA_LIMIT || (uint64_t)(uintptr_t)probe >= MR_ISA_LIMIT)
        mr_die("the heap starts at 0x%llx and malloc answered 0x%llx, at or above "
               "2^47 (0x%llx). libswiftCore masks an isa with 0x7ffffffffff8, so a "
               "class allocated there decodes to an unmapped address and the Swift "
               "runtime faults on a pointer it computed itself. machorun must be "
               "linked below the limit: see MR_LOADER_BASE in scripts/build.sh.",
               (unsigned long long)brk_now, (unsigned long long)(uintptr_t)probe,
               (unsigned long long)MR_ISA_LIMIT);

    if ((uint64_t)(uintptr_t)big >= MR_ISA_LIMIT)
        mr_die("a %llu-byte allocation answered 0x%llx, at or above 2^47 (0x%llx), "
               "while a small one stayed low. That is glibc serving large requests "
               "from mmap instead of brk, which is exactly what mallopt(M_MMAP_MAX, 0) "
               "above is supposed to forbid -- so either that call did not take "
               "effect, or this glibc reaches for mmap by another route.",
               (unsigned long long)MR_HEAP_PROBE_LARGE,
               (unsigned long long)(uintptr_t)big, (unsigned long long)MR_ISA_LIMIT);

    free(big);
    free(probe);
    heap_bounds_init();
    /* qemu-user (and some stripped environments) never label a [heap] VMA.
     * mallopt(M_MMAP_MAX, 0) forced every malloc onto brk, so the break we
     * sampled before the probes IS the arena start for everything the guest
     * will be handed. Without this, malloc_size -- and malloc_zone_from_ptr
     * which uses it as the ownership test -- answers 0 for every heap pointer
     * under qemu-user. Measured: MACHORUN_VERBOSE logs "no [heap] mapping yet"
     * and a 32-byte malloc() then fails the ownership test. Native aarch64
     * still takes the [heap] path; this is only the missing-label case. */
    if (!heap_lo) {
        heap_lo = (uintptr_t)brk_now;
        heap_hi_cache = (uintptr_t)sbrk(0);
        mr_log("heap bounds: no [heap] VMA; using brk [0x%llx, 0x%llx)",
               (unsigned long long)heap_lo, (unsigned long long)heap_hi_cache);
    }
    mr_log("heap constrained: brk 0x%llx, one arena, mmap disabled; %llu-byte probe "
           "also below the limit 0x%llx",
           (unsigned long long)brk_now, (unsigned long long)MR_HEAP_PROBE_LARGE,
           (unsigned long long)MR_ISA_LIMIT);
}

void mr_reserve_pagezero(void)
{
    /* vm.mmap_min_addr is 32768 on the target container, so we cannot start at
     * 0 -- and do not need to: the kernel's own low-address ban already gives
     * us the null-deref-faults property below it. */
    void *p = mmap((void *)0x10000, EXEC_PREFERRED_BASE - 0x10000, PROT_NONE,
                   MAP_PRIVATE | MAP_ANONYMOUS | MAP_NORESERVE | MAP_FIXED_NOREPLACE, -1, 0);
    if (p == MAP_FAILED || p != (void *)0x10000) {
        if (p != MAP_FAILED) munmap(p, EXEC_PREFERRED_BASE - 0x10000);
        mr_log("could not reserve __PAGEZERO [0x10000, 0x100000000): %s "
               "(harmless: its only job is to make null derefs fault)", strerror(errno));
        return;
    }
    mr_log("__PAGEZERO reserved: [0x10000, 0x100000000) PROT_NONE");
}

/* A segment that claims file bytes past EOF is corrupt. Apple's toolchain
 * never emits this; a truncated extraction and the cache_layout_oversize
 * fixture do. Checked against the real file size (im->raw_len), not against
 * vmsize -- claiming more file bytes than exist is the thing we refuse,
 * even if we would have truncated the copy to vmsize. */
static void check_segment_file_bytes(const mr_image *im, const mr_segment *s)
{
    uint64_t off;
    if (s->filesize == 0) return;
    off = im->slice_off + s->fileoff;
    if (off < im->slice_off || off > im->raw_len ||
        s->filesize > im->raw_len - off)
        mr_die("%s: segment %s file bytes at offset %llu+%llu exceed the file (%zu bytes)",
               im->path, s->name,
               (unsigned long long)off, (unsigned long long)s->filesize, im->raw_len);
}

static int image_needs_copy(const mr_image *im, uint64_t page)
{
    for (int i = 0; i < im->nsegs; i++) {
        const mr_segment *s = &im->segs[i];
        uint64_t off;
        if (strcmp(s->name, "__PAGEZERO") == 0) continue;
        if (s->vmsize == 0) continue;
        if ((s->vmaddr & (page - 1)) != 0) return 1;
        if (s->filesize == 0) continue;
        off = im->slice_off + s->fileoff;
        if ((off & (page - 1)) != 0) return 1;
    }
    return 0;
}

/* Per-page union of segment protections. `after_fixups` downgrades
 * SG_READ_ONLY segments from their initprot (rw, so fixups can land) to
 * PROT_READ, matching mr_protect_readonly_segments on the mmap path.
 *
 * Two segments that share a host page cannot be given distinct protections:
 * the page gets every PROT_* bit either occupant asked for. Typical cases
 * in a packed cache dylib: DATA_CONST (r after fixups) sharing with DATA
 * (rw) becomes rw; TEXT (rx) sharing with DATA_CONST (rw) becomes rwx and
 * loses W^X on that page. Gaps between segments stay PROT_NONE. */
static void apply_copy_page_prots(mr_image *im, int after_fixups)
{
    uint64_t page = MR.page.v;
    uint64_t a;

    for (a = im->span_lo; a < im->span_hi; a += page) {
        int prot = 0, any = 0;
        for (int i = 0; i < im->nsegs; i++) {
            const mr_segment *s = &im->segs[i];
            uint64_t lo, hi;
            int p;
            if (strcmp(s->name, "__PAGEZERO") == 0) continue;
            if (s->vmsize == 0) continue;
            lo = s->vmaddr + (uint64_t)im->slide;
            hi = lo + s->vmsize;
            if (a + page <= lo || a >= hi) continue;
            any = 1;
            p = prot_of(s->initprot);
            if (after_fixups && (s->flags & SG_READ_ONLY))
                p = PROT_READ | (p & PROT_EXEC);
            prot |= p;
        }
        if (!any) continue;
        if (prot == 0) prot = PROT_NONE;
        if (mprotect((void *)a, (size_t)page, prot) != 0)
            mr_die("%s: mprotect of copied page 0x%llx to %c%c%c: %m",
                   im->path, (unsigned long long)a,
                   (prot & PROT_READ) ? 'r' : '-',
                   (prot & PROT_WRITE) ? 'w' : '-',
                   (prot & PROT_EXEC) ? 'x' : '-');
    }
}

static void map_image_by_copy(mr_image *im)
{
    uint64_t page = MR.page.v;
    void *got;

    im->mapped_by_copy = 1;
    mr_log("%s: mapping by copy (non-page-aligned vmaddr/fileoff; "
           "dyld-shared-cache layout). Shared host pages take the union of "
           "their segments' protections.", im->path);

    /* Pass 1: one anonymous RW mapping per merged page-run, over the
     * PROT_NONE reservation. Merging matters: DATA_CONST and DATA in a
     * packed cache dylib share a host page, and a second MAP_FIXED
     * anonymous mmap of that page would zero the first. Gaps between
     * runs stay PROT_NONE. A packed-fixture SIGSEGV at slide+0x4008 with
     * DATA at +0x14720 is stale ADRP in TEXT (the rewriter must move it),
     * not a missing data page — TEXT.vmsize ends at 0x4000 and the gap
     * is the CACHE_GAP, left unmapped on purpose. */
    {
        uint64_t lo[MR_MAX_SEGMENTS], hi[MR_MAX_SEGMENTS];
        int nrun = 0;
        for (int i = 0; i < im->nsegs; i++) {
            const mr_segment *s = &im->segs[i];
            uint64_t addr, a, b;
            int k;
            if (strcmp(s->name, "__PAGEZERO") == 0) continue;
            if (s->vmsize == 0) continue;
            addr = s->vmaddr + (uint64_t)im->slide;
            a = mr_round_dn(addr, page);
            b = mr_round_up(addr + s->vmsize, page);
            if (b < a) mr_die("%s: segment %s wraps the address space", im->path, s->name);
            for (k = nrun; k > 0 && lo[k - 1] > a; k--) {
                lo[k] = lo[k - 1];
                hi[k] = hi[k - 1];
            }
            lo[k] = a;
            hi[k] = b;
            nrun++;
        }
        for (int i = 0; i < nrun; ) {
            uint64_t a = lo[i], b = hi[i];
            int j = i + 1;
            while (j < nrun && lo[j] <= b) {
                if (hi[j] > b) b = hi[j];
                j++;
            }
            got = mmap((void *)a, (size_t)(b - a), PROT_READ | PROT_WRITE,
                       MAP_PRIVATE | MAP_ANONYMOUS | MAP_FIXED, -1, 0);
            if (got == MAP_FAILED)
                mr_die("%s: anonymous mapping for copied pages "
                       "(0x%llx bytes at 0x%llx): %m",
                       im->path, (unsigned long long)(b - a), (unsigned long long)a);
            i = j;
        }
    }

    /* Pass 2: read each segment's file bytes into place. The rest of vmsize
     * is already zero from the anonymous map. */
    for (int i = 0; i < im->nsegs; i++) {
        const mr_segment *s = &im->segs[i];
        uint64_t addr, filepart, off;
        ssize_t n;
        if (strcmp(s->name, "__PAGEZERO") == 0) continue;
        if (s->vmsize == 0) continue;
        addr = s->vmaddr + (uint64_t)im->slide;
        filepart = s->filesize;
        if (filepart > s->vmsize) filepart = s->vmsize;
        if (filepart == 0) continue;
        off = im->slice_off + s->fileoff;
        n = pread(im->fd, (void *)addr, filepart, (off_t)off);
        if (n < 0 || (uint64_t)n != filepart)
            mr_die("%s: short read of copied segment %s (wanted 0x%llx at file 0x%llx)",
                   im->path, s->name, (unsigned long long)filepart, (unsigned long long)off);
    }

    apply_copy_page_prots(im, 0);

    for (int i = 0; i < im->nsegs; i++) {
        const mr_segment *s = &im->segs[i];
        uint64_t addr;
        int prot;
        if (strcmp(s->name, "__PAGEZERO") == 0) continue;
        if (s->vmsize == 0) continue;
        addr = s->vmaddr + (uint64_t)im->slide;
        prot = prot_of(s->initprot);
        mr_log("  %-12s 0x%012llx+0x%llx prot=%c%c%c%s [copy]", s->name,
               (unsigned long long)addr, (unsigned long long)s->vmsize,
               (prot & PROT_READ) ? 'r' : '-', (prot & PROT_WRITE) ? 'w' : '-',
               (prot & PROT_EXEC) ? 'x' : '-',
               (s->flags & SG_READ_ONLY) ? " SG_READ_ONLY" : "");
    }
}

void mr_map_image(mr_image *im)
{
    uint64_t page = MR.page.v;
    uint64_t lo = UINT64_MAX, hi = 0, span;
    void *want, *got;

    for (int i = 0; i < im->nsegs; i++) {
        const mr_segment *s = &im->segs[i];
        if (strcmp(s->name, "__PAGEZERO") == 0) continue;
        if (s->vmsize == 0) continue;
        check_segment_file_bytes(im, s);
        if (s->vmaddr < lo) lo = s->vmaddr;
        if (s->vmaddr + s->vmsize > hi) hi = s->vmaddr + s->vmsize;
    }
    if (lo == UINT64_MAX) mr_die("%s: no mappable segments", im->path);
    if (lo != im->preferred_base)
        mr_die("%s: lowest mapped segment is at 0x%llx but __TEXT.vmaddr is 0x%llx; "
               "the loader assumes the mach header is the lowest mapped byte",
               im->path, (unsigned long long)lo, (unsigned long long)im->preferred_base);

    span = mr_round_up(hi - lo, page);

    /* One reservation for the whole image: makes "did the preferred base
     * collide" a single question and keeps inter-segment gaps unmapped. */
    /* MACHORUN_NO_PREFERRED_BASE exists to exercise the slid path. An
     * executable normally lands exactly at its preferred base, so slide == 0
     * and a whole class of "used the preferred base where the load base was
     * meant" bugs would never fire. Setting it forces every image to slide. */
    want = (im->filetype == MH_EXECUTE && !getenv("MACHORUN_NO_PREFERRED_BASE"))
               ? (void *)lo : NULL;
    got = MAP_FAILED;
    /* The preferred base is honoured only if it is ALSO addressable through
     * Swift's isa mask. An executable linked above 2^47 would otherwise load
     * happily and then fault the first time a class of its own was touched. */
    if (want && (uint64_t)want <= MR_ISA_LIMIT && span <= MR_ISA_LIMIT - (uint64_t)want) {
        got = mmap(want, span, PROT_NONE,
                   MAP_PRIVATE | MAP_ANONYMOUS | MAP_NORESERVE | MAP_FIXED_NOREPLACE, -1, 0);
        if (got != MAP_FAILED && got != want) { munmap(got, span); got = MAP_FAILED; }
    }
    if (got == MAP_FAILED) got = reserve_in_arena(span);
    if (got == MAP_FAILED)
        mr_die("%s: cannot reserve 0x%llx bytes below 2^47. Every image has to fit "
               "there because libswiftCore has the 47-bit isa mask compiled into it "
               "(see the placement note in src/map.c); the arena [0x%llx, 0x%llx) is "
               "full or too fragmented: %m",
               im->path, (unsigned long long)span,
               (unsigned long long)MR_ARENA_BASE, (unsigned long long)MR_ISA_LIMIT);

    im->load_base = (uint64_t)got;
    im->slide = (int64_t)im->load_base - (int64_t)lo;
    im->span_lo = im->load_base;
    im->span_hi = im->load_base + span;

    if (image_needs_copy(im, page)) {
        map_image_by_copy(im);
        return;
    }

    for (int i = 0; i < im->nsegs; i++) {
        const mr_segment *s = &im->segs[i];
        uint64_t addr, filepart;
        int prot;

        if (strcmp(s->name, "__PAGEZERO") == 0) continue;
        if (s->vmsize == 0) continue;

        addr = s->vmaddr + (uint64_t)im->slide;
        prot = prot_of(s->initprot);
        if (prot == 0) prot = PROT_NONE;

        if ((addr & (page - 1)) != 0)
            mr_die("%s: segment %s maps to 0x%llx which is not page (%llu) aligned",
                   im->path, s->name, (unsigned long long)addr, (unsigned long long)page);

        filepart = s->filesize;
        if (filepart > s->vmsize) filepart = s->vmsize;

        if (filepart > 0) {
            uint64_t off = im->slice_off + s->fileoff;
            if ((off & (page - 1)) == 0) {
                got = mmap((void *)addr, filepart, prot, MAP_PRIVATE | MAP_FIXED, im->fd, (off_t)off);
                if (got == MAP_FAILED)
                    mr_die("%s: mmap of segment %s (0x%llx bytes at 0x%llx from file offset 0x%llx): %m",
                           im->path, s->name, (unsigned long long)filepart,
                           (unsigned long long)addr, (unsigned long long)off);
            } else {
                /* Only reachable for a fat slice whose offset is not page
                 * aligned. Copy the bytes in rather than mis-mapping. */
                ssize_t n;
                got = mmap((void *)addr, filepart, PROT_READ | PROT_WRITE,
                           MAP_PRIVATE | MAP_ANONYMOUS | MAP_FIXED, -1, 0);
                if (got == MAP_FAILED)
                    mr_die("%s: anonymous mapping for unaligned segment %s: %m", im->path, s->name);
                n = pread(im->fd, got, filepart, (off_t)off);
                if (n < 0 || (uint64_t)n != filepart)
                    mr_die("%s: short read of segment %s", im->path, s->name);
                if (mprotect(got, filepart, prot) != 0)
                    mr_die("%s: mprotect of copied segment %s: %m", im->path, s->name);
            }
        }

        {
            uint64_t mapped = mr_round_up(filepart, page);
            if (s->vmsize > mapped) {
                got = mmap((void *)(addr + mapped), s->vmsize - mapped, prot,
                           MAP_PRIVATE | MAP_ANONYMOUS | MAP_FIXED, -1, 0);
                if (got == MAP_FAILED)
                    mr_die("%s: anonymous tail of segment %s (0x%llx bytes at 0x%llx): %m",
                           im->path, s->name, (unsigned long long)(s->vmsize - mapped),
                           (unsigned long long)(addr + mapped));
            }
        }

        mr_log("  %-12s 0x%012llx+0x%llx prot=%c%c%c%s", s->name,
               (unsigned long long)addr, (unsigned long long)s->vmsize,
               (prot & PROT_READ) ? 'r' : '-', (prot & PROT_WRITE) ? 'w' : '-',
               (prot & PROT_EXEC) ? 'x' : '-',
               (s->flags & SG_READ_ONLY) ? " SG_READ_ONLY" : "");
    }
}

/* The inverse of the SG_READ_ONLY protection below, for the one caller that is
 * allowed to ask: libobjc, through dyld's makeImageMutable block. Rounds the
 * same way mr_protect_readonly_segments does so the two agree on page bounds. */
int mr_mprotect_rw(void *addr, uint64_t size)
{
    uintptr_t base = (uintptr_t)mr_round_dn((uint64_t)(uintptr_t)addr, MR.page.v);
    uint64_t  len  = mr_round_up(size + ((uintptr_t)addr - base), MR.page.v);
    return mprotect((void *)base, (size_t)len, PROT_READ | PROT_WRITE);
}

void mr_protect_readonly_segments(mr_image *im)
{
    if (im->mapped_by_copy) {
        apply_copy_page_prots(im, 1);
        mr_log("  %s: copied-image page prots reapplied after fixups "
               "(SG_READ_ONLY -> r, union on shared pages)", im->path);
        return;
    }
    for (int i = 0; i < im->nsegs; i++) {
        const mr_segment *s = &im->segs[i];
        uint64_t addr;
        if (!(s->flags & SG_READ_ONLY) || s->vmsize == 0) continue;
        addr = s->vmaddr + (uint64_t)im->slide;
        if (mprotect((void *)addr, mr_round_up(s->vmsize, MR.page.v), PROT_READ) != 0)
            mr_die("%s: cannot mprotect SG_READ_ONLY segment %s to r--: %m", im->path, s->name);
        mr_log("  %s: %s now r-- (SG_READ_ONLY)", im->path, s->name);
    }
}
