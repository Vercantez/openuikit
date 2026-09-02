/*
 * target_os_probe.c -- the constants the PREPROCESSOR reads, verified
 * differentially. Every one must be DEFINED, and must have the right value.
 *
 * The name says TARGET_OS because that is what forced the file into existence;
 * §3 widens it to the other constants with the same blind spot.
 * sdk/tests/abi_probe.c diffs everything a program can PRINT -- struct sizes,
 * field offsets, errno and O_* values. It structurally cannot see a constant
 * that #if consumes and discards, because by the time there is a value to print
 * the decision has already been taken. Everything here lives in that gap.
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
#include <sys/cdefs.h>
#include <mach/vm_param.h>

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

/* ---- 3. the other constants that are read by #if and never at runtime ----
 *
 * sdk/tests/abi_probe.c already diffs everything a program can PRINT -- struct
 * sizes, field offsets, errno and O_* values. What it structurally cannot see
 * is a constant the preprocessor consumes and then discards, because by the
 * time there is a value to print the decision has already been made. That is
 * the same blind spot the TARGET_OS_* macros above sat in, and this project has
 * been bitten through it TWICE, both recorded in sdk/PROVENANCE.md §3 under
 * patches/0002-xnu-platform-macosx.patch:
 *
 *   - `__DARWIN_ONLY_UNIX_CONFORMANCE` undefined made __DARWIN_SUF_UNIX03
 *     `"$UNIX2003"`, renaming every __DARWIN_ALIAS'd libc function. It surfaced
 *     as 7 undefined symbols in libobjc that nothing anywhere exports
 *     (`_open$UNIX2003`, `_close$UNIX2003`, ...).
 *   - `MACH_VM_MAX_ADDRESS` silently dropped to the EMBEDDED 64 GiB value
 *     instead of macOS's 128 TiB. Nothing failed to compile.
 *
 * Both are guarded today only by a patch, with nothing asserting the outcome.
 * That is what these asserts are: the patch says what we did, and these say
 * what it had to achieve. MACH_VM_MAX_ADDRESS in particular is load-bearing
 * twice over -- objc4's own STATIC_ASSERTs size ISA_MASK and FAST_DATA_MASK
 * against it (docs/UNIMPLEMENTED.md#isa-va-width), so a wrong value here does
 * not fail, it changes which isa layout compiles.
 *
 * Hard-coded values are deliberate. Compiled against Apple's SDK on the oracle
 * side, a number Apple moves fails the build there and gets reported, which is
 * this repo's rule everywhere else: drift is a thing to notice, not to absorb.
 */

/* macOS arm64: 128 TiB minus the last 32 MiB. The embedded value is
 * 0x0000000FFFFFF000 (64 GiB), and confusing the two is the bug above. */
_Static_assert(MACH_VM_MAX_ADDRESS == 0x00007ffffe000000ULL,
               "MACH_VM_MAX_ADDRESS must be macOS's 128 TiB value, not the embedded 64 GiB one "
               "-- objc4 sizes its isa masks against this");

/* Selects the $UNIX2003 / $INODE64 symbol variants. Wrong here means every
 * __DARWIN_ALIAS'd libc symbol is renamed, and the failure appears as
 * undefined symbols in an unrelated library. */
_Static_assert(__DARWIN_ONLY_UNIX_CONFORMANCE == 1,
               "macOS arm64 is UNIX03-only; 0 renames every __DARWIN_ALIAS'd libc function");
_Static_assert(__DARWIN_ONLY_64_BIT_INO_T == 1,
               "macOS arm64 is 64-bit-ino_t-only; 0 selects the $INODE64 variants");

/* The CPU and runtime halves of TargetConditionals.h, which pick struct layouts
 * in vendored headers rather than merely gating declarations. */
_Static_assert(TARGET_CPU_ARM64 == 1, "we only build this sysroot for arm64");
_Static_assert(TARGET_CPU_X86_64 == 0, "TARGET_CPU_X86_64 must be 0 on arm64");
_Static_assert(TARGET_RT_64_BIT == 1, "arm64 Darwin is LP64");
_Static_assert(TARGET_RT_LITTLE_ENDIAN == 1, "arm64 Darwin is little-endian");
_Static_assert(TARGET_RT_MAC_MACHO == 1, "the object format is Mach-O");

int target_os_probe_ok(void);
int target_os_probe_ok(void) { return 1; }
