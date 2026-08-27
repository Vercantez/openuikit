#!/usr/bin/env python3
"""Apply swiftcore-macho's edits to a pristine swift-corelibs-libdispatch checkout.

Idempotent, anchor-asserted, same contract as scripts/apply_patches.py. The
metric here is patch COUNT and what each patch says: a patch that says "this is
not a Mac" is legitimate; one that says "this is not Mach-O" means the approach
is wrong.
"""
import sys, pathlib

ROOT = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else
                    pathlib.Path.home() / "work" / "libdispatch")

def edit(relpath, old, new, tag):
    p = ROOT / relpath
    s = p.read_text()
    if new in s:
        print(f"  [skip] {tag} (already applied)")
        return
    assert s.count(old) == 1, f"{tag}: anchor matched {s.count(old)}x in {relpath}"
    p.write_text(s.replace(old, new))
    print(f"  [ok]   {tag}")

# ---------------------------------------------------------------------------
# 1. Let the build system choose the event backend.
#
# event_config.h picks the backend from host defines alone:
#
#     #if defined(__linux__)                 -> epoll
#     #elif __has_include(<sys/event.h>)     -> kevent (+ Mach)
#     #elif defined(_WIN32)                  -> windows
#     #else                                  -> #error unsupported event loop
#
# We compile for a Darwin target on a Linux host, so __linux__ is absent. Our
# sysroot has no <sys/event.h>, so today this reaches the #error rather than
# silently selecting kevent — which is the good failure, but still a failure.
# This adds the one thing the chain lacks: an externally-supplied backend wins.
# It says "this is not a Mac", not "this is not Mach-O".
# ---------------------------------------------------------------------------
edit("src/event/event_config.h",
"""#if defined(__linux__)
#	include <sys/eventfd.h>
#	define DISPATCH_EVENT_BACKEND_EPOLL 1
#	define DISPATCH_EVENT_BACKEND_KEVENT 0
#	define DISPATCH_EVENT_BACKEND_WINDOWS 0""",
"""#if defined(DISPATCH_EVENT_BACKEND_EPOLL) && DISPATCH_EVENT_BACKEND_EPOLL
/* swiftcore-macho: the build system selected epoll explicitly. We target
 * Darwin (Mach-O) on a Linux host, so neither __linux__ nor <sys/event.h> is a
 * correct signal for which event loop the *host kernel* provides -- the guest
 * runs on Linux whatever its object format says. */
#	include <sys/eventfd.h>
#	define DISPATCH_EVENT_BACKEND_KEVENT 0
#	define DISPATCH_EVENT_BACKEND_WINDOWS 0
#elif defined(__linux__)
#	include <sys/eventfd.h>
#	define DISPATCH_EVENT_BACKEND_EPOLL 1
#	define DISPATCH_EVENT_BACKEND_KEVENT 0
#	define DISPATCH_EVENT_BACKEND_WINDOWS 0""",
     "build system selects the event backend")

# ---------------------------------------------------------------------------
# 2. Don't call sysctlbyname on a Linux host; take the fallback upstream already
#    wrote.
#
# hw_config.h sets name = "hw.logicalcpu_max" on Darwin and then calls
# sysctlbyname, which does not exist on Linux. The `else` branch immediately
# below it is already correct for us:
#
#     r = (int)sysconf(_SC_NPROCESSORS_ONLN);
#
# So this leaves `name` NULL rather than shimming a Darwin API over Linux. A
# fake sysctlbyname answering "hw.logicalcpu_max" would be more code, more
# surface, and a lie; taking the existing fallback is neither.
# ---------------------------------------------------------------------------
edit("src/shims/hw_config.h",
"""	switch (c) {
	case _dispatch_hw_config_logical_cpus:
		name = "hw.logicalcpu_max"; break;
	case _dispatch_hw_config_physical_cpus:
		name = "hw.physicalcpu_max"; break;
	case _dispatch_hw_config_active_cpus:
		name = "hw.activecpu"; break;
	}""",
"""	// swiftcore-macho: the host is Linux, which has no sysctlbyname. Leaving
	// `name` NULL selects the sysconf(_SC_NPROCESSORS_ONLN) branch below --
	// upstream's own code, and the right answer here.
	(void)c;""",
     "no sysctlbyname on a Linux host")

