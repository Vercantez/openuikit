#define _POSIX_C_SOURCE 200809L

#include "include/OpenUIKitLiveTransportGuest.h"
#include "OpenUIKitLiveTransportInternal.h"

#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

struct openui_live_transport_guest {
    openui_live_mapping mapping;
};

static bool map_existing(const char *path, openui_live_mapping *mapping)
{
    struct stat status;
    void *bytes;
    int descriptor;
    if (!path || !path[0] || !mapping) return false;
    descriptor = open(path, O_RDWR);
    if (descriptor < 0) return false;
    if (fstat(descriptor, &status) != 0 || status.st_size <= 0
        || (uint64_t)status.st_size > SIZE_MAX) {
        close(descriptor);
        return false;
    }
    bytes = mmap(NULL, (size_t)status.st_size,
        PROT_READ | PROT_WRITE, MAP_SHARED, descriptor, 0);
    if (bytes == MAP_FAILED) {
        close(descriptor);
        return false;
    }
    mapping->descriptor = descriptor;
    mapping->size = (size_t)status.st_size;
    mapping->bytes = (uint8_t *)bytes;
    mapping->header = NULL;
    if (!openui_live_validate_mapping(mapping)) {
        munmap(bytes, mapping->size);
        close(descriptor);
        memset(mapping, 0, sizeof(*mapping));
        mapping->descriptor = -1;
        return false;
    }
    return true;
}

openui_live_transport_guest *openui_live_transport_guest_open(const char *path)
{
    openui_live_transport_guest *transport;
    transport = (openui_live_transport_guest *)calloc(1, sizeof(*transport));
    if (!transport) return NULL;
    transport->mapping.descriptor = -1;
    if (!map_existing(path, &transport->mapping)) {
        free(transport);
        return NULL;
    }
    openui_live_atomic_fetch_or_u64(
        &transport->mapping.header->state_flags,
        OPENUI_LIVE_STATE_GUEST_READY);
    return transport;
}

void openui_live_transport_guest_close(openui_live_transport_guest *transport)
{
    if (!transport) return;
    if (transport->mapping.header) {
        openui_live_atomic_fetch_or_u64(
            &transport->mapping.header->state_flags,
            OPENUI_LIVE_STATE_GUEST_QUIT);
    }
    if (transport->mapping.bytes && transport->mapping.size) {
        munmap(transport->mapping.bytes, transport->mapping.size);
    }
    if (transport->mapping.descriptor >= 0) close(transport->mapping.descriptor);
    free(transport);
}

int32_t openui_live_transport_guest_publish_rgba(
    openui_live_transport_guest *transport,
    uint32_t width,
    uint32_t height,
    uint32_t stride,
    const uint8_t *bytes,
    uint64_t byte_count
)
{
    openui_live_transport_header_v1 *header;
    uint64_t expected;
    uint64_t sequence;
    uint64_t expected_claim;
    uint32_t active;
    uint32_t inactive;
    uint8_t *destination;
    if (!transport || !transport->mapping.header || !bytes
        || width == 0 || height == 0 || stride < width * UINT64_C(4)) {
        return OPENUI_LIVE_ERROR_ARGUMENT;
    }
    if ((uint64_t)height > UINT64_MAX / stride) return OPENUI_LIVE_ERROR_CAPACITY;
    expected = (uint64_t)height * stride;
    header = transport->mapping.header;
    if (byte_count != expected || byte_count > header->frame_capacity) {
        return OPENUI_LIVE_ERROR_CAPACITY;
    }
    sequence = openui_live_atomic_load_u64(&header->frame_sequence);
    if (sequence == UINT64_MAX) return OPENUI_LIVE_ERROR_SEQUENCE;
    active = openui_live_atomic_load_u32(&header->active_frame_slot);
    if (active > 1) return OPENUI_LIVE_ERROR_PROTOCOL;
    inactive = active ^ 1u;
    expected_claim = 0;
    if (!openui_live_atomic_compare_exchange_u64(
            &header->frame_slot_claims[inactive],
            &expected_claim,
            OPENUI_LIVE_FRAME_CLAIM_WRITER)) {
        return OPENUI_LIVE_BUSY;
    }
    if (openui_live_atomic_load_u64(&header->frame_sequence) != sequence
        || openui_live_atomic_load_u32(&header->active_frame_slot) != active) {
        openui_live_atomic_store_u64(&header->frame_slot_claims[inactive], 0);
        return OPENUI_LIVE_BUSY;
    }
    destination = openui_live_frame_slot(&transport->mapping, inactive);
    if (!destination) {
        openui_live_atomic_store_u64(&header->frame_slot_claims[inactive], 0);
        return OPENUI_LIVE_ERROR_PROTOCOL;
    }
    memcpy(destination, bytes, (size_t)byte_count);

    /*
     * Metadata lives beside the exclusively leased inactive slot.  The slot's
     * sequence, active slot, and global sequence form a release-published
     * three-part commit.  Releasing the producer lease last makes both pixels
     * and metadata available to a snapshot reader that acquires its lease.
     */
    openui_live_atomic_store_u32(&header->frame_slots[inactive].width, width);
    openui_live_atomic_store_u32(&header->frame_slots[inactive].height, height);
    openui_live_atomic_store_u32(&header->frame_slots[inactive].stride, stride);
    openui_live_atomic_store_u32(
        &header->frame_slots[inactive].format,
        OPENUI_LIVE_TRANSPORT_RGBA8888);
    openui_live_atomic_store_u64(
        &header->frame_slots[inactive].byte_count, byte_count);
    openui_live_atomic_store_u64(
        &header->frame_slots[inactive].sequence, sequence + 1);
    openui_live_atomic_store_u32(&header->active_frame_slot, inactive);
    openui_live_atomic_store_u64(&header->frame_sequence, sequence + 1);
    openui_live_atomic_fetch_add_u64(&header->guest_heartbeat, 1);
    openui_live_atomic_store_u64(&header->frame_slot_claims[inactive], 0);
    return OPENUI_LIVE_OK;
}

