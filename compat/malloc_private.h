/* compat/malloc_private.h -- objc4-linux. Darwin's private malloc SPI. */
#ifndef _OBJC4LINUX_MALLOC_PRIVATE_H
#define _OBJC4LINUX_MALLOC_PRIVATE_H
#include <malloc/malloc.h>

typedef enum {
    MALLOC_ZONE_MALLOC_OPTION_NONE  = 0,
    MALLOC_ZONE_MALLOC_OPTION_CLEAR = 1,
} malloc_zone_malloc_options_t;
typedef malloc_zone_malloc_options_t malloc_zone_options_t;

/* Darwin's "natural" allocation alignment: 16 on all 64-bit Apple platforms,
 * which is also what glibc's malloc guarantees on aarch64/x86-64. */
#define MALLOC_ZONE_MALLOC_DEFAULT_ALIGN ((size_t)16)

/* objc-runtime-new.mm calls malloc_zone_malloc_with_options(NULL, align, size,
 * MALLOC_ZONE_MALLOC_OPTION_CLEAR). With no zones that is exactly
 * aligned+zeroed heap memory. */
#ifdef __cplusplus
extern "C" {
#endif
void *malloc_zone_malloc_with_options_np(malloc_zone_t *zone, size_t align,
                                         size_t size, malloc_zone_malloc_options_t options);
#ifdef __cplusplus
}
#endif
#define malloc_zone_malloc_with_options malloc_zone_malloc_with_options_np

#endif
