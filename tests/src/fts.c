/* fts(3): the traversal may belong to glibc, but every field this fixture
 * exercises has to reach a Darwin guest in Darwin's ABI.
 *
 * FTS is 72 bytes on both arm64 platforms. That accidental agreement hides
 * the real hazard: FTSENT is 112 bytes on Darwin and 120 on glibc, diverging
 * at fts_nlink and shifting fts_level, fts_info, fts_instr, fts_statp, and the
 * inline name. Forwarding a Linux entry therefore links and usually walks,
 * while the guest reads plausible garbage. fts_statp is a second translated
 * structure, and fts_set must map the rebuilt Darwin entry back to the glibc
 * entry that owns the traversal.
 *
 * This fixture creates one exact tree in /tmp, records the fields that cross
 * that boundary, exercises fts_children's linked list, and skips a subtree
 * through fts_set. Records are sorted after walking because directory order
 * is intentionally not part of either platform's contract.
 */
#include <fts.h>
#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

#define ROOT "/tmp/machorun_fts_fixture"

_Static_assert(FTS_LOGICAL == 0x02 && FTS_NOCHDIR == 0x04 &&
               FTS_NOSTAT == 0x08 && FTS_PHYSICAL == 0x10 &&
               FTS_COMFOLLOWDIR == 0x400 && FTS_NOSTAT_TYPE == 0x800 &&
               FTS_OPTIONMASK == 0xcff && FTS_ROOTPARENTLEVEL == -1,
               "Darwin fts option constants changed");
_Static_assert(FTS_D == 1 && FTS_DC == 2 && FTS_DNR == 4 &&
               FTS_DOT == 5 && FTS_DP == 6 && FTS_ERR == 7 &&
               FTS_INIT == 9 && FTS_NSOK == 11,
               "Darwin fts info constants changed");
_Static_assert(FTS_SYMFOLLOW == 0x02 && FTS_NOINSTR == 3 &&
               FTS_SKIP == 4 && FTS_NAMEONLY == 0x100,
               "Darwin fts instruction constants changed");

struct record {
    char path[256];
    char name[128];
    char parent[128];
    char info[16];
    char kind[8];
    int level;
    int error;
    long number;
};

static int write_file(const char *path, const char *contents)
{
    int fd = open(path, O_WRONLY | O_CREAT | O_TRUNC, 0644);
    size_t n = strlen(contents);
    if (fd < 0) return -1;
    if (write(fd, contents, n) != (ssize_t)n) {
        close(fd);
        return -1;
    }
    return close(fd);
}

/* Every target is literal and owned by this fixture. Unknown material makes
 * setup fail rather than widening cleanup into a recursive deletion. */
static int cleanup(void)
{
    int rc = 0;
    const char *files[] = {
        ROOT "/nested/aardvark.txt",
        ROOT "/nested/leaf.txt",
        ROOT "/skip/hidden.txt",
        ROOT "/alpha.txt",
        ROOT "/pipe",
        ROOT "/link-to-leaf",
        ROOT "/link-to-dir",
        ROOT "/dangling"
    };
    for (size_t i = 0; i < sizeof files / sizeof files[0]; i++)
        if (unlink(files[i]) < 0 && errno != ENOENT) rc = -1;
    if (rmdir(ROOT "/nested") < 0 && errno != ENOENT) rc = -1;
    if (rmdir(ROOT "/skip") < 0 && errno != ENOENT) rc = -1;
    if (rmdir(ROOT) < 0 && errno != ENOENT) rc = -1;
    return rc;
}

static int make_tree(void)
{
    if (cleanup() < 0) return -1;
    if (mkdir(ROOT, 0755) < 0 ||
        mkdir(ROOT "/nested", 0755) < 0 ||
        mkdir(ROOT "/skip", 0755) < 0 ||
        write_file(ROOT "/alpha.txt", "alpha\n") < 0 ||
        write_file(ROOT "/nested/leaf.txt", "leaf\n") < 0 ||
        write_file(ROOT "/nested/aardvark.txt", "aardvark\n") < 0 ||
        write_file(ROOT "/skip/hidden.txt", "hidden\n") < 0 ||
        mkfifo(ROOT "/pipe", 0600) < 0 ||
        symlink("nested/leaf.txt", ROOT "/link-to-leaf") < 0 ||
        symlink("nested", ROOT "/link-to-dir") < 0 ||
        symlink("missing-target", ROOT "/dangling") < 0)
        return -1;
    return 0;
}

