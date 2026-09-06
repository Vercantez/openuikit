#include "OpenDispatchABI.h"

#include <dispatch/dispatch.h>
#include <errno.h>
#include <gnu/libc-version.h>
#include <pthread.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#define OPENUI_DISPATCH_GLOBAL_QUEUE_SLOTS 32
#define OPENUI_DISPATCH_PRIVATE_QUEUE_SLOTS 128
#define OPENUI_DISPATCH_SEMAPHORE_SLOTS 128
#define OPENUI_DISPATCH_REQUIRED_GLIBC_MAJOR 2
#define OPENUI_DISPATCH_REQUIRED_GLIBC_MINOR 38

static pthread_mutex_t queue_lock = PTHREAD_MUTEX_INITIALIZER;
static dispatch_queue_t global_queues[OPENUI_DISPATCH_GLOBAL_QUEUE_SLOTS];
static dispatch_queue_t private_queues[OPENUI_DISPATCH_PRIVATE_QUEUE_SLOTS];
static dispatch_semaphore_t semaphores[OPENUI_DISPATCH_SEMAPHORE_SLOTS];

__attribute__((noreturn)) static void boundary_abort(const char *message)
{
    static const char prefix[] = "OpenDispatchHost: ";
    (void)write(2, prefix, sizeof(prefix) - 1);
    (void)write(2, message, strlen(message));
    (void)write(2, "\n", 1);
    abort();
}

static int parse_glibc(const char *version, unsigned *major, unsigned *minor)
{
    char *end = NULL;
    unsigned long first;
    unsigned long second;

    if (version == NULL || major == NULL || minor == NULL) return -1;
    errno = 0;
    first = strtoul(version, &end, 10);
    if (errno != 0 || end == version || *end != '.') return -1;
    version = end + 1;
    errno = 0;
    second = strtoul(version, &end, 10);
    if (errno != 0 || end == version || (*end != '\0' && *end != '.')) return -1;
    if (first > UINT32_MAX || second > UINT32_MAX) return -1;
    *major = (unsigned)first;
    *minor = (unsigned)second;
    return 0;
}

int32_t openui_dispatch_host_v1_runtime_check(void)
{
    unsigned major = 0;
    unsigned minor = 0;
    if (parse_glibc(gnu_get_libc_version(), &major, &minor) != 0) return -1;
    if (major < OPENUI_DISPATCH_REQUIRED_GLIBC_MAJOR) return -1;
    if (major == OPENUI_DISPATCH_REQUIRED_GLIBC_MAJOR
        && minor < OPENUI_DISPATCH_REQUIRED_GLIBC_MINOR) return -1;
    return 0;
}

static void require_runtime(void)
{
    if (openui_dispatch_host_v1_runtime_check() != 0) {
        boundary_abort("staged libdispatch requires glibc >= 2.38");
    }
}

static void remember_global_queue(dispatch_queue_t queue)
{
    size_t index;
    if (queue == NULL) return;
    if (pthread_mutex_lock(&queue_lock) != 0) {
        boundary_abort("cannot lock global queue registry");
    }
    for (index = 0; index < OPENUI_DISPATCH_GLOBAL_QUEUE_SLOTS; index++) {
        if (global_queues[index] == queue) break;
        if (global_queues[index] == NULL) {
            global_queues[index] = queue;
            break;
        }
    }
    if (pthread_mutex_unlock(&queue_lock) != 0) {
        boundary_abort("cannot unlock global queue registry");
    }
    if (index == OPENUI_DISPATCH_GLOBAL_QUEUE_SLOTS) {
        boundary_abort("global queue registry is full");
    }
}

static int is_known_global_queue(dispatch_queue_t queue)
{
    size_t index;
    int found = 0;
    if (queue == NULL) return 0;
    if (pthread_mutex_lock(&queue_lock) != 0) {
        boundary_abort("cannot lock global queue registry");
    }
    for (index = 0; index < OPENUI_DISPATCH_GLOBAL_QUEUE_SLOTS; index++) {
        if (global_queues[index] == queue) {
            found = 1;
            break;
        }
    }
    if (pthread_mutex_unlock(&queue_lock) != 0) {
        boundary_abort("cannot unlock global queue registry");
    }
    return found;
}

