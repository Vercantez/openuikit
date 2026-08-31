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

#define OPENUI_DISPATCH_QUEUE_SLOTS 32
#define OPENUI_DISPATCH_REQUIRED_GLIBC_MAJOR 2
#define OPENUI_DISPATCH_REQUIRED_GLIBC_MINOR 38

static pthread_mutex_t queue_lock = PTHREAD_MUTEX_INITIALIZER;
static dispatch_queue_t global_queues[OPENUI_DISPATCH_QUEUE_SLOTS];

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
    for (index = 0; index < OPENUI_DISPATCH_QUEUE_SLOTS; index++) {
        if (global_queues[index] == queue) break;
        if (global_queues[index] == NULL) {
            global_queues[index] = queue;
            break;
        }
    }
    if (pthread_mutex_unlock(&queue_lock) != 0) {
        boundary_abort("cannot unlock global queue registry");
    }
    if (index == OPENUI_DISPATCH_QUEUE_SLOTS) {
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
    for (index = 0; index < OPENUI_DISPATCH_QUEUE_SLOTS; index++) {
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
    default:
        boundary_abort("unknown queue kind crossed the ELF boundary");
    }
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
