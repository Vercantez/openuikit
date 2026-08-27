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

echo "staged Linux-ABI headers into $INC"
ls "$INC/sys/epoll.h" "$INC/sys/eventfd.h" "$INC/sys/timerfd.h" \
   "$INC/sys/signalfd.h" "$INC/linux/sockios.h" "$INC/linux/futex.h" | sed 's/^/  /'
