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
__END_DECLS
#endif /* _SIGNAL_H_ */
