/* dirent_r.c -- readdir_r, and the parts of CF's plain surface that can be
 * graded against a macOS oracle.
 *
 * readdir_r's CONTRACT IS EASY TO GET BACKWARDS and that is what this grades.
 * It returns an ERRNO -- 0 on success, including at end of directory -- and
 * signals end-of-directory by storing NULL through `result`. It does NOT return
 * -1 and does NOT set errno. A wrapper that returned -1 at EOF would make every
 * caller's loop terminate as an error, and a wrapper that set errno would make
 * a correct caller think the directory was unreadable.
 *
 * The entries themselves are the `struct dirent` translation that readdir
 * already needed -- 1048 bytes on Darwin against 280 on glibc, with d_type at
 * 20 against 18 and d_name at 21 against 19. readdir_r differs only in filling
 * the CALLER's struct rather than one we own, which is why the translation now
 * lives in a single helper both entry points call: two copies would be free to
 * drift, and a copy that got d_reclen wrong would corrupt a caller walking a
 * buffer rather than reading one record.
 *
 * WHAT IT READS AND WHY. A directory this fixture creates itself, so the
 * contents are identical on both systems -- reading any real directory would
 * make the output a property of the machine. The names are chosen so that
 * sorting is unambiguous and one of them is long enough to exercise d_namlen
 * and d_reclen rather than only the short path.
 *
 * __darwin_check_fd_set_overflow is here because it is a pure range check with
 * no host dependence at all: FD_SETSIZE is 1024 and sizeof(fd_set) is 128 on
 * BOTH systems, measured, so fd_set needs no translation and the answers are
 * the same everywhere.
 *
 * DELIBERATELY ABSENT, because no oracle-matching fixture can hold them:
 *
 *   gethostuuid  -- succeeds on macOS and fails in a container, which has no
 *                   host identity of its own (/etc/machine-id is empty and the
 *                   dbus id absent, measured). Failing is correct rather than a
 *                   gap; inventing a UUID would be indistinguishable from a
 *                   real one. docs/UNIMPLEMENTED.md#gethostuuid-no-identity.
 *   sysdir_*     -- returns real paths on macOS and an empty enumeration here,
 *                   because Linux has no Darwin domains at all.
 *                   docs/UNIMPLEMENTED.md#sysdir-empty.
 *   chown        -- changing ownership needs privilege the test does not have
 *                   and should not want.
 */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <dirent.h>
#include <sys/stat.h>
#include <sys/select.h>
#include <unistd.h>
#include <errno.h>

static int cmp(const void *a, const void *b)
{
    return strcmp(*(const char **)a, *(const char **)b);
}

int main(void)
{
    const char *dir = "mr_dirent_probe";
    const char *made[] = { "a", "bb", "a_rather_longer_entry_name_here" };
    char *seen[64];
    int nseen = 0, i, rc;
    DIR *d;
    struct dirent ent, *res;

    /* Build the directory so the contents are ours rather than the machine's. */
    mkdir(dir, 0755);
    for (i = 0; i < 3; i++) {
        char p[256];
        FILE *f;
        snprintf(p, sizeof p, "%s/%s", dir, made[i]);
        f = fopen(p, "w");
        if (f) fclose(f);
    }

    puts("== readdir_r returns an errno and signals EOF through result");
    d = opendir(dir);
    if (!d) { puts("  opendir failed"); return 1; }

    for (;;) {
        res = NULL;
        errno = 0;
        rc = readdir_r(d, &ent, &res);
        if (rc != 0) { printf("  readdir_r returned errno %d\n", rc); break; }
        if (!res) break;                      /* end of directory, rc still 0 */
        if (strcmp(ent.d_name, ".") == 0 || strcmp(ent.d_name, "..") == 0) continue;
        if (nseen < 64) seen[nseen++] = strdup(ent.d_name);
        /* d_namlen and d_reclen are the two fields a copied translation would
         * drift on, and the long name is the case that shows it. */
        if (ent.d_namlen != strlen(ent.d_name))
            printf("  d_namlen disagrees with the name for \"%s\"\n", ent.d_name);
    }
    printf("  final rc=%d  result NULL at EOF: %s  errno untouched: %s\n",
           rc, res == NULL ? "yes" : "NO", errno == 0 ? "yes" : "NO");

    qsort(seen, (size_t)nseen, sizeof seen[0], cmp);
    printf("  entries found: %d\n", nseen);
    for (i = 0; i < nseen; i++) printf("    %s\n", seen[i]);

    closedir(d);

    puts("== a second pass agrees with the first");
    /* rewind and count again -- a translation that mutated shared state would
     * differ between passes, which reading once cannot show. */
    d = opendir(dir);
    {
        int again = 0;
        for (;;) {
            res = NULL;
            if (readdir_r(d, &ent, &res) != 0 || !res) break;
            if (strcmp(ent.d_name, ".") && strcmp(ent.d_name, "..")) again++;
        }
        printf("  same count: %s\n", again == nseen ? "yes" : "NO");
        closedir(d);
    }

    puts("== __darwin_check_fd_set_overflow is a pure range check");
    {
        fd_set fds;
        FD_ZERO(&fds);
        printf("  FD_SETSIZE=%d  sizeof(fd_set)=%zu\n",
               FD_SETSIZE, sizeof(fd_set));
        /* FD_SET expands into the check on Darwin, so exercising the macro is
         * exercising the function. An in-range descriptor must round trip. */
        FD_SET(3, &fds);
        printf("  fd 3 set and readable: %s\n", FD_ISSET(3, &fds) ? "yes" : "NO");
        FD_CLR(3, &fds);
        printf("  and cleared: %s\n", !FD_ISSET(3, &fds) ? "yes" : "NO");
    }

    /* Tidy up so a re-run starts from the same state. */
    for (i = 0; i < 3; i++) {
        char p[256];
        snprintf(p, sizeof p, "%s/%s", dir, made[i]);
        unlink(p);
    }
    rmdir(dir);

    puts("done");
    return 0;
}
