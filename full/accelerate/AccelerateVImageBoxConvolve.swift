import Foundation

/// Swift port of the existing `Accelerate.c` `vImageBoxConvolve_ARGB8888`.
/// Pixel results match `tests/accelerate-box-convolve-apple-2026-09-01.txt`.
public func vImageBoxConvolve_ARGB8888(
    _ src: UnsafePointer<vImage_Buffer>,
    _ dest: UnsafePointer<vImage_Buffer>,
    _ tempBuffer: UnsafeMutableRawPointer!,
    _ srcOffsetToROI_X: vImagePixelCount,
    _ srcOffsetToROI_Y: vImagePixelCount,
    _ kernel_height: UInt32,
    _ kernel_width: UInt32,
    _ backgroundColor: UnsafePointer<UInt8>!,
    _ flags: vImage_Flags
) -> vImage_Error {
    _ = tempBuffer
    _ = backgroundColor
    let source = src.pointee
    let destination = dest.pointee
    guard let sourceData = source.data, let destData = destination.data else {
        return kvImageNullPointerArgument
    }
    if source.width == 0 || source.height == 0 || destination.width == 0 || destination.height == 0 {
        return kvImageInvalidParameter
    }
    if kernel_width == 0 || kernel_height == 0
        || (kernel_width & 1) == 0 || (kernel_height & 1) == 0
    {
        return kvImageInvalidKernelSize
    }
    let edgeExtend = vImage_Flags(kvImageEdgeExtend)
    let copyInPlace = vImage_Flags(kvImageCopyInPlace)
    let backgroundFill = vImage_Flags(kvImageBackgroundColorFill)
    let truncateKernel = vImage_Flags(kvImageTruncateKernel)
    if (flags & edgeExtend) == 0
        || (flags & (copyInPlace | backgroundFill | truncateKernel)) != 0
    {
        return kvImageInvalidEdgeStyle
    }
    let leaveAlpha = vImage_Flags(kvImageLeaveAlphaUnchanged)
    let doNotTile = vImage_Flags(kvImageDoNotTile)
    let allowed = leaveAlpha | edgeExtend | doNotTile
    if (flags & ~allowed) != 0 {
        return kvImageInvalidParameter
    }
    if srcOffsetToROI_X > source.width || srcOffsetToROI_Y > source.height
        || destination.width > source.width - srcOffsetToROI_X
        || destination.height > source.height - srcOffsetToROI_Y
    {
        return kvImageBufferSizeMismatch
    }
    let sourceVisible = Int(source.width) * 4
    let destVisible = Int(destination.width) * 4
    if source.rowBytes < sourceVisible || destination.rowBytes < destVisible {
        return kvImageBufferSizeMismatch
    }

    let divisor = UInt64(kernel_width) * UInt64(kernel_height)
    if divisor == 0 {
        return kvImageInvalidKernelSize
    }

    let srcBytes = sourceData.assumingMemoryBound(to: UInt8.self)
    var ownedCopy: UnsafeMutablePointer<UInt8>?
    let readBase: UnsafePointer<UInt8>
    if source.data == destination.data {
        let byteCount = Int(source.height) * source.rowBytes
        let copy = UnsafeMutablePointer<UInt8>.allocate(capacity: byteCount)
        copy.update(from: srcBytes, count: byteCount)
        ownedCopy = copy
        readBase = UnsafePointer(copy)
    } else {
        readBase = UnsafePointer(srcBytes)
    }
    defer { ownedCopy?.deallocate() }

    let destBytes = destData.assumingMemoryBound(to: UInt8.self)
    let radiusX = kernel_width / 2
    let radiusY = kernel_height / 2
    let srcHeight = source.height
    let srcWidth = source.width

    func clamp(_ base: vImagePixelCount, kernelIndex: UInt32, radius: UInt32, limit: vImagePixelCount)
        -> vImagePixelCount
    {
        if kernelIndex < radius {
            let delta = vImagePixelCount(radius - kernelIndex)
            return delta > base ? 0 : base - delta
        }
        let delta = vImagePixelCount(kernelIndex - radius)
        if delta >= limit - base {
            return limit - 1
        }
        return base + delta
    }

    for y in 0..<destination.height {
        for x in 0..<destination.width {
            var sums: (UInt64, UInt64, UInt64, UInt64) = (0, 0, 0, 0)
            let centerX = srcOffsetToROI_X + x
            let centerY = srcOffsetToROI_Y + y
            for ky in 0..<kernel_height {
                let sy = clamp(centerY, kernelIndex: ky, radius: radiusY, limit: srcHeight)
                let row = readBase.advanced(by: Int(sy) * source.rowBytes)
                for kx in 0..<kernel_width {
                    let sx = clamp(centerX, kernelIndex: kx, radius: radiusX, limit: srcWidth)
                    let pixel = row.advanced(by: Int(sx) * 4)
                    sums.0 += UInt64(pixel[0])
                    sums.1 += UInt64(pixel[1])
                    sums.2 += UInt64(pixel[2])
                    sums.3 += UInt64(pixel[3])
                }
            }
            let sourcePixel = readBase.advanced(
                by: Int(centerY) * source.rowBytes + Int(centerX) * 4
            )
            let pixel = destBytes.advanced(by: Int(y) * destination.rowBytes + Int(x) * 4)
            if (flags & leaveAlpha) != 0 {
                pixel[0] = sourcePixel[0]
            } else {
                pixel[0] = UInt8((sums.0 + divisor / 2) / divisor)
            }
            pixel[1] = UInt8((sums.1 + divisor / 2) / divisor)
            pixel[2] = UInt8((sums.2 + divisor / 2) / divisor)
            pixel[3] = UInt8((sums.3 + divisor / 2) / divisor)
        }
    }
    return kvImageNoError
}
