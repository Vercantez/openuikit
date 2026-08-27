/*
 * glibc_abi_probe.c -- pin the LINUX half of every ABI we forward across.
 *
 * COMPILE-ONLY, and compiled by the HOST compiler against REAL GLIBC HEADERS,
 * which is the whole point: it is the only file in this repository that does.
 * Everything under darwin/src/ is built `-nostdinc` for arm64-apple-macos and
 * cannot see a glibc header, so its assertions about Linux are assertions about
 * OUR HAND-WRITTEN MIRRORS, not about glibc.
 *
 * That gap was real. `posix.c` carries
 *     _Static_assert(sizeof(struct linux_stat) == 128, ...)
 * which proves our mirror is 128 bytes and proves nothing at all about the
 * struct glibc will actually write into. If glibc's layout ever moved, that
 * assertion would keep passing while `stat()` silently returned nonsense.
 * The first assertion below is the one that closes it.
 *
 * ---------------------------------------------------------------------------
 * THE HAZARD THIS FILE EXISTS FOR
 *
 * Darwin and glibc disagree about the size of most "opaque" C library types,
 * and the disagreement runs BOTH ways. Measured 2026-08-27, Darwin from Apple's
 * own headers on macOS 26.5.2, glibc from the test-bed image:
 *
 *   type                          Darwin   glibc   forwarding a glibc object
 *                                                  into the guest's storage
 *   ---------------------------------------------------------------------
 *   pthread_mutex_t                   64      48   fits (this is why adopt()
 *   pthread_cond_t                    48      48   fits  works at all)
 *   pthread_rwlock_t                 200      56   fits
 *   pthread_once_t                    16       4   fits
 *   pthread_mutexattr_t               16       8   fits
 *   struct stat                      144     128   TRANSLATED, field by field
 *   ---------------------------------------------------------------------
 *   posix_spawnattr_t                  8     336   OVERFLOWS by 328
 *   posix_spawn_file_actions_t         8      80   OVERFLOWS by 72
 *   sem_t                              4      32   OVERFLOWS by 28
 *   regex_t                           32      64   OVERFLOWS by 32
 *   jmp_buf                          192     312   OVERFLOWS by 120
 *   sigjmp_buf                       196     312   OVERFLOWS by 116
 *   sigset_t                           4     128   OVERFLOWS by 124
 *   ucontext_t                       880    4560   OVERFLOWS by 3680
 *   ---------------------------------------------------------------------
 *   struct dirent                   1048     280   fits, and is STILL WRONG:
 *                                                  d_type is at 20 on Darwin
 *                                                  and 18 here, d_name at 21
 *                                                  and 19. The guest reads the
 *                                                  wrong bytes, quietly.
 *   glob_t                            88      72   fits, same layout problem
 *
 * A type in the OVERFLOWS block must never be handed to glibc in the guest's
 * storage: the guest reserved Darwin's size, glibc writes its own, and the
 * excess lands on whatever the guest had next. Every symbol resolves, the link
 * is clean, and the call returns success. docs/UNIMPLEMENTED.md#opaque-abi-class
 * has the full table and what to do instead.
 *
 * None of those are forwarded today -- `stat`/`fstat`/`lstat` are the only
 * members of this class libSystem exports, and they are translated. This file
 * is the tripwire for the next person to close one of them.
 *
 * WHY ASSERT EXACT SIZES rather than `<= darwin_size`: a `<=` check passes for
 * the eight types that overflow only because it would be written the other way
 * round, and it says nothing when glibc changes in the safe direction. An exact
 * value fails on ANY movement and sends the reader back to the table above,
 * which is where the fits/overflows verdict actually lives.
 */
#define _GNU_SOURCE 1
#define _XOPEN_SOURCE 700

#include <dirent.h>
#include <time.h>
#include <glob.h>
#include <pthread.h>
#include <regex.h>
#include <semaphore.h>
#include <setjmp.h>
#include <signal.h>
#include <spawn.h>
#include <stddef.h>
#include <dlfcn.h>
#include <errno.h>
#include <netinet/in.h>
#include <pwd.h>
#include <signal.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <poll.h>
#include <fcntl.h>
#include <sched.h>
#include <ucontext.h>

