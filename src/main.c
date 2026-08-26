/* main.c -- machorun: run a precompiled Mach-O binary on Linux/arm64.
 *
 *   machorun [-v] <mach-o> [args...]
 *
 * One process, two object formats. We are a Linux ELF linked at a fixed base;
 * the guest is a Mach-O mapped into our address space, calling our Mach-O
 * libSystem, which forwards to the same glibc we are linked against. No syscall
 * translation happens anywhere.
 *
 * The fixed base is not a stylistic choice -- it is what keeps glibc's heap,
 * and so every class object the runtimes allocate, inside the 47 bits
 * libswiftCore's isa mask can address. src/map.c has the account.
 */
#define _GNU_SOURCE
#include "machorun.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

extern char **environ;

typedef int (*mr_entry_fn)(int, char **, char **, char **);

static void usage(void)
{
    fputs("usage: machorun [-v|--verbose] [--info] <mach-o binary> [args...]\n"
          "  MACHORUN_VERBOSE=1   same as -v\n"
          "  MACHORUN_ROOT=<dir>  where the darwin/ tree lives (default: next to the loader)\n",
          stderr);
    _exit(64);
}

static char *loader_dir(void)
{
    char buf[4096];
    ssize_t n = readlink("/proc/self/exe", buf, sizeof(buf) - 1);
    if (n <= 0) return mr_xstrdup(".");
    buf[n] = 0;
    return mr_dirname(buf);
}

/* The prefix map's root: a mirrored Darwin tree, so /usr/lib/libSystem.B.dylib
 * becomes <root>/usr/lib/libSystem.B.dylib. */
static void find_darwin_root(void)
{
    const char *env = getenv("MACHORUN_ROOT");
    char *dir = loader_dir();
    const char *rel[] = { "darwin", "../darwin", "../../darwin", NULL };
    char probe[4096];

    if (env && *env) {
        char *r = mr_join(env, "darwin");
        MR.darwin_root = mr_file_exists(r) || access(r, X_OK) == 0 ? r : mr_xstrdup(env);
        if (MR.darwin_root != r) free(r);
        mr_log("darwin root: %s (from MACHORUN_ROOT)", MR.darwin_root);
        free(dir);
        return;
    }
    for (int i = 0; rel[i]; i++) {
        char *cand = mr_join(dir, rel[i]);
        snprintf(probe, sizeof(probe), "%s/usr/lib", cand);
        if (access(probe, X_OK) == 0) { MR.darwin_root = cand; break; }
        free(cand);
    }
    free(dir);
    mr_log("darwin root: %s", MR.darwin_root ? MR.darwin_root : "(none found)");
}

static void check_host(void)
{
    long ps = sysconf(_SC_PAGESIZE);
    if (ps <= 0) mr_die("sysconf(_SC_PAGESIZE) failed");
    MR.page.v = (uint64_t)ps;

    if (MR.page.v > 0x4000)
        mr_die("this kernel has %ld-byte pages. Apple's arm64 segments are 16 KiB apart, so "
               "__TEXT (r-x) and __DATA_CONST (rw-) share one page here and cannot be given "
               "distinct protections. See docs/PLAN.md §I.4 for the copy-in fallback that "
               "would fix it; it is not implemented.", ps);

    /* The loader's own text has to clear the guest's __PAGEZERO below it and
     * Swift's isa mask above it, and scripts/build.sh links it at
     * MR_LOADER_BASE to satisfy both at once. Checked rather than assumed,
     * because the whole point of a link-time address is that a build can lose
     * it silently. */
    if ((uint64_t)(uintptr_t)&check_host < 0x100000000ull)
        mr_die("machorun itself is loaded below 4 GiB (at %p), which is inside the guest's "
               "__PAGEZERO. It must be linked at MR_LOADER_BASE; see scripts/build.sh.",
               (void *)&check_host);
    if ((uint64_t)(uintptr_t)&check_host >= MR_ISA_LIMIT)
        mr_die("machorun itself is loaded at %p, at or above 2^47. glibc puts the heap "
               "just past this image, so every class the runtimes allocate would be "
               "truncated by libswiftCore's isa mask. It must be linked at "
               "MR_LOADER_BASE; see scripts/build.sh.", (void *)&check_host);
}

