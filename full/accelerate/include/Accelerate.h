#ifndef OPENUIKIT_ACCELERATE_H
#define OPENUIKIT_ACCELERATE_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#if defined(__GNUC__)
#define OPENUI_ACCELERATE_API __attribute__((visibility("default")))
#else
#define OPENUI_ACCELERATE_API
#endif

typedef unsigned long vImagePixelCount;
typedef long vImage_Error;
typedef uint32_t vImage_Flags;
typedef uint8_t Pixel_8888[4];

typedef struct vImage_Buffer {
    void *data;
    vImagePixelCount height;
    vImagePixelCount width;
    size_t rowBytes;
} vImage_Buffer;

enum {
    kvImageNoError = 0,
    kvImageRoiLargerThanInputBuffer = -21766,
    kvImageInvalidKernelSize = -21767,
    kvImageInvalidEdgeStyle = -21768,
    kvImageMemoryAllocationError = -21771,
    kvImageNullPointerArgument = -21772,
    kvImageInvalidParameter = -21773,
    kvImageBufferSizeMismatch = -21774
};

enum {
    kvImageNoFlags = 0,
    kvImageLeaveAlphaUnchanged = 1,
    kvImageCopyInPlace = 2,
    kvImageBackgroundColorFill = 4,
    kvImageEdgeExtend = 8,
    kvImageDoNotTile = 16,
    kvImageHighQualityResampling = 32,
    kvImageTruncateKernel = 64,
    kvImageGetTempBufferSize = 128
};

OPENUI_ACCELERATE_API vImage_Error vImageBoxConvolve_ARGB8888(
    const vImage_Buffer *src,
    const vImage_Buffer *dest,
    void *tempBuffer,
    vImagePixelCount srcOffsetToROI_X,
    vImagePixelCount srcOffsetToROI_Y,
    uint32_t kernel_height,
    uint32_t kernel_width,
    const Pixel_8888 backgroundColor,
    vImage_Flags flags
);

#ifdef __cplusplus
}
#endif

#endif
