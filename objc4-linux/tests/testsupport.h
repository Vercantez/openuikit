// testsupport.h -- shared scaffolding for the objc4-linux differential corpus.
//
// Every test in tests/ is a single translation unit that includes this header
// and nothing platform-specific. The header must therefore compile identically
// against the macOS SDK's <objc/*.h> and against our port's headers.
//
// Rules this header exists to enforce (see docs/TESTING.md):
//   * No Foundation. objc4 alone has no NSObject, so tests bring their own
//     root class (TestRoot below).
//   * No addresses, no timings, no unordered iteration in output. Print
//     relationships (null/non-null, equal/not-equal, sorted lists) instead.
//   * Every line goes through say(), which flushes, so output interleaves
//     deterministically with anything the runtime writes to stderr.

#ifndef OBJC4_TESTSUPPORT_H
#define OBJC4_TESTSUPPORT_H

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#include <objc/objc.h>
#include <objc/runtime.h>
#include <objc/message.h>

// ---------------------------------------------------------------------------
// Runtime entry points we declare ourselves.
//
// These are ABI-stable exports of libobjc that Apple keeps in the private
// <objc/objc-internal.h>, which is not shipped in the macOS SDK. Declaring them
// here rather than including a private header is what lets one source file
// compile unchanged on both sides.
// ---------------------------------------------------------------------------
#ifdef __cplusplus
extern "C" {
#endif

id   objc_retain(id obj);
void objc_release(id obj);
id   objc_autorelease(id obj);
void *objc_autoreleasePoolPush(void);
void objc_autoreleasePoolPop(void *ctxt);

void objc_storeStrong(id *location, id obj);

// <objc/objc-sync.h> is not pulled in by <objc/runtime.h>; declare rather than
// include, so the corpus does not depend on the header layout of either side.
int objc_sync_enter(id obj);
int objc_sync_exit(id obj);

id   objc_initWeak(id *location, id val);
void objc_destroyWeak(id *location);
void objc_copyWeak(id *to, id *from);
void objc_moveWeak(id *to, id *from);
id   objc_loadWeakRetained(id *location);

// Root-class helpers libobjc implements for NSObject's benefit. A custom root
// class must call them itself; see the comment on TestRoot below.
id        _objc_rootRetain(id obj);
void      _objc_rootRelease(id obj);
id        _objc_rootAutorelease(id obj);
uintptr_t _objc_rootRetainCount(id obj);
bool      _objc_rootTryRetain(id obj);
bool      _objc_rootIsDeallocating(id obj);
void      _objc_rootDealloc(id obj);
id        _objc_rootInit(id obj);

#ifdef __cplusplus
}
#endif

// ---------------------------------------------------------------------------
// Deterministic output
// ---------------------------------------------------------------------------

__attribute__((format(printf, 1, 2)))
static void say(const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    vprintf(fmt, ap);
    va_end(ap);
    putchar('\n');
    fflush(stdout);
}

// Never print a pointer. Print what is true about it.
#define YN(x)        ((x) ? "yes" : "no")
#define NULLNESS(p)  ((p) ? "nonnull" : "null")
#define SAFESTR(s)   ((s) ? (s) : "(null)")

static int str_cmp_qsort(const void *a, const void *b) {
    return strcmp(*(const char *const *)a, *(const char *const *)b);
}

// Sort before printing anything the runtime hands back as a list: method,
// ivar, property and protocol lists are in emission order, which is a linker
// artifact and not a semantic guarantee.
static void sort_strings(const char **v, unsigned n) {
    qsort((void *)v, n, sizeof(*v), str_cmp_qsort);
}

static void print_sorted_strings(const char *label, const char **v, unsigned n) {
    sort_strings(v, n);
    for (unsigned i = 0; i < n; i++) say("%s[%u]=%s", label, i, v[i]);
    say("%s.count=%u", label, n);
}

// ---------------------------------------------------------------------------
// Event log: lets +load / +initialize / -dealloc record ordering before main()
// has a chance to run, and lets main() print it as one deterministic block.
// ---------------------------------------------------------------------------

#define EVENTLOG_MAX 64
static const char *g_events[EVENTLOG_MAX];
static unsigned g_event_count;

static void event(const char *name) {
    if (g_event_count < EVENTLOG_MAX) g_events[g_event_count] = name;
    g_event_count++;
}

// Same, but for events whose text is computed (e.g. "+initialize self=Child").
// Uses a static arena rather than strdup: +load runs before main and we do not
// want a malloc on that path to be part of what the test measures.
static char g_event_arena[4096];
static unsigned g_event_arena_used;

