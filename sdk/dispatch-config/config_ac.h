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
#endif
