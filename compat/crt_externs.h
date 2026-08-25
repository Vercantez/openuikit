/* compat/crt_externs.h -- objc4-linux.
 * _NSGetEnviron() exists on Darwin because environ is not directly exported
 * from a dylib. On Linux `environ` is a plain global in libc. */
#ifndef _OBJC4LINUX_CRT_EXTERNS_H
#define _OBJC4LINUX_CRT_EXTERNS_H
#ifdef __cplusplus
extern "C" {
#endif
extern char **environ;
static inline char ***_NSGetEnviron(void) { return &environ; }
extern int    *_NSGetArgc(void);
extern char ***_NSGetArgv(void);
#ifdef __cplusplus
}
#endif
#endif
