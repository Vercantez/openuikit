#include "OpenSwiftIOKitRuntime.h"

#include <stdio.h>

#define OPEN_SWIFT_IOKIT_DECLARE(name, symbol, code) \
    int32_t open_swift_iokit_##name(void) __asm__(symbol);
OPEN_SWIFT_IOKIT_CONSTANTS(OPEN_SWIFT_IOKIT_DECLARE)

struct return_case {
    const char *name;
    int32_t (*getter)(void);
    int32_t expected;
};

#define OPEN_SWIFT_IOKIT_CASE(name, symbol, code) \
    {#name, open_swift_iokit_##name, OPEN_SWIFT_IOKIT_COMMON_ERROR(code)},
static const struct return_case cases[] = {
    OPEN_SWIFT_IOKIT_CONSTANTS(OPEN_SWIFT_IOKIT_CASE)
};

int main(void) {
    size_t count = sizeof(cases) / sizeof(cases[0]);
    for (size_t index = 0; index < count; ++index) {
        int32_t actual = cases[index].getter();
        if (actual != cases[index].expected) {
            fprintf(stderr,
                    "OpenSwiftIOKitHostTests: %s returned 0x%08x, expected 0x%08x\n",
                    cases[index].name,
                    (uint32_t)actual,
                    (uint32_t)cases[index].expected);
            return 1;
        }
    }
    if (count != 52) {
        fprintf(stderr,
                "OpenSwiftIOKitHostTests: constant count %zu, expected 52\n",
                count);
        return 1;
    }
    puts("SWIFT_IOKIT_HOST_OK constants=52 unsupported=0xe00002c7");
    return 0;
}
