/* syspatch.c -- the libSystem symbols the iOS-simulator libswiftCore.dylib and
 * libswiftObjectiveC.dylib import that machorun's /usr/lib/libSystem.B.dylib
 * does not export. Built into an UMBRELLA libSystem.B.dylib that defines these
 * and LC_REEXPORT_DYLIBs machorun's real libSystem (staged as libSystem.real.dylib).
 *
 * Measured set: dyld_info -imports on each swift dylib, minus machorun's
 * libSystem exports. 46 for libswiftCore, 1 for libswiftObjectiveC. Concurrency
 * is not staged (no async on the drawing path) so its dispatch/voucher imports
 * are out of scope here.
 *
 * Three honesty tiers:
 *   REAL     -- behaviour the drawing path can depend on: 128-bit divide,
 *               dispatch_once_f, getsectiondata, malloc_type_*, the strtod_l
 *               family, the main-executable header.
 *   FALLBACK -- returns the value that means "no preoptimized data / not found",
 *               which is the TRUTH under machorun (no dyld shared cache). Swift
 *               then takes its own scan path. Correct, not a lie.
 *   STUB     -- os_log / signpost / asl logging and a couple of never-hit
 *               parsers: no-ops, so logging silently does nothing.
 *
 * asm() labels pin the exact Mach-O symbol names.
 */
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <mach-o/loader.h>

/* machorun's real libSystem provides these; reachable because we reexport it. */
extern void   *malloc(size_t);
extern void   *calloc(size_t, size_t);
extern void   *realloc(void *, size_t);
extern int     posix_memalign(void **, size_t, size_t);
extern double  strtod(const char *, char **);
extern long    sysconf(int);
extern int     pthread_mutex_lock(void *);
extern int     pthread_mutex_unlock(void *);

/* ============================ REAL ============================ */

/* 128-bit integer divide/modulo -- compiler-rt builtins the stdlib's
 * Int128/UInt128 paths reference. One right answer each. */
__int128 di3(__int128 a, __int128 b) asm("___divti3");
__int128 mi3(__int128 a, __int128 b) asm("___modti3");
unsigned __int128 udi3(unsigned __int128 a, unsigned __int128 b) asm("___udivti3");
unsigned __int128 umi3(unsigned __int128 a, unsigned __int128 b) asm("___umodti3");
__int128 di3(__int128 a, __int128 b) { return a / b; }
__int128 mi3(__int128 a, __int128 b) { return a % b; }
unsigned __int128 udi3(unsigned __int128 a, unsigned __int128 b) { return a / b; }
unsigned __int128 umi3(unsigned __int128 a, unsigned __int128 b) { return a % b; }

/* dispatch_once_f: the one-time-init primitive swift_once sits on. The DONE
 * sentinel libdispatch uses (and the inlined fast path in libswiftCore checks)
 * is ~0l. This MUST be per-token, not a shared lock: the Swift runtime nests
 * swift_once on DIFFERENT tokens (one lazy init drives another), and a single
 * global mutex deadlocks the moment the fn() body enters a second once. A
 * per-token CAS state machine (0 -> RUNNING -> DONE) has no cross-token lock, so
 * nesting on distinct tokens is free; genuine same-token recursion still spins,
 * exactly as libdispatch would. */
#define MR_ONCE_RUNNING 1l
void mr_dispatch_once_f(long *pred, void *ctx, void (*fn)(void *)) asm("_dispatch_once_f");
void mr_dispatch_once_f(long *pred, void *ctx, void (*fn)(void *))
{
    if (__atomic_load_n(pred, __ATOMIC_ACQUIRE) == ~0l) return;
    long expected = 0;
    if (__atomic_compare_exchange_n(pred, &expected, MR_ONCE_RUNNING, 0,
                                    __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE)) {
        fn(ctx);
        __atomic_store_n(pred, ~0l, __ATOMIC_RELEASE);
    } else {
        while (__atomic_load_n(pred, __ATOMIC_ACQUIRE) != ~0l)
            __asm__ __volatile__("yield");
    }
}