static void remember_private_queue(dispatch_queue_t queue)
{
    size_t index;
    if (queue == NULL) boundary_abort("cannot register a NULL private queue");
    if (pthread_mutex_lock(&queue_lock) != 0) {
        boundary_abort("cannot lock private queue registry");
    }
    for (index = 0; index < OPENUI_DISPATCH_PRIVATE_QUEUE_SLOTS; index++) {
        if (private_queues[index] == NULL) {
            private_queues[index] = queue;
            break;
        }
    }
    if (pthread_mutex_unlock(&queue_lock) != 0) {
        boundary_abort("cannot unlock private queue registry");
    }
    if (index == OPENUI_DISPATCH_PRIVATE_QUEUE_SLOTS) {
        boundary_abort("private queue registry is full");
    }
}

static int is_known_private_queue(dispatch_queue_t queue)
{
    size_t index;
    int found = 0;
    if (queue == NULL) return 0;
    if (pthread_mutex_lock(&queue_lock) != 0) {
        boundary_abort("cannot lock private queue registry");
    }
    for (index = 0; index < OPENUI_DISPATCH_PRIVATE_QUEUE_SLOTS; index++) {
        if (private_queues[index] == queue) {
            found = 1;
            break;
        }
    }
    if (pthread_mutex_unlock(&queue_lock) != 0) {
        boundary_abort("cannot unlock private queue registry");
    }
    return found;
}

static int forget_private_queue(dispatch_queue_t queue)
{
    size_t index;
    int found = 0;
    if (queue == NULL) return 0;
    if (pthread_mutex_lock(&queue_lock) != 0) {
        boundary_abort("cannot lock private queue registry");
    }
    for (index = 0; index < OPENUI_DISPATCH_PRIVATE_QUEUE_SLOTS; index++) {
        if (private_queues[index] == queue) {
            private_queues[index] = NULL;
            found = 1;
            break;
        }
    }
    if (pthread_mutex_unlock(&queue_lock) != 0) {
        boundary_abort("cannot unlock private queue registry");
    }
    return found;
}

static void remember_semaphore(dispatch_semaphore_t semaphore)
{
    size_t index;
    if (semaphore == NULL) boundary_abort("cannot register a NULL semaphore");
    if (pthread_mutex_lock(&queue_lock) != 0) {
        boundary_abort("cannot lock semaphore registry");
    }
    for (index = 0; index < OPENUI_DISPATCH_SEMAPHORE_SLOTS; index++) {
        if (semaphores[index] == NULL) {
            semaphores[index] = semaphore;
            break;
        }
    }
    if (pthread_mutex_unlock(&queue_lock) != 0) {
        boundary_abort("cannot unlock semaphore registry");
    }
    if (index == OPENUI_DISPATCH_SEMAPHORE_SLOTS) {
        boundary_abort("semaphore registry is full");
    }
}

static int is_known_semaphore(dispatch_semaphore_t semaphore)
{
    size_t index;
    int found = 0;
    if (semaphore == NULL) return 0;
    if (pthread_mutex_lock(&queue_lock) != 0) {
        boundary_abort("cannot lock semaphore registry");
    }
    for (index = 0; index < OPENUI_DISPATCH_SEMAPHORE_SLOTS; index++) {
        if (semaphores[index] == semaphore) {
            found = 1;
            break;
        }
    }
    if (pthread_mutex_unlock(&queue_lock) != 0) {
        boundary_abort("cannot unlock semaphore registry");
    }
    return found;
}

static int forget_semaphore(dispatch_semaphore_t semaphore)
{
    size_t index;
    int found = 0;
    if (semaphore == NULL) return 0;
    if (pthread_mutex_lock(&queue_lock) != 0) {
        boundary_abort("cannot lock semaphore registry");
    }
    for (index = 0; index < OPENUI_DISPATCH_SEMAPHORE_SLOTS; index++) {
        if (semaphores[index] == semaphore) {
            semaphores[index] = NULL;
            found = 1;
            break;
        }
    }
    if (pthread_mutex_unlock(&queue_lock) != 0) {
        boundary_abort("cannot unlock semaphore registry");
    }
    return found;
}

