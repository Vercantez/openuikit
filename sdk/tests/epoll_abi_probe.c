/*
 * epoll_abi_probe.c -- pin the LINUX half of the epoll/eventfd/timerfd/signalfd
 * ABI that scripts/stage_linux_abi.sh declares by hand.
 *
 * COMPILE-ONLY, and compiled by the HOST compiler against REAL GLIBC HEADERS.
 * That is the entire point, and it is the gap this file closes.
 *
 * THE BUG IN MY OWN WORK THAT THIS FIXES
 * --------------------------------------
 * scripts/stage_linux_abi.sh stages Darwin-side headers carrying assertions
 * like:
 *
 *     _Static_assert(sizeof(struct epoll_event) == 16, "...");
 *
 * Those compile in a TU built `-target arm64-apple-macos -isysroot <our sdk>`,
 * against MY OWN declaration of struct epoll_event. So the assertion proves my
 * mirror is 16 bytes and proves NOTHING about the struct the kernel and glibc
 * will actually use. If glibc's layout moved, it would keep passing while every
 * epoll event was silently misread -- the same shape as machorun's
 * `_Static_assert(sizeof(struct linux_stat) == 128)` in posix.c, which pins a
 * mirror and says nothing about glibc.
 *
 * I did read these numbers off the host when I wrote the headers, but that was a
 * one-shot manual step, not a durable check. This file makes it a build-time
 * one.
 *
 * WHY NOT REUSE sdk_abi_probe
 * ---------------------------
 * That instrument compares OUR SDK against APPLE'S -- both Darwin. It is the
 * right check for "do our headers match Apple's" and the WRONG one here: this
 * is a Darwin-declaration-versus-glibc-reality hazard, and a Darwin-vs-Darwin
 * comparison would pass while the bug is present. Different question, different
 * instrument.
 *
 * HOW TO RUN
 *   cc -std=gnu11 -fsyntax-only sdk/tests/epoll_abi_probe.c        (Linux only)
 * It is skipped on macOS, where <sys/epoll.h> does not exist.
 *
 * DEMONSTRATE THE TEETH: -DEPOLL_ABI_PROBE_MUTANT flips one expected value, and
 * the file MUST then fail to compile. A probe never shown to fail is not a probe.
 */

#if !defined(__linux__)
#error "epoll_abi_probe.c is the LINUX half; compile it with the host compiler on Linux."
#endif

#include <stddef.h>
#include <stdint.h>
#include <sys/epoll.h>
#include <sys/eventfd.h>
#include <sys/timerfd.h>
#include <sys/signalfd.h>
#include <sys/syscall.h>
#include <linux/futex.h>
#include <asm-generic/ioctls.h>   /* FIONREAD; linux/sockios.h aliases SIOCINQ */
#include <time.h>

#ifdef EPOLL_ABI_PROBE_MUTANT
#  define EXPECT_EPOLL_EVENT_SIZE 12   /* the x86_64 packed size: MUST fail here */
#else
#  define EXPECT_EPOLL_EVENT_SIZE 16
#endif

/* --------------------------------------------------------------- epoll ----
 * The one that matters most. struct epoll_event is __attribute__((packed)) and
 * 12 bytes on x86_64, but UNPACKED and 16 bytes on aarch64 with data at offset
 * 8. Writing the x86 layout on aarch64 corrupts every event, silently, with no
 * diagnostic anywhere.
 */
_Static_assert(sizeof(struct epoll_event) == EXPECT_EPOLL_EVENT_SIZE,
    "struct epoll_event size disagrees with sdk/linux-abi sys/epoll.h");
_Static_assert(_Alignof(struct epoll_event) == 8, "epoll_event alignment");
_Static_assert(offsetof(struct epoll_event, events) == 0, "epoll_event.events offset");
_Static_assert(offsetof(struct epoll_event, data) == 8, "epoll_event.data offset");
_Static_assert(sizeof(epoll_data_t) == 8, "epoll_data_t size");

