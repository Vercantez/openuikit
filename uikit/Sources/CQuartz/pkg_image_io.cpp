#include "qz_internal.hpp"
/* OWNED BY package image-io. */

#include <climits>
#include <cstdio>
#include <cstdlib>
#include <cstring>

#define STB_IMAGE_IMPLEMENTATION
#define STBI_NO_HDR
#define STBI_NO_LINEAR
#define STBI_NO_BMP
#define STBI_NO_PSD
#define STBI_NO_TGA
#define STBI_NO_GIF
#define STBI_NO_PIC
#define STBI_NO_PNM
#if defined(__GNUC__)
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-function"
#pragma GCC diagnostic ignored "-Wsign-compare"
#endif
#include "stb_image.h"
#if defined(__GNUC__)
#pragma GCC diagnostic pop
#endif

#include "stb_image_write.h"

static int sniff_kind(const uint8_t *d, size_t n) {
    if (n >= 8 && d[0] == 0x89 && d[1] == 0x50 && d[2] == 0x4E && d[3] == 0x47 &&
        d[4] == 0x0D && d[5] == 0x0A && d[6] == 0x1A && d[7] == 0x0A)
        return 1; /* PNG */
    if (n >= 2 && d[0] == 0xFF && d[1] == 0xD8)
        return 2; /* JPEG */
    return 0;
}

static bool read_file(const char *path, std::vector<uint8_t> *out) {
    if (!path || !out) return false;
    FILE *f = fopen(path, "rb");
    if (!f) return false;
    if (fseek(f, 0, SEEK_END) != 0) {
        fclose(f);
        return false;
    }
    long n = ftell(f);
    if (n < 0) {
        fclose(f);
        return false;
    }
    if (fseek(f, 0, SEEK_SET) != 0) {
        fclose(f);
        return false;
    }
    out->resize((size_t)n);
    size_t rd = n ? fread(out->data(), 1, (size_t)n, f) : 0;
    fclose(f);
    out->resize(rd);
    return true;
}

static QZImageRef image_from_stbi_rgba(int w, int h, uint8_t *rgba) {
    if (!rgba || w <= 0 || h <= 0) {
        if (rgba) stbi_image_free(rgba);
        return nullptr;
    }
    QZImageRef img = QZImageCreate((size_t)w, (size_t)h, rgba);
    stbi_image_free(rgba);
    return img;
}

/* want: 0 = PNG or JPEG, 1 = PNG only, 2 = JPEG only. */
static QZImageRef load_mem(const uint8_t *data, size_t length, int want) {
    if (!data || length == 0) return nullptr;
    int kind = sniff_kind(data, length);
    if (kind == 0) return nullptr;
    if (want && kind != want) return nullptr;
    if (length > (size_t)INT_MAX) return nullptr;
    int w = 0, h = 0, n = 0;
    uint8_t *px = stbi_load_from_memory(data, (int)length, &w, &h, &n, 4);
    return image_from_stbi_rgba(w, h, px);
}

QZImageRef QZImageCreateWithPNGFile(const char *path) {
    std::vector<uint8_t> buf;
    if (!read_file(path, &buf)) return nullptr;
    return load_mem(buf.data(), buf.size(), 1);
}

QZImageRef QZImageCreateWithJPEGFile(const char *path) {
    std::vector<uint8_t> buf;
    if (!read_file(path, &buf)) return nullptr;
    return load_mem(buf.data(), buf.size(), 2);
}

int QZImageWritePNGFile(QZImageRef image, const char *path) {
    if (!image || !path || image->width <= 0 || image->height <= 0) return 0;
    if (image->rgba.size() < (size_t)image->width * (size_t)image->height * 4) return 0;
    int w = image->width, h = image->height;
    std::vector<uint8_t> np((size_t)w * (size_t)h * 4);
    const uint8_t *src = image->rgba.data();
    for (int i = 0; i < w * h; i++) {
        uint8_t a = src[i * 4 + 3];
        np[i * 4 + 3] = a;
        if (a == 0) {
            np[i * 4 + 0] = np[i * 4 + 1] = np[i * 4 + 2] = 0;
        } else if (a == 255) {
            np[i * 4 + 0] = src[i * 4 + 0];
            np[i * 4 + 1] = src[i * 4 + 1];
            np[i * 4 + 2] = src[i * 4 + 2];
        } else {
            np[i * 4 + 0] = (uint8_t)std::min(255, (src[i * 4 + 0] * 255) / a);
            np[i * 4 + 1] = (uint8_t)std::min(255, (src[i * 4 + 1] * 255) / a);
            np[i * 4 + 2] = (uint8_t)std::min(255, (src[i * 4 + 2] * 255) / a);
        }
    }
    return stbi_write_png(path, w, h, 4, np.data(), w * 4) ? 1 : 0;
}

QZImageRef QZImageCreateWithBytes(const uint8_t *data, size_t length) {
    return load_mem(data, length, 0);
}

/* ---- Straight-alpha RGBA8 codec (no QZImage round trip) ---------------- */

uint8_t *QZImageDecodeRGBA(const uint8_t *data, size_t length, int *out_width,
                           int *out_height) {
    if (out_width) *out_width = 0;
    if (out_height) *out_height = 0;
    if (!data || length == 0 || length > (size_t)INT_MAX) return nullptr;
    if (sniff_kind(data, length) == 0) return nullptr;
    int w = 0, h = 0, n = 0;
    uint8_t *px = stbi_load_from_memory(data, (int)length, &w, &h, &n, 4);
    if (!px) return nullptr;
    if (w <= 0 || h <= 0) {
        stbi_image_free(px);
        return nullptr;
    }
    if (out_width) *out_width = w;
    if (out_height) *out_height = h;
    return px; /* stbi uses malloc; QZImageFreeRGBA frees it */
}

void QZImageFreeRGBA(uint8_t *pixels) {
    if (pixels) free(pixels);
}

static void encode_sink(void *context, void *data, int size) {
    std::vector<uint8_t> *out = (std::vector<uint8_t> *)context;
    const uint8_t *p = (const uint8_t *)data;
    if (size > 0) out->insert(out->end(), p, p + size);
}

static uint8_t *finish_encode(std::vector<uint8_t> &buf, int ok, size_t *out_length) {
    if (out_length) *out_length = 0;
    if (!ok || buf.empty()) return nullptr;
    uint8_t *mem = (uint8_t *)malloc(buf.size());
    if (!mem) return nullptr;
    memcpy(mem, buf.data(), buf.size());
    if (out_length) *out_length = buf.size();
    return mem;
}

uint8_t *QZImageEncodePNG(const uint8_t *rgba, int width, int height, size_t *out_length) {
    if (out_length) *out_length = 0;
    if (!rgba || width <= 0 || height <= 0) return nullptr;
    std::vector<uint8_t> buf;
    int ok = stbi_write_png_to_func(encode_sink, &buf, width, height, 4, rgba, width * 4);
    return finish_encode(buf, ok, out_length);
}

uint8_t *QZImageEncodeJPEG(const uint8_t *rgba, int width, int height, int quality,
                           size_t *out_length) {
    if (out_length) *out_length = 0;
    if (!rgba || width <= 0 || height <= 0) return nullptr;
    if (quality < 1) quality = 1;
    if (quality > 100) quality = 100;
    std::vector<uint8_t> buf;
    int ok = stbi_write_jpg_to_func(encode_sink, &buf, width, height, 4, rgba, quality);
    return finish_encode(buf, ok, out_length);
}
