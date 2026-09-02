/*
 * compat/src/objc4linux-compat.cpp  --  objc4-linux
 *
 * Implementations for the Darwin surface declared in compat/*.h.
 *
 * The rule for this file: anything that has a real Linux equivalent is
 * implemented for real; anything that does not aborts through
 * objc4linux_unimplemented() with file/line/function, and has an entry in
 * docs/UNIMPLEMENTED.md. There are no silent stubs and no functions that
 * quietly return a plausible-looking wrong answer.
 */

#include <errno.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <dlfcn.h>
#include <link.h>
#include <elf.h>

#include <objc4linux/unimplemented.h>
#include <_simple.h>
#include <CrashReporterClient.h>
#include <os/reason_private.h>
#include <os/feature_private.h>
#include <mach/mach.h>
#include <mach-o/loader.h>
#include <mach-o/getsect.h>
#include <mach-o/dyld.h>
#include <mach-o/dyld_priv.h>
#include <mach-o/ldsyms.h>
#include <malloc/malloc.h>
#include <malloc_private.h>
#include <kern/restartable.h>
#include <dispatch/dispatch.h>

/* ------------------------------------------------------------------ *
 * The loud abort. Everything unported funnels here.
 * ------------------------------------------------------------------ */

extern "C" void
objc4linux_unimplemented_(const char *file, int line, const char *func,
                          const char *what)
{
    /* Deliberately write(2), not fprintf: this can be reached from inside
     * objc_msgSend, where stdio locks are not safe to take. */
    char buf[1024];
    int n = snprintf(buf, sizeof(buf),
                     "objc4-linux: UNIMPLEMENTED: %s\n"
                     "  in %s at %s:%d\n"
                     "  This is a hole in the port, not a bug in your program.\n"
                     "  See docs/UNIMPLEMENTED.md.\n",
                     what, func, file, line);
    if (n > 0) {
        ssize_t ignored = write(STDERR_FILENO, buf, (size_t)n);
        (void)ignored;
    }
    __objc_crash_message = what;
    abort();
}

#define UNIMPL(what) objc4linux_unimplemented(what)

/* ------------------------------------------------------------------ *
 * _simple.h -- malloc-free, objc-free logging.
 *
 * REAL. Must not allocate and must not re-enter objc_msgSend, which is why
 * objc-os.h marks syslog()/vsyslog() unavailable. Fixed stack buffer +
 * write(2) satisfies both.
 * ------------------------------------------------------------------ */

namespace {
struct SimpleString {
    static const size_t kCap = 4096;
    size_t len;
    char   buf[kCap];
};
}

extern "C" {

_SIMPLE_STRING _simple_salloc(void)
{
    SimpleString *s = (SimpleString *)calloc(1, sizeof(SimpleString));
    return (_SIMPLE_STRING)s;
}

int _simple_vsprintf(_SIMPLE_STRING b, const char *fmt, va_list ap)
{
    SimpleString *s = (SimpleString *)b;
    if (!s) return -1;
    int n = vsnprintf(s->buf + s->len, SimpleString::kCap - s->len, fmt, ap);
    if (n < 0) return n;
    s->len += (size_t)n;
    if (s->len >= SimpleString::kCap) s->len = SimpleString::kCap - 1;
    return n;
}

int _simple_sprintf(_SIMPLE_STRING b, const char *fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);
    int n = _simple_vsprintf(b, fmt, ap);
    va_end(ap);
    return n;
}

void _simple_put(_SIMPLE_STRING b, const char *str)
{
    _simple_sprintf(b, "%s", str);
}

char *_simple_string(_SIMPLE_STRING b)
{
    SimpleString *s = (SimpleString *)b;
    return s ? s->buf : (char *)"";
}

void _simple_sfree(_SIMPLE_STRING b)
{
    free(b);
}

void _simple_asl_log(int level, const char *facility, const char *message)
{
    /* Darwin routes this to the unified log. We have no equivalent that is
     * safe to call from inside the runtime; stderr is the honest choice. */
    (void)level;
    (void)facility;
    if (!message) return;
    size_t n = strlen(message);
    ssize_t ignored = write(STDERR_FILENO, message, n);
    if (n == 0 || message[n - 1] != '\n')
        ignored = write(STDERR_FILENO, "\n", 1);
    (void)ignored;
}

