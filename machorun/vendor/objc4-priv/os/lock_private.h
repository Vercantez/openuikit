/*
 * vendor/objc4-priv/os/lock_private.h
 *
 * Apple ships <os/lock_private.h> only in their INTERNAL SDK. The public SDK
 * has <os/lock.h>, which defines os_unfair_lock and the three basic
 * operations. This header is the delta: it includes the public one (so the
 * struct is defined exactly once, by Apple) and adds the private SPI objc4
 * actually calls.
 *
 * Everything here is a DECLARATION. The definitions come from machorun's
 * darwin/usr/lib/libSystem.B.dylib at run time, which is where the real ones
 * come from on macOS too. Nothing is reimplemented as an inline, because an
 * inline would bake our semantics into the runtime instead of leaving them at
 * the libSystem seam where they can be measured.
 */
#ifndef _OBJC4_PRIV_OS_LOCK_PRIVATE_H
#define _OBJC4_PRIV_OS_LOCK_PRIVATE_H

#include <os/lock.h>
#include <stdint.h>
#include <stdbool.h>

__BEGIN_DECLS

/* os_unfair_lock_lock_with_options ------------------------------------- */
OS_ENUM(os_unfair_lock_options, uint32_t,
    OS_UNFAIR_LOCK_NONE                     = 0x00000000,
    OS_UNFAIR_LOCK_DATA_SYNCHRONIZATION     = 0x00010000,
    OS_UNFAIR_LOCK_ADAPTIVE_SPIN            = 0x00040000,
);

extern void os_unfair_lock_lock_with_options(os_unfair_lock_t lock,
                                             os_unfair_lock_options_t options);

/*
 * The *_inline forms. On Darwin these are static inlines in the internal
 * header that expand the lock fast path into the caller -- objc4's whole
 * locking layer uses them. Here they forward to the out-of-line entry points
 * in machorun's libSystem. Same semantics, one call more; the difference is
 * performance, not behaviour, and it is recorded in docs/UNIMPLEMENTED.md.
 */
static inline void
os_unfair_lock_lock_inline(os_unfair_lock_t lock)
{
    os_unfair_lock_lock(lock);
}

static inline void
os_unfair_lock_lock_with_options_inline(os_unfair_lock_t lock,
                                        os_unfair_lock_options_t options)
{
    os_unfair_lock_lock_with_options(lock, options);
}

static inline bool
os_unfair_lock_trylock_inline(os_unfair_lock_t lock)
{
    return os_unfair_lock_trylock(lock);
}

static inline void
os_unfair_lock_unlock_inline(os_unfair_lock_t lock)
{
    os_unfair_lock_unlock(lock);
}

static inline void
os_unfair_lock_assert_owner_inline(os_unfair_lock_t lock)
{
    os_unfair_lock_assert_owner(lock);
}

static inline void
os_unfair_lock_assert_not_owner_inline(os_unfair_lock_t lock)
{
    os_unfair_lock_assert_not_owner(lock);
}

/* os_unfair_recursive_lock --------------------------------------------- */
typedef struct os_unfair_recursive_lock_s {
    os_unfair_lock ourl_lock;
    uint32_t       ourl_count;
} os_unfair_recursive_lock, *os_unfair_recursive_lock_t;

#define OS_UNFAIR_RECURSIVE_LOCK_INIT \
        ((os_unfair_recursive_lock){ OS_UNFAIR_LOCK_INIT, 0 })

extern void os_unfair_recursive_lock_lock_with_options(
        os_unfair_recursive_lock_t lock, os_unfair_lock_options_t options);
extern bool os_unfair_recursive_lock_trylock(os_unfair_recursive_lock_t lock);
extern void os_unfair_recursive_lock_unlock(os_unfair_recursive_lock_t lock);
extern bool os_unfair_recursive_lock_owned(os_unfair_recursive_lock_t lock);

/* @synchronized's unlock: "unlock if I own it", reporting whether I did. */
extern bool os_unfair_recursive_lock_tryunlock4objc(os_unfair_recursive_lock_t lock);

/* Post-fork(): the child has one thread, so drop the lock unconditionally. */
extern void os_unfair_recursive_lock_unlock_forked_child(os_unfair_recursive_lock_t lock);

static inline void
os_unfair_recursive_lock_lock(os_unfair_recursive_lock_t lock)
{
    os_unfair_recursive_lock_lock_with_options(lock, OS_UNFAIR_LOCK_NONE);
}

/* Referenced only from a comment in NSObject.mm, but the type name appears. */
typedef struct os_lock_handoff_s { uintptr_t _opaque; } os_lock_handoff_s;

__END_DECLS

#endif
