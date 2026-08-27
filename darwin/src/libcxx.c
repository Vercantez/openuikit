/* libcxx.c -- the part of /usr/lib/libc++.1.dylib that is NOT upstream libc++.
 *
 * THIS FILE USED TO BE THE WHOLE OF OUR libc++: operator new/delete, the
 * __cxa_guard_* trio and std::terminate, hand-written because there was no
 * libc++abi. There is one now (vendor/libcxxabi, built by
 * scripts/build_darwin.sh into /usr/lib/libc++abi.dylib, which this dylib
 * re-exports exactly as Darwin's libc++ does), and every one of those has gone
 * back to upstream where it belongs.
 *
 * What is left is the one thing upstream LLVM 18 does not have: APPLE'S TYPED
 * operator new/delete. Apple's clang lowers `new T` in code built against their
 * libc++ to operator new(size_t, std::__type_descriptor_t) -- an extra 64-bit
 * token describing the type, for their typed-memory-operations work -- and
 * Apple's SHIPPED libswiftCore imports nothing else: __ZnwmSt19__type_descriptor_t
 * and __ZdlPvSt19__type_descriptor_t, and never the plain forms. It binds them
 * two-level FROM libc++, which is why they are here rather than in libc++abi.
 *
 * The array and aligned typed forms are deliberately absent: nothing we run
 * imports them, and src/resolve.c now names any weak-definition gap out loud at
 * load time, so the first binary that needs one will say so rather than
 * branching through zero.
 *
 * Built on Linux as Mach-O, like libSystem.
 */

typedef unsigned long size_t;

#define EXPORT __attribute__((visibility("default")))

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

/* The untyped forms live in libc++abi now (vendor/libcxxabi's
 * stdlib_new_delete.cpp), which is where Darwin puts them and which libc++
 * re-exports. These two forward to them by name rather than to malloc, so
 * there is ONE allocator on this path and a future new_handler or
 * std::bad_alloc behaviour cannot differ between the typed and untyped
 * spellings. */
extern void *mr_untyped_new(size_t) __asm__("__Znwm");
extern void  mr_untyped_delete(void *) __asm__("__ZdlPv");

EXPORT void *mr_new_typed(size_t n, unsigned long long td) { (void)td; return mr_untyped_new(n); }
EXPORT void  mr_delete_typed(void *p, unsigned long long td) { (void)td; mr_untyped_delete(p); }

/* The __cxa_guard_* trio and std::terminate are NOT here any more; they are
 * libc++abi's (vendor/libcxxabi's cxa_guard.cpp and cxa_handlers.cpp), which is
 * where Darwin puts them and which libc++ re-exports. Both replacements are
 * strictly better than what was here:
 *
 *   - the guards were SINGLE-THREADED. The comment said so honestly and said
 *     "if that changes, this needs to grow rather than be trusted". It has now
 *     grown, by deletion: upstream blocks the second thread on a futex while
 *     the first runs the constructor.
 *   - std::terminate called bail(). Upstream runs the installed terminate
 *     handler first, which is what objc-exception.mm relies on to print the
 *     class name of an uncaught ObjC exception.
 */
