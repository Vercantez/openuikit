#include "qz_internal.hpp"
#include <cstdio>
/* OWNED BY package data-provider. */

struct QZDataProvider {
    std::vector<uint8_t> bytes;
};

QZDataProviderRef QZDataProviderCreateWithFilename(const char *path) {
    if (!path) return nullptr;
    FILE *f = std::fopen(path, "rb");
    if (!f) return nullptr;
    auto *dp = new QZDataProvider();
    if (std::fseek(f, 0, SEEK_END) == 0) {
        long n = std::ftell(f);
        if (n > 0 && std::fseek(f, 0, SEEK_SET) == 0) {
            dp->bytes.resize((size_t)n);
            size_t rd = std::fread(dp->bytes.data(), 1, (size_t)n, f);
            dp->bytes.resize(rd);
        }
    }
    std::fclose(f);
    return dp;
}

QZDataProviderRef QZDataProviderCreateWithData(const void *data, size_t size) {
    auto *dp = new QZDataProvider();
    if (data && size)
        dp->bytes.assign((const uint8_t *)data, (const uint8_t *)data + size);
    return dp;
}

void QZDataProviderRelease(QZDataProviderRef dp) { delete dp; }

size_t QZDataProviderGetSize(QZDataProviderRef dp) { return dp ? dp->bytes.size() : 0; }

const void *QZDataProviderGetBytePtr(QZDataProviderRef dp) {
    return (dp && !dp->bytes.empty()) ? dp->bytes.data() : nullptr;
}

QZImageRef QZImageCreateWithDataProvider(QZDataProviderRef dp, size_t width, size_t height,
                                         size_t bitsPerComponent, size_t bytesPerRow) {
    if (!dp || dp->bytes.empty()) return nullptr;
    const uint8_t *data = dp->bytes.data();
    size_t size = dp->bytes.size();

    /* Encoded PNG/JPEG in the provider — same path as CGImageCreateWithPNGDataProvider. */
    QZImageRef encoded = QZImageCreateWithBytes(data, size);
    if (encoded) return encoded;

    /* Raw 8-bit RGBA, matching CGImageCreate with a bitmap data provider. */
    if (width == 0 || height == 0) return nullptr;
    if (bitsPerComponent != 0 && bitsPerComponent != 8) return nullptr;

    size_t min_bpr = width * 4u;
    size_t bpr = bytesPerRow ? bytesPerRow : min_bpr;
    if (bpr < min_bpr) return nullptr;
    size_t need = (height - 1u) * bpr + min_bpr;
    if (size < need) return nullptr;

    if (bpr == min_bpr) return QZImageCreate(width, height, data);

    std::vector<uint8_t> packed(width * height * 4u);
    for (size_t y = 0; y < height; y++)
        std::memcpy(packed.data() + y * min_bpr, data + y * bpr, min_bpr);
    return QZImageCreate(width, height, packed.data());
}
