/* dsys.h -- the shared floor of our Darwin userland.
 *
 * Every .c file under darwin/src/ is compiled for arm64-apple-macos with
 * -nostdinc: there is no macOS SDK on the build host, and glibc's headers are
 * not compilable for a Darwin target. So everything is declared here.
 *
 * THE GLIBC BOUNDARY IS EXPLICIT. Every glibc function is declared with an asm
 * label of the form _glibc_<name>; machorun's resolver turns that into
 * dlsym(RTLD_DEFAULT, "<name>"). Without the rename our own forwarder `puts`
 * would be its own callee -- infinite recursion -- and the boundary would be
 * invisible in `nm`. With it, `nm -u` on the dylib IS the list of everything
 * we borrow from Linux.
 *
 * Types are DARWIN's, because the guest was compiled against Darwin's headers
 * and its struct layouts are not ours to renegotiate. Where Linux disagrees
 * (struct stat, errno values, O_* bits, CLOCK_* ids) the translation happens
 * on this side of the call. docs/ABI.md has the measurements.
 */
#ifndef MACHORUN_DSYS_H
#define MACHORUN_DSYS_H

typedef unsigned long      size_t;
typedef long               ssize_t;
typedef unsigned long      uintptr_t;
typedef long               intptr_t;
typedef unsigned char      uint8_t;
typedef unsigned short     uint16_t;
typedef unsigned int       uint32_t;
typedef unsigned long long uint64_t;
typedef int                int32_t;
typedef long long          int64_t;
typedef long               off_t;
typedef long               time_t;
typedef __builtin_va_list  va_list;
#define va_start __builtin_va_start
#define va_end   __builtin_va_end
#define va_arg   __builtin_va_arg
#define va_copy  __builtin_va_copy
#define NULL ((void *)0)

#define GLIBCSYM(n) __asm__("_glibc_" #n)

/* Defined by build/machorun, not by glibc and not by a dylib -- src/resolve.c
 * strips the leading underscore and dlsyms it out of the loader, the same path
 * the _dyld_* surface takes. Registered in darwin/loader-exports.txt. */
extern void mr_report_backtrace(const char *why);
extern void mr_report_memory(const void *addr, unsigned before, unsigned after);
extern void mr_guard_arm(const void *word);
extern void mr_guard_disarm(const void *word);
#define EXPORT __attribute__((visibility("default")))
#define HIDDEN __attribute__((visibility("hidden")))

/* ---------------------------------------------------------- memory, string */
extern void  *glibc_malloc(size_t)                          GLIBCSYM(malloc);
extern void  *glibc_calloc(size_t, size_t)                  GLIBCSYM(calloc);
extern int    glibc_sigemptyset(void *)                      GLIBCSYM(sigemptyset);
extern int    glibc_sigsuspend(const void *)                GLIBCSYM(sigsuspend);
extern int    glibc_sigpending(void *)                      GLIBCSYM(sigpending);
extern int    glibc_sigwait(const void *, int *)            GLIBCSYM(sigwait);
extern int    glibc_sigaddset(void *, int)                  GLIBCSYM(sigaddset);
extern int    glibc_sigismember(const void *, int)          GLIBCSYM(sigismember);
extern int    glibc_pthread_sigmask(int, const void *, void *) GLIBCSYM(pthread_sigmask);
extern int    glibc_sigprocmask(int, const void *, void *)  GLIBCSYM(sigprocmask);
extern int    glibc_signalfd(int, const void *, int)        GLIBCSYM(signalfd);
/* All four take a SIGNAL NUMBER, and ten of the 31 are numbered differently on
 * the two systems -- so none of these may be reached except through the
 * translation in darwin/src/posix.c. `struct sigaction` is void* here for the
 * same reason struct stat is: glibc's is 152 bytes against Darwin's 16. */
extern int    glibc_sigaction(int, const void *, void *)    GLIBCSYM(sigaction);
extern int    glibc_pthread_kill(unsigned long, int)        GLIBCSYM(pthread_kill);
extern int    glibc_kill(int, int)                          GLIBCSYM(kill);
extern int    glibc_raise(int)                              GLIBCSYM(raise);
/* poll's second argument is glibc's nfds_t -- unsigned LONG, where Darwin's is
 * unsigned INT.  Spelled out here rather than left to a header so the width
 * conversion happens at the call, in view of the cast. darwin/src/posix.c has
 * the account of why a 4-byte value in a 64-bit argument slot is not benign. */
