#ifndef OPENUIKIT_LIVE_TRANSPORT_INTERNAL_H
#define OPENUIKIT_LIVE_TRANSPORT_INTERNAL_H

#include "include/OpenUIKitLiveTransportABI.h"

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

typedef struct openui_live_mapping {
    int descriptor;
    size_t size;
    uint8_t *bytes;
    openui_live_transport_header_v1 *header;
} openui_live_mapping;

bool openui_live_required_size(
    uint64_t frame_capacity,
    uint32_t input_record_capacity,
    uint64_t *result
);

bool openui_live_initialize_mapping(
    openui_live_mapping *mapping,
    uint64_t frame_capacity,
    uint32_t input_record_capacity
);

bool openui_live_validate_mapping(openui_live_mapping *mapping);

uint8_t *openui_live_frame_slot(openui_live_mapping *mapping, uint32_t slot);
openui_live_input_record_v1 *openui_live_input_slot(
    openui_live_mapping *mapping,
    uint64_t sequence
);

uint64_t openui_live_atomic_load_u64(const uint64_t *value);
uint32_t openui_live_atomic_load_u32(const uint32_t *value);
void openui_live_atomic_store_u64(uint64_t *value, uint64_t replacement);
void openui_live_atomic_store_u32(uint32_t *value, uint32_t replacement);
uint64_t openui_live_atomic_fetch_add_u64(uint64_t *value, uint64_t addend);
uint64_t openui_live_atomic_fetch_or_u64(uint64_t *value, uint64_t bits);
uint64_t openui_live_atomic_fetch_sub_u64(uint64_t *value, uint64_t subtrahend);
bool openui_live_atomic_compare_exchange_u64(
    uint64_t *value,
    uint64_t *expected,
    uint64_t replacement
);

#endif
