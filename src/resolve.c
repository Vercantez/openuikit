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
#include <stdlib.h>

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

/* One line per distinct symbol, however many images bind it. */
static void report_weak_null(const mr_image *from, const char *name)
{
    static const char *seen[64];
    static int nseen;

    for (int i = 0; i < nseen; i++)
        if (strcmp(seen[i], name) == 0) return;
    if (nseen < (int)(sizeof(seen) / sizeof(seen[0]))) seen[nseen++] = name;

    fprintf(stderr,
            "machorun: WEAK-DEFINITION GAP: nothing in the process defines '%s',\n"
            "  which %s binds as a coalesced weak definition. It is now NULL, and a\n"
            "  call through it will branch to address 0. This is a missing definition\n"
            "  in our runtime libraries, not an optional symbol -- see\n"
            "  docs/UNIMPLEMENTED.md#weak-definition-gaps.\n",
            name, from->path);
}

__attribute__((noreturn)) void mr_stub_binder_trap(void);
__attribute__((noreturn)) void mr_stub_binder_trap(void)
{
    mr_die("dyld_stub_binder was entered -- this is a loader bug. machorun binds the "
           "classic lazy-bind stream eagerly at load time, so no __stub_helper entry "
           "should ever reach the binder. See docs/PLAN.md §I.6.");
}

/* -delay_init, which ld64.lld-18 does not implement.
 *
 * objc4 refers to swift_retain/swift_release so a Swift-stable object can be
 * retained without a message send. On Darwin those references are -delay_init:
 * they resolve on first use, and only if libswiftCore is in the process. Our
 * ld64.lld has no such flag, so they come out as ordinary flat-lookup binds
 * that have to resolve at load time even when there is no Swift runtime.
 *
 * darwin/src/objcsupport.c used to define them, which put a diagnostic abort
 * in libSystem.B.dylib -- an image that loads BEFORE libswiftCore.dylib, so
 * the flat lookup (first definition in load order wins) handed objc4 the abort
 * instead of the real implementation. Defining them here fixes that by
 * construction: host_lookup runs only after every loaded image has been
 * searched and come up empty, so a real libswiftCore always wins no matter
 * what order the guest linked its dylibs in, and a guest with no Swift runtime
 * still gets a sentence rather than a jump through NULL.
 *
 * They are reached through host_lookup's underscore-stripping path, so the ELF
 * names must be exactly these. darwin/loader-exports.txt lists them #internal:
 * they are a seam between the loader and libobjc, and must NOT appear in
 * libSystem.B.tbd, or a guest could link against a promise that only the
 * loader can keep. */
#define SWIFT_ABSENT(fn, verb)                                                 \
    __attribute__((noreturn)) void fn(void *o);                                \
    __attribute__((noreturn)) void fn(void *o)                                 \
    {                                                                          \
        (void)o;                                                               \
        mr_die(#fn ": objc4's fast-path refcounting tried to " verb " a "       \
               "Swift-stable object, but no libswiftCore is loaded. On Darwin " \
               "this reference is -delay_init and would have brought the Swift "\
               "runtime in; machorun has no delay-init, so link the guest "     \
               "against libswiftCore -- in any order -- or do not create Swift "\
               "objects. See docs/UNIMPLEMENTED.md#swift-interop.");            \
    }
SWIFT_ABSENT(swift_retain,  "retain")
SWIFT_ABSENT(swift_release, "release")

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
    /* The one symbol whose obvious fix is the wrong one. A two-level bind of
     * swift_retain/swift_release against libSystem can only come from a
     * libSystem.B.tbd that still ADVERTISES them -- a stub staged before they
     * were removed from libSystem (they live in the loader now; see
     * docs/UNIMPLEMENTED.md#swift-interop). Following the generic advice below
     * and "adding the symbol back to libSystem" would resolve this error and
     * silently restore the bug that removal fixed: libSystem loads before
     * libswiftCore, so its definition wins the flat lookup and every Swift
     * object release reaches a diagnostic abort instead of the real runtime.
     * Say so here, because the generic message points the wrong way. */
    if (in && in->is_runtime &&
        (strcmp(name, "_swift_release") == 0 || strcmp(name, "_swift_retain") == 0)) {
        fprintf(stderr,
                "  This is a STALE SDK, not a missing symbol. Do NOT add %s to\n"
                "  libSystem: it lives in the loader precisely so a real libswiftCore\n"
                "  wins the lookup in any link order. Re-stage your sysroot's\n"
                "  usr/lib/*.tbd from machorun's sdk/usr/lib -- a stub built before\n"
                "  b9f0e23 still advertises it, so the linker recorded a two-level\n"
                "  bind to libSystem that nothing can satisfy.\n", name);
        return;
    }
    /* "Add it to that dylib" is the right fix only if that dylib is really the
     * symbol's owner, and a TWO-LEVEL bind is not evidence that it is: the
     * ordinal was chosen by the linker from that dylib's .tbd, so a stale stub
     * points here just as convincingly as a genuine gap. Getting that backwards
     * is what the swift_retain/swift_release case above is -- adding those to
     * libSystem clears the error and restores the bug their removal fixed.
     * That pair is special-cased because its remedy is actively harmful; the
     * general shape is not, so name it rather than enumerate more symbols. */
    if (in && in->is_runtime)
        fprintf(stderr,
                "  That is one of our own dylibs, so either it is missing this symbol\n"
                "  or the stub that promised it is stale. The linker chose that\n"
                "  library from its .tbd, so check which it is before adding anything:\n"
                "      nm -g %s | grep %s\n"
                "  Exports it: your sysroot's .tbd disagrees with the dylib and needs\n"
                "  re-staging from machorun's sdk/usr/lib.\n"
                "  Does not:   a real gap (docs/UNIMPLEMENTED.md) -- but check that no\n"
                "  other loaded image owns it first, because anything defined here\n"
                "  loads early and wins every flat lookup.\n",
                in->path, name);
}

