/* host_deny.c -- names that must NOT be satisfied out of glibc by name alone.
 *
 * THE PROBLEM THIS EXISTS FOR IS THAT NOBODY CHOOSES TO FORWARD.
 *
 * src/resolve.c has one escape hatch: when a bind from one of OUR OWN images
 * (is_runtime -- anything the darwin-root prefix map served, which includes
 * every dylib staged into a guest root) finds no definition in any loaded
 * Mach-O, it calls host_lookup() and takes glibc's symbol of the same name.
 * That is deliberate and load-bearing: it is how libSystem reaches glibc.
 *
 * But it is a DEFAULT, not a decision. A dylib staged into a guest root for
 * some unrelated reason drags its undefined symbols in with it, and each one
 * that our userland does not define is silently answered by glibc -- with no
 * translation of any kind. Measured 2026-08-27 on the FoundationEssentials
 * URL-oracle guest root (scratch/mrroot_fe): 371 distinct symbols host-bound,
 * of which 329 are the explicit `_glibc_*` boundary (below), 34 are the
 * loader's own exports (darwin/loader-exports.txt), and EIGHT are plain
 * Darwin C names that arrived by accident. Four of those eight are ABI-
 * divergent, and each would have failed as a WRONG ANSWER rather than as a
 * missing symbol. They are the table below.
 *
 * WHAT THIS DOES: it does not refuse the bind. It binds the name to a stub
 * that names itself and dies IF IT IS EVER CALLED. That distinction is the
 * whole design:
 *
 *   - refusing at bind time would stop a guest that never calls the symbol.
 *     All four of these are dormant in the root that found them: the URL
 *     oracle scores 802/802 and touches none of them. Turning a working run
 *     into a load failure over a call that does not happen trades a silent
 *     hazard for a loud regression.
 *   - binding to glibc keeps the wrong answer.
 *
 * So: load succeeds, MACHORUN_VERBOSE=1 says the name was denied, and the
 * first call stops the process with a sentence. That is the same late-but-loud
 * shape as the eight advertised-but-unimplemented libSystem entries, and it is
 * the tolerable form of a partial claim.
 *
 * `_glibc_*` IS NOT AND MUST NOT BE DENIED. That prefix is an assertion by a
 * wrapper author -- "I have checked this ABI and it is identical on both
 * sides" (darwin/src/dsys.h) -- and darwin/src/posix.c's own `open` wrapper
 * reaches glibc's open through exactly that label after translating the flags.
 * Denying the labelled spelling would block the correct implementation of the
 * very symbol we are protecting. The label is where the audit lives; this
 * table is for the names that never got one.
 *
 * ADDING AN ENTRY: two kinds of row, and they must not be confused.
 *
 *   ABI-divergent Darwin C names -- measure both sides first (sdk/tests/abi_probe.c
 *   on Darwin against Apple's SDK, a host compile against real glibc on Linux)
 *   and put the numbers in the message. The fix is a translating wrapper in
 *   darwin/src.
 *
 *   compiler-rt builtins -- do NOT measure Darwin vs glibc, do NOT add them to
 *   darwin/host-bound-allowed.txt, and do NOT implement them in darwin/src.
 *   Apple answers them from libclang_rt.osx.a at link (PR #64). A name in this
 *   family reaching glibc means a dylib was linked without that archive
 *   (typically `-undefined dynamic_lookup`). The message must name the archive.
 *
 * REMOVING AN ENTRY: for an ABI-divergent name, implement it in darwin/src.
 * Then libSystem exports it, resolve.c finds it in a loaded image, and this
 * table is never consulted -- an entry costs nothing once the real thing exists,
 * so delete it for tidiness, not because it is in the way. For a compiler-rt
 * row, rebuild the importing dylib NOUNDEFS with libclang_rt.osx.a; the row
 * stays as the loud answer if some future dylib is linked without the archive.
 */
#include "machorun.h"
#include <stdio.h>
#include <string.h>
#include <unistd.h>

/* X(mach-o identifier, "cname", hazard family, why).
 * Parsers in check_undefined.sh and host_deny_gate.sh take cname from the
 * SAME LINE as X(ident, "cname" -- do not wrap between the identifier and
 * the quoted C name. Mixed-case compiler-rt hooks depend on that. */
