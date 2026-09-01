#include <stdio.h>
#include <stdint.h>
#include <string.h>

#if defined(__APPLE__)
#include <Accelerate/Accelerate.h>
#else
#include "Accelerate.h"
#endif

static void print_pixels(const char *label, const uint8_t *bytes)
{
    printf("%s", label);
    for (size_t index = 0; index < 3 * 3 * 4; ++index)
        printf("%s%u", index ? "," : "", (unsigned)bytes[index]);
    putchar('\n');
}

int main(void)
{
    uint8_t source_bytes[3 * 3 * 4] = {
        10, 0, 1, 2,   20, 3, 4, 5,   30, 6, 7, 8,
        40, 9, 10, 11, 50, 12, 13, 14, 60, 15, 16, 17,
        70, 18, 19, 20, 80, 21, 22, 23, 90, 24, 25, 26
    };
    uint8_t output[3 * 3 * 4];
    uint8_t alpha_output[3 * 3 * 4];
    Pixel_8888 background = {0, 0, 0, 0};
    vImage_Buffer source = {
        source_bytes, 3, 3, 3 * 4
    };
    vImage_Buffer destination = {
        output, 3, 3, 3 * 4
    };
    vImage_Buffer alpha_destination = {
        alpha_output, 3, 3, 3 * 4
    };

    memset(output, 0xA5, sizeof(output));
    vImage_Error edge = vImageBoxConvolve_ARGB8888(
        &source, &destination, NULL, 0, 0, 3, 3, background,
        kvImageEdgeExtend
    );
    printf("edge-status=%ld\n", (long)edge);
    print_pixels("edge-pixels=", output);

    memset(alpha_output, 0xA5, sizeof(alpha_output));
    vImage_Error alpha = vImageBoxConvolve_ARGB8888(
        &source, &alpha_destination, NULL, 0, 0, 3, 3, background,
        kvImageEdgeExtend | kvImageLeaveAlphaUnchanged
    );
    printf("alpha-status=%ld\n", (long)alpha);
    print_pixels("alpha-pixels=", alpha_output);

    vImage_Error even = vImageBoxConvolve_ARGB8888(
        &source, &destination, NULL, 0, 0, 2, 3, background,
        kvImageEdgeExtend
    );
    vImage_Error no_edge = vImageBoxConvolve_ARGB8888(
        &source, &destination, NULL, 0, 0, 3, 3, background,
        kvImageNoFlags
    );
    vImage_Error oversized_roi = vImageBoxConvolve_ARGB8888(
        &source, &destination, NULL, 1, 0, 3, 3, background,
        kvImageEdgeExtend
    );
    printf("errors=even:%ld,no-edge:%ld,roi:%ld\n",
           (long)even, (long)no_edge, (long)oversized_roi);
    return 0;
}
