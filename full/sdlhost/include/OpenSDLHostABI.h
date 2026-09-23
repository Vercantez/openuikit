#ifndef OPENUIKIT_OPEN_SDL_HOST_ABI_H
#define OPENUIKIT_OPEN_SDL_HOST_ABI_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#if defined(__GNUC__)
#define OPENUI_SDL_HOST_API __attribute__((visibility("default")))
#else
#define OPENUI_SDL_HOST_API
#endif

/*
 * The window of the interactive Mach-O guest host (host_full), owned on the
 * Linux side by libOpenSDLHost.so.  Same shape as OpenURLTransportABI.h: a
 * narrow, versioned boundary that no SDL type, union, callback or variadic
 * function crosses.  Every function has fixed arity; the only aggregate is
 * openui_sdl_event_v1, whose members are fixed-width scalars and one byte
 * array, so its layout is identical under the Darwin and Linux AArch64 C ABIs.
 *
 * Values are SDL's own: key_sym is an SDL_Keycode, key_mods SDL_Keymod bits,
 * button 1 is the left button.  Positions are in window POINTS (the host sets
 * SDL_RenderSetLogicalSize to the point size, so SDL reports mouse positions
 * in points on any display density).  Pixels handed to present() are
 * straight-alpha RGBA8 in memory order R,G,B,A (OpenUIKit's Bitmap), which is
 * SDL_PIXELFORMAT_ABGR8888 on little-endian; they are composited over white.
 *
 * Threading: every call is made from the process main thread.
 */
#define OPENUI_SDL_HOST_ABI_VERSION 1u
#define OPENUI_SDL_HOST_TEXT_BYTES 32u

typedef enum openui_sdl_event_kind_v1 {
    OPENUI_SDL_EVENT_OTHER = 0,
    OPENUI_SDL_EVENT_QUIT = 1,
    OPENUI_SDL_EVENT_KEY_DOWN = 2,
    OPENUI_SDL_EVENT_TEXT = 3,
    OPENUI_SDL_EVENT_MOUSE_DOWN = 4,
    OPENUI_SDL_EVENT_MOUSE_MOTION = 5,
    OPENUI_SDL_EVENT_MOUSE_UP = 6
} openui_sdl_event_kind_v1;

typedef struct openui_sdl_event_v1 {
    uint32_t abi_version;
    uint32_t struct_size;
    uint32_t kind;          /* openui_sdl_event_kind_v1 */
    uint32_t button;        /* MOUSE_DOWN / MOUSE_UP: SDL button index */
    int32_t x;              /* MOUSE_*: window points */
    int32_t y;
    int32_t key_sym;        /* KEY_DOWN: SDL_Keycode */
    uint32_t key_mods;      /* KEY_DOWN: SDL_Keymod */
    uint64_t timestamp_ms;  /* SDL event timestamp (SDL_GetTicks clock) */
    uint8_t text[OPENUI_SDL_HOST_TEXT_BYTES]; /* TEXT: NUL-terminated UTF-8 */
} openui_sdl_event_v1;

/*
 * Open a window of point_w x point_h points backed by a pixel_w x pixel_h
 * streaming texture.  Returns NULL on failure (reason: last_error()).
 * SDL_VIDEODRIVER selects the driver as usual (x11 under Xvfb, dummy
 * headless).
 */
OPENUI_SDL_HOST_API void *openui_sdl_host_v1_open(
    const char *title, int32_t point_w, int32_t point_h,
    int32_t pixel_w, int32_t pixel_h);
OPENUI_SDL_HOST_API const char *openui_sdl_host_v1_last_error(void);
/* 1 and *out filled when an event was dequeued, 0 when the queue is empty. */
OPENUI_SDL_HOST_API int32_t openui_sdl_host_v1_poll(
    void *host, openui_sdl_event_v1 *out);
/* Upload and present one frame. 0 on success. */
OPENUI_SDL_HOST_API int32_t openui_sdl_host_v1_present(
    void *host, const uint8_t *rgba, int32_t width, int32_t height,
    int32_t pitch);
OPENUI_SDL_HOST_API uint32_t openui_sdl_host_v1_ticks(void);
OPENUI_SDL_HOST_API uint64_t openui_sdl_host_v1_performance_counter(void);
OPENUI_SDL_HOST_API uint64_t openui_sdl_host_v1_performance_frequency(void);
OPENUI_SDL_HOST_API void openui_sdl_host_v1_delay(uint32_t milliseconds);
OPENUI_SDL_HOST_API void openui_sdl_host_v1_start_text_input(void *host);
OPENUI_SDL_HOST_API void openui_sdl_host_v1_close(void *host);

/*
 * One run-loop turn of the libdispatch main queue: runs the blocks enqueued
 * on dispatch_get_main_queue() so far (what CFRunLoop does on Darwin via
 * _dispatch_main_queue_callback_4CF).  Returns 1 when the host libdispatch
 * provides the drain entry point, 0 when it does not (nothing ran).
 */
OPENUI_SDL_HOST_API int32_t openui_sdl_host_v1_drain_main_queue(void);

#ifdef __cplusplus
}
#endif

#endif