static const char *info_name(unsigned short info)
{
    switch (info) {
    case FTS_D:       return "D";
    case FTS_DC:      return "DC";
    case FTS_DEFAULT: return "DEFAULT";
    case FTS_DNR:     return "DNR";
    case FTS_DOT:     return "DOT";
    case FTS_DP:      return "DP";
    case FTS_ERR:     return "ERR";
    case FTS_F:       return "F";
    case FTS_NS:      return "NS";
    case FTS_NSOK:    return "NSOK";
    case FTS_SL:      return "SL";
    case FTS_SLNONE:  return "SLNONE";
    default:          return "UNKNOWN";
    }
}

static const char *kind_name(const FTSENT *entry)
{
    if (!entry->fts_statp) return "none";
    if (S_ISDIR(entry->fts_statp->st_mode)) return "dir";
    if (S_ISREG(entry->fts_statp->st_mode)) return "file";
    if (S_ISLNK(entry->fts_statp->st_mode)) return "link";
    return "other";
}

static int bytes_are_zero(const void *pointer, size_t size)
{
    const unsigned char *bytes = pointer;
    for (size_t i = 0; i < size; i++)
        if (bytes[i] != 0) return 0;
    return 1;
}

static const char *relative_path(const char *path)
{
    size_t n = strlen(ROOT);
    if (strncmp(path, ROOT, n) != 0) return "<outside>";
    return path[n] ? path + n : "/";
}

static int by_record(const void *a, const void *b)
{
    const struct record *ra = a, *rb = b;
    int rc = strcmp(ra->path, rb->path);
    if (rc) return rc;
    return strcmp(ra->info, rb->info);
}

static int by_string(const void *a, const void *b)
{
    return strcmp(*(const char *const *)a, *(const char *const *)b);
}

