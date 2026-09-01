#ifndef OPENUIKIT_LIVE_TRANSPORT_HOST_H
#define OPENUIKIT_LIVE_TRANSPORT_HOST_H

#include "OpenUIKitLiveTransportABI.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct openui_live_transport_host openui_live_transport_host;

typedef struct openui_live_frame_snapshot_v1 {
    uint64_t sequence;
    uint32_t width;
    uint32_t height;
    uint32_t stride;
    uint32_t format;
    uint64_t byte_count;
} openui_live_frame_snapshot_v1;

/* Create is exclusive and refuses to replace any existing filesystem entry. */
openui_live_transport_host *openui_live_transport_host_create(
    const char *path,
    uint64_t frame_capacity,
    uint32_t input_record_capacity
);

openui_live_transport_host *openui_live_transport_host_open(const char *path);
void openui_live_transport_host_close(openui_live_transport_host *transport);

/*
 * Copy a sequence-consistent frame into caller storage.  Returns 1 for a
 * frame, 0 before the first guest frame, or a negative OPENUI_LIVE_ERROR_*.
 */
int32_t openui_live_transport_host_snapshot(
    openui_live_transport_host *transport,
    openui_live_frame_snapshot_v1 *snapshot,
    uint8_t *destination,
    uint64_t destination_capacity
);

/* Enqueue one event. Returns 1, 0 when the ring is full, or a negative error. */
int32_t openui_live_transport_host_enqueue(
    openui_live_transport_host *transport,
    const openui_live_input_record_v1 *record,
    uint64_t *published_sequence
);

uint64_t openui_live_transport_host_frame_capacity(
    const openui_live_transport_host *transport
);
uint64_t openui_live_transport_host_frame_sequence(
    const openui_live_transport_host *transport
);
uint64_t openui_live_transport_host_input_write_sequence(
    const openui_live_transport_host *transport
);
uint64_t openui_live_transport_host_input_read_sequence(
    const openui_live_transport_host *transport
);
uint64_t openui_live_transport_host_dropped_input_count(
    const openui_live_transport_host *transport
);
uint64_t openui_live_transport_host_state_flags(
    const openui_live_transport_host *transport
);
void openui_live_transport_host_request_quit(
    openui_live_transport_host *transport
);

#ifdef __cplusplus
}
#endif

#endif
