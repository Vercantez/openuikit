#ifndef OPENUIKIT_OPEN_URL_TRANSPORT_ABI_H
#define OPENUIKIT_OPEN_URL_TRANSPORT_ABI_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#if defined(__GNUC__)
#define OPENUI_URL_TRANSPORT_API __attribute__((visibility("default")))
#else
#define OPENUI_URL_TRANSPORT_API
#endif

/*
 * A deliberately narrow, versioned ABI between a Darwin-ABI Mach-O guest and
 * the Linux host transport.  No libcurl type, platform struct, callback, or
 * variadic function crosses this line.  Buffers in a request remain owned by
 * the caller for the duration of perform(); buffers in a response remain
 * owned by the transport until release_response().
 */
#define OPENUI_URL_TRANSPORT_ABI_VERSION 1u
#define OPENUI_URL_TRANSPORT_MAX_URL_BYTES 65536u
#define OPENUI_URL_TRANSPORT_MAX_METHOD_BYTES 64u
#define OPENUI_URL_TRANSPORT_MAX_REQUEST_HEADER_BYTES 1048576u
#define OPENUI_URL_TRANSPORT_MAX_REQUEST_BODY_BYTES 536870912u
#define OPENUI_URL_TRANSPORT_MAX_RESPONSE_HEADER_BYTES 4194304u
#define OPENUI_URL_TRANSPORT_MAX_RESPONSE_BODY_BYTES 536870912u

typedef enum openui_url_transport_error_v1 {
    OPENUI_URL_TRANSPORT_OK = 0,
    OPENUI_URL_TRANSPORT_BAD_URL = 1,
    OPENUI_URL_TRANSPORT_UNSUPPORTED_SCHEME = 2,
    OPENUI_URL_TRANSPORT_DNS_FAILURE = 3,
    OPENUI_URL_TRANSPORT_CONNECT_FAILURE = 4,
    OPENUI_URL_TRANSPORT_TIMEOUT = 5,
    OPENUI_URL_TRANSPORT_CONNECTION_LOST = 6,
    OPENUI_URL_TRANSPORT_TLS_FAILURE = 7,
    OPENUI_URL_TRANSPORT_RECEIVE_FAILURE = 8,
    OPENUI_URL_TRANSPORT_SEND_FAILURE = 9,
    OPENUI_URL_TRANSPORT_OUT_OF_MEMORY = 10,
    OPENUI_URL_TRANSPORT_CANCELLED = 11,
    OPENUI_URL_TRANSPORT_BAD_REQUEST = 12,
    OPENUI_URL_TRANSPORT_UNAVAILABLE = 13,
    OPENUI_URL_TRANSPORT_INTERNAL = 14,
    OPENUI_URL_TRANSPORT_RESPONSE_TOO_LARGE = 15
} openui_url_transport_error_v1;

typedef struct openui_url_transport_request_v1 {
    uint32_t abi_version;
    uint32_t struct_size;
    const uint8_t *url_bytes;
    uint64_t url_count;
    const uint8_t *method_bytes;
    uint64_t method_count;
    const uint8_t *header_bytes;
    uint64_t header_count;
    const uint8_t *body_bytes;
    uint64_t body_count;
    uint64_t connect_timeout_milliseconds;
    uint64_t total_timeout_milliseconds;
    uint64_t maximum_response_header_bytes;
    uint64_t maximum_response_body_bytes;
} openui_url_transport_request_v1;

typedef struct openui_url_transport_response_v1 {
    uint32_t abi_version;
    uint32_t struct_size;
    int32_t transport_error;
    int32_t native_error;
    int64_t status_code;
    uint8_t *effective_url_bytes;
    uint64_t effective_url_count;
    uint8_t *header_bytes;
    uint64_t header_count;
    uint8_t *body_bytes;
    uint64_t body_count;
    uint8_t *error_message_bytes;
    uint64_t error_message_count;
} openui_url_transport_response_v1;

