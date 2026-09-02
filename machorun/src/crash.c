/* crash.c -- turn a guest fault into a sentence instead of a bare exit code.
 *
 * A Mach-O guest that faults gives us a Linux signal with an aarch64 pc. That
 * pc is meaningless on its own; attributed to an image and an offset it is a
 * line of otool away from being understood. The handler also recognises the
 * one wall this project chose not to climb: a raw Darwin `svc #0x80`.
 *
 * It also prints the integer registers and walks the frame-pointer chain, both
 * attributed to images and to the nearest exported symbol. That is worth more
 * than it looks. A pc alone says WHERE a guest died; the argument registers and
 * the caller say WHAT it was asked to do and WHO asked. Every register fact in
 * the libswiftCore metadata investigation up to this point had to be recovered
 * by hand-tracing disassembly backwards from the pc, one `mov` at a time, and
 * that reconstruction stops at the function entry -- it cannot cross the return
 * address, which is exactly where the interesting question usually lives.
 *
 * Two things make this safe to do from a signal handler that is running BECAUSE
 * memory was bad:
 *
 *   - Every guest-memory read goes through safe_read(), which hands the address
 *     to write(2) on a pipe. An unmapped address makes write return EFAULT
 *     instead of faulting us, and a <=PIPE_BUF write to a pipe is atomic, so a
 *     bad address transfers nothing. A fault inside the fault handler would
 *     replace a diagnosable crash with an undiagnosable one.
 *   - The frame walk requires each frame pointer to be 16-aligned and strictly
 *     increasing. A corrupted x29 therefore terminates the walk rather than
 *     looping, and a stack-overflow crash -- where x29 is fine but there is no
 *     stack left -- is handled by SA_ONSTACK plus a dedicated signal stack.
 *
 * The default disposition is restored before re-raising, so the process still
 * dies with the same status it would have had -- the harness's exit-code
 * comparison is untouched.
 */
#define _GNU_SOURCE
#include "machorun.h"

#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <ucontext.h>
#include <unistd.h>

#define MR_BT_MAX_FRAMES 40

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

/* ------------------------------------------------------------ safe reads */

/* Probing with write(2) rather than reading directly: the kernel validates the
 * buffer and returns EFAULT for an address we may not touch, which is the whole
 * point -- we are here because an address was bad, and guessing which other
 * ones are good is how a crash reporter becomes the crash. */
static int probe_pipe[2] = { -1, -1 };

static int safe_read(uint64_t addr, void *dst, size_t n)
{
    if (probe_pipe[0] < 0 || n == 0 || n > 64) return 0;
    if (write(probe_pipe[1], (const void *)(uintptr_t)addr, n) != (ssize_t)n) return 0;
    return read(probe_pipe[0], dst, n) == (ssize_t)n;
}

/* ----------------------------------------------------------- attribution */

/* One definition of "which image is this address in" lives in src/image.c.
 * This was a fourth copy of it. */
#define image_of(pc) mr_image_containing((const void *)(uintptr_t)(pc))

/* Greatest export at or below `off`. Exports are the only symbols we keep --
 * the trie has no statics -- so a hit can be several kilobytes short of the
 * truth. The delta is printed for exactly that reason: `+0x40` is a name you
 * can trust, `+0x2f10` is a hint to go look at the disassembly. */
static const char *nearest_export(const mr_image *im, uint64_t off, uint64_t *delta)
{
    const char *best = NULL;
    uint64_t best_off = 0;

    if (!im) return NULL;
    for (size_t i = 0; i < im->nexports; i++) {
        uint64_t o = im->exports[i].offset;
        if (o <= off && (!best || o > best_off)) { best = im->exports[i].name; best_off = o; }
    }
    if (best) *delta = off - best_off;
    return best;
}