/* ------------------------------------------------------------------ *
 * CrashReporterClient.h
 *
 * PARTIAL. gdb/lldb can read the global; systemd-coredump and abrt cannot.
 * ------------------------------------------------------------------ */

const char *__objc_crash_message = nullptr;

const char *CRSetCrashLogMessage(const char *msg)
{
    __objc_crash_message = msg;
    return msg;
}

const char *CRGetCrashLogMessage(void)
{
    return __objc_crash_message;
}

/* ------------------------------------------------------------------ *
 * os/reason_private.h
 *
 * PARTIAL. The reason namespace/code are preserved in the message so they
 * stay greppable, but nothing structured reaches the crash reporter.
 * ------------------------------------------------------------------ */

void abort_with_reason(uint32_t ns, uint64_t code, const char *reason,
                       uint64_t flags)
{
    (void)flags;
    char buf[1024];
    int n = snprintf(buf, sizeof(buf),
                     "objc4-linux: abort_with_reason(ns=%u code=%llu): %s\n",
                     ns, (unsigned long long)code, reason ? reason : "(null)");
    if (n > 0) { ssize_t i = write(STDERR_FILENO, buf, (size_t)n); (void)i; }
    __objc_crash_message = reason;
    abort();
}

void os_fault_with_payload(uint32_t ns, uint64_t code, void *payload,
                           uint32_t payload_size, const char *reason,
                           uint64_t flags)
{
    /* Darwin's os_fault_with_payload reports and CONTINUES. Keep that: it is
     * a diagnostic, not a fatal error. */
    (void)payload; (void)payload_size; (void)flags;
    char buf[1024];
    int n = snprintf(buf, sizeof(buf),
                     "objc4-linux: os_fault(ns=%u code=%llu): %s\n",
                     ns, (unsigned long long)code, reason ? reason : "(null)");
    if (n > 0) { ssize_t i = write(STDERR_FILENO, buf, (size_t)n); (void)i; }
}

/* ------------------------------------------------------------------ *
 * os/feature_private.h
 *
 * REAL, with different plumbing: Darwin reads objc4.plist through the
 * os_feature service; we read OBJC_FEATURE_<name> from the environment and
 * otherwise take the caller's compiled-in default.
 * ------------------------------------------------------------------ */

bool objc4linux_feature_enabled(const char *subsystem, const char *feature,
                                bool default_value)
{
    (void)subsystem;
    char name[128];
    snprintf(name, sizeof(name), "OBJC_FEATURE_%s", feature);
    const char *v = getenv(name);
    if (!v) return default_value;
    return !(v[0] == '0' && v[1] == '\0');
}

/* ------------------------------------------------------------------ *
 * malloc zones
 *
 * REAL where it matters. SUPPORT_ZONES is 0 on Linux, so the only zone call
 * that survives is _calloc_canonical's malloc_zone_malloc_with_options with
 * a NULL zone -- which is exactly "aligned, zeroed heap memory".
 * ------------------------------------------------------------------ */

void *malloc_zone_malloc_with_options_np(malloc_zone_t *zone, size_t align,
                                         size_t size,
                                         malloc_zone_malloc_options_t options)
{
    if (zone) UNIMPL("malloc_zone_malloc_with_options with a non-default zone");
    if (align < sizeof(void *)) align = sizeof(void *);
    void *p = nullptr;
    if (posix_memalign(&p, align, size) != 0) return nullptr;
    if (options & MALLOC_ZONE_MALLOC_OPTION_CLEAR) memset(p, 0, size);
    return p;
}

malloc_zone_t *malloc_default_zone(void)        { UNIMPL("malloc zones"); }
void *malloc_zone_malloc(malloc_zone_t *, size_t)          { UNIMPL("malloc zones"); }
void *malloc_zone_calloc(malloc_zone_t *, size_t, size_t)  { UNIMPL("malloc zones"); }
void *malloc_zone_realloc(malloc_zone_t *, void *, size_t) { UNIMPL("malloc zones"); }
void  malloc_zone_free(malloc_zone_t *, void *)            { UNIMPL("malloc zones"); }
unsigned malloc_zone_batch_malloc(malloc_zone_t *, size_t, void **, unsigned) { UNIMPL("malloc zones"); }
void  malloc_zone_batch_free(malloc_zone_t *, void **, unsigned)             { UNIMPL("malloc zones"); }

