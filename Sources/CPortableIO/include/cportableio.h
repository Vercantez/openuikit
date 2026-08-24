#ifndef CPORTABLEIO_H
#define CPORTABLEIO_H
#include <stddef.h>

/* Reads an entire file. Returns malloc'd buffer (caller frees with
   cpio_free) and sets *out_size. Returns NULL on failure. */
unsigned char *cpio_read_file(const char *path, size_t *out_size);
void cpio_free(unsigned char *buf);

#endif
