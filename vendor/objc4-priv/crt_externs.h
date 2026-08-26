/*
 * vendor/objc4-priv/crt_externs.h
 *
 * The public SDK's <crt_externs.h> declares _NSGetArgc/_NSGetArgv/_NSGetEnviron
 * /_NSGetProgname but NOT `__progname`, which objc-block-trampolines.mm reads
 * directly (the QtWebEngineProcess / Steam Helper eager-load workaround, inside
 * `#if TARGET_OS_OSX`). Apple's internal crt_externs.h declares it; ours adds
 * exactly that one line on top of the real header.
 */
#ifndef _OBJC4_PRIV_CRT_EXTERNS_H
#define _OBJC4_PRIV_CRT_EXTERNS_H

#include_next <crt_externs.h>

__BEGIN_DECLS
/* BSD's "name this process was invoked as". Set by crt1 on Darwin; machorun's
 * libSystem sets it from argv[0] at startup. */
extern const char *__progname;
__END_DECLS

#endif