# ---------------------------------------------------------------------------
# 3. Don't restub Mach types when the sysroot has the real Mach headers.
#
# src/shims/mach.h says "Stub out defines for some mach types" -- it exists for
# platforms where Mach is ABSENT. Our sysroot ships Darwin's real Mach headers
# (machorun stages them for objc4, and they are not separable: <stdlib.h> alone
# reaches two mach/ headers, <dispatch/dispatch.h> reaches fourteen). So the
# stubs collide with the genuine articles:
#
#   error: 'MACH_PORT_NULL' macro redefined
#   error: 'MACH_PORT_DEAD' macro redefined
#   error: typedef redefinition with different types
#           ('uint32_t' vs 'kern_return_t')
#
# Unlike the earlier three Mach encounters, this one is NOT a detection result
# that forcing HAVE_MACH=0 can paper over -- it is two definitions colliding.
#
# The fix keeps the two questions separate, which is the whole lesson of this
# port in reverse: whether the TYPES exist is a header question, and whether
# Mach IPC is USABLE is a capability question. Defer to the real headers for the
# types; HAVE_MACH=0 continues to govern whether any Mach code path compiles.
# dispatch_mach_msg_t and firehose_activity_id_t are libdispatch's own types,
# not Mach's, so they stay.
# ---------------------------------------------------------------------------
edit("src/shims/mach.h",
"""typedef uint32_t mach_port_t;

#define  MACH_PORT_NULL (0)
#define  MACH_PORT_DEAD (-1)

typedef uint32_t mach_error_t;

typedef uint32_t mach_msg_return_t;

typedef uint32_t mach_msg_bits_t;

typedef void *dispatch_mach_msg_t;

typedef uint64_t firehose_activity_id_t;

typedef void *mach_msg_header_t;""",
"""#if __has_include(<mach/mach.h>)
/* swiftcore-macho: the sysroot has Darwin's real Mach headers, so take the
 * genuine types rather than restubbing them into a collision. HAVE_MACH=0 still
 * governs whether any Mach IPC code path compiles -- header presence is not
 * capability, and here that cuts the other way: the types are real even though
 * the IPC is not implemented. */
#include <mach/mach.h>
#include <mach/message.h>
#include <mach/error.h>

/* dispatch_mach_msg_t is NOT redefined here: dispatch's own public headers
 * already declare it as struct dispatch_mach_msg_s *, and restubbing it to
 * void * is the same collision one layer up. Only firehose_activity_id_t is
 * genuinely absent. (Found by compiling, not by reading -- the first version of
 * this patch kept the typedef and collided.) */
typedef uint64_t firehose_activity_id_t;

#else

typedef uint32_t mach_port_t;

#define  MACH_PORT_NULL (0)
#define  MACH_PORT_DEAD (-1)

typedef uint32_t mach_error_t;

typedef uint32_t mach_msg_return_t;

typedef uint32_t mach_msg_bits_t;

typedef void *dispatch_mach_msg_t;

typedef uint64_t firehose_activity_id_t;

typedef void *mach_msg_header_t;

#endif""",
     "defer to real Mach headers for types when present")