#define PIN(type, bytes) \
    _Static_assert(sizeof(type) == (bytes), \
        #type " is no longer " #bytes " bytes in glibc. Re-read the table in " \
        "sdk/tests/glibc_abi_probe.c: this number decides whether a glibc " \
        "object fits in the storage a Darwin guest reserved.")

/* The one that closes a live hole: darwin/src/posix.c mirrors this by hand. */
PIN(struct stat, 128);
_Static_assert(offsetof(struct stat, st_size) == 48,
    "glibc struct stat has moved st_size; stat_l2d() in darwin/src/posix.c "
    "reads it at a hard-coded offset and would now translate garbage.");

/* Fit inside Darwin's footprint. adopt() in darwin/src/libsystem.c depends on
 * these staying smaller than the Darwin sizes in the table above. */
PIN(pthread_mutex_t,      48);
PIN(pthread_cond_t,       48);
PIN(pthread_rwlock_t,     56);
PIN(pthread_once_t,        4);
PIN(pthread_mutexattr_t,   8);
PIN(pthread_condattr_t,    8);
PIN(pthread_rwlockattr_t,  8);
PIN(pthread_attr_t,       64);

/* THE CONSTANTS ARE SWAPPED, and that is not a size problem so nothing above
 * would catch it. Darwin: NORMAL 0, ERRORCHECK 1, RECURSIVE 2. glibc: NORMAL
 * 0, RECURSIVE 1, ERRORCHECK 2. A forwarded settype(RECURSIVE) therefore
 * yields an ERRORCHECK mutex that returns EDEADLK the first time its owner
 * relocks it -- every symbol resolving, every size matching, the behaviour
 * inverted. darwin/src/libsystem.c translates; this pins the glibc half so a
 * change there fails the build instead of silently un-swapping the mapping.
 * tests/bin/21_pthread_cond case 5 is the behavioural check. */
_Static_assert(PTHREAD_MUTEX_NORMAL     == 0, "glibc PTHREAD_MUTEX_NORMAL moved");
_Static_assert(PTHREAD_MUTEX_RECURSIVE  == 1, "glibc PTHREAD_MUTEX_RECURSIVE moved; "
    "darwin/src/libsystem.c's mutex_type_d2g() maps Darwin's 2 onto this value");
_Static_assert(PTHREAD_MUTEX_ERRORCHECK == 2, "glibc PTHREAD_MUTEX_ERRORCHECK moved; "
    "darwin/src/libsystem.c's mutex_type_d2g() maps Darwin's 1 onto this value");

/* pthread_cond_t is the one that does NOT fit: Darwin gives 48 bytes of which
 * the first 8 are the __sig word, leaving 40, and glibc wants 48. That is why
 * libsystem.c keeps a POINTER in the opaque area rather than the object. If
 * this number ever drops to 40 or below the handle indirection could be
 * dropped -- but check the sig word still survives before doing it. */
_Static_assert(sizeof(pthread_cond_t) == 48,
    "glibc pthread_cond_t changed size; darwin/src/libsystem.c stores a handle "
    "because 48 does not fit in Darwin's 40 opaque bytes. Re-check that reasoning.");

/* And the errno values pthread returns BY VALUE rather than through errno.
 * ETIMEDOUT differs and EAGAIN/EDEADLK are swapped, which is why every pthread
 * return goes through mr_pthread_rc(). */
_Static_assert(ETIMEDOUT == 110, "glibc ETIMEDOUT moved (Darwin's is 60)");
_Static_assert(EDEADLK   ==  35, "glibc EDEADLK moved (Darwin's is 11)");
_Static_assert(EAGAIN    ==  11, "glibc EAGAIN moved (Darwin's is 35)");
_Static_assert(EBUSY     ==  16, "glibc EBUSY moved (Darwin's is 16 too, so far)");

/* Do NOT fit. Forwarding any of these into guest storage corrupts it. */
PIN(posix_spawnattr_t,          336);
PIN(posix_spawn_file_actions_t,  80);
PIN(sem_t,                       32);
PIN(regex_t,                     64);
PIN(sigset_t,                   128);
PIN(ucontext_t,                4560);
PIN(jmp_buf,                    312);
PIN(sigjmp_buf,                 312);