extern int    glibc_poll(void *, unsigned long, int)        GLIBCSYM(poll);
extern int    glibc_ppoll(void *, unsigned long, const void *,
                          const void *)                     GLIBCSYM(ppoll);
extern void  *glibc_bsearch(const void *, const void *, size_t, size_t,
                            int (*)(const void *, const void *)) GLIBCSYM(bsearch);
extern char  *glibc_strncat(char *, const char *, size_t)   GLIBCSYM(strncat);
extern size_t glibc_strnlen(const char *, size_t)           GLIBCSYM(strnlen);
extern int    glibc_strncasecmp(const char *, const char *, size_t) GLIBCSYM(strncasecmp);
extern char  *glibc_strtok(char *, const char *)            GLIBCSYM(strtok);
extern char  *glibc_strtok_r(char *, const char *, char **) GLIBCSYM(strtok_r);
extern int    glibc_dlclose(void *)                         GLIBCSYM(dlclose);
/* DATA, not functions: glibc's tzset() fills these and a guest reads them.
 * Forwarding a data symbol works the same way -- machorun resolves the
 * _glibc_ alias with dlsym, which finds objects as well as functions. */
extern long   glibc_tz_timezone                             GLIBCSYM(timezone);
extern int    glibc_tz_daylight                             GLIBCSYM(daylight);
extern char  *glibc_tz_tzname[2]                            GLIBCSYM(tzname);
/* glibc's own environ, as DATA. The guest's `environ` must be kept equal to
 * this or the two spellings of "the environment" diverge -- see the setenv
 * family in darwin/src/libsystem.c. */
extern char **glibc_environ                                 GLIBCSYM(environ);
extern int    glibc_setenv(const char *, const char *, int) GLIBCSYM(setenv);
extern int    glibc_unsetenv(const char *)                  GLIBCSYM(unsetenv);
extern int    glibc_putenv(char *)                          GLIBCSYM(putenv);
extern void  *glibc_opendir(const char *)                   GLIBCSYM(opendir);
extern void  *glibc_readdir(void *)                         GLIBCSYM(readdir);
extern int    glibc_closedir(void *)                        GLIBCSYM(closedir);
extern void   glibc_rewinddir(void *)                       GLIBCSYM(rewinddir);
extern int    glibc_dirfd(void *)                           GLIBCSYM(dirfd);
typedef int (*glibc_fts_compar_fn)(const void *, const void *);
extern void  *glibc_fts_open(char *const *, int,
                             glibc_fts_compar_fn)           GLIBCSYM(fts_open);
extern void  *glibc_fts_read(void *)                        GLIBCSYM(fts_read);
extern void  *glibc_fts_children(void *, int)               GLIBCSYM(fts_children);
extern int    glibc_fts_set(void *, void *, int)            GLIBCSYM(fts_set);
extern int    glibc_fts_close(void *)                       GLIBCSYM(fts_close);
extern void  *glibc_realloc(void *, size_t)                 GLIBCSYM(realloc);
extern void   glibc_free(void *)                            GLIBCSYM(free);
extern int    glibc_posix_memalign(void **, size_t, size_t) GLIBCSYM(posix_memalign);
extern void  *glibc_aligned_alloc(size_t, size_t)           GLIBCSYM(aligned_alloc);
extern size_t glibc_malloc_usable_size(void *)              GLIBCSYM(malloc_usable_size);

extern size_t glibc_strlen(const char *)                    GLIBCSYM(strlen);
extern size_t glibc_wcslen(const int *)                      GLIBCSYM(wcslen);
extern int   *glibc_wmemchr(const int *, int, size_t)       GLIBCSYM(wmemchr);
extern char  *glibc_strcpy(char *, const char *)            GLIBCSYM(strcpy);
extern char  *glibc_strncpy(char *, const char *, size_t)   GLIBCSYM(strncpy);
extern char  *glibc_strcat(char *, const char *)            GLIBCSYM(strcat);
extern int    glibc_strcmp(const char *, const char *)      GLIBCSYM(strcmp);
extern int    glibc_strncmp(const char *, const char *, size_t) GLIBCSYM(strncmp);
extern char  *glibc_strchr(const char *, int)               GLIBCSYM(strchr);
extern char  *glibc_strrchr(const char *, int)              GLIBCSYM(strrchr);
extern char  *glibc_strstr(const char *, const char *)      GLIBCSYM(strstr);
extern char  *glibc_strdup(const char *)                    GLIBCSYM(strdup);
extern void  *glibc_memcpy(void *, const void *, size_t)    GLIBCSYM(memcpy);
extern void  *glibc_memmove(void *, const void *, size_t)   GLIBCSYM(memmove);
extern void  *glibc_memset(void *, int, size_t)             GLIBCSYM(memset);
extern int    glibc_memcmp(const void *, const void *, size_t) GLIBCSYM(memcmp);
extern void  *glibc_memchr(const void *, int, size_t)       GLIBCSYM(memchr);