static int physical_walk(void)
{
    char *paths[] = { ROOT, NULL };
    struct record records[32];
    char *children[16];
    int nrecords = 0, nchildren = 0, skipped = 0, child_marked = 0;
    long child_number = -1, skip_number = -1, root_number = -1;
    int child_pointer = 0, child_identity = 0, skip_instr = -1;
    int root_pointer = 0;
    long root_parent_number = -1;
    int root_parent_pointer = 0;
    dev_t stream_device = 0;
    int stream_device_root = 0, stream_device_file = 0;
    FTS *fts = fts_open(paths, FTS_PHYSICAL | FTS_NOCHDIR, NULL);
    FTSENT *entry;

    if (!fts) {
        printf("physical open failed errno=%d\n", errno);
        return -1;
    }
    while ((entry = fts_read(fts)) != NULL) {
        struct record *record;
        if (nrecords >= (int)(sizeof records / sizeof records[0])) {
            puts("too many records");
            fts_close(fts);
            return -1;
        }
        record = &records[nrecords++];
        snprintf(record->path, sizeof record->path, "%s",
                 relative_path(entry->fts_path));
        snprintf(record->name, sizeof record->name, "%s", entry->fts_name);
        snprintf(record->parent, sizeof record->parent, "%s",
                 entry->fts_level == 0 || !entry->fts_parent
                     ? "<root>" : entry->fts_parent->fts_name);
        snprintf(record->info, sizeof record->info, "%s",
                 info_name(entry->fts_info));
        snprintf(record->kind, sizeof record->kind, "%s", kind_name(entry));
        record->level = entry->fts_level;
        record->error = entry->fts_errno;
        record->number = entry->fts_number;

        if (entry->fts_level == 0 && entry->fts_info == FTS_D) {
            int bad_rc, bad_errno;
            FTSENT *child = fts_children(fts, 0);
            stream_device = fts->fts_dev;
            stream_device_root = stream_device != 0 &&
                stream_device == entry->fts_dev;
            for (; child && nchildren < 16; child = child->fts_link) {
                children[nchildren++] = strdup(child->fts_name);
                if (strcmp(child->fts_name, "alpha.txt") == 0) {
                    child->fts_number = 313;
                    child->fts_pointer = (void *)(uintptr_t)0x5678;
                    child_marked++;
                }
            }
            printf("root parent level=%d name=[%s]\n",
                   entry->fts_parent ? entry->fts_parent->fts_level : 999,
                   entry->fts_parent ? entry->fts_parent->fts_name : "<null>");
            printf("root parent surface info=%u instr=%u accpath=%s path=%s statp=%s symfd=%d\n",
                   entry->fts_parent ? entry->fts_parent->fts_info : 999,
                   entry->fts_parent ? entry->fts_parent->fts_instr : 999,
                   entry->fts_parent && entry->fts_parent->fts_accpath == NULL
                       ? "null" : "BAD",
                   entry->fts_parent &&
                       entry->fts_parent->fts_path == entry->fts_path
                       ? "shared" : "BAD",
                   entry->fts_parent && entry->fts_parent->fts_statp &&
                       bytes_are_zero(entry->fts_parent->fts_statp,
                                      sizeof *entry->fts_parent->fts_statp)
                       ? "zero" : "BAD",
                   entry->fts_parent ? entry->fts_parent->fts_symfd : 999);
            errno = 0;
            bad_rc = fts_set(fts, entry, 99);
            bad_errno = errno;
            printf("invalid set rc=%d errno=%d EINVAL=%d\n",
                   bad_rc, bad_errno, EINVAL);
            errno = 0;
            entry->fts_number = 4242;
            entry->fts_pointer = (void *)(uintptr_t)0x1234;
            entry->fts_parent->fts_number = 5150;
            entry->fts_parent->fts_pointer = (void *)(uintptr_t)0x5150;
        }
        if (strcmp(entry->fts_name, "alpha.txt") == 0 &&
            entry->fts_info == FTS_F) {
            child_number = entry->fts_number;
            child_pointer = entry->fts_pointer ==
                (void *)(uintptr_t)0x5678;
            child_identity = entry->fts_ino == 0 && entry->fts_dev == 0 &&
                entry->fts_nlink == 0 && entry->fts_statp;
            stream_device_file = fts->fts_dev == stream_device;
        }
        if (strcmp(entry->fts_name, "skip") == 0 &&
            entry->fts_info == FTS_D) {
            entry->fts_number = 77;
            if (fts_set(fts, entry, FTS_SKIP) < 0) {
                printf("fts_set failed errno=%d\n", errno);
                fts_close(fts);
                return -1;
            }
            skipped++;
        }
        if (strcmp(entry->fts_name, "skip") == 0 &&
            entry->fts_info == FTS_DP) {
            skip_instr = entry->fts_instr;
            skip_number = entry->fts_number;
        }
        if (entry->fts_level == 0 && entry->fts_info == FTS_DP) {
            root_number = entry->fts_number;
            root_pointer = entry->fts_pointer ==
                (void *)(uintptr_t)0x1234;
            root_parent_number = entry->fts_parent->fts_number;
            root_parent_pointer = entry->fts_parent->fts_pointer ==
                (void *)(uintptr_t)0x5150;
        }
    }
    if (errno != 0) {
        printf("physical read failed errno=%d\n", errno);
        fts_close(fts);
        return -1;
    }
    printf("physical eof current=%s\n",
           fts->fts_cur == NULL ? "null" : "STALE");
    if (fts_close(fts) < 0) {
        printf("physical close failed errno=%d\n", errno);
        return -1;
    }
    printf("child roundtrip number=%ld pointer=%s file-identity=%s\n",
           child_number, child_pointer ? "preserved" : "LOST",
           child_identity ? "zero-with-stat" : "BAD");
    printf("skip postorder instr=%d number=%ld\n",
           skip_instr, skip_number);
    printf("root roundtrip number=%ld pointer=%s\n",
           root_number, root_pointer ? "preserved" : "LOST");
    printf("root-parent roundtrip number=%ld pointer=%s\n",
           root_parent_number,
           root_parent_pointer ? "preserved" : "LOST");
    printf("stream device root=%s file=%s\n",
           stream_device_root ? "initialized" : "BAD",
           stream_device_file ? "retained" : "BAD");

    qsort(children, (size_t)nchildren, sizeof children[0], by_string);
    printf("children count=%d", nchildren);
    for (int i = 0; i < nchildren; i++) {
        printf(" [%s]", children[i]);
        free(children[i]);
    }
    putchar('\n');

    qsort(records, (size_t)nrecords, sizeof records[0], by_record);
    printf("physical records=%d skipped=%d child-marked=%d\n",
           nrecords, skipped, child_marked);
    for (int i = 0; i < nrecords; i++)
        printf("  path=%s name=%s parent=%s level=%d info=%s kind=%s err=%d number=%ld\n",
               records[i].path, records[i].name, records[i].parent,
               records[i].level, records[i].info, records[i].kind,
               records[i].error, records[i].number);
    return 0;
}

