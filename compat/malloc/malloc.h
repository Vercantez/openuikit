/*
 * compat/malloc/malloc.h  --  objc4-linux
 *
 * Darwin's malloc introspection, mapped to glibc's.
 *
 * CAVEAT: malloc_size() on Darwin returns the size of the allocated block;
 * glibc's malloc_usable_size() returns the *usable* size, which may be larger
 * than requested (rounded up to the allocator's bin). objc4 uses it for
 * objc_isUniquelyReferenced sizing and for diagnostics, not for ivar layout,
 * so over-reporting is safe there -- but every new use must be re-checked.
 */
#ifndef _OBJC4LINUX_MALLOC_MALLOC_H
#define _OBJC4LINUX_MALLOC_MALLOC_H

#include <stddef.h>
#include <stdlib.h>
#include <malloc.h>   /* glibc: malloc_usable_size */

#ifdef __cplusplus
extern "C" {
#endif

static inline size_t malloc_size(const void *ptr) {
    return ptr ? malloc_usable_size((void *)ptr) : 0;
}
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
