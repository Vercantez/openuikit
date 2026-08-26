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

#include "dsys.h"

/* glibc's variadic snprintf, declared NON-variadically with the exact shape we
 * call it with. See the header comment: this is the safe crossing. */
extern int glibc_snprintf_d(char *, size_t, const char *, double) GLIBCSYM(snprintf);

/* --------------------------------------------------------- loud failure */

HIDDEN void mr_say(const char *s)
{
    glibc_write(2, s, glibc_strlen(s));
}

HIDDEN __attribute__((noreturn)) void mr_bail(const char *what)
{
    mr_say("machorun/libSystem: ");
    mr_say(what);
    mr_say("\n");
    glibc_fflush(NULL);
    glibc__exit(71);
    __builtin_unreachable();
}

HIDDEN __attribute__((noreturn)) void mr_bail2(const char *what, const char *detail)
{
    mr_say("machorun/libSystem: ");
    mr_say(what);
    mr_say(": ");
    mr_say(detail);
    mr_say("\n");
    glibc_fflush(NULL);
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
            int upper = 0, isneg = 0, alt_octal = 0;
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
                if (flags & FLAG_ALT) {
                    if (uv && base == 16) prefix = upper ? "0X" : "0x";
                    /* "#o increases the precision, if and only if necessary,
                     * to force the first digit of the result to be a zero"
                     * (C17 7.21.6.1). It is a precision bump, not a prefix --
                     * which is why %#o of 64 is "0100" and not "00100". */
                    else if (base == 8) alt_octal = 1;
                }
            }

            if (isneg) sign = '-';
            else if (flags & FLAG_PLUS) sign = '+';
            else if (flags & FLAG_SPACE) sign = ' ';

            n = utoa(uv, base, upper, num);
            {
                long zeros = (prec >= 0 && (long)n < prec) ? prec - (long)n : 0;
                if (alt_octal && zeros == 0) zeros = 1;
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
            mr_bail("%n in a format string is not supported");
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

/* FWD  -- a pure forwarder: same ABI on both sides, no errno in its contract.
 * FWDE -- a forwarder whose contract INCLUDES errno, so the guest's errno slot
 *         is pushed to glibc before the call and pulled back after it. See
 *         darwin/src/posix.c for why both halves are needed. */
#define FWD(ret, name, params, args)  EXPORT ret name params { return glibc_##name args; }
#define FWDV(name, params, args)      EXPORT void name params { glibc_##name args; }
#define FWDE(ret, name, params, args) EXPORT ret name params { return MR_ERRNO_CALL(glibc_##name args); }

FWDE(void *, malloc,  (size_t n),               (n))
FWDE(void *, calloc,  (size_t n, size_t m),     (n, m))
FWDE(void *, realloc, (void *p, size_t n),      (p, n))
FWDV(free, (void *p), (p))
FWDE(int, posix_memalign, (void **p, size_t a, size_t n), (p, a, n))
FWDE(void *, aligned_alloc, (size_t a, size_t n), (a, n))
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
FWDE(int, fflush,  (void *f),        (f))
FWDE(int, fclose,  (void *f),        (f))
FWD(int, fputs,   (const char *s, void *f), (s, f))
FWD(int, fputc,   (int c, void *f), (c, f))
FWD(int, fgetc,   (void *f),        (f))
FWD(int, ferror,  (void *f),        (f))
FWD(int, feof,    (void *f),        (f))
FWDE(void *, fopen, (const char *p, const char *m), (p, m))
FWDE(size_t, fwrite, (const void *p, size_t a, size_t b, void *f), (p, a, b, f))
FWDE(size_t, fread,  (void *p, size_t a, size_t b, void *f),       (p, a, b, f))
EXPORT int putc(int c, void *f) { return glibc_fputc(c, f); }
EXPORT int fputs_unlocked(const char *s, void *f) { return glibc_fputs(s, f); }

FWD(int, getpid, (void), ())
/* the strtol family lives in posix.c: Darwin sets EINVAL where glibc does not */
FWDE(double, strtod, (const char *s, char **e), (s, e))
FWD(char *, getenv, (const char *n), (n))
FWD(time_t, time, (time_t *t), (t))
FWD(int, fileno, (void *f), (f))
FWDE(int, fseek, (void *f, long o, int w), (f, o, w))
FWDE(long, ftell, (void *f), (f))
FWD(int, usleep, (unsigned u), (u))
FWD(int, sched_yield, (void), ())
FWD(long, sysconf, (int n), (n))
FWDE(int, munmap, (void *a, size_t n), (a, n))
FWDE(int, mprotect, (void *a, size_t n, int p), (a, n, p))
FWDV(qsort, (void *b, size_t n, size_t s, int (*c)(const void *, const void *)), (b, n, s, c))
EXPORT void *mmap(void *a, size_t n, int prot, int flags, int fd, long off)
{
    /* MAP_ANON differs: 0x1000 on Darwin, 0x20 on Linux. MAP_PRIVATE/SHARED/FIXED agree. */
    int lf = flags & 0x0f;
    if (flags & 0x1000) lf |= 0x20;
    if (flags & 0x0010) lf |= 0x10;              /* MAP_FIXED */
    return MR_ERRNO_CALL(glibc_mmap(a, n, prot, lf, fd, off));
}

EXPORT void abort(void) { glibc_abort(); }

/* --------------------------------------------------------- exit / atexit */

struct atexit_entry { void (*fn)(void *); void *arg; void *dso; int is_cxa; };
static struct atexit_entry atexit_list[256];
static int atexit_n;

EXPORT int __cxa_atexit(void (*fn)(void *), void *arg, void *dso)
{
    if (atexit_n >= (int)(sizeof(atexit_list) / sizeof(atexit_list[0])))
        mr_bail("more than 256 __cxa_atexit registrations");
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
    mr_bail("__stack_chk_fail: the guest detected a stack smash");
}

/* ------------------------------------------------------------- loader-side */

EXPORT void *_tlv_bootstrap(void *desc)
{
    (void)desc;
    mr_bail("__tlv_bootstrap was entered. machorun patches every TLV descriptor's "
         "thunk at load time, so reaching the bootstrap means the loader did not "
         "see this image's __thread_vars");
}

EXPORT void _tlv_atexit(void (*fn)(void *), void *arg)
{
    (void)fn; (void)arg;
    mr_bail("_tlv_atexit: C++ thread_local destructors are not implemented");
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
                mr_bail("a pthread object has an unexpected Darwin signature; its layout "
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
    if (attr) mr_bail("pthread_mutex_init with a non-NULL attribute is not implemented");
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
    if (attr) mr_bail("pthread_create with a non-NULL pthread_attr_t is not implemented "
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

/* os_unfair_lock is exactly four bytes in the guest -- Darwin stores an owning
 * thread port in them -- so it cannot hold a glibc pthread_mutex_t and cannot
 * be widened. We use the same four bytes as the lock word: 0 is unlocked, and
 * a locked lock holds the owner's Mach-ish thread token. Contention yields
 * rather than futex-waits; that is a fairness and CPU-burn difference under
 * heavy contention, not a correctness one, and it is recorded in
 * docs/UNIMPLEMENTED.md. */
static unsigned unfair_token(void)
{
    unsigned t = (unsigned)(glibc_pthread_self() >> 8);
    return t ? t : 1u;
}

EXPORT void os_unfair_lock_lock(void *l)
{
    unsigned *w = l, me = unfair_token(), expect = 0;
    while (!__atomic_compare_exchange_n(w, &expect, me, 1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
        if (expect == me)
            mr_bail("os_unfair_lock_lock: recursive acquisition by the owning thread "
                    "(Darwin traps this too, deliberately)");
        expect = 0;
        glibc_sched_yield();
    }
}

EXPORT int os_unfair_lock_trylock(void *l)
{
    unsigned *w = l, me = unfair_token(), expect = 0;
    return __atomic_compare_exchange_n(w, &expect, me, 0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED);
}

EXPORT void os_unfair_lock_unlock(void *l)
{
    unsigned *w = l, me = unfair_token();
    unsigned owner = __atomic_load_n(w, __ATOMIC_RELAXED);
    if (owner != me)
        mr_bail("os_unfair_lock_unlock: this thread does not own the lock");
    __atomic_store_n(w, 0u, __ATOMIC_RELEASE);
}

EXPORT void os_unfair_lock_assert_owner(void *l)
{
    if (__atomic_load_n((unsigned *)l, __ATOMIC_RELAXED) != unfair_token())
        mr_bail("os_unfair_lock_assert_owner: this thread does not own the lock");
}

EXPORT void os_unfair_lock_assert_not_owner(void *l)
{
    if (__atomic_load_n((unsigned *)l, __ATOMIC_RELAXED) == unfair_token())
        mr_bail("os_unfair_lock_assert_not_owner: this thread owns the lock");
}
