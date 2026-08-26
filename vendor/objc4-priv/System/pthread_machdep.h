/*
 * vendor/objc4-priv/System/pthread_machdep.h
 *
 * Darwin's DIRECT thread-specific-data SPI, which objc4 reaches through
 * runtime/Threading/darwin.h. Apple ships this only in the internal SDK.
 *
 * On real Darwin these are inlines that read the `_pthread` struct off
 * TPIDRRO_EL0. We cannot do that: under machorun the guest's threads are
 * glibc threads and TPIDRRO_EL0 holds glibc's TLS base, not a Darwin
 * `_pthread`. So they are DECLARATIONS here and machorun's libSystem owns a
 * real per-thread slot array. That keeps the mechanism at the libSystem seam
 * where every other Darwin primitive already lives, instead of inlining a
 * different mechanism into the runtime's hot path.
 *
 * The key numbers are Apple's, from <pthread/tsd_private.h>. They are ABI:
 * objc4 stores its autorelease pool and sync data in these slots, and any
 * other library that thinks it owns slot 41 would collide -- exactly as on
 * Darwin.
 */
#ifndef _OBJC4_PRIV_SYSTEM_PTHREAD_MACHDEP_H
#define _OBJC4_PRIV_SYSTEM_PTHREAD_MACHDEP_H

#include <pthread.h>
#include <stdbool.h>

__BEGIN_DECLS

/* Slot 0 of every Darwin thread's TSD array is the pthread_t itself. */
#define _PTHREAD_TSD_SLOT_PTHREAD_SELF      0

/* libobjc's reserved block, from <pthread/tsd_private.h>. */
#define __PTK_FRAMEWORK_OBJC_KEY0           40
#define __PTK_FRAMEWORK_OBJC_KEY1           41
#define __PTK_FRAMEWORK_OBJC_KEY2           42
#define __PTK_FRAMEWORK_OBJC_KEY3           43
#define __PTK_FRAMEWORK_OBJC_KEY4           44
#define __PTK_FRAMEWORK_OBJC_KEY5           45
#define __PTK_FRAMEWORK_OBJC_KEY6           46
#define __PTK_FRAMEWORK_OBJC_KEY7           47
#define __PTK_FRAMEWORK_OBJC_KEY8           48
#define __PTK_FRAMEWORK_OBJC_KEY9           49

extern bool  _pthread_has_direct_tsd(void);
extern void *_pthread_getspecific_direct(unsigned long slot);
extern void  _pthread_setspecific_direct(unsigned long slot, void *value);

/* Darwin's "adopt this reserved key and give it a destructor". */
extern int   pthread_key_init_np(int key, void (*destructor)(void *));

__END_DECLS

#endif
