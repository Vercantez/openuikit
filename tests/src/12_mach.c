/* 12_mach -- the Mach APIs a plain C program actually reaches for.
 *
 * The README's bet says Mach is "a bounded list, not a kernel ABI": these
 * calls do not get their traps emulated, they get REIMPLEMENTED on Linux
 * primitives inside our libSystem -- vm_allocate on mmap, mach_absolute_time
 * on clock_gettime. This fixture is the bound on that claim for rung (j).
 *
 * Everything printed is a derived fact, never a raw port number, address or
 * timestamp: a port name, a page size and a mach_absolute_time reading are all
 * legitimately different on the two platforms. What must be identical is the
 * BEHAVIOUR -- success codes, page alignment, zero-fill, the read-back of
 * memory we own, monotonicity, and the timebase converting to real seconds.
 */
#include <mach/mach.h>
#include <mach/mach_time.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

int main(void)
{
    mach_port_t task = mach_task_self();
    mach_port_t thread = mach_thread_self();
    kern_return_t kr;
    vm_address_t addr = 0;
    const vm_size_t len = 64 * 1024;

    printf("task_self nonnull=%s\n", task != MACH_PORT_NULL ? "yes" : "no");
    printf("task_self stable=%s\n", mach_task_self() == task ? "yes" : "no");
    printf("thread_self nonnull=%s\n", thread != MACH_PORT_NULL ? "yes" : "no");

    /* ---- vm_allocate / vm_protect / vm_deallocate ---- */
    kr = vm_allocate(task, &addr, len, VM_FLAGS_ANYWHERE);
    printf("vm_allocate kr=%d ok=%s\n", kr, kr == KERN_SUCCESS ? "yes" : "no");
    if (kr != KERN_SUCCESS) return 1;

    printf("vm_allocate aligned=%s\n", (addr & 0x3fff) == 0 ? "yes" : "no");

    /* Freshly allocated Mach memory is zero-filled, by contract. */
    {
        unsigned char *p = (unsigned char *)addr;
        int zeroed = 1;
        for (size_t i = 0; i < len; i++)
            if (p[i]) { zeroed = 0; break; }
        printf("vm_allocate zerofilled=%s\n", zeroed ? "yes" : "no");

        memset(p, 0xA5, len);
        p[0] = 'M'; p[1] = 'a'; p[2] = 'c'; p[3] = 'h'; p[4] = 0;
        printf("readback=%s tail=0x%02x\n", (char *)p, p[len - 1]);
    }

    kr = vm_protect(task, addr, len, FALSE, VM_PROT_READ);
    printf("vm_protect ro kr=%d ok=%s\n", kr, kr == KERN_SUCCESS ? "yes" : "no");
    printf("still readable=%s\n", ((char *)addr)[0] == 'M' ? "yes" : "no");

    kr = vm_protect(task, addr, len, FALSE, VM_PROT_READ | VM_PROT_WRITE);
    printf("vm_protect rw kr=%d\n", kr);
    ((char *)addr)[0] = 'm';
    printf("writable again=%s\n", ((char *)addr)[0] == 'm' ? "yes" : "no");

    kr = vm_deallocate(task, addr, len);
    printf("vm_deallocate kr=%d ok=%s\n", kr, kr == KERN_SUCCESS ? "yes" : "no");

    /* A second, independent allocation must not hand back a mapping that
     * overlaps something we already own. */
    {
        vm_address_t a = 0, b = 0;
        vm_allocate(task, &a, len, VM_FLAGS_ANYWHERE);
        vm_allocate(task, &b, len, VM_FLAGS_ANYWHERE);
        printf("two allocs distinct=%s disjoint=%s\n",
               a != b ? "yes" : "no",
               (a + len <= b || b + len <= a) ? "yes" : "no");
        vm_deallocate(task, a, len);
        vm_deallocate(task, b, len);
    }

    /* ---- mach_absolute_time / mach_timebase_info ---- */
    {
        mach_timebase_info_data_t tb;
        uint64_t t0, t1, elapsed_ns;

        kr = mach_timebase_info(&tb);
        printf("timebase kr=%d sane=%s\n", kr,
               (kr == KERN_SUCCESS && tb.numer > 0 && tb.denom > 0) ? "yes" : "no");

        t0 = mach_absolute_time();
        t1 = mach_absolute_time();
        printf("abs monotonic=%s\n", t1 >= t0 ? "yes" : "no");

        t0 = mach_absolute_time();
        usleep(120000);                       /* 120 ms */
        t1 = mach_absolute_time();
        elapsed_ns = (t1 - t0) * tb.numer / tb.denom;
        /* Wide bounds: this is a scheduling claim, not a benchmark. */
        printf("slept 120ms measured in [100ms,3s]=%s\n",
               (elapsed_ns >= 100000000ull && elapsed_ns <= 3000000000ull) ? "yes" : "no");

        printf("continuous monotonic=%s\n",
               mach_continuous_time() >= t1 - 1000000000ull ? "yes" : "no");
    }

    /* ---- error strings ---- */
    printf("kr0=[%s]\n", mach_error_string(KERN_SUCCESS));
    printf("kr1=[%s]\n", mach_error_string(KERN_INVALID_ADDRESS));
    printf("kr2=[%s]\n", mach_error_string(KERN_PROTECTION_FAILURE));
    printf("kr4=[%s]\n", mach_error_string(KERN_INVALID_ARGUMENT));

    /* ---- port refcounting on the thread port we took above ---- */
    kr = mach_port_deallocate(task, thread);
    printf("port_deallocate kr=%d\n", kr);

    fflush(stdout);
    return 0;
}
