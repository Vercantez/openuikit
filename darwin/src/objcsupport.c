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
 * Darwin thread-specific data -- the WHOLE key namespace, not just objc4's.
 *
 * On Darwin a pthread_key_t is not an opaque token, it is an INDEX into a flat
 * per-thread slot array, and the public and private APIs address the same
 * array. Slot 0 is the pthread itself, the low slots are carved up between
 * frameworks by <pthread/tsd_private.h> (libobjc owns 40..49, the Swift
 * runtime 100..109), and pthread_key_create hands out indices above the
 * reserved block. `pthread_getspecific(40)` and `_pthread_getspecific_direct(40)`
 * are the same load.
 *
 * We cannot use Darwin's mechanism -- it is a load off TPIDRRO_EL0, and under
 * machorun TPIDRRO_EL0 holds glibc's TLS base -- so we keep a real per-thread
 * slot array behind one glibc TSD key. Same observable semantics, one
 * indirection more.
 *
 * WHY THIS OWNS pthread_key_create/getspecific/setspecific TOO, when those
 * used to be one-line forwarders to glibc in libsystem.c: because forwarding
 * makes the two halves of one namespace disagree. glibc's keys are opaque
 * counters starting near 0, so a guest that called pthread_key_create could be
 * handed key 40 -- libobjc's slot -- and then pthread_setspecific(40) had two
 * possible meanings. Worse, the Swift runtime never calls pthread_key_create
 * at all: SwiftTLSContext::get() adopts the RESERVED key 100 with
 * pthread_key_init_np and then reads it back with plain pthread_getspecific.
 * Forwarded to glibc that is key 100 in glibc's namespace, which glibc never
 * allocated, so every setspecific failed silently and every getspecific
 * returned NULL -- a fresh TLS context allocated on every single call.
 * One array, one dispatch, no ambiguity.
 *
 * THE NUMBERS ARE MEASURED, not guessed. Apple ships <pthread/tsd_private.h>
 * only in the internal SDK, so a probe on the oracle (macOS 26.5.2, arm64)
 * reported:
 *
 *   pthread_key_create's first key                       258
 *   keys it will hand out before failing                 510  (last: 767)
 *   pthread_setspecific(1000) / pthread_key_init_np(1000) EINVAL
 *   pthread_key_init_np(100, dtor)                       0
 *   pthread_setspecific(40, v) then direct-read slot 40  same value
 *   pthread_setspecific(55, v) on a key nobody adopted   0, reads back
 *   pthread_key_delete(100) on a reserved key            EINVAL
 *   a destructor that re-sets its own slot               runs again
 *   pthread_key_create when exhausted                    EAGAIN
 *
 * The same probe was then run against THIS implementation under machorun and
 * agreed line for line, with one deliberate divergence: pthread_getspecific()
 * on an OUT-OF-RANGE key returns garbage on Darwin -- it is a raw indexed load
 * off the thread struct with no validation, and POSIX says the behaviour is
 * undefined -- and NULL here. Reproducing an out-of-bounds read is not parity
 * worth having.
 *
 * So: keys 0..257 are the reserved block and live in our array; 258..767 are
 * dynamic. The dynamic half is delegated to glibc with a fixed +258 bias
 * rather than reimplemented, which buys glibc's key reuse, its delete
 * semantics and its thread-exit destructor pass for free. The bias is what
 * keeps the two halves from ever naming the same key.
 *
 * We allocate ONE slot past the reserved block, index DTSD_TOKEN_SLOT, for the
 * os_unfair_lock owner token. It is deliberately out of reach of
 * _pthread_getspecific_direct and _pthread_setspecific_direct, which
 * bound-check against DTSD_RESERVED, so no guest can read or clobber it, and
 * dtsd_thread_exit never runs a destructor over it.
 * ===================================================================== */
#define DTSD_RESERVED    258                 /* keys 0..257: framework-reserved */
#define DTSD_KEY_MAX     768                 /* Darwin keys are 0..767 */
#define DTSD_DYNAMIC_MAX (DTSD_KEY_MAX - DTSD_RESERVED)   /* 510, as measured */
#define DTSD_TOKEN_SLOT  DTSD_RESERVED       /* private; a guest cannot address it */
#define DTSD_ARRAY_LEN   (DTSD_RESERVED + 1)

/* POSIX's limit on how many times a thread-exit pass will re-run a destructor
 * that re-sets its own slot. Darwin honours it; the probe above saw a
 * self-resetting destructor run on every pass. */
#define DTSD_DESTRUCTOR_ITERATIONS 4

#define DERR_EINVAL 22
#define DERR_EAGAIN 35

static unsigned  dtsd_key;
static void    (*dtsd_dtor[DTSD_RESERVED])(void *);

/* Key creation used to be a plain `if (!ready)`, safe only because objc4
 * touches TSD from the single-threaded _objc_init. mr_thread_token() breaks
 * that assumption -- a lock can now be the first thing a brand-new thread
 * touches -- and losing that race would give one thread two different slot
 * arrays over its life, hence two different tokens, which is exactly the
 * ownership confusion this whole change exists to remove. So: a three-state
 * atomic, 0 unmade / 1 being made / 2 usable. */
