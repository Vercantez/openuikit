#ifndef OPEN_FOUNDATION_INTERNATIONALIZATION_ABI_H
#define OPEN_FOUNDATION_INTERNATIONALIZATION_ABI_H

#include <stdint.h>

#if defined(__GNUC__)
#define OPENUI_FOUNDATION_INTL_API __attribute__((visibility("default")))
#else
#define OPENUI_FOUNDATION_INTL_API
#endif

#define OPENUI_FOUNDATION_INTL_ABI_VERSION UINT32_C(1)
#define OPENUI_FOUNDATION_INTL_MAX_PATH_BYTES UINT64_C(4096)

enum openui_foundation_intl_result {
    OPENUI_FOUNDATION_INTL_OK = 0,
    OPENUI_FOUNDATION_INTL_BAD_INPUT = 1,
    OPENUI_FOUNDATION_INTL_NOT_FOUND = 2,
    OPENUI_FOUNDATION_INTL_OUTPUT_TOO_SMALL = 3
};

#ifdef __cplusplus
extern "C" {
#endif

OPENUI_FOUNDATION_INTL_API int32_t openui_foundation_intl_v1_realpath(
    uint32_t abi_version,
    const char *path,
    char *output,
    uint64_t output_capacity
);

#ifdef __cplusplus
}
#endif

#endif
