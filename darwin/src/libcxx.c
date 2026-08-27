/* libcxx.c -- our /usr/lib/libc++.1.dylib, so far as the corpus needs it.
 *
 * BE HONEST ABOUT WHAT THIS IS. It is not libc++. It is the out-of-line part
 * of libc++ that a C++ translation unit actually leaves undefined once the
 * headers have been inlined: the operator new / operator delete family. That
 * is genuinely all that tests/bin/05b_cxx_init imports from libc++ --
 * measured with nm -u, the entire list is __ZdlPv -- because its std::string
 * fits in the short-string buffer and every other member is a header inline.
 *
 * What is NOT here, and will fail loudly by name if a future fixture needs it:
 *   - the std::string / iostream / locale out-of-line symbols,
 *   - __cxa_throw and friends: exceptions need libc++abi AND an unwinder that
 *     reads Apple's compact __unwind_info, which is not .eh_frame. That is the
 *     real M9 wall and this file does not touch it.
 *
 * Built on Linux as Mach-O, like libSystem. Same rules: the glibc boundary is
 * spelled _glibc_<name>, and nothing here is variadic.
 */

typedef unsigned long size_t;

#define GLIBCSYM(n) __asm__("_glibc_" #n)
#define EXPORT __attribute__((visibility("default")))

extern void  *glibc_malloc(size_t)                    GLIBCSYM(malloc);
extern void   glibc_free(void *)                      GLIBCSYM(free);
extern int    glibc_posix_memalign(void **, size_t, size_t) GLIBCSYM(posix_memalign);
extern long   glibc_write(int, const void *, size_t)  GLIBCSYM(write);
extern void   glibc__exit(int)                        GLIBCSYM(_exit);

static void bail(const char *s)
{
    const char *p = s;
    size_t n = 0;
    while (*p++) n++;
    glibc_write(2, "machorun/libc++: ", 17);
    glibc_write(2, s, n);
    glibc_write(2, "\n", 1);
    glibc__exit(71);
}

static void *alloc(size_t n)
{
    void *p = glibc_malloc(n ? n : 1);
    /* Real libc++ throws std::bad_alloc here. We have no exception machinery,
     * so say so instead of returning NULL into code that will not check it. */
    if (!p) bail("operator new could not allocate and std::bad_alloc cannot be "
                 "thrown without libc++abi + an unwinder");
    return p;
}

static void *alloc_aligned(size_t n, size_t align)
{
    void *p = 0;
    if (glibc_posix_memalign(&p, align < sizeof(void *) ? sizeof(void *) : align, n ? n : 1) != 0)
        bail("aligned operator new could not allocate");
    return p;
}

/* Apple's TYPED memory operations. Apple's clang lowers `new T` in code built
 * against their libc++ to operator new(size_t, std::__type_descriptor_t) -- an
 * extra 64-bit token describing the type, for their memory-safety tooling --
 * and their libc++ defines the pair. Ours did not, and Apple's SHIPPED
 * libswiftCore uses nothing else: it imports __ZnwmSt19__type_descriptor_t and
 * __ZdlPvSt19__type_descriptor_t and never the plain forms. Our own
 * Linux-built libswiftCore imports __Znwm and __ZdlPvm instead, which is
 * exactly why the shipped runtime was the only one affected.
 *
 * The descriptor is metadata; it does not change what must be allocated, so
 * these forward to the untyped implementations. The parameter is taken as a
 * 64-bit scalar rather than a struct because the call sites pass a single
 * value in x1 (`movk` x4 building 0x00080c4018a671a6, then `bl`), and an
 * 8-byte POD and a uint64_t are the same thing to AAPCS64.
 *
 * ONLY these two are defined, deliberately. The array and aligned typed forms
 * exist in Apple's libc++ and nothing we run imports them yet; machorun now
 * names any weak-definition gap out loud at load time (src/resolve.c), so the
 * first binary that needs one will say so instead of branching through zero. */
EXPORT void *mr_new_typed(size_t n, unsigned long long td)
                                                    __asm__("__ZnwmSt19__type_descriptor_t");
EXPORT void  mr_delete_typed(void *p, unsigned long long td)
                                                    __asm__("__ZdlPvSt19__type_descriptor_t");

EXPORT void *mr_new(size_t n)                       __asm__("__Znwm");
EXPORT void *mr_new_array(size_t n)                 __asm__("__Znam");
EXPORT void *mr_new_align(size_t n, size_t a)       __asm__("__ZnwmSt11align_val_t");
EXPORT void *mr_new_array_align(size_t n, size_t a) __asm__("__ZnamSt11align_val_t");
EXPORT void  mr_delete(void *p)                     __asm__("__ZdlPv");
EXPORT void  mr_delete_array(void *p)               __asm__("__ZdaPv");
EXPORT void  mr_delete_sized(void *p, size_t n)     __asm__("__ZdlPvm");
EXPORT void  mr_delete_array_sized(void *p, size_t n) __asm__("__ZdaPvm");
EXPORT void  mr_delete_align(void *p, size_t a)     __asm__("__ZdlPvSt11align_val_t");
EXPORT void  mr_delete_array_align(void *p, size_t a) __asm__("__ZdaPvSt11align_val_t");

EXPORT void *mr_new_typed(size_t n, unsigned long long td) { (void)td; return alloc(n); }
EXPORT void  mr_delete_typed(void *p, unsigned long long td) { (void)td; glibc_free(p); }

EXPORT void *mr_new(size_t n) { return alloc(n); }
EXPORT void *mr_new_array(size_t n) { return alloc(n); }
EXPORT void *mr_new_align(size_t n, size_t a) { return alloc_aligned(n, a); }
EXPORT void *mr_new_array_align(size_t n, size_t a) { return alloc_aligned(n, a); }
EXPORT void  mr_delete(void *p) { glibc_free(p); }
EXPORT void  mr_delete_array(void *p) { glibc_free(p); }
EXPORT void  mr_delete_sized(void *p, size_t n) { (void)n; glibc_free(p); }
EXPORT void  mr_delete_array_sized(void *p, size_t n) { (void)n; glibc_free(p); }
EXPORT void  mr_delete_align(void *p, size_t a) { (void)a; glibc_free(p); }
EXPORT void  mr_delete_array_align(void *p, size_t a) { (void)a; glibc_free(p); }

/* The C++ ABI's guard variables for function-local statics. Single-threaded
 * initialisation only: a real implementation blocks the second thread on a
 * futex while the first runs the constructor. Nothing in the corpus
 * initialises a local static from two threads; if that changes, this needs to
 * grow rather than be trusted. */
EXPORT int  mr_guard_acquire(unsigned long long *g) __asm__("___cxa_guard_acquire");
EXPORT void mr_guard_release(unsigned long long *g) __asm__("___cxa_guard_release");
EXPORT void mr_guard_abort(unsigned long long *g)   __asm__("___cxa_guard_abort");

EXPORT int  mr_guard_acquire(unsigned long long *g) { return (*(char *)g) == 0; }
EXPORT void mr_guard_release(unsigned long long *g) { *(char *)g = 1; }
EXPORT void mr_guard_abort(unsigned long long *g)   { (void)g; }

EXPORT void mr_terminate(void) __asm__("__ZSt9terminatev");
EXPORT void mr_terminate(void) { bail("std::terminate() called"); }
