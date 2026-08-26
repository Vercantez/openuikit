/* libsystem.c -- our replacement /usr/lib/libSystem.B.dylib.
 *
 * Built ON LINUX as a Mach-O arm64 dylib (clang -target arm64-apple-macos11 +
 * ld64.lld-18), then loaded by machorun into the guest's address space. This
 * is the project's core bet: the guest calls _printf and lands HERE, in code
 * compiled for its own ABI, which then calls glibc. No Darwin syscall is ever
 * emulated.
 *
 * Two rules govern this file.
 *
 * 1. THE GLIBC BOUNDARY IS EXPLICIT. Every glibc function we call is declared
 *    with an asm label of the form _glibc_<name>. machorun's resolver turns
 *    that into dlsym(RTLD_DEFAULT, "<name>"). Without the rename our own
 *    forwarder `puts` would be its own callee -- infinite recursion -- and the
 *    boundary would be invisible in `nm`. Now it is one grep.
 *
 * 2. A VARIADIC FUNCTION IS NEVER A FORWARDER (docs/PLAN.md §II.4). Darwin
 *    arm64 passes variadic arguments on the stack with an 8-byte va_list;
 *    Linux aarch64 passes them in x1-x7/v0-v7 with a 32-byte va_list. So the
 *    printf family is implemented here, over the Darwin va_list, and only the
 *    bytes go to glibc. The one crossing we do make -- float formatting via
 *    glibc snprintf -- goes through a NON-variadic prototype, which is safe
 *    precisely because an aarch64-Linux variadic callee spills x0-x7/v0-v7 to
 *    its register save area on entry, so ordinary AAPCS64 argument passing
 *    lands exactly where its va_arg will look.
 *
 * No headers are included: -nostdinc, because there is no macOS SDK on the
 * build host and glibc's headers are not compilable for a Darwin target.
 * Everything is declared here.
 */

typedef unsigned long size_t;
typedef long          ssize_t;
typedef unsigned long uintptr_t;
typedef __builtin_va_list va_list;
#define va_start __builtin_va_start
#define va_end   __builtin_va_end
#define va_arg   __builtin_va_arg
#define NULL ((void *)0)

#define GLIBCSYM(n) __asm__("_glibc_" #n)
#define EXPORT __attribute__((visibility("default")))

/* ------------------------------------------------------- the glibc side */
extern void  *glibc_malloc(size_t)                       GLIBCSYM(malloc);
extern void  *glibc_calloc(size_t, size_t)               GLIBCSYM(calloc);
extern void  *glibc_realloc(void *, size_t)              GLIBCSYM(realloc);
extern void   glibc_free(void *)                         GLIBCSYM(free);
extern int    glibc_posix_memalign(void **, size_t, size_t) GLIBCSYM(posix_memalign);
extern void  *glibc_aligned_alloc(size_t, size_t)        GLIBCSYM(aligned_alloc);
extern size_t glibc_malloc_usable_size(void *)           GLIBCSYM(malloc_usable_size);

extern size_t glibc_strlen(const char *)                 GLIBCSYM(strlen);
extern char  *glibc_strcpy(char *, const char *)         GLIBCSYM(strcpy);
extern char  *glibc_strncpy(char *, const char *, size_t) GLIBCSYM(strncpy);
extern char  *glibc_strcat(char *, const char *)         GLIBCSYM(strcat);
extern int    glibc_strcmp(const char *, const char *)   GLIBCSYM(strcmp);
extern int    glibc_strncmp(const char *, const char *, size_t) GLIBCSYM(strncmp);
extern char  *glibc_strchr(const char *, int)            GLIBCSYM(strchr);
extern char  *glibc_strrchr(const char *, int)           GLIBCSYM(strrchr);
extern char  *glibc_strstr(const char *, const char *)   GLIBCSYM(strstr);
extern char  *glibc_strdup(const char *)                 GLIBCSYM(strdup);
extern void  *glibc_memcpy(void *, const void *, size_t) GLIBCSYM(memcpy);
extern void  *glibc_memmove(void *, const void *, size_t) GLIBCSYM(memmove);
extern void  *glibc_memset(void *, int, size_t)          GLIBCSYM(memset);
extern int    glibc_memcmp(const void *, const void *, size_t) GLIBCSYM(memcmp);
extern void  *glibc_memchr(const void *, int, size_t)    GLIBCSYM(memchr);

