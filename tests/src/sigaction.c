/* sigaction.c -- the `sigaction` rung: installing a signal handler, which is the first
 * thing in this corpus that crosses the boundary in BOTH directions.
 *
 * Every other wrapper in darwin/src/posix.c translates arguments going out and
 * results coming back, and is finished when the call returns. sigaction
 * installs a CALLBACK: the boundary gets crossed again later, from glibc's
 * signal delivery, on a stack we did not build, into guest code.
 *
 * THE ONE THAT MAKES THIS FIXTURE WORTH RUNNING is the signal NUMBER in that
 * second crossing. Ten of the 31 signals are numbered differently, and the two
 * this fixture uses are among them:
 *
 *     SIGUSR1   Darwin 30   Linux 10
 *     SIGUSR2   Darwin 31   Linux 12
 *
 * A wrapper that translated the number on the way IN and stopped there would
 * install the handler on the right signal and then call it with LINUX's
 * number. A guest handler installed for SIGUSR1 would be invoked with 10 --
 * which on Darwin is SIGBUS. So the handler below records the number it was
 * given and main prints its NAME, and that name is the difference between this
 * fixture passing and failing.
 *
 * It is not a hypothetical: swift-corelibs-libdispatch's event_epoll.c
 * installs a handler that passes the number it receives straight to
 * pthread_kill. Untranslated, the signal is not merely misread, it is re-sent
 * under a different name to a different thread.
 *
 * THREE MORE THINGS DIFFER and are exercised here:
 *
 *   struct sigaction is 16 bytes on Darwin and 152 on Linux, and `oact` is an
 *   OUT parameter -- so a forward has glibc write 152 bytes into 16. That is
 *   the overflow class with a live consumer, and every save-and-restore idiom
 *   in the world uses oact.
 *
 *   sa_mask is a 4-byte Darwin sigset_t BY VALUE inside that struct, against
 *   glibc's 128, so it is the sigset_t crossing embedded in a struct rather
 *   than passed as a pointer.
 *
 *   NOT ONE sa_flags BIT AGREES. Darwin's SA_RESTART (0x02) is glibc's
 *   SA_NOCLDWAIT; Darwin's SA_ONSTACK (0x01) is its SA_NOCLDSTOP. Note that
 *   SA_RESTART would ROUND-TRIP by accident through an untranslated wrapper,
 *   since 0x02 goes out and 0x02 comes back -- so the flags cases below are
 *   honest regression cover rather than the discriminating part. The signal
 *   number is the discriminating part.
 *
 * The handler does no printing: it records into a volatile sig_atomic_t and
 * main reports. That keeps it async-signal-safe and keeps the output ordered
 * the same way on both systems.
 */
#include <stdio.h>
#include <signal.h>
#include <string.h>
#include <pthread.h>

static volatile sig_atomic_t got_signo;
static volatile sig_atomic_t got_count;

static void handler(int signo)
{
    got_signo = signo;
    got_count++;
}

/* Only the names this fixture can legitimately see. Anything else is reported
 * as a raw number, because a signal we did not ask for arriving under a name
 * we recognise is precisely the bug being tested for. */
static const char *signame(int s)
{
    switch (s) {
    case SIGUSR1: return "SIGUSR1";
    case SIGUSR2: return "SIGUSR2";
    case SIGBUS:  return "SIGBUS";     /* what Linux's 10 means on Darwin */
    case SIGSYS:  return "SIGSYS";     /* what Linux's 12 means on Darwin */
    case 0:       return "(none)";
    default:      return "OTHER";
    }
}

static void show_flags(const char *label, int f)
{
    int known = SA_ONSTACK | SA_RESTART | SA_RESETHAND | SA_NOCLDSTOP |
                SA_NODEFER | SA_NOCLDWAIT | SA_SIGINFO;
    int first = 1;
    printf("  %-26s ", label);
    if (!f) printf("(none)");
#define F(b) if (f & b) { printf("%s%s", first ? "" : "|", #b); first = 0; }
    F(SA_ONSTACK) F(SA_RESTART) F(SA_RESETHAND) F(SA_NOCLDSTOP)
    F(SA_NODEFER) F(SA_NOCLDWAIT) F(SA_SIGINFO)
#undef F
    printf("  stray=%s\n", (f & ~known) ? "YES" : "no");
}