/* "libswiftCore.dylib+0x34a8c (_swift_checkMetadataState+0x1c)" into buf.
 *
 * `is_return` shifts the SYMBOL lookup back by one byte while still printing
 * the real address. A return address points at the instruction AFTER the call,
 * and when the call is the last thing in a function -- which is every tail call
 * and every call to a noreturn function like mr_bail -- that address belongs to
 * the NEXT symbol. Without this, the frame above an mr_bail reads
 * `_os_unfair_lock_assert_owner+0x0` when the caller was really
 * os_unfair_lock_unlock, which is a wrong name rather than a vague one. */
static int describe_at(char *buf, size_t cap, uint64_t addr, int is_return)
{
    uint64_t lookup = is_return && addr ? addr - 1 : addr;
    mr_image *im = image_of(lookup);
    const char *base, *sym;
    uint64_t off, delta = 0;

    if (!im)
        return snprintf(buf, cap, "0x%llx  <not in any Mach-O image: loader, glibc or JIT>",
                        (unsigned long long)addr);

    base = strrchr(im->path, '/');
    base = base ? base + 1 : im->path;
    off  = addr - im->load_base;
    sym  = nearest_export(im, lookup - im->load_base, &delta);

    if (sym)
        return snprintf(buf, cap, "0x%llx  %s+0x%llx  (%s+0x%llx)",
                        (unsigned long long)addr, base, (unsigned long long)off,
                        sym, (unsigned long long)(delta + (is_return ? 1 : 0)));
    return snprintf(buf, cap, "0x%llx  %s+0x%llx",
                    (unsigned long long)addr, base, (unsigned long long)off);
}

static int describe(char *buf, size_t cap, uint64_t addr)
{
    return describe_at(buf, cap, addr, 0);
}

/* ---------------------------------------------------------------- output */

/* One line at a time straight to fd 2. Accumulating into a big buffer is how
 * the previous version worked and it silently truncates at whatever the buffer
 * happens to be; a backtrace has no fixed length. */
static void emit(const char *fmt, ...) __attribute__((format(printf, 1, 2)));
static void emit(const char *fmt, ...)
{
    char line[512];
    va_list ap;
    int n;

    va_start(ap, fmt);
    n = vsnprintf(line, sizeof(line), fmt, ap);
    va_end(ap);
    if (n > (int)sizeof(line) - 1) n = (int)sizeof(line) - 1;
    if (n > 0) (void)!write(2, line, (size_t)n);
}

static void dump_registers(const ucontext_t *u)
{
    char d[512];

    emit("  registers:\n");
    for (int i = 0; i <= 28; i += 4) {
        emit("   ");
        for (int j = i; j < i + 4 && j <= 28; j++)
            emit(" x%-2d=%016llx", j, (unsigned long long)u->uc_mcontext.regs[j]);
        emit("\n");
    }
    emit("    x29=%016llx  x30=%016llx   sp=%016llx\n",
         (unsigned long long)u->uc_mcontext.regs[29],
         (unsigned long long)u->uc_mcontext.regs[30],
         (unsigned long long)u->uc_mcontext.sp);

    describe_at(d, sizeof(d), (uint64_t)u->uc_mcontext.regs[30], 1);
    emit("    x30 (link register) is %s\n", d);
}

/* AArch64 frame record: [x29] = caller's x29, [x29+8] = caller's return address.
 *
 * `pc` and `lr` are the two registers a signal context has and a live call does
 * not, so both are optional. Passing lr matters more than it looks: a leaf
 * function needs no frame, so on a fault inside one, x29 still belongs to the
 * CALLER and the chain silently skips a level. x30 is the only place that frame
 * exists. The teeth check for this handler is built on exactly that case. */