extern int    glibc_puts(const char *)                   GLIBCSYM(puts);
extern int    glibc_putchar(int)                         GLIBCSYM(putchar);
extern size_t glibc_fwrite(const void *, size_t, size_t, void *) GLIBCSYM(fwrite);
extern size_t glibc_fread(void *, size_t, size_t, void *) GLIBCSYM(fread);
extern int    glibc_fflush(void *)                       GLIBCSYM(fflush);
extern void  *glibc_fopen(const char *, const char *)    GLIBCSYM(fopen);
extern int    glibc_fclose(void *)                       GLIBCSYM(fclose);
extern int    glibc_fputs(const char *, void *)          GLIBCSYM(fputs);
extern int    glibc_fputc(int, void *)                   GLIBCSYM(fputc);
extern int    glibc_fgetc(void *)                        GLIBCSYM(fgetc);
extern int    glibc_ferror(void *)                       GLIBCSYM(ferror);
extern int    glibc_feof(void *)                         GLIBCSYM(feof);

extern ssize_t glibc_write(int, const void *, size_t)    GLIBCSYM(write);
extern ssize_t glibc_read(int, void *, size_t)           GLIBCSYM(read);
extern int     glibc_close(int)                          GLIBCSYM(close);
extern int     glibc_getpid(void)                        GLIBCSYM(getpid);
extern void    glibc_abort(void)                         GLIBCSYM(abort);
extern void    glibc_exit(int)                           GLIBCSYM(exit);
extern void    glibc__exit(int)                          GLIBCSYM(_exit);
extern int    *glibc___errno_location(void)              GLIBCSYM(__errno_location);
extern int     glibc_atoi(const char *)                  GLIBCSYM(atoi);
extern long    glibc_strtol(const char *, char **, int)  GLIBCSYM(strtol);
extern double  glibc_strtod(const char *, char **)       GLIBCSYM(strtod);
extern void    glibc_qsort(void *, size_t, size_t, int (*)(const void *, const void *)) GLIBCSYM(qsort);
extern char   *glibc_getenv(const char *)                GLIBCSYM(getenv);
extern long    glibc_time(long *)                        GLIBCSYM(time);
extern int     glibc_clock_gettime(int, void *)          GLIBCSYM(clock_gettime);
extern int     glibc_usleep(unsigned)                    GLIBCSYM(usleep);
extern int     glibc_sched_yield(void)                   GLIBCSYM(sched_yield);
extern long    glibc_sysconf(int)                        GLIBCSYM(sysconf);
extern void   *glibc_mmap(void *, size_t, int, int, int, long) GLIBCSYM(mmap);
extern int     glibc_munmap(void *, size_t)              GLIBCSYM(munmap);
extern int     glibc_mprotect(void *, size_t, int)       GLIBCSYM(mprotect);

/* glibc's variadic snprintf, declared NON-variadically with the exact shape we
 * call it with. See the header comment: this is the safe crossing. */
extern int glibc_snprintf_d(char *, size_t, const char *, double) GLIBCSYM(snprintf);

/* glibc data objects. These are data imports: the GOT slot holds the address
 * of glibc's variable, so this really is glibc's stdout, not a copy. */
extern void *glibc_stdout GLIBCSYM(stdout);
extern void *glibc_stderr GLIBCSYM(stderr);
extern void *glibc_stdin  GLIBCSYM(stdin);

/* pthreads, glibc side. glibc's pthread_t is an unsigned long; Darwin's is an
 * opaque pointer. Both are 8 bytes and both are only ever passed back to us. */
typedef unsigned long g_pthread_t;
extern int glibc_pthread_create(g_pthread_t *, const void *, void *(*)(void *), void *) GLIBCSYM(pthread_create);
extern int glibc_pthread_join(g_pthread_t, void **)      GLIBCSYM(pthread_join);
extern int glibc_pthread_detach(g_pthread_t)             GLIBCSYM(pthread_detach);
extern g_pthread_t glibc_pthread_self(void)              GLIBCSYM(pthread_self);
extern int glibc_pthread_equal(g_pthread_t, g_pthread_t) GLIBCSYM(pthread_equal);
extern int glibc_pthread_mutex_init(void *, const void *) GLIBCSYM(pthread_mutex_init);
extern int glibc_pthread_mutex_lock(void *)              GLIBCSYM(pthread_mutex_lock);
extern int glibc_pthread_mutex_trylock(void *)           GLIBCSYM(pthread_mutex_trylock);
extern int glibc_pthread_mutex_unlock(void *)            GLIBCSYM(pthread_mutex_unlock);
extern int glibc_pthread_mutex_destroy(void *)           GLIBCSYM(pthread_mutex_destroy);
extern int glibc_pthread_cond_init(void *, const void *) GLIBCSYM(pthread_cond_init);
extern int glibc_pthread_cond_wait(void *, void *)       GLIBCSYM(pthread_cond_wait);
extern int glibc_pthread_cond_signal(void *)             GLIBCSYM(pthread_cond_signal);
extern int glibc_pthread_cond_broadcast(void *)          GLIBCSYM(pthread_cond_broadcast);
extern int glibc_pthread_cond_destroy(void *)            GLIBCSYM(pthread_cond_destroy);
extern int glibc_pthread_once(void *, void (*)(void))    GLIBCSYM(pthread_once);
extern int glibc_pthread_key_create(unsigned *, void (*)(void *)) GLIBCSYM(pthread_key_create);
extern int glibc_pthread_key_delete(unsigned)            GLIBCSYM(pthread_key_delete);
extern void *glibc_pthread_getspecific(unsigned)         GLIBCSYM(pthread_getspecific);
extern int glibc_pthread_setspecific(unsigned, const void *) GLIBCSYM(pthread_setspecific);

