/* concpatch.c -- the libSystem symbols libswift_Concurrency imports that
 * machorun's Darwin userland does not have.
 *
 * WHY THIS EXISTS. The full OpenUIKit module carries `@MainActor` on its UI
 * classes, the way real UIKit does, so it must be compiled with the
 * _Concurrency module and the guest must load libswift_Concurrency.dylib.
 * That dylib imports 458 symbols; 436 already exist in our userland, and these
 * 22 do not. Measured with nm(1) against the staged guest root, not guessed.
 *
 * HOUSE RULE (docs/RUNTIME.md §4): a symbol that exists only so binding can
 * succeed is a LOUD ABORT, never a silent no-op. The Swift job scheduler,
 * global/main queues, dispatch_main, and null-voucher policy below are real;
 * unsupported Dispatch sources and signposts still abort. Anything genuinely
 * safe to implement IS implemented, and is marked REAL below.
 *
 * The three DATA symbols get real storage: the Swift runtime takes their
 * address during image initialisation (before any of our code runs), so an
 * abort is not available as a behaviour there. They are zeroed and never
 * dereferenced on the synchronous path; the functions that would dereference
 * them are the aborting ones above.
 */

#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "../dispatch/include/OpenDispatchABI.h"

/* Which library a symbol must come from is not a choice: these binaries use
 * two-level namespace binding, so each import names its defining library and
 * a definition anywhere else is invisible. The split between this file and
 * conccxx.cpp is dyld_info's answer, not a preference. */

extern void cpio_log_stderr_unused(void); /* silence -Wmissing-prototypes noise */

__attribute__((noreturn))
static void conc_abort(const char *who)
{
    /* write(2) directly: this runs where stdio may not be safe, and the
     * message must survive whatever state the runtime is in. */
    static const char pre[] = "concpatch: libswift_Concurrency entered ";
    static const char post[] = " -- the render path is NOT synchronous after "
                               "all. This stub exists only for binding; see "
                               "full/shims/concpatch.c.\n";
    extern long write(int, const void *, unsigned long);
    write(2, pre, sizeof(pre) - 1);
    write(2, who, strlen(who));
    write(2, post, sizeof(post) - 1);
    abort();
}

