/* probe.c -- stands in for a dylib STAGED into a guest root.
 *
 * The distinction this fixture turns on is src/resolve.c's `from->is_runtime`.
 * A dylib the darwin-root prefix map served -- which is every dylib staged
 * into a guest root, not just the ones machorun builds -- gets the host
 * fallback for anything no loaded image defines. A GUEST executable does not:
 * its missing imports are reported and the load fails. So the hazard can only
 * be reproduced from a dylib on the runtime side of that line, and this file
 * is that dylib. It is installed at /usr/lib/libdenyprobe.dylib inside a
 * throwaway darwin root built by scripts/host_deny_gate.sh.
 *
 * It calls the symbols and PRINTS WHAT THEY RETURNED, not whether they were
 * called. A control that reports "remquo ran" passes with any implementation;
 * one that reports "remquo(13,4) returned 1 with quo 3" does not.
 */
#include <stdio.h>
#include <string.h>

/* Darwin signatures. fcntl.h/math.h/stdlib.h would supply most of these, but
 * writing them out keeps the ABI this fixture is about visible in one place --
 * and semaphore.h is not in machorun's sysroot at all, deliberately (see
 * [[machorun-project]]'s note on sem_t: 4 bytes on Darwin, 32 in glibc). */
extern int          openat(int, const char *, int, ...);
extern void        *sem_open(const char *, int, ...);
extern int          vdprintf(int, const char *, __builtin_va_list);
extern long double  strtold(const char *, char **);
extern double       remquo(double, double, int *);
extern float        nanf(const char *);

static int probe_vdprintf(const char *fmt, ...)
{
    __builtin_va_list ap;
    int n;
    __builtin_va_start(ap, fmt);
    n = vdprintf(1, fmt, ap);
    __builtin_va_end(ap);
    return n;
}

/* Returns 0 when the named probe ran to completion. A denied name never
 * returns at all -- the loud stub calls _exit(70) -- so "returned" and
 * "was allowed through" are the same statement here. */
int deny_probe(const char *what);
int deny_probe(const char *what)
{
    if (strcmp(what, "remquo") == 0) {          /* CONTROL: must be allowed */
        int quo = -1;
        double r = remquo(13.0, 4.0, &quo);
        printf("remquo(13.0, 4.0, &quo) returned %.1f, quo %d\n", r, quo);
        return 0;
    }
    if (strcmp(what, "nanf") == 0) {            /* CONTROL: must be allowed */
        float x = nanf("");
        printf("nanf(\"\") returned a value with x!=x -> %d\n", x != x);
        return 0;
    }
    if (strcmp(what, "openat") == 0) {          /* DENIED */
        int fd = openat(-2 /* Darwin AT_FDCWD */, "probe.txt", 0 /* O_RDONLY */);
        printf("openat returned %d -- REACHED GLIBC, the deny-list did not fire\n", fd);
        return 1;
    }
    if (strcmp(what, "sem_open") == 0) {        /* DENIED */
        void *s = sem_open("/machorun_deny_probe", 0x200 /* Darwin O_CREAT */);
        printf("sem_open returned %p -- REACHED GLIBC, the deny-list did not fire\n", s);
        return 1;
    }
    if (strcmp(what, "vdprintf") == 0) {        /* DENIED */
        int n = probe_vdprintf("vdprintf wrote this: %d %s\n", 42, "text");
        printf("vdprintf returned %d -- REACHED GLIBC, the deny-list did not fire\n", n);
        return 1;
    }
    if (strcmp(what, "strtold") == 0) {         /* DENIED */
        long double v = strtold("1.5", (char **)0);
        printf("strtold(\"1.5\") returned %.1f -- REACHED GLIBC, the deny-list "
               "did not fire\n", (double)v);
        return 1;
    }
    printf("probe: no such probe '%s'\n", what);
    return 2;
}
