#define _GNU_SOURCE

#include "OpenURLTransportABI.h"

#include <curl/curl.h>
#include <limits.h>
#include <pthread.h>
#include <stdatomic.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

typedef struct transport_operation {
    atomic_bool cancelled;
    atomic_bool timed_out;
    pthread_mutex_t state_lock;
    pthread_cond_t state_changed;
    bool performing;
    bool destroying;
    uint64_t idle_timeout_milliseconds;
    uint64_t last_activity_milliseconds;
    curl_off_t last_download_count;
    curl_off_t last_upload_count;
} transport_operation;

typedef struct byte_buffer {
    uint8_t *bytes;
    size_t count;
    size_t capacity;
    size_t limit;
    bool failed;
    bool exceeded_limit;
} byte_buffer;

static atomic_flag global_init_lock = ATOMIC_FLAG_INIT;
static atomic_bool global_init_finished;
static CURLcode global_init_result = CURLE_FAILED_INIT;

static void ensure_global_init(void)
{
    if (atomic_load_explicit(&global_init_finished, memory_order_acquire)) return;
    while (atomic_flag_test_and_set_explicit(&global_init_lock, memory_order_acquire)) {
    }
    if (!atomic_load_explicit(&global_init_finished, memory_order_relaxed)) {
        global_init_result = curl_global_init(CURL_GLOBAL_DEFAULT);
        atomic_store_explicit(&global_init_finished, true, memory_order_release);
    }
    atomic_flag_clear_explicit(&global_init_lock, memory_order_release);
}

static bool append_bytes(byte_buffer *buffer, const void *bytes, size_t count)
{
    size_t needed;
    size_t capacity;
    uint8_t *grown;

    if (buffer->failed) return false;
    if (count == 0) return true;
    if (!bytes || count > SIZE_MAX - buffer->count) {
        buffer->failed = true;
        return false;
    }
    needed = buffer->count + count;
    if (needed > buffer->limit) {
        buffer->failed = true;
        buffer->exceeded_limit = true;
        return false;
    }
    if (needed > buffer->capacity) {
        capacity = buffer->capacity ? buffer->capacity : 4096;
        while (capacity < needed) {
            if (capacity > SIZE_MAX / 2) {
                capacity = needed;
                break;
            }
            capacity *= 2;
        }
        grown = (uint8_t *)realloc(buffer->bytes, capacity);
        if (!grown) {
            buffer->failed = true;
            return false;
        }
        buffer->bytes = grown;
        buffer->capacity = capacity;
    }
    memcpy(buffer->bytes + buffer->count, bytes, count);
    buffer->count = needed;
    return true;
}

static size_t receive_bytes(char *bytes, size_t size, size_t count, void *context)
{
    byte_buffer *buffer = (byte_buffer *)context;
    size_t total;
    if (size != 0 && count > SIZE_MAX / size) {
        buffer->failed = true;
        return 0;
    }
    total = size * count;
    return append_bytes(buffer, bytes, total) ? total : 0;
}

static uint64_t monotonic_milliseconds(void)
{
    struct timespec value;
    if (clock_gettime(CLOCK_MONOTONIC, &value) != 0) return 0;
    uint64_t seconds = (uint64_t)value.tv_sec;
    if (seconds > UINT64_MAX / 1000) return UINT64_MAX;
    return seconds * 1000 + (uint64_t)value.tv_nsec / 1000000;
}

static int progress_callback(
    void *context,
    curl_off_t download_total,
    curl_off_t download_now,
    curl_off_t upload_total,
    curl_off_t upload_now
)
{
    transport_operation *operation = (transport_operation *)context;
    (void)download_total;
    (void)upload_total;
    if (atomic_load_explicit(&operation->cancelled, memory_order_relaxed)) return 1;
    uint64_t now = monotonic_milliseconds();
    if (download_now != operation->last_download_count
        || upload_now != operation->last_upload_count) {
        operation->last_download_count = download_now;
        operation->last_upload_count = upload_now;
        operation->last_activity_milliseconds = now;
        return 0;
    }
    if (operation->idle_timeout_milliseconds && now
        && operation->last_activity_milliseconds
        && now >= operation->last_activity_milliseconds
        && now - operation->last_activity_milliseconds
            >= operation->idle_timeout_milliseconds) {
        atomic_store_explicit(&operation->timed_out, true, memory_order_relaxed);
        return 1;
    }
    return 0;
}

