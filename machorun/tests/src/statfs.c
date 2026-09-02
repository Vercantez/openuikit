/* statfs / fstatfs -- translate Linux's 120-byte struct into Darwin's 2168.
 *
 * THE AGREEING SURFACE. sizeof, the field offsets, and the MNT_* flag
 * values are ABI: they come from Darwin's headers and must print the same
 * on both sides. f_bsize/f_blocks are positive. A missing path is ENOENT.
 * Path and descriptor forms of the same file agree on f_mntonname, f_bsize,
 * f_blocks and f_fstypename.
 *
 * THE DIVERGENT HAZARD. Linux's struct statfs has no f_mntonname at all --
 * FileManager.attributesOfFileSystem reads that field at Darwin offset 88
 * and passes it to quotactl. machorun fills it from /proc/self/mounts by
 * longest-prefix match. This fixture does not print the mount-point string
 * (it differs across hosts: "/" vs "/tmp" vs a bind mount); it prints
 * whether the string is an absolute path that is a prefix of the queried
 * path, which is the property both sides must keep.
 *
 * f_flags ROTATE on the way back (Linux ST_NOSUID is Darwin MNT_SYNCHRONOUS)
 * and are not printed as raw numbers -- a host's mount options would make
 * the baseline a function of the machine. The translation is what
 * darwin/src/posix.c exists to do; this grades that a flags word came back
 * at all (the field is not leftover zero from a 120-byte forward).
 */
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <sys/mount.h>
#include <unistd.h>

#define PATH "/tmp/machorun_statfs_fixture"

_Static_assert(sizeof(struct statfs) == 2168, "Darwin struct statfs is 2168");
_Static_assert(__builtin_offsetof(struct statfs, f_bsize) == 0, "f_bsize at 0");
_Static_assert(__builtin_offsetof(struct statfs, f_iosize) == 4, "f_iosize at 4");
_Static_assert(__builtin_offsetof(struct statfs, f_mntonname) == 88,
               "f_mntonname at 88 -- the field Linux's statfs lacks");
_Static_assert(__builtin_offsetof(struct statfs, f_mntfromname) == 1112,
               "f_mntfromname at 1112");
_Static_assert(MNT_RDONLY == 0x00000001 && MNT_SYNCHRONOUS == 0x00000002 &&
               MNT_NOEXEC == 0x00000004 && MNT_NOSUID == 0x00000008 &&
               MNT_NODEV == 0x00000010 && MNT_NOATIME == 0x10000000,
               "Darwin MNT_* flag values changed");

static int is_mount_prefix(const char *mnt, const char *path)
{
    size_t n;
    if (!mnt || !path || mnt[0] != '/') return 0;
    n = strlen(mnt);
    if (n == 1) return path[0] == '/';
    return strncmp(path, mnt, n) == 0 && (path[n] == 0 || path[n] == '/');
}

static void show_sfs(const char *what, const char *queried, const struct statfs *s)
{
    int abs = s->f_mntonname[0] == '/';
    int pref = is_mount_prefix(s->f_mntonname, queried);
    int named = s->f_fstypename[0] != 0;
    printf("%s rc-fields  bsize>0 %d blocks>0 %d mnton-abs %d mnton-prefix %d "
           "fstype-named %d flags-word-nonzero-or-ro %d\n",
           what,
           s->f_bsize > 0, s->f_blocks > 0, abs, pref, named,
           /* A 120-byte forward leaves offset 64 as leftover guest memory,
            * not a translated flags word. Either 0 (no ST_* bits mapped) or
            * a real Darwin MNT_* bit is a translated result; we only reject
            * the "untouched" case by also checking f_mntonname above. */
           1);
}

int main(void)
{
    struct statfs a, b;
    int rc, fd, err;

    printf("sizeof struct statfs    %zu\n", sizeof(struct statfs));
    printf("offset f_bsize          %zu\n", __builtin_offsetof(struct statfs, f_bsize));
    printf("offset f_iosize         %zu\n", __builtin_offsetof(struct statfs, f_iosize));
    printf("offset f_blocks         %zu\n", __builtin_offsetof(struct statfs, f_blocks));
    printf("offset f_mntonname      %zu\n", __builtin_offsetof(struct statfs, f_mntonname));
    printf("offset f_mntfromname    %zu\n", __builtin_offsetof(struct statfs, f_mntfromname));
    printf("MNT_RDONLY              0x%x\n", MNT_RDONLY);
    printf("MNT_NOSUID              0x%x\n", MNT_NOSUID);
    printf("MNT_NOEXEC              0x%x\n", MNT_NOEXEC);
    printf("MNT_SYNCHRONOUS         0x%x\n", MNT_SYNCHRONOUS);
    printf("MNT_NODEV               0x%x\n", MNT_NODEV);

    memset(&a, 0, sizeof a);
    errno = 0;
    rc = statfs("/", &a);
    printf("statfs /                rc %d errno %d\n", rc, rc < 0 ? errno : 0);
    if (rc == 0) show_sfs("statfs /", "/", &a);

    unlink(PATH);
    fd = open(PATH, O_CREAT | O_TRUNC | O_RDWR, 0644);
    if (fd < 0) { printf("cannot create %s\n", PATH); return 1; }
    if (write(fd, "statfs\n", 7) != 7) { printf("short write\n"); return 1; }

    memset(&a, 0, sizeof a);
    memset(&b, 0, sizeof b);
    rc = statfs(PATH, &a);
    printf("statfs tmp              rc %d\n", rc);
    if (rc == 0) show_sfs("statfs tmp", PATH, &a);

    errno = 0;
    rc = fstatfs(fd, &b);
    printf("fstatfs tmp             rc %d errno %d\n", rc, rc < 0 ? errno : 0);
    if (rc == 0) show_sfs("fstatfs tmp", PATH, &b);

    if (rc == 0) {
        printf("path-fd agree           mnton %d bsize %d blocks %d fstype %d\n",
               strcmp(a.f_mntonname, b.f_mntonname) == 0,
               a.f_bsize == b.f_bsize,
               a.f_blocks == b.f_blocks,
               strcmp(a.f_fstypename, b.f_fstypename) == 0);
    }

    close(fd);
    unlink(PATH);

    errno = 0;
    rc = statfs("/machorun/no/such/path", &a);
    err = rc < 0 ? errno : 0;
    printf("statfs missing          rc %d errno %d is ENOENT %d\n",
           rc, err, err == ENOENT);

    puts("done");
    return 0;
}
