/* In-process test of mr_map_image's copy path.
 *
 * The loader is an aarch64 ELF; this file is a Linux host program that
 * links only map.c+util.c so the copy-map can run on x86_64 as well as
 * arm64. It maps two synthetic images:
 *
 *   packed: DATA_CONST vmaddr 0x14720 (cache_layout_packed). Checks:
 *     - file bytes land at vmaddr+slide, not at the pre-pack DATA page 0x4000
 *     - the TEXT-to-DATA gap (slide+0x4008) is not readable
 *     - DATA_CONST and DATA sharing page 0x14000 stay writable after the
 *       SG_READ_ONLY pass (union of protections)
 *
 *   sparse: DATA_CONST vmaddr 0x22256720 (libswiftObjectiveC TEXT-to-DATA
 *   delta, measured 2026-09-03). Checks:
 *     - bytes land at +0x22256720
 *     - the packed-style gap +0x4008 AND a mid-cache hole are unmapped
 *     - no single VMA covers the ~546 MB union (per-segment reservation)
 *
 *   dsc-nofix: a dylib with DATA_CONST bytes and neither LC_DYLD_INFO
 *   nor LC_DYLD_CHAINED_FIXUPS is refused (Apple cache extracts). A
 *   dylib whose LC_DYLD_INFO_ONLY is present with every size zero is
 *   NOT refused (libCombine.dylib). The predicate is checked here; the
 *   loader _exit(74)s before mapping on the extract shape.
 *
 * The 2026-09-03 packed-fixture SIGSEGV was pc at imageoff 0x5e0, fault
 * at slide+0x4008: that address is the packed gap. The Reminder guest then
 * died at exit 139 after copy-mapping Apple's extract: the union of those
 * segments is hundreds of MB and must not be mmap'd or walked.
 */
#define _GNU_SOURCE
#include "machorun.h"

#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/stat.h>

#define CACHE_SPARSE_DELTA 0x22256720ull

static void fill_seg(mr_segment *s, const char *name,
                     uint64_t vm, uint64_t vmsz, uint64_t fo, uint64_t fsz,
                     uint32_t prot, uint32_t flags);

static void expect_dsc(const char *what, const mr_image *im, int want)
{
    int got = mr_image_is_cache_extract_without_fixups(im);
    if (got != want) {
        fprintf(stderr, "test_copy_map: %s: dsc-nofix predicate %d, want %d\n",
                what, got, want);
        exit(1);
    }
}

static void test_dsc_nofix_predicate(void)
{
    mr_image im;
    memset(&im, 0, sizeof(im));
    im.filetype = MH_DYLIB;
    im.nsegs = 2;
    fill_seg(&im.segs[0], "__TEXT", 0, 0x4000, 0, 0x1000,
             VM_PROT_READ | VM_PROT_EXECUTE, 0);
    fill_seg(&im.segs[1], "__DATA_CONST", 0x4000, 0x1000, 0x1000, 0x20,
             VM_PROT_READ | VM_PROT_WRITE, SG_READ_ONLY);
    expect_dsc("dylib DATA_CONST, no fixups", &im, 1);

    im.has_chained_fixups = 1;
    im.chained_size = 64;
    expect_dsc("dylib with chained fixups", &im, 0);
    im.chained_size = 0;
    expect_dsc("dylib with LC_DYLD_CHAINED_FIXUPS datasize 0", &im, 0);
    im.has_chained_fixups = 0;

    im.filetype = MH_EXECUTE;
    expect_dsc("executable without fixups", &im, 0);
    im.filetype = MH_DYLIB;

    im.segs[1].filesize = 0;
    expect_dsc("dylib with empty DATA_CONST", &im, 0);
    im.segs[1].filesize = 0x20;

    struct dyld_info_command di;
    memset(&di, 0, sizeof(di));
    di.bind_size = 16;
    im.dyld_info = &di;
    expect_dsc("dylib with classic binds", &im, 0);
    di.bind_size = 0;
    expect_dsc("dyld_info present + zero sizes", &im, 0);
    im.dyld_info = NULL;
    expect_dsc("no dyld_info and no chained", &im, 1);
}