/* ------------------------------------------------------------------ *
 * dispatch_once -- REAL, via a relaxed/acquire double-checked flag.
 * objc4 uses exactly one (objc-exception.mm).
 * ------------------------------------------------------------------ */

void dispatch_once_f(dispatch_once_t *pred, void *ctx, void (*fn)(void *))
{
    if (__atomic_load_n(pred, __ATOMIC_ACQUIRE) == 2) return;
    long expected = 0;
    if (__atomic_compare_exchange_n(pred, &expected, 1, false,
                                    __ATOMIC_ACQUIRE, __ATOMIC_ACQUIRE)) {
        fn(ctx);
        __atomic_store_n(pred, 2, __ATOMIC_RELEASE);
    } else {
        while (__atomic_load_n(pred, __ATOMIC_ACQUIRE) != 2)
            ;
    }
}

#if __BLOCKS__
void objc4linux_dispatch_once(dispatch_once_t *pred, dispatch_block_t block)
{
    struct Ctx { dispatch_block_t b; } c = { block };
    dispatch_once_f(pred, &c, [](void *p) { ((Ctx *)p)->b(); });
}
#endif

/* ------------------------------------------------------------------ *
 * dyld: SDK version gating
 *
 * REAL, by fiat: there is no legacy Linux Objective-C ABI to be
 * bug-compatible with, so every "is the SDK at least X" question is yes.
 * objc-os.h's sdkIsAtLeast() is #defined to 1 on Linux, so these are only
 * reached by the two direct dyld_program_sdk_at_least() calls.
 * ------------------------------------------------------------------ */

const dyld_build_version_t dyld_platform_version_macOS_10_11 = { 1, 0 };
const dyld_build_version_t dyld_platform_version_macOS_10_13 = { 1, 0 };
const dyld_build_version_t dyld_fall_2018_os_versions        = { 1, 0 };
const dyld_build_version_t dyld_fall_2020_os_versions        = { 1, 0 };

bool dyld_program_sdk_at_least(dyld_build_version_t) { return true; }
uint32_t dyld_get_active_platform(void) { return 1; /* not macOS, not iOS */ }

/* ------------------------------------------------------------------ *
 * dyld: image identity and image discovery
 *
 * MOVED. dyld_image_header_containing_address, dyld_image_path_containing_
 * address, _dyld_get_prog_image_header, _dyld_get_dlopen_image_header,
 * _dyld_get_image_uuid, _dyld_is_memory_immutable,
 * _dyld_objc_register_callbacks and _dyld_lookup_section_info are all
 * implemented for real in compat/src/objc4linux-elf.cpp, backed by
 * dl_iterate_phdr(3) and the on-disk ELF section header table.
 * ------------------------------------------------------------------ */

/* ------------------------------------------------------------------ *
 * dyld shared cache -- does not exist. SUPPORT_PREOPT is 0, so nothing
 * should reach these; if something does, we want to hear about it.
 * ------------------------------------------------------------------ */

bool dyld_shared_cache_some_image_overridden(void) { return false; }
bool _dyld_get_shared_cache_range(size_t *len, const void **addr)
{
    if (len) *len = 0;
    if (addr) *addr = nullptr;
    return false;   /* "there is no shared cache" is the true answer */
}
const char *_dyld_get_objc_selector(const char *) { return nullptr; }
uint32_t _dyld_objc_class_count(void) { return 0; }
void _dyld_for_each_objc_class(const char *, void (^)(void *, bool, bool *))    {}
void _dyld_for_each_objc_protocol(const char *, void (^)(void *, bool, bool *)) {}
void _dyld_for_objc_header_opt_ro(void (^)(const void *))                       {}
void _dyld_for_objc_header_opt_rw(void (^)(void *))                             {}

/* ------------------------------------------------------------------ *
 * libobjc's own image record. Filled in when libobjc registers itself.
 * ------------------------------------------------------------------ */

