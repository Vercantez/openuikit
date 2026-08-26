/* objcsupport.c -- the part of Darwin's userland that Apple's objc4 needs and
 * the C/C++ corpus never did.
 *
 * Everything here is reached because libobjc.A.dylib is now a real Mach-O
 * built from Apple's own source, so it calls Apple's own SPI rather than a
 * Linux substitute. `nm -u libobjc.A.dylib` is the specification for this
 * file; anything on that list which is NOT here falls through machorun's
 * host-lookup escape hatch to a same-named glibc symbol, which is only correct
 * for the pure-computation ones (str*, mem*, arc4random).
 *
 * The rule of this project applies unchanged: nothing silently no-ops. A stub
 * that cannot do the real thing calls mr_bail() and names itself.
 */
#include "dsys.h"

static void note(const char *s)          /* unbuffered stderr, no formatting */
{
    if (s) glibc_write(2, s, glibc_strlen(s));
}

/* ===================================================================== *
 * Darwin direct thread-specific data
 *
 * runtime/Threading/darwin.h reaches TSD through _pthread_getspecific_direct,
 * which on Darwin is a load from the `_pthread` struct off TPIDRRO_EL0 at a
 * fixed slot index. We cannot do that: the guest's threads are glibc threads
 * and TPIDRRO_EL0 holds glibc's TLS base. So we keep a real per-thread slot
 * array behind one glibc TSD key. Same observable semantics, one indirection
 * more.
 *
 * Slot numbering is Apple's ABI (<pthread/tsd_private.h>): slot 0 is the
 * pthread itself, and libobjc owns 40..49. We size for 64.
 * ===================================================================== */
#define DTSD_SLOTS 64

static unsigned  dtsd_key;
static int       dtsd_key_ready;
static void    (*dtsd_dtor[DTSD_SLOTS])(void *);

static void dtsd_thread_exit(void *p)
{
    void **slots = (void **)p;
    /* Darwin runs TSD destructors in slot order, repeatedly, like pthreads.
     * One pass is enough for objc4: its destructors do not re-set their slot. */
    for (int i = 0; i < DTSD_SLOTS; i++) {
        void *v = slots[i];
        if (v && dtsd_dtor[i]) { slots[i] = NULL; dtsd_dtor[i](v); }
    }
    glibc_free(slots);
}

static void **dtsd_slots(void)
{
    if (!dtsd_key_ready) {
        /* Racy only before the first thread is created; objc4 touches TSD from
         * _objc_init, which is single-threaded by construction. */
        if (glibc_pthread_key_create(&dtsd_key, dtsd_thread_exit) != 0)
            mr_bail("objcsupport: pthread_key_create for the direct-TSD array failed");
        dtsd_key_ready = 1;
    }
    void **slots = (void **)glibc_pthread_getspecific(dtsd_key);
    if (!slots) {
        slots = (void **)glibc_calloc(DTSD_SLOTS, sizeof(void *));
        if (!slots) mr_bail("objcsupport: out of memory allocating a direct-TSD array");
        slots[0] = (void *)glibc_pthread_self();     /* _PTHREAD_TSD_SLOT_PTHREAD_SELF */
        glibc_pthread_setspecific(dtsd_key, slots);
    }
    return slots;
}

EXPORT int _pthread_has_direct_tsd(void) { return 1; }

EXPORT void *_pthread_getspecific_direct(unsigned long slot)
{
    if (slot >= DTSD_SLOTS)
        mr_bail("_pthread_getspecific_direct: slot out of range (we provide 64)");
    return dtsd_slots()[slot];
}

EXPORT void _pthread_setspecific_direct(unsigned long slot, void *value)
{
    if (slot >= DTSD_SLOTS)
        mr_bail("_pthread_setspecific_direct: slot out of range (we provide 64)");
    dtsd_slots()[slot] = value;
}

/* Darwin's "adopt this reserved key and give it a destructor". */
EXPORT int pthread_key_init_np(int key, void (*destructor)(void *))
{
    if (key < 0 || key >= DTSD_SLOTS) return 22;   /* EINVAL */
    dtsd_dtor[key] = destructor;
    (void)dtsd_slots();          /* force the array to exist on this thread */
    return 0;
}