static char **build_apple(const char *argv0)
{
    static char *apple[2];
    char *e = mr_xmalloc(strlen(argv0) + 32);
    sprintf(e, "executable_path=%s", argv0);
    apple[0] = e;
    apple[1] = NULL;
    return apple;
}

static uint64_t find_runtime_symbol(const char *name)
{
    uint64_t addr;
    for (int i = 0; i < MR.nimages; i++)
        if (MR.images[i]->is_runtime && mr_exports_lookup(MR.images[i], name, &addr))
            return addr;
    return 0;
}

static void dump_image(const mr_image *im)
{
    printf("%s\n", im->path);
    printf("  filetype=%u flags=0x%x base=0x%llx slide=0x%llx%s\n",
           im->filetype, im->mh_flags, (unsigned long long)im->load_base,
           (unsigned long long)im->slide, im->is_runtime ? " [runtime]" : "");
    if (im->install_name) printf("  install_name %s\n", im->install_name);
    for (int i = 0; i < im->nsegs; i++)
        printf("  seg %-14s vm=0x%llx+0x%llx file=%llu+%llu prot=%u/%u flags=0x%x\n",
               im->segs[i].name, (unsigned long long)im->segs[i].vmaddr,
               (unsigned long long)im->segs[i].vmsize, (unsigned long long)im->segs[i].fileoff,
               (unsigned long long)im->segs[i].filesize, im->segs[i].initprot,
               im->segs[i].maxprot, im->segs[i].flags);
    for (int i = 0; i < im->ndeps; i++)
        printf("  dep[%d] %s -> %s\n", i + 1, im->deps[i].path,
               im->deps[i].img ? im->deps[i].img->path : "(missing weak)");
    for (int i = 0; i < im->nrpaths; i++) printf("  rpath %s\n", im->rpaths[i]);
    printf("  fixups: %s\n", im->chained_size ? "chained" : im->dyld_info ? "classic" : "none");
    printf("  exports: %zu\n", im->nexports);
    if (im->has_entry) printf("  LC_MAIN entryoff=0x%llx stacksize=0x%llx\n",
                              (unsigned long long)im->entryoff, (unsigned long long)im->stacksize);
    if (im->has_unixthread) printf("  LC_UNIXTHREAD pc=0x%llx\n",
                                   (unsigned long long)im->unixthread_pc);
}