static int dtsd_key_state;

static void dtsd_thread_exit(void *p)
{
    void **slots = (void **)p;
    /* Darwin runs TSD destructors in slot order, and re-runs the pass while a
     * destructor keeps re-setting its own slot, up to POSIX's iteration limit.
     * objc4's destructors do not re-set, so one pass used to be enough for it;
     * now that this array backs every reserved key a guest can adopt, the real
     * loop is what a guest is entitled to expect. */
    for (int pass = 0; pass < DTSD_DESTRUCTOR_ITERATIONS; pass++) {
        int again = 0;
        for (int i = 0; i < DTSD_RESERVED; i++) {
            void *v = slots[i];
            if (v && dtsd_dtor[i]) { slots[i] = NULL; dtsd_dtor[i](v); again = 1; }
        }
        if (!again) break;
    }
    glibc_free(slots);
}

static void dtsd_key_make(void)
{
    int unmade = 0;
    if (__atomic_compare_exchange_n(&dtsd_key_state, &unmade, 1, 0,
                                    __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE)) {
        if (glibc_pthread_key_create(&dtsd_key, dtsd_thread_exit) != 0)
            mr_bail("objcsupport: pthread_key_create for the direct-TSD array failed");
        __atomic_store_n(&dtsd_key_state, 2, __ATOMIC_RELEASE);
        return;
    }
    /* Someone else is making it. This is the one place we spin, it is bounded
     * by a single pthread_key_create, and it cannot deadlock: the maker never
     * calls back into here. */
    while (__atomic_load_n(&dtsd_key_state, __ATOMIC_ACQUIRE) != 2)
        glibc_sched_yield();
}

static void **dtsd_slots(void)
{
    if (__atomic_load_n(&dtsd_key_state, __ATOMIC_ACQUIRE) != 2) dtsd_key_make();

    void **slots = (void **)glibc_pthread_getspecific(dtsd_key);
    if (!slots) {
        slots = (void **)glibc_calloc(DTSD_ARRAY_LEN, sizeof(void *));
        if (!slots) mr_bail("objcsupport: out of memory allocating a direct-TSD array");
        slots[0] = (void *)glibc_pthread_self();     /* _PTHREAD_TSD_SLOT_PTHREAD_SELF */
        glibc_pthread_setspecific(dtsd_key, slots);
    }
    return slots;
}

/* ===================================================================== *
 * The os_unfair_lock owner token.
 *
 * An os_unfair_lock is four bytes and a locked one holds its owner's token, so
 * the token must be 32 bits, must never be 0 (that is "unlocked"), must be the
 * same value every time one thread asks, and must differ between any two live
 * threads. That last property is the one we got wrong: the token used to be
 * `(unsigned)(pthread_self() >> 8)`, which throws away 32 bits of a 64-bit TCB
 * pointer. On Apple silicon the surviving bits happened to differ; on Graviton3
 * glibc lays the TCBs out so that two threads collide roughly half the time,
 * and a colliding token makes a fresh acquisition read as recursive
 * acquisition by the owner -- so objc4 aborted, intermittently, with ASLR
 * deciding. docs/UNIMPLEMENTED.md#os-unfair-lock-owner has the measurements.
 *
 * No derivation of a pointer can fix this; hashing 64 bits into 32 always has
 * collisions and we cannot choose the inputs. So the token is not derived from
 * anything. It is handed out from a counter, one per thread, on first use, and
 * kept in the private TSD slot. Sequential ids are unique by construction over
 * the life of the process, which is stronger than a kernel tid (those get
 * reused after a thread exits).
 *
 * This must be callable from anywhere a lock can be taken, so it must not take
 * a lock itself. The counter is a single atomic, and the TSD read underneath is
 * glibc's.
 *
 * CORRECTION (independent review): this used to claim the TSD path takes no
 * lock because it "is glibc's, which is independent of ours". That reasons
 * about WHOSE lock rather than WHETHER THERE IS ONE. dtsd_slots() CALLOCS on a
 * thread's first call, and glibc's arena mutex is not recursive -- so a thread
 * already inside malloc that first-touched a lock would deadlock against a
 * mutex it already holds. Darwin's os_unfair_lock_lock never allocates.
 *
 * The allocation is now hoisted: mr_thread_trampoline() primes this array
 * before the guest runs, so on every guest thread this is a pure TSD read.
 * The main thread, which has no trampoline, is primed by an image constructor
 * in libsystem.c (mr_prime_main_thread_tsd). That had to go in the dylib rather
 * than the loader: mr_constrain_heap() runs before find_darwin_root(), so the
 * loader cannot call into a Mach-O image it has not mapped yet.
 * ===================================================================== */
static unsigned dtsd_token_counter;

HIDDEN unsigned mr_thread_token(void)
{
    void **slots = dtsd_slots();
    unsigned t = (unsigned)(uintptr_t)slots[DTSD_TOKEN_SLOT];
    if (!t) {
        /* Skip 0 if the counter ever wraps -- 4 billion threads, but the check
         * is two instructions and the alternative is a lock that reads
         * unlocked while held. */
        do { t = __atomic_add_fetch(&dtsd_token_counter, 1, __ATOMIC_RELAXED); } while (!t);
        slots[DTSD_TOKEN_SLOT] = (void *)(uintptr_t)t;
    }
    return t;
}