int32_t openui_live_transport_guest_poll_input(
    openui_live_transport_guest *transport,
    openui_live_input_record_v1 *record
)
{
    openui_live_transport_header_v1 *header;
    openui_live_input_record_v1 *source;
    uint64_t read_sequence;
    uint64_t write_sequence;
    uint64_t next_sequence;
    uint64_t record_sequence;
    if (!transport || !transport->mapping.header || !record) {
        return OPENUI_LIVE_ERROR_ARGUMENT;
    }
    header = transport->mapping.header;
    read_sequence = openui_live_atomic_load_u64(&header->input_read_sequence);
    write_sequence = openui_live_atomic_load_u64(&header->input_write_sequence);
    if (read_sequence >= write_sequence) return OPENUI_LIVE_NO_EVENT;
    if (read_sequence == UINT64_MAX) return OPENUI_LIVE_ERROR_SEQUENCE;
    next_sequence = read_sequence + 1;
    source = openui_live_input_slot(&transport->mapping, next_sequence);
    if (!source) return OPENUI_LIVE_ERROR_PROTOCOL;
    record_sequence = openui_live_atomic_load_u64(&source->sequence);
    if (record_sequence != next_sequence) return OPENUI_LIVE_NO_EVENT;
    memcpy(record, source, sizeof(*record));
    if (openui_live_atomic_load_u64(&source->sequence) != next_sequence
        || record->sequence != next_sequence
        || record->payload_count > OPENUI_LIVE_TRANSPORT_INPUT_PAYLOAD_SIZE) {
        return OPENUI_LIVE_ERROR_PROTOCOL;
    }
    openui_live_atomic_store_u64(&header->input_read_sequence, next_sequence);
    return OPENUI_LIVE_EVENT;
}

uint64_t openui_live_transport_guest_frame_sequence(
    const openui_live_transport_guest *transport
)
{
    return transport && transport->mapping.header
        ? openui_live_atomic_load_u64(&transport->mapping.header->frame_sequence)
        : 0;
}

uint64_t openui_live_transport_guest_dropped_input_count(
    const openui_live_transport_guest *transport
)
{
    return transport && transport->mapping.header
        ? openui_live_atomic_load_u64(&transport->mapping.header->dropped_input_count)
        : 0;
}

uint64_t openui_live_transport_guest_state_flags(
    const openui_live_transport_guest *transport
)
{
    return transport && transport->mapping.header
        ? openui_live_atomic_load_u64(&transport->mapping.header->state_flags)
        : 0;
}

void openui_live_transport_guest_request_quit(openui_live_transport_guest *transport)
{
    if (!transport || !transport->mapping.header) return;
    openui_live_atomic_fetch_or_u64(
        &transport->mapping.header->state_flags,
        OPENUI_LIVE_STATE_GUEST_QUIT);
}
