/* fixups_chained.c -- LC_DYLD_CHAINED_FIXUPS.
 *
 * The format the modern toolchain emits (deployment target >= macOS 12), and
 * the one that abolishes lazy binding: a chained-fixups binary has no
 * __stub_helper, no __la_symbol_ptr, and never references dyld_stub_binder --
 * its __stubs load straight out of __got, which the chain walk binds eagerly.
 *
 * Note carefully: starts->page_size (0x4000, measured) is a property of these
 * TABLES, not of the kernel. sysconf(_SC_PAGESIZE) must never appear in this
 * file -- see PLAN §I.4 for why that is the easiest bug in the project.
 */
#define _GNU_SOURCE
#include "machorun.h"

#include <stdio.h>
#include <string.h>

typedef struct {
    uint64_t value;    /* resolved symbol address, 0 if legitimately absent */
    int64_t  addend;
    const char *name;
    int      found;
} chained_import;

static const char *ptr_format_name(uint16_t f)
{
    switch (f) {
    case DYLD_CHAINED_PTR_ARM64E:          return "DYLD_CHAINED_PTR_ARM64E";
    case DYLD_CHAINED_PTR_64:              return "DYLD_CHAINED_PTR_64";
    case DYLD_CHAINED_PTR_32:              return "DYLD_CHAINED_PTR_32";
    case DYLD_CHAINED_PTR_32_CACHE:        return "DYLD_CHAINED_PTR_32_CACHE";
    case DYLD_CHAINED_PTR_32_FIRMWARE:     return "DYLD_CHAINED_PTR_32_FIRMWARE";
    case DYLD_CHAINED_PTR_64_OFFSET:       return "DYLD_CHAINED_PTR_64_OFFSET";
    case DYLD_CHAINED_PTR_ARM64E_KERNEL:   return "DYLD_CHAINED_PTR_ARM64E_KERNEL";
    case DYLD_CHAINED_PTR_64_KERNEL_CACHE: return "DYLD_CHAINED_PTR_64_KERNEL_CACHE";
    case DYLD_CHAINED_PTR_ARM64E_USERLAND: return "DYLD_CHAINED_PTR_ARM64E_USERLAND";
    default:                               return "unknown";
    }
}

