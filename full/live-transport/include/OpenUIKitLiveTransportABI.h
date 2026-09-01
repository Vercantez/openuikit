#ifndef OPENUIKIT_LIVE_TRANSPORT_ABI_H
#define OPENUIKIT_LIVE_TRANSPORT_ABI_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/*
 * A versioned, pointer-free wire layout shared by an ARM64 Mach-O UIKit
 * guest and a native Linux display host.  The backing file contains this
 * header, two equally sized RGBA frame slots, then a fixed input-record ring.
 *
 * Fields participating in publication are deliberately ordinary fixed-width
 * integers.  Producers and consumers access them with acquire/release atomic
 * builtins in the transport implementation; no compiler-specific C atomic
 * type or pthread object crosses the Darwin/Linux ABI boundary.
 */
#define OPENUI_LIVE_TRANSPORT_MAGIC UINT64_C(0x4f55494c49564531)
#define OPENUI_LIVE_TRANSPORT_ABI_VERSION 1u
#define OPENUI_LIVE_TRANSPORT_HEADER_SIZE 256u
#define OPENUI_LIVE_TRANSPORT_INPUT_RECORD_SIZE 128u
#define OPENUI_LIVE_TRANSPORT_INPUT_PAYLOAD_SIZE 80u

#define OPENUI_LIVE_TRANSPORT_RGBA8888 1u

/* static constants remain visible to Swift's Clang importer (UINT64_C macros do not). */
static const uint64_t OPENUI_LIVE_STATE_HOST_READY = UINT64_C(1);
static const uint64_t OPENUI_LIVE_STATE_GUEST_READY = UINT64_C(2);
static const uint64_t OPENUI_LIVE_STATE_HOST_QUIT = UINT64_C(4);
static const uint64_t OPENUI_LIVE_STATE_GUEST_QUIT = UINT64_C(8);

/*
 * Each frame slot has one cross-process lease word.  Bit 63 is the producer
 * lease; the remaining bits count concurrent snapshot readers.  The words
 * are plain fixed-width ABI storage and are accessed only through atomic
 * builtins in the implementation.
 */
#define OPENUI_LIVE_FRAME_CLAIM_WRITER (UINT64_C(1) << 63)
#define OPENUI_LIVE_FRAME_CLAIM_READERS_MASK \
    (OPENUI_LIVE_FRAME_CLAIM_WRITER - UINT64_C(1))

#define OPENUI_LIVE_INPUT_TOUCH_DOWN 1u
#define OPENUI_LIVE_INPUT_TOUCH_MOVE 2u
#define OPENUI_LIVE_INPUT_TOUCH_UP 3u
#define OPENUI_LIVE_INPUT_TOUCH_CANCEL 4u
#define OPENUI_LIVE_INPUT_TEXT_UTF8 5u
#define OPENUI_LIVE_INPUT_KEY 6u
#define OPENUI_LIVE_INPUT_QUIT 7u

#define OPENUI_LIVE_KEY_BACKSPACE 1u
#define OPENUI_LIVE_KEY_LEFT 2u
#define OPENUI_LIVE_KEY_RIGHT 3u
#define OPENUI_LIVE_KEY_UP 4u
#define OPENUI_LIVE_KEY_DOWN 5u
#define OPENUI_LIVE_KEY_RETURN 6u

typedef struct openui_live_transport_header_v1 {
    uint64_t magic;
    uint32_t abi_version;
    uint32_t header_size;
    uint64_t file_size;
    uint64_t frame_capacity;
    uint32_t input_record_capacity;
    uint32_t input_record_size;
    uint32_t frame_format;
    uint32_t active_frame_slot;
    uint64_t frame_sequence;
    uint64_t input_write_sequence;
    uint64_t input_read_sequence;
    uint64_t dropped_input_count;
    uint64_t guest_heartbeat;
    uint64_t host_heartbeat;
    uint64_t state_flags;
    uint64_t frame_slot_claims[2];
    uint8_t reserved_0[8];
    struct {
        uint32_t width;
        uint32_t height;
        uint32_t stride;
        uint32_t format;
        uint64_t byte_count;
        uint64_t sequence;
    } frame_slots[2];
    uint8_t reserved[64];
} openui_live_transport_header_v1;

typedef struct openui_live_input_record_v1 {
    uint64_t sequence;
    uint64_t timestamp_nanoseconds;
    uint32_t kind;
    uint32_t flags;
    float x;
    float y;
    int32_t touch_id;
    uint32_t key;
    uint32_t payload_count;
    uint32_t reserved_0;
    uint8_t payload[OPENUI_LIVE_TRANSPORT_INPUT_PAYLOAD_SIZE];
} openui_live_input_record_v1;

#ifdef __cplusplus
#define OPENUI_LIVE_STATIC_ASSERT static_assert
#else
#define OPENUI_LIVE_STATIC_ASSERT _Static_assert
#endif

OPENUI_LIVE_STATIC_ASSERT(sizeof(void *) == 8,
    "OpenUIKit live transport requires a 64-bit ABI");
OPENUI_LIVE_STATIC_ASSERT(sizeof(float) == 4,
    "OpenUIKit live transport requires IEEE-width float storage");
OPENUI_LIVE_STATIC_ASSERT(sizeof(openui_live_transport_header_v1)
        == OPENUI_LIVE_TRANSPORT_HEADER_SIZE,
    "OpenUIKit live transport header layout drifted");
OPENUI_LIVE_STATIC_ASSERT(offsetof(openui_live_transport_header_v1, file_size) == 16,
    "OpenUIKit live transport file_size offset drifted");
OPENUI_LIVE_STATIC_ASSERT(offsetof(openui_live_transport_header_v1,
        active_frame_slot) == 44,
    "OpenUIKit live transport active frame slot offset drifted");
OPENUI_LIVE_STATIC_ASSERT(offsetof(openui_live_transport_header_v1, frame_sequence) == 48,
    "OpenUIKit live transport frame sequence offset drifted");
OPENUI_LIVE_STATIC_ASSERT(offsetof(openui_live_transport_header_v1,
        input_write_sequence) == 56,
    "OpenUIKit live transport input write sequence offset drifted");
OPENUI_LIVE_STATIC_ASSERT(offsetof(openui_live_transport_header_v1, state_flags) == 96,
    "OpenUIKit live transport state offset drifted");
OPENUI_LIVE_STATIC_ASSERT(offsetof(openui_live_transport_header_v1,
        frame_slot_claims) == 104,
    "OpenUIKit live transport frame-slot claims drifted");
OPENUI_LIVE_STATIC_ASSERT(offsetof(openui_live_transport_header_v1, frame_slots) == 128,
    "OpenUIKit live transport frame-slot descriptors drifted");
OPENUI_LIVE_STATIC_ASSERT(sizeof(((openui_live_transport_header_v1 *)0)->frame_slots[0])
        == 32,
    "OpenUIKit live transport frame-slot descriptor layout drifted");
OPENUI_LIVE_STATIC_ASSERT(sizeof(openui_live_input_record_v1)
        == OPENUI_LIVE_TRANSPORT_INPUT_RECORD_SIZE,
    "OpenUIKit live transport input record layout drifted");
OPENUI_LIVE_STATIC_ASSERT(offsetof(openui_live_input_record_v1, kind) == 16,
    "OpenUIKit live transport input kind offset drifted");
OPENUI_LIVE_STATIC_ASSERT(offsetof(openui_live_input_record_v1, payload) == 48,
    "OpenUIKit live transport input payload offset drifted");

#undef OPENUI_LIVE_STATIC_ASSERT

#ifdef __cplusplus
}
#endif

#endif
