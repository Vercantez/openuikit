/*
 * compat/objc4linux/darwin-cdefs.h  --  objc4-linux
 *
 * Force-included (-include) into every translation unit. Supplies the pieces
 * of Darwin's <sys/cdefs.h> that glibc's does not have, so the vendored
 * headers -- including the *public* ones we ship to clients -- need no edits.
 */
#ifndef _OBJC4LINUX_DARWIN_CDEFS_H
#define _OBJC4LINUX_DARWIN_CDEFS_H

#include <sys/cdefs.h>

#ifndef __unused
#   define __unused     __attribute__((__unused__))
#endif
#ifndef __used
#   define __used       __attribute__((__used__))
#endif
#ifndef __deprecated
#   define __deprecated __attribute__((__deprecated__))
#endif
#ifndef __pure
#   define __pure       __attribute__((__pure__))
#endif
#ifndef __const
#   define __const      const
#endif
#ifndef __dead2
#   define __dead2      __attribute__((__noreturn__))
#endif
#ifndef __pure2
#   define __pure2      __attribute__((__const__))
#endif
#ifndef __DARWIN_NULL
#   define __DARWIN_NULL NULL
#endif

/* glibc has __BEGIN_DECLS/__END_DECLS, but only under __cplusplus guards that
 * match Darwin's. Defined defensively. */
#ifndef __BEGIN_DECLS
#   ifdef __cplusplus
#       define __BEGIN_DECLS extern "C" {
#       define __END_DECLS   }
#   else
#       define __BEGIN_DECLS
#       define __END_DECLS
#   endif
#endif


/* ---- BSD/Darwin libc functions glibc does not have -------------------- */

#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <pthread.h>
#include <dlfcn.h>

/* reallocf: realloc that frees the original on failure. BSD/Darwin only. */
static inline void *objc4linux_reallocf(void *p, size_t n) {
    void *q = realloc(p, n);
    if (!q && n != 0) free(p);
    return q;
}
#ifndef reallocf
#   define reallocf objc4linux_reallocf
#endif

/* issetugid: "did this process start setuid/setgid?" Darwin/BSD have a
 * dedicated syscall. glibc does not; comparing real and effective ids is the
 * standard portable approximation. It differs from the real thing in one way:
 * a process that started setuid and then dropped privileges reads as clean
 * here but as tainted on Darwin. objc4 uses it only to decide whether to
 * honour OBJC_* environment variables, so this errs toward honouring them --
 * NOTE THE DIRECTION: it is the less conservative choice. Recorded in
 * docs/UNIMPLEMENTED.md. */
static inline int objc4linux_issetugid(void) {
    return (getuid() != geteuid()) || (getgid() != getegid());
}
#ifndef issetugid
#   define issetugid objc4linux_issetugid
#endif

/* Darwin dlopen/dlsym flag: "search only the given handle". glibc's dlsym
 * with an explicit handle already does that, so it is a no-op here. */
#ifndef RTLD_FIRST
#   define RTLD_FIRST 0
#endif

#ifdef __cplusplus
/* Darwin's pthread_setname_np names the CALLING thread and takes one
 * argument; glibc's takes (pthread_t, const char *). Add the Darwin spelling
 * as a C++ overload rather than editing the call site. glibc also caps the
 * name at 16 bytes including NUL and returns ERANGE otherwise, which Darwin
 * does not -- so long names silently fail to be set. */
static inline int pthread_setname_np(const char *name) {
    return ::pthread_setname_np(::pthread_self(), name);
}
#endif

/* objc4's Threading/lockdebug.h uses std::variant, and objc-exception.mm uses
 * std::terminate, but both rely on Darwin's libc++ pulling the headers in
 * transitively. libstdc++ does not. */
#ifdef __cplusplus
#   include <variant>
#   include <initializer_list>
#   include <exception>
#endif

#endif
