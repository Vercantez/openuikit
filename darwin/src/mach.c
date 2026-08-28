/* mach.c -- the Mach APIs, reimplemented on Linux primitives.
 *
 * The README's bet: "Mach APIs get implemented on top of Linux primitives,
 * which is a bounded list rather than a whole kernel ABI." This file is that
 * bound for plain C programs. Nothing here emulates a Mach trap; vm_allocate
 * is mmap, mach_absolute_time is clock_gettime, and a port name is a token we
 * mint ourselves.
 *
 * WHERE THE FICTION IS, AND WHERE IT IS NOT
 *
 *   Ports are fiction. There is no Mach kernel underneath, so a mach_port_t
 *   here is a name in OUR table. mach_task_self_ is a fixed name; each thread
 *   gets its own name from mach_thread_self(). Passing one of these to a real
 *   Mach message call would be meaningless -- and mach_msg is not implemented,
 *   it aborts (docs/UNIMPLEMENTED.md), rather than pretending to send.
 *
 *   Memory is not fiction. vm_allocate really allocates, vm_protect really
 *   protects, and vm_deallocate really unmaps. Alignment is Darwin's 16 KiB
 *   page, not Linux's, because a guest built for arm64 macOS is entitled to
 *   assume the page it was compiled against.
 *
 *   Time is not fiction either, but its UNIT is ours: mach_absolute_time
 *   returns nanoseconds and mach_timebase_info reports numer = denom = 1. On
 *   Apple silicon the real ratio is 125/3 over a 24 MHz counter. Any correct
 *   program multiplies by numer/denom before believing a duration, and this
 *   fixture-verified pair keeps that arithmetic exact.
 */
#include "dsys.h"

typedef unsigned int  mach_port_t;
typedef int           kern_return_t;
typedef unsigned long vm_address_t;
typedef unsigned long vm_size_t;
typedef int           vm_prot_t;
typedef int           boolean_t;

#define KERN_SUCCESS             0
#define KERN_INVALID_ADDRESS     1
#define KERN_PROTECTION_FAILURE  2
#define KERN_NO_SPACE            3
#define KERN_INVALID_ARGUMENT    4
#define KERN_FAILURE             5
#define KERN_RESOURCE_SHORTAGE   6
#define KERN_NOT_RECEIVER        7
#define KERN_NO_ACCESS           8
#define KERN_MEMORY_FAILURE      9
#define KERN_INVALID_NAME       15
#define KERN_INVALID_TASK       16
#define KERN_INVALID_RIGHT      17
#define KERN_NOT_SUPPORTED      46

#define MACH_PORT_NULL 0

#define VM_FLAGS_FIXED    0x0000
#define VM_FLAGS_ANYWHERE 0x0001

/* VM_PROT_* and Linux's PROT_* agree on READ=1, WRITE=2, EXECUTE=4. */
#define VM_PROT_NONE    0
#define VM_PROT_READ    1
#define VM_PROT_WRITE   2
#define VM_PROT_EXECUTE 4

#define L_PROT_READ  1
#define L_PROT_WRITE 2
#define L_PROT_EXEC  4
#define L_MAP_PRIVATE 0x02
#define L_MAP_FIXED   0x10
#define L_MAP_ANON    0x20
#define L_MAP_FAILED  ((void *)-1)

/* ------------------------------------------------------------------ ports */

/* 0x103 is what a real task port name usually looks like on Darwin; the value
 * carries no meaning here beyond being non-null and recognisable in a dump. */
EXPORT mach_port_t mach_task_self_ = 0x103;
EXPORT mach_port_t mach_host_self_ = 0x203;

EXPORT mach_port_t mach_task_self(void) { return mach_task_self_; }
EXPORT mach_port_t mach_host_self(void) { return mach_host_self_; }
EXPORT mach_port_t task_self_trap(void) { return mach_task_self_; }

/* Thread port names: one per thread, minted on demand and remembered in a
 * pthread key so that two calls on the same thread agree and two threads
 * disagree -- which is the only property portable code relies on. */
static unsigned thread_key;
static int thread_key_state;
static unsigned thread_port_next = 0x303;

