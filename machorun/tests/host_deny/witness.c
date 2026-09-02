/* witness.c -- what the deny-list is preventing, measured on the host.
 *
 * An ordinary Linux/aarch64 ELF, compiled by gcc against real glibc, calling
 * glibc's openat with DARWIN'S CONSTANTS -- which is exactly what a Mach-O
 * caller reaching glibc through machorun's host fallback would do. It prints
 * the RETURN of each call and the state of the file afterwards.
 *
 * This exists because "the constants differ" is an assertion and a reader is
 * entitled to the consequence. The consequence is worse than a failure: the
 * flags ROTATE, so O_CREAT arrives as O_TRUNC and the call SUCCEEDS at doing
 * something else. A guest creating a file destroys one instead.
 *
 * It also re-derives the two constant columns rather than quoting them, so the
 * numbers in src/host_deny.c's message cannot drift away from the machine.
 */
#define _GNU_SOURCE
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

/* Darwin's values. Measured on macOS/arm64 against Apple's SDK, and identical
 * to machorun's own sdk/usr/include/sys/fcntl.h, which is what a guest was
 * compiled against. */
#define DARWIN_AT_FDCWD (-2)
#define DARWIN_O_RDONLY 0x0
#define DARWIN_O_WRONLY 0x1
#define DARWIN_O_CREAT  0x200
#define DARWIN_O_EXCL   0x800
#define DARWIN_O_TRUNC  0x400

static void writefile(const char *p, const char *s)
{
    int fd = open(p, O_WRONLY | O_CREAT | O_TRUNC, 0644);
    if (fd >= 0) { ssize_t n = write(fd, s, strlen(s)); (void)n; close(fd); }
}

static long filesize(const char *p)
{
    FILE *f = fopen(p, "rb");
    long n;
    if (!f) return -1;
    fseek(f, 0, SEEK_END); n = ftell(f); fclose(f);
    return n;
}

int main(void)
{
    int fd;

    printf("  constant      Darwin   Linux\n");
    printf("  AT_FDCWD      %6d  %6d\n", DARWIN_AT_FDCWD, AT_FDCWD);
    printf("  O_CREAT       0x%04x  0x%04x   (Darwin's O_CREAT is Linux's %s)\n",
           DARWIN_O_CREAT, O_CREAT, DARWIN_O_CREAT == O_TRUNC ? "O_TRUNC" : "?");
    printf("  O_TRUNC       0x%04x  0x%04x   (Darwin's O_TRUNC is Linux's %s)\n",
           DARWIN_O_TRUNC, O_TRUNC, DARWIN_O_TRUNC == O_APPEND ? "O_APPEND" : "?");
    printf("  O_EXCL        0x%04x  0x%04x   (Darwin's O_EXCL is Linux's %s)\n",
           DARWIN_O_EXCL, O_EXCL, DARWIN_O_EXCL == O_NONBLOCK ? "O_NONBLOCK" : "?");

    writefile("witness_data.txt", "twenty-four bytes here.\n");

    errno = 0;
    fd = openat(DARWIN_AT_FDCWD, "witness_data.txt", DARWIN_O_RDONLY);
    printf("  openat(Darwin AT_FDCWD=%d, \"witness_data.txt\", O_RDONLY)"
           " returned %d, errno %d (%s)\n",
           DARWIN_AT_FDCWD, fd, errno, fd < 0 ? strerror(errno) : "-");
    if (fd >= 0) close(fd);

    errno = 0;
    fd = openat(AT_FDCWD, "witness_data.txt", O_RDONLY);
    printf("  openat(Linux  AT_FDCWD=%d, \"witness_data.txt\", O_RDONLY)"
           " returned %d, errno %d\n", AT_FDCWD, fd, errno);
    if (fd >= 0) close(fd);

    /* The rotation, shown as damage rather than as a table. A guest asking to
     * CREATE a file it expects not to exist asks glibc to TRUNCATE one. */
    printf("  witness_data.txt is %ld bytes before\n", filesize("witness_data.txt"));
    errno = 0;
    fd = openat(AT_FDCWD, "witness_data.txt",
                DARWIN_O_WRONLY | DARWIN_O_CREAT);   /* guest means: create */
    printf("  openat(..., Darwin O_WRONLY|O_CREAT = 0x%x) returned %d, errno %d\n",
           DARWIN_O_WRONLY | DARWIN_O_CREAT, fd, errno);
    if (fd >= 0) close(fd);
    printf("  witness_data.txt is %ld bytes after\n", filesize("witness_data.txt"));

    unlink("witness_data.txt");
    return 0;
}