__attribute__((format(printf, 1, 2)))
static void eventf(const char *fmt, ...) {
    char tmp[160];
    va_list ap;
    va_start(ap, fmt);
    vsnprintf(tmp, sizeof tmp, fmt, ap);
    va_end(ap);
    size_t n = strlen(tmp) + 1;
    if (g_event_arena_used + n <= sizeof g_event_arena) {
        char *p = g_event_arena + g_event_arena_used;
        memcpy(p, tmp, n);
        g_event_arena_used += (unsigned)n;
        event(p);
    } else {
        event("<event-arena-full>");
    }
}

static void print_events(const char *label) {
    unsigned n = g_event_count < EVENTLOG_MAX ? g_event_count : EVENTLOG_MAX;
    for (unsigned i = 0; i < n; i++) say("%s[%u]=%s", label, i, g_events[i]);
    say("%s.count=%u", label, g_event_count);
}

// Index of the first event with this name, or -1. Used to assert orderings
// without depending on absolute positions.
static int event_index(const char *name) {
    unsigned n = g_event_count < EVENTLOG_MAX ? g_event_count : EVENTLOG_MAX;
    for (unsigned i = 0; i < n; i++) {
        if (strcmp(g_events[i], name) == 0) return (int)i;
    }
    return -1;
}

static void say_order(const char *a, const char *b) {
    int ia = event_index(a), ib = event_index(b);
    if (ia < 0 || ib < 0) say("%s<%s=missing", a, b);
    else say("%s<%s=%s", a, b, YN(ia < ib));
}

// ---------------------------------------------------------------------------
// TestRoot: a root class with no Foundation behind it.
//
// MEASURED, not assumed: a root class that is not NSObject always gets the
// custom-RR / custom-AWZ / custom-Core bits (objc-runtime-new.mm, the
// "Custom root class" branch of scanAddedClassImpl). So objc_retain() and
// objc_release() do NOT use the runtime's inline reference counting on
// TestRoot -- they objc_msgSend -retain / -release. Without the four methods
// below, the very first objc_release() aborts with
//   "-[Leaf release]: unrecognized selector".
// That abort is what a first draft of this header actually produced, and it is
// itself asserted as an oracle fact in tests/028-arc-custom-rr.m.
//
// The bodies forward to libobjc's own root implementations, so the reference
// counts the ARC tests observe are the runtime's real ones.
//
// Tests are compiled -fno-objc-arc, so writing -retain/-release directly is
// legal here (under ARC, clang rejects them and Apple's own testroot.i has to
// install them with class_addMethod).
// ---------------------------------------------------------------------------

@interface TestRoot {
@public
    Class isa;
}
+ (id)alloc;
+ (id)new;
+ (Class)class;
+ (Class)superclass;
+ (void)initialize;
- (id)init;
- (void)dealloc;
- (Class)class;
- (id)self;
- (id)retain;
- (oneway void)release;
- (id)autorelease;
- (uintptr_t)retainCount;
- (BOOL)allowsWeakReference;
- (BOOL)retainWeakReference;
@end

// Bumped by every TestRoot subclass instance that reaches -dealloc.
static int g_dealloc_count;

@implementation TestRoot
+ (id)alloc { return class_createInstance(self, 0); }
+ (id)new   { return [[self alloc] init]; }
+ (Class)class { return self; }
+ (Class)superclass { return class_getSuperclass(self); }
+ (void)initialize { }
// Classes are not refcounted; these keep objc_retain(SomeClass) from aborting.
+ (id)retain { return self; }
+ (oneway void)release { }
+ (id)autorelease { return self; }
+ (uintptr_t)retainCount { return UINTPTR_MAX; }
- (id)init { return self; }
- (void)dealloc { g_dealloc_count++; _objc_rootDealloc(self); }
- (Class)class { return object_getClass(self); }
- (id)self { return self; }
- (id)retain { return _objc_rootRetain(self); }
- (oneway void)release { _objc_rootRelease(self); }
- (id)autorelease { return _objc_rootAutorelease(self); }
- (uintptr_t)retainCount { return _objc_rootRetainCount(self); }
- (BOOL)allowsWeakReference { return !_objc_rootIsDeallocating(self); }
- (BOOL)retainWeakReference { return _objc_rootTryRetain(self); }
@end

#endif // OBJC4_TESTSUPPORT_H
