import Foundation

func _vImageRequireBuffers(_ src: UnsafePointer<vImage_Buffer>?, _ dest: UnsafePointer<vImage_Buffer>?) -> vImage_Error {
    guard let src, let dest, src.pointee.data != nil, dest.pointee.data != nil else {
        return kvImageNullPointerArgument
    }
    return kvImageNoError
}

func _vImageValidateLayout(_ buf: vImage_Buffer, bytesPerPixel: Int) -> vImage_Error {
    let w = Int(buf.width)
    let h = Int(buf.height)
    if w < 0 || h < 0 || bytesPerPixel <= 0 {
        return kvImageInvalidParameter
    }
    if buf.rowBytes < w * bytesPerPixel {
        return kvImageInvalidRowBytes
    }
    return kvImageNoError
}

func _vImageNearestScale(
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
    let srcBase = src.pointee.data!
    let destBase = dest.pointee.data!
    for y in 0..<destH {
        let sy = min(srcH - 1, y * srcH / destH)
        for x in 0..<destW {
            let sx = min(srcW - 1, x * srcW / destW)
            let s = srcBase.advanced(by: sy * srcRow + sx * bytesPerPixel)
            let d = destBase.advanced(by: y * destRow + x * bytesPerPixel)
            d.copyMemory(from: s, byteCount: bytesPerPixel)
        }
    }
    return kvImageNoError
}

func _vImageFill(
    _ dest: UnsafePointer<vImage_Buffer>,
    color: UnsafeRawPointer,
    bytesPerPixel: Int,
    flags: vImage_Flags
) -> vImage_Error {
    _ = flags
    guard dest.pointee.data != nil else { return kvImageNullPointerArgument }
    let layout = _vImageValidateLayout(dest.pointee, bytesPerPixel: bytesPerPixel)
    if layout != kvImageNoError { return layout }
    let w = Int(dest.pointee.width)
    let h = Int(dest.pointee.height)
    guard w >= 0, h >= 0, bytesPerPixel > 0 else { return kvImageInvalidParameter }
    let row = dest.pointee.rowBytes
    for y in 0..<h {
        for x in 0..<w {
            dest.pointee.data!.advanced(by: y * row + x * bytesPerPixel)
                .copyMemory(from: color, byteCount: bytesPerPixel)
        }
    }
    return kvImageNoError
}

func _vImageCopyBuffer(
    _ src: UnsafePointer<vImage_Buffer>,
    _ dest: UnsafePointer<vImage_Buffer>,
    pixelSize: Int,
    flags: vImage_Flags
) -> vImage_Error {
    _vImageNearestScale(src, dest, bytesPerPixel: pixelSize, flags: flags)
}

func _vImageReflectHorizontal(
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
    let w = Int(src.pointee.width)
    let h = Int(src.pointee.height)
    guard w == Int(dest.pointee.width), h == Int(dest.pointee.height), bytesPerPixel > 0 else {
        return kvImageBufferSizeMismatch
    }
    let srcRow = src.pointee.rowBytes
    let destRow = dest.pointee.rowBytes
    for y in 0..<h {
        for x in 0..<w {
            let s = src.pointee.data!.advanced(by: y * srcRow + x * bytesPerPixel)
            let d = dest.pointee.data!.advanced(by: y * destRow + (w - 1 - x) * bytesPerPixel)
            d.copyMemory(from: s, byteCount: bytesPerPixel)
        }
    }
    return kvImageNoError
}

func _vImageReflectVertical(
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
    let w = Int(src.pointee.width)
    let h = Int(src.pointee.height)
    guard w == Int(dest.pointee.width), h == Int(dest.pointee.height), bytesPerPixel > 0 else {
        return kvImageBufferSizeMismatch
    }
    let srcRow = src.pointee.rowBytes
    let destRow = dest.pointee.rowBytes
    for y in 0..<h {
        for x in 0..<w {
            let s = src.pointee.data!.advanced(by: y * srcRow + x * bytesPerPixel)
            let d = dest.pointee.data!.advanced(by: (h - 1 - y) * destRow + x * bytesPerPixel)
            d.copyMemory(from: s, byteCount: bytesPerPixel)
        }
    }
    return kvImageNoError
}

