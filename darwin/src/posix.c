/* posix.c -- the parts of libSystem where "forward it to glibc" is wrong.
 *
 * Three translations live here, each of them measured rather than assumed
 * (docs/ABI.md, and scripts/gen_errno_table.sh which re-takes the measurement):
 *
 *   errno   54 of the 87 errno names common to both systems have different
 *           values. EAGAIN is 35 on Darwin and 11 on Linux; EDEADLK is 11 on
 *           Darwin and 35 on Linux -- they are exactly each other's. The guest
 *           compiled Darwin's numbers into its own code, so `if (errno ==
 *           EAGAIN)` in a guest is a comparison against 35 and nothing else.
 *
 *   O_*     ten of thirteen open() flags differ, and the collisions are the
 *           dangerous kind: Darwin's O_CREAT (0x0200) is Linux's O_TRUNC.
 *           Passing the guest's flag word through does not report a different
 *           error, it performs a different operation.
 *
 *   stat    144 bytes on Darwin against 128 on Linux, with st_mode and
 *           st_nlink 16-bit on Darwin and 32-bit on Linux, and every field
 *           after st_ino at a different offset.
 *
 * The errno protocol is the subtle one. Darwin's errno is `(*__error())`, so
 * every read AND every write in the guest is a call into us. We keep the
 * guest's errno in our own per-thread slot and bracket every erroring call:
 *
 *     mr_errno_in()    guest slot -> glibc errno   (before the call)
 *     <the glibc call>
 *     mr_errno_out()   glibc errno -> guest slot   (after it)
 *
 * Doing only the second half would break the classic idiom
 *     errno = 0; v = strtol(s, ...); if (errno == ERANGE) ...
 * because the guest's `errno = 0` lands in our slot, glibc never sees it, and
 * a stale glibc errno gets translated back on top of the guest's clear.
 */
#include "dsys.h"
#include "errno_table.h"

/* --------------------------------------------------------- the errno slot */

/* Per-thread, through a pthread key rather than a __thread variable: TLV
 * descriptors in our own dylib would make libSystem depend on the very loader
 * machinery it is being loaded by. A key costs one call and no bootstrap. */
static unsigned err_key;
static int err_key_state;      /* 0 = none, 1 = building, 2 = ready */
static int err_main_slot;      /* before the key exists, and if it cannot be made */

static void errno_key_init(void)
{
    int expect = 0;
    if (__atomic_load_n(&err_key_state, __ATOMIC_ACQUIRE) == 2) return;
    if (__atomic_compare_exchange_n(&err_key_state, &expect, 1, 0,
                                    __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE)) {
        if (glibc_pthread_key_create(&err_key, glibc_free) != 0)
            mr_bail("pthread_key_create failed while setting up errno");
        __atomic_store_n(&err_key_state, 2, __ATOMIC_RELEASE);
        return;
    }
    while (__atomic_load_n(&err_key_state, __ATOMIC_ACQUIRE) != 2)
        glibc_sched_yield();
}

HIDDEN int *mr_errno_slot(void)
{
    int *p;
    errno_key_init();
    p = glibc_pthread_getspecific(err_key);
    if (!p) {
        p = glibc_malloc(sizeof(int));
        if (!p) return &err_main_slot;      /* out of memory reporting errno */
        *p = 0;
        glibc_pthread_setspecific(err_key, p);
    }
    return p;
}

/* ===================================================================== *
 * The password database. Same class as struct dirent, and worse where it
 * counts: the two layouts AGREE for four fields and then diverge, so a
 * forwarded struct looks right exactly long enough to be trusted.
 *
 *   Darwin field   off   what it would actually read out of glibc's 48 bytes
 *   pw_name          0   pw_name        <- agrees
 *   pw_passwd        8   pw_passwd      <- agrees
 *   pw_uid          16   pw_uid         <- agrees
 *   pw_gid          20   pw_gid         <- agrees
 *   pw_change       24   pw_gecos       (a char* read as a time_t)
 *   pw_class        32   pw_dir         (the home directory, as the class)
 *   pw_gecos        40   pw_shell       (the shell, as the full name)
 *   pw_dir          48   PAST THE END   <- out-of-bounds read
 *   pw_shell        56   PAST THE END
 *   pw_expire       64   PAST THE END
 *
 * Measured on macOS 26.5.2 (72 bytes) and in the test-bed image (48). The
 * field a caller almost always wants is pw_dir -- "where is the home
 * directory", which is exactly what CoreFoundation asks for -- and it is the
 * first one to fall off the end of the allocation.
 *
 * glibc has no pw_change, pw_class or pw_expire. Darwin's neutral values are
 * 0, "" and 0: no forced password change, no login class, no expiry. Those are
 * answers rather than filler -- a Linux account genuinely has none of them.
 *
 * The strings are glibc's and live until the next call to the same function,
 * which is the contract on BOTH systems, so they cross unchanged. Only the
 * struct is rebuilt. ===================================================== */
struct darwin_passwd {
    char       *pw_name;
    char       *pw_passwd;
    unsigned    pw_uid;
    unsigned    pw_gid;
    long        pw_change;
    char       *pw_class;
    char       *pw_gecos;
    char       *pw_dir;
    char       *pw_shell;
    long        pw_expire;
};
_Static_assert(sizeof(struct darwin_passwd) == 72, "Darwin struct passwd is 72 bytes");
_Static_assert(__builtin_offsetof(struct darwin_passwd, pw_gecos) == 40, "pw_gecos at 40");
_Static_assert(__builtin_offsetof(struct darwin_passwd, pw_dir)   == 48, "pw_dir at 48");
_Static_assert(__builtin_offsetof(struct darwin_passwd, pw_shell) == 56, "pw_shell at 56");

/* Our mirror of glibc's. sdk/tests/glibc_abi_probe.c pins these against the
 * REAL header -- this declaration alone would only pin itself, which is the
 * mistake the linux_stat assertion below made for months. */
struct linux_passwd {
    char       *pw_name;
    char       *pw_passwd;
    unsigned    pw_uid;
    unsigned    pw_gid;
    char       *pw_gecos;
    char       *pw_dir;
    char       *pw_shell;
};
_Static_assert(sizeof(struct linux_passwd) == 48, "our mirror of glibc's struct passwd is 48 bytes");

static char pw_empty_class[] = "";

static void passwd_l2d(const struct linux_passwd *l, struct darwin_passwd *d)
{
    d->pw_name   = l->pw_name;
    d->pw_passwd = l->pw_passwd;
    d->pw_uid    = l->pw_uid;
    d->pw_gid    = l->pw_gid;
    d->pw_gecos  = l->pw_gecos;
    d->pw_dir    = l->pw_dir;
    d->pw_shell  = l->pw_shell;
    d->pw_change = 0;                 /* no forced change: Linux has no field */
    d->pw_class  = pw_empty_class;    /* no login class */
    d->pw_expire = 0;                 /* no expiry */
}

/* Darwin returns a pointer to static storage the next call overwrites, and so
 * does glibc, so one static IS the contract rather than a shortcut. */
static struct darwin_passwd pw_static;

EXPORT void *getpwnam(const char *name)
{
    struct linux_passwd *l = MR_ERRNO_CALL(glibc_getpwnam(name));
    if (!l) return 0;
    passwd_l2d(l, &pw_static);
    return &pw_static;
}

EXPORT void *getpwuid(unsigned uid)
{
    struct linux_passwd *l = MR_ERRNO_CALL(glibc_getpwuid(uid));
    if (!l) return 0;
    passwd_l2d(l, &pw_static);
    return &pw_static;
}

/* The _r forms hand us the CALLER's struct, which is Darwin-shaped and 72
 * bytes. glibc must not write into it -- that is the 48-into-72 direction of
 * the same bug, and it would leave pw_dir/pw_shell/pw_expire holding whatever
 * was on the caller's stack. glibc fills a mirror of ours and we translate.
 * The strings land in the caller's buffer either way, which is what keeps the
 * pointers valid after we return. */
EXPORT int getpwnam_r(const char *name, struct darwin_passwd *out,
                      char *buf, unsigned long buflen, struct darwin_passwd **result)
{
    struct linux_passwd l;
    void *found = 0;
    int rc = MR_ERRNO_CALL(glibc_getpwnam_r(name, &l, buf, buflen, &found));
    if (result) *result = 0;
    if (rc != 0) return mr_pthread_rc(rc);   /* _r reports errno by return */
    if (!found) return 0;                    /* no such user: rc 0, *result NULL */
    passwd_l2d(&l, out);
    if (result) *result = out;
    return 0;
}

EXPORT int getpwuid_r(unsigned uid, struct darwin_passwd *out,
                      char *buf, unsigned long buflen, struct darwin_passwd **result)
{
    struct linux_passwd l;
    void *found = 0;
    int rc = MR_ERRNO_CALL(glibc_getpwuid_r(uid, &l, buf, buflen, &found));
    if (result) *result = 0;
    if (rc != 0) return mr_pthread_rc(rc);
    if (!found) return 0;
    passwd_l2d(&l, out);
    if (result) *result = out;
    return 0;
}

static int darwin_from_linux_errno(int e)
{
    if (e >= 0 && e < MR_ERRNO_L2D_N && mr_errno_l2d[e] >= 0)
        return mr_errno_l2d[e];
    return e == 0 ? 0 : -e;   /* negative: "a Linux errno with no Darwin twin" */
}