/* Fit, but differ in LAYOUT, which is the quieter failure: the guest reads
 * Darwin's offsets out of a glibc object. readdir() must translate, not
 * forward. */
PIN(struct dirent, 280);
_Static_assert(offsetof(struct dirent, d_type) == 18,
    "glibc struct dirent has moved d_type (Darwin puts it at 20). Any readdir() "
    "forwarder must translate field by field, like stat_l2d() does.");
_Static_assert(offsetof(struct dirent, d_name) == 19,
    "glibc struct dirent has moved d_name (Darwin puts it at 21).");
PIN(glob_t, 72);

/* struct passwd: 48 here against Darwin's 72, agreeing for the first four
 * fields and diverging after -- so posix.c translates rather than forwards.
 * These pin the LINUX half of that translation, which posix.c's own
 * `struct linux_passwd` mirror cannot do for itself. pw_dir is the field that
 * matters: at Darwin's offset 48 it reads past the end of this allocation. */
PIN(struct passwd, 48);
_Static_assert(offsetof(struct passwd, pw_gecos) == 24,
    "glibc struct passwd moved pw_gecos (Darwin puts it at 40)");
_Static_assert(offsetof(struct passwd, pw_dir)   == 32,
    "glibc struct passwd moved pw_dir (Darwin puts it at 48 -- past the end of this struct)");
_Static_assert(offsetof(struct passwd, pw_shell) == 40,
    "glibc struct passwd moved pw_shell (Darwin puts it at 56)");

/* ------------------------------------------------------------------ CONSTANTS
 * A hazard the size checks above structurally cannot see: same width, symbols
 * resolve, behaviour inverts. Measured across 160 constants, 76 differ. errno,
 * the O_* flags, MAP_ANON and the clock ids were already translated when this
 * audit ran; sysconf was not, and every one of its 128 shared _SC_* names has a
 * different value on the two systems.
 *
 * The two families below are NOT forwarded today -- libSystem exports no
 * sigaction, kill, raise, socket or setsockopt -- so these are landmines rather
 * than live bugs. They are pinned now because the measurement exists and
 * because both have imminent consumers: libdispatch's link step reaches the
 * socket constants, and CF's remaining surface reaches into both. Pinning is
 * cheap while nobody is under pressure to ship the symbol.
 *
 * The Darwin halves live in sdk/tests/abi_probe.c, which compiles against our
 * SDK and diffs against Apple's. Signals are there; SOCKETS ARE NOT, because
 * sys/socket.h is staged with a dangling include (sys/constrained_ctypes.h)
 * and nothing can compile against it yet. So the socket family is currently
 * guarded on ONE side only, and that is recorded rather than glossed. */

/* SIGNALS. Nine of the 28 shared names differ, and three form a CYCLE --
 * Darwin SIGCONT 19 / SIGCHLD 20 against Linux 18 / 17 -- so a forwarded
 * number does not merely miss, it names a DIFFERENT REAL SIGNAL. A guest
 * asking to handle SIGCHLD would be handed SIGCONT. */
_Static_assert(SIGBUS  ==  7, "glibc SIGBUS moved (Darwin's is 10)");
_Static_assert(SIGUSR1 == 10, "glibc SIGUSR1 moved (Darwin's is 30)");
_Static_assert(SIGUSR2 == 12, "glibc SIGUSR2 moved (Darwin's is 31)");
_Static_assert(SIGCHLD == 17, "glibc SIGCHLD moved (Darwin's is 20 -- and Darwin's 17 is SIGSTOP)");
_Static_assert(SIGCONT == 18, "glibc SIGCONT moved (Darwin's is 19 -- and Darwin's 18 is SIGTSTP)");
_Static_assert(SIGSTOP == 19, "glibc SIGSTOP moved (Darwin's is 17)");
_Static_assert(SIGTSTP == 20, "glibc SIGTSTP moved (Darwin's is 18)");
_Static_assert(SIGURG  == 23, "glibc SIGURG moved (Darwin's is 16)");
_Static_assert(SIGSYS  == 31, "glibc SIGSYS moved (Darwin's is 12)");
/* The three that agree, pinned so a change is noticed rather than assumed. */
_Static_assert(SIGSEGV == 11, "glibc SIGSEGV moved (Darwin's is 11 too, so far)");
_Static_assert(SIGKILL ==  9, "glibc SIGKILL moved");
_Static_assert(SIGPIPE == 13, "glibc SIGPIPE moved");
/* sigprocmask's how-argument is shifted by one, which is the quiet kind: every
 * value is valid on both sides, so a forward silently does the wrong operation
 * -- SIG_BLOCK becomes SIG_UNBLOCK. */
