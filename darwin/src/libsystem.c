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

EXPORT void __machorun_libsystem_bootstrap(int argc, char **argv, char **envp, char **apple)
{
    mr_argc = argc; mr_argv = argv; mr_envp = envp; mr_apple = apple;
    environ = envp;
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
FWD(int, ungetc,  (int c, void *f), (c, f))
FWDV(rewind, (void *f), (f))
EXPORT int putc(int c, void *f) { return glibc_fputc(c, f); }
EXPORT int getc(void *f) { return glibc_fgetc(f); }
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
 * Found by tests/bin/21_pthread_cond's NEGATIVE CONTROL: a timedwait nobody
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
#define DARWIN_MUTEX_SIG 0x32AAABA7L
#define DARWIN_ONCE_SIG  0x30B1BCBAL
#define MR_ADOPTED_SIG   0x6D724F4BL   /* 'mrOK' */

struct darwin_opaque { long sig; unsigned char opaque[56]; };

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
 * bug in it. MEASURED before this fix: tests/bin/08_pthread aborted 10 times
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
            if (o->sig != expect_sig && o->sig != 0)
                mr_bail("a pthread object has an unexpected Darwin signature; its layout "
                     "was compiled into the guest and cannot be renegotiated");
            glibc_memset(o->opaque, 0, sizeof(o->opaque));
            if (!is_once) glibc_pthread_mutex_init(o->opaque, NULL);
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
    if (attr) mr_bail("pthread_create with a non-NULL pthread_attr_t is not implemented "
                   "(Darwin's attr struct layout differs from glibc's)");
    s = glibc_malloc(sizeof *s);
    if (!s) return 12 /* Darwin ENOMEM */;
    s->fn = fn;
    s->arg = arg;
    rc = mr_pthread_rc(glibc_pthread_create(&t, NULL, mr_thread_trampoline, s));
    if (rc == 0) *thread = (void *)t;
    else glibc_free(s);
    return rc;
}

EXPORT int   pthread_join(void *t, void **ret) { return mr_pthread_rc(glibc_pthread_join((g_pthread_t)t, ret)); }
EXPORT int   pthread_detach(void *t)           { return mr_pthread_rc(glibc_pthread_detach((g_pthread_t)t)); }
EXPORT void *pthread_self(void)                { return (void *)glibc_pthread_self(); }
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
