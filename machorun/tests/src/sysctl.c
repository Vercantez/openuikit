/* sysctl.c -- the `sysctl` rung: the five MIBs CoreFoundation needs, and the one
 * that gates __CFInitialize.
 *
 * sysctl is the only entry in this whole boundary with NOTHING TO FORWARD TO.
 * sys/sysctl.h no longer exists in glibc 2.39, Linux's sysctl(2) was removed
 * from the kernel and returns ENOSYS, and the symbol survives in libc.so.6
 * only as a compat stub -- which is exactly the shape that lets a link succeed
 * and a call quietly do nothing. So every MIB here is a translation or a
 * refusal, never a pass-through.
 *
 * THE ONE THAT MATTERS is {CTL_KERN, KERN_PROC, KERN_PROC_PID, pid}. CF's
 * _CFGetSVUID reaches it from __CFInitialize, so nothing in CoreFoundation
 * runs until it answers. On Darwin it returns a whole struct kinfo_proc -- 648
 * bytes of BSD process table -- and CF reads exactly one field out of it:
 * kp_eproc.e_pcred.p_svuid, the saved set-user-ID.
 *
 * Under machorun that field is filled from getresuid(2), which is not a
 * plausible substitute for the answer but IS the answer: Linux's way of asking
 * the same question. Everything else in the struct is zeroed, so a reader of a
 * field we did not fill gets a defined 0 rather than stack contents.
 *
 * WHAT THIS FIXTURE CAN AND CANNOT ASSERT. It cannot print the uid: a CI
 * machine and a developer's laptop run as different users, and macOS and a
 * container certainly do. What it CAN assert is the property CF actually
 * depends on -- that the saved set-user-ID matches getuid() for a process that
 * is not setuid, which is true on both systems and is the whole point of the
 * check CF is making. It also asserts the SIZES, which is where a wrong answer
 * would be a stack smash rather than a wrong number.
 *
 * The CPU and memory MIBs are printed as RELATIONS rather than values for the
 * same reason: a machine's core count is not a portable constant, but
 * "available <= configured" and "memory is a positive multiple of the page
 * size" hold everywhere and would both break under a wrong width or a
 * forgotten 64-bit multiply.
 */
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/sysctl.h>

