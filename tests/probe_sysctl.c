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

/* WALL 7: gethostuuid -- AND IT CORRECTS A PREDICTION IN #78's SCOPE REPORT.
 *
 * That report said gethostuuid was unreachable, on the reasoning that
 * UserDefaults always passes kCFPreferencesAnyHost. The argument is true and
 * the conclusion was wrong. `CFPreferencesCopyAppValue` does not use the
 * caller's host argument for the search: `CFApplicationPreferences.c:422-429`
 * builds an EIGHT-DOMAIN search list and four of those domains are
 * kCFPreferencesCurrentHost. Reaching a by-host domain needs
 * _CFPreferencesGetByHostIdentifierString -> _CFGetHostUUIDString ->
 * gethostuuid, whatever the caller asked for.
 *
 * Measured, not argued: with machorun #80's mutex fix in, T16's very first
 * CFPreferencesCopyAppValue printed `STUB CALLED: gethostuuid`. A link-level
 * reading of the gate could not have seen this, which is the whole reason the
 * route ruling wanted CF EXECUTED.
 *
 * NOT FICTION, and that distinction matters here. Darwin returns the host's
 * hardware UUID; /etc/machine-id is Linux's stable per-host identifier and is
 * the honest analogue. It is 32 lower-case hex digits with no dashes, which is
 * exactly 16 bytes -- the same shape CFUUIDCreateFromUUIDBytes wants.
 *
 * THE FAILURE PATH IS DARWIN'S OWN, so it needs no invention: on -1, CF logs
 * and returns NULL, and _CFPreferencesGetByHostIdentifierString then uses
 * CFSTR("UnknownHostID"). So a host with no machine-id degrades to a defined
 * Darwin behaviour rather than to a guess -- which is why this returns -1
 * instead of fabricating a UUID.
 *
 * THIS BELONGS IN MACHORUN'S libSystem, not here. CFPreferences.c's own
 * comment says so: "The entry point is in libSystem.B.dylib, but not actually
 * declared". It sits in this file under the rule at the top -- a probe is a
 * claim that something is absent -- and must be DELETED the moment machorun
 * exports it, or link order will silently prefer this copy over theirs. */
int gethostuuid(unsigned char *uuid_buf, const struct timespec *timeoutp);
int gethostuuid(unsigned char *uuid_buf, const struct timespec *timeoutp)
{
    (void)timeoutp;                      /* Darwin's timeout is for a daemon
                                          * round trip; reading a file cannot
                                          * block on one. */
    if (!uuid_buf) return -1;

    FILE *f = fopen("/etc/machine-id", "r");
    if (!f) return -1;
    char hex[33];
    size_t n = fread(hex, 1, 32, f);
    fclose(f);
    if (n != 32) return -1;

    for (int i = 0; i < 16; i++) {
        int hi = -1, lo = -1;
        char a = hex[i * 2], b = hex[i * 2 + 1];
        if (a >= '0' && a <= '9') hi = a - '0';
        else if (a >= 'a' && a <= 'f') hi = a - 'a' + 10;
        else if (a >= 'A' && a <= 'F') hi = a - 'A' + 10;
        if (b >= '0' && b <= '9') lo = b - '0';
        else if (b >= 'a' && b <= 'f') lo = b - 'a' + 10;
        else if (b >= 'A' && b <= 'F') lo = b - 'A' + 10;
        /* A malformed machine-id is a failure, not a partial UUID: half a
         * host identifier would still name a by-host preference file. */
        if (hi < 0 || lo < 0) return -1;
        uuid_buf[i] = (unsigned char)((hi << 4) | lo);
    }
    return 0;
}

/* WALL 8: snprintf_l -- the locale-aware snprintf, reached from CF's number
 * and string formatting on the preferences path.
 *
 * NOT FICTION for the only locale we can be in. Darwin's `_l` family takes an
 * explicit locale_t; passing NULL means the C locale, and LC_GLOBAL_LOCALE
 * here IS the C locale because nothing in this stack calls setlocale with
 * anything else. Under those conditions snprintf_l and snprintf are the same
 * function, so this forwards rather than reimplements.
 *
 * WHAT WOULD MAKE IT A LIE, stated so the next person can check rather than
 * trust: a non-C locale would change decimal separators and digit grouping,
 * and this forward would silently format 1.5 as "1,5" in a German locale --
 * plausible output, wrong bytes, no error. If ICU or a real locale ever lands,
 * this must be revisited, and the fact that it CANNOT currently be wrong is a
 * property of the environment, not of the code.
 *
 * Belongs in machorun's libSystem with the rest of the printf family. */
#include <stdarg.h>
typedef void *mr_locale_t;
int snprintf_l(char *buf, size_t n, mr_locale_t loc, const char *fmt, ...);
int snprintf_l(char *buf, size_t n, mr_locale_t loc, const char *fmt, ...)
{
    (void)loc;
    va_list ap;
    va_start(ap, fmt);
    int r = vsnprintf(buf, n, fmt, ap);
    va_end(ap);
    return r;
}

/* WALL 9: pthread_threadid_np -- Darwin's 64-bit kernel thread id.
 *
 * NOT FICTION. Darwin's contract: with a NULL thread argument, write the
 * CALLING thread's id and return 0; a non-NULL thread other than self needs
 * the kernel's mapping, which is the part we cannot do. Linux's gettid() is
 * exactly the calling-thread case, so self is answered truthfully and anything
 * else is refused with ESRCH rather than being handed the caller's own id --
 * a wrong-but-plausible id is how a thread-keyed cache silently collides.
 *
 * Reached on the preferences path via CF's logging/diagnostic helpers.
 * Belongs in machorun's libSystem beside the rest of the pthread surface. */
#include <sys/syscall.h>
#include <errno.h>
/* Through the loader's glibc bridge, like mr_glibc_readlink above: the guest's
 * own syscall() would be Darwin's numbering, and SYS_gettid is Linux's. */
extern long mr_glibc_syscall(long, ...) __asm__("_glibc_syscall");
int pthread_threadid_np(void *thread, unsigned long long *thread_id);
int pthread_threadid_np(void *thread, unsigned long long *thread_id)
{
    if (thread != NULL) return ESRCH;    /* not self: we have no mapping */
    if (thread_id) *thread_id = (unsigned long long)mr_glibc_syscall(SYS_gettid);
    return 0;
}

/* WALL 10: writev -- and the three walls before it name what CF is doing.
 *
 * snprintf_l, pthread_threadid_np and writev arriving in that order, all on
 * the FIRST CFPreferencesCopyAppValue, is CFLog's signature: format the
 * message, stamp it with the thread id, write it with one vector call. CF is
 * not failing here, it is trying to TELL us something -- and until writev
 * exists the message is the one thing we cannot see.
 *
 * That is worth stating because a stub abort on `writev` reads like a missing
 * file primitive, and the actual finding is a diagnostic we are deaf to.
 *
 * NOT FICTION: glibc's writev, through the loader's bridge for the same reason
 * as gettid above. Darwin's struct iovec is {void *iov_base; size_t iov_len},
 * which is glibc's layout exactly -- both are pointer-then-size_t with no
 * padding on arm64 -- so the vector can be forwarded rather than translated.
 * If that ever stops being true this is a silent buffer-boundary bug, so the
 * assertion is written down rather than assumed. */
extern long mr_glibc_writev(int, const void *, int) __asm__("_glibc_writev");
long writev(int fd, const void *iov, int iovcnt);
long writev(int fd, const void *iov, int iovcnt)
{
    return mr_glibc_writev(fd, iov, iovcnt);
}