/* --------------------------------------------------------------- stdio, fd */
extern int    glibc_puts(const char *)                      GLIBCSYM(puts);
extern int    glibc_putchar(int)                            GLIBCSYM(putchar);
extern size_t glibc_fwrite(const void *, size_t, size_t, void *) GLIBCSYM(fwrite);
extern size_t glibc_fread(void *, size_t, size_t, void *)   GLIBCSYM(fread);
extern int    glibc_fflush(void *)                          GLIBCSYM(fflush);
extern void  *glibc_fopen(const char *, const char *)       GLIBCSYM(fopen);
extern int    glibc_fclose(void *)                          GLIBCSYM(fclose);
extern int    glibc_fputs(const char *, void *)             GLIBCSYM(fputs);
extern int    glibc_fputc(int, void *)                      GLIBCSYM(fputc);
extern int    glibc_fgetc(void *)                           GLIBCSYM(fgetc);
extern int    glibc_ferror(void *)                          GLIBCSYM(ferror);
extern int    glibc_feof(void *)                            GLIBCSYM(feof);
extern int    glibc_fileno(void *)                          GLIBCSYM(fileno);
extern int    glibc_fseek(void *, long, int)                GLIBCSYM(fseek);
extern long   glibc_ftell(void *)                           GLIBCSYM(ftell);
extern int    glibc_ungetc(int, void *)                     GLIBCSYM(ungetc);
extern void   glibc_rewind(void *)                          GLIBCSYM(rewind);
/* POSIX getline. Darwin's FILE is 152 bytes (sdk/_stdio.h __sFILE) against
 * glibc aarch64's 216, but the FILE* a guest can hold is glibc's object:
 * fopen is forwarded and __stdinp/out/err are re-pointed at bootstrap. */
extern ssize_t glibc_getline(char **, size_t *, void *)     GLIBCSYM(getline);
extern void  *glibc_stdout GLIBCSYM(stdout);
extern void  *glibc_stderr GLIBCSYM(stderr);
extern void  *glibc_stdin  GLIBCSYM(stdin);

extern ssize_t glibc_write(int, const void *, size_t)       GLIBCSYM(write);
extern ssize_t glibc_read(int, void *, size_t)              GLIBCSYM(read);
extern int     glibc_close(int)                             GLIBCSYM(close);
/* glibc's open is variadic; declaring it with the exact non-variadic shape we
 * call it with is the safe crossing (docs/ABI.md §"the one legal crossing"):
 * an AAPCS64 variadic callee spills x0-x7 to its save area on entry, so
 * ordinary argument passing lands exactly where its va_arg looks. */
