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
/* epoll_pwait takes a sigset_t*, which is 4 bytes on Darwin and 128 in glibc,
 * so it is a CROSSING call and must not carry a label -- a labelled version
 * would hand glibc a 4-byte object to read 128 bytes out of. It had one.
 * libSystem exports no _epoll_pwait today, so this is an unresolved symbol at
 * link if anything reaches for it, which is the failure we want while no
 * wrapper exists. Nothing in libdispatch or CF uses it (verified at the link:
 * the epoll symbols that actually appear are create1/ctl/wait). */
extern int epoll_pwait(int, struct epoll_event *, int, int, const sigset_t *);
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

/* CLOCK IDS DO NOT AGREE, AND ONLY ONE OF THE THREE ANNOUNCES ITSELF.
 *
 * timerfd_create is a Linux call, so its clockid argument must carry a LINUX
 * value. Measured on both sides rather than recalled:
 *
 *     clock              Darwin   Linux
 *     CLOCK_REALTIME       0        0     agrees
 *     CLOCK_MONOTONIC      6        1     DOES NOT AGREE
 *     CLOCK_BOOTTIME    absent      7     absent on Darwin
 *
 * Only CLOCK_BOOTTIME is a compile error. CLOCK_MONOTONIC is present, wrong,
 * and silent: Darwin's 6 is Linux's CLOCK_REALTIME_ALARM, so every
 * DISPATCH_CLOCK_UPTIME timer would either fail with EPERM (that clock wants
 * CAP_WAKE_ALARM) or, with the capability, quietly become a wall-clock alarm.
 * Adding only the constant the compiler asked for would have produced exactly
 * that. THE COMPILER OBJECTS TO THE ABSENT CONSTANT AND NEVER TO THE
 * PRESENT-BUT-WRONG ONE, which is the whole hazard in one line.
 *
 * So the Linux values get their own names and the call sites are patched to
 * use them (dispatch_patches.py, the event_epoll clockid patch). Translating
 * silently inside a macro would repeat the mistake this file exists to avoid. */
#define TFD_CLOCK_REALTIME  0
#define TFD_CLOCK_MONOTONIC 1
#define TFD_CLOCK_BOOTTIME  7
_Static_assert(CLOCK_REALTIME == 0 && CLOCK_MONOTONIC == 6,
    "Darwin's clock ids are not what this translation table was measured "
    "against. Re-measure both sides before trusting TFD_CLOCK_*.");
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
/* NO GLIBCSYM LABEL HERE, AND THAT IS THE WHOLE POINT.
 *
 * GLIBCSYM means "this ABI is identical on both sides, bind straight to glibc".
 * signalfd is the opposite: it takes a sigset_t*, Darwin's is 4 bytes and
 * glibc's is 128, and glibc reads the 8 it hands the kernel out of the guest's
 * 4. machorun's libSystem now TRANSLATES it (master e5e7224, verified present
 * in the built artifact), widening the mask and remapping the ten signal
 * numbers that differ.
 *
 * A GLIBCSYM label would emit _glibc_signalfd and bypass that translator
 * entirely -- shipping exactly the bug the wrapper was written to prevent.
 * Measured: with the label, event_epoll.o imported _glibc_signalfd. So the
 * declaration is plain, and binds to libSystem's _signalfd.
 *
 * This is the general rule for everything staged here: GLIBCSYM for a function
 * whose ABI genuinely matches, a PLAIN declaration for anything libSystem has
 * to translate. Getting that backwards is silent.
 *
 * The _Static_assert that used to sit here refusing to compile is gone,
 * because it said "there is no translating wrapper yet" and now there is. */
extern int signalfd(int, const sigset_t *, int);
#endif
EOF

cat > "$INC/sys/ioctl.h" <<'EOF'
#ifndef _SWIFTCORE_MACHO_SYS_IOCTL_H
#define _SWIFTCORE_MACHO_SYS_IOCTL_H
/* NOTE THE ABSENT GLIBCSYM. Every other declaration this script stages binds
 * DIRECT to glibc, because the two ABIs agree once the constants are right.
 * ioctl is the exception, and the reason is the calling convention rather than
 * any argument:
 *
 *   ioctl is VARIADIC, and Darwin's arm64 ABI passes variadic arguments on the
 *   STACK where AAPCS64 -- which glibc follows -- passes the first eight in
 *   registers. A direct bind would put the third argument on the stack and
 *   glibc would read x2, i.e. it would use whatever was in that register as a
 *   pointer and write through it. Silent memory corruption, not a wrong value.
 *
 * So this is declared plain, with Darwin's own prototype, and resolves against
 * libSystem -- which owns the translating wrappers and re-emits the varargs in
 * glibc's convention. libSystem does not export _ioctl yet, so this currently
 * FAILS AT THE LINK, naming the symbol. That is the intended failure: a link
 * error is recoverable and the corruption is not. */
