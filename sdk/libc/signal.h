/* signal.h — clean-room. Darwin's <signal.h> is a thin wrapper that pulls in
 * <sys/signal.h> (which machorun's SDK already carries from xnu) and adds the
 * sig_atomic_t typedef plus the two ISO C entry points. */
#ifndef _SIGNAL_H_
#define _SIGNAL_H_
#include <sys/cdefs.h>
#include <sys/signal.h>
#include <sys/_types.h>
typedef int sig_atomic_t;
__BEGIN_DECLS
void (*signal(int, void (*)(int)))(int);
int raise(int);

/* The sigset_t manipulators. CLEAN-ROOM: these are POSIX-specified semantics
 * over a layout we measured -- Darwin's sigset_t is a 4-byte bitmask where
 * signal N owns bit N-1. They are INLINE on Darwin too, not library calls, so
 * libSystem exports none of them (measured: 0 defined symbols for each) and
 * declaring them extern would produce a link error rather than a call.
 *
 * They are also the SAFE half of the signal surface, and the distinction
 * matters. These touch only the guest's own 4-byte object, so nothing crosses
 * the Darwin/glibc boundary. The unsafe half is anything that hands a
 * sigset_t* to glibc, whose sigset_t is 128 bytes -- see the armed-hazard note
 * on signalfd in scripts/stage_linux_abi.sh. pthread_sigmask is the worst of
 * them, since its third argument is an OUT parameter.
 *
 * If machorun's <sys/signal.h> ever gains these, the redefinition will be a
 * compile error. That is the outcome we want: loud, not silently divergent. */
#ifndef _SWIFTCORE_MACHO_SIGSET_OPS
#define _SWIFTCORE_MACHO_SIGSET_OPS 1
#define __sigbits(signo) (1U << ((signo) - 1))

static __inline int sigemptyset(sigset_t *set) { *set = 0; return 0; }
static __inline int sigfillset(sigset_t *set) { *set = ~(sigset_t)0; return 0; }
static __inline int sigaddset(sigset_t *set, int signo)
{ *set |= __sigbits(signo); return 0; }
static __inline int sigdelset(sigset_t *set, int signo)
{ *set &= ~__sigbits(signo); return 0; }
static __inline int sigismember(const sigset_t *set, int signo)
{ return (*set & __sigbits(signo)) != 0; }
#endif /* _SWIFTCORE_MACHO_SIGSET_OPS */
__END_DECLS
#endif /* _SIGNAL_H_ */
