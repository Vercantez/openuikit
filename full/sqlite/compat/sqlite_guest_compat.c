/* fchmod and utimes for the guest's libsqlite3, which sqlite3.c is compiled
 * to call under these names (-Dfchmod=... -Dutimes=..., build_sqlite_guest.sh).
 *
 * machorun's libSystem does not export either yet: FoundationEssentials'
 * fm_unimplemented.c defines private loud-abort copies of both, and a
 * libSystem.tbd that lists them reorders render_full's symbol table (measured;
 * machorun/darwin/src/posix.c). Until that changes they live here, private to
 * this dylib, built only from names machorun does export.
 *
 * fchmod: SQLite calls it once, in robust_open, to undo the umask on a file it
 * just created. The guest's files are Linux files, so /proc/self/fd/N names
 * the open file and chmod follows that link to it -- the same inode fchmod
 * would change. A bad descriptor answers EBADF first, as fchmod does.
 *
 * utimes: only the "unix-dotfile" VFS calls it (dotlockLock, refreshing a lock
 * file's time). It is not the default VFS and NetNewsWire/FMDB never select
 * it; this answers ENOSYS rather than pretending to succeed. */
#include <errno.h>
#include <stdio.h>
#include <sys/stat.h>
#include <sys/time.h>

__attribute__((visibility("hidden")))
int openuikit_sqlite_fchmod(int fd, mode_t mode)
{
    struct stat st;
    char path[64];
    if (fstat(fd, &st) != 0)
        return -1;
    snprintf(path, sizeof path, "/proc/self/fd/%d", fd);
    return chmod(path, mode);
}

__attribute__((visibility("hidden")))
int openuikit_sqlite_utimes(const char *path, const struct timeval times[2])
{
    (void)path;
    (void)times;
    errno = ENOSYS;
    return -1;
}
