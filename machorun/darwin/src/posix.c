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

/* ===================================================================== *
 * The group database. The passwd family's sibling, and the interesting
 * result is that IT IS NOT THE PASSWD SHAPE.
 *
 * Measured on both sides before writing anything: `struct group` is 32 bytes
 * with gr_name/gr_passwd/gr_gid/gr_mem at 0/8/16/24 on BOTH systems. Darwin
 * adds no fields here the way it does to `struct passwd` (pw_change, pw_class
 * and pw_expire are what make that one 72 against 48), so there is no layout
 * to translate.
 *
 * THAT IS A FINDING, NOT A REASON TO STOP CHECKING. "Same size" was the
 * pthread_cond_t trap -- 48 on both, and only 40 bytes of Darwin's are ours.
 * So the mirrors and assertions below stay: they cost nothing and they turn a
 * future divergence into a build failure instead of a wrong gr_gid.
 * sdk/tests/glibc_abi_probe.c pins glibc's side against the REAL header, which
 * this file -- built -nostdinc for a Darwin target -- structurally cannot do.
 *
 * WHAT STILL CROSSES: the _r forms report errors AS THEIR RETURN VALUE, an
 * errno, exactly like the pthread family, so the VALUE needs translating even
 * though the struct does not. ERANGE happens to be 34 on both, which is
 * precisely the arrangement that makes this look unnecessary -- the one error
 * a caller usually tests for agrees, and the rest do not.
 *
 * And the contract that inverts easily, measured on both: "no such group" is
 * rc == 0 with *result == NULL, not an error return. A wrapper reporting
 * ENOENT there makes every correct caller's lookup fail. Same shape as
 * readdir_r (docs/UNIMPLEMENTED.md#readdir-r-contract).
 * ===================================================================== */
struct darwin_group {
    char     *gr_name;
    char     *gr_passwd;
    unsigned  gr_gid;
    char    **gr_mem;
};
struct linux_group {
    char     *gr_name;
    char     *gr_passwd;
    unsigned  gr_gid;
    char    **gr_mem;
};
_Static_assert(sizeof(struct darwin_group) == 32, "Darwin struct group is 32 bytes");
_Static_assert(sizeof(struct linux_group) == 32, "our mirror of glibc's struct group is 32 bytes");
_Static_assert(__builtin_offsetof(struct darwin_group, gr_gid) == 16, "gr_gid at 16");
_Static_assert(__builtin_offsetof(struct darwin_group, gr_mem) == 24, "gr_mem at 24");
_Static_assert(__builtin_offsetof(struct linux_group,  gr_mem) == 24,
    "if glibc ever moves gr_mem, group_l2d below stops being a copy");

/* Field by field rather than a struct assignment, so the day the layouts stop
 * agreeing this is the place that has to change and the assertions above are
 * what will say so. */
static void group_l2d(const struct linux_group *l, struct darwin_group *d)
{
    d->gr_name   = l->gr_name;
    d->gr_passwd = l->gr_passwd;
    d->gr_gid    = l->gr_gid;
    d->gr_mem    = l->gr_mem;
}

/* Static storage the next call overwrites -- the contract on both systems. */
static struct darwin_group gr_static;

EXPORT void *getgrnam(const char *name)
{
    struct linux_group *l = MR_ERRNO_CALL(glibc_getgrnam(name));
    if (!l) return 0;
    group_l2d(l, &gr_static);
    return &gr_static;
}

EXPORT void *getgrgid(unsigned gid)
{
    struct linux_group *l = MR_ERRNO_CALL(glibc_getgrgid(gid));
    if (!l) return 0;
    group_l2d(l, &gr_static);
    return &gr_static;
}

EXPORT int getgrnam_r(const char *name, struct darwin_group *out,
                      char *buf, unsigned long buflen, struct darwin_group **result)
{
    struct linux_group l;
    void *found = 0;
    int rc = MR_ERRNO_CALL(glibc_getgrnam_r(name, &l, buf, buflen, &found));
    if (result) *result = 0;
    if (rc != 0) return mr_pthread_rc(rc);   /* _r reports errno by return */
    if (!found) return 0;                    /* no such group: rc 0, *result NULL */
    group_l2d(&l, out);
    if (result) *result = out;
    return 0;
}