#define MR_HOST_DENY_TABLE(X)                                                  \
    X(strtold, "strtold",                                                      \
      "return-value width",                                                    \
      "long double is 8 bytes on Darwin/arm64 (LDBL_MANT_DIG 53 -- it IS "     \
      "double) and 16 on Linux/aarch64 (binary128, LDBL_MANT_DIG 113), "       \
      "measured both sides. glibc returns a quad in q0; the Darwin caller "    \
      "reads d0 as a double, i.e. the low half of a binary128 significand. "   \
      "Nothing in the signature, the arity or the linkage says so -- only the "\
      "width of a register does. x86_64 implements strtold in libSystem "      \
      "(darwin/src/libsystem.c); this row stays so an aarch64 host-bind "      \
      "cannot silently return a binary128 half. openat/sem_open/vdprintf "     \
      "moved into darwin/src (translating wrappers) and are no longer here.")  \
    /* compiler-rt builtins. Mach-O spelling is "_" + cname, so cname "__divti3"
     * is the import ___divti3. glibc does not implement these. A root that
     * still lists them as undefined was linked without libclang_rt.osx.a. */  \
    X(__divti3, "__divti3", "compiler-rt",                                     \
      "compiler-rt builtin. Reaching glibc means a dylib was linked without "  \
      "libclang_rt.osx.a (PR #64). Do not host-bind-allow this name.")          \
    X(__modti3, "__modti3", "compiler-rt",                                     \
      "compiler-rt builtin. Reaching glibc means a dylib was linked without "  \
      "libclang_rt.osx.a (PR #64). Do not host-bind-allow this name.")          \
    X(__udivti3, "__udivti3", "compiler-rt",                                   \
      "compiler-rt builtin. Reaching glibc means a dylib was linked without "  \
      "libclang_rt.osx.a (PR #64). Do not host-bind-allow this name.")          \
    X(__umodti3, "__umodti3", "compiler-rt",                                   \
      "compiler-rt builtin. Reaching glibc means a dylib was linked without "  \
      "libclang_rt.osx.a (PR #64). Do not host-bind-allow this name.")          \
    X(__truncsfhf2, "__truncsfhf2", "compiler-rt",                             \
      "compiler-rt builtin. Reaching glibc means a dylib was linked without "  \
      "libclang_rt.osx.a (PR #64). Do not host-bind-allow this name.")          \
    X(__isPlatformVersionAtLeast, "__isPlatformVersionAtLeast", "compiler-rt", \
      "compiler-rt builtin. Reaching glibc means a dylib was linked without "  \
      "libclang_rt.osx.a (PR #64). Do not host-bind-allow this name.")          \
    X(__isPlatformOrVariantPlatformVersionAtLeast, "__isPlatformOrVariantPlatformVersionAtLeast", "compiler-rt", \
      "compiler-rt builtin. Reaching glibc means a dylib was linked without "  \
      "libclang_rt.osx.a (PR #64). Do not host-bind-allow this name.")

#define DENY_STUB(mangled, cname, family, why)                                 \
    __attribute__((noreturn)) static void mr_host_deny_##mangled(void);        \
    __attribute__((noreturn)) static void mr_host_deny_##mangled(void)         \
    {                                                                          \
        mr_host_deny_die("_" cname, family, why);                              \
    }

__attribute__((noreturn)) static void
mr_host_deny_die(const char *name, const char *family, const char *why);

MR_HOST_DENY_TABLE(DENY_STUB)

static const struct { const char *name; void (*trap)(void); } deny[] = {
#define DENY_ROW(mangled, cname, family, why) { "_" cname, mr_host_deny_##mangled },
    MR_HOST_DENY_TABLE(DENY_ROW)
#undef DENY_ROW
};

__attribute__((noreturn)) static void
mr_host_deny_die(const char *name, const char *family, const char *why)
{
    fflush(stdout);
    fprintf(stderr,
        "machorun: HOST-BIND DENIED: %s\n"
        "  Nothing in the guest root defines it, so machorun's host fallback\n"
        "  would have handed the caller glibc's %s with NO TRANSLATION. It is\n"
        "  bound to this stub instead, and you have just called it.\n"
        "  hazard family: %s\n"
        "  %s\n",
        name, name + 1, family, why);
    if (strcmp(family, "compiler-rt") == 0) {
        fprintf(stderr,
            "  FIX: a compiler-rt builtin reaching glibc means a dylib was\n"
            "  linked without libclang_rt.osx.a (PR #64,\n"
            "  swiftcore-macho/scripts/build_compiler_rt_osx.sh). Rebuild that\n"
            "  dylib NOUNDEFS with the archive. Do NOT add %s to\n"
            "  darwin/host-bound-allowed.txt and do NOT implement it in\n"
            "  darwin/src -- gen_tbd libSystem must not export compiler-rt.\n"
            "  See docs/UNIMPLEMENTED.md#host-bind-denied.\n",
            name + 1);
    } else {
        fprintf(stderr,
            "  FIX: implement %s in darwin/src (libSystem), translating on the\n"
            "  Darwin side of the call, and delete its row from src/host_deny.c.\n"
            "  Do NOT declare it with a GLIBCSYM label: that label means \"this ABI\n"
            "  is identical on both sides\", it binds straight to glibc, and it would\n"
            "  route around the wrapper you just wrote -- silently, exactly as this\n"
            "  stub does not. See docs/UNIMPLEMENTED.md#host-bind-denied.\n",
            name + 1);
    }
    fflush(stderr);
    _exit(70);
}

/* The trap for `name`, or NULL if the name is not denied.
 *
 * Called only from the host-fallback path in src/resolve.c, i.e. only after
 * every loaded image has been searched and come up empty. A real
 * implementation anywhere in the process therefore always wins over this
 * table; the table can only ever intercept what would otherwise have gone
 * straight to glibc. */
void *mr_host_deny_trap(const char *name)
{
    if (!name) return NULL;
    for (size_t i = 0; i < sizeof(deny) / sizeof(deny[0]); i++)
        if (strcmp(deny[i].name, name) == 0) return (void *)deny[i].trap;
    return NULL;
}