int ioctl(int, unsigned long, ...);
#endif
EOF

cat > "$INC/linux/sockios.h" <<'EOF'
#ifndef _SWIFTCORE_MACHO_LINUX_SOCKIOS_H
#define _SWIFTCORE_MACHO_LINUX_SOCKIOS_H
#include <sys/ioctl.h>
/* Linux ioctl numbers; Darwin's FIONREAD is a different encoding entirely.
 *
 * BOTH HALVES OF THE PAIR, because the first version of this header had only
 * SIOCINQ and event_epoll.c uses `writer ? SIOCOUTQ : SIOCINQ` -- one
 * expression, one of the two names defined. Half a family is the recurring
 * shape of these gaps: the half that is used first gets added, and the other
 * half surfaces later as a compile error if you are lucky and as a wrong
 * number if you are not. Measured on the host: */
#define SIOCINQ  0x541b   /* == Linux FIONREAD */
#define SIOCOUTQ 0x5411   /* == Linux TIOCOUTQ */
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

# <poll.h>. CoreFoundation's epoll run loop reaches it (CFRunLoop.c:131).
# struct pollfd happens to agree between Darwin and glibc -- three fields, same
# order, same widths -- which is exactly the coincidence that makes a forward
# look safe without being checked, so the layout AND the event bits are pinned
# in sdk/tests/epoll_abi_probe.c rather than trusted.
cat > "$INC/poll.h" <<'EOF'
#ifndef _SWIFTCORE_MACHO_POLL_H
#define _SWIFTCORE_MACHO_POLL_H
/* ADDITIVE, NOT A REPLACEMENT. This sits at the same path as machorun's own
 * <poll.h>, so everything Darwin declares must come THROUGH it rather than be
 * restated here -- otherwise the header silently subtracts, which is the
 * mistake sdk/libc/signal.h made and which cost a day on #47.
 *
 * IT HAD ALREADY MADE IT, AND THE LABEL WAS THE ARMED PART. This file used to
 * declare `poll` itself, with GLIBCSYM(poll) and `typedef unsigned long nfds_t`:
 *
 *   nfds_t   `unsigned int` (4) in machorun's <sys/poll.h>, `unsigned long`
 *            (8) here. Two widths for one typedef name in one sysroot, chosen
 *            by which spelling of the include a TU happened to use.
 *   poll     GLIBCSYM bound it STRAIGHT TO GLIBC, bypassing libSystem's
 *            translating _poll -- which exists precisely because poll needs
 *            three translations: the nfds_t width, the POLLWRNORM/POLLWRBAND
 *            collision, and the sigset_t on ppoll.
 *
 * THE LABEL WAS NOT WRONG WHEN IT WAS WRITTEN. libSystem had no _poll then, so
 * a direct bind was the only option available. It went wrong when the wrapper
 * LANDED. A GLIBCSYM label is a claim about the world -- "no wrapper exists and
 * the two ABIs are identical" -- and it decays silently the moment either half
 * stops being true. Labels must be re-checked whenever libSystem grows a
 * symbol; that is now the audit at the end of this script.
 *
 * So: no poll, no nfds_t, no POLL* constants here. All of them come from
 * Darwin's own header below, and `poll` resolves to libSystem's wrapper. */
#include <sys/poll.h>

/* ppoll is the one genuine addition: not a Darwin API, so machorun's SDK does
 * not declare it, and libSystem exports _ppoll as an extension for us.
 * PLAIN, NOT LABELLED -- it takes a sigset_t*, 4 bytes on Darwin against 128 in
 * glibc, so it has to cross through the wrapper. CoreFoundation only ever
 * passes NULL for the mask, so the parameter stays void*: NULL converts and a
 * real sigset_t* does not compile, which keeps the hazard unreachable by
 * construction rather than by convention. */
extern int ppoll(struct pollfd *, nfds_t, const struct timespec *,
                 const void * /* sigset_t* would cross; see above */);
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

