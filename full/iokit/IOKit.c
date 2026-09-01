#include "IOKit.h"

kern_return_t IOObjectRelease(io_object_t object) {
    (void)object;
    return kIOReturnUnsupported;
}

io_object_t IOIteratorNext(io_iterator_t iterator) {
    (void)iterator;
    return IO_OBJECT_NULL;
}

kern_return_t IOServiceGetMatchingServices(
    mach_port_t mainPort,
    CFDictionaryRef matching,
    io_iterator_t *existing) {
    (void)mainPort;
    (void)matching;
    if (existing != NULL) {
        *existing = IO_OBJECT_NULL;
    }
    return kIOReturnUnsupported;
}

CFTypeRef IORegistryEntryCreateCFProperty(
    io_registry_entry_t entry,
    CFStringRef key,
    CFAllocatorRef allocator,
    IOOptionBits options) {
    (void)entry;
    (void)key;
    (void)allocator;
    (void)options;
    return NULL;
}

CFTypeRef IORegistryEntrySearchCFProperty(
    io_registry_entry_t entry,
    const char *plane,
    CFStringRef key,
    CFAllocatorRef allocator,
    IOOptionBits options) {
    (void)entry;
    (void)plane;
    (void)key;
    (void)allocator;
    (void)options;
    return NULL;
}

CFMutableDictionaryRef IOBSDNameMatching(
    mach_port_t mainPort,
    uint32_t options,
    const char *bsdName) {
    (void)mainPort;
    (void)options;
    (void)bsdName;
    return NULL;
}
