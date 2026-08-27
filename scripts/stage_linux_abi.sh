#!/bin/bash
# Stage Linux-ABI headers into our Darwin sysroot, for libdispatch's epoll backend.
#
# WHY THESE ARE HAND-WRITTEN RATHER THAN GLIBC'S:
# glibc's <sys/epoll.h> needs glibc's <sys/cdefs.h> for __THROW. Our sysroot
# already owns that path with Apple's version, so including glibc's headers
# against -isysroot <our sdk> fails with 20 syntax errors in glibc's own
# declarations. The two libcs cannot share the include namespace.
#
# So we declare the Linux ABI ourselves, the way machorun's libSystem already
# declares glibc functions — with GLIBCSYM asm labels (`_glibc_<name>`), which
# the loader binds via dlsym(RTLD_DEFAULT, name) (src/resolve.c). Consequence:
# **libdispatch's own sources need no patch for this.** It is an SDK addition,
# which is the right place for it.
#
# EVERY CONSTANT AND LAYOUT BELOW WAS READ OFF THE HOST, not written from
# memory, and is pinned with _Static_assert so a wrong guess fails the build
# instead of corrupting memory. That mattered: struct epoll_event is PACKED and
# 12 bytes on x86_64 but UNPACKED and 16 bytes on aarch64. Writing the x86
# layout would have been silent corruption of every event.
set -euo pipefail
SDK=${SDK:-$HOME/work/sdk/MacOSX.sdk}
INC=$SDK/usr/include
mkdir -p "$INC/sys" "$INC/linux" "$INC/asm-generic"

cat > "$INC/sys/epoll.h" <<'EOF'
#ifndef _SWIFTCORE_MACHO_SYS_EPOLL_H
#define _SWIFTCORE_MACHO_SYS_EPOLL_H
#include <stdint.h>
#include <signal.h>
#define GLIBCSYM(n) __asm__("_glibc_" #n)
enum {
  EPOLLIN = 0x1, EPOLLPRI = 0x2, EPOLLOUT = 0x4, EPOLLERR = 0x8,
  EPOLLHUP = 0x10, EPOLLRDHUP = 0x2000,
  EPOLLEXCLUSIVE = (int)0x10000000, EPOLLWAKEUP = (int)0x20000000,
  EPOLLONESHOT = (int)0x40000000, EPOLLET = (int)0x80000000
};
#define EPOLL_CTL_ADD 1
#define EPOLL_CTL_DEL 2
#define EPOLL_CTL_MOD 3
#define EPOLL_CLOEXEC 0x80000
typedef union epoll_data { void *ptr; int fd; uint32_t u32; uint64_t u64; } epoll_data_t;
/* NOT __attribute__((packed)) on aarch64 — that is an x86_64-only quirk. */
struct epoll_event { uint32_t events; epoll_data_t data; };
_Static_assert(sizeof(epoll_data_t) == 8, "epoll_data_t");
_Static_assert(sizeof(struct epoll_event) == 16, "epoll_event size (aarch64: unpacked)");
_Static_assert(_Alignof(struct epoll_event) == 8, "epoll_event align");
_Static_assert(__builtin_offsetof(struct epoll_event, events) == 0, "epoll_event.events");
_Static_assert(__builtin_offsetof(struct epoll_event, data) == 8, "epoll_event.data");
extern int epoll_create1(int) GLIBCSYM(epoll_create1);
extern int epoll_ctl(int, int, int, struct epoll_event *) GLIBCSYM(epoll_ctl);
extern int epoll_wait(int, struct epoll_event *, int, int) GLIBCSYM(epoll_wait);
extern int epoll_pwait(int, struct epoll_event *, int, int, const sigset_t *) GLIBCSYM(epoll_pwait);
#endif
EOF

cat > "$INC/sys/eventfd.h" <<'EOF'
#ifndef _SWIFTCORE_MACHO_SYS_EVENTFD_H
#define _SWIFTCORE_MACHO_SYS_EVENTFD_H
#include <stdint.h>
#define GLIBCSYM(n) __asm__("_glibc_" #n)
#define EFD_SEMAPHORE 0x1
#define EFD_CLOEXEC   0x80000
#define EFD_NONBLOCK  0x800
typedef uint64_t eventfd_t;
extern int eventfd(unsigned int, int) GLIBCSYM(eventfd);
extern int eventfd_read(int, eventfd_t *) GLIBCSYM(eventfd_read);
extern int eventfd_write(int, eventfd_t) GLIBCSYM(eventfd_write);
#endif
EOF