static void thread_key_init(void)
{
    int expect = 0;
    if (__atomic_load_n(&thread_key_state, __ATOMIC_ACQUIRE) == 2) return;
    if (__atomic_compare_exchange_n(&thread_key_state, &expect, 1, 0,
                                    __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE)) {
        if (glibc_pthread_key_create(&thread_key, NULL) != 0)
            mr_bail("pthread_key_create failed while minting a thread port");
        __atomic_store_n(&thread_key_state, 2, __ATOMIC_RELEASE);
        return;
    }
    while (__atomic_load_n(&thread_key_state, __ATOMIC_ACQUIRE) != 2)
        glibc_sched_yield();
}

EXPORT mach_port_t mach_thread_self(void)
{
    unsigned long v;
    thread_key_init();
    v = (unsigned long)glibc_pthread_getspecific(thread_key);
    if (!v) {
        v = __atomic_fetch_add(&thread_port_next, 4, __ATOMIC_RELAXED);
        glibc_pthread_setspecific(thread_key, (void *)v);
    }
    return (mach_port_t)v;
}

/* pthread_mach_thread_np: a pthread_t to its Mach thread port.
 *
 * WANTED BY libc++abi, not by libunwind. This is the last open consumer of
 * foundation-scope's pthread_mach_thread_np sweep, which covered ICU (zero
 * references, structurally) and our libc++ but could not reach libc++abi or
 * libunwind because those artifacts were gone. Now measured on both:
 * libunwind's entire external surface is three pthread_rwlock calls, two
 * _dyld_* calls and plain libc -- no Mach anything. libc++abi's cxa_guard DOES
 * need it, for PlatformThreadID() (cxa_guard_impl.h:162), which it uses to
 * detect a thread recursively initialising the same function-local static --
 * i.e. as a thread IDENTITY, never as a port to send on.
 *
 * So mach_thread_self()'s name is exactly the right answer, and this is a
 * translation rather than a stub. It is deliberately limited to the CURRENT
 * thread: our port names live in thread-local storage, so we simply do not
 * know another thread's, and Darwin's version does. Returning something
 * plausible for another thread would break the one property the caller
 * depends on -- that two live threads never share an id. */
EXPORT mach_port_t pthread_mach_thread_np(void *thread)
{
    if (thread != (void *)glibc_pthread_self())
        mr_bail("pthread_mach_thread_np was asked for a thread other than the caller. "
                "machorun mints port names into thread-local storage, so only the "
                "current thread's is knowable; answering for another thread would "
                "have to invent a name, and two threads sharing one is exactly what "
                "the callers use this to rule out.");
    return mach_thread_self();
}

/* Reference counting on names we minted. There is no kernel to tell, so this
 * is a validity check rather than a release: a name we never handed out is an
 * error the caller should hear about, not a silent success. */
EXPORT kern_return_t mach_port_deallocate(mach_port_t task, mach_port_t name)
{
    if (task != mach_task_self_) return KERN_INVALID_TASK;
    if (name == MACH_PORT_NULL) return KERN_INVALID_NAME;
    if (name == mach_task_self_ || name == mach_host_self_) return KERN_SUCCESS;
    if (name >= 0x303 && name < __atomic_load_n(&thread_port_next, __ATOMIC_RELAXED))
        return KERN_SUCCESS;
    return KERN_INVALID_NAME;
}

EXPORT kern_return_t mach_port_mod_refs(mach_port_t task, mach_port_t name, int right, int delta)
{
    (void)right; (void)delta;
    return mach_port_deallocate(task, name);
}

/* --------------------------------------------------------- virtual memory */

static unsigned long round_page(unsigned long n)
{
    return (n + (MR_DARWIN_PAGE - 1)) & ~(MR_DARWIN_PAGE - 1);
}