_Static_assert(SIG_BLOCK   == 0, "glibc SIG_BLOCK moved (Darwin's is 1)");
_Static_assert(SIG_UNBLOCK == 1, "glibc SIG_UNBLOCK moved (Darwin's is 2)");
_Static_assert(SIG_SETMASK == 2, "glibc SIG_SETMASK moved (Darwin's is 3)");
_Static_assert(SA_SIGINFO  == 4, "glibc SA_SIGINFO moved (Darwin's is 64)");

/* SOCKETS. SOL_SOCKET is the one to notice: 65535 on Darwin against 1 on
 * Linux, and 1 on Linux is a valid level, so a forwarded setsockopt would set
 * an option at the wrong level rather than failing. Every SO_* differs too. */
_Static_assert(SOL_SOCKET   == 1, "glibc SOL_SOCKET moved (Darwin's is 65535)");
_Static_assert(SO_REUSEADDR == 2, "glibc SO_REUSEADDR moved (Darwin's is 4)");
_Static_assert(SO_ERROR     == 4, "glibc SO_ERROR moved (Darwin's is 4103)");
_Static_assert(SO_BROADCAST == 6, "glibc SO_BROADCAST moved (Darwin's is 32)");
_Static_assert(SO_SNDBUF    == 7, "glibc SO_SNDBUF moved (Darwin's is 4097)");
_Static_assert(SO_RCVBUF    == 8, "glibc SO_RCVBUF moved (Darwin's is 4098)");
_Static_assert(SO_KEEPALIVE == 9, "glibc SO_KEEPALIVE moved (Darwin's is 8)");
_Static_assert(SO_LINGER    == 13, "glibc SO_LINGER moved (Darwin's is 128)");
_Static_assert(AF_INET6     == 10, "glibc AF_INET6 moved (Darwin's is 30)");
/* AF_UNIX/AF_INET and SOCK_STREAM/SOCK_DGRAM agree; pinned for the same
 * reason as the agreeing signals. */
_Static_assert(AF_UNIX    == 1, "glibc AF_UNIX moved");
_Static_assert(AF_INET    == 2, "glibc AF_INET moved");
_Static_assert(SOCK_STREAM == 1, "glibc SOCK_STREAM moved");
_Static_assert(SOCK_DGRAM  == 2, "glibc SOCK_DGRAM moved");

/* dlfcn, because dlopen's mode already crosses: darwin/src/objcsupport.c tests
 * RTLD_NOLOAD using DARWIN's 0x10, which is right precisely because the guest
 * passes Darwin's value and we never forward the mode to glibc. If anyone ever
 * does forward it, 0x10 means something else here. */
_Static_assert(RTLD_NOLOAD == 4,   "glibc RTLD_NOLOAD moved (Darwin's is 16 -- and libSystem tests Darwin's)");
_Static_assert(RTLD_GLOBAL == 256, "glibc RTLD_GLOBAL moved (Darwin's is 8)");

/* pthread attributes, which CF's list reaches (pthread_attr_setdetachstate). */
_Static_assert(PTHREAD_CREATE_JOINABLE == 0, "glibc PTHREAD_CREATE_JOINABLE moved (Darwin's is 1)");
_Static_assert(PTHREAD_CREATE_DETACHED == 1, "glibc PTHREAD_CREATE_DETACHED moved (Darwin's is 2)");

/* Not a struct-shape problem but the same family: a width mismatch inside a
 * translated struct. Darwin's dev_t is 4 bytes and mode_t/nlink_t are 2. */
PIN(dev_t,   8);
PIN(mode_t,  4);
PIN(nlink_t, 4);

