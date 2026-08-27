/*
 * abi_probe.c -- print the ABI, not behaviour.
 *
 * This is the one new test docs/SDK_SURVEY.md §6.1 asked this milestone to buy,
 * and it earned its place before it was even written: staging xnu's published
 * sys/cdefs.h without selecting XNU_PLATFORM_MacOSX left
 * __DARWIN_ONLY_UNIX_CONFORMANCE undefined and MACH_VM_MAX_ADDRESS_RAW at the
 * embedded 64 GB value instead of macOS's 128 TB. Nothing failed to compile.
 * That is the whole risk in one sentence: the headers are ABI, and a vendored
 * header from the wrong revision moves a field or a constant silently.
 *
 * So this program prints numbers a compiler decided -- struct sizes, field
 * offsets, errno and O_* values, va_list's size -- and one thing a LINKER and a
 * LOADER decided: the first bytes of _DefaultRuneLocale, which Darwin's
 * <ctype.h> inlines a lookup into and which docs/ABI.md therefore calls part of
 * the ABI rather than an implementation detail.
 *
 * It is built TWICE, by scripts/sdk_abi_probe.sh:
 *   macOS, Apple clang, Apple's SDK, run natively   -> the oracle
 *   Linux, clang-18,   sdk/ headers + sdk/usr/lib .tbd stubs,
 *          linked by ld64.lld-18, run under machorun -> the answer
 * and the two outputs must be byte-identical.
 *
 * It is deliberately NOT in tests/bin. Those binaries are the precompiled
 * Darwin bytes the whole project exists to run and must keep coming from
 * Xcode (docs/SDK_SURVEY.md §6.3). This one is the opposite kind of artefact:
 * its entire point is to be compiled on both sides.
 */

#include <errno.h>
#include <fcntl.h>
#include <stdarg.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/signal.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <sys/stat.h>
#include <sys/mount.h>
#include <sys/sysctl.h>
#include <tzfile.h>
#include <dirent.h>
#include <poll.h>
#include <sched.h>
#include <pthread.h>
#include <sys/types.h>
#include <time.h>
#include <runetype.h>
#include <sys/cdefs.h>
#include <mach/vm_param.h>
#include <mach/machine/vm_param.h>

#define SZ(t)      printf("sizeof %-28s %zu\n", #t, sizeof(t))
#define OFF(s, f)  printf("offset %-28s %zu\n", #s "." #f, offsetof(struct s, f))
#define VAL(m)     printf("value  %-28s %lld\n", #m, (long long)(m))
#define HEX(m)     printf("value  %-28s 0x%016llx\n", #m, (unsigned long long)(m))
/* The suffix macros expand to NOTHING on macOS/arm64 and to a string literal
 * when the conformance settings are wrong, so they cannot be passed as an
 * expression -- "" m is the only spelling that survives both. */
#define STR(m)     printf("string %-28s \"%s\"\n", #m, "" m)