cat > "$INC/sys/timerfd.h" <<'EOF'
#ifndef _SWIFTCORE_MACHO_SYS_TIMERFD_H
#define _SWIFTCORE_MACHO_SYS_TIMERFD_H
#include <time.h>
#define GLIBCSYM(n) __asm__("_glibc_" #n)
#define TFD_CLOEXEC       0x80000
#define TFD_NONBLOCK      0x800
#define TFD_TIMER_ABSTIME 0x1
/* Darwin's struct timespec is {time_t; long} = 16 bytes on arm64, same as
 * glibc's, so struct itimerspec matches at 32 bytes. Asserted, not assumed. */
struct itimerspec { struct timespec it_interval; struct timespec it_value; };
_Static_assert(sizeof(struct timespec) == 16, "timespec");
_Static_assert(sizeof(struct itimerspec) == 32, "itimerspec");
extern int timerfd_create(int, int) GLIBCSYM(timerfd_create);
extern int timerfd_settime(int, int, const struct itimerspec *, struct itimerspec *) GLIBCSYM(timerfd_settime);
extern int timerfd_gettime(int, struct itimerspec *) GLIBCSYM(timerfd_gettime);
#endif
EOF

cat > "$INC/sys/signalfd.h" <<'EOF'
#ifndef _SWIFTCORE_MACHO_SYS_SIGNALFD_H
#define _SWIFTCORE_MACHO_SYS_SIGNALFD_H
#include <stdint.h>
#include <signal.h>
#define GLIBCSYM(n) __asm__("_glibc_" #n)
#define SFD_CLOEXEC  0x80000
#define SFD_NONBLOCK 0x800
struct signalfd_siginfo {
  uint32_t ssi_signo, ssi_errno_pad; int32_t ssi_code;
  uint32_t ssi_pid, ssi_uid; int32_t ssi_fd;
  uint32_t ssi_tid, ssi_band, ssi_overrun, ssi_trapno;
  int32_t  ssi_status, ssi_int;
  uint64_t ssi_ptr, ssi_utime, ssi_stime, ssi_addr;
  uint16_t ssi_addr_lsb; uint16_t __pad2; int32_t ssi_syscall;
  uint64_t ssi_call_addr; uint32_t ssi_arch;
  uint8_t  __pad[128 - 4*10 - 4*2 - 8*4 - 2*2 - 4 - 8 - 4 - 4];
};
_Static_assert(sizeof(struct signalfd_siginfo) == 128, "signalfd_siginfo is 128 bytes");
_Static_assert(__builtin_offsetof(struct signalfd_siginfo, ssi_signo) == 0, "ssi_signo");
/* ARMED HAZARD, made loud rather than silent.
 *
 * This is the opaque/sized-type overflow class from the #49 audit, and unlike
 * the eight types that audit found dormant, THIS ONE IS REACHED: libdispatch's
 * event_epoll.c calls signalfd(-1, &sigmask, ...) with a sigset_t it owns.
 *
 *     Darwin sigset_t   4 bytes   (a uint32 bitmask)
 *     glibc  sigset_t  128 bytes
 *
 * A naive GLIBCSYM forward would hand glibc a 4-byte object and let it read the
 * 8 bytes it passes to the kernel -- so the guest subscribes to whatever
 * happens to sit next to its mask on the stack. Silent, plausible, and wrong.
 * pthread_sigmask is worse: its third argument is an OUT parameter, so a naive
 * forward WRITES 128 bytes into 4.
 *
 * So this declaration refuses to compile rather than forwarding. The fix is a
 * TRANSLATING wrapper in machorun's libSystem -- widen Darwin's 32-bit mask
 * into the kernel's, as the directory family is already translated rather than
 * forwarded -- not a declaration we can stage from here.
 */
_Static_assert(sizeof(sigset_t) == 8,
    "signalfd cannot be forwarded directly: Darwin's sigset_t is 4 bytes and "
    "glibc's is 128, so glibc would read past the guest's object. Needs a "
    "translating wrapper in libSystem, not a GLIBCSYM forward.");
extern int signalfd(int, const sigset_t *, int) GLIBCSYM(signalfd);
#endif
EOF

cat > "$INC/linux/sockios.h" <<'EOF'
#ifndef _SWIFTCORE_MACHO_LINUX_SOCKIOS_H
#define _SWIFTCORE_MACHO_LINUX_SOCKIOS_H
/* Linux ioctl number; Darwin's FIONREAD is a different encoding entirely. */
#define SIOCINQ  0x541b
#ifndef FIONREAD
#define FIONREAD SIOCINQ
#endif
#endif
EOF

