#include "CommonDigest.h"

#include <string.h>

static const uint32_t k[64] = {
    0x428a2f98U, 0x71374491U, 0xb5c0fbcfU, 0xe9b5dba5U,
    0x3956c25bU, 0x59f111f1U, 0x923f82a4U, 0xab1c5ed5U,
    0xd807aa98U, 0x12835b01U, 0x243185beU, 0x550c7dc3U,
    0x72be5d74U, 0x80deb1feU, 0x9bdc06a7U, 0xc19bf174U,
    0xe49b69c1U, 0xefbe4786U, 0x0fc19dc6U, 0x240ca1ccU,
    0x2de92c6fU, 0x4a7484aaU, 0x5cb0a9dcU, 0x76f988daU,
    0x983e5152U, 0xa831c66dU, 0xb00327c8U, 0xbf597fc7U,
    0xc6e00bf3U, 0xd5a79147U, 0x06ca6351U, 0x14292967U,
    0x27b70a85U, 0x2e1b2138U, 0x4d2c6dfcU, 0x53380d13U,
    0x650a7354U, 0x766a0abbU, 0x81c2c92eU, 0x92722c85U,
    0xa2bfe8a1U, 0xa81a664bU, 0xc24b8b70U, 0xc76c51a3U,
    0xd192e819U, 0xd6990624U, 0xf40e3585U, 0x106aa070U,
    0x19a4c116U, 0x1e376c08U, 0x2748774cU, 0x34b0bcb5U,
    0x391c0cb3U, 0x4ed8aa4aU, 0x5b9cca4fU, 0x682e6ff3U,
    0x748f82eeU, 0x78a5636fU, 0x84c87814U, 0x8cc70208U,
    0x90befffaU, 0xa4506cebU, 0xbef9a3f7U, 0xc67178f2U,
};

static uint32_t rotate_right(uint32_t value, unsigned int count) {
    return (value >> count) | (value << (32U - count));
}

static uint32_t load_be32(const unsigned char *bytes) {
    return ((uint32_t)bytes[0] << 24U) |
           ((uint32_t)bytes[1] << 16U) |
           ((uint32_t)bytes[2] << 8U) |
           (uint32_t)bytes[3];
}

static void store_be32(uint32_t value, unsigned char *bytes) {
    bytes[0] = (unsigned char)(value >> 24U);
    bytes[1] = (unsigned char)(value >> 16U);
    bytes[2] = (unsigned char)(value >> 8U);
    bytes[3] = (unsigned char)value;
}

static void transform(CC_SHA256_CTX *context, const unsigned char block[64]) {
    uint32_t words[64];
    for (unsigned int index = 0; index < 16; ++index) {
        words[index] = load_be32(block + index * 4U);
    }
    for (unsigned int index = 16; index < 64; ++index) {
        uint32_t x = words[index - 15];
        uint32_t y = words[index - 2];
        uint32_t s0 = rotate_right(x, 7) ^ rotate_right(x, 18) ^ (x >> 3U);
        uint32_t s1 = rotate_right(y, 17) ^ rotate_right(y, 19) ^ (y >> 10U);
        words[index] = words[index - 16] + s0 + words[index - 7] + s1;
    }

    uint32_t a = context->hash[0];
    uint32_t b = context->hash[1];
    uint32_t c = context->hash[2];
    uint32_t d = context->hash[3];
    uint32_t e = context->hash[4];
    uint32_t f = context->hash[5];
    uint32_t g = context->hash[6];
    uint32_t h = context->hash[7];

    for (unsigned int index = 0; index < 64; ++index) {
        uint32_t s1 = rotate_right(e, 6) ^ rotate_right(e, 11) ^ rotate_right(e, 25);
        uint32_t choose = (e & f) ^ (~e & g);
        uint32_t temporary1 = h + s1 + choose + k[index] + words[index];
        uint32_t s0 = rotate_right(a, 2) ^ rotate_right(a, 13) ^ rotate_right(a, 22);
        uint32_t majority = (a & b) ^ (a & c) ^ (b & c);
        uint32_t temporary2 = s0 + majority;
        h = g;
        g = f;
        f = e;
        e = d + temporary1;
        d = c;
        c = b;
        b = a;
        a = temporary1 + temporary2;
    }

    context->hash[0] += a;
    context->hash[1] += b;
    context->hash[2] += c;
    context->hash[3] += d;
    context->hash[4] += e;
    context->hash[5] += f;
    context->hash[6] += g;
    context->hash[7] += h;
}

int CC_SHA256_Init(CC_SHA256_CTX *context) {
    if (context == NULL) {
        return 0;
    }
    memset(context, 0, sizeof(*context));
    context->hash[0] = 0x6a09e667U;
    context->hash[1] = 0xbb67ae85U;
    context->hash[2] = 0x3c6ef372U;
    context->hash[3] = 0xa54ff53aU;
    context->hash[4] = 0x510e527fU;
    context->hash[5] = 0x9b05688cU;
    context->hash[6] = 0x1f83d9abU;
    context->hash[7] = 0x5be0cd19U;
    return 1;
}

int CC_SHA256_Update(CC_SHA256_CTX *context, const void *data, CC_LONG length) {
    if (context == NULL || (length != 0U && data == NULL)) {
        return 0;
    }
    const unsigned char *input = (const unsigned char *)data;
    uint64_t old_count = ((uint64_t)context->count[1] << 32U) | context->count[0];
    unsigned int buffered = (unsigned int)(old_count & 63U);
    uint64_t new_count = old_count + length;
    context->count[0] = (uint32_t)new_count;
    context->count[1] = (uint32_t)(new_count >> 32U);
    unsigned char *buffer = (unsigned char *)context->wbuf;

    if (buffered != 0U) {
        unsigned int needed = 64U - buffered;
        unsigned int copied = length < needed ? length : needed;
        memcpy(buffer + buffered, input, copied);
        buffered += copied;
        input += copied;
        length -= copied;
        if (buffered == 64U) {
            transform(context, buffer);
        }
    }
    while (length >= 64U) {
        transform(context, input);
        input += 64U;
        length -= 64U;
    }
    if (length != 0U) {
        memcpy(buffer, input, length);
    }
    return 1;
}

int CC_SHA256_Final(unsigned char digest[32], CC_SHA256_CTX *context) {
    if (context == NULL || digest == NULL) {
        return 0;
    }
    uint64_t byte_count = ((uint64_t)context->count[1] << 32U) | context->count[0];
    unsigned int buffered = (unsigned int)(byte_count & 63U);
    unsigned char final_blocks[128];
    unsigned int final_count = buffered < 56U ? 64U : 128U;
    memset(final_blocks, 0, final_count);
    memcpy(final_blocks, (unsigned char *)context->wbuf, buffered);
    final_blocks[buffered] = 0x80U;
    uint64_t bit_count = byte_count * 8U;
    for (unsigned int index = 0; index < 8; ++index) {
        final_blocks[final_count - 1U - index] = (unsigned char)(bit_count >> (index * 8U));
    }
    transform(context, final_blocks);
    if (final_count == 128U) {
        transform(context, final_blocks + 64U);
    }
    for (unsigned int index = 0; index < 8; ++index) {
        store_be32(context->hash[index], digest + index * 4U);
    }
    memset(context, 0, sizeof(*context));
    return 1;
}

unsigned char *CC_SHA256(const void *data, CC_LONG length, unsigned char digest[32]) {
    CC_SHA256_CTX context;
    if (!CC_SHA256_Init(&context) || !CC_SHA256_Update(&context, data, length) ||
        !CC_SHA256_Final(digest, &context)) {
        return NULL;
    }
    return digest;
}