extern int     glibc_open(const char *, int, unsigned)      GLIBCSYM(open);
extern off_t   glibc_lseek(int, off_t, int)                 GLIBCSYM(lseek);
extern ssize_t glibc_getxattr(const char *, const char *, void *, size_t)   GLIBCSYM(getxattr);
extern ssize_t glibc_lgetxattr(const char *, const char *, void *, size_t)  GLIBCSYM(lgetxattr);
extern ssize_t glibc_fgetxattr(int, const char *, void *, size_t)           GLIBCSYM(fgetxattr);
extern int     glibc_setxattr(const char *, const char *, const void *, size_t, int)  GLIBCSYM(setxattr);
extern int     glibc_lsetxattr(const char *, const char *, const void *, size_t, int) GLIBCSYM(lsetxattr);
extern int     glibc_fsetxattr(int, const char *, const void *, size_t, int)          GLIBCSYM(fsetxattr);
extern int     glibc_removexattr(const char *, const char *)                GLIBCSYM(removexattr);
extern int     glibc_lremovexattr(const char *, const char *)               GLIBCSYM(lremovexattr);
extern int     glibc_fremovexattr(int, const char *)                        GLIBCSYM(fremovexattr);
extern ssize_t glibc_listxattr(const char *, char *, size_t)                GLIBCSYM(listxattr);
extern ssize_t glibc_llistxattr(const char *, char *, size_t)               GLIBCSYM(llistxattr);
extern ssize_t glibc_flistxattr(int, char *, size_t)                        GLIBCSYM(flistxattr);
extern void   *glibc_getgrnam(const char *)                  GLIBCSYM(getgrnam);
extern void   *glibc_getgrgid(unsigned)                      GLIBCSYM(getgrgid);
extern int     glibc_getgrnam_r(const char *, void *, char *, size_t, void **) GLIBCSYM(getgrnam_r);
extern int     glibc_getgrgid_r(unsigned, void *, char *, size_t, void **)     GLIBCSYM(getgrgid_r);
extern int     glibc_gettid(void)                            GLIBCSYM(gettid);
extern int     glibc_vsnprintf(char *, size_t, const char *, va_list) GLIBCSYM(vsnprintf);
extern int     glibc_uname(void *)                           GLIBCSYM(uname);
extern int     glibc_stat(const char *, void *)             GLIBCSYM(stat);
extern int     glibc_lstat(const char *, void *)            GLIBCSYM(lstat);
extern int     glibc_fstat(int, void *)                     GLIBCSYM(fstat);
extern int     glibc_mkdir(const char *, unsigned)          GLIBCSYM(mkdir);
extern int     glibc_mkfifo(const char *, unsigned)         GLIBCSYM(mkfifo);
extern int     glibc_rmdir(const char *)                    GLIBCSYM(rmdir);
extern int     glibc_unlink(const char *)                   GLIBCSYM(unlink);
extern int     glibc_rename(const char *, const char *)     GLIBCSYM(rename);
extern int     glibc_access(const char *, int)              GLIBCSYM(access);
extern int     glibc_chmod(const char *, unsigned)          GLIBCSYM(chmod);
extern int     glibc_symlink(const char *, const char *)    GLIBCSYM(symlink);
extern ssize_t glibc_readlink(const char *, char *, size_t) GLIBCSYM(readlink);
extern int     glibc_ftruncate(int, off_t)                  GLIBCSYM(ftruncate);
extern int     glibc_fsync(int)                             GLIBCSYM(fsync);
extern int     glibc_dup(int)                               GLIBCSYM(dup);
extern int     glibc_dup2(int, int)                         GLIBCSYM(dup2);
extern int     glibc_pipe(int *)                            GLIBCSYM(pipe);
/* getresuid(2) is how Linux answers "what is the SAVED set-user-ID". Darwin
 * answers the same question through sysctl(KERN_PROC), which is why this is
 * here -- see the sysctl section in darwin/src/posix.c. */
extern int     glibc_getresuid(unsigned *, unsigned *, unsigned *) GLIBCSYM(getresuid);
extern int     glibc_chown(const char *, unsigned, unsigned) GLIBCSYM(chown);
extern int     glibc_gethostname(char *, size_t)            GLIBCSYM(gethostname);
extern int     glibc_readdir_r(void *, void *, void **)     GLIBCSYM(readdir_r);
extern int     glibc_getrlimit(int, void *)                 GLIBCSYM(getrlimit);
extern int     glibc_setrlimit(int, const void *)           GLIBCSYM(setrlimit);
extern long    glibc_writev(int, const void *, int)         GLIBCSYM(writev);
extern int     glibc_pthread_attr_setscope(void *, int)     GLIBCSYM(pthread_attr_setscope);
extern int     glibc_pthread_attr_getscope(const void *, int *) GLIBCSYM(pthread_attr_getscope);
/* pthread_atfork IS NOT A DYNAMIC SYMBOL IN GLIBC. It lives in
 * libc_nonshared.a as a static wrapper over __register_atfork, so dlsym finds
 * nothing and a plain forward fails at RUNTIME with an undefined symbol rather
 * than at link. See pthread_atfork() in darwin/src/posix.c. */
extern int     glibc___register_atfork(void (*)(void), void (*)(void),
                                       void (*)(void), void *) GLIBCSYM(__register_atfork);
