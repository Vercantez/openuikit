#ifndef CPORTABLEIO_H
#define CPORTABLEIO_H
#include <stddef.h>

/* Reads an entire file. Returns malloc'd buffer (caller frees with
   cpio_free) and sets *out_size. Returns NULL on failure. */
unsigned char *cpio_read_file(const char *path, size_t *out_size);
void cpio_free(unsigned char *buf);

/* Writes an entire file. Returns non-zero on success. */
int cpio_write_file(const char *path, const unsigned char *buf, size_t size);

/* Writes a NUL-terminated string to stderr, followed by a newline. */
void cpio_log_stderr(const char *msg);

/* Returns the value of an environment variable, or NULL. */
const char *cpio_getenv(const char *name);

/* Terminates the process. Needed by Foundation-free executables. */
void cpio_exit(int code);

/* A small opaque mutex for Swift state which is deliberately non-actor
   isolated (for example UIPasteboard, which UIKit marks Sendable). */
void *cpio_mutex_create(void);
void cpio_mutex_destroy(void *mutex);
void cpio_mutex_lock(void *mutex);
void cpio_mutex_unlock(void *mutex);

#endif
