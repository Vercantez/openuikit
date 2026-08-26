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
#include <sys/stat.h>
#include <sys/types.h>
#include <time.h>
#include <runetype.h>

#define SZ(t)      printf("sizeof %-28s %zu\n", #t, sizeof(t))
#define OFF(s, f)  printf("offset %-28s %zu\n", #s "." #f, offsetof(struct s, f))
#define VAL(m)     printf("value  %-28s %lld\n", #m, (long long)(m))

int main(void)
{
    puts("== fundamental types");
    SZ(void *); SZ(long); SZ(long long); SZ(size_t); SZ(ptrdiff_t);
    SZ(wchar_t); SZ(time_t); SZ(off_t); SZ(ino_t); SZ(dev_t); SZ(mode_t);
    SZ(nlink_t); SZ(blkcnt_t); SZ(blksize_t); SZ(uid_t); SZ(gid_t);
    SZ(va_list);

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
    puts("== open flags  (10 of 13 differ; Darwin's O_CREAT IS Linux's O_TRUNC)");
    VAL(O_RDONLY); VAL(O_WRONLY); VAL(O_RDWR);   VAL(O_ACCMODE);
    VAL(O_NONBLOCK); VAL(O_APPEND); VAL(O_CREAT); VAL(O_TRUNC);
    VAL(O_EXCL); VAL(O_NOCTTY); VAL(O_DIRECTORY); VAL(O_CLOEXEC);
    VAL(O_NOFOLLOW); VAL(O_SYNC);

    puts("");
    puts("== stat mode bits");
    VAL(S_IFMT); VAL(S_IFREG); VAL(S_IFDIR); VAL(S_IFLNK); VAL(S_IFBLK);
    VAL(S_IFCHR); VAL(S_IFIFO); VAL(S_IFSOCK);

    puts("");
    puts("== seek / stdio");
    VAL(SEEK_SET); VAL(SEEK_CUR); VAL(SEEK_END);
    VAL(EOF); VAL(BUFSIZ); VAL(FOPEN_MAX); VAL(FILENAME_MAX);

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
