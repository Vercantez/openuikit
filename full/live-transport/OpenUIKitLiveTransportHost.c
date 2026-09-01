#define _POSIX_C_SOURCE 200809L

#include "include/OpenUIKitLiveTransportHost.h"
#include "include/OpenUIKitLiveTransportGuest.h"
#include "OpenUIKitLiveTransportInternal.h"

#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

struct openui_live_transport_host {
    openui_live_mapping mapping;
};

static openui_live_transport_host *allocate_host(void)
{
    openui_live_transport_host *transport;
    transport = (openui_live_transport_host *)calloc(1, sizeof(*transport));
    if (transport) transport->mapping.descriptor = -1;
    return transport;
}

static bool map_descriptor(
    int descriptor,
    size_t size,
    openui_live_mapping *mapping
)
{
    void *bytes;
    bytes = mmap(NULL, size, PROT_READ | PROT_WRITE, MAP_SHARED, descriptor, 0);
    if (bytes == MAP_FAILED) return false;
    mapping->descriptor = descriptor;
    mapping->size = size;
    mapping->bytes = (uint8_t *)bytes;
    mapping->header = NULL;
    return true;
}

openui_live_transport_host *openui_live_transport_host_create(
    const char *path,
    uint64_t frame_capacity,
    uint32_t input_record_capacity
)
{
    openui_live_transport_host *transport;
    uint64_t required;
    int descriptor;
    if (!path || !path[0]
        || !openui_live_required_size(
            frame_capacity, input_record_capacity, &required)
        || required > INT64_MAX) return NULL;
    descriptor = open(path, O_RDWR | O_CREAT | O_EXCL, 0600);
    if (descriptor < 0) return NULL;
    if (ftruncate(descriptor, (off_t)required) != 0) {
        close(descriptor);
        unlink(path);
        return NULL;
    }
    transport = allocate_host();
    if (!transport
        || !map_descriptor(descriptor, (size_t)required, &transport->mapping)
        || !openui_live_initialize_mapping(
            &transport->mapping, frame_capacity, input_record_capacity)) {
        if (transport && transport->mapping.bytes) {
            munmap(transport->mapping.bytes, transport->mapping.size);
        }
        if (transport) free(transport);
        close(descriptor);
        unlink(path);
        return NULL;
    }
    return transport;
}

openui_live_transport_host *openui_live_transport_host_open(const char *path)
{
    openui_live_transport_host *transport;
    struct stat status;
    int descriptor;
    if (!path || !path[0]) return NULL;
    descriptor = open(path, O_RDWR);
    if (descriptor < 0) return NULL;
    if (fstat(descriptor, &status) != 0 || status.st_size <= 0
        || (uint64_t)status.st_size > SIZE_MAX) {
        close(descriptor);
        return NULL;
    }
    transport = allocate_host();
    if (!transport
        || !map_descriptor(
            descriptor, (size_t)status.st_size, &transport->mapping)
        || !openui_live_validate_mapping(&transport->mapping)) {
        if (transport && transport->mapping.bytes) {
            munmap(transport->mapping.bytes, transport->mapping.size);
        }
        if (transport) free(transport);
        close(descriptor);
        return NULL;
    }
    openui_live_atomic_fetch_or_u64(
        &transport->mapping.header->state_flags,
        OPENUI_LIVE_STATE_HOST_READY);
    return transport;
}

void openui_live_transport_host_close(openui_live_transport_host *transport)
{
    if (!transport) return;
    if (transport->mapping.bytes && transport->mapping.size) {
        munmap(transport->mapping.bytes, transport->mapping.size);
    }
    if (transport->mapping.descriptor >= 0) close(transport->mapping.descriptor);
    free(transport);
}

