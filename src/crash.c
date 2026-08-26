/* crash.c -- turn a guest fault into a sentence instead of a bare exit code.
 *
 * A Mach-O guest that faults gives us a Linux signal with an aarch64 pc. That
 * pc is meaningless on its own; attributed to an image and an offset it is a
 * line of otool away from being understood. The handler also recognises the
 * one wall this project chose not to climb: a raw Darwin `svc #0x80`.
 *
 * The default disposition is restored before re-raising, so the process still
 * dies with the same status it would have had -- the harness's exit-code
 * comparison is untouched.
 */
#define _GNU_SOURCE
#include "machorun.h"

#include <signal.h>
#include <stdio.h>
#include <string.h>
#include <ucontext.h>
#include <unistd.h>

static const char *signame(int s)
{
    switch (s) {
    case SIGSEGV: return "SIGSEGV";
    case SIGBUS:  return "SIGBUS";
    case SIGILL:  return "SIGILL";
    case SIGTRAP: return "SIGTRAP";
    case SIGFPE:  return "SIGFPE";
    case SIGSYS:  return "SIGSYS";
    default:      return "signal";
    }
}

/* svc #imm is 0xD4000001 | (imm << 5); Darwin's is svc #0x80. */
static int is_darwin_svc(uint32_t insn) { return insn == (0xD4000001u | (0x80u << 5)); }

static void handler(int sig, siginfo_t *si, void *uc)
{
    ucontext_t *u = uc;
    uint64_t pc = (uint64_t)u->uc_mcontext.pc;
    mr_image *in = NULL;
    char buf[1024];
    int n;

    for (int i = 0; i < MR.nimages; i++)
        if (pc >= MR.images[i]->span_lo && pc < MR.images[i]->span_hi) { in = MR.images[i]; break; }

    n = snprintf(buf, sizeof(buf),
                 "\nmachorun: guest died with %s at pc 0x%llx (fault address %p)\n",
                 signame(sig), (unsigned long long)pc, si->si_addr);
    if (in)
        n += snprintf(buf + n, sizeof(buf) - n,
                      "  pc is in %s at image offset 0x%llx\n",
                      in->path, (unsigned long long)(pc - in->load_base));
    else
        n += snprintf(buf + n, sizeof(buf) - n,
                      "  pc is not inside any loaded Mach-O image (loader or glibc code)\n");

    if (in) {
        const uint32_t *code = (const uint32_t *)(pc & ~3ull);
        for (int back = 0; back <= 4; back++) {
            if ((uint64_t)(code - back) < in->span_lo) break;
            if (!is_darwin_svc(code[-back])) continue;
            n += snprintf(buf + n, sizeof(buf) - n,
                "  there is a raw `svc #0x80` %d instruction(s) back. That is Darwin's\n"
                "  syscall convention: number in x16, BSD numbering. On Linux/arm64 svc\n"
                "  traps to the Linux kernel, which reads x8 and uses Linux numbering, so\n"
                "  it lands somewhere arbitrary. This is the boundary of machorun's core\n"
                "  bet -- we replace libSystem instead of emulating Darwin syscalls -- and\n"
                "  supporting it would mean seccomp trapping or binary rewriting. See\n"
                "  docs/FIXTURES.md rung (a) and docs/UNIMPLEMENTED.md.\n", back);
            break;
        }
    }

    (void)!write(2, buf, (size_t)n);
    signal(sig, SIG_DFL);
    raise(sig);
}

void mr_install_crash_reporter(void)
{
    struct sigaction sa;
    int sigs[] = { SIGSEGV, SIGBUS, SIGILL, SIGTRAP, SIGFPE, SIGSYS };
    memset(&sa, 0, sizeof(sa));
    sa.sa_sigaction = handler;
    sa.sa_flags = SA_SIGINFO | SA_NODEFER | SA_RESETHAND;
    sigemptyset(&sa.sa_mask);
    for (unsigned i = 0; i < sizeof(sigs) / sizeof(sigs[0]); i++)
        sigaction(sigs[i], &sa, NULL);
}
