//===----------------------------------------------------------------------===//
//
// This source file is part of the open iOS-on-Linux platform project.
//
// It supplies the four private primitives used by Swift's open-source
// Observation implementation without depending on Swift's private C++
// runtime headers.  The ABI and behavior match the upstream helpers: a
// process-private unfair lock and one process-private pthread TLS key.
//
//===----------------------------------------------------------------------===//

#include <os/lock.h>
#include <pthread.h>
#include <stddef.h>
#include <stdint.h>

#if __has_attribute(swiftcall)
#define OPEN_OBSERVATION_SWIFTCALL __attribute__((swiftcall))
#else
#define OPEN_OBSERVATION_SWIFTCALL
#endif

#define OPEN_OBSERVATION_HIDDEN __attribute__((visibility("hidden")))

static pthread_key_t observation_tls_key;
static pthread_once_t observation_tls_once = PTHREAD_ONCE_INIT;

static void observation_tls_initialize(void) {
    if (pthread_key_create(&observation_tls_key, NULL) != 0) {
        __builtin_trap();
    }
}

OPEN_OBSERVATION_HIDDEN OPEN_OBSERVATION_SWIFTCALL
size_t _swift_observation_lock_size(void) {
    return sizeof(os_unfair_lock);
}

OPEN_OBSERVATION_HIDDEN OPEN_OBSERVATION_SWIFTCALL
void _swift_observation_lock_init(const void *storage) {
    os_unfair_lock *lock = (os_unfair_lock *)(uintptr_t)storage;
    *lock = OS_UNFAIR_LOCK_INIT;
}

OPEN_OBSERVATION_HIDDEN OPEN_OBSERVATION_SWIFTCALL
void _swift_observation_lock_lock(const void *storage) {
    os_unfair_lock_lock((os_unfair_lock *)(uintptr_t)storage);
}

OPEN_OBSERVATION_HIDDEN OPEN_OBSERVATION_SWIFTCALL
void _swift_observation_lock_unlock(const void *storage) {
    os_unfair_lock_unlock((os_unfair_lock *)(uintptr_t)storage);
}

OPEN_OBSERVATION_HIDDEN OPEN_OBSERVATION_SWIFTCALL
void *_swift_observation_tls_get(void) {
    if (pthread_once(&observation_tls_once, observation_tls_initialize) != 0) {
        __builtin_trap();
    }
    return pthread_getspecific(observation_tls_key);
}

OPEN_OBSERVATION_HIDDEN OPEN_OBSERVATION_SWIFTCALL
void _swift_observation_tls_set(void *value) {
    if (pthread_once(&observation_tls_once, observation_tls_initialize) != 0) {
        __builtin_trap();
    }
    if (pthread_setspecific(observation_tls_key, value) != 0) {
        __builtin_trap();
    }
}
