/*
 * target_os_probe.c -- every TARGET_OS_* macro a consumer tests must be
 * DEFINED, and must have the right value.
 *
 * This exists because of a failure mode that is invisible until it is not.
 * swift-corelibs' CoreFoundation compiles with -Wundef-prefix=TARGET_OS
 * promoted to an error, and it tests platform macros with #if rather than
 * #ifdef. So a macro our sysroot forgets does not quietly evaluate to 0 -- all
 * 86 CF translation units fail. That error is the good case. The bad case is a
 * macro we define with the WRONG value: CF then compiles clean and silently
 * takes the WASI or Android branch of a file.
 *
 * So this file does two different things, because there are two different
 * risks:
 *
 *   1. It is compiled with -Wundef-prefix=TARGET_OS -Werror, exactly as CF is,
 *      and every macro below is tested with #if. That reproduces CF's build
 *      condition without needing CF, and catches a MISSING macro.
 *
 *   2. It _Static_asserts the values that are decided by the target rather
 *      than by opinion. That catches a WRONG macro.
 *
 * WHERE THE VALUES COME FROM, since guessing is the thing to avoid:
 *
 *   - The 18 macros Apple defines are checked against Apple's own
 *     TargetConditionals.h. TARGET_OS_NANO in particular is not a judgement
 *     call: Apple's header documents it as "DEPRECATED: Same as
 *     TARGET_OS_WATCH" and defines it as exactly that, behind an #ifndef.
 *   - TARGET_OS_WASI, _ANDROID, _BSD and _CYGWIN are NOT Apple's. They appear
 *     nowhere in any Apple TargetConditionals.h (verified: zero definitions of
 *     each in the MacOSX15.4 SDK copy). They are swift-corelibs-foundation's
 *     own, and for a Darwin target the correct value is not "unknown" but 0.
 *
 * Build (see the header of sdk/local/TargetConditionals.h):
 *   clang -target arm64-apple-macos11 -isysroot sdk -Wundef-prefix=TARGET_OS \
 *         -Werror -fsyntax-only sdk/tests/target_os_probe.c
 */

#include <TargetConditionals.h>

/* ---- 1. every macro must be DEFINED: #if, not #ifdef, under -Wundef ---- */

/* Apple's platform set. */
#if TARGET_OS_MAC || !TARGET_OS_MAC
#endif
#if TARGET_OS_OSX || !TARGET_OS_OSX
#endif
#if TARGET_OS_IPHONE || !TARGET_OS_IPHONE
#endif
#if TARGET_OS_IOS || !TARGET_OS_IOS
#endif
#if TARGET_OS_TV || !TARGET_OS_TV
#endif
#if TARGET_OS_WATCH || !TARGET_OS_WATCH
#endif
#if TARGET_OS_VISION || !TARGET_OS_VISION
#endif
#if TARGET_OS_BRIDGE || !TARGET_OS_BRIDGE
#endif
#if TARGET_OS_DRIVERKIT || !TARGET_OS_DRIVERKIT
#endif
#if TARGET_OS_MACCATALYST || !TARGET_OS_MACCATALYST
#endif
#if TARGET_OS_SIMULATOR || !TARGET_OS_SIMULATOR
#endif
#if TARGET_OS_EMBEDDED || !TARGET_OS_EMBEDDED
#endif
#if TARGET_OS_NANO || !TARGET_OS_NANO
#endif
/* Non-Darwin, and the four that are corelibs' rather than Apple's. */
#if TARGET_OS_WIN32 || !TARGET_OS_WIN32
#endif
#if TARGET_OS_WINDOWS || !TARGET_OS_WINDOWS
#endif
#if TARGET_OS_UNIX || !TARGET_OS_UNIX
#endif
#if TARGET_OS_LINUX || !TARGET_OS_LINUX
#endif
#if TARGET_OS_WASI || !TARGET_OS_WASI
#endif
#if TARGET_OS_ANDROID || !TARGET_OS_ANDROID
#endif
#if TARGET_OS_BSD || !TARGET_OS_BSD
#endif
#if TARGET_OS_CYGWIN || !TARGET_OS_CYGWIN
#endif

/* ---- 2. the values the target decides, not opinion ---- */

/* We only ever build this sysroot for Darwin. */
_Static_assert(TARGET_OS_MAC == 1, "TARGET_OS_MAC must be 1 for a Darwin target");

/* Apple's documented aliasing. If this ever fails, TARGET_OS_NANO has been
 * given a life of its own and CF's watchOS branch is now reachable. */
_Static_assert(TARGET_OS_NANO == TARGET_OS_WATCH,
               "TARGET_OS_NANO is Apple's deprecated alias for TARGET_OS_WATCH");

/* Not Darwin, therefore false -- never merely undefined. */
_Static_assert(TARGET_OS_WIN32 == 0, "TARGET_OS_WIN32 must be 0");
_Static_assert(TARGET_OS_WINDOWS == 0, "TARGET_OS_WINDOWS must be 0");
_Static_assert(TARGET_OS_LINUX == 0, "TARGET_OS_LINUX must be 0");
_Static_assert(TARGET_OS_WASI == 0, "TARGET_OS_WASI must be 0 on a Darwin target");
_Static_assert(TARGET_OS_ANDROID == 0, "TARGET_OS_ANDROID must be 0 on a Darwin target");
_Static_assert(TARGET_OS_BSD == 0, "TARGET_OS_BSD must be 0 on a Darwin target");
_Static_assert(TARGET_OS_CYGWIN == 0, "TARGET_OS_CYGWIN must be 0 on a Darwin target");

/* A macOS target is macOS and nothing else. These are what make a wrong answer
 * LOUD rather than a silently different code path. */
#if __is_target_os(macos) && !__is_target_environment(macabi)
_Static_assert(TARGET_OS_OSX == 1, "arm64-apple-macos must set TARGET_OS_OSX");
_Static_assert(TARGET_OS_IPHONE == 0, "arm64-apple-macos must not set TARGET_OS_IPHONE");
_Static_assert(TARGET_OS_IOS == 0, "arm64-apple-macos must not set TARGET_OS_IOS");
_Static_assert(TARGET_OS_WATCH == 0, "arm64-apple-macos must not set TARGET_OS_WATCH");
_Static_assert(TARGET_OS_NANO == 0, "TARGET_OS_NANO follows TARGET_OS_WATCH");
_Static_assert(TARGET_OS_SIMULATOR == 0, "a macos target is not the simulator");
_Static_assert(TARGET_OS_MACCATALYST == 0, "a macos target is not Catalyst");
#endif

int target_os_probe_ok(void);
int target_os_probe_ok(void) { return 1; }
