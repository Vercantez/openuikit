/* compat/malloc_type_private.h -- objc4-linux.
 * Darwin 14's typed allocator. Not present on Linux; objc-malloc-instance.h
 * already falls back to calloc() when _MALLOC_TYPE_ENABLED is 0. */
#ifndef _OBJC4LINUX_MALLOC_TYPE_PRIVATE_H
#define _OBJC4LINUX_MALLOC_TYPE_PRIVATE_H
#define _MALLOC_TYPE_ENABLED 0
#endif