static void walk_frames(uint64_t pc, uint64_t lr, uint64_t fp)
{
    uint64_t prev = 0;
    char d[512];
    int frame = 0;

    if (pc) {
        describe(d, sizeof(d), pc);
        emit("    #%-2d %s\n", frame++, d);
    }
    if (lr) {
        describe_at(d, sizeof(d), lr, 1);
        emit("    #%-2d %s   [from x30]\n", frame++, d);
    }

    while (frame < MR_BT_MAX_FRAMES) {
        uint64_t rec[2];

        if (!fp || (fp & 15) || fp <= prev) break;   /* monotonic and aligned, or stop */
        if (!safe_read(fp, rec, sizeof(rec))) {
            emit("    #%-2d <frame pointer 0x%llx is not readable; chain ends here>\n",
                 frame, (unsigned long long)fp);
            break;
        }
        if (!rec[1]) break;

        describe_at(d, sizeof(d), rec[1], 1);
        emit("    #%-2d %s\n", frame++, d);

        prev = fp;
        fp   = rec[0];
    }

    if (frame >= MR_BT_MAX_FRAMES)
        emit("    ... truncated at %d frames\n", MR_BT_MAX_FRAMES);
}

/* Called by our own dylibs from mr_bail (darwin/src/libsystem.c), through the
 * loader-symbol boundary registered in darwin/loader-exports.txt.
 *
 * A guest-side diagnostic knows WHAT rule was broken and has no way at all to
 * find out WHO broke it: darwin/src is a Mach-O dylib with no access to the
 * loader's image table. `os_unfair_lock_unlock: this thread does not own the
 * lock` was a true statement with no addressee for as long as that was true. */
/* Hex around an address, image/heap attributed, for a guest-side diagnostic
 * that has an address and no way to look at it. Reads go through safe_read, so
 * an unmapped word prints as ?? rather than turning a diagnostic into a second
 * crash. */
void mr_report_memory(const void *addr, unsigned before, unsigned after)
{
    uint64_t a = (uint64_t)(uintptr_t)addr;
    uint64_t lo = (a - before) & ~15ull, hi = (a + after + 15) & ~15ull;
    mr_image *im = image_of(a);

    emit("  memory around 0x%llx (%s):\n", (unsigned long long)a,
         im ? im->path : (mr_addr_in_glibc_heap(addr) ? "glibc heap" : "not an image, not the heap"));
    for (uint64_t p = lo; p < hi; p += 16) {
        uint64_t w[2];
        char line[160];
        int n;
        if (!safe_read(p, w, sizeof(w))) {
            emit("    0x%llx  <unreadable>\n", (unsigned long long)p);
            continue;
        }
        n = snprintf(line, sizeof(line), "    0x%llx  %016llx %016llx%s\n",
                     (unsigned long long)p, (unsigned long long)w[0],
                     (unsigned long long)w[1],
                     (a >= p && a < p + 16) ? "   <-- here" : "");
        if (n > 0) (void)!write(2, line, (size_t)n);
    }
}

void mr_report_backtrace(const char *why)
{
    if (why) emit("  %s\n", why);
    emit("  backtrace (frame-pointer chain):\n");
    walk_frames(0, 0, (uint64_t)(uintptr_t)__builtin_frame_address(0));
}

/* --------------------------------------------------------- the watchpoint */

/* mprotect is the only write watchpoint available without ptrace, and it is
 * page-granular, so arming it on one four-byte lock word arms it on everything
 * else that shares the page. The handler therefore has to tell the two apart:
 * a write to the WATCHED WORD is the answer and stops the process; a write
 * anywhere else on the page is noise, gets one line naming the writer, and is
 * allowed to proceed. Without that distinction the first unrelated heap write
 * ends the run and the watchpoint never sees what it was set for.
 *
 * Debugging machinery, off unless the guest asks for it. */
static volatile uint64_t guard_word, guard_page, guard_size;
static volatile int      guard_armed, guard_stale;
static volatile uint32_t guard_value;      /* what the word held when armed */
static volatile uint64_t guard_last_pc;    /* writer of the previous allowed store */

static void guard_protect(int writable)
{
    if (guard_page)
        mprotect((void *)(uintptr_t)guard_page, (size_t)guard_size,
                 writable ? (PROT_READ | PROT_WRITE) : PROT_READ);
}

