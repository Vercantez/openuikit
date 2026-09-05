import Foundation

// Thumbnail geometry measured 2026-09-05 Apple ImageIO on a 16×12 PNG
// (macOS 26.1):
//   maxPixel 1→1×1, 2→2×2, 3→3×2, 4→4×3, 5→5×4, 6→6×4, 8→8×6,
//   16→16×12, 17→16×12 (no upscale).
// newDim = round-half-to-even(dim * maxPixel / max(w,h)), clamped ≥ 1.
// JPEG orientation 6 + CreateThumbnailWithTransform + max 8 → 6×8
// (rotate 90° CW after fitting the stored 16×12 into 8×6).

func imageioThumbnail(
    _ image: CGImage,
    options: CFDictionary?,
    orientation: UInt32
) -> CGImage? {
    let always = imageioDictBool(options, kCGImageSourceCreateThumbnailFromImageAlways)
    let ifAbsent = imageioDictBool(options, kCGImageSourceCreateThumbnailFromImageIfAbsent)
    let withTransform = imageioDictBool(options, kCGImageSourceCreateThumbnailWithTransform)
    let maxPixel = imageioDictInt(options, kCGImageSourceThumbnailMaxPixelSize)
    if !always && !ifAbsent && maxPixel == nil {
        return image
    }
    var working = image
    var width = image.width
    var height = image.height
    if withTransform, let oriented = imageioApplyOrientation(image, orientation) {
        working = oriented
        width = oriented.width
        height = oriented.height
    }
    guard let maxPixel, maxPixel > 0 else { return working }
    let longSide = max(width, height)
    if longSide <= maxPixel { return working }
    let scaledW = imageioScaleDim(width, maxPixel: maxPixel, longSide: longSide)
    let scaledH = imageioScaleDim(height, maxPixel: maxPixel, longSide: longSide)
    return imageioResample(working, width: scaledW, height: scaledH)
}

private func imageioScaleDim(_ dim: Int, maxPixel: Int, longSide: Int) -> Int {
    // MEASURED 2026-09-05: 16×12 max=6 → 6×4 because 12*6/16 = 4.5
    // rounds half-to-even to 4, not half-away-from-zero (which is 5).
    let scaled = (Double(dim) * Double(maxPixel) / Double(longSide))
        .rounded(.toNearestOrEven)
    return max(1, Int(scaled))
}

private func imageioResample(_ image: CGImage, width: Int, height: Int) -> CGImage? {
    guard width > 0, height > 0, image.width > 0, image.height > 0 else { return nil }
    if width == image.width, height == image.height { return image }
    var pixels = [UInt8](repeating: 0, count: width * height * 4)
    let srcW = image.width
    let srcH = image.height
    let src = image.pixels
    for y in 0..<height {
        let srcY = min(srcH - 1, y * srcH / height)
        for x in 0..<width {
            let srcX = min(srcW - 1, x * srcW / width)
            let di = (y * width + x) * 4
            let si = (srcY * srcW + srcX) * 4
            pixels[di] = src[si]
            pixels[di + 1] = src[si + 1]
            pixels[di + 2] = src[si + 2]
            pixels[di + 3] = src[si + 3]
        }
    }
    return imageioMakeImage(width: width, height: height, pixels: pixels)
}

private func imageioApplyOrientation(_ image: CGImage, _ orientation: UInt32) -> CGImage? {
    let width = image.width
    let height = image.height
    let src = image.pixels
    func pixel(_ x: Int, _ y: Int) -> (UInt8, UInt8, UInt8, UInt8) {
        let i = (y * width + x) * 4
        return (src[i], src[i + 1], src[i + 2], src[i + 3])
    }
    let swap = orientation >= 5
    let outW = swap ? height : width
    let outH = swap ? width : height
    var out = [UInt8](repeating: 0, count: outW * outH * 4)
    for y in 0..<height {
        for x in 0..<width {
            let (nx, ny): (Int, Int)
            switch orientation {
            case 2: nx = width - 1 - x; ny = y
            case 3: nx = width - 1 - x; ny = height - 1 - y
            case 4: nx = x; ny = height - 1 - y
            case 5: nx = y; ny = x
            case 6: nx = height - 1 - y; ny = x
            case 7: nx = height - 1 - y; ny = width - 1 - x
            case 8: nx = y; ny = width - 1 - x
            default: nx = x; ny = y
            }
            let p = pixel(x, y)
            let i = (ny * outW + nx) * 4
            out[i] = p.0
            out[i + 1] = p.1
            out[i + 2] = p.2
            out[i + 3] = p.3
        }
    }
    return imageioMakeImage(width: outW, height: outH, pixels: out)
}