int main(void)
{
    struct sigaction sa, old, back;
    int rc;

    /* ---- the signal number survives the round trip into guest code ---- */
    puts("== a handler for SIGUSR1, whose number differs on the two systems");
    memset(&sa, 0, sizeof sa);
    sa.sa_handler = handler;
    sa.sa_flags = SA_RESTART;
    sigemptyset(&sa.sa_mask);

    rc = sigaction(SIGUSR1, &sa, &old);
    printf("  install rc=%d  previous handler was default=%s\n",
           rc, old.sa_handler == SIG_DFL ? "yes" : "no");

    got_signo = 0; got_count = 0;
    raise(SIGUSR1);
    printf("  after raise(SIGUSR1):       count=%d  handler saw %s\n",
           (int)got_count, signame((int)got_signo));

    got_signo = 0; got_count = 0;
    pthread_kill(pthread_self(), SIGUSR1);
    printf("  after pthread_kill(SIGUSR1): count=%d  handler saw %s\n",
           (int)got_count, signame((int)got_signo));

    /* ---- and for a second signal, so a single lucky mapping cannot pass ---- */
    puts("== the same for SIGUSR2, which differs differently");
    rc = sigaction(SIGUSR2, &sa, NULL);
    got_signo = 0; got_count = 0;
    raise(SIGUSR2);
    printf("  install rc=%d  after raise(SIGUSR2): count=%d  handler saw %s\n",
           rc, (int)got_count, signame((int)got_signo));

    /* ---- oact: the 152-into-16 direction ---- */
    puts("== reading the action back through oact");
    memset(&back, 0, sizeof back);
    rc = sigaction(SIGUSR1, NULL, &back);
    printf("  query rc=%d  handler is the one we installed=%s\n",
           rc, back.sa_handler == handler ? "yes" : "no");
    show_flags("flags read back", back.sa_flags);

    /* ---- sa_mask, a Darwin sigset_t by value inside the struct ---- */
    puts("== sa_mask crosses inside the struct, not as a pointer");
    memset(&sa, 0, sizeof sa);
    sa.sa_handler = handler;
    sa.sa_flags = 0;
    sigemptyset(&sa.sa_mask);
    sigaddset(&sa.sa_mask, SIGUSR2);
    rc = sigaction(SIGUSR1, &sa, NULL);
    memset(&back, 0, sizeof back);
    sigaction(SIGUSR1, NULL, &back);
    printf("  install rc=%d  SIGUSR2 in the mask we read back=%s  SIGINT=%s\n",
           rc,
           sigismember(&back.sa_mask, SIGUSR2) ? "yes" : "no",
           sigismember(&back.sa_mask, SIGINT)  ? "yes" : "no");

    /* ---- the save-and-restore idiom, which is what oact is for ---- */
    puts("== save, replace with SIG_IGN, restore");
    memset(&sa, 0, sizeof sa);
    sa.sa_handler = SIG_IGN;
    sigemptyset(&sa.sa_mask);
    sigaction(SIGUSR1, &sa, &old);
    got_signo = 0; got_count = 0;
    raise(SIGUSR1);
    printf("  while ignored:   count=%d  (0 is correct)\n", (int)got_count);

    sigaction(SIGUSR1, &old, NULL);      /* restore what save gave us */
    got_signo = 0; got_count = 0;
    raise(SIGUSR1);
    printf("  after restore:   count=%d  handler saw %s\n",
           (int)got_count, signame((int)got_signo));

    /* ---- SIG_DFL and the sentinels, the only two values that agree ---- */
    puts("== back to SIG_DFL");
    memset(&sa, 0, sizeof sa);
    sa.sa_handler = SIG_DFL;
    sigemptyset(&sa.sa_mask);
    rc = sigaction(SIGUSR1, &sa, &old);
    printf("  rc=%d  oact reported our handler=%s\n",
           rc, old.sa_handler == handler ? "yes" : "no");

    memset(&back, 0, sizeof back);
    sigaction(SIGUSR1, NULL, &back);
    printf("  now default=%s\n", back.sa_handler == SIG_DFL ? "yes" : "no");

    /* SIGEMT and SIGINFO are DELIBERATELY NOT TESTED HERE. They exist only on
     * Darwin, so macOS installs a handler and returns 0 while machorun has no
     * Linux signal to install on and returns EINVAL. That is a real divergence
     * no wrapper can reconcile, which means it cannot live in a fixture that
     * must match its oracle byte for byte -- the same reason POLLWRBAND is
     * absent from poll. It is recorded in
     * docs/UNIMPLEMENTED.md#sigaction-darwin-only-signals instead. */

    puts("done");
    return 0;
}