static int can_read(const void *p)
{
    int fds[2];
    ssize_t n;
    if (pipe(fds) != 0) return 0;
    n = write(fds[1], p, 1);
    close(fds[0]);
    close(fds[1]);
    return n == 1;
}

/* 1 if some VMA fully covers [lo, hi). 0 if none does. -1 if maps unreadable. */
static int vma_covers(uint64_t lo, uint64_t hi)
{
    FILE *f = fopen("/proc/self/maps", "r");
    char line[512];
    int covered = 0;
    if (!f) return -1;
    while (fgets(line, sizeof line, f)) {
        unsigned long a, b;
        if (sscanf(line, "%lx-%lx", &a, &b) != 2) continue;
        if (a <= lo && b >= hi) {
            covered = 1;
            break;
        }
    }
    fclose(f);
    return covered;
}

static void fill_seg(mr_segment *s, const char *name,
                     uint64_t vm, uint64_t vmsz, uint64_t fo, uint64_t fsz,
                     uint32_t prot, uint32_t flags)
{
    memset(s, 0, sizeof(*s));
    snprintf(s->name, sizeof(s->name), "%s", name);
    s->vmaddr = vm;
    s->vmsize = vmsz;
    s->fileoff = fo;
    s->filesize = fsz;
    s->maxprot = prot;
    s->initprot = prot;
    s->flags = flags;
}

enum { TEXT_USED = 0x100, DC_USED = 0x20, DATA_USED = 4 };

static int write_blob(char *tmpl, uint8_t *blob, size_t n)
{
    int fd = mkstemp(tmpl);
    if (fd < 0) {
        perror("mkstemp");
        return -1;
    }
    if (write(fd, blob, n) != (ssize_t)n) {
        perror("write");
        close(fd);
        return -1;
    }
    return fd;
}

static void fill_blob(uint8_t *blob)
{
    memset(blob, 0, TEXT_USED + DC_USED + DATA_USED);
    memset(blob, 'T', TEXT_USED);
    blob[0] = 0xCF;
    blob[1] = 0xFA;
    blob[2] = 0xED;
    blob[3] = 0xFE;
    for (int i = 0; i < DC_USED; i++) blob[TEXT_USED + i] = (uint8_t)(0xA0 + i);
    blob[TEXT_USED + DC_USED] = 0x11;
    blob[TEXT_USED + DC_USED + 1] = 0x22;
    blob[TEXT_USED + DC_USED + 2] = 0x33;
    blob[TEXT_USED + DC_USED + 3] = 0x44;
}