static uint8_t *duplicate_bytes(const void *bytes, size_t count)
{
    uint8_t *copy;
    if (count == 0) return NULL;
    copy = (uint8_t *)malloc(count);
    if (copy) memcpy(copy, bytes, count);
    return copy;
}

static bool set_error_message(
    openui_url_transport_response_v1 *response,
    const char *message
)
{
    size_t count;
    if (!message || !message[0]) return true;
    count = strlen(message);
    response->error_message_bytes = duplicate_bytes(message, count);
    if (!response->error_message_bytes) return false;
    response->error_message_count = count;
    return true;
}

static void release_response_payload(openui_url_transport_response_v1 *response)
{
    free(response->effective_url_bytes);
    free(response->header_bytes);
    free(response->body_bytes);
    free(response->error_message_bytes);
    response->effective_url_bytes = NULL;
    response->effective_url_count = 0;
    response->header_bytes = NULL;
    response->header_count = 0;
    response->body_bytes = NULL;
    response->body_count = 0;
    response->error_message_bytes = NULL;
    response->error_message_count = 0;
}

static int32_t finish_error_response(
    openui_url_transport_response_v1 *response,
    openui_url_transport_error_v1 error,
    int32_t native_error,
    const char *message
)
{
    release_response_payload(response);
    response->transport_error = error;
    response->native_error = native_error;
    response->status_code = 0;
    if (!set_error_message(response, message)) {
        release_response_payload(response);
        response->transport_error = OPENUI_URL_TRANSPORT_OUT_OF_MEMORY;
        response->native_error = CURLE_OUT_OF_MEMORY;
    }
    return response->transport_error;
}

static openui_url_transport_error_v1 map_curl_error(
    CURLcode code,
    const transport_operation *operation
)
{
    if (code == CURLE_OK) return OPENUI_URL_TRANSPORT_OK;
    if (atomic_load_explicit(&operation->cancelled, memory_order_relaxed))
        return OPENUI_URL_TRANSPORT_CANCELLED;
    if (atomic_load_explicit(&operation->timed_out, memory_order_relaxed))
        return OPENUI_URL_TRANSPORT_TIMEOUT;
    switch (code) {
    case CURLE_URL_MALFORMAT:
        return OPENUI_URL_TRANSPORT_BAD_URL;
    case CURLE_UNSUPPORTED_PROTOCOL:
        return OPENUI_URL_TRANSPORT_UNSUPPORTED_SCHEME;
    case CURLE_COULDNT_RESOLVE_HOST:
    case CURLE_COULDNT_RESOLVE_PROXY:
        return OPENUI_URL_TRANSPORT_DNS_FAILURE;
    case CURLE_COULDNT_CONNECT:
        return OPENUI_URL_TRANSPORT_CONNECT_FAILURE;
    case CURLE_OPERATION_TIMEDOUT:
        return OPENUI_URL_TRANSPORT_TIMEOUT;
    case CURLE_PARTIAL_FILE:
    case CURLE_GOT_NOTHING:
        return OPENUI_URL_TRANSPORT_CONNECTION_LOST;
    case CURLE_SSL_CONNECT_ERROR:
    case CURLE_PEER_FAILED_VERIFICATION:
    case CURLE_SSL_CERTPROBLEM:
    case CURLE_SSL_CIPHER:
    case CURLE_USE_SSL_FAILED:
        return OPENUI_URL_TRANSPORT_TLS_FAILURE;
    case CURLE_RECV_ERROR:
        return OPENUI_URL_TRANSPORT_RECEIVE_FAILURE;
    case CURLE_SEND_ERROR:
    case CURLE_READ_ERROR:
    case CURLE_UPLOAD_FAILED:
        return OPENUI_URL_TRANSPORT_SEND_FAILURE;
    case CURLE_OUT_OF_MEMORY:
        return OPENUI_URL_TRANSPORT_OUT_OF_MEMORY;
    case CURLE_ABORTED_BY_CALLBACK:
        return OPENUI_URL_TRANSPORT_INTERNAL;
    default:
        return OPENUI_URL_TRANSPORT_INTERNAL;
    }
}