func _vImageRotate90(
    _ src: UnsafePointer<vImage_Buffer>,
    _ dest: UnsafePointer<vImage_Buffer>,
    rotationConstant: UInt8,
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
    let w = Int(src.pointee.width)
    let h = Int(src.pointee.height)
    let srcRow = src.pointee.rowBytes
    let destRow = dest.pointee.rowBytes
    let turns = Int(rotationConstant) & 3
    for y in 0..<h {
        for x in 0..<w {
            var dx = x
            var dy = y
            var dw = w
            var dh = h
            switch turns {
            case 1:
                dx = h - 1 - y
                dy = x
                dw = h
                dh = w
            case 2:
                dx = w - 1 - x
                dy = h - 1 - y
            case 3:
                dx = y
                dy = w - 1 - x
                dw = h
                dh = w
            default:
                break
            }
            _ = dw
            _ = dh
            let s = src.pointee.data!.advanced(by: y * srcRow + x * bytesPerPixel)
            let d = dest.pointee.data!.advanced(by: dy * destRow + dx * bytesPerPixel)
            d.copyMemory(from: s, byteCount: bytesPerPixel)
        }
    }
    return kvImageNoError
}

func _vImageHistogramPlanar8(
    _ src: UnsafePointer<vImage_Buffer>,
    histogram: UnsafeMutablePointer<vImagePixelCount>,
    flags: vImage_Flags
) -> vImage_Error {
    _ = flags
    guard src.pointee.data != nil else { return kvImageNullPointerArgument }
    let layout = _vImageValidateLayout(src.pointee, bytesPerPixel: 1)
    if layout != kvImageNoError { return layout }
    for i in 0..<256 { histogram[i] = 0 }
    let w = Int(src.pointee.width)
    let h = Int(src.pointee.height)
    let row = src.pointee.rowBytes
    let base = src.pointee.data!.assumingMemoryBound(to: UInt8.self)
    for y in 0..<h {
        for x in 0..<w {
            let value = base[y * row + x]
            histogram[Int(value)] += 1
        }
    }
    return kvImageNoError
}

func _vImageAlphaBlendARGB8888(
    _ srcTop: UnsafePointer<vImage_Buffer>,
    _ srcBottom: UnsafePointer<vImage_Buffer>,
    _ dest: UnsafePointer<vImage_Buffer>,
    flags: vImage_Flags
) -> vImage_Error {
    _ = flags
    guard srcTop.pointee.data != nil, srcBottom.pointee.data != nil, dest.pointee.data != nil else {
        return kvImageNullPointerArgument
    }
    let topLayout = _vImageValidateLayout(srcTop.pointee, bytesPerPixel: 4)
    if topLayout != kvImageNoError { return topLayout }
    let bottomLayout = _vImageValidateLayout(srcBottom.pointee, bytesPerPixel: 4)
    if bottomLayout != kvImageNoError { return bottomLayout }
    let destLayout = _vImageValidateLayout(dest.pointee, bytesPerPixel: 4)
    if destLayout != kvImageNoError { return destLayout }
    let w = Int(srcTop.pointee.width)
    let h = Int(srcTop.pointee.height)
    for y in 0..<h {
        for x in 0..<w {
            let ti = y * srcTop.pointee.rowBytes + x * 4
            let bi = y * srcBottom.pointee.rowBytes + x * 4
            let di = y * dest.pointee.rowBytes + x * 4
            let t = srcTop.pointee.data!.assumingMemoryBound(to: UInt8.self)
            let b = srcBottom.pointee.data!.assumingMemoryBound(to: UInt8.self)
            let d = dest.pointee.data!.assumingMemoryBound(to: UInt8.self)
            let a = Int(t[ti])
            d[di] = UInt8(min(255, a))
            for c in 1..<4 {
                let tv = Int(t[ti + c]) * a
                let bv = Int(b[bi + c]) * (255 - a)
                d[di + c] = UInt8((tv + bv + 127) / 255)
            }
        }
    }
    return kvImageNoError
}

