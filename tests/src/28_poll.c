/* 28_poll.c -- rung (aa): poll(2), where all three arguments are wrong.
 *
 * poll is the most innocent-looking call in the boundary: an array of 8-byte
 * structs whose layout is identical on both systems, a count, and a
 * millisecond timeout. Every one of those three is mistranslated by a naive
 * forward, and the shapes are all different.
 *
 *   nfds_t IS A DIFFERENT WIDTH. Darwin's is unsigned int, glibc's is
 *   unsigned long -- 4 against 8, in an argument slot whose upper word AAPCS
 *   leaves unspecified. Not testable from inside a C fixture, because the
 *   garbage that ends up in the top half is whatever the caller happened to
 *   leave there; it is pinned instead by sdk/tests/abi_probe.c (Darwin's 4)
 *   and sdk/tests/glibc_abi_probe.c (glibc's 8). What this fixture CAN do is
 *   drive the count past the wrapper's 32-entry stack buffer, which is the
 *   only place the count is used for anything but the call itself.
 *
 *   TWO OF THE TEN FLAGS ARE NUMBERED DIFFERENTLY:
 *
 *       POLLWRNORM   Darwin 0x0004   glibc 0x0100
 *       POLLWRBAND   Darwin 0x0100   glibc 0x0200
 *
 *   Darwin spells POLLWRNORM as a plain alias for POLLOUT, so its two write
 *   flags sit one position below glibc's, and Darwin's POLLWRBAND is
 *   bit-identical to glibc's POLLWRNORM.
 *
 * WHAT THIS FIXTURE IS AND IS NOT, because the first version of it claimed
 * more than it could deliver and I would rather the next reader inherit the
 * correction than the claim.
 *
 * I wrote it to catch an untranslated forward, on the theory that Linux's
 * pipe_poll sets EPOLLOUT|EPOLLWRNORM for a writable pipe and a guest would
 * therefore get POLLOUT|POLLWRBAND back. Then I ran it against a deliberately
 * untranslated poll() as a negative control, and it PASSED -- so I measured,
 * and the theory was wrong in a specific way: poll(2) masks revents by the
 * events the caller requested. glibc can only return POLLWRNORM to someone
 * who asked for 0x0100, and a Darwin guest asking 0x0100 is asking for
 * POLLWRBAND. Measured under Linux on a writable pipe: events=POLLOUT gives
 * revents=0x0004, not 0x0104.
 *
 * So this is a REGRESSION GUARD, not a discriminating test. It holds the
 * eight already-agreeing flags, the counts, and the heap path to the byte
 * against a macOS oracle; it does not by itself prove the translation is
 * needed. What proves that is sdk/tests/{abi,glibc_abi}_probe.c, which pin
 * the two columns so a change on either side fails the build.
 *
 * Nor could it test the flag mapping even if written to: the one case that
 * would show it -- POLLWRBAND on a pipe -- is a place the two KERNELS
 * disagree. Darwin answers 0x0100 (its kqueue-backed poll treats an ordinary
 * writable pipe as write-band-ready) and Linux answers 0 (a pipe has no write
 * band). No mapping reaches that, so no oracle-matching fixture can contain
 * it.
 *
 * ppoll(2) has no fixture here and cannot have one: Darwin does not have the
 * function (Apple's sys/poll.h at xnu-12377.121.6 declares poll and nothing
 * else), so macOS cannot produce an oracle for it. What that leaves untested
 * is only ppoll's own timespec-to-milliseconds clamp -- the flag and count
 * translations are the same mr_poll_common() body this fixture drives, and
 * the sigset_t half is what 25_sigmask already covers.
 *
 * Nothing host-specific is printed: no descriptor numbers, no addresses, no
 * sizes. The output is identical on macOS and under machorun when all the
 * translations are right.
 */
#include <stdio.h>
#include <poll.h>
#include <unistd.h>
#include <string.h>

/* Darwin's whole poll vocabulary, most-specific spellings first. POLLWRNORM
 * is deliberately absent: it is the same bit as POLLOUT, so naming it would
 * print one of the two arbitrarily. That aliasing is the bug's disguise, and
 * the decomposition should not paper over it. */
static const struct { const char *n; short b; } F[] = {
    { "POLLIN",     POLLIN     }, { "POLLPRI",    POLLPRI    },
    { "POLLOUT",    POLLOUT    }, { "POLLERR",    POLLERR    },
    { "POLLHUP",    POLLHUP    }, { "POLLNVAL",   POLLNVAL   },
    { "POLLRDNORM", POLLRDNORM }, { "POLLRDBAND", POLLRDBAND },
    { "POLLWRBAND", POLLWRBAND },
};
#define NF (sizeof F / sizeof F[0])

/* Print revents by name, and report every bit not in `want` as a STRAY. A
 * stray is exactly what a mistranslated flag looks like from inside the
 * guest: a condition the kernel never reported, named after a real one. */
static void show(const char *label, int n, short revents, short want)
{
    short left = revents, stray;
    size_t i;
    int first = 1;

    printf("  %-34s n=%d revents=", label, n);
    if (!revents) printf("(none)");
    for (i = 0; i < NF; i++) {
        if (!(revents & F[i].b)) continue;
        printf("%s%s", first ? "" : "|", F[i].n);
        first = 0;
        left = (short)(left & ~F[i].b);
    }
    if (left) printf("%s0x%04x", first ? "" : "|", (unsigned short)left);

    stray = (short)(revents & ~want);
    printf("  stray=%s\n", stray ? "YES" : "no");
}

