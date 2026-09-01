#ifndef OPENUIKIT_COMPRESSION_ABI_H
#define OPENUIKIT_COMPRESSION_ABI_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#if defined(__GNUC__)
#define OPENUI_COMPRESSION_API __attribute__((visibility("default")))
#else
#define OPENUI_COMPRESSION_API
#endif

typedef enum compression_algorithm {
    COMPRESSION_LZ4 = 0x100,
    COMPRESSION_ZLIB = 0x205,
    COMPRESSION_LZMA = 0x306,
    COMPRESSION_LZFSE = 0x801,
    COMPRESSION_LZBITMAP = 0x702,
    COMPRESSION_BROTLI = 0xB02
} compression_algorithm;

typedef enum compression_stream_operation {
    COMPRESSION_STREAM_ENCODE = 0,
    COMPRESSION_STREAM_DECODE = 1
} compression_stream_operation;

enum {
    OPENUI_COMPRESSION_ABI_VERSION = 1,
    OPENUI_COMPRESSION_OPERATION_ENCODE = 0,
    OPENUI_COMPRESSION_OPERATION_DECODE = 1,
    OPENUI_COMPRESSION_ALGORITHM_BROTLI = 0xB02,
    OPENUI_COMPRESSION_OK = 0,
    OPENUI_COMPRESSION_INVALID_ARGUMENT = 1,
    OPENUI_COMPRESSION_UNSUPPORTED = 2,
    OPENUI_COMPRESSION_INVALID_DATA = 3,
    OPENUI_COMPRESSION_LIMIT_EXCEEDED = 4,
    OPENUI_COMPRESSION_OUT_OF_MEMORY = 5,
    OPENUI_COMPRESSION_INTERNAL = 6
};

typedef struct openui_compression_response_v1 {
    uint8_t *bytes;
    uint64_t count;
    int32_t status;
    int32_t reserved;
} openui_compression_response_v1;

OPENUI_COMPRESSION_API int32_t openui_compression_v1_transform(
    uint32_t abi_version,
    int32_t operation,
    int32_t algorithm,
    const uint8_t *input_bytes,
    uint64_t input_count,
    uint64_t output_limit,
    openui_compression_response_v1 *response
);

OPENUI_COMPRESSION_API void openui_compression_v1_release(
    openui_compression_response_v1 *response
);

#ifdef __cplusplus
}
#endif

#endif