/* ---- shared section finder: match by SECTION name across all segments,
 * returning the slid address + size. Segment-name-agnostic so it serves both
 * __TEXT swift5 sections and __DATA objc sections. slide = header addr minus
 * the __TEXT preferred vmaddr, exactly as cctools' getsectiondata computes. */
static uint8_t *find_section(const struct mach_header_64 *mh, const char *sect,
                             size_t *size_out)
{
    if (size_out) *size_out = 0;
    if (!mh || mh->magic != MH_MAGIC_64) return NULL;
    uintptr_t slide = 0; int have_slide = 0;
    const struct load_command *lc = (const struct load_command *)(mh + 1);
    for (uint32_t i = 0; i < mh->ncmds; i++) {
        if (lc->cmd == LC_SEGMENT_64) {
            const struct segment_command_64 *sc = (const void *)lc;
            if (!have_slide && strcmp(sc->segname, "__TEXT") == 0) {
                slide = (uintptr_t)mh - (uintptr_t)sc->vmaddr; have_slide = 1;
            }
        }
        lc = (const void *)((const char *)lc + lc->cmdsize);
    }
    lc = (const struct load_command *)(mh + 1);
    for (uint32_t i = 0; i < mh->ncmds; i++) {
        if (lc->cmd == LC_SEGMENT_64) {
            const struct segment_command_64 *sc = (const void *)lc;
            const struct section_64 *s = (const void *)(sc + 1);
            for (uint32_t j = 0; j < sc->nsects; j++, s++)
                if (strncmp(s->sectname, sect, 16) == 0) {
                    if (size_out) *size_out = (size_t)s->size;
                    return (uint8_t *)(s->addr + slide);
                }
        }
        lc = (const void *)((const char *)lc + lc->cmdsize);
    }
    return NULL;
}

/* getsectiondata(mh, seg, sect, size): the cctools shape (seg is ignored, we
 * match on section name -- unique in practice). Swift's fallback path uses it. */
uint8_t *mr_getsectiondata(const struct mach_header_64 *mh, const char *seg,
                           const char *sect, unsigned long *size) asm("_getsectiondata");
uint8_t *mr_getsectiondata(const struct mach_header_64 *mh, const char *seg,
                           const char *sect, unsigned long *size)
{
    (void)seg; size_t n = 0;
    uint8_t *p = find_section(mh, sect, &n);
    if (size) *size = (unsigned long)n;
    return p;
}

/* ---- _dyld_lookup_section_info: THE reconciliation point.
 *
 * machorun's loader implements this with an OLD objc-only dyld_section_kind
 * enum (0=__objc_classlist ... 14=__objc_imageinfo). The iOS-simulator
 * libswiftCore was built against a NEWER dyld_priv.h whose enum puts the Swift
 * sections FIRST (measured from libswiftCore's own callback symbol names:
 * kind 0=__swift5_protos, 1=__swift5_proto, 2=__swift5_types,
 * 3=__swift5_replace, 4=__swift5_replac2, 5=__swift5_acfuncs). The two enums
 * collide on 0..5, and machorun's own vendored objc4 ALSO calls this function
 * with the old enum -- so a single static table cannot serve both.
 *
 * Both callers reach this override (libswiftCore two-level from libSystem;
 * machorun's objc4 flat-namespace, which finds our libSystem export before the
 * loader's). We disambiguate by the return address: walk it down to the
 * caller's mach header and read its LC_ID_DYLIB. libswiftCore -> Swift enum;
 * anything else (objc4) -> the loader's objc enum, reproduced here. No image
 * escapes: objc4 gets byte-identical answers to the loader's, Swift gets the
 * sections it actually asked for. */
struct mr_secresult { void *buffer; size_t bufferSize; };

