/* ctype.c -- the C locale, getopt, and time formatting.
 *
 * THIS FILE EXISTS BECAUSE OF WHAT `nm -u` SAYS. A representative hand-built
 * macOS utility -- getopt, qsort, strftime, isalpha, fgets -- imports 17
 * symbols, and before this file seven of them were missing. Two of those seven
 * are the interesting ones:
 *
 *     ___maskrune   __DefaultRuneLocale
 *
 * Darwin's <ctype.h> does not call isdigit(). It inlines
 *
 *     ((c < 0 || c >= 256) ? __maskrune(c, f)
 *                          : (_DefaultRuneLocale.__runetype[c] & (f)))
 *
 * into the guest. So `_DefaultRuneLocale` is a 3208-byte DATA symbol whose
 * layout and contents were compiled into the guest's own instructions -- it is
 * not a function we can implement however we like, it is a table we have to
 * reproduce. darwin/src/rune_table.h holds Apple's actual bytes, recorded from
 * macOS by scripts/gen_rune_table.sh; the flag values (0x00000100 for _CTYPE_A
 * and so on) never appear here because we never interpret the table, we only
 * hand the guest the same numbers Apple would have.
 *
 * getopt is written out rather than forwarded: glibc's permutes argv by default
 * and Darwin's does not, so forwarding would change which arguments a program
 * sees. Its optarg/optind are also globals, and the guest reads OURS.
 */
#include "dsys.h"
#include "rune_table.h"

/* ------------------------------------------------------- the rune locale */

/* Measured layout (scripts/gen_rune_table.sh prints it): 3208 bytes, with
 * __runetype at 60, __maplower at 1084 and __mapupper at 2108. The three
 * _RuneRange tails and the two function pointers are all NULL in the C locale,
 * which is what makes this reproducible as static data. */
typedef int32_t rune_t;

struct rune_range { uint32_t nranges; void *ranges; };

struct rune_locale {
    char      magic[8];                       /*    0  "RuneMagA" */
    char      encoding[32];                   /*    8  "NONE"     */
    void     *sgetrune;                       /*   40  NULL       */
    void     *sputrune;                       /*   48  NULL       */
    rune_t    invalid_rune;                   /*   56             */
    uint32_t  runetype[MR_CACHED_RUNES];      /*   60             */
    rune_t    maplower[MR_CACHED_RUNES];      /* 1084             */
    rune_t    mapupper[MR_CACHED_RUNES];      /* 2108             */
    struct rune_range runetype_ext;           /* 3136             */
    struct rune_range maplower_ext;           /* 3152             */
    struct rune_range mapupper_ext;           /* 3168             */
    void     *variable;                       /* 3184  encoding-dependent */
    int32_t   variable_len;                   /* 3192             */
    /* "extra fields to deal with arbitrary character classes" -- present in
     * the SDK's _RuneLocale and part of the 3208 bytes, even though the C
     * locale leaves them empty. Measured, because a struct that is eight bytes
     * short is a struct whose consumers read past it. */
    int32_t   ncharclasses;                   /* 3196             */
    void     *charclasses;                    /* 3200             */
};                                            /* 3208             */

_Static_assert(sizeof(struct rune_locale) == 3208, "_RuneLocale is 3208 bytes on Darwin/arm64");
_Static_assert(__builtin_offsetof(struct rune_locale, runetype) == 60, "__runetype at 60");
_Static_assert(__builtin_offsetof(struct rune_locale, maplower) == 1084, "__maplower at 1084");
_Static_assert(__builtin_offsetof(struct rune_locale, mapupper) == 2108, "__mapupper at 2108");
_Static_assert(__builtin_offsetof(struct rune_locale, runetype_ext) == 3136, "__runetype_ext at 3136");
_Static_assert(__builtin_offsetof(struct rune_locale, variable) == 3184, "__variable at 3184");

/* STATICALLY initialised, deliberately: a constructor would put this table
 * behind an initialiser-ordering question, and the guest's own constructors are
 * entitled to call isdigit(). */
EXPORT struct rune_locale _DefaultRuneLocale = {
    { 'R', 'u', 'n', 'e', 'M', 'a', 'g', 'A' },
    "NONE",
    NULL, NULL,
    MR_INVALID_RUNE,
    { MR_RUNETYPE_INIT },
    { MR_MAPLOWER_INIT },
    { MR_MAPUPPER_INIT },
    { 0, NULL }, { 0, NULL }, { 0, NULL },
    NULL, 0,
    0, NULL,
};

EXPORT struct rune_locale *_CurrentRuneLocale = &_DefaultRuneLocale;