static int nostat_walk(void)
{
    struct dir_identity {
        char path[256];
        unsigned long long ino;
        unsigned long long dev;
        unsigned long long nlink;
    } dirs[8];
    char *paths[] = { ROOT, NULL };
    FTS *fts = fts_open(paths, FTS_PHYSICAL | FTS_NOCHDIR | FTS_NOSTAT, NULL);
    FTSENT *entry;
    int count = 0, statp = 0, nsok = 0, nsok_zero = 0;
    int ndirs = 0, dir_scalars = 0, dir_stable = 0;
    if (!fts) {
        printf("nostat open failed errno=%d\n", errno);
        return -1;
    }
    while ((entry = fts_read(fts)) != NULL) {
        count++;
        if (entry->fts_statp) statp++;
        if (entry->fts_info == FTS_NSOK) {
            nsok++;
            if (entry->fts_ino == 0 && entry->fts_dev == 0 &&
                entry->fts_nlink == 0) nsok_zero++;
        }
        if (entry->fts_info == FTS_D) {
            if (entry->fts_ino != 0 && entry->fts_dev != 0 &&
                entry->fts_nlink != 0) dir_scalars++;
            if (ndirs < (int)(sizeof dirs / sizeof dirs[0])) {
                snprintf(dirs[ndirs].path, sizeof dirs[ndirs].path, "%s",
                         relative_path(entry->fts_path));
                dirs[ndirs].ino = entry->fts_ino;
                dirs[ndirs].dev = entry->fts_dev;
                dirs[ndirs].nlink = entry->fts_nlink;
                ndirs++;
            }
        } else if (entry->fts_info == FTS_DP) {
            if (entry->fts_ino != 0 && entry->fts_dev != 0 &&
                entry->fts_nlink != 0) dir_scalars++;
            for (int i = 0; i < ndirs; i++)
                if (strcmp(dirs[i].path, relative_path(entry->fts_path)) == 0 &&
                    dirs[i].ino == (unsigned long long)entry->fts_ino &&
                    dirs[i].dev == (unsigned long long)entry->fts_dev &&
                    dirs[i].nlink == (unsigned long long)entry->fts_nlink) {
                    dir_stable++;
                    break;
                }
        }
    }
    if (errno != 0) {
        printf("nostat read failed errno=%d\n", errno);
        fts_close(fts);
        return -1;
    }
    if (fts_close(fts) < 0) return -1;
    printf("nostat records=%d statp=%d nsok=%d dir-scalars=%d dir-stable=%d nsok-zero=%d\n",
           count, statp, nsok, dir_scalars, dir_stable, nsok_zero);
    return 0;
}

static int nested_comparator_result;

static int simple_fts_name(const FTSENT **left, const FTSENT **right)
{
    return strcmp((*left)->fts_name, (*right)->fts_name);
}

static int by_fts_name(const FTSENT **left, const FTSENT **right)
{
    /* fts has no comparator context argument. The bridge therefore installs
     * its stream in pthread-local state around each glibc call. Re-enter once
     * from guest comparator code: an implementation that clears rather than
     * restores the outer stream aborts on the next outer comparison. */
    if (nested_comparator_result == 0) {
        char *nested_paths[] = {
            ROOT "/nested/leaf.txt", ROOT "/alpha.txt", NULL
        };
        FTS *nested;
        FTSENT *entry;
        int count = 0;
        nested_comparator_result = -1; /* prevents recursion before fts_open */
        nested = fts_open(nested_paths,
                          FTS_PHYSICAL | FTS_NOCHDIR, simple_fts_name);
        if (nested) {
            while ((entry = fts_read(nested)) != NULL) count++;
            if (errno == 0 && fts_close(nested) == 0)
                nested_comparator_result = count;
        }
    }
    return simple_fts_name(left, right);
}