extern int      glibc_geteuid(void)                          GLIBCSYM(geteuid);
extern int      glibc_getegid(void)                          GLIBCSYM(getegid);
/* fcntl and ioctl are VARIADIC in glibc and are declared NON-variadic here on
 * purpose. Darwin's arm64 ABI puts variadic arguments on the STACK where
 * AAPCS64 puts the first eight in REGISTERS, so a variadic call from our
 * Darwin-compiled code into glibc would have glibc read a register as the
 * argument -- silent corruption rather than a wrong value. Both real callers
 * pass a fixed arity, so a fixed-arity declaration is both correct and the
 * thing that makes the mismatch impossible to write. */
extern int     glibc_fcntl(int, int, long)                  GLIBCSYM(fcntl);
extern int     glibc_ioctl(int, unsigned long, void *)      GLIBCSYM(ioctl);
extern int     glibc_getsockopt(int, int, int, void *, unsigned *) GLIBCSYM(getsockopt);
extern int     glibc_madvise(void *, size_t, int)           GLIBCSYM(madvise);
extern long    glibc_pwrite(int, const void *, size_t, long) GLIBCSYM(pwrite);
extern int     glibc_pthread_attr_init(void *)              GLIBCSYM(pthread_attr_init);
extern int     glibc_pthread_attr_destroy(void *)           GLIBCSYM(pthread_attr_destroy);
extern int     glibc_pthread_attr_setschedparam(void *, const void *)
                                                            GLIBCSYM(pthread_attr_setschedparam);
extern int     glibc_pthread_attr_getschedparam(const void *, void *)
                                                            GLIBCSYM(pthread_attr_getschedparam);
extern int     glibc_pthread_attr_setschedpolicy(void *, int) GLIBCSYM(pthread_attr_setschedpolicy);
extern int     glibc_pthread_attr_getschedpolicy(const void *, int *)
                                                            GLIBCSYM(pthread_attr_getschedpolicy);
extern int     glibc_pthread_attr_setdetachstate(void *, int) GLIBCSYM(pthread_attr_setdetachstate);
extern int     glibc_pthread_attr_getdetachstate(const void *, int *)
                                                            GLIBCSYM(pthread_attr_getdetachstate);
extern int     glibc_pthread_attr_getstacksize(const void *, size_t *)
                                                            GLIBCSYM(pthread_attr_getstacksize);
extern int     glibc_pthread_attr_setstacksize(void *, size_t) GLIBCSYM(pthread_attr_setstacksize);
/* GNU extensions, not Darwin names. pthread_getattr_np is in aarch64
 * libc.so.6 (pthread_getattr_np@@GLIBC_2.32); Darwin has no counterpart
 * under that spelling. Used only to implement pthread_get_stack*_np. */
extern int     glibc_pthread_getattr_np(unsigned long, void *)
                                                            GLIBCSYM(pthread_getattr_np);
extern int     glibc_pthread_attr_getstack(const void *, void **, size_t *)
                                                            GLIBCSYM(pthread_attr_getstack);
extern int     glibc_pthread_setschedparam(unsigned long, int, const void *)
                                                            GLIBCSYM(pthread_setschedparam);
extern void    glibc_pthread_exit(void *)                   GLIBCSYM(pthread_exit);
/* syscall(2) is VARIADIC in its C prototype and is not a variadic FUNCTION on
 * aarch64: glibc's is hand-written assembly that expects the number in x0 and
 * six arguments in x1..x6, which is plain AAPCS register passing. Declaring it
 * FIXED-ARITY here is therefore both correct and the thing that makes the
 * Darwin-varargs-on-the-stack mismatch impossible to write. It is deliberately
 * NOT re-exported to guests -- see futex() in darwin/src/posix.c. */
extern long    glibc_syscall(long, long, long, long, long, long, long)
                                                            GLIBCSYM(syscall);
extern int     glibc_isatty(int)                            GLIBCSYM(isatty);
extern char   *glibc_getcwd(char *, size_t)                 GLIBCSYM(getcwd);
extern int     glibc_chdir(const char *)                    GLIBCSYM(chdir);
extern int     glibc_mkstemp(char *)                        GLIBCSYM(mkstemp);
extern char   *glibc_mkdtemp(char *)                        GLIBCSYM(mkdtemp);

