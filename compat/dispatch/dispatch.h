/*
 * compat/dispatch/dispatch.h -- objc4-linux.
 * objc4 uses exactly one dispatch primitive (dispatch_once in
 * objc-exception.mm). pthread_once is the exact equivalent for the
 * no-argument case; we keep the block form working via a thread-local
 * trampoline-free approach using __attribute__((constructor))-safe
 * std::call_once semantics implemented in objc4linux-support.cpp.
 */
#ifndef _OBJC4LINUX_DISPATCH_H
#define _OBJC4LINUX_DISPATCH_H
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
typedef long dispatch_once_t;
#if __BLOCKS__
typedef void (^dispatch_block_t)(void);
void objc4linux_dispatch_once(dispatch_once_t *predicate, dispatch_block_t block);
#define dispatch_once(p, b) objc4linux_dispatch_once((p), (b))
#endif
void dispatch_once_f(dispatch_once_t *predicate, void *context, void (*function)(void *));
#ifdef __cplusplus
}
#endif
#endif