static int linux_from_darwin_errno(int e)
{
    if (e >= 0 && e < MR_ERRNO_D2L_N && mr_errno_d2l[e] >= 0)
        return mr_errno_d2l[e];
    if (e < 0) return -e;     /* the untranslatable value, coming back */
    return e;
}

/* pthread is the one family that returns its error as the RETURN VALUE rather
 * than through errno, so the errno table has to be reachable from libsystem.c
 * too. Nothing else needs this. */
HIDDEN int mr_pthread_rc(int linux_rc)
{
    return linux_rc == 0 ? 0 : darwin_from_linux_errno(linux_rc);
}

HIDDEN void mr_errno_in(void)  { *glibc___errno_location() = linux_from_darwin_errno(*mr_errno_slot()); }
HIDDEN void mr_errno_out(void) { *mr_errno_slot() = darwin_from_linux_errno(*glibc___errno_location()); }

/* Darwin spells errno `(*__error())`. This is the whole of the guest's access
 * to it -- reads and writes both. */
EXPORT int *__error(void) { return mr_errno_slot(); }
EXPORT int *__errno_location(void) { return mr_errno_slot(); }

/* ---------------------------------------------------------- open(2) flags */

/* Measured 2026-08-25; docs/ABI.md §"open flags". Darwin on the left. */
#define D_O_RDONLY    0x0000
#define D_O_WRONLY    0x0001
#define D_O_RDWR      0x0002
#define D_O_ACCMODE   0x0003
#define D_O_NONBLOCK  0x0004
#define D_O_APPEND    0x0008
#define D_O_SHLOCK    0x0010
#define D_O_EXLOCK    0x0020
#define D_O_ASYNC     0x0040
#define D_O_SYNC      0x0080
#define D_O_NOFOLLOW  0x0100
#define D_O_CREAT     0x0200
#define D_O_TRUNC     0x0400
#define D_O_EXCL      0x0800
#define D_O_EVTONLY   0x8000
#define D_O_NOCTTY    0x20000
#define D_O_DIRECTORY 0x100000
#define D_O_SYMLINK   0x200000
#define D_O_DSYNC     0x400000
#define D_O_CLOEXEC   0x1000000

#define L_O_NONBLOCK  0x000800
#define L_O_APPEND    0x000400
#define L_O_SYNC      0x101000
#define L_O_DSYNC     0x001000
#define L_O_ASYNC     0x002000
#define L_O_NOFOLLOW  0x008000
#define L_O_CREAT     0x000040
#define L_O_TRUNC     0x000200
#define L_O_EXCL      0x000080
#define L_O_NOCTTY    0x000100
#define L_O_DIRECTORY 0x004000
#define L_O_CLOEXEC   0x080000

static int linux_open_flags(int d)
{
    int l = d & D_O_ACCMODE;          /* RDONLY/WRONLY/RDWR agree, 0/1/2 */
    int rest = d & ~D_O_ACCMODE;

#define MAP(dbit, lbit) do { if (rest & (dbit)) { l |= (lbit); rest &= ~(dbit); } } while (0)
    MAP(D_O_NONBLOCK,  L_O_NONBLOCK);
    MAP(D_O_APPEND,    L_O_APPEND);
    MAP(D_O_ASYNC,     L_O_ASYNC);
    MAP(D_O_SYNC,      L_O_SYNC);
    MAP(D_O_DSYNC,     L_O_DSYNC);
    MAP(D_O_NOFOLLOW,  L_O_NOFOLLOW);
    MAP(D_O_CREAT,     L_O_CREAT);
    MAP(D_O_TRUNC,     L_O_TRUNC);
    MAP(D_O_EXCL,      L_O_EXCL);
    MAP(D_O_NOCTTY,    L_O_NOCTTY);
    MAP(D_O_DIRECTORY, L_O_DIRECTORY);
    MAP(D_O_CLOEXEC,   L_O_CLOEXEC);
    /* O_SHLOCK/O_EXLOCK (BSD flock-on-open), O_EVTONLY and O_SYMLINK have no
     * Linux equivalent. Dropping them would silently change the semantics the
     * caller asked for, so we refuse instead. */
    MAP(D_O_SHLOCK,  0); MAP(D_O_EXLOCK, 0); MAP(D_O_EVTONLY, 0); MAP(D_O_SYMLINK, 0);
#undef MAP
    if (rest)
        mr_bail("open(): a Darwin O_* flag with no Linux equivalent was requested "
                "(O_SHLOCK/O_EXLOCK/O_EVTONLY/O_SYMLINK or an unknown bit)");
    return l;
}

EXPORT int open(const char *path, int flags, ...)
{
    unsigned mode = 0;
    if (flags & D_O_CREAT) {
        va_list ap;
        va_start(ap, flags);
        mode = va_arg(ap, unsigned);
        va_end(ap);
    }
    return MR_ERRNO_CALL(glibc_open(path, linux_open_flags(flags), mode));
}

/* The compiler lowers open() with a mode argument to _open in Darwin's
 * headers; the $NOCANCEL variants come from the same header for code compiled
 * against the modern SDK. Same function, different symbol. */
EXPORT int mr_open_nocancel(const char *path, int flags, ...) __asm__("_open$NOCANCEL");
EXPORT int mr_open_nocancel(const char *path, int flags, ...)
{
    unsigned mode = 0;
    if (flags & D_O_CREAT) {
        va_list ap;
        va_start(ap, flags);
        mode = va_arg(ap, unsigned);
        va_end(ap);
    }
    return MR_ERRNO_CALL(glibc_open(path, linux_open_flags(flags), mode));
}

/* ------------------------------------------------------------ struct stat */

/* Darwin, arm64, __DARWIN_64_BIT_INO_T. Offsets measured, not guessed. */
struct darwin_stat {
    int32_t  st_dev;            /*   0 */
    uint16_t st_mode;           /*   4 */
    uint16_t st_nlink;          /*   6 */
    uint64_t st_ino;            /*   8 */
    uint32_t st_uid;            /*  16 */
    uint32_t st_gid;            /*  20 */
    int32_t  st_rdev;           /*  24 */
    int32_t  __pad0;            /*  28 */
    long     st_atime_sec,  st_atime_nsec;   /*  32 */
    long     st_mtime_sec,  st_mtime_nsec;   /*  48 */
    long     st_ctime_sec,  st_ctime_nsec;   /*  64 */
    long     st_btime_sec,  st_btime_nsec;   /*  80 */
    int64_t  st_size;           /*  96 */
    int64_t  st_blocks;         /* 104 */
    int32_t  st_blksize;        /* 112 */
    uint32_t st_flags;          /* 116 */
    uint32_t st_gen;            /* 120 */
    int32_t  st_lspare;         /* 124 */
    int64_t  st_qspare[2];      /* 128 */
};                              /* 144 */

/* Linux, aarch64 (asm-generic/stat.h). Also measured. */
struct linux_stat {
    unsigned long st_dev;       /*   0 */
    unsigned long st_ino;       /*   8 */
    unsigned int  st_mode;      /*  16 */
    unsigned int  st_nlink;     /*  20 */
    unsigned int  st_uid;       /*  24 */
    unsigned int  st_gid;       /*  28 */
    unsigned long st_rdev;      /*  32 */
    unsigned long __pad1;       /*  40 */
    long          st_size;      /*  48 */
    int           st_blksize;   /*  56 */
    int           __pad2;       /*  60 */
    long          st_blocks;    /*  64 */
    long st_atime_sec; unsigned long st_atime_nsec;   /*  72 */
    long st_mtime_sec; unsigned long st_mtime_nsec;   /*  88 */
    long st_ctime_sec; unsigned long st_ctime_nsec;   /* 104 */
    unsigned int  __unused_[2]; /* 120 */
};                              /* 128 */

_Static_assert(sizeof(struct darwin_stat) == 144, "Darwin struct stat is 144 bytes");
_Static_assert(sizeof(struct linux_stat) == 128, "Linux aarch64 struct stat is 128 bytes");
_Static_assert(__builtin_offsetof(struct darwin_stat, st_size) == 96, "st_size at 96");
_Static_assert(__builtin_offsetof(struct linux_stat, st_size) == 48, "st_size at 48");

static void stat_l2d(const struct linux_stat *l, struct darwin_stat *d)
{
    glibc_memset(d, 0, sizeof *d);
    d->st_dev   = (int32_t)l->st_dev;
    d->st_mode  = (uint16_t)l->st_mode;    /* S_IF* and the permission bits
                                            * agree; only the width differs */
    d->st_nlink = (uint16_t)l->st_nlink;
    d->st_ino   = l->st_ino;
    d->st_uid   = l->st_uid;
    d->st_gid   = l->st_gid;
    d->st_rdev  = (int32_t)l->st_rdev;
    d->st_atime_sec = l->st_atime_sec; d->st_atime_nsec = (long)l->st_atime_nsec;
    d->st_mtime_sec = l->st_mtime_sec; d->st_mtime_nsec = (long)l->st_mtime_nsec;
    d->st_ctime_sec = l->st_ctime_sec; d->st_ctime_nsec = (long)l->st_ctime_nsec;
    /* Linux has no birth time in this struct; statx does. Darwin programs read
     * st_birthtimespec, so give them the ctime rather than a zero that would
     * date every file to 1970. */
    d->st_btime_sec = l->st_ctime_sec; d->st_btime_nsec = (long)l->st_ctime_nsec;
    d->st_size    = l->st_size;
    d->st_blocks  = l->st_blocks;
    d->st_blksize = l->st_blksize;
}

