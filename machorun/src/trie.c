/* trie.c -- the export trie, slurped once per image into a flat table.
 *
 * Format (measured, docs/MACHO_NOTES.md §6):
 *   uleb terminal_size
 *     if terminal_size: uleb flags, then payload by flags
 *   uint8 child_count
 *   child_count x { cstring edge; uleb child_offset_from_trie_start }
 * Children start terminal_size bytes after the terminal_size uleb, so the
 * payload is skipped by length and not by parsing it -- which is what lets a
 * future flag we do not understand still parse structurally.
 */
#define _GNU_SOURCE
#include "machorun.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
    mr_image *im;
    const uint8_t *start, *end;
    mr_export *out;
    size_t n, cap;
    char prefix[512];
} trie_walk;

static void emit(trie_walk *w, size_t plen, uint32_t flags, uint64_t offset)
{
    mr_export *e;
    if (w->n == w->cap) {
        w->cap = w->cap ? w->cap * 2 : 64;
        w->out = realloc(w->out, w->cap * sizeof(*w->out));
        if (!w->out) mr_die("out of memory growing the export table");
    }
    e = &w->out[w->n++];
    e->name = mr_xstrdup(w->prefix);
    (void)plen;
    e->offset = offset;
    e->flags = flags;
}

static void walk(trie_walk *w, uint64_t node_off, size_t plen, int depth)
{
    const uint8_t *p, *children;
    uint64_t term_size;
    uint8_t nchild;

    if (depth > 128) mr_die("%s: export trie is more than 128 levels deep", w->im->path);
    if (node_off >= (uint64_t)(w->end - w->start))
        mr_die("%s: export trie child offset 0x%llx is outside the trie blob",
               w->im->path, (unsigned long long)node_off);

    p = w->start + node_off;
    term_size = mr_uleb(&p, w->end);
    children = p + term_size;
    if (children > w->end) mr_die("%s: export trie terminal payload runs past the blob", w->im->path);

    if (term_size > 0) {
        const uint8_t *t = p;
        uint32_t flags = (uint32_t)mr_uleb(&t, w->end);
        uint64_t value = 0;
        if (flags & EXPORT_SYMBOL_FLAGS_REEXPORT) {
            /* uleb ordinal, then an optional renamed symbol. Chasing it needs
             * the dylib graph; our own libSystem is deliberately one flat
             * dylib so this does not arise in milestone 1. */
            mr_unimplemented("EXPORT_SYMBOL_FLAGS_REEXPORT",
                             "%s: export '%s' is a re-export (flags 0x%x). Re-export chasing "
                             "is not implemented; ship the symbol in the dylib that names it.",
                             w->im->path, w->prefix, flags);
        } else if (flags & EXPORT_SYMBOL_FLAGS_STUB_AND_RESOLVER) {
            mr_unimplemented("EXPORT_SYMBOL_FLAGS_STUB_AND_RESOLVER",
                             "%s: export '%s' has a resolver function (flags 0x%x); "
                             "ifunc-style exports are not implemented.",
                             w->im->path, w->prefix, flags);
        } else {
            value = mr_uleb(&t, w->end);
        }
        emit(w, plen, flags, value);
    }

    if (children >= w->end) return;
    p = children;
    nchild = *p++;
    for (uint8_t i = 0; i < nchild; i++) {
        const char *edge = (const char *)p;
        size_t elen;
        uint64_t coff;
        while (p < w->end && *p) p++;
        if (p >= w->end) mr_die("%s: unterminated edge string in export trie", w->im->path);
        elen = (size_t)((const char *)p - edge);
        p++;
        coff = mr_uleb(&p, w->end);
        if (plen + elen + 1 >= sizeof(w->prefix))
            mr_die("%s: export name longer than %zu bytes", w->im->path, sizeof(w->prefix));
        memcpy(w->prefix + plen, edge, elen);
        w->prefix[plen + elen] = 0;
        walk(w, coff, plen + elen, depth + 1);
        w->prefix[plen] = 0;
    }
}

void mr_exports_parse(mr_image *im)
{
    trie_walk w;
    if (!im->trie_size) return;
    memset(&w, 0, sizeof(w));
    w.im = im;
    w.start = mr_file_at(im, im->trie_off, im->trie_size, "export trie");
    w.end = w.start + im->trie_size;
    walk(&w, 0, 0, 0);
    im->exports = w.out;
    im->nexports = w.n;
}

int mr_exports_lookup(const mr_image *im, const char *name, uint64_t *addr_out)
{
    for (size_t i = 0; i < im->nexports; i++) {
        const mr_export *e = &im->exports[i];
        if (strcmp(e->name, name) != 0) continue;
        if ((e->flags & EXPORT_SYMBOL_FLAGS_KIND_MASK) == EXPORT_SYMBOL_FLAGS_KIND_ABSOLUTE)
            *addr_out = e->offset;
        else
            *addr_out = im->load_base + e->offset;
        return 1;
    }
    return 0;
}
