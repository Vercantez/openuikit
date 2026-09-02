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
 * ADDING AN ENTRY: measure both sides first (sdk/tests/abi_probe.c on Darwin
 * against Apple's SDK, a host compile against real glibc on Linux) and put the
 * numbers in the message. The message a user sees must contain the evidence,
 * because the fix it points at -- a translating wrapper in darwin/src -- is
 * work, and nobody does work on the strength of an assertion.
 *
 * REMOVING AN ENTRY: implement the symbol in darwin/src. Then libSystem
 * exports it, resolve.c finds it in a loaded image, and this table is never
 * consulted -- an entry costs nothing once the real thing exists, so delete it
 * for tidiness, not because it is in the way.
 */
#include "machorun.h"
#include <stdio.h>
#include <string.h>
#include <unistd.h>

/* X(mach-o name, C name, hazard family, why -- with the measured numbers) */
#define MR_HOST_DENY_TABLE(X)                                                  \
    X(openat, "openat",                                                        \
      "constants + variadic",                                                  \
      "AT_FDCWD is -2 on Darwin and -100 on Linux, so a guest asking for "     \
      "\"relative to the current directory\" hands glibc an ordinary bad file "\
      "descriptor. Worse, the O_* flags ROTATE rather than merely diverge "    \
      "(measured both sides): Darwin's O_CREAT 0x200 IS Linux's O_TRUNC, and " \
      "Darwin's O_TRUNC 0x400 IS Linux's O_APPEND, and Darwin's O_EXCL 0x800 " \
      "IS Linux's O_NONBLOCK. A guest asking to CREATE a file therefore asks " \
      "glibc to TRUNCATE one -- a value that maps to something else real is "  \
      "what costs the afternoon, not a value that maps to nothing. And the "   \
      "mode argument is variadic: Darwin's arm64 varargs go on the stack, "    \
      "AAPCS64 puts them in registers.")                                       \
    X(sem_open, "sem_open",                                                    \
      "constants (inverted sentinel) + variadic",                              \
      "SEM_FAILED is (sem_t *)-1 on Darwin and (sem_t *)0 on Linux, so the "   \
      "error test is INVERTED: glibc's failure return reads as success and "   \
      "glibc's success return reads as failure. The O_* flags diverge as for " \
      "openat, and the mode/value arguments are variadic.")                    \
    X(vdprintf, "vdprintf",                                                    \
      "variadic convention (va_list layout)",                                  \
      "va_list is 8 bytes on Darwin/arm64 and 32 on Linux/aarch64 (measured "  \
      "both sides, not recalled). Darwin's is a single stack cursor -- all "   \
      "varargs are on the stack; glibc's is {__stack,__gr_top,__vr_top,"       \
      "__gr_offs,__vr_offs} and steers on the two offsets. glibc therefore "   \
      "reads 32 bytes out of an 8-byte object and decides register-vs-stack "  \
      "from whatever follows it. This is the same reason machorun owns its "   \
      "own printf formatter, and it is why vdprintf is NOT the harmless "      \
      "stdio forward it looks like.")                                          \
    X(strtold, "strtold",                                                      \
      "return-value width",                                                    \
      "long double is 8 bytes on Darwin/arm64 (LDBL_MANT_DIG 53 -- it IS "     \
      "double) and 16 on Linux/aarch64 (binary128, LDBL_MANT_DIG 113), "       \
      "measured both sides. glibc returns a quad in q0; the Darwin caller "    \
      "reads d0 as a double, i.e. the low half of a binary128 significand. "   \
      "Nothing in the signature, the arity or the linkage says so -- only the "\
      "width of a register does.")

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
        "  %s\n"
        "  FIX: implement %s in darwin/src (libSystem), translating on the\n"
        "  Darwin side of the call, and delete its row from src/host_deny.c.\n"
        "  Do NOT declare it with a GLIBCSYM label: that label means \"this ABI\n"
        "  is identical on both sides\", it binds straight to glibc, and it would\n"
        "  route around the wrapper you just wrote -- silently, exactly as this\n"
        "  stub does not. See docs/UNIMPLEMENTED.md#host-bind-denied.\n",
        name, name + 1, family, why, name + 1);
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
