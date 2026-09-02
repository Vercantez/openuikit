/* fixups_classic.c -- LC_DYLD_INFO_ONLY opcode streams.
 *
 * What a deployment target <= macOS 11 (or -Wl,-no_fixup_chains) produces, and
 * what ld64.lld emits for the dylibs we build ourselves. Three interpreters
 * over one "write a pointer here" primitive.
 *
 * Lazy binding is bound EAGERLY: the lazy stream names exactly the set of
 * (address, symbol) pairs that lazy resolution would eventually produce, so
 * walking it at load time gives the same memory state without a
 * register-preserving trampoline. dyld_stub_binder is still bound, because the
 * bind stream asks for it -- to a function in our libSystem that aborts with a
 * loud message. If that message ever appears, this assumption was wrong.
 */
#define _GNU_SOURCE
#include "machorun.h"

#include <stdio.h>
#include <string.h>

static uint64_t seg_addr(mr_image *im, int seg, uint64_t off, const char *what)
{
    if (seg < 0 || seg >= im->nsegs)
        mr_die("%s: %s names segment index %d but the image has %d segments",
               im->path, what, seg, im->nsegs);
    if (off > im->segs[seg].vmsize)
        mr_die("%s: %s offset 0x%llx is past the end of segment %s (0x%llx)",
               im->path, what, (unsigned long long)off, im->segs[seg].name,
               (unsigned long long)im->segs[seg].vmsize);
    return im->segs[seg].vmaddr + (uint64_t)im->slide + off;
}

/* ------------------------------------------------------------- rebase */

static void rebase_stream(mr_image *im, const uint8_t *p, const uint8_t *end)
{
    int type = REBASE_TYPE_POINTER, seg = -1;
    uint64_t off = 0;

    while (p < end) {
        uint8_t byte = *p++;
        uint8_t op = byte & REBASE_OPCODE_MASK, imm = byte & REBASE_IMMEDIATE_MASK;
        uint64_t count = 0, skip = 0;

        switch (op) {
        case REBASE_OPCODE_DONE:
            return;
        case REBASE_OPCODE_SET_TYPE_IMM:
            type = imm;
            break;
        case REBASE_OPCODE_SET_SEGMENT_AND_OFFSET_ULEB:
            seg = imm; off = mr_uleb(&p, end);
            break;
        case REBASE_OPCODE_ADD_ADDR_ULEB:
            off += mr_uleb(&p, end);
            break;
        case REBASE_OPCODE_ADD_ADDR_IMM_SCALED:
            off += (uint64_t)imm * 8;
            break;
        case REBASE_OPCODE_DO_REBASE_IMM_TIMES:
            count = imm; skip = 0;
            break;
        case REBASE_OPCODE_DO_REBASE_ULEB_TIMES:
            count = mr_uleb(&p, end); skip = 0;
            break;
        case REBASE_OPCODE_DO_REBASE_ADD_ADDR_ULEB:
            count = 1; skip = mr_uleb(&p, end);
            break;
        case REBASE_OPCODE_DO_REBASE_ULEB_TIMES_SKIPPING_ULEB:
            count = mr_uleb(&p, end); skip = mr_uleb(&p, end);
            break;
        default:
            mr_die("%s: unknown rebase opcode 0x%02x", im->path, op);
        }

        if (!count) continue;
        if (type != REBASE_TYPE_POINTER)
            mr_unimplemented("classic rebase type",
                             "%s: REBASE_TYPE %d; only 1 (POINTER) is implemented "
                             "(2/3 are 32-bit text relocs, which arm64 does not emit)",
                             im->path, type);
        for (uint64_t i = 0; i < count; i++) {
            uint64_t *slot = (uint64_t *)seg_addr(im, seg, off, "rebase");
            *slot += (uint64_t)im->slide;
            off += 8 + skip;
        }
    }
}

/* --------------------------------------------------------------- bind */

typedef enum { BIND_REGULAR, BIND_WEAK, BIND_LAZY } bind_kind;

