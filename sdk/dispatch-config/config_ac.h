/* swiftcore-macho: our libdispatch configuration.
 * internal.h prefers <config/config_ac.h> over the checked-in <config/config.h>,
 * which is a DARWIN config asserting HAVE_MACH 1 / HAVE_OBJC 1 /
 * HAVE_PTHREAD_WORKQUEUES 1. Using upstream's own escape hatch keeps our
 * settings in one auditable file and avoids -D flags colliding with it. */
#ifndef __SWIFTCORE_MACHO_DISPATCH_CONFIG_AC__
#define __SWIFTCORE_MACHO_DISPATCH_CONFIG_AC__
#define HAVE_MACH 0
/* 1: Mach IPC is absent, Mach TIME is not, and conflating them cost us four
 * errors. machorun's libSystem exports mach_absolute_time AND
 * mach_continuous_time, and <mach/mach_time.h> declares both. With this at 0,
 * src/shims/time.h fell past its first branch for _dispatch_uptime and
 * _dispatch_monotonic_time to "#error platform needs to implement ...",
 * because the remaining branches all require __linux__. HAVE_MACH stays 0 --
 * that governs port-based IPC, which we genuinely do not have. */
#define HAVE_MACH_ABSOLUTE_TIME 1
#define HAVE_MACH_APPROXIMATE_TIME 0
#define HAVE_MACH_PORT_CONSTRUCT 0
#define HAVE_OBJC 0
#define HAVE_PTHREAD_WORKQUEUES 0
/* 1, and this is what RETIRES patch 6 rather than merely withdrawing it.
 * src/shims/priority.h guards on HAVE_PTHREAD_QOS_H && __has_include(
 * <pthread/qos_private.h>), and upstream models only "both present" or
 * "neither". Leaving this 0 while the sysroot HAS <sys/qos.h> puts us in the
 * third case Part 8 describes: priority.h takes the no-QoS branch and
 * re-defines every QOS_CLASS_* enumerator sys/qos.h already defined -- 18
 * errors, all redefinitions. machorun staged the three private QoS headers
 * (1ea43ff), so upstream's "both present" case is now simply TRUE and it takes
 * its own Darwin path. A config line, not a patch, exactly as predicted. */
#define HAVE_PTHREAD_QOS_H 1
#define HAVE_PTHREAD_WORKQUEUE_QOS 0
#define HAVE_PTHREAD_WORKQUEUE_SETDISPATCH_NP 0
#define HAVE_MALLOC_MALLOC_H 0
#define HAVE_SYS_CDEFS_H 1
#define HAVE_SYS_STAT_H 1
#define HAVE_SYS_TYPES_H 1
#define HAVE_UNISTD_H 1
#define HAVE_STRLCPY 1
/* 1, and I had this backwards. getprogname IS declared by the sysroot -- in
 * <_stdlib.h>, not <stdlib.h> -- and libSystem exports _getprogname. Grepping
 * only stdlib.h said "absent", which is the SAME trap build_cxxruntime.sh
 * already documents for div_t/ldiv_t. At 0, src/shims/getprogname.h defined
 * its own static one, colliding with the real declaration. */
#define HAVE_GETPROGNAME 1
#define HAVE_PROGRAM_INVOCATION_SHORT_NAME 1
#define VOUCHER_USE_MACH_VOUCHER 0
#define DISPATCH_USE_INTERNAL_WORKQUEUE 1
#define USE_OBJC 0

/* Selects patch 4's semaphore backend. NOT USE_POSIX_SEM, deliberately:
 * _dispatch_sema4_t is embedded by value, so Darwin's 4-byte sem_t would sit
 * where glibc's sem_init writes 32 -- a clean link, a 0 return, and 28 bytes
 * gone. Darwin also returns ENOSYS for sem_init, so USE_POSIX_SEM emulates a
 * configuration Apple's own platform does not have. See dispatch_patches.py. */
/* Selects patch 10's futex lock word. lock.h sets HAVE_FUTEX at line 169 under
 * `#ifndef HAVE_FUTEX`, so defining it HERE wins everywhere -- including the
 * branch at lock.h:58, which runs BEFORE line 169 and would otherwise read it
 * as 0. That ordering cost me a 4->20 error regression before I measured it.
 * Using upstream's own macro rather than inventing one also means lock.c's six
 * `#elif HAVE_FUTEX` sites activate with no patch at all. */
#define HAVE_FUTEX 1

/* The lock scheme and the TSD scheme are COUPLED, which is not obvious from
 * either file. libdispatch's futex lock builds its owner field from
 * _dispatch_get_tsd_base()->tid, and _dispatch_get_tsd_base() exists ONLY under
 * DISPATCH_USE_THREAD_LOCAL_STORAGE -- the Apple direct-TSD path has no such
 * accessor, because there the owner is a mach thread port instead. So taking
 * the futex lock (patch 10) obliges us to leave Apple's TSD optimisations too.
 * Measured: with direct TSD, src/shims/lock.c had 5 errors; with these, 1. */
#define USE_APPLE_TSD_OPTIMIZATIONS 0
#define DISPATCH_USE_THREAD_LOCAL_STORAGE 1

/* No dtrace on Linux. internal.h includes the CMake-GENERATED "provider.h"
 * under DISPATCH_USE_DTRACE, so this is a build-system artifact rather than a
 * porting gap -- worth saying because it looks like a missing header. */
#define DISPATCH_USE_DTRACE 0

#define USE_PTHREAD_SEM 1
#endif