_Static_assert(EPOLLIN == 0x1,        "EPOLLIN");
_Static_assert(EPOLLPRI == 0x2,       "EPOLLPRI");
_Static_assert(EPOLLOUT == 0x4,       "EPOLLOUT");
_Static_assert(EPOLLERR == 0x8,       "EPOLLERR");
_Static_assert(EPOLLHUP == 0x10,      "EPOLLHUP");
_Static_assert(EPOLLRDHUP == 0x2000,  "EPOLLRDHUP");
_Static_assert((unsigned)EPOLLONESHOT == 0x40000000u, "EPOLLONESHOT");
_Static_assert((unsigned)EPOLLET == 0x80000000u,      "EPOLLET");
_Static_assert(EPOLL_CTL_ADD == 1 && EPOLL_CTL_DEL == 2 && EPOLL_CTL_MOD == 3,
    "EPOLL_CTL_*");
_Static_assert(EPOLL_CLOEXEC == 0x80000, "EPOLL_CLOEXEC");

/* ------------------------------------------------------------- eventfd ----
 * eventfd is the poke/wakeup path of the epoll backend; a wrong EFD_NONBLOCK
 * would deadlock the manager thread rather than fail loudly.
 */
_Static_assert(EFD_SEMAPHORE == 0x1,   "EFD_SEMAPHORE");
_Static_assert(EFD_CLOEXEC == 0x80000, "EFD_CLOEXEC");
_Static_assert(EFD_NONBLOCK == 0x800,  "EFD_NONBLOCK");
_Static_assert(sizeof(eventfd_t) == 8, "eventfd_t");

/* ------------------------------------------------------------- timerfd ----
 * struct itimerspec is two struct timespec. Darwin's timespec is {time_t; long}
 * = 16 bytes on arm64 and so is glibc's, which is why our Darwin-side header can
 * declare itimerspec at all -- but that coincidence must be CHECKED, not assumed.
 */
_Static_assert(sizeof(struct timespec) == 16,  "timespec (Darwin/glibc coincide)");
_Static_assert(sizeof(struct itimerspec) == 32, "itimerspec");
_Static_assert(offsetof(struct itimerspec, it_interval) == 0,  "it_interval");
_Static_assert(offsetof(struct itimerspec, it_value) == 16,    "it_value");
_Static_assert(TFD_CLOEXEC == 0x80000,     "TFD_CLOEXEC");
_Static_assert(TFD_NONBLOCK == 0x800,      "TFD_NONBLOCK");
_Static_assert(TFD_TIMER_ABSTIME == 0x1,   "TFD_TIMER_ABSTIME");

/* ------------------------------------------------------------ signalfd ----*/
_Static_assert(sizeof(struct signalfd_siginfo) == 128, "signalfd_siginfo");
_Static_assert(offsetof(struct signalfd_siginfo, ssi_signo) == 0, "ssi_signo");
_Static_assert(SFD_CLOEXEC == 0x80000,  "SFD_CLOEXEC");
_Static_assert(SFD_NONBLOCK == 0x800,   "SFD_NONBLOCK");

/* ---------------------------------------------------------------- misc ----*/
_Static_assert(FIONREAD == 0x541b, "SIOCINQ/FIONREAD (Linux encoding, not Darwin's)");
_Static_assert(FUTEX_WAIT == 0 && FUTEX_WAKE == 1 && FUTEX_PRIVATE_FLAG == 128,
    "FUTEX_*");
_Static_assert(SYS_futex == 98, "SYS_futex on aarch64");
/* The lock-word bits, added when libdispatch's futex lock became reachable.
 * These are NOT cosmetic: DLOCK_OWNER_MASK is FUTEX_TID_MASK, and the waiters /
 * failed-trylock bits are FUTEX_WAITERS / FUTEX_OWNER_DIED. A wrong value here
 * corrupts the lock word at runtime instead of failing to build, so the staged
 * declarations are a HYPOTHESIS and this is the test. */
_Static_assert(FUTEX_WAITERS    == 0x80000000, "FUTEX_WAITERS");
_Static_assert(FUTEX_OWNER_DIED == 0x40000000, "FUTEX_OWNER_DIED");
_Static_assert(FUTEX_TID_MASK   == 0x3fffffff, "FUTEX_TID_MASK");

/* Compile-only. */