int main(void)
{
    int    mib[4];
    size_t len;
    int    v32;
    uint64_t v64;
    struct kinfo_proc kp;
    int rc;

    puts("== KERN_PROC / KERN_PROC_PID, which gates __CFInitialize");
    mib[0] = CTL_KERN; mib[1] = KERN_PROC; mib[2] = KERN_PROC_PID; mib[3] = getpid();

    /* The NULL-oldp size query is deliberately NOT asserted here. macOS
     * answers 3888 -- six times sizeof(struct kinfo_proc) -- because the
     * kernel over-reserves against the process list growing between the sizing
     * call and the fetch. machorun answers 648, the number of bytes it will
     * actually write, because it has no process list and no race to lose.
     * Imitating a kernel's reservation heuristic would be cargo-culting an
     * implementation detail, and CF never makes the sizing call anyway: it
     * passes a real buffer. Recorded in
     * docs/UNIMPLEMENTED.md#sysctl-mibs rather than papered over here.
     */

    memset(&kp, 0xAB, sizeof kp);          /* poison, so a short write shows */
    len = sizeof kp;
    rc = sysctl(mib, 4, &kp, &len, NULL, 0);
    printf("  fetch rc=%d  wrote %s\n", rc,
           len == sizeof(struct kinfo_proc) ? "the whole struct" : "A DIFFERENT SIZE");

    /* The property CF depends on. Not setuid, so the saved set-user-ID is the
     * real one -- true on macOS and under machorun, and the thing the check is
     * for. Printing the uid itself would differ between any two machines.
     *
     * THIS LINE HAS LESS TEETH THAN IT LOOKS AND THE HONEST PLACE TO SAY SO IS
     * HERE. Under machorun the struct is zeroed except for p_svuid, and the
     * test container runs as root -- so a WRONG offset still reads 0, getuid()
     * is also 0, and this check passes. Measured: deliberately writing p_svuid
     * eight bytes off left the fixture green. The offset is guarded instead by
     * sdk/tests/abi_probe.c, which static-asserts it against Apple's own SDK on
     * one side and our sysroot on the other. What this fixture does verify is
     * the plumbing around it: the call succeeds, the width is right, and the
     * value is self-consistent. */
    printf("  p_svuid == getuid(): %s\n",
           kp.kp_eproc.e_pcred.p_svuid == getuid() ? "yes" : "NO");

    puts("== KERN_MAXFILESPERPROC");
    mib[0] = CTL_KERN; mib[1] = KERN_MAXFILESPERPROC;
    len = sizeof v32; v32 = -1;
    rc = sysctl(mib, 2, &v32, &len, NULL, 0);
    printf("  rc=%d  width=%s  positive=%s\n", rc,
           len == sizeof(int) ? "int" : "WRONG", v32 > 0 ? "yes" : "NO");

    puts("== HW_NCPU and HW_AVAILCPU");
    {
        int ncpu = -1, avail = -1;
        mib[0] = CTL_HW; mib[1] = HW_NCPU;
        len = sizeof ncpu;
        rc = sysctl(mib, 2, &ncpu, &len, NULL, 0);
        printf("  HW_NCPU      rc=%d width=%s positive=%s\n", rc,
               len == sizeof(int) ? "int" : "WRONG", ncpu > 0 ? "yes" : "NO");

        mib[1] = HW_AVAILCPU;
        len = sizeof avail;
        rc = sysctl(mib, 2, &avail, &len, NULL, 0);
        printf("  HW_AVAILCPU  rc=%d width=%s positive=%s\n", rc,
               len == sizeof(int) ? "int" : "WRONG", avail > 0 ? "yes" : "NO");

        /* The relation, not the numbers: online cores cannot exceed
         * configured ones on any machine either system runs on. */
        printf("  available <= configured: %s\n", avail <= ncpu ? "yes" : "NO");
    }

    puts("== HW_MEMSIZE, the one that is uint64 rather than int");
    mib[0] = CTL_HW; mib[1] = HW_MEMSIZE;
    len = sizeof v64; v64 = 0;
    rc = sysctl(mib, 2, &v64, &len, NULL, 0);
    printf("  rc=%d  width=%s  positive=%s\n", rc,
           len == sizeof(uint64_t) ? "uint64" : "WRONG", v64 > 0 ? "yes" : "NO");
    /* A forgotten 64-bit multiply wraps to 0 or to something smaller than a
     * page on any machine with more than 4 GiB, so this catches it without
     * naming a size.
     *
     * Against sysconf(_SC_PAGESIZE) rather than getpagesize(), and the
     * difference is a real one this fixture found: under machorun the two
     * DISAGREE. getpagesize() returns Darwin's 16384 (darwin/src/mach.c hard-
     * codes MR_DARWIN_PAGE, which is right for a guest whose Mach-O segments
     * are 16K-aligned), while sysconf translates straight through to the host's
     * 4096. HW_MEMSIZE is computed as host-pages x host-page-size, because the
     * question is how much memory the MACHINE has -- so it is a multiple of the
     * sysconf value and not of the getpagesize one. On macOS both are 16384 and
     * the distinction does not arise. The divergence itself is reported in
     * docs/UNIMPLEMENTED.md#pagesize-two-answers. */
    printf("  a whole number of pages: %s\n",
           (v64 % (uint64_t)sysconf(_SC_PAGESIZE)) == 0 ? "yes" : "NO");
    printf("  at least 64 MiB: %s\n", v64 >= (64ull << 20) ? "yes" : "NO");

    puts("done");
    return 0;
}
