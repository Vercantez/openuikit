#ifndef OPENUIKIT_FOUNDATION_NSOBJCRUNTIME_H
#define OPENUIKIT_FOUNDATION_NSOBJCRUNTIME_H

#include <objc/NSObjCRuntime.h>

#if defined(__cplusplus)
#define FOUNDATION_EXTERN extern "C"
#else
#define FOUNDATION_EXTERN extern
#endif

#define FOUNDATION_EXPORT FOUNDATION_EXTERN __attribute__((visibility("default")))
#define FOUNDATION_IMPORT FOUNDATION_EXTERN

#ifndef NS_INLINE
#define NS_INLINE static __inline__ __attribute__((always_inline))
#endif

#ifndef FOUNDATION_STATIC_INLINE
#define FOUNDATION_STATIC_INLINE static __inline__
#endif

#ifndef NS_ASSUME_NONNULL_BEGIN
#define NS_ASSUME_NONNULL_BEGIN _Pragma("clang assume_nonnull begin")
#endif

#ifndef NS_ASSUME_NONNULL_END
#define NS_ASSUME_NONNULL_END _Pragma("clang assume_nonnull end")
#endif

#endif