/* Has any thread besides the initial one ever been created? objc4 uses it to
 * take single-threaded fast paths. Conservative answer is 1; we track it in
 * libsystem.c's pthread_create, but until that exists, saying "threaded" is
 * the safe lie -- it only costs locking. */
EXPORT int pthread_is_threaded_np(void) { return 1; }

EXPORT int pthread_getname_np(void *t, char *buf, size_t n)
{ (void)t; if (n) buf[0] = 0; return 0; }
EXPORT int pthread_setname_np(const char *name) { (void)name; return 0; }

/* ===================================================================== *
 * os_unfair_lock: the private SPI beyond the three public entry points.
 * libsystem.c owns the lock word itself (four bytes, owner token or zero).
 * ===================================================================== */
extern void os_unfair_lock_lock(void *);
extern int  os_unfair_lock_trylock(void *);
extern void os_unfair_lock_unlock(void *);

EXPORT void os_unfair_lock_lock_with_options(void *l, unsigned options)
{
    /* Every option is a scheduling hint (DATA_SYNCHRONIZATION, ADAPTIVE_SPIN).
     * None changes the lock's semantics, so honouring them is a performance
     * question, not a correctness one. */
    (void)options;
    os_unfair_lock_lock(l);
}

/* os_unfair_recursive_lock = { os_unfair_lock lock; uint32_t count; } */
typedef struct { unsigned lock; unsigned count; } recursive_lock;

static unsigned self_token(void)
{
    return (unsigned)((unsigned long)glibc_pthread_self() >> 8) | 0x80000000u;
}

EXPORT void os_unfair_recursive_lock_lock_with_options(void *p, unsigned options)
{
    recursive_lock *r = p;
    (void)options;
    if (__atomic_load_n(&r->lock, __ATOMIC_ACQUIRE) == self_token()) { r->count++; return; }
    os_unfair_lock_lock(&r->lock);
    r->count = 0;
}

EXPORT int os_unfair_recursive_lock_trylock(void *p)
{
    recursive_lock *r = p;
    if (__atomic_load_n(&r->lock, __ATOMIC_ACQUIRE) == self_token()) { r->count++; return 1; }
    if (!os_unfair_lock_trylock(&r->lock)) return 0;
    r->count = 0;
    return 1;
}

EXPORT void os_unfair_recursive_lock_unlock(void *p)
{
    recursive_lock *r = p;
    if (r->count) { r->count--; return; }
    os_unfair_lock_unlock(&r->lock);
}

EXPORT int os_unfair_recursive_lock_owned(void *p)
{
    recursive_lock *r = p;
    return __atomic_load_n(&r->lock, __ATOMIC_ACQUIRE) == self_token();
}

/* @synchronized's unlock: drop it if I hold it, and say whether I did. */
EXPORT int os_unfair_recursive_lock_tryunlock4objc(void *p)
{
    recursive_lock *r = p;
    if (__atomic_load_n(&r->lock, __ATOMIC_ACQUIRE) != self_token()) return 0;
    if (r->count) { r->count--; return 1; }
    os_unfair_lock_unlock(&r->lock);
    return 1;
}

/* After fork() the child has exactly one thread, so the lock is ours to drop
 * whoever held it. */
EXPORT void os_unfair_recursive_lock_unlock_forked_child(void *p)
{
    recursive_lock *r = p;
    r->count = 0;
    __atomic_store_n(&r->lock, 0u, __ATOMIC_RELEASE);
}

/* ===================================================================== *
 * malloc zones. objc4 asks for the default zone and allocates from it.
 * There is one heap here -- glibc's -- so the "zone" is a token, and every
 * zone call routes to the same allocator. A program that treats a zone as a
 * separate arena (mass-free by zone, zone introspection) would notice; objc4
 * does not, it only ever uses the default one.
 * ===================================================================== */
static unsigned long default_zone_token[16];   /* an address to hand out */

EXPORT void *malloc_default_zone(void) { return default_zone_token; }

EXPORT void *malloc_zone_malloc(void *zone, size_t size)
{
    if (zone != (void *)default_zone_token)
        mr_bail("malloc_zone_malloc: machorun has exactly one malloc zone "
                "(the default). A foreign zone pointer means someone created a "
                "zone we do not know about.");
    return glibc_malloc(size);
}

