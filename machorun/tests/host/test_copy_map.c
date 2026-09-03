/* In-process test of mr_map_image's copy path.
 *
 * The loader is an aarch64 ELF; this file is a Linux host program that
 * links only map.c+util.c so the copy-map can run on x86_64 as well as
 * arm64. It builds a synthetic image whose DATA_CONST vmaddr is 0x14720
 * (the packed-fixture shape) and checks:
 *   - file bytes land at vmaddr+slide, not at the pre-pack DATA page 0x4000
 *   - the TEXT-to-DATA gap (slide+0x4008) is not readable (PROT_NONE)
 *   - DATA_CONST and DATA sharing page 0x14000 stay writable after the
 *     SG_READ_ONLY pass (union of protections)
 *
 * The 2026-09-03 packed-fixture SIGSEGV was pc at imageoff 0x5e0, fault
 * at slide+0x4008: that address is this gap. The mapper must leave it
 * unmapped; the rewriter must point ADRP at 0x14720 instead.
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

int main(void)
{
    enum { TEXT_USED = 0x100, DC_USED = 0x20, DATA_USED = 4 };
    uint8_t blob[TEXT_USED + DC_USED + DATA_USED];
    char tmpl[] = "/tmp/mr-copy-map-XXXXXX";
    int fd;
    mr_image im;
    uint8_t *got;
    uint64_t gap, dc, data;

    memset(blob, 0, sizeof(blob));
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

    fd = mkstemp(tmpl);
    if (fd < 0) {
        perror("mkstemp");
        return 1;
    }
    if (write(fd, blob, sizeof(blob)) != (ssize_t)sizeof(blob)) {
        perror("write");
        return 1;
    }

    memset(&im, 0, sizeof(im));
    im.path = tmpl;
    im.fd = fd;
    im.raw_len = sizeof(blob);
    im.filetype = MH_DYLIB;
    im.preferred_base = 0;
    im.nsegs = 3;
    /* TEXT 0..0x4000, DATA_CONST at the packed fixture's 0x14720, DATA
     * packed against it so they share host page 0x14000. */
    fill_seg(&im.segs[0], "__TEXT", 0, 0x4000, 0, TEXT_USED,
             VM_PROT_READ | VM_PROT_EXECUTE, 0);
    fill_seg(&im.segs[1], "__DATA_CONST", 0x14720, 0x20, TEXT_USED, DC_USED,
             VM_PROT_READ | VM_PROT_WRITE, SG_READ_ONLY);
    fill_seg(&im.segs[2], "__DATA", 0x14740, 0x10, TEXT_USED + DC_USED, DATA_USED,
             VM_PROT_READ | VM_PROT_WRITE, 0);

    MR.page.v = 4096;
    MR.verbose = 0;
    mr_map_image(&im);

    if (!im.mapped_by_copy) {
        fprintf(stderr, "test_copy_map: expected copy path, got mmap path\n");
        return 1;
    }

    got = (uint8_t *)(uintptr_t)im.load_base;
    if (got[0] != 0xCF || got[TEXT_USED - 1] != 'T') {
        fprintf(stderr, "test_copy_map: TEXT bytes missing at load_base\n");
        return 1;
    }

    dc = im.load_base + 0x14720;
    data = im.load_base + 0x14740;
    gap = im.load_base + 0x4008;

    if (memcmp((void *)(uintptr_t)dc, blob + TEXT_USED, DC_USED) != 0) {
        fprintf(stderr, "test_copy_map: DATA_CONST bytes not at vmaddr+slide "
                        "(0x%llx)\n", (unsigned long long)dc);
        return 1;
    }
    if (memcmp((void *)(uintptr_t)data, blob + TEXT_USED + DC_USED, DATA_USED) != 0) {
        fprintf(stderr, "test_copy_map: DATA bytes not at vmaddr+slide "
                        "(0x%llx)\n", (unsigned long long)data);
        return 1;
    }

    /* The pre-pack GOT page must NOT have been populated. That is the
     * address the unfixed stubs ADRP'd to. */
    if (can_read((void *)(uintptr_t)gap)) {
        fprintf(stderr, "test_copy_map: gap at slide+0x4008 is readable; "
                        "it must stay PROT_NONE (packed DATA is at +0x14720)\n");
        return 1;
    }

    mr_protect_readonly_segments(&im);

    /* Shared page 0x14000: DATA_CONST wants r after fixups, DATA wants rw.
     * Union is rw — a write through the DATA address must succeed. */
    *(volatile uint8_t *)(uintptr_t)data = 0x55;
    if (*(volatile uint8_t *)(uintptr_t)data != 0x55) {
        fprintf(stderr, "test_copy_map: DATA page not writable after "
                        "SG_READ_ONLY pass (union of prots failed)\n");
        return 1;
    }
    if (*(volatile uint8_t *)(uintptr_t)dc != blob[TEXT_USED]) {
        fprintf(stderr, "test_copy_map: DATA_CONST prefix lost on the shared page\n");
        return 1;
    }

    close(fd);
    unlink(tmpl);
    printf("test_copy_map ok  load_base=0x%llx  DATA_CONST at +0x14720  "
           "gap +0x4008 PROT_NONE  shared page rw\n",
           (unsigned long long)im.load_base);
    return 0;
}
