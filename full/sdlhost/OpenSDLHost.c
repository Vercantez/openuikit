/*
 * libOpenSDLHost.so -- the Linux half of the interactive Mach-O guest host.
 *
 * Owns the SDL window, the renderer, the streaming texture and the event
 * queue for host_full (full/driver/HostMain.swift), which reaches these
 * functions through full/sdlhost/OpenSDLHostBridge.c's `_glibc_` labels.
 * Mirrors uikit/Sources/openhost/HostCore.swift's SDLHost call for call, so a
 * frame reaches the screen the same way on both routes.
 *
 * Environment (read at open):
 *   OPENUI_SDL_HOST_WINDOW_SCALE=N  window pixels per point (default 1). The
 *       texture is always the full-resolution bitmap; the renderer's logical
 *       size keeps mouse coordinates in points whatever this is.
 *   OPENUI_SDL_HOST_MIN_FRAME_MS=N  minimum interval between presents when
 *       the renderer has no vsync (default 16; 0 disables). Under Xvfb the
 *       software renderer never blocks in SDL_RenderPresent.
 */
#define _GNU_SOURCE

#include "OpenSDLHostABI.h"

#include <SDL2/SDL.h>
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct sdl_host {
    SDL_Window *window;
    SDL_Renderer *renderer;
    SDL_Texture *texture;
    int32_t pixel_w;
    int32_t pixel_h;
    int vsync;
    uint32_t min_frame_ms;
    uint64_t last_present_counter;
    /* OPENUI_SDL_HOST_STATS=1: input-to-present latency and frame rate. */
    int stats;
    uint32_t pending_input_ms;   /* SDL timestamp of the oldest unpresented input, 0 = none */
    uint32_t window_start_ms;
    uint32_t window_frames;
    uint32_t window_inputs;
    uint64_t window_latency_sum;
    uint32_t window_latency_max;
} sdl_host;

static void stats_note_input(sdl_host *h, uint32_t timestamp)
{
    if (h && h->stats && h->pending_input_ms == 0)
        h->pending_input_ms = timestamp ? timestamp : 1;
}

static void stats_note_present(sdl_host *h)
{
    if (!h->stats) return;
    uint32_t now = SDL_GetTicks();
    if (h->window_start_ms == 0) h->window_start_ms = now;
    h->window_frames++;
    if (h->pending_input_ms) {
        uint32_t latency = now - h->pending_input_ms;
        h->window_latency_sum += latency;
        if (latency > h->window_latency_max) h->window_latency_max = latency;
        h->window_inputs++;
        h->pending_input_ms = 0;
    }
    uint32_t span = now - h->window_start_ms;
    if (span >= 2000) {
        fprintf(stderr,
                "sdlhost-stats: %.1f fps (%u frames / %u ms), input->present "
                "avg %u ms max %u ms over %u inputs\n",
                h->window_frames * 1000.0 / span, h->window_frames, span,
                h->window_inputs ? (uint32_t)(h->window_latency_sum / h->window_inputs) : 0,
                h->window_latency_max, h->window_inputs);
        h->window_start_ms = now;
        h->window_frames = 0;
        h->window_inputs = 0;
        h->window_latency_sum = 0;
        h->window_latency_max = 0;
    }
}

static char last_error[512];

static void set_error(const char *what)
{
    snprintf(last_error, sizeof last_error, "%s: %s", what, SDL_GetError());
}

static long env_long(const char *name, long fallback)
{
    const char *v = getenv(name);
    if (!v || !*v) return fallback;
    char *end = NULL;
    long n = strtol(v, &end, 10);
    return (end && *end == '\0' && n >= 0) ? n : fallback;
}

OPENUI_SDL_HOST_API const char *openui_sdl_host_v1_last_error(void)
{
    return last_error;
}