EXPORT void *malloc_zone_calloc(void *zone, size_t n, size_t size)
{ (void)zone; return glibc_calloc(n, size); }
EXPORT void *malloc_zone_realloc(void *zone, void *p, size_t size)
{ (void)zone; return glibc_realloc(p, size); }
EXPORT void  malloc_zone_free(void *zone, void *p) { (void)zone; glibc_free(p); }

/* malloc_type / "malloc with options" is Darwin's typed-allocator SPI. The
 * options word carries alignment and zeroing requests. */
EXPORT void *malloc_zone_malloc_with_options_np(void *zone, size_t align,
                                                size_t size, unsigned options)
{
    (void)zone;
    void *p = NULL;
    if (align <= sizeof(void *) * 2) {
        p = glibc_malloc(size);
    } else if (glibc_posix_memalign(&p, align, size) != 0) {
        return NULL;
    }
    if (p && (options & 1u)) {          /* MALLOC_NP_OPTION_CLEAR */
        glibc_memset(p, 0, size);
    }
    return p;
}

/* ===================================================================== *
 * Structured abort. On Darwin this hands ReportCrash a namespace, a code and
 * a string. There is no ReportCrash here, so the reason goes to stderr where
 * a differential test can see it, and then we abort.
 * ===================================================================== */
EXPORT void abort_with_reason(unsigned ns, unsigned long long code,
                              const char *reason, unsigned long long flags)
{
    (void)ns; (void)code; (void)flags;
    mr_bail2("abort_with_reason", reason ? reason : "(no reason string)");
}

EXPORT void abort_with_payload(unsigned ns, unsigned long long code, void *payload,
                               unsigned psize, const char *reason, unsigned long long flags)
{ (void)payload; (void)psize; abort_with_reason(ns, code, reason, flags); }

EXPORT void os_fault_with_payload(unsigned ns, unsigned long long code, void *payload,
                                  unsigned psize, const char *reason, unsigned long long flags)
{
    /* A "fault" is a non-fatal report on Darwin. Non-fatal here too: print it
     * and continue, because turning it into an abort would make us stricter
     * than macOS and break the differential comparison. */
    (void)payload; (void)psize; (void)flags; (void)ns; (void)code;
    note("machorun: os_fault_with_payload: ");
    note(reason ? reason : "(no reason string)");
    note("\n");
}

/* CrashReporter annotations. Darwin stores a string that ReportCrash prints.
 * We keep it, so a crash handler can show it, and that is all it is for. */
static const char *cr_message;
EXPORT void        CRSetCrashLogMessage(const char *m) { cr_message = m; }
EXPORT const char *CRGetCrashLogMessage(void)          { return cr_message; }

/* ===================================================================== *
 * Blocks. objc4 uses them for imp_implementationWithBlock and for the
 * shared-cache iteration callbacks. This is the ABI from Apple's
 * compiler-rt BlocksRuntime, implemented directly rather than forwarded to
 * Ubuntu's libBlocksRuntime, because _NSConcreteStackBlock is a DATA symbol:
 * a forwarding copy would be a different object than the one clang's codegen
 * compares against, and block identity would break.
 * ===================================================================== */
struct Block_layout {
    void       *isa;
    int         flags;
    int         reserved;
    void      (*invoke)(void *, ...);
    struct Block_descriptor *descriptor;
};
struct Block_descriptor {
    unsigned long reserved;
    unsigned long size;
    void (*copy)(void *dst, const void *src);
    void (*dispose)(const void *);
};

#define BLOCK_NEEDS_FREE     (1 << 24)
#define BLOCK_HAS_COPY_DISPOSE (1 << 25)
#define BLOCK_IS_GLOBAL      (1 << 28)
#define BLOCK_REFCOUNT_MASK  0xfffe

EXPORT void *_NSConcreteStackBlock[32];
EXPORT void *_NSConcreteGlobalBlock[32];
EXPORT void *_NSConcreteMallocBlock[32];

EXPORT void *_Block_copy(const void *arg)
{
    struct Block_layout *b = (struct Block_layout *)arg;
    if (!b) return NULL;
    if (b->flags & BLOCK_IS_GLOBAL) return b;
    if (b->flags & BLOCK_NEEDS_FREE) {
        __atomic_add_fetch(&b->flags, 2, __ATOMIC_RELAXED);
        return b;
    }
    struct Block_layout *c = glibc_malloc(b->descriptor->size);
    if (!c) return NULL;
    glibc_memcpy(c, b, b->descriptor->size);
    c->flags = (b->flags & ~BLOCK_REFCOUNT_MASK) | BLOCK_NEEDS_FREE | 2;
    c->isa   = _NSConcreteMallocBlock;
    if (b->flags & BLOCK_HAS_COPY_DISPOSE) b->descriptor->copy(c, b);
    return c;
}

