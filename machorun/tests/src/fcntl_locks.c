/* fcntl_locks.c -- the `fcntl_locks` rung: POSIX record locks and
 * F_FULLFSYNC, what SQLite's unix VFS does to every database file.
 *
 * WHAT IS TRANSLATED (docs/UNIMPLEMENTED.md, fcntl):
 *     F_GETLK/F_SETLK/F_SETLKW   Darwin 7/8/9, Linux 5/6/7 -- forwarded, a
 *                                lock QUERY would acquire and block
 *     l_type                     Darwin RD 1 / UN 2 / WR 3, Linux 0 / 2 / 1
 *     struct flock               Darwin {start; len; pid; type; whence} 24 B,
 *                                Linux {type; whence; start; len; pid} 32 B
 *     F_FULLFSYNC                Darwin 51, no Linux command: fsync(2)
 *
 * One process holds no conflicting lock against itself, so F_GETLK answers
 * F_UNLCK and must leave whence/start/len as given. Nothing host-specific is
 * printed. */
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static const char *errname(int e)
{
    switch (e) {
    case 0:      return "0";
    case EBADF:  return "EBADF";
    case EINVAL: return "EINVAL";
    default:     return "OTHER";
    }
}

static const char *typename(short t)
{
    return t == F_RDLCK ? "F_RDLCK" : t == F_WRLCK ? "F_WRLCK" : t == F_UNLCK ? "F_UNLCK" : "?";
}

static void lock(int fd, int cmd, const char *cmdname, short type, off_t start, off_t len)
{
    struct flock fl;
    memset(&fl, 0, sizeof fl);
    fl.l_type = type;
    fl.l_whence = SEEK_SET;
    fl.l_start = start;
    fl.l_len = len;
    errno = 0;
    int rc = fcntl(fd, cmd, &fl);
    printf("%s %s %lld+%lld rc=%d errno=%s", cmdname, typename(type), (long long)start,
           (long long)len, rc, errname(errno));
    if (cmd == F_GETLK)
        printf(" -> %s whence=%d %lld+%lld", typename(fl.l_type), fl.l_whence,
               (long long)fl.l_start, (long long)fl.l_len);
    printf("\n");
}

int main(void)
{
    const char *tmp = getenv("TMPDIR");
    char path[1024];
    snprintf(path, sizeof path, "%s/fcntl_locks.%d", (tmp && *tmp) ? tmp : "/tmp", (int)getpid());
    unlink(path);
    int fd = open(path, O_RDWR | O_CREAT | O_EXCL, 0600);
    if (fd < 0) { printf("open failed\n"); return 1; }
    write(fd, "0123456789", 10);

    /* SQLite's byte ranges: PENDING 0x40000000, RESERVED +1, SHARED +2.. */
    lock(fd, F_SETLK, "F_SETLK", F_RDLCK, 0x40000000, 1);
    lock(fd, F_SETLK, "F_SETLK", F_WRLCK, 0x40000001, 1);
    lock(fd, F_GETLK, "F_GETLK", F_WRLCK, 0x40000000, 510);
    lock(fd, F_SETLKW, "F_SETLKW", F_WRLCK, 0x40000002, 510);
    lock(fd, F_SETLK, "F_SETLK", F_UNLCK, 0, 0);
    lock(fd, F_GETLK, "F_GETLK", F_RDLCK, 3, 4);

    struct flock bad;
    memset(&bad, 0, sizeof bad);
    bad.l_type = 99;
    errno = 0;
    int rc = fcntl(fd, F_SETLK, &bad);
    printf("F_SETLK bad type rc=%d errno=%s\n", rc, errname(errno));
    errno = 0;
    rc = fcntl(-1, F_SETLK, &bad);
    printf("F_SETLK bad fd rc=%d errno=%s\n", rc, errname(errno));

    errno = 0;
    rc = fcntl(fd, F_FULLFSYNC);
    printf("F_FULLFSYNC rc=%d errno=%s\n", rc, errname(errno));
    errno = 0;
    rc = fcntl(-1, F_FULLFSYNC);
    printf("F_FULLFSYNC bad fd rc=%d errno=%s\n", rc, errname(errno));

    rc = fcntl(fd, F_SETFD, FD_CLOEXEC);
    printf("F_SETFD rc=%d F_GETFD=%d\n", rc, fcntl(fd, F_GETFD));
    int dup = fcntl(fd, F_DUPFD, 0);
    printf("F_DUPFD ok=%d cloexec=%d\n", dup > fd, dup >= 0 ? fcntl(dup, F_GETFD) : -1);
    close(dup);
    close(fd);
    unlink(path);
    return 0;
}
