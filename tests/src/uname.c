/* uname -- struct utsname is 1280 bytes on Darwin and 390 in glibc, and the
 * offsets are what kill you.
 *
 * Darwin: five 256-byte fields at 0/256/512/768/1024.
 * glibc:  SIX  65-byte fields at 0/65/130/195/260/325.
 *
 * A forward writes 390 bytes into a 1280-byte object, which is the SAFE
 * direction for the size and therefore does not crash -- and then the guest
 * reads `nodename` at +256, which is the middle of glibc's `machine`. Every
 * field but the first is garbage, the call returns 0, and nothing looks wrong.
 *
 * WHAT CAN AND CANNOT BE GRADED HERE, stated because a fixture that quietly
 * omits half its subject is worth less than one that says which half.
 *
 *   graded byte-for-byte:  the return value, `sysname`, `machine`, the NUL
 *                          termination of every field, and -- the measured
 *                          detail -- that Darwin writes strlen+1 bytes and
 *                          LEAVES THE REST OF THE FIELD ALONE. glibc zeroes
 *                          the whole 65 bytes, so a memset-then-copy
 *                          implementation fails this line and nothing else
 *                          would catch it.
 *   NOT graded:            `nodename`, `release` and `version` are facts about
 *                          the machine. Two Macs disagree about all three, so
 *                          no differential fixture could ever compare them.
 *                          Their SHAPE is graded instead.
 *
 * `release` in particular is a recorded divergence rather than an oversight:
 * machorun reports the Linux kernel's release under a Darwin `sysname`, and
 * docs/UNIMPLEMENTED.md#uname-identity argues why inventing a Darwin version
 * number would have been worse.
 */
#include <errno.h>
#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include <sys/utsname.h>

/* Every byte from the NUL to the end of the field must still hold the sentinel
 * the struct was filled with. This is the whole point of the fixture: it is
 * true on Darwin, false for anything that zeroes the field first, and cannot
 * be reached by looking at the strings. */
static int tail_untouched(const char *f, unsigned width, char sentinel)
{
    size_t len = strnlen(f, width);
    if (len >= width) return 0;                  /* not terminated at all */
    for (size_t i = len + 1; i < width; i++)
        if (f[i] != sentinel) return 0;
    return 1;
}

int main(void)
{
    struct utsname u;
    int rc;

    printf("sizeof struct utsname   %zu\n", sizeof u);
    printf("offset sysname          %zu\n", offsetof(struct utsname, sysname));
    printf("offset nodename         %zu\n", offsetof(struct utsname, nodename));
    printf("offset release          %zu\n", offsetof(struct utsname, release));
    printf("offset version          %zu\n", offsetof(struct utsname, version));
    printf("offset machine          %zu\n", offsetof(struct utsname, machine));
    printf("field width             %zu\n", sizeof u.sysname);

    memset(&u, 'Z', sizeof u);
    rc = uname(&u);
    printf("uname returned          %d\n", rc);

    /* The two fields whose CONTENT is the same on any machine of this kind. */
    printf("sysname                 [%s]\n", u.sysname);
    printf("machine                 [%s]\n", u.machine);

    /* The three that are machine-specific: shape only. */
    printf("nodename non-empty      %d\n", u.nodename[0] != 0 && u.nodename[0] != 'Z');
    printf("release  non-empty      %d\n", u.release[0]  != 0 && u.release[0]  != 'Z');
    printf("version  non-empty      %d\n", u.version[0]  != 0 && u.version[0]  != 'Z');

    /* release must parse as a dotted version: FoundationEssentials'
     * ProcessInfo.operatingSystemVersion splits exactly this string. */
    printf("release starts numeric  %d\n", u.release[0] >= '0' && u.release[0] <= '9');
    printf("release has a dot       %d\n", strchr(u.release, '.') != NULL);

    printf("sysname tail untouched  %d\n", tail_untouched(u.sysname,  256, 'Z'));
    printf("nodename tail untouched %d\n", tail_untouched(u.nodename, 256, 'Z'));
    printf("release tail untouched  %d\n", tail_untouched(u.release,  256, 'Z'));
    printf("version tail untouched  %d\n", tail_untouched(u.version,  256, 'Z'));
    printf("machine tail untouched  %d\n", tail_untouched(u.machine,  256, 'Z'));

    /* The bytes past nodename[0] would be glibc's `machine` under a naive
     * forward, so this is the specific corruption the translation prevents. */
    printf("nodename != machine     %d\n", strcmp(u.nodename, u.machine) != 0);

    errno = 0;
    rc = uname(NULL);
    printf("uname(NULL) returned    %d errno %d\n", rc, errno);

    puts("done");
    return 0;
}
