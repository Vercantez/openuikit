#include "Accelerate.h"

#include <limits.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

static int checked_row_width(vImagePixelCount width, size_t *bytes)
{
    if (width > SIZE_MAX / 4) return 0;
    *bytes = (size_t)width * 4;
    return 1;
}

static vImagePixelCount clamped_coordinate(
    vImagePixelCount base,
    uint32_t kernel_index,
    uint32_t kernel_radius,
    vImagePixelCount limit
)
{
    if (kernel_index < kernel_radius) {
        vImagePixelCount delta = (vImagePixelCount)(kernel_radius - kernel_index);
        return delta > base ? 0 : base - delta;
    }
    vImagePixelCount delta = (vImagePixelCount)(kernel_index - kernel_radius);
    if (delta >= limit - base) return limit - 1;
    return base + delta;
}

vImage_Error vImageBoxConvolve_ARGB8888(
    const vImage_Buffer *src,
    const vImage_Buffer *dest,
    void *tempBuffer,
    vImagePixelCount srcOffsetToROI_X,
    vImagePixelCount srcOffsetToROI_Y,
    uint32_t kernel_height,
    uint32_t kernel_width,
    const Pixel_8888 backgroundColor,
    vImage_Flags flags
)
{
    (void)tempBuffer;
    (void)backgroundColor;
    if (!src || !dest || !src->data || !dest->data)
        return kvImageNullPointerArgument;
    if (!src->width || !src->height || !dest->width || !dest->height)
        return kvImageInvalidParameter;
    if (!kernel_width || !kernel_height
        || !(kernel_width & 1u) || !(kernel_height & 1u))
        return kvImageInvalidKernelSize;
    if (!(flags & kvImageEdgeExtend)
        || (flags & (kvImageCopyInPlace | kvImageBackgroundColorFill
                     | kvImageTruncateKernel)))
        return kvImageInvalidEdgeStyle;
    if (flags & ~(vImage_Flags)(kvImageLeaveAlphaUnchanged
                                | kvImageEdgeExtend
                                | kvImageDoNotTile))
        return kvImageInvalidParameter;
    if (srcOffsetToROI_X > src->width || srcOffsetToROI_Y > src->height
        || dest->width > src->width - srcOffsetToROI_X
        || dest->height > src->height - srcOffsetToROI_Y)
        return kvImageBufferSizeMismatch;

    size_t source_visible_bytes;
    size_t destination_visible_bytes;
    if (!checked_row_width(src->width, &source_visible_bytes)
        || !checked_row_width(dest->width, &destination_visible_bytes)
        || src->rowBytes < source_visible_bytes
        || dest->rowBytes < destination_visible_bytes)
        return kvImageBufferSizeMismatch;

    uint64_t divisor = (uint64_t)kernel_width * (uint64_t)kernel_height;
    if (!divisor || divisor > UINT64_MAX / UINT8_MAX)
        return kvImageInvalidKernelSize;

    const uint8_t *source = (const uint8_t *)src->data;
    uint8_t *source_copy = NULL;
    if (src->data == dest->data) {
        if (src->height > SIZE_MAX / src->rowBytes)
            return kvImageMemoryAllocationError;
        size_t byte_count = (size_t)src->height * src->rowBytes;
        source_copy = (uint8_t *)malloc(byte_count);
        if (!source_copy) return kvImageMemoryAllocationError;
        memcpy(source_copy, src->data, byte_count);
        source = source_copy;
    }

    uint8_t *destination = (uint8_t *)dest->data;
    const uint32_t radius_x = kernel_width / 2;
    const uint32_t radius_y = kernel_height / 2;
    for (vImagePixelCount y = 0; y < dest->height; ++y) {
        for (vImagePixelCount x = 0; x < dest->width; ++x) {
            uint64_t sums[4] = {0, 0, 0, 0};
            vImagePixelCount center_x = srcOffsetToROI_X + x;
            vImagePixelCount center_y = srcOffsetToROI_Y + y;
            for (uint32_t ky = 0; ky < kernel_height; ++ky) {
                vImagePixelCount sy = clamped_coordinate(
                    center_y, ky, radius_y, src->height
                );
                const uint8_t *row = source + (size_t)sy * src->rowBytes;
                for (uint32_t kx = 0; kx < kernel_width; ++kx) {
                    vImagePixelCount sx = clamped_coordinate(
                        center_x, kx, radius_x, src->width
                    );
                    const uint8_t *pixel = row + (size_t)sx * 4;
                    sums[0] += pixel[0];
                    sums[1] += pixel[1];
                    sums[2] += pixel[2];
                    sums[3] += pixel[3];
                }
            }
            const uint8_t *source_pixel = source
                + (size_t)center_y * src->rowBytes + (size_t)center_x * 4;
            uint8_t *pixel = destination
                + (size_t)y * dest->rowBytes + (size_t)x * 4;
            pixel[0] = (flags & kvImageLeaveAlphaUnchanged)
                ? source_pixel[0]
                : (uint8_t)((sums[0] + divisor / 2) / divisor);
            pixel[1] = (uint8_t)((sums[1] + divisor / 2) / divisor);
            pixel[2] = (uint8_t)((sums[2] + divisor / 2) / divisor);
            pixel[3] = (uint8_t)((sums[3] + divisor / 2) / divisor);
        }
    }
    free(source_copy);
    return kvImageNoError;
}
