/* fcntl_madvise.c -- the `fcntl_madvise` rung: the libdispatch boundary, and the two
 * translations in it that a fixture can actually reach.
 *
 * Eleven symbols arrived together for swift-corelibs-libdispatch. Most cannot
 * be graded against a macOS oracle -- `sysctl` returns a machorun build string
 * by design, `ioctl`'s SIOCINQ is Linux-only, `getsockopt(SO_ACCEPTCONN)`
 * needs a listening socket whose fd numbers would differ. Two can be graded
 * exactly, and they happen to be the two carrying the subtler mistake.
 *
 * FCNTL: THE COMMAND AGREES AND THE VALUE DOES NOT. F_GETFL is 3 and F_SETFL
 * is 4 on both systems, which is what makes this look safe. But the argument
 * and the result are an O_* flag word, and ten of thirteen O_* flags differ:
 *
 *     O_NONBLOCK   Darwin 0x0004   Linux 0x0800
 *     O_APPEND     Darwin 0x0008   Linux 0x0400
 *
 * So a wrapper that passed the command through and stopped would set a
 * DIFFERENT flag -- and Darwin's O_NONBLOCK (0x0004) is not even unused on
 * Linux, so the descriptor ends up in some other mode with no error. This
 * fixture sets O_NONBLOCK through F_SETFL, reads it back through F_GETFL, and
 * checks the round trip by NAME. That only comes out right if both directions
 * translate.
 *
 * MADVISE: THE ONE ADVICE VALUE THAT DIFFERS IS THE ONE THAT GETS USED.
 *
 *     MADV_NORMAL 0  RANDOM 1  SEQUENTIAL 2  WILLNEED 3  DONTNEED 4   agree
 *     MADV_FREE   Darwin 5   Linux 8                                 differ
 *
 * An audit that probed the common range would call madvise a plain forward --
 * mine did -- and libdispatch's allocator calls it with MADV_FREE and nothing
 * else. Both are exercised below, so the fixture covers the case the census
 * missed as well as the four it did not.
 *
 * F_GETNOSIGPIPE and F_SETNOSIGPIPE are deliberately NOT here. They exist only
 * on Darwin, macOS answers them, and machorun returns ENOTSUP because Linux
 * has no per-fd SIGPIPE suppression at all -- so no oracle-matching fixture
 * can hold them. docs/UNIMPLEMENTED.md#fcntl-nosigpipe has that, for the same
 * reason POLLWRBAND is absent from poll and SIGEMT from sigaction.
 *
 * Nothing host-specific is printed: no descriptor numbers, no addresses, no
 * pointers. Identical on macOS and under machorun when the translation holds.
 */
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <string.h>
#include <errno.h>

static void show_flags(const char *label, int f)
{
    int first = 1;
    printf("  %-30s ", label);
#define F(b) if (f & b) { printf("%s%s", first ? "" : "|", #b); first = 0; }
    F(O_NONBLOCK) F(O_APPEND) F(O_ASYNC) F(O_SYNC) F(O_CLOEXEC)
#undef F
    if (first) printf("(none)");
    /* The access mode is separate: it is a 2-bit field, not a flag, and it is
     * the one part of the word that agrees on both systems. */
    printf("   accmode=%s\n",
           (f & O_ACCMODE) == O_RDONLY ? "O_RDONLY" :
           (f & O_ACCMODE) == O_WRONLY ? "O_WRONLY" :
           (f & O_ACCMODE) == O_RDWR   ? "O_RDWR"   : "?");
}

int main(void)
{
    int pfd[2], f, rc;
    void *page;
    long pagesz = sysconf(_SC_PAGESIZE);

    if (pipe(pfd) != 0) { puts("pipe failed"); return 1; }

    puts("== F_GETFL on a fresh pipe read end");
    f = fcntl(pfd[0], F_GETFL);
    if (f < 0) { puts("  F_GETFL failed"); return 1; }
    show_flags("initial", f);

    puts("== set O_NONBLOCK through F_SETFL and read it back");
    /* The load-bearing case. Darwin's O_NONBLOCK is 0x0004 and Linux's is
     * 0x0800; an untranslated F_SETFL would set Linux's 0x0004, which is not
     * O_NONBLOCK there, and the read-back would not show it. */
    rc = fcntl(pfd[0], F_SETFL, f | O_NONBLOCK);
    printf("  F_SETFL rc=%d\n", rc);
    f = fcntl(pfd[0], F_GETFL);
    show_flags("after setting O_NONBLOCK", f);
    printf("  O_NONBLOCK survived the round trip: %s\n",
           (f & O_NONBLOCK) ? "yes" : "no");

    puts("== and that it really took effect, not just read back");
    /* A read on an empty non-blocking pipe must fail with EAGAIN rather than
     * block. This is the behavioural half: the flag word could round-trip
     * through our own tables and still never have reached the kernel. */
    {
        char c;
        errno = 0;
        rc = (int)read(pfd[0], &c, 1);
        printf("  read on empty non-blocking pipe: rc=%d errno=%s\n",
               rc, errno == EAGAIN ? "EAGAIN" : errno == 0 ? "0" : "OTHER");
    }

    puts("== clear it again");
    f = fcntl(pfd[0], F_GETFL);
    rc = fcntl(pfd[0], F_SETFL, f & ~O_NONBLOCK);
    f = fcntl(pfd[0], F_GETFL);
    printf("  F_SETFL rc=%d  O_NONBLOCK now: %s\n", rc,
           (f & O_NONBLOCK) ? "yes" : "no");

    puts("== O_APPEND, a second flag that differs (0x0008 against 0x0400)");
    {
        int wf = fcntl(pfd[1], F_GETFL);
        rc = fcntl(pfd[1], F_SETFL, wf | O_APPEND);
        wf = fcntl(pfd[1], F_GETFL);
        printf("  F_SETFL rc=%d  O_APPEND survived: %s\n", rc,
               (wf & O_APPEND) ? "yes" : "no");
        show_flags("write end now", wf);
    }

    close(pfd[0]); close(pfd[1]);

    puts("== madvise across the whole advice range");
    page = mmap(NULL, (size_t)pagesz * 4, PROT_READ | PROT_WRITE,
                MAP_PRIVATE | MAP_ANON, -1, 0);
    if (page == MAP_FAILED) { puts("  mmap failed"); return 1; }
    memset(page, 0xA5, (size_t)pagesz * 4);

    /* The four that agree, as a control: if these ever start failing, the
     * problem is madvise itself and not the one translated value. */
    printf("  MADV_NORMAL     rc=%d\n", madvise(page, (size_t)pagesz, MADV_NORMAL));
    printf("  MADV_RANDOM     rc=%d\n", madvise(page, (size_t)pagesz, MADV_RANDOM));
    printf("  MADV_SEQUENTIAL rc=%d\n", madvise(page, (size_t)pagesz, MADV_SEQUENTIAL));
    printf("  MADV_WILLNEED   rc=%d\n", madvise(page, (size_t)pagesz, MADV_WILLNEED));

    /* THE ONE THAT DIFFERS, and the only one libdispatch uses. Darwin's 5
     * forwarded to Linux is an unassigned advice value, so an untranslated
     * call returns -1/EINVAL here and 0 on macOS. */
    errno = 0;
    rc = madvise(page, (size_t)pagesz, MADV_FREE);
    printf("  MADV_FREE       rc=%d  errno=%s\n", rc,
           rc == 0 ? "0" : errno == EINVAL ? "EINVAL" : "OTHER");

    munmap(page, (size_t)pagesz * 4);
    puts("done");
    return 0;
}
