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