/* FIRST COME, and that is the whole design.
 *
 * The obvious version re-arms on every lock, and it watches the wrong word:
 * the lock whose value changes underneath you is by definition one you took
 * and have not yet released, so a LATER acquisition would move the watch off
 * it precisely during the window of interest. Measured -- the first version
 * did exactly this and reported every write on the page except the one it was
 * set for. So an arm while armed is a no-op, and only the matching unlock
 * releases it. */
void mr_guard_arm(const void *word)
{
    uint64_t a = (uint64_t)(uintptr_t)word;
    uint64_t pg = MR.page.v ? MR.page.v : 4096;

    if (guard_armed) {
        /* Re-protect after a write we let through, or the watch is one write
         * old and silently off. */
        if (guard_stale) { guard_protect(0); guard_stale = 0; }
        return;
    }
    if (!mr_addr_in_glibc_heap(word)) return;   /* an image __DATA page is all data */
    guard_word = a;
    guard_size = pg;
    guard_page = a & ~(pg - 1);
    guard_armed = 1;
    guard_stale = 0;
    guard_last_pc = 0;
    safe_read(a, (void *)&guard_value, sizeof(uint32_t));
    guard_protect(0);
}

void mr_guard_disarm(const void *word)
{
    if (!guard_armed || (uint64_t)(uintptr_t)word != guard_word) return;
    guard_protect(1);
    guard_armed = 0;
    guard_page = 0;
}

/* 1 if the fault was noise on the guarded page and the store may proceed. */
static int guard_handled(int sig, siginfo_t *si, const ucontext_t *u)
{
    uint64_t fa = (uint64_t)(uintptr_t)si->si_addr;
    char d[512];

    if (sig != SIGSEGV || !guard_armed || !guard_page) return 0;
    if (fa < guard_page || fa >= guard_page + guard_size) return 0;

    if (fa >= guard_word && fa < guard_word + 4) {
        emit("\nmachorun: WATCHPOINT HIT -- the guarded word 0x%llx is being written\n",
             (unsigned long long)guard_word);
        return 0;                      /* fall through to the full report, then die */
    }

    /* Letting an unrelated store proceed means unprotecting the page, and the
     * watch is blind until the guest's next lock operation re-arms it. A store
     * to the watched word inside that window is missed -- MEASURED, not
     * feared: the first version of this watchpoint allowed 413 stores and never
     * once fired, while the word changed anyway. So check the word itself on
     * every fault. That brackets the writer between two named stores, which is
     * strictly weaker than catching it but is a bracket rather than nothing. */
    {
        uint32_t now = guard_value;
        if (safe_read(guard_word, &now, sizeof(now)) && now != guard_value) {
            char prev[512];
            describe(prev, sizeof(prev), guard_last_pc);
            emit("\nmachorun: THE WATCHED WORD CHANGED: 0x%llx went 0x%08x -> 0x%08x\n"
                 "  without faulting, so it was written while the page was open. The\n"
                 "  window was opened by the store from %s\n"
                 "  and closed here.\n",
                 (unsigned long long)guard_word, guard_value, now, prev);
            return 0;                  /* full report from here, then die */
        }
    }

    describe(d, sizeof(d), (uint64_t)u->uc_mcontext.pc);
    emit("machorun: guarded page written at 0x%llx (not the watched word) from %s\n",
         (unsigned long long)fa, d);
    guard_last_pc = (uint64_t)u->uc_mcontext.pc;
    guard_protect(1);
    guard_stale = 1;      /* re-armed by the guest's next lock operation */
    return 1;
}

/* ------------------------------------------------------------ the handler */

