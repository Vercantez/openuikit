/* file_attrs.c -- the `file_attrs` rung: fchown and strspn, two libSystem
 * names SQLite 3.51.0 links (its unix VFS calls fchown on every file it
 * creates as root; its URI parser uses strspn) that the guest libSystem did
 * not export (full/sqlite/build_sqlite_guest.sh).
 *
 * uid_t/gid_t agree on both systems and errno is checked by NAME, so this is
 * a plain forward -- the rung pins that it stays one. fchmod and utimes are
 * not here: see darwin/src/posix.c for why they are not exported yet.
 * Nothing host-specific is printed: no uids, no paths, no descriptors. */
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

static const char *errname(int e)
{
    switch (e) {
    case 0:      return "0";
    case EBADF:  return "EBADF";
    case EPERM:  return "EPERM";
    default:     return "OTHER";
    }
}

int main(void)
{
    const char *tmp = getenv("TMPDIR");
    char path[1024];
    snprintf(path, sizeof path, "%s/file_attrs.%d", (tmp && *tmp) ? tmp : "/tmp", (int)getpid());
    unlink(path);
    int fd = open(path, O_RDWR | O_CREAT | O_EXCL, 0600);
    if (fd < 0) { printf("open failed\n"); return 1; }

    struct stat st;
    errno = 0;
    int rc = fchown(fd, getuid(), getgid());
    fstat(fd, &st);
    printf("fchown self rc=%d errno=%s owner-kept=%d\n", rc, errname(errno),
           st.st_uid == getuid() && st.st_gid == getgid());
    errno = 0;
    rc = fchown(fd, (uid_t)-1, (gid_t)-1);
    printf("fchown unchanged rc=%d errno=%s\n", rc, errname(errno));
    errno = 0;
    rc = fchown(-1, getuid(), getgid());
    printf("fchown bad fd rc=%d errno=%s\n", rc, errname(errno));

    printf("strspn %zu %zu %zu %zu\n", strspn("abcabcxyz", "abc"), strspn("xyz", "abc"),
           strspn("", "abc"), strspn("0123456789-+", "0123456789"));

    close(fd);
    unlink(path);
    return 0;
}
