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

print("dispatch patches applied")