EXPORT int _pthread_has_direct_tsd(void) { return 1; }

/* The direct SPI addresses the reserved block only. On Darwin it can also
 * reach a dynamic key's slot, because there the two ranges are one array; here
 * the dynamic half lives in glibc and has no slot to point at. objc4 uses
 * slot 0 and 40..49 and nothing else, so this has never been reached -- and if
 * it is, it says so rather than returning a plausible NULL. */
EXPORT void *_pthread_getspecific_direct(unsigned long slot)
{
    if (slot >= DTSD_RESERVED)
        mr_bail("_pthread_getspecific_direct: slot is outside the reserved block "
                "(0..257). A key from pthread_key_create cannot be read through "
                "the direct SPI under machorun; use pthread_getspecific.");
    return dtsd_slots()[slot];
}

EXPORT void _pthread_setspecific_direct(unsigned long slot, void *value)
{
    if (slot >= DTSD_RESERVED)
        mr_bail("_pthread_setspecific_direct: slot is outside the reserved block "
                "(0..257). A key from pthread_key_create cannot be written through "
                "the direct SPI under machorun; use pthread_setspecific.");
    dtsd_slots()[slot] = value;
}

/* Darwin's "adopt this reserved key and give it a destructor". This is how the
 * Swift runtime installs the destructor for SwiftTLSContext on key 100; if it
 * fails, tls_init_once() calls swift::fatal and no Swift class or generic can
 * be instantiated. */
EXPORT int pthread_key_init_np(int key, void (*destructor)(void *))
{
    if (key < 0 || key >= DTSD_RESERVED) return DERR_EINVAL;
    dtsd_dtor[key] = destructor;
    (void)dtsd_slots();          /* force the array to exist on this thread */
    return 0;
}

/* ------------------------------------------------------- the public API.
 * Reserved keys are our array; dynamic keys are glibc's, biased by
 * DTSD_RESERVED so the two ranges can never name the same key. */

EXPORT int pthread_key_create(unsigned *k, void (*d)(void *))
{
    unsigned g;
    int rc = glibc_pthread_key_create(&g, d);
    if (rc != 0) return rc;
    if (g >= DTSD_DYNAMIC_MAX) {
        /* Darwin runs out at 510 dynamic keys; so do we, at the same count,
         * rather than handing back a key that pthread_getspecific would then
         * have to reject. */
        glibc_pthread_key_delete(g);
        return DERR_EAGAIN;
    }
    *k = g + DTSD_RESERVED;
    return 0;
}

EXPORT int pthread_key_delete(unsigned k)
{
    /* Deleting a framework-reserved key is EINVAL on Darwin -- measured. */
    if (k < DTSD_RESERVED || k >= DTSD_KEY_MAX) return DERR_EINVAL;
    return glibc_pthread_key_delete(k - DTSD_RESERVED);
}

EXPORT void *pthread_getspecific(unsigned k)
{
    if (k < DTSD_RESERVED) return dtsd_slots()[k];
    if (k >= DTSD_KEY_MAX) return NULL;
    return glibc_pthread_getspecific(k - DTSD_RESERVED);
}

