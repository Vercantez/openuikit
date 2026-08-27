/* PROBES FOR THE FOUR INIT WALLS MACHORUN HAS NOT YET IMPLEMENTED.
 *
 * WAS ALSO A PROBE sysctl AND __strlcpy_chk. BOTH ARE GONE, deliberately:
 * machorun landed the five MIBs and __strlcpy_chk (master cc6524e, verified in
 * the built dylib), so keeping local versions would mean testing MY code
 * instead of THEIRS -- and link order would silently prefer mine. Removing a
 * probe the moment the real thing lands is the same rule as deleting a shim
 * when the sysroot grows one; a probe is a claim that something is absent.
 *
 * What remains, all measured absent from libSystem today:
 *     pthread_getugid_np    __strlcat_chk    pthread_atfork    _NSGetExecutablePath
 *
 * Two of the four are FICTION and are marked as such at their definitions:
 * pthread_atfork is a no-op, and _NSGetExecutablePath returns the LOADER's path
 * rather than the guest's. Any result that depends on bundles is measuring a
 * lie; results that do not touch bundles are not affected. See
 * docs/cf-census/cf-init-walls.md.
 */
#include <sys/types.h>
#include <sys/sysctl.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

/* ---------------------------------------------------------------------------
 * THE WALLS BEHIND sysctl, satisfied one at a time so the NEXT one becomes
 * visible. Each is answered with the least fiction that lets CF proceed, and
 * every one is recorded in docs/cf-census/cf-init-walls.md with what a real
 * implementation would have to do. None of this is shippable.
 * ------------------------------------------------------------------------- */

/* WALL 1: pthread_getugid_np -- Darwin-only SPI, part of the same
 * "is this process privileged" question as _CFGetSVUID. Returns the thread's
 * effective uid/gid. Linux has no per-thread ugid override, so a real
 * implementation is geteuid/getegid, which is what this does -- meaning this
 * one is not fiction at all and machorun can implement it exactly this way. */
int pthread_getugid_np(uid_t *uid, gid_t *gid);
int pthread_getugid_np(uid_t *uid, gid_t *gid)
{
    if (uid) *uid = geteuid();
    if (gid) *gid = getegid();
    return 0;
}

/* WALL 2: __strlcat_chk (__strlcpy_chk LANDED in libSystem and is gone from here) -- Apple's _FORTIFY_SOURCE variants.
 * The compiler rewrites strlcat/strlcpy into these when the destination size is
 * known, passing it as a fourth argument. REAL implementations, not fiction:
 * the semantics are strlcat/strlcpy plus a check that the declared object size
 * is not exceeded. Both are absent from libSystem and both are trivial, so
 * machorun can take these almost verbatim.
 *
 * Darwin's contract: return the length it TRIED to create, so the caller can
 * detect truncation by comparing against the buffer size. Getting that wrong
 * turns a detectable truncation into a silent one. */
size_t __strlcat_chk(char *dst, const char *src, size_t dsize, size_t objsize);
size_t __strlcat_chk(char *dst, const char *src, size_t dsize, size_t objsize)
{
    if (dsize > objsize) abort();
    size_t dlen = 0;
    while (dlen < dsize && dst[dlen]) dlen++;
    size_t slen = strlen(src);
    if (dlen == dsize) return dsize + slen;   /* dst not NUL-terminated */
    size_t room = dsize - dlen - 1, n = slen < room ? slen : room;
    memcpy(dst + dlen, src, n);
    dst[dlen + n] = '\0';
    return dlen + slen;
}

/* WALL 3: setenv -- and this one is NOT fiction either.
 *
 * setenv's ABI is (const char *, const char *, int) -> int on both platforms,
 * with no struct, no constant and no width that differs, so it is one of the
 * genuinely plain forwards. Bound straight to glibc through the loader's
 * _glibc_<x> convention, which resolves because libCFTest.dylib is loaded from
 * a Darwin absolute path and therefore has is_runtime set.
 *
 * A no-op returning 0 was the tempting shortcut and would have been WRONG in a
 * way that matters HERE specifically: CF sets variables during initialisation
 * and reads them back, so a no-op could send the rest of this walk down a
 * different path than the real one and silently corrupt the wall list. The
 * whole value of this probe is that the sequence it discovers is the sequence
 * that will actually happen. */
