#include "OpenDispatchABI.h"

#include <dispatch/dispatch.h>
#include <errno.h>
#include <gnu/libc-version.h>
#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#define OPENUI_DISPATCH_QUEUE_SLOTS 32
#define OPENUI_DISPATCH_REQUIRED_GLIBC_MAJOR 2
#define OPENUI_DISPATCH_REQUIRED_GLIBC_MINOR 38

static pthread_mutex_t queue_lock = PTHREAD_MUTEX_INITIALIZER;
static dispatch_queue_t global_queues[OPENUI_DISPATCH_QUEUE_SLOTS];

struct custom_queue_entry {
    dispatch_queue_t queue;
    struct custom_queue_entry *next;
};

static struct custom_queue_entry *custom_queue_head;

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

static void remember_custom_queue(dispatch_queue_t queue)
{
    struct custom_queue_entry *entry;
    if (queue == NULL) boundary_abort("cannot register a NULL custom queue");
    entry = malloc(sizeof(*entry));
    if (entry == NULL) boundary_abort("cannot allocate custom queue registry entry");
    entry->queue = queue;
    if (pthread_mutex_lock(&queue_lock) != 0) {
        boundary_abort("cannot lock custom queue registry");
    }
    entry->next = custom_queue_head;
    custom_queue_head = entry;
    if (pthread_mutex_unlock(&queue_lock) != 0) {
        boundary_abort("cannot unlock custom queue registry");
    }
}

static int is_known_custom_queue(dispatch_queue_t queue)
{
    struct custom_queue_entry *entry;
    int found = 0;
    if (queue == NULL) return 0;
    if (pthread_mutex_lock(&queue_lock) != 0) {
        boundary_abort("cannot lock custom queue registry");
    }
    for (entry = custom_queue_head; entry != NULL; entry = entry->next) {
        if (entry->queue == queue) {
            found = 1;
            break;
        }
    }
    if (pthread_mutex_unlock(&queue_lock) != 0) {
        boundary_abort("cannot unlock custom queue registry");
    }
    return found;
}

static void forget_custom_queue(dispatch_queue_t queue)
{
    struct custom_queue_entry **link;
    struct custom_queue_entry *removed = NULL;
    if (queue == NULL) boundary_abort("cannot release a NULL custom queue");
    if (pthread_mutex_lock(&queue_lock) != 0) {
        boundary_abort("cannot lock custom queue registry");
    }
    for (link = &custom_queue_head; *link != NULL; link = &(*link)->next) {
        if ((*link)->queue == queue) {
            removed = *link;
            *link = removed->next;
            break;
        }
    }
    if (pthread_mutex_unlock(&queue_lock) != 0) {
        boundary_abort("cannot unlock custom queue registry");
    }
    if (removed == NULL) boundary_abort("unminted custom queue release attempted");
    free(removed);
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
    case OPENUI_DISPATCH_QUEUE_CUSTOM_V1:
        if (!is_known_custom_queue((dispatch_queue_t)opaque)) {
            boundary_abort("unminted custom queue pointer crossed the ELF boundary");
        }
        return (dispatch_queue_t)opaque;
    default:
        boundary_abort("unknown queue kind crossed the ELF boundary");
    }
}

void *openui_dispatch_host_v1_create_queue(
    const char *label,
    int64_t qos_identifier,
    uint64_t attributes,
    uint32_t target_kind,
    void *target_queue
)
{
    dispatch_queue_attr_t attribute;
    dispatch_queue_t queue;
    dispatch_queue_t target = NULL;

    require_runtime();
    if (label == NULL) boundary_abort("NULL custom queue label submitted");
    if ((attributes & ~((uint64_t)OPENUI_DISPATCH_QUEUE_CONCURRENT_V1)) != 0) {
        boundary_abort("unsupported custom queue attributes submitted");
    }
    attribute = (attributes & OPENUI_DISPATCH_QUEUE_CONCURRENT_V1) != 0
        ? DISPATCH_QUEUE_CONCURRENT : DISPATCH_QUEUE_SERIAL;
    queue = dispatch_queue_create(label, attribute);
    if (queue == NULL) boundary_abort("libdispatch refused a custom queue");

    if (target_kind != 0) {
        target = checked_queue(target_kind, target_queue);
    } else if (target_queue != NULL) {
        boundary_abort("custom queue target pointer has no queue kind");
    } else if (qos_identifier != 0) {
        target = dispatch_get_global_queue((intptr_t)qos_identifier, 4);
        if (target == NULL) {
            target = dispatch_get_global_queue((intptr_t)qos_identifier, 0);
        }
        if (target == NULL) boundary_abort("libdispatch refused the requested QoS");
    }
    if (target != NULL) dispatch_set_target_queue(queue, target);
    remember_custom_queue(queue);
    return queue;
}