/* Both compilers must prove the same arm64-width wire layout. */
#ifdef __cplusplus
#define OPENUI_URL_TRANSPORT_STATIC_ASSERT static_assert
#else
#define OPENUI_URL_TRANSPORT_STATIC_ASSERT _Static_assert
#endif
OPENUI_URL_TRANSPORT_STATIC_ASSERT(sizeof(void *) == 8,
    "OpenURLTransport requires a 64-bit pointer ABI");
OPENUI_URL_TRANSPORT_STATIC_ASSERT(sizeof(openui_url_transport_request_v1) == 104,
    "OpenURLTransport request layout drifted");
OPENUI_URL_TRANSPORT_STATIC_ASSERT(offsetof(openui_url_transport_request_v1, url_bytes) == 8,
    "OpenURLTransport request.url_bytes offset drifted");
OPENUI_URL_TRANSPORT_STATIC_ASSERT(offsetof(openui_url_transport_request_v1, method_bytes) == 24,
    "OpenURLTransport request.method_bytes offset drifted");
OPENUI_URL_TRANSPORT_STATIC_ASSERT(offsetof(openui_url_transport_request_v1, header_bytes) == 40,
    "OpenURLTransport request.header_bytes offset drifted");
OPENUI_URL_TRANSPORT_STATIC_ASSERT(offsetof(openui_url_transport_request_v1, body_bytes) == 56,
    "OpenURLTransport request.body_bytes offset drifted");
OPENUI_URL_TRANSPORT_STATIC_ASSERT(offsetof(openui_url_transport_request_v1,
    connect_timeout_milliseconds) == 72,
    "OpenURLTransport request timeout offset drifted");
OPENUI_URL_TRANSPORT_STATIC_ASSERT(offsetof(openui_url_transport_request_v1,
    maximum_response_header_bytes) == 88,
    "OpenURLTransport request response-limit offset drifted");
OPENUI_URL_TRANSPORT_STATIC_ASSERT(sizeof(openui_url_transport_response_v1) == 88,
    "OpenURLTransport response layout drifted");
OPENUI_URL_TRANSPORT_STATIC_ASSERT(offsetof(openui_url_transport_response_v1, status_code) == 16,
    "OpenURLTransport response.status_code offset drifted");
OPENUI_URL_TRANSPORT_STATIC_ASSERT(offsetof(openui_url_transport_response_v1,
    effective_url_bytes) == 24,
    "OpenURLTransport response.effective_url_bytes offset drifted");
OPENUI_URL_TRANSPORT_STATIC_ASSERT(offsetof(openui_url_transport_response_v1, header_bytes) == 40,
    "OpenURLTransport response.header_bytes offset drifted");
OPENUI_URL_TRANSPORT_STATIC_ASSERT(offsetof(openui_url_transport_response_v1, body_bytes) == 56,
    "OpenURLTransport response.body_bytes offset drifted");
OPENUI_URL_TRANSPORT_STATIC_ASSERT(offsetof(openui_url_transport_response_v1,
    error_message_bytes) == 72,
    "OpenURLTransport response.error_message_bytes offset drifted");
#undef OPENUI_URL_TRANSPORT_STATIC_ASSERT

/*
 * One caller owns an operation. Exactly one perform() may be active. cancel()
 * may race perform(), and destroy() may race an already-active perform():
 * destroy() blocks until that perform has returned. No new API call may begin
 * after destroy() is invoked. This makes the guest object's lifetime rule
 * explicit without exposing a host mutex or reference-count layout in the ABI.
 */
OPENUI_URL_TRANSPORT_API void *openui_url_transport_v1_create(void);
OPENUI_URL_TRANSPORT_API int32_t openui_url_transport_v1_perform(
    void *operation,
    const openui_url_transport_request_v1 *request,
    openui_url_transport_response_v1 *response
);
OPENUI_URL_TRANSPORT_API void openui_url_transport_v1_cancel(void *operation);
OPENUI_URL_TRANSPORT_API void openui_url_transport_v1_destroy(void *operation);
OPENUI_URL_TRANSPORT_API void openui_url_transport_v1_release_response(
    openui_url_transport_response_v1 *response
);

#ifdef __cplusplus
}
#endif

#undef OPENUI_URL_TRANSPORT_API

#endif