static void handler(int sig, siginfo_t *si, void *uc)
{
    ucontext_t *u = uc;
    uint64_t pc = (uint64_t)u->uc_mcontext.pc;
    mr_image *in;

    if (guard_handled(sig, si, u)) {
        /* SA_RESETHAND disarmed us on entry; put the handler back before
         * returning to the faulting store, or the next fault dies silently. */
        mr_install_crash_reporter();
        return;
    }
    in = image_of(pc);

    emit("\nmachorun: guest died with %s at pc 0x%llx (fault address %p)\n",
         signame(sig), (unsigned long long)pc, si->si_addr);

    if (in)
        emit("  pc is in %s at image offset 0x%llx\n",
             in->path, (unsigned long long)(pc - in->load_base));
    else
        emit("  pc is not inside any loaded Mach-O image (loader or glibc code)\n");

    /* A fault whose address is within a page of the stack pointer is a stack
     * overflow, not a wild pointer, and the two want completely different
     * investigations. Saying so costs one comparison. */
    if (sig == SIGSEGV && si->si_addr) {
        uint64_t sp = (uint64_t)u->uc_mcontext.sp, fa = (uint64_t)(uintptr_t)si->si_addr;
        uint64_t d = sp > fa ? sp - fa : fa - sp;
        if (d < 65536)
            emit("  the fault address is within 0x%llx of sp, so this is a STACK OVERFLOW\n"
                 "  rather than a wild pointer -- look for unbounded recursion, and note\n"
                 "  that the backtrace below will be many repetitions of one frame.\n",
                 (unsigned long long)d);
    }

    if (in) {
        const uint32_t *code = (const uint32_t *)(pc & ~3ull);
        for (int back = 0; back <= 4; back++) {
            uint32_t insn;
            if ((uint64_t)(uintptr_t)(code - back) < in->span_lo) break;
            if (!safe_read((uint64_t)(uintptr_t)(code - back), &insn, sizeof(insn))) break;
            if (!is_darwin_svc(insn)) continue;
            emit("  there is a raw `svc #0x80` %d instruction(s) back. That is Darwin's\n"
                 "  syscall convention: number in x16, BSD numbering. On Linux/arm64 svc\n"
                 "  traps to the Linux kernel, which reads x8 and uses Linux numbering, so\n"
                 "  it lands somewhere arbitrary. This is the boundary of machorun's core\n"
                 "  bet -- we replace libSystem instead of emulating Darwin syscalls -- and\n"
                 "  supporting it would mean seccomp trapping or binary rewriting. See\n"
                 "  docs/FIXTURES.md rung (a) and docs/UNIMPLEMENTED.md.\n", back);
            break;
        }
    }

    dump_registers(u);
    emit("  backtrace (frame-pointer chain):\n");
    walk_frames((uint64_t)u->uc_mcontext.pc,
                (uint64_t)u->uc_mcontext.regs[30],
                (uint64_t)u->uc_mcontext.regs[29]);

    signal(sig, SIG_DFL);
    raise(sig);
}

void mr_install_crash_reporter(void)
{
    struct sigaction sa;
    /* Not SIGSTKSZ: on glibc >= 2.34 that is sysconf(_SC_SIGSTKSZ), a function
     * call, and cannot size a static array. 64 KiB is far more than this
     * handler needs -- its deepest frame is one 512-byte line buffer. */
    static char altstack[65536];
    stack_t ss;
    int sigs[] = { SIGSEGV, SIGBUS, SIGILL, SIGTRAP, SIGFPE, SIGSYS };

    if (pipe2(probe_pipe, O_CLOEXEC | O_NONBLOCK) != 0) probe_pipe[0] = probe_pipe[1] = -1;

    /* Without an alternate stack a stack-overflow SIGSEGV has nowhere to run
     * the handler and the process dies silently -- which is exactly what
     * machorun did for the std::__sort self-recursion: exit 139, no output at
     * all, for a bug the handler would have named in one line. */
    ss.ss_sp = altstack;
    ss.ss_size = sizeof(altstack);
    ss.ss_flags = 0;
    sigaltstack(&ss, NULL);

    memset(&sa, 0, sizeof(sa));
    sa.sa_sigaction = handler;
    sa.sa_flags = SA_SIGINFO | SA_NODEFER | SA_RESETHAND | SA_ONSTACK;
    sigemptyset(&sa.sa_mask);
    for (unsigned i = 0; i < sizeof(sigs) / sizeof(sigs[0]); i++)
        sigaction(sigs[i], &sa, NULL);
}