# ---------------------------------------------------------------------------
# 4. A fourth _dispatch_sema4_t backend: pthread mutex + condition variable.
#
# src/shims/lock.h offers USE_MACH_SEM / USE_POSIX_SEM / USE_WIN32_SEM and then
# `#error "port has to implement _dispatch_sema4_t"`. We are a Darwin target
# WITHOUT Mach IPC -- a combination upstream does not model -- so this is the
# same "this is not a Mac" statement as patches 1-3.
#
# USE_POSIX_SEM is the trap that looks like a one-line config fix:
#
#   * _dispatch_sema4_t is embedded BY VALUE in libdispatch's structures, so
#     `typedef sem_t _dispatch_sema4_t` puts Darwin's 4-byte sem_t where glibc's
#     sem_init writes 32. Clean link, 0 return, 28 bytes past the object gone --
#     the opaque-pointer audit's first LIVE instance, in exactly the path CF
#     needs (dispatch_semaphore_* is among CF's 21 symbols).
#   * Darwin does not implement unnamed POSIX semaphores at all: measured on
#     macOS 26 arm64, sem_init returns -1/ENOSYS. Selecting USE_POSIX_SEM for a
#     Darwin target emulates a configuration Apple's platform never has.
#   * Darwin's sem_t is 4 bytes, so the pointer-handle trick that rescues
#     posix_spawnattr_t cannot apply here -- 4 bytes cannot hold a pointer.
#
# The pair below is safe for reasons that were MEASURED, not assumed:
#
#   * No overflow, because machorun adopts both types as HANDLES. cond_glibc()
#     stores a pointer to a heap glibc cond in the first 8 bytes of Darwin's
#     opaque area (darwin/src/libsystem.c) and the mutex path does the same via
#     adopt(), so nothing is written past the guest's allocation regardless of
#     the size disagreement. sizeof is 120 on both platforms.
#   * ETIMEDOUT is translated. mr_pthread_rc() wraps glibc_pthread_cond_timedwait
#     at the call site; a probe under machorun returns rc=60, matching the
#     compiled Darwin value. Without it a guest sees Linux's 110, compares
#     against 60, and concludes a wait that EXPIRED had SUCCEEDED -- which is
#     how 21_pthread_cond found that bug ("waited=yes timedout=NO").
#   * Attributes are NULL, as they must be: machorun's forwarder bails on a
#     non-NULL condattr. That costs nothing, because _dispatch_sema4_timedwait
#     is handed nanoseconds since the EPOCH and the default cond already uses
#     the realtime clock. NULL mutex attrs also sidestep the swapped mutex TYPE
#     constants entirely.
#
# Verified on both platforms, 4/4, teeth demonstrated by mutation: an inverted
# timeout return fails the negative-control case ONLY, on macOS and under
# machorun. See foundation-macho docs/DISPATCH_PATCH4.md and tests/t4_sema4.c.
# ---------------------------------------------------------------------------
edit("src/shims/lock.h",
"""#else
#error "port has to implement _dispatch_sema4_t"
#endif""",
"""#elif USE_PTHREAD_SEM

/* Fourth branch -- see scripts/dispatch_patches.py. A Darwin target without
 * Mach IPC, which upstream models neither with USE_MACH_SEM (no Mach) nor with
 * USE_POSIX_SEM (Darwin's 4-byte sem_t would be overwritten by glibc's 32, and
 * Darwin returns ENOSYS for sem_init anyway). */
typedef struct _dispatch_sema4_s {
	pthread_mutex_t dsema_mutex;
	pthread_cond_t  dsema_cond;
	long            dsema_value;
} _dispatch_sema4_t;

/* A condition variable cannot promise wakeup ordering. Upstream's POSIX and
 * Win32 backends both define these to 0 for the same reason; matching them is
 * honest rather than claiming a guarantee we do not provide. */
#define _DSEMA4_POLICY_FIFO 0
#define _DSEMA4_POLICY_LIFO 0
#define _DSEMA4_TIMEOUT() ((errno) = ETIMEDOUT, -1)

void _dispatch_sema4_init(_dispatch_sema4_t *sema, int policy);
/* Creation is eager, as in the POSIX branch: init does the work, so the lazy
 * create_slow path is a no-op and is_created is always true. */
#define _dispatch_sema4_is_created(sema) ((void)sema, 1)
#define _dispatch_sema4_create_slow(sema, policy) ((void)sema, (void)policy)

#else
#error "port has to implement _dispatch_sema4_t"
#endif""",
     "patch 4a: declare the pthread semaphore backend")

