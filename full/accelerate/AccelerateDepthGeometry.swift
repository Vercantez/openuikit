import Foundation

func _vImageAffineFromDouble(_ transform: vImage_AffineTransform_Double) -> vImage_AffineTransform {
    vImage_AffineTransform(
        a: Float(transform.a),
        b: Float(transform.b),
        c: Float(transform.c),
        d: Float(transform.d),
        tx: Float(transform.tx),
        ty: Float(transform.ty)
    )
}

func _vImageBilinearScale(
    _ src: UnsafePointer<vImage_Buffer>,
    _ dest: UnsafePointer<vImage_Buffer>,
    bytesPerPixel: Int,
    flags: vImage_Flags
) -> vImage_Error {
    _ = flags
    let check = _vImageRequireBuffers(src, dest)
    if check != kvImageNoError { return check }
    let srcLayout = _vImageValidateLayout(src.pointee, bytesPerPixel: bytesPerPixel)
    if srcLayout != kvImageNoError { return srcLayout }
    let destLayout = _vImageValidateLayout(dest.pointee, bytesPerPixel: bytesPerPixel)
    if destLayout != kvImageNoError { return destLayout }
    let srcW = Int(src.pointee.width)
    let srcH = Int(src.pointee.height)
    let destW = Int(dest.pointee.width)
    let destH = Int(dest.pointee.height)
    guard srcW > 0, srcH > 0, destW > 0, destH > 0, bytesPerPixel > 0 else {
        return kvImageInvalidParameter
    }
    let srcRow = src.pointee.rowBytes
    let destRow = dest.pointee.rowBytes
    let srcBase = src.pointee.data!.assumingMemoryBound(to: UInt8.self)
    let destBase = dest.pointee.data!.assumingMemoryBound(to: UInt8.self)
    for y in 0..<destH {
        let fy = destH == 1 ? 0.0 : Double(y) * Double(srcH - 1) / Double(destH - 1)
        let y0 = min(srcH - 1, Int(Foundation.floor(fy)))
        let y1 = min(srcH - 1, y0 + 1)
        let wy = fy - Double(y0)
        for x in 0..<destW {
            let fx = destW == 1 ? 0.0 : Double(x) * Double(srcW - 1) / Double(destW - 1)
            let x0 = min(srcW - 1, Int(Foundation.floor(fx)))
            let x1 = min(srcW - 1, x0 + 1)
            let wx = fx - Double(x0)
            for c in 0..<bytesPerPixel {
                let p00 = Double(srcBase[y0 * srcRow + x0 * bytesPerPixel + c])
                let p10 = Double(srcBase[y0 * srcRow + x1 * bytesPerPixel + c])
                let p01 = Double(srcBase[y1 * srcRow + x0 * bytesPerPixel + c])
                let p11 = Double(srcBase[y1 * srcRow + x1 * bytesPerPixel + c])
                let top = p00 * (1 - wx) + p10 * wx
                let bot = p01 * (1 - wx) + p11 * wx
                let value = top * (1 - wy) + bot * wy
                destBase[y * destRow + x * bytesPerPixel + c] = UInt8(min(255, max(0, Int(value + 0.5))))
            }
        }
    }
    return kvImageNoError
}

func _vImageScaleDispatch(
    _ src: UnsafePointer<vImage_Buffer>,
    _ dest: UnsafePointer<vImage_Buffer>,
    bytesPerPixel: Int,
    flags: vImage_Flags
) -> vImage_Error {
    if flags & vImage_Flags(kvImageHighQualityResampling) != 0 {
        return _vImageBilinearScale(src, dest, bytesPerPixel: bytesPerPixel, flags: flags)
    }
    return _vImageNearestScale(src, dest, bytesPerPixel: bytesPerPixel, flags: flags)
}