EXPORT kern_return_t vm_allocate(mach_port_t task, vm_address_t *addr, vm_size_t size, int flags)
{
    unsigned long want, got, base, end;

    if (task != mach_task_self_) return KERN_INVALID_TASK;
    if (!addr) return KERN_INVALID_ARGUMENT;
    if (size == 0) { if (flags & VM_FLAGS_ANYWHERE) *addr = 0; return KERN_SUCCESS; }

    want = round_page(size);

    if (!(flags & VM_FLAGS_ANYWHERE)) {
        void *p = glibc_mmap((void *)(*addr & ~(MR_DARWIN_PAGE - 1)), want,
                             L_PROT_READ | L_PROT_WRITE,
                             L_MAP_PRIVATE | L_MAP_ANON | L_MAP_FIXED, -1, 0);
        if (p == L_MAP_FAILED) return KERN_NO_SPACE;
        *addr = (vm_address_t)p;
        return KERN_SUCCESS;
    }

    /* Over-map by one Darwin page and trim, so the result is 16 KiB-aligned
     * even on a 4 KiB-page kernel. A guest compiled for arm64 macOS may hold
     * the page size in its head; handing it a 4 KiB-aligned "page" is the kind
     * of difference that shows up ten thousand lines later. */
    got = (unsigned long)glibc_mmap(NULL, want + MR_DARWIN_PAGE,
                                    L_PROT_READ | L_PROT_WRITE,
                                    L_MAP_PRIVATE | L_MAP_ANON, -1, 0);
    if (got == (unsigned long)L_MAP_FAILED) return KERN_NO_SPACE;

    base = round_page(got);
    end  = base + want;
    if (base > got) glibc_munmap((void *)got, base - got);
    if (end < got + want + MR_DARWIN_PAGE)
        glibc_munmap((void *)end, got + want + MR_DARWIN_PAGE - end);

    *addr = (vm_address_t)base;
    return KERN_SUCCESS;
}

EXPORT kern_return_t vm_deallocate(mach_port_t task, vm_address_t addr, vm_size_t size)
{
    if (task != mach_task_self_) return KERN_INVALID_TASK;
    if (size == 0) return KERN_SUCCESS;
    if (addr & (MR_DARWIN_PAGE - 1)) return KERN_INVALID_ADDRESS;
    if (glibc_munmap((void *)addr, round_page(size)) != 0) return KERN_INVALID_ADDRESS;
    return KERN_SUCCESS;
}

EXPORT kern_return_t vm_protect(mach_port_t task, vm_address_t addr, vm_size_t size,
                                boolean_t set_maximum, vm_prot_t prot)
{
    if (task != mach_task_self_) return KERN_INVALID_TASK;
    if (set_maximum)
        mr_bail("vm_protect(set_maximum=TRUE): Linux has no maximum-protection "
                "concept, so raising or lowering a ceiling cannot be honoured");
    if (size == 0) return KERN_SUCCESS;
    if (glibc_mprotect((void *)(addr & ~(MR_DARWIN_PAGE - 1)), round_page(size), prot) != 0)
        return KERN_PROTECTION_FAILURE;
    return KERN_SUCCESS;
}

/* ------------------------------------------------------------- vm_copy
 *
 * Darwin's in-task virtual copy. MEASURED against macOS/arm64 rather than read
 * off a summary, because every summary of this call is wrong about it
 * (tests/src/vm_copy.c is the measurement, tests/expected/vm_copy.stdout the
 * record):
 *
 *   - NO page-alignment requirement, on either address or the size. An
 *     unaligned 100-byte copy succeeds and touches exactly 100 bytes.
 *   - OVERLAPPING regions get memmove semantics, not a forward byte copy. The
 *     fixture's checksum tells the two apart (7176144 against 7176128), which
 *     is why it prints a checksum instead of "it copied".
 *   - a PROT_NONE, read-only or unmapped region gives KERN_INVALID_ADDRESS,
 *     NOT KERN_PROTECTION_FAILURE. The name of the error is the part a reader
 *     would have got wrong.
 *   - size 0 succeeds.
 *
 * So the implementation is: check both ranges, then memmove. The check is what
 * makes it a translation rather than a memmove with a Mach signature -- Darwin
 * RETURNS an error for an unmapped address and a bare memmove would take a
 * SIGSEGV, which is not a worse error code, it is a different outcome.
 *
 * WHY /proc/self/maps AND NOT SOMETHING CHEAPER. msync(2) and mincore(2) both
 * report unmapped ranges, and neither can see PROTECTION -- so a read-only
 * destination would pass the check and then fault inside memmove. The three
 * protection cases are a third of what was measured. The cost is one open/read
 * of /proc/self/maps per call, which is real and is the reason
 * Platform.copyMemoryPages' memmove fallback is not obviously worse than this;
 * correctness first, and the cost is named here rather than discovered.
 */

/* Fill `have` with what /proc/self/maps says covers [addr, addr+len):
 * returns 0 if any byte of the range is not in a mapping. Bits are the same
 * VM_PROT_* / PROT_* values, which agree on both systems (READ 1, WRITE 2). */
