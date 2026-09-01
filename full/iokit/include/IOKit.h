#ifndef OPENUIKIT_PORTABLE_IOKIT_H
#define OPENUIKIT_PORTABLE_IOKIT_H

#include <stddef.h>
#include <stdint.h>

#if defined(__APPLE__) || defined(__MACH__)
#include <mach/kern_return.h>
#include <mach/mach_types.h>
#else
typedef int32_t kern_return_t;
typedef uint32_t mach_port_t;
#ifndef KERN_SUCCESS
#define KERN_SUCCESS ((kern_return_t)0)
#endif
#endif

#ifdef __cplusplus
extern "C" {
#endif

#if defined(__has_feature)
#if __has_feature(attribute_cf_returns_retained)
#define OPENIOKIT_CF_RETURNS_RETAINED __attribute__((cf_returns_retained))
#else
#define OPENIOKIT_CF_RETURNS_RETAINED
#endif
#if __has_feature(attribute_cf_consumed)
#define OPENIOKIT_CF_RELEASES_ARGUMENT __attribute__((cf_consumed))
#else
#define OPENIOKIT_CF_RELEASES_ARGUMENT
#endif
#else
#define OPENIOKIT_CF_RETURNS_RETAINED
#define OPENIOKIT_CF_RELEASES_ARGUMENT
#endif

#define OPENIOKIT_EXPORT __attribute__((visibility("default")))

#if defined(__has_attribute)
#if __has_attribute(swift_private)
#define OPENIOKIT_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define OPENIOKIT_SWIFT_PRIVATE
#endif
#else
#define OPENIOKIT_SWIFT_PRIVATE
#endif

typedef kern_return_t IOReturn;
typedef uint32_t IOOptionBits;
typedef mach_port_t io_object_t;
typedef io_object_t io_iterator_t;
typedef io_object_t io_registry_entry_t;
typedef io_object_t io_service_t;

#if defined(__has_attribute)
#if __has_attribute(objc_bridge)
#define OPENIOKIT_CF_BRIDGED_TYPE(T) __attribute__((objc_bridge(T)))
#define OPENIOKIT_CF_BRIDGED_MUTABLE_TYPE(T) \
    __attribute__((objc_bridge_mutable(T)))
#else
#define OPENIOKIT_CF_BRIDGED_TYPE(T)
#define OPENIOKIT_CF_BRIDGED_MUTABLE_TYPE(T)
#endif
#else
#define OPENIOKIT_CF_BRIDGED_TYPE(T)
#define OPENIOKIT_CF_BRIDGED_MUTABLE_TYPE(T)
#endif

typedef const OPENIOKIT_CF_BRIDGED_TYPE(id) void *CFTypeRef
    OPENIOKIT_SWIFT_PRIVATE;
typedef const struct OPENIOKIT_CF_BRIDGED_TYPE(NSString) __CFString *CFStringRef
    OPENIOKIT_SWIFT_PRIVATE;
typedef const struct OPENIOKIT_CF_BRIDGED_TYPE(id) __CFAllocator *CFAllocatorRef
    OPENIOKIT_SWIFT_PRIVATE;
typedef const struct OPENIOKIT_CF_BRIDGED_TYPE(NSDictionary) __CFDictionary
    *CFDictionaryRef OPENIOKIT_SWIFT_PRIVATE;
typedef struct OPENIOKIT_CF_BRIDGED_MUTABLE_TYPE(NSMutableDictionary)
    __CFDictionary *CFMutableDictionaryRef OPENIOKIT_SWIFT_PRIVATE;

#define IO_OBJECT_NULL ((io_object_t)0)
#define kIOServicePlane "IOService"

enum {
    kIORegistryIterateRecursively = 0x00000001,
    kIORegistryIterateParents = 0x00000002
};

#define kIOReturnSuccess KERN_SUCCESS
#define kIOReturnUnsupported ((kern_return_t)0xe00002c7u)

OPENIOKIT_EXPORT OPENIOKIT_SWIFT_PRIVATE kern_return_t
IOObjectRelease(io_object_t object);
OPENIOKIT_EXPORT OPENIOKIT_SWIFT_PRIVATE io_object_t
IOIteratorNext(io_iterator_t iterator);

OPENIOKIT_EXPORT OPENIOKIT_SWIFT_PRIVATE kern_return_t
IOServiceGetMatchingServices(
    mach_port_t mainPort,
    CFDictionaryRef matching OPENIOKIT_CF_RELEASES_ARGUMENT,
    io_iterator_t *existing);

OPENIOKIT_EXPORT OPENIOKIT_SWIFT_PRIVATE CFTypeRef
IORegistryEntryCreateCFProperty(
    io_registry_entry_t entry,
    CFStringRef key,
    CFAllocatorRef allocator,
    IOOptionBits options);

OPENIOKIT_EXPORT OPENIOKIT_SWIFT_PRIVATE CFTypeRef
IORegistryEntrySearchCFProperty(
    io_registry_entry_t entry,
    const char *plane,
    CFStringRef key,
    CFAllocatorRef allocator,
    IOOptionBits options) OPENIOKIT_CF_RETURNS_RETAINED;

OPENIOKIT_EXPORT OPENIOKIT_SWIFT_PRIVATE CFMutableDictionaryRef
IOBSDNameMatching(
    mach_port_t mainPort,
    uint32_t options,
    const char *bsdName) OPENIOKIT_CF_RETURNS_RETAINED;

#ifdef __cplusplus
}
#endif

#endif
