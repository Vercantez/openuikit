#define _POSIX_C_SOURCE 200809L

#include "OpenUIKitLiveTransportGuest.h"
#include "OpenUIKitLiveTransportHost.h"

#include <assert.h>
#include <fcntl.h>
#include <pthread.h>
#include <sched.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>

static void require_bytes(const uint8_t *actual, const uint8_t *expected, size_t count)
{
    if (memcmp(actual, expected, count) != 0) {
        fputs("live transport bytes differ\n", stderr);
        abort();
    }
}

#define STRESS_FRAME_BYTES (64u * 64u * 4u)
#ifndef STRESS_FINAL_SEQUENCE
#define STRESS_FINAL_SEQUENCE 2000u
#endif
#ifndef STRESS_MAX_SNAPSHOTS
#define STRESS_MAX_SNAPSHOTS 100000u
#endif

typedef struct stress_context {
    openui_live_transport_guest *guest;
    uint64_t busy_count;
} stress_context;

static void *publish_stress_frames(void *raw_context)
{
    stress_context *context = (stress_context *)raw_context;
    uint8_t bytes[STRESS_FRAME_BYTES];
    uint64_t sequence;
    for (sequence = 3; sequence <= STRESS_FINAL_SEQUENCE; sequence++) {
        int32_t result;
        memset(bytes, (int)(sequence & 0xff), sizeof(bytes));
        do {
            result = openui_live_transport_guest_publish_rgba(
                context->guest, 64, 64, 256, bytes, sizeof(bytes));
            if (result == OPENUI_LIVE_BUSY) {
                context->busy_count += 1;
                sched_yield();
            }
        } while (result == OPENUI_LIVE_BUSY);
        assert(result == OPENUI_LIVE_OK);
    }
    return NULL;
}

