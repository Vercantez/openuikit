#define _POSIX_C_SOURCE 200809L

#include "OpenURLTransportABI.h"

#include <pthread.h>
#include <stdatomic.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

static void fail(const char *message)
{
    fprintf(stderr, "OpenURLTransportHostTests: %s\n", message);
    exit(1);
}

static openui_url_transport_request_v1 request_for(
    const char *url,
    const char *method,
    const char *headers
)
{
    openui_url_transport_request_v1 request = {0};
    request.abi_version = OPENUI_URL_TRANSPORT_ABI_VERSION;
    request.struct_size = sizeof(request);
    request.url_bytes = (const uint8_t *)url;
    request.url_count = strlen(url);
    request.method_bytes = (const uint8_t *)method;
    request.method_count = strlen(method);
    request.header_bytes = (const uint8_t *)headers;
    request.header_count = strlen(headers);
    request.connect_timeout_milliseconds = 2000;
    request.total_timeout_milliseconds = 10000;
    request.maximum_response_header_bytes = OPENUI_URL_TRANSPORT_MAX_RESPONSE_HEADER_BYTES;
    request.maximum_response_body_bytes = OPENUI_URL_TRANSPORT_MAX_RESPONSE_BODY_BYTES;
    return request;
}

static int32_t perform(
    void *operation,
    openui_url_transport_request_v1 *request,
    openui_url_transport_response_v1 *response
)
{
    memset(response, 0, sizeof(*response));
    return openui_url_transport_v1_perform(operation, request, response);
}

static char *joined_url(const char *base, const char *path)
{
    size_t count = strlen(base) + strlen(path);
    char *result = malloc(count + 1);
    if (!result) fail("cannot allocate test URL");
    memcpy(result, base, strlen(base));
    memcpy(result + strlen(base), path, strlen(path) + 1);
    return result;
}

static void require_error(
    openui_url_transport_request_v1 request,
    int32_t expected,
    const char *label
)
{
    void *operation = openui_url_transport_v1_create();
    openui_url_transport_response_v1 response = {0};
    if (!operation) fail("cannot create operation");
    int32_t actual = perform(operation, &request, &response);
    if (actual != expected || response.transport_error != expected) {
        fprintf(stderr, "%s: error=%d response=%d expected=%d\n",
            label, actual, response.transport_error, expected);
        exit(1);
    }
    openui_url_transport_v1_release_response(&response);
    openui_url_transport_v1_destroy(operation);
}

typedef struct slow_context {
    void *operation;
    openui_url_transport_request_v1 request;
    openui_url_transport_response_v1 response;
    atomic_bool entered;
    int32_t result;
} slow_context;

static void *run_slow(void *opaque)
{
    slow_context *context = opaque;
    atomic_store_explicit(&context->entered, true, memory_order_release);
    context->result = perform(context->operation, &context->request, &context->response);
    return NULL;
}

static bool server_saw_slow_request(const char *base)
{
    char *url = joined_url(base, "/slow-entered");
    openui_url_transport_request_v1 request = request_for(url, "GET", "");
    openui_url_transport_response_v1 response = {0};
    void *operation = openui_url_transport_v1_create();
    bool yes = false;
    if (!operation) fail("cannot create poll operation");
    if (perform(operation, &request, &response) == OPENUI_URL_TRANSPORT_OK
        && response.body_count == 3 && response.body_bytes
        && memcmp(response.body_bytes, "yes", 3) == 0)
        yes = true;
    openui_url_transport_v1_release_response(&response);
    openui_url_transport_v1_destroy(operation);
    free(url);
    return yes;
}

static double monotonic_seconds(void)
{
    struct timespec value;
    if (clock_gettime(CLOCK_MONOTONIC, &value) != 0) fail("clock_gettime failed");
    return (double)value.tv_sec + (double)value.tv_nsec / 1000000000.0;
}

int main(int argc, char **argv)
{
    if (argc != 2) fail("expected loopback base URL");
    const char *base = argv[1];
    char *large_url = joined_url(base, "/large");
    char *slow_url = joined_url(base, "/slow");

    openui_url_transport_request_v1 request = request_for(large_url, "GET X", "");
    require_error(request, OPENUI_URL_TRANSPORT_BAD_REQUEST, "invalid-method");

    request = request_for(large_url, "GET", "Bad Header: value\r\n");
    require_error(request, OPENUI_URL_TRANSPORT_BAD_REQUEST, "malformed-header");

    request = request_for(large_url, "GET", "");
    request.maximum_response_body_bytes = OPENUI_URL_TRANSPORT_MAX_RESPONSE_BODY_BYTES + 1ULL;
    require_error(request, OPENUI_URL_TRANSPORT_BAD_REQUEST, "over-hard-limit");

    request = request_for(large_url, "GET", "");
    request.maximum_response_body_bytes = 4;
    require_error(request, OPENUI_URL_TRANSPORT_RESPONSE_TOO_LARGE, "response-limit");

    slow_context slow = {0};
    slow.operation = openui_url_transport_v1_create();
    if (!slow.operation) fail("cannot create slow operation");
    slow.request = request_for(slow_url, "GET", "");
    atomic_init(&slow.entered, false);
    pthread_t thread;
    if (pthread_create(&thread, NULL, run_slow, &slow) != 0) fail("pthread_create failed");
    while (!atomic_load_explicit(&slow.entered, memory_order_acquire)) {
    }
    struct timespec pause = {.tv_sec = 0, .tv_nsec = 20000000};
    bool observed = false;
    for (int attempt = 0; attempt < 100 && !observed; attempt++) {
        observed = server_saw_slow_request(base);
        if (!observed) nanosleep(&pause, NULL);
    }
    if (!observed) fail("slow request never reached server");
    double started = monotonic_seconds();
    openui_url_transport_v1_cancel(slow.operation);
    openui_url_transport_v1_destroy(slow.operation);
    double elapsed = monotonic_seconds() - started;
    if (pthread_join(thread, NULL) != 0) fail("pthread_join failed");
    if (slow.result != OPENUI_URL_TRANSPORT_CANCELLED
        || slow.response.transport_error != OPENUI_URL_TRANSPORT_CANCELLED)
        fail("cancelled perform did not report cancellation");
    if (elapsed > 2.5) fail("destroy did not complete promptly after cancellation");
    openui_url_transport_v1_release_response(&slow.response);

    free(large_url);
    free(slow_url);
    puts("OPEN_URL_TRANSPORT_HOST_OK bounds=hard,response method=token headers=validated cancel-destroy=race-safe");
    return 0;
}
