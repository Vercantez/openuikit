#include "CommonDigest.h"

#include <stdio.h>
#include <string.h>

static void hex(const unsigned char *bytes, size_t count, char *output) {
    static const char digits[] = "0123456789abcdef";
    for (size_t index = 0; index < count; ++index) {
        output[index * 2] = digits[bytes[index] >> 4U];
        output[index * 2 + 1] = digits[bytes[index] & 15U];
    }
    output[count * 2] = '\0';
}

int main(void) {
    const char input[] = "abc";
    const char expected[] =
        "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad";
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    char encoded[CC_SHA256_DIGEST_LENGTH * 2 + 1];
    if (CC_SHA256(input, 3, digest) != digest) return 1;
    hex(digest, sizeof(digest), encoded);
    if (strcmp(encoded, expected) != 0) return 2;

    CC_SHA256_CTX context;
    if (!CC_SHA256_Init(&context)) return 3;
    if (!CC_SHA256_Update(&context, input, 1)) return 4;
    if (!CC_SHA256_Update(&context, input + 1, 2)) return 5;
    if (!CC_SHA256_Final(digest, &context)) return 6;
    hex(digest, sizeof(digest), encoded);
    if (strcmp(encoded, expected) != 0) return 7;

    const char empty_expected[] =
        "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855";
    if (CC_SHA256(NULL, 0, digest) != digest) return 8;
    hex(digest, sizeof(digest), encoded);
    if (strcmp(encoded, empty_expected) != 0) return 9;

    const char boundary_expected[] =
        "635361c48bb9eab14198e76ea8ab7f1a41685d6ad62aa9146d301d4f17eb0ae0";
    unsigned char boundary[65];
    memset(boundary, 'a', sizeof(boundary));
    if (!CC_SHA256_Init(&context)) return 10;
    if (!CC_SHA256_Update(&context, boundary, 55)) return 11;
    if (!CC_SHA256_Update(&context, boundary + 55, 10)) return 12;
    if (!CC_SHA256_Final(digest, &context)) return 13;
    hex(digest, sizeof(digest), encoded);
    if (strcmp(encoded, boundary_expected) != 0) return 14;

    puts("COMMONCRYPTO_HOST_OK sha256=oneshot,streaming,boundary");
    return 0;
}
