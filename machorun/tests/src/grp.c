/* getgrnam / getgrgid / getgrnam_r / getgrgid_r -- the passwd family's sibling,
 * and the measurement said it is NOT the passwd shape.
 *
 * `struct passwd` is 72 bytes on Darwin and 48 in glibc, agreeing for the first
 * four fields and then diverging -- which is what makes a forwarded one look
 * right just long enough to be trusted. `struct group` is 32 bytes on BOTH,
 * with gr_name/gr_passwd/gr_gid/gr_mem at 0/8/16/24 on both. There is no layout
 * to translate.
 *
 * SO WHAT IS LEFT TO GET WRONG, and what this fixture actually grades:
 *
 *   1. THE RETURN VALUE IS AN ERRNO, not -1 with errno set -- the pthread
 *      convention. ERANGE is 34 on both, which is the worst possible
 *      arrangement: the one error a caller usually tests for AGREES, so a
 *      wrapper that forgot to translate passes every obvious test and returns
 *      Linux numbers for everything else.
 *   2. "NO SUCH GROUP" IS rc == 0 WITH *result == NULL. Not an error. A
 *      wrapper reporting ENOENT there makes every correct caller's lookup
 *      fail -- the readdir_r shape, and it inverts just as easily.
 *   3. gr_mem is a NULL-TERMINATED ARRAY built inside the caller's buffer.
 *      Both the array and the strings must land there or the pointers dangle
 *      the moment the buffer goes out of scope.
 *
 * WHAT IT DOES NOT COMPARE, said here rather than left as a gap: group NAMES
 * and gr_passwd. gid 0 is `wheel` on macOS and `root` in the container, and
 * gr_passwd is `*` against `x`. Those are facts about the machine, not about
 * the ABI. The fixture instead does a ROUND TRIP -- look a group up by gid,
 * then look the name it returned back up by name -- which asserts a real value
 * on any machine without naming it.
 */
#include <errno.h>
#include <grp.h>
#include <stddef.h>
#include <stdio.h>
#include <string.h>

static int in_buffer(const void *p, const char *buf, size_t n)
{
    return (const char *)p >= buf && (const char *)p < buf + n;
}

int main(void)
{
    struct group g, *res;
    char buf[8192];
    char name0[256];
    int rc, n;

    printf("sizeof struct group     %zu\n", sizeof(struct group));
    printf("offset gr_name          %zu\n", offsetof(struct group, gr_name));
    printf("offset gr_passwd        %zu\n", offsetof(struct group, gr_passwd));
    printf("offset gr_gid           %zu\n", offsetof(struct group, gr_gid));
    printf("offset gr_mem           %zu\n", offsetof(struct group, gr_mem));

    /* --- getgrgid_r for gid 0, which exists on every system of either kind. */
    res = (struct group *)1;
    memset(&g, 0, sizeof g);
    rc = getgrgid_r(0, &g, buf, sizeof buf, &res);
    printf("getgrgid_r(0) rc        %d\n", rc);
    printf("  found                 %d\n", res != NULL);
    printf("  result points at &g   %d\n", res == &g);
    printf("  gr_gid                %u\n", res ? g.gr_gid : 4294967295u);
    printf("  gr_name non-empty     %d\n", res && g.gr_name && g.gr_name[0] != 0);
    printf("  gr_name in buffer     %d\n", res && in_buffer(g.gr_name, buf, sizeof buf));
    printf("  gr_passwd non-NULL    %d\n", res && g.gr_passwd != NULL);
    printf("  gr_mem non-NULL       %d\n", res && g.gr_mem != NULL);
    printf("  gr_mem in buffer      %d\n", res && in_buffer(g.gr_mem, buf, sizeof buf));
    n = 0;
    if (res && g.gr_mem) {
        while (g.gr_mem[n]) n++;                       /* NULL-terminated */
        printf("  gr_mem terminates     1\n");
    } else {
        printf("  gr_mem terminates     0\n");
    }
    name0[0] = 0;
    if (res && g.gr_name) {
        strncpy(name0, g.gr_name, sizeof name0 - 1);
        name0[sizeof name0 - 1] = 0;
    }

    /* --- ROUND TRIP: the name we were just given must resolve to gid 0. This
     * is a value assertion that does not depend on what the group is called. */
    res = (struct group *)1;
    memset(&g, 0, sizeof g);
    rc = getgrnam_r(name0, &g, buf, sizeof buf, &res);
    printf("getgrnam_r(round trip) rc %d\n", rc);
    printf("  found                 %d\n", res != NULL);
    printf("  gid came back as 0    %d\n", res && g.gr_gid == 0);
    printf("  name came back same   %d\n", res && g.gr_name && strcmp(g.gr_name, name0) == 0);

    /* --- the contract that inverts: a name that is not there. */
    res = (struct group *)1;
    rc = getgrnam_r("machorun_no_such_group", &g, buf, sizeof buf, &res);
    printf("getgrnam_r(missing) rc  %d\n", rc);
    printf("  result set to NULL    %d\n", res == NULL);

    /* --- a buffer that cannot hold the answer. ERANGE is 34 on both, which is
     * exactly why an untranslated return value survives this check; the round
     * trip above is what actually exercises the translation. */
    {
        char tiny[1];
        res = (struct group *)1;
        rc = getgrgid_r(0, &g, tiny, sizeof tiny, &res);
        printf("getgrgid_r(tiny) rc     %d\n", rc);
        printf("  rc == ERANGE          %d\n", rc == ERANGE);
        printf("  result set to NULL    %d\n", res == NULL);
    }

    /* --- the non-_r forms: static storage, overwritten by the next call. */
    {
        struct group *a = getgrgid(0);
        printf("getgrgid(0) non-NULL    %d\n", a != NULL);
        printf("  gr_gid                %u\n", a ? a->gr_gid : 4294967295u);
        printf("  same name as _r       %d\n", a && a->gr_name && strcmp(a->gr_name, name0) == 0);
        {
            struct group *b = getgrnam(name0);
            printf("getgrnam(same) non-NULL %d\n", b != NULL);
            printf("  gr_gid                %u\n", b ? b->gr_gid : 4294967295u);
            printf("  static storage reused %d\n", a == b);
        }
        printf("getgrnam(missing) NULL  %d\n", getgrnam("machorun_no_such_group") == NULL);
    }

    puts("done");
    return 0;
}
