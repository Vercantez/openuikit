#include "OpenUIKitLiveTransportInternal.h"

#include <limits.h>
#include <string.h>

uint64_t openui_live_atomic_load_u64(const uint64_t *value)
{
    return __atomic_load_n(value, __ATOMIC_ACQUIRE);
}

uint32_t openui_live_atomic_load_u32(const uint32_t *value)
{
    return __atomic_load_n(value, __ATOMIC_ACQUIRE);
}

void openui_live_atomic_store_u64(uint64_t *value, uint64_t replacement)
{
    __atomic_store_n(value, replacement, __ATOMIC_RELEASE);
}

void openui_live_atomic_store_u32(uint32_t *value, uint32_t replacement)
{
    __atomic_store_n(value, replacement, __ATOMIC_RELEASE);
}

uint64_t openui_live_atomic_fetch_add_u64(uint64_t *value, uint64_t addend)
{
    return __atomic_fetch_add(value, addend, __ATOMIC_ACQ_REL);
}

uint64_t openui_live_atomic_fetch_or_u64(uint64_t *value, uint64_t bits)
{
    return __atomic_fetch_or(value, bits, __ATOMIC_ACQ_REL);
}

uint64_t openui_live_atomic_fetch_sub_u64(uint64_t *value, uint64_t subtrahend)
{
    return __atomic_fetch_sub(value, subtrahend, __ATOMIC_ACQ_REL);
}

bool openui_live_atomic_compare_exchange_u64(
    uint64_t *value,
    uint64_t *expected,
    uint64_t replacement
)
{
    return __atomic_compare_exchange_n(
        value, expected, replacement, false, __ATOMIC_ACQ_REL, __ATOMIC_ACQUIRE);
}

bool openui_live_required_size(
    uint64_t frame_capacity,
    uint32_t input_record_capacity,
    uint64_t *result
)
{
    uint64_t frame_bytes;
    uint64_t input_bytes;
    uint64_t total;
    if (!result || frame_capacity == 0 || input_record_capacity == 0) return false;
    if (frame_capacity > (UINT64_MAX - OPENUI_LIVE_TRANSPORT_HEADER_SIZE) / 2) {
        return false;
    }
    frame_bytes = frame_capacity * 2;
    input_bytes = (uint64_t)input_record_capacity
        * OPENUI_LIVE_TRANSPORT_INPUT_RECORD_SIZE;
    if (input_bytes / OPENUI_LIVE_TRANSPORT_INPUT_RECORD_SIZE
        != input_record_capacity) return false;
    total = OPENUI_LIVE_TRANSPORT_HEADER_SIZE + frame_bytes;
    if (input_bytes > UINT64_MAX - total) return false;
    total += input_bytes;
    if (total > SIZE_MAX) return false;
    *result = total;
    return true;
}

bool openui_live_initialize_mapping(
    openui_live_mapping *mapping,
    uint64_t frame_capacity,
    uint32_t input_record_capacity
)
{
    uint64_t required;
    openui_live_transport_header_v1 *header;
    if (!mapping || !mapping->bytes
        || !openui_live_required_size(frame_capacity, input_record_capacity, &required)
        || required != mapping->size) return false;
    memset(mapping->bytes, 0, mapping->size);
    header = (openui_live_transport_header_v1 *)mapping->bytes;
    header->magic = OPENUI_LIVE_TRANSPORT_MAGIC;
    header->abi_version = OPENUI_LIVE_TRANSPORT_ABI_VERSION;
    header->header_size = OPENUI_LIVE_TRANSPORT_HEADER_SIZE;
    header->file_size = required;
    header->frame_capacity = frame_capacity;
    header->input_record_capacity = input_record_capacity;
    header->input_record_size = OPENUI_LIVE_TRANSPORT_INPUT_RECORD_SIZE;
    header->frame_format = OPENUI_LIVE_TRANSPORT_RGBA8888;
    mapping->header = header;
    openui_live_atomic_store_u64(&header->state_flags, OPENUI_LIVE_STATE_HOST_READY);
    return true;
}

bool openui_live_validate_mapping(openui_live_mapping *mapping)
{
    uint64_t required;
    openui_live_transport_header_v1 *header;
    if (!mapping || !mapping->bytes
        || mapping->size < OPENUI_LIVE_TRANSPORT_HEADER_SIZE) return false;
    header = (openui_live_transport_header_v1 *)mapping->bytes;
    if (header->magic != OPENUI_LIVE_TRANSPORT_MAGIC
        || header->abi_version != OPENUI_LIVE_TRANSPORT_ABI_VERSION
        || header->header_size != OPENUI_LIVE_TRANSPORT_HEADER_SIZE
        || header->file_size != mapping->size
        || header->input_record_size != OPENUI_LIVE_TRANSPORT_INPUT_RECORD_SIZE
        || header->frame_format != OPENUI_LIVE_TRANSPORT_RGBA8888
        || !openui_live_required_size(
            header->frame_capacity,
            header->input_record_capacity,
            &required)
        || required != mapping->size) return false;
    mapping->header = header;
    return true;
}

uint8_t *openui_live_frame_slot(openui_live_mapping *mapping, uint32_t slot)
{
    uint64_t offset;
    if (!mapping || !mapping->header || slot > 1) return NULL;
    offset = OPENUI_LIVE_TRANSPORT_HEADER_SIZE
        + (uint64_t)slot * mapping->header->frame_capacity;
    if (offset >= mapping->size) return NULL;
    return mapping->bytes + (size_t)offset;
}

openui_live_input_record_v1 *openui_live_input_slot(
    openui_live_mapping *mapping,
    uint64_t sequence
)
{
    uint64_t offset;
    uint64_t index;
    if (!mapping || !mapping->header || sequence == 0
        || mapping->header->input_record_capacity == 0) return NULL;
    index = (sequence - 1) % mapping->header->input_record_capacity;
    offset = OPENUI_LIVE_TRANSPORT_HEADER_SIZE
        + mapping->header->frame_capacity * 2
        + index * OPENUI_LIVE_TRANSPORT_INPUT_RECORD_SIZE;
    if (offset > mapping->size
        || OPENUI_LIVE_TRANSPORT_INPUT_RECORD_SIZE > mapping->size - offset) {
        return NULL;
    }
    return (openui_live_input_record_v1 *)(mapping->bytes + (size_t)offset);
}