/* ------------------------------------------------------------- process, os */
extern int     glibc_getpid(void)                           GLIBCSYM(getpid);
extern void    glibc_abort(void)                            GLIBCSYM(abort);
extern void    glibc_exit(int)                              GLIBCSYM(exit);
extern void    glibc__exit(int)                             GLIBCSYM(_exit);
extern int    *glibc___errno_location(void)                 GLIBCSYM(__errno_location);
extern char   *glibc_strerror(int)                          GLIBCSYM(strerror);
extern int     glibc_atoi(const char *)                     GLIBCSYM(atoi);
extern long    glibc_strtol(const char *, char **, int)     GLIBCSYM(strtol);
extern unsigned long glibc_strtoul(const char *, char **, int) GLIBCSYM(strtoul);
extern long long glibc_strtoll(const char *, char **, int)  GLIBCSYM(strtoll);
extern double  glibc_strtod(const char *, char **)          GLIBCSYM(strtod);
extern float   glibc_strtof(const char *, char **)          GLIBCSYM(strtof);
extern void    glibc_qsort(void *, size_t, size_t, int (*)(const void *, const void *)) GLIBCSYM(qsort);
extern char   *glibc_getenv(const char *)                   GLIBCSYM(getenv);
extern time_t  glibc_time(time_t *)                         GLIBCSYM(time);
extern int     glibc_clock_gettime(int, void *)             GLIBCSYM(clock_gettime);
extern int     glibc_gettimeofday(void *, void *)           GLIBCSYM(gettimeofday);
extern int     glibc_nanosleep(const void *, void *)        GLIBCSYM(nanosleep);
extern int     glibc_usleep(unsigned)                       GLIBCSYM(usleep);
extern unsigned glibc_sleep(unsigned)                       GLIBCSYM(sleep);
extern int     glibc_sched_yield(void)                      GLIBCSYM(sched_yield);
extern long    glibc_sysconf(int)                           GLIBCSYM(sysconf);
extern void   *glibc_getpwnam(const char *)                 GLIBCSYM(getpwnam);
extern void   *glibc_getpwuid(unsigned)                     GLIBCSYM(getpwuid);
extern int     glibc_getpwnam_r(const char *, void *, char *, size_t, void **) GLIBCSYM(getpwnam_r);
extern int     glibc_getpwuid_r(unsigned, void *, char *, size_t, void **)     GLIBCSYM(getpwuid_r);
extern void   *glibc_mmap(void *, size_t, int, int, int, long) GLIBCSYM(mmap);
extern int     glibc_munmap(void *, size_t)                 GLIBCSYM(munmap);
extern int     glibc_mprotect(void *, size_t, int)          GLIBCSYM(mprotect);

extern int glibc_pthread_rwlock_init(void *, const void *)   GLIBCSYM(pthread_rwlock_init);
extern int glibc_pthread_rwlock_destroy(void *)             GLIBCSYM(pthread_rwlock_destroy);
extern int glibc_pthread_rwlock_rdlock(void *)              GLIBCSYM(pthread_rwlock_rdlock);
extern int glibc_pthread_rwlock_tryrdlock(void *)           GLIBCSYM(pthread_rwlock_tryrdlock);
extern int glibc_pthread_rwlock_wrlock(void *)              GLIBCSYM(pthread_rwlock_wrlock);
extern int glibc_pthread_rwlock_trywrlock(void *)           GLIBCSYM(pthread_rwlock_trywrlock);
extern int glibc_pthread_rwlock_unlock(void *)              GLIBCSYM(pthread_rwlock_unlock);

