/* 23_passwd.c -- rung (u): the password database, translated not forwarded.
 *
 * struct passwd is the same hazard as struct dirent with a nastier profile:
 * the two layouts AGREE for the first four fields and then diverge, so a
 * forwarded struct reads correctly exactly long enough to be believed.
 *
 *   Darwin field   off   what it reads out of glibc's 48 bytes
 *   pw_name          0   pw_name        <- agrees
 *   pw_passwd        8   pw_passwd      <- agrees
 *   pw_uid          16   pw_uid         <- agrees
 *   pw_gid          20   pw_gid         <- agrees
 *   pw_change       24   pw_gecos       (a char* read as a time_t)
 *   pw_class        32   pw_dir         (the home directory, as the class)
 *   pw_gecos        40   pw_shell       (the shell, as the full name)
 *   pw_dir          48   PAST THE END of a 48-byte allocation
 *   pw_shell        56   PAST THE END
 *
 * Darwin's struct is 72 bytes and glibc's is 48, and the field a caller
 * actually wants -- pw_dir, "where is the home directory", which is what
 * CoreFoundation asks for -- is the first one off the end.
 *
 * WHAT THIS PRINTS. Not the values: usernames, uids and home directories
 * differ between a macOS host and a container, so no fixed expected output can
 * be right. It prints the STRUCTURAL PROPERTIES that must hold on any Unix and
 * that a forwarded struct fails:
 *
 *   - the same uid looked up by name and by number agrees with itself
 *   - pw_dir is an absolute path, not a shell and not garbage
 *   - pw_shell is an absolute path
 *   - pw_class is empty, pw_change and pw_expire are zero
 *   - the _r form fills the caller's struct consistently with the plain form
 *
 * MEASURED against a deliberately forwarded build, because a predicted tell is
 * not a demonstrated one. Handing glibc's struct back unmodified gives:
 *
 *     by_uid          has a name        <- still passes
 *     uid round-trip  agrees            <- still passes
 *     name round-trip agrees            <- still passes
 *     pw_dir absolute NO                <- caught
 *     pw_shell absolute NO              <- caught
 *     pw_class empty  NO                <- caught (it holds the home directory)
 *     pw_change zero  NO                <- caught (a char* read as a time_t)
 *
 * Three of the checks pass on a broken build, which is the whole point: the
 * first four fields agree, so anything testing only names and uids is
 * satisfied. The absolute-path and neutral-value checks are what discriminate.
 *
 * AND ONE PREDICTION THAT DID NOT HOLD, kept because being wrong about which
 * check fires is worth more than pretending otherwise. I expected
 * "pw_gecos == pw_shell" to be the tell, reasoning that Darwin's pw_gecos
 * (offset 40) reads glibc's pw_shell (also 40). It does -- but Darwin's
 * pw_shell (56) reads PAST THE END and comes back as garbage, so the two
 * strings differ and the check passes on a forwarded build. It compares a
 * wrong-but-valid value against an out-of-bounds one. Retained because it
 * would fire if the struct ever grew enough to bring pw_shell back in bounds,
 * and labelled so nobody reads it as the discriminator.
 *
 * Same predicates-not-values approach as 19_isa_mask and 22_sysconf, for the
 * same reason: when the right answer legitimately differs per host, test the
 * invariant.
 */
#include <stdio.h>
#include <string.h>
#include <pwd.h>
#include <unistd.h>
#include <sys/types.h>

static int is_abs_path(const char *s) { return s && s[0] == '/'; }

int main(void)
{
    /* geteuid rather than getuid: getuid is not exported by libSystem yet
     * (it is on the CF libc list, in another agent's half of the split), and
     * for this fixture's purpose -- struct layout, not identity -- the
     * effective uid does the same job. */
    uid_t me = geteuid();
    struct passwd *by_uid = getpwuid(me);
    if (!by_uid) { printf("getpwuid(self) returned NULL\n"); return 1; }

    printf("by_uid          %s\n", by_uid->pw_name ? "has a name" : "NO NAME");
    printf("uid round-trip  %s\n", by_uid->pw_uid == me ? "agrees" : "DISAGREES");
    printf("pw_dir absolute %s\n", is_abs_path(by_uid->pw_dir) ? "yes" : "NO");
    printf("pw_shell absolute %s\n", is_abs_path(by_uid->pw_shell) ? "yes" : "NO");

    /* NOT the tell, though it looks like one -- see the header. Forwarded,
     * pw_gecos reads glibc's pw_shell and pw_shell reads out of bounds, so
     * these differ for the wrong reason and this check passes anyway. */
    printf("gecos != shell  %s\n",
           (by_uid->pw_gecos && by_uid->pw_shell &&
            strcmp(by_uid->pw_gecos, by_uid->pw_shell) == 0) ? "SAME (forwarded!)" : "differ");

    /* pw_class and the two time fields have no Linux equivalent. Darwin's
     * neutral answers are "" and 0 -- real answers, since a Linux account has
     * no login class or expiry. Forwarded, pw_class would hold pw_dir. */
    printf("pw_class empty  %s\n",
           (by_uid->pw_class && by_uid->pw_class[0] == '\0') ? "yes" : "NO");
    printf("pw_change zero  %s\n", by_uid->pw_change == 0 ? "yes" : "NO");
    printf("pw_expire zero  %s\n", by_uid->pw_expire == 0 ? "yes" : "NO");

    /* Name -> uid must round-trip back to the same account. */
    {
        char name[256];
        struct passwd *by_name;
        snprintf(name, sizeof name, "%s", by_uid->pw_name ? by_uid->pw_name : "");
        by_name = getpwnam(name);
        printf("name round-trip %s\n",
               (by_name && by_name->pw_uid == me) ? "agrees" : "DISAGREES");
    }

    /* The reentrant form fills the CALLER's 72-byte struct. Forwarded, glibc
     * would write 48 bytes into it and leave pw_dir onward holding whatever
     * the caller's stack had. */
    {
        struct passwd pw, *res = NULL;
        char buf[4096];
        int rc = getpwuid_r(me, &pw, buf, sizeof buf, &res);
        printf("_r rc           %s\n", rc == 0 ? "0" : "nonzero");
        printf("_r found        %s\n", res == &pw ? "points at ours" : "NO");
        printf("_r dir absolute %s\n", (res && is_abs_path(pw.pw_dir)) ? "yes" : "NO");
        printf("_r uid agrees   %s\n", (res && pw.pw_uid == me) ? "yes" : "NO");
        printf("_r gecos!=shell %s\n",
               (res && pw.pw_gecos && pw.pw_shell &&
                strcmp(pw.pw_gecos, pw.pw_shell) == 0) ? "SAME (forwarded!)" : "differ");
    }

    /* A user that cannot exist must be reported absent, not invented. */
    printf("absent user     %s\n",
           getpwnam("machorun-no-such-user-2026") == NULL ? "NULL (correct)" : "INVENTED ONE");

    printf("done\n");
    return 0;
}
