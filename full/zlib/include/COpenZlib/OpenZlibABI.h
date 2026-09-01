#ifndef OPENUIKIT_OPEN_ZLIB_ABI_H
#define OPENUIKIT_OPEN_ZLIB_ABI_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define OPEN_ZLIB_ABI_VERSION 1u

#if defined(__GNUC__) || defined(__clang__)
#define OPEN_ZLIB_EXPORT __attribute__((visibility("default")))
#else
#define OPEN_ZLIB_EXPORT
#endif

OPEN_ZLIB_EXPORT uint32_t open_zlib_abi_version(void);
OPEN_ZLIB_EXPORT const char *open_zlib_host_version(void);
OPEN_ZLIB_EXPORT int32_t open_zlib_inflate_init2(
    void *stream, int32_t window_bits);
OPEN_ZLIB_EXPORT int32_t open_zlib_inflate(void *stream, int32_t flush);
OPEN_ZLIB_EXPORT int32_t open_zlib_inflate_end(void *stream);

#ifdef __cplusplus
}
#endif

#endif
