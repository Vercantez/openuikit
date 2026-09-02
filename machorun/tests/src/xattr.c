/* Extended attributes -- four hazards in one family, and only one of them is
 * a struct.
 *
 *   FLAGS ROTATE.   Darwin XATTR_CREATE is 0x02 and Linux XATTR_REPLACE is
 *                   0x02, so a forwarded "create only if absent" performs
 *                   "replace only if present" -- the exact inverse, failing
 *                   and succeeding backwards. Darwin's XATTR_REPLACE (0x04)
 *                   is not a valid Linux flag at all.
 *   NOFOLLOW IS A   Linux spells it lgetxattr/lsetxattr/lremovexattr/
 *   FUNCTION.       llistxattr. A flag word cannot express it.
 *   DIFFERENT       Darwin's get/set carry a `position` argument Linux's do
 *   ARITY.          not -- a shape none of the catalogued hazard families
 *                   covers. A forward hands Linux the POSITION where it
 *                   expects the flags.
 *   THE NAME SPACE. Linux refuses any name outside user./security./system./
 *                   trusted.; Darwin accepts anything, and a real Darwin file
 *                   is full of com.apple.*. machorun prefixes `user.` on the
 *                   way in and strips it on the way out.
 *
 * And one more that the generic errno table gets right and uselessly: "no such
 * attribute" is ENOATTR (93) on Darwin and ENODATA (61) on Linux, and Darwin
 * ALSO has an ENODATA at 96 -- so the table's correct name translation lands
 * on a value no xattr caller tests for.
 *
 * THE FILE LIVES IN /tmp, WHICH IS NOT A DETAIL. machorun's test-bed container
 * mounts the repository from macOS, and that mount does not support extended
 * attributes at all: measured, setxattr on a file under the mount returns
 * EOPNOTSUPP (95) while the same call on /tmp succeeds. A fixture written in
 * the fixture directory would fail for a reason that has nothing to do with
 * the code under test.
 */
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/xattr.h>
#include <unistd.h>

#define A_NAME "machorun.alpha"
#define B_NAME "machorun.beta"
#define PATH   "/tmp/machorun_xattr_fixture"

static int cmp(const void *a, const void *b)
{
    return strcmp(*(const char *const *)a, *(const char *const *)b);
}

/* Only the names this fixture set. A file can carry attributes nobody here
 * asked for -- macOS adds com.apple.provenance to some files -- and grading
 * the whole list would make the verdict depend on that. Sorted, because the
 * order a filesystem returns names in is not part of any contract. */
static void show_list(const char *what, const char *buf, long n)
{
    const char *ours[16];
    int k = 0;
    for (long i = 0; i < n && k < 16; ) {
        const char *nm = buf + i;
        if (strncmp(nm, "machorun.", 9) == 0) ours[k++] = nm;
        i += (long)strlen(nm) + 1;
    }
    qsort((void *)ours, (size_t)k, sizeof ours[0], cmp);
    printf("  %s ours=%d", what, k);
    for (int i = 0; i < k; i++) printf(" [%s]", ours[i]);
    printf("\n");
}