/* --------------------------------------------------------- loud failure */

static void say(const char *s)
{
    glibc_write(2, s, glibc_strlen(s));
}

__attribute__((noreturn)) static void bail(const char *what)
{
    say("machorun/libSystem: ");
    say(what);
    say("\n");
    glibc__exit(71);
    __builtin_unreachable();
}

/* ------------------------------------------------------- process state */

EXPORT char **environ;
EXPORT void *__stdoutp, *__stderrp, *__stdinp;
EXPORT unsigned long __stack_chk_guard = 0x0000ff0d0a0d0aull;
EXPORT const char *__progname;

static int    mr_argc;
static char **mr_argv;
static char **mr_envp;
static char **mr_apple;

EXPORT void __machorun_libsystem_bootstrap(int argc, char **argv, char **envp, char **apple)
{
    mr_argc = argc; mr_argv = argv; mr_envp = envp; mr_apple = apple;
    environ = envp;
    __stdoutp = glibc_stdout;
    __stderrp = glibc_stderr;
    __stdinp  = glibc_stdin;
    __progname = argc > 0 ? argv[0] : "";
}

EXPORT int   *_NSGetArgc(void)    { return &mr_argc; }
EXPORT char ***_NSGetArgv(void)   { return &mr_argv; }
EXPORT char ***_NSGetEnviron(void) { return &mr_envp; }
EXPORT char **_NSGetProgname(void) { return (char **)&__progname; }

EXPORT int *__error(void) { return glibc___errno_location(); }

/* ---------------------------------------------------------- the printf */

struct sink {
    char  *dst;          /* string sinks */
    size_t cap, off;     /* off counts what WOULD be written (snprintf rules) */
    void  *file;         /* FILE* sinks */
    char   buf[512];
    size_t buflen;
};

static void sink_flush(struct sink *s)
{
    if (s->file && s->buflen) {
        glibc_fwrite(s->buf, 1, s->buflen, s->file);
        s->buflen = 0;
    }
}

static void sink_put(struct sink *s, const char *p, size_t n)
{
    if (s->file) {
        for (size_t i = 0; i < n; i++) {
            if (s->buflen == sizeof(s->buf)) sink_flush(s);
            s->buf[s->buflen++] = p[i];
        }
        s->off += n;
    } else {
        for (size_t i = 0; i < n; i++) {
            if (s->dst && s->off + i + 1 < s->cap) s->dst[s->off + i] = p[i];
        }
        s->off += n;
    }
}

static void sink_pad(struct sink *s, char c, long n)
{
    char b[16];
    for (unsigned i = 0; i < sizeof(b); i++) b[i] = c;
    while (n > 0) {
        long k = n > (long)sizeof(b) ? (long)sizeof(b) : n;
        sink_put(s, b, (size_t)k);
        n -= k;
    }
}

static size_t utoa(unsigned long long v, unsigned base, int upper, char *out)
{
    const char *digits = upper ? "0123456789ABCDEF" : "0123456789abcdef";
    char tmp[24];
    size_t n = 0;
    do { tmp[n++] = digits[v % base]; v /= base; } while (v);
    for (size_t i = 0; i < n; i++) out[i] = tmp[n - 1 - i];
    return n;
}

#define FLAG_LEFT  1
#define FLAG_ZERO  2
#define FLAG_PLUS  4
#define FLAG_SPACE 8
#define FLAG_ALT   16

