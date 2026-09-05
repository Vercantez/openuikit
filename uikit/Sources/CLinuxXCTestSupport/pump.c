/* Linux XCTest 6.2.4 parks the main thread in CFRunLoop ppoll inside
 * awaitUsingExpectation → XCTWaiter.wait → RunLoop.run(mode:before:).
 *
 * MEASURED uikit-linux, Swift 6.2.4, aarch64, OpenUIKitPackageTests.xctest
 * ink list (GlyphInk+CA+Registry+Geometry+Color+ABI+SwiftUI stub):
 *   without this pump: 3/5 runs hit timeout 20 s (runs 1,3,4); runs 2,5
 *   finished 90 tests in 0.455 s / 0.761 s. Stall last line varies.
 *   LD_PRELOAD of a 200 ms DISPATCH_SOURCE_TYPE_TIMER on the global
 *   queue that dispatch_async's to main: 6/6 runs 90/90 in 0.6–1.0 s,
 *   CFRunLoopWakeUp-only pump: 2/2 ink runs still timeout 20 s (and the
 *   BeforeWaiting observer made the last test print "started" twice).
 *   dispatch_async_f onto DispatchQueue.main from that timer: 20/20 ink
 *   (90 tests, 0.44–0.50 s) and 20/20 selector (35 tests, 7–28 ms).
 *
 * Mechanism (same as swift-corelibs-xctest#504): every test's async
 * setUp/tearDown is wrapped in Task { … }; XCTWaiter.primitiveWait
 * then runs the main CFRunLoop for min(0.1 s, remaining) slices with
 * asyncTestTimeout = 30 days. corelibs CFRunLoop arms the before-date
 * as a dispatch timer whose CFRunLoopWakeUp often never lands, so
 * ppoll waits with a NULL timeout. The Test Task is already done or
 * sitting on DispatchQueue.main; nothing wakes the loop. A libdispatch
 * timer on a *non-main* queue does fire (manager thread + worker), and
 * dispatch_async_f onto _dispatch_main_q is the wakeup CFRunLoop
 * actually watches (the main-queue eventfd). CFRunLoopWakeUp alone
 * did not.
 *
 * 10 ms is 10× finer than primitiveWait's 0.1 s slice; the preload
 * already proved 200 ms is enough. Do not use a CFRunLoopTimer — that
 * is the clock that does not wake.
 *
 * Headers are declared here instead of #include <CoreFoundation/…> /
 * <dispatch/…> so this target needs no -I / -fblocks (unsafeFlags on a
 * non-test target would make the package unusable as an SPM dependency).
 */

#include "include/linux_xctest_pump.h"

#include <stdatomic.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/syscall.h>

#ifndef SYS_gettid
#define SYS_gettid 178
#endif

/* ---- libdispatch (C ABI; matches /usr/lib/swift/dispatch) ---- */
typedef void *dispatch_queue_t;
typedef void *dispatch_source_t;
typedef uint64_t dispatch_time_t;
typedef void (*dispatch_function_t)(void *);
struct dispatch_source_type_s;
extern const struct dispatch_source_type_s _dispatch_source_type_timer;
#define DISPATCH_SOURCE_TYPE_TIMER (&_dispatch_source_type_timer)
#define DISPATCH_TIME_NOW 0ull
#define NSEC_PER_MSEC 1000000ull
#define DISPATCH_QUEUE_PRIORITY_DEFAULT 0

dispatch_queue_t dispatch_get_global_queue(long identifier, unsigned long flags);
dispatch_source_t dispatch_source_create(const struct dispatch_source_type_s *type,
                                         uintptr_t handle, unsigned long mask,
                                         dispatch_queue_t queue);
void dispatch_source_set_timer(dispatch_source_t source, dispatch_time_t start,
                               uint64_t interval, uint64_t leeway);
void dispatch_source_set_event_handler_f(dispatch_source_t source,
                                         dispatch_function_t handler);
void dispatch_resume(void *object);
dispatch_time_t dispatch_time(dispatch_time_t when, int64_t delta);
void dispatch_async_f(dispatch_queue_t queue, void *context,
                      dispatch_function_t work);
/* dispatch_get_main_queue is inline around this object. */
extern char _dispatch_main_q;
#define LINUX_DISPATCH_MAIN_QUEUE ((dispatch_queue_t)&_dispatch_main_q)

static atomic_int g_installed;
static dispatch_source_t g_timer;

static int tracing(void) {
    static int cached = -1;
    if (cached < 0)
        cached = getenv("OPENUIKIT_XCTEST_TRACE") ? 1 : 0;
    return cached;
}

static int mytid(void) {
    return (int)syscall(SYS_gettid);
}

static void main_queue_tick(void *ctx) {
    (void)ctx;
    /* Running on DispatchQueue.main drains whatever MainActor /
     * swift_task jobs were sitting there. MEASURED via LD_PRELOAD:
     * this print fired on tid==pid during XCTest's RunLoop. */
    if (tracing()) {
        fprintf(stderr, "xctest-pump: MAIN-QUEUE-DRAINED tid=%d\n", mytid());
        fflush(stderr);
    }
}

static void timer_fire(void *ctx) {
    (void)ctx;
    if (tracing()) {
        fprintf(stderr, "xctest-pump: wake tid=%d\n", mytid());
        fflush(stderr);
    }
    /* MEASURED: CFRunLoopWakeUp alone did not stop the stall (2/2 ink
     * runs still hit timeout 20 s, last test "started" twice — the
     * BeforeWaiting observer re-entered). dispatch_async to main DID
     * (preload 6/6). The main-queue eventfd is what CFRunLoop is
     * actually watching. */
    dispatch_async_f(LINUX_DISPATCH_MAIN_QUEUE, NULL, main_queue_tick);
}

int linux_xctest_pump_install(void) {
    int expected = 0;
    if (!atomic_compare_exchange_strong(&g_installed, &expected, 1))
        return 1;

    /* Global concurrent queue — not main. MEASURED: this is the timer
     * that actually fires while XCTest sits in ppoll; a CFRunLoopTimer
     * for the same interval does not. */
    dispatch_queue_t q =
        dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    g_timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, q);
    dispatch_source_set_timer(
        g_timer,
        dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_MSEC),
        10 * NSEC_PER_MSEC,
        1 * NSEC_PER_MSEC);
    dispatch_source_set_event_handler_f(g_timer, timer_fire);
    dispatch_resume(g_timer);

    /* Enqueue-hook loggers were tried (OPENUIKIT_XCTEST_TRACE=1) and
     * rejected: C calling convention ≠ SWIFT_CC(swift), and the hooked
     * ink list hung at GlyphInkTableTests.testIOSMaskKeyFormatAndHarvestedHit
     * (timeout 30 s) after 110 GLOBAL enqueues and 0 MAIN enqueues.
     * MainActor bypasses swift_task_enqueueMainExecutor_hook
     * (swiftlang/swift#63104). The pump is the non-main timer plus
     * dispatch_async_f onto the main queue. */
    if (tracing()) {
        fprintf(stderr, "xctest-pump: installed tid=%d pid=%d\n",
                mytid(), getpid());
        fflush(stderr);
    }
    return 1;
}

int linux_xctest_pump_installed(void) {
    return atomic_load(&g_installed);
}

__attribute__((constructor, used))
static void linux_xctest_pump_ctor(void) {
    linux_xctest_pump_install();
}