func _vImageAffineWarpU8(
    _ src: UnsafePointer<vImage_Buffer>,
    _ dest: UnsafePointer<vImage_Buffer>,
    transform: vImage_AffineTransform,
    backColor: UnsafePointer<UInt8>?,
    bytesPerPixel: Int,
    flags: vImage_Flags
) -> vImage_Error {
    if flags & vImage_Flags(kvImageGetTempBufferSize) != 0 { return 0 }
    let check = _vImageRequireBuffers(src, dest)
    if check != kvImageNoError { return check }
    let srcLayout = _vImageValidateLayout(src.pointee, bytesPerPixel: bytesPerPixel)
    if srcLayout != kvImageNoError { return srcLayout }
    let destLayout = _vImageValidateLayout(dest.pointee, bytesPerPixel: bytesPerPixel)
    if destLayout != kvImageNoError { return destLayout }
    let srcW = Int(src.pointee.width)
    let srcH = Int(src.pointee.height)
    let destW = Int(dest.pointee.width)
    let destH = Int(dest.pointee.height)
    guard srcW > 0, srcH > 0, destW > 0, destH > 0 else { return kvImageInvalidParameter }
    let bilinear = flags & vImage_Flags(kvImageHighQualityResampling) != 0
    let srcRow = src.pointee.rowBytes
    let destRow = dest.pointee.rowBytes
    let srcBase = src.pointee.data!.assumingMemoryBound(to: UInt8.self)
    let destBase = dest.pointee.data!.assumingMemoryBound(to: UInt8.self)
    let a = Double(transform.a)
    let b = Double(transform.b)
    let c = Double(transform.c)
    let d = Double(transform.d)
    let tx = Double(transform.tx)
    let ty = Double(transform.ty)
    func sampleNearest(_ sx: Int, _ sy: Int, _ channel: Int) -> UInt8 {
        if sx < 0 || sy < 0 || sx >= srcW || sy >= srcH {
            if let backColor { return backColor[channel] }
            return 0
        }
        return srcBase[sy * srcRow + sx * bytesPerPixel + channel]
    }
    for y in 0..<destH {
        for x in 0..<destW {
            let sx = a * Double(x) + b * Double(y) + tx
            let sy = c * Double(x) + d * Double(y) + ty
            let destPixel = destBase.advanced(by: y * destRow + x * bytesPerPixel)
            if bilinear {
                let x0 = Int(Foundation.floor(sx))
                let y0 = Int(Foundation.floor(sy))
                let wx = sx - Double(x0)
                let wy = sy - Double(y0)
                for channel in 0..<bytesPerPixel {
                    let p00 = Double(sampleNearest(x0, y0, channel))
                    let p10 = Double(sampleNearest(x0 + 1, y0, channel))
                    let p01 = Double(sampleNearest(x0, y0 + 1, channel))
                    let p11 = Double(sampleNearest(x0 + 1, y0 + 1, channel))
                    let top = p00 * (1 - wx) + p10 * wx
                    let bot = p01 * (1 - wx) + p11 * wx
                    let value = top * (1 - wy) + bot * wy
                    destPixel[channel] = UInt8(min(255, max(0, Int(value + 0.5))))
                }
            } else {
                let nx = Int(sx >= 0 ? sx + 0.5 : sx - 0.5)
                let ny = Int(sy >= 0 ? sy + 0.5 : sy - 0.5)
                for channel in 0..<bytesPerPixel {
                    destPixel[channel] = sampleNearest(nx, ny, channel)
                }
            }
        }
    }
    return kvImageNoError
}

func _vImageRotateU8(
    _ src: UnsafePointer<vImage_Buffer>,
    _ dest: UnsafePointer<vImage_Buffer>,
    angleInRadians: Float,
    backColor: UnsafePointer<UInt8>?,
    bytesPerPixel: Int,
    flags: vImage_Flags
) -> vImage_Error {
    let check = _vImageRequireBuffers(src, dest)
    if check != kvImageNoError { return check }
    let srcW = Double(src.pointee.width)
    let srcH = Double(src.pointee.height)
    let destW = Double(dest.pointee.width)
    let destH = Double(dest.pointee.height)
    let cosA = Double(Foundation.cos(angleInRadians))
    let sinA = Double(Foundation.sin(angleInRadians))
    let cxSrc = (srcW - 1) / 2
    let cySrc = (srcH - 1) / 2
    let cxDst = (destW - 1) / 2
    let cyDst = (destH - 1) / 2
    // Map destination pixels into source space around image centres.
    let transform = vImage_AffineTransform(
        a: Float(cosA),
        b: Float(sinA),
        c: Float(-sinA),
        d: Float(cosA),
        tx: Float(-cosA * cxDst - sinA * cyDst + cxSrc),
        ty: Float(sinA * cxDst - cosA * cyDst + cySrc)
    )
    return _vImageAffineWarpU8(
        src, dest, transform: transform, backColor: backColor,
        bytesPerPixel: bytesPerPixel, flags: flags
    )
}