int main(void)
{
    uint8_t blob[TEXT_USED + DC_USED + DATA_USED];
    char packed_tmpl[] = "/tmp/mr-copy-map-packed-XXXXXX";
    char sparse_tmpl[] = "/tmp/mr-copy-map-sparse-XXXXXX";
    int pfd, sfd;
    mr_image packed, sparse;
    uint8_t *got;
    uint64_t gap, dc, data, mid;
    int cover;

    fill_blob(blob);
    test_dsc_nofix_predicate();
    pfd = write_blob(packed_tmpl, blob, sizeof(blob));
    if (pfd < 0) return 1;
    sfd = write_blob(sparse_tmpl, blob, sizeof(blob));
    if (sfd < 0) return 1;

    MR.page.v = 4096;
    MR.verbose = 0;

    /* ---- packed-contiguous: DATA at +0x14720, shared page 0x14000 ---- */
    memset(&packed, 0, sizeof(packed));
    packed.path = packed_tmpl;
    packed.fd = pfd;
    packed.raw_len = sizeof(blob);
    packed.filetype = MH_DYLIB;
    packed.preferred_base = 0;
    packed.nsegs = 3;
    fill_seg(&packed.segs[0], "__TEXT", 0, 0x4000, 0, TEXT_USED,
             VM_PROT_READ | VM_PROT_EXECUTE, 0);
    fill_seg(&packed.segs[1], "__DATA_CONST", 0x14720, 0x20, TEXT_USED, DC_USED,
             VM_PROT_READ | VM_PROT_WRITE, SG_READ_ONLY);
    fill_seg(&packed.segs[2], "__DATA", 0x14740, 0x10, TEXT_USED + DC_USED, DATA_USED,
             VM_PROT_READ | VM_PROT_WRITE, 0);

    mr_map_image(&packed);

    if (!packed.mapped_by_copy) {
        fprintf(stderr, "test_copy_map: packed: expected copy path, got mmap path\n");
        return 1;
    }

    got = (uint8_t *)(uintptr_t)packed.load_base;
    if (got[0] != 0xCF || got[TEXT_USED - 1] != 'T') {
        fprintf(stderr, "test_copy_map: packed: TEXT bytes missing at load_base\n");
        return 1;
    }

    dc = packed.load_base + 0x14720;
    data = packed.load_base + 0x14740;
    gap = packed.load_base + 0x4008;

    if (memcmp((void *)(uintptr_t)dc, blob + TEXT_USED, DC_USED) != 0) {
        fprintf(stderr, "test_copy_map: packed: DATA_CONST bytes not at vmaddr+slide "
                        "(0x%llx)\n", (unsigned long long)dc);
        return 1;
    }
    if (memcmp((void *)(uintptr_t)data, blob + TEXT_USED + DC_USED, DATA_USED) != 0) {
        fprintf(stderr, "test_copy_map: packed: DATA bytes not at vmaddr+slide "
                        "(0x%llx)\n", (unsigned long long)data);
        return 1;
    }
    if (can_read((void *)(uintptr_t)gap)) {
        fprintf(stderr, "test_copy_map: packed: gap at slide+0x4008 is readable; "
                        "it must stay unmapped (packed DATA is at +0x14720)\n");
        return 1;
    }

    mr_protect_readonly_segments(&packed);

    *(volatile uint8_t *)(uintptr_t)data = 0x55;
    if (*(volatile uint8_t *)(uintptr_t)data != 0x55) {
        fprintf(stderr, "test_copy_map: packed: DATA page not writable after "
                        "SG_READ_ONLY pass (union of prots failed)\n");
        return 1;
    }
    if (*(volatile uint8_t *)(uintptr_t)dc != blob[TEXT_USED]) {
        fprintf(stderr, "test_copy_map: packed: DATA_CONST prefix lost on the shared page\n");
        return 1;
    }

    close(pfd);
    unlink(packed_tmpl);

    /* ---- sparse cache-wide: DATA at +0x22256720 ---- */
    memset(&sparse, 0, sizeof(sparse));
    sparse.path = sparse_tmpl;
    sparse.fd = sfd;
    sparse.raw_len = sizeof(blob);
    sparse.filetype = MH_DYLIB;
    sparse.preferred_base = 0;
    sparse.nsegs = 3;
    fill_seg(&sparse.segs[0], "__TEXT", 0, 0x4000, 0, TEXT_USED,
             VM_PROT_READ | VM_PROT_EXECUTE, 0);
    fill_seg(&sparse.segs[1], "__DATA_CONST", CACHE_SPARSE_DELTA, 0x20,
             TEXT_USED, DC_USED, VM_PROT_READ | VM_PROT_WRITE, SG_READ_ONLY);
    fill_seg(&sparse.segs[2], "__DATA", CACHE_SPARSE_DELTA + 0x20, 0x10,
             TEXT_USED + DC_USED, DATA_USED, VM_PROT_READ | VM_PROT_WRITE, 0);

    mr_map_image(&sparse);

    if (!sparse.mapped_by_copy) {
        fprintf(stderr, "test_copy_map: sparse: expected copy path, got mmap path\n");
        return 1;
    }

    got = (uint8_t *)(uintptr_t)sparse.load_base;
    if (got[0] != 0xCF || got[TEXT_USED - 1] != 'T') {
        fprintf(stderr, "test_copy_map: sparse: TEXT bytes missing at load_base\n");
        return 1;
    }

    dc = sparse.load_base + CACHE_SPARSE_DELTA;
    data = sparse.load_base + CACHE_SPARSE_DELTA + 0x20;
    gap = sparse.load_base + 0x4008;
    mid = sparse.load_base + (CACHE_SPARSE_DELTA / 2);

    if (memcmp((void *)(uintptr_t)dc, blob + TEXT_USED, DC_USED) != 0) {
        fprintf(stderr, "test_copy_map: sparse: DATA_CONST bytes not at +0x%llx "
                        "(0x%llx)\n",
                (unsigned long long)CACHE_SPARSE_DELTA, (unsigned long long)dc);
        return 1;
    }
    if (memcmp((void *)(uintptr_t)data, blob + TEXT_USED + DC_USED, DATA_USED) != 0) {
        fprintf(stderr, "test_copy_map: sparse: DATA bytes not at vmaddr+slide "
                        "(0x%llx)\n", (unsigned long long)data);
        return 1;
    }
    if (can_read((void *)(uintptr_t)gap)) {
        fprintf(stderr, "test_copy_map: sparse: +0x4008 is readable; packed-style "
                        "gap must stay unmapped when DATA is at +0x22256720\n");
        return 1;
    }
    if (can_read((void *)(uintptr_t)mid)) {
        fprintf(stderr, "test_copy_map: sparse: mid-gap +0x%llx is readable; "
                        "the cache-wide hole must not be reserved\n",
                (unsigned long long)(CACHE_SPARSE_DELTA / 2));
        return 1;
    }

    cover = vma_covers(sparse.load_base, sparse.load_base + CACHE_SPARSE_DELTA);
    if (cover < 0) {
        fprintf(stderr, "test_copy_map: sparse: /proc/self/maps unreadable\n");
        return 1;
    }
    if (cover) {
        fprintf(stderr, "test_copy_map: sparse: a VMA covers [load_base, "
                        "load_base+0x22256720); copy-map reserved the union "
                        "instead of per-segment page-runs\n");
        return 1;
    }

    {
        FILE *mf = fopen("/proc/self/maps", "r");
        char line[512];
        uint64_t slo = sparse.load_base, shi = sparse.load_base + CACHE_SPARSE_DELTA + 0x1000;
        if (mf) {
            printf("sparse VMAs in [0x%llx, 0x%llx):\n",
                   (unsigned long long)slo, (unsigned long long)shi);
            while (fgets(line, sizeof line, mf)) {
                unsigned long a, b;
                if (sscanf(line, "%lx-%lx", &a, &b) != 2) continue;
                if (b <= slo || a >= shi) continue;
                printf("  %s", line);
            }
            fclose(mf);
        }
    }

    mr_protect_readonly_segments(&sparse);
    *(volatile uint8_t *)(uintptr_t)data = 0x55;
    if (*(volatile uint8_t *)(uintptr_t)data != 0x55) {
        fprintf(stderr, "test_copy_map: sparse: DATA page not writable after "
                        "SG_READ_ONLY pass\n");
        return 1;
    }

    close(sfd);
    unlink(sparse_tmpl);
    printf("test_copy_map ok  packed load_base=0x%llx DATA_CONST +0x14720  "
           "gap +0x4008 PROT_NONE  shared page rw; "
           "sparse load_base=0x%llx DATA_CONST +0x22256720  "
           "hole unmapped  no union VMA; "
           "dsc-nofix predicate ok\n",
           (unsigned long long)packed.load_base,
           (unsigned long long)sparse.load_base);
    return 0;
}