/* CLOCK IDS. darwin/src/posix.c's mr_linux_clock_id() maps Darwin's ids onto
 * these, and BOTH tables in it are hand-written -- so before this block
 * nothing verified either half. That is the shape of the linux_stat bug at
 * the top of this file: a mirror of glibc's values that glibc never checks.
 *
 * A wrong value here does not fail: it silently reads a DIFFERENT CLOCK.
 * Passing Darwin's CLOCK_MONOTONIC (6) through untranslated lands on Linux's
 * CLOCK_REALTIME_ALARM, which at least needs a capability and returns EPERM;
 * most other confusions just return the wrong time. */
_Static_assert(CLOCK_REALTIME           == 0, "glibc CLOCK_REALTIME moved (Darwin's is 0 too)");
_Static_assert(CLOCK_MONOTONIC          == 1, "glibc CLOCK_MONOTONIC moved (Darwin's is 6)");
_Static_assert(CLOCK_PROCESS_CPUTIME_ID == 2, "glibc CLOCK_PROCESS_CPUTIME_ID moved (Darwin's is 12)");
_Static_assert(CLOCK_THREAD_CPUTIME_ID  == 3, "glibc CLOCK_THREAD_CPUTIME_ID moved (Darwin's is 16)");
_Static_assert(CLOCK_MONOTONIC_RAW      == 4, "glibc CLOCK_MONOTONIC_RAW moved (Darwin's is 4 too)");
_Static_assert(CLOCK_BOOTTIME           == 7, "glibc CLOCK_BOOTTIME moved");

/* POLL. Two of the ten flags differ, and the pair is the worst possible
 * arrangement: Darwin's POLLWRBAND (0x0100) is bit-identical to glibc's
 * POLLWRNORM, so a forwarded events word does not fail and does not land on an
 * unused bit -- it asks for a real, different, adjacent condition. Darwin
 * spells POLLWRNORM as an alias for POLLOUT, which is why its two write flags
 * sit one position below glibc's. darwin/src/posix.c's mr_pollev_d2l/l2d
 * translate; this pins the glibc half so a change there fails the build rather
 * than quietly un-mapping the pair.
 *
 * nfds_t is the other half of the same call and is not a flag problem at all:
 * 8 bytes here against Darwin's 4, in an argument slot whose upper word AAPCS
 * leaves unspecified. This PIN is what makes the cast in mr_poll_common()
 * necessary rather than merely defensive. */
_Static_assert(POLLIN     == 0x0001, "glibc POLLIN moved (Darwin's is 0x0001 too)");
_Static_assert(POLLPRI    == 0x0002, "glibc POLLPRI moved (Darwin's is 0x0002 too)");
_Static_assert(POLLOUT    == 0x0004, "glibc POLLOUT moved (Darwin's is 0x0004 too)");
_Static_assert(POLLERR    == 0x0008, "glibc POLLERR moved (Darwin's is 0x0008 too)");
_Static_assert(POLLHUP    == 0x0010, "glibc POLLHUP moved (Darwin's is 0x0010 too)");
_Static_assert(POLLNVAL   == 0x0020, "glibc POLLNVAL moved (Darwin's is 0x0020 too)");
_Static_assert(POLLRDNORM == 0x0040, "glibc POLLRDNORM moved (Darwin's is 0x0040 too)");
_Static_assert(POLLRDBAND == 0x0080, "glibc POLLRDBAND moved (Darwin's is 0x0080 too)");
_Static_assert(POLLWRNORM == 0x0100, "glibc POLLWRNORM moved (Darwin's is 0x0004, "
    "an alias for POLLOUT); darwin/src/posix.c maps Darwin's POLLOUT onto both");
_Static_assert(POLLWRBAND == 0x0200, "glibc POLLWRBAND moved (Darwin's is 0x0100, "
    "which is THIS header's POLLWRNORM -- see mr_pollev_d2l in darwin/src/posix.c)");
PIN(nfds_t, 8);
PIN(struct pollfd, 8);
_Static_assert(offsetof(struct pollfd, fd)      == 0, "glibc pollfd.fd moved");
_Static_assert(offsetof(struct pollfd, events)  == 4, "glibc pollfd.events moved");
_Static_assert(offsetof(struct pollfd, revents) == 6, "glibc pollfd.revents moved");

