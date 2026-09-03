/* The eight CHECK 5 names Darwin actually ran: strto*_l, getsectiondata,
 * malloc_zone_from_ptr, pthread_get_stackaddr_np / pthread_get_stacksize_np,
 * getline.
 *
 * Split from os_system_version_get_current_version, which is a ninth name
 * with a different ABI (out-pointer, not a by-value struct) and lives in
 * tests/src/hostbound_osver.c. The Darwin oracle printed the twelve lines
 * from strtod through stacksize byte-identically, then SIGSEGV'd on the
 * by-value os_system_version call (exit 139). These eight keep their
 * coverage even if that ninth row stays NEEDS_DARWIN_BASELINE.
 *
 * No tests/expected/ files are committed for this id: a qemu/machorun run
 * is not an oracle. The manifest says norun:NEEDS_DARWIN_BASELINE until
 * the operator records on macOS with tests/build_fixtures.sh and
 * harness/run_macos.sh --record.
 *
 * WHAT EACH ONE IS GRADED FOR (Darwin semantics):
 *
 *   strto*_l     NULL and LC_GLOBAL_LOCALE both mean C, same bytes as the
 *                non-_l converter. Locale construction is closed (setlocale
 *                only). strtold_l's width is 8 -- Darwin arm64 long double
 *                IS double.
 *
 *   getsectiondata
 *                finds a section this binary actually contains, matching
 *                BOTH segment and section name; the bytes at the returned
 *                pointer are the bytes the compiler emitted.
 *
 *   malloc_zone_from_ptr
 *                a malloc() pointer is in the default zone; a stack pointer
 *                and NULL are not.
 *
 *   pthread_get_stackaddr_np
 *                the HIGH end: a local sits at lo <= &local < addr.
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
