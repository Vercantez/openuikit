#define _POSIX_C_SOURCE 200809L

#include "include/OpenUIKitLiveTransportGuest.h"
#include "include/OpenUIKitLiveTransportHost.h"

#include <SDL.h>

#include <errno.h>
#include <inttypes.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define DEFAULT_FRAME_CAPACITY (UINT64_C(64) * 1024 * 1024)
#define DEFAULT_INPUT_CAPACITY 256u

typedef struct options {
    const char *transport_path;
    const char *title;
    uint64_t frame_capacity;
    uint32_t input_capacity;
    bool create;
    uint64_t maximum_presented_frames;
} options;

static void usage(const char *program)
{
    fprintf(stderr,
        "usage: %s --transport PATH [--create] [--title TITLE] "
        "[--frame-capacity BYTES] [--input-capacity COUNT] "
        "[--max-presented-frames COUNT]\n",
        program);
    exit(2);
}

static uint64_t parse_u64(const char *text, const char *label)
{
    char *end = NULL;
    unsigned long long value;
    errno = 0;
    value = strtoull(text, &end, 10);
    if (errno || !text[0] || !end || *end) {
        fprintf(stderr, "invalid %s: %s\n", label, text);
        exit(2);
    }
    return (uint64_t)value;
}

static options parse_options(int argc, char **argv)
{
    options result = {
        .transport_path = NULL,
        .title = "Portable UIKit Application",
        .frame_capacity = DEFAULT_FRAME_CAPACITY,
        .input_capacity = DEFAULT_INPUT_CAPACITY,
        .create = false,
        .maximum_presented_frames = 0,
    };
    int index;
    for (index = 1; index < argc; index++) {
        if (strcmp(argv[index], "--transport") == 0 && index + 1 < argc) {
            result.transport_path = argv[++index];
        } else if (strcmp(argv[index], "--title") == 0 && index + 1 < argc) {
            result.title = argv[++index];
        } else if (strcmp(argv[index], "--frame-capacity") == 0
            && index + 1 < argc) {
            result.frame_capacity = parse_u64(argv[++index], "frame capacity");
        } else if (strcmp(argv[index], "--input-capacity") == 0
            && index + 1 < argc) {
            uint64_t value = parse_u64(argv[++index], "input capacity");
            if (value > UINT32_MAX) usage(argv[0]);
            result.input_capacity = (uint32_t)value;
        } else if (strcmp(argv[index], "--max-presented-frames") == 0
            && index + 1 < argc) {
            result.maximum_presented_frames = parse_u64(
                argv[++index], "maximum presented frames");
        } else if (strcmp(argv[index], "--create") == 0) {
            result.create = true;
        } else {
            usage(argv[0]);
        }
    }
    if (!result.transport_path || !result.transport_path[0]
        || result.frame_capacity == 0 || result.input_capacity == 0) {
        usage(argv[0]);
    }
    return result;
}

static uint64_t monotonic_nanoseconds(void)
{
    struct timespec value;
    if (clock_gettime(CLOCK_MONOTONIC, &value) != 0) return 0;
    return (uint64_t)value.tv_sec * UINT64_C(1000000000)
        + (uint64_t)value.tv_nsec;
}

static uint32_t translated_key(SDL_Keycode key)
{
    switch (key) {
    case SDLK_BACKSPACE: return OPENUI_LIVE_KEY_BACKSPACE;
    case SDLK_LEFT: return OPENUI_LIVE_KEY_LEFT;
    case SDLK_RIGHT: return OPENUI_LIVE_KEY_RIGHT;
    case SDLK_UP: return OPENUI_LIVE_KEY_UP;
    case SDLK_DOWN: return OPENUI_LIVE_KEY_DOWN;
    case SDLK_RETURN:
    case SDLK_KP_ENTER: return OPENUI_LIVE_KEY_RETURN;
    default: return 0;
    }
}

static bool enqueue_event(
    openui_live_transport_host *transport,
    openui_live_input_record_v1 *record
)
{
    uint64_t sequence = 0;
    int32_t result = openui_live_transport_host_enqueue(
        transport, record, &sequence);
    if (result < 0) {
        fprintf(stderr, "live input enqueue failed: %d\n", result);
        return false;
    }
    if (result == OPENUI_LIVE_NO_EVENT) {
        fprintf(stderr, "OPENUIKIT_LIVE_INPUT_DROPPED total=%" PRIu64 "\n",
            openui_live_transport_host_dropped_input_count(transport));
        return true;
    }
    printf("OPENUIKIT_LIVE_INPUT sequence=%" PRIu64 " kind=%u\n",
        sequence, record->kind);
    fflush(stdout);
    return true;
}

