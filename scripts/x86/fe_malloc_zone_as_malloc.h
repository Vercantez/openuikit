/* machorun libSystem has one malloc zone (the default). CoreFoundation's
   TARGET_OS_MAC allocator callbacks call malloc_zone_malloc with the
   allocator's info pointer as a zone; that aborts (exit 71) in
   __CFRuntimeCreateInstance. The portable CFBase.c #else uses malloc/free.
   Same mapping CoreFoundation_Prefix.h already uses on Windows. */
#ifndef OPENUIKIT_FE_MALLOC_ZONE_AS_MALLOC
#define OPENUIKIT_FE_MALLOC_ZONE_AS_MALLOC
#define malloc_zone_malloc(zone, size) malloc(size)
#define malloc_zone_calloc(zone, n, size) calloc((n), (size))
#define malloc_zone_realloc(zone, ptr, size) realloc((ptr), (size))
#define malloc_zone_memalign(zone, align, size) malloc(size)
#define malloc_zone_free(zone, ptr) free(ptr)
#endif