static int comparator_walk(void)
{
    char *paths[] = { ROOT, NULL };
    FTS *fts = fts_open(paths, FTS_PHYSICAL | FTS_NOCHDIR, by_fts_name);
    FTSENT *entry;
    int count = 0;
    if (!fts) {
        printf("comparator open failed errno=%d\n", errno);
        return -1;
    }
    printf("comparator order=");
    while ((entry = fts_read(fts)) != NULL) {
        printf(" [%s:%s]", relative_path(entry->fts_path),
               info_name(entry->fts_info));
        count++;
    }
    putchar('\n');
    if (errno != 0) {
        printf("comparator read failed errno=%d\n", errno);
        fts_close(fts);
        return -1;
    }
    if (fts_close(fts) < 0) return -1;
    printf("comparator records=%d\n", count);
    printf("nested comparator=%s records=%d\n",
           nested_comparator_result == 2 ? "ok" : "FAILED",
           nested_comparator_result);
    if (nested_comparator_result != 2) return -1;
    return 0;
}

static int nameonly_children(int nostat)
{
    char *paths[] = { ROOT, NULL };
    int options = FTS_PHYSICAL | FTS_NOCHDIR | (nostat ? FTS_NOSTAT : 0);
    FTS *fts = fts_open(paths, options, NULL);
    FTSENT *entry, *child;
    int count = 0, nsok = 0, statp = 0, zero = 0;
    if (!fts) {
        printf("nameonly%s open failed errno=%d\n",
               nostat ? "-nostat" : "", errno);
        return -1;
    }
    entry = fts_read(fts);
    if (!entry || entry->fts_info != FTS_D) {
        printf("nameonly%s root failed errno=%d\n",
               nostat ? "-nostat" : "", errno);
        fts_close(fts);
        return -1;
    }
    child = fts_children(fts, FTS_NAMEONLY);
    for (; child; child = child->fts_link) {
        count++;
        if (child->fts_info == FTS_NSOK) nsok++;
        if (child->fts_statp) {
            statp++;
            if (bytes_are_zero(child->fts_statp,
                               sizeof *child->fts_statp)) zero++;
        }
    }
    if (fts_close(fts) < 0) return -1;
    printf("nameonly%s count=%d nsok=%d statp=%d zero=%d\n",
           nostat ? "-nostat" : "", count, nsok, statp, zero);
    return 0;
}

static int logical_surface(void)
{
    char *paths[] = { ROOT "/alpha.txt", NULL };
    FTS *fts = fts_open(paths, FTS_LOGICAL, NULL);
    if (!fts) {
        printf("logical open failed errno=%d\n", errno);
        return -1;
    }
    printf("logical public-options=0x%x\n", fts->fts_options);
    return fts_close(fts);
}

static int invalid_options(void)
{
    char *paths[] = { ROOT, NULL };
    FTS *fts;
    int saved_errno;
    errno = 0;
    fts = fts_open(paths, FTS_PHYSICAL | 0x1000, NULL);
    saved_errno = errno;
    printf("invalid-options stream=%s errno=%d EINVAL=%d\n",
           fts == NULL ? "null" : "UNEXPECTED", saved_errno, EINVAL);
    if (fts) fts_close(fts);
    return fts == NULL && saved_errno == EINVAL ? 0 : -1;
}

static int nostat_type_walk(void)
{
    char *paths[] = { ROOT, NULL };
    FTS *fts = fts_open(paths,
                        FTS_PHYSICAL | FTS_NOCHDIR | FTS_NOSTAT_TYPE,
                        NULL);
    FTSENT *entry;
    int records = 0, directories = 0, files = 0, symlinks = 0;
    int defaults = 0, nsok = 0, statp = 0;
    int public_options;
    if (!fts) {
        printf("nostat-type open failed errno=%d\n", errno);
        return -1;
    }
    public_options = fts->fts_options;
    errno = 0;
    while ((entry = fts_read(fts)) != NULL) {
        records++;
        if (entry->fts_statp) statp++;
        switch (entry->fts_info) {
        case FTS_D:
        case FTS_DP:      directories++; break;
        case FTS_F:       files++; break;
        case FTS_SL:      symlinks++; break;
        case FTS_DEFAULT: defaults++; break;
        case FTS_NSOK:    nsok++; break;
        default: break;
        }
    }
    if (errno != 0 || fts_close(fts) < 0) {
        printf("nostat-type traversal failed errno=%d\n", errno);
        return -1;
    }
    printf("nostat-type options=0x%x records=%d dirs=%d files=%d symlinks=%d default=%d nsok=%d statp=%d\n",
           public_options, records, directories, files, symlinks, defaults,
           nsok, statp);
    return 0;
}

