/* A PROBE sysctl, to look ahead past __CFInitialize's first wall.
 *
 * NOT AN IMPLEMENTATION AND NOT SHIPPABLE. This exists to answer one question:
 * what does CoreFoundation reach for AFTER the five sysctl MIBs, which cannot
 * be derived from static analysis because those calls are unreachable until
 * something answers the first one. Serially discovering them costs a round trip
 * to machorun per wall; this finds them in one pass, in our own tree, before
 * anything lands there.
 *
 * IT SATISFIES EXACTLY THE FIVE MIBs CF USES AND ABORTS ON EVERYTHING ELSE,
 * loudly and by name. An unknown MIB answered with zeroes would let CF proceed
 * on a fabricated fact, which is the failure mode this whole exercise exists to
 * avoid -- and it would corrupt the very list we are trying to collect.
 *
 * HOW IT WINS OVER libSystem'S REAL _sysctl: link order, not runtime shadowing.
 * This object is passed to the linker BEFORE -lSystem, so ld64 resolves _sysctl
 * here and never consults libSystem. That is ordinary static resolution. It is
 * deliberately NOT the flat-namespace trick of hoping our copy loads first,
 * which is the shadowing bug this project has now hit five times.
 *
 * THE p_svuid VALUE IS A PROBE VALUE AND IS DOCUMENTED AS ONE. Darwin has no
 * getresuid (measured: libSystem exports geteuid and getuid, not getresuid), so
 * this reports the effective uid as the saved-set uid. That makes svuid == euid,
 * which is the not-setuid case -- the common one, and the safe one to assume
 * while measuring. It is NOT what machorun should ship: there the real saved-set
 * uid is available from Linux's getresuid(2), and the whole point of the
 * objection I raised is that this predicate should be answered from the system
 * rather than assumed. Nothing here should reach machorun.
 */
#include <sys/types.h>
#include <sys/sysctl.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

extern int printf(const char *, ...);

/* WRITE(2), NOT printf. The first run of this probe produced NOTHING on either
 * stream: printf is block-buffered when stdout is a file or pipe, and abort()
 * discards the buffer. The instrument was swallowing the one message the whole
 * exercise exists to collect. Unbuffered write to fd 2 cannot be lost. */
static void probe_say(const char *s)
{
    size_t n = 0; while (s[n]) n++;
    (void)!write(2, s, n);
}

static void probe_bail(const char *what, int a, int b)
{
    char buf[160]; int i = 0;
    const char *p1 = "PROBE-SYSCTL: unimplemented MIB {";
    while (*p1) buf[i++] = *p1++;
    i += snprintf(buf + i, sizeof(buf) - (size_t)i, "%d, %d} (%s)\n", a, b, what);
    buf[i] = 0;
    probe_say(buf);
    probe_say("PROBE-SYSCTL: refusing to answer with zeroes -- a fabricated fact\n"
              "  in CF would corrupt the very list this run exists to collect.\n");
    abort();
}

int sysctl(int *name, unsigned namelen, void *oldp, size_t *oldlenp,
           void *newp, size_t newlen);

int sysctl(int *name, unsigned namelen, void *oldp, size_t *oldlenp,
           void *newp, size_t newlen)
{
    (void)newp; (void)newlen;
    if (namelen < 2 || !name) { probe_bail("malformed", -1, -1); }

    if (name[0] == CTL_KERN && name[1] == KERN_PROC &&
        namelen >= 3 && name[2] == KERN_PROC_PID) {
        /* CFUtilities.c:624 _CFGetSVUID reads exactly one field out of this:
         * kp_eproc.e_pcred.p_svuid. Everything else stays zeroed, which is the
         * shape machorun should implement too -- the struct does not need
         * modelling, only that one integer needs to be true. */
        struct kinfo_proc *kp = (struct kinfo_proc *)oldp;
        if (!kp || !oldlenp || *oldlenp < sizeof(*kp)) return -1;
        memset(kp, 0, sizeof(*kp));
        kp->kp_eproc.e_pcred.p_svuid = geteuid();   /* PROBE VALUE -- see header */
        *oldlenp = sizeof(*kp);
        return 0;
    }

    if (name[0] == CTL_KERN && name[1] == KERN_MAXFILESPERPROC) {
        if (!oldp || !oldlenp || *oldlenp < sizeof(int)) return -1;
        *(int *)oldp = 10240;                       /* RLIMIT_NOFILE on Linux */
        *oldlenp = sizeof(int);
        return 0;
    }

    if (name[0] == CTL_HW && (name[1] == HW_NCPU || name[1] == HW_AVAILCPU)) {
        if (!oldp || !oldlenp || *oldlenp < sizeof(int)) return -1;
        long n = sysconf(_SC_NPROCESSORS_ONLN);
        *(int *)oldp = (int)(n > 0 ? n : 1);
        *oldlenp = sizeof(int);
        return 0;
    }

    if (name[0] == CTL_HW && name[1] == HW_MEMSIZE) {
        if (!oldp || !oldlenp || *oldlenp < sizeof(uint64_t)) return -1;
        long pages = sysconf(_SC_PHYS_PAGES), psz = sysconf(_SC_PAGESIZE);
        *(uint64_t *)oldp = (pages > 0 && psz > 0)
                          ? (uint64_t)pages * (uint64_t)psz
                          : (uint64_t)1 << 31;
        *oldlenp = sizeof(uint64_t);
        return 0;
    }

    probe_bail("not one of CF's five", name[0], name[1]);
    return -1;
}

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

/* WALL 2: __strlcat_chk / __strlcpy_chk -- Apple's _FORTIFY_SOURCE variants.
 * The compiler rewrites strlcat/strlcpy into these when the destination size is
 * known, passing it as a fourth argument. REAL implementations, not fiction:
 * the semantics are strlcat/strlcpy plus a check that the declared object size
 * is not exceeded. Both are absent from libSystem and both are trivial, so
 * machorun can take these almost verbatim.
 *
 * Darwin's contract: return the length it TRIED to create, so the caller can
 * detect truncation by comparing against the buffer size. Getting that wrong
 * turns a detectable truncation into a silent one. */
size_t __strlcpy_chk(char *dst, const char *src, size_t dsize, size_t objsize);
size_t __strlcpy_chk(char *dst, const char *src, size_t dsize, size_t objsize)
{
    if (dsize > objsize) abort();          /* the check the _chk form exists for */
    size_t slen = strlen(src);
    if (dsize) {
        size_t n = slen < dsize - 1 ? slen : dsize - 1;
        memcpy(dst, src, n);
        dst[n] = '\0';
    }
    return slen;
}

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
