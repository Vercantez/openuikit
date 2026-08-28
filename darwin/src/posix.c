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
 * tests/bin/errno lists _stat and _fstat). The aliases are here anyway so
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
 * Measured 2026-08-25, and the fixture utility is what noticed:
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

/* THE ONE PLACE THAT TURNS A GLIBC DIRENT INTO A DARWIN ONE. Both readdir and
 * readdir_r need it, and a second copy would be free to drift -- particularly
 * on d_reclen, which is the size of THIS record and is what a caller walking a
 * buffer steps by. glibc's d_name is shorter, so its d_reclen is not Darwin's. */
static void mr_dirent_l2d(const struct linux_dirent *l, struct darwin_dirent *out)
{
    size_t n = glibc_strlen(l->d_name);
    if (n > sizeof out->d_name - 1) n = sizeof out->d_name - 1;

    glibc_memset(out, 0, sizeof *out);
    out->d_ino     = l->d_ino;
    out->d_seekoff = (uint64_t)l->d_off;
    out->d_type    = l->d_type;            /* DT_* agree on both systems */
    out->d_namlen  = (uint16_t)n;
    glibc_memcpy(out->d_name, l->d_name, n);
    out->d_reclen  = (uint16_t)(__builtin_offsetof(struct darwin_dirent, d_name) + n + 1);
}

EXPORT void *readdir(void *dirp)
{
    struct mr_dir *d = dirp;
    const struct linux_dirent *l;

    if (!d) return 0;
    /* glibc signals end-of-directory with NULL and a *preserved* errno, so the
     * errno dance has to not clobber it. MR_ERRNO_CALL pushes the guest's
     * errno in and pulls glibc's back out, which is exactly right here. */
    l = MR_ERRNO_CALL(glibc_readdir(d->ldir));
    if (!l) return 0;

    mr_dirent_l2d(l, &d->ent);
    return &d->ent;
}

/* readdir_r fills the CALLER's dirent rather than ours, and it exists as a
 * separate entry point only for that reason -- so the translation itself lives
 * in one place. There were four copies of "which image is this address in"
 * before someone merged them; two copies of a struct translation would drift
 * the same way, and a copy that got d_reclen wrong would corrupt a caller
 * walking a buffer rather than reading one record.
 *
 * The contract differs from readdir in a way that is easy to get backwards:
 * readdir_r returns an ERRNO (0 on success, including at end of directory) and
 * signals end-of-directory by storing NULL through `result` -- it does NOT
 * return -1, and it does not set the guest's errno. A wrapper that returned -1
 * at EOF would make every caller's loop terminate as an error. */
EXPORT int readdir_r(void *dirp, struct darwin_dirent *entry,
                     struct darwin_dirent **result)
{
    struct mr_dir *d = dirp;
    struct linux_dirent lent;
    void *lres = 0;
    int rc;

