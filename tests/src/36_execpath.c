/* 36_execpath.c -- rung (ai): _NSGetExecutablePath, pthread_atfork and the
 * BSD string forms -- three of CoreFoundation's initialisation walls, and one
 * of them is the sharpest "plausible wrong answer" in the boundary.
 *
 * _NSGetExecutablePath IS THE ONE THAT MATTERS. The obvious Linux
 * implementation is readlink("/proc/self/exe"), and it is wrong in a way that
 * survives review: under machorun the process genuinely IS machorun, and the
 * Mach-O is something the loader mapped rather than something the kernel
 * exec'd. So /proc/self/exe returns the LOADER's path -- a real, existing,
 * readable file that is not the guest.
 *
 * CoreFoundation uses the answer to find the main bundle. A wrong path does not
 * fail: it points CF at a different directory, and every bundle-relative
 * resource lookup then fails a long way from the cause.
 *
 * WHAT THE FIXTURE CAN ASSERT. Not the path itself -- it is an absolute
 * filesystem path and differs between any two machines, let alone between a
 * macOS checkout and a container. What it CAN assert is the property that
 * distinguishes a right answer from the plausible wrong one: **the path ends
 * in this fixture's own name**. /proc/self/exe under machorun would end in
 * "machorun", and on macOS the same check passes trivially because the kernel
 * really did exec this binary. So one line covers both systems and only the
 * correct implementation satisfies it on both.
 *
 * It also covers Darwin's in/out bufsize contract, which is easy to get half
 * right: on success return 0; if the buffer is too small, write the REQUIRED
 * size back through bufsize and return -1. A caller that ignores the -1 and
 * reads the buffer gets whatever was there, so the size must be set on the
 * failure path too.
 *
 * pthread_atfork is here because it is a THIRD kind of gap. Not "same name,
 * different ABI" -- same name, and glibc does not export it as a dynamic
 * symbol at all: it lives in libc_nonshared.a as a static wrapper over
 * __register_atfork, so a plain forward fails at RUNTIME rather than at link.
 * This fixture registers handlers and does NOT fork -- machorun never forks,
 * and forking under a test harness is its own kind of trouble -- so what is
 * graded is that registration SUCCEEDS, which is the part that would have
 * failed with an undefined symbol.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>
#include <unistd.h>
#include <errno.h>
#include <mach-o/dyld.h>

static void pre(void)   { }
static void parent(void) { }
static void child(void)  { }

int main(void)
{
    char  buf[4096];
    unsigned sz;
    int rc;

    puts("== _NSGetExecutablePath");

    /* Size query: a too-small buffer must report the requirement and fail. */
    sz = 1;
    buf[0] = 'X';
    rc = _NSGetExecutablePath(buf, &sz);
    printf("  bufsize=1  rc=%d  reported a larger size: %s\n",
           rc, sz > 1 ? "yes" : "NO");

    /* The real call. */
    sz = sizeof buf;
    rc = _NSGetExecutablePath(buf, &sz);
    printf("  full buffer rc=%d  non-empty: %s  absolute: %s\n",
           rc, buf[0] ? "yes" : "NO", buf[0] == '/' ? "yes" : "NO");

    /* THE DISCRIMINATING LINE. /proc/self/exe would end in "machorun" here and
     * in this fixture's name on macOS; only a loader-derived answer ends in the
     * fixture's name on BOTH. */
    {
        const char *base = strrchr(buf, '/');
        base = base ? base + 1 : buf;
        printf("  names this executable: %s\n",
               strcmp(base, "36_execpath") == 0 ? "yes" : "NO");
    }

    /* bufsize is NOT updated on success -- measured on the oracle, a
     * 4096-byte buffer comes back still saying 4096 rather than the 113 the
     * path needed. Apple writes it only on the failure path, where it is the
     * caller's instruction for how much to allocate. Asserting it is unchanged
     * is what catches an implementation that "helpfully" sets it. */
    printf("  bufsize untouched on success: %s\n",
           sz == sizeof buf ? "yes" : "NO");

    puts("== pthread_atfork registers (glibc has no dynamic symbol for it)");
    rc = pthread_atfork(pre, parent, child);
    printf("  rc=%d\n", rc);
    /* Registering twice must also succeed -- glibc keeps a list, and a wrapper
     * that only worked once would be a different bug with the same first
     * result. */
    rc = pthread_atfork(pre, parent, child);
    printf("  again rc=%d\n", rc);

    puts("== pthread_getugid_np");
    {
        unsigned u = 12345, g = 12345;
        errno = 0;
        rc = pthread_getugid_np(&u, &g);
        /* THIS SPI FAILS ON DARWIN for an ordinary unprivileged thread --
         * measured on the oracle, rc=-1 with ESRCH and the outputs untouched.
         * It was recommended to me as "return geteuid()/getegid()", which is a
         * good argument from what Linux can supply and the wrong answer for
         * what Darwin does. CF is already on its failure path on a Mac, so
         * succeeding here would send it down a branch it never takes. */
        printf("  rc=%d  errno==ESRCH: %s  outputs untouched: %s\n", rc,
               errno == ESRCH ? "yes" : "NO",
               (u == 12345 && g == 12345) ? "yes" : "NO");
    }

    puts("== strlcat, which reports the length it TRIED to make");
    {
        char d[8];
        size_t n;

        strcpy(d, "ab");
        n = strlcat(d, "cd", sizeof d);
        printf("  fits:      result=\"%s\" returned=%zu\n", d, n);

        strcpy(d, "abcde");
        n = strlcat(d, "XYZ", sizeof d);
        /* Truncated to 7 chars + NUL, but the RETURN is 5+3=8 -- the length it
         * wanted. A wrapper returning the written length would report 7 and a
         * caller testing `n >= sizeof d` would miss the truncation. */
        printf("  truncates: result=\"%s\" returned=%zu  detectable: %s\n",
               d, n, n >= sizeof d ? "yes" : "NO");
    }

    puts("done");
    return 0;
}