func _vImagePremultiplyARGB8888(
    _ src: UnsafePointer<vImage_Buffer>,
    _ dest: UnsafePointer<vImage_Buffer>,
    flags: vImage_Flags
) -> vImage_Error {
    _ = flags
    let check = _vImageRequireBuffers(src, dest)
    if check != kvImageNoError { return check }
    let srcLayout = _vImageValidateLayout(src.pointee, bytesPerPixel: 4)
    if srcLayout != kvImageNoError { return srcLayout }
    let destLayout = _vImageValidateLayout(dest.pointee, bytesPerPixel: 4)
    if destLayout != kvImageNoError { return destLayout }
    let w = Int(src.pointee.width)
    let h = Int(src.pointee.height)
    for y in 0..<h {
        for x in 0..<w {
            let si = y * src.pointee.rowBytes + x * 4
            let di = y * dest.pointee.rowBytes + x * 4
            let s = src.pointee.data!.assumingMemoryBound(to: UInt8.self)
            let d = dest.pointee.data!.assumingMemoryBound(to: UInt8.self)
            let a = Int(s[si])
            d[di] = s[si]
            for c in 1..<4 {
                d[di + c] = UInt8((Int(s[si + c]) * a + 127) / 255)
            }
        }
    }
    return kvImageNoError
}

func _vImageUnpremultiplyARGB8888(
    _ src: UnsafePointer<vImage_Buffer>,
    _ dest: UnsafePointer<vImage_Buffer>,
    flags: vImage_Flags
) -> vImage_Error {
    _ = flags
    let check = _vImageRequireBuffers(src, dest)
    if check != kvImageNoError { return check }
    let srcLayout = _vImageValidateLayout(src.pointee, bytesPerPixel: 4)
    if srcLayout != kvImageNoError { return srcLayout }
    let destLayout = _vImageValidateLayout(dest.pointee, bytesPerPixel: 4)
    if destLayout != kvImageNoError { return destLayout }
    let w = Int(src.pointee.width)
    let h = Int(src.pointee.height)
    for y in 0..<h {
        for x in 0..<w {
            let si = y * src.pointee.rowBytes + x * 4
            let di = y * dest.pointee.rowBytes + x * 4
            let s = src.pointee.data!.assumingMemoryBound(to: UInt8.self)
            let d = dest.pointee.data!.assumingMemoryBound(to: UInt8.self)
            let a = Int(s[si])
            d[di] = s[si]
            if a == 0 {
                for c in 1..<4 { d[di + c] = 0 }
            } else {
                for c in 1..<4 {
                    d[di + c] = UInt8(min(255, (Int(s[si + c]) * 255 + a / 2) / a))
                }
            }
        }
    }
    return kvImageNoError
}