# ---------------------------------------------------------------------------
# THE LABEL AUDIT. A GLIBCSYM label decays; this is what notices.
#
# GLIBCSYM(x) binds a call DIRECTLY to glibc's x via the loader's dlsym path,
# bypassing libSystem entirely. That is correct only while libSystem has no
# wrapper for x -- and a wrapper existing is exactly what means the two ABIs
# were NOT identical after all, since nobody writes a translating wrapper for a
# call that could have been forwarded.
#
# So: LIBSYSTEM EXPORTING A SYMBOL WE HAVE LABELLED IS A CONTRADICTION, and the
# resolution is always to drop the label. This fired for real on `poll`: the
# label was written when libSystem had no _poll, machorun later added a _poll
# doing three separate translations, and the label went on quietly routing
# around all three. Nothing failed. The call succeeded and did the wrong thing.
#
# This is the mechanical version of a rule I would otherwise have to remember
# to re-check every time machorun grows a symbol, which is precisely the kind
# of thing that does not get remembered.
: "${LIBSYSTEM:=}"
if [ -z "$LIBSYSTEM" ]; then
  for c in "$SDK/../../lib/libSystem.B.dylib" "$(dirname "$INC")/../lib/libSystem.B.dylib" \
           /work/lib/libSystem.B.dylib "$HOME/machorun/darwin/usr/lib/libSystem.B.dylib"; do
    [ -f "$c" ] && { LIBSYSTEM=$c; break; }
  done
fi
if [ -z "$LIBSYSTEM" ]; then
  echo "stage_linux_abi: REFUSING -- cannot find libSystem.B.dylib to audit the" >&2
  echo "  GLIBCSYM labels against. Set LIBSYSTEM=<path>. Skipping this check is" >&2
  echo "  not an option: an unaudited label is how a translating wrapper gets" >&2
  echo "  bypassed silently (see the poll note above)." >&2
  exit 2
fi
# Pick an nm that can read Mach-O. GNU nm returns EMPTY rather than failing on
# these, so an unguarded `nm | grep` would report every symbol as absent and the
# audit would pass by producing nothing -- a false green of exactly the shape
# this script exists to prevent. Hence the positive control below.
NMBIN=""
for c in llvm-nm-18 llvm-nm nm; do command -v "$c" >/dev/null 2>&1 && { NMBIN=$c; break; }; done
[ -n "$NMBIN" ] || { echo "stage_linux_abi: no nm available for the label audit" >&2; exit 2; }
EXPORTS=$("$NMBIN" -gU "$LIBSYSTEM" 2>/dev/null | awk '{print $NF}')
# POSITIVE CONTROL: _malloc is in every libSystem ever built. If we cannot see
# it, the tool or the parse is wrong and every "not exported" answer below is
# meaningless.
case "$EXPORTS" in
  *_malloc*) ;;
  *) echo "stage_linux_abi: label audit ABORTED -- $NMBIN could not find _malloc" >&2
     echo "  in $LIBSYSTEM, so it cannot read this file and every result would" >&2
     echo "  be a false negative." >&2; exit 2 ;;
esac
# AUDIT THE STAGED HEADERS, NOT THIS SCRIPT'S TEXT. The first version grepped
# "$0" and immediately reported `poll` as bypassed -- from the PROSE above, which
# contains the literal GLIBCSYM(poll) while explaining why the label was removed.
# Same class as enumerating sources from comments, which dispatch_census.sh
# already had to learn. Grep the artifact, not the description of the artifact:
# only a label that reached a real header can bypass anything.
BYPASSED=""
LABELLED=$(grep -rhoE '\)[[:space:]]*GLIBCSYM\([a-z_0-9]+\)' "$INC" 2>/dev/null \
           | sed 's/.*GLIBCSYM(//;s/)//' | sort -u)
for sym in $LABELLED; do
  case "$EXPORTS" in
    *"_$sym"*)
      # substring match can over-report (_poll matches _ppoll), so confirm exact
      if printf '%s\n' "$EXPORTS" | grep -qx "_$sym"; then
        BYPASSED="$BYPASSED $sym"
      fi ;;
  esac
done
if [ -n "$BYPASSED" ]; then
  echo "stage_linux_abi: REFUSING -- libSystem exports a translating wrapper for" >&2
  echo "  symbols this script still binds DIRECTLY to glibc with GLIBCSYM:" >&2
  for s in $BYPASSED; do echo "      $s" >&2; done
  echo "  A wrapper exists because the ABIs differ. The label routes around it," >&2
  echo "  so the call succeeds and does the wrong thing. Drop the label and let" >&2
  echo "  the declaration bind to libSystem." >&2
  exit 2
fi

echo "staged Linux-ABI headers into $INC"
echo "  label audit: $(printf '%s\n' $LABELLED | grep -c .) labelled symbols in the staged headers, none shadowing a libSystem wrapper"
ls "$INC/sys/epoll.h" "$INC/sys/eventfd.h" "$INC/sys/timerfd.h" \
   "$INC/sys/signalfd.h" "$INC/linux/sockios.h" "$INC/linux/futex.h" "$INC/sys/syscall.h" "$INC/syscall.h" "$INC/poll.h" \
   "$INC/sys/ioctl.h" | sed 's/^/  /'