static const char *caller_id(void *ra)
{
    /* __TEXT is page-aligned and contiguous; scan down to the MH_MAGIC_64. */
    uintptr_t p = (uintptr_t)ra & ~0xFFFull;
    for (int steps = 0; steps < 8192; steps++, p -= 0x1000) {
        const struct mach_header_64 *mh = (const struct mach_header_64 *)p;
        if (mh->magic != MH_MAGIC_64) continue;
        if (mh->filetype != MH_DYLIB && mh->filetype != MH_EXECUTE) continue;
        const struct load_command *lc = (const struct load_command *)(mh + 1);
        for (uint32_t i = 0; i < mh->ncmds; i++) {
            if (lc->cmd == LC_ID_DYLIB) {
                const struct dylib_command *dc = (const void *)lc;
                return (const char *)lc + dc->dylib.name.offset;
            }
            lc = (const void *)((const char *)lc + lc->cmdsize);
        }
        return NULL;   /* found a header but no id (e.g. the main exe) */
    }
    return NULL;
}

/* the Swift enum, measured from libswiftCore's callback symbols */
static const char *swift_sectname(int kind)
{
    switch (kind) {
        case 0: return "__swift5_protos";
        case 1: return "__swift5_proto";
        case 2: return "__swift5_types";
        case 3: return "__swift5_replace";
        case 4: return "__swift5_replac2";
        case 5: return "__swift5_acfuncs";
        default: return NULL;
    }
}
/* the loader's objc enum (machorun src/objc_notify.c kind_sectname[]) */
static const char *objc_sectname(int kind)
{
    static const char *const t[] = {
        "__objc_classlist","__objc_nlclslist","__objc_classrefs","__objc_superrefs",
        "__objc_protolist","__objc_protorefs","__objc_selrefs","__objc_msgrefs",
        "__objc_catlist","__objc_catlist2","__objc_nlcatlist","__objc_stublist",
        "__objc_fork_ok","__objc_rawisa","__objc_imageinfo",
    };
    return (kind >= 0 && kind < (int)(sizeof t / sizeof t[0])) ? t[kind] : NULL;
}

struct mr_secresult
mr_lookup_section_info(const void *mh, void *info, int kind) asm("__dyld_lookup_section_info");
struct mr_secresult
mr_lookup_section_info(const void *mh, void *info, int kind)
{
    (void)info;
    struct mr_secresult r = { NULL, 0 };
    const char *id = caller_id(__builtin_return_address(0));
    /* any Swift runtime dylib uses the Swift enum; objc4 (libobjc) the objc one */
    const char *sect = (id && strstr(id, "libswift"))
                       ? swift_sectname(kind) : objc_sectname(kind);
    if (!sect) return r;
    size_t n = 0;
    void *p = find_section((const struct mach_header_64 *)mh, sect, &n);
    r.buffer = p; r.bufferSize = p ? n : 0;
    return r;
}

/* The main executable's mach header. Bound flat to __mh_execute_header, which
 * the guest exe is linked -export_dynamic so it lands in the export trie. */
extern struct mach_header_64 mr_mh_exec asm("__mh_execute_header");
struct mach_header_64 *mr_NSGetMachExecuteHeader(void) asm("__NSGetMachExecuteHeader");
struct mach_header_64 *mr_NSGetMachExecuteHeader(void) { return &mr_mh_exec; }

/* TYPED MALLOC IS DELIBERATELY NOT DEFINED HERE ANY MORE. It used to be, and
 * that was the single worst bug this project has had.
 *
 * `malloc_type_zone_malloc_with_options_internal` takes FIVE parameters and
 * `size` is the THIRD (malloc/malloc.h:192). This file declared FOUR and
 * forwarded the second -- the ALIGNMENT -- to malloc as the size. It compiled
 * to `mov x0, x1; b _malloc`, so every allocation through that entry point got
 * a block the size of its own alignment, sixteen bytes whatever was asked for,
 * and the caller wrote its whole object over the neighbours. That was the
 * entirety of the "46 UIKit scenes fail with nondeterministic memory
 * corruption" wall: 22 glibc heap aborts, 19 SIGSEGVs on wild addresses and 9
 * silent failures, no two alike, because a heap overflow of arbitrary size
 * onto arbitrary neighbours never fails the same way twice.
 *
 * Only Apple's SHIPPED libswiftCore reaches it -- ours calls plain
 * malloc/calloc/realloc -- which is why the failure looked like a property of
 * the runtime rather than of this file.
 *
 * machorun now defines the whole family correctly (0f39750,
 * darwin/src/objcsupport.c) and this umbrella REEXPORTS machorun's libSystem.
 * A definition here SHADOWS that reexport, so re-adding any of them silently
 * reinstates the bug rather than colliding with the fix. One implementation,
 * and it is machorun's, where it is tested.
 *
 * If a malloc_type symbol ever comes up undefined again, add it to machorun,
 * NOT here -- and read the argument order off the header, because this family
 * mixes three orders and they are not guessable. */