EXPORT int stat(const char *path, struct darwin_stat *out)
{
    struct linux_stat ls;
    int rc = MR_ERRNO_CALL(glibc_stat(path, &ls));
    if (rc == 0) stat_l2d(&ls, out);
    return rc;
}

EXPORT int lstat(const char *path, struct darwin_stat *out)
{
    struct linux_stat ls;
    int rc = MR_ERRNO_CALL(glibc_lstat(path, &ls));
    if (rc == 0) stat_l2d(&ls, out);
    return rc;
}

EXPORT int fstat(int fd, struct darwin_stat *out)
{
    struct linux_stat ls;
    int rc = MR_ERRNO_CALL(glibc_fstat(fd, &ls));
    if (rc == 0) stat_l2d(&ls, out);
    return rc;
}

/* macOS's headers rename these to the $INODE64 symbols on x86_64 only; on
 * arm64 the plain names are what the linker emits (verified: `nm -u` on
 * tests/bin/13_errno lists _stat and _fstat). The aliases are here anyway so
 * an x86_64-built object that made it into a fat file still resolves. */
EXPORT int mr_stat64(const char *p, struct darwin_stat *o)  __asm__("_stat$INODE64");
EXPORT int mr_stat64(const char *p, struct darwin_stat *o)  { return stat(p, o); }
EXPORT int mr_lstat64(const char *p, struct darwin_stat *o) __asm__("_lstat$INODE64");
EXPORT int mr_lstat64(const char *p, struct darwin_stat *o) { return lstat(p, o); }
EXPORT int mr_fstat64(int fd, struct darwin_stat *o)        __asm__("_fstat$INODE64");
EXPORT int mr_fstat64(int fd, struct darwin_stat *o)        { return fstat(fd, o); }

/* ------------------------------------------------------------- the rest of
 * the file surface. Every one of these is bracketed for errno; that is the
 * only reason they are not one-line forwarders. */

EXPORT ssize_t read(int fd, void *b, size_t n)        { return MR_ERRNO_CALL(glibc_read(fd, b, n)); }
EXPORT ssize_t write(int fd, const void *b, size_t n) { return MR_ERRNO_CALL(glibc_write(fd, b, n)); }
EXPORT int     close(int fd)                          { return MR_ERRNO_CALL(glibc_close(fd)); }
EXPORT off_t   lseek(int fd, off_t off, int whence)   { return MR_ERRNO_CALL(glibc_lseek(fd, off, whence)); }
EXPORT int     mkdir(const char *p, unsigned m)       { return MR_ERRNO_CALL(glibc_mkdir(p, m)); }
EXPORT int     rmdir(const char *p)                   { return MR_ERRNO_CALL(glibc_rmdir(p)); }
EXPORT int     unlink(const char *p)                  { return MR_ERRNO_CALL(glibc_unlink(p)); }
EXPORT int     rename(const char *a, const char *b)   { return MR_ERRNO_CALL(glibc_rename(a, b)); }
EXPORT int     access(const char *p, int m)           { return MR_ERRNO_CALL(glibc_access(p, m)); }
EXPORT int     chmod(const char *p, unsigned m)       { return MR_ERRNO_CALL(glibc_chmod(p, m)); }
EXPORT int     symlink(const char *a, const char *b)  { return MR_ERRNO_CALL(glibc_symlink(a, b)); }
EXPORT ssize_t readlink(const char *p, char *b, size_t n) { return MR_ERRNO_CALL(glibc_readlink(p, b, n)); }
EXPORT int     ftruncate(int fd, off_t n)             { return MR_ERRNO_CALL(glibc_ftruncate(fd, n)); }
EXPORT int     fsync(int fd)                          { return MR_ERRNO_CALL(glibc_fsync(fd)); }
EXPORT int     dup(int fd)                            { return MR_ERRNO_CALL(glibc_dup(fd)); }
EXPORT int     dup2(int a, int b)                     { return MR_ERRNO_CALL(glibc_dup2(a, b)); }
/* pipe(2) writes two descriptors into an int[2] the guest owns. int is 4 bytes
 * on both, the array is the guest's, and there are no flags -- so this is a
 * plain forward and stays one. pipe2's flags word is NOT, which is why it is
 * absent: O_NONBLOCK and O_CLOEXEC are among the ten open() flags that differ,
 * so it would need open()'s translation and nothing has asked for it yet. */
EXPORT int     pipe(int fds[2])                       { return MR_ERRNO_CALL(glibc_pipe(fds)); }
EXPORT int     isatty(int fd)                         { return MR_ERRNO_CALL(glibc_isatty(fd)); }
EXPORT char   *getcwd(char *b, size_t n)              { return MR_ERRNO_CALL(glibc_getcwd(b, n)); }
EXPORT int     chdir(const char *p)                   { return MR_ERRNO_CALL(glibc_chdir(p)); }
EXPORT int     mkstemp(char *t)                       { return MR_ERRNO_CALL(glibc_mkstemp(t)); }
EXPORT char   *mkdtemp(char *t)                       { return MR_ERRNO_CALL(glibc_mkdtemp(t)); }
EXPORT int     remove(const char *p)
{
    struct linux_stat ls;
    if (glibc_lstat(p, &ls) == 0 && (ls.st_mode & 0170000) == 0040000)
        return MR_ERRNO_CALL(glibc_rmdir(p));
    return MR_ERRNO_CALL(glibc_unlink(p));
}

/* ------------------------------------------------------ the strtol family
 *
 * Measured 2026-08-25, and the fixture 14_utility is what noticed:
 *
 *     strtol("zz", NULL, 10)   Darwin: errno = EINVAL (22)   Linux: errno = 0
 *     strtoul / strtoll / strtoull / atoi: the same
 *     strtod / strtof:         neither sets it
 *
 * "If no conversion could be performed, 0 is returned and errno is set to
 * EINVAL" is Darwin's documented contract, and a guest that checks it is not
 * being exotic -- it is following the man page it was written against. glibc
 * leaves errno untouched, so forwarding loses the signal entirely. */
#define DARWIN_EINVAL 22

#define STRTO_INT(ret, name, call)                                        \
    EXPORT ret name(const char *s, char **endp, int base)                 \
    {                                                                     \
        char *end = NULL;                                                 \
        ret v;                                                            \
        mr_errno_in();                                                    \
        v = call(s, &end, base);                                          \
        mr_errno_out();                                                   \
        if (endp) *endp = end;                                            \
        if (end == s && *mr_errno_slot() == 0)                            \
            *mr_errno_slot() = DARWIN_EINVAL;                             \
        return v;                                                         \
    }

extern unsigned long long glibc_strtoull(const char *, char **, int) GLIBCSYM(strtoull);

STRTO_INT(long,               strtol,   glibc_strtol)
STRTO_INT(unsigned long,      strtoul,  glibc_strtoul)
STRTO_INT(long long,          strtoll,  glibc_strtoll)
STRTO_INT(unsigned long long, strtoull, glibc_strtoull)
STRTO_INT(long long,          strtoq,   glibc_strtoll)
STRTO_INT(unsigned long long, strtouq,  glibc_strtoull)

EXPORT int  atoi(const char *s) { return (int)strtol(s, NULL, 10); }
EXPORT long atol(const char *s) { return strtol(s, NULL, 10); }
EXPORT long long atoll(const char *s) { return strtoll(s, NULL, 10); }

/* ------------------------------------------------------------- error text */

EXPORT char *strerror(int e)
{
    /* Darwin's own strings, recorded from macOS by scripts/gen_errno_table.sh.
     * Translating the number and asking glibc would be a second guess: the two
     * libcs do not agree on every message. */
    static char unknown[32];
    if (e >= 0 && e < MR_STRERROR_N && mr_strerror_darwin[e])
        return (char *)mr_strerror_darwin[e];
    {
        /* Darwin's format for a number it does not know. */
        char *p = unknown;
        const char *pre = "Unknown error: ";
        int v = e, neg = v < 0;
        char digits[16];
        int n = 0;
        while (*pre) *p++ = *pre++;
        if (neg) { *p++ = '-'; v = -v; }
        do { digits[n++] = (char)('0' + v % 10); v /= 10; } while (v);
        while (n) *p++ = digits[--n];
        *p = 0;
        return unknown;
    }
}

EXPORT int strerror_r(int e, char *buf, size_t len)
{
    const char *s = strerror(e);
    size_t n = glibc_strlen(s);
    if (n + 1 > len) { *mr_errno_slot() = 34 /* Darwin ERANGE */; return 34; }
    glibc_memcpy(buf, s, n + 1);
    return 0;
}

EXPORT void perror(const char *what)
{
    const char *msg = strerror(*mr_errno_slot());
    void *f = glibc_stderr;
    if (what && *what) {
        glibc_fwrite(what, 1, glibc_strlen(what), f);
        glibc_fwrite(": ", 1, 2, f);
    }
    glibc_fwrite(msg, 1, glibc_strlen(msg), f);
    glibc_fwrite("\n", 1, 1, f);
    glibc_fflush(f);
}

