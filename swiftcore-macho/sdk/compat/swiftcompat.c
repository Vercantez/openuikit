/* libswiftcompat.dylib — the exact gap between what our cross-built
 * libswiftCore.dylib imports and what machorun's self-hosted libSystem /
 * libc++ / libobjc export. The live export count is whatever
 * scripts/build_compat.sh prints after the disjointness assertion.
 *
 * This is deliberately a SEPARATE dylib in this repository rather than an edit
 * to machorun: it keeps the measurement honest (the gap stays visible and
 * countable) and leaves ~/machorun read-only.
 *
 * Symbols are grouped by how real the implementation is:
 *   REAL     — a correct implementation (the arithmetic builtins,
 *              dispatch_once_f).
 *   BENIGN   — correct for our purposes, where the Darwin behaviour is either
 *              trivially reproducible or genuinely unused off Apple hardware
 *              (availability checks, flockfile).
 *
 * There is no longer a BIND-ONLY class, and that is the point of this file's
 * one hard rule:
 *
 *   NOTHING HERE MAY DEFINE A SYMBOL machorun's userland ALREADY DEFINES.
 *
 * Not a corrected version, not a better version -- none. libswiftCore binds
 * most of these FLAT, so a duplicate is resolved by load order rather than by
 * which one is right, and the wrong winner fails somewhere else entirely. As
 * machorun's libSystem / libobjc / libc++abi grow real implementations, the
 * answer is to DELETE the family from this file, never to keep a second copy in
 * sync. scripts/build_compat.sh asserts the disjointness and fails the build
 * rather than shipping an overlap; ten symbols were removed on 2026-08-27 when
 * libc++abi landed, and the assertion is what stops them coming back.
 */
#include <stdint.h>
#include <stddef.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sched.h>
#include <time.h>

#define SHIM(name) __asm__(name) __attribute__((visibility("default")))

/* ---------------------------------------------------------------- REAL ----
 * 128-bit integer division. Darwin gets these from libcompiler_rt inside
 * libSystem. They cannot be written as `a / b` on __int128 — clang lowers that
 * back into a call to this very function — so this is an explicit restoring
 * long division, shared by all four entry points.
 */
typedef unsigned __int128 u128;
typedef signed   __int128 s128;

static u128 udivmod128(u128 n, u128 d, u128 *rem) {
    if (d == 0) { volatile int z = 0; return (u128)(1 / z); } /* trap like the real one */
    if (d > n) { if (rem) *rem = n; return 0; }
    /* Normalise: find the highest bit of d relative to n. */
    int shift = 0;
    u128 dd = d;
    while (dd <= n && !(dd >> 127)) { dd <<= 1; shift++; }
    if (dd > n) { dd >>= 1; shift--; }
    u128 q = 0;
    for (int i = shift; i >= 0; i--) {
        if (n >= dd) { n -= dd; q |= ((u128)1 << i); }
        dd >>= 1;
    }
    if (rem) *rem = n;
    return q;
}

u128 __udivti3(u128 a, u128 b) { return udivmod128(a, b, 0); }
u128 __umodti3(u128 a, u128 b) { u128 r; udivmod128(a, b, &r); return r; }

s128 __divti3(s128 a, s128 b) {
    int neg = 0;
    u128 ua, ub;
    if (a < 0) { ua = (u128)(-a); neg ^= 1; } else ua = (u128)a;
    if (b < 0) { ub = (u128)(-b); neg ^= 1; } else ub = (u128)b;
    u128 q = udivmod128(ua, ub, 0);
    return neg ? -(s128)q : (s128)q;
}

s128 __modti3(s128 a, s128 b) {
    int neg = (a < 0);
    u128 ua = (a < 0) ? (u128)(-a) : (u128)a;
    u128 ub = (b < 0) ? (u128)(-b) : (u128)b;
    u128 r;
    udivmod128(ua, ub, &r);
    return neg ? -(s128)r : (s128)r;
}

/* DELETED 2026-09-03: getline, getsectiondata, strtod_l / strtof_l / strtold_l,
 * os_system_version_get_current_version, malloc_zone_from_ptr,
 * pthread_get_stackaddr_np, pthread_get_stacksize_np.
 *
 * machorun's libSystem (darwin/src/libsystem.c) now exports all nine. The
 * x86_64 in-tree dylib grades them as overlap, and build_compat.sh refuses to
 * emit a colliding shim. Same rule as the 2026-08-27 libc++abi cut: delete
 * from this file, do not keep a second copy.
 */