typedef unsigned long g_pthread_t;
extern int glibc_pthread_create(g_pthread_t *, const void *, void *(*)(void *), void *) GLIBCSYM(pthread_create);
extern int glibc_pthread_join(g_pthread_t, void **)         GLIBCSYM(pthread_join);
extern int glibc_pthread_detach(g_pthread_t)                GLIBCSYM(pthread_detach);
extern g_pthread_t glibc_pthread_self(void)                 GLIBCSYM(pthread_self);
extern int glibc_pthread_equal(g_pthread_t, g_pthread_t)    GLIBCSYM(pthread_equal);
extern int glibc_pthread_mutex_init(void *, const void *)   GLIBCSYM(pthread_mutex_init);
extern int glibc_pthread_mutex_lock(void *)                 GLIBCSYM(pthread_mutex_lock);
extern int glibc_pthread_mutex_trylock(void *)              GLIBCSYM(pthread_mutex_trylock);
extern int glibc_pthread_mutex_unlock(void *)               GLIBCSYM(pthread_mutex_unlock);
extern int glibc_pthread_mutex_destroy(void *)              GLIBCSYM(pthread_mutex_destroy);
extern int glibc_pthread_cond_init(void *, const void *)    GLIBCSYM(pthread_cond_init);
extern int glibc_pthread_cond_wait(void *, void *)          GLIBCSYM(pthread_cond_wait);
extern int glibc_pthread_cond_signal(void *)                GLIBCSYM(pthread_cond_signal);
extern int glibc_pthread_cond_broadcast(void *)             GLIBCSYM(pthread_cond_broadcast);
extern int glibc_pthread_cond_destroy(void *)               GLIBCSYM(pthread_cond_destroy);
extern int glibc_pthread_cond_timedwait(void *, void *, const void *) GLIBCSYM(pthread_cond_timedwait);
extern int glibc_pthread_mutexattr_init(void *)             GLIBCSYM(pthread_mutexattr_init);
extern int glibc_pthread_mutexattr_destroy(void *)          GLIBCSYM(pthread_mutexattr_destroy);
extern int glibc_pthread_mutexattr_settype(void *, int)     GLIBCSYM(pthread_mutexattr_settype);
extern int glibc_pthread_mutexattr_gettype(void *, int *)   GLIBCSYM(pthread_mutexattr_gettype);
extern int glibc_pthread_once(void *, void (*)(void))       GLIBCSYM(pthread_once);
extern int glibc_pthread_key_create(unsigned *, void (*)(void *)) GLIBCSYM(pthread_key_create);
extern int glibc_pthread_key_delete(unsigned)               GLIBCSYM(pthread_key_delete);
extern void *glibc_pthread_getspecific(unsigned)            GLIBCSYM(pthread_getspecific);
extern int glibc_pthread_setspecific(unsigned, const void *) GLIBCSYM(pthread_setspecific);

/* ------------------------------------------------------ internal machinery */

HIDDEN void mr_say(const char *s);
HIDDEN void mr_record_main_thread(void);
HIDDEN __attribute__((noreturn)) void mr_bail(const char *what);
HIDDEN __attribute__((noreturn)) void mr_bail2(const char *what, const char *detail);

/* NULL and LC_GLOBAL_LOCALE ((void *)-1) are the only locale_t values a guest
 * can hold: libSystem exports setlocale and no locale constructor. Both mean
 * the C locale. Anything else is a locale we did not mint -- see snprintf_l. */
HIDDEN void mr_require_c_locale(const void *loc, const char *who);

/* The owning-thread token stored in an os_unfair_lock's four bytes. Unique per
 * live thread BY CONSTRUCTION, never 0, stable for the life of the thread.
 * Implemented in objcsupport.c on top of the direct-TSD array; see the comment
 * there and docs/UNIMPLEMENTED.md#os-unfair-lock-owner for why it may not be
 * derived from pthread_self(). */
HIDDEN unsigned mr_thread_token(void);

/* The loader, not glibc: answers dlopen(RTLD_NOLOAD). Resolved through the
 * loader-export seam, so no GLIBCSYM label. */
extern int mr_image_is_loaded(const char *key);

/* errno, in the two directions that matter. See darwin/src/posix.c. */
HIDDEN int  *mr_errno_slot(void);          /* the guest-visible Darwin errno */
HIDDEN void  mr_errno_in(void);            /* guest's value  -> glibc's errno */
HIDDEN void  mr_errno_out(void);           /* glibc's errno  -> guest's value */
HIDDEN int   mr_pthread_rc(int linux_rc);   /* a pthread RETURN value -> Darwin's */

/* Every call that can set errno is bracketed. Doing only the "out" half would
 * resurrect a stale glibc errno through the classic
 *     errno = 0; v = strtol(...); if (errno == ERANGE) ...
 * idiom, because the guest's write lands in OUR slot and glibc never sees it.
 */
#define MR_ERRNO_CALL(expr)  ({ mr_errno_in(); __typeof__(expr) _r = (expr); mr_errno_out(); _r; })
#define MR_ERRNO_CALL_V(expr) do { mr_errno_in(); (expr); mr_errno_out(); } while (0)

/* Darwin's page size on arm64 is 16 KiB and guests are entitled to assume it.
 * Linux/arm64 may be running 4 KiB pages, so anything we hand back as "a page"
 * is aligned to the larger of the two. */
#define MR_DARWIN_PAGE 16384ul

#endif /* MACHORUN_DSYS_H */