OPENUI_SDL_HOST_API void *openui_sdl_host_v1_open(
    const char *title, int32_t point_w, int32_t point_h,
    int32_t pixel_w, int32_t pixel_h)
{
    if (point_w <= 0 || point_h <= 0 || pixel_w <= 0 || pixel_h <= 0) {
        snprintf(last_error, sizeof last_error, "bad window size");
        return NULL;
    }
    SDL_SetMainReady();
    if (SDL_Init(SDL_INIT_VIDEO) != 0) {
        set_error("SDL_Init");
        return NULL;
    }
    sdl_host *h = calloc(1, sizeof *h);
    if (!h) {
        snprintf(last_error, sizeof last_error, "out of memory");
        SDL_Quit();
        return NULL;
    }
    long window_scale = env_long("OPENUI_SDL_HOST_WINDOW_SCALE", 1);
    if (window_scale < 1 || window_scale > 4) window_scale = 1;
    h->min_frame_ms = (uint32_t)env_long("OPENUI_SDL_HOST_MIN_FRAME_MS", 16);
    h->stats = env_long("OPENUI_SDL_HOST_STATS", 0) != 0;
    h->pixel_w = pixel_w;
    h->pixel_h = pixel_h;
    h->window = SDL_CreateWindow(
        title ? title : "host_full",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        (int)(point_w * window_scale), (int)(point_h * window_scale),
        SDL_WINDOW_ALLOW_HIGHDPI | SDL_WINDOW_SHOWN);
    if (!h->window) {
        set_error("SDL_CreateWindow");
        goto fail;
    }
    /* Same fallback as openhost: headless (dummy) has no accelerated
     * renderer. Captured frames come from the guest's Bitmap, never from
     * this renderer, so the fallback cannot change them. */
    h->renderer = SDL_CreateRenderer(
        h->window, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
    if (!h->renderer)
        h->renderer = SDL_CreateRenderer(h->window, -1, SDL_RENDERER_SOFTWARE);
    if (!h->renderer) {
        set_error("SDL_CreateRenderer");
        goto fail;
    }
    SDL_RendererInfo info;
    if (SDL_GetRendererInfo(h->renderer, &info) == 0)
        h->vsync = (info.flags & SDL_RENDERER_PRESENTVSYNC) != 0;
    SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "linear");
    SDL_RenderSetLogicalSize(h->renderer, point_w, point_h);
    h->texture = SDL_CreateTexture(h->renderer, SDL_PIXELFORMAT_ABGR8888,
                                   SDL_TEXTUREACCESS_STREAMING, pixel_w, pixel_h);
    if (!h->texture) {
        set_error("SDL_CreateTexture");
        goto fail;
    }
    SDL_SetTextureBlendMode(h->texture, SDL_BLENDMODE_BLEND);
    return h;

fail:
    if (h->texture) SDL_DestroyTexture(h->texture);
    if (h->renderer) SDL_DestroyRenderer(h->renderer);
    if (h->window) SDL_DestroyWindow(h->window);
    free(h);
    SDL_Quit();
    return NULL;
}

OPENUI_SDL_HOST_API int32_t openui_sdl_host_v1_poll(
    void *host, openui_sdl_event_v1 *out)
{
    if (!out) return 0;
    SDL_Event ev;
    if (SDL_PollEvent(&ev) == 0) return 0;
    switch (ev.type) {
    case SDL_KEYDOWN: case SDL_TEXTINPUT: case SDL_MOUSEBUTTONDOWN:
    case SDL_MOUSEBUTTONUP: case SDL_MOUSEMOTION:
        stats_note_input(host, ev.common.timestamp);
        break;
    default:
        break;
    }
    memset(out, 0, sizeof *out);
    out->abi_version = OPENUI_SDL_HOST_ABI_VERSION;
    out->struct_size = (uint32_t)sizeof *out;
    out->timestamp_ms = ev.common.timestamp;
    switch (ev.type) {
    case SDL_QUIT:
        out->kind = OPENUI_SDL_EVENT_QUIT;
        break;
    case SDL_KEYDOWN:
        out->kind = OPENUI_SDL_EVENT_KEY_DOWN;
        out->key_sym = ev.key.keysym.sym;
        out->key_mods = ev.key.keysym.mod;
        break;
    case SDL_TEXTINPUT: {
        out->kind = OPENUI_SDL_EVENT_TEXT;
        size_t n = strnlen(ev.text.text, sizeof ev.text.text);
        if (n >= OPENUI_SDL_HOST_TEXT_BYTES) n = OPENUI_SDL_HOST_TEXT_BYTES - 1;
        memcpy(out->text, ev.text.text, n);
        out->text[n] = 0;
        break;
    }
    case SDL_MOUSEBUTTONDOWN:
    case SDL_MOUSEBUTTONUP:
        out->kind = ev.type == SDL_MOUSEBUTTONDOWN ? OPENUI_SDL_EVENT_MOUSE_DOWN
                                                  : OPENUI_SDL_EVENT_MOUSE_UP;
        out->button = ev.button.button;
        out->x = ev.button.x;
        out->y = ev.button.y;
        break;
    case SDL_MOUSEMOTION:
        out->kind = OPENUI_SDL_EVENT_MOUSE_MOTION;
        out->x = ev.motion.x;
        out->y = ev.motion.y;
        break;
    default:
        out->kind = OPENUI_SDL_EVENT_OTHER;
        break;
    }
    return 1;
}

