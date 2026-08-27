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
# 6. Don't restub the QoS enum when the sysroot has pthread/qos.h.
#
# src/shims/priority.h defines QOS_CLASS_USER_INTERACTIVE and friends for
# platforms without Darwin's QoS. Our sysroot has <pthread/qos.h>, so they
# collide -- identical shape to patch 3, one layer over.
# ---------------------------------------------------------------------------
edit("src/shims/priority.h",
"""#if HAVE_PTHREAD_QOS_H && __has_include(<pthread/qos_private.h>)
#include <pthread/qos.h>
#include <pthread/qos_private.h>""",
"""/* swiftcore-macho: upstream models two cases -- BOTH QoS headers present, or
 * NEITHER. Our sysroot is the third: Darwin's PUBLIC <pthread/qos.h> is there
 * (so qos_class_t and its enumerators are already defined) but Apple's PRIVATE
 * <pthread/qos_private.h> is not, and inventing that SPI header would be worse
 * than not having it. Upstream's condition conflates the two, so we fall to the
 * #else and redefine every enumerator on top of the real ones:
 *     error: redefinition of enumerator 'QOS_CLASS_USER_INTERACTIVE'
 * Take the public header for the TYPE; the private SPI stays absent. */
#if HAVE_PTHREAD_QOS_H && __has_include(<pthread/qos.h>)
#include <pthread/qos.h>
#if __has_include(<pthread/qos_private.h>)
#include <pthread/qos_private.h>
#else
/* QOS_CLASS_MAINTENANCE is Apple SPI: it lives in qos_private.h, not the public
 * qos.h, so taking the public header alone leaves exactly this one enumerator
 * undeclared. 0x05 is its documented value, below BACKGROUND (0x09). */
#define QOS_CLASS_MAINTENANCE ((qos_class_t)0x05)
#endif""",
     "public QoS header without the private SPI")

print("dispatch patches applied")
