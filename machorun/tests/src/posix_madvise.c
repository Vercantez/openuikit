/* posix_madvise.c -- the `posix_madvise` rung.
 *
 * Reached by the iOS-simulator guest (docs/agent_reports/ios-target-route.md):
 * swift-foundation-icu compiled for an iOS triple maps its data file and
 * calls posix_madvise, which the macOS build never referenced, so machorun
 * stopped at load with "undefined symbol '_posix_madvise'".
 *
 * The advice values 0..4 agree on Darwin and Linux (sys/mman.h both sides).
 * What differs is everything else, MEASURED on macOS 26 and the iOS 26.1
 * simulator (identical transcripts, tests/expected/posix_madvise.stdout):
 *   - Darwin does NOT follow POSIX's "return the error number": an invalid
 *     advice returns -1 and sets errno to EINVAL, like madvise. glibc's
 *     posix_madvise returns EINVAL and leaves errno alone.
 *   - Darwin accepts an unaligned address (rc 0); Linux EINVALs it.
 *   - POSIX_MADV_DONTNEED keeps the page's contents on Darwin. glibc's
 *     posix_madvise ignores DONTNEED for exactly that reason; madvise's
 *     MADV_DONTNEED on Linux would zero a private anonymous page.
 * errno is set to a sentinel before each call so both conventions show.
 */
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>

static void call(const char *label, void *p, size_t n, int advice)
{
    errno = 12345;
    int rc = posix_madvise(p, n, advice);
    int e = errno;
    printf("  %-28s rc=%s errno=%s\n", label,
           rc == 0 ? "0" : rc == EINVAL ? "EINVAL" : rc == -1 ? "-1" : "other",
           e == 12345 ? "untouched" : e == EINVAL ? "EINVAL" : "other");
}

int main(void)
{
    size_t page = (size_t)getpagesize();
    char *p = mmap(NULL, page * 4, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0);
    if (p == MAP_FAILED) { printf("mmap failed\n"); return 1; }
    memset(p, 7, page * 4);
    printf("posix_madvise\n");
    call("POSIX_MADV_NORMAL", p, page * 4, POSIX_MADV_NORMAL);
    call("POSIX_MADV_RANDOM", p, page * 4, POSIX_MADV_RANDOM);
    call("POSIX_MADV_SEQUENTIAL", p, page * 4, POSIX_MADV_SEQUENTIAL);
    call("POSIX_MADV_WILLNEED", p, page * 4, POSIX_MADV_WILLNEED);
    call("POSIX_MADV_DONTNEED", p + page, page, POSIX_MADV_DONTNEED);
    call("invalid advice 99", p, page, 99);
    call("unaligned address", p + 1, page, POSIX_MADV_NORMAL);
    printf("  data after advice: first page %d, DONTNEED page %d\n", p[0], p[page]);
    munmap(p, page * 4);
    return 0;
}
