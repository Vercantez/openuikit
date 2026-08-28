/* UDPlatformMinimal.h -- the libc surface UserDefaults' guest build needs,
 * declared so the guest does NOT `import Darwin`.
 *
 * WHY NOT `import Darwin`. Measured 2026-08-28, and it is the same finding as
 * include/CFPreferencesMinimal.h one layer down. The guest branch imported
 * Darwin for pthread, vsnprintf and exit. That pulls APPLE'S SWIFT DARWIN
 * OVERLAY DYLIBS into the load graph, and those depend on Apple's
 * CoreFoundation AND Apple's Foundation:
 *
 *     machorun: cannot find dylib
 *       '/System/Library/Frameworks/Foundation.framework/Foundation'
 *       required by: .../swift/libswift_Builtin_float.dylib
 *
 * Foundation is the thing this project is building. An overlay that demands
 * Apple's copy of it cannot be in the graph of a guest that supplies its own.
 * (The first missing dylib was CoreFoundation; satisfying it revealed
 * Foundation, which is how the shape became visible rather than staying one
 * confusing error.)
 *
 * THIS DOES NOT CONTRADICT THE canImport(Darwin) RULING. That governs which
 * ABI the compiler emits against -- and this header is compiled against
 * machorun's SDK, so the ABI is still Darwin's. What changes is only that
 * Apple's overlay DYLIBS stay out of the load. Declaring is not "pretending to
 * be Linux"; it is naming what we use instead of importing a module we do not
 * ship.
 *
 * Third use of declare-don't-import, after CFPreferencesMinimal.h and the
 * refusal to `import CoreFoundation`.
 */

#ifndef FM_UD_PLATFORM_MINIMAL_H
#define FM_UD_PLATFORM_MINIMAL_H

#include <stdarg.h>
#include <stddef.h>

/* Darwin's pthread_mutex_t IS this layout: a signature word followed by 56
 * opaque bytes, 64 in total. It is declared here rather than included because
 * <pthread.h> drags the rest of the Darwin module surface back in.
 *
 * THE SIGNATURE WORD IS LOAD-BEARING and is why this must not be a bare byte
 * array: machorun's adopt() reads it to tell "statically initialised by
 * Apple's header" from "already adopted by us" (#80). We never static-init one
 * -- _UDMutex calls ud_pthread_mutex_init, which is what writes it -- so the
 * zeroed case is the one that applies, and adopt() accepts zero. */
typedef struct { long __sig; char __opaque[56]; } ud_pthread_mutex_t;

int ud_pthread_mutex_init(ud_pthread_mutex_t *m, const void *attr)
    __asm__("_pthread_mutex_init");
int ud_pthread_mutex_destroy(ud_pthread_mutex_t *m)
    __asm__("_pthread_mutex_destroy");
int ud_pthread_mutex_lock(ud_pthread_mutex_t *m)
    __asm__("_pthread_mutex_lock");
int ud_pthread_mutex_unlock(ud_pthread_mutex_t *m)
    __asm__("_pthread_mutex_unlock");

/* Formatting. "%0.16g" is a C format string, so going through vsnprintf is the
 * same call one layer less indirect than Foundation's String(format:) -- which
 * the guest does not have anyway. */
int ud_vsnprintf(char *buf, size_t n, const char *fmt, va_list ap)
    __asm__("_vsnprintf");

/* Process and environment. `write` is fd-2 for the loud aborts, and it is used
 * rather than a print because a buffered write is discarded by abort(). */
/* _Noreturn so Swift sees it as `-> Never` and a `guard` body ending in
 * ud_exit() satisfies the compiler. Without it the guard does not
 * terminate the scope and the file does not build. */
_Noreturn void ud_exit(int status) __asm__("_exit");
void  ud_abort(void) __asm__("_abort");
char *ud_getenv(const char *name) __asm__("_getenv");
long  ud_write(int fd, const void *buf, unsigned long n) __asm__("_write");
unsigned long ud_strlen(const char *s) __asm__("_strlen");

#endif /* FM_UD_PLATFORM_MINIMAL_H */
