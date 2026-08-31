#include "OpenFoundationInternationalizationABI.h"

#include <stdio.h>
#include <string.h>

static int expect(int condition, const char *message)
{
    if (condition) return 1;
    fprintf(stderr, "OpenFoundationInternationalizationHostTests: %s\n", message);
    return 0;
}

int main(void)
{
    char path[4096];
    char tiny[1];
    int ok = 1;

    ok &= expect(
        openui_foundation_intl_v1_realpath(1, "/", path, sizeof(path)) == 0,
        "root realpath failed");
    ok &= expect(strcmp(path, "/") == 0, "root realpath changed identity");
    ok &= expect(
        openui_foundation_intl_v1_realpath(2, "/", path, sizeof(path)) ==
            OPENUI_FOUNDATION_INTL_BAD_INPUT,
        "unknown ABI version accepted");
    ok &= expect(
        openui_foundation_intl_v1_realpath(1, "/", tiny, sizeof(tiny)) ==
            OPENUI_FOUNDATION_INTL_OUTPUT_TOO_SMALL,
        "short output buffer accepted");
    ok &= expect(
        openui_foundation_intl_v1_realpath(
            1, "/openui-no-such-path", path, sizeof(path)) ==
            OPENUI_FOUNDATION_INTL_NOT_FOUND,
        "missing path accepted");
    if (ok) {
        puts(
            "OPEN_FOUNDATION_INTERNATIONALIZATION_HOST_OK "
            "realpath=bounded,versioned");
    }
    return ok ? 0 : 1;
}