static int comfollowdir_walk(void)
{
    char *paths[] = {
        ROOT "/link-to-leaf", ROOT "/dangling", ROOT "/link-to-dir", NULL
    };
    FTS *fts = fts_open(paths,
                        FTS_PHYSICAL | FTS_NOCHDIR | FTS_COMFOLLOWDIR,
                        simple_fts_name);
    FTSENT *entry;
    int records = 0, directories = 0, files = 0, symlinks = 0;
    int dangling = 0, public_options;
    if (!fts) {
        printf("comfollowdir open failed errno=%d\n", errno);
        return -1;
    }
    public_options = fts->fts_options;
    printf("comfollowdir order=");
    errno = 0;
    while ((entry = fts_read(fts)) != NULL) {
        printf(" [%s:%s]", relative_path(entry->fts_path),
               info_name(entry->fts_info));
        records++;
        if (entry->fts_info == FTS_D || entry->fts_info == FTS_DP)
            directories++;
        else if (entry->fts_info == FTS_F) files++;
        else if (entry->fts_info == FTS_SL) symlinks++;
        else if (entry->fts_info == FTS_SLNONE) dangling++;
    }
    putchar('\n');
    if (errno != 0 || fts_close(fts) < 0) {
        printf("comfollowdir traversal failed errno=%d\n", errno);
        return -1;
    }
    printf("comfollowdir options=0x%x records=%d dirs=%d files=%d symlinks=%d dangling=%d\n",
           public_options, records, directories, files, symlinks, dangling);
    return 0;
}

static int pre_read_roots(void)
{
    char *paths[] = {
        ROOT "/nested/leaf.txt", ROOT "/alpha.txt", NULL
    };
    FTS *fts = fts_open(paths, FTS_PHYSICAL | FTS_NOCHDIR,
                        simple_fts_name);
    FTSENT *entry;
    int count = 0, pathlen_zero = 0, parent_level = 0;
    int public_child_null, records = 0, roundtrip = 0;
    if (!fts) {
        printf("pre-read open failed errno=%d\n", errno);
        return -1;
    }
    entry = fts_children(fts, 0);
    public_child_null = fts->fts_child == NULL;
    for (; entry; entry = entry->fts_link) {
        count++;
        if (entry->fts_pathlen == 0) pathlen_zero++;
        if (entry->fts_parent && entry->fts_parent->fts_level == -1)
            parent_level++;
        if (strstr(entry->fts_name, "alpha.txt") != NULL) {
            entry->fts_number = 909;
            entry->fts_pointer = (void *)(uintptr_t)0x9090;
        }
    }
    errno = 0;
    while ((entry = fts_read(fts)) != NULL) {
        records++;
        if (strcmp(entry->fts_name, "alpha.txt") == 0 &&
            entry->fts_number == 909 &&
            entry->fts_pointer == (void *)(uintptr_t)0x9090)
            roundtrip++;
    }
    if (errno != 0 || fts_close(fts) < 0) {
        printf("pre-read traversal failed errno=%d\n", errno);
        return -1;
    }
    printf("pre-read roots=%d public-child=%s pathlen-zero=%d parent-level=%d records=%d roundtrip=%s\n",
           count, public_child_null ? "null" : "STALE", pathlen_zero,
           parent_level, records, roundtrip == 1 ? "preserved" : "LOST");
    return 0;
}

