#include "OpenCompressionABI.h"

#include <limits.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

/*
 * Ubuntu's pinned runtime image intentionally ships Brotli's shared objects
 * without development headers.  These are the library's stable public C ABI
 * declarations; keeping the exact, tiny boundary here also prevents a Brotli
 * struct from crossing into the Darwin guest.
 */
typedef struct BrotliDecoderStateStruct BrotliDecoderState;
typedef void *(*brotli_alloc_func)(void *, size_t);
typedef void (*brotli_free_func)(void *, void *);
typedef enum BrotliDecoderResult {
    BROTLI_DECODER_RESULT_ERROR = 0,
    BROTLI_DECODER_RESULT_SUCCESS = 1,
    BROTLI_DECODER_RESULT_NEEDS_MORE_INPUT = 2,
    BROTLI_DECODER_RESULT_NEEDS_MORE_OUTPUT = 3
} BrotliDecoderResult;
typedef int BROTLI_BOOL;
typedef enum BrotliEncoderMode {
    BROTLI_MODE_GENERIC = 0,
    BROTLI_MODE_TEXT = 1,
    BROTLI_MODE_FONT = 2
} BrotliEncoderMode;

extern BrotliDecoderState *BrotliDecoderCreateInstance(
    brotli_alloc_func, brotli_free_func, void *
);
extern void BrotliDecoderDestroyInstance(BrotliDecoderState *);
extern BrotliDecoderResult BrotliDecoderDecompressStream(
    BrotliDecoderState *, size_t *, const uint8_t **,
    size_t *, uint8_t **, size_t *
);
extern size_t BrotliEncoderMaxCompressedSize(size_t);
extern BROTLI_BOOL BrotliEncoderCompress(
    int, int, BrotliEncoderMode, size_t, const uint8_t *, size_t *, uint8_t *
);

static int32_t fail(
    openui_compression_response_v1 *response,
    int32_t status
)
{
    if (response) {
        free(response->bytes);
        response->bytes = NULL;
        response->count = 0;
        response->status = status;
        response->reserved = 0;
    }
    return status;
}

static int grow(
    uint8_t **bytes,
    size_t *capacity,
    size_t used,
    size_t limit
)
{
    if (*capacity >= limit) return 0;
    size_t next = *capacity ? *capacity : (limit < 65536 ? limit : 65536);
    while (next <= used) {
        if (next > limit / 2) {
            next = limit;
            break;
        }
        next *= 2;
    }
    if (next <= used || next > limit) return 0;
    uint8_t *grown = (uint8_t *)realloc(*bytes, next);
    if (!grown) return -1;
    *bytes = grown;
    *capacity = next;
    return 1;
}

static int32_t decode_brotli(
    const uint8_t *input,
    size_t input_count,
    size_t limit,
    openui_compression_response_v1 *response
)
{
    BrotliDecoderState *state = BrotliDecoderCreateInstance(NULL, NULL, NULL);
    if (!state) return fail(response, OPENUI_COMPRESSION_OUT_OF_MEMORY);
    uint8_t *output = NULL;
    size_t capacity = 0;
    size_t used = 0;
    int grew = grow(&output, &capacity, used, limit);
    if (grew <= 0) {
        BrotliDecoderDestroyInstance(state);
        return fail(
            response,
            grew < 0 ? OPENUI_COMPRESSION_OUT_OF_MEMORY
                     : OPENUI_COMPRESSION_LIMIT_EXCEEDED
        );
    }
    size_t available_in = input_count;
    const uint8_t *next_in = input;
    for (;;) {
        size_t available_out = capacity - used;
        uint8_t *next_out = output + used;
        BrotliDecoderResult result = BrotliDecoderDecompressStream(
            state,
            &available_in,
            &next_in,
            &available_out,
            &next_out,
            NULL
        );
        used = capacity - available_out;
        if (result == BROTLI_DECODER_RESULT_SUCCESS) {
            if (available_in != 0) {
                free(output);
                BrotliDecoderDestroyInstance(state);
                return fail(response, OPENUI_COMPRESSION_INVALID_DATA);
            }
            break;
        }
        if (result == BROTLI_DECODER_RESULT_ERROR
            || result == BROTLI_DECODER_RESULT_NEEDS_MORE_INPUT) {
            free(output);
            BrotliDecoderDestroyInstance(state);
            return fail(response, OPENUI_COMPRESSION_INVALID_DATA);
        }
        grew = grow(&output, &capacity, used, limit);
        if (grew <= 0) {
            free(output);
            BrotliDecoderDestroyInstance(state);
            return fail(
                response,
                grew < 0 ? OPENUI_COMPRESSION_OUT_OF_MEMORY
                         : OPENUI_COMPRESSION_LIMIT_EXCEEDED
            );
        }
    }
    BrotliDecoderDestroyInstance(state);
    response->bytes = output;
    response->count = (uint64_t)used;
    response->status = OPENUI_COMPRESSION_OK;
    response->reserved = 0;
    return OPENUI_COMPRESSION_OK;
}

static int32_t encode_brotli(
    const uint8_t *input,
    size_t input_count,
    size_t limit,
    openui_compression_response_v1 *response
)
{
    size_t capacity = BrotliEncoderMaxCompressedSize(input_count);
    if (!capacity) capacity = 1;
    if (capacity > limit)
        return fail(response, OPENUI_COMPRESSION_LIMIT_EXCEEDED);
    uint8_t *output = (uint8_t *)malloc(capacity);
    if (!output) return fail(response, OPENUI_COMPRESSION_OUT_OF_MEMORY);
    size_t count = capacity;
    BROTLI_BOOL ok = BrotliEncoderCompress(
        5,
        22,
        BROTLI_MODE_GENERIC,
        input_count,
        input,
        &count,
        output
    );
    if (!ok) {
        free(output);
        return fail(response, OPENUI_COMPRESSION_INTERNAL);
    }
    response->bytes = output;
    response->count = (uint64_t)count;
    response->status = OPENUI_COMPRESSION_OK;
    response->reserved = 0;
    return OPENUI_COMPRESSION_OK;
}

int32_t openui_compression_v1_transform(
    uint32_t abi_version,
    int32_t operation,
    int32_t algorithm,
    const uint8_t *input_bytes,
    uint64_t input_count,
    uint64_t output_limit,
    openui_compression_response_v1 *response
)
{
    if (!response) return OPENUI_COMPRESSION_INVALID_ARGUMENT;
    memset(response, 0, sizeof(*response));
    if (abi_version != OPENUI_COMPRESSION_ABI_VERSION
        || algorithm != OPENUI_COMPRESSION_ALGORITHM_BROTLI
        || input_count > SIZE_MAX || output_limit > SIZE_MAX
        || (!input_bytes && input_count != 0) || output_limit == 0)
        return fail(response, OPENUI_COMPRESSION_INVALID_ARGUMENT);
    if (operation == OPENUI_COMPRESSION_OPERATION_DECODE)
        return decode_brotli(
            input_bytes, (size_t)input_count, (size_t)output_limit, response
        );
    if (operation == OPENUI_COMPRESSION_OPERATION_ENCODE)
        return encode_brotli(
            input_bytes, (size_t)input_count, (size_t)output_limit, response
        );
    return fail(response, OPENUI_COMPRESSION_UNSUPPORTED);
}

void openui_compression_v1_release(
    openui_compression_response_v1 *response
)
{
    if (!response) return;
    free(response->bytes);
    memset(response, 0, sizeof(*response));
}
