#include "include/cportableio.h"
#include <stdio.h>
#include <stdlib.h>

unsigned char *cpio_read_file(const char *path, size_t *out_size) {
    FILE *f = fopen(path, "rb");
    if (!f) return NULL;
    if (fseek(f, 0, SEEK_END) != 0) { fclose(f); return NULL; }
    long size = ftell(f);
    if (size < 0) { fclose(f); return NULL; }
    rewind(f);
    unsigned char *buf = malloc((size_t)size);
    if (!buf) { fclose(f); return NULL; }
    if (fread(buf, 1, (size_t)size, f) != (size_t)size) {
        free(buf); fclose(f); return NULL;
    }
    fclose(f);
    *out_size = (size_t)size;
    return buf;
}

void cpio_free(unsigned char *buf) { free(buf); }

void cpio_log_stderr(const char *msg) {
    fputs(msg, stderr);
    fputc('\n', stderr);
    fflush(stderr);
}

const char *cpio_getenv(const char *name) { return getenv(name); }

void cpio_exit(int code) { exit(code); }

int cpio_write_file(const char *path, const unsigned char *buf, size_t size) {
    FILE *f = fopen(path, "wb");
    if (!f) return 0;
    size_t n = size ? fwrite(buf, 1, size, f) : 0;
    if (fclose(f) != 0) return 0;
    return n == size;
}