static bool valid_utf8(const uint8_t *bytes, size_t count)
{
    size_t index = 0;
    while (index < count) {
        uint8_t first = bytes[index++];
        if (first <= 0x7f) continue;
        size_t continuation_count;
        uint32_t scalar;
        uint32_t minimum;
        if (first >= 0xc2 && first <= 0xdf) {
            continuation_count = 1;
            scalar = first & 0x1f;
            minimum = 0x80;
        } else if (first >= 0xe0 && first <= 0xef) {
            continuation_count = 2;
            scalar = first & 0x0f;
            minimum = 0x800;
        } else if (first >= 0xf0 && first <= 0xf4) {
            continuation_count = 3;
            scalar = first & 0x07;
            minimum = 0x10000;
        } else {
            return false;
        }
        if (continuation_count > count - index) return false;
        for (size_t offset = 0; offset < continuation_count; offset++) {
            uint8_t continuation = bytes[index++];
            if ((continuation & 0xc0) != 0x80) return false;
            scalar = (scalar << 6) | (continuation & 0x3f);
        }
        if (scalar < minimum || scalar > 0x10ffff
            || (scalar >= 0xd800 && scalar <= 0xdfff))
            return false;
    }
    return true;
}

static bool ascii_case_prefix(
    const uint8_t *bytes,
    size_t count,
    const char *prefix
)
{
    size_t prefix_count = strlen(prefix);
    if (count < prefix_count) return false;
    for (size_t index = 0; index < prefix_count; index++) {
        uint8_t byte = bytes[index];
        if (byte >= 'A' && byte <= 'Z') byte = (uint8_t)(byte + ('a' - 'A'));
        if (byte != (uint8_t)prefix[index]) return false;
    }
    return true;
}

static bool valid_request(const openui_url_transport_request_v1 *request)
{
    if (!request || request->abi_version != OPENUI_URL_TRANSPORT_ABI_VERSION
        || request->struct_size != sizeof(*request)
        || !request->url_bytes || !request->url_count
        || !request->method_bytes || !request->method_count)
        return false;
    if (request->url_count > OPENUI_URL_TRANSPORT_MAX_URL_BYTES
        || request->method_count > OPENUI_URL_TRANSPORT_MAX_METHOD_BYTES)
        return false;
    if (request->header_count > OPENUI_URL_TRANSPORT_MAX_REQUEST_HEADER_BYTES
        || request->body_count > OPENUI_URL_TRANSPORT_MAX_REQUEST_BODY_BYTES)
        return false;
    if (request->header_count && !request->header_bytes) return false;
    if (request->body_count && !request->body_bytes) return false;
    if (request->maximum_response_header_bytes
            > OPENUI_URL_TRANSPORT_MAX_RESPONSE_HEADER_BYTES
        || request->maximum_response_body_bytes
            > OPENUI_URL_TRANSPORT_MAX_RESPONSE_BODY_BYTES)
        return false;
    if (memchr(request->url_bytes, 0, (size_t)request->url_count)
        || memchr(request->url_bytes, '\r', (size_t)request->url_count)
        || memchr(request->url_bytes, '\n', (size_t)request->url_count))
        return false;
    if (!valid_utf8(request->url_bytes, (size_t)request->url_count)
        || (!ascii_case_prefix(request->url_bytes, (size_t)request->url_count, "http://")
            && !ascii_case_prefix(request->url_bytes, (size_t)request->url_count, "https://")))
        return false;
    for (size_t index = 0; index < (size_t)request->method_count; index++) {
        uint8_t byte = request->method_bytes[index];
        bool token = (byte >= '0' && byte <= '9')
            || (byte >= 'A' && byte <= 'Z')
            || (byte >= 'a' && byte <= 'z')
            || byte == '!' || byte == '#' || byte == '$' || byte == '%'
            || byte == '&' || byte == '\'' || byte == '*' || byte == '+'
            || byte == '-' || byte == '.' || byte == '^' || byte == '_'
            || byte == '`' || byte == '|' || byte == '~';
        if (!token) return false;
    }
    return true;
}

static char *terminated_copy(const uint8_t *bytes, size_t count)
{
    char *copy;
    if (count == SIZE_MAX) return NULL;
    copy = (char *)malloc(count + 1);
    if (!copy) return NULL;
    memcpy(copy, bytes, count);
    copy[count] = 0;
    return copy;
}

static long bounded_timeout(uint64_t milliseconds)
{
    return milliseconds > (uint64_t)LONG_MAX ? LONG_MAX : (long)milliseconds;
}

typedef enum header_parse_result {
    HEADER_PARSE_OK,
    HEADER_PARSE_MALFORMED,
    HEADER_PARSE_OUT_OF_MEMORY
} header_parse_result;