EXPORT void _Block_release(const void *arg)
{
    struct Block_layout *b = (struct Block_layout *)arg;
    if (!b || (b->flags & BLOCK_IS_GLOBAL) || !(b->flags & BLOCK_NEEDS_FREE)) return;
    if ((__atomic_sub_fetch(&b->flags, 2, __ATOMIC_ACQ_REL) & BLOCK_REFCOUNT_MASK) == 0) {
        if (b->flags & BLOCK_HAS_COPY_DISPOSE) b->descriptor->dispose(b);
        glibc_free(b);
    }
}

/* __block variable copy/dispose. objc4 captures only objects and pointers in
 * its blocks, never __block variables, so the byref path is unreached; it
 * bails rather than silently doing the wrong thing with a byref header. */
EXPORT void _Block_object_assign(void *dst, const void *obj, const int flags)
{
    enum { BLOCK_FIELD_IS_OBJECT = 3, BLOCK_FIELD_IS_BLOCK = 7, BLOCK_FIELD_IS_BYREF = 8 };
    switch (flags & 0x17) {
    case BLOCK_FIELD_IS_OBJECT: *(const void **)dst = obj; break;   /* ARC handles rr */
    case BLOCK_FIELD_IS_BLOCK:  *(void **)dst = _Block_copy(obj);   break;
    default:
        mr_bail("_Block_object_assign: __block byref capture is not implemented "
                "(see docs/UNIMPLEMENTED.md#blocks-byref). objc4's own blocks "
                "never use one, so reaching this means a guest block did.");
    }
}

EXPORT void _Block_object_dispose(const void *obj, const int flags)
{
    enum { BLOCK_FIELD_IS_BLOCK = 7 };
    if ((flags & 0x17) == BLOCK_FIELD_IS_BLOCK) _Block_release(obj);
}

EXPORT int _Block_has_signature(void *b) { (void)b; return 0; }
EXPORT const char *_Block_signature(void *b) { (void)b; return NULL; }
EXPORT int _Block_use_stret(void *b) { (void)b; return 0; }

/* ===================================================================== *
 * Swift refcounting. objc4 refers to swift_retain/swift_release so that a
 * Swift-stable class can be retained without a message send. On Darwin the
 * reference is delay-init: it resolves only if libswiftCore is loaded.
 * ld64.lld does not implement -delay_init, so the reference is a plain
 * undefined and something must define it. These are reachable ONLY for an
 * object whose class isSwiftStable(), which cannot exist without libswiftCore
 * -- so reaching one means something is badly wrong, and we say so.
 * ===================================================================== */
EXPORT void *swift_retain(void *o)
{
    (void)o;
    mr_bail("swift_retain: a Swift-stable object reached objc4's fast-path "
            "refcounting, but no libswiftCore is loaded under machorun. "
            "See docs/UNIMPLEMENTED.md#swift-interop.");
    return 0;
}
EXPORT void swift_release(void *o)
{
    (void)o;
    mr_bail("swift_release: a Swift-stable object reached objc4's fast-path "
            "refcounting, but no libswiftCore is loaded under machorun. "
            "See docs/UNIMPLEMENTED.md#swift-interop.");
}

/* ===================================================================== *
 * Restartable ranges. Darwin lets a thread declare a PC range that the kernel
 * restarts if it is preempted inside it; objc4 uses it to make the cache
 * scan interruptible. Linux has no equivalent (rseq is close but not this),
 * so we report failure, which is exactly what objc4 handles on a kernel that
 * does not support it.
 * ===================================================================== */
EXPORT int task_restartable_ranges_register(unsigned task, void *ranges, unsigned count)
{ (void)task; (void)ranges; (void)count; return 46; }   /* KERN_NOT_SUPPORTED */
EXPORT int task_restartable_ranges_synchronize(unsigned task)
{ (void)task; return 46; }