/* Called by the inlined macros only for c < 0 or c >= 256. The C locale has no
 * extension ranges, so everything outside the cached window classifies as
 * nothing at all -- which is the same answer Apple's gives. */
EXPORT unsigned long __maskrune(int c, unsigned long f)
{
    if (c >= 0 && c < MR_CACHED_RUNES) return _DefaultRuneLocale.runetype[c] & f;
    return 0;
}

EXPORT int __istype(int c, unsigned long f) { return __maskrune(c, f) != 0; }

EXPORT int __toupper(int c)
{
    return (c >= 0 && c < MR_CACHED_RUNES) ? _DefaultRuneLocale.mapupper[c] : c;
}

EXPORT int __tolower(int c)
{
    return (c >= 0 && c < MR_CACHED_RUNES) ? _DefaultRuneLocale.maplower[c] : c;
}

EXPORT int toupper(int c) { return __toupper(c); }
EXPORT int tolower(int c) { return __tolower(c); }

/* Out-of-line forms, for guests built where the macros are not used. The flag
 * values come from Apple's headers via the generator, not from reading the
 * table and guessing which bit is which. */
#define CTYPE_FN(name, flag) EXPORT int name(int c) { return (int)__maskrune(c, (unsigned long)(flag)); }
CTYPE_FN(isalpha,  MR_CTYPE_A)
CTYPE_FN(iscntrl,  MR_CTYPE_C)
CTYPE_FN(isdigit,  MR_CTYPE_D)
CTYPE_FN(isgraph,  MR_CTYPE_G)
CTYPE_FN(islower,  MR_CTYPE_L)
CTYPE_FN(ispunct,  MR_CTYPE_P)
CTYPE_FN(isspace,  MR_CTYPE_S)
CTYPE_FN(isupper,  MR_CTYPE_U)
CTYPE_FN(isxdigit, MR_CTYPE_X)
CTYPE_FN(isblank,  MR_CTYPE_B)
CTYPE_FN(isprint,  MR_CTYPE_R)
CTYPE_FN(isalnum,  MR_CTYPE_A | MR_CTYPE_D)
CTYPE_FN(isideogram,   MR_CTYPE_I)
CTYPE_FN(isspecial,    MR_CTYPE_T)
CTYPE_FN(isphonogram,  MR_CTYPE_Q)
CTYPE_FN(isrune,       0xFFFFFFF0UL)
CTYPE_FN(ishexnumber,  MR_CTYPE_X)
CTYPE_FN(isnumber,     MR_CTYPE_D)
EXPORT int isascii(int c) { return (unsigned)c <= 0177; }
EXPORT int toascii(int c) { return c & 0177; }

EXPORT int __mb_cur_max = MR_MB_CUR_MAX;

/* ------------------------------------------------------------- setlocale */

/* We have exactly one locale, and it is the one every fixture and every
 * correct program starts in. Asking for another gets NULL -- a documented
 * POSIX failure -- rather than a silent pretence that the locale changed. */
static char c_locale[] = "C";

EXPORT char *setlocale(int category, const char *name)
{
    (void)category;
    if (!name || !*name) return c_locale;                 /* query */
    if (glibc_strcmp(name, "C") == 0 || glibc_strcmp(name, "POSIX") == 0)
        return c_locale;
    /* "" means "take it from the environment"; under machorun the environment
     * cannot deliver anything but C, so say so instead of lying. */
    return NULL;
}

/* --------------------------------------------------------------- getopt */

/* BSD getopt: it does NOT permute argv. glibc's does, by default, which would
 * change which arguments a Darwin program sees -- so this is written out
 * rather than forwarded. optarg/optind/opterr/optopt are the guest's view of
 * our state, so they must be OUR globals. */
EXPORT char *optarg;
EXPORT int optind = 1;
EXPORT int opterr = 1;
EXPORT int optopt;
EXPORT int optreset;

static int getopt_place;   /* index into the current cluster, e.g. -abc */

