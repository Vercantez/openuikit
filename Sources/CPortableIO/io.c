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