/* ---------------------------------------------------------------- REAL ----
 * Mach-O header type for _NSGetMachExecuteHeader. Layout constants are from
 * the Mach-O format, not from an Apple header.
 */
struct mh { uint32_t magic, cputype, cpusubtype, filetype, ncmds, sizeofcmds, flags, reserved; };

/* _NSGetMachExecuteHeader: the main executable's header. machorun's libSystem
 * exports no dyld image APIs at all (it has only the _NSGetArgc/Argv family),
 * so this uses the other Darwin idiom: every Mach-O executable defines
 * __mh_execute_header, and a dylib referencing it gets the *host program's*
 * header bound at load time. */
extern const struct mh __mh_execute_header __attribute__((weak_import));
const struct mh *_NSGetMachExecuteHeader(void) {
    /* weak_import: machorun's flat lookup does not surface symbols the main
     * executable defines, so this can legitimately be absent. The runtime's one
     * caller treats NULL as "no sections to register from the main image". */
    return &__mh_execute_header ? &__mh_execute_header : (const struct mh *)0;
}

/* ---------------------------------------------------------------- REAL ----
 * dispatch_once_f. libdispatch's one-shot, with the same "run exactly once,
 * later callers observe the result" contract, built on pthread_once semantics
 * via an atomic state machine.
 */
typedef long dispatch_once_t;
void dispatch_once_f(dispatch_once_t *pred, void *ctx, void (*fn)(void *)) {
    long observed = __atomic_load_n(pred, __ATOMIC_ACQUIRE);
    if (observed == 2) return;
    long expected = 0;
    if (__atomic_compare_exchange_n(pred, &expected, 1, 0,
                                    __ATOMIC_ACQUIRE, __ATOMIC_ACQUIRE)) {
        fn(ctx);
        __atomic_store_n(pred, 2, __ATOMIC_RELEASE);
        return;
    }
    while (__atomic_load_n(pred, __ATOMIC_ACQUIRE) != 2) sched_yield();
}

/* -------------------------------------------------------------- BENIGN ----
 * Availability. Every check is against the deployment target of a system we
 * are emulating in full, so "yes" is the honest answer here.
 */
int32_t __isPlatformVersionAtLeast(uint32_t p, uint32_t ma, uint32_t mi, uint32_t su) {
    (void)p; (void)ma; (void)mi; (void)su; return 1;
}
int32_t __isPlatformOrVariantPlatformVersionAtLeast(uint32_t p, uint32_t ma, uint32_t mi,
                                                    uint32_t su, uint32_t p2, uint32_t ma2,
                                                    uint32_t mi2, uint32_t su2) {
    (void)p; (void)ma; (void)mi; (void)su; (void)p2; (void)ma2; (void)mi2; (void)su2; return 1;
}
int _dyld_is_objc_constant(const void *p) { (void)p; return 0; }

/* stdio locking: machorun is not multiplexing FILE* across threads. */
void flockfile(FILE *f)   { (void)f; }
void funlockfile(FILE *f) { (void)f; }

/* ----------------------------------------------------------------- C++ ----
 * libc++ / libc++abi pieces machorun's 60 KB libc++.1.dylib does not carry.
 */
void libcpp_verbose_abort(const char *fmt, ...) SHIM("__ZNSt3__122__libcpp_verbose_abortEPKcz");
void libcpp_verbose_abort(const char *fmt, ...) { (void)fmt; abort(); }

unsigned hardware_concurrency(void) SHIM("__ZNSt3__16thread20hardware_concurrencyEv");
unsigned hardware_concurrency(void) {
    long n = sysconf(_SC_NPROCESSORS_ONLN);
    return n > 0 ? (unsigned)n : 1u;
}

/* std::operator+(const char*, const std::string&). libc++'s std::string is
 * layout-stable across the ABI, so this is expressed in C++ in shim.cpp
 * rather than reconstructed here. */

