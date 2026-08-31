#ifndef OPENUI_DISPATCH_ABI_H
#define OPENUI_DISPATCH_ABI_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Fixed-width boundary shared by the Mach-O Dispatch facade and the Linux
 * helper. Queue objects never cross this boundary as structures. A global
 * queue is an opaque pointer minted by the helper; the main queue is selected
 * by kind and is never represented by the guest's _dispatch_main_q token on
 * the Linux side.
 */
enum openui_dispatch_queue_kind_v1 {
    OPENUI_DISPATCH_QUEUE_MAIN_V1 = 1,
    OPENUI_DISPATCH_QUEUE_GLOBAL_V1 = 2
};

typedef void (*openui_dispatch_callback_v1)(void *context);

#if defined(__GNUC__)
#define OPENUI_DISPATCH_EXPORT __attribute__((visibility("default")))
#define OPENUI_DISPATCH_NORETURN __attribute__((noreturn))
#else
#define OPENUI_DISPATCH_EXPORT
#define OPENUI_DISPATCH_NORETURN
#endif

/* ELF helper ABI. These symbols are found through machorun's _glibc_ gate. */
OPENUI_DISPATCH_EXPORT int32_t openui_dispatch_host_v1_runtime_check(void);
OPENUI_DISPATCH_EXPORT void *openui_dispatch_host_v1_get_global_queue(
    int64_t identifier,
    uint64_t flags
);
OPENUI_DISPATCH_EXPORT void openui_dispatch_host_v1_async(
    uint32_t queue_kind,
    void *queue,
    void *context,
    openui_dispatch_callback_v1 callback
);
OPENUI_DISPATCH_EXPORT void openui_dispatch_host_v1_after(
    uint32_t queue_kind,
    void *queue,
    uint64_t delay_nanoseconds,
    void *context,
    openui_dispatch_callback_v1 callback
);
OPENUI_DISPATCH_EXPORT uint64_t openui_dispatch_host_v1_monotonic_nanoseconds(void);
OPENUI_DISPATCH_EXPORT OPENUI_DISPATCH_NORETURN
void openui_dispatch_host_v1_main(void);

/* Mach-O ABI consumed by the portable Swift Dispatch module. */
void *openui_dispatch_v1_get_global_queue(int64_t identifier, uint64_t flags);
void openui_dispatch_v1_async(
    uint32_t queue_kind,
    void *queue,
    void *context,
    openui_dispatch_callback_v1 callback
);
void openui_dispatch_v1_after(
    uint32_t queue_kind,
    void *queue,
    uint64_t delay_nanoseconds,
    void *context,
    openui_dispatch_callback_v1 callback
);
uint64_t openui_dispatch_v1_monotonic_nanoseconds(void);

#ifdef __cplusplus
}
#endif

#endif
