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
 * succeed is a LOUD ABORT, never a silent no-op. A renderer that runs one
 * scene to completion synchronously never enqueues onto a dispatch queue,
 * never creates a timer source and never adopts a voucher -- so if any of
 * these is entered, that assumption is wrong and it must say so rather than
 * quietly producing a subtly different picture. Anything genuinely trivial and
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
STUB(dispatch_async_swift_job)
STUB(dispatch_get_global_queue)
STUB(dispatch_main)
STUB(dispatch_release)
STUB(dispatch_set_context)
STUB(dispatch_source_create)
STUB(dispatch_source_set_event_handler_f)
STUB(dispatch_source_set_timer)

/* dispatch_assert_queue$V2 -- the `$` is not a C identifier character, so the
 * symbol is named with an asm label rather than by spelling the function. */
__attribute__((noreturn)) void conc_dispatch_assert_queue_v2(void) __asm__("_dispatch_assert_queue$V2");
__attribute__((noreturn)) void conc_dispatch_assert_queue_v2(void) { conc_abort("dispatch_assert_queue$V2"); }

/* ---- vouchers, signposts, os_object ------------------------------------- */
STUB(voucher_adopt)
STUB(voucher_copy)
STUB(os_release)
STUB(os_signpost_id_make_with_pointer)

/* ---- REAL implementations ----------------------------------------------- */

/* qos_class_self: this process has exactly one thread of interest and no QoS
 * plumbing, so it is QOS_CLASS_DEFAULT (0x15, <sys/qos.h>). Returning the
 * truth is cheaper and safer than aborting -- the Swift runtime calls this
 * while deciding executor priorities, on the synchronous path. */
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
 * alignment is maximal. Nothing on the synchronous render path dereferences
 * them -- the functions that would are the aborting stubs above. */
__attribute__((aligned(16))) unsigned char _dispatch_main_q[256] = {0};
__attribute__((aligned(16))) unsigned char _dispatch_source_type_timer[256] = {0};

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
