/* The nine host-bound names that were CHECK 5's to-implement pile.
 *
 * libobjc.A.dylib and libquartz.dylib in this tree do not import any of them
 * (measured: nm -u; objc wants getsegmentdata/strtol, quartz wants strtod).
 * They are the documented libswiftCore gap, and they are what a host-bind of
 * the Darwin spelling would have reached glibc BY NAME for -- or failed to,
 * for the five names glibc does not export at all.
 *
 * WHAT EACH ONE IS GRADED FOR (Darwin semantics, not a self-record):
 *
 *   strto*_l     NULL and LC_GLOBAL_LOCALE both mean C, same bytes as the
 *                non-_l converter. Locale construction is closed (setlocale
 *                only), so these are the only locale_t values a guest can
 *                hold. strtold_l's width is 8 -- Darwin arm64 long double
 *                IS double; a forward to glibc strtold_l would be 16.
 *
 *   getsectiondata
 *                finds a section this binary actually contains, by matching
 *                BOTH segment and section name, and the bytes at the returned
 *                pointer are the bytes the compiler emitted. A walk that
 *                matches only the section name, or that forgets the slide,
 *                fails this.
 *
 *   malloc_zone_from_ptr
 *                a malloc() pointer is in the default zone; a stack pointer
 *                and NULL are not. Always-NULL (the compat-shim answer) fails
 *                the heap line; always-default fails the stack line.
 *
 *   pthread_get_stackaddr_np
 *                the HIGH end: a local sits at lo <= &local < addr, with
 *                addr - size giving lo. glibc getstack's LOW address fails
 *                the high=1 check.
 *
 *   os_system_version
 *                26.1.0 by value -- the SDK version the corpus carries in
 *                LC_BUILD_VERSION, not a guessed 15.0.0.
 *
 *   getline      POSIX: reads one line including the newline, returns the
 *                length. FILE* came from fopen, so it is glibc's object.
 */
#include <errno.h>
#include <mach-o/getsect.h>
#include <mach-o/ldsyms.h>
#include <malloc/malloc.h>
#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <xlocale.h>

static const unsigned char mrchk[8]
    __attribute__((used, section("__DATA,__mrchk"))) = {
        'h', 'o', 's', 't', 'b', 'o', 'u', 'n'
    };

typedef struct { uint32_t major, minor, patch; } os_sysver_t;
os_sysver_t os_system_version_get_current_version(void);

int main(void)
{
    char *end;
    double d, dnull, dglob;
    float fl;
    long double ld;
    unsigned long segsz = 0;
    uint8_t *sec;
    void *heap, *zone, *def, *stzone;
    char local;
    void *stk;
    size_t stsz;
    os_sysver_t ver;
    FILE *fp;
    char *line = NULL;
    size_t cap = 0;
    ssize_t n;
    char path[] = "/tmp/hostbound_surface.XXXXXX";
    int fd;

    /* --- strto*_l against the non-_l converters, C locale both ways. */
    d = strtod("1.5", &end);
    printf("strtod                %.1f\n", d);

    dnull = strtod_l("1.5", &end, NULL);
    printf("strtod_l NULL         %.1f same=%d\n", dnull, dnull == d);

    dglob = strtod_l("1.5", &end, LC_GLOBAL_LOCALE);
    printf("strtod_l GLOBAL       %.1f same=%d\n", dglob, dglob == d);

    /* strtof is host-bound in this tree, not a libSystem export; the
     * comparison is against the IEEE binary32 value, which both sides share. */
    fl = strtof_l("1.25", &end, NULL);
    printf("strtof_l NULL         %.2f same=%d\n", fl, fl == 1.25f);

    printf("strtold_l width       %d\n", (int)sizeof(long double));
    ld = strtold_l("2.5", &end, NULL);
    printf("strtold_l NULL        %.1Lf same_as_strtod=%d\n",
           ld, (double)ld == strtod("2.5", &end));

    /* --- getsectiondata on a section this file contains. */
    sec = getsectiondata(&_mh_execute_header, "__DATA", "__mrchk", &segsz);
    printf("getsectiondata        found=%d size=%lu match=%d\n",
           sec != NULL, segsz,
           sec && segsz == sizeof mrchk && memcmp(sec, mrchk, sizeof mrchk) == 0);

    /* --- malloc_zone_from_ptr: heap vs stack vs NULL. */
    heap = malloc(32);
    def = malloc_default_zone();
    zone = malloc_zone_from_ptr(heap);
    printf("malloc_zone heap      nonzero=%d same_as_default=%d\n",
           zone != NULL, zone == def);
    stzone = malloc_zone_from_ptr(&local);
    printf("malloc_zone stack     null=%d\n", stzone == NULL);
    printf("malloc_zone NULL      null=%d\n", malloc_zone_from_ptr(NULL) == NULL);
    free(heap);

    /* --- pthread stack: HIGH address, local inside [lo, addr). */
    stk = pthread_get_stackaddr_np(pthread_self());
    stsz = pthread_get_stacksize_np(pthread_self());
    printf("stackaddr             high=%d\n",
           stsz && (char *)stk - stsz <= &local && &local < (char *)stk);
    printf("stacksize             nonzero=%d covers_local=%d\n",
           stsz != 0,
           stsz && (char *)stk - stsz <= &local && &local < (char *)stk);

    ver = os_system_version_get_current_version();
    printf("os_system_version     %u.%u.%u\n", ver.major, ver.minor, ver.patch);

    /* --- getline via a FILE* this library minted. */
    fd = mkstemp(path);
    if (fd < 0) {
        printf("getline               mkstemp failed\n");
        return 1;
    }
    close(fd);
    fp = fopen(path, "w+");
    if (!fp) {
        unlink(path);
        printf("getline               fopen failed\n");
        return 1;
    }
    fwrite("hello world\n", 1, 12, fp);
    rewind(fp);
    n = getline(&line, &cap, fp);
    printf("getline               n=%ld [%s] cap_nonzero=%d\n",
           (long)n, (n > 0 && line && line[n - 1] == '\n') ? "has_nl" : "no_nl",
           cap != 0);
    fclose(fp);
    unlink(path);
    free(line);

    puts("done");
    return 0;
}