edit("src/shims/lock.c",
"""#elif USE_WIN32_SEM""",
"""#elif USE_PTHREAD_SEM

/* pthread reports errors through its RETURN VALUE, not errno -- unlike the
 * POSIX-semaphore branch above, whose macro checks `== -1` and reads errno.
 * Reusing that macro here would check the wrong thing and never fire. */
#define DISPATCH_PTHREAD_VERIFY(rc) do { \\
		int _rc = (rc); \\
		if (unlikely(_rc != 0)) { \\
			DISPATCH_INTERNAL_CRASH(_rc, "pthread semaphore API failure"); \\
		} \\
	} while (0)

void
_dispatch_sema4_init(_dispatch_sema4_t *sema, int policy DISPATCH_UNUSED)
{
	sema->dsema_value = 0;
	/* NULL attributes deliberately: machorun's forwarder bails on a non-NULL
	 * pthread_condattr_t, and the mutex TYPE constants differ between Darwin
	 * and glibc, so requesting a type would be requesting a different one. */
	DISPATCH_PTHREAD_VERIFY(pthread_mutex_init(&sema->dsema_mutex, NULL));
	DISPATCH_PTHREAD_VERIFY(pthread_cond_init(&sema->dsema_cond, NULL));
}

void
_dispatch_sema4_dispose_slow(_dispatch_sema4_t *sema, int policy DISPATCH_UNUSED)
{
	DISPATCH_PTHREAD_VERIFY(pthread_cond_destroy(&sema->dsema_cond));
	DISPATCH_PTHREAD_VERIFY(pthread_mutex_destroy(&sema->dsema_mutex));
}

void
_dispatch_sema4_signal(_dispatch_sema4_t *sema, long count)
{
	DISPATCH_PTHREAD_VERIFY(pthread_mutex_lock(&sema->dsema_mutex));
	sema->dsema_value += count;
	/* Signalling under the lock costs a possible extra context switch and
	 * removes the window where a waiter arrives between bump and wake. */
	if (count == 1) {
		DISPATCH_PTHREAD_VERIFY(pthread_cond_signal(&sema->dsema_cond));
	} else {
		DISPATCH_PTHREAD_VERIFY(pthread_cond_broadcast(&sema->dsema_cond));
	}
	DISPATCH_PTHREAD_VERIFY(pthread_mutex_unlock(&sema->dsema_mutex));
}

void
_dispatch_sema4_wait(_dispatch_sema4_t *sema)
{
	DISPATCH_PTHREAD_VERIFY(pthread_mutex_lock(&sema->dsema_mutex));
	/* while, not if: a broadcast wakes every waiter but only `count` may
	 * proceed, and pthread_cond_wait may wake spuriously. */
	while (sema->dsema_value == 0) {
		DISPATCH_PTHREAD_VERIFY(pthread_cond_wait(&sema->dsema_cond,
				&sema->dsema_mutex));
	}
	sema->dsema_value--;
	DISPATCH_PTHREAD_VERIFY(pthread_mutex_unlock(&sema->dsema_mutex));
}

bool
_dispatch_sema4_timedwait(_dispatch_sema4_t *sema, dispatch_time_t timeout)
{
	struct timespec ts;
	uint64_t nsec = _dispatch_time_nanoseconds_since_epoch(timeout);
	ts.tv_sec  = (__typeof__(ts.tv_sec))(nsec / NSEC_PER_SEC);
	ts.tv_nsec = (__typeof__(ts.tv_nsec))(nsec % NSEC_PER_SEC);

	DISPATCH_PTHREAD_VERIFY(pthread_mutex_lock(&sema->dsema_mutex));
	while (sema->dsema_value == 0) {
		int rc = pthread_cond_timedwait(&sema->dsema_cond,
				&sema->dsema_mutex, &ts);
		if (rc == ETIMEDOUT) {
			/* TRUE MEANS TIMED OUT, matching upstream's POSIX branch.
			 * Inverting this makes every timed wait report success. */
			DISPATCH_PTHREAD_VERIFY(pthread_mutex_unlock(&sema->dsema_mutex));
			return true;
		}
		if (rc != 0) {
			DISPATCH_PTHREAD_VERIFY(pthread_mutex_unlock(&sema->dsema_mutex));
			DISPATCH_INTERNAL_CRASH(rc, "pthread semaphore API failure");
		}
	}
	sema->dsema_value--;
	DISPATCH_PTHREAD_VERIFY(pthread_mutex_unlock(&sema->dsema_mutex));
	return false;
}

#elif USE_WIN32_SEM""",
     "patch 4b: implement the pthread semaphore backend")

# ---------------------------------------------------------------------------
# 7. Mach TIME without Mach IPC -- the same conflation at three levels.
#
# HAVE_MACH means "port-based IPC" to us and we set it 0. Upstream uses it for
# more, and the overlap is TIME: mach_absolute_time() and mach_continuous_time()
# are clock functions machorun's libSystem exports and <mach/mach_time.h>
# declares. They have nothing to do with ports.
#
# It bit at three levels, and finding all three meant following the errors as
# they CHANGED SHAPE rather than trusting the first diagnosis:
#
#   1. config -- HAVE_MACH_ABSOLUTE_TIME was 0, so src/shims/time.h fell past
#      its first branch to `#error platform needs to implement _dispatch_uptime`
#      (every remaining branch requires __linux__). Fixed in config_ac.h.
#   2. includes, patched here -- <mach/mach_time.h> sits INSIDE internal.h's
#      `#if HAVE_MACH` block, so fixing the config turned those #errors into
#      "call to undeclared function mach_absolute_time": branch now right,
#      declaration still absent.
#   3. <time.h> is included by internal.h ONLY under `#if defined(_WIN32)`.
#      Everyone else gets it transitively -- real Darwin THROUGH mach_time.h.
#      So dropping the Mach include silently costs a Darwin target <time.h> as
#      well, which is why clock_gettime_nsec_np and CLOCK_REALTIME read as
#      undeclared while <time.h> defines both perfectly well.
#
# Five errors, one cause. Says "this is not a Mac (IPC)", not "this is not
# Mach-O", so it is legitimate by this port's own metric.
# ---------------------------------------------------------------------------
edit("src/internal.h",
"""#endif /* HAVE_MACH */""",
"""#endif /* HAVE_MACH */

/* swiftcore-macho: Mach TIME survives HAVE_MACH=0 -- see dispatch_patches.py.
 * <mach/mach_time.h> is a clock header, not an IPC header, and libSystem
 * exports mach_absolute_time/mach_continuous_time. <time.h> is included above
 * only under _WIN32; on real Darwin it arrives transitively THROUGH
 * mach_time.h, so a Darwin target with HAVE_MACH=0 loses both at once. */
#if !HAVE_MACH && HAVE_MACH_ABSOLUTE_TIME
#include <mach/mach_time.h>
#endif
#include <time.h>""",
     "patch 7: Mach time headers survive HAVE_MACH=0")

