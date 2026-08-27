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
#define EXPORT __attribute__((visibility("default")))
#define HIDDEN __attribute__((visibility("hidden")))

/* ---------------------------------------------------------- memory, string */
extern void  *glibc_malloc(size_t)                          GLIBCSYM(malloc);
extern void  *glibc_calloc(size_t, size_t)                  GLIBCSYM(calloc);
extern void  *glibc_bsearch(const void *, const void *, size_t, size_t,
                            int (*)(const void *, const void *)) GLIBCSYM(bsearch);
extern char  *glibc_strncat(char *, const char *, size_t)   GLIBCSYM(strncat);
extern size_t glibc_strnlen(const char *, size_t)           GLIBCSYM(strnlen);
extern int    glibc_dlclose(void *)                         GLIBCSYM(dlclose);
/* DATA, not functions: glibc's tzset() fills these and a guest reads them.
 * Forwarding a data symbol works the same way -- machorun resolves the
 * _glibc_ alias with dlsym, which finds objects as well as functions. */
extern long   glibc_tz_timezone                             GLIBCSYM(timezone);
extern int    glibc_tz_daylight                             GLIBCSYM(daylight);
extern char  *glibc_tz_tzname[2]                            GLIBCSYM(tzname);
extern void  *glibc_opendir(const char *)                   GLIBCSYM(opendir);
extern void  *glibc_readdir(void *)                         GLIBCSYM(readdir);
extern int    glibc_closedir(void *)                        GLIBCSYM(closedir);
extern void   glibc_rewinddir(void *)                       GLIBCSYM(rewinddir);
extern int    glibc_dirfd(void *)                           GLIBCSYM(dirfd);
extern void  *glibc_realloc(void *, size_t)                 GLIBCSYM(realloc);
extern void   glibc_free(void *)                            GLIBCSYM(free);
extern int    glibc_posix_memalign(void **, size_t, size_t) GLIBCSYM(posix_memalign);
extern void  *glibc_aligned_alloc(size_t, size_t)           GLIBCSYM(aligned_alloc);
extern size_t glibc_malloc_usable_size(void *)              GLIBCSYM(malloc_usable_size);

extern size_t glibc_strlen(const char *)                    GLIBCSYM(strlen);
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
extern int     glibc_stat(const char *, void *)             GLIBCSYM(stat);
extern int     glibc_lstat(const char *, void *)            GLIBCSYM(lstat);
extern int     glibc_fstat(int, void *)                     GLIBCSYM(fstat);
extern int     glibc_mkdir(const char *, unsigned)          GLIBCSYM(mkdir);
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
HIDDEN __attribute__((noreturn)) void mr_bail(const char *what);
HIDDEN __attribute__((noreturn)) void mr_bail2(const char *what, const char *detail);

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
