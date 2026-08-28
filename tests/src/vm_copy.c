/* vm_copy -- Mach's in-task virtual copy, and the answers a man page does not
 * give you.
 *
 * FoundationEssentials reaches this through Platform.copyMemoryPages, which
 * reads (Platform.swift:63)
 *
 *     if vm_copy(mach_task_self(), src, len, dst) != KERN_SUCCESS {
 *         memmove(dest, source, length)
 *     }
 *
 * so returning KERN_FAILURE is a legitimate implementation for THAT caller --
 * upstream wrote the fallback for exactly this. It is not legitimate for any
 * other caller, and "the one consumer I looked at has a fallback" is how a gap
 * becomes permanent. This fixture asks Darwin what vm_copy actually DOES, so
 * the implementation can agree with a measurement instead of with a summary.
 *
 * FOUR THINGS IT MEASURED THAT A READER WOULD HAVE GUESSED WRONG:
 *   - there is NO page-alignment requirement, on either address or the size.
 *     An unaligned 100-byte copy succeeds and touches exactly 100 bytes.
 *   - OVERLAPPING regions get memmove semantics, not a forward byte copy. The
 *     two differ by 40 in the checksum below, so this fixture can tell them
 *     apart -- which is the only reason it prints a checksum rather than "it
 *     copied".
 *   - a PROT_NONE or read-only region gives KERN_INVALID_ADDRESS (1), NOT
 *     KERN_PROTECTION_FAILURE (2). Every summary of vm_copy says otherwise.
 *   - size 0 succeeds.
 *
 * IT PRINTS RETURN CODES AND CONTENTS, NEVER ADDRESSES -- the comparison is
 * byte-for-byte against macOS and an address is the one thing that legitimately
 * differs. kern_return_t is printed as a number: KERN_SUCCESS 0,
 * KERN_INVALID_ADDRESS 1, KERN_PROTECTION_FAILURE 2, KERN_INVALID_ARGUMENT 4.
 */
#include <mach/mach.h>
#include <mach/vm_map.h>
#include <stdio.h>
#include <string.h>

static void fill(char *p, unsigned n, int seed)
{
    for (unsigned i = 0; i < n; i++) p[i] = (char)('a' + ((i + seed) % 26));
}

/* Sum plus both ends. Printing the whole region would be noise; printing "did
 * it copy" would pass for a copy of the wrong length or the wrong direction. */
static void show(const char *what, const char *p, unsigned n)
{
    unsigned long sum = 0;
    for (unsigned i = 0; i < n; i++) sum += (unsigned char)p[i];
    printf("  %-22s first=%c last=%c sum=%lu\n", what, p[0], p[n - 1], sum);
}

