/* init.c -- initialiser discovery and ordering.
 *
 * Two section forms, and the modern one is NOT __mod_init_func:
 *   __TEXT,__init_offsets    S_INIT_FUNC_OFFSETS (0x16) -- uint32 offsets from
 *                            the mach header, read-only, no fixups. What a
 *                            deployment target >= macOS 12 emits.
 *   __DATA_CONST,__mod_init_func  S_MOD_INIT_FUNC_POINTERS (0x09) -- 8-byte
 *                            pointers, each rebased.
 * A loader that knows only the second runs zero constructors on a modern
 * binary and reports no error. Both are implemented here and "neither present"
 * is distinguished from "present and empty" in the log.
 *
 * Order is depth-first, dependencies before dependents, main executable last.
 * Initialisers are called with Darwin's signature (argc, argv, envp, apple).
 */
#define _GNU_SOURCE
#include "machorun.h"

#include <stdio.h>
#include <string.h>

typedef void (*mr_initialiser)(int, char **, char **, char **);

static void call_init(mr_image *im, uint64_t addr, const char *how, size_t idx)
{
    mr_initialiser fn = (mr_initialiser)addr;
    mr_log("%s: initialiser %s[%zu] at 0x%llx", im->path, how, idx, (unsigned long long)addr);
    fn(MR.argc, MR.argv, MR.envp, MR.apple);
}

/* Does this image carry ObjC metadata? If so it needs libobjc's map_images to
 * have run before any initialiser, and we do not have that yet -- say so
 * precisely rather than crashing inside a +load. */
void mr_objc_note_image(mr_image *im)
{
    for (int i = 0; i < im->nsegs; i++) {
        const mr_segment *s = &im->segs[i];
        for (uint32_t j = 0; j < s->nsects; j++) {
            if (strncmp(s->sects[j].sectname, "__objc_imageinfo", 16) != 0) continue;
            mr_unimplemented("ObjC image registration",
                             "%s carries __objc_imageinfo, so it needs libobjc's map_images / "
                             "load_images callbacks (registered through "
                             "_dyld_objc_register_callbacks) to run before its initialisers. "
                             "No Mach-O libobjc.A.dylib is shipped in darwin/ yet, so classes "
                             "would never be registered and objc_msgSend would fault.", im->path);
        }
    }
}

void mr_run_initialisers(mr_image *im)
{
    int found_any = 0;

    if (!im || im->init_state) return;    /* done, or a cycle */
    im->init_state = 1;

    for (int i = 0; i < im->ndeps; i++)
        mr_run_initialisers(im->deps[i].img);

    mr_objc_note_image(im);

    for (int i = 0; i < im->nsegs; i++) {
        const mr_segment *s = &im->segs[i];
        for (uint32_t j = 0; j < s->nsects; j++) {
            const struct section_64 *sec = &s->sects[j];
            uint64_t addr = sec->addr + (uint64_t)im->slide;

            if ((sec->flags & SECTION_TYPE) == S_INIT_FUNC_OFFSETS) {
                const uint32_t *offs = (const uint32_t *)addr;
                size_t n = (size_t)(sec->size / 4);
                found_any = 1;
                /* The linker has already sorted these by constructor priority:
                 * walk the array in order, never re-sort. */
                for (size_t k = 0; k < n; k++)
                    call_init(im, im->load_base + offs[k], "__init_offsets", k);
            } else if ((sec->flags & SECTION_TYPE) == S_MOD_INIT_FUNC_POINTERS) {
                const uint64_t *ptrs = (const uint64_t *)addr;
                size_t n = (size_t)(sec->size / 8);
                found_any = 1;
                for (size_t k = 0; k < n; k++)
                    call_init(im, ptrs[k], "__mod_init_func", k);
            } else if ((sec->flags & SECTION_TYPE) == S_MOD_TERM_FUNC_POINTERS) {
                mr_log("%s: has __mod_term_func; Darwin routes destructors through "
                       "__cxa_atexit instead, so it is not run", im->path);
            }
        }
    }

    if (!found_any)
        mr_log("%s: no initialiser section (neither __init_offsets nor __mod_init_func)",
               im->path);

    im->init_state = 2;
}