cat > "$INC/linux/futex.h" <<'EOF'
#ifndef _SWIFTCORE_MACHO_LINUX_FUTEX_H
#define _SWIFTCORE_MACHO_LINUX_FUTEX_H
#define FUTEX_WAIT          0
#define FUTEX_WAKE          1
#define FUTEX_PRIVATE_FLAG  128
#define FUTEX_WAIT_PRIVATE  (FUTEX_WAIT | FUTEX_PRIVATE_FLAG)
#define FUTEX_WAKE_PRIVATE  (FUTEX_WAKE | FUTEX_PRIVATE_FLAG)
/* The lock-word bits. libdispatch's futex lock builds DLOCK_OWNER_MASK,
 * DLOCK_WAITERS_BIT and DLOCK_FAILED_TRYLOCK_BIT out of these, so getting one
 * wrong corrupts the lock word rather than failing to compile. Pinned against
 * real glibc in sdk/tests/epoll_abi_probe.c. */
#define FUTEX_WAITERS       0x80000000
#define FUTEX_OWNER_DIED    0x40000000
#define FUTEX_TID_MASK      0x3fffffff
/* Priority-inheritance ops: libdispatch's unfair lock uses FUTEX_LOCK_PI /
 * FUTEX_UNLOCK_PI so the kernel can boost a lock holder. Pinned in the probe. */
#define FUTEX_LOCK_PI       6
#define FUTEX_UNLOCK_PI     7
#define FUTEX_TRYLOCK_PI    8
#endif
EOF

# sys/syscall.h -- only SYS_futex, which is all libdispatch's lock needs. The
# value is pinned on aarch64 by the probe; declaring the whole syscall table
# would be surface we do not use and cannot check.
# <syscall.h> is the spelling src/shims/lock.c uses; glibc makes it a one-line
# forward to <sys/syscall.h>, and so do we.
cat > "$INC/syscall.h" <<'EOF'
#ifndef _SWIFTCORE_MACHO_SYSCALL_H
#define _SWIFTCORE_MACHO_SYSCALL_H
#include <sys/syscall.h>
#endif
EOF

cat > "$INC/sys/syscall.h" <<'EOF'
#ifndef _SWIFTCORE_MACHO_SYS_SYSCALL_H
#define _SWIFTCORE_MACHO_SYS_SYSCALL_H
#ifndef GLIBCSYM
#define GLIBCSYM(n) __asm__("_glibc_" #n)
#endif
#define SYS_futex 98    /* aarch64; _Static_assert'd in epoll_abi_probe.c */
#define SYS_gettid 178  /* aarch64; likewise */

/* gettid() as a DIRECT declaration, deliberately, rather than leaving callers
 * to reach it through syscall(SYS_gettid).
 *
 * syscall() is VARIADIC, and Darwin's arm64 variadic ABI is not AAPCS64 -- a
 * Darwin-compiled caller puts varargs on the stack while glibc expects them in
 * registers. That is the same reason machorun owns the printf formatter rather
 * than forwarding it, and it makes a GLIBCSYM forward of syscall() a live ABI
 * mismatch rather than a convenience. gettid() is non-variadic, is a real
 * exported glibc symbol (verified: `W gettid@@GLIBC_2.30`), and takes no
 * arguments at all, so it crosses cleanly. */
extern int gettid(void) GLIBCSYM(gettid);
#endif
EOF

cat > "$INC/linux/limits.h" <<'EOF'
#ifndef _SWIFTCORE_MACHO_LINUX_LIMITS_H
#define _SWIFTCORE_MACHO_LINUX_LIMITS_H
#include <limits.h>
#ifndef NAME_MAX
#define NAME_MAX 255
#endif
#ifndef PATH_MAX
#define PATH_MAX 4096
#endif
#endif
EOF

# The _Static_asserts inside these headers pin OUR MIRROR, not glibc -- they
# compile in a Darwin TU against our own declarations. sdk/tests/epoll_abi_probe.c
# is the check that actually looks at glibc; run it whenever these change.
if [ "$(uname -s)" = "Linux" ] && [ -f "$(dirname "$0")/run_epoll_abi_probe.sh" ]; then
  bash "$(dirname "$0")/run_epoll_abi_probe.sh" || {
    echo "ABORT: staged Linux ABI disagrees with real glibc." >&2; exit 1; }
fi

echo "staged Linux-ABI headers into $INC"
ls "$INC/sys/epoll.h" "$INC/sys/eventfd.h" "$INC/sys/timerfd.h" \
   "$INC/sys/signalfd.h" "$INC/linux/sockios.h" "$INC/linux/futex.h" "$INC/sys/syscall.h" "$INC/syscall.h" | sed 's/^/  /'
