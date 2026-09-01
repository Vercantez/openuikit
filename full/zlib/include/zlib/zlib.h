/*
 * Portable zlib stream surface for app-facing Swift imports.
 *
 * This is a deliberately reduced declaration set derived from zlib 1.2.12's
 * public zlib.h and zconf.h interfaces. zlib is Copyright (C) 1995-2022
 * Jean-loup Gailly and Mark Adler and is distributed under the zlib license.
 * The declarations retain the stable public z_stream ABI while the functions
 * cross a small audited host boundary on Linux.
 */
#ifndef OPENUIKIT_PORTABLE_ZLIB_H
#define OPENUIKIT_PORTABLE_ZLIB_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

#define ZLIB_VERSION "1.2.12"
#define ZLIB_VERNUM 0x12c0

typedef unsigned char Byte;
typedef unsigned char Bytef;
typedef unsigned int uInt;
typedef unsigned long uLong;
typedef void *voidpf;

typedef voidpf (*alloc_func)(voidpf opaque, uInt items, uInt size);
typedef void (*free_func)(voidpf opaque, voidpf address);

struct internal_state;

typedef struct z_stream_s {
    Bytef *next_in;
    uInt avail_in;
    uLong total_in;

    Bytef *next_out;
    uInt avail_out;
    uLong total_out;

    char *msg;
    struct internal_state *state;

    alloc_func zalloc;
    free_func zfree;
    voidpf opaque;

    int data_type;
    uLong adler;
    uLong reserved;
} z_stream;

typedef z_stream *z_streamp;

#define Z_NO_FLUSH 0
#define Z_PARTIAL_FLUSH 1
#define Z_SYNC_FLUSH 2
#define Z_FULL_FLUSH 3
#define Z_FINISH 4
#define Z_BLOCK 5
#define Z_TREES 6

#define Z_OK 0
#define Z_STREAM_END 1
#define Z_NEED_DICT 2
#define Z_ERRNO (-1)
#define Z_STREAM_ERROR (-2)
#define Z_DATA_ERROR (-3)
#define Z_MEM_ERROR (-4)
#define Z_BUF_ERROR (-5)
#define Z_VERSION_ERROR (-6)

#define MAX_WBITS 15

#if defined(__GNUC__) || defined(__clang__)
#define ZEXPORT __attribute__((visibility("default")))
#else
#define ZEXPORT
#endif

ZEXPORT const char *zlibVersion(void);
ZEXPORT int inflateInit2_(z_streamp stream, int window_bits,
                          const char *version, int stream_size);
ZEXPORT int inflate(z_streamp stream, int flush);
ZEXPORT int inflateEnd(z_streamp stream);

#ifdef __cplusplus
}
#endif

#endif
