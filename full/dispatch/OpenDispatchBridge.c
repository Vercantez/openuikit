#include "OpenDispatchABI.h"

/*
 * The portable Swift module intentionally exposes only fixed-width calls.
 * The Linux libdispatch structs and the guest's identity-only _dispatch_main_q
 * object are never interpreted across this boundary.
 */
extern void *host_get_global_queue(int64_t, uint64_t)
    __asm__("_glibc_openui_dispatch_host_v1_get_global_queue");
extern void *host_create_queue(
    const char *, uint64_t, uint32_t, int32_t, uint32_t, void *
) __asm__("_glibc_openui_dispatch_host_v1_create_queue");
extern void host_release_queue(void *)
    __asm__("_glibc_openui_dispatch_host_v1_release_queue");
extern void host_async(
    uint32_t, void *, void *, openui_dispatch_callback_v1
) __asm__("_glibc_openui_dispatch_host_v1_async");
extern void host_after(
    uint32_t, void *, uint64_t, void *, openui_dispatch_callback_v1
) __asm__("_glibc_openui_dispatch_host_v1_after");
extern uint64_t host_monotonic_nanoseconds(void)
    __asm__("_glibc_openui_dispatch_host_v1_monotonic_nanoseconds");
extern void host_queue_set_specific(
    uint32_t, void *, const void *, void *, openui_dispatch_callback_v1
) __asm__("_glibc_openui_dispatch_host_v1_queue_set_specific");
extern void *host_get_specific(const void *)
    __asm__("_glibc_openui_dispatch_host_v1_get_specific");
extern void *host_semaphore_create(int64_t)
    __asm__("_glibc_openui_dispatch_host_v1_semaphore_create");
extern int64_t host_semaphore_signal(void *)
    __asm__("_glibc_openui_dispatch_host_v1_semaphore_signal");
extern int32_t host_semaphore_wait(void *, uint64_t)
    __asm__("_glibc_openui_dispatch_host_v1_semaphore_wait");
extern void host_semaphore_release(void *)
    __asm__("_glibc_openui_dispatch_host_v1_semaphore_release");

void *openui_dispatch_v1_get_global_queue(int64_t identifier, uint64_t flags)
{
    return host_get_global_queue(identifier, flags);
}

void *openui_dispatch_v1_create_queue(
    const char *label,
    uint64_t flags,
    uint32_t qos_class,
    int32_t relative_priority,
    uint32_t target_kind,
    void *target_queue
)
{
    return host_create_queue(
        label,
        flags,
        qos_class,
        relative_priority,
        target_kind,
        target_queue
    );
}

void openui_dispatch_v1_release_queue(void *queue)
{
    host_release_queue(queue);
}

void openui_dispatch_v1_async(
    uint32_t queue_kind,
    void *queue,
    void *context,
    openui_dispatch_callback_v1 callback
)
{
    host_async(queue_kind, queue, context, callback);
}

void openui_dispatch_v1_after(
    uint32_t queue_kind,
    void *queue,
    uint64_t delay_nanoseconds,
    void *context,
    openui_dispatch_callback_v1 callback
)
{
    host_after(queue_kind, queue, delay_nanoseconds, context, callback);
}

uint64_t openui_dispatch_v1_monotonic_nanoseconds(void)
{
    return host_monotonic_nanoseconds();
}

void openui_dispatch_v1_queue_set_specific(
    uint32_t queue_kind,
    void *queue,
    const void *key,
    void *context,
    openui_dispatch_callback_v1 destructor
)
{
    host_queue_set_specific(queue_kind, queue, key, context, destructor);
}

void *openui_dispatch_v1_get_specific(const void *key)
{
    return host_get_specific(key);
}

void *openui_dispatch_v1_semaphore_create(int64_t value)
{
    return host_semaphore_create(value);
}

int64_t openui_dispatch_v1_semaphore_signal(void *semaphore)
{
    return host_semaphore_signal(semaphore);
}

int32_t openui_dispatch_v1_semaphore_wait(
    void *semaphore,
    uint64_t delay_nanoseconds
)
{
    return host_semaphore_wait(semaphore, delay_nanoseconds);
}

void openui_dispatch_v1_semaphore_release(void *semaphore)
{
    host_semaphore_release(semaphore);
}
