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
    if (want) {
        got = mmap(want, span, PROT_NONE,
                   MAP_PRIVATE | MAP_ANONYMOUS | MAP_NORESERVE | MAP_FIXED_NOREPLACE, -1, 0);
        if (got == MAP_FAILED || got != want) {
            if (got != MAP_FAILED) munmap(got, span);
            got = mmap(NULL, span, PROT_NONE, MAP_PRIVATE | MAP_ANONYMOUS | MAP_NORESERVE, -1, 0);
        }
    } else {
        got = mmap(NULL, span, PROT_NONE, MAP_PRIVATE | MAP_ANONYMOUS | MAP_NORESERVE, -1, 0);
    }
    if (got == MAP_FAILED) mr_die("%s: cannot reserve 0x%llx bytes of address space: %m",
                                  im->path, (unsigned long long)span);

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