int main(void)
{
    char buf[4096];
    long n;
    int rc, fd;

    printf("XATTR_NOFOLLOW          0x%x\n", XATTR_NOFOLLOW);
    printf("XATTR_CREATE            0x%x\n", XATTR_CREATE);
    printf("XATTR_REPLACE           0x%x\n", XATTR_REPLACE);
    printf("XATTR_MAXNAMELEN        %d\n", XATTR_MAXNAMELEN);
    printf("ENOATTR                 %d\n", ENOATTR);

    unlink(PATH);
    fd = open(PATH, O_CREAT | O_TRUNC | O_RDWR, 0644);
    if (fd < 0) { printf("cannot create %s\n", PATH); return 1; }
    if (write(fd, "hello\n", 6) != 6) { printf("short write\n"); return 1; }

    /* --- set, then read back the VALUE. */
    errno = 0;
    rc = setxattr(PATH, A_NAME, "alpha-value", 11, 0, 0);
    printf("setxattr alpha rc       %d errno %d\n", rc, rc < 0 ? errno : 0);

    errno = 0;
    n = getxattr(PATH, A_NAME, NULL, 0, 0, 0);
    printf("getxattr size query     %ld\n", n);

    memset(buf, 0, sizeof buf);
    errno = 0;
    n = getxattr(PATH, A_NAME, buf, sizeof buf, 0, 0);
    printf("getxattr value          %ld [%.*s]\n", n, (int)(n > 0 ? n : 0), buf);

    /* --- the flag rotation, in both directions. XATTR_CREATE on a name that
     * exists must fail with EEXIST; forwarded raw it becomes Linux's
     * XATTR_REPLACE and SUCCEEDS. */
    errno = 0;
    rc = setxattr(PATH, A_NAME, "nope", 4, 0, XATTR_CREATE);
    printf("setxattr CREATE exists  rc %d errno %d EEXIST %d\n",
           rc, rc < 0 ? errno : 0, EEXIST);

    /* XATTR_REPLACE on a name that does not exist must fail with ENOATTR;
     * forwarded raw, 0x04 is not a Linux flag at all. */
    errno = 0;
    rc = setxattr(PATH, "machorun.absent", "nope", 4, 0, XATTR_REPLACE);
    printf("setxattr REPLACE absent rc %d errno %d is ENOATTR %d\n",
           rc, rc < 0 ? errno : 0, rc < 0 && errno == ENOATTR);

    /* --- the value survived both failures. */
    memset(buf, 0, sizeof buf);
    n = getxattr(PATH, A_NAME, buf, sizeof buf, 0, 0);
    printf("alpha still             %ld [%.*s]\n", n, (int)(n > 0 ? n : 0), buf);

    /* --- a name that is not there. */
    errno = 0;
    n = getxattr(PATH, "machorun.missing", buf, sizeof buf, 0, 0);
    printf("getxattr missing        %ld errno %d is ENOATTR %d\n",
           n, n < 0 ? errno : 0, n < 0 && errno == ENOATTR);

    /* --- a buffer too small. */
    errno = 0;
    n = getxattr(PATH, A_NAME, buf, 1, 0, 0);
    printf("getxattr short buffer   %ld errno %d ERANGE %d\n",
           n, n < 0 ? errno : 0, ERANGE);

    /* --- the Darwin-only `position` argument. There are no resource forks
     * here, and Darwin itself answers EINVAL for a non-zero position on an
     * ordinary attribute. */
    errno = 0;
    n = getxattr(PATH, A_NAME, buf, sizeof buf, 1, 0);
    printf("getxattr position 1     %ld errno %d EINVAL %d\n",
           n, n < 0 ? errno : 0, EINVAL);

    /* --- the descriptor forms. */
    errno = 0;
    rc = fsetxattr(fd, B_NAME, "beta", 4, 0, 0);
    printf("fsetxattr beta rc       %d errno %d\n", rc, rc < 0 ? errno : 0);
    memset(buf, 0, sizeof buf);
    n = fgetxattr(fd, B_NAME, buf, sizeof buf, 0, 0);
    printf("fgetxattr beta          %ld [%.*s]\n", n, (int)(n > 0 ? n : 0), buf);

    /* --- listing, by path and by descriptor. The names must come back the
     * way the guest wrote them, with no `user.` in sight. */
    errno = 0;
    n = listxattr(PATH, NULL, 0, 0);
    printf("listxattr size query    %s\n", n > 0 ? "positive" : "NOT POSITIVE");
    memset(buf, 0, sizeof buf);
    n = listxattr(PATH, buf, sizeof buf, 0);
    printf("listxattr rc            %s\n", n > 0 ? "positive" : "NOT POSITIVE");
    show_list("listxattr", buf, n);

    memset(buf, 0, sizeof buf);
    n = flistxattr(fd, buf, sizeof buf, 0);
    printf("flistxattr rc           %s\n", n > 0 ? "positive" : "NOT POSITIVE");
    show_list("flistxattr", buf, n);

    /* --- XATTR_NOFOLLOW on a REGULAR file: the flag has to reach the l*
     * entry points and must answer identically there. (A symlink is not used:
     * Linux forbids user.* attributes on symlinks outright, so that case
     * could never agree with Darwin and would be testing the kernel's policy
     * rather than this translation.) */
    memset(buf, 0, sizeof buf);
    n = getxattr(PATH, A_NAME, buf, sizeof buf, 0, XATTR_NOFOLLOW);
    printf("getxattr NOFOLLOW       %ld [%.*s]\n", n, (int)(n > 0 ? n : 0), buf);

    /* --- removal, and removing it twice. */
    errno = 0;
    rc = removexattr(PATH, A_NAME, 0);
    printf("removexattr rc          %d errno %d\n", rc, rc < 0 ? errno : 0);
    errno = 0;
    rc = removexattr(PATH, A_NAME, 0);
    printf("removexattr again rc    %d errno %d is ENOATTR %d\n",
           rc, rc < 0 ? errno : 0, rc < 0 && errno == ENOATTR);
    errno = 0;
    rc = fremovexattr(fd, B_NAME, 0);
    printf("fremovexattr rc         %d errno %d\n", rc, rc < 0 ? errno : 0);

    memset(buf, 0, sizeof buf);
    n = listxattr(PATH, buf, sizeof buf, 0);
    show_list("after removal", buf, n < 0 ? 0 : n);

    close(fd);
    unlink(PATH);
    puts("done");
    return 0;
}
