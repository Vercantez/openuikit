#ifndef OPENUIKIT_LIVE_TRANSPORT_GUEST_H
#define OPENUIKIT_LIVE_TRANSPORT_GUEST_H

#include "OpenUIKitLiveTransportABI.h"

#ifdef __cplusplus
extern "C" {
#endif

#if defined(__GNUC__)
#define OPENUI_LIVE_API __attribute__((visibility("default")))
#else
#define OPENUI_LIVE_API
#endif

typedef struct openui_live_transport_guest openui_live_transport_guest;

/* Return values shared by the guest and native host implementations. */
#define OPENUI_LIVE_OK 0
#define OPENUI_LIVE_NO_EVENT 0
#define OPENUI_LIVE_EVENT 1
#define OPENUI_LIVE_BUSY 2
#define OPENUI_LIVE_ERROR_ARGUMENT (-1)
#define OPENUI_LIVE_ERROR_SYSTEM (-2)
#define OPENUI_LIVE_ERROR_PROTOCOL (-3)
#define OPENUI_LIVE_ERROR_CAPACITY (-4)
#define OPENUI_LIVE_ERROR_SEQUENCE (-5)

/*
 * Attach to an existing host-created transport file.  A live guest never
 * creates, truncates, or resizes the file, so a typo cannot destroy an
 * unrelated path.  The caller owns the returned opaque context.
 */
OPENUI_LIVE_API openui_live_transport_guest *
openui_live_transport_guest_open(const char *path);

OPENUI_LIVE_API void
openui_live_transport_guest_close(openui_live_transport_guest *transport);

/*
 * Publish a complete RGBA8888 frame.  The producer exclusively leases the
 * inactive slot, writes its pixels and metadata, then release-publishes its
 * sequence.  OPENUI_LIVE_BUSY means a consumer still holds that slot and the
 * caller should skip or retry the frame.  byte_count must equal height *
 * stride and fit the host-advertised frame capacity.
 */
OPENUI_LIVE_API int32_t openui_live_transport_guest_publish_rgba(
    openui_live_transport_guest *transport,
    uint32_t width,
    uint32_t height,
    uint32_t stride,
    const uint8_t *bytes,
    uint64_t byte_count
);

/* Poll the single-producer input ring in exact sequence order. */
OPENUI_LIVE_API int32_t openui_live_transport_guest_poll_input(
    openui_live_transport_guest *transport,
    openui_live_input_record_v1 *record
);

OPENUI_LIVE_API uint64_t openui_live_transport_guest_frame_sequence(
    const openui_live_transport_guest *transport
);

OPENUI_LIVE_API uint64_t openui_live_transport_guest_dropped_input_count(
    const openui_live_transport_guest *transport
);

OPENUI_LIVE_API uint64_t openui_live_transport_guest_state_flags(
    const openui_live_transport_guest *transport
);

OPENUI_LIVE_API void openui_live_transport_guest_request_quit(
    openui_live_transport_guest *transport
);

#ifdef __cplusplus
}
#endif

#undef OPENUI_LIVE_API

#endif