static struct curl_slist *parse_headers(
    const uint8_t *bytes,
    size_t count,
    header_parse_result *result
)
{
    struct curl_slist *headers = NULL;
    size_t offset = 0;
    *result = HEADER_PARSE_OK;
    while (offset < count) {
        size_t end = offset;
        size_t colon;
        size_t line_count;
        char *line;
        struct curl_slist *grown;
        while (end + 1 < count && !(bytes[end] == '\r' && bytes[end + 1] == '\n')) {
            if (bytes[end] == 0 || bytes[end] == '\r' || bytes[end] == '\n') {
                *result = HEADER_PARSE_MALFORMED;
                curl_slist_free_all(headers);
                return NULL;
            }
            end++;
        }
        if (end + 1 >= count || end == offset) {
            *result = HEADER_PARSE_MALFORMED;
            curl_slist_free_all(headers);
            return NULL;
        }
        colon = offset;
        while (colon < end && bytes[colon] != ':') colon++;
        if (colon == offset || colon == end) {
            *result = HEADER_PARSE_MALFORMED;
            curl_slist_free_all(headers);
            return NULL;
        }
        for (size_t index = offset; index < colon; index++) {
            uint8_t byte = bytes[index];
            bool token = (byte >= '0' && byte <= '9')
                || (byte >= 'A' && byte <= 'Z')
                || (byte >= 'a' && byte <= 'z')
                || byte == '!' || byte == '#' || byte == '$' || byte == '%'
                || byte == '&' || byte == '\'' || byte == '*' || byte == '+'
                || byte == '-' || byte == '.' || byte == '^' || byte == '_'
                || byte == '`' || byte == '|' || byte == '~';
            if (!token) {
                *result = HEADER_PARSE_MALFORMED;
                curl_slist_free_all(headers);
                return NULL;
            }
        }
        for (size_t index = colon + 1; index < end; index++) {
            uint8_t byte = bytes[index];
            if ((byte < 0x20 && byte != '\t') || byte == 0x7f) {
                *result = HEADER_PARSE_MALFORMED;
                curl_slist_free_all(headers);
                return NULL;
            }
        }
        line_count = end - offset;
        line = (char *)malloc(line_count + 1);
        if (!line) {
            *result = HEADER_PARSE_OUT_OF_MEMORY;
            curl_slist_free_all(headers);
            return NULL;
        }
        memcpy(line, bytes + offset, line_count);
        line[line_count] = 0;
        grown = curl_slist_append(headers, line);
        free(line);
        if (!grown) {
            *result = HEADER_PARSE_OUT_OF_MEMORY;
            curl_slist_free_all(headers);
            return NULL;
        }
        headers = grown;
        offset = end + 2;
    }
    return headers;
}

static bool begin_perform(transport_operation *operation)
{
    bool allowed;
    pthread_mutex_lock(&operation->state_lock);
    allowed = !operation->performing && !operation->destroying;
    if (allowed) operation->performing = true;
    pthread_mutex_unlock(&operation->state_lock);
    return allowed;
}

static void end_perform(transport_operation *operation)
{
    pthread_mutex_lock(&operation->state_lock);
    operation->performing = false;
    pthread_cond_broadcast(&operation->state_changed);
    pthread_mutex_unlock(&operation->state_lock);
}

void *openui_url_transport_v1_create(void)
{
    transport_operation *operation = (transport_operation *)calloc(1, sizeof(*operation));
    if (!operation) return NULL;
    atomic_init(&operation->cancelled, false);
    atomic_init(&operation->timed_out, false);
    if (pthread_mutex_init(&operation->state_lock, NULL) != 0) {
        free(operation);
        return NULL;
    }
    if (pthread_cond_init(&operation->state_changed, NULL) != 0) {
        pthread_mutex_destroy(&operation->state_lock);
        free(operation);
        return NULL;
    }
    return operation;
}

void openui_url_transport_v1_cancel(void *opaque)
{
    transport_operation *operation = (transport_operation *)opaque;
    if (operation)
        atomic_store_explicit(&operation->cancelled, true, memory_order_relaxed);
}

void openui_url_transport_v1_destroy(void *opaque)
{
    transport_operation *operation = (transport_operation *)opaque;
    if (!operation) return;
    pthread_mutex_lock(&operation->state_lock);
    operation->destroying = true;
    while (operation->performing)
        pthread_cond_wait(&operation->state_changed, &operation->state_lock);
    pthread_mutex_unlock(&operation->state_lock);
    pthread_cond_destroy(&operation->state_changed);
    pthread_mutex_destroy(&operation->state_lock);
    free(operation);
}