# ---------------------------------------------------------------------------
# 8. The once-generation fast path reads the Darwin COMM PAGE.
#
# src/shims/lock.h selects it on `#elif __APPLE__` and then dereferences
# _COMM_PAGE_CPU_QUIESCENT_COUNTER, a fixed kernel-mapped address. machorun
# maps no comm page and the constant is not in the sysroot, so that guard asks
# "is this Apple's compiler target" when it means "is this Apple's KERNEL".
# HAVE_MACH is the flag that already means the latter. Same shape as CFRunLoop
# selecting Mach ports on TARGET_OS_MAC.
# ---------------------------------------------------------------------------
edit("src/shims/lock.h",
"""#elif __APPLE__
#define DISPATCH_ONCE_USE_QUIESCENT_COUNTER 1""",
"""#elif __APPLE__ && HAVE_MACH
/* swiftcore-macho: __APPLE__ here is a proxy for Apple's KERNEL, not Apple's
 * target -- the fast path dereferences _COMM_PAGE_CPU_QUIESCENT_COUNTER at a
 * kernel-mapped address machorun does not provide. */
#define DISPATCH_ONCE_USE_QUIESCENT_COUNTER 1""",
     "patch 8: the once counter needs the comm page, not just __APPLE__")

# ---------------------------------------------------------------------------
# 9. _dispatch_time_now_cached's Mach fast path.
#
# Gated `#if TARGET_OS_MAC`, calls mach_get_times() -- a Darwin SPI machorun's
# libSystem does NOT export (checked: 0 defined symbols matching). The `#else`
# branch calls _dispatch_time_now(clock), which is portable and correct; the
# Mach path is a batching optimisation that fills three clocks in one trap.
# So this costs a little cache efficiency and nothing semantic.
# ---------------------------------------------------------------------------
edit("src/shims/time.h",
"""#if TARGET_OS_MAC
	struct timespec ts;
	mach_get_times(&cache->nows[DISPATCH_CLOCK_UPTIME],
			&cache->nows[DISPATCH_CLOCK_MONOTONIC], &ts);
	cache->nows[DISPATCH_CLOCK_WALL] = _dispatch_timespec_to_nano(ts);
#else""",
"""#if TARGET_OS_MAC && HAVE_MACH
	/* swiftcore-macho: mach_get_times is a Darwin SPI libSystem does not
	 * export. It only BATCHES three clock reads into one trap, so the portable
	 * branch below is equivalent, just less efficient. */
	struct timespec ts;
	mach_get_times(&cache->nows[DISPATCH_CLOCK_UPTIME],
			&cache->nows[DISPATCH_CLOCK_MONOTONIC], &ts);
	cache->nows[DISPATCH_CLOCK_WALL] = _dispatch_timespec_to_nano(ts);
#else""",
     "patch 9: mach_get_times is an optimisation we cannot take")

# ---------------------------------------------------------------------------
# 10. The LOCK WORD: Mach thread ports vs futex TIDs.
#
# `#if TARGET_OS_MAC` at src/shims/lock.h:37 selects a lock whose owner field is
# a MACH THREAD PORT: `_dispatch_tid_self()` is `_dispatch_thread_port()`, which
# tsd.h:335 defines as `pthread_mach_thread_np(_dispatch_thread_self())`. We
# have no mach thread ports, and the visible symptom is the opaque-pointer ABI
# class again -- `_dispatch_thread_self()` yields a uintptr_t while Darwin's
# pthread_t is an opaque POINTER, so it fails to compile rather than silently
# passing a bad handle. The good failure, and the fourth TARGET_OS_MAC standing
# in for "has Mach kernel facilities".
#
# The futex branch is the intended destination, and the evidence is that
# swiftcore-macho ALREADY staged what it needs: scripts/stage_linux_abi.sh
# declares linux/futex.h and sdk/tests/epoll_abi_probe.c pins FUTEX_* and
# SYS_futex against real glibc. Nothing else in this port wanted those.
#
# NOTE THIS IS A SEMANTIC CHANGE, not a header fix: the lock WORD LAYOUT
# differs between the two branches (DLOCK_OWNER_MASK becomes FUTEX_TID_MASK,
# and the waiters/failed-trylock bits move to FUTEX_WAITERS/FUTEX_OWNER_DIED).
# It compiles, which is a real gate but NOT verification -- no lock has been
# contended under machorun. Do not read a clean build as a working lock.
# ---------------------------------------------------------------------------
edit("src/shims/lock.h",
"""#if TARGET_OS_MAC

typedef mach_port_t dispatch_tid;""",
"""#if TARGET_OS_MAC && HAVE_MACH

typedef mach_port_t dispatch_tid;""",
     "patch 10a: the Mach lock needs Mach thread ports, not just TARGET_OS_MAC")