func _vImageConvertPlanar8toARGB8888(
    _ srcA: UnsafePointer<vImage_Buffer>,
    _ srcR: UnsafePointer<vImage_Buffer>,
    _ srcG: UnsafePointer<vImage_Buffer>,
    _ srcB: UnsafePointer<vImage_Buffer>,
    _ dest: UnsafePointer<vImage_Buffer>,
    flags: vImage_Flags
) -> vImage_Error {
    _ = flags
    let w = Int(srcA.pointee.width)
    let h = Int(srcA.pointee.height)
    let destLayout = _vImageValidateLayout(dest.pointee, bytesPerPixel: 4)
    if destLayout != kvImageNoError { return destLayout }
    if _vImageValidateLayout(srcA.pointee, bytesPerPixel: 1) != kvImageNoError { return kvImageInvalidRowBytes }
    if _vImageValidateLayout(srcR.pointee, bytesPerPixel: 1) != kvImageNoError { return kvImageInvalidRowBytes }
    if _vImageValidateLayout(srcG.pointee, bytesPerPixel: 1) != kvImageNoError { return kvImageInvalidRowBytes }
    if _vImageValidateLayout(srcB.pointee, bytesPerPixel: 1) != kvImageNoError { return kvImageInvalidRowBytes }
    for y in 0..<h {
        for x in 0..<w {
            let di = y * dest.pointee.rowBytes + x * 4
            let d = dest.pointee.data!.assumingMemoryBound(to: UInt8.self)
            d[di] = srcA.pointee.data!.assumingMemoryBound(to: UInt8.self)[y * srcA.pointee.rowBytes + x]
            d[di + 1] = srcR.pointee.data!.assumingMemoryBound(to: UInt8.self)[y * srcR.pointee.rowBytes + x]
            d[di + 2] = srcG.pointee.data!.assumingMemoryBound(to: UInt8.self)[y * srcG.pointee.rowBytes + x]
            d[di + 3] = srcB.pointee.data!.assumingMemoryBound(to: UInt8.self)[y * srcB.pointee.rowBytes + x]
        }
    }
    return kvImageNoError
}

func _vImageConvertARGB8888toPlanar8(
    _ srcARGB: UnsafePointer<vImage_Buffer>,
    _ destA: UnsafePointer<vImage_Buffer>,
    _ destR: UnsafePointer<vImage_Buffer>,
    _ destG: UnsafePointer<vImage_Buffer>,
    _ destB: UnsafePointer<vImage_Buffer>,
    flags: vImage_Flags
) -> vImage_Error {
    _ = flags
    let w = Int(srcARGB.pointee.width)
    let h = Int(srcARGB.pointee.height)
    if _vImageValidateLayout(srcARGB.pointee, bytesPerPixel: 4) != kvImageNoError { return kvImageInvalidRowBytes }
    if _vImageValidateLayout(destA.pointee, bytesPerPixel: 1) != kvImageNoError { return kvImageInvalidRowBytes }
    if _vImageValidateLayout(destR.pointee, bytesPerPixel: 1) != kvImageNoError { return kvImageInvalidRowBytes }
    if _vImageValidateLayout(destG.pointee, bytesPerPixel: 1) != kvImageNoError { return kvImageInvalidRowBytes }
    if _vImageValidateLayout(destB.pointee, bytesPerPixel: 1) != kvImageNoError { return kvImageInvalidRowBytes }
    for y in 0..<h {
        for x in 0..<w {
            let si = y * srcARGB.pointee.rowBytes + x * 4
            let s = srcARGB.pointee.data!.assumingMemoryBound(to: UInt8.self)
            destA.pointee.data!.assumingMemoryBound(to: UInt8.self)[y * destA.pointee.rowBytes + x] = s[si]
            destR.pointee.data!.assumingMemoryBound(to: UInt8.self)[y * destR.pointee.rowBytes + x] = s[si + 1]
            destG.pointee.data!.assumingMemoryBound(to: UInt8.self)[y * destG.pointee.rowBytes + x] = s[si + 2]
            destB.pointee.data!.assumingMemoryBound(to: UInt8.self)[y * destB.pointee.rowBytes + x] = s[si + 3]
        }
    }
    return kvImageNoError
}