void openui_url_transport_v1_release_response(
    openui_url_transport_response_v1 *response
)
{
    if (!response) return;
    release_response_payload(response);
    memset(response, 0, sizeof(*response));
}

int32_t openui_url_transport_v1_perform(
    void *opaque,
    const openui_url_transport_request_v1 *request,
    openui_url_transport_response_v1 *response
)
{
    transport_operation *operation = (transport_operation *)opaque;
    CURL *curl = NULL;
    CURLcode code = CURLE_FAILED_INIT;
    struct curl_slist *headers = NULL;
    byte_buffer body = {0};
    byte_buffer response_headers = {0};
    char curl_error[CURL_ERROR_SIZE] = {0};
    char *url = NULL;
    char *method = NULL;
    char *effective_url = NULL;
    long status_code = 0;
    header_parse_result header_result = HEADER_PARSE_OK;
    bool active_perform = false;
    openui_url_transport_error_v1 mapped;

    if (!response) return OPENUI_URL_TRANSPORT_BAD_REQUEST;
    memset(response, 0, sizeof(*response));
    response->abi_version = OPENUI_URL_TRANSPORT_ABI_VERSION;
    response->struct_size = sizeof(*response);
    if (!operation || !valid_request(request)) {
        return finish_error_response(response, OPENUI_URL_TRANSPORT_BAD_REQUEST,
            0, "invalid OpenURLTransport request");
    }
    if (!begin_perform(operation)) {
        return finish_error_response(response, OPENUI_URL_TRANSPORT_BAD_REQUEST,
            0, "OpenURLTransport operation is already performing or being destroyed");
    }
    active_perform = true;
    atomic_store_explicit(&operation->timed_out, false, memory_order_relaxed);
    operation->idle_timeout_milliseconds = request->connect_timeout_milliseconds;
    operation->last_activity_milliseconds = monotonic_milliseconds();
    operation->last_download_count = 0;
    operation->last_upload_count = 0;
    response_headers.limit = request->maximum_response_header_bytes
        ? (size_t)request->maximum_response_header_bytes
        : OPENUI_URL_TRANSPORT_MAX_RESPONSE_HEADER_BYTES;
    body.limit = request->maximum_response_body_bytes
        ? (size_t)request->maximum_response_body_bytes
        : OPENUI_URL_TRANSPORT_MAX_RESPONSE_BODY_BYTES;
    url = terminated_copy(request->url_bytes, (size_t)request->url_count);
    method = terminated_copy(request->method_bytes, (size_t)request->method_count);
    if (!url || !method) {
        free(url);
        free(method);
        finish_error_response(response, OPENUI_URL_TRANSPORT_OUT_OF_MEMORY,
            CURLE_OUT_OF_MEMORY, "cannot allocate URL transport request strings");
        goto complete;
    }
    ensure_global_init();
    if (global_init_result != CURLE_OK) {
        finish_error_response(response, OPENUI_URL_TRANSPORT_UNAVAILABLE,
            global_init_result, curl_easy_strerror(global_init_result));
        free(url);
        free(method);
        goto complete;
    }
    headers = parse_headers(
        request->header_bytes,
        (size_t)request->header_count,
        &header_result
    );
    if (header_result != HEADER_PARSE_OK) {
        finish_error_response(response,
            header_result == HEADER_PARSE_OUT_OF_MEMORY
                ? OPENUI_URL_TRANSPORT_OUT_OF_MEMORY
                : OPENUI_URL_TRANSPORT_BAD_REQUEST,
            header_result == HEADER_PARSE_OUT_OF_MEMORY ? CURLE_OUT_OF_MEMORY : 0,
            header_result == HEADER_PARSE_OUT_OF_MEMORY
                ? "cannot allocate HTTP header list"
                : "malformed HTTP header block");
        free(url);
        free(method);
        goto complete;
    }
    curl = curl_easy_init();
    if (!curl) {
        curl_slist_free_all(headers);
        finish_error_response(response, OPENUI_URL_TRANSPORT_OUT_OF_MEMORY,
            CURLE_OUT_OF_MEMORY, "curl_easy_init failed");
        free(url);
        free(method);
        goto complete;
    }

#define SETOPT(option, value) do { code = curl_easy_setopt(curl, option, value); if (code != CURLE_OK) goto finished; } while (0)
    SETOPT(CURLOPT_ERRORBUFFER, curl_error);
    SETOPT(CURLOPT_URL, url);
    SETOPT(CURLOPT_CUSTOMREQUEST, method);
    SETOPT(CURLOPT_FOLLOWLOCATION, 0L);
    SETOPT(CURLOPT_NOSIGNAL, 1L);
    SETOPT(CURLOPT_SSL_VERIFYPEER, 1L);
    SETOPT(CURLOPT_SSL_VERIFYHOST, 2L);
    SETOPT(CURLOPT_ACCEPT_ENCODING, "");
    SETOPT(CURLOPT_USERAGENT, "OpenUIKitFoundation/1");
#ifdef CURLOPT_PROTOCOLS_STR
    SETOPT(CURLOPT_PROTOCOLS_STR, "http,https");
#else
    SETOPT(CURLOPT_PROTOCOLS, (long)(CURLPROTO_HTTP | CURLPROTO_HTTPS));
#endif
    SETOPT(CURLOPT_HTTPHEADER, headers);
    SETOPT(CURLOPT_WRITEFUNCTION, receive_bytes);
    SETOPT(CURLOPT_WRITEDATA, &body);
    SETOPT(CURLOPT_HEADERFUNCTION, receive_bytes);
    SETOPT(CURLOPT_HEADERDATA, &response_headers);
    SETOPT(CURLOPT_XFERINFOFUNCTION, progress_callback);
    SETOPT(CURLOPT_XFERINFODATA, operation);
    SETOPT(CURLOPT_NOPROGRESS, 0L);
    if (request->connect_timeout_milliseconds)
        SETOPT(CURLOPT_CONNECTTIMEOUT_MS,
            bounded_timeout(request->connect_timeout_milliseconds));
    if (request->total_timeout_milliseconds)
        SETOPT(CURLOPT_TIMEOUT_MS,
            bounded_timeout(request->total_timeout_milliseconds));
    if (strcmp(method, "HEAD") == 0)
        SETOPT(CURLOPT_NOBODY, 1L);
    if (request->body_bytes || request->body_count) {
        static const uint8_t empty_body = 0;
        SETOPT(CURLOPT_POSTFIELDS,
            request->body_bytes ? (const void *)request->body_bytes : (const void *)&empty_body);
        SETOPT(CURLOPT_POSTFIELDSIZE_LARGE, (curl_off_t)request->body_count);
    }
    code = curl_easy_perform(curl);
finished:
#undef SETOPT
    if (body.exceeded_limit || response_headers.exceeded_limit) {
        code = CURLE_FILESIZE_EXCEEDED;
    } else if (body.failed || response_headers.failed) {
        code = CURLE_OUT_OF_MEMORY;
    }
    (void)curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &status_code);
    (void)curl_easy_getinfo(curl, CURLINFO_EFFECTIVE_URL, &effective_url);
    mapped = code == CURLE_FILESIZE_EXCEEDED
        ? OPENUI_URL_TRANSPORT_RESPONSE_TOO_LARGE
        : map_curl_error(code, operation);
    if (mapped == OPENUI_URL_TRANSPORT_OK && effective_url) {
        size_t count = strlen(effective_url);
        response->effective_url_bytes = duplicate_bytes(effective_url, count);
        if (count && !response->effective_url_bytes) {
            mapped = OPENUI_URL_TRANSPORT_OUT_OF_MEMORY;
            code = CURLE_OUT_OF_MEMORY;
        } else {
            response->effective_url_count = count;
        }
    }
    if (mapped == OPENUI_URL_TRANSPORT_OK && !effective_url) {
        mapped = OPENUI_URL_TRANSPORT_INTERNAL;
        code = CURLE_FAILED_INIT;
    }
    if (mapped == OPENUI_URL_TRANSPORT_OK) {
        response->body_bytes = body.bytes;
        response->body_count = body.count;
        body.bytes = NULL;
        response->header_bytes = response_headers.bytes;
        response->header_count = response_headers.count;
        response_headers.bytes = NULL;
        response->transport_error = OPENUI_URL_TRANSPORT_OK;
        response->native_error = CURLE_OK;
        response->status_code = status_code;
    } else {
        finish_error_response(response, mapped, code,
            curl_error[0] ? curl_error : curl_easy_strerror(code));
    }

    free(body.bytes);
    free(response_headers.bytes);
    curl_slist_free_all(headers);
    curl_easy_cleanup(curl);
    free(url);
    free(method);
complete:
    if (active_perform) end_perform(operation);
    return response->transport_error;
}