/* __assert_rtn -- what Darwin's <assert.h> expands to when NDEBUG is absent.
 *
 * The message text is part of the observable behaviour: a guest's stderr is
 * compared byte-for-byte against macOS, so this reproduces Libc's exact
 * wording, including the "(expr)" parentheses, the trailing full stop, and the
 * two forms (with and without a function name -- Libc omits the clause when
 * __func__ is unavailable, which is what a non-GNUC assert() does).
 *
 * It exists because sdk/usr/include/assert.h is Apple's real header and its
 * non-NDEBUG branch calls this. Everything in this repository compiles with
 * -DNDEBUG, so nothing here reaches it; a guest that does not is exactly the
 * caller this is for. */
static void assert_puts(const char *s)
{
    if (s) glibc_fwrite(s, 1, glibc_strlen(s), glibc_stderr);
}

static void assert_putint(int v)
{
    char buf[16];
    int n = 0;
    unsigned u = v < 0 ? 0u - (unsigned)v : (unsigned)v;
    if (v < 0) glibc_fwrite("-", 1, 1, glibc_stderr);
    do { buf[n++] = (char)('0' + (u % 10)); u /= 10; } while (u);
    while (n) { n--; glibc_fwrite(&buf[n], 1, 1, glibc_stderr); }
}

EXPORT __attribute__((noreturn))
void __assert_rtn(const char *func, const char *file, int line, const char *expr)
{
    assert_puts("Assertion failed: (");
    assert_puts(expr ? expr : "");
    assert_puts("), ");
    if (func) { assert_puts("function "); assert_puts(func); assert_puts(", "); }
    assert_puts("file ");
    assert_puts(file ? file : "");
    assert_puts(", line ");
    assert_putint(line);
    assert_puts(".\n");
    glibc_fflush(glibc_stderr);
    glibc_abort();
    __builtin_unreachable();
}

/* The pre-UNIX03 spelling, still referenced by <assert.h>'s !__GNUC__ branch. */
EXPORT __attribute__((noreturn))
void __assert(const char *expr, const char *file, int line)
{
    __assert_rtn((const char *)0, file, line, expr);
}

/* ------------------------------------------------------------ BSD stringery */

EXPORT void  bzero(void *d, size_t n)                  { glibc_memset(d, 0, n); }
EXPORT void  bcopy(const void *s, void *d, size_t n)   { glibc_memmove(d, s, n); }
EXPORT int   bcmp(const void *a, const void *b, size_t n) { return glibc_memcmp(a, b, n); }
EXPORT char *index(const char *s, int c)               { return glibc_strchr(s, c); }
EXPORT char *rindex(const char *s, int c)              { return glibc_strrchr(s, c); }

/* memset_pattern4/8/16 -- Darwin-only, and glibc has no equivalent to forward
 * to, so this is one of the few places where the userland implements rather
 * than translates. clang's loop idiom recogniser EMITS calls to these for a
 * plain `for (i...) dst[i] = c;` over a non-byte type on an Apple target, so a
 * guest can depend on them without its source ever naming them: vendored
 * quartz reaches _memset_pattern16 from stb_image_write's row filter.
 *
 * Darwin's contract (man memset_pattern): copy the pattern repeatedly over
 * len bytes, TRUNCATING the final copy if len is not a multiple of the pattern
 * size. len is a byte count, not a repeat count. */
static void mr_memset_pattern(void *b, const void *pat, size_t patlen, size_t len)
{
    unsigned char *d = (unsigned char *)b;
    const unsigned char *p = (const unsigned char *)pat;
    while (len >= patlen) { glibc_memcpy(d, p, patlen); d += patlen; len -= patlen; }
    if (len) glibc_memcpy(d, p, len);
}

EXPORT void memset_pattern4(void *b, const void *p, size_t len)  { mr_memset_pattern(b, p, 4, len); }
EXPORT void memset_pattern8(void *b, const void *p, size_t len)  { mr_memset_pattern(b, p, 8, len); }
EXPORT void memset_pattern16(void *b, const void *p, size_t len) { mr_memset_pattern(b, p, 16, len); }

/* ------------------------------------------------------------------ clocks */

/* CLOCK_MONOTONIC is 6 on Darwin and 1 on Linux; passing the guest's id
 * through lands on CLOCK_REALTIME_ALARM, which needs a capability and fails
 * with EPERM. Measured 2026-08-25. */
#define D_CLOCK_REALTIME           0
#define D_CLOCK_MONOTONIC          6
#define D_CLOCK_MONOTONIC_RAW      4
#define D_CLOCK_MONOTONIC_RAW_APPROX 5
#define D_CLOCK_UPTIME_RAW         8
#define D_CLOCK_UPTIME_RAW_APPROX  9
#define D_CLOCK_PROCESS_CPUTIME_ID 12
#define D_CLOCK_THREAD_CPUTIME_ID  16

#define L_CLOCK_REALTIME           0
#define L_CLOCK_MONOTONIC          1
#define L_CLOCK_PROCESS_CPUTIME_ID 2
#define L_CLOCK_THREAD_CPUTIME_ID  3
#define L_CLOCK_MONOTONIC_RAW      4
#define L_CLOCK_BOOTTIME           7

HIDDEN int mr_linux_clock_id(int darwin_id)
{
    switch (darwin_id) {
    case D_CLOCK_REALTIME:             return L_CLOCK_REALTIME;
    case D_CLOCK_MONOTONIC:            return L_CLOCK_MONOTONIC;
    case D_CLOCK_MONOTONIC_RAW:
    case D_CLOCK_MONOTONIC_RAW_APPROX: return L_CLOCK_MONOTONIC_RAW;
    /* Darwin's UPTIME_RAW excludes time asleep; Linux's MONOTONIC does too
     * (BOOTTIME is the one that includes it). */
    case D_CLOCK_UPTIME_RAW:
    case D_CLOCK_UPTIME_RAW_APPROX:    return L_CLOCK_MONOTONIC;
    case D_CLOCK_PROCESS_CPUTIME_ID:   return L_CLOCK_PROCESS_CPUTIME_ID;
    case D_CLOCK_THREAD_CPUTIME_ID:    return L_CLOCK_THREAD_CPUTIME_ID;
    default:
        mr_bail("clock_gettime with an unrecognised Darwin clock id");
    }
}

/* struct timespec and struct timeval have identical layouts on both systems
 * (measured: 16 bytes each, {long,long}), so only the clock id is translated. */
EXPORT int clock_gettime(int clk, void *ts)
{
    return MR_ERRNO_CALL(glibc_clock_gettime(mr_linux_clock_id(clk), ts));
}

EXPORT uint64_t clock_gettime_nsec_np(int clk)
{
    struct { long sec, nsec; } ts = { 0, 0 };
    if (glibc_clock_gettime(mr_linux_clock_id(clk), &ts) != 0) return 0;
    return (uint64_t)ts.sec * 1000000000ull + (uint64_t)ts.nsec;
}

EXPORT int gettimeofday(void *tv, void *tz) { return MR_ERRNO_CALL(glibc_gettimeofday(tv, tz)); }
EXPORT int nanosleep(const void *req, void *rem) { return MR_ERRNO_CALL(glibc_nanosleep(req, rem)); }
EXPORT unsigned sleep(unsigned s) { return glibc_sleep(s); }

/* ---------------------------------------------------------- directories */

/* DIR is opaque on both systems, so the POINTER crosses fine. `struct dirent`
 * does not, and this is the layout half of the opaque-ABI hazard class rather
 * than the size half -- nothing is corrupted, the guest simply reads the wrong
 * bytes and gets wrong filenames.
 *
 *                       Darwin/arm64          glibc/aarch64
 *     sizeof                   1048                     280
 *     d_ino                   0 (8)                   0 (8)
 *     d_seekoff / d_off       8 (8)                   8 (8)
 *     d_reclen               16 (2)                  16 (2)
 *     d_namlen               18 (2)                       -
 *     d_type                 20 (1)                  18 (1)
 *     d_name              21 (1024)                19 (256)
 *
 * Both sides of that table are pinned by tests, not by this comment:
 * sdk/tests/abi_probe.c baselines the Darwin column against Apple's own SDK,
 * and sdk/tests/glibc_abi_probe.c static-asserts the glibc column against real
 * glibc headers with the host compiler.
 *
 * So returning glibc's pointer would be wrong twice over. The guest would read
 * d_type from offset 20 -- inside glibc's d_name -- and read a filename from
 * offset 21, and it would read up to offset 1044 of a 280-byte allocation,
 * which is an out-of-bounds read on someone else's heap. Hence a per-DIR
 * wrapper holding one translated Darwin dirent, refilled on each readdir, with
 * the same lifetime the caller already expects: valid until the next readdir
 * or closedir on that DIR. */

struct linux_dirent {
    uint64_t d_ino;             /*  0 */
    int64_t  d_off;             /*  8 */
    uint16_t d_reclen;          /* 16 */
    uint8_t  d_type;            /* 18 */
    char     d_name[256];       /* 19 */
};

struct darwin_dirent {
    uint64_t d_ino;             /*  0 */
    uint64_t d_seekoff;         /*  8 */
    uint16_t d_reclen;          /* 16 */
    uint16_t d_namlen;          /* 18 */
    uint8_t  d_type;            /* 20 */
    char     d_name[1024];      /* 21 */
};

