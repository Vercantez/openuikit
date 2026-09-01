#ifndef OPENUIKIT_OPEN_ZLIB_ABI_H
#define OPENUIKIT_OPEN_ZLIB_ABI_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define OPEN_ZLIB_ABI_VERSION 1u

uint32_t open_zlib_abi_version(void);
const char *open_zlib_host_version(void);
int32_t open_zlib_inflate_init2(void *stream, int32_t window_bits);
int32_t open_zlib_inflate(void *stream, int32_t flush);
int32_t open_zlib_inflate_end(void *stream);

#ifdef __cplusplus
}
#endif

#endif