int32_t openui_live_transport_host_snapshot(
    openui_live_transport_host *transport,
    openui_live_frame_snapshot_v1 *snapshot,
    uint8_t *destination,
    uint64_t destination_capacity
)
{
    openui_live_transport_header_v1 *header;
    uint64_t before;
    uint64_t after;
    uint64_t byte_count;
    uint64_t claim;
    uint64_t slot_sequence;
    uint32_t active;
    uint8_t *source;
    unsigned attempt;
    if (!transport || !transport->mapping.header || !snapshot || !destination) {
        return OPENUI_LIVE_ERROR_ARGUMENT;
    }
    header = transport->mapping.header;
    for (attempt = 0; attempt < 8; attempt++) {
        before = openui_live_atomic_load_u64(&header->frame_sequence);
        if (before == 0) return OPENUI_LIVE_NO_EVENT;
        active = openui_live_atomic_load_u32(&header->active_frame_slot);
        if (active > 1) return OPENUI_LIVE_ERROR_PROTOCOL;
        claim = openui_live_atomic_load_u64(&header->frame_slot_claims[active]);
        if ((claim & OPENUI_LIVE_FRAME_CLAIM_WRITER) != 0
            || (claim & OPENUI_LIVE_FRAME_CLAIM_READERS_MASK)
                == OPENUI_LIVE_FRAME_CLAIM_READERS_MASK) {
            continue;
        }
        if (!openui_live_atomic_compare_exchange_u64(
                &header->frame_slot_claims[active], &claim, claim + 1)) {
            continue;
        }
        if (openui_live_atomic_load_u64(&header->frame_sequence) != before
            || openui_live_atomic_load_u32(&header->active_frame_slot) != active) {
            openui_live_atomic_fetch_sub_u64(
                &header->frame_slot_claims[active], 1);
            continue;
        }
        slot_sequence = openui_live_atomic_load_u64(
            &header->frame_slots[active].sequence);
        if (slot_sequence != before) {
            openui_live_atomic_fetch_sub_u64(
                &header->frame_slot_claims[active], 1);
            continue;
        }
        snapshot->width = openui_live_atomic_load_u32(
            &header->frame_slots[active].width);
        snapshot->height = openui_live_atomic_load_u32(
            &header->frame_slots[active].height);
        snapshot->stride = openui_live_atomic_load_u32(
            &header->frame_slots[active].stride);
        snapshot->format = openui_live_atomic_load_u32(
            &header->frame_slots[active].format);
        byte_count = openui_live_atomic_load_u64(
            &header->frame_slots[active].byte_count);
        if (snapshot->width == 0 || snapshot->height == 0
            || snapshot->stride < (uint64_t)snapshot->width * 4
            || snapshot->format != OPENUI_LIVE_TRANSPORT_RGBA8888
            || byte_count != (uint64_t)snapshot->height * snapshot->stride
            || byte_count > header->frame_capacity
            || byte_count > destination_capacity) {
            openui_live_atomic_fetch_sub_u64(
                &header->frame_slot_claims[active], 1);
            return byte_count > destination_capacity
                ? OPENUI_LIVE_ERROR_CAPACITY
                : OPENUI_LIVE_ERROR_PROTOCOL;
        }
        source = openui_live_frame_slot(&transport->mapping, active);
        if (!source) {
            openui_live_atomic_fetch_sub_u64(
                &header->frame_slot_claims[active], 1);
            return OPENUI_LIVE_ERROR_PROTOCOL;
        }
        memcpy(destination, source, (size_t)byte_count);
        after = openui_live_atomic_load_u64(&header->frame_sequence);
        if (after == before
            && openui_live_atomic_load_u32(&header->active_frame_slot) == active
            && openui_live_atomic_load_u64(
                &header->frame_slots[active].sequence) == before) {
            snapshot->sequence = before;
            snapshot->byte_count = byte_count;
            openui_live_atomic_fetch_add_u64(&header->host_heartbeat, 1);
            openui_live_atomic_fetch_sub_u64(
                &header->frame_slot_claims[active], 1);
            return OPENUI_LIVE_EVENT;
        }
        openui_live_atomic_fetch_sub_u64(
            &header->frame_slot_claims[active], 1);
    }
    return OPENUI_LIVE_ERROR_SEQUENCE;
}

