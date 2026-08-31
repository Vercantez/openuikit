#include "OpenRelativeTimeABI.h"

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void fail(const char *message)
{
    fprintf(stderr, "OpenRelativeTimeHostTests: %s\n", message);
    exit(1);
}

static void require_format(
    const char *locale,
    int32_t units_style,
    int32_t date_time_style,
    int32_t unit,
    double value,
    const char *expected
)
{
    uint8_t output[OPENUI_RELATIVE_TIME_MAX_OUTPUT_BYTES];
    uint64_t count = 0;
    int32_t error = openui_relative_time_v1_format(
        OPENUI_RELATIVE_TIME_ABI_VERSION,
        (const uint8_t *)locale,
        strlen(locale),
        units_style,
        date_time_style,
        unit,
        value,
        output,
        sizeof(output),
        &count
    );
    if (error != OPENUI_RELATIVE_TIME_OK || count != strlen(expected) ||
        memcmp(output, expected, count) != 0) {
        fprintf(stderr, "locale=%s error=%d actual=%.*s expected=%s\n",
            locale, error, (int)count, output, expected);
        exit(1);
    }
}

int main(void)
{
    require_format("en_US_POSIX", 0, 0, OPENUI_RELATIVE_TIME_HOUR,
        -2, "2 hours ago");
    require_format("en_US_POSIX", 0, 1, OPENUI_RELATIVE_TIME_DAY,
        -1, "yesterday");
    require_format("en_US_POSIX", 1, 0, OPENUI_RELATIVE_TIME_MINUTE,
        2, "in two minutes");
    require_format("en_US_POSIX", 2, 0, OPENUI_RELATIVE_TIME_HOUR,
        2, "in 2 hr.");
    require_format("en_US_POSIX", 3, 0, OPENUI_RELATIVE_TIME_DAY,
        2, "in 2d");
    require_format("fr_FR", 0, 0, OPENUI_RELATIVE_TIME_HOUR,
        -2, "il y a 2 heures");
    require_format("de_DE", 0, 0, OPENUI_RELATIVE_TIME_DAY,
        1, "in 1 Tag");
    require_format("ja_JP", 0, 0, OPENUI_RELATIVE_TIME_DAY,
        1, "1 日後");

    uint8_t output[8] = {0};
    uint64_t count = 99;
    if (openui_relative_time_v1_format(
        0, (const uint8_t *)"en", 2, 0, 0,
        OPENUI_RELATIVE_TIME_SECOND, 1, output, sizeof(output), &count
    ) != OPENUI_RELATIVE_TIME_BAD_INPUT || count != 0) {
        fail("ABI version gate failed");
    }
    if (openui_relative_time_v1_format(
        OPENUI_RELATIVE_TIME_ABI_VERSION,
        (const uint8_t *)"en", 2, 0, 0,
        OPENUI_RELATIVE_TIME_SECOND, 1, output, 2, &count
    ) != OPENUI_RELATIVE_TIME_OUTPUT_TOO_SMALL || count <= 2) {
        fail("output bound gate failed");
    }

    puts("OPEN_RELATIVE_TIME_HOST_OK icu=real locale=en,fr,de,ja styles=4 bounds=hard");
    return 0;
}