    if (!d || !entry || !result) return 22;      /* EINVAL, Darwin's */
    rc = glibc_readdir_r(d->ldir, &lent, &lres);
    if (rc != 0) { *result = 0; return darwin_from_linux_errno(rc); }
    if (!lres)   { *result = 0; return 0; }      /* end of directory, not an error */
    mr_dirent_l2d(&lent, entry);
    *result = entry;
    return 0;
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
 *    before it shipped -- tests/src/poll.c passed with the translation
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

/* ------------------------------------- the rest of libdispatch's boundary */

/* Eight symbols swift-corelibs-libdispatch reaches for, measured at the call
 * sites rather than from the man pages. They are together because they arrived
 * together, and because three are VARIADIC -- which is what makes this group
 * different in kind from a list of forwards.
 *
 * Darwin's arm64 ABI passes variadic arguments on the STACK; AAPCS64, which
 * glibc follows, passes the first eight in REGISTERS. A `_glibc_` bind for a
 * variadic function therefore has glibc read a register the caller never wrote
 * and -- for ioctl and fcntl -- write through it. That is silent memory
 * corruption rather than a wrong answer, and it is the same reason printf has
 * its own formatter in libsystem.c. Every variadic entry below takes its
 * arguments with va_arg on OUR side and calls a FIXED-ARITY glibc declaration
 * (dsys.h), so the mismatch cannot be written even by accident. */

/* --- madvise: one advice value, and it is the one libdispatch uses -------- */

/* Measured on both sides 2026-08-27:
 *
 *     MADV_NORMAL 0  RANDOM 1  SEQUENTIAL 2  WILLNEED 3  DONTNEED 4   agree
 *     MADV_FREE   Darwin 5     Linux 8                               differ
 *
 * The first five agreeing is what makes this look plain, and I classified it
 * as plain in an earlier audit on exactly that evidence -- having probed 0..4
 * and not 5. libdispatch's allocator calls madvise with MADV_FREE and nothing
 * else, so the single value it uses is the single value that differs. Probing
 * the common range and generalising is how a census misses the only case its
 * consumer exercises.
 *
 * What Darwin's 5 lands on if forwarded is worth stating exactly, because it
 * reached me as "Linux's 5 is MADV_REMOVE, which punches a hole in the
 * object" -- destructive. Measured: Linux's MADV_REMOVE is 9 and 5 is
 * UNASSIGNED, so a forward returns EINVAL. Loud, not destructive. Real
 * symptom, mechanism one number off. */
#define MR_D_MADV_FREE 5
#define MR_L_MADV_FREE 8

EXPORT int madvise(void *addr, size_t len, int advice)
{
    int l;
    if (advice >= 0 && advice <= 4) l = advice;         /* NORMAL..DONTNEED */
    else if (advice == MR_D_MADV_FREE) l = MR_L_MADV_FREE;
    else
        mr_bail("madvise(): a Darwin advice value with no Linux equivalent "
                "(MADV_FREE_REUSABLE/REUSE/PAGEOUT and the zero-wired family "
                "are Darwin-only). See docs/UNIMPLEMENTED.md#not-a-plain-forward.");
    return MR_ERRNO_CALL(glibc_madvise(addr, len, l));
}

/* --- pwrite and the two pthread_attr entries ----------------------------- */

/* The only genuinely plain forward in the group: off_t is 8 bytes on both, the
 * buffer is the caller's, and there are no flags. */
EXPORT ssize_t pwrite(int fd, const void *buf, size_t n, off_t off)
{
    return MR_ERRNO_CALL(glibc_pwrite(fd, buf, n, (long)off));
}

/* pthread_attr_t is 64 bytes on BOTH -- pinned in glibc_abi_probe.c -- so the
 * guest's storage holds glibc's object and these need nothing. That is unusual
 * enough in this file to say out loud: it is why these are forwards where
 * pthread_cond_t next door needs a handle indirection. */
EXPORT int pthread_attr_init(void *a)    { return glibc_pthread_attr_init(a); }
EXPORT int pthread_attr_destroy(void *a) { return glibc_pthread_attr_destroy(a); }

/* struct sched_param is 8 bytes on Darwin and 4 on glibc, which looks like the
 * overflow class and is not, in this direction: it is an IN parameter, so
 * glibc READS 4 of the guest's 8 and writes nothing. That is safe only because
 * sched_priority is the leading field on both -- measured, offset 0 either way
 * -- so the four bytes glibc reads are the four the guest meant.
 *
 * pthread_attr_getschedparam is deliberately absent: it is the OUT direction,
 * where glibc writes 4 bytes into the guest's 8 and leaves Darwin's trailing
 * word holding whatever was on the stack.
 *
 * pthread_attr_setschedpolicy is absent for a louder reason. SCHED_OTHER is 1
 * on Darwin and 0 on glibc, and Darwin's 1 IS glibc's SCHED_FIFO -- so a
 * forwarded "ordinary scheduler" makes the thread real-time. Nothing asks. */
EXPORT int pthread_attr_setschedparam(void *a, const void *param)
{
    return glibc_pthread_attr_setschedparam(a, param);
}

/* --- the rest of the pthread_attr surface, revealed by an untruncated link */

/* These arrived ten symbols late, because ld64.lld stops after 20 diagnostics
 * and every "20 undefined symbols" measurement was the CEILING rather than the
 * count. Worth recording where the work is rather than only in a commit
 * message: the whole pthread_attr family was invisible while everyone argued
 * about fcntl, and TWO INDEPENDENT LINKS BOTH RETURNING EXACTLY 20 was offered
 * as evidence the number was sound. A saturated measurement is perfectly
 * reproducible, and a metric pinned at its limit looks exactly like one that
 * has converged.
 *
 * THE DETACH STATE IS OFF BY ONE, which is the same worst-case spacing as
 * SIG_BLOCK and fails the same way -- in the direction that looks fine:
 *
 *     PTHREAD_CREATE_JOINABLE   Darwin 1   glibc 0
 *     PTHREAD_CREATE_DETACHED   Darwin 2   glibc 1
 *
 * A forwarded JOINABLE (1) is read by glibc as DETACHED, so the guest gets a
 * thread it cannot join, and the pthread_join that follows fails or -- worse
 * -- joins a thread that has already been reaped. DETACHED (2) is out of
 * glibc's range and merely fails, which is the only reason this would ever be
 * noticed. Both columns pinned in sdk/tests/{abi,glibc_abi}_probe.c. */
#define MR_D_PTHREAD_CREATE_JOINABLE 1
#define MR_D_PTHREAD_CREATE_DETACHED 2
#define MR_L_PTHREAD_CREATE_JOINABLE 0
#define MR_L_PTHREAD_CREATE_DETACHED 1

EXPORT int pthread_attr_setdetachstate(void *a, int d)
{
    int l;
    if (d == MR_D_PTHREAD_CREATE_JOINABLE)      l = MR_L_PTHREAD_CREATE_JOINABLE;
    else if (d == MR_D_PTHREAD_CREATE_DETACHED) l = MR_L_PTHREAD_CREATE_DETACHED;
    else return 22;                              /* EINVAL, by return value */
    return glibc_pthread_attr_setdetachstate(a, l);
}

/* The read-back direction of the same off-by-one. A guest that stores JOINABLE
 * and reads DETACHED has been told its own attribute object changed under it. */
EXPORT int pthread_attr_getdetachstate(const void *a, int *out)
{
    int l = 0, rc = glibc_pthread_attr_getdetachstate(a, &l);
    if (rc == 0 && out)
        *out = (l == MR_L_PTHREAD_CREATE_DETACHED) ? MR_D_PTHREAD_CREATE_DETACHED
                                                   : MR_D_PTHREAD_CREATE_JOINABLE;
    return rc;
}

/* size_t on both, no flags, the attr object is glibc's. Genuinely plain. */
EXPORT int pthread_attr_setstacksize(void *a, size_t n)
{
    return glibc_pthread_attr_setstacksize(a, n);
}

EXPORT int pthread_attr_getstacksize(const void *a, size_t *out)
{
    return glibc_pthread_attr_getstacksize(a, out);
}

/* THE SCHEDULING POLICY, which is the one that would not have failed.
 *
 *     SCHED_OTHER   Darwin 1   glibc 0
 *     SCHED_FIFO    Darwin 4   glibc 1
 *     SCHED_RR      Darwin 2   glibc 2      <- the only one that agrees
 *
 * Darwin's SCHED_OTHER IS glibc's SCHED_FIFO, so a forwarded request for the
 * ORDINARY scheduler makes the thread real-time: it runs until it blocks or
 * yields, and on a machine running a test suite that is a hang rather than a
 * slowdown. Darwin's SCHED_FIFO (4) is not a valid Linux policy and merely
 * fails, which is again the wrong half being loud. */
#define MR_D_SCHED_OTHER 1
#define MR_D_SCHED_FIFO  4
#define MR_D_SCHED_RR    2
#define MR_L_SCHED_OTHER 0
#define MR_L_SCHED_FIFO  1
#define MR_L_SCHED_RR    2

static int mr_sched_policy_d2l(int d)
{
    switch (d) {
    case MR_D_SCHED_OTHER: return MR_L_SCHED_OTHER;
    case MR_D_SCHED_FIFO:  return MR_L_SCHED_FIFO;
    case MR_D_SCHED_RR:    return MR_L_SCHED_RR;
    default:               return -1;
    }
}

static int mr_sched_policy_l2d(int l)
{
    switch (l) {
    case MR_L_SCHED_OTHER: return MR_D_SCHED_OTHER;
    case MR_L_SCHED_FIFO:  return MR_D_SCHED_FIFO;
    case MR_L_SCHED_RR:    return MR_D_SCHED_RR;
    default:
        mr_bail("pthread_attr_getschedpolicy(): glibc reported a policy with no "
                "Darwin equivalent (SCHED_BATCH/IDLE/DEADLINE are Linux-only). "
                "Handing the raw number back would name a different policy.");
    }
}

EXPORT int pthread_attr_setschedpolicy(void *a, int policy)
{
    int l = mr_sched_policy_d2l(policy);
    if (l < 0) return 22;                        /* EINVAL, by return value */
    return glibc_pthread_attr_setschedpolicy(a, l);
}

EXPORT int pthread_attr_getschedpolicy(const void *a, int *out)
{
    int l = 0, rc = glibc_pthread_attr_getschedpolicy(a, &l);
    if (rc == 0 && out) *out = mr_sched_policy_l2d(l);
    return rc;
}

/* THE OUT DIRECTION OF sched_param, which I declined to write an hour ago on
 * the grounds that nothing asked. Something asks.
 *
 * struct sched_param is 8 bytes on Darwin and 4 on glibc, with sched_priority
 * the leading field on both (measured, offset 0 either way). The IN direction
 * is therefore safe as a forward -- glibc reads the 4 bytes the guest meant.
 * This is the OUT direction, where a forward has glibc write 4 bytes into the
 * guest's 8 and leave Darwin's trailing opaque word holding whatever was on
 * the stack. Reading it back through Darwin's struct would then see garbage in
 * a field the guest is entitled to treat as initialised. So glibc fills OUR
 * 4-byte mirror and we write the whole 8. */
struct darwin_sched_param { int sched_priority; char opaque[4]; };
_Static_assert(sizeof(struct darwin_sched_param) == 8, "Darwin struct sched_param is 8 bytes");

EXPORT int pthread_attr_getschedparam(const void *a, struct darwin_sched_param *out)
{
    int lprio = 0, rc = glibc_pthread_attr_getschedparam(a, &lprio);
    if (rc == 0 && out) {
        out->sched_priority = lprio;
        glibc_memset(out->opaque, 0, sizeof out->opaque);
    }
    return rc;
}

/* Both a policy and a sched_param, so both translations at once. The param is
 * IN, so the 8-into-4 read is the safe direction. */
EXPORT int pthread_setschedparam(unsigned long thread, int policy, const void *param)
{
    int l = mr_sched_policy_d2l(policy);
    if (l < 0) return 22;                        /* EINVAL */
    return glibc_pthread_setschedparam(thread, l, param);
}

/* Plain: the thread is glibc's, the value is opaque, and there is no return. */
EXPORT void pthread_exit(void *value) { glibc_pthread_exit(value); }

/* --- futex: a NON-VARIADIC door, deliberately, and not syscall(2) --------- */

/* libdispatch's core lock path (src/shims/lock.c) reaches the futex through
 * the variadic multiplexer:
 *
 *     syscall(SYS_futex, uaddr, op | opflags, val, timeout, uaddr2, val3)
 *
 * SEVEN ARGUMENTS THROUGH syscall(2), on every lock and every thread event.
 * machorun does not export syscall and will not: Darwin's arm64 ABI passes
 * variadic arguments on the STACK where AAPCS64 passes the first eight in
 * REGISTERS, so a forward would hand glibc six values it never wrote -- one of
 * them a struct timespec * it writes through. That is not a wrong lock, it is
 * a wild store on the hottest path in the library.
 *
 * So the door is this instead: a NON-VARIADIC six-argument futex(). Fixed
 * arguments use the same registers under both ABIs, so there is no mismatch
 * left to translate -- which is a stronger property than translating it. The
 * caller patches one line to reach it, the same shape as the existing
 * syscall(SYS_gettid) -> gettid() patch.
 *
 * NOTHING ABOUT THE ARGUMENTS IS TRANSLATED, and that is deliberate rather
 * than lazy. The op values (FUTEX_WAIT, FUTEX_WAKE, FUTEX_PRIVATE_FLAG ...)
 * are LINUX constants with no Darwin counterpart at all, so the caller is
 * Linux shim code compiled for a Darwin target and is already speaking Linux
 * -- the signalfd judgement, for the same reason. struct timespec is 16 bytes
 * with identical field offsets on both (pinned by abi_probe), so it crosses as
 * itself. The uaddrs are the guest's own memory.
 *
 * __NR_futex is 98 on aarch64. It is spelled out here because sys/syscall.h is
 * a Linux header this Darwin-targeted translation unit cannot include. */
#define MR_NR_FUTEX 98

EXPORT int futex(unsigned int *uaddr, int op, unsigned int val,
                 const void *timeout, unsigned int *uaddr2, unsigned int val3)
{
    /* syscall(2) reports errors through errno like any other libc call, so the
     * full bracket applies rather than half of it -- and the errno the guest
     * reads must be Darwin's: a futex wait that times out reports ETIMEDOUT,
     * which is 60 on Darwin and 110 on Linux, and lock.c compares against the
     * number it was compiled with. */
    long rc = MR_ERRNO_CALL(glibc_syscall(MR_NR_FUTEX, (long)(size_t)uaddr, op,
                                          val, (long)(size_t)timeout,
                                          (long)(size_t)uaddr2, val3));
    return (int)rc;
}

/* --- getsockopt: the level differs, and 1 is valid on both ---------------- */

/* SOL_SOCKET is 65535 on Darwin and 1 on Linux, and 1 IS a valid level on
 * Linux -- so a forwarded getsockopt reads an option at the WRONG LEVEL rather
 * than failing. Every SO_* differs too: libdispatch asks for SO_ACCEPTCONN,
 * which is 2 on Darwin and 30 on Linux.
 *
 * Only the option libdispatch uses is mapped. A table covering options nothing
 * asks for would be a guess with a plausible face, and this is the file where
 * that is most expensive. */
#define MR_D_SOL_SOCKET    0xffff
#define MR_L_SOL_SOCKET    1
#define MR_D_SO_ACCEPTCONN 0x0002
#define MR_L_SO_ACCEPTCONN 30

/* Linux's legacy socket request numbers. Declared up here rather than beside
 * ioctl() because getsockopt reaches two of them: SO_NREAD and SO_NWRITE are
 * answered by an ioctl on Linux, not by a socket option. */
#define MR_L_FIONREAD      0x541bUL     /* == Linux SIOCINQ */
#define MR_L_FIONBIO       0x5421UL
#define MR_L_SIOCOUTQ      0x5411UL

/* SO_NREAD and SO_NWRITE are the pair that CROSS API SURFACES. Darwin answers
 * "how many bytes are readable / still unsent" through getsockopt; Linux has
 * neither option and answers through ioctl(SIOCINQ) and ioctl(SIOCOUTQ). So
 * these two are translated into a DIFFERENT CALL, not a different constant --
 * which is the only honest mapping, and the reason a bare "speak Darwin above
 * libSystem" rule needs this wrapper to make it implementable at all. */
#define MR_D_SO_NREAD  0x1020
#define MR_D_SO_NWRITE 0x1024

EXPORT int getsockopt(int s, int level, int optname, void *optval, unsigned *optlen)
{
    if (level != MR_D_SOL_SOCKET)
        mr_bail("getsockopt(): only SOL_SOCKET is translated. A forwarded level "
                "reads an option at a DIFFERENT level rather than failing "
                "(Darwin's SOL_SOCKET is 65535, Linux's is 1, and 1 is valid).");

    switch (optname) {
    case MR_D_SO_ACCEPTCONN:
        return MR_ERRNO_CALL(glibc_getsockopt(s, MR_L_SOL_SOCKET,
                                              MR_L_SO_ACCEPTCONN, optval, optlen));
    case MR_D_SO_NREAD:
    case MR_D_SO_NWRITE: {
        /* Both report an int, which is what Linux's ioctl writes too, so the
         * caller's buffer needs no reshaping -- only the CALL changes. */
        unsigned long req = (optname == MR_D_SO_NREAD) ? MR_L_FIONREAD
                                                       : MR_L_SIOCOUTQ;
        if (!optval || !optlen || *optlen < sizeof(int)) {
            *mr_errno_slot() = 22;                       /* EINVAL */
            return -1;
        }
        *optlen = sizeof(int);
        return MR_ERRNO_CALL(glibc_ioctl(s, req, optval));
    }
    default:
        mr_bail("getsockopt(SOL_SOCKET, ...): only SO_ACCEPTCONN, SO_NREAD and "
                "SO_NWRITE are translated. Every SO_* number differs between "
                "the two systems, so a forwarded one names a different option.");
    }
}

/* --- fcntl: variadic, and two commands Linux simply does not have --------- */

/* THE DANGEROUS PART OF fcntl IS NOT REACHED BY THIS CONSUMER, and saying that
 * precisely matters more than repeating the warning. Five of the ten standard
 * commands are ROTATED into each other -- Darwin's F_GETLK (7) is glibc's
 * F_SETLKW, so a forwarded "is this lock held?" becomes "take it and block" --
 * but libdispatch touches none of them. What it uses is:
 *
 *     F_GETFL         3 / 3     agree
 *     F_SETFL         4 / 4     agree
 *     F_GETNOSIGPIPE  74        DOES NOT EXIST ON LINUX
 *     F_SETNOSIGPIPE  73        DOES NOT EXIST ON LINUX
 *
 * The lock commands still BAIL rather than being left to chance, because the
 * next consumer is not this one.
 *
 * F_GETFL/F_SETFL agreeing as COMMANDS is not the end of it: their argument
 * and result are an O_* flag word, and ten of thirteen O_* flags differ --
 * O_NONBLOCK alone is 0x0004 here and 0x0800 there. The command passes through
 * and the VALUE needs translating in both directions.
 *
 * F_*NOSIGPIPE has no Linux counterpart at all: Linux suppresses SIGPIPE
 * per-send with MSG_NOSIGNAL or process-wide with SIG_IGN, never per-fd.
 * ENOTSUP is the honest answer -- a silent no-op would leave the guest
 * believing a write to a closed pipe will not raise SIGPIPE. */
#define MR_F_GETFL         3
#define MR_F_SETFL         4
#define MR_F_GETNOSIGPIPE 74
#define MR_F_SETNOSIGPIPE 73

/* The reverse of linux_open_flags, for what F_GETFL hands back. Only the
 * status flags can appear in a F_GETFL result; the creation flags cannot, but
 * they are mapped anyway so the function is a true inverse. */
static int darwin_open_flags(int l)
{
    int d = l & D_O_ACCMODE;          /* RDONLY/WRONLY/RDWR agree, 0/1/2 */
    int rest = l & ~3;

#define UNMAP(lbit, dbit) do { if (rest & (lbit)) { d |= (dbit); rest &= ~(lbit); } } while (0)
    UNMAP(L_O_SYNC,      D_O_SYNC);   /* before DSYNC: L_O_SYNC contains it */
    UNMAP(L_O_DSYNC,     D_O_DSYNC);
    UNMAP(L_O_NONBLOCK,  D_O_NONBLOCK);
    UNMAP(L_O_APPEND,    D_O_APPEND);
    UNMAP(L_O_ASYNC,     D_O_ASYNC);
    UNMAP(L_O_NOFOLLOW,  D_O_NOFOLLOW);
    UNMAP(L_O_CREAT,     D_O_CREAT);
    UNMAP(L_O_TRUNC,     D_O_TRUNC);
    UNMAP(L_O_EXCL,      D_O_EXCL);
    UNMAP(L_O_NOCTTY,    D_O_NOCTTY);
    UNMAP(L_O_DIRECTORY, D_O_DIRECTORY);
    UNMAP(L_O_CLOEXEC,   D_O_CLOEXEC);
#undef UNMAP
    /* Linux-only status bits (O_PATH, O_TMPFILE, O_NOATIME, O_DIRECT) have no
     * Darwin spelling. Dropping them is right where forwarding is not: the
     * guest cannot have asked for them, so they can only have come from
     * something else on the same descriptor, and inventing a Darwin flag for
     * them would report a mode the guest never set. */
    return d;
}

EXPORT int fcntl(int fd, int cmd, ...)
{
    va_list ap;
    long arg;
    int rc;

    /* Taken with va_arg on OUR side; glibc_fcntl is declared fixed-arity. */
    va_start(ap, cmd);
    arg = va_arg(ap, long);
    va_end(ap);

    switch (cmd) {
    case MR_F_GETFL:
        rc = MR_ERRNO_CALL(glibc_fcntl(fd, MR_F_GETFL, 0));
        return rc < 0 ? rc : darwin_open_flags(rc);
    case MR_F_SETFL:
        return MR_ERRNO_CALL(glibc_fcntl(fd, MR_F_SETFL,
                                         linux_open_flags((int)arg)));
    case MR_F_GETNOSIGPIPE:
    case MR_F_SETNOSIGPIPE:
        *mr_errno_slot() = 45;                  /* ENOTSUP, Darwin's value */
        return -1;
    default:
        mr_bail("fcntl(): only F_GETFL, F_SETFL and the two F_*NOSIGPIPE "
                "commands are translated. Five of the ten standard commands are "
                "ROTATED between the two systems -- Darwin's F_GETLK is glibc's "
                "F_SETLKW, so a forwarded lock QUERY blocks acquiring the lock. "
                "See docs/UNIMPLEMENTED.md#not-a-plain-forward.");
    }
}

/* --- ioctl: one namespace in, and here is why that is not a preference ---- */

/* Darwin encodes an ioctl request as direction|size|group|number -- FIONREAD is
 * 0x4004667f, FIONBIO 0x8004667e -- while Linux uses small opaque numbers for
 * the legacy socket and tty requests, FIONREAD being 0x541b. Nothing about the
 * two spaces corresponds, so a forward asks the kernel for an unrelated
 * operation, through a pointer.
 *
 * THIS WRAPPER TAKES DARWIN REQUEST NUMBERS ONLY. It used to accept both
 * spellings, on the signalfd precedent -- "this file IS the boundary, and
 * Linux shim code compiled for a Darwin target speaks Linux". **That precedent
 * does not extend to ioctl, and the reason is the whole of the argument.**
 *
 * For signalfd the SYMBOL determines the namespace: signalfd exists only on
 * Linux, so any call to it is shim code by construction and its sigset_t is
 * unambiguously Darwin's. ioctl exists on BOTH systems, so the symbol implies
 * nothing about which namespace the request came from -- and 0x541b is a
 * perfectly well-formed Darwin request that simply is not allocated. A wrapper
 * that accepted both could never know which it had received. That is guessing,
 * and this file's rule is to bail rather than guess.
 *
 * It became urgent rather than theoretical when CoreFoundation arrived:
 * CFSocket.c does `#define ioctlsocket(a,b,c) ioctl(a,b,c)` and passes DARWIN
 * numbers, while libdispatch's epoll backend passes LINUX ones. Two namespaces,
 * one symbol, no discriminator.
 *
 * WHAT THE LINUX-SIDE CALLER SHOULD DO INSTEAD, and this is the part a bare
 * "use Darwin numbers" instruction cannot deliver, because I measured it and
 * one of the two requests has no Darwin ioctl at all:
 *
 *     bytes readable    Darwin FIONREAD (ioctl)          Linux SIOCINQ (ioctl)
 *     bytes unsent      Darwin SO_NWRITE (GETSOCKOPT)    Linux SIOCOUTQ (ioctl)
 *
 * Darwin has no FIONWRITE. It answers "how much is still unsent" through
 * getsockopt, and Linux has no SO_NWRITE and answers it through ioctl. So the
 * same question sits on DIFFERENT API SURFACES on the two systems -- which is
 * not a constant mismatch and cannot be fixed by renumbering. SIOCINQ maps onto
 * FIONREAD here; SIOCOUTQ has to become getsockopt(SOL_SOCKET, SO_NWRITE),
 * which this file then translates back onto Linux's ioctl. A cross-surface
 * translation looks exotic and is exactly what a boundary is for. */
#define MR_D_FIONREAD  0x4004667fUL     /* _IOR('f', 127, int)  */
#define MR_D_FIONBIO   0x8004667eUL     /* _IOW('f', 126, int)  */

EXPORT int ioctl(int fd, unsigned long req, ...)
{
    va_list ap;
    void *arg;
    unsigned long lreq;

    va_start(ap, req);
    arg = va_arg(ap, void *);
    va_end(ap);

    switch (req) {
    case MR_D_FIONREAD: lreq = MR_L_FIONREAD; break;
    case MR_D_FIONBIO:  lreq = MR_L_FIONBIO;  break;
    default:
        mr_bail("ioctl(): only Darwin request numbers are accepted, and only "
                "FIONREAD and FIONBIO are mapped. Darwin encodes a request as "
                "direction|size|group|number and Linux uses small opaque "
                "numbers for the legacy requests, so the two spaces do not "
                "correspond -- and because ioctl exists on BOTH systems, the "
                "symbol cannot tell us which namespace a caller meant. "
                "Linux-origin code wanting SIOCOUTQ should ask for "
                "getsockopt(SOL_SOCKET, SO_NWRITE), which is how Darwin spells "
                "that question. See docs/UNIMPLEMENTED.md#ioctl-request-encoding.");
    }

    return MR_ERRNO_CALL(glibc_ioctl(fd, lreq, arg));
}

/* --- sysctl: nothing to forward to, so it is implemented ----------------- */

/* sysctl CANNOT be forwarded in either direction, which is unusual enough to
 * record. sys/sysctl.h no longer exists in glibc 2.39, Linux's sysctl(2) was
 * removed from the kernel and returns ENOSYS, and Darwin's is an unrelated BSD
 * MIB API. The symbol survives in libc.so.6 only as a compat stub -- exactly
 * the shape that lets a link succeed and a call quietly do nothing.
 *
 * libdispatch's single use is {CTL_KERN, KERN_OSVERSION} into _dispatch_build,
 * which is introspection: the string reaches crash reports and nowhere else. A
 * fixed answer is therefore a real answer rather than a stub pretending to be
 * one -- and it says "machorun" rather than a plausible macOS build number, so
 * nobody reads a crash report and believes it came from a Mac.
 *
 * Anything else bails, because an unimplemented MIB and a nonexistent one are
 * different facts and only one of them should look like a normal failure. */
#define MR_CTL_KERN              1
#define MR_CTL_HW                6
#define MR_KERN_OSTYPE           1
#define MR_KERN_OSRELEASE        2
#define MR_KERN_PROC            14
#define MR_KERN_PROC_PID         1
#define MR_KERN_MAXFILESPERPROC 29
#define MR_KERN_OSVERSION       65
#define MR_HW_NCPU               3
#define MR_HW_MEMSIZE           24
#define MR_HW_AVAILCPU          25

/* Darwin _SC_* names. Four of the five MIBs below are questions our own
 * sysconf already answers, and it already carries the Darwin-to-Linux _SC_
 * translation (all 128 names differ), so asking it is both less code and one
 * fewer table to keep honest than reaching for glibc directly. */
#define MR_SC_OPEN_MAX           5
#define MR_SC_PAGESIZE          29
#define MR_SC_NPROCESSORS_CONF  57
#define MR_SC_NPROCESSORS_ONLN  58
#define MR_SC_PHYS_PAGES       200
extern long sysconf(int);                       /* darwin/src/libsystem.c */

static int mr_sysctl_string(const char *val, void *oldp, size_t *oldlenp)
{
    size_t need = glibc_strlen(val) + 1;
    if (!oldlenp) { *mr_errno_slot() = 22; return -1; }              /* EINVAL */
    if (!oldp) { *oldlenp = need; return 0; }                        /* size query */
    if (*oldlenp < need) { *oldlenp = need; *mr_errno_slot() = 12; return -1; } /* ENOMEM */
    glibc_memcpy(oldp, val, need);
    *oldlenp = need;
    return 0;
}

/* The scalar MIBs. The WIDTH is part of the answer and is not negotiable: a
 * caller passes a buffer of exactly the size the MIB is documented to return
 * and checks nothing, so writing 8 bytes where CF expects 4 is a stack smash
 * rather than a wrong number. HW_MEMSIZE is the uint64 one; the rest are int. */
static int mr_sysctl_fixed(const void *src, size_t need, void *oldp, size_t *oldlenp)
{
    if (!oldlenp) { *mr_errno_slot() = 22; return -1; }
    if (!oldp) { *oldlenp = need; return 0; }
    if (*oldlenp < need) { *oldlenp = need; *mr_errno_slot() = 12; return -1; }
    glibc_memcpy(oldp, src, need);
    *oldlenp = need;
    return 0;
}

/* {CTL_KERN, KERN_PROC, KERN_PROC_PID, pid} -- THE ONE THAT GATES CoreFoundation.
 *
 * __CFInitialize reaches this through __CFStringGetUserDefaultEncoding and
 * _CFGetSVUID, so nothing in CF runs until it answers. On Darwin it returns a
 * whole `struct kinfo_proc` -- 648 bytes of BSD process table -- and CF reads
 * EXACTLY ONE FIELD out of it: kp_eproc.e_pcred.p_svuid, the saved
 * set-user-ID, at offset 396.
 *
 * Linux has no kinfo_proc and no equivalent MIB, so there is nothing to
 * forward to in any form. But it also does not need the struct MODELLED, and
 * that is the difference between a translating wrapper and porting a BSD
 * process table for one integer.
 *
 * WHY SYNTHESIZING IS RIGHT HERE AND IS NOT A GUESS, which was the open
 * question when this was handed to me. getresuid(2) returns the process's
 * ACTUAL saved set-user-ID -- it is not a plausible substitute for the answer,
 * it IS the answer, obtained through the API Linux uses to give it. Same shape
 * as SO_NWRITE and ioctl(SIOCOUTQ): one question, two API surfaces.
 *
 * That matters because of what CF does with it. The value feeds a setuid check
 * deciding whether the process may trust its environment, so a WRONG answer is
 * a security-relevant answer. A true one from getresuid is strictly safer than
 * either a fabricated uid or a reported failure -- failure is a supported
 * outcome for CF's caller, but it discards information CF would have had on
 * macOS, and the goal here is to behave as macOS does.
 *
 * Every other byte is ZEROED rather than left uninitialised. A caller reading
 * a field we did not fill gets a defined 0, not whatever was on the stack --
 * and a zeroed BSD process entry is obviously empty rather than plausibly
 * populated. The offset is mirrored by hand and therefore pinned against
 * Apple's own SDK in sdk/tests/abi_probe.c, which is the linux_stat rule. */
#define MR_KINFO_PROC_SIZE   648
#define MR_KINFO_P_SVUID_OFF 396

static int mr_sysctl_kinfo_proc(void *oldp, size_t *oldlenp)
{
    unsigned char buf[MR_KINFO_PROC_SIZE];
    unsigned ruid = 0, euid = 0, suid = 0;

    if (!oldlenp) { *mr_errno_slot() = 22; return -1; }
    if (!oldp) { *oldlenp = MR_KINFO_PROC_SIZE; return 0; }
    if (*oldlenp < MR_KINFO_PROC_SIZE) {
        *oldlenp = MR_KINFO_PROC_SIZE; *mr_errno_slot() = 12; return -1;
    }
    if (MR_ERRNO_CALL(glibc_getresuid(&ruid, &euid, &suid)) != 0) return -1;

    glibc_memset(buf, 0, sizeof buf);
    glibc_memcpy(buf + MR_KINFO_P_SVUID_OFF, &suid, sizeof suid);
    glibc_memcpy(oldp, buf, MR_KINFO_PROC_SIZE);
    *oldlenp = MR_KINFO_PROC_SIZE;
    return 0;
}

EXPORT int sysctl(int *name, unsigned namelen, void *oldp, size_t *oldlenp,
                  void *newp, size_t newlen)
{
    if (newp || newlen) { *mr_errno_slot() = 1; return -1; }         /* EPERM */
    if (!name || namelen < 2) { *mr_errno_slot() = 22; return -1; }  /* EINVAL */

    if (name[0] == MR_CTL_KERN) {
        switch (name[1]) {
        case MR_KERN_OSTYPE:    return mr_sysctl_string("Darwin",   oldp, oldlenp);
        case MR_KERN_OSRELEASE: return mr_sysctl_string("machorun", oldp, oldlenp);
        case MR_KERN_OSVERSION: return mr_sysctl_string("machorun", oldp, oldlenp);
        case MR_KERN_MAXFILESPERPROC: {
            int v = (int)sysconf(MR_SC_OPEN_MAX);
            return mr_sysctl_fixed(&v, sizeof v, oldp, oldlenp);
        }
        case MR_KERN_PROC:
            /* Only the by-pid form, and only for ourselves -- a process table
             * walk would need the struct really modelled. */
            if (namelen >= 3 && name[2] == MR_KERN_PROC_PID)
                return mr_sysctl_kinfo_proc(oldp, oldlenp);
            mr_bail("sysctl(CTL_KERN, KERN_PROC, ...): only KERN_PROC_PID is "
                    "implemented, and only the saved set-user-ID within it. "
                    "See docs/UNIMPLEMENTED.md#sysctl-mibs.");
        default:
            mr_bail("sysctl(CTL_KERN, ...): that MIB is not implemented. See "
                    "docs/UNIMPLEMENTED.md#sysctl-mibs.");
        }
    }

    if (name[0] == MR_CTL_HW) {
        switch (name[1]) {
        case MR_HW_NCPU: {
            int v = (int)sysconf(MR_SC_NPROCESSORS_CONF);
            return mr_sysctl_fixed(&v, sizeof v, oldp, oldlenp);
        }
        case MR_HW_AVAILCPU: {
            int v = (int)sysconf(MR_SC_NPROCESSORS_ONLN);
            return mr_sysctl_fixed(&v, sizeof v, oldp, oldlenp);
        }
        case MR_HW_MEMSIZE: {
            /* uint64 on Darwin, and Linux answers it as pages x page size --
             * so the multiplication has to happen in 64 bits or a 32 GiB
             * machine reports 0 after the product wraps. */
            unsigned long long v = (unsigned long long)sysconf(MR_SC_PHYS_PAGES)
                                 * (unsigned long long)sysconf(MR_SC_PAGESIZE);
            return mr_sysctl_fixed(&v, sizeof v, oldp, oldlenp);
        }
        default:
            mr_bail("sysctl(CTL_HW, ...): that MIB is not implemented. See "
                    "docs/UNIMPLEMENTED.md#sysctl-mibs.");
        }
    }

    mr_bail("sysctl(): only CTL_KERN and CTL_HW are implemented. There is "
            "nothing to forward to -- glibc dropped sys/sysctl.h and Linux's "
            "sysctl(2) returns ENOSYS -- so an unimplemented MIB must not look "
            "like a normal failure. See docs/UNIMPLEMENTED.md#sysctl-mibs.");
}

/* ------------------------------------- three more of CoreFoundation's walls */

/* pthread_getugid_np(2) FAILS ON DARWIN, and that is what we reproduce.
 *
 * It was recommended to me as "geteuid()/getegid(), take it verbatim -- Linux
 * has no per-thread ugid override, so that literally IS the correct
 * implementation". That reasons from what Linux can supply, which is a good
 * argument for a function whose Darwin behaviour nobody had checked. Measured
 * on the oracle (macOS 26.5.2, ordinary unprivileged thread):
 *
 *     pthread_getugid_np(&u, &g)  ->  rc = -1, errno = ESRCH, u and g UNTOUCHED
 *
 * So on real Darwin this SPI does not answer for an ordinary thread at all,
 * and every caller -- CoreFoundation included -- is already on its failure
 * path there. Returning 0 with the effective ids would be MORE USEFUL and
 * would send CF down a branch it never takes on a Mac, which is the opposite
 * of what this boundary is for. The outputs are left untouched because Darwin
 * leaves them untouched, and a caller that ignores the -1 must see what it
 * would have seen.
 *
 * ESRCH is 3 on both systems, so the number crosses unchanged -- checked
 * rather than assumed, since a coincidence is exactly what this file distrusts. */
EXPORT int pthread_getugid_np(unsigned *uid, unsigned *gid)
{
    (void)uid; (void)gid;
    *mr_errno_slot() = 3;                     /* ESRCH, and 3 on both systems */
    return -1;
}

/* pthread_atfork: A THIRD KIND OF GAP, and the one that fails latest.
 *
 * Everything else in this file is "same name, different ABI" -- a struct that
 * is a different size, a constant that is a different number, a scalar that is
 * a different width, a variadic convention that is different. This one is
 * SAME NAME, NO DYNAMIC SYMBOL AT ALL.
 *
 * pthread_atfork has an identical prototype on both systems -- three function
 * pointers, no struct, no constant -- so it lands squarely on the "safe to
 * forward" pile by every check we have. glibc's header declares it; the man
 * page documents it; and glibc does NOT export it from libc.so. It lives in
 * libc_nonshared.a as a static wrapper over __register_atfork, so there is
 * nothing for dlsym to find and a forward fails at RUNTIME:
 *
 *     machorun: undefined symbol '_glibc_pthread_atfork'
 *
 * Measured rather than taken on report, with positive controls so an empty
 * answer could not be the instrument: `nm -D --defined-only libc.so.6` finds
 * pthread_atfork ZERO times and __register_atfork once, while malloc,
 * getresuid and geteuid are all found.
 *
 * So this is a door built rather than a call forwarded, the same shape as
 * futex. The fourth argument is the DSO handle glibc uses to unregister the
 * handlers if the caller's library is unloaded; NULL means "never unregister",
 * which is right here because libSystem is never unloaded. */
EXPORT int pthread_atfork(void (*prepare)(void), void (*parent)(void),
                          void (*child)(void))
{
    return glibc___register_atfork(prepare, parent, child, 0);
}

/* _NSGetExecutablePath: THE PLAUSIBLE WRONG ANSWER.
 *
 * The obvious Linux implementation is readlink("/proc/self/exe"), and it is
 * wrong in a way that would survive review: under machorun the process
 * genuinely IS machorun, and the Mach-O is something the loader mapped rather
 * than something the kernel exec'd. So /proc/self/exe returns the LOADER's
 * path -- a real, existing, readable file, and not the guest.
 *
 * CoreFoundation uses this to locate the main bundle. A wrong answer here does
 * not fail; it points CF at a different directory and every bundle-relative
 * resource lookup then fails somewhere far away from the cause. The answer has
 * to come from the loader's own knowledge of which image it loaded, which is
 * why src/resolve.c exports mr_guest_executable_path().
 *
 * Darwin's contract, and the reason bufsize is in/out: on success return 0; if
 * the buffer is too small, WRITE THE REQUIRED SIZE back through bufsize and
 * return -1. A caller that ignores the -1 and reads the buffer gets whatever
 * was there, so the size must be set on the failure path too. */
extern const char *mr_guest_executable_path(void);   /* -> loader, resolve.c */

EXPORT int _NSGetExecutablePath(char *buf, unsigned *bufsize)
{
    const char *p = mr_guest_executable_path();
    size_t need;

    if (!bufsize) return -1;
    if (!p) {
        /* The loader always has a main image by the time a guest can call
         * this, so a NULL here means something is wrong with our own state
         * rather than with the caller's arguments. */
        mr_bail("_NSGetExecutablePath: the loader has no main image recorded. "
                "Returning a path would be inventing one.");
    }

    need = glibc_strlen(p) + 1;
    if (!buf || *bufsize < need) { *bufsize = (unsigned)need; return -1; }
    glibc_memcpy(buf, p, need);
    /* bufsize is DELIBERATELY NOT UPDATED on success. Measured on the oracle:
     * a 4096-byte buffer holding a 112-character path comes back with bufsize
     * still 4096, not 113. Apple writes it only on the FAILURE path, where it
     * is the caller's instruction for how much to allocate. Setting it on
     * success looks tidier and is a different function. */
    return 0;
}

/* ------------------------------- resource limits, writev, and thread scope */

/* THE RLIMIT RESOURCE NUMBERS ARE ROTATED, and only two of the seven move --
 * which is what makes it look safe. Measured both sides 2026-08-27:
 *
 *     CPU 0  FSIZE 1  DATA 2  STACK 3  CORE 4        agree
 *     RLIMIT_NOFILE    Darwin 8   Linux 7            differ
 *     RLIMIT_AS        Darwin 5   Linux 9            differ
 *
 * And the collisions are with LIVE limits rather than unused slots: Darwin's
 * NOFILE (8) is Linux's RLIMIT_MEMLOCK and Darwin's AS (5) is Linux's
 * RLIMIT_RSS. So a forwarded getrlimit(RLIMIT_NOFILE) does not fail -- it
 * returns how much memory this process may lock, as a file-descriptor count.
 * CoreFoundation asks for NOFILE, so this is the live one rather than the
 * theoretical one.
 *
 * AND THE STRUCT NEEDS TRANSLATING AFTER ALL, which I got wrong first time and
 * only found because the negative control PASSED. The LAYOUT agrees -- 16
 * bytes on both, rlim_t 8 on both -- so every size check passes and I wrote
 * "struct rlimit needs nothing". The VALUE inside it does not:
 *
 *     RLIM_INFINITY   Darwin 0x7fffffffffffffff   Linux 0xffffffffffffffff
 *
 * A guest testing `rlim_cur == RLIM_INFINITY` compares against DARWIN's
 * spelling, so an unlimited Linux resource reads as a specific enormous FINITE
 * number and every "is this capped?" test answers wrongly. It is the
 * sockaddr_in shape inverted: there an identical size hid a different layout,
 * here an identical layout hides a different value. Nothing structural catches
 * either.
 *
 * That is also why the control passed: forwarding the raw resource number gave
 * Linux's MEMLOCK, which is unlimited, which the fixture then read as finite
 * because the sentinels disagree -- one bug concealing another. */
#define MR_D_RLIMIT_NOFILE 8
#define MR_L_RLIMIT_NOFILE 7
#define MR_D_RLIMIT_AS     5
#define MR_L_RLIMIT_AS     9

static int mr_rlimit_d2l(int r)
{
    if (r >= 0 && r <= 4) return r;              /* CPU FSIZE DATA STACK CORE */
    if (r == MR_D_RLIMIT_NOFILE) return MR_L_RLIMIT_NOFILE;
    if (r == MR_D_RLIMIT_AS)     return MR_L_RLIMIT_AS;
    mr_bail("getrlimit/setrlimit: a Darwin RLIMIT_* with no mapping. The "
            "numbers are ROTATED between the two systems -- Darwin's NOFILE is "
            "Linux's MEMLOCK -- so a forward returns a different limit rather "
            "than failing. See docs/UNIMPLEMENTED.md#rlimit-rotated.");
}

#define MR_D_RLIM_INFINITY 0x7fffffffffffffffULL
#define MR_L_RLIM_INFINITY 0xffffffffffffffffULL

struct mr_rlimit { unsigned long long cur, max; };
_Static_assert(sizeof(struct mr_rlimit) == 16, "struct rlimit is 16 bytes on both");

static unsigned long long mr_rlim_l2d(unsigned long long v)
{
    return v == MR_L_RLIM_INFINITY ? MR_D_RLIM_INFINITY : v;
}

static unsigned long long mr_rlim_d2l(unsigned long long v)
{
    return v == MR_D_RLIM_INFINITY ? MR_L_RLIM_INFINITY : v;
}

EXPORT int getrlimit(int resource, struct mr_rlimit *rlp)
{
    struct mr_rlimit tmp;
    int rc = MR_ERRNO_CALL(glibc_getrlimit(mr_rlimit_d2l(resource), &tmp));
    if (rc == 0 && rlp) {
        rlp->cur = mr_rlim_l2d(tmp.cur);
        rlp->max = mr_rlim_l2d(tmp.max);
    }
    return rc;
}

EXPORT int setrlimit(int resource, const struct mr_rlimit *rlp)
{
    struct mr_rlimit tmp;
    if (!rlp) { *mr_errno_slot() = 14; return -1; }      /* EFAULT */
    tmp.cur = mr_rlim_d2l(rlp->cur);
    tmp.max = mr_rlim_d2l(rlp->max);
    return MR_ERRNO_CALL(glibc_setrlimit(mr_rlimit_d2l(resource), &tmp));
}

/* writev IS A GENUINE PLAIN FORWARD, and it is worth saying why rather than
 * just doing it: struct iovec is 16 bytes on both with iov_base at 0 and
 * iov_len at 8 -- measured, not assumed. That is unusual enough in this file
 * to be the exception that needs evidence. The count is an int on both, so
 * there is no nfds_t-style width problem either. */
EXPORT long writev(int fd, const void *iov, int iovcnt)
{
    return MR_ERRNO_CALL(glibc_writev(fd, iov, iovcnt));
}

/* PTHREAD_SCOPE IS OFF BY ONE, the third instance of that spacing after
 * SIG_BLOCK and the detach state, and it fails the same way -- in the
 * direction that looks fine:
 *
 *     PTHREAD_SCOPE_SYSTEM    Darwin 1   glibc 0
 *     PTHREAD_SCOPE_PROCESS   Darwin 2   glibc 1
 *
 * Linux implements only SCOPE_SYSTEM. So a forwarded Darwin SCOPE_SYSTEM (1)
 * arrives as glibc's SCOPE_PROCESS, which glibc rejects with ENOTSUP -- the
 * guest asks for the one scope Linux supports and is told it is unsupported.
 * Darwin's SCOPE_PROCESS (2) is out of range and also fails, so BOTH
 * directions fail without translation and only one of them should. */
#define MR_D_PTHREAD_SCOPE_SYSTEM  1
#define MR_D_PTHREAD_SCOPE_PROCESS 2
#define MR_L_PTHREAD_SCOPE_SYSTEM  0
#define MR_L_PTHREAD_SCOPE_PROCESS 1

EXPORT int pthread_attr_setscope(void *a, int scope)
{
    int l;
    if (scope == MR_D_PTHREAD_SCOPE_SYSTEM)       l = MR_L_PTHREAD_SCOPE_SYSTEM;
    else if (scope == MR_D_PTHREAD_SCOPE_PROCESS) l = MR_L_PTHREAD_SCOPE_PROCESS;
    else return 22;                               /* EINVAL, by return value */
    return glibc_pthread_attr_setscope(a, l);
}

/* The read-back half, and it exists because the whole-families rule applies to
 * a translation as much as to a symbol list: a set without its get is a
 * one-way mapping nothing can check, and the fixture that grades this needs
 * both ends to prove the round trip. */
EXPORT int pthread_attr_getscope(const void *a, int *out)
{
    int l = 0, rc = glibc_pthread_attr_getscope(a, &l);
    if (rc == 0 && out)
        *out = (l == MR_L_PTHREAD_SCOPE_PROCESS) ? MR_D_PTHREAD_SCOPE_PROCESS
                                                 : MR_D_PTHREAD_SCOPE_SYSTEM;
    return rc;
}

/* ------------------------------------------- the rest of CF's plain surface */

EXPORT int chown(const char *path, unsigned uid, unsigned gid)
{
    return MR_ERRNO_CALL(glibc_chown(path, uid, gid));
}

EXPORT int gethostname(char *name, size_t len)
{
    return MR_ERRNO_CALL(glibc_gethostname(name, len));
}

/* __darwin_check_fd_set_overflow is Apple's fortify helper: FD_SET and
 * FD_ISSET expand into a call to it so an out-of-range descriptor is caught
 * rather than smashing the bitmap. It returns non-zero when the descriptor may
 * be used.
 *
 * fd_set needs NO translation, which is worth recording because it is the
 * exception: FD_SETSIZE is 1024 and sizeof(fd_set) is 128 on BOTH systems,
 * measured. So this is a pure range check and not a struct crossing.
 *
 * `unlimited` is Apple's escape hatch for callers that have deliberately sized
 * their own bitmap larger; when it is set the only invalid descriptor is a
 * negative one. Getting that backwards would either reject every legitimate
 * large-fd caller or accept a write past the end of a 128-byte object. */
#define MR_FD_SETSIZE 1024

EXPORT int __darwin_check_fd_set_overflow(int n, const void *set, int unlimited)
{
    (void)set;
    if (n < 0) return 0;
    return unlimited ? 1 : (n < MR_FD_SETSIZE);
}

/* gethostuuid(2) is Darwin-only: a stable per-HOST identifier, not per-boot and
 * not per-process. Linux's nearest equivalent is /etc/machine-id, which is
 * exactly the same idea -- so reading it is the answer rather than a stand-in,
 * the same judgement as getresuid for the saved set-user-ID.
 *
 * IT WILL FAIL IN A CONTAINER, AND THAT IS THE CORRECT OUTCOME RATHER THAN A
 * GAP. Measured in the test-bed image: /etc/machine-id exists and is EMPTY,
 * and /var/lib/dbus/machine-id is absent -- a container has no host identity
 * of its own to report. Darwin's own gethostuuid can fail too (it returns -1
 * in sandboxes), so callers must already have a failure path. Inventing a UUID
 * would be worse than failing in a specific way: a fabricated host identifier
 * is indistinguishable from a real one, and anything that persists it would
 * carry the fiction forward.
 *
 * The `wait` argument is a timeout for Darwin's underlying call and has nothing
 * to wait for here. */
EXPORT int gethostuuid(unsigned char out[16], const void *wait)
{
    char buf[64];
    int fd, i;
    long n;

    (void)wait;
    if (!out) { *mr_errno_slot() = 14; return -1; }        /* EFAULT */

    fd = MR_ERRNO_CALL(glibc_open("/etc/machine-id", 0 /* O_RDONLY, same on both */, 0));
    if (fd < 0) return -1;
    n = MR_ERRNO_CALL(glibc_read(fd, buf, sizeof buf));
    (void)MR_ERRNO_CALL(glibc_close(fd));
    if (n < 32) { *mr_errno_slot() = 2; return -1; }       /* ENOENT: no identity */

    /* 32 hex characters into 16 bytes. Anything that is not hex means the file
     * is not a machine-id, which is a failure rather than something to salvage. */
    for (i = 0; i < 16; i++) {
        int hi = buf[i * 2], lo = buf[i * 2 + 1], v = 0, k;
        for (k = 0; k < 2; k++) {
            int c = k ? lo : hi, d;
            if (c >= '0' && c <= '9')      d = c - '0';
            else if (c >= 'a' && c <= 'f') d = c - 'a' + 10;
            else if (c >= 'A' && c <= 'F') d = c - 'A' + 10;
            else { *mr_errno_slot() = 2; return -1; }
            v = (v << 4) | d;
        }
        out[i] = (unsigned char)v;
    }
    return 0;
}

/* ----------------------------------------------------------------- uname
 *
 * `struct utsname` is the struct-layout hazard in its plainest form, and in the
 * OUT-parameter direction: Darwin's is 1280 bytes with five 256-byte fields at
 * 0/256/512/768/1024; glibc's is 390 bytes with SIX 65-byte fields at
 * 0/65/130/195/260/325. Both measured, not recalled. A forward writes 390 bytes
 * into a 1280-byte object -- the safe direction for the SIZE, which is exactly
 * why it would not crash -- and then every field but the first is read from the
 * wrong place: the guest's `nodename` at +256 lands inside glibc's `machine`.
 *
 * ONE BEHAVIOURAL DIFFERENCE THAT ONLY A MEASUREMENT FINDS: Darwin writes
 * strlen+1 bytes per field and LEAVES THE REST OF THE FIELD ALONE; glibc zeroes
 * the whole 65 bytes. Filling the struct with a sentinel before the call shows
 * it immediately and nothing else does. tests/bin/uname checks it, which is why
 * the copy below is a string copy and not a memset-then-copy.
 *
 * WHAT IT REPORTS is a DECISION, not a measurement, and the two halves are
 * different in kind:
 *
 *   sysname   "Darwin". Every compile-time signal the guest carries says Darwin
 *             -- TARGET_OS_MAC, the Mach-O it is, the SDK it was built against
 *             -- and a guest branching here should find the branch its own
 *             binary was compiled for. "Linux" would be true about the kernel
 *             and contradict every other signal in the process.
 *   machine   "arm64". A NAME TRANSLATION, not a claim: glibc spells the same
 *             CPU "aarch64", and a guest switching on the string would fail to
 *             recognise its own architecture.
 *   nodename  the kernel's, verbatim.
 *   release   the kernel's, verbatim, and THIS IS THE HONEST DIVERGENCE: a
 *             LINUX version number under a Darwin sysname.
 *             FoundationEssentials' ProcessInfo.operatingSystemVersion parses
 *             exactly this field, so it reports the Linux kernel version.
 *             Inventing a Darwin release was rejected: it would be a fabricated
 *             number that version-gated code ACTS on -- the guess with a
 *             plausible face. A wrong-but-real kernel version is discoverable;
 *             an invented one is not. docs/UNIMPLEMENTED.md#uname-identity.
 *   version   names machorun, so anything that PRINTS the version string tells
 *             the whole truth instead of half of it.
 */

struct darwin_utsname {
    char sysname[256]; char nodename[256]; char release[256];
    char version[256]; char machine[256];
};
struct linux_utsname {
    char sysname[65]; char nodename[65]; char release[65];
    char version[65]; char machine[65];  char domainname[65];
};
_Static_assert(sizeof(struct darwin_utsname) == 1280, "Darwin utsname is 1280 bytes");
_Static_assert(sizeof(struct linux_utsname) == 390, "glibc aarch64 utsname is 390 bytes");
_Static_assert(__builtin_offsetof(struct darwin_utsname, nodename) == 256, "Darwin nodename at 256");
_Static_assert(__builtin_offsetof(struct linux_utsname,  nodename) == 65,  "glibc nodename at 65");

/* Exactly strlen+1 bytes and never more, matching what Darwin was measured to
 * do. The bound is the DESTINATION field's, not the source's. */
static void uts_put(char *dst, const char *src)
{
    size_t i = 0;
    while (src[i] && i < 255) { dst[i] = src[i]; i++; }
    dst[i] = 0;
}

static size_t uts_cat(char *dst, size_t at, const char *src)
{
    while (*src && at < 255) dst[at++] = *src++;
    dst[at] = 0;
    return at;
}

EXPORT int uname(struct darwin_utsname *u)
{
    struct linux_utsname l;
    size_t at;

    if (!u) { *mr_errno_slot() = 14; return -1; }   /* EFAULT, 14 on both */
    if (MR_ERRNO_CALL(glibc_uname(&l)) != 0) return -1;

    uts_put(u->sysname,  "Darwin");
    uts_put(u->nodename, l.nodename);
    uts_put(u->release,  l.release);
    uts_put(u->machine,  "arm64");

    at = uts_cat(u->version, 0, "machorun: a Darwin userland on ");
    at = uts_cat(u->version, at, l.sysname);
    at = uts_cat(u->version, at, " ");
    at = uts_cat(u->version, at, l.release);
    at = uts_cat(u->version, at, " ");
    (void)uts_cat(u->version, at, l.version);
    return 0;
}

/* sysdir_*: Darwin's search-path enumeration, behind NSSearchPathForDirectories
 * InDomains -- "where is the Caches directory", "where is Application Support".
 *
 * THIS RETURNS AN EMPTY ENUMERATION, AND THE CHOICE IS THE INTERESTING PART.
 * Linux has no Darwin domains at all: there is no ~/Library/Caches, no
 * /System, no notion of a user domain versus a local domain. The three
 * candidate answers are
 *
 *   invent XDG paths          -- ~/.cache for Caches, and so on. This is a
 *                                GUESS WITH A PLAUSIBLE FACE: the paths exist,
 *                                a caller would use them happily, and nothing
 *                                would ever reveal that Darwin means something
 *                                else by the domain it asked about.
 *   abort                     -- loud, but a query whose failure is routine on
 *                                Darwin (a sandboxed process legitimately has
 *                                no such directory) should not stop a process.
 *   enumerate nothing         -- what this does. `start` returns 0, which the
 *                                API already defines as "no more results", so
 *                                every correct caller's loop simply does not
 *                                execute.
 *
 * I have chosen the third because it is the only one that cannot be mistaken
 * for a real path. WHAT I DO NOT KNOW is what CoreFoundation does with an empty
 * enumeration -- I have not read its fallback, and that is the risk here rather
 * than the mechanism. Recorded in docs/UNIMPLEMENTED.md#sysdir-empty so whoever
 * has CF's sources can check it rather than rediscover it. */
EXPORT unsigned sysdir_start_search_path_enumeration(unsigned dir, unsigned domainMask)
{
    (void)dir; (void)domainMask;
    return 0;                                  /* the API's "no more results" */
}

EXPORT unsigned sysdir_get_next_search_path_enumeration(unsigned state, char *path)
{
    (void)state;
    if (path) path[0] = 0;                     /* never leave the caller's buffer stale */
    return 0;
}

/* _simple_asl_log is Apple SPI: the fallback branch of libdispatch's
 * _dispatch_log when no other destination is configured. It is NOT variadic
 * (level, facility, message), which is worth stating because the rest of the
 * _simple_asl family is. Sending it to stderr is what a Darwin process with no
 * syslog would do, and it keeps a diagnostic the guest chose to emit from
 * disappearing. */
EXPORT void _simple_asl_log(int level, const char *facility, const char *message)
{
    (void)level;
    if (!message) return;
    if (facility) {
        (void)write(2, facility, glibc_strlen(facility));
        (void)write(2, ": ", 2);
    }
    (void)write(2, message, glibc_strlen(message));
    (void)write(2, "\n", 1);
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
