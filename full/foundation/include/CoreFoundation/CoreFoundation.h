#ifndef OPENUIKIT_COREFOUNDATION_COREFOUNDATION_H
#define OPENUIKIT_COREFOUNDATION_COREFOUNDATION_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

typedef unsigned char Boolean;
typedef signed long CFIndex;
typedef unsigned long CFOptionFlags;
typedef unsigned long CFTypeID;

#if defined(__OBJC__) && __has_attribute(objc_bridge) && \
    __has_feature(objc_bridge_id)
#define CF_BRIDGED_TYPE(type) __attribute__((objc_bridge(type)))
#define CF_BRIDGED_MUTABLE_TYPE(type) \
    __attribute__((objc_bridge_mutable(type)))
#else
#define CF_BRIDGED_TYPE(type)
#define CF_BRIDGED_MUTABLE_TYPE(type)
#endif

#if __has_feature(objc_fixed_enum)
#define CF_OPTIONS(type, name) enum name : type name; enum name : type
#else
#define CF_OPTIONS(type, name) type name; enum
#endif

#if __has_feature(arc_cf_code_audited)
#define CF_IMPLICIT_BRIDGING_ENABLED \
    _Pragma("clang arc_cf_code_audited begin")
#define CF_IMPLICIT_BRIDGING_DISABLED \
    _Pragma("clang arc_cf_code_audited end")
#else
#define CF_IMPLICIT_BRIDGING_ENABLED
#define CF_IMPLICIT_BRIDGING_DISABLED
#endif

#if __has_feature(assume_nonnull)
#define CF_ASSUME_NONNULL_BEGIN _Pragma("clang assume_nonnull begin")
#define CF_ASSUME_NONNULL_END _Pragma("clang assume_nonnull end")
#else
#define CF_ASSUME_NONNULL_BEGIN
#define CF_ASSUME_NONNULL_END
#endif

typedef const void *CFTypeRef;
typedef const struct CF_BRIDGED_TYPE(id) __CFAllocator *CFAllocatorRef;
typedef const struct CF_BRIDGED_TYPE(NSString) __CFString *CFStringRef;
typedef struct CF_BRIDGED_TYPE(NSError) __CFError *CFErrorRef;
typedef struct CF_BRIDGED_MUTABLE_TYPE(id) __CFRunLoop *CFRunLoopRef;

#endif
