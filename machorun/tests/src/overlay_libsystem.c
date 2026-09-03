/* overlay_libsystem.c -- overlay NOUNDEFS names implemented in machorun.
 *
 * qos_class_self, voucher_copy/adopt, os_release, memset_s, vdprintf,
 * openat(AT_FDCWD), clock_getres. Not host-bound: CLOCK_* and AT_FDCWD
 * diverge, va_list diverges on arm64, memset_s is C11 Annex K (glibc lacks it).
 *
 * Operator: tests/build_fixtures.sh overlay_libsystem &&
 * harness/run_macos.sh --record overlay_libsystem, then flip the manifest
 * oracle cell to `run`.
 */
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

extern unsigned qos_class_self(void);
extern void *voucher_copy(void);
extern void *voucher_adopt(void *);
extern void os_release(void *);
extern int memset_s(void *, size_t, int, size_t);
extern int vdprintf(int, const char *, __builtin_va_list);

static int call_vdprintf(const char *fmt, ...)
{
    __builtin_va_list ap;
    int n;
    __builtin_va_start(ap, fmt);
    n = vdprintf(1, fmt, ap);
    __builtin_va_end(ap);
    return n;
}

int main(void)
{
    unsigned char buf[8];
    int fd, rc, n;
    struct timespec ts;

    printf("qos_class_self          0x%x\n", qos_class_self());
    printf("voucher_copy_NULL       %s\n", voucher_copy() == NULL ? "yes" : "NO");
    printf("voucher_adopt_NULL      %s\n", voucher_adopt(NULL) == NULL ? "yes" : "NO");
    os_release(NULL);
    printf("os_release_NULL         ok\n");

    memset(buf, 0, sizeof buf);
    rc = memset_s(buf, sizeof buf, 0xaa, 4);
    printf("memset_s_ok             rc=%d b0=0x%x\n", rc, buf[0]);
    rc = memset_s(NULL, 8, 0, 1);
    printf("memset_s_null           rc=%d EINVAL=%d\n", rc, rc == EINVAL);
    rc = memset_s(buf, 4, 0, 8);
    printf("memset_s_erange         rc=%d ERANGE=%d\n", rc, rc == ERANGE);

    n = call_vdprintf("vdprintf %d\n", 42);
    printf("vdprintf_n              %d\n", n);

    fd = openat(AT_FDCWD, "/dev/null", O_RDONLY);
    printf("openat_AT_FDCWD         fd>=0=%d\n", fd >= 0);
    if (fd >= 0) close(fd);

    rc = clock_getres(CLOCK_MONOTONIC, &ts);
    printf("clock_getres            rc=%d nsec>0=%d\n", rc, ts.tv_nsec > 0);
    puts("done");
    return 0;
}