static int mr_vformat(struct sink *s, const char *fmt, va_list ap)
{
    for (const char *p = fmt; *p; ) {
        const char *start = p;
        while (*p && *p != '%') p++;
        if (p > start) sink_put(s, start, (size_t)(p - start));
        if (!*p) break;
        p++;                                     /* past '%' */

        int flags = 0;
        long width = 0, prec = -1;
        int lmod = 0;                            /* 1=l 2=ll 3=z 4=h 5=hh 6=L */
        char conv;

        for (;; p++) {
            if (*p == '-') flags |= FLAG_LEFT;
            else if (*p == '0') flags |= FLAG_ZERO;
            else if (*p == '+') flags |= FLAG_PLUS;
            else if (*p == ' ') flags |= FLAG_SPACE;
            else if (*p == '#') flags |= FLAG_ALT;
            else break;
        }
        if (*p == '*') { width = va_arg(ap, int); p++; if (width < 0) { flags |= FLAG_LEFT; width = -width; } }
        else while (*p >= '0' && *p <= '9') width = width * 10 + (*p++ - '0');
        if (*p == '.') {
            p++;
            prec = 0;
            if (*p == '*') { prec = va_arg(ap, int); p++; }
            else while (*p >= '0' && *p <= '9') prec = prec * 10 + (*p++ - '0');
        }
        if (*p == 'l') { p++; lmod = 1; if (*p == 'l') { p++; lmod = 2; } }
        else if (*p == 'z' || *p == 't' || *p == 'j') { p++; lmod = 3; }
        else if (*p == 'h') { p++; lmod = 4; if (*p == 'h') { p++; lmod = 5; } }
        else if (*p == 'L') { p++; lmod = 6; }
        else if (*p == 'q') { p++; lmod = 2; }
        conv = *p ? *p++ : 0;

        switch (conv) {
        case 0:
            return (int)s->off;
        case '%':
            sink_put(s, "%", 1);
            break;
        case 'c': {
            char c = (char)va_arg(ap, int);
            long pad = width - 1;
            if (!(flags & FLAG_LEFT)) sink_pad(s, ' ', pad);
            sink_put(s, &c, 1);
            if (flags & FLAG_LEFT) sink_pad(s, ' ', pad);
            break;
        }
        case 's': {
            const char *v = va_arg(ap, const char *);
            size_t n;
            if (!v) v = "(null)";
            n = glibc_strlen(v);
            if (prec >= 0 && (size_t)prec < n) n = (size_t)prec;
            if (!(flags & FLAG_LEFT)) sink_pad(s, ' ', width - (long)n);
            sink_put(s, v, n);
            if (flags & FLAG_LEFT) sink_pad(s, ' ', width - (long)n);
            break;
        }
        case 'd': case 'i': case 'u': case 'x': case 'X': case 'o': case 'p': {
            char num[32];
            char sign = 0;
            size_t n;
            unsigned base = 10;
            int upper = 0, isneg = 0;
            unsigned long long uv = 0;
            const char *prefix = "";

            if (conv == 'p') {
                uv = (unsigned long long)(uintptr_t)va_arg(ap, void *);
                base = 16; prefix = "0x";
                if (prec < 0) prec = 0;
            } else if (conv == 'd' || conv == 'i') {
                long long sv;
                switch (lmod) {
                case 1: sv = va_arg(ap, long); break;
                case 2: sv = va_arg(ap, long long); break;
                case 3: sv = (long long)va_arg(ap, size_t); break;
                default: sv = va_arg(ap, int); break;
                }
                if (lmod == 4) sv = (short)sv;
                if (lmod == 5) sv = (signed char)sv;
                isneg = sv < 0;
                uv = isneg ? (unsigned long long)(-(sv + 1)) + 1 : (unsigned long long)sv;
            } else {
                switch (lmod) {
                case 1: uv = va_arg(ap, unsigned long); break;
                case 2: uv = va_arg(ap, unsigned long long); break;
                case 3: uv = va_arg(ap, size_t); break;
                default: uv = va_arg(ap, unsigned int); break;
                }
                if (lmod == 4) uv = (unsigned short)uv;
                if (lmod == 5) uv = (unsigned char)uv;
                if (conv == 'x') base = 16;
                else if (conv == 'X') { base = 16; upper = 1; }
                else if (conv == 'o') base = 8;
                if ((flags & FLAG_ALT) && uv && base == 16) prefix = upper ? "0X" : "0x";
            }

            if (isneg) sign = '-';
            else if (flags & FLAG_PLUS) sign = '+';
            else if (flags & FLAG_SPACE) sign = ' ';

            n = utoa(uv, base, upper, num);
            {
                long zeros = (prec >= 0 && (long)n < prec) ? prec - (long)n : 0;
                long body = (long)n + zeros + (sign ? 1 : 0) + (long)glibc_strlen(prefix);
                long pad = width - body;
                if (prec >= 0) flags &= ~FLAG_ZERO;      /* precision beats '0' */
                if (!(flags & FLAG_LEFT) && !(flags & FLAG_ZERO)) sink_pad(s, ' ', pad);
                if (sign) sink_put(s, &sign, 1);
                if (*prefix) sink_put(s, prefix, glibc_strlen(prefix));
                if (!(flags & FLAG_LEFT) && (flags & FLAG_ZERO)) sink_pad(s, '0', pad);
                sink_pad(s, '0', zeros);
                sink_put(s, num, n);
                if (flags & FLAG_LEFT) sink_pad(s, ' ', pad);
            }
            break;
        }
        case 'f': case 'F': case 'e': case 'E': case 'g': case 'G': case 'a': case 'A': {
            /* Float formatting is delegated to glibc through a NON-variadic
             * prototype -- see the header comment. Correct rounding of doubles
             * is not something to reimplement for a fixture. */
            double v = va_arg(ap, double);
            char spec[32], out[512];
            size_t si = 0;
            int n;
            spec[si++] = '%';
            if (flags & FLAG_LEFT)  spec[si++] = '-';
            if (flags & FLAG_ZERO)  spec[si++] = '0';
            if (flags & FLAG_PLUS)  spec[si++] = '+';
            if (flags & FLAG_SPACE) spec[si++] = ' ';
            if (flags & FLAG_ALT)   spec[si++] = '#';
            if (width) si += utoa((unsigned long long)width, 10, 0, spec + si);
            if (prec >= 0) {
                spec[si++] = '.';
                si += utoa((unsigned long long)prec, 10, 0, spec + si);
            }
            spec[si++] = conv;
            spec[si] = 0;
            n = glibc_snprintf_d(out, sizeof(out), spec, v);
            if (n < 0) n = 0;
            if ((size_t)n >= sizeof(out)) n = (int)sizeof(out) - 1;
            sink_put(s, out, (size_t)n);
            break;
        }
        case 'n':
            bail("%n in a format string is not supported");
        default:
            /* Unknown conversion: emit it verbatim, as the C library does. */
            sink_put(s, "%", 1);
            sink_put(s, &conv, 1);
            break;
        }
    }
    return (int)s->off;
}