int main(int argc, char **argv)
{
    int i = 1, info_only = 0;
    const char *guest;
    mr_image *im;
    uint64_t bootstrap, exitfn;
    int rc;

    if (getenv("MACHORUN_VERBOSE")) MR.verbose = 1;
    for (; i < argc; i++) {
        if (strcmp(argv[i], "-v") == 0 || strcmp(argv[i], "--verbose") == 0) MR.verbose = 1;
        else if (strcmp(argv[i], "--info") == 0) info_only = 1;
        else if (strcmp(argv[i], "--") == 0) { i++; break; }
        else break;
    }
    if (i >= argc) usage();
    guest = argv[i];

    check_host();
    mr_install_crash_reporter();
    /* Before find_darwin_root and everything after it: M_ARENA_MAX only binds
     * arenas that do not exist yet, so the knob has to be turned before the
     * loader's own allocations, let alone the guest's. */
    mr_constrain_heap();
    find_darwin_root();
    mr_reserve_pagezero();

    MR.exec_dir = mr_dirname(guest);
    MR.argc = argc - i;
    MR.argv = &argv[i];
    MR.envp = environ;
    MR.apple = build_apple(guest);

    im = mr_image_load(guest, NULL, 0, 1);

    /* Everything is mapped before anything is bound: a bind in image A can
     * name a symbol in image B, and B's export trie must already be readable. */
    for (int k = MR.nimages - 1; k >= 0; k--) mr_fixups_apply(MR.images[k]);
    for (int k = 0; k < MR.nimages; k++) mr_protect_readonly_segments(MR.images[k]);
    for (int k = 0; k < MR.nimages; k++) mr_tlv_setup(MR.images[k]);

    if (info_only) {
        for (int k = 0; k < MR.nimages; k++) dump_image(MR.images[k]);
        return 0;
    }

    /* environ, _NSGetArgv, __progname and the FILE* data exports are libSystem
     * state, so it gets told about the process before any initialiser runs. */
    bootstrap = find_runtime_symbol("___machorun_libsystem_bootstrap");
    if (bootstrap) {
        mr_log("libSystem bootstrap at 0x%llx", (unsigned long long)bootstrap);
        ((void (*)(int, char **, char **, char **))bootstrap)(MR.argc, MR.argv, MR.envp, MR.apple);
    } else if (MR.nimages > 1) {
        mr_log("no ___machorun_libsystem_bootstrap export found in any runtime image");
    }

    /* _objc_init, at the point Darwin's libSystem initializer calls it: after
     * our own dylibs are usable, before any guest initialiser. libobjc
     * registers its dyld callbacks from in there and we deliver map_images for
     * every already-loaded image before returning. See src/objc_notify.c. */
    mr_objc_run_objc_init();

    mr_run_initialisers(im);

    if (im->has_entry) {
        mr_entry_fn entry = (mr_entry_fn)(im->load_base + im->entryoff);
        if (im->stacksize)
            mr_unimplemented("LC_MAIN.stacksize",
                             "%s: LC_MAIN asks for a 0x%llx-byte main stack, which means running "
                             "main on a separately mmap'd stack. Measured 0 in every fixture.",
                             im->path, (unsigned long long)im->stacksize);
        mr_log("entry: 0x%llx(argc=%d)", (unsigned long long)(uintptr_t)entry, MR.argc);
        rc = entry(MR.argc, MR.argv, MR.envp, MR.apple);
    } else if (im->has_unixthread) {
        /* Darwin's LC_UNIXTHREAD entry gets a kernel-built stack:
         * [argc][argv...][NULL][envp...][NULL][apple...][NULL]. macOS 11+ on
         * arm64 refuses to exec these at all (measured: SIGKILL), so there is
         * no oracle for it -- but the parse and the mapping are still real. */
        size_t nenv = 0;
        uint64_t *sp;
        void *stack;
        while (MR.envp[nenv]) nenv++;
        stack = mr_xmalloc(65536);
        sp = (uint64_t *)((char *)stack + 32768);
        sp = (uint64_t *)((uintptr_t)sp & ~15ull);
        {
            uint64_t *w = sp;
            *w++ = (uint64_t)MR.argc;
            for (int k = 0; k < MR.argc; k++) *w++ = (uint64_t)(uintptr_t)MR.argv[k];
            *w++ = 0;
            for (size_t k = 0; k < nenv; k++) *w++ = (uint64_t)(uintptr_t)MR.envp[k];
            *w++ = 0;
            *w++ = (uint64_t)(uintptr_t)MR.apple[0];
            *w++ = 0;
        }
        mr_log("entry: LC_UNIXTHREAD pc=0x%llx",
               (unsigned long long)(im->load_base + im->unixthread_pc - im->preferred_base));
        __asm__ volatile("mov sp, %0\n\tbr %1"
                         :
                         : "r"(sp),
                           "r"(im->load_base + im->unixthread_pc - im->preferred_base)
                         : "memory");
        __builtin_unreachable();
    } else {
        mr_die("%s: no LC_MAIN and no LC_UNIXTHREAD -- nothing to call", im->path);
    }

    /* Return through the guest's own exit so its atexit/__cxa_atexit handlers
     * and stdio flush happen exactly as they would on Darwin. */
    exitfn = find_runtime_symbol("_exit");
    if (exitfn) ((void (*)(int))exitfn)(rc);
    return rc;
}
