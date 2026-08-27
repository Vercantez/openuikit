/* sigmask.c -- the `sigmask` rung: blocking signals, which is two translations.
 *
 * sigset_t is the first REACHED member of the overflow class: Darwin's is a
 * 32-bit bitmask (bit signo-1), glibc's is 128 bytes. pthread_sigmask's third
 * argument is an OUT parameter, so a naive forward writes 128 bytes into 4.
 *
 * But the size is the half that fails loudly. Two quieter things also differ:
 *
 *   TEN OF THE 29 STANDARD SIGNALS HAVE DIFFERENT NUMBERS.
 *       SIGBUS 10/7   SIGSYS 12/31  SIGURG 16/23  SIGSTOP 17/19  SIGTSTP 18/20
 *       SIGCONT 19/18 SIGCHLD 20/17 SIGIO 23/29   SIGUSR1 30/10  SIGUSR2 31/12
 *   A wrapper that widened the mask and stopped there would subscribe the
 *   guest to the wrong signals, return 0, and look fine.
 *
 *   THE `how` ARGUMENT IS OFF BY ONE.
 *       Darwin SIG_BLOCK 1 / SIG_UNBLOCK 2 / SIG_SETMASK 3
 *       glibc  SIG_BLOCK 0 / SIG_UNBLOCK 1 / SIG_SETMASK 2
 *   Off by one is the worst possible spacing: a forwarded SIG_BLOCK is read as
 *   SIG_UNBLOCK and does the OPPOSITE of what was asked, returning success.
 *   Only SIG_SETMASK failed at all, and only because 3 is out of range. That
 *   is what caught it during development; an API with two values instead of
 *   three would have been silently inverted with nothing to notice.
 *
 * So this fixture blocks the signals whose NUMBERS differ, reads the mask back
 * through a second pthread_sigmask, and prints which survived -- a round trip
 * that only comes out right if every one of the three translations is right.
 * It also counts STRAY blocked signals: anything blocked that was never asked
 * for, which is what a mistranslated number looks like from the inside.
 *
 * No addresses, no sizes beyond sigset_t's, nothing host-specific: the output
 * is identical on macOS and under machorun when the translation is correct.
 */
#include <stdio.h>
#include <signal.h>
#include <string.h>

static const struct { const char *n; int s; } S[] = {
    { "SIGUSR1", SIGUSR1 }, { "SIGUSR2", SIGUSR2 }, { "SIGCHLD", SIGCHLD },
    { "SIGBUS",  SIGBUS  }, { "SIGURG",  SIGURG  }, { "SIGIO",   SIGIO   },
    { "SIGSYS",  SIGSYS  }, { "SIGCONT", SIGCONT }, { "SIGTSTP", SIGTSTP },
    { "SIGINT",  SIGINT  }, { "SIGTERM", SIGTERM }, { "SIGPIPE", SIGPIPE },
};
#define NS (sizeof S / sizeof S[0])

int main(void)
{
    sigset_t block, old, back;
    int stray = 0;

    printf("sizeof(sigset_t)=%zu\n", sizeof(sigset_t));

    sigemptyset(&block);
    for (unsigned i = 0; i < NS; i++) sigaddset(&block, S[i].s);

    if (pthread_sigmask(SIG_BLOCK, &block, &old) != 0) { printf("SIG_BLOCK failed\n"); return 1; }
    if (pthread_sigmask(SIG_SETMASK, &block, &back) != 0) { printf("SIG_SETMASK failed\n"); return 1; }

    printf("round trip:\n");
    for (unsigned i = 0; i < NS; i++)
        printf("  %-8s(%2d) %s\n", S[i].n, S[i].s,
               sigismember(&back, S[i].s) ? "blocked" : "MISSING");

    for (int s = 1; s <= 31; s++) {
        int wanted = 0;
        for (unsigned i = 0; i < NS; i++) if (S[i].s == s) wanted = 1;
        if (!wanted && sigismember(&back, s)) { printf("  STRAY %d\n", s); stray++; }
    }
    printf("stray=%d\n", stray);

    /* SIG_UNBLOCK, so the inversion has a second chance to show: if `how` were
     * forwarded raw, this would be read as SIG_SETMASK and the mask would end
     * up as `block` rather than empty. */
    pthread_sigmask(SIG_UNBLOCK, &block, NULL);
    pthread_sigmask(SIG_BLOCK, NULL, &back);
    {
        int left = 0;
        for (unsigned i = 0; i < NS; i++) if (sigismember(&back, S[i].s)) left++;
        printf("after SIG_UNBLOCK still blocked=%d\n", left);
    }

    pthread_sigmask(SIG_SETMASK, &old, NULL);
    printf("done\n");
    return 0;
}