static int file_format(void *f, const char *fmt, va_list ap)
{
    struct sink s;
    int n;
    glibc_memset(&s, 0, sizeof(s));
    s.file = f ? f : glibc_stdout;
    n = mr_vformat(&s, fmt, ap);
    sink_flush(&s);
    return n;
}

EXPORT int printf(const char *fmt, ...)
{
    va_list ap; int n;
    va_start(ap, fmt);
    n = file_format(__stdoutp ? __stdoutp : glibc_stdout, fmt, ap);
    va_end(ap);
    return n;
}

EXPORT int fprintf(void *f, const char *fmt, ...)
{
    va_list ap; int n;
    va_start(ap, fmt);
    n = file_format(f, fmt, ap);
    va_end(ap);
    return n;
}

EXPORT int vprintf(const char *fmt, va_list ap)
{
    return file_format(__stdoutp ? __stdoutp : glibc_stdout, fmt, ap);
}

EXPORT int vfprintf(void *f, const char *fmt, va_list ap) { return file_format(f, fmt, ap); }

EXPORT int vsnprintf(char *dst, size_t cap, const char *fmt, va_list ap)
{
    struct sink s;
    int n;
    glibc_memset(&s, 0, sizeof(s));
    s.dst = dst; s.cap = cap;
    n = mr_vformat(&s, fmt, ap);
    if (dst && cap) dst[(size_t)n < cap ? (size_t)n : cap - 1] = 0;
    return n;
}

EXPORT int snprintf(char *dst, size_t cap, const char *fmt, ...)
{
    va_list ap; int n;
    va_start(ap, fmt);
    n = vsnprintf(dst, cap, fmt, ap);
    va_end(ap);
    return n;
}

EXPORT int vsprintf(char *dst, const char *fmt, va_list ap)
{
    return vsnprintf(dst, (size_t)-1, fmt, ap);
}

EXPORT int sprintf(char *dst, const char *fmt, ...)
{
    va_list ap; int n;
    va_start(ap, fmt);
    n = vsnprintf(dst, (size_t)-1, fmt, ap);
    va_end(ap);
    return n;
}

EXPORT int asprintf(char **out, const char *fmt, ...)
{
    va_list ap; int n; char *buf;
    va_start(ap, fmt);
    n = vsnprintf(NULL, 0, fmt, ap);
    va_end(ap);
    if (n < 0) return -1;
    buf = glibc_malloc((size_t)n + 1);
    if (!buf) return -1;
    va_start(ap, fmt);
    vsnprintf(buf, (size_t)n + 1, fmt, ap);
    va_end(ap);
    *out = buf;
    return n;
}

/* The fortify lowering the compiler emits; the guest's buffer sizes are its
 * own business, we only need the entry points to exist and behave. */
