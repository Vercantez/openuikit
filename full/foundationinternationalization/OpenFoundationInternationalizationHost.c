#define _GNU_SOURCE

#include "OpenFoundationInternationalizationABI.h"

#include <limits.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>

int32_t openui_foundation_intl_v1_realpath(
    uint32_t abi_version,
    const char *path,
    char *output,
    uint64_t output_capacity
)
{
    char canonical[PATH_MAX];
    size_t path_count;
    size_t canonical_count;

    if (abi_version != OPENUI_FOUNDATION_INTL_ABI_VERSION || !path || !output ||
        output_capacity == 0 ||
        output_capacity > OPENUI_FOUNDATION_INTL_MAX_PATH_BYTES) {
        return OPENUI_FOUNDATION_INTL_BAD_INPUT;
    }
    path_count = strnlen(path, (size_t)OPENUI_FOUNDATION_INTL_MAX_PATH_BYTES);
    if (path_count == 0 || path_count == OPENUI_FOUNDATION_INTL_MAX_PATH_BYTES) {
        return OPENUI_FOUNDATION_INTL_BAD_INPUT;
    }
    if (!realpath(path, canonical)) return OPENUI_FOUNDATION_INTL_NOT_FOUND;
    canonical_count = strlen(canonical);
    if (canonical_count + 1 > output_capacity) {
        return OPENUI_FOUNDATION_INTL_OUTPUT_TOO_SMALL;
    }
    memcpy(output, canonical, canonical_count + 1);
    return OPENUI_FOUNDATION_INTL_OK;
}
