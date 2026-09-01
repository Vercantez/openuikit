#include "OpenZlibABI.h"

#include <stdio.h>
#include <string.h>
#include <zlib.h>

static const unsigned char gzip_payload[] = {
    0x1f, 0x8b, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x02, 0x13, 0x05, 0xc1,
    0xd1, 0x0d, 0x80, 0x20, 0x0c, 0x05, 0xc0, 0x55, 0xde, 0x02, 0x2e, 0xe0,
    0x2f, 0xbf, 0x1a, 0x13, 0x36, 0xa8, 0xd0, 0x00, 0x09, 0x69, 0x09, 0xb6,
    0x46, 0x9d, 0xde, 0xbb, 0xc8, 0x37, 0x8b, 0x73, 0x20, 0x83, 0x8b, 0xa9,
    0xa7, 0xca, 0x19, 0x31, 0x04, 0x15, 0xa3, 0x26, 0x3c, 0x51, 0xbe, 0x36,
    0x30, 0xe8, 0xed, 0x4a, 0x79, 0xc5, 0xd0, 0x69, 0x74, 0x76, 0xc6, 0x4e,
    0xa9, 0x2e, 0x07, 0x8a, 0xf3, 0x65, 0x50, 0xc1, 0xd6, 0xc4, 0x9f, 0x1f,
    0x02, 0xc8, 0xd6, 0x53, 0x4d, 0x00, 0x00, 0x00
};

static const char expected[] =
    "RevenueCat untouched RCContainer gzip payload: portable Mach-O guest on Linux";

int main(void) {
    z_stream stream = {0};
    unsigned char output[256] = {0};
    stream.next_in = (Bytef *)gzip_payload;
    stream.avail_in = (uInt)sizeof(gzip_payload);
    stream.next_out = output;
    stream.avail_out = (uInt)sizeof(output);

    if (open_zlib_abi_version() != OPEN_ZLIB_ABI_VERSION ||
        open_zlib_inflate_init2(&stream, MAX_WBITS + 16) != Z_OK) {
        return 10;
    }
    int status = open_zlib_inflate(&stream, Z_NO_FLUSH);
    if (status != Z_STREAM_END || stream.avail_in != 0 ||
        stream.total_out != strlen(expected) ||
        memcmp(output, expected, strlen(expected)) != 0) {
        open_zlib_inflate_end(&stream);
        return 11;
    }
    if (open_zlib_inflate_end(&stream) != Z_OK) {
        return 12;
    }

    z_stream malformed = {0};
    unsigned char invalid[] = {0x1f, 0x8b, 0x08, 0x00, 0xff};
    malformed.next_in = invalid;
    malformed.avail_in = (uInt)sizeof(invalid);
    malformed.next_out = output;
    malformed.avail_out = (uInt)sizeof(output);
    if (open_zlib_inflate_init2(&malformed, MAX_WBITS + 16) != Z_OK) {
        return 13;
    }
    status = open_zlib_inflate(&malformed, Z_FINISH);
    if (status != Z_DATA_ERROR && status != Z_BUF_ERROR) {
        open_zlib_inflate_end(&malformed);
        return 14;
    }
    if (open_zlib_inflate_end(&malformed) != Z_OK) {
        return 15;
    }

    printf("OPEN_ZLIB_HOST_OK abi=v1 host=%s gzip=exact malformed=fail-closed\n",
           open_zlib_host_version());
    return 0;
}
