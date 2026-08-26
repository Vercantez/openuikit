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
 */
#define _GNU_SOURCE
#include "machorun.h"

#include <errno.h>
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
 * WHERE IMAGES GO, and why it is not "wherever mmap feels like".
 *
 * Apple's arm64 runtimes do not treat an isa field as a whole pointer. The
 * Swift standard library has the 47-bit mask INLINED into compiled code --
 * `and x8, x8, #0x7ffffffffff8` appears at 20+ sites in the libswiftCore we
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
 * `ulimit -s unlimited` also "fixes" this -- it flips Linux to the legacy
 * bottom-up mmap layout process-wide -- but that is a property of how machorun
 * was invoked rather than of machorun, it stops applying the moment something
 * re-execs, and it moves every unrelated allocation too. A policy here is
 * checkable; an ambient rlimit is not.
 * ===================================================================== */

/* The mask keeps bits 3..46, so an image is addressable iff its last byte is
 * below 2^47. tests/bin/19_isa_mask asserts exactly that, for every image. */
#define MR_ISA_LIMIT   0x800000000000ull

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

void mr_map_image(mr_image *im)
{
    uint64_t page = MR.page.v;
    uint64_t lo = UINT64_MAX, hi = 0, span;
    void *want, *got;

    for (int i = 0; i < im->nsegs; i++) {
        const mr_segment *s = &im->segs[i];
        if (strcmp(s->name, "__PAGEZERO") == 0) continue;
        if (s->vmsize == 0) continue;
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