int main(void)
{
    char path[] = "/private/tmp/openui-live-transport-test-XXXXXX";
    uint8_t first_frame[16] = {
        255, 0, 0, 255, 0, 255, 0, 255,
        0, 0, 255, 255, 255, 255, 255, 255,
    };
    uint8_t second_frame[16] = {
        1, 2, 3, 4, 5, 6, 7, 8,
        9, 10, 11, 12, 13, 14, 15, 16,
    };
    uint8_t snapshot_bytes[STRESS_FRAME_BYTES];
    openui_live_frame_snapshot_v1 snapshot;
    openui_live_input_record_v1 event;
    openui_live_input_record_v1 received;
    openui_live_transport_host *host;
    openui_live_transport_host *second_host;
    openui_live_transport_guest *guest;
    openui_live_transport_header_v1 *wire_header;
    stress_context stress;
    pthread_t publisher;
    uint64_t last_validated_sequence = 0;
    uint64_t sequence = 0;
    int descriptor = mkstemp(path);
    assert(descriptor >= 0);
    assert(close(descriptor) == 0);
    assert(unlink(path) == 0);

    host = openui_live_transport_host_create(path, sizeof(snapshot_bytes), 2);
    assert(host != NULL);
    assert(openui_live_transport_host_frame_capacity(host) == sizeof(snapshot_bytes));
    assert(openui_live_transport_host_snapshot(
        host, &snapshot, snapshot_bytes, sizeof(snapshot_bytes)) == OPENUI_LIVE_NO_EVENT);

    /* Exclusive creation may never truncate a live session. */
    assert(openui_live_transport_host_create(path, sizeof(snapshot_bytes), 2) == NULL);
    second_host = openui_live_transport_host_open(path);
    assert(second_host != NULL);
    openui_live_transport_host_close(second_host);

    guest = openui_live_transport_guest_open(path);
    assert(guest != NULL);
    assert((openui_live_transport_host_state_flags(host)
        & (OPENUI_LIVE_STATE_HOST_READY | OPENUI_LIVE_STATE_GUEST_READY))
        == (OPENUI_LIVE_STATE_HOST_READY | OPENUI_LIVE_STATE_GUEST_READY));

    assert(openui_live_transport_guest_publish_rgba(
        guest, 2, 2, 8, first_frame, sizeof(first_frame)) == OPENUI_LIVE_OK);
    memset(&snapshot, 0, sizeof(snapshot));
    memset(snapshot_bytes, 0, sizeof(snapshot_bytes));
    assert(openui_live_transport_host_snapshot(
        host, &snapshot, snapshot_bytes, sizeof(snapshot_bytes)) == OPENUI_LIVE_EVENT);
    assert(snapshot.sequence == 1);
    assert(snapshot.width == 2 && snapshot.height == 2 && snapshot.stride == 8);
    assert(snapshot.format == OPENUI_LIVE_TRANSPORT_RGBA8888);
    assert(snapshot.byte_count == sizeof(first_frame));
    require_bytes(snapshot_bytes, first_frame, sizeof(first_frame));

    /* A reader lease makes wraparound explicit backpressure, never a race. */
    descriptor = open(path, O_RDWR);
    assert(descriptor >= 0);
    wire_header = (openui_live_transport_header_v1 *)mmap(
        NULL, OPENUI_LIVE_TRANSPORT_HEADER_SIZE,
        PROT_READ | PROT_WRITE, MAP_SHARED, descriptor, 0);
    assert(wire_header != MAP_FAILED);
    assert(__atomic_load_n(&wire_header->active_frame_slot, __ATOMIC_ACQUIRE) == 1);
    __atomic_store_n(&wire_header->frame_slot_claims[0], 1, __ATOMIC_RELEASE);
    assert(openui_live_transport_guest_publish_rgba(
        guest, 2, 2, 8, second_frame, sizeof(second_frame)) == OPENUI_LIVE_BUSY);
    assert(openui_live_transport_guest_frame_sequence(guest) == 1);
    __atomic_store_n(&wire_header->frame_slot_claims[0], 0, __ATOMIC_RELEASE);
    assert(munmap(wire_header, OPENUI_LIVE_TRANSPORT_HEADER_SIZE) == 0);
    assert(close(descriptor) == 0);

    /* The next successful publication must select the other frame slot. */
    assert(openui_live_transport_guest_publish_rgba(
        guest, 2, 2, 8, second_frame, sizeof(second_frame)) == OPENUI_LIVE_OK);
    assert(openui_live_transport_host_snapshot(
        host, &snapshot, snapshot_bytes, sizeof(snapshot_bytes)) == OPENUI_LIVE_EVENT);
    assert(snapshot.sequence == 2);
    require_bytes(snapshot_bytes, second_frame, sizeof(second_frame));
    assert(openui_live_transport_guest_publish_rgba(
        guest, 2, 2, 8, second_frame, 15) == OPENUI_LIVE_ERROR_CAPACITY);

    /* Concurrent publication/snapshot must never expose a torn frame slot. */
    stress.guest = guest;
    stress.busy_count = 0;
    assert(pthread_create(&publisher, NULL, publish_stress_frames, &stress) == 0);
    for (unsigned attempt = 0; attempt < STRESS_MAX_SNAPSHOTS; attempt++) {
        int32_t result = openui_live_transport_host_snapshot(
            host, &snapshot, snapshot_bytes, sizeof(snapshot_bytes));
        if (result == OPENUI_LIVE_ERROR_SEQUENCE) continue;
        assert(result == OPENUI_LIVE_EVENT);
        assert(snapshot.sequence >= 2 && snapshot.sequence <= STRESS_FINAL_SEQUENCE);
        if (snapshot.sequence > 2
            && snapshot.sequence != last_validated_sequence) {
            uint8_t expected = (uint8_t)(snapshot.sequence & 0xff);
            for (uint64_t index = 0; index < snapshot.byte_count; index++) {
                assert(snapshot_bytes[index] == expected);
            }
            last_validated_sequence = snapshot.sequence;
        }
        if (snapshot.sequence == STRESS_FINAL_SEQUENCE) break;
        sched_yield();
    }
    assert(pthread_join(publisher, NULL) == 0);
    assert(openui_live_transport_host_snapshot(
        host, &snapshot, snapshot_bytes, sizeof(snapshot_bytes)) == OPENUI_LIVE_EVENT);
    assert(snapshot.sequence == STRESS_FINAL_SEQUENCE);
    for (uint64_t index = 0; index < snapshot.byte_count; index++) {
        assert(snapshot_bytes[index] == (uint8_t)(STRESS_FINAL_SEQUENCE & 0xff));
    }

    memset(&event, 0, sizeof(event));
    event.kind = OPENUI_LIVE_INPUT_TOUCH_DOWN;
    event.timestamp_nanoseconds = UINT64_C(123456789);
    event.x = 13.5f;
    event.y = 22.25f;
    event.touch_id = 7;
    assert(openui_live_transport_host_enqueue(host, &event, &sequence)
        == OPENUI_LIVE_EVENT);
    assert(sequence == 1);

    memset(&event, 0, sizeof(event));
    event.kind = OPENUI_LIVE_INPUT_TEXT_UTF8;
    event.timestamp_nanoseconds = UINT64_C(123456999);
    event.payload_count = 5;
    memcpy(event.payload, "Linux", 5);
    assert(openui_live_transport_host_enqueue(host, &event, &sequence)
        == OPENUI_LIVE_EVENT);
    assert(sequence == 2);

    /* A full ring is explicit and counted; no unread event is overwritten. */
    event.kind = OPENUI_LIVE_INPUT_QUIT;
    event.payload_count = 0;
    assert(openui_live_transport_host_enqueue(host, &event, &sequence)
        == OPENUI_LIVE_NO_EVENT);
    assert(openui_live_transport_host_dropped_input_count(host) == 1);
    assert(openui_live_transport_guest_dropped_input_count(guest) == 1);

    memset(&received, 0, sizeof(received));
    assert(openui_live_transport_guest_poll_input(guest, &received)
        == OPENUI_LIVE_EVENT);
    assert(received.sequence == 1);
    assert(received.kind == OPENUI_LIVE_INPUT_TOUCH_DOWN);
    assert(received.timestamp_nanoseconds == UINT64_C(123456789));
    assert(received.x == 13.5f && received.y == 22.25f && received.touch_id == 7);
    assert(openui_live_transport_guest_poll_input(guest, &received)
        == OPENUI_LIVE_EVENT);
    assert(received.sequence == 2);
    assert(received.kind == OPENUI_LIVE_INPUT_TEXT_UTF8);
    assert(received.payload_count == 5);
    require_bytes(received.payload, (const uint8_t *)"Linux", 5);
    assert(openui_live_transport_guest_poll_input(guest, &received)
        == OPENUI_LIVE_NO_EVENT);

    memset(&event, 0, sizeof(event));
    event.kind = OPENUI_LIVE_INPUT_QUIT;
    assert(openui_live_transport_host_enqueue(host, &event, &sequence)
        == OPENUI_LIVE_EVENT);
    assert(sequence == 3);
    assert(openui_live_transport_guest_poll_input(guest, &received)
        == OPENUI_LIVE_EVENT);
    assert(received.sequence == 3 && received.kind == OPENUI_LIVE_INPUT_QUIT);
    assert(openui_live_transport_host_input_write_sequence(host) == 3);
    assert(openui_live_transport_host_input_read_sequence(host) == 3);

    openui_live_transport_host_request_quit(host);
    assert((openui_live_transport_guest_state_flags(guest)
        & OPENUI_LIVE_STATE_HOST_QUIT) != 0);
    openui_live_transport_guest_request_quit(guest);
    assert((openui_live_transport_host_state_flags(host)
        & OPENUI_LIVE_STATE_GUEST_QUIT) != 0);

    openui_live_transport_guest_close(guest);
    openui_live_transport_host_close(host);
    assert(unlink(path) == 0);
    printf("OPENUIKIT_LIVE_TRANSPORT_TEST_OK frames=%u inputs=3 drops=1 torn=0\n",
        STRESS_FINAL_SEQUENCE);
    return 0;
}
