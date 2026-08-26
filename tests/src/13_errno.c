/* 13_errno -- the numbers that are NOT the same on the two systems.
 *
 * Measured 2026-08-25 (docs/ABI.md): of 44 errno constants probed, 18 have
 * different values on Darwin and Linux -- EAGAIN is 35 on Darwin and 11 on
 * Linux, EDEADLK is exactly the other way round, ENOTEMPTY is 66 against 39.
 * Ten of thirteen O_* flags differ too: O_CREAT is 0x0200 on Darwin and 0x0040
 * on Linux, and Darwin's O_CREAT bit IS Linux's O_TRUNC bit.
 *
 * Those constants are compiled INTO the guest. A libSystem that forwards
 * open() and errno straight through therefore does not merely report a
 * different number -- it opens a different file. This fixture pins the
 * translation in both directions:
 *
 *   flags   guest's Darwin O_* -> Linux O_*, on the way in
 *   errno   glibc's Linux value -> Darwin value, on the way out
 *   stat    glibc's 128-byte struct stat -> Darwin's 144-byte layout
 *
 * The temp directory is fixed, and removed on the way in and out, so nothing
 * printed depends on the environment.
 */
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

#define DIR "/tmp/machorun-13-errno"

static void cleanup(void)
{
    unlink(DIR "/file");
    unlink(DIR "/other");
    rmdir(DIR);
}

int main(void)
{
    int fd, rc;
    char buf[64];
    struct stat st;

    cleanup();

    /* ---- errno values the guest will compare against its own constants ---- */
    errno = 0;
    fd = open("/machorun/definitely/not/here", O_RDONLY);
    printf("open missing rc=%d errno=%d ENOENT=%d match=%s\n",
           fd, errno, ENOENT, errno == ENOENT ? "yes" : "no");

    /* ENOTEMPTY: 66 on Darwin, 39 on Linux. The headline case. */
    if (mkdir(DIR, 0755) != 0) { perror("mkdir"); return 1; }
    fd = open(DIR "/file", O_WRONLY | O_CREAT | O_TRUNC, 0644);
    printf("open O_CREAT rc=%s\n", fd >= 0 ? "ok" : "failed");
    if (fd < 0) { perror("open"); return 1; }
    if (write(fd, "hello\n", 6) != 6) { perror("write"); return 1; }
    close(fd);

    errno = 0;
    rc = rmdir(DIR);
    printf("rmdir nonempty rc=%d errno=%d ENOTEMPTY=%d match=%s\n",
           rc, errno, ENOTEMPTY, errno == ENOTEMPTY ? "yes" : "no");

    /* O_EXCL must actually mean O_EXCL, not whatever bit Linux calls 0x0800. */
    errno = 0;
    rc = open(DIR "/file", O_WRONLY | O_CREAT | O_EXCL, 0644);
    printf("O_EXCL on existing rc=%d errno=%d EEXIST=%d match=%s\n",
           rc, errno, EEXIST, errno == EEXIST ? "yes" : "no");

    errno = 0;
    rc = open(DIR, O_WRONLY);
    printf("open dir for write rc=%d errno=%d EISDIR=%d match=%s\n",
           rc, errno, EISDIR, errno == EISDIR ? "yes" : "no");

    errno = 0;
    rc = close(4242);
    printf("close bogus rc=%d errno=%d EBADF=%d match=%s\n",
           rc, errno, EBADF, errno == EBADF ? "yes" : "no");

    /* ---- errno must survive a SUCCESSFUL call untouched ----
     * The strtol idiom: clear errno, call, and believe what you read. A
     * libSystem that resynchronises errno from glibc's after every call would
     * resurrect a stale value here. */
    errno = 0;
    (void)strtol("42", NULL, 10);
    printf("errno after success=%d\n", errno);

    errno = 0;
    (void)strtol("999999999999999999999999", NULL, 10);
    printf("strtol overflow errno=%d ERANGE=%d match=%s\n",
           errno, ERANGE, errno == ERANGE ? "yes" : "no");

    /* And a guest-written errno must not be clobbered by our bookkeeping. */
    errno = ENOTEMPTY;
    printf("guest-set errno persists=%s\n", errno == ENOTEMPTY ? "yes" : "no");

    /* ---- O_APPEND: Darwin 0x0008, Linux 0x0400 ----
     * If the flag is passed through raw, Linux sees O_NONBLOCK|... and the
     * second write lands at offset 0, truncating the story. */
    fd = open(DIR "/file", O_WRONLY | O_APPEND);
    if (fd < 0) { perror("open append"); return 1; }
    if (write(fd, "world\n", 6) != 6) { perror("write append"); return 1; }
    close(fd);

    fd = open(DIR "/file", O_RDONLY);
    memset(buf, 0, sizeof buf);
    rc = (int)read(fd, buf, sizeof buf - 1);
    close(fd);
    printf("append read %d bytes=[%s]", rc, buf);
    printf("\n");

    /* ---- struct stat: a different size and different offsets ---- */
    memset(&st, 0, sizeof st);
    rc = stat(DIR "/file", &st);
    printf("stat rc=%d size=%lld isreg=%s isdir=%s perm=%03o nlink=%d\n",
           rc, (long long)st.st_size,
           S_ISREG(st.st_mode) ? "yes" : "no",
           S_ISDIR(st.st_mode) ? "yes" : "no",
           (unsigned)(st.st_mode & 0777), (int)st.st_nlink);

    memset(&st, 0, sizeof st);
    rc = stat(DIR, &st);
    printf("stat dir rc=%d isdir=%s isreg=%s\n", rc,
           S_ISDIR(st.st_mode) ? "yes" : "no", S_ISREG(st.st_mode) ? "yes" : "no");

    fd = open(DIR "/file", O_RDONLY);
    memset(&st, 0, sizeof st);
    rc = fstat(fd, &st);
    printf("fstat rc=%d size=%lld isreg=%s\n", rc, (long long)st.st_size,
           S_ISREG(st.st_mode) ? "yes" : "no");
    close(fd);

    errno = 0;
    rc = stat(DIR "/nope", &st);
    printf("stat missing rc=%d errno=%d match=%s\n", rc, errno,
           errno == ENOENT ? "yes" : "no");

    /* ---- strerror: the text a program prints for a translated number ---- */
    printf("strerror ENOENT=[%s]\n", strerror(ENOENT));
    printf("strerror ENOTEMPTY=[%s]\n", strerror(ENOTEMPTY));
    printf("strerror EAGAIN=[%s]\n", strerror(EAGAIN));
    printf("strerror EDEADLK=[%s]\n", strerror(EDEADLK));

    errno = ENOENT;
    fflush(stdout);
    perror("perror says");

    /* ---- lseek, since offsets are the other thing programs get wrong ---- */
    fd = open(DIR "/file", O_RDONLY);
    printf("lseek end=%lld cur=%lld set3=%lld\n",
           (long long)lseek(fd, 0, SEEK_END),
           (long long)lseek(fd, 0, SEEK_CUR),
           (long long)lseek(fd, 3, SEEK_SET));
    memset(buf, 0, sizeof buf);
    rc = (int)read(fd, buf, 4);
    printf("read after seek %d=[%s]\n", rc, buf);
    close(fd);

    cleanup();
    errno = 0;
    rc = stat(DIR, &st);
    printf("after cleanup stat rc=%d errno=%d match=%s\n", rc, errno,
           errno == ENOENT ? "yes" : "no");

    fflush(stdout);
    return 0;
}
