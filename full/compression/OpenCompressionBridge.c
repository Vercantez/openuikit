#include "OpenCompressionABI.h"

extern int32_t host_transform(
    uint32_t,
    int32_t,
    int32_t,
    const uint8_t *,
    uint64_t,
    uint64_t,
    openui_compression_response_v1 *
) __asm__("_glibc_openui_compression_v1_transform");

extern void host_release(openui_compression_response_v1 *)
    __asm__("_glibc_openui_compression_v1_release");

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
    return host_transform(
        abi_version,
        operation,
        algorithm,
        input_bytes,
        input_count,
        output_limit,
        response
    );
}

void openui_compression_v1_release(openui_compression_response_v1 *response)
{
    host_release(response);
}
