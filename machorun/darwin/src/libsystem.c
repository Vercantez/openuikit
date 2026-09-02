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
    mr_report_backtrace(NULL);
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
    mr_report_backtrace(NULL);
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

extern void tzset(void);
static void mr_init_libdispatch(void);   /* defined just below the bootstrap */

EXPORT void __machorun_libsystem_bootstrap(int argc, char **argv, char **envp, char **apple)
{
    mr_argc = argc; mr_argv = argv; mr_envp = envp; mr_apple = apple;
    /* Point at GLIBC's environ rather than at envp. They hold the same array
     * at this moment -- the loader passed its own environ as envp -- but
     * naming glibc's makes the two spellings the same object by construction
     * rather than by coincidence, which is the property the setenv family
     * above depends on. */
    (void)envp;
    environ = glibc_environ;
    __stdoutp = glibc_stdout;
    __stderrp = glibc_stderr;
    __stdinp  = glibc_stdin;
    __progname = argc > 0 ? argv[0] : "";
    /* Darwin's time functions populate timezone/daylight/tzname on first use,
     * so a guest may read them without ever calling tzset(). Establish them
     * once here rather than leaving zeros that would read as UTC. */
    tzset();
    /* Before any guest thread exists, so pthread_main_np has a truth to compare
     * against rather than a zero that would make every thread look like main. */
    mr_record_main_thread();
    /* THE POSITION IS THE POINT. See mr_init_libdispatch below. */
    mr_init_libdispatch();
}

/* libdispatch_init() IS NOT A CONSTRUCTOR, AND THAT IS NOT AN OVERSIGHT IN
 * libdispatch -- it is DISPATCH_EXPORT, an ordinary exported function, and on
 * Darwin **libSystem's own initialiser calls it**. libdispatch is a sub-library
 * of the libSystem umbrella there, so the call is a plain linked one.
 *
 * Nothing in our stack was making it, so every function pointer that init
 * assigns stayed NULL. Measured init sections: libswiftCore 1, libSystem 1,
 * libquartz 1, **libdispatch 0**. The symptom was a SIGSEGV at pc 0x0 inside
 * _dispatch_time -- a call through a null pointer rather than a bad address,
 * with the argument register holding exactly the nanoseconds the caller passed.
 *
 * THAT DISTANCE IS WHY THIS BELONGS HERE RATHER THAN AS A CONSTRUCTOR IN
 * SOMEONE'S libdispatch BUILD. The crash lands in dispatch_time, which is a
 * long way from a missing init, and the next person to meet it will not have
 * the diagnosis in hand -- they will go looking for a missing SYMBOL, because
 * that is what an absent callee usually means here. Putting the call where
 * Darwin puts it means no consumer has to discover this twice.
 *
 * WHY THE BOOTSTRAP AND NOT __attribute__((constructor)): this function runs at
 * the point src/main.c documents as "Darwin's libSystem initializer" -- AFTER
 * every image is mapped and bound, and BEFORE any guest initialiser. Both
 * halves are load-bearing. Mapped, because mr_dlsym_default searches the loaded
 * images and libdispatch must be among them; before, because a guest
 * initialiser that touches a dispatch queue would otherwise get the NULL
 * pointer we are here to fill.
 *
 * Looked up by name rather than linked, because libSystem does not depend on
 * libdispatch -- the dependency runs the other way, and a link here would be a
 * cycle. mr_dlsym_default is the loader's flat search over guest images and
 * deliberately does not fall back to the host, so a process with no libdispatch
 * gets NULL and this does nothing, which is the correct behaviour rather than
 * a fallback.
 *
 * A libdispatch dlopen'd LATER is not covered: the bootstrap has already run.
 * Nothing does that today, and the honest fix if something ever does is for the
 * loader to make the call on load rather than for this to poll. */
extern void *mr_dlsym_default(const char *name);   /* -> loader, resolve.c */