void *openui_dispatch_host_v1_get_global_queue(
    int64_t identifier,
    uint64_t flags
)
{
    dispatch_queue_t queue;
    require_runtime();
    queue = dispatch_get_global_queue((intptr_t)identifier, (uintptr_t)flags);
    remember_global_queue(queue);
    return queue;
}

static dispatch_queue_t checked_queue(uint32_t queue_kind, void *opaque)
{
    switch (queue_kind) {
    case OPENUI_DISPATCH_QUEUE_MAIN_V1:
        if (opaque != NULL) {
            boundary_abort("guest main-queue token crossed the ELF boundary");
        }
        return dispatch_get_main_queue();
    case OPENUI_DISPATCH_QUEUE_GLOBAL_V1:
        if (!is_known_global_queue((dispatch_queue_t)opaque)) {
            boundary_abort("unminted global queue pointer crossed the ELF boundary");
        }
        return (dispatch_queue_t)opaque;
    case OPENUI_DISPATCH_QUEUE_PRIVATE_V1:
        if (!is_known_private_queue((dispatch_queue_t)opaque)) {
            boundary_abort("unminted private queue pointer crossed the ELF boundary");
        }
        return (dispatch_queue_t)opaque;
    default:
        boundary_abort("unknown queue kind crossed the ELF boundary");
    }
}

void *openui_dispatch_host_v1_create_queue(
    const char *label,
    uint64_t flags,
    uint32_t qos_class,
    int32_t relative_priority,
    uint32_t target_kind,
    void *target_queue
)
{
    dispatch_queue_attr_t attribute;
    dispatch_queue_t queue;
    dispatch_queue_t target = NULL;
    require_runtime();
    if (label == NULL) boundary_abort("NULL private queue label crossed boundary");
    if ((flags & ~((uint64_t)OPENUI_DISPATCH_QUEUE_CONCURRENT_V1)) != 0) {
        boundary_abort("unknown private queue flags crossed boundary");
    }
    if (relative_priority < -15 || relative_priority > 0) {
        boundary_abort("private queue relative priority is outside -15...0");
    }
    if (target_kind != 0) {
        target = checked_queue(target_kind, target_queue);
    } else if (target_queue != NULL) {
        boundary_abort("private queue target pointer has no kind");
    }
    attribute = (flags & OPENUI_DISPATCH_QUEUE_CONCURRENT_V1) != 0
        ? DISPATCH_QUEUE_CONCURRENT : DISPATCH_QUEUE_SERIAL;
    if (qos_class != 0) {
        switch (qos_class) {
        case 0x09: /* background */
        case 0x11: /* utility */
        case 0x15: /* default */
        case 0x19: /* user initiated */
        case 0x21: /* user interactive */
            break;
        default:
            boundary_abort("unknown private queue QoS crossed boundary");
        }
        attribute = dispatch_queue_attr_make_with_qos_class(
            attribute,
            (dispatch_qos_class_t)qos_class,
            relative_priority
        );
        if (attribute == NULL) boundary_abort("libdispatch refused queue QoS");
    }
    queue = dispatch_queue_create(label, attribute);
    if (queue == NULL) boundary_abort("libdispatch refused private queue");
    if (target != NULL) dispatch_set_target_queue(queue, target);
    remember_private_queue(queue);
    return queue;
}

void openui_dispatch_host_v1_release_queue(void *opaque)
{
    dispatch_queue_t queue = (dispatch_queue_t)opaque;
    require_runtime();
    if (!forget_private_queue(queue)) {
        boundary_abort("unminted private queue release crossed the ELF boundary");
    }
    dispatch_release(queue);
}

void openui_dispatch_host_v1_queue_set_specific(
    uint32_t queue_kind,
    void *opaque,
    const void *key,
    void *context,
    openui_dispatch_callback_v1 destructor
)
{
    dispatch_queue_t queue;
    require_runtime();
    if (key == NULL) boundary_abort("NULL queue-specific key crossed boundary");
    if (context != NULL && destructor == NULL) {
        boundary_abort("queue-specific context has no destructor");
    }
    queue = checked_queue(queue_kind, opaque);
    dispatch_queue_set_specific(queue, key, context, destructor);
}

