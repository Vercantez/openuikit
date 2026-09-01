#include "OpenSwiftIOKitRuntime.h"

#define OPEN_SWIFT_IOKIT_EXPORT __attribute__((visibility("default")))

#define OPEN_SWIFT_IOKIT_DEFINE(name, symbol, code) \
    OPEN_SWIFT_IOKIT_EXPORT int32_t open_swift_iokit_##name(void) \
        __asm__(symbol); \
    int32_t open_swift_iokit_##name(void) { \
        return OPEN_SWIFT_IOKIT_COMMON_ERROR(code); \
    }

OPEN_SWIFT_IOKIT_CONSTANTS(OPEN_SWIFT_IOKIT_DEFINE)

OPEN_SWIFT_IOKIT_EXPORT const uint8_t open_swift_iokit_force_load
    __asm__("__swift_FORCE_LOAD_$_swiftIOKit") = 0;