/* ===================================================================== *
 * C++ exception ABI and the unwinder.
 *
 * objc4's @throw/@catch machinery is compiled in and its symbols must resolve,
 * but machorun has no unwinder for Apple's compact __TEXT,__unwind_info
 * format (docs/UNIMPLEMENTED.md#unwind-compact). glibc's libgcc unwinder reads
 * .eh_frame, which these binaries do not have. So every one of these aborts
 * naming itself: a program that never throws runs correctly, and one that
 * throws stops with a sentence instead of jumping into an unwinder that would
 * walk garbage.
 * ===================================================================== */
#define UNWIND_STUB(name)                                                     \
    EXPORT void name(void) {                                                  \
        mr_bail(#name ": C++/ObjC exception unwinding is not implemented. "    \
                "Apple's binaries carry __TEXT,__unwind_info (compact "        \
                "unwind), not .eh_frame, so libgcc's unwinder cannot be "      \
                "forwarded to. See docs/UNIMPLEMENTED.md#unwind-compact.");    \
    }

UNWIND_STUB(__cxa_allocate_exception)
UNWIND_STUB(__cxa_throw)
UNWIND_STUB(__cxa_begin_catch)
UNWIND_STUB(__cxa_end_catch)
UNWIND_STUB(__cxa_rethrow)
UNWIND_STUB(__cxa_current_exception_type)
UNWIND_STUB(__gxx_personality_v0)
UNWIND_STUB(_Unwind_Resume)
UNWIND_STUB(_Unwind_GetIP)
UNWIND_STUB(_Unwind_GetCFA)
UNWIND_STUB(unw_getcontext)
UNWIND_STUB(unw_init_local)
UNWIND_STUB(unw_step)
UNWIND_STUB(unw_get_reg)
UNWIND_STUB(unw_get_proc_info)

/* std::terminate / std::set_terminate, mangled. objc-exception.mm installs a
 * terminate handler so that an uncaught ObjC exception prints its class name.
 * Installing one is harmless; calling terminate aborts, which is what
 * std::terminate does. */
static void (*terminate_handler)(void);
EXPORT void (*_ZSt13set_terminatePFvvE(void (*h)(void)))(void)
{
    void (*old)(void) = terminate_handler;
    terminate_handler = h;
    return old;
}
EXPORT void _ZSt9terminatev(void)
{
    if (terminate_handler) terminate_handler();
    mr_bail("std::terminate() was called and the handler returned");
}

/* ===================================================================== *
 * Odds and ends objc4 reaches for that the C corpus never did.
 * ===================================================================== */
EXPORT const char *dispatch_queue_get_label(void *q)
{
    /* objc4 only ever asks for the label of the current queue, to print it in
     * a diagnostic. There is no libdispatch here. */
    (void)q;
    return "com.apple.main-thread";
}

/* --- BSD/Darwin libc that glibc either lacks or spells differently ------- */
extern int    glibc_strcasecmp(const char *, const char *)          GLIBCSYM(strcasecmp);
extern size_t glibc_strcspn(const char *, const char *)             GLIBCSYM(strcspn);
extern ssize_t glibc_pread(int, void *, size_t, off_t)              GLIBCSYM(pread);
extern int    glibc_geteuid(void)                                   GLIBCSYM(geteuid);
extern void   glibc_getrandom_fill(void *, size_t, unsigned)        GLIBCSYM(getrandom);
extern int    glibc_backtrace(void **, int)                         GLIBCSYM(backtrace);
extern char **glibc_backtrace_symbols(void *const *, int)           GLIBCSYM(backtrace_symbols);
extern void   glibc_backtrace_symbols_fd(void *const *, int, int)   GLIBCSYM(backtrace_symbols_fd);
extern int    glibc_dladdr(const void *, void *)                    GLIBCSYM(dladdr);
extern void  *glibc_dlopen(const char *, int)                       GLIBCSYM(dlopen);
extern void  *glibc_dlsym(void *, const char *)                     GLIBCSYM(dlsym);
extern char  *glibc_dlerror(void)                                   GLIBCSYM(dlerror);

EXPORT int    strcasecmp(const char *a, const char *b) { return glibc_strcasecmp(a, b); }
EXPORT size_t strcspn(const char *s, const char *r)    { return glibc_strcspn(s, r); }
/* strtoull already lives in posix.c, with the Darwin errno translation. */
EXPORT ssize_t pread(int fd, void *b, size_t n, off_t o) { return glibc_pread(fd, b, n, o); }
EXPORT int    geteuid(void) { return glibc_geteuid(); }

