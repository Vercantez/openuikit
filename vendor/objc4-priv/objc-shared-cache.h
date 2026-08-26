/*
 * compat/objc-shared-cache.h -- objc4-linux.
 * The dyld shared cache's precomputed objc tables. There is no shared cache on
 * Linux; SUPPORT_PREOPT is 0 and objc-opt.mm's `#if !SUPPORT_PREOPT` fallback
 * bodies are used instead. This header exists so the include resolves.
 */
#ifndef _OBJC4LINUX_OBJC_SHARED_CACHE_H
#define _OBJC4LINUX_OBJC_SHARED_CACHE_H
#endif