/* SIGACTION. The struct is the widest size mismatch in this file -- 152 bytes
 * against Darwin's 16 -- and `oact` is an OUT parameter, so a forward has
 * glibc write 152 bytes into 16. darwin/src/posix.c mirrors this layout BY
 * HAND, which is the linux_stat shape, so the mirror is pinned here against
 * the real header. A wrong offset does not fail: it writes the flags word into
 * the middle of a signal mask.
 *
 * NOT ONE sa_flags BIT AGREES, and the collisions are with live flags rather
 * than with unused bits. Darwin SA_RESTART (0x02) is THIS header's
 * SA_NOCLDWAIT; Darwin SA_ONSTACK (0x01) is its SA_NOCLDSTOP; Darwin
 * SA_RESETHAND (0x04) is its SA_SIGINFO, which changes the calling convention
 * the kernel uses to deliver. libdispatch's event_epoll.c installs its handler
 * with exactly SA_RESTART, so this is the live one rather than the theoretical
 * one. */
PIN(struct sigaction, 152);
_Static_assert(offsetof(struct sigaction, sa_mask)  == 8,
    "glibc sigaction.sa_mask moved; darwin/src/posix.c mirrors this layout");
_Static_assert(offsetof(struct sigaction, sa_flags) == 136,
    "glibc sigaction.sa_flags moved (Darwin's is at 12); "
    "darwin/src/posix.c mirrors this layout by hand");
_Static_assert(SA_NOCLDSTOP == 0x00000001, "glibc SA_NOCLDSTOP moved (Darwin's is 0x08)");
_Static_assert(SA_NOCLDWAIT == 0x00000002, "glibc SA_NOCLDWAIT moved (Darwin's is 0x20, "
    "and Darwin's SA_RESTART is THIS value -- see mr_sigflags_d2l)");
_Static_assert(SA_SIGINFO   == 0x00000004, "glibc SA_SIGINFO moved (Darwin's is 0x40, "
    "and Darwin's SA_RESETHAND is THIS value)");
_Static_assert(SA_ONSTACK   == 0x08000000, "glibc SA_ONSTACK moved (Darwin's is 0x01)");
_Static_assert(SA_RESTART   == 0x10000000, "glibc SA_RESTART moved (Darwin's is 0x02)");
_Static_assert(SA_NODEFER   == 0x40000000, "glibc SA_NODEFER moved (Darwin's is 0x10)");
_Static_assert(SA_RESETHAND == (int)0x80000000, "glibc SA_RESETHAND moved (Darwin's is 0x04)");

/* The two handler sentinels are the only things in the whole signal surface
 * that agree, which is why they cross unchanged and a NULL table slot can mean
 * "not ours" rather than "unset". */
_Static_assert((long)(SIG_DFL) == 0, "glibc SIG_DFL is no longer 0");
_Static_assert((long)(SIG_IGN) == 1, "glibc SIG_IGN is no longer 1");

/* siginfo_t is why SA_SIGINFO is refused rather than mapped: honouring the
 * three-argument handler form means translating this too, and a ucontext_t we
 * have no mapping for at all. */
PIN(siginfo_t, 128);

/* FCNTL. The five commands a run loop uses agree; the other five are ROTATED
 * INTO EACH OTHER, which is the worst arrangement in this file. Darwin's
 * F_GETLK is 7, and 7 HERE is F_SETLKW -- so a forwarded "is this lock held?"
 * becomes "take this lock and block until you can", and a query turns into an
 * indefinite hang. Darwin's F_SETLK (8) is this header's F_SETOWN, so a
 * struct flock * is read as a pid; Darwin's F_GETOWN (5) is this header's
 * F_GETLK, and F_GETOWN takes no third argument, so glibc writes 32 bytes
 * through whatever register was there.
 *
 * fcntl is NOT forwarded and NOT implemented -- see
 * docs/UNIMPLEMENTED.md#not-a-plain-forward. These pins exist so that if
 * anyone adds a forward later, the numbers they would have relied on are
 * already written down and checked. */
