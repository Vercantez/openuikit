/*
 * compat/Block_private.h -- objc4-linux.
 *
 * libBlocksRuntime (Debian: libblocksruntime-dev) ships <Block.h> but not
 * Apple's private <Block_private.h>. objc4 needs the struct layout to inspect
 * a block's flags/invoke pointer for imp_implementationWithBlock. The layout
 * below is the ABI-stable one clang emits and is identical on both platforms.
 */
#ifndef _OBJC4LINUX_BLOCK_PRIVATE_H
#define _OBJC4LINUX_BLOCK_PRIVATE_H

#include <stdint.h>
#include <stdbool.h>
#include <Block.h>

#ifdef __cplusplus
extern "C" {
#endif

enum {
    BLOCK_DEALLOCATING      = (0x0001),
    BLOCK_REFCOUNT_MASK     = (0xfffe),
    BLOCK_INLINE_LAYOUT_STRING = (1 << 21),
    BLOCK_SMALL_DESCRIPTOR  = (1 << 22),
    BLOCK_IS_NOESCAPE       = (1 << 23),
    BLOCK_NEEDS_FREE        = (1 << 24),
    BLOCK_HAS_COPY_DISPOSE  = (1 << 25),
    BLOCK_HAS_CTOR          = (1 << 26),
    BLOCK_IS_GC             = (1 << 27),
    BLOCK_IS_GLOBAL         = (1 << 28),
    BLOCK_USE_STRET         = (1 << 29),
    BLOCK_HAS_SIGNATURE     = (1 << 30),
    BLOCK_HAS_EXTENDED_LAYOUT = (1 << 31),
};

struct Block_descriptor_1 {
    uintptr_t reserved;
    uintptr_t size;
};

struct Block_layout {
    void       *isa;
    volatile int32_t flags;
    int32_t     reserved;
    void      (*invoke)(void *, ...);
    struct Block_descriptor_1 *descriptor;
};

extern void *_Block_copy(const void *block);
extern void  _Block_release(const void *block);
extern const char *_Block_signature(void *block);
extern const char *_Block_layout(void *block);
extern void *_Block_extract_layout(void *block);

/* libBlocksRuntime does not export these predicates; they are one-line reads
 * of the flags word above and are identical on both platforms. */
static inline bool _Block_has_signature(void *block) {
    return (((struct Block_layout *)block)->flags & BLOCK_HAS_SIGNATURE) != 0;
}
static inline bool _Block_use_stret(void *block) {
    struct Block_layout *l = (struct Block_layout *)block;
    const int req = BLOCK_HAS_SIGNATURE | BLOCK_USE_STRET;
    return (l->flags & req) == req;
}

#ifdef __cplusplus
}
#endif

#endif