edit("src/shims/lock.h",
"""#elif defined(__linux__)

#include <linux/futex.h>""",
"""#elif defined(__linux__) || HAVE_FUTEX

/* swiftcore-macho: reached by a Darwin target without Mach thread ports. The
 * futex ABI is declared by scripts/stage_linux_abi.sh and pinned against real
 * glibc by sdk/tests/epoll_abi_probe.c (FUTEX_*, SYS_futex), which were staged
 * for exactly this.
 *
 * HAVE_FUTEX comes from config_ac.h. lock.h sets it at line 169 under
 * `#ifndef HAVE_FUTEX`, which is AFTER this branch at line 58 -- so relying on
 * lock.h's own definition silently evaluated to 0 and fell through to "define
 * _dispatch_lock encoding scheme for your platform here", taking the error
 * count from 4 to 20. Defining it in the config instead makes it true at both
 * points, and lock.c's six `#elif HAVE_FUTEX` sites then need no patch. */
#include <linux/futex.h>""",
     "patch 10b: let a non-Linux target reach the futex lock")

# ---------------------------------------------------------------------------
# 11. lock.c's Darwin ulock/thread_switch block.
#
# `#if TARGET_OS_MAC` at src/shims/lock.c:23 opens a block using
# ULF_WAIT_WORKQ_DATA_CONTENTION and SWITCH_OPTION_OSLOCK_DEPRESS -- constants
# from Darwin's __ulock_wait and thread_switch SPIs, neither of which our
# sysroot declares nor libSystem exports. The futex implementations below it are
# already selected by HAVE_FUTEX. Fifth instance of TARGET_OS_MAC standing in
# for "has Mach kernel facilities".
# ---------------------------------------------------------------------------
edit("src/shims/lock.c",
"""#if TARGET_OS_MAC
dispatch_static_assert(DLOCK_LOCK_DATA_CONTENTION ==
		ULF_WAIT_WORKQ_DATA_CONTENTION);""",
"""#if TARGET_OS_MAC && HAVE_MACH
/* swiftcore-macho: __ulock_wait / thread_switch are Darwin kernel SPIs the
 * sysroot does not declare and libSystem does not export. The futex paths
 * below are selected by HAVE_FUTEX instead. */
dispatch_static_assert(DLOCK_LOCK_DATA_CONTENTION ==
		ULF_WAIT_WORKQ_DATA_CONTENTION);""",
     "patch 11: lock.c's ulock block needs Mach, not just TARGET_OS_MAC")

# _dispatch_firehose_gate_wait is the same shape one more time: gated
# `#if TARGET_OS_MAC`, it calls _dispatch_unfair_lock_wait, which exists only
# under HAVE_UL_UNFAIR_LOCK (Darwin's __ulock SPI). Firehose is Apple's logging
# transport and we already build with OS_FIREHOSE_SPI=0, so nothing calls this.
edit("src/shims/lock.c",
"""#if TARGET_OS_MAC

void
_dispatch_firehose_gate_wait(dispatch_gate_t dgl, uint32_t owner,
		uint32_t flags)""",
"""#if TARGET_OS_MAC && HAVE_UL_UNFAIR_LOCK
/* swiftcore-macho: needs Darwin's __ulock SPI, and firehose is Apple's logging
 * transport -- we build with OS_FIREHOSE_SPI=0, so nothing calls this. */
void
_dispatch_firehose_gate_wait(dispatch_gate_t dgl, uint32_t owner,
		uint32_t flags)""",
     "patch 11b: firehose gate wait needs Darwin's ulock SPI")

# ---------------------------------------------------------------------------
# 12. Workloops need Darwin's pthread-workqueue KERNEL interface.
#
# `#if TARGET_OS_MAC` at src/queue.c:4086 calls _pthread_workloop_create /
# _pthread_workloop_destroy -- Darwin SPIs backed by the kernel workqueue, which
# is precisely the machinery this port decided to do without
# (HAVE_PTHREAD_WORKQUEUES 0, DISPATCH_USE_INTERNAL_WORKQUEUE 1). Seventh
# instance of TARGET_OS_MAC standing in for a kernel facility; gating on the
# flag that already records the decision.
# ---------------------------------------------------------------------------
edit("src/queue.c",
"""#endif // HAVE_PTHREAD_ATTR_SETCPUPERCENT_NP
#if TARGET_OS_MAC
	if (_dispatch_workloop_has_kernel_attributes(dwl)) {""",
"""#endif // HAVE_PTHREAD_ATTR_SETCPUPERCENT_NP
/* swiftcore-macho: _pthread_workloop_* are Darwin kernel-workqueue SPIs, and
 * this port runs on DISPATCH_USE_INTERNAL_WORKQUEUE instead. */
#if TARGET_OS_MAC && HAVE_PTHREAD_WORKQUEUES
	if (_dispatch_workloop_has_kernel_attributes(dwl)) {""",
     "patch 12a: workloop create needs the pthread-workqueue kernel interface")