func _vImagePermuteChannelsU8(
    _ src: UnsafePointer<vImage_Buffer>,
    _ dest: UnsafePointer<vImage_Buffer>,
    permuteMap: UnsafePointer<UInt8>,
    channelCount: Int,
    flags: vImage_Flags
) -> vImage_Error {
    _ = flags
    let check = _vImageRequireBuffers(src, dest)
    if check != kvImageNoError { return check }
    let srcLayout = _vImageValidateLayout(src.pointee, bytesPerPixel: channelCount)
    if srcLayout != kvImageNoError { return srcLayout }
    let destLayout = _vImageValidateLayout(dest.pointee, bytesPerPixel: channelCount)
    if destLayout != kvImageNoError { return destLayout }
    let w = Int(src.pointee.width)
    let h = Int(src.pointee.height)
    guard w == Int(dest.pointee.width), h == Int(dest.pointee.height) else {
        return kvImageBufferSizeMismatch
    }
    var map = [Int](repeating: 0, count: channelCount)
    for i in 0..<channelCount {
        let idx = Int(permuteMap[i])
        if idx < 0 || idx >= channelCount { return kvImageInvalidParameter }
        map[i] = idx
    }
    let srcRow = src.pointee.rowBytes
    let destRow = dest.pointee.rowBytes
    let srcBase = src.pointee.data!.assumingMemoryBound(to: UInt8.self)
    let destBase = dest.pointee.data!.assumingMemoryBound(to: UInt8.self)
    var tmp = [UInt8](repeating: 0, count: channelCount)
    for y in 0..<h {
        for x in 0..<w {
            let si = y * srcRow + x * channelCount
            for c in 0..<channelCount { tmp[c] = srcBase[si + c] }
            let di = y * destRow + x * channelCount
            for c in 0..<channelCount { destBase[di + c] = tmp[map[c]] }
        }
    }
    return kvImageNoError
}

func _vImageTentWeight(_ offset: Int, radius: Int) -> Int {
    max(0, radius + 1 - abs(offset))
}

func _vImageTentConvolveU8(
    _ src: UnsafePointer<vImage_Buffer>,
    _ dest: UnsafePointer<vImage_Buffer>,
    kernelWidth: UInt32,
    kernelHeight: UInt32,
    bytesPerPixel: Int,
    flags: vImage_Flags
) -> vImage_Error {
    let check = _vImageRequireBuffers(src, dest)
    if check != kvImageNoError { return check }
    if kernelWidth % 2 == 0 || kernelHeight % 2 == 0 || kernelWidth == 0 || kernelHeight == 0 {
        return kvImageInvalidKernelSize
    }
    if flags & vImage_Flags(kvImageEdgeExtend) == 0 && flags & vImage_Flags(kvImageBackgroundColorFill) == 0 {
        return kvImageInvalidEdgeStyle
    }
    let srcLayout = _vImageValidateLayout(src.pointee, bytesPerPixel: bytesPerPixel)
    if srcLayout != kvImageNoError { return srcLayout }
    let destLayout = _vImageValidateLayout(dest.pointee, bytesPerPixel: bytesPerPixel)
    if destLayout != kvImageNoError { return destLayout }
    let w = Int(src.pointee.width)
    let h = Int(src.pointee.height)
    guard w == Int(dest.pointee.width), h == Int(dest.pointee.height) else {
        return kvImageBufferSizeMismatch
    }
    let rx = Int(kernelWidth) / 2
    let ry = Int(kernelHeight) / 2
    var weightSum = 0
    for ky in -ry...ry {
        for kx in -rx...rx {
            weightSum += _vImageTentWeight(kx, radius: rx) * _vImageTentWeight(ky, radius: ry)
        }
    }
    guard weightSum > 0 else { return kvImageInvalidKernelSize }
    let srcRow = src.pointee.rowBytes
    let destRow = dest.pointee.rowBytes
    let srcBase = src.pointee.data!.assumingMemoryBound(to: UInt8.self)
    let destBase = dest.pointee.data!.assumingMemoryBound(to: UInt8.self)
    func sample(_ x: Int, _ y: Int, _ c: Int) -> Int {
        let xx = min(max(x, 0), w - 1)
        let yy = min(max(y, 0), h - 1)
        return Int(srcBase[yy * srcRow + xx * bytesPerPixel + c])
    }
    for y in 0..<h {
        for x in 0..<w {
            for c in 0..<bytesPerPixel {
                var sum = 0
                for ky in -ry...ry {
                    let wy = _vImageTentWeight(ky, radius: ry)
                    for kx in -rx...rx {
                        let wx = _vImageTentWeight(kx, radius: rx)
                        sum += sample(x + kx, y + ky, c) * wx * wy
                    }
                }
                destBase[y * destRow + x * bytesPerPixel + c] = UInt8((sum + weightSum / 2) / weightSum)
            }
        }
    }
    return kvImageNoError
}
