/* resolve.c -- two-level symbol resolution across loaded Mach-O images, with
 * one deliberate escape hatch: images that came out of our own darwin/ tree
 * may also resolve against the host ELF process (glibc + this loader) via
 * dlsym. That is how libSystem.B.dylib -- a Mach-O we build on Linux -- calls
 * glibc: its undefined symbols are flat-lookup binds that land here.
 *
 * Guest binaries never get that fallback. If a fixture's import is missing,
 * that is a real gap in our libSystem and it must be reported, not papered
 * over with a host symbol that happens to share a name.
 */
#define _GNU_SOURCE
#include "machorun.h"

#include <dlfcn.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

static uint64_t host_lookup(const char *name)
{
    /* Two spellings reach the host.
     *
     * _glibc_<x> is the explicit boundary our own dylibs use: libSystem
     * declares glibc's puts as `_glibc_puts` precisely so that its own
     * exported `_puts` forwarder is not its own callee. That prefix can never
     * collide with a Darwin symbol, so the mapping is unambiguous.
     *
     * Otherwise Mach-O's leading underscore is stripped -- exactly one:
     * _printf -> printf, ___cxa_atexit -> __cxa_atexit. This is how our
     * dylibs reach loader-provided entry points. */
    if (strncmp(name, "_glibc_", 7) == 0)
        return (uint64_t)dlsym(RTLD_DEFAULT, name + 7);
    if (name[0] != '_') return 0;
    return (uint64_t)dlsym(RTLD_DEFAULT, name + 1);
}

__attribute__((noreturn)) void mr_stub_binder_trap(void);
__attribute__((noreturn)) void mr_stub_binder_trap(void)
{
    mr_die("dyld_stub_binder was entered -- this is a loader bug. machorun binds the "
           "classic lazy-bind stream eagerly at load time, so no __stub_helper entry "
           "should ever reach the binder. See docs/PLAN.md §I.6.");
}

static int lookup_in(mr_image *im, const char *name, uint64_t *out, int depth)
{
    if (!im) return 0;
    if (mr_exports_lookup(im, name, out)) return 1;
    if (depth < 4) {
        for (int i = 0; i < im->ndeps; i++)
            if (im->deps[i].reexport && im->deps[i].img &&
                lookup_in(im->deps[i].img, name, out, depth + 1))
                return 1;
    }
    return 0;
}

void mr_resolve_report(mr_image *from, const mr_image *in, const char *name)
{
    int shown = 0;
    fprintf(stderr, "machorun: undefined symbol '%s'\n", name);
    fprintf(stderr, "  wanted by:  %s\n", from->path);
    if (in) fprintf(stderr, "  looked in:  %s\n", in->path);
    else    fprintf(stderr, "  looked in:  every loaded image (flat lookup)\n");
    if (in && in->nexports) {
        size_t pre = strlen(name);
        if (pre > 4) pre = 4;
        for (size_t i = 0; i < in->nexports && shown < 5; i++) {
            if (strncmp(in->exports[i].name, name, pre) != 0) continue;
            if (!shown) fprintf(stderr, "  near names in that image:\n");
            fprintf(stderr, "    %s\n", in->exports[i].name);
            shown++;
        }
    }
    if (in && in->is_runtime)
        fprintf(stderr,
                "  %s is one of our own dylibs, so this is a gap in our Darwin\n"
                "  userland: add %s to it (see docs/UNIMPLEMENTED.md).\n",
                in->path, name);
}

uint64_t mr_resolve_symbol(mr_image *from, int lib_ordinal, const char *name,
                           int weak_import, int *found)
{
    uint64_t addr = 0;
    mr_image *target = NULL;
    int flat = 0, weak_lookup = 0;

    *found = 0;

    if (lib_ordinal > 0) {
        if (lib_ordinal > from->ndeps)
            mr_die("%s: bind of '%s' names library ordinal %d but the image has only %d "
                   "LC_LOAD_DYLIB commands", from->path, name, lib_ordinal, from->ndeps);
        target = from->deps[lib_ordinal - 1].img;
        if (!target) {           /* missing weak dylib */
            *found = 0;
            return 0;
        }
    } else if (lib_ordinal == BIND_SPECIAL_DYLIB_SELF) {
        target = from;
    } else if (lib_ordinal == BIND_SPECIAL_DYLIB_MAIN_EXECUTABLE) {
        target = MR.main_image;
    } else if (lib_ordinal == BIND_SPECIAL_DYLIB_FLAT_LOOKUP) {
        flat = 1;
    } else if (lib_ordinal == BIND_SPECIAL_DYLIB_WEAK_LOOKUP) {
        flat = 1; weak_lookup = 1;
    } else {
        mr_die("%s: bind of '%s' uses unknown special library ordinal %d",
               from->path, name, lib_ordinal);
    }

    if (flat) {
        /* Flat lookup searches every image in load order -- which includes the
         * main executable, and that is what makes a dylib's reverse import of
         * an exe symbol (fixture 07) resolve. */
        for (int i = 0; i < MR.nimages && !*found; i++)
            if (mr_exports_lookup(MR.images[i], name, &addr)) *found = 1;
    } else {
        *found = lookup_in(target, name, &addr, 0);
    }

    if (!*found && strcmp(name, "dyld_stub_binder") == 0) {
        /* The classic bind stream demands this symbol even though we bind the
         * lazy stream eagerly and nothing should ever reach the binder. Bind
         * it to a trap so that "ever" is checkable rather than assumed. */
        *found = 1;
        return (uint64_t)(uintptr_t)mr_stub_binder_trap;
    }

    if (!*found && from->is_runtime) {
        addr = host_lookup(name);
        if (addr) {
            *found = 1;
            mr_log("host: %s -> %s+0x0", name, "glibc/loader");
        }
    }

    if (!*found) {
        if (weak_import || weak_lookup) return 0;   /* legitimately NULL */
        mr_resolve_report(from, flat ? NULL : target, name);
        fflush(stderr);
        _exit(73);
    }
    return addr;
}