_Static_assert(sizeof(struct linux_dirent) == 280, "glibc struct dirent is 280 bytes");
_Static_assert(sizeof(struct darwin_dirent) == 1048, "Darwin struct dirent is 1048 bytes");
_Static_assert(__builtin_offsetof(struct linux_dirent,  d_type) == 18, "glibc d_type at 18");
_Static_assert(__builtin_offsetof(struct darwin_dirent, d_type) == 20, "Darwin d_type at 20");
_Static_assert(__builtin_offsetof(struct linux_dirent,  d_name) == 19, "glibc d_name at 19");
_Static_assert(__builtin_offsetof(struct darwin_dirent, d_name) == 21, "Darwin d_name at 21");

struct mr_dir {
    void *ldir;                     /* glibc DIR* */
    struct darwin_dirent ent;       /* refilled per readdir */
};

EXPORT void *opendir(const char *path)
{
    struct mr_dir *d;
    void *ldir = MR_ERRNO_CALL(glibc_opendir(path));
    if (!ldir) return 0;
    d = glibc_calloc(1, sizeof *d);
    if (!d) { glibc_closedir(ldir); return 0; }
    d->ldir = ldir;
    return d;
}

EXPORT void *readdir(void *dirp)
{
    struct mr_dir *d = dirp;
    const struct linux_dirent *l;
    size_t n;

    if (!d) return 0;
    /* glibc signals end-of-directory with NULL and a *preserved* errno, so the
     * errno dance has to not clobber it. MR_ERRNO_CALL pushes the guest's
     * errno in and pulls glibc's back out, which is exactly right here. */
    l = MR_ERRNO_CALL(glibc_readdir(d->ldir));
    if (!l) return 0;

    n = glibc_strlen(l->d_name);
    if (n > sizeof d->ent.d_name - 1) n = sizeof d->ent.d_name - 1;

    glibc_memset(&d->ent, 0, sizeof d->ent);
    d->ent.d_ino     = l->d_ino;
    d->ent.d_seekoff = (uint64_t)l->d_off;
    d->ent.d_type    = l->d_type;          /* DT_* agree on both systems */
    d->ent.d_namlen  = (uint16_t)n;
    glibc_memcpy(d->ent.d_name, l->d_name, n);
    /* Darwin's d_reclen is the size of THIS record, which is what a caller
     * walking a buffer would step by -- not glibc's, whose d_name is shorter. */
    d->ent.d_reclen  = (uint16_t)(__builtin_offsetof(struct darwin_dirent, d_name) + n + 1);
    return &d->ent;
}

EXPORT int closedir(void *dirp)
{
    struct mr_dir *d = dirp;
    int rc;
    if (!d) return 0;
    rc = MR_ERRNO_CALL(glibc_closedir(d->ldir));
    glibc_free(d);
    return rc;
}

EXPORT void rewinddir(void *dirp)
{
    struct mr_dir *d = dirp;
    if (d) glibc_rewinddir(d->ldir);
}

EXPORT int dirfd(void *dirp)
{
    struct mr_dir *d = dirp;
    return d ? MR_ERRNO_CALL(glibc_dirfd(d->ldir)) : -1;
}

/* ------------------------------------------------------------- signals */

/* TWO translations, not one, and the second is the easier to miss.
 *
 * SIZE:   Darwin's sigset_t is a 32-bit bitmask -- bit (signo-1) -- and
 *         glibc's is 128 bytes. A naive forward of pthread_sigmask hands
 *         glibc a 4-byte object to WRITE 128 bytes into, because its third
 *         argument is an OUT parameter. That is the #49 overflow class with a
 *         live consumer rather than a theoretical one.
 *
 * NUMBER: ten of the 29 standard signals have DIFFERENT numbers on the two
 *         systems. A wrapper that widened the mask and stopped there would
 *         compile, link, return 0, and subscribe the guest to the wrong
 *         signals. Measured on this host, darwin/linux:
 *
 *           SIGBUS 10/7    SIGSYS 12/31   SIGURG 16/23   SIGSTOP 17/19
 *           SIGTSTP 18/20  SIGCONT 19/18  SIGCHLD 20/17  SIGIO 23/29
 *           SIGUSR1 30/10  SIGUSR2 31/12
 *
 *         Both columns are pinned by tests rather than by this comment:
 *         sdk/tests/abi_probe.c baselines the Darwin numbers against Apple's
 *         own SDK, and sdk/tests/glibc_abi_probe.c static-asserts the glibc
 *         ones against real glibc headers with the host compiler.
 *
 * The five set manipulators need nothing: Darwin defines them as MACROS over
 * the guest's own 4-byte word (signal.h:125-128), so they never cross the
 * boundary. That is the general rule this file follows -- operations on the
 * guest's OWN object are safe; operations that hand a pointer to that object
 * ACROSS the boundary need translating.
 *
 * glibc's sigset_t is treated as OPAQUE here. We never touch its bits, only
 * hand it to glibc's own sigemptyset/sigaddset/sigismember, so the only thing
 * assumed about it is its size -- which glibc_abi_probe pins. */

#define MR_LINUX_SIGSET_BYTES 128
typedef struct { unsigned char opaque[MR_LINUX_SIGSET_BYTES]; } mr_linux_sigset;

/* Darwin signo (1..31) -> Linux signo. 0 means "no Linux equivalent":
 * SIGEMT (7) and SIGINFO (29) do not exist on Linux. */
static const unsigned char mr_signo_d2l_tab[32] = {
    0,
     1,  2,  3,  4,  5,  6,  0,  8,   /*  1..8   HUP INT QUIT ILL TRAP ABRT EMT FPE */
     9,  7, 11, 31, 13, 14, 15, 23,   /*  9..16  KILL BUS SEGV SYS PIPE ALRM TERM URG */
    19, 20, 18, 17, 21, 22, 29, 24,   /* 17..24  STOP TSTP CONT CHLD TTIN TTOU IO XCPU */
    25, 26, 27, 28,  0, 10, 12        /* 25..31  XFSZ VTALRM PROF WINCH INFO USR1 USR2 */
};

static int mr_signo_d2l(int d)
{
    if (d < 1 || d > 31) return 0;
    return (int)mr_signo_d2l_tab[d];
}

static int mr_signo_l2d(int l)
{
    for (int d = 1; d <= 31; d++)
        if ((int)mr_signo_d2l_tab[d] == l) return d;
    return 0;
}

/* Darwin 32-bit mask -> glibc's opaque set, built with glibc's own primitives
 * so no layout is assumed. A Darwin-only signal (SIGEMT, SIGINFO) has nothing
 * to map to and is dropped: there is no Linux signal it could mean, and
 * inventing one would subscribe the guest to something it never asked for. */
static void mr_sigset_d2l(unsigned int d, mr_linux_sigset *out)
{
    glibc_sigemptyset(out);
    for (int s = 1; s <= 31; s++) {
        int l;
        if (!(d & (1u << (s - 1)))) continue;
        l = mr_signo_d2l(s);
        if (l) glibc_sigaddset(out, l);
    }
}

static unsigned int mr_sigset_l2d(const mr_linux_sigset *l)
{
    unsigned int d = 0;
    for (int s = 1; s <= 31; s++) {
        int ls = mr_signo_d2l(s);
        if (ls && glibc_sigismember(l, ls)) d |= 1u << (s - 1);
    }
    return d;
}

/* THE `how` ARGUMENT NEEDS TRANSLATING TOO, and I wrote a comment here first
 * claiming it did not. Measured, after the round-trip test failed:
 *
 *     Darwin  SIG_BLOCK 1  SIG_UNBLOCK 2  SIG_SETMASK 3
 *     glibc   SIG_BLOCK 0  SIG_UNBLOCK 1  SIG_SETMASK 2
 *
 * Off by one, which is the worst possible spacing: a forwarded SIG_BLOCK is
 * read by glibc as SIG_UNBLOCK and does the OPPOSITE of what the guest asked,
 * returning 0 for success. Only SIG_SETMASK fails loudly, and only because 3
 * happens to be out of range -- an API with two values instead of three would
 * have been silently inverted with nothing to catch it.
 *
 * sdk/tests/glibc_abi_probe.c already pinned all three, with a comment saying
 * exactly this. I asserted the opposite without checking it. */
static int mr_sigmask_how_d2l(int how)
{
    switch (how) {
    case 1: return 0;   /* SIG_BLOCK   */
    case 2: return 1;   /* SIG_UNBLOCK */
    case 3: return 2;   /* SIG_SETMASK */
    default: return -1; /* let glibc reject it */
    }
}

EXPORT int pthread_sigmask(int how, const unsigned int *set, unsigned int *oset)
{
    mr_linux_sigset lset, loset;
    int rc;

    if (set) mr_sigset_d2l(*set, &lset);
    rc = glibc_pthread_sigmask(mr_sigmask_how_d2l(how), set ? &lset : 0, oset ? &loset : 0);
    /* pthread_* report errors as the RETURN VALUE, not through errno, so no
     * errno translation here -- and the value itself is an errno number whose
     * Darwin and Linux spellings differ for several codes. Only 0 and
     * "non-zero" are relied on by any caller we have. */
    if (rc == 0 && oset) *oset = mr_sigset_l2d(&loset);
    return rc;
}

EXPORT int sigprocmask(int how, const unsigned int *set, unsigned int *oset)
{
    mr_linux_sigset lset, loset;
    int rc;

    if (set) mr_sigset_d2l(*set, &lset);
    rc = MR_ERRNO_CALL(glibc_sigprocmask(mr_sigmask_how_d2l(how), set ? &lset : 0, oset ? &loset : 0));
    if (rc == 0 && oset) *oset = mr_sigset_l2d(&loset);
    return rc;
}