static int followed_symlink(void)
{
    char *paths[] = { ROOT "/link-to-dir", NULL };
    FTS *fts = fts_open(paths, FTS_PHYSICAL, NULL);
    FTSENT *entry;
    int records = 0, followed = 0, preorder = 0, postorder = 0;
    int preorder_symfd = 999, postorder_symfd = 998, postorder_flags = 0;
    int stream_device_zero = 0;
    if (!fts) {
        printf("follow open failed errno=%d\n", errno);
        return -1;
    }
    errno = 0;
    while ((entry = fts_read(fts)) != NULL) {
        records++;
        if (entry->fts_level == 0 && entry->fts_info == FTS_SL) {
            if (fts->fts_dev == 0) stream_device_zero++;
            if (fts_set(fts, entry, FTS_FOLLOW) != 0) {
                printf("follow set failed errno=%d\n", errno);
                fts_close(fts);
                return -1;
            }
            followed++;
        } else if (entry->fts_level == 0 && entry->fts_info == FTS_D) {
            if (fts->fts_dev == 0) stream_device_zero++;
            if ((entry->fts_flags & FTS_SYMFOLLOW) && entry->fts_symfd >= 0) {
                preorder_symfd = entry->fts_symfd;
                preorder++;
            }
        } else if (entry->fts_level == 0 && entry->fts_info == FTS_DP) {
            if (fts->fts_dev == 0) stream_device_zero++;
            postorder_symfd = entry->fts_symfd;
            postorder_flags = entry->fts_flags;
            if ((entry->fts_flags & FTS_SYMFOLLOW) &&
                postorder_symfd == preorder_symfd &&
                postorder_symfd >= 0) postorder++;
        }
    }
    if (errno != 0 || fts_close(fts) < 0) {
        printf("follow traversal failed errno=%d\n", errno);
        return -1;
    }
    printf("follow records=%d set=%d preorder=%s postorder=%s flags=%s stream-dev=%s\n",
           records, followed, preorder == 1 ? "active" : "BAD",
           postorder == 1 ? "retained" : "BAD",
           (postorder_flags & FTS_SYMFOLLOW) ? "symfollow" : "BAD",
           stream_device_zero == 3 ? "zero" : "BAD");
    return followed == 1 && preorder == 1 && postorder == 1 &&
        stream_device_zero == 3 ? 0 : -1;
}

static int repeated_children_generation(void)
{
    char *paths[] = { ROOT "/skip", NULL };
    FTS *fts = fts_open(paths, FTS_PHYSICAL | FTS_NOCHDIR, NULL);
    FTSENT *root, *first, *second;
    int reset;
    if (!fts) {
        printf("repeat-children open failed errno=%d\n", errno);
        return -1;
    }
    root = fts_read(fts);
    if (!root || root->fts_info != FTS_D) {
        printf("repeat-children root failed errno=%d\n", errno);
        fts_close(fts);
        return -1;
    }
    first = fts_children(fts, 0);
    if (!first || first->fts_link ||
        strcmp(first->fts_name, "hidden.txt") != 0) {
        puts("repeat-children first list failed");
        fts_close(fts);
        return -1;
    }
    first->fts_number = 313;
    first->fts_pointer = (void *)(uintptr_t)0x313;
    second = fts_children(fts, 0);
    if (!second || second->fts_link ||
        strcmp(second->fts_name, "hidden.txt") != 0) {
        puts("repeat-children second list failed");
        fts_close(fts);
        return -1;
    }
    reset = second->fts_number == 0 && second->fts_pointer == NULL;
    if (fts_close(fts) < 0) return -1;
    printf("repeat-children generations=2 replacement=%s\n",
           reset ? "fresh" : "LEAKED");
    return reset ? 0 : -1;
}

static int directory_again_generation(void)
{
    char *paths[] = { ROOT "/skip", NULL };
    FTS *fts = fts_open(paths, FTS_PHYSICAL | FTS_NOCHDIR, NULL);
    FTSENT *entry;
    int pass = 1, first = 0, second = 0, reset = 0;
    if (!fts) {
        printf("again open failed errno=%d\n", errno);
        return -1;
    }
    errno = 0;
    while ((entry = fts_read(fts)) != NULL) {
        if (entry->fts_level == 1 && entry->fts_info == FTS_F &&
            strcmp(entry->fts_name, "hidden.txt") == 0) {
            if (pass == 1) {
                first++;
                entry->fts_number = 717;
                entry->fts_pointer = (void *)(uintptr_t)0x717;
            } else {
                second++;
                if (entry->fts_number == 0 && entry->fts_pointer == NULL)
                    reset++;
            }
        }
        if (entry->fts_level == 0 && entry->fts_info == FTS_DP &&
            pass == 1) {
            if (fts_set(fts, entry, FTS_AGAIN) != 0) {
                printf("again set failed errno=%d\n", errno);
                fts_close(fts);
                return -1;
            }
            pass = 2;
        }
    }
    if (errno != 0 || fts_close(fts) < 0) {
        printf("again traversal failed errno=%d\n", errno);
        return -1;
    }
    printf("again passes=%d first=%d second=%d descendant=%s\n",
           pass, first, second, reset == 1 ? "fresh" : "LEAKED");
    return pass == 2 && first == 1 && second == 1 && reset == 1 ? 0 : -1;
}

