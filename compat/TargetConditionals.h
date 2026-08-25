/*
 * compat/TargetConditionals.h  --  objc4-linux
 *
 * Apple's <TargetConditionals.h> for a platform Apple does not have.
 *
 * Deliberately: every TARGET_OS_* is 0, including TARGET_OS_MAC. objc4's
 * `#if TARGET_OS_MAC` blocks pull in 25 Darwin headers and select the Darwin
 * threading package; we want none of that. A new TARGET_OS_LINUX selects the
 * branches we add by patch (see patches/0001, patches/0002).
 */
#ifndef _OBJC4LINUX_TARGETCONDITIONALS_H
#define _OBJC4LINUX_TARGETCONDITIONALS_H

#define TARGET_OS_MAC               0
#define TARGET_OS_OSX               0
#define TARGET_OS_IPHONE            0
#define TARGET_OS_IOS               0
#define TARGET_OS_TV                0
#define TARGET_OS_WATCH             0
#define TARGET_OS_BRIDGE            0
#define TARGET_OS_VISION            0
#define TARGET_OS_MACCATALYST       0
#define TARGET_OS_UIKITFORMAC       0
#define TARGET_OS_SIMULATOR         0
#define TARGET_OS_EMBEDDED          0
#define TARGET_OS_DRIVERKIT         0
#define TARGET_OS_WIN32             0
#define TARGET_OS_WINDOWS           0
#define TARGET_OS_UNIX              1

/* Ours. */
#define TARGET_OS_LINUX             1

#if defined(__aarch64__) || defined(__arm64__)
#   define TARGET_CPU_ARM64         1
#   define TARGET_CPU_ARM           0
#   define TARGET_CPU_X86_64        0
#   define TARGET_CPU_X86           0
#elif defined(__x86_64__)
#   define TARGET_CPU_ARM64         0
#   define TARGET_CPU_ARM           0
#   define TARGET_CPU_X86_64        1
#   define TARGET_CPU_X86           0
#else
#   error objc4-linux: unsupported CPU
#endif

#define TARGET_RT_MAC_CFM           0
#define TARGET_RT_MAC_MACHO         0
#define TARGET_RT_LITTLE_ENDIAN     1
#define TARGET_RT_BIG_ENDIAN        0
#define TARGET_RT_64_BIT            (__SIZEOF_POINTER__ == 8)

#endif