/* signalfd(2) is LINUX-ONLY and has no Darwin counterpart, so a Darwin
 * libSystem exporting it looks wrong at first glance. It is here because this
 * file IS the Darwin/Linux boundary and it is the only place that holds the
 * translation above: swift-corelibs-libdispatch's epoll backend is Linux code
 * compiled for a Darwin target, and it passes a sigset_t it owns -- a 4-byte
 * Darwin one. Forwarding that directly is the bug this whole section exists to
 * prevent. */
EXPORT int signalfd(int fd, const unsigned int *mask, int flags)
{
    mr_linux_sigset lmask;
    if (!mask) return MR_ERRNO_CALL(glibc_signalfd(fd, 0, flags));
    mr_sigset_d2l(*mask, &lmask);
    return MR_ERRNO_CALL(glibc_signalfd(fd, &lmask, flags));
}

/* The rest of the sigset_t surface. sigpending is the dangerous one -- its
 * argument is an OUT parameter, so a forward writes glibc's 128 bytes into the
 * guest's 4, exactly like pthread_sigmask's third argument.
 *
 * sigwait carries a second translation the others do not: it returns a SIGNAL
 * NUMBER through its out-parameter, and that number is glibc's. Handing it back
 * unmapped would tell a guest waiting on SIGUSR1 that it received signal 10 --
 * which on Darwin is SIGBUS. */
EXPORT int sigsuspend(const unsigned int *mask)
{
    mr_linux_sigset lmask;
    if (!mask) return MR_ERRNO_CALL(glibc_sigsuspend(0));
    mr_sigset_d2l(*mask, &lmask);
    return MR_ERRNO_CALL(glibc_sigsuspend(&lmask));
}

EXPORT int sigpending(unsigned int *out)
{
    mr_linux_sigset lset;
    int rc = MR_ERRNO_CALL(glibc_sigpending(&lset));
    if (rc == 0 && out) *out = mr_sigset_l2d(&lset);
    return rc;
}

EXPORT int sigwait(const unsigned int *set, int *signo)
{
    mr_linux_sigset lset;
    int lsig = 0, rc;

    if (!set) return 22;                      /* EINVAL, Darwin's value */
    mr_sigset_d2l(*set, &lset);
    rc = glibc_sigwait(&lset, &lsig);         /* returns an errno, not -1 */
    if (rc == 0 && signo) {
        int d = mr_signo_l2d(lsig);
        if (!d)
            mr_bail("sigwait woke on a Linux signal with no Darwin equivalent. "
                    "Handing the raw number back would name a different signal "
                    "to the guest (see the signal table in darwin/src/posix.c).");
        *signo = d;
    }
    return rc;
}

/* ----------------------------------------------------------- sigaction(2) */

/* FOUR translations and a TRAMPOLINE, and the trampoline is the part that
 * makes this different in kind from everything above it. Every other wrapper
 * in this file translates arguments on the way out and results on the way
 * back. sigaction installs a CALLBACK, so the boundary has to be crossed again
 * later, on a thread we did not start, in the other direction.
 *
 * Measured on both sides 2026-08-27, and every row differs:
 *
 *                       Darwin   glibc
 *   sizeof(sigaction)       16     152
 *   offsetof sa_mask         8       8    <- the only thing that agrees
 *   offsetof sa_flags       12     136
 *   sizeof(sigset_t)         4     128
 *
 *   SA_ONSTACK            0x01   0x08000000
 *   SA_RESTART            0x02   0x10000000
 *   SA_RESETHAND          0x04   0x80000000
 *   SA_NOCLDSTOP          0x08   0x00000001
 *   SA_NODEFER            0x10   0x40000000
 *   SA_NOCLDWAIT          0x20   0x00000002
 *   SA_SIGINFO            0x40   0x00000004
 *
 * NOT ONE FLAG AGREES, and the low bits collide with live Linux flags rather
 * than with nothing, so a forward asks for a real and different thing. The
 * worst is the one the only caller we have actually uses:
 * swift-corelibs-libdispatch's event_epoll.c installs its handler with
 * `.sa_flags = SA_RESTART`, which is Darwin's 0x02, which is glibc's
 * SA_NOCLDWAIT. The guest asks for restartable syscalls and gets "reap
 * children automatically" -- two unrelated behaviours, no error, no warning.
 * Darwin's SA_ONSTACK (0x01) likewise arrives as SA_NOCLDSTOP, and Darwin's
 * SA_RESETHAND (0x04) as SA_SIGINFO, which changes the calling convention the
 * kernel uses for the handler.
 *
 * THE STRUCT IS THE #49 OVERFLOW CLASS AT ITS WORST: `oact` is an OUT
 * parameter, so a forward has glibc write 152 bytes into the guest's 16. Our
 * one caller passes NULL for it, which is a property of that caller and not of
 * this code -- the same "safe because today's caller does not" that the ppoll
 * report turned on.
 *
 * AND THE SIGNAL NUMBER ITSELF, which is why the trampoline exists. The guest
 * hands us a Darwin signo; glibc wants Linux's. That direction is just
 * mr_signo_d2l. But when the signal ARRIVES, glibc calls the handler with
 * LINUX's number, and the handler is guest code that will compare it against
 * Darwin's. A guest handler installed for SIGUSR1 would be called with 10,
 * which on Darwin is SIGBUS. Worse, event_epoll.c's handler passes that number
 * straight to pthread_kill -- so an untranslated number would not merely be
 * misread, it would be re-sent, to a different signal, on a different thread.
 *
 * So we install OUR function with glibc, keep the guest's in a table indexed
 * by DARWIN signo, and translate on the way in. The table is the only state
 * this file keeps that outlives a call. */

#define MR_D_SA_ONSTACK   0x01
#define MR_D_SA_RESTART   0x02
#define MR_D_SA_RESETHAND 0x04
#define MR_D_SA_NOCLDSTOP 0x08
#define MR_D_SA_NODEFER   0x10
#define MR_D_SA_NOCLDWAIT 0x20
#define MR_D_SA_SIGINFO   0x40
#define MR_D_SA_KNOWN     0x7F

#define MR_L_SA_NOCLDSTOP 0x00000001
#define MR_L_SA_NOCLDWAIT 0x00000002
#define MR_L_SA_SIGINFO   0x00000004
#define MR_L_SA_ONSTACK   0x08000000
#define MR_L_SA_RESTART   0x10000000
#define MR_L_SA_NODEFER   0x40000000
#define MR_L_SA_RESETHAND 0x80000000u
/* glibc sets this itself on the way in and the kernel hands it back in oact.
 * It is not part of the guest's vocabulary and must be dropped rather than
 * bailed on, or reading back any handler we installed would abort. */
#define MR_L_SA_RESTORER  0x04000000

struct darwin_sigaction {
    void        *sa_handler_u;   /* the union: sa_handler or sa_sigaction */
    unsigned int sa_mask;        /* Darwin sigset_t, 4 bytes, by VALUE */
    int          sa_flags;
};
_Static_assert(sizeof(struct darwin_sigaction) == 16, "Darwin struct sigaction is 16 bytes");
_Static_assert(__builtin_offsetof(struct darwin_sigaction, sa_mask)  == 8,  "sa_mask at 8");
_Static_assert(__builtin_offsetof(struct darwin_sigaction, sa_flags) == 12, "sa_flags at 12");

/* Our mirror of glibc's. Hand-written, and therefore pinned against the REAL
 * header by sdk/tests/glibc_abi_probe.c -- a mirror that only pins itself is
 * the linux_stat mistake, and a wrong offset here writes the flags word into
 * the middle of a signal mask. */
struct linux_sigaction {
    void            *sa_handler_u;
    mr_linux_sigset  sa_mask;
    int              sa_flags;
    void           (*sa_restorer)(void);
};
_Static_assert(sizeof(struct linux_sigaction) == 152, "our mirror of glibc's struct sigaction is 152 bytes");
_Static_assert(__builtin_offsetof(struct linux_sigaction, sa_mask)  == 8,   "mirror sa_mask at 8");
_Static_assert(__builtin_offsetof(struct linux_sigaction, sa_flags) == 136, "mirror sa_flags at 136");

static int mr_sigflags_d2l(int d)
{
    int l = 0;
    if (d & ~MR_D_SA_KNOWN)
        mr_bail("sigaction(): an sa_flags bit outside Darwin's vocabulary. "
                "Forwarding it would name a different Linux flag (see the flag "
                "table in darwin/src/posix.c).");
    if (d & MR_D_SA_ONSTACK)   l |= MR_L_SA_ONSTACK;
    if (d & MR_D_SA_RESTART)   l |= MR_L_SA_RESTART;
    if (d & MR_D_SA_RESETHAND) l |= MR_L_SA_RESETHAND;
    if (d & MR_D_SA_NOCLDSTOP) l |= MR_L_SA_NOCLDSTOP;
    if (d & MR_D_SA_NODEFER)   l |= MR_L_SA_NODEFER;
    if (d & MR_D_SA_NOCLDWAIT) l |= MR_L_SA_NOCLDWAIT;
    /* SA_SIGINFO is refused rather than mapped. It changes the handler's
     * signature to (int, siginfo_t *, void *), and Darwin's siginfo_t is 104
     * bytes where glibc's is 128, with different fields -- so honouring it
     * means a second struct translation and a ucontext_t we have no mapping
     * for at all. Nothing has asked: libdispatch installs a one-argument
     * sa_handler. Bailing is the honest answer; mapping the bit and handing
     * the guest a Linux siginfo would be the dishonest one. */
    if (d & MR_D_SA_SIGINFO)
        mr_bail("sigaction(SA_SIGINFO): the three-argument handler form is not "
                "implemented. Darwin's siginfo_t is 104 bytes and glibc's is "
                "128, with different fields, so the guest would be handed a "
                "Linux siginfo. See docs/UNIMPLEMENTED.md#sigaction-siginfo.");
    return l;
}