/* strtod_l family: the locale argument is the C locale on this path; delegate. */
double      mr_strtod_l(const char *s, char **e, void *loc) asm("_strtod_l");
float       mr_strtof_l(const char *s, char **e, void *loc) asm("_strtof_l");
long double mr_strtold_l(const char *s, char **e, void *loc) asm("_strtold_l");
double      mr_strtod_l(const char *s, char **e, void *loc) { (void)loc; return strtod(s, e); }
float       mr_strtof_l(const char *s, char **e, void *loc) { (void)loc; return (float)strtod(s, e); }
long double mr_strtold_l(const char *s, char **e, void *loc) { (void)loc; return (long double)strtod(s, e); }

/* pthread stack bounds. The Swift runtime uses these to decide whether a
 * pointer lives on the stack; a FAKE high end (an 8 MB round-up of the current
 * SP, which lands ABOVE the real mapping) makes it treat heap metadata as a
 * stack scratch buffer and write past the stack top -- a SIGSEGV at a
 * 0x7fff... address inside swift_initClassMetadataImpl. So report the TRUE
 * bounds, read from glibc: pthread_getattr_np gives the LOW end + size, and
 * Darwin's _np returns the HIGH end (base of downward growth). */
extern unsigned long glibc_self(void) asm("_glibc_pthread_self");
extern int glibc_getattr_np(unsigned long, void *) asm("_glibc_pthread_getattr_np");
extern int glibc_attr_getstack(const void *, void **, size_t *) asm("_glibc_pthread_attr_getstack");
extern int glibc_attr_destroy(void *) asm("_glibc_pthread_attr_destroy");
#define MR_STK_FALLBACK (8ul << 20)
static int stack_bounds(void **lo_out, size_t *sz_out)
{
    unsigned char attr[128];   /* glibc pthread_attr_t is ~56 bytes on arm64 */
    void *lo = NULL; size_t sz = 0;
    if (glibc_getattr_np(glibc_self(), attr) != 0) return 0;
    int ok = glibc_attr_getstack(attr, &lo, &sz) == 0 && lo && sz;
    glibc_attr_destroy(attr);
    if (!ok) return 0;
    *lo_out = lo; *sz_out = sz; return 1;
}
void  *mr_pthread_stackaddr(void *t) asm("_pthread_get_stackaddr_np");
size_t mr_pthread_stacksize(void *t) asm("_pthread_get_stacksize_np");
void  *mr_pthread_stackaddr(void *t)
{
    (void)t; void *lo; size_t sz;
    if (stack_bounds(&lo, &sz)) return (unsigned char *)lo + sz;   /* high end */
    uintptr_t sp = (uintptr_t)&t;
    return (void *)((sp + MR_STK_FALLBACK - 1) & ~(MR_STK_FALLBACK - 1));
}
size_t mr_pthread_stacksize(void *t)
{
    (void)t; void *lo; size_t sz;
    if (stack_bounds(&lo, &sz)) return sz;
    return MR_STK_FALLBACK;
}

/* pthread_main_np: nonzero iff the calling thread is the process main thread.
 * The Swift MainActor default-isolation executor (swift_task_..MainActor..)
 * calls this to decide whether it is already running on the main thread.
 * The machorun guest runs the Swift runtime init and the whole render on its
 * initial thread; we lazily capture the first caller's pthread identity as
 * "main" (glibc_pthread_self, already bridged for the stack code) and report 1
 * for it, 0 for any other. Single-threaded render => always the main thread,
 * which is the truth. */