static void bind_stream(mr_image *im, const uint8_t *p, const uint8_t *end, bind_kind kind)
{
    int ordinal = kind == BIND_WEAK ? BIND_SPECIAL_DYLIB_FLAT_LOOKUP : 0;
    int type = BIND_TYPE_POINTER, seg = -1, weak_import = 0;
    const char *name = NULL;
    int64_t addend = 0;
    uint64_t off = 0;

    while (p < end) {
        uint8_t byte = *p++;
        uint8_t op = byte & BIND_OPCODE_MASK, imm = byte & BIND_IMMEDIATE_MASK;
        uint64_t count = 1, skip = 0;
        int do_bind = 0;

        switch (op) {
        case BIND_OPCODE_DONE:
            /* In the lazy stream every entry is its own program terminated by
             * DONE, so this is a separator, not the end of the stream. */
            if (kind == BIND_LAZY) { ordinal = 0; name = NULL; addend = 0; weak_import = 0; continue; }
            return;
        case BIND_OPCODE_SET_DYLIB_ORDINAL_IMM:
            ordinal = imm;
            break;
        case BIND_OPCODE_SET_DYLIB_ORDINAL_ULEB:
            ordinal = (int)mr_uleb(&p, end);
            break;
        case BIND_OPCODE_SET_DYLIB_SPECIAL_IMM:
            ordinal = imm ? (int)(int8_t)(0xF0 | imm) : 0;   /* sign-extend 4 bits */
            break;
        case BIND_OPCODE_SET_SYMBOL_TRAILING_FLAGS_IMM:
            weak_import = (imm & BIND_SYMBOL_FLAGS_WEAK_IMPORT) != 0;
            name = (const char *)p;
            while (p < end && *p) p++;
            if (p >= end) mr_die("%s: unterminated symbol name in bind stream", im->path);
            p++;
            break;
        case BIND_OPCODE_SET_TYPE_IMM:
            type = imm;
            break;
        case BIND_OPCODE_SET_ADDEND_SLEB:
            addend = mr_sleb(&p, end);
            break;
        case BIND_OPCODE_SET_SEGMENT_AND_OFFSET_ULEB:
            seg = imm; off = mr_uleb(&p, end);
            break;
        case BIND_OPCODE_ADD_ADDR_ULEB:
            off += mr_uleb(&p, end);
            break;
        case BIND_OPCODE_DO_BIND:
            do_bind = 1; count = 1; skip = 0;
            break;
        case BIND_OPCODE_DO_BIND_ADD_ADDR_ULEB:
            do_bind = 1; count = 1; skip = mr_uleb(&p, end);
            break;
        case BIND_OPCODE_DO_BIND_ADD_ADDR_IMM_SCALED:
            do_bind = 1; count = 1; skip = (uint64_t)imm * 8;
            break;
        case BIND_OPCODE_DO_BIND_ULEB_TIMES_SKIPPING_ULEB:
            do_bind = 1; count = mr_uleb(&p, end); skip = mr_uleb(&p, end);
            break;
        case BIND_OPCODE_THREADED:
            mr_unimplemented("BIND_OPCODE_THREADED",
                             "%s: threaded rebase/bind in a classic bind stream. That is the "
                             "iOS 12-era precursor to chained fixups; not implemented.", im->path);
        default:
            mr_die("%s: unknown bind opcode 0x%02x", im->path, op);
        }

        if (!do_bind) continue;
        if (type != BIND_TYPE_POINTER)
            mr_unimplemented("classic bind type",
                             "%s: BIND_TYPE %d for '%s'; only 1 (POINTER) is implemented",
                             im->path, type, name ? name : "?");
        if (!name) mr_die("%s: bind with no symbol name set", im->path);

        for (uint64_t i = 0; i < count; i++) {
            uint64_t *slot = (uint64_t *)seg_addr(im, seg, off, "bind");
            int found = 0;
            uint64_t v = mr_resolve_symbol(im, ordinal, name,
                                           weak_import || kind == BIND_WEAK, &found);
            if (found)
                *slot = v + (uint64_t)addend;
            else if (kind != BIND_WEAK)
                *slot = 0;      /* weak import, legitimately NULL */
            /* a weak bind with no definition leaves the image's own value */
            off += 8 + skip;
        }
    }
}

void mr_fixups_classic(mr_image *im)
{
    const struct dyld_info_command *d = im->dyld_info;
    const uint8_t *p;

    if (d->rebase_size) {
        p = mr_file_at(im, d->rebase_off, d->rebase_size, "rebase opcodes");
        rebase_stream(im, p, p + d->rebase_size);
    }
    if (d->bind_size) {
        p = mr_file_at(im, d->bind_off, d->bind_size, "bind opcodes");
        bind_stream(im, p, p + d->bind_size, BIND_REGULAR);
    }
    if (d->weak_bind_size) {
        p = mr_file_at(im, d->weak_bind_off, d->weak_bind_size, "weak bind opcodes");
        bind_stream(im, p, p + d->weak_bind_size, BIND_WEAK);
    }
    if (d->lazy_bind_size) {
        p = mr_file_at(im, d->lazy_bind_off, d->lazy_bind_size, "lazy bind opcodes");
        bind_stream(im, p, p + d->lazy_bind_size, BIND_LAZY);
    }
}

void mr_fixups_apply(mr_image *im)
{
    if (im->fixed_up) return;
    im->fixed_up = 1;

    if (im->chained_size && im->dyld_info)
        mr_die("%s: has both LC_DYLD_CHAINED_FIXUPS and LC_DYLD_INFO_ONLY", im->path);

    if (im->chained_size) {
        mr_log("%s: chained fixups", im->path);
        mr_fixups_chained(im);
    } else if (im->dyld_info) {
        mr_log("%s: classic LC_DYLD_INFO_ONLY fixups", im->path);
        mr_fixups_classic(im);
    } else {
        mr_log("%s: no fixup tables at all (static image)", im->path);
    }
}
