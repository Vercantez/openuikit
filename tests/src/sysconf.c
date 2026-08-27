/* sysconf.c -- the `sysconf` rung: the constants that cross the boundary.
 *
 * sysconf is the sharpest instance of a hazard class the size audit could not
 * see. Of the 128 _SC_* names that exist on both systems, ALL 128 have
 * different values -- Darwin's _SC_PAGESIZE is 29 where Linux's is 30,
 * _SC_NPROCESSORS_ONLN is 58 against 84. Forwarded raw, every query a guest
 * makes reads the wrong row of glibc's table. Before the fix:
 *
 *     sysconf(_SC_PAGESIZE)         -> 200809   (macOS: 16384)
 *     sysconf(_SC_NPROCESSORS_ONLN) -> -1       (macOS: 16)
 *     sysconf(_SC_OPEN_MAX)         -> 16       (macOS: 1048576)
 *
 * The third is why this is a fixture rather than a comment. 200809 is obvious
 * nonsense and -1 is a visible failure, but 16 is a perfectly plausible
 * open-file limit -- nothing about it looks wrong, and a guest that sized a
 * table with it would just be wrong.
 *
 * WHY IT PRINTS PREDICATES AND NOT VALUES. The right answers legitimately
 * DIFFER between the two hosts: macOS reports a 16 KiB page and Linux a 4 KiB
 * one, and machorun deliberately reports the host's real page size rather than
 * Darwin's (docs/MACHO_NOTES.md §9). CPU count and the open-file limit vary by
 * machine. So a fixture printing the numbers could never be byte-identical,
 * and one printing nothing useful would pass against the broken version. What
 * IS identical across hosts is whether each answer is in the range that answer
 * can possibly occupy -- which the broken version fails on all three counts.
 *
 * Same shape as isa_mask: when the values cannot match, grade the property.
 */
#include <stdio.h>
#include <unistd.h>
#include <errno.h>

static void probe(const char *what, long got, long lo, long hi)
{
    printf("%-22s %s\n", what,
           (got >= lo && got <= hi) ? "in range" : "OUT OF RANGE");
}

int main(void)
{
    /* A page is a power of two between 4 KiB and 64 KiB on every system we
     * target. 200809 is not a page size on any of them. */
    probe("_SC_PAGESIZE", sysconf(_SC_PAGESIZE), 4096, 65536);
    probe("_SC_NPROCESSORS_CONF", sysconf(_SC_NPROCESSORS_CONF), 1, 4096);
    probe("_SC_NPROCESSORS_ONLN", sysconf(_SC_NPROCESSORS_ONLN), 1, 4096);
    probe("_SC_OPEN_MAX", sysconf(_SC_OPEN_MAX), 20, 1u << 30);
    probe("_SC_CLK_TCK", sysconf(_SC_CLK_TCK), 1, 10000);
    probe("_SC_ARG_MAX", sysconf(_SC_ARG_MAX), 4096, 1u << 30);
    probe("_SC_LINE_MAX", sysconf(_SC_LINE_MAX), 256, 1u << 24);
    probe("_SC_HOST_NAME_MAX", sysconf(_SC_HOST_NAME_MAX), 64, 4096);

    /* A page size must also be a power of two -- a check no wrong row of
     * glibc's table is likely to satisfy by accident. */
    {
        long ps = sysconf(_SC_PAGESIZE);
        printf("%-22s %s\n", "page is 2^n", (ps > 0 && (ps & (ps - 1)) == 0) ? "yes" : "NO");
    }

    /* An unrecognised name must be REFUSED, not answered. This is the negative
     * control: a translation that silently passed unknown values through would
     * return whatever glibc's table holds at that index, and pass every check
     * above while being wrong here. */
    {
        long r;
        errno = 0;
        r = sysconf(0x7fff);
        printf("%-22s %s\n", "unknown name",
               (r == -1 && errno == EINVAL) ? "refused with EINVAL" : "ANSWERED");
    }

    printf("done\n");
    return 0;
}