static int mr_range_prot(unsigned long addr, unsigned long len, int *have)
{
    char buf[8192];
    char line[512];
    unsigned nline = 0;
    unsigned long cur = addr, end = addr + len;
    int fd, prot = 7, covered = 0;
    ssize_t n;

    *have = 0;
    if (len == 0) return 1;
    if (end < addr) return 0;                    /* wrapped: never mapped */

    fd = glibc_open("/proc/self/maps", 0 /* O_RDONLY, 0 on both */, 0);
    if (fd < 0)
        mr_bail("vm_copy: /proc/self/maps is unreadable, so an unmapped "
                "address cannot be distinguished from a mapped one. Refusing "
                "to guess: the wrong answer here is a SIGSEGV where Darwin "
                "returns KERN_INVALID_ADDRESS");

    /* Streamed a line at a time rather than slurped, because a real app's map
     * is far larger than any buffer worth reserving here, and a truncated read
     * would report a mapped address as unmapped -- a wrong answer that looks
     * like a finding. */
    while (!covered && (n = glibc_read(fd, buf, sizeof buf)) > 0) {
        for (ssize_t i = 0; i < n && !covered; i++) {
            if (buf[i] != '\n') {
                if (nline < sizeof line - 1) line[nline++] = buf[i];
                continue;
            }
            line[nline] = 0;
            nline = 0;
            {
                char *p = line, *q;
                unsigned long s = glibc_strtoul(p, &q, 16);
                unsigned long e;
                int lprot = 0;
                if (q == p || *q != '-') continue;
                e = glibc_strtoul(q + 1, &q, 16);
                if (*q != ' ') continue;
                q++;
                if (q[0] == 'r') lprot |= 1;
                if (q[1] == 'w') lprot |= 2;
                if (q[2] == 'x') lprot |= 4;
                if (e <= cur) continue;          /* entirely before us */
                if (s > cur) break;              /* a HOLE at cur */
                prot &= lprot;
                cur = e;
                if (cur >= end) covered = 1;
            }
        }
    }
    glibc_close(fd);
    if (!covered) return 0;
    *have = prot;
    return 1;
}

EXPORT kern_return_t vm_copy(mach_port_t task, vm_address_t src, vm_size_t size,
                             vm_address_t dst)
{
    int have = 0;

    if (task != mach_task_self_) return KERN_INVALID_TASK;
    if (size == 0) return KERN_SUCCESS;          /* measured: Darwin returns 0 */
    if (!mr_range_prot(src, size, &have) || !(have & 1))
        return KERN_INVALID_ADDRESS;             /* measured: 1, not 2 */
    if (!mr_range_prot(dst, size, &have) || !(have & 2))
        return KERN_INVALID_ADDRESS;
    glibc_memmove((void *)dst, (const void *)src, size);
    return KERN_SUCCESS;
}

/* The mach_vm_* family is the same thing with 64-bit-wide types; on arm64
 * those are the same types. */
EXPORT kern_return_t mach_vm_allocate(mach_port_t t, uint64_t *a, uint64_t s, int f)
{ return vm_allocate(t, (vm_address_t *)a, (vm_size_t)s, f); }
EXPORT kern_return_t mach_vm_deallocate(mach_port_t t, uint64_t a, uint64_t s)
{ return vm_deallocate(t, (vm_address_t)a, (vm_size_t)s); }
EXPORT kern_return_t mach_vm_protect(mach_port_t t, uint64_t a, uint64_t s, boolean_t m, vm_prot_t p)
{ return vm_protect(t, (vm_address_t)a, (vm_size_t)s, m, p); }

EXPORT kern_return_t host_page_size(mach_port_t host, vm_size_t *out)
{
    if (host != mach_host_self_) return KERN_INVALID_ARGUMENT;
    *out = MR_DARWIN_PAGE;
    return KERN_SUCCESS;
}
EXPORT int getpagesize(void) { return (int)MR_DARWIN_PAGE; }
EXPORT vm_size_t vm_page_size = MR_DARWIN_PAGE;
EXPORT unsigned long vm_page_mask = MR_DARWIN_PAGE - 1;
EXPORT int vm_page_shift = 14;

/* -------------------------------------------------------------------- time */

#define L_CLOCK_MONOTONIC 1
#define L_CLOCK_BOOTTIME  7

struct l_timespec { long sec, nsec; };