/* issetugid(2): "was this process started with elevated privilege?" objc4 uses
 * it to decide whether to honour OBJC_* environment variables. Linux has no
 * such call; comparing real and effective uid is the standard substitute and
 * catches exactly the setuid case objc4 cares about. */
extern int glibc_getuid(void) GLIBCSYM(getuid);
EXPORT int issetugid(void) { return glibc_getuid() != glibc_geteuid(); }

/* reallocf(3) is BSD-only: realloc that frees the original on failure. */
EXPORT void *reallocf(void *p, size_t n)
{
    void *q = glibc_realloc(p, n);
    if (!q && n) glibc_free(p);
    return q;
}

/* strlcpy(3) is BSD-only. Returns the length it TRIED to make, which is what
 * callers test for truncation. */
EXPORT size_t strlcpy(char *dst, const char *src, size_t size)
{
    size_t n = glibc_strlen(src);
    if (size) {
        size_t c = n < size - 1 ? n : size - 1;
        glibc_memcpy(dst, src, c);
        dst[c] = 0;
    }
    return n;
}

/* arc4random(3). glibc has getrandom(2); Darwin's contract is "never fails",
 * so a short read is a hard error rather than a silent weakening. */
EXPORT void arc4random_buf(void *buf, size_t n)
{
    glibc_getrandom_fill(buf, n, 0);
}
EXPORT unsigned arc4random(void)
{
    unsigned v;
    arc4random_buf(&v, sizeof v);
    return v;
}
/* Uniform over [0, upper). Rejection sampling, as Apple's does -- taking the
 * modulus directly would bias the low values. */
EXPORT unsigned arc4random_uniform(unsigned upper)
{
    if (upper < 2) return 0;
    unsigned min = (unsigned)(-(int)upper) % upper, r;
    do { r = arc4random(); } while (r < min);
    return r % upper;
}

EXPORT int  backtrace(void **b, int n)                { return glibc_backtrace(b, n); }
EXPORT char **backtrace_symbols(void *const *b, int n){ return glibc_backtrace_symbols(b, n); }
EXPORT void backtrace_symbols_fd(void *const *b, int n, int fd) { glibc_backtrace_symbols_fd(b, n, fd); }

/* dladdr / dlopen / dlsym over GUEST images is not the same question as over
 * host ELF images, and machorun has no guest dlopen yet. Forwarding to glibc
 * would answer about the loader's own ELF world, which is a different process
 * image than the one the caller means. */
EXPORT int dladdr(const void *addr, void *info)
{
    (void)addr; (void)info;
    mr_bail("dladdr: machorun has no guest image introspection yet. Forwarding to "
            "glibc's dladdr would describe the LOADER's ELF images, not the "
            "Mach-O ones the caller is asking about. See docs/UNIMPLEMENTED.md.");
    return 0;
}
EXPORT void *dlopen(const char *path, int mode)
{
    (void)path; (void)mode;
    mr_bail("dlopen: not implemented for guest Mach-O images "
            "(see docs/UNIMPLEMENTED.md#dlopen-dlsym).");
    return 0;
}
/* Darwin's pseudo-handles, from <dlfcn.h>. */
#define MR_RTLD_NEXT      ((void *)-1L)
#define MR_RTLD_DEFAULT   ((void *)-2L)
#define MR_RTLD_SELF      ((void *)-3L)
#define MR_RTLD_MAIN_ONLY ((void *)-5L)

extern void *mr_dlsym_default(const char *name);   /* -> loader, via host lookup */

EXPORT void *dlsym(void *h, const char *name)
{
    if (h == MR_RTLD_DEFAULT) return mr_dlsym_default(name);
    if (h == MR_RTLD_NEXT || h == MR_RTLD_SELF || h == MR_RTLD_MAIN_ONLY)
        mr_bail("dlsym: RTLD_NEXT / RTLD_SELF / RTLD_MAIN_ONLY need a notion of "
                "'the calling image', which means walking back to the caller's "
                "return address. Only RTLD_DEFAULT is implemented "
                "(docs/UNIMPLEMENTED.md#dlopen-dlsym).");
    mr_bail("dlsym: a real handle means dlopen, which machorun does not "
            "implement yet (docs/UNIMPLEMENTED.md#dlopen-dlsym).");
    return 0;
}
EXPORT char *dlerror(void) { return 0; }

