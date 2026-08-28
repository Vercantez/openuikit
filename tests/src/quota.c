/* quotactl -- and the finding is that Darwin does not support quotas either.
 *
 * The obvious plan was a translating wrapper, and the obstacles are real:
 * the ARGUMENT ORDER is swapped (Darwin `quotactl(path, cmd, id, addr)`
 * against Linux `quotactl(cmd, special, id, addr)`, so a forward hands Linux a
 * `const char *` as its integer command); the first argument is a different
 * OBJECT (Darwin's mount point against Linux's block device); Darwin's
 * Q_QUOTASTAT has no Linux equivalent; and `struct dqblk` differs in layout
 * and in UNITS.
 *
 * The measurement made the wrapper unnecessary. On macOS 26.5.2 with APFS,
 * every quotactl command on every path returns ENOTSUP -- APFS implements no
 * quotas at all -- and FileManager.attributesOfFileSystem, the only consumer,
 * treats a non-zero return as "no quota" and reports the plain statfs totals.
 * That is the ORDINARY path on Darwin today, not a fallback.
 *
 * So this fixture grades the ordinary path on both systems, byte for byte,
 * which is a stronger claim than a translating wrapper could have made: no
 * test on EITHER machine has quotas to exercise a success path with.
 *
 * THE ONE WAY THIS FIXTURE COULD GO STALE, said out loud: a Mac with an
 * HFS+ volume that has quotas turned on would answer differently. macOS's own
 * baseline verification (harness/run_macos.sh re-runs every fixture natively)
 * reports BASELINE-DRIFT rather than passing quietly if that ever happens.
 */
#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <sys/quota.h>
#include <unistd.h>

int main(void)
{
    struct dqblk db;
    int on = 0, rc;

    printf("SUBCMDSHIFT             %d\n", SUBCMDSHIFT);
    printf("SUBCMDMASK              0x%x\n", SUBCMDMASK);
    printf("USRQUOTA                %d\n", USRQUOTA);
    printf("GRPQUOTA                %d\n", GRPQUOTA);
    printf("Q_QUOTAON               0x%x\n", Q_QUOTAON);
    printf("Q_QUOTAOFF              0x%x\n", Q_QUOTAOFF);
    printf("Q_GETQUOTA              0x%x\n", Q_GETQUOTA);
    printf("Q_SETQUOTA              0x%x\n", Q_SETQUOTA);
    printf("Q_SYNC                  0x%x\n", Q_SYNC);
    printf("Q_QUOTASTAT             0x%x\n", Q_QUOTASTAT);
    printf("QCMD(Q_GETQUOTA,USR)    0x%x\n", QCMD(Q_GETQUOTA, USRQUOTA));
    printf("sizeof struct dqblk     %zu\n", sizeof(struct dqblk));

    /* The call FoundationEssentials makes first, with "/" written out.
     *
     * FE passes statfs's f_mntonname, and this fixture does NOT, deliberately:
     * `statfs` is not implemented in machorun's libSystem either -- a gap
     * ADJACENT to #69 and not on its list, surfaced by gen_tbd CHECK 3
     * refusing to emit a stub for a corpus symbol nothing defines. Using it
     * here would make this fixture fail for a reason that is not about
     * quotactl. "/" is a mount point on both systems, which is what the
     * argument has to be. */
    errno = 0;
    rc = quotactl("/", QCMD(Q_QUOTASTAT, USRQUOTA),
                  (int)geteuid(), (char *)&on);
    printf("Q_QUOTASTAT on /        rc %d errno %d is ENOTSUP %d\n",
           rc, rc < 0 ? errno : 0, rc < 0 && errno == ENOTSUP);

    memset(&db, 0, sizeof db);
    errno = 0;
    rc = quotactl("/", QCMD(Q_GETQUOTA, USRQUOTA),
                  (int)geteuid(), (char *)&db);
    printf("Q_GETQUOTA on /         rc %d errno %d is ENOTSUP %d\n",
           rc, rc < 0 ? errno : 0, rc < 0 && errno == ENOTSUP);

    /* A path that exists but is not a mount point: Darwin does not require
     * one, and answers ENOTSUP just the same. */
    errno = 0;
    rc = quotactl("/tmp", QCMD(Q_QUOTASTAT, USRQUOTA), (int)geteuid(), (char *)&on);
    printf("Q_QUOTASTAT on /tmp     rc %d errno %d is ENOTSUP %d\n",
           rc, rc < 0 ? errno : 0, rc < 0 && errno == ENOTSUP);

    /* A path that does not exist. Darwin distinguishes this from an
     * unsupported filesystem, and so must the implementation. */
    errno = 0;
    rc = quotactl("/machorun/no/such/path", QCMD(Q_QUOTASTAT, USRQUOTA), 0, (char *)&on);
    printf("Q_QUOTASTAT bad path    rc %d errno %d is ENOENT %d\n",
           rc, rc < 0 ? errno : 0, rc < 0 && errno == ENOENT);

    /* What the caller does with all of that: no quota information, so the
     * filesystem's own totals stand. */
    printf("caller falls back       %d\n", rc != 0);
    puts("done");
    return 0;
}