_Static_assert(F_DUPFD  == 0, "glibc F_DUPFD moved (Darwin's is 0 too)");
_Static_assert(F_GETFD  == 1, "glibc F_GETFD moved (Darwin's is 1 too)");
_Static_assert(F_SETFD  == 2, "glibc F_SETFD moved (Darwin's is 2 too)");
_Static_assert(F_GETFL  == 3, "glibc F_GETFL moved (Darwin's is 3 too)");
_Static_assert(F_SETFL  == 4, "glibc F_SETFL moved (Darwin's is 4 too)");
_Static_assert(F_GETLK  == 5, "glibc F_GETLK moved (Darwin's is 7; Darwin's F_GETOWN is THIS value)");
_Static_assert(F_SETLK  == 6, "glibc F_SETLK moved (Darwin's is 8; Darwin's F_SETOWN is THIS value)");
_Static_assert(F_SETLKW == 7, "glibc F_SETLKW moved (Darwin's is 9; Darwin's F_GETLK is THIS value -- "
    "a forwarded query would BLOCK acquiring the lock)");
_Static_assert(F_GETOWN == 9, "glibc F_GETOWN moved (Darwin's is 5)");
_Static_assert(F_SETOWN == 8, "glibc F_SETOWN moved (Darwin's is 6; Darwin's F_SETLK is THIS value)");
PIN(struct flock, 32);

/* SCHEDULING. SCHED_RR is the only one of the three that agrees, and the
 * disagreement is the dangerous direction: Darwin's SCHED_OTHER is 1, and 1
 * HERE is SCHED_FIFO -- so a guest asking for the ordinary scheduler would be
 * made real-time, run-until-you-yield. Not forwarded, same reference. */
_Static_assert(SCHED_OTHER == 0, "glibc SCHED_OTHER moved (Darwin's is 1, "
    "which is THIS header's SCHED_FIFO)");
_Static_assert(SCHED_FIFO  == 1, "glibc SCHED_FIFO moved (Darwin's is 4)");
_Static_assert(SCHED_RR    == 2, "glibc SCHED_RR moved (Darwin's is 2 too -- the only one)");
PIN(struct sched_param, 4);
/* This one DOES agree, which is why pthread_attr_init/destroy are among the
 * four symbols in that census that really were plain forwards. */
PIN(pthread_attr_t, 64);

/* SCHEDULING AND DETACH STATE, both revealed ten symbols late because
 * ld64.lld caps its diagnostics at 20 and every "20 undefined" measurement was
 * the CEILING rather than the count.
 *
 * SCHED_RR is the only one of the three policies that agrees, and Darwin's
 * SCHED_OTHER (1) is THIS header's SCHED_FIFO -- so a forwarded request for
 * the ordinary scheduler makes the thread real-time, which on a machine
 * running a test suite is a hang rather than a slowdown.
 *
 * The detach state is worse because it is off by ONE: Darwin's
 * PTHREAD_CREATE_JOINABLE is 1 and 1 HERE is DETACHED, so the SAFE-LOOKING
 * direction is the broken one -- the guest asks for a joinable thread, gets a
 * detached one, and the pthread_join that follows has nothing to join. Darwin
 * DETACHED (2) is out of range here and merely fails. Same shape as
 * SIG_BLOCK/SIG_UNBLOCK. */
_Static_assert(SCHED_OTHER == 0, "glibc SCHED_OTHER moved (Darwin's is 1, "
    "which is THIS header's SCHED_FIFO -- see mr_sched_policy_d2l)");
_Static_assert(SCHED_FIFO  == 1, "glibc SCHED_FIFO moved (Darwin's is 4)");
_Static_assert(SCHED_RR    == 2, "glibc SCHED_RR moved (Darwin's is 2 too -- the only one)");
_Static_assert(PTHREAD_CREATE_JOINABLE == 0, "glibc PTHREAD_CREATE_JOINABLE moved "
    "(Darwin's is 1, which is THIS header's DETACHED)");
_Static_assert(PTHREAD_CREATE_DETACHED == 1, "glibc PTHREAD_CREATE_DETACHED moved (Darwin's is 2)");

/* Compile-only. There is deliberately no main(): nothing here should run, and
 * nothing here should link. */