# The matching destroy site, gated the same way. Two sites, not one -- the
# create at queue.c:4090 and the destroy at 4152, each in its own
# `#if TARGET_OS_MAC` block. Patching only the first left the file failing on
# the second, which is why the census went 22 -> 23 rather than 22 -> 24.
edit("src/queue.c",
"""#if TARGET_OS_MAC
	if (dwl->dwl_attr && (dwl->dwl_attr->dwla_flags &
			DISPATCH_WORKLOOP_ATTR_NEEDS_DESTROY)) {
		(void)dispatch_assume_zero(_pthread_workloop_destroy((uint64_t)dwl));
	}
#endif // TARGET_OS_MAC""",
"""#if TARGET_OS_MAC && HAVE_PTHREAD_WORKQUEUES
	/* swiftcore-macho: pairs with the create site above. */
	if (dwl->dwl_attr && (dwl->dwl_attr->dwla_flags &
			DISPATCH_WORKLOOP_ATTR_NEEDS_DESTROY)) {
		(void)dispatch_assume_zero(_pthread_workloop_destroy((uint64_t)dwl));
	}
#endif // TARGET_OS_MAC && HAVE_PTHREAD_WORKQUEUES""",
     "patch 12b: the matching workloop destroy site")

# ---------------------------------------------------------------------------
# 5. The runloop handle: a Mach port on Darwin, an eventfd everywhere else.
#
# Scoped in docs/CONCURRENCY.md Part 9. Six sites, all the same shape:
#
#     #if TARGET_OS_MAC        -> mach_port_construct / MACH_PORT_VALID / ...
#     #elif defined(__linux__) -> eventfd / fd >= 0 / ...
#
# We are TARGET_OS_MAC with no __linux__, so we take the Mach branch and reach
# mach_port_construct -- one of machorun's four self-naming aborts. Eighth
# instance of TARGET_OS_MAC standing in for a kernel facility.
#
# The added condition is DISPATCH_EVENT_BACKEND_EPOLL, upstream's OWN macro and
# exactly the right meaning: if the event backend is epoll then a runloop handle
# is an eventfd. Using a name upstream already has keeps this a configuration
# rather than a fork -- the same reasoning that replaced an invented
# DISPATCH_LOCK_USE_FUTEX with HAVE_FUTEX.
#
# Confirmed by Part 7: _dispatch_get_main_queue_port_4CF is a one-line forward
# to the HANDLE entry point, so "port" is a legacy alias and nothing here needs
# port receive rights. CFRunLoop's integration works on the eventfd.
# ---------------------------------------------------------------------------
_RUNLOOP_SITES = [
    ("private/private.h",
     "#if TARGET_OS_MAC\ntypedef mach_port_t dispatch_runloop_handle_t;\n"
     "#elif defined(__linux__) || defined(__FreeBSD__)",
     "#if TARGET_OS_MAC && HAVE_MACH\ntypedef mach_port_t dispatch_runloop_handle_t;\n"
     "#elif defined(__linux__) || defined(__FreeBSD__) || DISPATCH_EVENT_BACKEND_EPOLL",
     "5a: the handle typedef"),
    ("src/queue.c",
     "#if TARGET_OS_MAC\n\treturn MACH_PORT_VALID(handle);\n#elif defined(__linux__)",
     "#if TARGET_OS_MAC && HAVE_MACH\n\treturn MACH_PORT_VALID(handle);\n"
     "#elif defined(__linux__) || DISPATCH_EVENT_BACKEND_EPOLL",
     "5b: handle_is_valid"),
    ("src/queue.c",
     "#if TARGET_OS_MAC\n\treturn ((dispatch_runloop_handle_t)(uintptr_t)dq->do_ctxt);\n"
     "#elif defined(__linux__)",
     "#if TARGET_OS_MAC && HAVE_MACH\n\treturn ((dispatch_runloop_handle_t)(uintptr_t)dq->do_ctxt);\n"
     "#elif defined(__linux__) || DISPATCH_EVENT_BACKEND_EPOLL",
     "5c: queue_get_handle"),
    ("src/queue.c",
     "#if TARGET_OS_MAC\n\tdq->do_ctxt = (void *)(uintptr_t)handle;\n#elif defined(__linux__)",
     "#if TARGET_OS_MAC && HAVE_MACH\n\tdq->do_ctxt = (void *)(uintptr_t)handle;\n"
     "#elif defined(__linux__) || DISPATCH_EVENT_BACKEND_EPOLL",
     "5d: queue_set_handle"),
    # The two that actually call into Mach. mach_port_construct is one of
    # machorun's four self-naming aborts, so without this the failure would have
    # been a runtime bail inside CFRunLoop's first main-queue wakeup rather than
    # a build error -- a good argument for naming those aborts.
    ("src/queue.c",
     "#if TARGET_OS_MAC\n\tmach_port_options_t opts = {",
     "#if TARGET_OS_MAC && HAVE_MACH\n\tmach_port_options_t opts = {",
     "5e: handle_init (mach_port_construct)"),
    ("src/queue.c",
     "#if TARGET_OS_MAC\n\tmach_port_t mp = (mach_port_t)handle;",
     "#if TARGET_OS_MAC && HAVE_MACH\n\tmach_port_t mp = (mach_port_t)handle;",
     "5f: handle_dispose (mach_port_destruct)"),
    # Each of those two functions has its OWN `#elif defined(__linux__)`, which
    # 5a-5d did not touch. Gating the Mach half without opening the eventfd half
    # just moves the failure to the `#else` -- "runloop support not implemented
    # on this platform" -- which is a clearer error but not a fix.
    ("src/queue.c",
     "#elif defined(__linux__)\n\tint fd = eventfd(0, EFD_CLOEXEC | EFD_NONBLOCK);",
     "#elif defined(__linux__) || DISPATCH_EVENT_BACKEND_EPOLL\n"
     "\tint fd = eventfd(0, EFD_CLOEXEC | EFD_NONBLOCK);",
     "5g: handle_init eventfd branch"),
    ("src/queue.c",
     "#elif defined(__linux__)\n\tint rc = close(handle);",
     "#elif defined(__linux__) || DISPATCH_EVENT_BACKEND_EPOLL\n\tint rc = close(handle);",
     "5h: handle_dispose close branch"),
]
for relpath, old, new_, tag in _RUNLOOP_SITES:
    edit(relpath, old, new_, "patch " + tag)