EXPORT int __snprintf_chk(char *d, size_t n, int flag, size_t slen, const char *fmt, ...)
{
    va_list ap; int r;
    (void)flag; (void)slen;
    va_start(ap, fmt);
    r = vsnprintf(d, n, fmt, ap);
    va_end(ap);
    return r;
}

EXPORT int __sprintf_chk(char *d, int flag, size_t slen, const char *fmt, ...)
{
    va_list ap; int r;
    (void)flag; (void)slen;
    va_start(ap, fmt);
    r = vsnprintf(d, (size_t)-1, fmt, ap);
    va_end(ap);
    return r;
}

EXPORT int __printf_chk(int flag, const char *fmt, ...)
{
    va_list ap; int n;
    (void)flag;
    va_start(ap, fmt);
    n = file_format(__stdoutp ? __stdoutp : glibc_stdout, fmt, ap);
    va_end(ap);
    return n;
}

/* ------------------------------------------------------------ forwarders */

#define FWD(ret, name, params, args) EXPORT ret name params { return glibc_##name args; }
#define FWDV(name, params, args)     EXPORT void name params { glibc_##name args; }

FWD(void *, malloc,  (size_t n),               (n))
FWD(void *, calloc,  (size_t n, size_t m),     (n, m))
FWD(void *, realloc, (void *p, size_t n),      (p, n))
FWDV(free, (void *p), (p))
FWD(int, posix_memalign, (void **p, size_t a, size_t n), (p, a, n))
FWD(void *, aligned_alloc, (size_t a, size_t n), (a, n))
EXPORT void *valloc(size_t n) { void *p = NULL; glibc_posix_memalign(&p, 16384, n); return p; }
EXPORT size_t malloc_size(const void *p) { return glibc_malloc_usable_size((void *)p); }
EXPORT size_t malloc_good_size(size_t n) { return n; }

FWD(size_t, strlen,  (const char *s),                    (s))
FWD(char *, strcpy,  (char *d, const char *s),           (d, s))
FWD(char *, strncpy, (char *d, const char *s, size_t n), (d, s, n))
FWD(char *, strcat,  (char *d, const char *s),           (d, s))
FWD(int,    strcmp,  (const char *a, const char *b),     (a, b))
FWD(int,    strncmp, (const char *a, const char *b, size_t n), (a, b, n))
FWD(char *, strchr,  (const char *s, int c),             (s, c))
FWD(char *, strrchr, (const char *s, int c),             (s, c))
FWD(char *, strstr,  (const char *h, const char *n),     (h, n))
FWD(char *, strdup,  (const char *s),                    (s))
FWD(void *, memcpy,  (void *d, const void *s, size_t n), (d, s, n))
FWD(void *, memmove, (void *d, const void *s, size_t n), (d, s, n))
FWD(void *, memset,  (void *d, int c, size_t n),         (d, c, n))
FWD(int,    memcmp,  (const void *a, const void *b, size_t n), (a, b, n))
FWD(void *, memchr,  (const void *s, int c, size_t n),   (s, c, n))

EXPORT char  *__strcpy_chk(char *d, const char *s, size_t sz) { (void)sz; return glibc_strcpy(d, s); }
EXPORT char  *__strcat_chk(char *d, const char *s, size_t sz) { (void)sz; return glibc_strcat(d, s); }
EXPORT void  *__memcpy_chk(void *d, const void *s, size_t n, size_t sz) { (void)sz; return glibc_memcpy(d, s, n); }
EXPORT void  *__memmove_chk(void *d, const void *s, size_t n, size_t sz) { (void)sz; return glibc_memmove(d, s, n); }
EXPORT void  *__memset_chk(void *d, int c, size_t n, size_t sz) { (void)sz; return glibc_memset(d, c, n); }

FWD(int, puts,    (const char *s),  (s))
FWD(int, putchar, (int c),          (c))
FWD(int, fflush,  (void *f),        (f))
FWD(int, fclose,  (void *f),        (f))
FWD(int, fputs,   (const char *s, void *f), (s, f))
FWD(int, fputc,   (int c, void *f), (c, f))
FWD(int, fgetc,   (void *f),        (f))
FWD(int, ferror,  (void *f),        (f))
FWD(int, feof,    (void *f),        (f))
FWD(void *, fopen, (const char *p, const char *m), (p, m))
FWD(size_t, fwrite, (const void *p, size_t a, size_t b, void *f), (p, a, b, f))
FWD(size_t, fread,  (void *p, size_t a, size_t b, void *f),       (p, a, b, f))
EXPORT int putc(int c, void *f) { return glibc_fputc(c, f); }
EXPORT int fputs_unlocked(const char *s, void *f) { return glibc_fputs(s, f); }