int main(void)
{
    const unsigned P = (unsigned)vm_page_size;   /* 16384 on Darwin/arm64 */
    vm_address_t src = 0, dst = 0;
    kern_return_t kr;

    kr = vm_allocate(mach_task_self(), &src, P * 4, VM_FLAGS_ANYWHERE);
    printf("vm_allocate src returned %d\n", (int)kr);
    kr = vm_allocate(mach_task_self(), &dst, P * 4, VM_FLAGS_ANYWHERE);
    printf("vm_allocate dst returned %d\n", (int)kr);
    if (!src || !dst) return 1;

    char *s = (char *)src, *d = (char *)dst;

    /* 1. the case everybody agrees about: page-aligned, whole pages. */
    fill(s, P * 2, 0);
    memset(d, '.', P * 2);
    kr = vm_copy(mach_task_self(), src, P * 2, dst);
    printf("aligned whole pages     returned %d\n", (int)kr);
    show("dst after aligned", d, P * 2);
    printf("  memcmp src/dst        %d\n", memcmp(s, d, P * 2));

    /* 2. a size that is not a multiple of the page size, and the byte AFTER it. */
    fill(s, P * 2, 1);
    memset(d, '.', P * 2);
    kr = vm_copy(mach_task_self(), src, 100, dst);
    printf("aligned, size 100       returned %d\n", (int)kr);
    printf("  dst[0]=%c dst[99]=%c dst[100]=%c\n", d[0], d[99], d[100]);

    /* 3. source address not page-aligned. */
    fill(s, P * 2, 2);
    memset(d, '.', P * 2);
    kr = vm_copy(mach_task_self(), src + 8, P, dst);
    printf("unaligned src +8        returned %d\n", (int)kr);
    printf("  dst[0]=%c\n", d[0]);

    /* 4. destination not page-aligned. */
    fill(s, P * 2, 3);
    memset(d, '.', P * 2);
    kr = vm_copy(mach_task_self(), src, P, dst + 8);
    printf("unaligned dst +8        returned %d\n", (int)kr);
    printf("  dst[0]=%c dst[8]=%c\n", d[0], d[8]);

    /* 5. size 0. */
    kr = vm_copy(mach_task_self(), src, 0, dst);
    printf("size 0                  returned %d\n", (int)kr);

    /* 6. OVERLAP, forwards. memmove is defined here and a virtual copy need
     * not be; this is the case where "implement it as memmove" and "implement
     * it as memcpy" give different bytes, so it is measured and not assumed. */
    fill(s, P * 4, 4);
    kr = vm_copy(mach_task_self(), src, P * 2, src + P);
    printf("overlapping +1 page     returned %d\n", (int)kr);
    show("src after overlap", s, P * 4);

    /* 7. an address that is not mapped at all -- taken from an allocation we
     * then free, so it is a real hole rather than a number invented here. */
    {
        vm_address_t gone = 0;
        vm_allocate(mach_task_self(), &gone, P, VM_FLAGS_ANYWHERE);
        vm_deallocate(mach_task_self(), gone, P);
        fill(s, P, 5);
        kr = vm_copy(mach_task_self(), src, P, gone);
        printf("dst unmapped            returned %d\n", (int)kr);
        kr = vm_copy(mach_task_self(), gone, P, dst);
        printf("src unmapped            returned %d\n", (int)kr);
    }

    /* 8-10. PROTECTION. Mapped, and not accessible the way the call needs. */
    vm_protect(mach_task_self(), dst, P, 0, VM_PROT_NONE);
    kr = vm_copy(mach_task_self(), src, P, dst);
    printf("dst PROT_NONE           returned %d\n", (int)kr);
    vm_protect(mach_task_self(), dst, P, 0, VM_PROT_READ);
    kr = vm_copy(mach_task_self(), src, P, dst);
    printf("dst read-only           returned %d\n", (int)kr);
    vm_protect(mach_task_self(), dst, P, 0, VM_PROT_READ | VM_PROT_WRITE);
    vm_protect(mach_task_self(), src, P, 0, VM_PROT_NONE);
    kr = vm_copy(mach_task_self(), src, P, dst);
    printf("src PROT_NONE           returned %d\n", (int)kr);
    vm_protect(mach_task_self(), src, P, 0, VM_PROT_READ | VM_PROT_WRITE);

    /* THE CASE THIS FIXTURE DOES NOT CONTAIN, named rather than omitted.
     * `vm_copy` with a task port that is not this task returns 268435459
     * (0x10000003, MACH_SEND_INVALID_DEST) on Darwin -- an IPC error about the
     * PORT, produced before vm_copy is reached at all. machorun's ports are
     * integers with no IPC space behind them
     * (docs/UNIMPLEMENTED.md#mach-ports-are-fiction), and every other vm_*
     * entry in darwin/src/mach.c answers KERN_INVALID_TASK. Putting the case
     * here would either force vm_copy alone to fake a send failure, or record
     * a divergence as expected output. Both are worse than saying so. */

    vm_deallocate(mach_task_self(), src, P * 4);
    vm_deallocate(mach_task_self(), dst, P * 4);
    puts("done");
    return 0;
}
