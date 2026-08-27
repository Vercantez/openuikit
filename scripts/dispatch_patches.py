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