int main(void)
{
    struct pollfd p[64];
    int pfd[2], many[64], i, n;
    char c = 'x';

    if (pipe(pfd) != 0) { puts("pipe failed"); return 1; }

    puts("== the write end of a pipe is writable");
    /* Both systems answer POLLOUT alone, because poll masks revents by the
     * events asked for. This is the case I expected to differ and it does
     * not; it is kept as the plainest statement of what a run loop actually
     * sees, which is the traffic the eight agreeing flags carry. */
    p[0].fd = pfd[1]; p[0].events = POLLOUT; p[0].revents = 0;
    n = poll(p, 1, 0);
    show("events=POLLOUT", n, p[0].revents, POLLOUT);

    /* POLLWRNORM is the same bit, so this must produce the same answer. If
     * the two lines ever differ, the alias has been broken somewhere. */
    p[0].fd = pfd[1]; p[0].events = POLLOUT | POLLWRNORM; p[0].revents = 0;
    n = poll(p, 1, 0);
    show("events=POLLOUT|POLLWRNORM", n, p[0].revents, POLLOUT);

    puts("== the read end, before and after a write");
    p[0].fd = pfd[0]; p[0].events = POLLIN; p[0].revents = 0;
    n = poll(p, 1, 0);
    show("before write", n, p[0].revents, POLLIN);

    if (write(pfd[1], &c, 1) != 1) { puts("write failed"); return 1; }
    p[0].fd = pfd[0]; p[0].events = POLLIN; p[0].revents = 0;
    n = poll(p, 1, 0);
    show("after write", n, p[0].revents, POLLIN);

    if (read(pfd[0], &c, 1) != 1) { puts("read failed"); return 1; }

    puts("== POLLRDNORM is a distinct bit on both, and must survive");
    p[0].fd = pfd[1]; p[0].events = POLLRDNORM; p[0].revents = 0;
    n = poll(p, 1, 0);
    show("events=POLLRDNORM on a write end", n, p[0].revents, 0);

    puts("== a descriptor that is not open");
    /* POLLNVAL is reported in revents whatever was asked for, and it is one of
     * the six flags whose value already agrees, so this is a control: it must
     * read the same however the translation is written. */
    {
        int dead = dup(pfd[0]);
        close(dead);
        p[0].fd = dead; p[0].events = POLLIN; p[0].revents = 0;
        n = poll(p, 1, 0);
        show("closed fd, events=POLLIN", n, p[0].revents, POLLNVAL);
    }

    puts("== a negative descriptor is ignored, not an error");
    p[0].fd = -1; p[0].events = POLLIN; p[0].revents = 0;
    n = poll(p, 1, 0);
    show("fd=-1", n, p[0].revents, 0);

    puts("== 64 descriptors, past the wrapper's 32-entry stack buffer");
    /* 32 pipes, both ends of each: 32 idle read ends and 32 writable write
     * ends. The count is the point -- 64 forces the wrapper onto its heap
     * path, which is the only code in it that reads nfds for anything other
     * than passing it on.
     *
     * Pipes rather than the obvious /dev/null, and the reason is worth
     * recording because it cost a baseline: Darwin's poll is kqueue-backed
     * and answers POLLNVAL (0x0020) for /dev/null, /dev/zero and character
     * devices generally, where Linux answers POLLOUT. That is a real kernel
     * difference and not a translation this boundary could fix, so it does
     * not belong in a fixture that exists to grade the translation. */
    for (i = 0; i < 32; i++) {
        int q[2];
        if (pipe(q) != 0) { puts("pipe failed"); return 1; }
        many[i * 2]     = q[0];
        many[i * 2 + 1] = q[1];
        p[i * 2]     = (struct pollfd){ q[0], POLLIN,  0 };
        p[i * 2 + 1] = (struct pollfd){ q[1], POLLOUT, 0 };
    }
    n = poll(p, 64, 0);
    {
        int out = 0, quiet = 0, stray = 0;
        for (i = 0; i < 64; i++) {
            short want = (i & 1) ? POLLOUT : 0;            /* odd = write end */
            if ((i & 1) && (p[i].revents & POLLOUT)) out++;
            if (!(i & 1) && !p[i].revents) quiet++;
            if (p[i].revents & ~want) stray++;
        }
        printf("  n=%d  POLLOUT on %d of 32 write ends  %d of 32 read ends "
               "quiet  strays=%d\n", n, out, quiet, stray);
    }
    for (i = 0; i < 64; i++) close(many[i]);

    puts("== a zero timeout with nothing to report returns 0");
    p[0].fd = pfd[0]; p[0].events = POLLIN; p[0].revents = 0;
    n = poll(p, 1, 0);
    printf("  n=%d\n", n);

    puts("== nfds=0 is legal and just sleeps for the timeout");
    n = poll(p, 0, 0);
    printf("  n=%d\n", n);

    close(pfd[0]); close(pfd[1]);
    puts("done");
    return 0;
}
