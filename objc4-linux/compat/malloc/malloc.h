/*
 * compat/malloc/malloc.h  --  objc4-linux
 *
 * Darwin's malloc introspection, mapped to glibc's.
 *
 * malloc_size() is NOT malloc_usable_size(). Two differences, and the second
 * one is load-bearing:
 *
 *   1. Darwin returns the allocated block size; glibc returns the *usable*
 *      size, rounded up to the allocator's bin. objc4 uses the number for
 *      sizing and diagnostics, never for ivar layout, so over-reporting is
 *      harmless.
 *
 *   2. Darwin returns ZERO for a pointer malloc does not own. glibc's
 *      malloc_usable_size() makes no such promise -- it reads the chunk
 *      header at ptr-16 and returns whatever is there. objc4 depends on the
 *      Darwin behaviour in objc-runtime-new.h:
 *
 *          static inline void try_free(const void *p)
 *          { if (p && malloc_size(p)) free((void *)p); }
 *
 *      Every ivar name, ivar type, class name and ivar-layout string in a
 *      compiled image is a pointer into that image's read-only data. On
 *      Darwin try_free() sees malloc_size()==0 and skips them; with a naive
 *      malloc_usable_size() it calls free() on a constant and the process
 *      dies with "munmap_chunk(): invalid pointer". MEASURED: that was the
 *      objc_disposeClassPair() crash in tests/023-dynamic-class.m.
 *
 *      So malloc_size() is implemented out of line, in
 *      compat/src/objc4linux-elf.cpp, and answers 0 for any address inside a
 *      loaded ELF image -- which is exactly the question try_free is asking.
 */
#ifndef _OBJC4LINUX_MALLOC_MALLOC_H
#define _OBJC4LINUX_MALLOC_MALLOC_H

#include <stddef.h>
#include <stdlib.h>
#include <malloc.h>   /* glibc: malloc_usable_size */

#ifdef __cplusplus
extern "C" {
#endif

size_t malloc_size(const void *ptr);
static inline size_t malloc_good_size(size_t size) { return size; }

/* Zones do not exist. SUPPORT_ZONES is 0 on Linux, so these are only named in
 * code that is compiled out; they exist so that headers parse. */
typedef struct _malloc_zone_t malloc_zone_t;
malloc_zone_t *malloc_default_zone(void);
void  *malloc_zone_malloc(malloc_zone_t *zone, size_t size);
void  *malloc_zone_calloc(malloc_zone_t *zone, size_t n, size_t size);
void  *malloc_zone_realloc(malloc_zone_t *zone, void *p, size_t size);
void   malloc_zone_free(malloc_zone_t *zone, void *p);
unsigned malloc_zone_batch_malloc(malloc_zone_t *zone, size_t size, void **results, unsigned num);
void   malloc_zone_batch_free(malloc_zone_t *zone, void **to_be_freed, unsigned num);

#ifdef __cplusplus
}
#endif

#endif
