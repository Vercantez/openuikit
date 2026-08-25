/*
 * compat/_simple.h  --  objc4-linux
 *
 * Darwin's malloc-free, ObjC-free formatting/logging used by _objc_inform.
 * This MUST NOT allocate and MUST NOT call anything that could re-enter
 * objc_msgSend -- which is exactly why objc-os.h marks syslog()/vsyslog()
 * unavailable. Our implementation formats into a fixed stack buffer with
 * vsnprintf and write(2)s to stderr.
 */
#ifndef _OBJC4LINUX_SIMPLE_H
#define _OBJC4LINUX_SIMPLE_H

#include <stdarg.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef void *_SIMPLE_STRING;

/* asl(3) priority levels, same values as syslog(3)'s LOG_*. Our
 * _simple_asl_log ignores the level and writes to stderr. */
#define ASL_LEVEL_EMERG   0
#define ASL_LEVEL_ALERT   1
#define ASL_LEVEL_CRIT    2
#define ASL_LEVEL_ERR     3
#define ASL_LEVEL_WARNING 4
#define ASL_LEVEL_NOTICE  5
#define ASL_LEVEL_INFO    6
#define ASL_LEVEL_DEBUG   7

_SIMPLE_STRING _simple_salloc(void);
int   _simple_vsprintf(_SIMPLE_STRING b, const char *fmt, va_list ap);
int   _simple_sprintf(_SIMPLE_STRING b, const char *fmt, ...) __attribute__((format(printf, 2, 3)));
char *_simple_string(_SIMPLE_STRING b);
void  _simple_sfree(_SIMPLE_STRING b);
void  _simple_asl_log(int level, const char *facility, const char *message);
void  _simple_put(_SIMPLE_STRING b, const char *s);

#ifdef __cplusplus
}
#endif

#endif