func _vImageConvertPlanar8toPlanarF(
    _ src: UnsafePointer<vImage_Buffer>,
    _ dest: UnsafePointer<vImage_Buffer>,
    maxFloat: Pixel_F,
    minFloat: Pixel_F,
    flags: vImage_Flags
) -> vImage_Error {
    _ = flags
    if _vImageValidateLayout(src.pointee, bytesPerPixel: 1) != kvImageNoError { return kvImageInvalidRowBytes }
    if _vImageValidateLayout(dest.pointee, bytesPerPixel: 4) != kvImageNoError { return kvImageInvalidRowBytes }
    let w = Int(src.pointee.width)
    let h = Int(src.pointee.height)
    let span = maxFloat - minFloat
    for y in 0..<h {
        for x in 0..<w {
            let s = src.pointee.data!.assumingMemoryBound(to: UInt8.self)[y * src.pointee.rowBytes + x]
            dest.pointee.data!.assumingMemoryBound(to: Float.self)[y * (dest.pointee.rowBytes / 4) + x] =
                minFloat + span * Float(s) / 255
        }
    }
    return kvImageNoError
}

func _vImageConvertPlanarFtoPlanar8(
    _ src: UnsafePointer<vImage_Buffer>,
    _ dest: UnsafePointer<vImage_Buffer>,
    maxFloat: Pixel_F,
    minFloat: Pixel_F,
    flags: vImage_Flags
) -> vImage_Error {
    _ = flags
    if _vImageValidateLayout(src.pointee, bytesPerPixel: 4) != kvImageNoError { return kvImageInvalidRowBytes }
    if _vImageValidateLayout(dest.pointee, bytesPerPixel: 1) != kvImageNoError { return kvImageInvalidRowBytes }
    let w = Int(src.pointee.width)
    let h = Int(src.pointee.height)
    let span = maxFloat - minFloat
    for y in 0..<h {
        for x in 0..<w {
            let v = src.pointee.data!.assumingMemoryBound(to: Float.self)[y * (src.pointee.rowBytes / 4) + x]
            var scaled = span == 0 ? 0 : (v - minFloat) / span * 255
            if scaled < 0 { scaled = 0 }
            if scaled > 255 { scaled = 255 }
            dest.pointee.data!.assumingMemoryBound(to: UInt8.self)[y * dest.pointee.rowBytes + x] = UInt8(scaled)
        }
    }
    return kvImageNoError
}

func _vImageBoxConvolvePlanar8(
    _ src: UnsafePointer<vImage_Buffer>,
    _ dest: UnsafePointer<vImage_Buffer>,
    kernelWidth: UInt32,
    kernelHeight: UInt32,
    flags: vImage_Flags
) -> vImage_Error {
    let kw = Int(kernelWidth)
    let kh = Int(kernelHeight)
    if kw % 2 == 0 || kh % 2 == 0 { return kvImageInvalidKernelSize }
    if flags & vImage_Flags(kvImageEdgeExtend) == 0 { return kvImageInvalidEdgeStyle }
    if _vImageValidateLayout(src.pointee, bytesPerPixel: 1) != kvImageNoError { return kvImageInvalidRowBytes }
    if _vImageValidateLayout(dest.pointee, bytesPerPixel: 1) != kvImageNoError { return kvImageInvalidRowBytes }
    let w = Int(src.pointee.width)
    let h = Int(src.pointee.height)
    let rx = kw / 2
    let ry = kh / 2
    func sample(_ x: Int, _ y: Int) -> Int {
        let xx = min(max(x, 0), w - 1)
        let yy = min(max(y, 0), h - 1)
        return Int(src.pointee.data!.assumingMemoryBound(to: UInt8.self)[yy * src.pointee.rowBytes + xx])
    }
    for y in 0..<h {
        for x in 0..<w {
            var sum = 0
            for ky in -ry...ry {
                for kx in -rx...rx {
                    sum += sample(x + kx, y + ky)
                }
            }
            dest.pointee.data!.assumingMemoryBound(to: UInt8.self)[y * dest.pointee.rowBytes + x] =
                UInt8((sum + (kw * kh) / 2) / (kw * kh))
        }
    }
    return kvImageNoError
}
