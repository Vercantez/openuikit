/*
 * TargetConditionals.h -- machorun's clean-room replacement.
 *
 * NOT Apple's header.  Apple's is 534 lines and matches nothing in any
 * apple-oss-distributions release (docs/SDK_SURVEY.md §2.4); this is written
 * from the outside, against the eight TARGET_* macros anything we compile
 * actually reads.
 *
 * Everything here is DERIVED, not asserted: clang's __is_target_os() /
 * __is_target_environment() / __is_target_arch() answer for the -target on the
 * command line, so `-target arm64-apple-macos11` and `-target arm64-apple-ios15`
 * get different answers out of the same file.  docs/OBJC4_MACHO.md §1 records
 * the five predefines objc4 needs to come out right; three of those five
 * (__arm64__, __arm64, __OBJC_BOOL_IS_BOOL) clang supplies itself, and the
 * other two (TARGET_OS_MAC, TARGET_OS_OSX) are the first two lines below.
 *
 * WHAT THIS OMITS versus Apple's:
 *   - the pre-clang-3.x fallback ladder (__ppc__, __i386__ era gating).  We
 *     require a clang that has __is_target_os; older ones get an #error.
 *   - TARGET_OS_NANO, TARGET_OS_RTKIT, TARGET_OS_EXCLAVEKIT and the other
 *     internal-platform flags.  Apple defines them; nothing we compile reads
 *     them, and a guest that does gets an undefined-identifier error rather
 *     than a wrong answer.
 *   - TARGET_ABI_USES_IOS_VALUES and the Rosetta/translation flags.
 *   - the deprecated TARGET_IPHONE_SIMULATOR / TARGET_OS_NANO aliases.
 */

#ifndef __TARGETCONDITIONALS__
#define __TARGETCONDITIONALS__

#if !defined(__is_target_os) || !defined(__is_target_environment)
  #error "machorun's TargetConditionals.h needs a clang with __is_target_os (clang 6+)"
#endif

/* ------------------------------------------------------------------ vendor */
/* TARGET_OS_MAC is Apple's name for "some Darwin", not for "macOS".  Every
 * Apple platform sets it; TARGET_OS_OSX is the one that means the desktop. */
#if defined(__APPLE__) && defined(__MACH__)
  #define TARGET_OS_MAC               1
#else
  #define TARGET_OS_MAC               0
#endif

/* -------------------------------------------------------------- which OS */
#define TARGET_OS_OSX                 (TARGET_OS_MAC && __is_target_os(macos) && !__is_target_environment(macabi))
#define TARGET_OS_MACCATALYST         (TARGET_OS_MAC && __is_target_environment(macabi))
#define TARGET_OS_IOS                 (TARGET_OS_MAC && __is_target_os(ios) && !__is_target_environment(macabi))
#define TARGET_OS_TV                  (TARGET_OS_MAC && __is_target_os(tvos))
#define TARGET_OS_WATCH               (TARGET_OS_MAC && __is_target_os(watchos))
#define TARGET_OS_VISION              (TARGET_OS_MAC && __is_target_os(xros))
#define TARGET_OS_BRIDGE              (TARGET_OS_MAC && __is_target_os(bridgeos))
#define TARGET_OS_DRIVERKIT           (TARGET_OS_MAC && __is_target_os(driverkit))

/* TARGET_OS_IPHONE is "an embedded Apple OS or Catalyst", i.e. everything with
 * the iOS-family API shape.  TARGET_OS_EMBEDDED is the older spelling that
 * excludes the simulator and Catalyst. */
#define TARGET_OS_IPHONE              (TARGET_OS_IOS || TARGET_OS_TV || TARGET_OS_WATCH || \
                                       TARGET_OS_VISION || TARGET_OS_BRIDGE || TARGET_OS_MACCATALYST)
#define TARGET_OS_SIMULATOR           (TARGET_OS_MAC && __is_target_environment(simulator))
#define TARGET_OS_EMBEDDED            (TARGET_OS_IPHONE && !TARGET_OS_SIMULATOR && !TARGET_OS_MACCATALYST)

/* Not Darwin.  Present because vendored headers test them. */
#define TARGET_OS_WIN32               0
#define TARGET_OS_WINDOWS             0
#define TARGET_OS_UNIX                0
#define TARGET_OS_LINUX               0

/* ------------------------------------------------------------------- CPU */
#define TARGET_CPU_PPC                0
#define TARGET_CPU_PPC64              0
#define TARGET_CPU_68K                0
#define TARGET_CPU_MIPS               0
#define TARGET_CPU_SPARC              0
#define TARGET_CPU_ALPHA              0

#if defined(__arm64__) || defined(__aarch64__)
  #define TARGET_CPU_X86              0
  #define TARGET_CPU_X86_64           0
  #define TARGET_CPU_ARM              0
  #define TARGET_CPU_ARM64            1
#elif defined(__x86_64__)
  #define TARGET_CPU_X86              0
  #define TARGET_CPU_X86_64           1
  #define TARGET_CPU_ARM              0
  #define TARGET_CPU_ARM64            0
#elif defined(__i386__)
  #define TARGET_CPU_X86              1
  #define TARGET_CPU_X86_64           0
  #define TARGET_CPU_ARM              0
  #define TARGET_CPU_ARM64            0
#elif defined(__arm__)
  #define TARGET_CPU_X86              0
  #define TARGET_CPU_X86_64           0
  #define TARGET_CPU_ARM              1
  #define TARGET_CPU_ARM64            0
#else
  #error "machorun's TargetConditionals.h: unrecognised target CPU"
#endif

/* ------------------------------------------------------------------ runtime */
#define TARGET_RT_MAC_CFM             0
#define TARGET_RT_MAC_MACHO           1
#if defined(__BIG_ENDIAN__)
  #define TARGET_RT_LITTLE_ENDIAN     0
  #define TARGET_RT_BIG_ENDIAN        1
#else
  #define TARGET_RT_LITTLE_ENDIAN     1
  #define TARGET_RT_BIG_ENDIAN        0
#endif
#if defined(__LP64__)
  #define TARGET_RT_64_BIT            1
#else
  #define TARGET_RT_64_BIT            0
#endif

#endif /* __TARGETCONDITIONALS__ */