EXPORT int pthread_setspecific(unsigned k, const void *v)
{
    if (k < DTSD_RESERVED) { dtsd_slots()[k] = (void *)v; return 0; }
    if (k >= DTSD_KEY_MAX) return DERR_EINVAL;
    return glibc_pthread_setspecific(k - DTSD_RESERVED, v);
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

/* This MUST be the identical value libsystem.c's os_unfair_lock_lock stores,
 * because the recursion check below compares it against a word that
 * os_unfair_lock_lock wrote. The old pair did not: this one OR'd in 0x80000000
 * and the other did not, so the two agreed only when bit 39 of the TCB pointer
 * happened to be set. It always was on the hosts we ran, which is why the
 * recursion path appeared to work. Both now call one function. */
static unsigned self_token(void) { return mr_thread_token(); }

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
 * malloc_type: Apple's TYPED allocator (macOS 14 / iOS 17), the surface
 * Apple's SHIPPED libswiftCore uses and nothing else in this project does.
 * Our own Linux-built libswiftCore imports plain malloc/calloc/realloc/
 * posix_memalign; Apple's imports _malloc_type_malloc, _malloc_type_calloc,
 * _malloc_type_realloc, _malloc_type_posix_memalign and
 * _malloc_type_zone_malloc_with_options_internal, and nothing else.
 *
 * The type id is a compiler-generated token describing the allocated type. It
 * steers a per-type heap for diagnostics and carries no semantics we have to
 * honour, so forwarding to the untyped allocator is exact rather than
 * approximate. Ignoring the token is the ONLY thing about this family that is
 * safe to do casually.
 *
 * READ THE ARGUMENT ORDER OFF THE HEADER, EVERY TIME. This family mixes three
 * orders and they are not guessable:
 *
 *     malloc_type_malloc            (size, type)
 *     malloc_type_calloc            (count, size, type)
 *     malloc_type_realloc           (ptr, size, type)
 *     malloc_type_aligned_alloc     (ALIGN, size, type)
 *     malloc_type_posix_memalign    (out, ALIGN, size, type)
 *     malloc_type_zone_malloc       (zone, size, type)          <- no align
 *     malloc_type_zone_memalign     (zone, ALIGN, size, type)
 *     ..._zone_malloc_with_options_ (zone, ALIGN, size, options, type)
 *
 * sdk/usr/include/malloc/_malloc_type.h and malloc/malloc.h:192 are the
 * authority and are vendored precisely so nobody has to guess.
 *
 * THIS FAMILY DID NOT EXIST IN MACHORUN UNTIL 2026-08-27, AND THAT COST THE
 * PROJECT ITS LONGEST BUG. A libSystem hole gets filled by whoever hits it
 * first: ~/swift-macho-linux/spike/syspatch.c supplied its own
 * malloc_type_zone_malloc_with_options_internal with FOUR parameters instead
 * of five, so the argument it forwarded to malloc as the size was the
 * ALIGNMENT. It compiled to `mov x0, x1; b _malloc` -- every allocation
 * through that entry point got a block the size of its own alignment, sixteen
 * bytes whatever was asked for, and the caller wrote the whole object over its
 * neighbours. That was the entirety of the "46 UIKit scenes fail with
 * nondeterministic memory corruption" wall: 22 glibc heap aborts, 19 SIGSEGVs
 * on wild addresses and 9 silent failures, all one wrong register. It looked
 * like many bugs because a heap overflow of arbitrary size onto arbitrary
 * neighbours fails differently every time.
 *
 * Two lessons are worth more than the fix. A missing libSystem symbol is not
 * neutral -- someone WILL define it, somewhere we do not test. And the wrong
 * definition was never detectable from its own behaviour: it returned a valid
 * pointer every time, and the damage surfaced elsewhere, later, as somebody
 * else's crash. tests/src/malloc_type.c exists to make the size a checked
 * property at the point of allocation instead.
 * ===================================================================== */
#define MT_ALIGN_TRIVIAL (sizeof(void *) * 2)   /* what plain malloc already gives */

/* OUR sysconf (libsystem.c), so the argument is DARWIN's _SC_PAGESIZE. */
extern long sysconf(int);

static void *mt_aligned(size_t align, size_t size)
{
    void *p = NULL;
    if (align <= MT_ALIGN_TRIVIAL) return glibc_malloc(size);
    if (glibc_posix_memalign(&p, align, size) != 0) return NULL;
    return p;
}

/* WHICH MEMBERS REQUIRE size TO BE A MULTIPLE OF align, MEASURED AGAINST
 * APPLE'S LIBMALLOC because no header states it:
 *
 *     aligned_alloc(64, 3000)                -> NULL     (C11 requires it)
 *     aligned_alloc(64, 3008)                -> ok
 *     zone_memalign(64, 3000)                -> ok       (no such rule)
 *     posix_memalign(128, 4400)              -> rc 0     (no such rule)
 *     valloc(6000) / zone_valloc(6000)       -> ok       (no such rule)
 *     ..._with_options_internal(32, 6000, 0) -> NULL
 *     ..._with_options_internal(32, 6144, 0) -> ok
 *     ..._with_options_internal(16, 6000, 0) -> ok       (align <= 16 exempt)
 *
 * So the rule holds for aligned_alloc and for the with-options entry point,
 * and only once the alignment exceeds what plain malloc already guarantees.
 * Returning a block where macOS returns NULL would be a silent divergence in
 * the permissive direction, which is the harder kind to notice. */
static int mt_size_ok_for_align(size_t align, size_t size)
{
    return align <= MT_ALIGN_TRIVIAL || (size % align) == 0;
}

EXPORT void *malloc_type_malloc(size_t size, unsigned long long type)
{ (void)type; return glibc_malloc(size); }

EXPORT void *malloc_type_calloc(size_t count, size_t size, unsigned long long type)
{ (void)type; return glibc_calloc(count, size); }

EXPORT void malloc_type_free(void *p, unsigned long long type)
{ (void)type; glibc_free(p); }

EXPORT void *malloc_type_realloc(void *p, size_t size, unsigned long long type)
{ (void)type; return glibc_realloc(p, size); }

EXPORT void *malloc_type_valloc(size_t size, unsigned long long type)
{ (void)type; return mt_aligned((size_t)sysconf(29 /* _SC_PAGESIZE, Darwin */), size); }

EXPORT void *malloc_type_aligned_alloc(size_t align, size_t size, unsigned long long type)
{ (void)type; return mt_size_ok_for_align(align, size) ? mt_aligned(align, size) : NULL; }

EXPORT int malloc_type_posix_memalign(void **out, size_t align, size_t size,
                                      unsigned long long type)
{ (void)type; return glibc_posix_memalign(out, align, size); }

EXPORT void *malloc_type_zone_malloc(void *zone, size_t size, unsigned long long type)
{ (void)type; return malloc_zone_malloc(zone, size); }

EXPORT void *malloc_type_zone_calloc(void *zone, size_t count, size_t size,
                                     unsigned long long type)
{ (void)type; return malloc_zone_calloc(zone, count, size); }

EXPORT void malloc_type_zone_free(void *zone, void *p, unsigned long long type)
{ (void)type; malloc_zone_free(zone, p); }

EXPORT void *malloc_type_zone_realloc(void *zone, void *p, size_t size,
                                      unsigned long long type)
{ (void)type; return malloc_zone_realloc(zone, p, size); }

EXPORT void *malloc_type_zone_valloc(void *zone, size_t size, unsigned long long type)
{ (void)zone; (void)type; return mt_aligned((size_t)sysconf(29), size); }

EXPORT void *malloc_type_zone_memalign(void *zone, size_t align, size_t size,
                                       unsigned long long type)
{ (void)zone; (void)type; return mt_aligned(align, size); }

/* FIVE parameters, and `size` is the THIRD. See malloc/malloc.h:192. */
EXPORT void *malloc_type_zone_malloc_with_options_internal(void *zone, size_t align,
                                                           size_t size,
                                                           unsigned long long options,
                                                           unsigned long long type)
{
    void *p;
    (void)zone; (void)type;
    if (!mt_size_ok_for_align(align, size)) return NULL;
    p = mt_aligned(align, size);
    if (p && (options & 1u)) glibc_memset(p, 0, size);   /* MALLOC_NP_OPTION_CLEAR */
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
 * Swift refcounting is NOT here, and its absence is the point.
 *
 * objc4 refers to swift_retain/swift_release so that a Swift-stable class can
 * be retained without a message send. On Darwin those two references carry
 * -delay_init: they resolve on first use and only if libswiftCore is in the
 * process. ld64.lld-18 has no -delay_init, so scripts/build_objc4.sh emits
 * them as ordinary flat-lookup binds, which must resolve at load time.
 *
 * This file used to define them as loud aborts so that the bind had something
 * to hit. That was fine while no Swift runtime could exist and wrong the
 * moment one did: machorun's flat lookup returns the FIRST definition in load
 * order, libSystem.B.dylib loads before libswiftCore.dylib, so objc4's
 * fast-path refcounting bound to the diagnostic abort with the real
 * implementation sitting in the very next image. The only way out was to order
 * -lswiftCore ahead of -lSystem on the guest's link line -- a load-bearing
 * detail no guest should have to know, and one that silently stops working the
 * day someone reorders a Makefile.
 *
 * The diagnostic now lives in the LOADER (src/resolve.c, listed in
 * darwin/loader-exports.txt). The loader is only consulted after the flat
 * lookup has found nothing in any image, so it cannot shadow a real
 * libswiftCore however the guest was linked, and a guest without one still
 * fails with a sentence instead of a null jump.
 * ===================================================================== */

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
 * The C++ exception ABI: NOT STUBBED ANY MORE.
 *
 * __cxa_throw, __gxx_personality_v0, std::terminate and the rest are LLVM
 * 18.1.8's libc++abi, compiled unpatched from vendor/libcxxabi and linked into
 * this dylib alongside libunwind (scripts/build_darwin.sh). What used to be
 * here was fourteen functions that aborted naming themselves.
 *
 * IT IS ITS OWN DYLIB, /usr/lib/libc++abi.dylib, EXACTLY AS ON DARWIN -- and
 * the first arrangement here was wrong in an instructive way. It put libc++abi
 * inside libSystem, reasoning that tests/objc44/038-exceptions loads only
 * libobjc and libSystem (otool -L), so nothing else could be found. That
 * worked for objc4 and FAILED for C++ guests: a guest linking -lc++ binds
 * __ZNSt13runtime_errorD1Ev TWO-LEVEL against libc++.1.dylib, because on
 * Darwin libc++ RE-EXPORTS libc++abi. Ours had nothing to re-export, so the
 * symbol was present in the process and unreachable from the only library
 * allowed to answer for it.
 *
 * "Put it where the current consumer will find it" is the reasoning that
 * produced the bug. Reproducing Darwin's shape is what fixed it: libc++abi is
 * its own dylib, libc++.1.dylib re-exports it, and libobjc LINKS against it
 * rather than relying on flat lookup. The loader already chases
 * LC_REEXPORT_DYLIB (src/resolve.c lookup_in, depth 4), so both consumers now
 * resolve for the same reason they resolve on macOS.
 * ===================================================================== */

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

/* The rest of the credential family. geteuid was exported alone because it was
 * the only one objc4 needed, and that asymmetry is worse than a plain gap: a
 * guest that calls getuid() links against a libSystem advertising geteuid and
 * dies at load on the sibling. Found writing the passwd fixture, which used
 * geteuid and documented why rather than tripping over it. All four are plain
 * value returns with no struct and no errno contract, so a forward is the whole
 * implementation. */
extern int glibc_getuid(void)  GLIBCSYM(getuid);
extern int glibc_getgid(void)  GLIBCSYM(getgid);
extern int glibc_getegid(void) GLIBCSYM(getegid);
EXPORT int    getuid(void)  { return glibc_getuid(); }
EXPORT int    getgid(void)  { return glibc_getgid(); }
EXPORT int    getegid(void) { return glibc_getegid(); }

/* issetugid(2): "was this process started with elevated privilege?" objc4 uses
 * it to decide whether to honour OBJC_* environment variables. Linux has no
 * such call; comparing real and effective uid is the standard substitute and
 * catches exactly the setuid case objc4 cares about. */
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

/* ---------------------------------------- OSAtomic and OSSpinLock (Darwin) */

/* ADOPTED FROM foundation-macho's src/compat/OSAtomic.c RATHER THAN REWRITTEN,
 * which is deliberate: an implementation someone has already exercised beats a
 * fresh one, and the risk here is a SECOND DEFINITION rather than a missing
 * one -- which is what CHECK 4 exists to catch and what cost this project a
 * week when a shim shadowed the real malloc_type family. Their own comment
 * said these belong in machorun's libSystem, since they are Darwin platform
 * API rather than Foundation. This is that move.
 *
 * THREE SEMANTICS THAT ARE EASY TO GET WRONG AND THAT CoreFoundation RELIES ON:
 *
 *   The increment/decrement/add forms return the NEW value, not the old one.
 *   Darwin's do. That is why these use __atomic_add_fetch rather than
 *   __atomic_fetch_add -- the two differ by exactly one value and a caller
 *   comparing the result against zero would take the wrong branch every time.
 *
 *   The plain (non-Barrier) forms are documented as NOT full barriers, but
 *   Apple's arm64 implementations are sequentially consistent in practice and
 *   callers have come to depend on it. SEQ_CST is the conservative choice; a
 *   weaker order would be a silent behavioural difference rather than a
 *   visible failure, which is the kind this boundary must not introduce.
 *
 *   The compare-and-swap forms are STRONG -- no spurious failure -- which is
 *   what Darwin promises and what CF's retain/release paths assume. Passing
 *   the caller's value directly to __atomic_compare_exchange_n would be wrong
 *   twice over: it updates `expected` in place on failure, so it needs a local. */

EXPORT int OSAtomicIncrement32(volatile int *value)
{
    return __atomic_add_fetch(value, 1, __ATOMIC_SEQ_CST);
}

EXPORT int OSAtomicDecrement32(volatile int *value)
{
    return __atomic_sub_fetch(value, 1, __ATOMIC_SEQ_CST);
}

EXPORT long long OSAtomicAdd64(long long amount, volatile long long *value)
{
    return __atomic_add_fetch(value, amount, __ATOMIC_SEQ_CST);
}

EXPORT int OSAtomicCompareAndSwap32Barrier(int oldValue, int newValue,
                                           volatile int *theValue)
{
    int expected = oldValue;
    return __atomic_compare_exchange_n(theValue, &expected, newValue,
                                       0 /* strong */,
                                       __ATOMIC_SEQ_CST, __ATOMIC_SEQ_CST);
}

EXPORT int OSAtomicCompareAndSwapPtrBarrier(void *oldValue, void *newValue,
                                            void *volatile *theValue)
{
    void *expected = oldValue;
    return __atomic_compare_exchange_n(theValue, &expected, newValue,
                                       0 /* strong */,
                                       __ATOMIC_SEQ_CST, __ATOMIC_SEQ_CST);
}

EXPORT void OSMemoryBarrier(void)
{
    __atomic_thread_fence(__ATOMIC_SEQ_CST);
}

/* OSSpinLock IS BACKED BY os_unfair_lock, AND THE TWO ARE COMPATIBLE BY
 * MEASUREMENT RATHER THAN BY LUCK: both are a 4-byte word whose unlocked state
 * is zero (OS_SPINLOCK_INIT and OS_UNFAIR_LOCK_INIT are both {0}), so a lock
 * initialised through either spelling is valid for the other.
 *
 * Writing a second spin loop here would mean maintaining a second
 * synchronisation primitive to get wrong, when libsystem.c already has one
 * that is exercised by tests/bin/21_unfair_lock_firsttouch and by a 300-run
 * threading gate. Reuse is the same judgement as adopting the OSAtomic bodies
 * above.
 *
 * ONE OBSERVABLE DIFFERENCE, recorded rather than hidden: recursive
 * acquisition ABORTS here and HANGS FOREVER on Darwin. Apple deprecated
 * OSSpinLock precisely because it has no owner tracking and no priority
 * donation, so a recursive or preempted holder deadlocks. Aborting with a
 * sentence is a divergence in the safe direction -- it cannot be mistaken for
 * correct behaviour, where a hang can be mistaken for slow work. */
extern void os_unfair_lock_lock(void *);      /* darwin/src/libsystem.c */
extern void os_unfair_lock_unlock(void *);

EXPORT void OSSpinLockLock(volatile int *lock)   { os_unfair_lock_lock((void *)lock); }
EXPORT void OSSpinLockUnlock(volatile int *lock) { os_unfair_lock_unlock((void *)lock); }

/* The _dyld_* image-introspection family. Every one of these is a question
 * only the loader can answer -- MR.images is dyld's table here, and libSystem
 * has no view of it. Same shape as _NSGetExecutablePath needing the MAIN image
 * and dladdr needing the CALLING one: three separate-looking gaps, one cause.
 *
 * CoreFoundation walks these to find bundles and to map addresses back to
 * binaries, and the standard idiom is to count first or to walk until the
 * header comes back NULL -- so out-of-range must return NULL/0 rather than
 * abort, which is what dyld does and what every correct caller relies on.
 *
 * The DECLARATIONS are the ABI: _dyld_image_count returns uint32_t and the
 * slide is an intptr_t, which is signed because an image can land BELOW its
 * preferred base. An unsigned slide would read a downward slide as an
 * enormous positive offset, and every address computed from it would be
 * wrong in a way that looks like a valid pointer. */
extern unsigned    mr_dyld_image_count(void);          /* -> loader, image.c */
extern const void *mr_dyld_image_header(unsigned);
extern const char *mr_dyld_image_name(unsigned);
extern long        mr_dyld_image_slide(unsigned);

EXPORT unsigned    _dyld_image_count(void)                { return mr_dyld_image_count(); }
EXPORT const void *_dyld_get_image_header(unsigned i)     { return mr_dyld_image_header(i); }
EXPORT const char *_dyld_get_image_name(unsigned i)       { return mr_dyld_image_name(i); }
EXPORT long        _dyld_get_image_vmaddr_slide(unsigned i) { return mr_dyld_image_slide(i); }

/* ------------------------------------------- the rest of the string family */

/* Plain forwards, and glibc really does export all three -- checked with
 * nm -D rather than assumed, after pthread_atfork turned out to have a header
 * declaration and no dynamic symbol. strncasecmp uses the C locale in its
 * non-_l form on both systems, so there is no locale_t crossing here; the _l
 * variants are a separate question and deliberately not answered yet. */
EXPORT int   strncasecmp(const char *a, const char *b, size_t n) { return glibc_strncasecmp(a, b, n); }
EXPORT char *strtok(char *s, const char *sep)                    { return glibc_strtok(s, sep); }
EXPORT char *strtok_r(char *s, const char *sep, char **save)     { return glibc_strtok_r(s, sep, save); }

/* strnstr(3) is BSD-only -- glibc has strstr but not the length-bounded form,
 * confirmed absent from libc.so.6 -- so it is implemented rather than bound.
 *
 * The contract detail worth getting right: `len` bounds the HAYSTACK, not the
 * needle, and the haystack need not be NUL-terminated within it. A version
 * written as strstr-with-a-length-check would read past `len` looking for the
 * terminator, which is the whole reason a caller reaches for the n form. */
EXPORT char *strnstr(const char *haystack, const char *needle, size_t len)
{
    size_t nlen = glibc_strlen(needle);
    size_t i;

    if (nlen == 0) return (char *)haystack;
    if (nlen > len) return 0;
    /* <= because a match may end exactly at the bound. */
    for (i = 0; i + nlen <= len; i++) {
        if (haystack[i] == 0) return 0;        /* the haystack ended first */
        if (glibc_strncmp(haystack + i, needle, nlen) == 0)
            return (char *)(haystack + i);
    }
    return 0;
}

/* flsl(3): find LAST set bit, 1-based, 0 for 0. glibc has ffsl -- find FIRST
 * -- and not this, which is a pairing worth noticing rather than a coincidence:
 * the two names differ by one letter and their answers differ by the whole
 * width of the word. Binding flsl to ffsl would compile, link, and return a
 * plausible small number for every input.
 *
 * __builtin_clzl is undefined for 0, so the zero case is handled before it
 * rather than trusted to it. */
EXPORT int flsl(long mask)
{
    if (mask == 0) return 0;
    return (int)(sizeof(long) * 8 - (unsigned)__builtin_clzl((unsigned long)mask));
}

EXPORT int fls(int mask)
{
    if (mask == 0) return 0;
    return (int)(sizeof(int) * 8 - (unsigned)__builtin_clz((unsigned)mask));
}

/* The _FORTIFY_SOURCE expansion of strlcpy, which libdispatch's init.c reaches
 * through <string.h> without ever naming it. There is nothing to forward to --
 * glibc has neither strlcpy's semantics nor Apple's __*_chk family -- so this
 * is implemented rather than bound.
 *
 * `os` is the compiler's idea of the destination's real size. A requested copy
 * longer than that is exactly the overflow the fortify wrapper exists to
 * catch, and aborting is what Apple's does: returning quietly would turn a
 * diagnosed overflow into an undiagnosed one. */
/* strlcat(3), BSD-only like strlcpy. Returns the length it TRIED to make --
 * the initial dst length plus the whole source -- which is how callers detect
 * truncation. Returning the length WRITTEN would turn a detectable truncation
 * into a silent one, which is the whole reason the BSD forms exist. */
EXPORT size_t strlcat(char *dst, const char *src, size_t size)
{
    size_t dl = glibc_strnlen(dst, size);
    size_t sl = glibc_strlen(src);
    if (dl == size) return size + sl;          /* dst not NUL-terminated in size */
    if (sl < size - dl) {
        glibc_memcpy(dst + dl, src, sl + 1);
    } else {
        glibc_memcpy(dst + dl, src, size - dl - 1);
        dst[size - 1] = 0;
    }
    return dl + sl;
}

EXPORT size_t __strlcat_chk(char *dst, const char *src, size_t len, size_t os)
{
    if (len > os)
        mr_bail("__strlcat_chk: buffer overflow detected -- the requested "
                "concatenation is longer than the destination the compiler sized.");
    return strlcat(dst, src, len);
}

EXPORT size_t __strlcpy_chk(char *dst, const char *src, size_t len, size_t os)
{
    if (len > os)
        mr_bail("__strlcpy_chk: buffer overflow detected -- the requested copy "
                "is longer than the destination the compiler sized.");
    return strlcpy(dst, src, len);
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
/* dladdr over GUEST images. Forwarding to glibc would describe the LOADER's
 * ELF world -- a different program with different addresses -- so the loader
 * answers from its own image table and LC_SYMTAB (src/image.c). */
extern int mr_dladdr(const void *addr, void *info);   /* -> loader */
EXPORT int dladdr(const void *addr, void *info) { return mr_dladdr(addr, info); }
/* dlopen over guest Mach-O images. The loader does the work (src/image.c's
 * mr_dlopen) because only it has the image table, the fixup machinery and the
 * objc notification path; this side is the Darwin ABI in front of it.
 *
 * THE HANDLE IS AN OPAQUE LOADER POINTER (an mr_image *), not a glibc handle.
 * It must never reach glibc's dlsym or dlclose, which is why dlclose no longer
 * forwards: it would hand ld.so a pointer into a different linker's world.
 *
 * RTLD_NOLOAD is still answered as a QUESTION rather than a load request --
 * "if this is already in the process give me a handle, otherwise say so" --
 * and now it can hand back a real handle instead of stopping. CoreFoundation
 * asks it on the OpenUIKit render path.
 *
 * THE RETURN ADDRESS IS PASSED, AND IT IS NOT BOOKKEEPING. @loader_path, and
 * the order in which @rpath searches LC_RPATHs, are both defined relative to
 * the image that CALLED dlopen. Only this side can say which image that is --
 * the loader sees its own frames -- and it costs nothing to know, because
 * libSystem.B.dylib is a Mach-O the guest calls directly, so
 * __builtin_return_address(0) is the guest's own return address in the guest's
 * own image. It is the same one line that answers dlsym's RTLD_NEXT and
 * RTLD_SELF below, for the same reason.
 *
 * Darwin's RTLD_NOLOAD is 0x10 (sdk/usr/include/dlfcn.h). */
#define MR_RTLD_NOLOAD 0x10

extern void *mr_dlopen(const char *path, int mode, const void *caller_ra);
extern void *mr_dlsym_handle(void *handle, const char *name);/* -> loader */

EXPORT void *dlopen(const char *path, int mode)
{
    return mr_dlopen(path, mode, __builtin_return_address(0));
}

/* Darwin's pseudo-handles, from <dlfcn.h>. */
#define MR_RTLD_NEXT      ((void *)-1L)
#define MR_RTLD_DEFAULT   ((void *)-2L)
#define MR_RTLD_SELF      ((void *)-3L)
#define MR_RTLD_MAIN_ONLY ((void *)-5L)

extern void *mr_dlsym_default(const char *name);   /* -> loader, via host lookup */
extern void *mr_dlsym_scoped(const void *caller_ra, int which, const char *name);

EXPORT void *dlsym(void *h, const char *name)
{
    if (h == MR_RTLD_DEFAULT) return mr_dlsym_default(name);
    /* Darwin's dlsym prepends the underscore; the export trie stores it. */
    if (!name) return 0;
    {
        char buf[512];
        size_t n = glibc_strlen(name);
        if (n + 2 > sizeof(buf))
            mr_bail2("dlsym: symbol name longer than machorun's buffer", name);
        buf[0] = '_';
        glibc_memcpy(buf + 1, name, n + 1);

        /* THE SCOPED HANDLES NEED "THE CALLING IMAGE", AND IT IS AVAILABLE
         * HERE. That notion was missing for as long as the question was asked
         * in the loader, which only ever sees its own frames. This function is
         * in libSystem.B.dylib -- a Mach-O we build and the guest calls
         * directly -- so __builtin_return_address(0) is the guest's own return
         * address, in the guest's own image. Nothing has to be walked. */
        if (h == MR_RTLD_NEXT || h == MR_RTLD_SELF || h == MR_RTLD_MAIN_ONLY)
            return mr_dlsym_scoped(__builtin_return_address(0), (int)(long)h, buf);

        return mr_dlsym_handle(h, buf);
    }
}

/* dlclose does NOT unload, and says so rather than pretending.
 *
 * machorun never unmaps an image: the loader has no teardown path, objc4 has
 * registered classes out of it, and a later dlopen of the same path returns the
 * same handle by design. Darwin's dlclose returns 0 on success, and success is
 * a fair description of "your reference is dropped" -- what it is not is a
 * promise that the code went away, and nothing in the corpus depends on that.
 * Returning non-zero would make a guest think the close FAILED, which is a
 * different and wronger claim.
 *
 * dlclose(NULL) returns non-zero on Darwin, which is also what glibc's would do
 * if it did not first dereference the pointer and SIGSEGV -- measured. */
EXPORT int dlclose(void *h) { return h ? 0 : 1; }
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