static unsigned long g_main_thread;   /* 0 until first call captures it */
int mr_pthread_main_np(void) asm("_pthread_main_np");
int mr_pthread_main_np(void)
{
    unsigned long self = glibc_self();
    if (g_main_thread == 0) g_main_thread = self;   /* first caller is main */
    return self == g_main_thread ? 1 : 0;
}

/* ---- reserved-key thread-local storage -----------------------------------
 * The Swift runtime's tls_init_once() claims Darwin RESERVED pthread key 100
 * (__PTK_FRAMEWORK_SWIFT_KEY0) and registers a destructor with
 * pthread_key_init_np(100, dtor); it then stores/reads its per-thread context
 * with the ordinary pthread_setspecific/getspecific(100, ...). machorun's
 * direct-TSD array stops at 64, so pthread_key_init_np(100) returns EINVAL and
 * Swift aborts "tls_init_once() failed to set destructor".
 *
 * We service the reserved range (>=100) ourselves out of a __thread array --
 * real per-thread storage via machorun's TLV support -- and delegate every
 * normal key straight to glibc, which is exactly where machorun's own
 * pthread_key_create sends them (so those keys already exist there). The
 * destructor is only ever run at thread exit; a drawing process that exits
 * wholesale does not depend on it, so recording-and-ignoring it is correct. */
#define MR_RKEY_BASE 100u
#define MR_RKEY_N    256u
static __thread void *g_rtsd[MR_RKEY_N];
static int mr_reserved(unsigned long k) { return k >= MR_RKEY_BASE && k < MR_RKEY_BASE + MR_RKEY_N; }

/* reach the host glibc directly for the non-reserved keys (machorun's _glibc_ bridge) */
extern int   glibc_setspecific(unsigned, const void *) asm("_glibc_pthread_setspecific");
extern void *glibc_getspecific(unsigned) asm("_glibc_pthread_getspecific");

int mr_key_init_np(int key, void (*dtor)(void *)) asm("_pthread_key_init_np");
int mr_key_init_np(int key, void (*dtor)(void *)) { (void)key; (void)dtor; return 0; }

int mr_setspecific(unsigned long key, const void *val) asm("_pthread_setspecific");
int mr_setspecific(unsigned long key, const void *val)
{
    if (mr_reserved(key)) { g_rtsd[key - MR_RKEY_BASE] = (void *)val; return 0; }
    return glibc_setspecific((unsigned)key, val);
}
void *mr_getspecific(unsigned long key) asm("_pthread_getspecific");
void *mr_getspecific(unsigned long key)
{
    if (mr_reserved(key)) return g_rtsd[key - MR_RKEY_BASE];
    return glibc_getspecific((unsigned)key);
}

/* ============================ FALLBACK ============================
 * Every dyld shared-cache / preoptimization SPI: under machorun there is no
 * shared cache, so "not found / none / false" is the honest answer and Swift
 * falls back to scanning the sections getsectiondata above hands it. */
static int ret0(void) { return 0; }
void *dyld_fpc(void) asm("__dyld_find_protocol_conformance");
void *dyld_fpcod(void) asm("__dyld_find_protocol_conformance_on_disk");
void *dyld_fftpc(void) asm("__dyld_find_foreign_type_protocol_conformance");
void *dyld_fftpcod(void) asm("__dyld_find_foreign_type_protocol_conformance_on_disk");
void *dyld_fphte(void) asm("__dyld_find_pointer_hash_table_entry");
int   dyld_hpspc(void) asm("__dyld_has_preoptimized_swift_protocol_conformances");
int   dyld_ioc(void) asm("__dyld_is_objc_constant");
int   dyld_ipoil(void) asm("__dyld_is_preoptimized_objc_image_loaded");
uint32_t dyld_sov(void) asm("__dyld_swift_optimizations_version");
void *dyld_gscr(void) asm("__dyld_get_shared_cache_range");
void *dyld_gspd(void) asm("__dyld_get_swift_prespecialized_data");
void *dyld_gdih(void) asm("__dyld_get_dlopen_image_header");
void *dyld_fpc(void) { return NULL; }
void *dyld_fpcod(void) { return NULL; }
void *dyld_fftpc(void) { return NULL; }
void *dyld_fftpcod(void) { return NULL; }
void *dyld_fphte(void) { return NULL; }
int   dyld_hpspc(void) { return 0; }
int   dyld_ioc(void) { return 0; }
int   dyld_ipoil(void) { return 0; }
uint32_t dyld_sov(void) { return 0; }
void *dyld_gscr(void) { return NULL; }
void *dyld_gspd(void) { return NULL; }
void *dyld_gdih(void) { return NULL; }