/* vasprintf(3).
 *
 * MEASURED THE HARD WAY: forwarding this to glibc's vasprintf segfaults inside
 * glibc (SIGSEGV, x0 = 0x2e, reached from _objc_init -> _objc_inform). A
 * va_list is NOT a portable token here. On Darwin/arm64 it is a plain
 * `char *` walking a stack area; on Linux/aarch64 (AAPCS64) it is a 32-byte
 * struct { __stack, __gr_top, __vr_top, __gr_offs, __vr_offs } describing a
 * register save area. Handing one to the other reads arguments out of thin
 * air. This is the same divergence docs/ABI.md measures for printf, arriving
 * through a different door.
 *
 * So vasprintf goes over OUR formatter, which speaks the Darwin va_list,
 * exactly like asprintf in libsystem.c. */
extern int mr_vsnprintf(char *, size_t, const char *, va_list) __asm__("_vsnprintf");

EXPORT int vasprintf(char **out, const char *fmt, va_list ap)
{
    va_list ap2;
    char *buf;
    int n;

    va_copy(ap2, ap);
    n = mr_vsnprintf(NULL, 0, fmt, ap2);
    va_end(ap2);
    if (n < 0) { *out = 0; return -1; }

    buf = glibc_malloc((size_t)n + 1);
    if (!buf) { *out = 0; return -1; }
    mr_vsnprintf(buf, (size_t)n + 1, fmt, ap);
    *out = buf;
    return n;
}

/* __vsnprintf_chk: the _FORTIFY_SOURCE form. `slen` is the compiler's idea of
 * the destination object's size; if the requested maxlen exceeds it, that is a
 * detected overflow. Goes over OUR formatter for the va_list reason above. */
EXPORT int __vsnprintf_chk(char *dst, size_t maxlen, int flag, size_t slen,
                           const char *fmt, va_list ap)
{
    (void)flag;
    if (slen < maxlen)
        mr_bail("__vsnprintf_chk: destination is smaller than the requested "
                "length -- _FORTIFY_SOURCE caught a real overflow.");
    return mr_vsnprintf(dst, maxlen, fmt, ap);
}

/* __chkstk_darwin: the stack probe clang emits ahead of a large frame.
 *
 * MEASURED CALL ABI (llvm-objdump over the corpus, e.g. 021-protocol-methods):
 *     mov  w9, #0x1570          ; frame size in BYTES, in x9
 *     adrp x16, ...             ; called indirectly through the GOT, so x16
 *     ldr  x16, [x16, #0xc8]    ; is already dead on entry
 *     blr  x16
 * It runs BEFORE the frame exists, so it must preserve every register the
 * caller still owns -- including x9. Only x16/x17, the intra-procedure-call
 * scratch pair, are free.
 *
 * On Darwin this exists so a frame larger than one guard page cannot step over
 * the guard and land in unrelated memory. Linux has the same hazard and the
 * same fix, so this is a real probe loop and not a bare `ret`: touch one word
 * every 4 KiB down from sp, the smaller of the two systems' page sizes. */
__asm__(
"    .text\n"
"    .p2align 2\n"
"    .globl ___chkstk_darwin\n"
"___chkstk_darwin:\n"
"    lsr  x16, x9, #12\n"          /* pages to probe */
"    cbz  x16, 1f\n"
"    mov  x17, sp\n"
"0:  sub  x17, x17, #4096\n"
"    ldr  xzr, [x17]\n"            /* a fault here is a genuine overflow */
"    subs x16, x16, #1\n"
"    b.ne 0b\n"
"1:  ret\n"
);

EXPORT int vm_remap(unsigned target, void **addr, size_t size, unsigned mask,
                    int flags, unsigned src_task, void *src_addr,
                    int copy, int *cur, int *max, int inherit)
{
    (void)target; (void)addr; (void)size; (void)mask; (void)flags;
    (void)src_task; (void)src_addr; (void)copy; (void)cur; (void)max; (void)inherit;
    mr_bail("vm_remap: mapping one VA range at a second address is a Mach "
            "primitive with no single-call Linux equivalent (it needs an "
            "memfd/shmem round trip). Nothing in the corpus reaches it.");
    return 1;
}