static void mr_init_libdispatch(void)
{
    void (*init)(void) = (void (*)(void))mr_dlsym_default("libdispatch_init");
    if (init) init();
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

/* ------------------------------------------------------------ the sscanf */

/* sscanf IS VARIADIC AND THEREFORE CANNOT BE FORWARDED, for the same reason
 * printf and dprintf cannot: Darwin's arm64 ABI passes variadic arguments on
 * the STACK where AAPCS64 passes the first eight in REGISTERS. glibc would
 * read registers this caller never wrote -- and every one of sscanf's variadic
 * arguments is a POINTER IT WRITES THROUGH, so a forward is a wild store per
 * conversion rather than a wrong number.
 *
 * IT IS DELIBERATELY NOT A GENERAL sscanf, and the reason is a measurement
 * rather than laziness. CoreFoundation's link census shows ONE call site (the
 * uuid code) plus one behind a TARGET_OS_MAC gate in CFTimeZone, which is
 * version parsing. A general parser is a project; the directives those two
 * need are an afternoon. So the supported set below is deliberately small AND
 * THE UNSUPPORTED CASE ABORTS BY NAME rather than silently converting nothing
 * -- because sscanf reports failure by returning a SHORT COUNT, which is
 * indistinguishable at the call site from input that legitimately did not
 * match. A directive we cannot handle must not look like a caller's bad input.
 *
 * Supported: whitespace, literals, %%, %n, assignment suppression with *,
 * field widths, and d i u o x X c s p, with hh h l ll z length modifiers.
 * Not supported and loud about it: the floating forms, %[, %S, %C.
 *
 * The return value is the number of items ASSIGNED, and EOF (-1) when input
 * ran out before the first conversion could start -- not 0. A caller looping
 * until sscanf returns less than it asked for cannot tell 0 from EOF, but a
 * caller checking for EOF specifically can, and CF does. */

static int mr_sc_isspace(int c)
{
    return c == ' ' || c == '\t' || c == '\n' || c == '\v' || c == '\f' || c == '\r';
}

static int mr_sc_digit(int c, int base)
{
    int d;
    if (c >= '0' && c <= '9')      d = c - '0';
    else if (c >= 'a' && c <= 'z') d = c - 'a' + 10;
    else if (c >= 'A' && c <= 'Z') d = c - 'A' + 10;
    else return -1;
    return d < base ? d : -1;
}

/* A FAILED CONVERSION IS NOT THE SAME ANSWER AS EXHAUSTED INPUT, and the
 * distinction is the one thing here I got wrong first and only found by diffing
 * against Apple's own sscanf. EOF (-1) means the input ran out BEFORE any
 * conversion could start; 0 means there was input and it did not match. So
 * sscanf("", "%d") is EOF and sscanf("zz", "%d") is 0 -- a caller looping until
 * EOF and one checking for a short count take different branches, and my first
 * version returned EOF for both. */
static int mr_sc_fail(const char *s, int assigned, int converted_any)
{
    if (converted_any) return assigned;
    return *s ? 0 : -1;                      /* matching failure vs EOF */
}

EXPORT int vsscanf(const char *in, const char *fmt, va_list ap)
{
    const char *s = in;
    int assigned = 0, converted_any = 0;

    while (*fmt) {
        if (mr_sc_isspace((unsigned char)*fmt)) {
            /* Whitespace in the format matches any run of it, including none. */
            while (mr_sc_isspace((unsigned char)*s)) s++;
            fmt++;
            continue;
        }
        if (*fmt != '%') {
            if (*s != *fmt) return mr_sc_fail(s, assigned, converted_any);
            s++; fmt++;
            continue;
        }

        fmt++;                                   /* past '%' */
        if (*fmt == '%') {
            if (*s != '%') return assigned;
            s++; fmt++;
            continue;
        }

        {
            int suppress = 0, width = 0, base = 10, neg = 0;
            int lmod = 0;                        /* 0 int, 1 long, 2 long long, -1 short, -2 char */
            unsigned long long acc = 0;
            int any = 0;

            if (*fmt == '*') { suppress = 1; fmt++; }
            while (*fmt >= '0' && *fmt <= '9') { width = width * 10 + (*fmt - '0'); fmt++; }
            if (*fmt == 'h') { fmt++; lmod = -1; if (*fmt == 'h') { fmt++; lmod = -2; } }
            else if (*fmt == 'l') { fmt++; lmod = 1; if (*fmt == 'l') { fmt++; lmod = 2; } }
            else if (*fmt == 'z') { fmt++; lmod = 1; }
            else if (*fmt == 'j') { fmt++; lmod = 2; }

            switch (*fmt) {
            case 'n': {
                if (!suppress) { int *p = va_arg(ap, int *); *p = (int)(s - in); }
                fmt++;
                continue;                        /* %n assigns but does not count */
            }
            case 'c': {
                int wantn = width ? width : 1, k;
                char *p = suppress ? 0 : va_arg(ap, char *);
                /* %c does NOT skip leading whitespace, which is the difference
                 * from every other directive here and the one most often got
                 * wrong -- a version that skipped would silently consume a
                 * separator the caller was about to match literally. */
                for (k = 0; k < wantn; k++) {
                    if (!s[k]) return mr_sc_fail(s + k, assigned, converted_any);
                    if (p) p[k] = s[k];
                }
                s += wantn;
                if (p) assigned++;
                converted_any = 1;
                fmt++;
                continue;
            }
            case 's': {
                char *p = suppress ? 0 : va_arg(ap, char *);
                int k = 0;
                while (mr_sc_isspace((unsigned char)*s)) s++;
                if (!*s) return mr_sc_fail(s, assigned, converted_any);
                while (*s && !mr_sc_isspace((unsigned char)*s) && (!width || k < width)) {
                    if (p) p[k] = *s;
                    s++; k++;
                }
                if (p) { p[k] = 0; assigned++; }
                converted_any = 1;
                fmt++;
                continue;
            }
            case 'p': base = 16; lmod = 2; goto number;
            case 'x': case 'X': base = 16; goto number;
            case 'o': base = 8;  goto number;
            case 'u': case 'd':  base = 10; goto number;
            case 'i': base = 0;  goto number;
            default:
                mr_bail("sscanf: an unsupported conversion. Only "
                        "d i u o x X c s p n %% with hh/h/l/ll/z are implemented, "
                        "because CoreFoundation's census showed two call sites and "
                        "a general parser is a different job. This aborts rather "
                        "than returning a short count, because a short count is "
                        "indistinguishable from input that legitimately did not "
                        "match. See docs/UNIMPLEMENTED.md#sscanf-subset.");
            }

number:
            while (mr_sc_isspace((unsigned char)*s)) s++;
            if (*s == '+' || *s == '-') {
                neg = (*s == '-');
                s++;
                if (width) width--;
            }
            if (base == 0) {                     /* %i sniffs the prefix */
                if (s[0] == '0' && (s[1] == 'x' || s[1] == 'X')) { base = 16; s += 2; }
                else if (s[0] == '0') base = 8;
                else base = 10;
            } else if (base == 16 && s[0] == '0' && (s[1] == 'x' || s[1] == 'X')) {
                s += 2;
                if (width) width -= 2;
            }
            {
                int k = 0, d;
                while ((!width || k < width) && (d = mr_sc_digit((unsigned char)*s, base)) >= 0) {
                    acc = acc * (unsigned)base + (unsigned)d;
                    s++; k++; any = 1;
                }
            }
            if (!any) return mr_sc_fail(s, assigned, converted_any);
            converted_any = 1;
            if (!suppress) {
                unsigned long long v = neg ? (unsigned long long)(-(long long)acc) : acc;
                /* The length modifier decides the WIDTH OF THE STORE, and this
                 * is the part a caller cannot recover from: writing 4 bytes
                 * through a `short *` clobbers whatever follows it, and the
                 * uuid call site uses %hhx into a byte array. */
                switch (lmod) {
                case -2: *va_arg(ap, unsigned char *)      = (unsigned char)v; break;
                case -1: *va_arg(ap, unsigned short *)     = (unsigned short)v; break;
                case  1: *va_arg(ap, unsigned long *)      = (unsigned long)v; break;
                case  2: *va_arg(ap, unsigned long long *) = v; break;
                default: *va_arg(ap, unsigned int *)       = (unsigned int)v; break;
                }
                assigned++;
            }
            fmt++;
        }
    }
    return assigned;
}

EXPORT int sscanf(const char *in, const char *fmt, ...)
{
    va_list ap; int n;
    va_start(ap, fmt);
    n = vsscanf(in, fmt, ap);
    va_end(ap);
    return n;
}

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

/* Locale construction is closed. Measured on the built dylib: libSystem
 * exports `setlocale` and no constructor -- no `newlocale`, `duplocale`,
 * `uselocale` or `freelocale`. A guest therefore CANNOT CONSTRUCT a locale_t.
 * The only values it can hold are NULL and LC_GLOBAL_LOCALE ((locale_t)-1,
 * measured on Darwin: sdk/usr/include/xlocale.h; glibc's LC_GLOBAL_LOCALE is
 * also (locale_t)-1L in bits/locale.h). And `setlocale` itself refuses
 * anything but "C"/"POSIX" (ctype.c), so the global locale is C as well.
 *
 * Both accepted values therefore MEAN the C locale. Anything else means the
 * guest obtained a locale_t from somewhere this library does not know about
 * -- which is exactly when acting in C would be a wrong answer, so it stops.
 *
 * This is shared by snprintf_l and the strto*_l family. glibc HAS strtod_l /
 * strtof_l / strtold_l (aarch64 libc.so.6, strtod_l@@GLIBC_2.17 and friends)
 * but Darwin's locale_t is `struct _xlocale *` (sdk/_types/_locale_t.h) and
 * glibc's is `struct __locale_struct *` (bits/types/__locale_t.h) -- same
 * pointer width, different pointee, and glibc treats a NULL locale_t as
 * invalid where Darwin treats it as C. Host-binding the Darwin name to glibc's
 * *_l would be a plausible parse of the wrong locale. */
HIDDEN void mr_require_c_locale(const void *loc, const char *who)
{
    if (loc != (void *)0 && loc != (void *)-1)
        mr_bail2(who, "locale this libSystem did not hand out: it exports "
                 "setlocale and no locale constructor, so the only locale_t a "
                 "guest can hold is NULL or LC_GLOBAL_LOCALE, and both mean C. "
                 "Acting in C for an unknown locale would put the wrong bytes "
                 "in the result and report success");
}

/* snprintf_l -- CFLog's, and the locale argument is the whole question.
 *
 * IT MUST GO THROUGH OUR OWN vsnprintf, not glibc's, and that is not a
 * preference: Darwin's arm64 varargs are all on the STACK with an 8-byte
 * va_list, AAPCS64 passes them in registers with a 32-byte one, so forwarding
 * any variadic formatter to glibc hands it garbage. That is why this library
 * owns a formatter at all.
 *
 * THE LOCALE IS ENFORCED BY CONSTRUCTION RATHER THAN ASSUMED -- see
 * mr_require_c_locale. Measured on Darwin, so the two accepted cases are
 * known to agree there too: snprintf_l(buf, n, NULL, "%d %.2f %s", 42, 1.5,
 * "x") and the same call with a freshly made "C" locale both yield 9 and
 * "42 1.50 x". */
EXPORT int snprintf_l(char *dst, size_t cap, void *loc, const char *fmt, ...)
{
    va_list ap; int n;
    mr_require_c_locale(loc, "snprintf_l");
    va_start(ap, fmt);
    n = vsnprintf(dst, cap, fmt, ap);
    va_end(ap);
    return n;
}

EXPORT int sprintf(char *dst, const char *fmt, ...)
{
    va_list ap; int n;
    va_start(ap, fmt);
    n = vsnprintf(dst, (size_t)-1, fmt, ap);
    va_end(ap);
    return n;
}

/* dprintf(3) belongs HERE rather than beside write() in posix.c, and the
 * reason is the whole point of this file having a formatter at all.
 *
 * It is VARIADIC. Darwin's arm64 ABI passes variadic arguments on the STACK;
 * AAPCS64, which glibc follows, passes the first eight in REGISTERS. A
 * `_glibc_dprintf` bind would have glibc read registers this caller never
 * wrote -- and for a format with a %s in it, that is a wild pointer being
 * dereferenced rather than a wrong number printed. So dprintf never reaches
 * glibc's: it formats with mr_vformat through vsnprintf, entirely on our side,
 * and hands the finished BYTES to write(2). The variadic convention is then
 * never crossed at all, which is a stronger property than translating it.
 *
 * libdispatch reaches this only on the DISPATCH_LOGFILE debug path, and that
 * does not make it optional: machorun binds eagerly, so an absent symbol is
 * fatal at LOAD, not at first call. "Only used when logging is on" is a
 * different claim from "only needed when logging is on". */
EXPORT int dprintf(int fd, const char *fmt, ...)
{
    char stackbuf[512], *buf = stackbuf;
    va_list ap;
    int n;

    va_start(ap, fmt);
    n = vsnprintf(stackbuf, sizeof stackbuf, fmt, ap);
    va_end(ap);
    if (n < 0) return -1;

    if ((size_t)n >= sizeof stackbuf) {      /* snprintf rules: n excludes the NUL */
        buf = glibc_malloc((size_t)n + 1);
        if (!buf) return -1;
        va_start(ap, fmt);
        vsnprintf(buf, (size_t)n + 1, fmt, ap);
        va_end(ap);
    }

    n = (int)MR_ERRNO_CALL(glibc_write(fd, buf, (size_t)n));
    if (buf != stackbuf) glibc_free(buf);
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
/* malloc_size is NOT malloc_usable_size, and the difference is load-bearing.
 *
 * Darwin's contract: "returns 0 if p was not allocated by any malloc zone".
 * Callers use it as an ownership test. objc4 is one: objc-runtime-new.h has
 *     static inline void try_free(const void *p)
 *     { if (p && malloc_size(p)) free((void *)p); }
 * and uses it in free_class() to tell a class_ro_t the compiler emitted into
 * __DATA_CONST from one the runtime allocated. glibc's malloc_usable_size does
 * no validation at all -- it reads the chunk header word before the pointer
 * and returns whatever is there, which for image data is a plausible non-zero
 * number. MEASURED: objc_disposeClassPair then free()s an address inside
 * libobjc's own mapping and glibc aborts with "munmap_chunk(): invalid
 * pointer" (tests/objc44/023-dynamic-class).
 *
 * So we answer the ownership question ourselves: anything inside a mapped
 * guest image is not ours. mr_addr_in_image is the loader's (src/image.c).
 * This is not an objc4 special case -- it is what the documented Darwin
 * behaviour is, and any guest that uses malloc_size as an ownership test gets
 * it right now. */
extern int mr_addr_in_image(const void *p);      /* -> loader, via host lookup */
extern int mr_addr_in_glibc_heap(const void *p); /* -> loader, via host lookup */

/* THE IMAGE CHECK ALONE WAS NOT ENOUGH, and the way that surfaced is worth
 * keeping: "munmap_chunk(): invalid pointer" -- the exact abort the paragraph
 * above records fixing for tests/objc44/023 -- came back in the UIKit scenes,
 * on tabbar_basic, with "free(): invalid pointer" on two more. A regression of
 * precisely the symptom a fix was written against says the fix was incomplete,
 * not that something new arrived.
 *
 * Incomplete because "not in an image" is not the same as "ours". A stack
 * address, the loader's own statics, and memory from any allocator that is not
 * glibc's all fell through to malloc_usable_size, which validates nothing and
 * answers with whatever word precedes the pointer. try_free() then frees it.
 *
 * So ownership is now established POSITIVELY rather than by elimination: a
 * pointer is ours only if it lies inside glibc's main-arena heap, whose bounds
 * the loader reads from /proc/self/maps. Anything we cannot place is answered
 * 0 -- "no malloc zone owns this" -- which is both Darwin's documented reply
 * for a foreign pointer and the safe direction: answering "not mine" for
 * something that was ours leaks it, answering "mine" for something that was
 * not corrupts the heap. src/map.c records the one case that costs us (an
 * allocation at or above glibc's 32 MiB mmap threshold lives outside brk and
 * so reports "not ours"). */
/* THE BRK CHECK ALONE UNDER-REPORTS, and existential-fix measured it: of ten
 * allocations from 32 MiB upward, four came back 0 from malloc_size for memory
 * malloc had just returned. Everything at or above glibc's 32 MiB
 * M_MMAP_THRESHOLD is served by mmap rather than brk, so it sits outside the
 * main arena and "not in brk" wrongly concluded "not ours". The first version
 * of this fix predicted that case and accepted it as a leak; it should not
 * have, because objc4's try_free is `if (p && malloc_size(p)) free(p)`, which
 * means a block of 32 MiB or more was never freed at all -- and any caller
 * using malloc_size to SIZE a buffer got 0 instead of its length.
 *
 * glibc's mmap-backed chunks are identifiable structurally, and cheaply.
 * Measured in the test-bed image across 32 MiB..256 MiB:
 *
 *     ptr=0xffff9235f010  offset-in-page 16  header 0x02001002  IS_MMAPPED=1
 *     ptr=0xffff8435f010  offset-in-page 16  header 0x10001002  IS_MMAPPED=1
 *     a small brk block   offset-in-page 688 header 0x51        IS_MMAPPED=0
 *
 * The chunk is page-aligned and the pointer is 16 bytes into it, the
 * IS_MMAPPED bit (0x2) is set, and PREV_INUSE (0x1) is clear -- mmap'd chunks
 * have no predecessor. Requiring all four, plus a page-aligned size, makes a
 * false positive need a pointer at exactly page+16 whose preceding word
 * happens to carry that bit pattern.
 *
 * The alignment test comes FIRST and is one AND: the header read only happens
 * for pointers that already look like a chunk base, so an arbitrary pointer is
 * never dereferenced on the strength of a guess. */
#define MR_MMAP_CHUNK_OFFSET 16
#define MR_IS_MMAPPED        0x2ULL
#define MR_PREV_INUSE        0x1ULL

static int in_glibc_mmap_chunk(const void *p)
{
    unsigned long a = (unsigned long)p;
    unsigned long long hdr, sz;

    /* 4096 rather than the real page size: a pointer 16 bytes into a 16 KiB
     * page is 16 bytes into a 4 KiB one too, so this is the looser gate and
     * the three checks below carry the weight. */
    if ((a & 0xfffUL) != MR_MMAP_CHUNK_OFFSET) return 0;

    hdr = *(const unsigned long long *)(a - 8);
    if (!(hdr & MR_IS_MMAPPED)) return 0;
    if (hdr & MR_PREV_INUSE)    return 0;
    sz = hdr & ~7ULL;
    if (sz < 0x1000ULL || (sz & 0xfffULL)) return 0;
    return 1;
}

EXPORT size_t malloc_size(const void *p)
{
    if (!p) return 0;
    if (mr_addr_in_image(p)) return 0;
    if (mr_addr_in_glibc_heap(p) || in_glibc_mmap_chunk(p))
        return glibc_malloc_usable_size((void *)p);
    return 0;
}
EXPORT size_t malloc_good_size(size_t n) { return n; }

FWD(char *, strncat, (char *d, const char *s, size_t n),  (d, s, n))
FWD(size_t, strnlen, (const char *s, size_t n),           (s, n))
FWD(void *, bsearch, (const void *k, const void *b, size_t n, size_t w,
                      int (*c)(const void *, const void *)),   (k, b, n, w, c))

/* div_t is {int quot; int rem;} on both systems -- 8 bytes, quot at 0, rem at
 * 4, measured against Apple's SDK -- so this could be a forward. It is written
 * out instead because the whole function is two divisions and doing it here
 * removes a struct-by-value return from the glibc boundary for nothing gained.
 * Darwin's contract is C's: truncation toward zero. */
typedef struct { int quot; int rem; }   mr_div_t;
typedef struct { long quot; long rem; } mr_ldiv_t;
_Static_assert(sizeof(mr_div_t) == 8, "div_t is 8 bytes");
EXPORT mr_div_t  div(int n, int d)        { mr_div_t r;  r.quot = n / d; r.rem = n % d; return r; }
EXPORT mr_ldiv_t ldiv(long n, long d)     { mr_ldiv_t r; r.quot = n / d; r.rem = n % d; return r; }

/* BSD, not POSIX: the program's short name, which __progname already holds
 * because __machorun_libsystem_bootstrap set it from argv[0]. Darwin returns
 * the basename; argv[0] may carry a path, so trim it here rather than storing
 * a second copy. */
EXPORT const char *getprogname(void)
{
    const char *p = __progname, *slash;
    if (!p) return "";
    for (slash = p; *p; p++) if (*p == '/') slash = p + 1;
    return slash;
}

/* Wide-char, for #48's libc++ surface. This file is -nostdinc, so wchar_t is
 * spelled out: it is `int` on arm64-apple-macos, 4 bytes and SIGNED.
 *
 * glibc's is also 4 bytes but UNSIGNED -- measured on both. Same width means
 * the same register, so the calling convention is identical and a forward is
 * safe; the signedness would only matter to a comparison that ordered
 * characters, and both of these only compare for equality. Noting it because
 * "same size" was the trap on pthread_cond_t, and it is worth being explicit
 * about which property is actually doing the work. sizeof(wchar_t) is pinned
 * in sdk/tests/abi_probe.c against Apple's SDK. */
typedef int mr_wchar_t;
FWD(size_t, wcslen,  (const mr_wchar_t *s),                 (s))
FWD(mr_wchar_t *, wmemchr, (const mr_wchar_t *s, mr_wchar_t c, size_t n), (s, c, n))
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
/* getline(3). POSIX on both sides: ssize_t getline(char **, size_t *, FILE *)
 * (Darwin sdk/_stdio.h:461; glibc stdio.h:707). ssize_t/size_t are 8 on both
 * (measured). Not variadic. FILE* is a pointer -- Darwin's FILE is 152 bytes
 * against glibc's 216, but the object behind every FILE* we hand out is
 * glibc's (fopen forward + bootstrap re-point). glibc exports getline
 * (getline@@GLIBC_2.17); the reason this is a wrapper rather than a
 * host-bound allow is that the FILE identity is a libSystem invariant, not a
 * CHECK 5 coincidence. */
FWDE(ssize_t, getline, (char **p, size_t *n, void *f), (p, n, f))
FWD(int, ungetc,  (int c, void *f), (c, f))
FWDV(rewind, (void *f), (f))
EXPORT int putc(int c, void *f) { return glibc_fputc(c, f); }
EXPORT int getc(void *f) { return glibc_fgetc(f); }
EXPORT int fputs_unlocked(const char *s, void *f) { return glibc_fputs(s, f); }

FWD(int, getpid, (void), ())
/* the strtol family lives in posix.c: Darwin sets EINVAL where glibc does not */
FWDE(double, strtod, (const char *s, char **e), (s, e))

/* strto*_l. glibc has the same names (strtod_l@@GLIBC_2.17, strtof_l,
 * strtold_l in aarch64 libc.so.6) and the same (nptr, endptr, locale)
 * arity, but the third argument is not the same object: Darwin locale_t is
 * struct _xlocale * and glibc's is struct __locale_struct *, and Darwin
 * NULL means C where glibc NULL is invalid. So these wrap strtod/strtof,
 * after mr_require_c_locale, rather than host-binding the Darwin name.
 *
 * strtold_l is the long-double trap a second time. Darwin arm64 long double
 * is 8 bytes, LDBL_MANT_DIG 53 (float.h via the SDK); glibc aarch64 is 16
 * bytes, LDBL_MANT_DIG 113. src/host_deny.c already denies a raw `_strtold`
 * host-bind for that reason. Calling glibc's strtold / strtold_l here would
 * write 16 bytes through an 8-byte return -- so this calls strtod, which is
 * what Darwin's long double IS. */
_Static_assert(sizeof(long double) == 8, "Darwin arm64 long double is IEEE binary64");

EXPORT double strtod_l(const char *s, char **e, void *loc)
{
    mr_require_c_locale(loc, "strtod_l");
    return MR_ERRNO_CALL(glibc_strtod(s, e));
}
EXPORT float strtof_l(const char *s, char **e, void *loc)
{
    mr_require_c_locale(loc, "strtof_l");
    return MR_ERRNO_CALL(glibc_strtof(s, e));
}
EXPORT long double strtold_l(const char *s, char **e, void *loc)
{
    mr_require_c_locale(loc, "strtold_l");
    return (long double)MR_ERRNO_CALL(glibc_strtod(s, e));
}

/* getsectiondata(3) -- <mach-o/getsect.h>. Mach-O only. aarch64 libc.so.6
 * has no such dynsym (measured: absent next to getline@@GLIBC_2.17 which IS
 * present), so a host-bind is a NULL bind, not an unrelated function. Walk
 * LC_SEGMENT_64 of an already-mapped header; slide is header - __TEXT.vmaddr,
 * the same construction cctools and libswiftcompat use. Structs are the
 * Mach-O on-disk layout, duplicated here because this file is -nostdinc. */
struct mr_mh64 {
    uint32_t magic, cputype, cpusubtype, filetype, ncmds, sizeofcmds, flags, reserved;
};
struct mr_lc { uint32_t cmd, cmdsize; };
struct mr_seg64 {
    uint32_t cmd, cmdsize; char segname[16];
    uint64_t vmaddr, vmsize, fileoff, filesize;
    uint32_t maxprot, initprot, nsects, flags;
};
struct mr_sect64 {
    char sectname[16], segname[16];
    uint64_t addr, size;
    uint32_t offset, align, reloff, nreloc, flags, reserved1, reserved2, reserved3;
};
#define MR_MH_MAGIC_64  0xfeedfacf
#define MR_LC_SEGMENT_64 0x19

EXPORT uint8_t *getsectiondata(const struct mr_mh64 *header, const char *segname,
                               const char *sectname, unsigned long *size)
{
    const uint8_t *p;
    intptr_t slide = 0;
    int have_slide = 0;
    uint32_t i, j;
    if (!header || header->magic != MR_MH_MAGIC_64 || !segname || !sectname) {
        if (size) *size = 0;
        return 0;
    }
    p = (const uint8_t *)header + sizeof(struct mr_mh64);
    for (i = 0; i < header->ncmds; i++) {
        const struct mr_lc *c = (const struct mr_lc *)p;
        if (c->cmd == MR_LC_SEGMENT_64) {
            const struct mr_seg64 *s = (const struct mr_seg64 *)c;
            if (!have_slide && glibc_strncmp(s->segname, "__TEXT", 16) == 0) {
                slide = (intptr_t)header - (intptr_t)s->vmaddr;
                have_slide = 1;
            }
        }
        p += c->cmdsize;
    }
    p = (const uint8_t *)header + sizeof(struct mr_mh64);
    for (i = 0; i < header->ncmds; i++) {
        const struct mr_lc *c = (const struct mr_lc *)p;
        if (c->cmd == MR_LC_SEGMENT_64) {
            const struct mr_seg64 *s = (const struct mr_seg64 *)c;
            if (glibc_strncmp(s->segname, segname, 16) == 0) {
                const struct mr_sect64 *sec = (const struct mr_sect64 *)(s + 1);
                for (j = 0; j < s->nsects; j++, sec++) {
                    if (glibc_strncmp(sec->sectname, sectname, 16) == 0) {
                        if (size) *size = (unsigned long)sec->size;
                        return (uint8_t *)(sec->addr + slide);
                    }
                }
            }
        }
        p += c->cmdsize;
    }
    if (size) *size = 0;
    return 0;
}

/* os_system_version_get_current_version. Darwin-only (not in sdk/ headers,
 * not in glibc -- measured absent from aarch64 libc.so.6 dynsym).
 *
 * THE CONVENTION WAS MEASURED FROM THE CALLER, not guessed from a C
 * declaration. libswiftCore's `__swift_stdlib_operatingSystemVersion` lazy
 * path (`__ZZZ36_...ENUlPvE_8__invoke`, vmaddr 0x39f9dc in the staged
 * swift-macosx/arm64 dylib) does this:
 *
 *     str  wzr, [sp, #8]
 *     str  xzr, [sp]          ; 12-byte zeroed slot
 *     mov  x0, sp             ; OUT-POINTER in x0
 *     bl   _os_system_version_get_current_version
 *     ldr  x8, [sp]           ; reads MEMORY after the call
 *     ldr  w9, [sp, #8]
 *     str  x8, [x19]
 *     str  w9, [x19, #8]
 *
 * It never consumes x0/x1 as a by-value struct. A `struct {u32,u32,u32}
 * f(void)` declaration compiled to `lsr x8, x0, #32; stp x8, x1, ...` and
 * SEGFAULTS on Darwin (oracle: exit 139 after the eight other names printed),
 * because the real callee stores through x0.
 *
 * Bind: the C fixture names it two-level from libSystem
 * (`nm -m`: `(undefined) external ... (from libSystem)`). libswiftCore binds
 * it FLAT (`weak external, dynamically looked up`) -- same spelling, no
 * two-level ordinal, which is why a second copy in libswiftcompat is a load-
 * order hazard. We export it from libSystem so both binds land here.
 *
 * 26.1.0 is the SDK version the corpus carries in LC_BUILD_VERSION, not a
 * claim about the host kernel. The fixture grades that the out-pointer was
 * written, not the digits, because Darwin's own provider reports the Mac's
 * OS (26.5.2 on the oracle machine). */
struct mr_os_version { uint32_t major, minor, patch; };
_Static_assert(sizeof(struct mr_os_version) == 12, "os_system_version is 3x u32");

EXPORT void os_system_version_get_current_version(struct mr_os_version *out)
{
    if (!out) return;
    out->major = 26;
    out->minor = 1;
    out->patch = 0;
}
/* THE ENVIRONMENT IS TWO ARRAYS WITH ONE NAME, and it was already latent
 * before anything wrote to it.
 *
 * `environ` is OUR exported variable, set at bootstrap from the loader's envp.
 * getenv forwards to glibc's, which reads GLIBC's environ. At startup those
 * hold the same contents, so everything works -- and they are two different
 * arrays. The moment anything mutates one, a guest walking `environ` and a
 * guest calling getenv see different environments, each internally consistent.
 * That is the two-reference-counts shape: no size differs, no constant
 * differs, and nothing structural catches it.
 *
 * So the family operates on ONE environment -- glibc's -- and `environ` is
 * re-pointed after every mutation. The re-point is not decoration: glibc's
 * setenv REALLOCATES the array when it grows, which changes the value of
 * glibc's environ, and a guest holding our stale pointer would be walking
 * freed memory. A cached copy taken once at bootstrap is correct exactly until
 * the first setenv, which is the worst possible lifetime for a bug.
 *
 * The guest reads `environ` as a VARIABLE, so there is no read to intercept;
 * re-syncing on write is the only point of control we have. It is sufficient
 * because libSystem is the only path by which a guest can mutate anything. */
static void mr_sync_environ(void) { environ = glibc_environ; }

FWD(char *, getenv, (const char *n), (n))

EXPORT int setenv(const char *name, const char *value, int overwrite)
{
    int rc = MR_ERRNO_CALL(glibc_setenv(name, value, overwrite));
    mr_sync_environ();
    return rc;
}

EXPORT int unsetenv(const char *name)
{
    int rc = MR_ERRNO_CALL(glibc_unsetenv(name));
    mr_sync_environ();
    return rc;
}

/* putenv takes ownership of the CALLER's string on both systems -- it stores
 * the pointer rather than copying -- so the buffer must outlive the call. That
 * contract is identical here and is why this is a forward rather than a copy:
 * copying would look tidier and would break a caller that later modifies its
 * own buffer to change the value, which is legal and which some code does. */
EXPORT int putenv(char *string)
{
    int rc = MR_ERRNO_CALL(glibc_putenv(string));
    mr_sync_environ();
    return rc;
}
FWD(time_t, time, (time_t *t), (t))
FWD(int, fileno, (void *f), (f))
FWDE(int, fseek, (void *f, long o, int w), (f, o, w))
FWDE(long, ftell, (void *f), (f))
FWD(int, usleep, (unsigned u), (u))
FWD(int, sched_yield, (void), ())
/* sysconf CANNOT be forwarded, and the reason is stark: of the 128 _SC_* names
 * that exist on both systems, ALL 128 have different values. Darwin's
 * _SC_PAGESIZE is 29 and Linux's is 30; _SC_NPROCESSORS_ONLN is 58 against 84.
 * A raw forward reads the wrong row of glibc's table for every query a guest
 * ever makes. Measured before this was fixed:
 *
 *     sysconf(_SC_PAGESIZE)         -> 200809   (macOS answers 16384)
 *     sysconf(_SC_NPROCESSORS_ONLN) -> -1       (macOS answers 16)
 *     sysconf(_SC_OPEN_MAX)         -> 16       (macOS answers 1048576)
 *
 * The third is the one to worry about. 200809 is obvious nonsense and -1 is a
 * failure, but 16 is a perfectly plausible open-file limit -- a guest sizing a
 * table with it is simply wrong, quietly.
 *
 * An unmapped name returns -1/EINVAL, which is sysconf's DOCUMENTED answer for
 * a name it does not recognise. That is a real answer rather than a guess, and
 * it is the direction to be wrong in: a caller that gets -1 knows it learned
 * nothing, where a caller that gets a number does not.
 *
 * darwin/src/sysconf_table.h is generated by scripts/gen_sysconf_table.sh,
 * which measures both platforms rather than trusting a hand-written table. */
#include "sysconf_table.h"

EXPORT long sysconf(int darwin_name)
{
    int linux_name;
    if (darwin_name < 0 || darwin_name >= MR_SYSCONF_D2L_N ||
        (linux_name = mr_sysconf_d2l[darwin_name]) < 0) {
        *mr_errno_slot() = 22;                    /* Darwin EINVAL */
        return -1;
    }
    return MR_ERRNO_CALL(glibc_sysconf(linux_name));
}
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

/* EVERY pthread RETURN VALUE HAS TO BE TRANSLATED, and this is not cosmetic.
 * pthread reports errors as its return value rather than through errno, and
 * the two platforms disagree about the numbers -- including one pair that is
 * swapped, which is the worst case because both values are valid on both
 * sides:
 *
 *      name          Darwin   Linux
 *      ETIMEDOUT         60     110
 *      EDEADLK           11      35
 *      EAGAIN            35      11     <- swapped with EDEADLK
 *      EBUSY             16      16     (happens to agree)
 *
 * Found by tests/bin/pthread_cond's NEGATIVE CONTROL: a timedwait nobody
 * signals must report ETIMEDOUT, and it reported "waited=yes timedout=NO"
 * under machorun -- the wait was correct and the verdict was not. A guest
 * comparing against Darwin's 60 sees 110 and concludes the wait succeeded,
 * so it proceeds as though its predicate were true. Nothing aborts.
 *
 * mr_pthread_rc() runs each return through the same table errno already uses
 * (darwin/src/errno_table.h). 0 stays 0. */
/* Darwin's opaque structs are compiled INTO the guest, so their layout is not
 * ours to choose: pthread_mutex_t is 64 bytes starting with a signature word,
 * pthread_once_t is 16. We keep a glibc object inside the opaque area and use
 * the signature word to tell "statically initialised by Apple's header" from
 * "already adopted by us". */
/* THE STATIC INITIALISER'S SIGNATURE *IS* THE TYPE, and there are THREE of
 * them, not one. This is the constants family wearing the ABI's own clothes:
 * the value is not a flag anyone passes, it is the first eight bytes of an
 * object the guest's compiler laid down, so nothing at any call site names it.
 *
 * Measured off Apple's own headers (a probe that reads the first word of each
 * public initialiser -- the ABI as compiled, not as documented):
 *
 *      PTHREAD_MUTEX_INITIALIZER              0x32AAABA7
 *      PTHREAD_ERRORCHECK_MUTEX_INITIALIZER   0x32AAABA1
 *      PTHREAD_RECURSIVE_MUTEX_INITIALIZER    0x32AAABA2
 *      PTHREAD_COND_INITIALIZER               0x3CB0B1BB   (one only)
 *      PTHREAD_RWLOCK_INITIALIZER             0x2DA8B3B4   (one only)
 *      PTHREAD_ONCE_INIT                      0x30B1BCBA   (one only)
 *
 * ACCEPTING ONLY THE FIRST ONE WAS A REAL WALL, not a theoretical one.
 * CoreFoundation's `CFLock_t` is `pthread_mutex_t` and `CFLockInit` is
 * `PTHREAD_ERRORCHECK_MUTEX_INITIALIZER` (CFLocking.h), so that is CF's lock
 * EVERYWHERE -- and the first CFPreferences call died in pthread_mutex_lock
 * before touching a file. It had not surfaced earlier only because the CFString
 * and CFDictionary paths exercised so far never take one.
 *
 * FIRSTFIT (0x32AAABA3) IS A FOURTH, AND ENUMERATING IT TOOK TWO GOES -- worth
 * recording, because the first answer was wrong in the reassuring direction.
 * Compiling `#ifdef PTHREAD_FIRSTFIT_MUTEX_INITIALIZER` against Apple's SDK
 * says NOT DEFINED, and the conclusion "a guest cannot name it" followed
 * naturally and was false: grepping the SDK finds that macro in
 * `<pthread/pthread_spis.h>`, an SPI header `<pthread.h>` does not pull in. A
 * guest that includes it explicitly gets a real firstfit initialiser. The
 * enumeration was scoped to what one #include could see, and reported cleanly
 * about a set that excluded the answer.
 *
 * It is ACCEPTED and mapped to the DEFAULT type, and that is measured rather
 * than assumed harmless: with the SPI header included, a firstfit mutex on
 * macOS answers lock 0, trylock-while-held EBUSY, unlock 0 and
 * UNLOCK-UNOWNED 0 -- bit for bit the DEFAULT mutex's observable contract.
 * "First fit" is a WAKEUP-ORDERING policy, not an error-checking one, so from
 * any single thread the two are indistinguishable. What mapping loses is which
 * waiter glibc wakes, and glibc offers no way to select that. A missed
 * optimisation, not a broken promise: neither platform's default mutex
 * guarantees an order, so no caller can observe a violated one. Recorded in
 * docs/UNIMPLEMENTED.md#pthread-mutex-firstfit, and deliberately NOT covered by
 * tests/bin/pthread_mutex_variants -- our sysroot does not stage
 * pthread/pthread_spis.h, so the fixture cannot name the initialiser at all.
 *
 * The variants are a MUTEX-only family. cond, rwlock and once have exactly one
 * public initialiser each -- checked the second way this time, by grepping
 * every `PTHREAD_*_INITIALIZER`/`_INIT` macro out of Apple's pthread headers
 * rather than by guessing names to #ifdef -- which is why their own checks a
 * few hundred lines down still compare against a single value. */
#define DARWIN_MUTEX_SIG            0x32AAABA7L
#define DARWIN_MUTEX_SIG_ERRORCHECK 0x32AAABA1L
#define DARWIN_MUTEX_SIG_RECURSIVE  0x32AAABA2L
#define DARWIN_MUTEX_SIG_FIRSTFIT   0x32AAABA3L
#define DARWIN_ONCE_SIG  0x30B1BCBAL
#define MR_ADOPTED_SIG   0x6D724F4BL   /* 'mrOK' */

struct darwin_opaque { long sig; unsigned char opaque[56]; };

/* Darwin static-initialiser signature -> DARWIN mutex type, or -1. It stops at
 * Darwin's type on purpose and hands off to mutex_type_d2g() below rather than
 * mapping to glibc's directly: the two platforms' type numbers are SWAPPED
 * (Darwin ERRORCHECK 1 / RECURSIVE 2, glibc RECURSIVE 1 / ERRORCHECK 2, both
 * measured), so a second table doing the same job would be a second place to
 * get that inversion wrong. */
static int mutex_type_d2g(int darwin_type);

static int mutex_type_for_sig(long sig)
{
    if (sig == DARWIN_MUTEX_SIG || sig == 0)      return 0;  /* NORMAL */
    if (sig == DARWIN_MUTEX_SIG_ERRORCHECK)       return 1;  /* ERRORCHECK */
    if (sig == DARWIN_MUTEX_SIG_RECURSIVE)        return 2;  /* RECURSIVE */
    /* firstfit: a wakeup-ORDERING policy, and its single-threaded contract is
     * measured to be the default's exactly. See the note above. */
    if (sig == DARWIN_MUTEX_SIG_FIRSTFIT)         return 0;
    return -1;
}

/* Initialise glibc's mutex with the type the guest's initialiser asked for.
 * The default goes through the attr-less path so the common case allocates and
 * destroys nothing. */
static void mutex_init_typed(void *storage, int darwin_type)
{
    unsigned char attr[16];              /* glibc's pthread_mutexattr_t is 8 */
    int g;
    if (darwin_type == 0) { glibc_pthread_mutex_init(storage, (void *)0); return; }
    g = mutex_type_d2g(darwin_type);
    glibc_memset(attr, 0, sizeof attr);
    glibc_pthread_mutexattr_init(attr);
    glibc_pthread_mutexattr_settype(attr, g);
    glibc_pthread_mutex_init(storage, attr);
    glibc_pthread_mutexattr_destroy(attr);
}

/* "0x" + 16 hex digits + NUL, for a bail that names what it actually saw. A
 * message that says "an unexpected signature" and not WHICH one costs the next
 * person the same measurement this one took. */
static const char *sig_hex(long v, char out[19])
{
    static const char d[] = "0123456789ABCDEF";
    int i;
    out[0] = '0'; out[1] = 'x';
    for (i = 0; i < 16; i++)
        out[2 + i] = d[(unsigned long)v >> (60 - 4 * i) & 0xf];
    out[18] = 0;
    return out;
}

/* The lock that guards lazy adoption must not itself be lazily initialised,
 * and it used to be:
 *
 *     if (!adopt_lock_ready) {        // "first use is before any thread exists"
 *         glibc_pthread_mutex_init(adopt_lock_storage, NULL);
 *         adopt_lock_ready = 1;
 *     }
 *
 * That comment was an assumption, not a fact. Two guest threads whose first
 * touch of any pthread object races will both see adopt_lock_ready == 0, and
 * one re-runs pthread_mutex_init over storage the other already holds locked.
 * glibc then futexes on a re-initialised word and aborts with "The futex
 * facility returned an unexpected error code" -- out of a fixture that has no
 * bug in it. MEASURED before this fix: tests/bin/pthread aborted 10 times
 * in 300 runs, about 3%, which is precisely the rate at which a corpus that
 * runs each fixture ONCE looks green. objcsupport.c's dtsd_key_make() had the
 * same bug behind the same "nothing is threaded yet" comment; this is the
 * second instance of it, so the assumption is the pattern, not the accident.
 *
 * There is nothing to initialise. glibc's PTHREAD_MUTEX_INITIALIZER is all
 * zeroes and pthread_mutex_init(&m, NULL) produces an all-zero object --
 * measured on the test image, sizeof 48, both all-zero. Static storage is
 * already zero, so this IS an initialised default mutex from the process's
 * first instruction, with no window to race over. 64 bytes because Darwin's
 * opaque is 64; glibc needs 48 of them. */
static unsigned char adopt_lock_storage[64];

static void *adopt_lock(void) { return adopt_lock_storage; }

/* Double-checked locking, so the two accesses to o->sig outside/inside the lock
 * have to be ordered explicitly. The fast path is an ACQUIRE load and the
 * publish is a RELEASE store: without that pairing, arm64 is free to let a
 * second thread observe MR_ADOPTED_SIG before it observes the mutex bytes
 * glibc_pthread_mutex_init just wrote, and it would then lock uninitialised
 * memory. That is the same futex abort as the adopt_lock bug above, from the
 * other end. */
static void *adopt(struct darwin_opaque *o, long expect_sig, int is_once)
{
    if (__atomic_load_n(&o->sig, __ATOMIC_ACQUIRE) != MR_ADOPTED_SIG) {
        glibc_pthread_mutex_lock(adopt_lock());
        if (o->sig != MR_ADOPTED_SIG) {
            /* A MUTEX may arrive under any of Darwin's three public static
             * initialisers, and the signature is the only thing that says
             * which -- so it is read for its TYPE, not merely checked. The
             * once path keeps the single-value check it always had, because
             * Apple publishes exactly one PTHREAD_ONCE_INIT. */
            int dtype = is_once ? -1 : mutex_type_for_sig(o->sig);
            if (is_once ? (o->sig != expect_sig && o->sig != 0) : (dtype < 0)) {
                char hex[19];
                mr_bail2("a pthread object has an unexpected Darwin signature; its "
                         "layout was compiled into the guest and cannot be "
                         "renegotiated. Accepted static initialisers are "
                         "0x32AAABA7 (default), 0x32AAABA1 (errorcheck), "
                         "0x32AAABA2 (recursive) and 0x32AAABA3 (firstfit) for a "
                         "mutex, 0x30B1BCBA for a once. Found", sig_hex(o->sig, hex));
            }
            glibc_memset(o->opaque, 0, sizeof(o->opaque));
            if (!is_once) mutex_init_typed(o->opaque, dtype);
            __atomic_store_n(&o->sig, MR_ADOPTED_SIG, __ATOMIC_RELEASE);
        }
        glibc_pthread_mutex_unlock(adopt_lock());
    }
    return o->opaque;
}

EXPORT int pthread_mutex_init(void *m, const void *attr)
{
    struct darwin_opaque *o = m;
    const struct darwin_opaque *ao = attr;
    /* An attribute is now honoured, which std::recursive_mutex needs. It must
     * be one WE adopted: a Darwin-initialised pthread_mutexattr_t holds
     * Apple's bytes, not glibc's, and passing those through would set a type
     * nobody chose. See the type-swap note above. */
    if (ao && ao->sig != MR_ADOPTED_SIG)
        mr_bail("pthread_mutex_init was given a pthread_mutexattr_t this libSystem "
                "did not initialise; its contents are Darwin's, not glibc's");
    glibc_memset(o->opaque, 0, sizeof(o->opaque));
    glibc_pthread_mutex_init(o->opaque, ao ? (const void *)ao->opaque : (const void *)0);
    o->sig = MR_ADOPTED_SIG;
    return 0;
}
EXPORT int pthread_mutex_lock(void *m)    { return mr_pthread_rc(glibc_pthread_mutex_lock(adopt(m, DARWIN_MUTEX_SIG, 0))); }
EXPORT int pthread_mutex_trylock(void *m) { return mr_pthread_rc(glibc_pthread_mutex_trylock(adopt(m, DARWIN_MUTEX_SIG, 0))); }
EXPORT int pthread_mutex_unlock(void *m)  { return mr_pthread_rc(glibc_pthread_mutex_unlock(adopt(m, DARWIN_MUTEX_SIG, 0))); }
EXPORT int pthread_mutex_destroy(void *m)
{
    struct darwin_opaque *o = m;
    if (o->sig != MR_ADOPTED_SIG) return 0;
    o->sig = 0;
    return mr_pthread_rc(glibc_pthread_mutex_destroy(o->opaque));
}

/* ===================================================================== *
 * Condition variables and mutex attributes.
 *
 * These back std::mutex and std::condition_variable in the libc++ we build,
 * and libdispatch's semaphore shim sits on them, so "it links" is not the bar.
 * Two things here are wrong in ways no size check can catch.
 *
 * ONE: pthread_cond_t CANNOT use adopt(), even though the totals look fine.
 *
 *      type                  Darwin total   Darwin OPAQUE   glibc
 *      pthread_mutex_t                 64              56      48   fits
 *      pthread_mutexattr_t             16               8       8   fits EXACTLY
 *      pthread_cond_t                  48              40      48   DOES NOT FIT
 *
 * The tempting reading is "48 == 48". But Darwin's first 8 bytes are the __sig
 * word, and that word is the entire mechanism for telling an Apple-initialised
 * object from one we adopted -- overwrite it and PTHREAD_COND_INITIALIZER
 * becomes indistinguishable from an adopted cond. So only 40 bytes are ours,
 * and a glibc cond is 48. Measured on macOS 26.5.2 and in the test-bed image,
 * and pinned in sdk/tests/glibc_abi_probe.c.
 *
 * So a cond holds a POINTER to a heap-allocated glibc cond -- the "indirect"
 * remedy in docs/UNIMPLEMENTED.md#opaque-abi-class, the same shape
 * posix_spawnattr_t needs. 40 bytes is ample for 8. A statically initialised
 * cond is handled by construction: it arrives with __sig == Darwin's
 * _PTHREAD_COND_SIG_init, which is exactly the case the signature check
 * catches, and we allocate on first use. The cost is that a static cond which
 * is never destroyed leaks one glibc cond -- bounded by the number of distinct
 * cond objects, not by operations, and far better than a design that cannot
 * accept a static initialiser at all.
 *
 * TWO: the mutex TYPE constants are SWAPPED between the platforms.
 *
 *      value   Darwin        glibc
 *          0   NORMAL        NORMAL
 *          1   ERRORCHECK    RECURSIVE
 *          2   RECURSIVE     ERRORCHECK
 *
 * Measured on both, because this one is invisible: a forwarded
 * pthread_mutexattr_settype(attr, PTHREAD_MUTEX_RECURSIVE) passes Darwin's 2,
 * glibc reads ERRORCHECK, and std::recursive_mutex becomes an error-checking
 * mutex that returns EDEADLK the first time it is relocked by its owner. Every
 * symbol resolves, every size matches, and the behaviour inverts. Constants
 * need translating exactly as layouts do.
 * ===================================================================== */
#define DARWIN_COND_SIG  0x3CB0B1BBL   /* _PTHREAD_COND_SIG_init, pthread_impl.h */

/* Darwin's opaque area for a cond is 40 bytes; we use the first 8 as a handle.
 * Asserted rather than assumed, because the whole design rests on it. */
_Static_assert(sizeof(struct darwin_opaque) >= 16, "need 8 bytes of opaque for the cond handle");

static int mutex_type_d2g(int darwin_type)
{
    switch (darwin_type) {
    case 0: return 0;    /* NORMAL     -> NORMAL     */
    case 1: return 2;    /* ERRORCHECK -> ERRORCHECK */
    case 2: return 1;    /* RECURSIVE  -> RECURSIVE  */
    default: return -1;
    }
}
static int mutex_type_g2d(int glibc_type)
{
    switch (glibc_type) {
    case 0: return 0;
    case 2: return 1;
    case 1: return 2;
    default: return -1;
    }
}

/* A cond's glibc object, allocated on first use. The adopt lock serialises
 * creation: two threads may reach the same statically-initialised cond at
 * once, and creating two glibc conds for one guest cond would lose wakeups. */
static void *cond_glibc(struct darwin_opaque *o)
{
    void **slot = (void **)o->opaque;
    if (__atomic_load_n(&o->sig, __ATOMIC_ACQUIRE) == MR_ADOPTED_SIG) return *slot;

    glibc_pthread_mutex_lock(adopt_lock());
    if (o->sig != MR_ADOPTED_SIG) {
        void *c;
        if (o->sig != DARWIN_COND_SIG && o->sig != 0)
            mr_bail("a pthread_cond_t has an unexpected Darwin signature; its layout "
                    "was compiled into the guest and cannot be renegotiated");
        c = glibc_malloc(64);            /* glibc's cond is 48; 64 is slack, not a guess */
        if (!c) { glibc_pthread_mutex_unlock(adopt_lock()); return 0; }
        glibc_memset(c, 0, 64);
        glibc_pthread_cond_init(c, 0);
        *slot = c;
        __atomic_store_n(&o->sig, MR_ADOPTED_SIG, __ATOMIC_RELEASE);
    }
    glibc_pthread_mutex_unlock(adopt_lock());
    return *slot;
}

EXPORT int pthread_cond_init(void *cond, const void *attr)
{
    struct darwin_opaque *o = cond;
    if (attr) mr_bail("pthread_cond_init with a non-NULL attribute is not implemented "
                      "(Darwin's pthread_condattr_t layout is not glibc's)");
    /* Re-initialising an adopted cond reuses its glibc object rather than
     * leaking the old one. */
    if (__atomic_load_n(&o->sig, __ATOMIC_ACQUIRE) == MR_ADOPTED_SIG) {
        void *c = *(void **)o->opaque;
        glibc_pthread_cond_destroy(c);
        glibc_memset(c, 0, 64);
        return mr_pthread_rc(glibc_pthread_cond_init(c, 0));
    }
    o->sig = 0;                          /* force a fresh adoption */
    return cond_glibc(o) ? 0 : 12 /* ENOMEM */;
}

EXPORT int pthread_cond_destroy(void *cond)
{
    struct darwin_opaque *o = cond;
    void *c;
    if (__atomic_load_n(&o->sig, __ATOMIC_ACQUIRE) != MR_ADOPTED_SIG) return 0;
    c = *(void **)o->opaque;
    o->sig = 0;
    *(void **)o->opaque = 0;
    glibc_pthread_cond_destroy(c);
    glibc_free(c);
    return 0;
}

EXPORT int pthread_cond_wait(void *cond, void *mutex)
{
    void *c = cond_glibc(cond);
    if (!c) return 12;
    return mr_pthread_rc(glibc_pthread_cond_wait(c, adopt(mutex, DARWIN_MUTEX_SIG, 0)));
}

EXPORT int pthread_cond_timedwait(void *cond, void *mutex, const void *abstime)
{
    void *c = cond_glibc(cond);
    if (!c) return 12;
    /* struct timespec is 16 bytes with the same field offsets on both -- pinned
     * in sdk/tests/glibc_abi_probe.c -- so it crosses unchanged. */
    return mr_pthread_rc(glibc_pthread_cond_timedwait(c, adopt(mutex, DARWIN_MUTEX_SIG, 0), abstime));
}

EXPORT int pthread_cond_signal(void *cond)
{
    void *c = cond_glibc(cond);
    return c ? mr_pthread_rc(glibc_pthread_cond_signal(c)) : 12;
}

EXPORT int pthread_cond_broadcast(void *cond)
{
    void *c = cond_glibc(cond);
    return c ? mr_pthread_rc(glibc_pthread_cond_broadcast(c)) : 12;
}

/* Darwin's pthread_mutexattr_t is 16 bytes: 8 of signature and 8 opaque. glibc
 * needs exactly 8, so it fits with ZERO MARGIN -- one glibc release from being
 * an overflow, with nothing to announce it. That is why it is pinned. */
EXPORT int pthread_mutexattr_init(void *a)
{
    struct darwin_opaque *o = a;
    glibc_memset(o->opaque, 0, 8);
    glibc_pthread_mutexattr_init(o->opaque);
    o->sig = MR_ADOPTED_SIG;
    return 0;
}
EXPORT int pthread_mutexattr_destroy(void *a)
{
    struct darwin_opaque *o = a;
    if (o->sig != MR_ADOPTED_SIG) return 0;
    o->sig = 0;
    return mr_pthread_rc(glibc_pthread_mutexattr_destroy(o->opaque));
}
EXPORT int pthread_mutexattr_settype(void *a, int type)
{
    struct darwin_opaque *o = a;
    int g = mutex_type_d2g(type);
    if (g < 0) return 22;                /* EINVAL */
    if (o->sig != MR_ADOPTED_SIG) pthread_mutexattr_init(a);
    return mr_pthread_rc(glibc_pthread_mutexattr_settype(o->opaque, g));
}
EXPORT int pthread_mutexattr_gettype(void *a, int *type)
{
    struct darwin_opaque *o = a;
    int g = 0, rc;
    if (o->sig != MR_ADOPTED_SIG) return 22;
    rc = glibc_pthread_mutexattr_gettype(o->opaque, &g);
    if (rc == 0 && type) *type = mutex_type_g2d(g);
    return rc;
}

/* ===================================================================== *
 * Read-write locks.
 *
 * libunwind takes one around its DWARF FDE cache and around its dynamic
 * unwind-section registry, so unwinding cannot work without these -- they were
 * the first thing the link failed on.
 *
 * UNLIKE pthread_cond_t, THIS ONE FITS INLINE, and the difference is measured
 * rather than assumed because the cond case looked identical and was not:
 *
 *      type                    Darwin total   Darwin OPAQUE   glibc
 *      pthread_rwlock_t                 200             192      56   fits, 136 spare
 *      pthread_rwlockattr_t              24              16       8   fits
 *
 * macOS 26.5.2 and the test-bed image, pinned in sdk/tests/glibc_abi_probe.c.
 * So a rwlock can use adopt()'s scheme directly: glibc's object lives in the
 * guest's own bytes and no handle or allocation is needed.
 *
 * DARWIN HAS TWO SIGNATURES FOR A RWLOCK AND ONLY ONE OF THEM CAN REACH US.
 * Measured: PTHREAD_RWLOCK_INITIALIZER leaves __sig == 0x2DA8B3B4, and after
 * Apple's pthread_rwlock_init it is 0x52574C4B ('RWLK'). The second can never
 * appear here, because OUR pthread_rwlock_init writes MR_ADOPTED_SIG instead --
 * so the static-initialiser value is the only Darwin signature this code ever
 * sees. Recorded because "why is only one constant here" is otherwise a
 * reasonable thing to get wrong later.
 * ===================================================================== */
#define DARWIN_RWLOCK_SIG 0x2DA8B3B4L   /* _PTHREAD_RWLOCK_SIG_init */

_Static_assert(sizeof(((struct darwin_opaque *)0)->opaque) >= 56,
               "glibc's pthread_rwlock_t is 56 bytes and must fit in Darwin's opaque area");

/* Same double-checked adoption as adopt(), with pthread_rwlock_init in place
 * of pthread_mutex_init. Not a parameter to adopt() because the initialiser is
 * the only difference and a function pointer there would be harder to read
 * than fifteen lines. */
static void *rwlock_g(struct darwin_opaque *o)
{
    if (__atomic_load_n(&o->sig, __ATOMIC_ACQUIRE) != MR_ADOPTED_SIG) {
        glibc_pthread_mutex_lock(adopt_lock());
        if (o->sig != MR_ADOPTED_SIG) {
            if (o->sig != DARWIN_RWLOCK_SIG && o->sig != 0)
                mr_bail("a pthread_rwlock_t has an unexpected Darwin signature; its "
                        "layout was compiled into the guest and cannot be renegotiated");
            glibc_memset(o->opaque, 0, sizeof(o->opaque));
            glibc_pthread_rwlock_init(o->opaque, NULL);
            __atomic_store_n(&o->sig, MR_ADOPTED_SIG, __ATOMIC_RELEASE);
        }
        glibc_pthread_mutex_unlock(adopt_lock());
    }
    return o->opaque;
}

EXPORT int pthread_rwlock_init(void *rw, const void *attr)
{
    struct darwin_opaque *o = rw;
    if (attr) mr_bail("pthread_rwlock_init with a non-NULL attribute is not implemented "
                      "(Darwin's pthread_rwlockattr_t layout is not glibc's, and the "
                      "only attribute either platform has is process-shared, which "
                      "machorun has no second process to share with)");
    if (__atomic_load_n(&o->sig, __ATOMIC_ACQUIRE) == MR_ADOPTED_SIG)
        glibc_pthread_rwlock_destroy(o->opaque);
    glibc_memset(o->opaque, 0, sizeof(o->opaque));
    glibc_pthread_rwlock_init(o->opaque, NULL);
    o->sig = MR_ADOPTED_SIG;
    return 0;
}

EXPORT int pthread_rwlock_destroy(void *rw)
{
    struct darwin_opaque *o = rw;
    if (o->sig != MR_ADOPTED_SIG) return 0;
    o->sig = 0;
    return mr_pthread_rc(glibc_pthread_rwlock_destroy(o->opaque));
}

EXPORT int pthread_rwlock_rdlock(void *rw)    { return mr_pthread_rc(glibc_pthread_rwlock_rdlock(rwlock_g(rw))); }
EXPORT int pthread_rwlock_tryrdlock(void *rw) { return mr_pthread_rc(glibc_pthread_rwlock_tryrdlock(rwlock_g(rw))); }
EXPORT int pthread_rwlock_wrlock(void *rw)    { return mr_pthread_rc(glibc_pthread_rwlock_wrlock(rwlock_g(rw))); }
EXPORT int pthread_rwlock_trywrlock(void *rw) { return mr_pthread_rc(glibc_pthread_rwlock_trywrlock(rwlock_g(rw))); }
EXPORT int pthread_rwlock_unlock(void *rw)    { return mr_pthread_rc(glibc_pthread_rwlock_unlock(rwlock_g(rw))); }

EXPORT int pthread_once(void *once, void (*fn)(void))
{
    struct darwin_opaque *o = once;
    return mr_pthread_rc(glibc_pthread_once(adopt(o, DARWIN_ONCE_SIG, 1), fn));
}

/* The isa-mask heap constraint (src/map.c) is checked on the main thread,
 * before any guest thread exists -- and that is exactly the case it cannot
 * see. glibc creates a secondary arena LAZILY, in the thread that first needs
 * one, and a secondary arena is mmap'd, which on this kernel means
 * 0xffff_xxxx_xxxx. mr_constrain_heap() sets M_ARENA_MAX=1 so that never
 * happens; this checks the result once, on the first guest thread, instead of
 * trusting it. Measured: without M_ARENA_MAX, 3216 of 3216 allocations across
 * 16 threads landed above 2^47, so the failure this guards is total, not
 * marginal. One relaxed test-and-set on thread creation is not a hot path. */
#define MR_GUEST_ISA_LIMIT 0x800000000000ull

struct mr_thread_start { void *(*fn)(void *); void *arg; };

static int mr_heap_probed;

static void *mr_thread_trampoline(void *p)
{
    struct mr_thread_start s = *(struct mr_thread_start *)p;
    glibc_free(p);

    if (!__atomic_test_and_set(&mr_heap_probed, __ATOMIC_RELAXED)) {
        void *probe = glibc_malloc(64);
        if ((unsigned long long)(uintptr_t)probe >= MR_GUEST_ISA_LIMIT)
            mr_bail("a guest thread's malloc answered at or above 2^47, so glibc gave "
                    "this thread its own arena despite M_ARENA_MAX=1. libswiftCore masks "
                    "an isa with 0x7ffffffffff8, so a class allocated here would decode "
                    "to an unmapped address. See mr_constrain_heap() in src/map.c.");
        glibc_free(probe);
    }

    /* Prime this thread's direct-TSD array BEFORE the guest runs.
     *
     * os_unfair_lock_lock -> unfair_token -> mr_thread_token -> dtsd_slots,
     * and dtsd_slots CALLOCS on a thread's first call. So without this, taking
     * a lock for the first time on a thread allocates -- and Darwin's
     * os_unfair_lock_lock never allocates, which callers are entitled to rely
     * on: it is usable from inside an allocator.
     *
     * The concrete hazard is glibc's arena mutex, which is NOT recursive. A
     * thread already inside glibc malloc that first-touches a lock would
     * deadlock against a mutex it already holds. mr_thread_token()'s own
     * comment argues it "must not take a lock itself" and that the TSD path
     * "is glibc's, which is independent of ours" -- but independent-of-ours is
     * not none, and calloc takes glibc's.
     *
     * Doing it here costs one allocation per thread at a point where the guest
     * is not yet running and no lock is held, and makes mr_thread_token() a
     * pure TSD read on every path a lock can reach. */
    (void)mr_thread_token();

    return s.fn(s.arg);
}

/* Prime the MAIN thread's direct-TSD array, closing the residue the trampoline
 * cannot reach (the main thread has no trampoline).
 *
 * This has to live in the dylib rather than in the loader: mr_constrain_heap()
 * in src/main.c would be the natural site by ordering, but it runs BEFORE
 * find_darwin_root(), so libSystem is not even located yet -- the loader cannot
 * call into a Mach-O image it has not mapped. An image initializer can, and
 * src/init.c runs both __init_offsets and __mod_init_func forms.
 *
 * Runs on the main thread while the process is still single-threaded, so it
 * cannot contend, and it is idempotent: if something already primed this
 * thread, mr_thread_token() returns the cached token and allocates nothing. */
__attribute__((constructor))
static void mr_prime_main_thread_tsd(void) { (void)mr_thread_token(); }

EXPORT int pthread_create(void **thread, const void *attr, void *(*fn)(void *), void *arg)
{
    g_pthread_t t;
    struct mr_thread_start *s;
    int rc;
    /* A non-NULL attr USED to abort here, on the grounds that Darwin's attr
     * layout differs from glibc's. The SIZE does not -- pthread_attr_t is 64
     * bytes on both, pinned in glibc_abi_probe.c -- but the CONTENTS did,
     * because nothing filled the guest's object with glibc's data.
     *
     * That changed when the pthread_attr_* family landed in darwin/src/posix.c.
     * init, destroy, setdetachstate, setstacksize and the sched entries all
     * call glibc's, so the guest's 64 bytes hold GLIBC's attr from the moment
     * it is initialised, and handing it straight to glibc_pthread_create is
     * correct rather than merely convenient.
     *
     * WHY THAT ARGUMENT IS SAFE HERE AND NOT FOR pthread_cond_t, which is the
     * comparison that matters: POSIX gives cond a STATIC INITIALIZER
     * (PTHREAD_COND_INITIALIZER), so a guest can produce one that never passed
     * through our init and still holds Darwin's bytes -- which is exactly why
     * that type keeps a handle indirection. pthread_attr_t has NO static
     * initializer on either system; pthread_attr_init is mandatory. So every
     * attr that legitimately reaches this call has been through ours.
     *
     * A guest that zeroes an attr and passes it without init is undefined
     * behaviour under POSIX, and equally undefined on Darwin. */
    s = glibc_malloc(sizeof *s);
    if (!s) return 12 /* Darwin ENOMEM */;
    s->fn = fn;
    s->arg = arg;
    rc = mr_pthread_rc(glibc_pthread_create(&t, attr, mr_thread_trampoline, s));
    if (rc == 0) *thread = (void *)t;
    else glibc_free(s);
    return rc;
}

EXPORT int   pthread_join(void *t, void **ret) { return mr_pthread_rc(glibc_pthread_join((g_pthread_t)t, ret)); }
EXPORT int   pthread_detach(void *t)           { return mr_pthread_rc(glibc_pthread_detach((g_pthread_t)t)); }
EXPORT void *pthread_self(void)                { return (void *)glibc_pthread_self(); }

/* pthread_threadid_np -- the 64-bit thread id CFLog stamps every line with.
 *
 * MEASURED ON DARWIN, and the measurement changed the design: it succeeds for
 * ANY thread, not only the caller.
 *
 *      pthread_threadid_np(NULL, &id)           -> 0, id non-zero
 *      pthread_threadid_np(pthread_self(), &id) -> 0, the SAME id
 *      pthread_threadid_np(other, &id)          -> 0, and it is THAT thread's
 *      pthread_threadid_np(NULL, NULL)          -> 22 (EINVAL)
 *
 * Self is exact here: Linux's gettid() is the same kind of number -- a
 * kernel-visible, process-unique thread id.
 *
 * ANOTHER THREAD IS NOT SERVED, AND IT STOPS RATHER THAN RETURNING ESRCH.
 * glibc has no way to map a pthread_t to its tid from outside that thread, so
 * answering would need a registry keyed on pthread_t, filled by this library's
 * own pthread_create and torn down at thread exit. That is buildable -- every
 * guest thread goes through our wrapper -- and it is not built.
 *
 * ESRCH was the tempting answer and is the wrong one: it says "no such
 * thread", which is FALSE (the thread exists and Darwin would have answered),
 * and a caller keying a cache or a log line by thread id would take a
 * legitimate-looking failure branch over a lie. A stop names the gap and
 * cannot be mistaken for the truth. Nothing reaches it today: CFLog asks for
 * the thread it is running on. */
EXPORT int pthread_threadid_np(void *thread, uint64_t *idp)
{
    if (!idp) return 22;                       /* EINVAL, measured on Darwin */
    if (thread != (void *)0 && thread != (void *)glibc_pthread_self())
        mr_bail("pthread_threadid_np for a thread other than the caller: glibc "
                "cannot map a pthread_t to its tid from outside that thread, so "
                "this needs a registry filled by our own pthread_create. Darwin "
                "answers this call, so returning ESRCH would report 'no such "
                "thread' about a thread that exists");
    *idp = (uint64_t)(unsigned int)glibc_gettid();
    return 0;
}
EXPORT int   pthread_equal(void *a, void *b)   { return glibc_pthread_equal((g_pthread_t)a, (g_pthread_t)b); }

/* pthread_key_create/delete/getspecific/setspecific are NOT here any more. A
 * Darwin pthread_key_t is an INDEX into the same per-thread slot array that
 * _pthread_getspecific_direct addresses, so the public API and the
 * reserved-slot SPI have to be one implementation or they disagree about what
 * key 40 (libobjc) or key 100 (the Swift runtime) means. objcsupport.c owns
 * that array and therefore owns these four; its TSD section header carries the
 * measurements taken on the oracle. */

/* os_unfair_lock is exactly four bytes in the guest -- Darwin stores an owning
 * thread port in them -- so it cannot hold a glibc pthread_mutex_t and cannot
 * be widened. We use the same four bytes as the lock word: 0 is unlocked, and
 * a locked lock holds the owner's thread token. Contention yields rather than
 * futex-waits; that is a fairness and CPU-burn difference under heavy
 * contention, not a correctness one, and it is recorded in
 * docs/UNIMPLEMENTED.md.
 *
 * The token comes from mr_thread_token() (objcsupport.c) and is a per-thread
 * sequential id, NOT a squeeze of pthread_self(). Deriving it from the TCB
 * pointer is what made this lock corrupt itself on Graviton3; the reasoning is
 * at mr_thread_token() and the evidence in
 * docs/UNIMPLEMENTED.md#os-unfair-lock-owner. Do not "simplify" it back. */
static unsigned unfair_token(void) { return mr_thread_token(); }

static char *hex32(char *p, unsigned v)
{
    static const char d[] = "0123456789abcdef";
    *p++ = '0'; *p++ = 'x';
    for (int i = 28; i >= 0; i -= 4) *p++ = d[(v >> i) & 15];
    return p;
}

static char *hex64(char *p, unsigned long long v)
{
    static const char d[] = "0123456789abcdef";
    int i = 60;
    *p++ = '0'; *p++ = 'x';
    while (i > 0 && !((v >> i) & 15)) i -= 4;
    for (; i >= 0; i -= 4) *p++ = d[(v >> i) & 15];
    return p;
}

/* A ring of the last few lock operations, gated on MACHORUN_LOCK_TRACE.
 *
 * The question a failed unlock raises is not answerable from the failure site:
 * "this thread does not own the lock" is consistent with the caller never
 * having taken it, with something else having released it, and with the four
 * bytes never having been a lock at all. Those want different investigations
 * and the history separates them in one read. Off by default -- two stores per
 * lock operation is not free on a path objc4 takes millions of times. */
#define LOCKLOG_N 48
struct locklog_entry { void *addr; unsigned word; unsigned char op; };
static struct locklog_entry locklog[LOCKLOG_N];
static unsigned locklog_n;
static signed char locklog_on = -1;

static int lock_trace(void)
{
    if (locklog_on < 0) {
        const char *e = glibc_getenv("MACHORUN_LOCK_TRACE");
        locklog_on = (e && e[0] && e[0] != '0') ? 1 : 0;
    }
    return locklog_on;
}

static void locklog_put(void *l, unsigned word, char op)
{
    unsigned i = locklog_n++ % LOCKLOG_N;
    locklog[i].addr = l; locklog[i].word = word; locklog[i].op = (unsigned char)op;
}


/* L took it, T trylock succeeded, f trylock failed, U released it, x tried to
 * release one it did not hold. `word` is what the four bytes held BEFORE the
 * operation, so a lock whose history is L then x with different words was
 * overwritten between the two, and one that only ever shows x was never ours. */
/* A write watchpoint for the four bytes of a held lock, gated on
 * MACHORUN_LOCK_GUARD.
 *
 * "The lock word changed while we held it" is where a lock investigation stops
 * being answerable from the lock code, because the next question is WHO WROTE
 * IT and nothing at the failure site knows. The loader owns the mechanism
 * (src/crash.c) since only it has the fault handler and the image table; this
 * side just says which word to watch and when. Heap locks only -- a lock in an
 * image's __DATA shares its page with the rest of __DATA. */
static int lock_guard(void)
{
    static signed char on = -1;
    if (on < 0) {
        const char *e = glibc_getenv("MACHORUN_LOCK_GUARD");
        on = (e && e[0] && e[0] != '0') ? 1 : 0;
    }
    return on;
}

static void locklog_dump(void *culprit)
{
    unsigned start = locklog_n > LOCKLOG_N ? locklog_n - LOCKLOG_N : 0;
    mr_say("  lock history (most recent last; * marks the failing address):\n");
    for (unsigned k = start; k < locklog_n; k++) {
        struct locklog_entry *e = &locklog[k % LOCKLOG_N];
        char buf[80], *p = buf;
        *p++ = ' '; *p++ = ' '; *p++ = ' '; *p++ = ' ';
        *p++ = (e->addr == culprit) ? '*' : ' ';
        *p++ = ' '; *p++ = (char)e->op; *p++ = ' ';
        p = hex64(p, (unsigned long long)(uintptr_t)e->addr);
        *p++ = ' '; *p++ = 'w'; *p++ = 'a'; *p++ = 's'; *p++ = ' ';
        p = hex64(p, e->word);
        *p++ = '\n'; *p = 0;
        mr_say(buf);
    }
}

EXPORT void os_unfair_lock_lock(void *l)
{
    unsigned *w = l, me = unfair_token(), expect = 0;
    if (lock_trace()) locklog_put(l, __atomic_load_n(w, __ATOMIC_RELAXED), 'L');
    while (!__atomic_compare_exchange_n(w, &expect, me, 1, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED)) {
        if (expect == me)
            mr_bail("os_unfair_lock_lock: recursive acquisition by the owning thread "
                    "(Darwin traps this too, deliberately)");
        expect = 0;
        glibc_sched_yield();
    }
    if (lock_guard()) mr_guard_arm(w);
}

EXPORT int os_unfair_lock_trylock(void *l)
{
    unsigned *w = l, me = unfair_token(), expect = 0;
    int got = __atomic_compare_exchange_n(w, &expect, me, 0, __ATOMIC_ACQUIRE, __ATOMIC_RELAXED);
    if (lock_trace()) locklog_put(l, expect, got ? 'T' : 'f');
    return got;
}

/* "this thread does not own the lock" is true and useless on its own: it does
 * not say whether the lock word was ZERO (a genuine unbalanced unlock -- the
 * caller never took it, or took it and something released it), or held ANOTHER
 * LIVE TOKEN (two threads, or one thread whose token changed underneath it,
 * which would be our TSD breaking rather than the guest misbehaving). Those
 * want opposite investigations, and the three numbers separate them. */
EXPORT void os_unfair_lock_unlock(void *l)
{
    unsigned *w = l, me = unfair_token();
    unsigned owner;
    if (lock_guard()) mr_guard_disarm(w);
    owner = __atomic_load_n(w, __ATOMIC_RELAXED);
    if (lock_trace()) locklog_put(l, owner, owner == me ? 'U' : 'x');
    if (owner != me) {
        if (lock_trace()) locklog_dump(l);
        char buf[96], *p = buf;
        p = hex32(p, (unsigned)(uintptr_t)l >> 0);
        *p++ = ' '; *p++ = 'h'; *p++ = 'o'; *p++ = 'l'; *p++ = 'd'; *p++ = 's'; *p++ = ' ';
        p = hex32(p, owner);
        *p++ = ','; *p++ = ' '; *p++ = 'w'; *p++ = 'e'; *p++ = ' '; *p++ = 'a';
        *p++ = 'r'; *p++ = 'e'; *p++ = ' ';
        p = hex32(p, me);
        *p = 0;
        mr_report_memory(l, 64, 64);
        mr_bail2("os_unfair_lock_unlock: this thread does not own the lock; lock at", buf);
    }
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