void mr_fixups_chained(mr_image *im)
{
    const struct dyld_chained_fixups_header *h;
    const struct dyld_chained_starts_in_image *si;
    const uint8_t *base;
    const char *symbols;
    chained_import *imports = NULL;
    uint32_t nimports;

    h = mr_file_at(im, im->chained_off, im->chained_size, "LC_DYLD_CHAINED_FIXUPS");
    base = (const uint8_t *)h;
    if (h->fixups_version != 0)
        mr_unimplemented("chained fixups version",
                         "%s: fixups_version %u, only 0 is known", im->path, h->fixups_version);
    if (h->symbols_format != 0)
        mr_unimplemented("chained fixups symbols_format",
                         "%s: symbols_format %u (zlib-compressed strings); only 0 "
                         "(uncompressed) is implemented", im->path, h->symbols_format);

    symbols = (const char *)(base + h->symbols_offset);
    nimports = h->imports_count;

    /* --- resolve every import once, up front -------------------------- */
    if (nimports) {
        const uint8_t *ip = base + h->imports_offset;
        imports = mr_xmalloc(nimports * sizeof(*imports));
        for (uint32_t i = 0; i < nimports; i++) {
            uint32_t lib_ordinal, weak, name_off;
            int64_t addend = 0;
            int ord;
            switch (h->imports_format) {
            case DYLD_CHAINED_IMPORT: {
                uint32_t v = ((const uint32_t *)ip)[i];
                lib_ordinal = v & 0xff;
                weak = (v >> 8) & 1;
                name_off = v >> 9;
                break;
            }
            case DYLD_CHAINED_IMPORT_ADDEND: {
                const uint32_t *v = (const uint32_t *)(ip + (size_t)i * 8);
                lib_ordinal = v[0] & 0xff;
                weak = (v[0] >> 8) & 1;
                name_off = v[0] >> 9;
                addend = (int32_t)v[1];
                break;
            }
            default:
                mr_unimplemented("chained imports_format",
                                 "%s: imports_format %u; only 1 (DYLD_CHAINED_IMPORT) and "
                                 "2 (_ADDEND) are implemented. Format 3 is _ADDEND64.",
                                 im->path, h->imports_format);
            }
            /* 8-bit ordinal, sign extended above 0xF0: 0xFF = main executable,
             * 0xFE = flat lookup, 0xFD = weak lookup. */
            ord = lib_ordinal > 0xF0 ? (int)(int8_t)(uint8_t)lib_ordinal : (int)lib_ordinal;
            imports[i].name = symbols + name_off;
            imports[i].addend = addend;
            imports[i].value = mr_resolve_symbol(im, ord, imports[i].name, (int)weak,
                                                 &imports[i].found);
        }
    }

    /* --- walk the chains ---------------------------------------------- */
    si = (const struct dyld_chained_starts_in_image *)(base + h->starts_offset);
    if ((int)si->seg_count > im->nsegs)
        mr_die("%s: chained fixups name %u segments but the image has %d",
               im->path, si->seg_count, im->nsegs);

    for (uint32_t s = 0; s < si->seg_count; s++) {
        const struct dyld_chained_starts_in_segment *ss;
        uint32_t off = si->seg_info_offset[s];
        macho_page_size_t mpage;

        if (off == 0) continue;   /* this segment has no fixups */
        ss = (const struct dyld_chained_starts_in_segment *)(base + h->starts_offset + off);
        mpage.v = ss->page_size;

        if (ss->pointer_format != DYLD_CHAINED_PTR_64_OFFSET &&
            ss->pointer_format != DYLD_CHAINED_PTR_64)
            mr_unimplemented("chained pointer_format",
                             "%s segment %s: pointer_format %u (%s). Only 6 "
                             "(DYLD_CHAINED_PTR_64_OFFSET) and 2 (DYLD_CHAINED_PTR_64) "
                             "are implemented.",
                             im->path, im->segs[s].name, ss->pointer_format,
                             ptr_format_name(ss->pointer_format));
        if (mpage.v == 0) mr_die("%s: chained starts page_size is 0", im->path);

        for (uint16_t pg = 0; pg < ss->page_count; pg++) {
            uint16_t start = ss->page_start[pg];
            uint64_t *p;

            if (start == DYLD_CHAINED_PTR_START_NONE) continue;
            if (start & DYLD_CHAINED_PTR_START_MULTI)
                mr_unimplemented("DYLD_CHAINED_PTR_START_MULTI",
                                 "%s segment %s page %u: multiple chain starts on one page. "
                                 "Measured impossible for 64-bit arm64 (max reach 4095*4 < 16384), "
                                 "so seeing it means the assumption was wrong.",
                                 im->path, im->segs[s].name, pg);

            p = (uint64_t *)(im->load_base + ss->segment_offset + (uint64_t)pg * mpage.v + start);
            for (;;) {
                uint64_t raw = *p;
                uint32_t next = (uint32_t)((raw >> 51) & 0xfff);

                if (raw >> 63) {                    /* bind */
                    uint32_t ordinal = (uint32_t)(raw & 0xffffff);
                    uint64_t addend8 = (raw >> 24) & 0xff;
                    if (ordinal >= nimports)
                        mr_die("%s: chained bind at %p names import %u but there are only %u",
                               im->path, (void *)p, ordinal, nimports);
                    *p = imports[ordinal].found
                             ? imports[ordinal].value + addend8 + (uint64_t)imports[ordinal].addend
                             : 0;
                } else {                            /* rebase */
                    uint64_t target = raw & 0xfffffffffull;         /* 36 bits */
                    uint64_t high8  = (raw >> 36) & 0xff;
                    uint64_t v = (ss->pointer_format == DYLD_CHAINED_PTR_64_OFFSET)
                                     ? im->load_base + target
                                     : target + (uint64_t)im->slide;
                    *p = v | (high8 << 56);
                }

                if (next == 0) break;
                p = (uint64_t *)((uint8_t *)p + next * 4);
            }
        }
    }
}
