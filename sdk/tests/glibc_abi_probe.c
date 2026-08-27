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
#include <glob.h>
#include <pthread.h>
#include <regex.h>
#include <semaphore.h>
#include <setjmp.h>
#include <signal.h>
#include <spawn.h>
#include <stddef.h>
#include <errno.h>
#include <sys/stat.h>
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

/* Not a struct-shape problem but the same family: a width mismatch inside a
 * translated struct. Darwin's dev_t is 4 bytes and mode_t/nlink_t are 2. */
PIN(dev_t,   8);
PIN(mode_t,  4);
PIN(nlink_t, 4);

/* Compile-only. There is deliberately no main(): nothing here should run, and
 * nothing here should link. */
