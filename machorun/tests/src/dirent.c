/* dirent.c -- the `pthread_cond` rung: reading a directory, which is a struct-layout
 * translation and not a forward.
 *
 * DIR is opaque on both systems so the POINTER crosses fine, and that is
 * exactly what makes this dangerous: everything links, nothing crashes, and
 * the guest reads the wrong bytes. `struct dirent` does NOT agree --
 *
 *                       Darwin/arm64          glibc/aarch64
 *     sizeof                   1048                     280
 *     d_reclen               16 (2)                  16 (2)
 *     d_namlen               18 (2)                       -
 *     d_type                 20 (1)                  18 (1)
 *     d_name              21 (1024)                19 (256)
 *
 * -- so a guest reading d_name at 21 from a glibc record gets the filename
 * starting two characters in, and reads d_type out of the middle of a name.
 *
 * MEASURED, with libSystem's readdir() temporarily forwarding glibc's pointer
 * straight back, on a directory containing alpha.txt, beta.txt, subdir1,
 * subdir2 and one 74-character name:
 *
 *     entries=7                    (should be 5: "." and ".." stopped
 *     name= len=0                   matching their own names, so the filter
 *     name= len=0                   let them through)
 *     name=bdir1 len=5             (subdir1, two characters eaten)
 *     name=pha.txt len=7           (alpha.txt)
 *     dirs=0 regular=0             (d_type read from inside a filename)
 *     exit=0                       <- and it succeeded
 *
 * Exit 0 with plausible-looking output is the whole point of this fixture.
 * darwin/src/posix.c translates instead, and this grades the result against
 * macOS. sdk/tests/abi_probe.c pins the Darwin column of that table against
 * Apple's SDK and sdk/tests/glibc_abi_probe.c pins the glibc column against
 * real glibc headers, so the layouts cannot drift without a test failing.
 *
 * The directory is BUILT BY THIS PROGRAM rather than found, because the output
 * has to be identical on two machines that share no filesystem. Names are
 * chosen to make a two-byte shift obvious, and one is long enough to run well
 * past the end of a glibc record.
 */
#include <dirent.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

#define LONGNAME "a-very-long-file-name-to-exercise-the-name-field-beyond-anything-short.txt"

static int by_name(const void *a, const void *b)
{
    return strcmp(*(const char *const *)a, *(const char *const *)b);
}

int main(void)
{
    /* A fixed relative directory: the fixture runs with cwd set by the
     * harness, and a name nothing else uses. */
    const char *dir = "mr_dirent_tmp";
    const char *files[] = { "alpha.txt", "beta.txt", LONGNAME };
    const char *subs[]  = { "subdir1", "subdir2" };
    char path[512];
    char *names[64];
    int types[64], n = 0, ndir = 0, nreg = 0, nother = 0;
    DIR *d;
    struct dirent *e;

    /* Build it, tolerating a leftover from an interrupted run. */
    mkdir(dir, 0755);
    for (unsigned i = 0; i < sizeof files / sizeof files[0]; i++) {
        FILE *f;
        snprintf(path, sizeof path, "%s/%s", dir, files[i]);
        f = fopen(path, "w");
        if (!f) { printf("cannot create %s\n", files[i]); return 1; }
        fclose(f);
    }
    for (unsigned i = 0; i < sizeof subs / sizeof subs[0]; i++) {
        snprintf(path, sizeof path, "%s/%s", dir, subs[i]);
        mkdir(path, 0755);
    }

    d = opendir(dir);
    if (!d) { printf("opendir failed\n"); return 1; }
    while ((e = readdir(d)) != NULL && n < 64) {
        if (strcmp(e->d_name, ".") == 0 || strcmp(e->d_name, "..") == 0) continue;
        names[n] = strdup(e->d_name);
        types[n] = e->d_type;
        n++;
    }
    closedir(d);

    qsort(names, (size_t)n, sizeof names[0], by_name);
    printf("entries=%d\n", n);
    for (int i = 0; i < n; i++)
        printf("  name=%s namelen=%zu\n", names[i], strlen(names[i]));

    for (int i = 0; i < n; i++) {
        if (types[i] == DT_DIR)      ndir++;
        else if (types[i] == DT_REG) nreg++;
        else                          nother++;
    }
    printf("d_type: dirs=%d regular=%d other=%d\n", ndir, nreg, nother);

    /* The long name is the one that runs past a glibc record; say so
     * explicitly rather than leaving it implicit in the list above. */
    printf("longest=%zu expected=%zu\n", strlen(names[0]), strlen(LONGNAME));

    /* rewinddir must restart the stream, which also proves the wrapper is
     * carrying glibc's DIR rather than a copy of it. */
    d = opendir(dir);
    if (d) {
        int first = 0, second = 0;
        while (readdir(d)) first++;
        rewinddir(d);
        while (readdir(d)) second++;
        closedir(d);
        printf("rewinddir: %s\n", first == second && first > 0 ? "same count" : "MISMATCH");
    }

    for (int i = 0; i < n; i++) free(names[i]);
    for (unsigned i = 0; i < sizeof files / sizeof files[0]; i++) {
        snprintf(path, sizeof path, "%s/%s", dir, files[i]);
        unlink(path);
    }
    for (unsigned i = 0; i < sizeof subs / sizeof subs[0]; i++) {
        snprintf(path, sizeof path, "%s/%s", dir, subs[i]);
        rmdir(path);
    }
    rmdir(dir);
    printf("done\n");
    return 0;
}