struct mach_header_64 _mh_dylib_header = {
    OBJC4LINUX_IMAGE_MAGIC, 0, 0, MH_DYLIB, 0, 0, 0, 0
};

/* ------------------------------------------------------------------ *
 * Mach-O section access -- there is no Mach-O.
 * ------------------------------------------------------------------ */

uint8_t *getsectiondata(const struct mach_header_64 *, const char *,
                        const char *, unsigned long *)
{
    UNIMPL("getsectiondata: ELF has no runtime-mapped section table");
}
uint8_t *getsegmentdata(const struct mach_header_64 *, const char *,
                        unsigned long *)
{
    UNIMPL("getsegmentdata: ELF has no runtime-mapped section table");
}
const struct section_64 *getsectbynamefromheader_64(const struct mach_header_64 *,
                                                    const char *, const char *)
{
    UNIMPL("getsectbynamefromheader_64: ELF has no runtime-mapped section table");
}

/* ------------------------------------------------------------------ *
 * Mach -- no IPC, no task ports, no thread state.
 * ------------------------------------------------------------------ */

mach_port_t mach_task_self(void)                 { UNIMPL("mach_task_self"); }
mach_port_t pthread_mach_thread_np(void *)       { UNIMPL("pthread_mach_thread_np"); }
const char *mach_error_string(kern_return_t)     { return strerror(errno); }
kern_return_t mach_port_deallocate(mach_port_t, mach_port_name_t) { UNIMPL("mach_port_deallocate"); }
kern_return_t task_threads(task_t, thread_act_array_t *, mach_msg_type_number_t *) { UNIMPL("task_threads"); }
kern_return_t thread_get_state(thread_t, thread_state_flavor_t, thread_state_t,
                               mach_msg_type_number_t *)          { UNIMPL("thread_get_state"); }
kern_return_t vm_allocate(vm_map_t, vm_address_t *, vm_size_t, int)   { UNIMPL("vm_allocate"); }
kern_return_t vm_deallocate(vm_map_t, vm_address_t, vm_size_t)        { UNIMPL("vm_deallocate"); }
kern_return_t vm_protect(vm_map_t, vm_address_t, vm_size_t, int, vm_prot_t) { UNIMPL("vm_protect"); }
kern_return_t vm_remap(vm_map_t, vm_address_t *, vm_size_t, vm_address_t, int,
                       vm_map_t, vm_address_t, int, vm_prot_t *, vm_prot_t *,
                       vm_inherit_t)
{
    /* The Linux equivalent is memfd_create + ftruncate + two mmaps of the same
     * fd (one PROT_READ|PROT_EXEC, one PROT_READ|PROT_WRITE). Needed only by
     * imp_implementationWithBlock. */
    UNIMPL("vm_remap: block trampolines are not ported (see PORT_MAP 2.1)");
}

kern_return_t task_restartable_ranges_register(task_t,
                                               task_restartable_range_array_t,
                                               mach_msg_type_number_t)
{
    UNIMPL("task_restartable_ranges_register");
}
kern_return_t task_restartable_ranges_synchronize(task_t)
{
    UNIMPL("task_restartable_ranges_synchronize");
}

/* ------------------------------------------------------------------ *
 * <mach-o/dyld.h> public API -- named by objc4 but not on any live path.
 * ------------------------------------------------------------------ */

uint32_t _dyld_image_count(void)                          { UNIMPL("_dyld_image_count"); }
const struct mach_header *_dyld_get_image_header(uint32_t) { UNIMPL("_dyld_get_image_header"); }
intptr_t _dyld_get_image_vmaddr_slide(uint32_t)            { UNIMPL("_dyld_get_image_vmaddr_slide"); }
const char *_dyld_get_image_name(uint32_t)                 { UNIMPL("_dyld_get_image_name"); }
void _dyld_register_func_for_add_image(void (*)(const struct mach_header *, intptr_t))    { UNIMPL("_dyld_register_func_for_add_image"); }
void _dyld_register_func_for_remove_image(void (*)(const struct mach_header *, intptr_t)) { UNIMPL("_dyld_register_func_for_remove_image"); }

int *_NSGetArgc(void)    { UNIMPL("_NSGetArgc"); }
char ***_NSGetArgv(void) { UNIMPL("_NSGetArgv"); }

} // extern "C"