void *openui_dispatch_host_v1_get_specific(const void *key)
{
    require_runtime();
    if (key == NULL) boundary_abort("NULL queue-specific lookup key crossed boundary");
    return dispatch_get_specific(key);
}

void *openui_dispatch_host_v1_semaphore_create(int64_t value)
{
    dispatch_semaphore_t semaphore;
    require_runtime();
    if (value < 0) boundary_abort("negative semaphore value crossed boundary");
    semaphore = dispatch_semaphore_create(value);
    if (semaphore == NULL) boundary_abort("libdispatch refused semaphore");
    remember_semaphore(semaphore);
    return semaphore;
}

int64_t openui_dispatch_host_v1_semaphore_signal(void *opaque)
{
    dispatch_semaphore_t semaphore = (dispatch_semaphore_t)opaque;
    require_runtime();
    if (!is_known_semaphore(semaphore)) {
        boundary_abort("unminted semaphore signal crossed the ELF boundary");
    }
    return dispatch_semaphore_signal(semaphore);
}

int32_t openui_dispatch_host_v1_semaphore_wait(
    void *opaque,
    uint64_t delay_nanoseconds
)
{
    dispatch_semaphore_t semaphore = (dispatch_semaphore_t)opaque;
    dispatch_time_t timeout;
    require_runtime();
    if (!is_known_semaphore(semaphore)) {
        boundary_abort("unminted semaphore wait crossed the ELF boundary");
    }
    timeout = delay_nanoseconds == UINT64_MAX
        ? DISPATCH_TIME_FOREVER
        : dispatch_time(
            DISPATCH_TIME_NOW,
            delay_nanoseconds > (uint64_t)INT64_MAX
                ? INT64_MAX : (int64_t)delay_nanoseconds
        );
    return dispatch_semaphore_wait(semaphore, timeout) == 0 ? 0 : 1;
}

void openui_dispatch_host_v1_semaphore_release(void *opaque)
{
    dispatch_semaphore_t semaphore = (dispatch_semaphore_t)opaque;
    require_runtime();
    if (!forget_semaphore(semaphore)) {
        boundary_abort("unminted semaphore release crossed the ELF boundary");
    }
    dispatch_release(semaphore);
}

void openui_dispatch_host_v1_async(
    uint32_t queue_kind,
    void *queue,
    void *context,
    openui_dispatch_callback_v1 callback
)
{
    require_runtime();
    if (callback == NULL) boundary_abort("NULL callback submitted");
    dispatch_async_f(checked_queue(queue_kind, queue), context, callback);
}
void openui_dispatch_host_v1_sync(
    uint32_t queue_kind,
    void *queue,
    void *context,
    openui_dispatch_callback_v1 callback
)
{
    require_runtime();
    if (callback == NULL) boundary_abort("NULL callback submitted");
    dispatch_sync_f(checked_queue(queue_kind, queue), context, callback);
}

void openui_dispatch_host_v1_after(
    uint32_t queue_kind,
    void *queue,
    uint64_t delay_nanoseconds,
    void *context,
    openui_dispatch_callback_v1 callback
)
{
    int64_t delay;
    require_runtime();
    if (callback == NULL) boundary_abort("NULL delayed callback submitted");
    delay = delay_nanoseconds > (uint64_t)INT64_MAX
        ? INT64_MAX : (int64_t)delay_nanoseconds;
    dispatch_after_f(
        dispatch_time(DISPATCH_TIME_NOW, delay),
        checked_queue(queue_kind, queue),
        context,
        callback
    );
}

uint64_t openui_dispatch_host_v1_monotonic_nanoseconds(void)
{
    struct timespec value;
    require_runtime();
    if (clock_gettime(CLOCK_MONOTONIC, &value) != 0) {
        boundary_abort("clock_gettime(CLOCK_MONOTONIC) failed");
    }
    return (uint64_t)value.tv_sec * UINT64_C(1000000000)
        + (uint64_t)value.tv_nsec;
}

void openui_dispatch_host_v1_main(void)
{
    require_runtime();
    dispatch_main();
    boundary_abort("real dispatch_main returned");
}