static int mr_sigflags_l2d(int l)
{
    int d = 0;
    l &= ~MR_L_SA_RESTORER;
    if ((unsigned)l & ~(unsigned)(MR_L_SA_NOCLDSTOP | MR_L_SA_NOCLDWAIT |
                                  MR_L_SA_SIGINFO   | MR_L_SA_ONSTACK   |
                                  MR_L_SA_RESTART   | MR_L_SA_NODEFER   |
                                  MR_L_SA_RESETHAND))
        mr_bail("sigaction(): glibc returned an sa_flags bit with no Darwin meaning.");
    if (l & MR_L_SA_ONSTACK)   d |= MR_D_SA_ONSTACK;
    if (l & MR_L_SA_RESTART)   d |= MR_D_SA_RESTART;
    if (l & MR_L_SA_RESETHAND) d |= MR_D_SA_RESETHAND;
    if (l & MR_L_SA_NOCLDSTOP) d |= MR_D_SA_NOCLDSTOP;
    if (l & MR_L_SA_NODEFER)   d |= MR_D_SA_NODEFER;
    if (l & MR_L_SA_NOCLDWAIT) d |= MR_D_SA_NOCLDWAIT;
    if (l & MR_L_SA_SIGINFO)   d |= MR_D_SA_SIGINFO;
    return d;
}

/* Indexed by DARWIN signo. SIG_DFL and SIG_IGN are not stored here -- they are
 * 0 and 1 on both systems (pinned both sides) and go to glibc unchanged, so a
 * NULL slot means "not ours" rather than "not set". */
static void *mr_guest_sigaction[32];

static void mr_sig_trampoline(int lsig)
{
    int d = mr_signo_l2d(lsig);
    void (*h)(int);

    /* A Linux signal with no Darwin name cannot be reported to the guest: it
     * has no number the guest would recognise, and picking one would name a
     * different signal. This cannot happen through sigaction() -- we only ever
     * register for signals we translated on the way in -- but the handler is
     * reachable from anything glibc decides to deliver. */
    if (d < 1 || d > 31) return;
    h = (void (*)(int))__atomic_load_n(&mr_guest_sigaction[d], __ATOMIC_ACQUIRE);
    if (h) h(d);
}

EXPORT int sigaction(int dsig, const struct darwin_sigaction *act,
                     struct darwin_sigaction *oact)
{
    struct linux_sigaction lact, loact;
    int lsig = mr_signo_d2l(dsig), rc;
    void *prev_guest;

    /* SIGEMT (7) and SIGINFO (29) exist only on Darwin. There is no Linux
     * signal to install a handler for, and inventing one would arm the guest
     * for something it never asked about. */
    if (lsig == 0) { *mr_errno_slot() = 22; return -1; }   /* EINVAL, Darwin's */

    prev_guest = __atomic_load_n(&mr_guest_sigaction[dsig], __ATOMIC_ACQUIRE);

    if (act) {
        void *h = act->sa_handler_u;
        int   real = (h != (void *)0 && h != (void *)1);   /* not SIG_DFL/SIG_IGN */

        glibc_memset(&lact, 0, sizeof lact);
        lact.sa_flags = mr_sigflags_d2l(act->sa_flags);
        mr_sigset_d2l(act->sa_mask, &lact.sa_mask);
        lact.sa_handler_u = real ? (void *)mr_sig_trampoline : h;

        /* Publish the guest's handler BEFORE glibc can deliver anything to the
         * trampoline. The reverse order has a window in which a signal arrives,
         * the trampoline loads a NULL slot, and the signal is silently dropped. */
        __atomic_store_n(&mr_guest_sigaction[dsig], real ? h : (void *)0,
                         __ATOMIC_RELEASE);
    }

    rc = MR_ERRNO_CALL(glibc_sigaction(lsig, act ? &lact : 0, oact ? &loact : 0));

    if (rc != 0 && act) {
        /* glibc refused, so the guest's handler is not installed and the table
         * must not claim it is. */
        __atomic_store_n(&mr_guest_sigaction[dsig], prev_guest, __ATOMIC_RELEASE);
        return rc;
    }

    if (rc == 0 && oact) {
        /* Report the guest ITS OWN handler, not our trampoline -- the classic
         * save-and-restore idiom reinstalls whatever oact came back with, and
         * handing back the trampoline would work by accident once and then
         * install a trampoline whose table slot the guest had overwritten. */
        oact->sa_handler_u = (loact.sa_handler_u == (void *)mr_sig_trampoline)
                                 ? prev_guest : loact.sa_handler_u;
        oact->sa_mask  = mr_sigset_l2d(&loact.sa_mask);
        oact->sa_flags = mr_sigflags_l2d(loact.sa_flags);
    }
    return rc;
}

/* The three ways to SEND one, all of which carry a Darwin signo. pthread_kill
 * is not optional company for sigaction: event_epoll.c's handler takes the
 * number it was given and passes it straight to pthread_kill, so leaving this
 * a plain forward would re-send the signal under a different name on the one
 * path sigaction exists to serve.
 *
 * pthread_t crosses as an opaque value: it is the guest's own, obtained from
 * our pthread_self, so it is glibc's handle either way. */
EXPORT int pthread_kill(unsigned long thread, int dsig)
{
    int lsig;
    if (dsig == 0) return glibc_pthread_kill(thread, 0);  /* the "is it alive" probe */
    lsig = mr_signo_d2l(dsig);
    if (!lsig) return 22;                                 /* EINVAL, by return value */
    return glibc_pthread_kill(thread, lsig);
}

EXPORT int kill(int pid, int dsig)
{
    int lsig;
    if (dsig == 0) return MR_ERRNO_CALL(glibc_kill(pid, 0));
    lsig = mr_signo_d2l(dsig);
    if (!lsig) { *mr_errno_slot() = 22; return -1; }
    return MR_ERRNO_CALL(glibc_kill(pid, lsig));
}

EXPORT int raise(int dsig)
{
    int lsig = mr_signo_d2l(dsig);
    if (!lsig) { *mr_errno_slot() = 22; return -1; }
    return MR_ERRNO_CALL(glibc_raise(lsig));
}

/* ---------------------------------------------------------------- poll(2) */

/* THREE translations, and only the third is the one this section was asked
 * for. poll looks like the safest possible forward -- an array of 8-byte
 * structs, a count, and a millisecond timeout -- and each of those three
 * arguments is wrong in a different way.
 *
 * 1. nfds_t IS A DIFFERENT WIDTH. Darwin's is `unsigned int`, glibc's is
 *    `unsigned long`. Measured on both sides 2026-08-27: 4 against 8. Under
 *    AAPCS a 32-bit argument is passed in w1 and the upper half of x1 is
 *    UNSPECIFIED, so glibc -- which reads the whole 64-bit register -- gets
 *    the guest's count with whatever the guest last left in the top word. A
 *    guest asking to poll 3 descriptors can hand glibc a count in the
 *    billions, and poll will walk off the end of the array reading it. This
 *    is the opaque-size hazard (docs/ABI.md, #49) appearing in a SCALAR
 *    argument rather than in a struct, which is a shape we had not seen: the
 *    two types have the same NAME and the same signedness and differ only in
 *    width, so nothing at the call site looks wrong. The cast below is the
 *    fix, and it only works because it is written here rather than left to a
 *    header to do implicitly.
 *
 * 2. TWO OF THE TEN FLAGS ARE NUMBERED DIFFERENTLY. Both columns measured,
 *    and both pinned by test (sdk/tests/abi_probe.c against Apple's SDK,
 *    glibc_abi_probe.c against real glibc) rather than by this comment:
 *
 *                      Darwin   glibc
 *        POLLIN        0x0001   0x0001      POLLERR    0x0008   0x0008
 *        POLLPRI       0x0002   0x0002      POLLHUP    0x0010   0x0010
 *        POLLOUT       0x0004   0x0004      POLLNVAL   0x0020   0x0020
 *        POLLRDNORM    0x0040   0x0040      POLLRDBAND 0x0080   0x0080
 *        POLLWRNORM    0x0004   0x0100   <-- differ
 *        POLLWRBAND    0x0100   0x0200   <-- differ
 *
 *    Darwin spells POLLWRNORM as a plain alias for POLLOUT ("no write type
 *    differentiation", sys/poll.h:72), so its two write flags sit one
 *    position below glibc's, and Darwin's POLLWRBAND is bit-identical to
 *    glibc's POLLWRNORM.
 *
 *    HOW MUCH THAT COSTS IS SMALLER THAN IT LOOKS, and the first draft of
 *    this comment got it wrong in the direction that flattered the fix. I
 *    wrote that a forward would grow an extra flag on the way back, because
 *    Linux's pipe_poll computes EPOLLOUT|EPOLLWRNORM for a writable pipe. It
 *    does compute that -- but poll(2) MASKS revents by the events that were
 *    requested, so glibc can only return POLLWRNORM to a caller that asked
 *    for 0x0100, and a Darwin guest asking for 0x0100 is asking for
 *    POLLWRBAND. Measured on a writable pipe under Linux: events=POLLOUT
 *    yields revents=0x0004, not 0x0104. A negative control caught the claim
 *    before it shipped -- tests/src/28_poll.c passed with the translation
 *    deliberately removed, which is what sent me back to measure.
 *
 * 3. ppoll's sigset_t, which is the 4-against-128 crossing the rest of this
 *    section exists for.
 *
 * So of the three, the load-bearing pair is the WIDTH and the SIGSET. The
 * flag mapping earns its place on the request direction and on the four
 * Darwin-only flags below, not on the round trip.
 *
 * The four Darwin-only flags (POLLEXTEND 0x0200, POLLATTRIB 0x0400,
 * POLLNLINK 0x0800, POLLWRITE 0x1000) are file-modification notifications
 * from Darwin's kqueue-backed poll with no Linux counterpart, and they are
 * where forwarding is unambiguously wrong rather than merely inexact: those
 * four bits are four DIFFERENT live Linux flags -- POLLWRBAND, POLLMSG,
 * POLLREMOVE, POLLRDHUP -- so a forward does not ask for nothing, it asks for
 * something else. They are DROPPED, for the same reason SIGEMT and SIGINFO
 * are dropped from a sigset: there is no Linux flag they could mean. Anything
 * outside the union of the two vocabularies is a bail rather than a guess.
 *
 * ONE DIFFERENCE NO MAPPING REACHES, recorded here because the flag table
 * looks like it should. Darwin's poll is kqueue-backed and treats POLLWRBAND
 * on an ordinary pipe as satisfied by plain writability, answering 0x0100;
 * Linux answers 0, because a pipe has no write band. Measured on both. That
 * is a kernel semantic difference rather than a numbering one, so we report
 * Linux's answer under Darwin's name and say so in docs/UNIMPLEMENTED.md.
 * It is the same shape as Darwin answering POLLNVAL for /dev/null where Linux
 * answers POLLOUT, which cost this fixture its first baseline. */

