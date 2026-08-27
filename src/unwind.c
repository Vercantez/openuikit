/* unwind.c -- `_dyld_find_unwind_sections`, the loader's half of unwinding.
 *
 * WHY THIS IS THE LOADER'S JOB AND NOT A LIBRARY'S. On Darwin, unwinding is
 * split in two. libunwind knows how to DECODE Apple's compact
 * `__TEXT,__unwind_info` and how to run the DWARF fallback; it does not know
 * where those bytes are, because only the loader knows what is mapped and
 * where. So libunwind asks, once per frame, and the very first thing
 * `LocalAddressSpace::findUnwindSections()` does on `__APPLE__` is call this
 * function (`libunwind/src/AddressSpace.hpp`). On macOS libdyld.dylib answers;
 * here the loader IS dyld, so the answer has to come from `MR.images`.
 *
 * The contract is taken from libunwind's own source rather than from memory,
 * because getting a struct layout or an argument order wrong at a boundary
 * like this is the project's most expensive recurring bug -- see
 * docs/UNIMPLEMENTED.md#malloc-type-zones for the one that cost 46 scenes:
 *
 *     struct dyld_unwind_sections {
 *       const struct mach_header*   mh;
 *       const void*                 dwarf_section;
 *       uintptr_t                   dwarf_section_length;
 *       const void*                 compact_unwind_section;
 *       uintptr_t                   compact_unwind_section_length;
 *     };
 *     extern "C" bool _dyld_find_unwind_sections(void *, dyld_unwind_sections *);
 *
 * ADDRESSES, NOT FILE OFFSETS. Everything handed back is a LIVE address in
 * this process: the mach header where it actually landed, and each section's
 * `addr` plus the image's slide. A section header's `addr` is where the linker
 * WANTED it, and every image here is slid.
 *
 * `__eh_frame` IS USUALLY ABSENT AND THAT IS NORMAL, not a gap. Apple's linker
 * emits compact unwind for everything it can express in 32 bits and falls back
 * to DWARF only for the functions it cannot -- a compact entry then carries a
 * DWARF offset instead of an encoding. None of the fixture corpus has an
 * `__eh_frame` at all. So a zero dwarf_section is a fact about the binary, and
 * this returns true with zeros in that pair rather than treating it as
 * failure; libunwind checks the lengths itself.
 */
#define _GNU_SOURCE
#include "machorun.h"

#include <stdint.h>

struct dyld_unwind_sections {
    const void *mh;
    const void *dwarf_section;
    uintptr_t   dwarf_section_length;
    const void *compact_unwind_section;
    uintptr_t   compact_unwind_section_length;
};

static void fill_section(const mr_image *im, const char *name,
                         const void **base, uintptr_t *len)
{
    const struct section_64 *sec = mr_image_section(im, "__TEXT", name);

    *base = NULL;
    *len  = 0;
    if (!sec) return;
    *base = (const void *)(uintptr_t)(sec->addr + (uint64_t)im->slide);
    *len  = (uintptr_t)sec->size;
}

/* libunwind registers a callback so it can drop cached DWARF FDEs for an image
 * that goes away. Nothing here ever goes away: machorun's dlclose does not
 * unmap (docs/UNIMPLEMENTED.md), and images are never otherwise removed. So
 * registering is a no-op that is CORRECT rather than a stub -- the callback
 * would have nothing to report. Keeping the pointer would be the dishonest
 * version: it would suggest a notification that will never come.
 *
 * This is deliberately quiet. It runs on the first DWARF-fallback frame of
 * every unwind, so a diagnostic here would fire on ordinary success. */
void _dyld_register_func_for_remove_image(void (*fn)(const void *mh, intptr_t slide));
void _dyld_register_func_for_remove_image(void (*fn)(const void *mh, intptr_t slide))
{
    (void)fn;
}

int _dyld_find_unwind_sections(void *addr, struct dyld_unwind_sections *info);
int _dyld_find_unwind_sections(void *addr, struct dyld_unwind_sections *info)
{
    uint64_t a = (uint64_t)(uintptr_t)addr;

    if (!info) return 0;

    for (int i = 0; i < MR.nimages; i++) {
        mr_image *im = MR.images[i];

        if (a < im->span_lo || a >= im->span_hi) continue;

        info->mh = (const void *)(uintptr_t)im->load_base;
        fill_section(im, "__eh_frame",   &info->dwarf_section,
                                         &info->dwarf_section_length);
        fill_section(im, "__unwind_info", &info->compact_unwind_section,
                                          &info->compact_unwind_section_length);
        return 1;
    }

    /* Not in any mapped Mach-O: a stack address, a glibc address, the loader
     * itself. False is the right answer and libunwind treats it as "no info
     * here", which is how an unwind walks off the top of the guest's frames
     * into our ELF world and stops instead of decoding noise. */
    return 0;
}
