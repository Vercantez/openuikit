/* swiftcore-macho: our libdispatch configuration.
 * internal.h prefers <config/config_ac.h> over the checked-in <config/config.h>,
 * which is a DARWIN config asserting HAVE_MACH 1 / HAVE_OBJC 1 /
 * HAVE_PTHREAD_WORKQUEUES 1. Using upstream's own escape hatch keeps our
 * settings in one auditable file and avoids -D flags colliding with it. */
#ifndef __SWIFTCORE_MACHO_DISPATCH_CONFIG_AC__
#define __SWIFTCORE_MACHO_DISPATCH_CONFIG_AC__
#define HAVE_MACH 0
#define HAVE_MACH_ABSOLUTE_TIME 0
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
#define HAVE_GETPROGNAME 0
#define HAVE_PROGRAM_INVOCATION_SHORT_NAME 1
#define VOUCHER_USE_MACH_VOUCHER 0
#define DISPATCH_USE_INTERNAL_WORKQUEUE 1
#define USE_OBJC 0

/* Selects patch 4's semaphore backend. NOT USE_POSIX_SEM, deliberately:
 * _dispatch_sema4_t is embedded by value, so Darwin's 4-byte sem_t would sit
 * where glibc's sem_init writes 32 -- a clean link, a 0 return, and 28 bytes
 * gone. Darwin also returns ENOSYS for sem_init, so USE_POSIX_SEM emulates a
 * configuration Apple's own platform does not have. See dispatch_patches.py. */
#define USE_PTHREAD_SEM 1
#endif
