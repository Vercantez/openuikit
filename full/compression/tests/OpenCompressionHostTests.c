#include "OpenCompressionABI.h"

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void require(int condition, const char *message)
{
    if (!condition) {
        fprintf(stderr, "OpenCompressionHostTests: %s\n", message);
        exit(1);
    }
}

int main(void)
{
    static const uint8_t payload[] =
        "IceCubes untouched RevenueCat Brotli response: "
        "portable Mach-O guests on Linux";
    static const uint8_t apple_encoded[] = {
        0x8b, 0x26, 0x80, 0x49, 0x63, 0x65, 0x43, 0x75, 0x62, 0x65,
        0x73, 0x20, 0x75, 0x6e, 0x74, 0x6f, 0x75, 0x63, 0x68, 0x65,
        0x64, 0x20, 0x52, 0x65, 0x76, 0x65, 0x6e, 0x75, 0x65, 0x43,
        0x61, 0x74, 0x20, 0x42, 0x72, 0x6f, 0x74, 0x6c, 0x69, 0x20,
        0x72, 0x65, 0x73, 0x70, 0x6f, 0x6e, 0x73, 0x65, 0x3a, 0x20,
        0x70, 0x6f, 0x72, 0x74, 0x61, 0x62, 0x6c, 0x65, 0x20, 0x4d,
        0x61, 0x63, 0x68, 0x2d, 0x4f, 0x20, 0x67, 0x75, 0x65, 0x73,
        0x74, 0x73, 0x20, 0x6f, 0x6e, 0x20, 0x4c, 0x69, 0x6e,
        0x75, 0x78, 0x03
    };
    openui_compression_response_v1 encoded = {0};
    int32_t status = openui_compression_v1_transform(
        OPENUI_COMPRESSION_ABI_VERSION,
        OPENUI_COMPRESSION_OPERATION_ENCODE,
        OPENUI_COMPRESSION_ALGORITHM_BROTLI,
        payload,
        sizeof(payload) - 1,
        4096,
        &encoded
    );
    require(status == OPENUI_COMPRESSION_OK, "Brotli encode failed");
    require(encoded.status == OPENUI_COMPRESSION_OK,
            "Brotli encode response status drifted");
    require(encoded.bytes != NULL && encoded.count > 0,
            "Brotli encode returned no bytes");

    openui_compression_response_v1 decoded = {0};
    status = openui_compression_v1_transform(
        OPENUI_COMPRESSION_ABI_VERSION,
        OPENUI_COMPRESSION_OPERATION_DECODE,
        OPENUI_COMPRESSION_ALGORITHM_BROTLI,
        encoded.bytes,
        encoded.count,
        4096,
        &decoded
    );
    if (status != OPENUI_COMPRESSION_OK)
        fprintf(stderr, "decode-status=%d response=%d encoded-count=%llu\n",
                status, decoded.status,
                (unsigned long long)encoded.count);
    require(status == OPENUI_COMPRESSION_OK, "Brotli decode failed");
    require(decoded.count == sizeof(payload) - 1,
            "Brotli decoded length drifted");
    require(memcmp(decoded.bytes, payload, sizeof(payload) - 1) == 0,
            "Brotli round-trip bytes drifted");

    openui_compression_response_v1 apple_decoded = {0};
    status = openui_compression_v1_transform(
        OPENUI_COMPRESSION_ABI_VERSION,
        OPENUI_COMPRESSION_OPERATION_DECODE,
        OPENUI_COMPRESSION_ALGORITHM_BROTLI,
        apple_encoded,
        sizeof(apple_encoded),
        4096,
        &apple_decoded
    );
    require(status == OPENUI_COMPRESSION_OK,
            "Apple Compression Brotli transcript failed to decode");
    require(apple_decoded.count == sizeof(payload) - 1,
            "Apple Compression decoded length drifted");
    require(memcmp(apple_decoded.bytes, payload, sizeof(payload) - 1) == 0,
            "Apple Compression transcript bytes drifted");

    openui_compression_response_v1 malformed = {0};
    static const uint8_t bad[] = {0xff, 0xff, 0xff, 0xff};
    status = openui_compression_v1_transform(
        OPENUI_COMPRESSION_ABI_VERSION,
        OPENUI_COMPRESSION_OPERATION_DECODE,
        OPENUI_COMPRESSION_ALGORITHM_BROTLI,
        bad,
        sizeof(bad),
        4096,
        &malformed
    );
    require(status == OPENUI_COMPRESSION_INVALID_DATA,
            "malformed Brotli did not fail closed");
    require(malformed.bytes == NULL && malformed.count == 0,
            "malformed Brotli exposed output");

    openui_compression_response_v1 limited = {0};
    status = openui_compression_v1_transform(
        OPENUI_COMPRESSION_ABI_VERSION,
        OPENUI_COMPRESSION_OPERATION_DECODE,
        OPENUI_COMPRESSION_ALGORITHM_BROTLI,
        encoded.bytes,
        encoded.count,
        8,
        &limited
    );
    require(status == OPENUI_COMPRESSION_LIMIT_EXCEEDED,
            "decode output limit did not fail closed");

    openui_compression_response_v1 unsupported = {0};
    status = openui_compression_v1_transform(
        OPENUI_COMPRESSION_ABI_VERSION,
        99,
        OPENUI_COMPRESSION_ALGORITHM_BROTLI,
        payload,
        sizeof(payload) - 1,
        4096,
        &unsupported
    );
    require(status == OPENUI_COMPRESSION_UNSUPPORTED,
            "unsupported operation status drifted");

    openui_compression_v1_release(&encoded);
    openui_compression_v1_release(&decoded);
    openui_compression_v1_release(&apple_decoded);
    openui_compression_v1_release(&malformed);
    openui_compression_v1_release(&limited);
    openui_compression_v1_release(&unsupported);
    printf("OPEN_COMPRESSION_HOST_OK algorithm=brotli roundtrip=exact malformed=fail-closed limit=hard abi=v1\n");
    return 0;
}
