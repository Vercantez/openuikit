#include "OpenRelativeTimeABI.h"

#include <math.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include <unicode/uenum.h>
#include <unicode/unum.h>
#include <unicode/ureldatefmt.h>
#include <unicode/ustring.h>
#include <unicode/utypes.h>

static bool valid_locale_byte(uint8_t byte)
{
    return (byte >= 'a' && byte <= 'z') ||
        (byte >= 'A' && byte <= 'Z') ||
        (byte >= '0' && byte <= '9') ||
        byte == '_' || byte == '-' || byte == '.' || byte == '@' || byte == '=' ||
        byte == ';';
}

static URelativeDateTimeUnit relative_unit(int32_t unit, bool *valid)
{
    *valid = true;
    switch (unit) {
    case OPENUI_RELATIVE_TIME_YEAR: return UDAT_REL_UNIT_YEAR;
    case OPENUI_RELATIVE_TIME_MONTH: return UDAT_REL_UNIT_MONTH;
    case OPENUI_RELATIVE_TIME_WEEK: return UDAT_REL_UNIT_WEEK;
    case OPENUI_RELATIVE_TIME_DAY: return UDAT_REL_UNIT_DAY;
    case OPENUI_RELATIVE_TIME_HOUR: return UDAT_REL_UNIT_HOUR;
    case OPENUI_RELATIVE_TIME_MINUTE: return UDAT_REL_UNIT_MINUTE;
    case OPENUI_RELATIVE_TIME_SECOND: return UDAT_REL_UNIT_SECOND;
    default:
        *valid = false;
        return UDAT_REL_UNIT_SECOND;
    }
}

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
)
{
    char locale[OPENUI_RELATIVE_TIME_MAX_LOCALE_BYTES + 1];
    UNumberFormat *number_format = NULL;
    URelativeDateTimeFormatter *formatter = NULL;
    UChar stack_result[256];
    UChar *utf16 = stack_result;
    int32_t utf16_capacity = (int32_t)(sizeof(stack_result) / sizeof(stack_result[0]));
    int32_t utf16_count;
    UErrorCode status = U_ZERO_ERROR;
    UDateRelativeDateTimeFormatterStyle width;
    URelativeDateTimeUnit icu_unit;
    bool unit_valid;
    int32_t utf8_count = 0;
    int32_t result = OPENUI_RELATIVE_TIME_ICU_FAILURE;

    if (output_count) *output_count = 0;
    if (abi_version != OPENUI_RELATIVE_TIME_ABI_VERSION || !locale_bytes ||
        locale_count == 0 || locale_count > OPENUI_RELATIVE_TIME_MAX_LOCALE_BYTES ||
        !output_bytes || !output_count || output_capacity == 0 ||
        output_capacity > OPENUI_RELATIVE_TIME_MAX_OUTPUT_BYTES ||
        units_style < 0 || units_style > 3 ||
        (date_time_style != 0 && date_time_style != 1) || !isfinite(value)) {
        return OPENUI_RELATIVE_TIME_BAD_INPUT;
    }
    for (uint64_t index = 0; index < locale_count; index++) {
        if (!valid_locale_byte(locale_bytes[index])) {
            return OPENUI_RELATIVE_TIME_BAD_INPUT;
        }
    }
    memcpy(locale, locale_bytes, (size_t)locale_count);
    locale[locale_count] = '\0';

    icu_unit = relative_unit(unit, &unit_valid);
    if (!unit_valid) return OPENUI_RELATIVE_TIME_BAD_INPUT;
    width = units_style < 2 ? UDAT_STYLE_LONG :
        (units_style == 2 ? UDAT_STYLE_SHORT : UDAT_STYLE_NARROW);

    if (units_style == 1) {
        number_format = unum_open(UNUM_SPELLOUT, NULL, 0, locale, NULL, &status);
        if (U_FAILURE(status) || !number_format) goto cleanup;
    }
    formatter = ureldatefmt_open(
        locale,
        number_format,
        width,
        UDISPCTX_CAPITALIZATION_NONE,
        &status
    );
    /* The ICU API adopts the number formatter when called, including failure. */
    number_format = NULL;
    if (U_FAILURE(status) || !formatter) goto cleanup;

retry_format:
    status = U_ZERO_ERROR;
    if (date_time_style == 0) {
        utf16_count = ureldatefmt_formatNumeric(
            formatter, value, icu_unit, utf16, utf16_capacity, &status
        );
    } else {
        utf16_count = ureldatefmt_format(
            formatter, value, icu_unit, utf16, utf16_capacity, &status
        );
    }
    if (status == U_BUFFER_OVERFLOW_ERROR && utf16 == stack_result) {
        if (utf16_count < 0 || utf16_count > (int32_t)OPENUI_RELATIVE_TIME_MAX_OUTPUT_BYTES) {
            result = OPENUI_RELATIVE_TIME_OUTPUT_TOO_SMALL;
            goto cleanup;
        }
        utf16_capacity = utf16_count + 1;
        utf16 = (UChar *)malloc((size_t)utf16_capacity * sizeof(UChar));
        if (!utf16) {
            result = OPENUI_RELATIVE_TIME_OUT_OF_MEMORY;
            goto cleanup;
        }
        goto retry_format;
    }
    if (U_FAILURE(status) || utf16_count < 0) goto cleanup;

    status = U_ZERO_ERROR;
    u_strToUTF8(
        (char *)output_bytes,
        (int32_t)output_capacity,
        &utf8_count,
        utf16,
        utf16_count,
        &status
    );
    if (status == U_BUFFER_OVERFLOW_ERROR) {
        if (utf8_count >= 0) *output_count = (uint64_t)utf8_count;
        result = OPENUI_RELATIVE_TIME_OUTPUT_TOO_SMALL;
        goto cleanup;
    }
    if (U_FAILURE(status) || utf8_count < 0) goto cleanup;
    *output_count = (uint64_t)utf8_count;
    result = OPENUI_RELATIVE_TIME_OK;

cleanup:
    if (formatter) ureldatefmt_close(formatter);
    if (number_format) unum_close(number_format);
    if (utf16 != stack_result) free(utf16);
    if (result != OPENUI_RELATIVE_TIME_OK &&
        result != OPENUI_RELATIVE_TIME_OUTPUT_TOO_SMALL) {
        *output_count = 0;
    }
    return result;
}
