#ifndef OPENUIKIT_COMMONCRYPTO_COMMONDIGEST_H
#define OPENUIKIT_COMMONCRYPTO_COMMONDIGEST_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef uint32_t CC_LONG;

#define CC_SHA256_BLOCK_BYTES 64
#define CC_SHA256_DIGEST_LENGTH 32

typedef struct CC_SHA256state_st {
    uint32_t count[2];
    uint32_t hash[8];
    uint32_t wbuf[16];
} CC_SHA256_CTX;

#if defined(__GNUC__)
#define OPENUIKIT_CC_EXPORT __attribute__((visibility("default")))
#else
#define OPENUIKIT_CC_EXPORT
#endif

OPENUIKIT_CC_EXPORT int CC_SHA256_Init(CC_SHA256_CTX *context);
OPENUIKIT_CC_EXPORT int CC_SHA256_Update(
    CC_SHA256_CTX *context,
    const void *data,
    CC_LONG length
);
OPENUIKIT_CC_EXPORT int CC_SHA256_Final(
    unsigned char digest[CC_SHA256_DIGEST_LENGTH],
    CC_SHA256_CTX *context
);
OPENUIKIT_CC_EXPORT unsigned char *CC_SHA256(
    const void *data,
    CC_LONG length,
    unsigned char digest[CC_SHA256_DIGEST_LENGTH]
);

#ifdef __cplusplus
}
#endif

#endif