static int stream_device_roots(void)
{
    char *paths[] = { ROOT, ROOT "/alpha.txt", NULL };
    FTS *fts = fts_open(paths, FTS_PHYSICAL | FTS_NOCHDIR, NULL);
    FTSENT *entry;
    int directory = 0, postorder = 0, file = 0, records = 0;
    if (!fts) {
        printf("stream-dev open failed errno=%d\n", errno);
        return -1;
    }
    errno = 0;
    while ((entry = fts_read(fts)) != NULL) {
        records++;
        if (entry->fts_level == 0 && entry->fts_info == FTS_D) {
            if (fts->fts_dev != 0 && fts->fts_dev == entry->fts_dev)
                directory++;
            if (fts_set(fts, entry, FTS_SKIP) != 0) {
                printf("stream-dev skip failed errno=%d\n", errno);
                fts_close(fts);
                return -1;
            }
        } else if (entry->fts_level == 0 && entry->fts_info == FTS_DP) {
            if (fts->fts_dev != 0) postorder++;
        } else if (entry->fts_level == 0 && entry->fts_info == FTS_F &&
                   strcmp(entry->fts_name, "alpha.txt") == 0) {
            if (fts->fts_dev == 0) file++;
        }
    }
    if (errno != 0 || fts_close(fts) < 0) {
        printf("stream-dev traversal failed errno=%d\n", errno);
        return -1;
    }
    printf("stream-device roots records=%d directory=%s postorder=%s file=%s\n",
           records, directory == 1 ? "set" : "BAD",
           postorder == 1 ? "retained" : "BAD",
           file == 1 ? "zero" : "BAD");
    return records == 3 && directory == 1 && postorder == 1 && file == 1
        ? 0 : -1;
}

int main(void)
{
    int rc = 0;
    printf("FTS=%zu FTSENT=%zu\n", sizeof(FTS), sizeof(FTSENT));
    printf("offset level=%zu info=%zu flags=%zu instr=%zu statp=%zu name=%zu\n",
           __builtin_offsetof(FTSENT, fts_level),
           __builtin_offsetof(FTSENT, fts_info),
           __builtin_offsetof(FTSENT, fts_flags),
           __builtin_offsetof(FTSENT, fts_instr),
           __builtin_offsetof(FTSENT, fts_statp),
           __builtin_offsetof(FTSENT, fts_name));
    if (make_tree() < 0) {
        printf("tree setup failed errno=%d\n", errno);
        return 1;
    }
    errno = 0;
    if (physical_walk() < 0) rc = 1;
    errno = 0;
    if (!rc && nostat_walk() < 0) rc = 1;
    errno = 0;
    if (!rc && comparator_walk() < 0) rc = 1;
    errno = 0;
    if (!rc && nameonly_children(0) < 0) rc = 1;
    errno = 0;
    if (!rc && nameonly_children(1) < 0) rc = 1;
    errno = 0;
    if (!rc && logical_surface() < 0) rc = 1;
    errno = 0;
    if (!rc && invalid_options() < 0) rc = 1;
    errno = 0;
    if (!rc && nostat_type_walk() < 0) rc = 1;
    errno = 0;
    if (!rc && comfollowdir_walk() < 0) rc = 1;
    errno = 0;
    if (!rc && pre_read_roots() < 0) rc = 1;
    errno = 0;
    if (!rc && followed_symlink() < 0) rc = 1;
    errno = 0;
    if (!rc && repeated_children_generation() < 0) rc = 1;
    errno = 0;
    if (!rc && directory_again_generation() < 0) rc = 1;
    errno = 0;
    if (!rc && stream_device_roots() < 0) rc = 1;
    if (cleanup() < 0) {
        printf("tree cleanup failed errno=%d\n", errno);
        rc = 1;
    }
    puts(rc ? "FAILED" : "done");
    return rc;
}
