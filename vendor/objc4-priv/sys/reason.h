/*
 * vendor/objc4-priv/sys/reason.h
 *
 * Apple's <sys/reason.h> is XNU-internal; the public SDK does not ship it.
 * These are the namespaces, codes and flags objc4 names when it calls
 * abort_with_reason() to record a structured crash.
 */
#ifndef _OBJC4_PRIV_SYS_REASON_H
#define _OBJC4_PRIV_SYS_REASON_H

#define OS_REASON_LIBSYSTEM                         18
#define OS_REASON_OBJC                              19

#define OS_REASON_LIBSYSTEM_CODE_FAULT              1

#define OBJC_EXIT_REASON_UNSPECIFIED                1
#define OBJC_EXIT_REASON_GC_NOT_SUPPORTED           2
#define OBJC_EXIT_REASON_CLASS_RO_SIGNING_REQUIRED  3

#define OS_REASON_FLAG_NO_CRASH_REPORT              0x00000001
#define OS_REASON_FLAG_ONE_TIME_FAILURE             0x00000002
#define OS_REASON_FLAG_GENERATE_CRASH_REPORT        0x00000004
#define OS_REASON_FLAG_CONSISTENT_FAILURE           0x00000008
#define OS_REASON_FLAG_ABORT                        0x00000010

#endif
