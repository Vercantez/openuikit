#include "zlib.h"
#include "OpenZlibABI.h"

#include <stddef.h>
#include <string.h>

_Static_assert(sizeof(z_stream) == 112, "portable z_stream ABI drifted");
_Static_assert(offsetof(z_stream, next_in) == 0, "z_stream.next_in drifted");
_Static_assert(offsetof(z_stream, avail_in) == 8, "z_stream.avail_in drifted");
_Static_assert(offsetof(z_stream, next_out) == 24, "z_stream.next_out drifted");
_Static_assert(offsetof(z_stream, state) == 56, "z_stream.state drifted");
_Static_assert(offsetof(z_stream, reserved) == 104, "z_stream.reserved drifted");

const char *zlibVersion(void) {
    return ZLIB_VERSION;
}

int inflateInit2_(z_streamp stream, int window_bits,
                  const char *version, int stream_size) {
    if (stream == NULL || version == NULL || version[0] != ZLIB_VERSION[0] ||
        stream_size != (int)sizeof(z_stream)) {
        return Z_VERSION_ERROR;
    }
    if (open_zlib_abi_version() != OPEN_ZLIB_ABI_VERSION) {
        return Z_VERSION_ERROR;
    }
    return open_zlib_inflate_init2(stream, window_bits);
}

int inflate(z_streamp stream, int flush) {
    if (stream == NULL) {
        return Z_STREAM_ERROR;
    }
    return open_zlib_inflate(stream, flush);
}

int inflateEnd(z_streamp stream) {
    if (stream == NULL) {
        return Z_STREAM_ERROR;
    }
    return open_zlib_inflate_end(stream);
}
