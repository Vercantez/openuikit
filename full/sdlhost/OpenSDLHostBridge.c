#include "OpenSDLHostABI.h"

/*
 * Darwin half of the interactive guest host window (libOpenSDLHost.dylib,
 * staged in the guest root's darwin/usr/lib so machorun lets it bind
 * `_glibc_` names).  Each forwarder has fixed arity and passes only scalars,
 * pointers and the fixed-width openui_sdl_event_v1; no SDL type, union or
 * variadic call crosses the Darwin/Linux AArch64 ABI line.  The Linux
 * definitions are in OpenSDLHost.c (libOpenSDLHost.so, LD_PRELOADed).
 */
extern void *host_open(const char *, int32_t, int32_t, int32_t, int32_t)
    __asm__("_glibc_openui_sdl_host_v1_open");
extern const char *host_last_error(void)
    __asm__("_glibc_openui_sdl_host_v1_last_error");
extern int32_t host_poll(void *, openui_sdl_event_v1 *)
    __asm__("_glibc_openui_sdl_host_v1_poll");
extern int32_t host_present(void *, const uint8_t *, int32_t, int32_t, int32_t)
    __asm__("_glibc_openui_sdl_host_v1_present");
extern uint32_t host_ticks(void)
    __asm__("_glibc_openui_sdl_host_v1_ticks");
extern uint64_t host_performance_counter(void)
    __asm__("_glibc_openui_sdl_host_v1_performance_counter");
extern uint64_t host_performance_frequency(void)
    __asm__("_glibc_openui_sdl_host_v1_performance_frequency");
extern void host_delay(uint32_t)
    __asm__("_glibc_openui_sdl_host_v1_delay");
extern void host_start_text_input(void *)
    __asm__("_glibc_openui_sdl_host_v1_start_text_input");
extern void host_close(void *)
    __asm__("_glibc_openui_sdl_host_v1_close");
extern int32_t host_drain_main_queue(void)
    __asm__("_glibc_openui_sdl_host_v1_drain_main_queue");

void *openui_sdl_host_v1_open(const char *title, int32_t point_w,
                              int32_t point_h, int32_t pixel_w, int32_t pixel_h)
{
    return host_open(title, point_w, point_h, pixel_w, pixel_h);
}

const char *openui_sdl_host_v1_last_error(void)
{
    return host_last_error();
}

int32_t openui_sdl_host_v1_poll(void *host, openui_sdl_event_v1 *out)
{
    return host_poll(host, out);
}

int32_t openui_sdl_host_v1_present(void *host, const uint8_t *rgba,
                                   int32_t width, int32_t height, int32_t pitch)
{
    return host_present(host, rgba, width, height, pitch);
}

uint32_t openui_sdl_host_v1_ticks(void)
{
    return host_ticks();
}

uint64_t openui_sdl_host_v1_performance_counter(void)
{
    return host_performance_counter();
}

uint64_t openui_sdl_host_v1_performance_frequency(void)
{
    return host_performance_frequency();
}

void openui_sdl_host_v1_delay(uint32_t milliseconds)
{
    host_delay(milliseconds);
}

void openui_sdl_host_v1_start_text_input(void *host)
{
    host_start_text_input(host);
}

void openui_sdl_host_v1_close(void *host)
{
    host_close(host);
}

int32_t openui_sdl_host_v1_drain_main_queue(void)
{
    return host_drain_main_queue();
}