EXPORT uint64_t mach_absolute_time(void)
{
    struct l_timespec ts = { 0, 0 };
    glibc_clock_gettime(L_CLOCK_MONOTONIC, &ts);
    return (uint64_t)ts.sec * 1000000000ull + (uint64_t)ts.nsec;
}

/* Darwin's continuous time keeps counting while the machine is asleep; that is
 * exactly Linux's CLOCK_BOOTTIME. */
EXPORT uint64_t mach_continuous_time(void)
{
    struct l_timespec ts = { 0, 0 };
    glibc_clock_gettime(L_CLOCK_BOOTTIME, &ts);
    return (uint64_t)ts.sec * 1000000000ull + (uint64_t)ts.nsec;
}
EXPORT uint64_t mach_approximate_time(void) { return mach_absolute_time(); }
EXPORT uint64_t mach_continuous_approximate_time(void) { return mach_continuous_time(); }

struct mach_timebase_info { uint32_t numer, denom; };

EXPORT kern_return_t mach_timebase_info(struct mach_timebase_info *info)
{
    if (!info) return KERN_INVALID_ARGUMENT;
    info->numer = 1;      /* our absolute-time unit IS the nanosecond */
    info->denom = 1;
    return KERN_SUCCESS;
}

/* ------------------------------------------------------------ error strings
 * The text is Apple's, recorded from macOS (tests/expected/mach.stdout is
 * the check). A code we do not know says so instead of inventing prose. */
EXPORT const char *mach_error_string(kern_return_t kr)
{
    switch (kr) {
    case KERN_SUCCESS:            return "(os/kern) successful";
    case KERN_INVALID_ADDRESS:    return "(os/kern) invalid address";
    case KERN_PROTECTION_FAILURE: return "(os/kern) protection failure";
    case KERN_NO_SPACE:           return "(os/kern) no space available";
    case KERN_INVALID_ARGUMENT:   return "(os/kern) invalid argument";
    case KERN_FAILURE:            return "(os/kern) failure";
    case KERN_RESOURCE_SHORTAGE:  return "(os/kern) resource shortage";
    case KERN_NOT_RECEIVER:       return "(os/kern) not receiver";
    case KERN_NO_ACCESS:          return "(os/kern) no access";
    case KERN_MEMORY_FAILURE:     return "(os/kern) memory failure";
    case KERN_INVALID_NAME:       return "(os/kern) invalid name";
    case KERN_INVALID_TASK:       return "(os/kern) invalid task";
    case KERN_INVALID_RIGHT:      return "(os/kern) invalid right";
    case KERN_NOT_SUPPORTED:      return "(os/kern) not supported";
    default:                      return "(machorun) kern_return_t with no recorded Apple text";
    }
}

EXPORT void mach_error(const char *prefix, kern_return_t kr)
{
    if (prefix) mr_say(prefix);
    mr_say(" ");
    mr_say(mach_error_string(kr));
    mr_say("\n");
}

/* ---------------------------------------------------------------- refusals
 * Everything below is reachable only by a program that wants real Mach IPC.
 * There is no kernel here to talk to, so these abort with the reason rather
 * than returning a plausible-looking KERN_SUCCESS. See docs/UNIMPLEMENTED.md. */

EXPORT kern_return_t mach_msg(void *msg, int option, unsigned send_size, unsigned rcv_size,
                              mach_port_t rcv_name, unsigned timeout, mach_port_t notify)
{
    (void)msg; (void)option; (void)send_size; (void)rcv_size;
    (void)rcv_name; (void)timeout; (void)notify;
    mr_bail("mach_msg: there is no Mach kernel under machorun. Ports here are "
            "names in our own table, so a message has nowhere to go");
}

EXPORT kern_return_t mach_port_allocate(mach_port_t task, int right, mach_port_t *name)
{
    (void)task; (void)right; (void)name;
    mr_bail("mach_port_allocate: machorun mints only the task, host and thread "
            "port names it knows how to answer for");
}

EXPORT kern_return_t task_for_pid(mach_port_t target, int pid, mach_port_t *out)
{
    (void)target; (void)pid; (void)out;
    mr_bail("task_for_pid: no Mach kernel, and no cross-process task ports");
}

EXPORT kern_return_t task_info(mach_port_t task, unsigned flavor, void *info, unsigned *count)
{
    (void)task; (void)flavor; (void)info; (void)count;
    mr_bail("task_info: the flavor structs are kernel ABI, and machorun has no kernel "
            "to fill them from");
}
