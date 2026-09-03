/* copyfile / fcopyfile -- Darwin-only, no glibc counterpart.
 *
 * THE AGREEING SURFACE. The COPYFILE_* flag values are ABI, transcribed from
 * copyfile.h (copyfile-240, 143 lines). copyfile of a regular file with
 * COPYFILE_ALL copies bytes and (where the filesystem allows) extended
 * attributes. COPYFILE_EXCL fails with EEXIST when the destination exists.
 *
 * THE DIVERGENT HAZARD. xattr translation already exists (user. prefix,
 * flag rotation); this fixture copies a file that carries one so a
 * copyfile that only did read/write would pass the data check and fail
 * the xattr check. fcopyfile to an invalid fd is EINVAL; fcopyfile from a
 * pipe is ENOTSUP -- Darwin refuses any source that is not a regular
 * file, symlink or directory. The file lives in /tmp because the
 * repository bind-mount often has no xattrs (see tests/src/xattr.c).
 *
 * COPYFILE_CLONE is exercised as a success-or-fallback path: both Darwin
 * (clonefile, then copy) and machorun (FICLONE, then copy) return 0. The
 * fixture does not print whether a clone happened -- that is a filesystem
 * property, not an ABI one.
 */
#include <copyfile.h>
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/xattr.h>
#include <unistd.h>

#define SRC  "/tmp/machorun_copyfile_src"
#define DST  "/tmp/machorun_copyfile_dst"
#define DST2 "/tmp/machorun_copyfile_dst2"
#define A_NAME "machorun.copy"

_Static_assert(COPYFILE_ACL == (1 << 0) && COPYFILE_STAT == (1 << 1) &&
               COPYFILE_XATTR == (1 << 2) && COPYFILE_DATA == (1 << 3),
               "COPYFILE content flags changed");
_Static_assert(COPYFILE_METADATA == (COPYFILE_SECURITY | COPYFILE_XATTR) &&
               COPYFILE_ALL == (COPYFILE_METADATA | COPYFILE_DATA),
               "COPYFILE composite flags changed");
_Static_assert(COPYFILE_EXCL == (1 << 17) &&
               COPYFILE_NOFOLLOW == (COPYFILE_NOFOLLOW_SRC | COPYFILE_NOFOLLOW_DST) &&
               COPYFILE_CLONE == (1 << 24) && COPYFILE_RUN_IN_PLACE == (1 << 26),
               "COPYFILE behaviour flags changed");

static void cleanup(void)
{
    unlink(SRC);
    unlink(DST);
    unlink(DST2);
}

int main(void)
{
    char buf[256];
    long n;
    int rc, src_fd, dst_fd, pfd[2], err;
    struct stat st;

    printf("COPYFILE_DATA           0x%x\n", COPYFILE_DATA);
    printf("COPYFILE_METADATA       0x%x\n", COPYFILE_METADATA);
    printf("COPYFILE_ALL            0x%x\n", COPYFILE_ALL);
    printf("COPYFILE_EXCL           0x%x\n", COPYFILE_EXCL);
    printf("COPYFILE_NOFOLLOW       0x%x\n", COPYFILE_NOFOLLOW);
    printf("COPYFILE_CLONE          0x%x\n", COPYFILE_CLONE);
    printf("COPYFILE_RUN_IN_PLACE   0x%x\n", COPYFILE_RUN_IN_PLACE);

    cleanup();
    src_fd = open(SRC, O_CREAT | O_TRUNC | O_RDWR, 0644);
    if (src_fd < 0) { printf("cannot create %s\n", SRC); return 1; }
    if (write(src_fd, "copyfile-payload\n", 17) != 17) {
        printf("short write\n"); return 1;
    }

    errno = 0;
    rc = setxattr(SRC, A_NAME, "copied-xattr", 12, 0, 0);
    printf("setxattr src            rc %d errno %d\n", rc, rc < 0 ? errno : 0);

    errno = 0;
    rc = copyfile(SRC, DST, NULL, COPYFILE_ALL);
    printf("copyfile ALL            rc %d errno %d\n", rc, rc < 0 ? errno : 0);

    dst_fd = open(DST, O_RDONLY);
    memset(buf, 0, sizeof buf);
    n = dst_fd >= 0 ? read(dst_fd, buf, sizeof buf) : -1;
    printf("dest bytes              %ld [%.*s]\n",
           n, (int)(n > 0 ? n : 0), buf);
    if (dst_fd >= 0) close(dst_fd);

    memset(buf, 0, sizeof buf);
    errno = 0;
    n = getxattr(DST, A_NAME, buf, sizeof buf, 0, 0);
    printf("dest xattr              %ld [%.*s] is match %d\n",
           n, (int)(n > 0 ? n : 0), buf,
           n == 12 && memcmp(buf, "copied-xattr", 12) == 0);

    if (stat(DST, &st) == 0)
        printf("dest mode               0%o\n", (unsigned)(st.st_mode & 07777));

    errno = 0;
    rc = copyfile(SRC, DST, NULL, COPYFILE_ALL | COPYFILE_EXCL);
    err = rc < 0 ? errno : 0;
    printf("copyfile EXCL exists    rc %d errno %d is EEXIST %d\n",
           rc, err, err == EEXIST);

    errno = 0;
    rc = copyfile(SRC, DST2, NULL, COPYFILE_CLONE | COPYFILE_RUN_IN_PLACE);
    printf("copyfile CLONE          rc %d errno %d\n", rc, rc < 0 ? errno : 0);
    dst_fd = open(DST2, O_RDONLY);
    memset(buf, 0, sizeof buf);
    n = dst_fd >= 0 ? read(dst_fd, buf, sizeof buf) : -1;
    printf("clone dest bytes        %ld match %d\n",
           n, n == 17 && memcmp(buf, "copyfile-payload\n", 17) == 0);
    if (dst_fd >= 0) close(dst_fd);

    errno = 0;
    rc = fcopyfile(-1, -1, NULL, COPYFILE_DATA);
    err = rc < 0 ? errno : 0;
    printf("fcopyfile bad fd        rc %d errno %d is EINVAL %d\n",
           rc, err, err == EINVAL);

    if (pipe(pfd) != 0) { printf("pipe failed\n"); return 1; }
    errno = 0;
    rc = fcopyfile(pfd[0], src_fd, NULL, COPYFILE_DATA);
    err = rc < 0 ? errno : 0;
    printf("fcopyfile from pipe     rc %d errno %d is ENOTSUP %d\n",
           rc, err, err == ENOTSUP);
    close(pfd[0]);
    close(pfd[1]);

    lseek(src_fd, 0, SEEK_SET);
    dst_fd = open(DST, O_WRONLY | O_TRUNC);
    if (dst_fd >= 0) {
        errno = 0;
        rc = fcopyfile(src_fd, dst_fd, NULL, COPYFILE_DATA);
        printf("fcopyfile DATA          rc %d errno %d\n", rc, rc < 0 ? errno : 0);
        close(dst_fd);
    }
    close(src_fd);

    cleanup();
    puts("done");
    return 0;
}