void openui_dispatch_host_v1_release_queue(void *opaque)
{
    dispatch_queue_t queue = (dispatch_queue_t)opaque;
    require_runtime();
    forget_custom_queue(queue);
    dispatch_release(queue);
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

void openui_dispatch_host_v1_sync(
    uint32_t queue_kind,
    void *queue,
    uint64_t flags,
    void *context,
    openui_dispatch_callback_v1 callback
)
{
    dispatch_queue_t checked;
    require_runtime();
    if (callback == NULL) boundary_abort("NULL synchronous callback submitted");
    if ((flags & ~((uint64_t)OPENUI_DISPATCH_WORK_BARRIER_V1)) != 0) {
        boundary_abort("unsupported synchronous work flags submitted");
    }
    checked = checked_queue(queue_kind, queue);
    if ((flags & OPENUI_DISPATCH_WORK_BARRIER_V1) != 0) {
        dispatch_barrier_sync_f(checked, context, callback);
    } else {
        dispatch_sync_f(checked, context, callback);
    }
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

static int read_unsigned_file(const char *path, uint64_t *result)
{
    FILE *stream;
    char buffer[128];
    char *end = NULL;
    unsigned long long value;

    if (path == NULL || result == NULL) return 0;
    stream = fopen(path, "r");
    if (stream == NULL) return 0;
    if (fgets(buffer, sizeof(buffer), stream) == NULL) {
        (void)fclose(stream);
        return 0;
    }
    if (fclose(stream) != 0) return 0;
    if (strncmp(buffer, "max", 3) == 0) return 0;
    errno = 0;
    value = strtoull(buffer, &end, 10);
    if (errno != 0 || end == buffer) return 0;
    while (*end == ' ' || *end == '\t' || *end == '\r' || *end == '\n') end++;
    if (*end != '\0') return 0;
    *result = (uint64_t)value;
    return 1;
}

static uint64_t classify_memory_ratio(uint64_t available, uint64_t total)
{
    long double used_ratio;
    if (total == 0 || available > total) {
        return OPENUI_DISPATCH_MEMORY_PRESSURE_NORMAL_V1;
    }
    used_ratio = (long double)(total - available) / (long double)total;
    if (used_ratio >= 0.95L) {
        return OPENUI_DISPATCH_MEMORY_PRESSURE_CRITICAL_V1;
    }
    if (used_ratio >= 0.80L) {
        return OPENUI_DISPATCH_MEMORY_PRESSURE_WARNING_V1;
    }
    return OPENUI_DISPATCH_MEMORY_PRESSURE_NORMAL_V1;
}

static uint64_t proc_memory_pressure(void)
{
    FILE *stream;
    char line[256];
    unsigned long long total_kib = 0;
    unsigned long long available_kib = 0;

    stream = fopen("/proc/meminfo", "r");
    if (stream == NULL) return OPENUI_DISPATCH_MEMORY_PRESSURE_NORMAL_V1;
    while (fgets(line, sizeof(line), stream) != NULL) {
        if (sscanf(line, "MemTotal: %llu kB", &total_kib) == 1) continue;
        if (sscanf(line, "MemAvailable: %llu kB", &available_kib) == 1) continue;
    }
    (void)fclose(stream);
    return classify_memory_ratio((uint64_t)available_kib, (uint64_t)total_kib);
}

uint64_t openui_dispatch_host_v1_memory_pressure(void)
{
    const char *override;
    uint64_t current = 0;
    uint64_t maximum = 0;

    require_runtime();
    override = getenv("OPENUI_DISPATCH_MEMORY_PRESSURE");
    if (override != NULL) {
        if (strcmp(override, "normal") == 0) {
            return OPENUI_DISPATCH_MEMORY_PRESSURE_NORMAL_V1;
        }
        if (strcmp(override, "warning") == 0) {
            return OPENUI_DISPATCH_MEMORY_PRESSURE_WARNING_V1;
        }
        if (strcmp(override, "critical") == 0) {
            return OPENUI_DISPATCH_MEMORY_PRESSURE_CRITICAL_V1;
        }
        boundary_abort("invalid OPENUI_DISPATCH_MEMORY_PRESSURE override");
    }
    if (read_unsigned_file("/sys/fs/cgroup/memory.current", &current)
        && read_unsigned_file("/sys/fs/cgroup/memory.max", &maximum)
        && maximum > 0) {
        return classify_memory_ratio(
            current >= maximum ? 0 : maximum - current,
            maximum
        );
    }
    return proc_memory_pressure();
}

void openui_dispatch_host_v1_main(void)
{
    require_runtime();
    dispatch_main();
    boundary_abort("real dispatch_main returned");
}