/* Declared under a unique C name with an __asm__ label, because <stdlib.h>
 * already declares setenv and re-declaring it with a label is a "conflicting
 * asm label" error. Same technique as the generated stubs, for the same
 * reason: the label sidesteps the C type system, which is what we want when
 * the goal is to occupy a symbol rather than to type-check a call. */
extern int mr_glibc_setenv(const char *, const char *, int) __asm__("_glibc_setenv");
int probe_setenv(const char *n, const char *v, int o) __asm__("_setenv");
int probe_setenv(const char *n, const char *v, int o) { return mr_glibc_setenv(n, v, o); }

/* WALL 4: pthread_atfork -- AND IT CANNOT BE FORWARDED BY dlsym, which is a
 * real finding for whoever implements it rather than a probe detail.
 *
 * The obvious treatment is a plain forward: three function pointers, no struct,
 * no constant, identical ABI. It fails at RUNTIME:
 *
 *     machorun: undefined symbol '_glibc_pthread_atfork'
 *       looked in: every loaded image (flat lookup)
 *
 * glibc does not export pthread_atfork as a dynamic symbol. It lives in
 * libc_nonshared.a and is implemented on top of __register_atfork, so there is
 * nothing for dlsym to find. A libSystem implementation has to call
 * __register_atfork(prepare, parent, child, __dso_handle) instead -- the same
 * shape as futex, where the door had to be built rather than forwarded.
 *
 * FOR THIS PROBE IT IS A NO-OP, and that IS fiction, recorded as such: atfork
 * handlers only matter across fork(), which this initialisation walk never
 * does, so it cannot alter the sequence of walls being collected. */
int probe_pthread_atfork(void (*p)(void), void (*c)(void), void (*ch)(void))
    __asm__("_pthread_atfork");
int probe_pthread_atfork(void (*p)(void), void (*c)(void), void (*ch)(void))
{ (void)p; (void)c; (void)ch; return 0; }

/* WALL 5: _NSGetExecutablePath -- dyld SPI, and it carries a TRAP that matters
 * far more than the function does.
 *
 * Darwin's contract: fill buf, return 0; if too small, set *bufsize to the
 * required size and return -1. CF uses it to find the main bundle, so getting
 * it wrong means every bundle-relative resource lookup is wrong.
 *
 * THE TRAP: the obvious Linux implementation is readlink("/proc/self/exe"), and
 * under machorun THAT RETURNS THE LOADER, not the guest. The process really is
 * machorun; the Mach-O is something it mapped. So a faithful implementation has
 * to come from the loader's own knowledge of which guest image it loaded, not
 * from the kernel's idea of what is executing. A /proc/self/exe implementation
 * would look completely correct, return a real and existing path, and point CF
 * at the wrong file -- with every bundle lookup then failing somewhere far away.
 *
 * The probe uses /proc/self/exe anyway, BECAUSE it only needs to get past this
 * call, and records the trap here so the real implementation does not repeat it.
 */
extern long mr_glibc_readlink(const char *, char *, unsigned long) __asm__("_glibc_readlink");
int probe_NSGetExecutablePath(char *buf, unsigned *bufsize) __asm__("__NSGetExecutablePath");
int probe_NSGetExecutablePath(char *buf, unsigned *bufsize)
{
    char tmp[4096];
    long n = mr_glibc_readlink("/proc/self/exe", tmp, sizeof(tmp) - 1);
    if (n <= 0) return -1;
    tmp[n] = '\0';
    unsigned need = (unsigned)n + 1;
    if (!bufsize) return -1;
    if (*bufsize < need) { *bufsize = need; return -1; }
    memcpy(buf, tmp, need);
    return 0;
}

/* WALL 6: flsl -- and it is NOT obscure. "find last set bit, long" is on the
 * MUTABLE COLLECTION path: CFArrayAppendValue reaches it through CFStorage's
 * capacity rounding, so nothing can be appended to a CFArray without it.
 *
 * Genuinely implementable, not fiction, and machorun can take this verbatim.
 * Darwin's contract: return the one-based index of the most significant set
 * bit, 0 for an argument of 0. __builtin_clzl is undefined for 0, which is
 * exactly the case the contract singles out, so the zero test comes first
 * rather than being an optimisation. */
int flsl(long mask);
int flsl(long mask)
{
    if (mask == 0) return 0;
    return (int)(64 - __builtin_clzl((unsigned long)mask));
}