/* DELETED 2026-08-27: the five __cxxabiv1 type_info vtables, __cxa_demangle
 * and operator delete(void*, size_t, align_val_t).
 *
 * machorun now builds LLVM 18.1.8's libc++abi as a real /usr/lib/libc++abi.dylib
 * and has real definitions of all seven. Ours were worse than redundant: the
 * vtables were `const void *[8] = {0,...}`, which clang places in
 * (__DATA,__common) -- ZEROFILL, no contents in the file at all. libswiftCore
 * binds all of them FLAT ("dynamically looked up"), so which definition wins is
 * decided by load order alone. libc++abi happens to load first today, so the
 * real ones win; a guest that links its dylibs in a different order gets a
 * vtable pointer into zeroed memory, and __gxx_personality_v0 dispatches
 * through exactly those vtables to match a catch. The failure would have been a
 * jump through NULL during exception dispatch, arbitrarily far from the cause.
 *
 * Deleting beats correcting. Two definitions of one symbol is the defect that
 * kept the malloc_type fix unreachable for a week (machorun
 * docs/STATUS.md, "umbrella shadows reexport"), and a corrected duplicate is
 * still a duplicate. The build now refuses to produce a shim that overlaps
 * machorun's userland at all -- see the disjointness assertion at the end of
 * scripts/build_compat.sh, which is what keeps this from growing back. */

/* ------------------------------------------------- _Concurrency additions ---
 * The gap measured against Apple's shipped libswift_Concurrency, minus the 13
 * dispatch symbols (the cooperative executor references none of them -- which
 * is itself a check on the build: if a dispatch symbol shows up here, the wrong
 * executor got compiled in).
 */
/* DELETED 2026-08-27: __cxa_pure_virtual (libc++abi has it) and
 * pthread_main_np (machorun's libSystem has it, darwin/src/posix.c).
 *
 * pthread_main_np is the one to remember. Ours was `return 1` with the comment
 * "single-threaded executor" -- true of the fixture that motivated it and false
 * of every program with a second thread, since a constant 1 makes EVERY thread
 * answer "yes, I am the main thread". machorun's records the main thread at
 * bootstrap and compares pthread_self against it, which is exact. Ours would
 * have won by load order and silently broken every @MainActor assertion and
 * libdispatch's main-queue check. It was never reached only because it was
 * never built: the shipped shim predates this line. */

unsigned qos_class_self(void);
unsigned qos_class_self(void) { return 0x21; }  /* QOS_CLASS_USER_INITIATED */

int memset_s(void *d, size_t dn, int c, size_t n);
int memset_s(void *d, size_t dn, int c, size_t n) {
    if (!d) return 22; if (n > dn) { memset(d, c, dn); return 34; }
    memset(d, c, n); return 0;
}

/* clock_getres is already declared by our sysroot's <time.h>; match it exactly
 * rather than redeclare, and forward to glibc through the loader's boundary. */
extern int glibc_clock_getres(clockid_t, struct timespec *) __asm__("_glibc_clock_getres");
int clock_getres(clockid_t id, struct timespec *ts) { return glibc_clock_getres(id, ts); }

/* DELETED 2026-08-27: malloc_type_malloc. machorun's libSystem implements the
 * whole family, and this project has already paid once for a second copy of it:
 * a shadowing definition is what made the loader's malloc_type fix unreachable
 * while every git-level check said the tree was current. One copy, in the
 * library that owns the allocator. */

/* os_log / os_signpost: telemetry only. No-ops that keep the shape. */
void *os_log_create(const char *s, const char *c);
void *os_log_create(const char *s, const char *c) { (void)s; (void)c; return (void *)1; }
void os_release(void *p);
void os_release(void *p) { (void)p; }
int  os_signpost_enabled(void *l);
int  os_signpost_enabled(void *l) { (void)l; return 0; }
unsigned long long os_signpost_id_generate(void *l);
unsigned long long os_signpost_id_generate(void *l) { (void)l; return 0; }
unsigned long long os_signpost_id_make_with_pointer(void *l, const void *p);
unsigned long long os_signpost_id_make_with_pointer(void *l, const void *p) { (void)l; (void)p; return 0; }

/* Mach vouchers: QoS propagation across queues. There are no queues here. */
void *voucher_copy(void);
void *voucher_copy(void) { return 0; }
void *voucher_adopt(void *v);
void *voucher_adopt(void *v) { (void)v; return 0; }

int csops(int pid, unsigned int ops, void *useraddr, size_t usersize);
int csops(int pid, unsigned int ops, void *useraddr, size_t usersize) {
    (void)pid; (void)ops; (void)useraddr; (void)usersize; return -1;
}
