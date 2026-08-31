#include "OpenDispatchABI.h"

/*
 * The portable Swift module intentionally exposes only fixed-width calls.
 * The Linux libdispatch structs and the guest's identity-only _dispatch_main_q
 * object are never interpreted across this boundary.
 */
extern void *host_get_global_queue(int64_t, uint64_t)
    __asm__("_glibc_openui_dispatch_host_v1_get_global_queue");
extern void host_async(
    uint32_t, void *, void *, openui_dispatch_callback_v1
) __asm__("_glibc_openui_dispatch_host_v1_async");
extern void host_after(
    uint32_t, void *, uint64_t, void *, openui_dispatch_callback_v1
) __asm__("_glibc_openui_dispatch_host_v1_after");
extern uint64_t host_monotonic_nanoseconds(void)
    __asm__("_glibc_openui_dispatch_host_v1_monotonic_nanoseconds");

void *openui_dispatch_v1_get_global_queue(int64_t identifier, uint64_t flags)
{
    return host_get_global_queue(identifier, flags);
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