EXPORT int getgrgid_r(unsigned gid, struct darwin_group *out,
                      char *buf, unsigned long buflen, struct darwin_group **result)
{
    struct linux_group l;
    void *found = 0;
    int rc = MR_ERRNO_CALL(glibc_getgrgid_r(gid, &l, buf, buflen, &found));
    if (result) *result = 0;
    if (rc != 0) return mr_pthread_rc(rc);
    if (!found) return 0;
    group_l2d(&l, out);
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

/* Darwin AT_FDCWD is -2; Linux is -100. Passing the guest's -2 through is an
 * ordinary EBADF, which is why openat used to be denied rather than host-bound. */
#define D_AT_FDCWD (-2)
#define L_AT_FDCWD (-100)

static int linux_at_fd(int darwin_fd)
{
    return darwin_fd == D_AT_FDCWD ? L_AT_FDCWD : darwin_fd;
}

EXPORT int openat(int fd, const char *path, int flags, ...)
{
    unsigned mode = 0;
    if (flags & D_O_CREAT) {
        va_list ap;
        va_start(ap, flags);
        mode = va_arg(ap, unsigned);
        va_end(ap);
    }
    return MR_ERRNO_CALL(glibc_openat(linux_at_fd(fd), path,
                                      linux_open_flags(flags), mode));
}

/* Darwin named semaphores. sem_t is int (4 bytes); glibc's is a 32-byte
 * struct. A by-name bind would hand Darwin callers a pointer they treat as
 * int* into a glibc object, and SEM_FAILED is inverted ((sem_t *)-1 vs NULL).
 * The pointer we return is identity: wait/post/close recover the glibc
 * semaphore from the heap object. Unnamed sem_init is not this path. */
#define MR_SEM_MAGIC 0x53454d31 /* 'SEM1' */
#define D_SEM_FAILED ((void *)(intptr_t)-1)
struct mr_named_sem {
    int   magic;
    void *glibc;
};

EXPORT void *sem_open(const char *name, int oflag, ...)
{
    unsigned mode = 0, value = 0;
    void *gs;
    struct mr_named_sem *s;
    if (oflag & D_O_CREAT) {
        va_list ap;
        va_start(ap, oflag);
        mode = va_arg(ap, unsigned);
        value = va_arg(ap, unsigned);
        va_end(ap);
    }
    gs = MR_ERRNO_CALL(glibc_sem_open(name, linux_open_flags(oflag), mode, value));
    if (!gs) return D_SEM_FAILED;
    s = glibc_malloc(sizeof(*s));
    if (!s) {
        glibc_sem_close(gs);
        return D_SEM_FAILED;
    }
    s->magic = MR_SEM_MAGIC;
    s->glibc = gs;
    return s;
}

static void *mr_sem_glibc(void *p, const char *who)
{
    struct mr_named_sem *s = p;
    if (!s || s == D_SEM_FAILED || s->magic != MR_SEM_MAGIC)
        mr_bail2(who, "not a named semaphore this libSystem minted "
                 "(Darwin sem_t is int; unnamed sem_init is not implemented)");
    return s->glibc;
}

EXPORT int sem_close(void *s)
{
    struct mr_named_sem *m = s;
    void *gs;
    int rc;
    gs = mr_sem_glibc(s, "sem_close");
    rc = MR_ERRNO_CALL(glibc_sem_close(gs));
    m->magic = 0;
    glibc_free(m);
    return rc;
}

EXPORT int sem_unlink(const char *name)
{
    return MR_ERRNO_CALL(glibc_sem_unlink(name));
}

EXPORT int sem_wait(void *s)
{
    return MR_ERRNO_CALL(glibc_sem_wait(mr_sem_glibc(s, "sem_wait")));
}

EXPORT int sem_trywait(void *s)
{
    return MR_ERRNO_CALL(glibc_sem_trywait(mr_sem_glibc(s, "sem_trywait")));
}

EXPORT int sem_post(void *s)
{
    return MR_ERRNO_CALL(glibc_sem_post(mr_sem_glibc(s, "sem_post")));
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

/* Linux, aarch64 (asm-generic/stat.h) or x86_64 (asm/stat.h). Measured. */
#if defined(__x86_64__)
struct linux_stat {
    unsigned long st_dev;       /*   0 */
    unsigned long st_ino;       /*   8 */
    unsigned long st_nlink;     /*  16 -- 8-byte nlink_t */
    unsigned int  st_mode;      /*  24 */
    unsigned int  st_uid;       /*  28 */
    unsigned int  st_gid;       /*  32 */
    unsigned int  __pad0;       /*  36 */
    unsigned long st_rdev;      /*  40 */
    long          st_size;      /*  48 */
    long          st_blksize;   /*  56 -- 8 bytes on x86_64 */
    long          st_blocks;    /*  64 */
    long st_atime_sec; unsigned long st_atime_nsec;   /*  72 */
    long st_mtime_sec; unsigned long st_mtime_nsec;   /*  88 */
    long st_ctime_sec; unsigned long st_ctime_nsec;   /* 104 */
    long          __unused[3];  /* 120 */
};                              /* 144 */
_Static_assert(sizeof(struct linux_stat) == 144, "Linux x86_64 struct stat is 144 bytes");
_Static_assert(__builtin_offsetof(struct linux_stat, st_nlink) == 16, "x86_64 st_nlink at 16");
_Static_assert(__builtin_offsetof(struct linux_stat, st_mode) == 24, "x86_64 st_mode at 24");
#else
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
_Static_assert(sizeof(struct linux_stat) == 128, "Linux aarch64 struct stat is 128 bytes");
#endif
_Static_assert(sizeof(struct darwin_stat) == 144, "Darwin struct stat is 144 bytes");
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

/* ===================================================================== *
 * fts(3): glibc owns traversal; libSystem owns returned Darwin entry bytes.
 *
 * The shared low option bits and the info/instruction constants agree, but
 * Darwin additionally accepts COMFOLLOWDIR (0x400) and NOSTAT_TYPE (0x800),
 * giving it an option mask of 0xcff against glibc's 0xff. Those two options
 * are emulated explicitly. The structures are also incompatible: FTS happens
 * to be 72 bytes on both, while FTSENT is 112 bytes on Darwin and 120 on Linux,
 * with fts_level and every field after it shifted. Returning glibc's entry
 * would make the guest read fts_info out of Linux padding and fts_name beyond
 * the host allocation. The stat pointer is a second incompatible structure
 * (144 bytes versus 128), so it is translated too.
 *
 * A per-stream wrapper owns Darwin entry generations. glibc may free an
 * FTSENT and reuse its address for the same name, level, and parent; rewriting
 * the old mirror would silently transfer guest-owned number and pointer fields
 * to a new file allocation. Every translated host object receives a private
 * cookie in glibc's initialized-but-otherwise-user-owned fts_number field.
 * fts_alloc resets that cookie, so exact malloc reuse starts a fresh Darwin
 * generation. A root's one-time argv-to-basename fts_load mutation retains
 * its cookie. fts_set maps a live guest generation back to the glibc peer,
 * preserving FTS_SKIP/FTS_FOLLOW/FTS_AGAIN without inventing a second walker.
 *
 * Comparators cross through a pthread-local thunk. glibc calls the thunk with
 * Linux FTSENT ** values; it rebuilds both entries, invokes the guest's Darwin
 * callback, and returns the ordering result. The surrounding fts_open/read/
 * children call installs the owning stream in thread-local state, including
 * during fts_open's initial root sort. Nested traversals save and restore the
 * previous stream rather than stealing the outer comparator's context.
 * ===================================================================== */

struct linux_ftsent {
    struct linux_ftsent *fts_cycle;      /*   0 */
    struct linux_ftsent *fts_parent;     /*   8 */
    struct linux_ftsent *fts_link;       /*  16 */
    long                 fts_number;     /*  24 */
    void                *fts_pointer;    /*  32 */
    char                *fts_accpath;    /*  40 */
    char                *fts_path;       /*  48 */
    int                  fts_errno;      /*  56 */
    int                  fts_symfd;      /*  60 */
    uint16_t             fts_pathlen;    /*  64 */
    uint16_t             fts_namelen;    /*  66 */
    uint32_t             _pad0;          /*  68 */
    uint64_t             fts_ino;        /*  72 */
    uint64_t             fts_dev;        /*  80 */
#if defined(__x86_64__)
    uint64_t             fts_nlink;      /*  88 -- glibc x86_64 nlink_t is 8 bytes */
    short                fts_level;      /*  96 */
    uint16_t             fts_info;       /*  98 */
    uint16_t             fts_flags;      /* 100 */
    uint16_t             fts_instr;      /* 102 */
#else
    uint32_t             fts_nlink;      /*  88 */
    short                fts_level;      /*  92 */
    uint16_t             fts_info;       /*  94 */
    uint16_t             fts_flags;      /*  96 */
    uint16_t             fts_instr;      /*  98 */
    uint32_t             _pad1;          /* 100 */
#endif
    struct linux_stat   *fts_statp;      /* 104 */
    char                 fts_name[1];    /* 112 */
};                                         /* 120 */

/* The current field repairs glibc 2.39's uninitialized FTS_INIT dummy before
 * close-before-read. fts_compar is installed after COMFOLLOWDIR's root-only
 * normalization and private initial sort so later directory sorts still call
 * the guest comparator. Every observed offset is pinned against real headers. */
struct linux_fts {
    struct linux_ftsent  *fts_cur;         /*  0 */
    struct linux_ftsent  *fts_child;       /*  8 */
    struct linux_ftsent **fts_array;       /* 16 */
    uint64_t              fts_dev;         /* 24 */
    char                 *fts_path;        /* 32 */
    int                   fts_rfd;         /* 40 */
    int                   fts_pathlen;     /* 44 */
    int                   fts_nitems;      /* 48 */
    uint32_t              _pad0;           /* 52 */
    glibc_fts_compar_fn    fts_compar;     /* 56 */
    int                   fts_options;     /* 64 */
    uint32_t              _pad1;           /* 68 */
};                                         /* 72 */

struct darwin_ftsent {
    struct darwin_ftsent *fts_cycle;     /*   0 */
    struct darwin_ftsent *fts_parent;    /*   8 */
    struct darwin_ftsent *fts_link;      /*  16 */
    long                  fts_number;    /*  24 */
    void                 *fts_pointer;   /*  32 */
    char                 *fts_accpath;   /*  40 */
    char                 *fts_path;      /*  48 */
    int                   fts_errno;     /*  56 */
    int                   fts_symfd;     /*  60 */
    uint16_t              fts_pathlen;   /*  64 */
    uint16_t              fts_namelen;   /*  66 */
    uint64_t              fts_ino;       /*  72 (four bytes of ABI padding) */
    int32_t               fts_dev;       /*  80 */
    uint16_t              fts_nlink;     /*  84 */
    short                 fts_level;     /*  86 */
    uint16_t              fts_info;      /*  88 */
    uint16_t              fts_flags;     /*  90 */
    uint16_t              fts_instr;     /*  92 */
    struct darwin_stat   *fts_statp;     /*  96 */
    char                  fts_name[1];   /* 104 */
};                                         /* 112 */

typedef int (*darwin_fts_compar)(const struct darwin_ftsent **,
                                 const struct darwin_ftsent **);

struct darwin_fts {
    struct darwin_ftsent  *fts_cur;      /*   0 */
    struct darwin_ftsent  *fts_child;    /*   8 */
    struct darwin_ftsent **fts_array;    /*  16 */
    int32_t                fts_dev;      /*  24 */
    uint32_t               _pad0;        /*  28 */
    char                  *fts_path;     /*  32 */
    int                    fts_rfd;      /*  40 */
    int                    fts_pathlen;  /*  44 */
    int                    fts_nitems;   /*  48 */
    uint32_t               _pad1;        /*  52 */
    darwin_fts_compar      fts_compar;   /*  56 */
    int                    fts_options;  /*  64 */
    uint32_t               _pad2;        /*  68 */
};                                         /*  72 */

_Static_assert(sizeof(struct linux_ftsent) == 120,
               "glibc FTSENT is 120 bytes");
#if defined(__x86_64__)
_Static_assert(__builtin_offsetof(struct linux_ftsent, fts_level) == 96,
               "glibc x86_64 FTSENT.fts_level is at 96");
_Static_assert(__builtin_offsetof(struct linux_ftsent, fts_info) == 98,
               "glibc x86_64 FTSENT.fts_info is at 98");
#else
_Static_assert(__builtin_offsetof(struct linux_ftsent, fts_level) == 92,
               "glibc aarch64 FTSENT.fts_level is at 92");
_Static_assert(__builtin_offsetof(struct linux_ftsent, fts_info) == 94,
               "glibc aarch64 FTSENT.fts_info is at 94");
#endif
_Static_assert(__builtin_offsetof(struct linux_ftsent, fts_statp) == 104,
               "glibc FTSENT.fts_statp is at 104");
_Static_assert(__builtin_offsetof(struct linux_ftsent, fts_name) == 112,
               "glibc FTSENT.fts_name is at 112");
_Static_assert(sizeof(struct linux_fts) == 72,
               "glibc FTS is 72 bytes");
_Static_assert(__builtin_offsetof(struct linux_fts, fts_compar) == 56,
               "glibc aarch64 FTS.fts_compar is at 56");
_Static_assert(__builtin_offsetof(struct linux_fts, fts_options) == 64,
               "glibc aarch64 FTS.fts_options is at 64");
_Static_assert(sizeof(struct darwin_ftsent) == 112,
               "Darwin arm64 FTSENT is 112 bytes");
_Static_assert(__builtin_offsetof(struct darwin_ftsent, fts_level) == 86,
               "Darwin arm64 FTSENT.fts_level is at 86");
_Static_assert(__builtin_offsetof(struct darwin_ftsent, fts_info) == 88,
               "Darwin arm64 FTSENT.fts_info is at 88");
_Static_assert(__builtin_offsetof(struct darwin_ftsent, fts_statp) == 96,
               "Darwin arm64 FTSENT.fts_statp is at 96");
_Static_assert(__builtin_offsetof(struct darwin_ftsent, fts_name) == 104,
               "Darwin arm64 FTSENT.fts_name is at 104");
_Static_assert(sizeof(struct darwin_fts) == 72,
               "Darwin arm64 FTS is 72 bytes");

#define MR_FTS_MAGIC 0x4d52465453563101ULL
#define D_FTS_OPTIONMASK 0xcff
#define D_FTS_COMFOLLOW 0x001
#define D_FTS_LOGICAL 0x002
#define D_FTS_NOCHDIR 0x004
#define D_FTS_NOSTAT 0x008
#define D_FTS_PHYSICAL 0x010
#define D_FTS_COMFOLLOWDIR 0x400
#define D_FTS_NOSTAT_TYPE 0x800
#define D_FTS_ROOTPARENTLEVEL (-1)
#define D_FTS_D 1
#define D_FTS_DC 2
#define D_FTS_DEFAULT 3
#define D_FTS_DNR 4
#define D_FTS_DOT 5
#define D_FTS_DP 6
#define D_FTS_ERR 7
#define D_FTS_F 8
#define D_FTS_INIT 9
#define D_FTS_NSOK 11
#define D_FTS_SL 12
#define D_FTS_SLNONE 13
#define D_FTS_SYMFOLLOW 0x02
#define D_FTS_NOINSTR 3
#define MR_FTS_COMPARATOR_ENTRY 0x01
#define MR_FTS_PRELOAD_ENTRY 0x02

struct mr_fts_entry {
    struct linux_ftsent *linux;
    struct darwin_ftsent *darwin;
    struct darwin_stat stat;
    size_t name_capacity;
    struct darwin_ftsent *identity_parent;
    short identity_level;
    long host_cookie;
    int identity_set;
    int preloaded_root;
    struct mr_fts_entry *next;
};

struct mr_fts {
    struct darwin_fts public;
    uint64_t magic;
    void *linux;
    struct mr_fts_entry *entries;
    int compar_error;
    int started;
    int darwin_options;
    int host_options;
    uint64_t next_cookie;
    struct darwin_ftsent *device_root;
    int32_t root_device;
};

static unsigned mr_fts_compar_key;
static int mr_fts_compar_key_state; /* 0 = none, 1 = building, 2 = ready */

static void mr_fts_compar_key_init(void)
{
    int expect = 0;
    if (__atomic_load_n(&mr_fts_compar_key_state, __ATOMIC_ACQUIRE) == 2)
        return;
    if (__atomic_compare_exchange_n(&mr_fts_compar_key_state, &expect, 1, 0,
                                    __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE)) {
        if (glibc_pthread_key_create(&mr_fts_compar_key, 0) != 0)
            mr_bail("pthread_key_create failed while setting up fts comparator");
        __atomic_store_n(&mr_fts_compar_key_state, 2, __ATOMIC_RELEASE);
        return;
    }
    while (__atomic_load_n(&mr_fts_compar_key_state, __ATOMIC_ACQUIRE) != 2)
        glibc_sched_yield();
}

static struct mr_fts *mr_fts_compar_enter(struct mr_fts *state)
{
    struct mr_fts *previous;
    mr_fts_compar_key_init();
    previous = glibc_pthread_getspecific(mr_fts_compar_key);
    if (glibc_pthread_setspecific(mr_fts_compar_key, state) != 0)
        mr_bail("pthread_setspecific failed while entering fts comparator");
    return previous;
}

static void mr_fts_compar_leave(struct mr_fts *previous)
{
    if (glibc_pthread_setspecific(mr_fts_compar_key, previous) != 0)
        mr_bail("pthread_setspecific failed while leaving fts comparator");
}

static struct mr_fts *mr_fts_state(struct darwin_fts *fts)
{
    struct mr_fts *state = (struct mr_fts *)fts;
    if (!state || state->magic != MR_FTS_MAGIC) {
        *mr_errno_slot() = 22;             /* Darwin EINVAL */
        return 0;
    }
    return state;
}

static struct mr_fts_entry *mr_fts_find_linux(
    struct mr_fts *state, struct linux_ftsent *linux)
{
    struct mr_fts_entry *entry;
    if (!linux) return 0;
    for (entry = state->entries; entry; entry = entry->next)
        if (entry->linux == linux) return entry;
    return 0;
}

static struct mr_fts_entry *mr_fts_find_darwin(
    struct mr_fts *state, struct darwin_ftsent *darwin)
{
    struct mr_fts_entry *entry;
    if (!darwin) return 0;
    for (entry = state->entries; entry; entry = entry->next)
        if (entry->darwin == darwin) return entry;
    return 0;
}

static struct mr_fts_entry *mr_fts_new_entry(
    struct mr_fts *state, struct linux_ftsent *linux, uint16_t namelen)
{
    struct mr_fts_entry *entry;
    size_t bytes;
    if (!linux) return 0;
    /* fts_number is initialized to zero by glibc's fts_alloc and is never
     * consumed by the host traversal. Use it as a private live-allocation
     * cookie. malloc can recycle the exact same address for the exact same
     * name/parent/level after fts_children or FTS_AGAIN; the reset cookie is
     * the only reliable way to distinguish that new native object. Guest
     * fts_number remains exclusively in the Darwin mirror. */
    if (state->next_cookie == 0x7fffffffffffffffULL) {
        *mr_errno_slot() = 84;             /* Darwin EOVERFLOW */
        return 0;
    }
    entry = glibc_calloc(1, sizeof *entry);
    if (!entry) {
        *mr_errno_slot() = 12;             /* Darwin ENOMEM */
        return 0;
    }
    /* Apple's allocator uses sizeof(FTSENT)+namelen: the declared object is
     * never underallocated for short names, while the trailing storage holds
     * the complete NUL-terminated component. */
    bytes = sizeof(struct darwin_ftsent) + (size_t)namelen;
    entry->darwin = glibc_calloc(1, bytes);
    if (!entry->darwin) {
        glibc_free(entry);
        *mr_errno_slot() = 12;
        return 0;
    }
    entry->linux = linux;
    entry->host_cookie = (long)++state->next_cookie;
    linux->fts_number = entry->host_cookie;
    entry->name_capacity = bytes
        - __builtin_offsetof(struct darwin_ftsent, fts_name);
    entry->next = state->entries;
    state->entries = entry;
    return entry;
}

static void mr_fts_retire_entry(
    struct mr_fts *state, struct mr_fts_entry *entry)
{
    struct mr_fts_entry **cursor = &state->entries;
    while (*cursor && *cursor != entry) cursor = &(*cursor)->next;
    if (*cursor != entry) return;
    *cursor = entry->next;
    glibc_free(entry->darwin);
    glibc_free(entry);
}

static struct mr_fts_entry *mr_fts_entry_for_identity(
    struct mr_fts *state, struct linux_ftsent *linux,
    struct darwin_ftsent *parent, int preload, int *is_new)
{
    struct mr_fts_entry *entry = mr_fts_find_linux(state, linux);
    int cookie_matches = entry && entry->host_cookie != 0 &&
        linux->fts_number == entry->host_cookie;
    int exact = cookie_matches && entry->identity_set &&
        entry->identity_parent == parent &&
        entry->identity_level == linux->fts_level &&
        entry->darwin->fts_namelen == linux->fts_namelen &&
        glibc_strcmp(entry->darwin->fts_name, linux->fts_name) == 0;
    int root_load = cookie_matches && entry->identity_set &&
        entry->preloaded_root && !preload && linux->fts_level == 0 &&
        entry->identity_parent == parent &&
        (size_t)linux->fts_namelen + 1 <= entry->name_capacity;
    int same = exact || root_load;

    if (!same) {
        /* A mismatching logical identity at the same glibc address means the
         * host freed and recycled that FTSENT. Native code has invalidated the
         * old pointer too, so retire it: retaining it would leak per visited
         * node and a stale fts_set could target the unrelated replacement. */
        if (entry) mr_fts_retire_entry(state, entry);
        entry = mr_fts_new_entry(state, linux, linux->fts_namelen);
        if (!entry) return 0;
        entry->identity_set = 1;
        entry->identity_parent = parent;
        entry->identity_level = linux->fts_level;
        entry->preloaded_root = preload && linux->fts_level == 0;
        /* Apple's fts_alloc zeroes these guest-owned fields. The host's
         * fts_number now contains our private cookie and must never escape. */
        entry->darwin->fts_number = 0;
        entry->darwin->fts_pointer = 0;
    } else if (!preload) {
        /* fts_load mutates a root's name from the argv spelling to its
         * basename. It is the same native object and must retain comparator/
         * pre-read guest state and pointer identity across that transition. */
        entry->preloaded_root = 0;
    }
    entry->darwin->fts_namelen = linux->fts_namelen;
    glibc_memcpy(entry->darwin->fts_name, linux->fts_name,
                 (size_t)linux->fts_namelen + 1);
    *is_new = !same;
    return entry;
}

static struct darwin_ftsent *mr_fts_root_parent_for(
    struct mr_fts *state, struct linux_ftsent *linux, char *root_path)
{
    struct mr_fts_entry *entry;
    struct darwin_ftsent *darwin;
    int is_new = 0;
    entry = mr_fts_entry_for_identity(state, linux, 0, 0, &is_new);
    if (!entry) return 0;
    darwin = entry->darwin;
    glibc_memset(&entry->stat, 0, sizeof entry->stat);
    darwin->fts_cycle = 0;
    darwin->fts_parent = 0;
    darwin->fts_link = 0;
    if (is_new) {
        darwin->fts_number = 0;
        darwin->fts_pointer = 0;
    }
    darwin->fts_accpath = 0;
    darwin->fts_path = root_path;
    darwin->fts_errno = 0;
    darwin->fts_symfd = -1;
    darwin->fts_pathlen = 0;
    darwin->fts_namelen = 0;
    darwin->fts_ino = 0;
    darwin->fts_dev = 0;
    darwin->fts_nlink = 0;
    darwin->fts_level = D_FTS_ROOTPARENTLEVEL;
    darwin->fts_info = 0;
    darwin->fts_flags = 0;
    darwin->fts_instr = D_FTS_NOINSTR;
    darwin->fts_statp = (state->darwin_options & D_FTS_NOSTAT)
        ? 0 : &entry->stat;
    darwin->fts_name[0] = '\0';
    return darwin;
}

static struct darwin_ftsent *mr_fts_translate(
    struct mr_fts *state, struct linux_ftsent *linux, unsigned context)
{
    struct mr_fts_entry *entry;
    struct mr_fts_entry *related_entry;
    struct darwin_ftsent *darwin;
    struct darwin_ftsent *parent = 0;
    char *safe_path;
    uint16_t safe_pathlen;
    int is_new;
    int preload;
    if (!linux) return 0;

    preload = (context & MR_FTS_PRELOAD_ENTRY) ||
        ((context & MR_FTS_COMPARATOR_ENTRY) && !state->linux);
    if (preload) {
        /* Before fts_load, glibc's shared fts_path and fts_pathlen are
         * indeterminate. fts_accpath is the initialized input spelling. */
        safe_path = linux->fts_accpath;
        safe_pathlen = 0;
    } else {
        safe_path = linux->fts_path;
        safe_pathlen = linux->fts_pathlen;
    }

    if (linux->fts_parent) {
        if (linux->fts_level == 0) {
            parent = mr_fts_root_parent_for(
                state, linux->fts_parent, safe_path);
            if (!parent) return 0;
        } else {
            related_entry = mr_fts_find_linux(state, linux->fts_parent);
            if (!related_entry) {
                *mr_errno_slot() = 22;     /* impossible relation: fail closed */
                return 0;
            }
            parent = related_entry->darwin;
        }
    }

    entry = mr_fts_entry_for_identity(
        state, linux, parent, preload, &is_new);
    if (!entry) return 0;
    darwin = entry->darwin;

    /* glibc leaves fts_cycle indeterminate except on FTS_DC entries, and
     * fts_link is public only on the list returned by fts_children. Reading
     * either unconditionally turns their garbage bytes into a pointer and was
     * caught by the fixture at the root's final FTS_DP entry. */
    darwin->fts_cycle = 0;
    if (linux->fts_info == D_FTS_DC && linux->fts_cycle) {
        related_entry = mr_fts_find_linux(state, linux->fts_cycle);
        if (!related_entry) {
            *mr_errno_slot() = 22;
            return 0;
        }
        darwin->fts_cycle = related_entry->darwin;
    }
    darwin->fts_parent = parent;
    darwin->fts_link = 0;
    darwin->fts_accpath = linux->fts_accpath;
    darwin->fts_path = safe_path;
    darwin->fts_pathlen = safe_pathlen;
    darwin->fts_errno = darwin_from_linux_errno(linux->fts_errno);
    /* SYMFOLLOW is initialized and is set only after glibc assigns symfd. It
     * remains set through DP and DNR/ERR transitions, matching shipping
     * Darwin's observable retained (already closed at DP) descriptor value. */
    darwin->fts_symfd = (linux->fts_flags & D_FTS_SYMFOLLOW)
        ? linux->fts_symfd : -1;
    darwin->fts_namelen = linux->fts_namelen;
    darwin->fts_level = linux->fts_level;
    darwin->fts_info = linux->fts_info;
    darwin->fts_flags = linux->fts_flags;
    /* glibc consumes and resets instructions as the traversal advances.
     * Copy on every observation; number and pointer are the only fields the
     * guest owns and therefore the only ones retained in a generation. */
    darwin->fts_instr = linux->fts_instr;
    glibc_memcpy(darwin->fts_name, linux->fts_name,
                 (size_t)linux->fts_namelen + 1);

    if (state->darwin_options & D_FTS_NOSTAT) {
        darwin->fts_statp = 0;
    } else if (linux->fts_info == D_FTS_NSOK) {
        /* fts_alloc deliberately leaves the host stat bytes uninitialized in
         * a NAMEONLY/NSOK list. Apple exposes a valid zero stat in this mode. */
        glibc_memset(&entry->stat, 0, sizeof entry->stat);
        darwin->fts_statp = &entry->stat;
    } else if (linux->fts_statp) {
        stat_l2d(linux->fts_statp, &entry->stat);
        darwin->fts_statp = &entry->stat;
    } else {
        darwin->fts_statp = 0;
    }

    if (linux->fts_info == D_FTS_D || linux->fts_info == D_FTS_DC ||
        linux->fts_info == D_FTS_DOT || linux->fts_info == D_FTS_DP) {
        /* glibc 2.39 initializes these scalar fields for directories even
         * under FTS_NOSTAT, where fts_statp is intentionally null. They are
         * indeterminate for non-directories, so the info guard is mandatory. */
        darwin->fts_ino = linux->fts_ino;
        darwin->fts_dev = (int32_t)linux->fts_dev;
        darwin->fts_nlink = (uint16_t)linux->fts_nlink;
    } else if (!is_new &&
               (linux->fts_info == D_FTS_DNR ||
                linux->fts_info == D_FTS_ERR)) {
        /* Apple retains directory identity if the same entry transitions to
         * DNR/ERR. The generation already carries those values. */
    } else {
        darwin->fts_ino = 0;
        darwin->fts_dev = 0;
        darwin->fts_nlink = 0;
    }
    return darwin;
}

static int mr_fts_compar_bridge(const void *left, const void *right)
{
    const struct linux_ftsent *const *linux_left = left;
    const struct linux_ftsent *const *linux_right = right;
    const struct darwin_ftsent *darwin_left;
    const struct darwin_ftsent *darwin_right;
    struct mr_fts *state;

    mr_fts_compar_key_init();
    state = glibc_pthread_getspecific(mr_fts_compar_key);
    if (!state || !state->public.fts_compar)
        mr_bail("fts comparator invoked without its owning stream");
    darwin_left = mr_fts_translate(
        state, (struct linux_ftsent *)*linux_left, MR_FTS_COMPARATOR_ENTRY);
    darwin_right = mr_fts_translate(
        state, (struct linux_ftsent *)*linux_right, MR_FTS_COMPARATOR_ENTRY);
    if (!darwin_left || !darwin_right) {
        state->compar_error = *mr_errno_slot() ? *mr_errno_slot() : 12;
        return 0;
    }
    return state->public.fts_compar(&darwin_left, &darwin_right);
}

static int mr_fts_internal_stat(
    const char *path, struct linux_stat *out, int follow)
{
    int saved = *mr_errno_slot();
    int rc = follow
        ? MR_ERRNO_CALL(glibc_stat(path, out))
        : MR_ERRNO_CALL(glibc_lstat(path, out));
    /* These probes implement an fts_open option; they are not a guest call and
     * must not replace the successful open's observable errno value. */
    *mr_errno_slot() = saved;
    return rc;
}

static void mr_fts_normalize_comfollowdir(
    struct mr_fts *state, void *linux_stream)
{
    struct linux_ftsent *initial =
        ((struct linux_fts *)linux_stream)->fts_cur;
    struct linux_ftsent *root;
    struct linux_stat link_stat, target_stat;
    const unsigned mode_mask = 0170000;
    const unsigned mode_directory = 0040000;
    const unsigned mode_symlink = 0120000;

    if (!initial) return;
    for (root = initial->fts_link; root; root = root->fts_link) {
        if (mr_fts_internal_stat(root->fts_accpath, &link_stat, 0) != 0 ||
            (link_stat.st_mode & mode_mask) != mode_symlink)
            continue;
        if (mr_fts_internal_stat(root->fts_accpath, &target_stat, 1) != 0)
            continue;                       /* host already exposes SLNONE */
        if ((target_stat.st_mode & mode_mask) == mode_directory)
            continue;                       /* COMFOLLOW result is exact */

        /* glibc's global COMFOLLOW followed a non-directory root symlink.
         * Apple's COMFOLLOWDIR performs this lstat fallback inside fts_stat.
         * Restore that host entry before sorting or the first fts_read. */
        root->fts_info = D_FTS_SL;
        root->fts_errno = 0;
        if (!(state->host_options & D_FTS_NOSTAT) && root->fts_statp)
            glibc_memcpy(root->fts_statp, &link_stat, sizeof link_stat);
    }
}

static int mr_fts_sort_initial_roots(
    struct mr_fts *state, void *linux_stream)
{
    struct linux_ftsent *initial =
        ((struct linux_fts *)linux_stream)->fts_cur;
    struct linux_ftsent *root;
    struct linux_ftsent **array;
    struct mr_fts *previous;
    size_t count = 0, i = 0;
    if (!initial) return 0;
    for (root = initial->fts_link; root; root = root->fts_link) count++;
    if (count < 2) return 0;
    array = glibc_malloc(count * sizeof *array);
    if (!array) {
        *mr_errno_slot() = 12;
        return -1;
    }
    for (root = initial->fts_link; root; root = root->fts_link)
        array[i++] = root;

    state->compar_error = 0;
    previous = mr_fts_compar_enter(state);
    glibc_qsort(array, count, sizeof *array, mr_fts_compar_bridge);
    mr_fts_compar_leave(previous);
    if (state->compar_error) {
        glibc_free(array);
        *mr_errno_slot() = state->compar_error;
        return -1;
    }
    initial->fts_link = array[0];
    for (i = 1; i < count; i++) array[i - 1]->fts_link = array[i];
    array[count - 1]->fts_link = 0;
    glibc_free(array);
    return 0;
}

static void mr_fts_free_entries(struct mr_fts *state)
{
    struct mr_fts_entry *entry, *next;
    for (entry = state->entries; entry; entry = next) {
        next = entry->next;
        glibc_free(entry->darwin);
        glibc_free(entry);
    }
    state->entries = 0;
}

static void mr_fts_update_public_device(
    struct mr_fts *state, struct darwin_ftsent *darwin)
{
    if (darwin->fts_level == 0) {
        if (state->device_root != darwin) {
            /* fts_load starts a new command-line root. Apple's calloc-backed
             * stream exposes zero for file/symlink/error roots; glibc's
             * private fts_dev is indeterminate in exactly those cases. */
            state->device_root = darwin;
            state->root_device = 0;
            if (darwin->fts_info == D_FTS_D ||
                darwin->fts_info == D_FTS_DC ||
                darwin->fts_info == D_FTS_DOT ||
                darwin->fts_info == D_FTS_DP)
                state->root_device = darwin->fts_dev;
        }
        /* Every same-root transition retains the fts_load value, including
         * D->DP/DNR/ERR and a followed symlink's SL->D->DP sequence. */
    }
    state->public.fts_dev = state->root_device;
}

EXPORT struct darwin_fts *fts_open(
    char *const *paths, int options, darwin_fts_compar compar)
{
    struct mr_fts *state;
    struct mr_fts *previous = 0;
    void *linux;
    int darwin_options = options;
    int host_options = options;
    int host_comparator;
    int private_sort;

    if (options & ~D_FTS_OPTIONMASK) {
        *mr_errno_slot() = 22;
        return 0;
    }
    state = glibc_calloc(1, sizeof *state);
    if (!state) {
        *mr_errno_slot() = 12;
        return 0;
    }
    state->magic = MR_FTS_MAGIC;

    /* Darwin's NOSTAT_TYPE is a richer d_type-based NOSTAT. glibc has no
     * equivalent, so deliberately take the more expensive exact route: let
     * glibc stat and classify every entry, then hide statp as Darwin requires.
     * This preserves values and traversal at the cost of the optimization. */
    if (options & D_FTS_NOSTAT_TYPE) {
        darwin_options |= D_FTS_NOSTAT;
        host_options &= ~(D_FTS_NOSTAT_TYPE | D_FTS_NOSTAT);
    }
    /* COMFOLLOWDIR is root-only and follows only directory targets. Ask
     * glibc to follow roots, then lstat-normalize non-directory symlinks. */
    if (options & D_FTS_COMFOLLOWDIR) {
        host_options &= ~D_FTS_COMFOLLOWDIR;
        host_options |= D_FTS_COMFOLLOW;
    }
    if (darwin_options & D_FTS_LOGICAL)
        darwin_options |= D_FTS_NOCHDIR;

    /* Guest code can write the public FTS structure. Safety/exposure guards
     * use immutable copies of both the Darwin and translated host options. */
    state->darwin_options = darwin_options;
    state->host_options = host_options;
    state->public.fts_options = darwin_options;
    state->public.fts_compar = compar;
    private_sort = compar && (options & D_FTS_COMFOLLOWDIR);
    host_comparator = compar && !private_sort;
    if (host_comparator) previous = mr_fts_compar_enter(state);
    linux = MR_ERRNO_CALL(glibc_fts_open(
        paths, host_options, host_comparator ? mr_fts_compar_bridge : 0));
    if (host_comparator) mr_fts_compar_leave(previous);
    if (linux) {
        struct linux_ftsent *initial =
            ((struct linux_fts *)linux)->fts_cur;
        if (initial && initial->fts_info == D_FTS_INIT)
            initial->fts_level = 1;
        if (options & D_FTS_COMFOLLOWDIR)
            mr_fts_normalize_comfollowdir(state, linux);
        if (private_sort) {
            if (mr_fts_sort_initial_roots(state, linux) != 0 &&
                !state->compar_error)
                state->compar_error = *mr_errno_slot()
                    ? *mr_errno_slot() : 12;
            if (!state->compar_error)
                ((struct linux_fts *)linux)->fts_compar =
                    mr_fts_compar_bridge;
        }
    }
    if (!linux || state->compar_error) {
        int saved = state->compar_error;
        if (linux) (void)MR_ERRNO_CALL(glibc_fts_close(linux));
        mr_fts_free_entries(state);
        state->magic = 0;
        glibc_free(state);
        if (saved) *mr_errno_slot() = saved;
        return 0;
    }
    state->linux = linux;
    return &state->public;
}

EXPORT struct darwin_ftsent *fts_read(struct darwin_fts *fts)
{
    struct mr_fts *state = mr_fts_state(fts);
    struct mr_fts *previous = 0;
    struct linux_ftsent *linux;
    struct darwin_ftsent *darwin;
    if (!state) return 0;
    state->compar_error = 0;
    if (state->public.fts_compar) previous = mr_fts_compar_enter(state);
    linux = MR_ERRNO_CALL(glibc_fts_read(state->linux));
    if (state->public.fts_compar) mr_fts_compar_leave(previous);
    /* A read ends the public fts_children exposure. The host may consume,
     * retain, or replace its private list depending on the instruction, but
     * no stale list head is published through the Darwin shell. */
    state->public.fts_child = 0;
    if (state->compar_error) {
        *mr_errno_slot() = state->compar_error;
        state->public.fts_cur = 0;
        return 0;
    }
    if (!linux) {
        state->public.fts_cur = 0;
        return 0;
    }
    darwin = mr_fts_translate(state, linux, 0);
    if (!darwin) {
        state->public.fts_cur = 0;
        return 0;
    }
    state->started = 1;
    state->public.fts_cur = darwin;
    state->public.fts_path = darwin->fts_path;
    /* FTS.fts_dev is the current root's starting device, not the current
     * entry's device. Never read glibc's field here: it is indeterminate for
     * file/symlink roots in 2.39. */
    mr_fts_update_public_device(state, darwin);
    return darwin;
}

EXPORT struct darwin_ftsent *fts_children(struct darwin_fts *fts, int instr)
{
    struct mr_fts *state = mr_fts_state(fts);
    struct mr_fts *previous = 0;
    struct linux_ftsent *head, *cursor;
    struct darwin_ftsent *darwin_head = 0;
    unsigned context;
    int pre_read;
    if (!state) return 0;
    /* The host call can free the prior list even if its replacement later
     * fails to translate. Publish a child pointer only after both passes have
     * completed successfully. */
    state->public.fts_child = 0;
    pre_read = !state->started;
    context = pre_read ? MR_FTS_PRELOAD_ENTRY : 0;
    state->compar_error = 0;
    if (state->public.fts_compar) previous = mr_fts_compar_enter(state);
    head = MR_ERRNO_CALL(glibc_fts_children(state->linux, instr));
    if (state->public.fts_compar) mr_fts_compar_leave(previous);
    if (state->compar_error) {
        *mr_errno_slot() = state->compar_error;
        state->public.fts_child = 0;
        return 0;
    }
    if (!head) {
        state->public.fts_child = 0;
        return 0;
    }
    /* First establish every generation, then wire the list. If glibc has
     * recycled an address, a one-pass translation can point an earlier item
     * at that address's obsolete generation before the new one is discovered. */
    for (cursor = head; cursor; cursor = cursor->fts_link) {
        struct darwin_ftsent *translated = mr_fts_translate(
            state, cursor, context);
        if (!translated) return 0;
        if (!darwin_head) darwin_head = translated;
    }
    for (cursor = head; cursor; cursor = cursor->fts_link) {
        struct mr_fts_entry *source = mr_fts_find_linux(state, cursor);
        struct mr_fts_entry *target = cursor->fts_link
            ? mr_fts_find_linux(state, cursor->fts_link) : 0;
        if (!source || (cursor->fts_link && !target)) {
            *mr_errno_slot() = 22;
            return 0;
        }
        source->darwin->fts_link = target ? target->darwin : 0;
    }
    /* Before the first read Darwin returns the root list but leaves the
     * public fts_child field null; directory child lists populate it. */
    if (!pre_read) state->public.fts_child = darwin_head;
    return darwin_head;
}

EXPORT int fts_set(struct darwin_fts *fts,
                   struct darwin_ftsent *entry, int instr)
{
    struct mr_fts *state = mr_fts_state(fts);
    struct mr_fts_entry *mapped;
    int rc;
    if (!state) return -1;
    mapped = mr_fts_find_darwin(state, entry);
    if (!mapped) {
        *mr_errno_slot() = 22;
        return -1;
    }
    rc = MR_ERRNO_CALL(glibc_fts_set(state->linux, mapped->linux, instr));
    if (rc == 0) mapped->darwin->fts_instr = (uint16_t)instr;
    return rc;
}

EXPORT int fts_close(struct darwin_fts *fts)
{
    struct mr_fts *state = mr_fts_state(fts);
    int rc;
    if (!state) return -1;
    rc = MR_ERRNO_CALL(glibc_fts_close(state->linux));
    mr_fts_free_entries(state);
    state->magic = 0;
    glibc_free(state);
    return rc;
}

#if defined(__x86_64__)
/* x86_64 Darwin headers emit _fts_*$INODE64; arm64 binds the plain names.
 * Keep these aliases off the arm64 dylib so its export list stays as it was. */
EXPORT struct darwin_fts *mr_fts_open64(char *const *p, int o, darwin_fts_compar c)
    __asm__("_fts_open$INODE64");
EXPORT struct darwin_fts *mr_fts_open64(char *const *p, int o, darwin_fts_compar c)
    { return fts_open(p, o, c); }
EXPORT struct darwin_ftsent *mr_fts_read64(struct darwin_fts *f)
    __asm__("_fts_read$INODE64");
EXPORT struct darwin_ftsent *mr_fts_read64(struct darwin_fts *f)
    { return fts_read(f); }
EXPORT struct darwin_ftsent *mr_fts_children64(struct darwin_fts *f, int i)
    __asm__("_fts_children$INODE64");
EXPORT struct darwin_ftsent *mr_fts_children64(struct darwin_fts *f, int i)
    { return fts_children(f, i); }
EXPORT int mr_fts_set64(struct darwin_fts *f, struct darwin_ftsent *e, int i)
    __asm__("_fts_set$INODE64");
EXPORT int mr_fts_set64(struct darwin_fts *f, struct darwin_ftsent *e, int i)
    { return fts_set(f, e, i); }
EXPORT int mr_fts_close64(struct darwin_fts *f) __asm__("_fts_close$INODE64");
EXPORT int mr_fts_close64(struct darwin_fts *f) { return fts_close(f); }
#endif

/* ------------------------------------------------------------- the rest of
 * the file surface. Every one of these is bracketed for errno; that is the
 * only reason they are not one-line forwarders. */

EXPORT ssize_t read(int fd, void *b, size_t n)        { return MR_ERRNO_CALL(glibc_read(fd, b, n)); }
EXPORT ssize_t write(int fd, const void *b, size_t n) { return MR_ERRNO_CALL(glibc_write(fd, b, n)); }
EXPORT int     close(int fd)                          { return MR_ERRNO_CALL(glibc_close(fd)); }
EXPORT off_t   lseek(int fd, off_t off, int whence)   { return MR_ERRNO_CALL(glibc_lseek(fd, off, whence)); }
EXPORT int     mkdir(const char *p, unsigned m)       { return MR_ERRNO_CALL(glibc_mkdir(p, m)); }
EXPORT int     mkfifo(const char *p, unsigned m)      { return MR_ERRNO_CALL(glibc_mkfifo(p, m)); }
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
#if defined(__x86_64__)
/* clang on Darwin/x86_64 emits ___bzero for memset(,0,) rather than inlining.
 * The arm64 backend does not. Same bytes as bzero; a distinct symbol so a
 * guest that calls it does not die at bind time. */
EXPORT void __bzero(void *d, size_t n)                 { glibc_memset(d, 0, n); }
#endif
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

/* CLOCK_* disagree (Darwin CLOCK_MONOTONIC is 6, Linux's is 1 — Darwin 6 is
 * Linux CLOCK_MONOTONIC_COARSE). timespec layout agrees ({long,long} 16 bytes
 * both sides). Not host-bound. */
EXPORT int clock_getres(int clk, void *ts)
{
    return MR_ERRNO_CALL(glibc_clock_getres(mr_linux_clock_id(clk), ts));
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

#if defined(__x86_64__)
EXPORT void *mr_opendir64(const char *p) __asm__("_opendir$INODE64");
EXPORT void *mr_opendir64(const char *p) { return opendir(p); }
EXPORT void *mr_readdir64(void *d) __asm__("_readdir$INODE64");
EXPORT void *mr_readdir64(void *d) { return readdir(d); }
EXPORT int mr_readdir_r64(void *d, struct darwin_dirent *e, struct darwin_dirent **r)
    __asm__("_readdir_r$INODE64");
EXPORT int mr_readdir_r64(void *d, struct darwin_dirent *e, struct darwin_dirent **r)
    { return readdir_r(d, e, r); }
EXPORT void mr_rewinddir64(void *d) __asm__("_rewinddir$INODE64");
EXPORT void mr_rewinddir64(void *d) { rewinddir(d); }
#endif

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

/* pthread_get_stackaddr_np / pthread_get_stacksize_np. Darwin-only
 * (sdk/usr/include/pthread.h:546,549). aarch64 libc.so.6 has neither name
 * (measured absent); the GNU nearest is pthread_getattr_np +
 * pthread_attr_getstack, which ARE present (pthread_getattr_np@@GLIBC_2.32,
 * pthread_attr_getstack@@GLIBC_2.34).
 *
 * THE ADDRESS IS INVERTED, not merely renamed. glibc's getstack returns the
 * stack's LOW address; Darwin's get_stackaddr_np returns the HIGH one.
 * Measured on macOS (docs/UNIMPLEMENTED.md): stackaddr 0x16b79c000 with a
 * local at 0x16b799fd8, i.e. below it. An alias of getstack would be off by
 * exactly the stack size -- a pointer that looks entirely reasonable and is
 * at the wrong end of the right region.
 *
 * pthread_attr_t is 64 bytes on both (Darwin SDK probe; glibc aarch64
 * sizeof). getattr_np writes a glibc attr into that blob; we only hand it
 * back to glibc getstack/destroy, never to Darwin attr operations.
 *
 * No fake 8 MiB window: libswiftcompat rounded the current frame up to 8 MiB
 * and called that the stack, which makes heap look like stack. If getattr
 * fails we die naming ourselves. */
static void mr_pthread_stack(unsigned long t, void **lo, size_t *sz, const char *who)
{
    unsigned char attr[64];
    *lo = 0;
    *sz = 0;
    if (glibc_pthread_getattr_np(t, attr) != 0)
        mr_bail2(who, "pthread_getattr_np failed");
    if (glibc_pthread_attr_getstack(attr, lo, sz) != 0)
        mr_bail2(who, "pthread_attr_getstack failed");
    glibc_pthread_attr_destroy(attr);
    if (!*lo || *sz == 0)
        mr_bail2(who, "empty stack");
}

EXPORT void *pthread_get_stackaddr_np(unsigned long t)
{
    void *lo;
    size_t sz;
    mr_pthread_stack(t, &lo, &sz, "pthread_get_stackaddr_np");
    return (char *)lo + sz;
}

EXPORT size_t pthread_get_stacksize_np(unsigned long t)
{
    void *lo;
    size_t sz;
    mr_pthread_stack(t, &lo, &sz, "pthread_get_stacksize_np");
    return sz;
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

static int mr_so_d2l(int opt);   /* the shared SO_* table, defined with the socket family below */

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
    default: {
        int l = mr_so_d2l(optname);
        if (l < 0)
            mr_bail("getsockopt(SOL_SOCKET, ...): only the SO_* options in "
                    "mr_so_d2l (plus SO_ACCEPTCONN, SO_NREAD, SO_NWRITE) are "
                    "translated. Every SO_* number differs between the two "
                    "systems, so a forwarded one names a different option.");
        return MR_ERRNO_CALL(glibc_getsockopt(s, MR_L_SOL_SOCKET, l, optval, optlen));
    }
    }
}

/* --- BSD sockets: same sizes, different first bytes -------------------- */

/* Added 2026-09-07 for the Ledger conformance app's loopback HTTP server
 * (socket / setsockopt(SO_REUSEADDR) / bind / listen / getsockname / accept,
 * then read/write/close): without `listen` the guest rendered five Ledger rows
 * where iOS renders six (focus-score.md, realapp_ledger_light 87.915 FAIL).
 *
 * NOTHING HERE IS A PLAIN FORWARD, and the sockaddr is the one that hides:
 *
 *     struct sockaddr_in   Darwin { u8 sin_len; u8 sin_family; u16 port; ... }
 *                          Linux  { u16 sin_family;            u16 port; ... }
 *
 * Same 16 bytes. A forwarded Darwin address makes the Linux kernel read
 * family = sin_len | (AF_INET << 8) = 0x0210 -- EAFNOSUPPORT when you are
 * lucky, and a real AF_* that happens to equal the length when you are not.
 * sockaddr_in6 (28 bytes) and sockaddr_un (Darwin 106 / Linux 110) have the
 * same two-byte head and are rewritten the same way; everything after the
 * head is byte-identical on both systems (port and addresses are network
 * order, flowinfo/scope_id are host u32 on both).
 *
 *     AF_UNIX 1/1   AF_INET 2/2   AF_INET6 30/10      (domain, both ways)
 *     SOCK_STREAM 1/1   SOCK_DGRAM 2/2   SOCK_RAW 3/3  (type; Darwin has no
 *                                                       SOCK_NONBLOCK/CLOEXEC bits)
 *     SOL_SOCKET 0xffff/1   IPPROTO_TCP 6/6   IPPROTO_IPV6 41/41
 *     SO_REUSEADDR 0x0004/2  SO_KEEPALIVE 0x0008/9  SO_BROADCAST 0x0020/6
 *     SO_REUSEPORT 0x0200/15 SO_SNDBUF 0x1001/7     SO_RCVBUF 0x1002/8
 *     SO_SNDTIMEO 0x1005/21  SO_RCVTIMEO 0x1006/20  SO_ERROR 0x1007/4
 *     SO_TYPE 0x1008/3       TCP_NODELAY 1/1        IPV6_V6ONLY 27/26
 *     MSG_OOB 1/1  MSG_PEEK 2/2  MSG_DONTWAIT 0x80/0x40  MSG_NOSIGNAL 0x80000/0x4000
 *
 * SO_NOSIGPIPE (Darwin 0x1022) has no Linux counterpart. It is ACCEPTED and
 * remembered per descriptor (a 1024-bit map), and send/sendto add
 * MSG_NOSIGNAL for a marked descriptor -- that is exactly the Darwin
 * contract (no SIGPIPE on EPIPE for that socket), unlike fcntl's
 * F_SETNOSIGPIPE which applies to non-sockets too and stays ENOTSUP.
 * Options outside the table BAIL rather than forward, as getsockopt does. */

#define MR_D_AF_UNIX   1
#define MR_D_AF_INET   2
#define MR_D_AF_INET6  30
#define MR_L_AF_INET6  10

static int mr_af_d2l(int af)
{
    switch (af) {
    case 0: case MR_D_AF_UNIX: case MR_D_AF_INET: return af;
    case MR_D_AF_INET6: return MR_L_AF_INET6;
    default: return -1;
    }
}

static int mr_af_l2d(int af)
{
    switch (af) {
    case 0: case MR_D_AF_UNIX: case MR_D_AF_INET: return af;
    case MR_L_AF_INET6: return MR_D_AF_INET6;
    default: return -1;
    }
}

/* Darwin -> Linux socket option number, SOL_SOCKET level; -1 = not mapped. */
static int mr_so_d2l(int opt)
{
    switch (opt) {
    case 0x0004: return 2;    /* SO_REUSEADDR */
    case 0x0008: return 9;    /* SO_KEEPALIVE */
    case 0x0020: return 6;    /* SO_BROADCAST */
    case 0x0200: return 15;   /* SO_REUSEPORT */
    case 0x1001: return 7;    /* SO_SNDBUF */
    case 0x1002: return 8;    /* SO_RCVBUF */
    case 0x1005: return 21;   /* SO_SNDTIMEO (struct timeval agrees: 16 bytes) */
    case 0x1006: return 20;   /* SO_RCVTIMEO */
    case 0x1007: return 4;    /* SO_ERROR */
    case 0x1008: return 3;    /* SO_TYPE */
    case MR_D_SO_ACCEPTCONN: return MR_L_SO_ACCEPTCONN;
    default: return -1;
    }
}

/* The largest Linux sockaddr we rewrite: sockaddr_un (110). */
#define MR_SA_MAX 128
#define MR_D_SOCKADDR_UN_LEN 106
#define MR_L_SOCKADDR_UN_LEN 110

/* Darwin sockaddr (sa_len, sa_family, body) -> Linux (family u16, body).
 * Returns the Linux length, or -1 with errno EAFNOSUPPORT set. */
static int mr_sockaddr_d2l(const void *d, unsigned dlen, unsigned char *l)
{
    const unsigned char *s = (const unsigned char *)d;
    int af, laf;
    unsigned body;
    if (!d || dlen < 2 || dlen > MR_SA_MAX) { *mr_errno_slot() = 22; return -1; }   /* EINVAL */
    af = s[1];
    laf = mr_af_d2l(af);
    if (laf < 0) { *mr_errno_slot() = 47; return -1; }                             /* EAFNOSUPPORT */
    body = dlen - 2;
    if (af == MR_D_AF_UNIX && body > MR_L_SOCKADDR_UN_LEN - 2) body = MR_L_SOCKADDR_UN_LEN - 2;
    l[0] = (unsigned char)(laf & 0xff);
    l[1] = (unsigned char)((laf >> 8) & 0xff);
    glibc_memcpy(l + 2, s + 2, body);
    return (int)(body + 2);
}

/* Linux sockaddr -> Darwin, into the caller's buffer of *dlen bytes;
 * *dlen becomes the full Darwin length (BSD semantics: truncated copy, full
 * length reported). */
static void mr_sockaddr_l2d(const unsigned char *l, unsigned llen, void *d, unsigned *dlen)
{
    unsigned char *o = (unsigned char *)d;
    unsigned avail = dlen ? *dlen : 0, full, n;
    int af = l[0] | (l[1] << 8), daf = mr_af_l2d(af);
    if (daf < 0) daf = af;                        /* unmapped family: report as-is */
    full = llen;                                  /* Darwin length == Linux length for INET/INET6 */
    if (af == MR_D_AF_UNIX && full > MR_D_SOCKADDR_UN_LEN) full = MR_D_SOCKADDR_UN_LEN;
    n = full < avail ? full : avail;
    if (o && n >= 1) o[0] = (unsigned char)full;
    if (o && n >= 2) o[1] = (unsigned char)daf;
    if (o && n > 2)  glibc_memcpy(o + 2, l + 2, n - 2);
    if (dlen) *dlen = full;
}

static unsigned char mr_nosigpipe[1024 / 8];

static int mr_msg_d2l(int f)
{
    int l = 0;
    if (f & 0x1)     l |= 0x1;        /* MSG_OOB */
    if (f & 0x2)     l |= 0x2;        /* MSG_PEEK */
    if (f & 0x40)    l |= 0x100;      /* MSG_WAITALL: Darwin 0x40, Linux 0x100 */
    if (f & 0x80)    l |= 0x40;       /* MSG_DONTWAIT */
    if (f & 0x80000) l |= 0x4000;     /* MSG_NOSIGNAL */
    if (f & ~(0x1 | 0x2 | 0x40 | 0x80 | 0x80000))
        mr_bail("send/recv: a MSG_* flag outside OOB/PEEK/WAITALL/DONTWAIT/"
                "NOSIGNAL. The numbers are rotated between the systems, so a "
                "forwarded flag word means something else.");
    return l;
}

static int mr_send_flags(int fd, int f)
{
    int l = mr_msg_d2l(f);
    if (fd >= 0 && fd < 1024 && (mr_nosigpipe[fd >> 3] & (1u << (fd & 7))))
        l |= 0x4000;                  /* SO_NOSIGPIPE on this socket */
    return l;
}

EXPORT int socket(int domain, int type, int protocol)
{
    int ld = mr_af_d2l(domain);
    if (ld < 0) { *mr_errno_slot() = 47; return -1; }             /* EAFNOSUPPORT */
    if (type < 1 || type > 3)
        mr_bail("socket(): only SOCK_STREAM/SOCK_DGRAM/SOCK_RAW are translated "
                "(Darwin has no SOCK_NONBLOCK/SOCK_CLOEXEC bits).");
    int fd = MR_ERRNO_CALL(glibc_socket(ld, type, protocol));
    if (fd >= 0 && fd < 1024) mr_nosigpipe[fd >> 3] &= (unsigned char)~(1u << (fd & 7));
    return fd;
}

EXPORT int socketpair(int domain, int type, int protocol, int sv[2])
{
    int ld = mr_af_d2l(domain);
    if (ld < 0) { *mr_errno_slot() = 47; return -1; }
    if (type < 1 || type > 3)
        mr_bail("socketpair(): only SOCK_STREAM/SOCK_DGRAM/SOCK_RAW are translated.");
    return MR_ERRNO_CALL(glibc_socketpair(ld, type, protocol, sv));
}

EXPORT int bind(int fd, const void *addr, unsigned len)
{
    unsigned char l[MR_SA_MAX];
    int n = mr_sockaddr_d2l(addr, len, l);
    if (n < 0) return -1;
    return MR_ERRNO_CALL(glibc_bind(fd, l, (unsigned)n));
}

EXPORT int connect(int fd, const void *addr, unsigned len)
{
    unsigned char l[MR_SA_MAX];
    int n = mr_sockaddr_d2l(addr, len, l);
    if (n < 0) return -1;
    return MR_ERRNO_CALL(glibc_connect(fd, l, (unsigned)n));
}

EXPORT int listen(int fd, int backlog)
{
    return MR_ERRNO_CALL(glibc_listen(fd, backlog));
}

EXPORT int accept(int fd, void *addr, unsigned *len)
{
    unsigned char l[MR_SA_MAX];
    unsigned ll = sizeof l;
    int c = MR_ERRNO_CALL(glibc_accept(fd, addr ? l : 0, addr ? &ll : 0));
    if (c >= 0 && addr) mr_sockaddr_l2d(l, ll, addr, len);
    if (c >= 0 && c < 1024) mr_nosigpipe[c >> 3] &= (unsigned char)~(1u << (c & 7));
    return c;
}

EXPORT int getsockname(int fd, void *addr, unsigned *len)
{
    unsigned char l[MR_SA_MAX];
    unsigned ll = sizeof l;
    int rc = MR_ERRNO_CALL(glibc_getsockname(fd, l, &ll));
    if (rc == 0) mr_sockaddr_l2d(l, ll, addr, len);
    return rc;
}

EXPORT int getpeername(int fd, void *addr, unsigned *len)
{
    unsigned char l[MR_SA_MAX];
    unsigned ll = sizeof l;
    int rc = MR_ERRNO_CALL(glibc_getpeername(fd, l, &ll));
    if (rc == 0) mr_sockaddr_l2d(l, ll, addr, len);
    return rc;
}

EXPORT int setsockopt(int fd, int level, int optname, const void *optval, unsigned optlen)
{
    if (level == MR_D_SOL_SOCKET) {
        if (optname == 0x1022) {                                  /* SO_NOSIGPIPE */
            int on = optval && optlen >= sizeof(int) ? *(const int *)optval : 1;
            if (fd < 0 || fd >= 1024) { *mr_errno_slot() = 9; return -1; }   /* EBADF */
            if (on) mr_nosigpipe[fd >> 3] |= (unsigned char)(1u << (fd & 7));
            else    mr_nosigpipe[fd >> 3] &= (unsigned char)~(1u << (fd & 7));
            return 0;
        }
        int l = mr_so_d2l(optname);
        if (l < 0)
            mr_bail("setsockopt(SOL_SOCKET, ...): an SO_* option outside mr_so_d2l. "
                    "Every SO_* number differs between the two systems, so a "
                    "forwarded one sets a different option.");
        return MR_ERRNO_CALL(glibc_setsockopt(fd, MR_L_SOL_SOCKET, l, optval, optlen));
    }
    if (level == 6) {                                             /* IPPROTO_TCP */
        if (optname != 1)                                         /* TCP_NODELAY agrees */
            mr_bail("setsockopt(IPPROTO_TCP, ...): only TCP_NODELAY is translated.");
        return MR_ERRNO_CALL(glibc_setsockopt(fd, 6, 1, optval, optlen));
    }
    if (level == 41) {                                            /* IPPROTO_IPV6 */
        if (optname != 27)                                        /* IPV6_V6ONLY 27 -> 26 */
            mr_bail("setsockopt(IPPROTO_IPV6, ...): only IPV6_V6ONLY is translated.");
        return MR_ERRNO_CALL(glibc_setsockopt(fd, 41, 26, optval, optlen));
    }
    mr_bail("setsockopt(): only SOL_SOCKET, IPPROTO_TCP and IPPROTO_IPV6 levels "
            "are translated (Darwin's SOL_SOCKET is 65535, Linux's is 1, and 1 "
            "is a valid level).");
}

EXPORT int shutdown(int fd, int how)
{
    if (how < 0 || how > 2) { *mr_errno_slot() = 22; return -1; }   /* SHUT_* agree */
    return MR_ERRNO_CALL(glibc_shutdown(fd, how));
}

EXPORT long send(int fd, const void *buf, size_t n, int flags)
{
    return MR_ERRNO_CALL(glibc_send(fd, buf, n, mr_send_flags(fd, flags)));
}

EXPORT long recv(int fd, void *buf, size_t n, int flags)
{
    return MR_ERRNO_CALL(glibc_recv(fd, buf, n, mr_msg_d2l(flags)));
}

EXPORT long sendto(int fd, const void *buf, size_t n, int flags, const void *addr, unsigned len)
{
    unsigned char l[MR_SA_MAX];
    int ln = 0;
    if (addr && len) { ln = mr_sockaddr_d2l(addr, len, l); if (ln < 0) return -1; }
    return MR_ERRNO_CALL(glibc_sendto(fd, buf, n, mr_send_flags(fd, flags),
                                      addr ? l : 0, (unsigned)ln));
}

EXPORT long recvfrom(int fd, void *buf, size_t n, int flags, void *addr, unsigned *len)
{
    unsigned char l[MR_SA_MAX];
    unsigned ll = sizeof l;
    long rc = MR_ERRNO_CALL(glibc_recvfrom(fd, buf, n, mr_msg_d2l(flags),
                                           addr ? l : 0, addr ? &ll : 0));
    if (rc >= 0 && addr) mr_sockaddr_l2d(l, ll, addr, len);
    return rc;
}

EXPORT int inet_pton(int af, const char *src, void *dst)
{
    int laf = mr_af_d2l(af);
    if (laf <= 0) { *mr_errno_slot() = 47; return -1; }
    return MR_ERRNO_CALL(glibc_inet_pton(laf, src, dst));
}

EXPORT const char *inet_ntop(int af, const void *src, char *dst, unsigned size)
{
    int laf = mr_af_d2l(af);
    if (laf <= 0) { *mr_errno_slot() = 47; return 0; }
    mr_errno_in();
    const char *r = glibc_inet_ntop(laf, src, dst, size);
    mr_errno_out();
    return r;
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

/* ===================================================================== *
 * quotactl. THE ANSWER TURNED OUT TO BE A MEASUREMENT, NOT A DESIGN.
 *
 * The obvious plan was a translating wrapper, and the obstacles are real and
 * large -- all four measured, not surveyed:
 *
 *   ARGUMENT ORDER IS SWAPPED. Darwin is quotactl(path, cmd, id, addr);
 *     Linux is quotactl(cmd, special, id, addr). A forward hands Linux a
 *     `const char *` as its integer command and an integer as its device
 *     path. Not a family in the catalogue: not a size, a constant, a width, a
 *     variadic convention or a return convention -- an ORDER.
 *   THE FIRST ARGUMENT IS A DIFFERENT OBJECT. Darwin takes the MOUNT POINT
 *     (FoundationEssentials passes statfs's f_mntonname); Linux takes the
 *     BLOCK DEVICE. Bridging them means parsing /proc/mounts.
 *   THE COMMANDS DO NOT CORRESPOND. Darwin's Q_QUOTASTAT ("are quotas on?")
 *     has no Linux equivalent at all.
 *   struct dqblk DIFFERS IN LAYOUT *AND UNITS*: Darwin's dqb_curbytes counts
 *     BYTES, Linux's block limits are in 1024-byte units.
 *
 * SO THE MEASUREMENT WAS TAKEN BEFORE THE WRAPPER WAS WRITTEN, AND IT MADE THE
 * WRAPPER UNNECESSARY. On macOS 26.5.2, APFS:
 *
 *     quotactl("/",    QCMD(Q_QUOTASTAT, USRQUOTA), euid, &on)  -> -1, errno 45
 *     quotactl("/",    QCMD(Q_GETQUOTA,  USRQUOTA), euid, &dqb) -> -1, errno 45
 *     quotactl("/tmp", QCMD(Q_QUOTASTAT, USRQUOTA), euid, &on)  -> -1, errno 45
 *     quotactl("/no/such/path", ...)                            -> -1, errno 2
 *
 * 45 is ENOTSUP. APFS does not implement quotas AT ALL, so on every modern Mac
 * the answer to every quotactl command is "not supported" -- and the only
 * consumer, FileManager.attributesOfFileSystem, is written for exactly that:
 * a non-zero return means "no quota" and it reports the plain statfs totals.
 * That is not a fallback path, it is the ordinary path on Darwin today.
 *
 * This therefore returns what Darwin returns, and the difftest fixture
 * compares the two byte for byte -- which is a far stronger claim than any
 * translating wrapper could have made, because NEITHER side has quotas to
 * exercise a success path with. A wrapper would have been ~200 lines of
 * /proc/mounts parsing and unit conversion whose success path no test on
 * either machine could reach.
 *
 * THE LIMIT, NAMED: on a Linux host that DOES have quotas enabled (ext4 with
 * usrquota), this reports ENOTSUP where a translation could have reported real
 * limits. FileManager then falls back to the filesystem's totals -- an
 * OVER-report of the space available to that user, never an under-report, and
 * exactly what the same code does on any Mac. docs/UNIMPLEMENTED.md#quotactl.
 *
 * The path is still stat'ed, because Darwin distinguishes a bad path (ENOENT)
 * from an unsupported filesystem (ENOTSUP) and so must this.
 * ===================================================================== */
#define D_ENOTSUP 45

EXPORT int quotactl(const char *path, int cmd, int uid, char *addr)
{
    struct linux_stat st;
    (void)cmd; (void)uid; (void)addr;
    if (!path) { *mr_errno_slot() = 14; return -1; }          /* EFAULT */
    if (MR_ERRNO_CALL(glibc_stat(path, &st)) != 0) return -1; /* ENOENT, ... */
    *mr_errno_slot() = D_ENOTSUP;
    return -1;
}

/* ===================================================================== *
 * statfs / fstatfs. A translation of the struct-stat kind, surfaced by the
 * quota work: FileManager.attributesOfFileSystem calls statfs before
 * quotactl and passes f_mntonname -- a field Linux's struct statfs does not
 * have at all.
 *
 * Darwin's INODE64 struct statfs is 2168 bytes (sdk/tests/abi_probe.c, and
 * __DARWIN_STRUCT_STATFS64 in sdk/usr/include/sys/mount.h). Linux's is 120
 * bytes on aarch64 (sdk/tests/glibc_abi_probe.c). Every offset disagrees.
 * Forwarding would write 120 bytes into 2168 of guest storage -- the safe
 * direction for SIZE, which is why it would not crash -- and then the guest
 * would read f_mntonname at +88 out of whatever followed f_bsize.
 *
 * f_flags ROTATE on the way back. Linux ST_NOSUID (2) is Darwin
 * MNT_SYNCHRONOUS; ST_NOEXEC (8) is Darwin MNT_NOSUID; ST_SYNCHRONOUS (16)
 * is Darwin MNT_NODEV. A forwarded flags word does not report a different
 * error, it names a different mount option.
 *
 * Mount identity -- f_mntonname, f_mntfromname, f_fstypename -- comes from
 * /proc/self/mounts, longest-prefix match against the path (or against
 * /proc/self/fd/N for fstatfs). That is the field Linux's statfs lacks and
 * the one FileManager actually reads.
 * ===================================================================== */

#define DARWIN_STATFS_SIZE 2168
#define DARWIN_MNAMELEN    1024     /* MAXPATHLEN; MNAMELEN for $INODE64 */
#define DARWIN_MFSTYPENAMELEN 16

/* Transcribed from sdk/usr/include/sys/mount.h __DARWIN_STRUCT_STATFS64.
 * Offsets pinned by sdk/tests/abi_probe.c against Apple's SDK. */
struct darwin_statfs {
    uint32_t f_bsize;                       /*   0 */
    int32_t  f_iosize;                      /*   4 */
    uint64_t f_blocks;                      /*   8 */
    uint64_t f_bfree;                       /*  16 */
    uint64_t f_bavail;                      /*  24 */
    uint64_t f_files;                       /*  32 */
    uint64_t f_ffree;                       /*  40 */
    int32_t  f_fsid[2];                     /*  48  fsid_t */
    uint32_t f_owner;                       /*  56 */
    uint32_t f_type;                        /*  60 */
    uint32_t f_flags;                       /*  64 */
    uint32_t f_fssubtype;                   /*  68 */
    char     f_fstypename[DARWIN_MFSTYPENAMELEN]; /*  72 */
    char     f_mntonname[DARWIN_MNAMELEN];        /*  88 */
    char     f_mntfromname[DARWIN_MNAMELEN];      /* 1112 */
    uint32_t f_flags_ext;                   /* 2136 */
    uint32_t f_reserved[7];                 /* 2140 */
};                                          /* 2168 */

/* Linux aarch64, sys/statfs.h. Also measured, pinned in glibc_abi_probe.c. */
struct linux_statfs {
    long     f_type;                        /*   0 */
    long     f_bsize;                       /*   8 */
    unsigned long f_blocks;                 /*  16 */
    unsigned long f_bfree;                  /*  24 */
    unsigned long f_bavail;                 /*  32 */
    unsigned long f_files;                  /*  40 */
    unsigned long f_ffree;                  /*  48 */
    int      f_fsid[2];                     /*  56 */
    long     f_namelen;                     /*  64 */
    long     f_frsize;                      /*  72 */
    long     f_flags;                       /*  80 */
    long     f_spare[4];                    /*  88 */
};                                          /* 120 */

_Static_assert(sizeof(struct darwin_statfs) == 2168,
    "Darwin struct statfs is 2168 bytes (sdk/tests/abi_probe.c)");
_Static_assert(sizeof(struct linux_statfs) == 120,
    "Linux aarch64 struct statfs is 120 bytes");
_Static_assert(__builtin_offsetof(struct darwin_statfs, f_mntonname) == 88,
    "Darwin f_mntonname at 88 -- the field Linux's statfs lacks");
_Static_assert(__builtin_offsetof(struct darwin_statfs, f_mntfromname) == 1112,
    "Darwin f_mntfromname at 1112");
_Static_assert(__builtin_offsetof(struct linux_statfs, f_flags) == 80,
    "Linux f_flags at 80; darwin/src/posix.c translates ST_* -> MNT_*");

/* Darwin MNT_* from sdk/usr/include/sys/mount.h. Linux ST_* from
 * <sys/statvfs.h>, measured on the test-bed image. ST_NOSUID=2 is Darwin
 * MNT_SYNCHRONOUS; that rotation is why this table exists. */
#define D_MNT_RDONLY      0x00000001u
#define D_MNT_SYNCHRONOUS 0x00000002u
#define D_MNT_NOEXEC      0x00000004u
#define D_MNT_NOSUID      0x00000008u
#define D_MNT_NODEV       0x00000010u
#define D_MNT_NOATIME     0x10000000u

#define L_ST_RDONLY       1
#define L_ST_NOSUID       2
#define L_ST_NODEV        4
#define L_ST_NOEXEC       8
#define L_ST_SYNCHRONOUS  16
#define L_ST_NOATIME      1024

static uint32_t statfs_flags_l2d(long lflags)
{
    uint32_t d = 0;
#define MAP(lbit, dbit) do { if (lflags & (lbit)) d |= (dbit); } while (0)
    MAP(L_ST_RDONLY,      D_MNT_RDONLY);
    MAP(L_ST_NOSUID,      D_MNT_NOSUID);
    MAP(L_ST_NODEV,       D_MNT_NODEV);
    MAP(L_ST_NOEXEC,      D_MNT_NOEXEC);
    MAP(L_ST_SYNCHRONOUS, D_MNT_SYNCHRONOUS);
    MAP(L_ST_NOATIME,     D_MNT_NOATIME);
#undef MAP
    /* ST_MANDLOCK / ST_NODIRATIME / ST_RELATIME have no Darwin names.
     * Dropping them is the OUT direction: they describe Linux and the guest
     * has no bit to put them in. The reverse -- a Darwin bit that would
     * land on a real Linux bit -- is the rotation this table exists to stop. */
    return d;
}

static void statfs_strput(char *dst, size_t dstn, const char *src)
{
    size_t i = 0;
    if (!src) { dst[0] = 0; return; }
    while (src[i] && i + 1 < dstn) { dst[i] = src[i]; i++; }
    dst[i] = 0;
}

/* /proc/self/mounts escapes space/tab/newline/backslash as \NNN octal. */
static size_t mounts_unescape(const char *in, char *out, size_t outn)
{
    size_t o = 0;
    while (*in && o + 1 < outn) {
        if (in[0] == '\\' && in[1] >= '0' && in[1] <= '7'
            && in[2] >= '0' && in[2] <= '7'
            && in[3] >= '0' && in[3] <= '7') {
            unsigned v = (unsigned)(in[1] - '0') * 64u
                       + (unsigned)(in[2] - '0') * 8u
                       + (unsigned)(in[3] - '0');
            out[o++] = (char)v;
            in += 4;
            continue;
        }
        out[o++] = *in++;
    }
    out[o] = 0;
    return o;
}

static int path_has_mount_prefix(const char *path, const char *mnt, size_t n)
{
    if (n == 0) return 0;
    if (n == 1 && mnt[0] == '/') return path[0] == '/';
    if (glibc_strncmp(path, mnt, n) != 0) return 0;
    return path[n] == 0 || path[n] == '/';
}

/* Join cwd + relative path into out. Returns 0 on success. */
static int statfs_abspath(const char *path, char *out, size_t outn)
{
    size_t i = 0, j;
    if (!path || !path[0]) return -1;
    if (path[0] == '/') {
        statfs_strput(out, outn, path);
        return 0;
    }
    if (!MR_ERRNO_CALL(glibc_getcwd(out, outn))) return -1;
    i = glibc_strlen(out);
    if (i + 2 >= outn) return -1;
    if (i == 0 || out[i - 1] != '/') out[i++] = '/';
    for (j = 0; path[j] && i + 1 < outn; j++) out[i++] = path[j];
    out[i] = 0;
    return 0;
}

static void fd_proc_path(int fd, char *out, size_t outn)
{
    const char *p = "/proc/self/fd/";
    size_t i = 0;
    unsigned u;
    char rev[16];
    int r = 0;
    while (p[i] && i + 1 < outn) { out[i] = p[i]; i++; }
    if (fd < 0) { out[0] = 0; return; }
    u = (unsigned)fd;
    if (u == 0) {
        if (i + 1 < outn) out[i++] = '0';
        out[i] = 0;
        return;
    }
    while (u && r < 16) { rev[r++] = (char)('0' + (u % 10u)); u /= 10u; }
    while (r && i + 1 < outn) out[i++] = rev[--r];
    out[i] = 0;
}

/* Longest-prefix match in /proc/self/mounts. on/from/type may be NULL. */
static int mounts_lookup(const char *path,
                         char *on, size_t onn,
                         char *from, size_t fromn,
                         char *type, size_t typen)
{
    void *fp;
    char line[4096];
    char best_on[DARWIN_MNAMELEN];
    char best_from[DARWIN_MNAMELEN];
    char best_type[DARWIN_MFSTYPENAMELEN];
    size_t best_n = 0;
    int found = 0;

    best_on[0] = best_from[0] = best_type[0] = 0;
    if (!path || path[0] != '/') return 0;

    fp = MR_ERRNO_CALL(glibc_fopen("/proc/self/mounts", "r"));
    if (!fp) return 0;
    while (glibc_fgets(line, (int)sizeof line, fp)) {
        const char *s = line;
        char raw_from[DARWIN_MNAMELEN], raw_on[DARWIN_MNAMELEN], raw_type[64];
        char un_from[DARWIN_MNAMELEN], un_on[DARWIN_MNAMELEN], un_type[64];
        size_t k, n;

        k = 0;
        while (*s && *s != ' ' && k + 1 < sizeof raw_from) raw_from[k++] = *s++;
        raw_from[k] = 0;
        if (*s != ' ') continue;
        s++;
        k = 0;
        while (*s && *s != ' ' && k + 1 < sizeof raw_on) raw_on[k++] = *s++;
        raw_on[k] = 0;
        if (*s != ' ') continue;
        s++;
        k = 0;
        while (*s && *s != ' ' && k + 1 < sizeof raw_type) raw_type[k++] = *s++;
        raw_type[k] = 0;

        mounts_unescape(raw_from, un_from, sizeof un_from);
        mounts_unescape(raw_on,   un_on,   sizeof un_on);
        mounts_unescape(raw_type, un_type, sizeof un_type);
        n = glibc_strlen(un_on);
        if (!path_has_mount_prefix(path, un_on, n)) continue;
        if (n < best_n) continue;
        best_n = n;
        found = 1;
        statfs_strput(best_on,   sizeof best_on,   un_on);
        statfs_strput(best_from, sizeof best_from, un_from);
        statfs_strput(best_type, sizeof best_type, un_type);
    }
    (void)MR_ERRNO_CALL(glibc_fclose(fp));

    if (!found) return 0;
    if (on)   statfs_strput(on,   onn,   best_on);
    if (from) statfs_strput(from, fromn, best_from);
    if (type) statfs_strput(type, typen, best_type);
    return 1;
}

static void statfs_l2d(const struct linux_statfs *l, struct darwin_statfs *d,
                       const char *path_for_mount)
{
    long bsize;
    glibc_memset(d, 0, sizeof *d);
    bsize = l->f_frsize ? l->f_frsize : l->f_bsize;
    d->f_bsize  = (uint32_t)bsize;           /* Darwin: fundamental block size */
    d->f_iosize = (int32_t)l->f_bsize;       /* Darwin: optimal transfer size */
    d->f_blocks = l->f_blocks;
    d->f_bfree  = l->f_bfree;
    d->f_bavail = l->f_bavail;
    d->f_files  = l->f_files;
    d->f_ffree  = l->f_ffree;
    d->f_fsid[0] = l->f_fsid[0];
    d->f_fsid[1] = l->f_fsid[1];
    d->f_owner = 0;                          /* Linux statfs has no owner */
    d->f_type  = 0;                          /* Darwin vfsconf index; not a magic */
    d->f_flags = statfs_flags_l2d(l->f_flags);
    d->f_fssubtype = 0;
    if (path_for_mount && path_for_mount[0] == '/') {
        mounts_lookup(path_for_mount,
                      d->f_mntonname, sizeof d->f_mntonname,
                      d->f_mntfromname, sizeof d->f_mntfromname,
                      d->f_fstypename, sizeof d->f_fstypename);
    }
}

EXPORT int statfs(const char *path, struct darwin_statfs *out)
{
    struct linux_statfs ls;
    char abspath[DARWIN_MNAMELEN];
    int rc;
    if (!path || !out) { *mr_errno_slot() = 14; return -1; }  /* EFAULT */
    rc = MR_ERRNO_CALL(glibc_statfs(path, &ls));
    if (rc != 0) return rc;
    if (statfs_abspath(path, abspath, sizeof abspath) != 0)
        abspath[0] = 0;
    statfs_l2d(&ls, out, abspath[0] ? abspath : path);
    return 0;
}

EXPORT int fstatfs(int fd, struct darwin_statfs *out)
{
    struct linux_statfs ls;
    char proc[64], tgt[DARWIN_MNAMELEN];
    ssize_t n;
    int rc;
    if (!out) { *mr_errno_slot() = 14; return -1; }
    rc = MR_ERRNO_CALL(glibc_fstatfs(fd, &ls));
    if (rc != 0) return rc;
    tgt[0] = 0;
    fd_proc_path(fd, proc, sizeof proc);
    n = MR_ERRNO_CALL(glibc_readlink(proc, tgt, sizeof tgt - 1));
    if (n > 0) {
        tgt[n] = 0;
        /* /proc/self/fd/N for a deleted file is "path (deleted)". Strip it
         * so the mount lookup still sees the directory. Pipes come back as
         * "pipe:[...]" and fail the leading-slash check, which is honest:
         * they have no mount identity in /proc/self/mounts. */
        if (n > 10 && glibc_strcmp(tgt + (n - 10), " (deleted)") == 0)
            tgt[n - 10] = 0;
    } else {
        tgt[0] = 0;
    }
    statfs_l2d(&ls, out, tgt[0] == '/' ? tgt : 0);
    return 0;
}

/* arm64 macOS sets __DARWIN_ONLY_64_BIT_INO_T, so the public names are
 * unsuffixed; the $INODE64 aliases exist for the same reason _stat$INODE64
 * does -- an x86_64 or older-target guest still binds that spelling. */
EXPORT int mr_statfs64(const char *p, struct darwin_statfs *o) __asm__("_statfs$INODE64");
EXPORT int mr_statfs64(const char *p, struct darwin_statfs *o) { return statfs(p, o); }
EXPORT int mr_fstatfs64(int fd, struct darwin_statfs *o)       __asm__("_fstatfs$INODE64");
EXPORT int mr_fstatfs64(int fd, struct darwin_statfs *o)       { return fstatfs(fd, o); }

/* ===================================================================== *
 * EXTENDED ATTRIBUTES. Four separate hazards in one family, and only one
 * of them is a struct.
 *
 * (1) THE OPTION FLAGS ROTATE. Measured both sides:
 *
 *         Darwin                  Linux
 *         XATTR_NOFOLLOW  0x01    -- not a flag at all, see (2)
 *         XATTR_CREATE    0x02    XATTR_REPLACE 0x02
 *         XATTR_REPLACE   0x04    -- not a valid flag
 *
 *     So Darwin's XATTR_CREATE arrives at Linux AS XATTR_REPLACE: "create
 *     this only if it does not exist" performs "replace this only if it
 *     does", which is the exact inverse and fails or succeeds exactly
 *     backwards. Rotation again, as in fcntl and the O_* bits -- a value
 *     that maps to SOMETHING ELSE REAL rather than to nothing.
 *
 * (2) XATTR_NOFOLLOW IS A FLAG ON DARWIN AND A DIFFERENT FUNCTION ON LINUX.
 *     Linux spells "do not follow the symlink" `lgetxattr`/`lsetxattr`/
 *     `lremovexattr`/`llistxattr`. A forwarded flag word cannot express it,
 *     so the wrapper DISPATCHES on the bit.
 *
 * (3) DIFFERENT ARITY -- a shape none of the catalogued hazard families
 *     covers. Darwin's get/set take a `position` argument (for resource
 *     forks) that Linux's do not, and Darwin's take `options` where Linux's
 *     set takes `flags` and Linux's get takes nothing at all. A forward
 *     therefore hands Linux the POSITION where it expects the flags.
 *     Measured on Darwin: a non-zero `position` on an ordinary attribute is
 *     EINVAL, which is exactly what this returns -- there are no resource
 *     forks here, so that answer is faithful rather than a refusal.
 *
 * (4) THE NAME SPACE. Linux refuses any name outside `user.`, `security.`,
 *     `system.` and `trusted.`; Darwin accepts anything. Measured in the
 *     test-bed image: `setxattr(path, "com.apple.foo", ...)` and
 *     `setxattr(path, "plainname", ...)` BOTH fail with EOPNOTSUPP, and
 *     `com.apple.*` is what a real Darwin file is full of.
 *
 *     So every name is prefixed with `user.` on the way in and stripped on
 *     the way out. ALWAYS prefixed, never conditionally: mapping only the
 *     names that need it would send Darwin's "foo" and Darwin's "user.foo"
 *     to the same Linux attribute, and both can exist at once on Darwin
 *     (measured). Prefixing unconditionally is injective, so the mapping is
 *     reversible and `listxattr` can undo it exactly.
 *
 *     CONSEQUENCE, stated rather than discovered: attributes NOT in the
 *     `user.` namespace -- `security.selinux` and friends -- are invisible
 *     to the guest, because a guest asking for "security.selinux" is asking
 *     for "user.security.selinux". That is the honest answer: the guest
 *     could not have created them and cannot address them.
 *
 * (5) AND THE ERRNO NAME, which the generic table gets RIGHT and USELESSLY.
 *     "no such attribute" is ENOATTR (93) on Darwin and ENODATA (61) on
 *     Linux. Darwin ALSO has an ENODATA, at 96, so the general table maps
 *     61 -> 96 -- correct as a name translation and wrong as an answer,
 *     because every xattr caller tests against ENOATTR. This family
 *     overrides it. Nothing else in the table does, which is why it is here
 *     and not in scripts/gen_errno_table.sh.
 * ===================================================================== */

#define D_XATTR_NOFOLLOW        0x0001
#define D_XATTR_CREATE          0x0002
#define D_XATTR_REPLACE         0x0004
#define D_XATTR_NOSECURITY      0x0008
#define D_XATTR_NODEFAULT       0x0010
#define D_XATTR_SHOWCOMPRESSION 0x0020

#define L_XATTR_CREATE   0x1
#define L_XATTR_REPLACE  0x2

#define D_ENOATTR        93
#define D_ENAMETOOLONG   63
#define D_EINVAL         22

#define XATTR_PREFIX     "user."
#define XATTR_PREFIX_LEN 5
#define XATTR_NAME_MAX   256

/* Darwin options -> Linux setxattr flags. Anything we cannot perform stops
 * the process by name rather than being dropped: dropping a flag makes the
 * call do something OTHER than what was asked, which is the whole lesson of
 * the O_* and POLL* work. */
static int xattr_flags_d2l(int options)
{
    int f = 0;
    if (options & D_XATTR_CREATE)  f |= L_XATTR_CREATE;
    if (options & D_XATTR_REPLACE) f |= L_XATTR_REPLACE;
    if (options & D_XATTR_NOSECURITY)
        mr_bail("setxattr(XATTR_NOSECURITY): that flag asks the Darwin VFS to "
                "skip its access check, which Linux has no way to express. "
                "Dropping it would perform a DIFFERENT operation than the one "
                "requested");
    if (options & D_XATTR_NODEFAULT)
        mr_bail("xattr(XATTR_NODEFAULT): Darwin-only; it selects which of the "
                "VFS's attribute sources answer, and Linux has one source");
    if (options & D_XATTR_SHOWCOMPRESSION)
        mr_bail("xattr(XATTR_SHOWCOMPRESSION): Darwin-only; it exposes the "
                "attributes behind HFS+/APFS decmpfs compression, which does "
                "not exist here");
    if (options & ~(D_XATTR_NOFOLLOW | D_XATTR_CREATE | D_XATTR_REPLACE |
                    D_XATTR_NOSECURITY | D_XATTR_NODEFAULT |
                    D_XATTR_SHOWCOMPRESSION))
        mr_bail("xattr: an option bit outside Darwin's own vocabulary was "
                "requested; refusing to guess what it meant");
    return f;
}

/* "foo" -> "user.foo". Returns 0 and sets errno on overflow. */
static int xattr_name_d2l(const char *name, char *out, unsigned long outlen)
{
    unsigned long i = 0;
    if (!name) { *mr_errno_slot() = 22; return 0; }          /* EINVAL */
    while (i < XATTR_PREFIX_LEN) { out[i] = XATTR_PREFIX[i]; i++; }
    while (*name) {
        if (i + 1 >= outlen) { *mr_errno_slot() = D_ENAMETOOLONG; return 0; }
        out[i++] = *name++;
    }
    out[i] = 0;
    return 1;
}

/* Linux ENODATA is Darwin ENOATTR for this family alone -- see (5) above.
 * Applied AFTER the generic translation, so everything else keeps the table's
 * answer. */
static void xattr_fix_errno(void)
{
    if (*mr_errno_slot() == 96) *mr_errno_slot() = D_ENOATTR;   /* ENODATA */
}

EXPORT long getxattr(const char *path, const char *name, void *value,
                     unsigned long size, unsigned int position, int options)
{
    char lname[XATTR_NAME_MAX];
    long n;
    if (position != 0) { *mr_errno_slot() = D_EINVAL; return -1; }
    (void)xattr_flags_d2l(options);          /* for the bails; get takes none */
    if (!xattr_name_d2l(name, lname, sizeof lname)) return -1;
    n = (options & D_XATTR_NOFOLLOW)
        ? MR_ERRNO_CALL(glibc_lgetxattr(path, lname, value, size))
        : MR_ERRNO_CALL(glibc_getxattr(path, lname, value, size));
    if (n < 0) xattr_fix_errno();
    return n;
}

EXPORT long fgetxattr(int fd, const char *name, void *value,
                      unsigned long size, unsigned int position, int options)
{
    char lname[XATTR_NAME_MAX];
    long n;
    if (position != 0) { *mr_errno_slot() = D_EINVAL; return -1; }
    (void)xattr_flags_d2l(options);
    if (!xattr_name_d2l(name, lname, sizeof lname)) return -1;
    n = MR_ERRNO_CALL(glibc_fgetxattr(fd, lname, value, size));
    if (n < 0) xattr_fix_errno();
    return n;
}

EXPORT int setxattr(const char *path, const char *name, const void *value,
                    unsigned long size, unsigned int position, int options)
{
    char lname[XATTR_NAME_MAX];
    int flags = xattr_flags_d2l(options), rc;
    if (position != 0) { *mr_errno_slot() = D_EINVAL; return -1; }
    if (!xattr_name_d2l(name, lname, sizeof lname)) return -1;
    rc = (options & D_XATTR_NOFOLLOW)
         ? MR_ERRNO_CALL(glibc_lsetxattr(path, lname, value, size, flags))
         : MR_ERRNO_CALL(glibc_setxattr(path, lname, value, size, flags));
    if (rc < 0) xattr_fix_errno();
    return rc;
}

EXPORT int fsetxattr(int fd, const char *name, const void *value,
                     unsigned long size, unsigned int position, int options)
{
    char lname[XATTR_NAME_MAX];
    int flags = xattr_flags_d2l(options), rc;
    if (position != 0) { *mr_errno_slot() = D_EINVAL; return -1; }
    if (!xattr_name_d2l(name, lname, sizeof lname)) return -1;
    rc = MR_ERRNO_CALL(glibc_fsetxattr(fd, lname, value, size, flags));
    if (rc < 0) xattr_fix_errno();
    return rc;
}

EXPORT int removexattr(const char *path, const char *name, int options)
{
    char lname[XATTR_NAME_MAX];
    int rc;
    (void)xattr_flags_d2l(options);
    if (!xattr_name_d2l(name, lname, sizeof lname)) return -1;
    rc = (options & D_XATTR_NOFOLLOW)
         ? MR_ERRNO_CALL(glibc_lremovexattr(path, lname))
         : MR_ERRNO_CALL(glibc_removexattr(path, lname));
    if (rc < 0) xattr_fix_errno();
    return rc;
}

EXPORT int fremovexattr(int fd, const char *name, int options)
{
    char lname[XATTR_NAME_MAX];
    int rc;
    (void)xattr_flags_d2l(options);
    if (!xattr_name_d2l(name, lname, sizeof lname)) return -1;
    rc = MR_ERRNO_CALL(glibc_fremovexattr(fd, lname));
    if (rc < 0) xattr_fix_errno();
    return rc;
}

/* listxattr has to REWRITE its answer, not just forward it: the names on disk
 * carry the `user.` prefix this family added, and the caller must not see it.
 * Names outside the `user.` namespace are dropped -- see (4).
 *
 * The two-call protocol (size query, then fetch) has to be honoured on OUR
 * side of the rewrite, because the stripped list is shorter than the raw one:
 * answering a size query with the raw size would make a caller allocate more
 * than it needs, which is harmless, and answering a fetch with the raw list
 * would overrun, which is not. So the raw list is always fetched into our own
 * buffer and the stripped size is what the caller is told. */
static long xattr_list_common(const char *path, int fd, int use_fd,
                              char *out, unsigned long size, int options)
{
    char *raw;
    long rawn, i, need = 0;
    int nofollow = options & D_XATTR_NOFOLLOW;

    (void)xattr_flags_d2l(options);

    rawn = use_fd ? MR_ERRNO_CALL(glibc_flistxattr(fd, 0, 0))
                  : (nofollow ? MR_ERRNO_CALL(glibc_llistxattr(path, 0, 0))
                              : MR_ERRNO_CALL(glibc_listxattr(path, 0, 0)));
    if (rawn < 0) { xattr_fix_errno(); return -1; }
    if (rawn == 0) return 0;

    raw = glibc_malloc((unsigned long)rawn);
    if (!raw) { *mr_errno_slot() = 12; return -1; }          /* ENOMEM */
    rawn = use_fd ? MR_ERRNO_CALL(glibc_flistxattr(fd, raw, (unsigned long)rawn))
                  : (nofollow ? MR_ERRNO_CALL(glibc_llistxattr(path, raw, (unsigned long)rawn))
                              : MR_ERRNO_CALL(glibc_listxattr(path, raw, (unsigned long)rawn)));
    if (rawn < 0) { glibc_free(raw); xattr_fix_errno(); return -1; }

    /* First pass: how much the stripped list needs. */
    for (i = 0; i < rawn; ) {
        const char *n = raw + i;
        unsigned long l = glibc_strlen(n);
        if (l > XATTR_PREFIX_LEN &&
            glibc_memcmp(n, XATTR_PREFIX, XATTR_PREFIX_LEN) == 0)
            need += (long)(l - XATTR_PREFIX_LEN) + 1;
        i += (long)l + 1;
    }
    if (size == 0) { glibc_free(raw); return need; }         /* size query */
    if ((unsigned long)need > size) {
        glibc_free(raw);
        *mr_errno_slot() = 34;                               /* ERANGE, 34 both */
        return -1;
    }
    /* Second pass: write them. */
    {
        long o = 0;
        for (i = 0; i < rawn; ) {
            const char *n = raw + i;
            unsigned long l = glibc_strlen(n);
            if (l > XATTR_PREFIX_LEN &&
                glibc_memcmp(n, XATTR_PREFIX, XATTR_PREFIX_LEN) == 0) {
                glibc_memcpy(out + o, n + XATTR_PREFIX_LEN,
                             l - XATTR_PREFIX_LEN + 1);
                o += (long)(l - XATTR_PREFIX_LEN) + 1;
            }
            i += (long)l + 1;
        }
    }
    glibc_free(raw);
    return need;
}

EXPORT long listxattr(const char *path, char *namebuff, unsigned long size, int options)
{
    return xattr_list_common(path, -1, 0, namebuff, size, options);
}

EXPORT long flistxattr(int fd, char *namebuff, unsigned long size, int options)
{
    return xattr_list_common(0, fd, 1, namebuff, size, options);
}

/* ===================================================================== *
 * copyfile / fcopyfile. Darwin-only; no glibc counterpart. Transcribed
 * COPYFILE_* values are from copyfile-240's copyfile.h (143 lines, the
 * header UNIMPLEMENTED.md measured): never inferred.
 *
 * FoundationEssentials calls copyfile and fcopyfile with state == nil and
 * seven flags (DATA, METADATA, ALL, EXCL, NOFOLLOW, CLONE, RUN_IN_PLACE).
 * A non-nil state, the callback protocol, COPYFILE_RECURSIVE, PACK/UNPACK,
 * MOVE/UNLINK/CHECK, CLONE_FORCE, and removefile all abort by name -- they
 * are the remainder of the handover, not a silent subset.
 *
 * COPYFILE_CLONE is APFS copy-on-write. Linux's closest thing is FICLONE;
 * when that fails we fall back to a data copy, which is what Apple's
 * copyfile.c does for the non-FORCE flag (and what FE's own non-clone
 * branch does two lines away). COPYFILE_RUN_IN_PLACE is a CoW-avoidance
 * hint; a full copy already satisfies it.
 *
 * COPYFILE_METADATA means times, mode, owner, BSD flags and xattrs. xattr
 * translation already exists in this file. chflags has no Linux equivalent
 * and is skipped (a Linux file has no BSD flags to copy). ACLs are skipped
 * the same way: Darwin copyfile treats "none" as success, and Linux has no
 * Darwin ACL to represent.
 * ===================================================================== */

/* Transcribed from copyfile-240 copyfile.h, which sdk/ stages. */
#define COPYFILE_ACL                 (1u << 0)
#define COPYFILE_STAT                (1u << 1)
#define COPYFILE_XATTR               (1u << 2)
#define COPYFILE_DATA                (1u << 3)
#define COPYFILE_SECURITY            (COPYFILE_STAT | COPYFILE_ACL)
#define COPYFILE_METADATA            (COPYFILE_SECURITY | COPYFILE_XATTR)
#define COPYFILE_ALL                 (COPYFILE_METADATA | COPYFILE_DATA)
#define COPYFILE_NOCACHE             (1u << 14)
#define COPYFILE_RECURSIVE           (1u << 15)
#define COPYFILE_CHECK               (1u << 16)
#define COPYFILE_EXCL                (1u << 17)
#define COPYFILE_NOFOLLOW_SRC        (1u << 18)
#define COPYFILE_NOFOLLOW_DST        (1u << 19)
#define COPYFILE_MOVE                (1u << 20)
#define COPYFILE_UNLINK              (1u << 21)
#define COPYFILE_NOFOLLOW            (COPYFILE_NOFOLLOW_SRC | COPYFILE_NOFOLLOW_DST)
#define COPYFILE_PACK                (1u << 22)
#define COPYFILE_UNPACK              (1u << 23)
#define COPYFILE_CLONE               (1u << 24)
#define COPYFILE_CLONE_FORCE         (1u << 25)
#define COPYFILE_RUN_IN_PLACE        (1u << 26)
#define COPYFILE_DATA_SPARSE         (1u << 27)
#define COPYFILE_PRESERVE_DST_TRACKED (1u << 28)
#define COPYFILE_VERBOSE             (1u << 30)

#define COPYFILE_FE_MASK (COPYFILE_ACL | COPYFILE_STAT | COPYFILE_XATTR | \
                          COPYFILE_DATA | COPYFILE_EXCL | COPYFILE_NOFOLLOW | \
                          COPYFILE_CLONE | COPYFILE_RUN_IN_PLACE)

#define MR_S_IFMT  0170000
#define MR_S_IFIFO 0010000
#define MR_S_IFDIR 0040000
#define MR_S_IFREG 0100000
#define MR_S_IFLNK 0120000
#define MR_S_IRWXU 0000700
#define MR_PERM_MASK 07777

#define MR_AT_FDCWD            (-100)
#define MR_AT_SYMLINK_NOFOLLOW 0x100
#define MR_FICLONE             0x40049409u   /* _IOW(0x94, 9, int), aarch64 */
#define D_EEXIST               17
#define D_EOPNOTSUPP           102
#define D_EBADF                9

struct linux_timespec_pair {
    long at_sec, at_nsec;
    long mt_sec, mt_nsec;
};

static void copyfile_refuse_unhandled(unsigned flags, const void *state)
{
    if (state)
        mr_bail("copyfile(state != NULL): copyfile_state_t, the 18 STATE keys "
                "and the callback protocol are not implemented. FE passes nil. "
                "See docs/UNIMPLEMENTED.md#copyfile-removefile.");
    if (flags & ~COPYFILE_FE_MASK)
        mr_bail("copyfile(): a flag outside FoundationEssentials' used subset "
                "(COPYFILE_RECURSIVE/PACK/UNPACK/MOVE/UNLINK/CHECK/CLONE_FORCE/"
                "NOCACHE/DATA_SPARSE/VERBOSE/...). See docs/UNIMPLEMENTED.md"
                "#copyfile-removefile.");
}

static int copyfile_copy_data_fd(int src, int dst)
{
    char buf[65536];
    for (;;) {
        ssize_t n, off = 0;
        n = MR_ERRNO_CALL(glibc_read(src, buf, sizeof buf));
        if (n < 0) return -1;
        if (n == 0) return 0;
        while (off < n) {
            ssize_t w = MR_ERRNO_CALL(glibc_write(dst, buf + (size_t)off,
                                                  (size_t)(n - off)));
            if (w <= 0) return -1;
            off += w;
        }
    }
}

static int copyfile_xattr_ok_errno(int e)
{
    return e == D_ENOTSUP || e == D_EOPNOTSUPP || e == D_ENOATTR || e == 0;
}

static int copyfile_copy_xattrs(const char *src, const char *dst, int src_fd,
                                int dst_fd, int use_fd, unsigned flags)
{
    char *names = 0, *value = 0;
    long n, i, vs;
    int xopt = (flags & COPYFILE_NOFOLLOW) ? D_XATTR_NOFOLLOW : 0;
    int rc = 0;

    n = use_fd ? flistxattr(src_fd, 0, 0, 0)
               : listxattr(src, 0, 0, xopt);
    if (n < 0) {
        return copyfile_xattr_ok_errno(*mr_errno_slot()) ? 0 : -1;
    }
    if (n == 0) return 0;
    names = glibc_malloc((unsigned long)n);
    if (!names) { *mr_errno_slot() = 12; return -1; }
    n = use_fd ? flistxattr(src_fd, names, (unsigned long)n, 0)
               : listxattr(src, names, (unsigned long)n, xopt);
    if (n < 0) {
        rc = copyfile_xattr_ok_errno(*mr_errno_slot()) ? 0 : -1;
        glibc_free(names);
        return rc;
    }
    for (i = 0; i < n; ) {
        const char *nm = names + i;
        unsigned long nl = glibc_strlen(nm);
        vs = use_fd ? fgetxattr(src_fd, nm, 0, 0, 0, 0)
                    : getxattr(src, nm, 0, 0, 0, xopt);
        if (vs < 0) {
            if (!copyfile_xattr_ok_errno(*mr_errno_slot())) { rc = -1; break; }
            i += (long)nl + 1;
            continue;
        }
        value = vs ? glibc_malloc((unsigned long)vs) : 0;
        if (vs && !value) { *mr_errno_slot() = 12; rc = -1; break; }
        if (vs) {
            long got = use_fd ? fgetxattr(src_fd, nm, value, (unsigned long)vs, 0, 0)
                              : getxattr(src, nm, value, (unsigned long)vs, 0, xopt);
            if (got < 0) { glibc_free(value); rc = -1; break; }
            vs = got;
        }
        if (use_fd) {
            if (fsetxattr(dst_fd, nm, value, (unsigned long)vs, 0, 0) < 0 &&
                !copyfile_xattr_ok_errno(*mr_errno_slot())) {
                glibc_free(value); rc = -1; break;
            }
        } else {
            if (setxattr(dst, nm, value, (unsigned long)vs, 0, xopt) < 0 &&
                !copyfile_xattr_ok_errno(*mr_errno_slot())) {
                glibc_free(value); rc = -1; break;
            }
        }
        glibc_free(value);
        value = 0;
        i += (long)nl + 1;
    }
    glibc_free(names);
    return rc;
}

static int copyfile_apply_stat(const char *dst, int dst_fd, int use_fd,
                               const struct linux_stat *st, unsigned flags)
{
    unsigned mode = (unsigned)st->st_mode & MR_PERM_MASK;
    struct linux_timespec_pair ts;
    int is_link = ((st->st_mode & MR_S_IFMT) == MR_S_IFLNK);

    (void)flags;
    ts.at_sec = st->st_atime_sec; ts.at_nsec = (long)st->st_atime_nsec;
    ts.mt_sec = st->st_mtime_sec; ts.mt_nsec = (long)st->st_mtime_nsec;

    if (use_fd) {
        if (!is_link && MR_ERRNO_CALL(glibc_fchmod(dst_fd, mode)) != 0)
            return -1;
        if (MR_ERRNO_CALL(glibc_fchown(dst_fd, st->st_uid, st->st_gid)) != 0)
            return -1;
        if (MR_ERRNO_CALL(glibc_futimens(dst_fd, &ts)) != 0)
            return -1;
        return 0;
    }
    if (!is_link && MR_ERRNO_CALL(glibc_chmod(dst, mode)) != 0)
        return -1;
    if (is_link) {
        if (MR_ERRNO_CALL(glibc_lchown(dst, st->st_uid, st->st_gid)) != 0)
            return -1;
        if (MR_ERRNO_CALL(glibc_utimensat(MR_AT_FDCWD, dst, &ts,
                                          MR_AT_SYMLINK_NOFOLLOW)) != 0)
            return -1;
    } else {
        if (MR_ERRNO_CALL(glibc_chown(dst, st->st_uid, st->st_gid)) != 0)
            return -1;
        if (MR_ERRNO_CALL(glibc_utimensat(MR_AT_FDCWD, dst, &ts, 0)) != 0)
            return -1;
    }
    return 0;
}

static int copyfile_try_clone(int src_fd, int dst_fd)
{
    int rc = MR_ERRNO_CALL(glibc_ioctl(dst_fd, (unsigned long)MR_FICLONE,
                                       (void *)(intptr_t)src_fd));
    return rc == 0 ? 1 : 0;
}

static int copyfile_open_src(const char *src, unsigned flags)
{
    int oflags = D_O_RDONLY;
    if (flags & COPYFILE_NOFOLLOW_SRC) oflags |= D_O_NOFOLLOW;
    return open(src, oflags);
}

static int copyfile_open_dst(const char *dst, unsigned flags, unsigned mode)
{
    int oflags = D_O_WRONLY | D_O_CREAT;
    if (flags & COPYFILE_DATA) oflags |= D_O_TRUNC;
    if (flags & COPYFILE_EXCL) oflags |= D_O_EXCL;
    if (flags & COPYFILE_NOFOLLOW_DST) oflags |= D_O_NOFOLLOW;
    return open(dst, oflags, mode ? mode : 0600u);
}

EXPORT int copyfile(const char *src, const char *dst, void *state,
                    unsigned flags)
{
    struct linux_stat st, dstst;
    int src_fd = -1, dst_fd = -1, rc = -1;
    int (*sfunc)(const char *, void *);
    unsigned mode;

    copyfile_refuse_unhandled(flags, state);
    if (!src || !dst) { *mr_errno_slot() = DARWIN_EINVAL; return -1; }

    /* COPYFILE_CLONE is "best try": FICLONE, then a regular copy. FORCE
     * is outside FE's subset and already refused above. RUN_IN_PLACE is
     * a no-op once we are doing a full copy rather than a CoW clone. */
    if (flags & COPYFILE_CLONE)
        flags |= COPYFILE_EXCL | COPYFILE_NOFOLLOW_SRC |
                 COPYFILE_STAT | COPYFILE_XATTR | COPYFILE_DATA;

    sfunc = (flags & COPYFILE_NOFOLLOW_SRC) ? glibc_lstat : glibc_stat;
    if (MR_ERRNO_CALL(sfunc(src, &st)) != 0) return -1;

    if ((flags & COPYFILE_EXCL) &&
        MR_ERRNO_CALL(glibc_lstat(dst, &dstst)) == 0) {
        *mr_errno_slot() = D_EEXIST;
        return -1;
    }

    switch (st.st_mode & MR_S_IFMT) {
    case MR_S_IFREG: {
        int cloned = 0;
        src_fd = copyfile_open_src(src, flags);
        if (src_fd < 0) return -1;
        mode = (unsigned)st.st_mode & MR_PERM_MASK;
        dst_fd = copyfile_open_dst(dst, flags, mode ? mode : 0600u);
        if (dst_fd < 0) { (void)close(src_fd); return -1; }
        if ((flags & COPYFILE_CLONE) && copyfile_try_clone(src_fd, dst_fd))
            cloned = 1;
        if (!cloned && (flags & COPYFILE_DATA)) {
            if (copyfile_copy_data_fd(src_fd, dst_fd) < 0) goto out;
        }
        break;
    }
    case MR_S_IFLNK: {
        char target[DARWIN_MNAMELEN];
        ssize_t n = MR_ERRNO_CALL(glibc_readlink(src, target, sizeof target - 1));
        if (n < 0) return -1;
        target[n] = 0;
        if (MR_ERRNO_CALL(glibc_symlink(target, dst)) != 0) return -1;
        break;
    }
    case MR_S_IFDIR:
        mode = (unsigned)st.st_mode & MR_PERM_MASK;
        if (MR_ERRNO_CALL(glibc_mkdir(dst, mode ? mode : 0755u)) != 0) {
            if (!((flags & COPYFILE_EXCL) == 0 && *mr_errno_slot() == D_EEXIST))
                return -1;
        }
        break;
    default:
        *mr_errno_slot() = D_ENOTSUP;
        return -1;
    }

    if (flags & COPYFILE_XATTR) {
        int use_fd = (src_fd >= 0 && dst_fd >= 0);
        if (copyfile_copy_xattrs(src, dst, src_fd, dst_fd, use_fd, flags) < 0)
            goto out;
    }
    if (flags & COPYFILE_STAT) {
        int use_fd = (dst_fd >= 0) && ((st.st_mode & MR_S_IFMT) == MR_S_IFREG);
        if (copyfile_apply_stat(dst, dst_fd, use_fd, &st, flags) < 0)
            goto out;
    }
    rc = 0;
out:
    if (src_fd >= 0) (void)close(src_fd);
    if (dst_fd >= 0) (void)close(dst_fd);
    return rc;
}

EXPORT int fcopyfile(int src_fd, int dst_fd, void *state, unsigned flags)
{
    struct linux_stat st;
    int cloned = 0;

    copyfile_refuse_unhandled(flags, state);
    if (src_fd < 0 || dst_fd < 0) {
        *mr_errno_slot() = DARWIN_EINVAL;
        return -1;
    }
    if (MR_ERRNO_CALL(glibc_fstat(src_fd, &st)) != 0) return -1;
    switch (st.st_mode & MR_S_IFMT) {
    case MR_S_IFREG:
    case MR_S_IFLNK:
    case MR_S_IFDIR:
        break;
    default:
        *mr_errno_slot() = D_ENOTSUP;
        return -1;
    }
    if (flags & COPYFILE_CLONE)
        flags |= COPYFILE_STAT | COPYFILE_XATTR | COPYFILE_DATA;

    if ((flags & COPYFILE_CLONE) &&
        (st.st_mode & MR_S_IFMT) == MR_S_IFREG &&
        copyfile_try_clone(src_fd, dst_fd))
        cloned = 1;
    if (!cloned && (flags & COPYFILE_DATA) &&
        (st.st_mode & MR_S_IFMT) == MR_S_IFREG) {
        if (copyfile_copy_data_fd(src_fd, dst_fd) < 0) return -1;
    }
    if (flags & COPYFILE_XATTR) {
        if (copyfile_copy_xattrs(0, 0, src_fd, dst_fd, 1, flags) < 0)
            return -1;
    }
    if (flags & COPYFILE_STAT) {
        if (copyfile_apply_stat(0, dst_fd, 1, &st, flags) < 0)
            return -1;
    }
    return 0;
}

EXPORT void *copyfile_state_alloc(void)
{
    mr_bail("copyfile_state_alloc(): the state object is not implemented. "
            "FE passes state == nil. See docs/UNIMPLEMENTED.md#copyfile-removefile.");
}

EXPORT int copyfile_state_free(void *s)
{
    (void)s;
    mr_bail("copyfile_state_free(): the state object is not implemented. "
            "See docs/UNIMPLEMENTED.md#copyfile-removefile.");
}

EXPORT int copyfile_state_get(void *s, unsigned flag, void *dst)
{
    (void)s; (void)flag; (void)dst;
    mr_bail("copyfile_state_get(): the 18 STATE keys are not implemented. "
            "See docs/UNIMPLEMENTED.md#copyfile-removefile.");
}

EXPORT int copyfile_state_set(void *s, unsigned flag, const void *src)
{
    (void)s; (void)flag; (void)src;
    mr_bail("copyfile_state_set(): the 18 STATE keys are not implemented. "
            "See docs/UNIMPLEMENTED.md#copyfile-removefile.");
}

EXPORT int removefile(const char *path, void *state, unsigned flags)
{
    (void)path; (void)state; (void)flags;
    mr_bail("removefile(): not implemented. The used subset requires the "
            "state object and confirm/error callbacks. See "
            "docs/UNIMPLEMENTED.md#copyfile-removefile.");
}

EXPORT void *removefile_state_alloc(void)
{
    mr_bail("removefile_state_alloc(): not implemented. See "
            "docs/UNIMPLEMENTED.md#copyfile-removefile.");
}

EXPORT int removefile_state_free(void *s)
{
    (void)s;
    mr_bail("removefile_state_free(): not implemented. See "
            "docs/UNIMPLEMENTED.md#copyfile-removefile.");
}

EXPORT int removefile_state_get(void *s, unsigned key, void *dst)
{
    (void)s; (void)key; (void)dst;
    mr_bail("removefile_state_get(): not implemented. See "
            "docs/UNIMPLEMENTED.md#copyfile-removefile.");
}

EXPORT int removefile_state_set(void *s, unsigned key, const void *src)
{
    (void)s; (void)key; (void)src;
    mr_bail("removefile_state_set(): not implemented. See "
            "docs/UNIMPLEMENTED.md#copyfile-removefile.");
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
#if defined(__x86_64__)
    uts_put(u->machine,  "x86_64");
#else
    uts_put(u->machine,  "arm64");
#endif

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