# ---------------------------------------------------------------------------
# GUARD for patch 4 (pthread semaphore backend), checked every run.
#
# The pthread backend is safe *because* libdispatch creates every lock and
# semaphore at runtime. pthread_cond_t is 48 bytes on BOTH Darwin and glibc --
# a coincidence that makes a forwarder look correct and pass every runtime size
# check, while being WRONG for a statically-initialised one:
# PTHREAD_COND_INITIALIZER is a compile-time constant carrying Darwin's field
# layout, and no runtime check can catch that.
#
# Measured today: ZERO PTHREAD_*_INITIALIZER in src/, and no statically
# initialised semaphore globals. But that is a property of libdispatch as it is
# now, not a guarantee -- so it is asserted here rather than written in a
# comment, because if someone adds one the coincidence turns into a silent trap.
import subprocess as _sp
_hits = _sp.run(["grep","-rlE","PTHREAD_[A-Z]+_INITIALIZER", str(ROOT / "src")],
                capture_output=True, text=True).stdout.split()
assert not _hits, (
    "libdispatch now statically initialises a pthread primitive (%s).\n"
    "The pthread semaphore backend assumed runtime creation only. A static\n"
    "PTHREAD_*_INITIALIZER embeds DARWIN's field layout into a structure glibc\n"
    "will interpret with its own -- and pthread_cond_t being 48 bytes on both\n"
    "sides means NO size check will catch it. Re-examine before building."
    % ", ".join(_hits))
print("  [ok]   guard: no static PTHREAD_*_INITIALIZER in src/")

# ---------------------------------------------------------------------------
# 6. WITHDRAWN -- superseded by staging Apple's own private headers.
#
# The QoS collision is NOT fixed by splitting upstream's condition. The three
# headers libdispatch wants are all open source, in releases machorun ALREADY
# pins, so upstream's "both headers present" case can simply be made true:
#
#   pthread/qos_private.h      libpthread-539.100.4  private/pthread/qos_private.h
#   sys/qos_private.h          libpthread-539.100.4  private/sys/qos_private.h
#   pthread/priority_private.h xnu-12377.121.6       bsd/pthread/priority_private.h
#
# With those staged, HAVE_PTHREAD_QOS_H && __has_include(<pthread/qos_private.h>)
# is TRUE and libdispatch takes its own Darwin path. No patch, no invented SPI.
#
# Staging is machorun-isamask's (sdk/ provenance + restore-integrity check).
# Until it lands, the QoS TUs do not build -- which is the correct failure.

print("dispatch patches applied")