int32_t openui_live_transport_host_enqueue(
    openui_live_transport_host *transport,
    const openui_live_input_record_v1 *record,
    uint64_t *published_sequence
)
{
    openui_live_transport_header_v1 *header;
    openui_live_input_record_v1 *destination;
    uint64_t write_sequence;
    uint64_t read_sequence;
    uint64_t next_sequence;
    if (!transport || !transport->mapping.header || !record
        || record->kind < OPENUI_LIVE_INPUT_TOUCH_DOWN
        || record->kind > OPENUI_LIVE_INPUT_QUIT
        || record->payload_count > OPENUI_LIVE_TRANSPORT_INPUT_PAYLOAD_SIZE) {
        return OPENUI_LIVE_ERROR_ARGUMENT;
    }
    header = transport->mapping.header;
    write_sequence = openui_live_atomic_load_u64(&header->input_write_sequence);
    read_sequence = openui_live_atomic_load_u64(&header->input_read_sequence);
    if (write_sequence == UINT64_MAX) return OPENUI_LIVE_ERROR_SEQUENCE;
    if (write_sequence < read_sequence) return OPENUI_LIVE_ERROR_PROTOCOL;
    if (write_sequence - read_sequence >= header->input_record_capacity) {
        openui_live_atomic_fetch_add_u64(&header->dropped_input_count, 1);
        return OPENUI_LIVE_NO_EVENT;
    }
    next_sequence = write_sequence + 1;
    destination = openui_live_input_slot(&transport->mapping, next_sequence);
    if (!destination) return OPENUI_LIVE_ERROR_PROTOCOL;

    /* Sequence is the per-record commit marker and is release-published last. */
    openui_live_atomic_store_u64(&destination->sequence, 0);
    destination->timestamp_nanoseconds = record->timestamp_nanoseconds;
    destination->kind = record->kind;
    destination->flags = record->flags;
    destination->x = record->x;
    destination->y = record->y;
    destination->touch_id = record->touch_id;
    destination->key = record->key;
    destination->payload_count = record->payload_count;
    destination->reserved_0 = 0;
    memset(destination->payload, 0, sizeof(destination->payload));
    if (record->payload_count) {
        memcpy(destination->payload, record->payload, record->payload_count);
    }
    openui_live_atomic_store_u64(&destination->sequence, next_sequence);
    openui_live_atomic_store_u64(&header->input_write_sequence, next_sequence);
    openui_live_atomic_fetch_add_u64(&header->host_heartbeat, 1);
    if (published_sequence) *published_sequence = next_sequence;
    return OPENUI_LIVE_EVENT;
}

uint64_t openui_live_transport_host_frame_capacity(
    const openui_live_transport_host *transport
)
{
    return transport && transport->mapping.header
        ? transport->mapping.header->frame_capacity : 0;
}

uint64_t openui_live_transport_host_frame_sequence(
    const openui_live_transport_host *transport
)
{
    return transport && transport->mapping.header
        ? openui_live_atomic_load_u64(&transport->mapping.header->frame_sequence) : 0;
}

uint64_t openui_live_transport_host_input_write_sequence(
    const openui_live_transport_host *transport
)
{
    return transport && transport->mapping.header
        ? openui_live_atomic_load_u64(&transport->mapping.header->input_write_sequence) : 0;
}

uint64_t openui_live_transport_host_input_read_sequence(
    const openui_live_transport_host *transport
)
{
    return transport && transport->mapping.header
        ? openui_live_atomic_load_u64(&transport->mapping.header->input_read_sequence) : 0;
}

uint64_t openui_live_transport_host_dropped_input_count(
    const openui_live_transport_host *transport
)
{
    return transport && transport->mapping.header
        ? openui_live_atomic_load_u64(&transport->mapping.header->dropped_input_count) : 0;
}

uint64_t openui_live_transport_host_state_flags(
    const openui_live_transport_host *transport
)
{
    return transport && transport->mapping.header
        ? openui_live_atomic_load_u64(&transport->mapping.header->state_flags) : 0;
}

void openui_live_transport_host_request_quit(openui_live_transport_host *transport)
{
    if (!transport || !transport->mapping.header) return;
    openui_live_atomic_fetch_or_u64(
        &transport->mapping.header->state_flags,
        OPENUI_LIVE_STATE_HOST_QUIT);
}