EXPORT int getopt(int argc, char *const argv[], const char *optstring)
{
    const char *oli;
    char c;

    if (optreset) { optreset = 0; getopt_place = 0; }

    if (getopt_place == 0) {
        if (optind >= argc || argv[optind] == NULL) return -1;
        if (argv[optind][0] != '-' || argv[optind][1] == 0) return -1;
        if (argv[optind][1] == '-' && argv[optind][2] == 0) { optind++; return -1; }
        getopt_place = 1;
    }

    c = argv[optind][getopt_place++];
    if (argv[optind][getopt_place] == 0) { optind++; getopt_place = 0; }

    oli = glibc_strchr(optstring, c);
    if (c == ':' || !oli) {
        optopt = c;
        if (opterr && *optstring != ':') {
            mr_say(argv[0] ? argv[0] : "?");
            mr_say(": illegal option -- ");
            { char b[2] = { c, '\n' }; glibc_write(2, b, 2); }
        }
        return '?';
    }

    if (oli[1] != ':') { optarg = NULL; return c; }

    if (getopt_place) {                       /* -oVALUE */
        optarg = (char *)&argv[optind][getopt_place];
        optind++;
        getopt_place = 0;
    } else if (optind >= argc) {              /* missing argument */
        optopt = c;
        if (*optstring == ':') return ':';
        if (opterr) {
            mr_say(argv[0] ? argv[0] : "?");
            mr_say(": option requires an argument -- ");
            { char b[2] = { c, '\n' }; glibc_write(2, b, 2); }
        }
        return '?';
    } else {                                  /* -o VALUE */
        optarg = argv[optind++];
    }
    return c;
}

/* ------------------------------------------------------------------ time */

/* struct tm is byte-identical on the two systems -- 56 bytes, same field
 * offsets including tm_gmtoff at 40 and tm_zone at 48 (measured, docs/ABI.md).
 * So these are forwards, not translations. */
extern void *glibc_gmtime_r(const time_t *, void *)      GLIBCSYM(gmtime_r);
extern void *glibc_localtime_r(const time_t *, void *)   GLIBCSYM(localtime_r);
extern void *glibc_gmtime(const time_t *)                GLIBCSYM(gmtime);
extern void *glibc_localtime(const time_t *)             GLIBCSYM(localtime);
extern time_t glibc_mktime(void *)                       GLIBCSYM(mktime);
extern time_t glibc_timegm(void *)                       GLIBCSYM(timegm);
extern size_t glibc_strftime(char *, size_t, const char *, const void *) GLIBCSYM(strftime);
extern char  *glibc_ctime_r(const time_t *, char *)      GLIBCSYM(ctime_r);
extern char  *glibc_asctime_r(const void *, char *)      GLIBCSYM(asctime_r);
extern char  *glibc_fgets(char *, int, void *)           GLIBCSYM(fgets);
extern void   glibc_tzset(void)                          GLIBCSYM(tzset);

EXPORT void   *gmtime_r(const time_t *t, void *tm)    { return glibc_gmtime_r(t, tm); }
EXPORT void   *localtime_r(const time_t *t, void *tm) { return glibc_localtime_r(t, tm); }
EXPORT void   *gmtime(const time_t *t)                { return glibc_gmtime(t); }
EXPORT void   *localtime(const time_t *t)             { return glibc_localtime(t); }
EXPORT time_t  mktime(void *tm)                       { return glibc_mktime(tm); }
EXPORT time_t  timegm(void *tm)                       { return glibc_timegm(tm); }
EXPORT char   *ctime_r(const time_t *t, char *b)      { return glibc_ctime_r(t, b); }
EXPORT char   *asctime_r(const void *tm, char *b)     { return glibc_asctime_r(tm, b); }
/* timezone / daylight / tzname are DATA on Darwin, and our <time.h> declares
 * all three -- so until now they were declared here and defined nowhere, which
 * links fine and dies at load. They cannot be aliases of glibc's, because a
 * Mach-O guest binds to OUR definitions; they have to be copies, refreshed
 * whenever glibc might have changed them. tzset() is that moment, and Darwin
 * documents it as the call that establishes them. The bootstrap calls it once
 * so a guest that reads tzname without calling tzset first -- which works on
 * Darwin, because its time functions populate them -- sees real values. */
EXPORT long   timezone;
EXPORT int    daylight;
EXPORT char  *tzname[2];

EXPORT void    tzset(void)
{
    glibc_tzset();
    timezone = glibc_tz_timezone;
    daylight = glibc_tz_daylight;
    tzname[0] = glibc_tz_tzname[0];
    tzname[1] = glibc_tz_tzname[1];
}
EXPORT double  difftime(time_t a, time_t b)           { return (double)(a - b); }

/* strftime's format language is not variadic, and the C locale's conversions
 * are POSIX-defined, so the bytes come from glibc. The %+ and %N Darwin
 * extensions are not implemented; nothing in the corpus uses them. */
EXPORT size_t strftime(char *buf, size_t cap, const char *fmt, const void *tm)
{
    return glibc_strftime(buf, cap, fmt, tm);
}

EXPORT char *fgets(char *b, int n, void *f) { return MR_ERRNO_CALL(glibc_fgets(b, n, f)); }