static void event_point(
    SDL_Renderer *renderer,
    int window_x,
    int window_y,
    float *frame_x,
    float *frame_y
)
{
#if SDL_VERSION_ATLEAST(2, 0, 18)
    SDL_RenderWindowToLogical(renderer, window_x, window_y, frame_x, frame_y);
#else
    int output_width = 0;
    int output_height = 0;
    int logical_width = 0;
    int logical_height = 0;
    SDL_GetRendererOutputSize(renderer, &output_width, &output_height);
    SDL_RenderGetLogicalSize(renderer, &logical_width, &logical_height);
    *frame_x = output_width > 0
        ? (float)window_x * logical_width / output_width : (float)window_x;
    *frame_y = output_height > 0
        ? (float)window_y * logical_height / output_height : (float)window_y;
#endif
}

int main(int argc, char **argv)
{
    options configuration = parse_options(argc, argv);
    openui_live_transport_host *transport;
    openui_live_frame_snapshot_v1 snapshot;
    uint64_t staging_capacity;
    uint8_t *staging;
    SDL_Window *window = NULL;
    SDL_Renderer *renderer = NULL;
    SDL_Texture *texture = NULL;
    uint32_t texture_width = 0;
    uint32_t texture_height = 0;
    uint64_t last_sequence = 0;
    uint64_t presented_frames = 0;
    bool running = true;
    bool touch_down = false;

    transport = configuration.create
        ? openui_live_transport_host_create(
            configuration.transport_path,
            configuration.frame_capacity,
            configuration.input_capacity)
        : openui_live_transport_host_open(configuration.transport_path);
    if (!transport) {
        fprintf(stderr, "cannot %s live transport: %s\n",
            configuration.create ? "create" : "open", configuration.transport_path);
        return 2;
    }
    staging_capacity = openui_live_transport_host_frame_capacity(transport);
    staging = (uint8_t *)malloc((size_t)staging_capacity);
    if (!staging) {
        fputs("cannot allocate live frame staging buffer\n", stderr);
        openui_live_transport_host_close(transport);
        return 2;
    }
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_EVENTS) != 0) {
        fprintf(stderr, "SDL initialization failed: %s\n", SDL_GetError());
        free(staging);
        openui_live_transport_host_close(transport);
        return 2;
    }
    SDL_StartTextInput();
    printf("OPENUIKIT_LIVE_HOST_READY path=%s frame_capacity=%" PRIu64
           " input_capacity=%u\n",
        configuration.transport_path,
        configuration.frame_capacity,
        configuration.input_capacity);
    fflush(stdout);

    while (running) {
        SDL_Event sdl_event;
        while (SDL_PollEvent(&sdl_event)) {
            openui_live_input_record_v1 input;
            memset(&input, 0, sizeof(input));
            input.timestamp_nanoseconds = monotonic_nanoseconds();
            switch (sdl_event.type) {
            case SDL_QUIT:
                input.kind = OPENUI_LIVE_INPUT_QUIT;
                (void)enqueue_event(transport, &input);
                running = false;
                break;
            case SDL_MOUSEBUTTONDOWN:
                if (sdl_event.button.button != SDL_BUTTON_LEFT || !renderer) break;
                touch_down = true;
                input.kind = OPENUI_LIVE_INPUT_TOUCH_DOWN;
                input.touch_id = 0;
                event_point(renderer, sdl_event.button.x, sdl_event.button.y,
                    &input.x, &input.y);
                if (!enqueue_event(transport, &input)) running = false;
                break;
            case SDL_MOUSEMOTION:
                if (!touch_down || !renderer) break;
                input.kind = OPENUI_LIVE_INPUT_TOUCH_MOVE;
                input.touch_id = 0;
                event_point(renderer, sdl_event.motion.x, sdl_event.motion.y,
                    &input.x, &input.y);
                if (!enqueue_event(transport, &input)) running = false;
                break;
            case SDL_MOUSEBUTTONUP:
                if (sdl_event.button.button != SDL_BUTTON_LEFT || !renderer) break;
                touch_down = false;
                input.kind = OPENUI_LIVE_INPUT_TOUCH_UP;
                input.touch_id = 0;
                event_point(renderer, sdl_event.button.x, sdl_event.button.y,
                    &input.x, &input.y);
                if (!enqueue_event(transport, &input)) running = false;
                break;
            case SDL_TEXTINPUT:
                input.kind = OPENUI_LIVE_INPUT_TEXT_UTF8;
                while (input.payload_count < OPENUI_LIVE_TRANSPORT_INPUT_PAYLOAD_SIZE
                    && sdl_event.text.text[input.payload_count] != '\0') {
                    input.payload_count++;
                }
                memcpy(input.payload, sdl_event.text.text, input.payload_count);
                if (!enqueue_event(transport, &input)) running = false;
                break;
            case SDL_KEYDOWN:
                input.key = translated_key(sdl_event.key.keysym.sym);
                if (!input.key) break;
                input.kind = OPENUI_LIVE_INPUT_KEY;
                if (!enqueue_event(transport, &input)) running = false;
                break;
            default:
                break;
            }
        }

        memset(&snapshot, 0, sizeof(snapshot));
        int32_t frame_result = openui_live_transport_host_snapshot(
            transport, &snapshot, staging, staging_capacity);
        if (frame_result < 0) {
            fprintf(stderr, "live frame snapshot failed: %d\n", frame_result);
            running = false;
        } else if (frame_result == OPENUI_LIVE_EVENT
            && snapshot.sequence != last_sequence) {
            if (!window) {
                window = SDL_CreateWindow(configuration.title,
                    SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
                    (int)snapshot.width, (int)snapshot.height,
                    SDL_WINDOW_RESIZABLE | SDL_WINDOW_ALLOW_HIGHDPI);
                renderer = window ? SDL_CreateRenderer(
                    window, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC) : NULL;
                if (!renderer && window) {
                    renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_SOFTWARE);
                }
                if (!window || !renderer
                    || SDL_RenderSetLogicalSize(
                        renderer, (int)snapshot.width, (int)snapshot.height) != 0) {
                    fprintf(stderr, "SDL window/renderer creation failed: %s\n", SDL_GetError());
                    running = false;
                    continue;
                }
            }
            if (!texture || texture_width != snapshot.width
                || texture_height != snapshot.height) {
                if (texture) SDL_DestroyTexture(texture);
                texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGBA32,
                    SDL_TEXTUREACCESS_STREAMING,
                    (int)snapshot.width, (int)snapshot.height);
                texture_width = snapshot.width;
                texture_height = snapshot.height;
            }
            if (!texture
                || SDL_UpdateTexture(texture, NULL, staging, (int)snapshot.stride) != 0
                || SDL_RenderClear(renderer) != 0
                || SDL_RenderCopy(renderer, texture, NULL, NULL) != 0) {
                fprintf(stderr, "SDL frame presentation failed: %s\n", SDL_GetError());
                running = false;
                continue;
            }
            SDL_RenderPresent(renderer);
            last_sequence = snapshot.sequence;
            presented_frames++;
            printf("OPENUIKIT_LIVE_FRAME sequence=%" PRIu64
                   " width=%u height=%u bytes=%" PRIu64 "\n",
                snapshot.sequence, snapshot.width, snapshot.height, snapshot.byte_count);
            fflush(stdout);
            if (configuration.maximum_presented_frames
                && presented_frames >= configuration.maximum_presented_frames) {
                running = false;
            }
        }
        if ((openui_live_transport_host_state_flags(transport)
            & OPENUI_LIVE_STATE_GUEST_QUIT) != 0) running = false;
        SDL_Delay(4);
    }

    openui_live_transport_host_request_quit(transport);
    if (texture) SDL_DestroyTexture(texture);
    if (renderer) SDL_DestroyRenderer(renderer);
    if (window) SDL_DestroyWindow(window);
    SDL_StopTextInput();
    SDL_Quit();
    free(staging);
    openui_live_transport_host_close(transport);
    printf("OPENUIKIT_LIVE_HOST_EXIT frames=%" PRIu64 " last_sequence=%" PRIu64 "\n",
        presented_frames, last_sequence);
    return 0;
}
