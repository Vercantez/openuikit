#include "OpenZlibABI.h"

#include <stddef.h>
#include <zlib.h>

_Static_assert(sizeof(z_stream) == 112, "host z_stream ABI drifted");
_Static_assert(offsetof(z_stream, next_in) == 0, "host next_in drifted");
_Static_assert(offsetof(z_stream, avail_in) == 8, "host avail_in drifted");
_Static_assert(offsetof(z_stream, next_out) == 24, "host next_out drifted");
_Static_assert(offsetof(z_stream, state) == 56, "host state drifted");
_Static_assert(offsetof(z_stream, reserved) == 104, "host reserved drifted");

uint32_t open_zlib_abi_version(void) {
    return OPEN_ZLIB_ABI_VERSION;
}

const char *open_zlib_host_version(void) {
    return zlibVersion();
}

int32_t open_zlib_inflate_init2(void *stream, int32_t window_bits) {
    return inflateInit2_((z_streamp)stream, window_bits,
                         ZLIB_VERSION, (int)sizeof(z_stream));
}

int32_t open_zlib_inflate(void *stream, int32_t flush) {
    return inflate((z_streamp)stream, flush);
}

int32_t open_zlib_inflate_end(void *stream) {
    return inflateEnd((z_streamp)stream);
}