FWD(ssize_t, write, (int fd, const void *b, size_t n), (fd, b, n))
FWD(ssize_t, read,  (int fd, void *b, size_t n),       (fd, b, n))
FWD(int, close, (int fd), (fd))
FWD(int, getpid, (void), ())
FWD(int, atoi, (const char *s), (s))
FWD(long, strtol, (const char *s, char **e, int b), (s, e, b))
FWD(double, strtod, (const char *s, char **e), (s, e))
FWD(char *, getenv, (const char *n), (n))
FWD(long, time, (long *t), (t))
FWD(int, usleep, (unsigned u), (u))
FWD(int, sched_yield, (void), ())
FWD(long, sysconf, (int n), (n))
FWD(int, munmap, (void *a, size_t n), (a, n))
FWD(int, mprotect, (void *a, size_t n, int p), (a, n, p))
FWDV(qsort, (void *b, size_t n, size_t s, int (*c)(const void *, const void *)), (b, n, s, c))
EXPORT void *mmap(void *a, size_t n, int prot, int flags, int fd, long off)
{
    /* MAP_ANON differs: 0x1000 on Darwin, 0x20 on Linux. MAP_PRIVATE/SHARED/FIXED agree. */
    int lf = flags & 0x0f;
    if (flags & 0x1000) lf |= 0x20;
    if (flags & 0x0010) lf |= 0x10;              /* MAP_FIXED */
    return glibc_mmap(a, n, prot, lf, fd, off);
}

EXPORT void abort(void) { glibc_abort(); }

/* --------------------------------------------------------- exit / atexit */

struct atexit_entry { void (*fn)(void *); void *arg; void *dso; int is_cxa; };
static struct atexit_entry atexit_list[256];
static int atexit_n;

EXPORT int __cxa_atexit(void (*fn)(void *), void *arg, void *dso)
{
    if (atexit_n >= (int)(sizeof(atexit_list) / sizeof(atexit_list[0])))
        bail("more than 256 __cxa_atexit registrations");
    atexit_list[atexit_n].fn = fn;
    atexit_list[atexit_n].arg = arg;
    atexit_list[atexit_n].dso = dso;
    atexit_list[atexit_n].is_cxa = 1;
    atexit_n++;
    return 0;
}

EXPORT int atexit(void (*fn)(void))
{
    int rc = __cxa_atexit((void (*)(void *))fn, NULL, NULL);
    if (rc == 0) atexit_list[atexit_n - 1].is_cxa = 0;
    return rc;
}

EXPORT void __cxa_finalize(void *dso)
{
    /* Reverse registration order, and never run an entry twice. */
    for (int i = atexit_n - 1; i >= 0; i--) {
        struct atexit_entry e = atexit_list[i];
        if (!e.fn) continue;
        if (dso && e.dso != dso) continue;
        atexit_list[i].fn = NULL;
        if (e.is_cxa) e.fn(e.arg);
        else ((void (*)(void))e.fn)();
    }
}

EXPORT void exit(int code)
{
    __cxa_finalize(NULL);
    glibc_fflush(NULL);
    glibc_exit(code);
    __builtin_unreachable();
}

EXPORT void _Exit(int code) { glibc__exit(code); }

/* Darwin's POSIX _exit is Mach-O symbol __exit (C name _exit is taken by the
 * C `exit` mangling); spell it explicitly. */
EXPORT void mr_posix_exit(int code) __asm__("__exit");
EXPORT void mr_posix_exit(int code) { glibc__exit(code); }

EXPORT void __stack_chk_fail(void)
{
    bail("__stack_chk_fail: the guest detected a stack smash");
}

/* ------------------------------------------------------------- loader-side */

EXPORT void *_tlv_bootstrap(void *desc)
{
    (void)desc;
    bail("__tlv_bootstrap was entered. machorun patches every TLV descriptor's "
         "thunk at load time, so reaching the bootstrap means the loader did not "
         "see this image's __thread_vars");
}

EXPORT void _tlv_atexit(void (*fn)(void *), void *arg)
{
    (void)fn; (void)arg;
    bail("_tlv_atexit: C++ thread_local destructors are not implemented");
}

/* dyld_stub_binder is deliberately NOT defined here. Defining it inside a
 * dylib that ld64.lld is also generating a __stub_helper for makes lld-18
 * segfault in StubHelperSection::writeTo -- reproducible, and not worth
 * fighting. machorun binds the symbol to a trap inside the loader instead
 * (src/resolve.c), which gives the same loud failure with no link-time
 * fragility. */

/* --------------------------------------------------------------- pthread */

/* Darwin's opaque structs are compiled INTO the guest, so their layout is not
 * ours to choose: pthread_mutex_t is 64 bytes starting with a signature word,
 * pthread_once_t is 16. We keep a glibc object inside the opaque area and use
 * the signature word to tell "statically initialised by Apple's header" from
 * "already adopted by us". */
