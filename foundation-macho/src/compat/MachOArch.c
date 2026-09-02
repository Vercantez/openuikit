/* MachOArch.c — NXGetLocalArchInfo / NXFindBestFatArch, and __exp10.
 *
 * CFBundle_Binary and CFBundle_Grok use the NX* pair to pick the right slice
 * out of a fat Mach-O. These are real implementations, not measurement stubs.
 *
 * Two things worth stating plainly:
 *
 * 1. Fat headers are BIG-ENDIAN on disk, always, regardless of the slices
 *    inside them. Callers of NXFindBestFatArch are documented to have already
 *    byte-swapped the fat_arch array into host order, so this function does NOT
 *    swap. Getting that backwards silently selects a garbage slice, so it is
 *    called out rather than assumed.
 *
 * 2. Apple's real NXFindBestFatArch consults a preference table that ranks
 *    related subtypes (e.g. an arm64e host preferring arm64e then arm64). We
 *    implement the two rules that matter and nothing more: exact
 *    (cputype, cpusubtype) match wins, otherwise a cputype match whose slice
 *    subtype is CPU_SUBTYPE_*_ALL. For a single-architecture arm64 target that
 *    is complete; if we ever host arm64e slices this needs the real ranking,
 *    and it should be revisited rather than extended by guesswork.
 */

#include <stddef.h>
#include <stdint.h>
#include <math.h>
#include <mach/machine.h>
#include <mach-o/fat.h>

#ifndef CPU_SUBTYPE_ARM64_ALL
#define CPU_SUBTYPE_ARM64_ALL 0
#endif

typedef struct {
    const char   *name;
    cpu_type_t    cputype;
    cpu_subtype_t cpusubtype;
    int           byteorder;
    const char   *description;
} NXArchInfo;

/* NX_LittleEndian is 1 in Apple's header; arm64 is little-endian. */
static const NXArchInfo kLocalArch = {
    "arm64", CPU_TYPE_ARM64, CPU_SUBTYPE_ARM64_ALL, 1, "ARM64"
};

const NXArchInfo *NXGetLocalArchInfo(void) {
    return &kLocalArch;
}

struct fat_arch *NXFindBestFatArch(cpu_type_t cputype, cpu_subtype_t cpusubtype,
                                   struct fat_arch *archs, unsigned long nfat) {
    /* CPU_SUBTYPE_MASK guards the capability bits (e.g. CPU_SUBTYPE_LIB64);
       they are not part of the identity being matched. */
    const cpu_subtype_t want = cpusubtype & ~CPU_SUBTYPE_MASK;

    for (unsigned long i = 0; i < nfat; i++) {
        if (archs[i].cputype == cputype &&
            (archs[i].cpusubtype & ~CPU_SUBTYPE_MASK) == want) {
            return &archs[i];
        }
    }
    for (unsigned long i = 0; i < nfat; i++) {
        if (archs[i].cputype == cputype &&
            (archs[i].cpusubtype & ~CPU_SUBTYPE_MASK) == CPU_SUBTYPE_ARM64_ALL) {
            return &archs[i];
        }
    }
    return NULL;
}

/* Darwin's libm exports __exp10; glibc spells it exp10 and does not export the
 * double-underscore name. Same function.
 *
 * The indirection is LOAD-BEARING. Written as the obvious `return pow(10.0, x);`
 * clang recognises the idiom, rewrites it to exp10, and emits a tail call to
 * __exp10 -- this very function. Measured: the whole body compiled to
 *
 *     0000000000000078 <___exp10>:
 *           78: 14000000    b  0x78 <___exp10>
 *
 * an unconditional branch to itself. It compiled without a warning and with
 * ZERO undefined symbols, which is exactly why it nearly went unnoticed; the
 * symbol table looked healthier than the correct version would have.
 *
 * A volatile function pointer defeats the pattern match while keeping pow's
 * accuracy (exp(x * M_LN10) would also work but is a ULP or two worse). */
static double (*volatile pow_indirect)(double, double) = pow;

double __exp10(double x) {
    return pow_indirect(10.0, x);
}