void *dyld_ipca(void) asm("_dyld_image_path_containing_address");
int   dyld_psal(void) asm("_dyld_program_sdk_at_least");
int   dyld_scsio(void) asm("_dyld_shared_cache_some_image_overridden");
void *dyld_ipca(void) { return NULL; }
int   dyld_psal(void) { return 1; }          /* SDK is "at least" anything asked */
int   dyld_scsio(void) { return 0; }

int  mr_avcheck(uint32_t n, const void *v) asm("__availability_version_check");
int  mr_avcheck(uint32_t n, const void *v) { (void)n;(void)v; return 1; } /* available */
int  mr_osfeat(const char *n) asm("__os_feature_enabled_simple_impl");
int  mr_osfeat(const char *n) { (void)n; return 0; }

void *mr_malloc_zone_from_ptr(const void *p) asm("_malloc_zone_from_ptr");
void *mr_malloc_zone_from_ptr(const void *p) { (void)p; return NULL; }

int mr_csops(int pid, unsigned op, void *buf, size_t n) asm("_csops");
int mr_csops(int pid, unsigned op, void *buf, size_t n) { (void)pid;(void)op;(void)buf;(void)n; return -1; }

/* os_system_version_get_current_version(struct{u32 major,minor,patch}*) -> bool */
struct mr_osver { uint32_t major, minor, patch; };
int mr_osver_get(struct mr_osver *o) asm("_os_system_version_get_current_version");
int mr_osver_get(struct mr_osver *o) { if (o) { o->major = 26; o->minor = 0; o->patch = 0; } return 1; }

/* ============================ STUB (logging / never-hit) ============================ */
static char g_dummy_log[8];
void *mr_os_log_create(const char *s, const char *c) asm("_os_log_create");
void *mr_os_log_create(const char *s, const char *c) { (void)s;(void)c; return g_dummy_log; }
int  mr_os_signpost_enabled(void *l) asm("_os_signpost_enabled");
int  mr_os_signpost_enabled(void *l) { (void)l; return 0; }
uint64_t mr_os_signpost_id_generate(void *l) asm("_os_signpost_id_generate");
uint64_t mr_os_signpost_id_generate(void *l) { (void)l; return 0; }
void mr_os_signpost_emit(void) asm("__os_signpost_emit_with_name_impl");
void mr_os_signpost_emit(void) {}
int  mr_os_trace_lazy(void) asm("__os_trace_lazy_init_completed_4swift");
int  mr_os_trace_lazy(void) { return 0; }
void mr_asl_log(void) asm("_asl_log");
void mr_asl_log(void) {}
void mr_flockfile(void *f) asm("_flockfile");
void mr_flockfile(void *f) { (void)f; }
void mr_funlockfile(void *f) asm("_funlockfile");
void mr_funlockfile(void *f) { (void)f; }

/* sscanf / getline: on this stdlib's parsing paths, unreached by a bitmap draw.
 * Return "nothing matched" / "EOF" rather than pretend. */
int mr_sscanf(const char *s, const char *f, ...) asm("_sscanf");
int mr_sscanf(const char *s, const char *f, ...) { (void)s;(void)f; return 0; }
long mr_getline(char **l, size_t *n, void *fp) asm("_getline");
long mr_getline(char **l, size_t *n, void *fp) { (void)l;(void)n;(void)fp; return -1; }

/* silence -Wunused for the shared trivial body */
void *mr__keep(void) { return (void *)ret0; }