#define DARWIN_MUTEX_SIG 0x32AAABA7L
#define DARWIN_ONCE_SIG  0x30B1BCBAL
#define MR_ADOPTED_SIG   0x6D724F4BL   /* 'mrOK' */

struct darwin_opaque { long sig; unsigned char opaque[56]; };

static unsigned char adopt_lock_storage[64];
static int adopt_lock_ready;

static void *adopt_lock(void)
{
    if (!adopt_lock_ready) {           /* first use is before any thread exists */
        glibc_pthread_mutex_init(adopt_lock_storage, NULL);
        adopt_lock_ready = 1;
    }
    return adopt_lock_storage;
}

static void *adopt(struct darwin_opaque *o, long expect_sig, int is_once)
{
    if (o->sig != MR_ADOPTED_SIG) {
        glibc_pthread_mutex_lock(adopt_lock());
        if (o->sig != MR_ADOPTED_SIG) {
            if (o->sig != expect_sig && o->sig != 0)
                bail("a pthread object has an unexpected Darwin signature; its layout "
                     "was compiled into the guest and cannot be renegotiated");
            glibc_memset(o->opaque, 0, sizeof(o->opaque));
            if (!is_once) glibc_pthread_mutex_init(o->opaque, NULL);
            o->sig = MR_ADOPTED_SIG;
        }
        glibc_pthread_mutex_unlock(adopt_lock());
    }
    return o->opaque;
}

EXPORT int pthread_mutex_init(void *m, const void *attr)
{
    struct darwin_opaque *o = m;
    if (attr) bail("pthread_mutex_init with a non-NULL attribute is not implemented");
    glibc_memset(o->opaque, 0, sizeof(o->opaque));
    glibc_pthread_mutex_init(o->opaque, NULL);
    o->sig = MR_ADOPTED_SIG;
    return 0;
}
EXPORT int pthread_mutex_lock(void *m)    { return glibc_pthread_mutex_lock(adopt(m, DARWIN_MUTEX_SIG, 0)); }
EXPORT int pthread_mutex_trylock(void *m) { return glibc_pthread_mutex_trylock(adopt(m, DARWIN_MUTEX_SIG, 0)); }
EXPORT int pthread_mutex_unlock(void *m)  { return glibc_pthread_mutex_unlock(adopt(m, DARWIN_MUTEX_SIG, 0)); }
EXPORT int pthread_mutex_destroy(void *m)
{
    struct darwin_opaque *o = m;
    if (o->sig != MR_ADOPTED_SIG) return 0;
    o->sig = 0;
    return glibc_pthread_mutex_destroy(o->opaque);
}

EXPORT int pthread_once(void *once, void (*fn)(void))
{
    struct darwin_opaque *o = once;
    return glibc_pthread_once(adopt(o, DARWIN_ONCE_SIG, 1), fn);
}

EXPORT int pthread_create(void **thread, const void *attr, void *(*fn)(void *), void *arg)
{
    g_pthread_t t;
    int rc;
    if (attr) bail("pthread_create with a non-NULL pthread_attr_t is not implemented "
                   "(Darwin's attr struct layout differs from glibc's)");
    rc = glibc_pthread_create(&t, NULL, fn, arg);
    if (rc == 0) *thread = (void *)t;
    return rc;
}

EXPORT int   pthread_join(void *t, void **ret) { return glibc_pthread_join((g_pthread_t)t, ret); }
EXPORT int   pthread_detach(void *t)           { return glibc_pthread_detach((g_pthread_t)t); }
EXPORT void *pthread_self(void)                { return (void *)glibc_pthread_self(); }
EXPORT int   pthread_equal(void *a, void *b)   { return glibc_pthread_equal((g_pthread_t)a, (g_pthread_t)b); }
EXPORT int   pthread_key_create(unsigned *k, void (*d)(void *)) { return glibc_pthread_key_create(k, d); }
EXPORT int   pthread_key_delete(unsigned k)    { return glibc_pthread_key_delete(k); }
EXPORT void *pthread_getspecific(unsigned k)   { return glibc_pthread_getspecific(k); }
EXPORT int   pthread_setspecific(unsigned k, const void *v) { return glibc_pthread_setspecific(k, v); }

/* os_unfair_lock is a 4-byte struct in the guest; a global table would be
 * needed to map it onto a real mutex. Nothing in the corpus uses it yet. */
EXPORT void os_unfair_lock_lock(void *l)
{
    (void)l;
    bail("os_unfair_lock_lock is not implemented");
}
EXPORT void os_unfair_lock_unlock(void *l)
{
    (void)l;
    bail("os_unfair_lock_unlock is not implemented");
}
