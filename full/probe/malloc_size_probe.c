/* malloc_size_probe.c -- does malloc_size() answer 0 for memory WE JUST
 * MALLOCED?
 *
 * Darwin's contract is "0 if p was not allocated by any malloc zone", and
 * callers use it as an ownership test -- objc4's try_free() is one, and objc4
 * also prints it when validating a hash table:
 *     objc[1]: Hash table corrupted ... buckets at 0x10033a6bab0 (0 BYTES)
 * That "(0 bytes)" is malloc_size on a live bucket array. If malloc_size can
 * answer 0 for a pointer malloc just returned, objc4 concludes its own table
 * is corrupt when nothing is wrong with it.
 *
 * machorun answers ownership POSITIVELY: a pointer is ours only if it lies in
 * glibc's MAIN-ARENA heap (bounds read from /proc/self/maps). Its own comment
 * records one case that costs -- an allocation at or above glibc's 32 MiB mmap
 * threshold lives outside brk. This walks sizes across that boundary and prints
 * the truth for each, so "some allocations report 0" stops being a deduction.
 */
#include <stdio.h>
#include <stdlib.h>

extern size_t malloc_size(const void *);

int main(void) {
    static const size_t sizes[] = {
        16, 1024, 64*1024, 1024*1024, 8*1024*1024,
        31*1024*1024, 32*1024*1024, 33*1024*1024, 64*1024*1024, 256*1024*1024
    };
    int bad = 0;
    for (unsigned i = 0; i < sizeof(sizes)/sizeof(sizes[0]); i++) {
        void *p = malloc(sizes[i]);
        if (!p) { printf("  %10zu  malloc FAILED\n", sizes[i]); continue; }
        size_t got = malloc_size(p);
        printf("  req=%10zu  ptr=%p  malloc_size=%10zu  %s\n",
               sizes[i], p, got, got ? "ok" : "<-- ZERO, reported foreign");
        if (!got) bad++;
        free(p);
    }
    printf("allocations misreported as foreign: %d\n", bad);
    return bad ? 1 : 0;
}