OPENUI_SDL_HOST_API int32_t openui_sdl_host_v1_present(
    void *host, const uint8_t *rgba, int32_t width, int32_t height,
    int32_t pitch)
{
    sdl_host *h = host;
    if (!h || !rgba || width != h->pixel_w || height != h->pixel_h) {
        snprintf(last_error, sizeof last_error,
                 "present: bitmap %dx%d != texture %dx%d", (int)width, (int)height,
                 h ? (int)h->pixel_w : -1, h ? (int)h->pixel_h : -1);
        return -1;
    }
    if (!h->vsync && h->min_frame_ms && h->last_present_counter) {
        uint64_t freq = SDL_GetPerformanceFrequency();
        uint64_t elapsed_ms =
            (SDL_GetPerformanceCounter() - h->last_present_counter) * 1000 / freq;
        if (elapsed_ms < h->min_frame_ms)
            SDL_Delay((uint32_t)(h->min_frame_ms - elapsed_ms));
    }
    if (SDL_UpdateTexture(h->texture, NULL, rgba, pitch) != 0) {
        set_error("SDL_UpdateTexture");
        return -1;
    }
    SDL_SetRenderDrawColor(h->renderer, 255, 255, 255, 255);
    SDL_RenderClear(h->renderer);
    SDL_RenderCopy(h->renderer, h->texture, NULL, NULL);
    SDL_RenderPresent(h->renderer);
    h->last_present_counter = SDL_GetPerformanceCounter();
    stats_note_present(h);
    return 0;
}

OPENUI_SDL_HOST_API uint32_t openui_sdl_host_v1_ticks(void)
{
    return SDL_GetTicks();
}

OPENUI_SDL_HOST_API uint64_t openui_sdl_host_v1_performance_counter(void)
{
    return SDL_GetPerformanceCounter();
}

OPENUI_SDL_HOST_API uint64_t openui_sdl_host_v1_performance_frequency(void)
{
    return SDL_GetPerformanceFrequency();
}

OPENUI_SDL_HOST_API void openui_sdl_host_v1_delay(uint32_t milliseconds)
{
    SDL_Delay(milliseconds);
}

OPENUI_SDL_HOST_API void openui_sdl_host_v1_start_text_input(void *host)
{
    (void)host;
    SDL_StartTextInput();
}

OPENUI_SDL_HOST_API void openui_sdl_host_v1_close(void *host)
{
    sdl_host *h = host;
    if (!h) return;
    SDL_DestroyTexture(h->texture);
    SDL_DestroyRenderer(h->renderer);
    SDL_DestroyWindow(h->window);
    free(h);
    SDL_Quit();
}

OPENUI_SDL_HOST_API int32_t openui_sdl_host_v1_drain_main_queue(void)
{
    /* Resolved at first use rather than linked: the entry point is
     * libdispatch's CFRunLoop hook, and the guest process already has the
     * toolchain libdispatch.so loaded (libOpenDispatchHost.so's dependency).
     * Linking it here would pin a second copy's path into this helper. */
    typedef void (*drain_fn)(void *);
    static drain_fn drain;
    static int resolved;
    if (!resolved) {
        drain = (drain_fn)dlsym(RTLD_DEFAULT, "_dispatch_main_queue_callback_4CF");
        resolved = 1;
    }
    if (!drain) return 0;
    drain(NULL);
    return 1;
}
