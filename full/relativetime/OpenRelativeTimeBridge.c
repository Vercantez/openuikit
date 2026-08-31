#include "OpenRelativeTimeABI.h"

extern int32_t host_format(
    uint32_t,
    const uint8_t *,
    uint64_t,
    int32_t,
    int32_t,
    int32_t,
    double,
    uint8_t *,
    uint64_t,
    uint64_t *
) __asm__("_glibc_openui_relative_time_v1_format");

int32_t openui_relative_time_v1_format(
    uint32_t abi_version,
    const uint8_t *locale_bytes,
    uint64_t locale_count,
    int32_t units_style,
    int32_t date_time_style,
    int32_t unit,
    double value,
    uint8_t *output_bytes,
    uint64_t output_capacity,
    uint64_t *output_count
)
{
    return host_format(
        abi_version,
        locale_bytes,
        locale_count,
        units_style,
        date_time_style,
        unit,
        value,
        output_bytes,
        output_capacity,
        output_count
    );
}
