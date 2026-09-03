#ifndef OPENUIKIT_OPEN_RELATIVE_TIME_ABI_H
#define OPENUIKIT_OPEN_RELATIVE_TIME_ABI_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#if defined(__GNUC__)
#define OPENUI_RELATIVE_TIME_API __attribute__((visibility("default")))
#else
#define OPENUI_RELATIVE_TIME_API
#endif

#define OPENUI_RELATIVE_TIME_ABI_VERSION 1u
#define OPENUI_RELATIVE_TIME_MAX_LOCALE_BYTES 256u
#define OPENUI_RELATIVE_TIME_MAX_OUTPUT_BYTES 4096u

typedef enum openui_relative_time_error_v1 {
    OPENUI_RELATIVE_TIME_OK = 0,
    OPENUI_RELATIVE_TIME_BAD_INPUT = 1,
    OPENUI_RELATIVE_TIME_OUTPUT_TOO_SMALL = 2,
    OPENUI_RELATIVE_TIME_ICU_FAILURE = 3,
    OPENUI_RELATIVE_TIME_OUT_OF_MEMORY = 4
} openui_relative_time_error_v1;

typedef enum openui_relative_time_unit_v1 {
    OPENUI_RELATIVE_TIME_YEAR = 0,
    OPENUI_RELATIVE_TIME_MONTH = 1,
    OPENUI_RELATIVE_TIME_WEEK = 2,
    OPENUI_RELATIVE_TIME_DAY = 3,
    OPENUI_RELATIVE_TIME_HOUR = 4,
    OPENUI_RELATIVE_TIME_MINUTE = 5,
    OPENUI_RELATIVE_TIME_SECOND = 6
} openui_relative_time_unit_v1;

/*
 * A fixed, versioned Darwin/Linux boundary. No ICU handle, Swift value,
 * platform struct, callback, or variadic call crosses it. Input and output
 * buffers remain owned by the Mach-O caller for the duration of the call.
 */
OPENUI_RELATIVE_TIME_API int32_t openui_relative_time_v1_format(
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
);

#ifdef __cplusplus
}
#endif

#endif
