/* 14_utility -- a representative hand-built macOS utility.
 *
 * Rungs (a)-(l) each isolate one mechanism. This one does not isolate
 * anything: it is the shape of program milestone 1 is actually for, and it
 * exists to answer "what would the NEXT binary need" with a measurement rather
 * than an opinion. It was written first, and the seven symbols it turned out
 * to be missing became darwin/src/ctype.c.
 *
 * The interesting import is not a function at all:
 *
 *     __DefaultRuneLocale     ___maskrune
 *
 * Darwin's <ctype.h> does not call isdigit(); it INLINES
 * `_DefaultRuneLocale.__runetype[c] & _CTYPE_D` into the guest. So a 3208-byte
 * data table -- its layout AND its contents -- is part of the ABI, and every
 * program that includes <ctype.h> carries the lookup in its own instructions.
 * Getting one bit of that table wrong misclassifies one character, which is
 * exactly the sort of thing a fixture that prints all 128 of them catches.
 *
 * getopt is the other one worth naming: Darwin's does not permute argv and
 * glibc's does, so forwarding it would change which arguments a program sees.
 * The fixture drives it over a synthetic argv so the harness needs no
 * command-line support.
 */
#include <ctype.h>
#include <errno.h>
#include <getopt.h>
#include <locale.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

static int by_name(const void *a, const void *b)
{
    return strcmp(*(const char *const *)a, *(const char *const *)b);
}

int main(void)
{
    /* ---- ctype, the whole cached window ---- */
    {
        /* One line per class, 128 characters wide. A table this shape makes a
         * single wrong bit visible as a single wrong column. */
        static const struct { const char *name; int (*fn)(int); } classes[] = {
            { "alpha", isalpha }, { "digit", isdigit }, { "alnum", isalnum },
            { "space", isspace }, { "punct", ispunct }, { "upper", isupper },
            { "lower", islower }, { "print", isprint }, { "graph", isgraph },
            { "cntrl", iscntrl }, { "xdigt", isxdigit }, { "blank", isblank },
        };
        for (unsigned k = 0; k < sizeof classes / sizeof classes[0]; k++) {
            printf("%s ", classes[k].name);
            for (int c = 0; c < 128; c++) putchar(classes[k].fn(c) ? '1' : '0');
            putchar('\n');
        }
        /* Outside the cached window and below it -- the __maskrune path. */
        printf("edges %d%d%d%d\n", isalpha(-1), isalpha(EOF), isdigit(300), isspace(-42));
        /* Case mapping, including the characters that map to themselves. */
        printf("upper=");
        for (int c = 'a' - 2; c <= 'z' + 2; c++) putchar(toupper(c));
        printf("\nlower=");
        for (int c = 'A' - 2; c <= 'Z' + 2; c++) putchar(tolower(c));
        printf("\nmb_cur_max=%d\n", (int)MB_CUR_MAX);
    }

    /* ---- setlocale ---- */
    printf("locale C=[%s] query=[%s] utf8=%s\n",
           setlocale(LC_ALL, "C"), setlocale(LC_ALL, NULL),
           setlocale(LC_ALL, "xx_YY.NOSUCH") ? "accepted" : "refused");

    /* ---- getopt over a synthetic argv ---- */
    {
        char *av[] = { "util", "-v", "-n", "42", "-xyz", "-mVALUE", "--", "-v", "tail", NULL };
        int ac = 9, c, seen = 0;
        opterr = 0;                       /* we print the errors ourselves */
        while ((c = getopt(ac, av, "vn:m:x")) != -1) {
            seen++;
            switch (c) {
            case 'n': case 'm': printf("opt %c arg=%s\n", c, optarg); break;
            case '?': printf("opt ? optopt=%c\n", optopt); break;
            default:  printf("opt %c\n", c); break;
            }
        }
        printf("getopt saw %d, optind=%d, rest=", seen, optind);
        for (int i = optind; i < ac; i++) printf("%s%s", av[i], i + 1 < ac ? "," : "\n");
    }

    /* ---- qsort with a guest callback, called from libSystem ---- */
    {
        const char *w[] = { "pear", "apple", "fig", "banana", "date" };
        qsort(w, 5, sizeof w[0], by_name);
        for (int i = 0; i < 5; i++) printf("%s%s", w[i], i < 4 ? " " : "\n");
    }

    /* ---- time: struct tm is byte-identical on both systems, so this is a
     * forward; strftime's C-locale conversions are POSIX-defined ---- */
    {
        time_t t = 1234567890;            /* 2009-02-13T23:31:30Z */
        struct tm tm;
        char buf[64];
        gmtime_r(&t, &tm);
        strftime(buf, sizeof buf, "%Y-%m-%dT%H:%M:%SZ", &tm);
        printf("gm=[%s] wday=%d yday=%d isdst=%d\n", buf, tm.tm_wday, tm.tm_yday, tm.tm_isdst);
        strftime(buf, sizeof buf, "%a %b %e %j %H%M %p", &tm);
        printf("fmt=[%s]\n", buf);
        printf("roundtrip=%s\n", timegm(&tm) == t ? "yes" : "no");
        printf("difftime=%.0f\n", difftime(t + 3600, t));
    }

    /* ---- fgets over a file we wrote, and the strtol idiom ---- */
    {
        const char *path = "/tmp/machorun-14-utility.txt";
        FILE *f = fopen(path, "w");
        char line[64];
        if (!f) { perror("fopen"); return 1; }
        fputs("alpha 17\nbeta 4294967296\ngamma notanumber\n", f);
        fclose(f);

        f = fopen(path, "r");
        if (!f) { perror("reopen"); return 1; }
        while (fgets(line, sizeof line, f)) {
            char *sp = strchr(line, ' ');
            char *end;
            long v;
            *strchr(line, '\n') = 0;
            errno = 0;
            v = strtol(sp + 1, &end, 10);
            printf("line %-6s value=%ld tail=%s errno=%d\n",
                   line, v, *end ? "junk" : "clean", errno);
        }
        printf("eof=%d error=%d\n", feof(f) ? 1 : 0, ferror(f) ? 1 : 0);
        fclose(f);
        unlink(path);
    }

    fflush(stdout);
    return 0;
}