/* dlsym(3) over GUEST images.
 *
 * Darwin's dlsym takes the C name and prepends the underscore itself, so
 * dlsym(RTLD_DEFAULT, "objc_msgSend") looks up "_objc_msgSend". Only
 * RTLD_DEFAULT is served here: it is the same flat search, in the same load
 * order, that BIND_SPECIAL_DYLIB_FLAT_LOOKUP gets below.
 *
 * It deliberately does NOT fall back to the host. A guest asking for a symbol
 * we do not have must get NULL -- as it would on a Mac missing that library --
 * rather than a same-named glibc symbol. */
/* The path of the MAIN GUEST IMAGE, for _NSGetExecutablePath.
 *
 * This has to come from the loader and cannot be synthesised in libSystem,
 * which is the whole reason it is exported. The obvious Linux implementation
 * of _NSGetExecutablePath is readlink("/proc/self/exe") -- and under machorun
 * the process genuinely IS machorun, so that returns the LOADER's path. The
 * Mach-O is something we mapped, not something the kernel exec'd.
 *
 * CoreFoundation uses the answer to locate the main bundle. So /proc/self/exe
 * would return a real, existing, readable path and point CF at the wrong file,
 * with every bundle-relative resource lookup then failing a long way from the
 * cause. A plausible wrong answer, in a place where the wrong answer is a
 * valid path. */
const char *mr_guest_executable_path(void)
{
    static char resolved[4096];
    static int  tried;

    if (!MR.main_image) return NULL;
    if (tried) return resolved[0] ? resolved : MR.main_image->path;
    tried = 1;

    /* RESOLVED, because dyld hands the guest an absolute path and we are given
     * whatever was on the command line -- the harness invokes "./35_execpath"
     * from tests/bin, so the unresolved answer is "./35_execpath". That is a
     * real path and the wrong shape: CoreFoundation takes the DIRECTORY of this
     * to find the main bundle, and a relative one resolves against whatever the
     * process's cwd happens to be later rather than against the executable.
     *
     * Falls back to the raw path if realpath fails, because a path we cannot
     * resolve is still better than none -- and the caller will find out. */
    if (!realpath(MR.main_image->path, resolved))
        resolved[0] = 0;
    return resolved[0] ? resolved : MR.main_image->path;
}

void *mr_dlsym_default(const char *name)
{
    char buf[512];
    uint64_t addr = 0;
    size_t n = strlen(name);

    if (n + 2 > sizeof buf)
        mr_die("dlsym: symbol name is %zu bytes, longer than machorun's %zu-byte buffer",
               n, sizeof buf - 2);
    buf[0] = '_';
    memcpy(buf + 1, name, n + 1);

    for (int i = 0; i < MR.nimages; i++)
        if (mr_exports_lookup(MR.images[i], buf, &addr))
            return (void *)(uintptr_t)addr;
    return NULL;
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

    if (!*found && weak_lookup) {
        /* A weak-def-coalesce bind is NOT an optional symbol. It says "this
         * symbol has one definition shared across the program, and the linker
         * does not care which image supplies it" -- which is how C++ inline
         * functions, template instantiations and the REPLACEABLE operator
         * new/delete are bound. Real dyld always finds one, because libc++
         * defines them. Here a miss means our libc++ subset is short a
         * definition, and binding it to NULL turns that into a branch through
         * zero at some unpredictable later moment.
         *
         * This was silent until 2026-08-27, and it hid a real one: Apple's
         * shipped libswiftCore imports operator new/delete in Apple's TYPED
         * form (__ZnwmSt19__type_descriptor_t, the extra argument being a
         * type descriptor for their typed-memory-operations work). Our libc++
         * defines only the untyped and sized forms, so both bound to NULL with
         * no diagnostic anywhere. Say it out loud instead. */
        report_weak_null(from, name);
        return 0;
    }

    if (!*found) {
        if (weak_import) return 0;   /* legitimately absent: optional at run time */
        mr_resolve_report(from, flat ? NULL : target, name);
        fflush(stderr);
        _exit(73);
    }
    return addr;
}