int main(void)
{
    puts("== fundamental types");
    SZ(void *); SZ(long); SZ(long long); SZ(size_t); SZ(ptrdiff_t);
    SZ(wchar_t); SZ(time_t); SZ(off_t); SZ(ino_t); SZ(dev_t); SZ(mode_t);
    SZ(nlink_t); SZ(blkcnt_t); SZ(blksize_t); SZ(uid_t); SZ(gid_t);
    SZ(va_list);

    puts("");
    puts("== struct kinfo_proc and struct tzhead  (CFUtilities, CFTimeZone)");
    SZ(struct kinfo_proc);
    OFF(kinfo_proc, kp_proc); OFF(kinfo_proc, kp_eproc);
    SZ(struct extern_proc);
    OFF(extern_proc, p_pid);  OFF(extern_proc, p_stat);
    OFF(extern_proc, p_comm); OFF(extern_proc, p_starttime);
    SZ(struct eproc);
    OFF(eproc, e_ppid); OFF(eproc, e_pgid); OFF(eproc, e_ucred);
    /* THE ONE FIELD CoreFoundation READS OUT OF kinfo_proc, and the reason it
     * is pinned here rather than trusted: darwin/src/posix.c mirrors this
     * offset BY HAND (it is compiled -nostdinc and cannot include this
     * header), which is the linux_stat shape. A wrong constant there writes
     * the saved set-user-ID into a neighbouring field and the value CF reads
     * is a zero it was never given.
     *
     * It cannot be caught by tests/bin/sysctl: the synthesized struct is
     * zeroed, so on a container running as root every offset reads 0 and the
     * fixture's uid check passes whatever the constant says. Measured that
     * directly -- a deliberately wrong offset passed the fixture. This pin and
     * the static assert below are what actually guard it. */
    printf("offset %-28s %zu\n", "kinfo_proc.p_svuid",
           offsetof(struct kinfo_proc, kp_eproc.e_pcred.p_svuid));
    _Static_assert(offsetof(struct kinfo_proc, kp_eproc.e_pcred.p_svuid) == 396,
        "kinfo_proc.kp_eproc.e_pcred.p_svuid moved; darwin/src/posix.c hard-codes "
        "396 in mr_sysctl_kinfo_proc() and cannot include this header to check");
    _Static_assert(sizeof(struct kinfo_proc) == 648,
        "struct kinfo_proc changed size; darwin/src/posix.c hard-codes 648");
    SZ(struct tzhead);
    OFF(tzhead, tzh_magic);    OFF(tzhead, tzh_version);
    OFF(tzhead, tzh_ttisgmtcnt); OFF(tzhead, tzh_ttisstdcnt);
    OFF(tzhead, tzh_leapcnt);  OFF(tzhead, tzh_timecnt);
    OFF(tzhead, tzh_typecnt);  OFF(tzhead, tzh_charcnt);
    printf("KERN_PROC_PID %d  KERN_PROC %d  CTL_KERN %d\n",
           KERN_PROC_PID, KERN_PROC, CTL_KERN);

    puts("");
    puts("== struct dirent and struct statfs  (CoreFoundation's, and $INODE64-sensitive)");
    SZ(struct dirent);
    OFF(dirent, d_ino); OFF(dirent, d_seekoff); OFF(dirent, d_reclen);
    OFF(dirent, d_namlen); OFF(dirent, d_type); OFF(dirent, d_name);
    SZ(struct statfs);
    OFF(statfs, f_bsize);  OFF(statfs, f_iosize); OFF(statfs, f_blocks);
    OFF(statfs, f_bfree);  OFF(statfs, f_bavail); OFF(statfs, f_files);
    OFF(statfs, f_ffree);  OFF(statfs, f_fsid);   OFF(statfs, f_owner);
    OFF(statfs, f_type);   OFF(statfs, f_flags);  OFF(statfs, f_fssubtype);
    OFF(statfs, f_fstypename); OFF(statfs, f_mntonname); OFF(statfs, f_mntfromname);

    puts("");
    puts("== struct stat  (docs/ABI.md: 144 bytes on Darwin, 128 on Linux)");
    SZ(struct stat);
    OFF(stat, st_dev);   OFF(stat, st_mode);  OFF(stat, st_nlink);
    OFF(stat, st_ino);   OFF(stat, st_uid);   OFF(stat, st_gid);
    OFF(stat, st_rdev);  OFF(stat, st_size);  OFF(stat, st_blocks);
    OFF(stat, st_blksize); OFF(stat, st_flags); OFF(stat, st_gen);
    OFF(stat, st_atimespec); OFF(stat, st_mtimespec); OFF(stat, st_ctimespec);
    OFF(stat, st_birthtimespec);
    SZ(struct timespec);
    OFF(timespec, tv_sec); OFF(timespec, tv_nsec);

    puts("");
    puts("== struct tm");
    SZ(struct tm);
    OFF(tm, tm_sec); OFF(tm, tm_min);  OFF(tm, tm_hour); OFF(tm, tm_mday);
    OFF(tm, tm_mon); OFF(tm, tm_year); OFF(tm, tm_wday); OFF(tm, tm_yday);
    OFF(tm, tm_isdst); OFF(tm, tm_gmtoff); OFF(tm, tm_zone);

    puts("");
    puts("== errno  (54 of 87 shared names differ from Linux; EAGAIN and");
    puts("==         EDEADLK hold each other's numbers)");
    VAL(EPERM); VAL(ENOENT); VAL(ESRCH); VAL(EINTR); VAL(EIO); VAL(ENXIO);
    VAL(E2BIG); VAL(ENOEXEC); VAL(EBADF); VAL(ECHILD); VAL(EDEADLK);
    VAL(ENOMEM); VAL(EACCES); VAL(EFAULT); VAL(EBUSY); VAL(EEXIST);
    VAL(EXDEV); VAL(ENODEV); VAL(ENOTDIR); VAL(EISDIR); VAL(EINVAL);
    VAL(ENFILE); VAL(EMFILE); VAL(ENOTTY); VAL(EFBIG); VAL(ENOSPC);
    VAL(ESPIPE); VAL(EROFS); VAL(EMLINK); VAL(EPIPE); VAL(EDOM);
    VAL(ERANGE); VAL(EAGAIN); VAL(EWOULDBLOCK); VAL(EINPROGRESS);
    VAL(ENOTSOCK); VAL(EOPNOTSUPP); VAL(ELOOP); VAL(ENAMETOOLONG);
    VAL(ENOTEMPTY); VAL(EOVERFLOW); VAL(ECANCELED); VAL(EIDRM);
    VAL(ENOTSUP); VAL(ETIMEDOUT); VAL(ENOSYS);

    puts("");
    puts("== signals  (9 of 28 shared names differ from Linux, and three form a");
    puts("==           CYCLE: Darwin SIGCONT 19 / SIGCHLD 20 against Linux 18 / 17,");
    puts("==           so a forwarded number does not merely miss, it names a");
    puts("==           different real signal. Nothing forwards one today.)");
    VAL(SIGHUP); VAL(SIGINT); VAL(SIGQUIT); VAL(SIGILL); VAL(SIGTRAP);
    VAL(SIGABRT); VAL(SIGFPE); VAL(SIGKILL); VAL(SIGBUS); VAL(SIGSEGV);
    VAL(SIGSYS); VAL(SIGPIPE); VAL(SIGALRM); VAL(SIGTERM); VAL(SIGURG);
    VAL(SIGSTOP); VAL(SIGTSTP); VAL(SIGCONT); VAL(SIGCHLD); VAL(SIGTTIN);
    VAL(SIGTTOU); VAL(SIGXCPU); VAL(SIGXFSZ); VAL(SIGVTALRM); VAL(SIGPROF);
    VAL(SIGWINCH); VAL(SIGUSR1); VAL(SIGUSR2);
    VAL(SIG_BLOCK); VAL(SIG_UNBLOCK); VAL(SIG_SETMASK);
    VAL(SA_RESTART); VAL(SA_SIGINFO); VAL(SA_NOCLDSTOP);
    /* NOT ONE sa_flags BIT AGREES WITH LINUX, and the low ones collide with
     * live Linux flags rather than with nothing: Darwin's SA_RESTART (0x02) is
     * glibc's SA_NOCLDWAIT, and Darwin's SA_ONSTACK (0x01) is its
     * SA_NOCLDSTOP. darwin/src/posix.c translates all seven. */
    VAL(SA_ONSTACK); VAL(SA_RESETHAND); VAL(SA_NODEFER); VAL(SA_NOCLDWAIT);
    VAL(SIG_DFL); VAL(SIG_IGN);
    /* struct sigaction is 16 bytes here and 152 on Linux, and sa_mask is a
     * 4-byte sigset_t BY VALUE inside it -- so the whole layout differs, not
     * one field, and `oact` is an OUT parameter. */
    SZ(struct sigaction); SZ(siginfo_t);
    OFF(sigaction, sa_mask); OFF(sigaction, sa_flags);

    puts("");
    puts("== clock ids  (darwin/src/posix.c translates these; both tables are hand-written)");
    VAL(CLOCK_REALTIME); VAL(CLOCK_MONOTONIC); VAL(CLOCK_MONOTONIC_RAW);
    VAL(CLOCK_MONOTONIC_RAW_APPROX); VAL(CLOCK_UPTIME_RAW); VAL(CLOCK_UPTIME_RAW_APPROX);
    VAL(CLOCK_PROCESS_CPUTIME_ID); VAL(CLOCK_THREAD_CPUTIME_ID);

    puts("");
    puts("== poll  (POLLWRNORM and POLLWRBAND differ from Linux, and Darwin's");
    puts("==        POLLWRBAND 0x0100 IS Linux's POLLWRNORM, so a forwarded");
    puts("==        events word subscribes to a real but different condition.");
    puts("==        nfds_t is the other half: 4 here, 8 on Linux, in a 64-bit");
    puts("==        argument slot. darwin/src/posix.c translates both.)");
    VAL(POLLIN); VAL(POLLPRI); VAL(POLLOUT); VAL(POLLERR); VAL(POLLHUP);
    VAL(POLLNVAL); VAL(POLLRDNORM); VAL(POLLRDBAND); VAL(POLLWRNORM);
    VAL(POLLWRBAND); VAL(POLLEXTEND); VAL(POLLATTRIB); VAL(POLLNLINK);
    VAL(POLLWRITE);
    SZ(nfds_t); SZ(struct pollfd);
    OFF(pollfd, fd); OFF(pollfd, events); OFF(pollfd, revents);

    puts("");
    puts("== socket constants  (SOL_SOCKET is 65535 on Darwin and 1 on Linux --");
    puts("==                    and 1 IS a valid level on Linux, so a forwarded");
    puts("==                    setsockopt would set an option at the wrong level");
    puts("==                    rather than failing. Every SO_* differs too.)");
    VAL(AF_UNIX); VAL(AF_INET); VAL(AF_INET6);
    VAL(SOCK_STREAM); VAL(SOCK_DGRAM);
    VAL(SOL_SOCKET); VAL(SO_REUSEADDR); VAL(SO_KEEPALIVE); VAL(SO_BROADCAST);
    VAL(SO_SNDBUF); VAL(SO_RCVBUF); VAL(SO_ERROR); VAL(SO_LINGER);
    VAL(SHUT_RD); VAL(SHUT_WR); VAL(SHUT_RDWR);
    VAL(MSG_PEEK); VAL(MSG_OOB); VAL(IPPROTO_TCP); VAL(IPPROTO_UDP);

    puts("");
    puts("== open flags  (10 of 13 differ; Darwin's O_CREAT IS Linux's O_TRUNC)");
    VAL(O_RDONLY); VAL(O_WRONLY); VAL(O_RDWR);   VAL(O_ACCMODE);
    VAL(O_NONBLOCK); VAL(O_APPEND); VAL(O_CREAT); VAL(O_TRUNC);
    VAL(O_EXCL); VAL(O_NOCTTY); VAL(O_DIRECTORY); VAL(O_CLOEXEC);
    VAL(O_NOFOLLOW); VAL(O_SYNC);

    puts("");
    puts("== fcntl commands  (the five a run loop uses agree; the other five are");
    puts("==                  ROTATED INTO EACH OTHER. Darwin's F_GETLK is Linux's");
    puts("==                  F_SETLKW, so ASKING whether a lock is held instead");
    puts("==                  ACQUIRES it and blocks. Not forwarded -- see");
    puts("==                  docs/UNIMPLEMENTED.md#not-a-plain-forward.)");
    VAL(F_DUPFD); VAL(F_GETFD); VAL(F_SETFD); VAL(F_GETFL); VAL(F_SETFL);
    VAL(F_GETLK); VAL(F_SETLK); VAL(F_SETLKW); VAL(F_GETOWN); VAL(F_SETOWN);
    SZ(struct flock);

    puts("");
    puts("== scheduling  (SCHED_OTHER is 1 here and 0 on Linux, and Darwin's 1 IS");
    puts("==              Linux's SCHED_FIFO -- so a guest asking for the NORMAL");
    puts("==              scheduler would be made real-time. Not forwarded.)");
    VAL(SCHED_OTHER); VAL(SCHED_FIFO); VAL(SCHED_RR);
    SZ(struct sched_param); SZ(pthread_attr_t);
    /* The detach state is OFF BY ONE, the same worst-case spacing as
     * SIG_BLOCK: Darwin's JOINABLE (1) is glibc's DETACHED, so a forward
     * yields a thread the guest cannot join, and only the DETACHED direction
     * fails loudly. darwin/src/posix.c translates. */
    VAL(PTHREAD_CREATE_JOINABLE); VAL(PTHREAD_CREATE_DETACHED);

    puts("");
    puts("== stat mode bits");
    VAL(S_IFMT); VAL(S_IFREG); VAL(S_IFDIR); VAL(S_IFLNK); VAL(S_IFBLK);
    VAL(S_IFCHR); VAL(S_IFIFO); VAL(S_IFSOCK);

    puts("");
    puts("== seek / stdio");
    VAL(SEEK_SET); VAL(SEEK_CUR); VAL(SEEK_END);
    VAL(EOF); VAL(BUFSIZ); VAL(FOPEN_MAX); VAL(FILENAME_MAX);

    /* THE per-product #ifdef check, and the reason this section exists.
     *
     * xnu publishes one header for every Apple product and gates the settings
     * on XNU_PLATFORM_<name>; Apple's install step resolves them with unifdef,
     * and sdk/patches/0002-xnu-platform-macosx.patch is how we do it instead.
     * Get that wrong and NOTHING FAILS TO COMPILE -- the numbers are simply the
     * embedded ones.  Verified 2026-08-26 by mutation: before these five lines
     * existed, forcing MACH_VM_MAX_ADDRESS_RAW to the 64 GB value passed
     * build_objc4 (32 objects), gen_tbd (all three checks), this probe and the
     * 44-test corpus (41/44).  Nothing in the repository noticed.  Now this
     * does, and it does so against Apple's own SDK rather than against a
     * number somebody typed in here. */
    puts("");
    puts("== per-product settings  (xnu gates these on XNU_PLATFORM_<name>;");
    puts("==   getting it wrong is silent -- sdk/patches/0002 selects MacOSX)");
    HEX(MACH_VM_MIN_ADDRESS_RAW);
    HEX(MACH_VM_MAX_ADDRESS_RAW);   /* macOS 128 TB, embedded 64 GB */
    HEX(MACH_VM_MIN_ADDRESS);
    HEX(MACH_VM_MAX_ADDRESS);
    HEX(VM_MIN_ADDRESS);
    HEX(VM_MAX_ADDRESS);
    VAL(__DARWIN_ONLY_UNIX_CONFORMANCE);
    VAL(__DARWIN_ONLY_64_BIT_INO_T);
    VAL(__DARWIN_ONLY_VERS_1050);
    STR(__DARWIN_SUF_UNIX03);       /* "" on macOS/arm64; "$UNIX2003" if unset */
    STR(__DARWIN_SUF_64_BIT_INO_T);

    /* _DefaultRuneLocale is not a compile-time fact: Darwin's <ctype.h> inlines
     * a lookup into this table, so its bytes are bound at LINK time out of
     * libSystem and read at RUN time by the guest. Printing them tests the
     * .tbd, the loader's data-symbol binding and the table's contents at once.
     * docs/ABI.md records why it is copied from Apple rather than rebuilt. */
    puts("");
    puts("== _DefaultRuneLocale  (a DATA ABI, resolved through the .tbd)");
    printf("sizeof %-28s %zu\n", "_RuneLocale", sizeof(_RuneLocale));
    printf("magic  %-28s %.8s\n", "_DefaultRuneLocale.magic", _DefaultRuneLocale.__magic);
    printf("encode %-28s %s\n", "_DefaultRuneLocale.encoding", _DefaultRuneLocale.__encoding);
    printf("runetype[0..15]             ");
    for (int i = 0; i < 16; i++)
        printf("%08x%s", (unsigned)_DefaultRuneLocale.__runetype[i], i == 15 ? "\n" : " ");
    printf("maplower['A'..'F']          ");
    for (int i = 'A'; i <= 'F'; i++)
        printf("%d%s", (int)_DefaultRuneLocale.__maplower[i], i == 'F' ? "\n" : " ");

    puts("");
    puts("== variadic ABI  (Darwin passes EVERY variadic argument on the stack");
    puts("==                with an 8-byte va_list; Linux uses x1-x7/v0-v7 and 32)");
    printf("%d %ld %lld %.2f %s %c\n", 1, 2L, 3LL, 4.5, "five", '6');

    return 0;
}