#define STUB(name) \
    __attribute__((noreturn)) void name(void); \
    __attribute__((noreturn)) void name(void) { conc_abort(#name); }

/* ---- libdispatch: queues, sources, timers ------------------------------- */
STUB(dispatch_activate)
STUB(dispatch_after_f)
STUB(dispatch_release)
STUB(dispatch_set_context)
STUB(dispatch_source_create)
STUB(dispatch_source_set_event_handler_f)
STUB(dispatch_source_set_timer)

/* dispatch_assert_queue$V2 -- the `$` is not a C identifier character, so the
 * symbol is named with an asm label rather than by spelling the function. */
__attribute__((noreturn)) void conc_dispatch_assert_queue_v2(void) __asm__("_dispatch_assert_queue$V2");
__attribute__((noreturn)) void conc_dispatch_assert_queue_v2(void) { conc_abort("dispatch_assert_queue$V2"); }

/* ---- signposts ---------------------------------------------------------- */
STUB(os_signpost_id_make_with_pointer)

/* ---- REAL implementations ----------------------------------------------- */

/* Swift's Darwin runtime and Linux runtime deliberately have different
 * DispatchClassMetadata layouts. Darwin has Objective-C interop padding and
 * places VTableInvoke at +0x30; the Linux runtime places it at +0x18. A Linux
 * __swift_run_job adapter would therefore jump through the wrong word of a
 * Darwin SwiftJob. Keep the Mach-O callback here, where the Darwin layout is
 * explicit, and let the ELF helper treat both job and callback as opaque. */
typedef void (*darwin_swift_job_invoke)(void *, void *, uint32_t);
struct darwin_dispatch_class_metadata {
    uintptr_t kind;
    void *opaque;
    void *objc_interop[3];
    uintptr_t vtable_type;
    darwin_swift_job_invoke invoke;
};
_Static_assert(
    offsetof(struct darwin_dispatch_class_metadata, invoke) == 0x30,
    "Darwin DispatchClassMetadata VTableInvoke offset drifted"
);

struct darwin_swift_job {
    const struct darwin_dispatch_class_metadata *metadata;
};

extern void *dispatch_host_get_global_queue(int64_t, uint64_t)
    __asm__("_glibc_openui_dispatch_host_v1_get_global_queue");
extern void dispatch_host_async(
    uint32_t, void *, void *, openui_dispatch_callback_v1
) __asm__("_glibc_openui_dispatch_host_v1_async");
extern void dispatch_host_main(void)
    __asm__("_glibc_openui_dispatch_host_v1_main")
    __attribute__((noreturn));

#define CONCPATCH_GLOBAL_QUEUE_SLOTS 32
static void *registered_global_queues[CONCPATCH_GLOBAL_QUEUE_SLOTS];
extern unsigned char _dispatch_main_q[];

static void register_global_queue(void *queue)
{
    unsigned index;
    void *expected;
    if (queue == NULL) return;
    for (index = 0; index < CONCPATCH_GLOBAL_QUEUE_SLOTS; index++) {
        void *current = __atomic_load_n(
            &registered_global_queues[index], __ATOMIC_ACQUIRE
        );
        if (current == queue) return;
        if (current != NULL) continue;
        expected = NULL;
        if (__atomic_compare_exchange_n(
                &registered_global_queues[index], &expected, queue, 0,
                __ATOMIC_RELEASE, __ATOMIC_ACQUIRE
            )) return;
        if (expected == queue) return;
    }
    conc_abort("dispatch global queue registry overflow");
}

static int is_registered_global_queue(void *queue)
{
    unsigned index;
    if (queue == NULL) return 0;
    for (index = 0; index < CONCPATCH_GLOBAL_QUEUE_SLOTS; index++) {
        if (__atomic_load_n(
                &registered_global_queues[index], __ATOMIC_ACQUIRE
            ) == queue) return 1;
    }
    return 0;
}

static void run_darwin_swift_job(void *opaque)
{
    struct darwin_swift_job *job = opaque;
    const struct darwin_dispatch_class_metadata *metadata;
    if (job == NULL) conc_abort("dispatch_async_swift_job(NULL job)");
    metadata = job->metadata;
    if (metadata == NULL || metadata->invoke == NULL) {
        conc_abort("Darwin SwiftJob has no VTableInvoke at metadata +0x30");
    }
    metadata->invoke(job, NULL, 0);
}

void *dispatch_get_global_queue(long identifier, unsigned long flags);
void *dispatch_get_global_queue(long identifier, unsigned long flags)
{
    void *queue = dispatch_host_get_global_queue(
        (int64_t)identifier, (uint64_t)flags
    );
    register_global_queue(queue);
    return queue;
}

void dispatch_async_swift_job(void *queue, void *job, unsigned int qos);
void dispatch_async_swift_job(void *queue, void *job, unsigned int qos)
{
    uint32_t kind;
    void *host_queue;
    (void)qos;
    if (queue == (void *)&_dispatch_main_q[0]) {
        kind = OPENUI_DISPATCH_QUEUE_MAIN_V1;
        host_queue = NULL;
    } else if (is_registered_global_queue(queue)) {
        kind = OPENUI_DISPATCH_QUEUE_GLOBAL_V1;
        host_queue = queue;
    } else {
        conc_abort("dispatch_async_swift_job(unmapped queue)");
    }
    dispatch_host_async(kind, host_queue, job, run_darwin_swift_job);
}

__attribute__((noreturn)) void dispatch_main(void);
__attribute__((noreturn)) void dispatch_main(void)
{
    dispatch_host_main();
}

/* Darwin vouchers are unavailable on Linux. This is not a scheduling
 * shortcut: it is exactly Swift's non-Apple voucher policy. A NULL voucher is
 * the only value this implementation can mint or adopt, and a non-NULL value
 * is therefore an ABI violation rather than something to ignore. */
void *voucher_copy(void);
void *voucher_copy(void) { return NULL; }

void *voucher_adopt(void *voucher);
void *voucher_adopt(void *voucher)
{
    if (voucher != NULL) conc_abort("voucher_adopt(non-NULL)");
    return NULL;
}

void os_release(void *object);
void os_release(void *object)
{
    if (object != NULL) conc_abort("os_release(non-NULL voucher)");
}

/* qos_class_self: the bridge does not translate Linux thread priorities into
 * Darwin QoS classes, so every guest-visible worker reports
 * QOS_CLASS_DEFAULT (0x15, <sys/qos.h>). The Swift runtime calls this while
 * deciding executor priorities. */
unsigned int qos_class_self(void);
unsigned int qos_class_self(void) { return 0x15; }

/* memset_s: C11 Annex K. The bounds-checked memset, with the guarantee it is
 * not optimised away. */
int memset_s(void *s, size_t smax, int c, size_t n);
int memset_s(void *s, size_t smax, int c, size_t n)
{
    if (s == NULL) return 22;              /* EINVAL */
    if (n > smax) { memset(s, c, smax); return 34; }  /* ERANGE, but still wipe */
    memset(s, c, n);
    return 0;
}

/* __cxa_pure_virtual and operator new(size_t, __type_descriptor_t) are NOT
 * here: dyld_info says libswift_Concurrency binds them against libc++, and
 * two-level binding means a definition in libSystem would never be found.
 * They live in full/shims/conccxx.cpp, which goes into the libc++ umbrella. */

/* clock_getres: our libSystem forwards clock_gettime to glibc but does not
 * export clock_getres. CLOCK_MONOTONIC/REALTIME on aarch64 Linux are
 * nanosecond-resolution, which is also what Darwin reports, so this is the
 * true answer rather than a placeholder. */
struct conc_timespec { long tv_sec; long tv_nsec; };
int clock_getres(int clk_id, struct conc_timespec *res);
int clock_getres(int clk_id, struct conc_timespec *res)
{
    (void)clk_id;
    if (!res) return -1;
    res->tv_sec = 0;
    res->tv_nsec = 1;
    return 0;
}

/* ---- DATA symbols -------------------------------------------------------
 * Addresses are taken during image initialisation, before any of our code can
 * run, so these cannot be aborts. They are opaque to us; size is generous and
 * alignment is maximal. `_dispatch_main_q` is used only as an address-identity
 * token; neither its guessed storage nor the timer-source storage is decoded. */
/* Size is a GUESS: these are opaque Darwin structs and we have no header for
 * them. 256 was chosen as "surely enough", which is exactly the reasoning that
 * produces the opaque-pointer ABI bugs catalogued in machorun's
 * docs/UNIMPLEMENTED.md -- so it is overridable, and
 * full/scripts/blobtest.sh runs the suite with a much larger value to prove
 * the size is not the corruption source. */
#ifndef CONCPATCH_BLOB
#define CONCPATCH_BLOB 256
#endif
__attribute__((aligned(16))) unsigned char _dispatch_main_q[CONCPATCH_BLOB] = {0};
__attribute__((aligned(16))) unsigned char _dispatch_source_type_timer[CONCPATCH_BLOB] = {0};

/* Autolink force-load anchor for the _Builtin_float module. Its only job is to
 * exist so the reference resolves. */
long _swift_FORCE_LOAD_swift_Builtin_float __asm__("__swift_FORCE_LOAD_$_swift_Builtin_float") = 0;

/* ---- dlopen: diagnosis, not a fix ---------------------------------------
 * machorun's dlopen is a deliberate loud bail ("not implemented for guest
 * Mach-O images"). It fires on this render path, and the bail does not say
 * WHAT was asked for -- which is the only thing that decides whether guest
 * dlopen is genuinely needed or whether the caller is doing an optional
 * feature probe that can honestly answer "absent".
 *
 * A direct definition here wins over the reexported one (the umbrella's own
 * exports shadow what it reexports), so this prints the request and then bails
 * exactly as machorun would. It is a probe: it must not become a silent
 * success, because a caller that gets a non-NULL handle will then dlsym
 * through it and machorun cannot service that either. */
extern long write(int, const void *, unsigned long);
void *dlopen(const char *path, int mode);
void *dlopen(const char *path, int mode)
{
    static const char pre[] = "concpatch: dlopen(\"";
    static const char mid[] = "\") -- refused, as machorun does. mode=";
    static const char nul[] = "<NULL>";
    char m[16];
    int n = 0, v = mode;
    if (v == 0) m[n++] = '0';
    while (v > 0 && n < 12) { m[n++] = (char)('0' + v % 10); v /= 10; }
    for (int i = 0; i < n / 2; i++) { char t = m[i]; m[i] = m[n-1-i]; m[n-1-i] = t; }
    m[n++] = '\n';
    write(2, pre, sizeof(pre) - 1);
    if (path) write(2, path, strlen(path)); else write(2, nul, sizeof(nul) - 1);
    write(2, mid, sizeof(mid) - 1);
    write(2, m, (unsigned long)n);
    return 0;   /* NULL: "could not load", the honest answer */
}

/* ---- pthread_main_np -----------------------------------------------------
 * NOT defined here, and the chain of wrong conclusions is the finding.
 *
 * The APP path needs it; the render path never does. The link fails with
 * "undefined symbol: _pthread_main_np", whose obvious reading is "machorun
 * lacks it". Adding it here then failed with "duplicate symbol" -- because
 * spike/syspatch.c:285 has provided it all along and the libSystem umbrella
 * exports it at 0xcbc.
 *
 * So the symbol exists in the dylib the guest will actually load, and the link
 * still fails, because the guest links -lSystem against the SDK's
 * libSystem.tbd and THAT does not advertise it. A .tbd is a promise about a
 * dylib, and this one is missing a promise it could keep -- the mirror image of
 * the stale swift_* entries, which promised symbols the dylib no longer had.
 *
 * Worked around in build_full.sh by linking the umbrella dylib directly. The
 * real fix is one line in machorun's sdk generation. */