#define MR_D_POLLWRNORM 0x0004   /* == Darwin POLLOUT, deliberately */
#define MR_D_POLLWRBAND 0x0100
#define MR_L_POLLOUT    0x0004
#define MR_L_POLLWRNORM 0x0100
#define MR_L_POLLWRBAND 0x0200

/* The eight that are already equal, plus Darwin's own POLLWRBAND, plus the
 * four Darwin extensions, is the whole Darwin vocabulary. */
#define MR_D_POLL_SAME  0x00FF   /* IN PRI OUT ERR HUP NVAL RDNORM RDBAND */
#define MR_D_POLL_DROP  0x1E00   /* EXTEND ATTRIB NLINK WRITE */
#define MR_D_POLL_KNOWN (MR_D_POLL_SAME | MR_D_POLLWRBAND | MR_D_POLL_DROP)
#define MR_L_POLL_KNOWN (0x00FF | MR_L_POLLWRNORM | MR_L_POLLWRBAND)

struct mr_pollfd { int fd; short events; short revents; };

static short mr_pollev_d2l(short d)
{
    short l;
    if ((unsigned)(unsigned short)d & ~(unsigned)MR_D_POLL_KNOWN)
        mr_bail("poll(): an event bit that is in neither system's vocabulary. "
                "Forwarding it would name a different Linux flag (see the flag "
                "table in darwin/src/posix.c).");
    l = (short)(d & MR_D_POLL_SAME);
    /* POLLWRNORM and POLLOUT are the same bit on Darwin, so a guest that set
     * it meant both; glibc separates them, and setting both is how we say so. */
    if (d & MR_D_POLLWRNORM) l |= MR_L_POLLOUT | MR_L_POLLWRNORM;
    if (d & MR_D_POLLWRBAND) l |= MR_L_POLLWRBAND;
    return l;
}

static short mr_pollev_l2d(short l)
{
    short d;
    if ((unsigned)(unsigned short)l & ~(unsigned)MR_L_POLL_KNOWN)
        mr_bail("poll(): glibc returned a revents bit with no Darwin meaning.");
    d = (short)(l & MR_D_POLL_SAME);
    if (l & MR_L_POLLWRNORM) d |= MR_D_POLLWRNORM;  /* folds onto POLLOUT */
    if (l & MR_L_POLLWRBAND) d |= MR_D_POLLWRBAND;
    return d;
}

/* The guest owns its array and poll(2) promises not to disturb .events, so the
 * translated copy goes in scratch rather than in place. Small counts -- every
 * run loop we have -- stay on the stack. */
#define MR_POLL_STACK_FDS 32

static int mr_poll_common(struct mr_pollfd *fds, unsigned int nfds,
                          int timeout_ms, const void *lsig, int use_ppoll)
{
    struct mr_pollfd stackbuf[MR_POLL_STACK_FDS], *scratch = stackbuf;
    long tsbuf[2];
    unsigned int i;
    int rc;

    if (nfds > MR_POLL_STACK_FDS) {
        scratch = glibc_malloc((size_t)nfds * sizeof *scratch);
        if (!scratch) { *mr_errno_slot() = 12; return -1; }   /* ENOMEM */
    }
    for (i = 0; i < nfds; i++) {
        scratch[i].fd      = fds[i].fd;
        scratch[i].events  = mr_pollev_d2l(fds[i].events);
        scratch[i].revents = 0;
    }

    if (use_ppoll) {
        /* struct timespec is 16 bytes with identical field offsets on both --
         * pinned by sdk/tests/abi_probe.c -- so it needs no translation, only
         * building. A NULL tmo_p is how ppoll spells "block", so the shared
         * body's negative timeout maps to a NULL pointer rather than to -1. */
        const void *ts = 0;
        if (timeout_ms >= 0) {
            tsbuf[0] = timeout_ms / 1000;
            tsbuf[1] = (long)(timeout_ms % 1000) * 1000000L;
            ts = tsbuf;
        }
        rc = MR_ERRNO_CALL(glibc_ppoll(scratch, (unsigned long)nfds, ts, lsig));
    } else {
        rc = MR_ERRNO_CALL(glibc_poll(scratch, (unsigned long)nfds, timeout_ms));
    }

    /* revents is written for every descriptor whenever the call did not fail,
     * including the zero-return timeout case, so translate back on any rc >= 0. */
    if (rc >= 0)
        for (i = 0; i < nfds; i++)
            fds[i].revents = mr_pollev_l2d(scratch[i].revents);

    if (scratch != stackbuf) glibc_free(scratch);
    return rc;
}

EXPORT int poll(struct mr_pollfd *fds, unsigned int nfds, int timeout)
{
    return mr_poll_common(fds, nfds, timeout, 0, 0);
}

/* ppoll(2) is LINUX-ONLY -- Apple's published sys/poll.h at xnu-12377.121.6
 * declares poll and nothing else -- so a Darwin libSystem exporting it looks
 * wrong for exactly the reason signalfd does, and it is here for exactly the
 * same reason: this file IS the Darwin/Linux boundary, and the Linux code that
 * swift-corelibs compiles for a Darwin target passes a sigset_t it owns, which
 * is a 4-byte Darwin one.
 *
 * Its timeout is a struct timespec rather than milliseconds, and that Linux
 * signature is kept, since a caller reaching for ppoll wants the Linux one. */
EXPORT int ppoll(struct mr_pollfd *fds, unsigned int nfds,
                 const long *tmo_p, const unsigned int *sigmask)
{
    mr_linux_sigset lmask;
    int ms = -1;

    if (tmo_p) {
        long long m = (long long)tmo_p[0] * 1000 + tmo_p[1] / 1000000;
        /* Clamping is not a rounding choice, it is the only honest one: the
         * shared body carries milliseconds in an int, and a timeout beyond 24
         * days would otherwise wrap to a short wait or to "block forever". */
        ms = m > 2147483647LL ? 2147483647 : (int)m;
        if (ms < 0) ms = 0;
    }
    if (!sigmask) return mr_poll_common(fds, nfds, ms, 0, 1);
    mr_sigset_d2l(*sigmask, &lmask);
    return mr_poll_common(fds, nfds, ms, &lmask, 1);
}

/* pthread_main_np(3) is BSD/Darwin-only: "is the calling thread the main
 * thread?". glibc has no equivalent -- gettid()==getpid() is the usual Linux
 * idiom but is about the THREAD GROUP LEADER, which is the same thing here
 * only because machorun never forks. Recording the main thread at bootstrap is
 * exact and does not depend on that.
 *
 * This was reported as "the .tbd fails to advertise a symbol libSystem has".
 * It did not: nothing in machorun defined it, in any dylib. gen_tbd.sh
 * generates from `nm` of the built dylibs, so it advertised exactly what
 * existed -- the mechanism was right and the implementation was absent. */
static unsigned long mr_main_thread;

HIDDEN void mr_record_main_thread(void)
{
    mr_main_thread = (unsigned long)glibc_pthread_self();
}

EXPORT int pthread_main_np(void)
{
    return (unsigned long)glibc_pthread_self() == mr_main_thread ? 1 : 0;
}
